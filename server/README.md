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
| `seedline_events` | The current daily and weekly seed challenges: featured seed, end time, top 10 and the caller's rank. |
| `seedline_pp` | The caller's global Performance Points: total, world rank, most valuable tracks and the global top 10. |

- **Leaderboards**: one per track, id `track:<ENV>:<SEED>`, authoritative (clients cannot write scores), ascending, `best` operator, score in milliseconds. Created on the first accepted run.
- **Events** (daily / weekly seed challenges): two authoritative leaderboards `daily` and `weekly` with reset schedules (`0 0 * * *` and `0 0 * * 1`). The competed seed rotates each period and is derived deterministically on the server from the period index (over the client's 16-character seed alphabet), so it is the single source of truth — clients cannot forge "today's" board. An accepted run whose seed matches the current daily/weekly seed is mirrored onto that event board. A `register_leaderboard_reset` hook notifies the top three finishers when a period rolls over.
- **Track statistics** (storage `track_stats`, public read): runs, unique players, best time, total time, first and last play. It also keeps `length_m` and the running sums `sum_logt` / `sum_logt2` over players' **best** log-times, which feed the Performance Points math without scanning the whole leaderboard.
- **Performance Points** (global skill rating, authoritative board `global_pp`, per-user doc `profile/pp`): see the dedicated section below.
- **Race ghosts** (storage `track_ghosts`, public read): one validated best-run path per user and track. Paths are flattened integer `(x decimeters, z decimeters, heading milliradians)` triples sampled at 5 Hz. The server limits paths to 5,000 points and track info returns up to 10 matching paths for the fastest other players, scanning at most 100 leaderboard records. Older leaderboard entries without a saved path are skipped.
- **Sessions** (storage `sessions`): one record per app launch with platform, version, start, last seen and duration. Active users come from a presence room (`seedline` chat channel) that the client joins over the WebSocket. Nakama's Lua runtime has no session end event, so duration is derived from the heartbeat.
- **Global counters** are sharded (8 shards) to avoid write contention.

### Validation and abuse protection

A run is rejected unless: seed and environment match strict patterns; time is an integer between 20 s and 1 h; laps equal 3; track length is 1500 to 5000 m; the average speed stays below 85 m/s (the kart tops out at 84 m/s while boosting); splits are strictly increasing, a multiple of 3, and the last one equals the finish time. Each user may submit 30 runs per 10 minutes. Submissions carry a client generated `run_id`, so retries never double count.

This is plausibility checking, not replay verification. A determined cheater can still submit a fast but plausible time or a fabricated path. If that matters, upload the recorded inputs and re-simulate on the server.

### Performance Points (global skill rating)

With unlimited retries the game is a time-attack, so it uses an osu!/Trackmania-style Performance Points rating. The server is the only source of truth: the client sends only its (validated) time, never any PP. All tuning constants live in the `PP` table at the top of `seedline.lua`.

Per track (judged against the distribution of every player's **best** time):

1. **Log-transform.** Lap times are right-skewed (a hard physical lower bound, a long tail of mistakes), so everything is computed on `t = ln(time_ms)`. `track_stats` keeps `sum_logt` and `sum_logt2` over players' bests, swapping a player's old `ln(T)` for the new one whenever they improve — so the mean and standard deviation are exact without scanning the board.
2. **Bayesian shrinkage.** A seed with only 1–2 players has no trustworthy distribution, so the real stats are blended with `W` (`syn_weight`, default 5) synthetic "par" players. The synthetic mean is a forge-proof par time derived from the validated track length (`total_distance / syn_speed`); the synthetic sigma is `syn_sigma`. `μ_eff = (N·μ_players + W·μ_syn)/(N+W)` (and likewise for σ). At `N=1` you are judged mostly against the generator's physics; by `N≈20` the real players dominate.
3. **Z → track PP.** `Z = (μ_eff − ln(time)) / σ_eff`, clamped to `[z_min, z_max] = [−2, +4]`, then `PP_track = max(0, base·(1 + 0.5·Z)) · C`, where `base = 100` (an average run), a `+4σ` world record tops out near 300, and `C = N/(N+conf_k)` caps PP until a few players have challenged the seed (so solo seed-fishing can't farm a huge score).
4. **Global aggregation.** A player's `profile/pp` doc stores their best `PP_track` per track (top `keep` retained). The global total sorts them high→low and applies a `0.95^(i−1)` geometric decay (the series converges to ×20, so ~200-PP top tracks approach a 4000 ceiling). It is written to the authoritative descending `global_pp` board as `round(PP × 100)`.

A run only moves a player's PP when it is a **new personal best**; the just-scored track is recomputed against fresh stats, while their other tracks refresh the next time they race them (PP there can drift slightly as new players join). `syn_speed`/`syn_sigma` are priors — calibrate them against real data after launch. PP state added to pre-existing tracks starts from the first new best recorded after deploy.

## Production checklist

1. Change `socket.server_key`, `session.encryption_key`, `session.refresh_encryption_key`, `runtime.http_key`, `console.username`, `console.password` and `console.signing_key`. The defaults are public.
2. Put Nakama behind TLS (reverse proxy) and set `seedline/nakama/ssl=true`, the host and the new server key in `project.godot` (section `[seedline]`). The same values can be overridden at runtime with `SEEDLINE_NAKAMA_ENABLED`, `SEEDLINE_NAKAMA_HOST`, `SEEDLINE_NAKAMA_PORT`, `SEEDLINE_NAKAMA_SSL` and `SEEDLINE_NAKAMA_KEY`.
3. Do not expose the console (7351) publicly.
4. Back up Postgres. Tune `--session.token_expiry_sec` as needed; the client refreshes tokens automatically.
5. Device id authentication is used, so an account lives with the install. Link a social or email identity later if accounts must survive reinstalls.
