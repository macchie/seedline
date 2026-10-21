--[[
  Seedline — Nakama runtime module (Lua).

  RPCs (all require a user session; the HTTP key is rejected):
    seedline_hello        register the client session (platform/version), returns the online count
    seedline_submit_run   submit a finished race; validated, idempotent, rate limited
    seedline_track_info   leaderboard top N + the caller's rank + per-track statistics
    seedline_overview     global statistics (online users, players, runs, sessions, daily actives)

  Data model:
    leaderboard  "track:<ENV>:<SEED>"   authoritative, ascending, operator "best", score = time in ms
    storage      track_stats   (system, public read)   runs / unique players / best / total time per track
                 track_played  (user)                  first/last play and personal numbers per user and track
                 runs          (user)                  one record per accepted run, key = client run id (idempotency)
                 sessions      (user)                  one record per client session (heartbeated through repeated hello calls)
                 profile       (user)                  per user totals, rate limiting window, last active day
                 counters      (system)                sharded global counters (sessions, runs, players, tracks, daily actives)

  Clients can never write scores: leaderboards are created as authoritative.
]]

local nk = require("nakama")

local CFG = {
  laps = 3,
  min_time_ms = 20000,
  max_time_ms = 3600000,
  -- the kart tops out at 84 m/s even while boosting, so a whole-run average can never exceed this
  max_avg_speed = 85.0,
  min_length_m = 1500,
  max_length_m = 5000,
  min_splits = 6,
  max_splits = 30,
  rate_window_s = 600,
  rate_max_runs = 30,
  top_limit = 10,
  room = "seedline",
  shards = 8,
  occ_retries = 10,
}

local SYSTEM = "00000000-0000-0000-0000-000000000000"
local PERM_NONE, PERM_PUBLIC = 0, 2

-- gRPC status codes understood by Nakama's error mapping
local E_INVALID, E_EXHAUSTED, E_PRECONDITION, E_INTERNAL, E_UNAUTH = 3, 8, 9, 13, 16

math.randomseed(nk.time())

local function fail(message, code)
  error({ message, code })
end

local function decode(payload)
  if payload == nil or payload == "" then
    return {}
  end
  local ok, value = pcall(nk.json_decode, payload)
  if not ok or type(value) ~= "table" then
    fail("payload must be a JSON object", E_INVALID)
  end
  return value
end

local function require_user(context)
  if context.user_id == nil or context.user_id == "" then
    fail("a user session is required", E_UNAUTH)
  end
  return context.user_id
end

local function now_ms()
  return nk.time()
end

local function now_s()
  return math.floor(now_ms() / 1000)
end

local function today()
  return os.date("!%Y%m%d", now_s())
end

local function is_conflict(err)
  return type(err) == "string" and (err:find("reject", 1, true) ~= nil or err:find("version", 1, true) ~= nil)
end

-- ----------------------------------------------------------------------------- storage helpers

local function read_doc(collection, key, user_id)
  local objects = nk.storage_read({ { collection = collection, key = key, user_id = user_id } })
  if objects ~= nil and #objects > 0 then
    return objects[1].value, objects[1].version
  end
  return nil, "*"
end

local function write_doc(collection, key, user_id, value, version, read_perm)
  return pcall(nk.storage_write, { {
    collection = collection,
    key = key,
    user_id = user_id,
    value = value,
    version = version,
    permission_read = read_perm or PERM_NONE,
    permission_write = PERM_NONE,
  } })
end

--- Optimistic read-modify-write. mutate(doc) returns the new doc (or nil to abort) and an extra result.
local function update_doc(collection, key, user_id, read_perm, mutate)
  for _ = 1, CFG.occ_retries do
    local doc, version = read_doc(collection, key, user_id)
    local new_doc, extra = mutate(doc)
    if new_doc == nil then
      return false, nil, extra
    end
    local ok, err = write_doc(collection, key, user_id, new_doc, version, read_perm)
    if ok then
      return true, new_doc, extra
    end
    if not is_conflict(err) then
      nk.logger_error(string.format("storage_write %s/%s failed: %s", collection, key, tostring(err)))
      fail("storage failure", E_INTERNAL)
    end
  end
  nk.logger_warn(string.format("storage_write %s/%s: too much contention", collection, key))
  fail("please retry", E_INTERNAL)
end

