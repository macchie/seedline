class_name Net
extends Node
## Nakama client: device auth with token refresh, RPC calls, presence socket and an offline run queue.
## Every public call is safe to make when the backend is disabled or unreachable; the game never waits on it.

signal status_changed(text: String)
signal online_changed(count: int)
signal track_info_ready(seed: String, env: String, info: Dictionary)
signal run_submitted(seed: String, env: String, info: Dictionary)
signal account_changed
signal car_pulled(car: Dictionary)
signal _auth_finished

const QUEUE_KEY := "net_queue"
const QUEUE_MAX := 50
const TIMEOUT_S := 8.0
const HEARTBEAT_S := 60.0
const ROOM := "seedline"
const SEED_RE := "^[A-Z0-9][A-Z0-9_-]*$"
const CAR_PUSH_DELAY_S := 1.5
const PASSWORD_MIN := 8

var enabled := true
var host := "127.0.0.1"
var port := 7350
var use_ssl := false
var server_key := "defaultkey"

var status := "offline"
var online := 0
var display_name := ""
var email := ""

var _token := ""
var _refresh := ""
var _auth_busy := false
var _session_id := ""
var _flushing := false
var _flush_retry_at := 0
var _socket: WebSocketPeer = null
var _socket_state := -1
var _room := {}
var _socket_retry_at := 0
var _socket_backoff := 2.0
var _hello_done := false
var _connecting := false
var _heartbeat: Timer
var _seed_re := RegEx.new()
var _info_serial := 0
var _car_timer: Timer
var _car_serial := 0
var _car_busy := false


func _ready() -> void:
	_load_config()
	_seed_re.compile(SEED_RE)
	_session_id = _uuid()
	display_name = str(Store.get_value("racer_name", ""))
	if display_name == "":
		display_name = "seedliner-%04d" % (randi() % 10000)
		Store.set_value("racer_name", display_name)
	_token = str(Store.get_value("net_token", ""))
	_refresh = str(Store.get_value("net_refresh", ""))
	email = str(Store.get_value("net_email", ""))
	_car_timer = Timer.new()
	_car_timer.one_shot = true
	_car_timer.wait_time = CAR_PUSH_DELAY_S
	_car_timer.timeout.connect(_push_car)
	add_child(_car_timer)
	_heartbeat = Timer.new()
	_heartbeat.wait_time = HEARTBEAT_S
	_heartbeat.timeout.connect(_on_heartbeat)
	add_child(_heartbeat)
	if enabled:
		_heartbeat.start()
		_connect()


func _load_config() -> void:
	enabled = bool(ProjectSettings.get_setting("seedline/nakama/enabled", true))
	host = str(ProjectSettings.get_setting("seedline/nakama/host", host))
	port = int(ProjectSettings.get_setting("seedline/nakama/port", port))
	use_ssl = bool(ProjectSettings.get_setting("seedline/nakama/ssl", use_ssl))
	server_key = str(ProjectSettings.get_setting("seedline/nakama/server_key", server_key))
	# environment overrides let a build point at another deployment without touching the project
	var e := OS.get_environment("SEEDLINE_NAKAMA_ENABLED")
	if e != "":
		enabled = e not in ["0", "false", "off"]
	if OS.get_environment("SEEDLINE_NAKAMA_HOST") != "":
		host = OS.get_environment("SEEDLINE_NAKAMA_HOST")
	if OS.get_environment("SEEDLINE_NAKAMA_PORT") != "":
		port = int(OS.get_environment("SEEDLINE_NAKAMA_PORT"))
	if OS.get_environment("SEEDLINE_NAKAMA_SSL") != "":
		use_ssl = OS.get_environment("SEEDLINE_NAKAMA_SSL") in ["1", "true", "on"]
	if OS.get_environment("SEEDLINE_NAKAMA_KEY") != "":
		server_key = OS.get_environment("SEEDLINE_NAKAMA_KEY")


# ================================================================== public api

func is_registered() -> bool:
	return email != ""


