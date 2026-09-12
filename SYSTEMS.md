# Systems in The Library

A running catalog of the reusable, generic game mechanics built in this
repo. The Library exists to prototype systems as a standalone, free-to-use
catalog — this file tracks what exists, where it lives, and its status.

## UI / flow

- **Launch screen** — `scenes/launch_screen/` — splash with the project name;
  auto-advances after ~2s, no skip-on-input.
- **Main menu** — `scenes/main_menu/` — Jugar / Opciones / Salir.
- **Overlay screen system** — `scenes/screens/screen_base.gd` (`ScreenBase`) +
  `scenes/screens/ui_kit.gd` (`UiKit`) — generic dimmed-backdrop + centered
  panel chrome for any secondary screen. `ScreenBase.open()` adds a screen on
  top of whatever's current; screens emit `closed` (or their own signal) when
  done.
- **Choose World Type screen** — `scenes/screens/choose_world_type_screen.gd`
  — card-picker pattern (locked vs. selectable cards). Currently offers
  Top-Down and Isometric.
- **Options screen** — `scenes/screens/options_screen.gd` — master volume +
  fullscreen toggle. Applies live; **not persisted to disk yet**.

## Player, NPCs & worlds

- **Shared player controller** — `scenes/player/player.gd`/`.tscn` — free-roam
  `CharacterBody2D` with corner-assist movement (softens tight-corner turns
  so they don't need pixel-precise alignment), driven by the
  `move_left/right/up/down` input actions. Used by Top-Down. Only the player
  moves this way (vector-summed, free-roam) — NPCs are always grid-only, see
  below.
- **Top-Down world** — `scenes/worlds/topdown_world/` — flat-color 10x10
  walled room (no tiles/textures), built from plain `Polygon2D` +
  `StaticBody2D` walls. Free-roam movement (see above).
- **Isometric world** — `scenes/worlds/isometric_world/` — same 10x10
  walled-room spec, built procedurally (`_build_room()` at runtime) on an
  isometric `TileSet` (`assets/tiles/iso_tileset.tres`, 64x32 diamond tiles).
  Two `TileMapLayer`s (floor, Y-sorted walls). Player movement is free/
  continuous like Top-Down (see below); the NPC is grid-stepped.
- **Isometric player movement** — `scenes/worlds/isometric_world/iso_player_mover.gd`
  (`IsoPlayerMover`) — free continuous `CharacterBody2D` movement (same
  corner-assist idea as the shared Player), except WASD is projected onto
  the room's own screen-diagonal axes instead of straight screen up/down/
  left/right, so it still reads as N/S/E/W on the diamond while keeping
  normal vector-summed blending (e.g. holding two keys together blends
  smoothly into a third direction, it doesn't snap to one axis). The room
  script empirically derives which grid delta lands in which screen
  quadrant from the TileSet's actual isometric projection
  (`_compute_screen_axes()` in `isometric_world.gd`), rather than assuming
  Godot's `tile_layout` sign convention. Result: W = north = screen
  top-left, S = south = screen bottom-right, A = west = screen bottom-left,
  D = east = screen top-right.
- **Grid-stepped actor base** — `scenes/npc/grid_actor.gd` (`GridActor`) —
  one-cell-at-a-time tweened movement for anything that should snap to a
  grid, room-shape-agnostic: takes a `cell_to_world: Callable` so the same
  class drives NPCs on both the isometric room's diamond grid
  (`TileMapLayer.map_to_local`) and Top-Down's plain square grid
  (`cell * CELL_SIZE`). NPCs are **always** grid-only — never free-roam,
  unlike the player.
- **Generic NPC** — `scenes/npc/npc.gd`/`.tscn` — extends `GridActor`,
  patrols back and forth between two grid cells (`configure_at_cells()`),
  pathfinding with Godot's built-in `AStarGrid2D` (real pathfinding, not
  just "step toward the target" — each room builds one shared nav grid,
  see `_build_nav_grid()` in the room scripts) and pausing at each end.
  `AnchorA`/`AnchorB` markers are repositioned to match for inspection. No
  schedule/time-of-day routing yet (just the 2 fixed anchors). Reacts to the
  player entering its `ProximityArea` with a small squash tween. One
  instance in each world (isometric: diamond grid, top-down: square grid) —
  same scene, different `cell_to_world` + nav grid.
- **Character sprites** — `scenes/common/character_sprite.gd`
  (`CharacterSprite`) + `scenes/common/directional_facing.gd`
  (`DirectionalFacing`) — directional `AnimatedSprite2D` driven by the
  `Template-<AnimationType>-Sheet.png` naming convention, with a tint
  (`modulate`) so one sheet can cover many recolors. `DirectionalFacing`
  picks which movement key "wins" for the player's facing/animation when
  several are held (greatest input strength, tied broken by whichever was
  pressed first) — NPCs don't need it, their facing is just whatever
  direction they're currently stepping in. **Full spec (row layout, per-world
  direction mapping, naming rules) is in
  [assets/characters/CHARACTER_SPRITES.md](assets/characters/CHARACTER_SPRITES.md)
  — read that before touching this system.** Current tints: Player blue
  (`Color(0.498, 0.839, 1, 1)`), NPC orange (`Color(1, 0.65, 0.3, 1)`).
