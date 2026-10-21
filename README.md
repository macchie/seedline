# Seedline — Godot 4.7 port

A seeded time-trial racer: every code is a track. This is a full port of the three.js web build to
**Godot 4.7.2 (stable)**, written in GDScript and built entirely in code (the only scene is `scenes/main.tscn`).

## Open and run

1. Open Godot 4.7.x → **Import** → pick this folder's `project.godot`.
2. Press **F5**. The project uses the **Compatibility** renderer (OpenGL 3 / WebGL 2) so it behaves the same on
   desktop, Android, iOS and the web.

The first import takes a few seconds while Godot imports the fonts.

## What carries over 1:1

- **Seeds and tracks.** Same hash, same mulberry32 stream, same float32 storage and JavaScript rounding, so a code
  produces the same track as the web build: the same layout, length, checkpoints, bridges, rivers, name and medal
  times. This was checked against the web generator on 45 seeds and every one matched.
- **World placement.** Scenery is drawn from the same `seed#world` stream in the same order, so rocks, trees, houses,
  temples, boats and the rest land in the same spots.
- **Driving.** The same fixed 120 Hz kart model (snappy steering, hop-drift, three-level mini-turbo, perfect start),
  the same collisions and the same checkpoint and lap rules. Lap times, medals and ghosts are therefore comparable.
- **Look.** Three-band toon lighting with shadows, hemisphere ambient, rim light, ink outlines, drifting cloud shadows,
  tilt-shift, bloom, the per-world colour grade, vignette and grain. The water shader has foam, ripples and river
  flow; there is also lava, weather (rain, drizzle, snow, dust, embers), smoke and splashes.
- **Interface.** The menu sheet (Track, Garage, Saved and Options tabs), race HUD with minimap, splits and
  countdown, the pause and finish cards, toasts and the loading screen. The layout follows the same breakpoints:
  a bottom sheet on phones, a left rail on short landscape screens and on desktop.
- **Controls.** Every action is rebindable (two slots each, keyboard and gamepad) under Options → Controls, and the
  bindings persist in `user://seedline.json`.
  - Keyboard (defaults): arrows or WASD; Space or Shift to boost; Backspace to respawn; R or Enter to restart; Esc or P
    to pause.
  - Gamepad (defaults): RT gas, LT or B brake, left stick or D-pad steer, A / Cross boost, Y / Triangle respawn,
    Start pause.
  - Touch: the hidden-slider steering wheel plus the BOOST, BRAKE and GAS pads, with a left- or right-thumb option.
- **Boost.** A Rocket-League-style gauge: 100 capacity, 2/3 full at the start of every run, drained while boost is held.
  Big orange pads (+100, 10 s respawn) and small cyan pads (+12, 4 s respawn) are placed from the seed with their own
  RNG stream, so the same seed always gives the same pads and the track itself is unchanged. Medal times are still
  computed without boost.
- **Saved data.** Options, paint, saved tracks, personal bests and ghosts are kept under the web build's keys, in
  `user://seedline.json`.
- **Sound.** The synthesised engine, skid and wind loops, and the beeps, chimes, thuds, splashes and whooshes are
  generated at runtime. No audio files are shipped.

## Notes on the port

- **Rendering.** three.js r128 lights in display space with no colour management. Godot's Compatibility renderer
  converts colours to linear and back, so the shaders do their lighting and fog in display space (see
  `shaders/common.gdshaderinc`) and hand Godot the final colour. Shadows still come from the engine's directional
  light.
- **Post-processing.** FXAA, bloom and the grade run in one canvas shader (`shaders/grade.gdshader`), because the
  Compatibility renderer has no screen-space anti-aliasing. Ink outlines and cloud shadows are a full-screen pass in
  the 3D scene that draws before water and particles, so water is not outlined.
- **Battery saver** turns off shadows and post-processing and lowers the render resolution, as on the web. Adaptive
  resolution also drops the 3D resolution when the frame rate falls below 48 fps.
- **Fonts.** Saira, Saira Condensed and JetBrains Mono are included (OFL). Saira Condensed has no italic, so the
  italic is slanted in code. A few symbols (★ ✕ ⌫ ← → ↔) come from small Noto subsets.
- **Night mode** is ported but switched off, as in the web build (`Envs.NIGHT_ENABLED`).
- **World building** runs on worker threads (terrain heights, colours and distance fields). A track takes roughly
  0.3–1 s to build on a desktop.

## Layout

```
scripts/core    utilities, seeded RNG, value noise, environments, persistence
scripts/track   track generator (genTrack) and track data
scripts/sim     car physics (stepCar) and medal times
scripts/render  geometry builders (three.js primitives), materials, procedural textures
scripts/world   world builder, props for the nine places, car model, effects
scripts/audio   synthesised sound
scripts/net     Nakama client (auth, presence, leaderboards, offline run queue)
scripts/ui      menu, HUD, touch controls and widgets
shaders         toon, PBR, water, lava, weather, sprites, ink and clouds, grade
server          Nakama Lua module and deploy script, see server/README.md
tools           developer scripts (screenshots, benchmarks, track checksums); not needed to play
```

## Online (Nakama)

Leaderboards per track, track statistics, sessions and the online count come from a Nakama server
(default `127.0.0.1:7350`, configured in the `[seedline]` section of `project.godot`).
See [server/README.md](server/README.md) for deployment and production notes. The game works offline.

## Exporting

Use **Project → Export** with the standard templates for 4.7.2. For the web, the single-threaded export works,
because world building falls back to the main thread when threads are not available.