## Links an email and password to the current account, so runs and settings carry over. Returns {ok, code, message}.
func register(mail: String, password: String, name: String) -> Dictionary:
	if not enabled:
		return _result(false, 0, "disabled", true)
	if not await _ensure_auth():
		return _result(false, 0, "offline", false)
	var body := {"email": mail, "password": password}
	var r: Dictionary = await _api("POST", "/v2/account/link/email", body, true)
	if r.code == 401:
		_token = ""
		if await _ensure_auth():
			r = await _api("POST", "/v2/account/link/email", body, true)
	if not r.ok:
		return r
	email = mail
	Store.set_value("net_email", mail)
	if name.strip_edges().length() >= 2:
		await set_display_name(name)
	await _refresh_account(false)
	account_changed.emit()
	queue_car()
	return r


## Switches to an existing account. Its car and name replace the local ones. Returns {ok, code, message}.
func login(mail: String, password: String) -> Dictionary:
	if not enabled:
		return _result(false, 0, "disabled", true)
	if _token != "":
		await flush_queue()
	var r: Dictionary = await _api("POST", "/v2/account/authenticate/email?create=false", {"email": mail, "password": password}, false)
	if not r.ok:
		return r
	if not _take_session(r):
		return _result(false, 0, "bad response", false)
	email = mail
	Store.set_value("net_email", mail)
	await _switch_session()
	account_changed.emit()
	return r


func logout() -> void:
	if not enabled:
		return
	await flush_queue()
	if _token != "":
		await _api("POST", "/v2/session/logout", {"token": _token, "refresh_token": _refresh}, true)
	_token = ""
	_refresh = ""
	email = ""
	Store.set_value("net_token", "")
	Store.set_value("net_refresh", "")
	Store.set_value("net_email", "")
	# the old device id is linked to the account that just signed out
	Store.set_value("net_device", "")
	display_name = "seedliner-%04d" % (randi() % 10000)
	Store.set_value("racer_name", display_name)
	await _switch_session()
	account_changed.emit()


## Marks the garage settings as changed; they are uploaded shortly after the last change.
func queue_car() -> void:
	_car_serial += 1
	Store.set_value("car_dirty", true)
	if enabled:
		_car_timer.start()


func is_online() -> bool:
	return enabled and status == "online"


func eligible(seed: String) -> bool:
	return enabled and seed.length() <= 64 and _seed_re.search(seed) != null


func set_display_name(n: String) -> void:
	n = n.strip_edges().substr(0, 20)
	if n.length() < 2:
		return
	display_name = n
	Store.set_value("racer_name", n)
	if not enabled or not await _ensure_auth():
		return
	await _api("PUT", "/v2/account", {"display_name": n}, true)


func fetch_track_info(seed: String, env: String) -> void:
	if not eligible(seed):
		return
	_info_serial += 1
	var serial := _info_serial
	var r: Dictionary = await call_rpc("seedline_track_info", {"seed": seed, "env": env})
	if serial != _info_serial:
		return
	if r.ok and r.data is Dictionary:
		track_info_ready.emit(seed, env, r.data)
	else:
		track_info_ready.emit(seed, env, {"error": true})


func submit_run(seed: String, env: String, time_s: float, length_m: float, splits: Array, laps: int, ghost: Array = []) -> void:
	if not eligible(seed):
		return
	var sp: Array = []
	for s in splits:
		sp.append(snappedf(float(s), 0.001))
	var entry := {
		"run_id": _uuid(),
		"seed": seed,
		"env": env,
		"time_ms": int(round(time_s * 1000.0)),
		"laps": laps,
		"length_m": snappedf(length_m, 0.1),
		"splits": sp,
		"version": str(ProjectSettings.get_setting("application/config/version", "")),
	}
	if ghost.size() >= 6 and ghost.size() % 3 == 0:
		entry.ghost = ghost.duplicate()
	var q: Array = Store.get_value(QUEUE_KEY, [])
	q.append(entry)
	while q.size() > QUEUE_MAX:
		q.pop_front()
	Store.set_value(QUEUE_KEY, q)
	flush_queue()


