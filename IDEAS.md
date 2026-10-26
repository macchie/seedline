
2. Graphics / visual polish
Boost feel: you already do a FOV kick; add a subtle speed-lines/chromatic-aberration pulse and light motion blur gated behind a reduce-motion toggle.
Finish night mode. NIGHT_ENABLED=false (envs.gd:4) — the whole day/dusk/night variant system is built and shipped-off. That's free content.

3. UI / UX
Split ui.gd into ui_menu, ui_options, ui_finish, ui_leaderboards, ui_tracks. It's the #1 maintainability risk and makes everything else slower to change.

4. Gameplay / feel
The fixed-step deterministic sim (car_sim.gd) is a real strength — it's what makes ghosts/replays reproducible. Lean into it.
Finish/enable drift (DRIFT_ENABLED flag, mini-turbo tiers already coded in car_sim) — it's largely built.
Rival tuning: rival_ghost_fleet exists — add selectable rival difficulty / "beat your friend's ghost" flows.

5. Audio
Spatialize rival engines and boost pads (AudioStreamPlayer3D) for positional cues.

6. Networking / backend / security (highest-priority cheap win)
project.godot ships dev config: nakama/host="192.168.1.123" (a committed LAN IP!), ssl=false, server_key="defaultkey" (project.godot). Any release build points at your dev machine over plaintext. Make host/SSL/key build- or env-driven (the env overrides already exist in _load_config) and default release to a real host + SSL + non-default key.
The server already does length/par validation and authoritative leaderboards — good anti-cheat foundation to keep building on.

7. Content & progression / retention
Daily/weekly events, seasons (season_pp), and the new global-ranking medals are a solid loop. Build on it: cosmetic unlocks tied to PP/season, more car models, shareable replay links (you have deterministic ghosts — a replay is just a seed + inputs), and a "track of the day" push.

8. Code architecture & maintainability
Several files read as literal 1:1 web ports. Where stable, migrate static UI to .tscn scenes for editor tooling and faster instancing.

9. Testing / tooling
You have tools/test_tracks.gd, test_replay_ghosts.gd, test_rival_ghost_fleet.gd — wire them into headless CI (godot --headless --script …). The deterministic sim makes this high-value and cheap: a replay-reproduction regression test alone protects your whole ghost/leaderboard system.

10. Accessibility
Reduce-motion toggle (disables camera shake, FOV kick, weather intensity) — easy and impactful.
Colorblind-safe palettes for env accents and medal colors; UI scale; controls are already remappable (good).

11. Platform
Mobile: adaptive resolution (perf.scale) already exists — surface it + add haptics. Web: your new Store flusher already degrades gracefully to single-thread. Desktop: gamepad bindings exist — add rumble.
