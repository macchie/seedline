# Seedline

Seedline is a deterministic time-trial racer built with **Godot 4.7.2**. Each 16-character seed
generates a repeatable circuit. Race it, record a best, then share the seed and chase the time.

## Current game

- **Seed-built tracks:** twelve environments, generated scenery, checkpoints, weather, terrain, boost
  pads, and a cached minimap preview for each saved track.
- **Precision driving:** fixed 120 Hz car simulation, three-lap races, drift and boost, track
  boundaries, and ordered anti-cut gates.
- **Runs and replays:** personal bests, lap splits, saved and recently played tracks, and recorded
  best-run replays that replay the original inputs through normal physics and boost/pickup logic.
  Older runs without input recordings can be viewed as route previews.
- **Ghost comparisons:** race alongside your own best and up to ten available opponents on the same
  seed. Pin and cycle through saved rival ghosts from the leaderboard, with a finish-time comparison
  against your selected racer.
- **Progression:** daily and weekly seed challenges award event participation and podium badges.
  Account progression tracks race, exploration, and environment milestones, alongside monthly
  seasonal PP standings.
- **Garage and options:** customize car paint and booster color; adjust graphics and rebind keyboard
  and gamepad controls. Touch controls adapt for phones and tablets.
- **Responsive interface:** Drive, Garage, Tracks (Saved and Last played), and Options are designed
  for desktop, tablet, and mobile, with keyboard, gamepad, and touch navigation.
- **Sound and presentation:** procedural 3D environments, toon/PBR shaders, minimaps, boost and
  exhaust effects, weather, synthesized engine and race sounds, and race HUD.

## Godot and graphics

The game is written in GDScript and builds its tracks, world props, car, effects, and UI at runtime.
It uses Godot's **Compatibility renderer** (OpenGL 3 / WebGL 2) and supports keyboard, gamepad, and
touch input. Local settings, car customization, saved tracks, personal bests, and replay data are
stored in `user://seedline.json`.

Run the project with Godot 4.7.x:

```sh
make godot
```

## Online services with Nakama

The Nakama Lua runtime and Postgres backend provide per-track and event leaderboards, global and
monthly seasonal Performance Points, account progression and achievements, online presence,
account-linked car settings, and stored opponent ghost paths. Runs are validated and idempotent;
when the service is unavailable, the game remains playable offline and queues finished runs for
retry.

Ghost paths are recorded on newly submitted runs. Older leaderboard results without a stored path
remain on the leaderboard but are not available as opponent ghosts. See
[server/README.md](server/README.md) for the RPCs, local deployment, validation, and production
configuration.

## Website

The responsive game landing page is a standalone Vite application in [website/](website/). Its
screenshots are captures from the running Godot game. Official release downloads have not been
published; the platform cards remain disabled until verified builds are available.

```sh
make website-install
make website
```

Build and preview the static site with:

```sh
make website-build
make website-preview
```

## Make targets

Run `make help` to list the available commands. `GODOT` and `NPM` can be overridden when the
executables are not on `PATH`, for example `make godot GODOT=/path/to/godot`.

## Repository layout

```text
scenes/       Main Godot scene
scripts/      Track generation, car simulation, networking, UI, and world rendering
shaders/      World, car, weather, and post-processing shaders
server/       Nakama Lua runtime and local deployment files
website/      Vite landing page and captured game screenshots
tools/        Track, replay, screenshot, and performance helpers
```

The `server/` and `website/` folders contain `.gdignore` markers and are excluded from Godot's
resource scan and project imports.