func flush_queue() -> void:
	if not enabled or _flushing or Time.get_ticks_msec() < _flush_retry_at:
		return
	_flushing = true
	while true:
		var q: Array = Store.get_value(QUEUE_KEY, [])
		if q.is_empty():
			break
		var entry: Dictionary = q[0]
		var r: Dictionary = await call_rpc("seedline_submit_run", entry)
		if r.ok:
			q.pop_front()
			Store.set_value(QUEUE_KEY, q)
			if r.data is Dictionary and r.data.get("info") is Dictionary:
				run_submitted.emit(entry.seed, entry.env, r.data.info)
			continue
		if r.permanent:
			push_warning("Seedline: run rejected by the server (%s)" % r.message)
			q.pop_front()
			Store.set_value(QUEUE_KEY, q)
			continue
		# transient failure: keep the queue and try again later
		_flush_retry_at = Time.get_ticks_msec() + (60000 if r.code == 429 else 15000)
		break
	_flushing = false


## Calls an RPC. Returns {ok, code, message, permanent, data}.
func call_rpc(id: String, payload: Dictionary) -> Dictionary:
	if not enabled:
		return _result(false, 0, "disabled", true)
	var r: Dictionary = await _rpc_once(id, payload)
	if r.code == 401:
		_token = ""
		r = await _rpc_once(id, payload)
	return r


# ================================================================== auth

func _connect() -> void:
	if _connecting:
		return
	_connecting = true
	var ok: bool = await _ensure_auth()
	if ok:
		await _refresh_account(true)
		await _hello()
	_connecting = false
	if not ok or not _hello_done:
		_set_status("offline")
		return
	_open_socket()
	flush_queue()
	sync_car()


func _switch_session() -> void:
	while _connecting:
		await get_tree().process_frame
	if _socket != null:
		_socket.close()
		_socket = null
		_socket_state = -1
	_room.clear()
	_socket_retry_at = 0
	_socket_backoff = 2.0
	_hello_done = false
	_set_status("offline")
	await _connect()


func _refresh_account(adopt_name: bool) -> void:
	var r: Dictionary = await _api("GET", "/v2/account", "", true)
	if not r.ok or not (r.data is Dictionary):
		return
	var mail := str(r.data.get("email", ""))
	var changed := mail != email
	email = mail
	Store.set_value("net_email", mail)
	var user = r.data.get("user")
	if adopt_name and mail != "" and user is Dictionary:
		var n := str(user.get("display_name", ""))
		if n.length() >= 2 and n != display_name:
			display_name = n
			Store.set_value("racer_name", n)
			changed = true
	if changed:
		account_changed.emit()


# ================================================================== garage sync

func sync_car() -> void:
	if not enabled or _car_busy:
		return
	_car_busy = true
	var r: Dictionary = await call_rpc("seedline_get_car", {})
	_car_busy = false
	if not r.ok or not (r.data is Dictionary):
		return
	var uid := _uid()
	var remote = r.data.get("car")
	var rev := int(r.data.get("rev", 0))
	var same_owner: bool = uid != "" and str(Store.get_value("car_uid", "")) == uid
	var dirty := bool(Store.get_value("car_dirty", false))
	if not (remote is Dictionary) or remote.is_empty():
		await _push_car()
	elif same_owner and dirty:
		await _push_car()
	elif not same_owner or rev > int(Store.get_value("car_rev", 0)):
		Store.set_value("car_rev", rev)
		Store.set_value("car_uid", uid)
		Store.set_value("car_dirty", false)
		car_pulled.emit(remote)