- **Placeholder iso tile generator** — `tools/gen_iso_placeholder_tiles.gd` —
  `@tool` `EditorScript` that (re)draws the flat-colour diamond floor/wall
  tiles (File > Run in the editor). Swap for real pixel art later.

## World chrome (day/night, devtools, keybinds)

`scenes/world_chrome/world_chrome.tscn` bundles the systems below into one
instanceable scene — both worlds include it as a child:

- **Day/night ambient lighting** — `day_night_lighting.gd` on a
  `CanvasModulate`, driven by `GameClock`. Samples `day_night_gradient.tres`
  (offset 0..1 = 00:00..24:00) every frame for a continuous colour fade;
  also eases a screen-edge vignette (`atmosphere_vignette.gdshader`) and
  fades any `PointLight2D`s down during the day. Ships with a built-in
  fallback gradient if none is assigned. Rooms start at 5:00 AM (dawn-ish,
  intentionally a bit dark) — use the devtools hour/day controls below to
  jump forward.
- **GameClock** (`autoload/game_clock.gd`) — continuous real-time day clock
  in in-game hours (20h/day, 5:00 AM start), pauses automatically while a
  Dialogic timeline is running. Devtool hooks: `add_hours()`, `add_days()`,
  `cycle_speed()` (1x/2x/4x/0.5x).
- **Clock HUD** — `clock_hud.gd`, always-visible "Day N (weekday) / HH:MM
  (day|night)" readout, top-left. Hour/day/speed control buttons only show
  while devtools mode is on.
- **DevTools** (`autoload/dev_tools.gd`) — global `enabled`/`toggled` state,
  flipped by the `toggle_devtools` action (Q). Anything can react to
  `toggled` to show/hide its own debug visuals.
- **Devtools grid overlay** — `devtools_overlay.gd`, Q-toggled spreadsheet-
  style world grid (column letters, row numbers via `GridRef`) for
  eyeballing coordinates when placing things.
- **GridRef** (`autoload/grid_ref.gd`) — spreadsheet-style coordinate helper
  (`cell_to_label`, `ref_to_cell`, `ref_to_world`, `rect_from_refs`) so code
  can refer to world positions the way you'd read them off the grid overlay
  (e.g. `"C3"`).
- **Keybinds** (`autoload/keybinds.gd`) + **Keybinds panel**
  (`keybinds_panel.gd`, E-toggled via `toggle_stats`) — live rebindable
  action list (move_* , toggle_devtools, toggle_stats, dialogic_default_action),
  conflict highlighting, save/reset to `user://keybinds.cfg`. Add an entry to
  `Keybinds.REBINDABLE_BINDINGS` (+ a label in `keybinds_panel.gd`) and it
  shows up automatically.

## Dev tooling

- **Screenshot/smoke-test harness** — `tests/screens_smoke_test.*` (UI
  screens) and `tests/worlds_smoke_test.*` (world scenes — real movement,
  wall-collision, iso screen-direction, NPC-autopilot, and devtools/keybinds
  toggle checks, not just a screenshot) — each test script is headed with a
  `<godot> res://tests/x.tscn (windowed; renders)` comment documenting how to
  invoke it (needs a real window to capture `get_viewport().get_texture()`;
  `--headless` won't render). Screenshots land in `tests/screenshots/`.
  Note: `Input.action_press()` only sets polling state and won't reach
  `_unhandled_input()`-based code (DevTools, Keybinds) — use a real
  `InputEventAction` round-trip via `Input.parse_input_event()` instead (see
  `_fire_action()` in `worlds_smoke_test.gd`).

## Typography & theme

- **Pixelify Sans** — `assets/typography/` — variable + static weights,
  [SIL Open Font License](assets/typography/OFL.txt), applied as the
  project's default `Theme` (`assets/typography/ui_theme.tres`).

## Third-party

- **[Dialogic](https://github.com/dialogic-godot/dialogic)**
  (`addons/dialogic/`, v2.0-Alpha-20, MIT license) — installed and enabled,
  autoloaded as `Dialogic`. Not wired into any scene/content yet beyond
  GameClock pausing on its timeline signals — installed ahead of need for
  future dialogue-driven systems.
- **[Character Templates Pack](https://erisesra.itch.io/character-templates-pack)**
  by Eris Esra (`assets/characters/Template-*-Sheet.png`) — the placeholder
  character art used by Player/NPC (see Character sprites above). Its
  license only covers finished work built with it: the templates themselves
  may not be resold/redistributed as a standalone pack. See
  [LICENSE](LICENSE) for the full terms and required credit.

## Deliberately deferred

- Isometric world's wall/floor art is placeholder-only; real pixel art is a
  separate pass.
- Options screen has no save/load — add a `ConfigFile`-backed settings
  system when it's actually needed.
- No save/load system for gameplay state yet (GameClock has no
  save/load-state methods either — add them alongside the save system).
- NPC has no schedule/time-of-day routing yet, just the 2 fixed anchors.
