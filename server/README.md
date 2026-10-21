# Seedline online backend (Nakama)

The game talks to [Nakama](https://heroiclabs.com/nakama/) for sessions, online presence, per-track leaderboards and track statistics. All logic lives in one Lua runtime module, `nakama/modules/seedline.lua`. The Godot client (`scripts/net/net.gd`) is a thin REST and WebSocket client. Without a reachable server the game plays normally and finished runs are queued on disk (max 50) and uploaded later.

## Local deployment

Nakama 3.x with Postgres on the default ports (7350 HTTP, 7349 gRPC, 7351 console):

```sh
server/deploy-local.sh            # optional argument: container name (default "nakama")
```

The script copies the module into `/nakama/data/modules` of the container and restarts it. Lua modules are loaded at startup. Check `docker logs nakama` for `Seedline module loaded`. If you run Nakama some other way, mount or copy `server/nakama/modules` into the runtime path (`--runtime.path`).

## What the module provides

| RPC | Purpose |
| --- | --- |
| `seedline_hello` | Registers a client session (heartbeat, called every 60 s), counts sessions and daily actives, returns the online count. |
| `seedline_submit_run` | Validated, idempotent run submission. Writes the leaderboard record and updates the statistics. |
| `seedline_track_info` | Top 10, the caller's rank and per-track statistics. |
| `seedline_overview` | Global numbers: online, players, runs, sessions, tracks, active today. |
| `seedline_get_car` | The account's saved car (paint color, finish, booster color) and its revision. |
| `seedline_save_car` | Saves the car after validating its colors and finish; last write wins. |

- **Leaderboards**: one per track, id `track:<ENV>:<SEED>`, authoritative (clients cannot write scores), ascending, `best` operator, score in milliseconds. Created on the first accepted run.
- **Track statistics** (storage `track_stats`, public read): runs, unique players, best time, total time, first and last play.
- **Sessions** (storage `sessions`): one record per app launch with platform, version, start, last seen and duration. Active users come from a presence room (`seedline` chat channel) that the client joins over the WebSocket. Nakama's Lua runtime has no session end event, so duration is derived from the heartbeat.
- **Global counters** are sharded (8 shards) to avoid write contention.

### Validation and abuse protection

A run is rejected unless: seed and environment match strict patterns; time is an integer between 20 s and 1 h; laps equal 3; track length is 1500 to 5000 m; the average speed stays below 85 m/s (the kart tops out at 84 m/s while boosting); splits are strictly increasing, a multiple of 3, and the last one equals the finish time. Each user may submit 30 runs per 10 minutes. Submissions carry a client generated `run_id`, so retries never double count.

This is plausibility checking, not replay verification. A determined cheater can still submit a fast but plausible time. If that matters, upload the recorded inputs and re-simulate on the server.

## Production checklist

1. Change `socket.server_key`, `session.encryption_key`, `session.refresh_encryption_key`, `runtime.http_key`, `console.username`, `console.password` and `console.signing_key`. The defaults are public.
2. Put Nakama behind TLS (reverse proxy) and set `seedline/nakama/ssl=true`, the host and the new server key in `project.godot` (section `[seedline]`). The same values can be overridden at runtime with `SEEDLINE_NAKAMA_ENABLED`, `SEEDLINE_NAKAMA_HOST`, `SEEDLINE_NAKAMA_PORT`, `SEEDLINE_NAKAMA_SSL` and `SEEDLINE_NAKAMA_KEY`.
3. Do not expose the console (7351) publicly.
4. Back up Postgres. Tune `--session.token_expiry_sec` as needed; the client refreshes tokens automatically.
5. Device id authentication is used, so an account lives with the install. Link a social or email identity later if accounts must survive reinstalls.