func _push_car() -> void:
	if not enabled or _car_busy:
		return
	var car: Dictionary = Store.get_value("car", {})
	if not car.has("color") or not car.has("finish"):
		car = {"color": "#e8402c", "finish": "gloss", "boost_color": "#38e8ff"}
	var serial := _car_serial
	_car_busy = true
	var r: Dictionary = await call_rpc("seedline_save_car", {
		"color": str(car.color),
		"finish": str(car.finish),
		"boost_color": str(car.get("boost_color", "#38e8ff")),
	})
	_car_busy = false
	if r.ok and r.data is Dictionary:
		Store.set_value("car_rev", int(r.data.get("rev", 0)))
		Store.set_value("car_uid", _uid())
		if serial == _car_serial:
			Store.set_value("car_dirty", false)
		else:
			_car_timer.start()
	elif not r.permanent:
		_car_timer.start(30.0)


func _uid() -> String:
	var c := _claims(_token)
	return str(c.get("uid", ""))


func _hello() -> void:
	var r: Dictionary = await _rpc_once("seedline_hello", {
		"client_session": _session_id,
		"platform": OS.get_name(),
		"version": str(ProjectSettings.get_setting("application/config/version", "")),
		"locale": OS.get_locale(),
	})
	if r.ok and r.data is Dictionary:
		_hello_done = true
		_set_online(int(r.data.get("online", online)))
		_set_status("online")
		if display_name != "":
			_api("PUT", "/v2/account", {"display_name": display_name}, true)
	else:
		if r.code == 401:
			_token = ""
		_set_status("offline")


func _on_heartbeat() -> void:
	if not enabled:
		return
	if not _hello_done or status != "online":
		_hello_done = false
		_connect()
		return
	_hello()
	flush_queue()


func _ensure_auth() -> bool:
	if _token != "" and _token_valid(_token):
		return true
	if _auth_busy:
		await _auth_finished
		return _token != "" and _token_valid(_token)
	_auth_busy = true
	var ok := false
	if _refresh != "" and _token_valid(_refresh):
		ok = _take_session(await _api("POST", "/v2/account/session/refresh", {"token": _refresh}, false))
	if not ok:
		var device := str(Store.get_value("net_device", ""))
		if device == "":
			device = _uuid()
			Store.set_value("net_device", device)
		ok = _take_session(await _api("POST", "/v2/account/authenticate/device?create=true", {"id": device}, false))
	_auth_busy = false
	_auth_finished.emit()
	return ok


func _take_session(r: Dictionary) -> bool:
	if not r.ok or not (r.data is Dictionary) or not r.data.has("token"):
		return false
	_token = str(r.data.token)
	_refresh = str(r.data.get("refresh_token", _refresh))
	Store.set_value("net_token", _token)
	Store.set_value("net_refresh", _refresh)
	return true


func _claims(jwt: String) -> Dictionary:
	var parts := jwt.split(".")
	if parts.size() != 3:
		return {}
	var b64 := parts[1].replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var claims = JSON.parse_string(Marshalls.base64_to_raw(b64).get_string_from_utf8())
	return claims if claims is Dictionary else {}


func _token_valid(jwt: String) -> bool:
	var claims := _claims(jwt)
	if not claims.has("exp"):
		return false
	# renew a little early so a request never races the expiry
	return float(claims.exp) - Time.get_unix_time_from_system() > 30.0


# ================================================================== http

func _rpc_once(id: String, payload: Dictionary) -> Dictionary:
	if not await _ensure_auth():
		return _result(false, 0, "offline", false)
	# Nakama expects the RPC body to be a JSON encoded string
	var r: Dictionary = await _api("POST", "/v2/rpc/" + id, JSON.stringify(JSON.stringify(payload)), true)
	if r.ok and r.data is Dictionary and r.data.has("payload"):
		var inner = JSON.parse_string(str(r.data.payload))
		r.data = inner if inner != null else {}
	return r