-- Sharded counters keep write contention low on hot global numbers.
local function counter_add(name, amount)
  local shard = math.random(CFG.shards)
  for _ = 1, CFG.occ_retries do
    local key = name .. ":" .. shard
    local doc, version = read_doc("counters", key, SYSTEM)
    local ok, err = write_doc("counters", key, SYSTEM, { v = (doc and doc.v or 0) + amount }, version)
    if ok then
      return
    end
    if not is_conflict(err) then
      nk.logger_error(string.format("counter %s failed: %s", key, tostring(err)))
      return
    end
    shard = math.random(CFG.shards)
  end
end

local function counter_total(name)
  local reads = {}
  for shard = 1, CFG.shards do
    reads[#reads + 1] = { collection = "counters", key = name .. ":" .. shard, user_id = SYSTEM }
  end
  local total = 0
  for _, object in ipairs(nk.storage_read(reads) or {}) do
    total = total + (object.value.v or 0)
  end
  return total
end

local function online_count()
  local ok, count = pcall(nk.stream_count, { mode = 2, label = CFG.room })
  if ok and type(count) == "number" then
    return count
  end
  return 0
end

-- ----------------------------------------------------------------------------- validation

local function is_number(v)
  return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function track_id(seed, env)
  if type(seed) ~= "string" or #seed < 1 or #seed > 64 or not seed:match("^[A-Z0-9][A-Z0-9_%-]*$") then
    fail("invalid seed", E_INVALID)
  end
  if type(env) ~= "string" or #env < 2 or #env > 24 or not env:match("^[A-Z0-9_]+$") then
    fail("invalid environment", E_INVALID)
  end
  return "track:" .. env .. ":" .. seed
end

local function validate_run(p)
  local lb_id = track_id(p.seed, p.env)

  local run_id = p.run_id
  if type(run_id) ~= "string" or #run_id < 8 or #run_id > 64 or not run_id:match("^[%w%-]+$") then
    fail("invalid run id", E_INVALID)
  end

  if not is_number(p.time_ms) or p.time_ms ~= math.floor(p.time_ms) then
    fail("invalid time", E_INVALID)
  end
  if p.time_ms < CFG.min_time_ms or p.time_ms > CFG.max_time_ms then
    fail("time out of range", E_INVALID)
  end

  if p.laps ~= CFG.laps then
    fail("unexpected lap count", E_INVALID)
  end

  if not is_number(p.length_m) or p.length_m < CFG.min_length_m or p.length_m > CFG.max_length_m then
    fail("invalid track length", E_INVALID)
  end
  local avg_speed = (CFG.laps * p.length_m) / (p.time_ms / 1000.0)
  if avg_speed > CFG.max_avg_speed then
    nk.logger_warn(string.format("rejected implausible run: %s %.1f m/s", lb_id, avg_speed))
    fail("implausible time", E_PRECONDITION)
  end

  local splits = p.splits
  if type(splits) ~= "table" or #splits < CFG.min_splits or #splits > CFG.max_splits or #splits % CFG.laps ~= 0 then
    fail("invalid splits", E_INVALID)
  end
  local previous = 0
  for _, s in ipairs(splits) do
    if not is_number(s) or s <= previous then
      fail("invalid splits", E_INVALID)
    end
    previous = s
  end
  if math.abs(previous * 1000.0 - p.time_ms) > 2.0 then
    fail("splits do not match the time", E_INVALID)
  end

  return {
    lb_id = lb_id,
    seed = p.seed,
    env = p.env,
    run_id = run_id,
    time_ms = p.time_ms,
    length_m = p.length_m,
    version = type(p.version) == "string" and p.version:sub(1, 32) or "",
  }
end

-- ----------------------------------------------------------------------------- players

local function display_names(ids)
  local names = {}
  if #ids == 0 then
    return names
  end
  local ok, users = pcall(nk.users_get_id, ids)
  if ok and users then
    for _, user in ipairs(users) do
      local name = user.display_name
      if name == nil or name == "" then
        name = user.username
      end
      names[user.user_id or user.id] = name
    end
  end
  return names
end

--- Per user totals, the daily active marker and the submission rate limit window.
local function touch_profile(uid, opts)
  local ok, _, extra = update_doc("profile", "profile", uid, PERM_NONE, function(doc)
    local now = now_s()
    local is_new = doc == nil
    doc = doc or { created_at = now, runs = 0, sessions = 0, window_start = now, window_runs = 0, last_day = "" }
    if opts.run then
      if now - doc.window_start >= CFG.rate_window_s then
        doc.window_start = now
        doc.window_runs = 0
      end
      if doc.window_runs >= CFG.rate_max_runs then
        return nil, "limited"
      end
      doc.window_runs = doc.window_runs + 1
      doc.runs = doc.runs + 1
    end
    if opts.session then
      doc.sessions = doc.sessions + 1
    end
    local result = { new_player = is_new, new_day = false }
    local day = today()
    if doc.last_day ~= day then
      doc.last_day = day
      result.new_day = true
    end
    doc.last_seen_at = now
    return doc, result
  end)
  return ok, extra
end

local function count_profile(info)
  if info == nil then
    return
  end
  if info.new_player then
    counter_add("players_total", 1)
  end
  if info.new_day then
    counter_add("dau:" .. today(), 1)
  end
end

-- ----------------------------------------------------------------------------- tracks

local function track_stats(lb_id)
  local doc = read_doc("track_stats", lb_id, SYSTEM) or {}
  return {
    runs = doc.runs or 0,
    players = doc.players or 0,
    best_ms = doc.best_ms,
    total_ms = doc.total_ms or 0,
    first_at = doc.first_at,
    last_at = doc.last_at,
  }
end

local function track_info(lb_id, uid)
  local result = { stats = track_stats(lb_id), top = {}, me = nil }
  local ok, records, owner_records = pcall(nk.leaderboard_records_list, lb_id, { uid }, CFG.top_limit)
  if not ok then
    return result
  end
  local ids, seen = {}, {}
  local function collect(list)
    for _, r in ipairs(list or {}) do
      if not seen[r.owner_id] then
        seen[r.owner_id] = true
        ids[#ids + 1] = r.owner_id
      end
    end
  end
  collect(records)
  collect(owner_records)
  local names = display_names(ids)
  for _, r in ipairs(records or {}) do
    result.top[#result.top + 1] = {
      rank = r.rank,
      user_id = r.owner_id,
      name = names[r.owner_id] or r.username or "racer",
      time_ms = r.score,
    }
  end
  if owner_records ~= nil and #owner_records > 0 then
    local r = owner_records[1]
    local rank = r.rank
    if rank == nil or rank < 1 then
      -- owner records can come back without a rank, the haystack query always ranks
      local ok_h, hay = pcall(nk.leaderboard_records_haystack, lb_id, uid, 1)
      if ok_h and hay ~= nil then
        for _, h in ipairs(hay) do
          if h.owner_id == uid then
            rank = h.rank
          end
        end
      end
    end
    if rank == nil or rank < 1 then
      for _, t in ipairs(result.top) do
        if t.user_id == uid then
          rank = t.rank
        end
      end
    end
    result.me = { rank = rank or 0, time_ms = r.score, name = names[uid] or r.username or "racer" }
  end
  return result
end

local function ensure_leaderboard(lb_id, seed, env)
  local ok, err = pcall(nk.leaderboard_create, lb_id, true, "asc", "best", nil, { seed = seed, env = env })
  if not ok then
    nk.logger_error(string.format("leaderboard_create %s failed: %s", lb_id, tostring(err)))
    fail("leaderboard unavailable", E_INTERNAL)
  end
end

local function record_track_play(run, uid)
  -- the first write of a (user, track) marker is what makes a unique player
  local _, _, new_player = update_doc("track_played", run.lb_id, uid, PERM_NONE, function(doc)
    local now = now_s()
    if doc == nil then
      return { first_at = now, last_at = now, runs = 1, best_ms = run.time_ms }, true
    end
    doc.runs = (doc.runs or 0) + 1
    doc.last_at = now
    if run.time_ms < (doc.best_ms or math.huge) then
      doc.best_ms = run.time_ms
    end
    return doc, false
  end)

  local _, _, new_track = update_doc("track_stats", run.lb_id, SYSTEM, PERM_PUBLIC, function(doc)
    local now = now_s()
    local created = doc == nil
    doc = doc or { runs = 0, players = 0, total_ms = 0, first_at = now, seed = run.seed, env = run.env, length_m = run.length_m }
    doc.runs = doc.runs + 1
    doc.total_ms = doc.total_ms + run.time_ms
    if new_player then
      doc.players = doc.players + 1
    end
    if doc.best_ms == nil or run.time_ms < doc.best_ms then
      doc.best_ms = run.time_ms
      doc.best_user = uid
    end
    doc.last_at = now
    return doc, created
  end)
  return new_player, new_track
end

-- ----------------------------------------------------------------------------- RPCs

local function rpc_hello(context, payload)
  local uid = require_user(context)
  local p = decode(payload)

  -- HTTP RPC contexts carry no session id, so the client supplies its own per launch id
  local session_id = p.client_session
  if type(session_id) == "string" and #session_id >= 8 and #session_id <= 64 and session_id:match("^[%w%-]+$") then
    local is_new_session = write_doc("sessions", session_id, uid, {
      started_at = now_s(),
      last_seen_at = now_s(),
      duration = 0,
      platform = type(p.platform) == "string" and p.platform:sub(1, 32) or "",
      version = type(p.version) == "string" and p.version:sub(1, 32) or "",
      locale = type(p.locale) == "string" and p.locale:sub(1, 16) or "",
      ip = context.client_ip,
    }, "*")
    if not is_new_session then
      -- repeated hellos act as heartbeats and keep the session duration current
      pcall(update_doc, "sessions", session_id, uid, PERM_NONE, function(doc)
        if doc == nil then
          return nil
        end
        doc.last_seen_at = now_s()
        doc.duration = doc.last_seen_at - (doc.started_at or doc.last_seen_at)
        return doc
      end)
    end
    -- only the first hello of a client session counts as a new session
    local _, info = touch_profile(uid, { session = is_new_session })
    if is_new_session then
      counter_add("sessions_total", 1)
    end
    count_profile(info)
  end

  return nk.json_encode({ online = online_count(), room = CFG.room, laps = CFG.laps })
end

local function rpc_submit_run(context, payload)
  local uid = require_user(context)
  local run = validate_run(decode(payload))

  -- idempotency: a retried submission returns the current standings without counting twice
  if read_doc("runs", run.run_id, uid) ~= nil then
    return nk.json_encode({ accepted = true, duplicate = true, info = track_info(run.lb_id, uid) })
  end

  local ok_profile, info = touch_profile(uid, { run = true })
  if not ok_profile then
    fail("too many submissions, slow down", E_EXHAUSTED)
  end

  local created = write_doc("runs", run.run_id, uid, {
    track = run.lb_id,
    time_ms = run.time_ms,
    length_m = run.length_m,
    version = run.version,
    at = now_s(),
  }, "*")
  if not created then
    return nk.json_encode({ accepted = true, duplicate = true, info = track_info(run.lb_id, uid) })
  end

  local ok, err = pcall(function()
    ensure_leaderboard(run.lb_id, run.seed, run.env)
    local names = display_names({ uid })
    nk.leaderboard_record_write(run.lb_id, uid, names[uid] or context.username, run.time_ms, 0, { v = run.version })
    local _, new_track = record_track_play(run, uid)
    counter_add("runs_total", 1)
    if new_track then
      counter_add("tracks_total", 1)
    end
    count_profile(info)
  end)
  if not ok then
    -- undo the idempotency marker so the client's retry is processed again
    pcall(nk.storage_delete, { { collection = "runs", key = run.run_id, user_id = uid } })
    if type(err) == "table" then
      error(err)
    end
    nk.logger_error("submit_run failed: " .. tostring(err))
    fail("could not record the run", E_INTERNAL)
  end

  return nk.json_encode({ accepted = true, duplicate = false, info = track_info(run.lb_id, uid) })
end

local function rpc_track_info(context, payload)
  local uid = require_user(context)
  local p = decode(payload)
  return nk.json_encode(track_info(track_id(p.seed, p.env), uid))
end

local function rpc_overview(context, _payload)
  require_user(context)
  return nk.json_encode({
    online = online_count(),
    players_total = counter_total("players_total"),
    runs_total = counter_total("runs_total"),
    sessions_total = counter_total("sessions_total"),
    tracks_total = counter_total("tracks_total"),
    active_today = counter_total("dau:" .. today()),
  })
end

nk.register_rpc(rpc_hello, "seedline_hello")
nk.register_rpc(rpc_submit_run, "seedline_submit_run")
nk.register_rpc(rpc_track_info, "seedline_track_info")
nk.register_rpc(rpc_overview, "seedline_overview")

nk.logger_info("Seedline module loaded")
