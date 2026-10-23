--[[
  Seedline — Nakama runtime module (Lua).

  RPCs (all require a user session; the HTTP key is rejected):
    seedline_hello        register the client session (platform/version), returns the online count
    seedline_submit_run   submit a finished race; validated, idempotent, rate limited
    seedline_track_info   leaderboard top N + the caller's rank + per-track statistics
    seedline_overview     global statistics (online users, players, runs, sessions, daily actives)

  Data model:
    leaderboard  "track:<ENV>:<SEED>"   authoritative, ascending, operator "best", score = time in ms
    track_ghosts (user, public read)    validated best-run path per user and track
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
  ghost_limit = 10,
  ghost_scan_limit = 100,
  ghost_max_points = 5000,
  ghost_sample_hz = 5,
  room = "seedline",
  shards = 8,
  occ_retries = 10,
}

-- Performance Points: a global skill rating in the osu!/Trackmania style, built for repeatable
-- 3-lap time attacks. Per track we judge a run against the shrunk log-normal distribution of every
-- player's best time, convert the Z-score to track PP, then aggregate a player's best tracks with a
-- geometric 0.95 decay. All of it is forge-proof: the client never sends PP, only its (validated) time.
local PP = {
  base = 100.0,        -- PP for an average (Z = 0) clean run
  z_min = -2.0,        -- clamp so a broken, unpopulated seed cannot grant infinite points
  z_max = 4.0,         -- a god-tier ~ +4 sigma world record tops out near 300 PP
  syn_weight = 5.0,    -- W: the synthetic "par anchor" counts as this many virtual players (a Bayesian prior)
  syn_speed = 50.0,    -- m/s reference average speed for the synthetic par time (calibrate with real data)
  syn_sigma = 0.15,    -- synthetic spread of ln(time); dominates sigma until real players arrive
  conf_k = 3.0,        -- C_confidence = N / (N + conf_k): caps PP until a few players challenge a seed
  decay = 0.95,        -- geometric weight of the i-th best track in the global total (series converges to x20)
  keep = 200,          -- most-valuable tracks retained per player for the global total
  score_scale = 100.0, -- the global_pp leaderboard stores round(global_pp * 100) as an integer score
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

  local ghost = nil
  if p.ghost ~= nil then
    if type(p.ghost) ~= "table" or #p.ghost < 6 or #p.ghost % 3 ~= 0 or #p.ghost / 3 > CFG.ghost_max_points then
      fail("invalid ghost path", E_INVALID)
    end
    ghost = {}
    local count = 0
    for i, value in ipairs(p.ghost) do
      local component = (i - 1) % 3
      local limit = component == 2 and 3142 or 1000000
      if not is_number(value) or value ~= math.floor(value) or math.abs(value) > limit then
        fail("invalid ghost path", E_INVALID)
      end
      count = count + 1
      ghost[count] = value
    end
    if count ~= #p.ghost then
      fail("invalid ghost path", E_INVALID)
    end
  end

  return {
    lb_id = lb_id,
    seed = p.seed,
    env = p.env,
    run_id = run_id,
    time_ms = p.time_ms,
    length_m = p.length_m,
    version = type(p.version) == "string" and p.version:sub(1, 32) or "",
    ghost = ghost,
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

-- Raw track_stats doc with the fields PP needs (log-time sums, length). Internal; not sent to clients.
local function track_stats_doc(lb_id)
  local doc = read_doc("track_stats", lb_id, SYSTEM) or {}
  return {
    runs = doc.runs or 0,
    players = doc.players or 0,
    best_ms = doc.best_ms,
    total_ms = doc.total_ms or 0,
    first_at = doc.first_at,
    last_at = doc.last_at,
    length_m = doc.length_m,
    sum_logt = doc.sum_logt,
    sum_logt2 = doc.sum_logt2,
  }
end

-- The client-facing subset (no internal log sums).
local function track_stats(lb_id)
  local doc = track_stats_doc(lb_id)
  return {
    runs = doc.runs,
    players = doc.players,
    best_ms = doc.best_ms,
    total_ms = doc.total_ms,
    first_at = doc.first_at,
    last_at = doc.last_at,
  }
end

-- ----------------------------------------------------------------------------- performance points

-- Synthetic par anchor: a forge-proof prior time (ms) derived from the validated track length.
local function pp_par_ms(length_m)
  local total_m = CFG.laps * (length_m or CFG.min_length_m)
  return (total_m / PP.syn_speed) * 1000.0
end

-- Bayesian-shrunk mean and standard deviation of ln(best time) for a track's player population.
-- Blends the N real players with W synthetic "par" players so a 1-2 player seed is judged mostly
-- against the generator's physics, and the real distribution dominates once ~20 humans have raced.
local function pp_effective(stats)
  local n = stats.players or 0
  local mu_syn = math.log(pp_par_ms(stats.length_m))
  local mu_players, var_players = mu_syn, 0.0
  if n >= 1 and stats.sum_logt ~= nil then
    mu_players = stats.sum_logt / n
    var_players = (stats.sum_logt2 or 0) / n - mu_players * mu_players
    if var_players < 0 then var_players = 0 end
  end
  local sigma_players = math.sqrt(var_players)
  local w = PP.syn_weight
  local mu_eff = (n * mu_players + w * mu_syn) / (n + w)
  local sigma_eff = (n * sigma_players + w * PP.syn_sigma) / (n + w)
  if sigma_eff < 1e-6 then
    sigma_eff = PP.syn_sigma
  end
  return mu_eff, sigma_eff, n
end

-- Raw track PP for a finish time (ms) against the track's current shrunk distribution.
-- Returns pp, the clamped z-score and the player count used.
local function pp_for_time(stats, time_ms)
  local n = stats.players or 0
  if not is_number(time_ms) or time_ms <= 0 then
    return 0.0, 0.0, n
  end
  local mu_eff, sigma_eff = pp_effective(stats)
  local z = (mu_eff - math.log(time_ms)) / sigma_eff
  if z < PP.z_min then
    z = PP.z_min
  elseif z > PP.z_max then
    z = PP.z_max
  end
  local conf = n / (n + PP.conf_k)
  local pp = PP.base * (1.0 + 0.5 * z) * conf
  if pp < 0 then
    pp = 0.0
  end
  return pp, z, n
end

local function round(x)
  return math.floor(x + 0.5)
end

local function track_info(lb_id, uid)
  local sdoc = track_stats_doc(lb_id)
  local result = {
    stats = {
      runs = sdoc.runs, players = sdoc.players, best_ms = sdoc.best_ms,
      total_ms = sdoc.total_ms, first_at = sdoc.first_at, last_at = sdoc.last_at,
    },
    top = {}, me = nil, ghosts = {},
  }
  local ok, records, owner_records = pcall(nk.leaderboard_records_list, lb_id, { uid }, CFG.ghost_scan_limit)
  if not ok then
    return result
  end
  local ids, seen = {}, {}
  local function collect(list, limit)
    for _, r in ipairs(list or {}) do
      if not seen[r.owner_id] then
        seen[r.owner_id] = true
        ids[#ids + 1] = r.owner_id
        if limit ~= nil and #ids >= limit then
          return
        end
      end
    end
  end
  collect(records, CFG.top_limit)
  collect(owner_records)
  local names = display_names(ids)
  for i, r in ipairs(records or {}) do
    if i <= CFG.top_limit then
      result.top[#result.top + 1] = {
        rank = r.rank,
        user_id = r.owner_id,
        name = names[r.owner_id] or r.username or "racer",
        time_ms = r.score,
      }
    end
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

  local reads, candidates = {}, {}
  for _, r in ipairs(records or {}) do
    if r.owner_id ~= uid and #candidates < CFG.ghost_scan_limit then
      candidates[#candidates + 1] = r
      reads[#reads + 1] = {
        collection = "track_ghosts",
        key = lb_id,
        user_id = r.owner_id,
      }
    end
  end
  if #reads > 0 then
    local read_ok, objects = pcall(nk.storage_read, reads)
    if not read_ok then
      nk.logger_warn("track ghost lookup failed: " .. tostring(objects))
    else
      local paths = {}
      for _, object in ipairs(objects or {}) do
        paths[object.user_id] = object.value
      end
      for _, r in ipairs(candidates) do
        if #result.ghosts >= CFG.ghost_limit then
          break
        end
        local doc = paths[r.owner_id]
        if doc ~= nil and doc.time_ms == r.score and type(doc.path) == "table" then
          result.ghosts[#result.ghosts + 1] = { time_ms = r.score, path = doc.path }
        end
      end
    end
  end

  -- PP preview for the current track: what the fastest run is worth now, what the caller's best is
  -- worth, the forge-proof par anchor and the theoretical ceiling of a +z_max world record.
  result.pp = {
    players = sdoc.players,
    par_ms = round(pp_par_ms(sdoc.length_m)),
    max_pp = PP.base * (1.0 + 0.5 * PP.z_max),
  }
  if result.top[1] ~= nil then
    result.pp.top_pp = pp_for_time(sdoc, result.top[1].time_ms)
  end
  if result.me ~= nil and result.me.time_ms ~= nil then
    result.pp.me_pp = pp_for_time(sdoc, result.me.time_ms)
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

-- ----------------------------------------------------------------------------- events (daily / weekly seeds)
-- Rotating authoritative leaderboards whose featured seed changes every period. The server is the
-- single source of truth for the seed: it derives it deterministically from the period index, so
-- every client races the same course and no one can forge "today's" board.

local EVENTS = {
  daily  = { cron = "0 0 * * *",  title = "Daily Seed",  window = 86400 },
  weekly = { cron = "0 0 * * 1",  title = "Weekly Seed", window = 604800 },
}
-- the client's shareable seed alphabet (scripts/core/u.gd CODE) — no I/L/O/0/1
local SEED_CODE = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
local EPOCH_MONDAY = 345600 -- 1970-01-05 00:00 UTC, the first Monday after the epoch

local function event_period(kind)
  local now = now_s()
  if kind == "weekly" then
    local p = math.floor((now - EPOCH_MONDAY) / EVENTS.weekly.window)
    return p, EPOCH_MONDAY + (p + 1) * EVENTS.weekly.window
  end
  local p = math.floor(now / EVENTS.daily.window)
  return p, (p + 1) * EVENTS.daily.window
end

-- Deterministic 16-char seed for a period. Lua 5.1 (gopher-lua) has no bitwise ops, so this uses
-- multiply/mod arithmetic kept well under 2^53 to stay exact: a rolling hash seeds a small LCG.
local function event_seed(kind, period)
  local key = kind .. "|" .. tostring(period) .. "|seedline-v1"
  local h = 2166136261
  for i = 1, #key do
    h = (h * 31 + key:byte(i)) % 4294967296
  end
  local n = #SEED_CODE
  local out = {}
  for i = 1, 16 do
    h = (h * 1664525 + 1013904223) % 4294967296
    local idx = (math.floor(h / 65536) % n) + 1
    out[i] = SEED_CODE:sub(idx, idx)
  end
  return table.concat(out)
end

--- Top N and the caller's own rank for a named leaderboard (shared by events).
local function board_standings(board_id, uid, limit)
  local out = { top = {}, me = nil }
  local ok, records, owner_records = pcall(nk.leaderboard_records_list, board_id, { uid }, limit)
  if not ok then
    return out
  end
  local ids, seen = {}, {}
  for _, r in ipairs(records or {}) do
    if not seen[r.owner_id] then
      seen[r.owner_id] = true
      ids[#ids + 1] = r.owner_id
    end
  end
  if owner_records ~= nil and owner_records[1] ~= nil and not seen[owner_records[1].owner_id] then
    ids[#ids + 1] = owner_records[1].owner_id
  end
  local names = display_names(ids)
  for i, r in ipairs(records or {}) do
    if i <= limit then
      out.top[#out.top + 1] = {
        rank = r.rank,
        user_id = r.owner_id,
        name = names[r.owner_id] or r.username or "racer",
        time_ms = r.score,
      }
    end
  end
  if owner_records ~= nil and owner_records[1] ~= nil then
    local r = owner_records[1]
    local rank = r.rank
    if rank == nil or rank < 1 then
      local ok_h, hay = pcall(nk.leaderboard_records_haystack, board_id, uid, 1)
      if ok_h and hay ~= nil then
        for _, h in ipairs(hay) do
          if h.owner_id == uid then
            rank = h.rank
          end
        end
      end
    end
    if rank == nil or rank < 1 then
      -- the caller is already in the fetched top page; reuse that rank
      for _, t in ipairs(out.top) do
        if t.user_id == uid then
          rank = t.rank
        end
      end
    end
    out.me = { rank = rank or 0, time_ms = r.score }
  end
  return out
end

local function event_view(kind, uid)
  local period, ends_at = event_period(kind)
  local standings = board_standings(kind, uid, CFG.top_limit)
  return {
    kind = kind,
    title = EVENTS[kind].title,
    seed = event_seed(kind, period),
    ends_at = ends_at,
    top = standings.top,
    me = standings.me,
  }
end

--- Mirror a just-accepted run into any event board whose featured seed it matches.
local function record_event_runs(uid, username, run)
  for kind, _ in pairs(EVENTS) do
    local period = event_period(kind)
    if run.seed == event_seed(kind, period) then
      pcall(nk.leaderboard_record_write, kind, uid, username, run.time_ms, 0, { v = run.version })
    end
  end
end

local function ensure_event_boards()
  for kind, def in pairs(EVENTS) do
    local ok, err = pcall(nk.leaderboard_create, kind, true, "asc", "best", def.cron, { kind = "event", title = def.title })
    if not ok and not (type(err) == "string" and err:find("exist", 1, true)) then
      nk.logger_warn(string.format("event board %s: %s", kind, tostring(err)))
    end
  end
end

-- One authoritative, descending board for the global PP rating (score = round(PP * 100)).
local function ensure_global_board()
  local ok, err = pcall(nk.leaderboard_create, "global_pp", true, "desc", "set", nil, { kind = "global_pp" })
  if not ok and not (type(err) == "string" and err:find("exist", 1, true)) then
    nk.logger_warn("global_pp board: " .. tostring(err))
  end
end

--- When an event period rolls over, tell the top finishers how they placed.
local function on_event_reset(_context, leaderboard, _reset)
  local id = leaderboard ~= nil and leaderboard.id or nil
  if id == nil or EVENTS[id] == nil then
    return
  end
  local ok, records = pcall(nk.leaderboard_records_list, id, nil, 3)
  if not ok or records == nil then
    return
  end
  local notifs = {}
  for _, r in ipairs(records) do
    notifs[#notifs + 1] = {
      user_id = r.owner_id,
      subject = string.format("You finished #%d in the %s", r.rank, EVENTS[id].title),
      content = { event = id, rank = r.rank, time_ms = r.score },
      code = 100,
      persistent = true,
    }
  end
  if #notifs > 0 then
    pcall(nk.notifications_send, notifs)
  end
end

local function record_track_play(run, uid)
  -- the first write of a (user, track) marker is what makes a unique player
  local _, _, mark = update_doc("track_played", run.lb_id, uid, PERM_NONE, function(doc)
    local now = now_s()
    if doc == nil then
      return { first_at = now, last_at = now, runs = 1, best_ms = run.time_ms },
        { new_player = true, old_best = nil, improved = true, best_ms = run.time_ms }
    end
    local prev = doc.best_ms
    doc.runs = (doc.runs or 0) + 1
    doc.last_at = now
    local improved = run.time_ms < (prev or math.huge)
    if improved then
      doc.best_ms = run.time_ms
    end
    return doc, { new_player = false, old_best = prev, improved = improved, best_ms = doc.best_ms }
  end)
  mark = mark or { new_player = false, old_best = nil, improved = false, best_ms = run.time_ms }

  -- Track_stats keeps the running log-time sums over players' *best* times so PP can compute the
  -- shrunk mean/sigma without scanning the whole leaderboard. When a player sets a new best we swap
  -- their old ln(T) contribution for the new one; a slower run never changes the distribution.
  local _, stats_doc, new_track = update_doc("track_stats", run.lb_id, SYSTEM, PERM_PUBLIC, function(doc)
    local now = now_s()
    local created = doc == nil
    doc = doc or { runs = 0, players = 0, total_ms = 0, first_at = now, seed = run.seed, env = run.env,
      length_m = run.length_m, sum_logt = 0.0, sum_logt2 = 0.0 }
    doc.sum_logt = doc.sum_logt or 0.0
    doc.sum_logt2 = doc.sum_logt2 or 0.0
    doc.length_m = doc.length_m or run.length_m
    doc.runs = doc.runs + 1
    doc.total_ms = doc.total_ms + run.time_ms
    if mark.new_player then
      doc.players = doc.players + 1
      local l = math.log(run.time_ms)
      doc.sum_logt = doc.sum_logt + l
      doc.sum_logt2 = doc.sum_logt2 + l * l
    elseif mark.improved and mark.old_best ~= nil then
      local lo = math.log(mark.old_best)
      local ln = math.log(run.time_ms)
      doc.sum_logt = doc.sum_logt - lo + ln
      doc.sum_logt2 = doc.sum_logt2 - lo * lo + ln * ln
    end
    if doc.best_ms == nil or run.time_ms < doc.best_ms then
      doc.best_ms = run.time_ms
      doc.best_user = uid
    end
    doc.last_at = now
    return doc, created
  end)
  return mark, new_track, stats_doc
end

-- Recompute a player's global PP from their per-track bests and push it to the global_pp board.
-- track PP for the tracks they aren't actively racing can drift as others join; it refreshes the
-- next time they set a time there. The just-scored track is always recomputed against fresh stats.
local function update_player_pp(uid, run, stats_doc)
  local track_pp, z, n = pp_for_time(stats_doc, run.time_ms)
  local global = 0.0
  update_doc("profile", "pp", uid, PERM_NONE, function(doc)
    doc = doc or { tracks = {}, global = 0.0 }
    doc.tracks = doc.tracks or {}
    doc.tracks[run.lb_id] = { pp = track_pp, t = run.time_ms, seed = run.seed, env = run.env }
    local arr = {}
    for id, e in pairs(doc.tracks) do
      arr[#arr + 1] = { id = id, pp = e.pp or 0.0 }
    end
    table.sort(arr, function(a, b) return a.pp > b.pp end)
    local g, factor = 0.0, 1.0
    for _, e in ipairs(arr) do
      g = g + e.pp * factor
      factor = factor * PP.decay
    end
    if #arr > PP.keep then
      local kept = {}
      for i = 1, PP.keep do
        kept[arr[i].id] = doc.tracks[arr[i].id]
      end
      doc.tracks = kept
    end
    doc.global = g
    global = g
    return doc
  end)
  pcall(nk.leaderboard_record_write, "global_pp", uid, "", round(global * PP.score_scale), 0, { pp = global })
  return { track_pp = track_pp, global_pp = global, z = z, players = n, improved = true }
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

  local pp_result = nil
  local ok, err = pcall(function()
    ensure_leaderboard(run.lb_id, run.seed, run.env)
    local names = display_names({ uid })
    local username = names[uid] or context.username
    nk.leaderboard_record_write(run.lb_id, uid, username, run.time_ms, 0, { v = run.version })
    record_event_runs(uid, username, run)
    if run.ghost ~= nil then
      local ghost_ok, ghost_err = pcall(function()
        update_doc("track_ghosts", run.lb_id, uid, PERM_PUBLIC, function(doc)
          if doc ~= nil and run.time_ms >= (doc.time_ms or math.huge) then
            return nil
          end
          return {
            time_ms = run.time_ms,
            path = run.ghost,
            sample_hz = CFG.ghost_sample_hz,
          }
        end)
      end)
      if not ghost_ok then
        nk.logger_warn("track ghost save failed: " .. tostring(ghost_err))
      end
    end
    local mark, new_track, stats_doc = record_track_play(run, uid)
    counter_add("runs_total", 1)
    if new_track then
      counter_add("tracks_total", 1)
    end
    count_profile(info)
    -- A run only changes a player's PP when it is a new personal best; a slower run is informational.
    if mark.improved then
      local pp_ok, res = pcall(update_player_pp, uid, run, stats_doc)
      if pp_ok then
        pp_result = res
      else
        nk.logger_warn("pp update failed: " .. tostring(res))
      end
    else
      local best_pp, z, n = pp_for_time(stats_doc, mark.best_ms or run.time_ms)
      local pdoc = read_doc("profile", "pp", uid)
      pp_result = { track_pp = best_pp, global_pp = (pdoc and pdoc.global) or 0.0, z = z, players = n, improved = false }
    end
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

  return nk.json_encode({ accepted = true, duplicate = false, pp = pp_result, info = track_info(run.lb_id, uid) })
end

local function rpc_track_info(context, payload)
  local uid = require_user(context)
  local p = decode(payload)
  return nk.json_encode(track_info(track_id(p.seed, p.env), uid))
end

--- The current daily and weekly seed challenges: featured seed, end time, top times and the caller's rank.
local function rpc_events(context, _payload)
  local uid = require_user(context)
  return nk.json_encode({
    daily = event_view("daily", uid),
    weekly = event_view("weekly", uid),
    now = now_s(),
  })
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

--- The caller's global Performance Points: total, world rank, their most valuable tracks and the
--- current global top. Scores on the global_pp board are stored as round(PP * 100).
local function rpc_pp(context, _payload)
  local uid = require_user(context)
  local doc = read_doc("profile", "pp", uid) or { tracks = {}, global = 0.0 }
  local arr = {}
  for _, e in pairs(doc.tracks or {}) do
    arr[#arr + 1] = { seed = e.seed, env = e.env, pp = e.pp or 0.0, time_ms = e.t }
  end
  table.sort(arr, function(a, b) return a.pp > b.pp end)
  local top = {}
  for i = 1, math.min(#arr, 25) do
    top[i] = arr[i]
  end
  local rank = 0
  local ok_h, hay = pcall(nk.leaderboard_records_haystack, "global_pp", uid, 1)
  if ok_h and hay ~= nil then
    for _, h in ipairs(hay) do
      if h.owner_id == uid then
        rank = h.rank or 0
      end
    end
  end
  local standings = board_standings("global_pp", uid, CFG.top_limit)
  local players = {}
  for _, t in ipairs(standings.top) do
    players[#players + 1] = { rank = t.rank, name = t.name, global_pp = (t.time_ms or 0) / PP.score_scale }
  end
  return nk.json_encode({
    global_pp = doc.global or 0.0,
    rank = rank,
    tracks_scored = #arr,
    top = top,
    top_players = players,
  })
end

--- Garage settings follow the account. Last write wins; the server clock orders the revisions.
local CAR_FINISHES = { gloss = true, metal = true, matte = true }

local function rpc_get_car(context, _payload)
  local uid = require_user(context)
  local doc = read_doc("profile", "car", uid)
  if doc == nil then
    return nk.json_encode({ car = nil, rev = 0 })
  end
  return nk.json_encode({ car = {
    color = doc.color,
    finish = doc.finish,
    boost_color = doc.boost_color or "#38e8ff",
  }, rev = doc.rev })
end

local function rpc_save_car(context, payload)
  local uid = require_user(context)
  local p = decode(payload)
  if type(p.color) ~= "string" or not p.color:match("^#%x%x%x%x%x%x$") then
    fail("invalid car color", E_INVALID)
  end
  if type(p.finish) ~= "string" or not CAR_FINISHES[p.finish] then
    fail("invalid car finish", E_INVALID)
  end
  if p.boost_color ~= nil and (type(p.boost_color) ~= "string" or not p.boost_color:match("^#%x%x%x%x%x%x$")) then
    fail("invalid booster color", E_INVALID)
  end
  local rev = now_ms()
  local ok = update_doc("profile", "car", uid, PERM_NONE, function(doc)
    -- never move a revision backwards, even if the server clock does
    if doc ~= nil and doc.rev ~= nil and doc.rev >= rev then
      rev = doc.rev + 1
    end
    return {
      color = p.color:lower(),
      finish = p.finish,
      boost_color = (p.boost_color or (doc and doc.boost_color) or "#38e8ff"):lower(),
      rev = rev,
    }
  end)
  if not ok then
    fail("could not save the car", E_INTERNAL)
  end
  return nk.json_encode({ rev = rev })
end

ensure_event_boards()
ensure_global_board()
pcall(nk.register_leaderboard_reset, on_event_reset)

nk.register_rpc(rpc_hello, "seedline_hello")
nk.register_rpc(rpc_submit_run, "seedline_submit_run")
nk.register_rpc(rpc_track_info, "seedline_track_info")
nk.register_rpc(rpc_overview, "seedline_overview")
nk.register_rpc(rpc_get_car, "seedline_get_car")
nk.register_rpc(rpc_save_car, "seedline_save_car")
nk.register_rpc(rpc_events, "seedline_events")
nk.register_rpc(rpc_pp, "seedline_pp")

nk.logger_info("Seedline module loaded")