func _api(method: String, path: String, body, authed: bool) -> Dictionary:
	if authed and _token == "":
		return _result(false, 401, "no session", false)
	var req := HTTPRequest.new()
	req.timeout = TIMEOUT_S
	add_child(req)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if authed:
		headers.append("Authorization: Bearer " + _token)
	else:
		headers.append("Authorization: Basic " + Marshalls.utf8_to_base64(server_key + ":"))
	var url := "%s://%s:%d%s" % ["https" if use_ssl else "http", host, port, path]
	var text: String = body if body is String else JSON.stringify(body)
	var m: int = {"GET": HTTPClient.METHOD_GET, "POST": HTTPClient.METHOD_POST, "PUT": HTTPClient.METHOD_PUT}[method]
	var err := req.request(url, headers, m, text)
	if err != OK:
		req.queue_free()
		return _result(false, 0, "request error %d" % err, false)
	var res: Array = await req.request_completed
	req.queue_free()
	if res[0] != HTTPRequest.RESULT_SUCCESS:
		return _result(false, 0, "network error %d" % res[0], false)
	var code: int = res[1]
	var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if code >= 200 and code < 300:
		var out := _result(true, code, "", false)
		out.data = parsed if parsed != null else {}
		return out
	var msg := str(parsed.get("message", "")) if parsed is Dictionary else ""
	# 4xx other than auth, timeouts and rate limits will never succeed on retry
	var permanent := code >= 400 and code < 500 and code not in [401, 408, 429]
	return _result(false, code, msg, permanent)


func _result(ok: bool, code: int, message: String, permanent: bool) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "permanent": permanent, "data": {}}


# ================================================================== presence socket

func _open_socket() -> void:
	if not enabled or _token == "" or _socket != null:
		return
	_socket = WebSocketPeer.new()
	var url := "%s://%s:%d/ws?token=%s&format=json&status=false" % ["wss" if use_ssl else "ws", host, port, _token.uri_encode()]
	_socket_state = -1
	if _socket.connect_to_url(url) != OK:
		_socket = null
		_schedule_socket_retry()


func _schedule_socket_retry() -> void:
	_socket_retry_at = Time.get_ticks_msec() + int(_socket_backoff * 1000.0)
	_socket_backoff = minf(_socket_backoff * 2.0, 60.0)


func _process(_dt: float) -> void:
	if not enabled:
		return
	if _socket == null:
		if _socket_retry_at > 0 and Time.get_ticks_msec() >= _socket_retry_at:
			_socket_retry_at = 0
			if _token == "" or not _token_valid(_token):
				_hello_done = false
				_connect()
			else:
				_open_socket()
		return
	_socket.poll()
	var st := _socket.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if _socket_state != st:
			_socket_state = st
			_socket_backoff = 2.0
			_socket.send_text(JSON.stringify({"cid": "1", "channel_join": {"target": ROOM, "type": 1, "persistence": false, "hidden": false}}))
		while _socket.get_available_packet_count() > 0:
			_on_socket_message(_socket.get_packet().get_string_from_utf8())
	elif st == WebSocketPeer.STATE_CLOSED:
		_socket = null
		_socket_state = -1
		_schedule_socket_retry()


func _on_socket_message(text: String) -> void:
	var m = JSON.parse_string(text)
	if not (m is Dictionary):
		return
	if m.get("channel") is Dictionary:
		_room.clear()
		for p in m.channel.get("presences", []):
			_room[str(p.get("session_id", ""))] = true
		var me = m.channel.get("self")
		if me is Dictionary:
			_room[str(me.get("session_id", ""))] = true
		_set_online(maxi(1, _room.size()))
	elif m.get("channel_presence_event") is Dictionary:
		var e: Dictionary = m.channel_presence_event
		for p in e.get("joins", []):
			_room[str(p.get("session_id", ""))] = true
		for p in e.get("leaves", []):
			_room.erase(str(p.get("session_id", "")))
		_set_online(maxi(1, _room.size()))


func _set_online(n: int) -> void:
	if n != online:
		online = n
		online_changed.emit(n)


func _set_status(s: String) -> void:
	if s != status:
		status = s
		status_changed.emit(s)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _socket != null:
		_socket.close()


func _uuid() -> String:
	var c := Crypto.new().generate_random_bytes(16)
	c[6] = (c[6] & 0x0f) | 0x40
	c[8] = (c[8] & 0x3f) | 0x80
	var h := c.hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]
