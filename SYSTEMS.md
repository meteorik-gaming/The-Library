# Systems in The Library

A running catalog of the reusable, generic game mechanics built in this
repo. The Library exists to prototype systems as a standalone, free-to-use
catalog — this file tracks what exists, where it lives, and its status.

## UI / flow

- **Launch screen** — `scenes/launch_screen/` — splash with the project name;
  auto-advances after 2.5s or on any key/click.
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

## Player & worlds

- **Shared player controller** — `scenes/player/player.gd`/`.tscn` —
  `CharacterBody2D` with corner-assist movement (softens tight-corner turns
  so they don't need pixel-precise alignment), driven by the
  `move_left/right/up/down` input actions. No walk-cycle art yet, so it's
  just a placeholder square — one scene, instanced by every world.
- **Top-Down world** — `scenes/worlds/topdown_world/` — flat-color 10x10
  walled room (no tiles/textures), built from plain `Polygon2D` +
  `StaticBody2D` walls.
- **Isometric world** — `scenes/worlds/isometric_world/` — same 10x10
  walled-room spec, built procedurally (`_build_room()` at runtime) on an
  isometric `TileSet` (`assets/tiles/iso_tileset.tres`, 64x32 diamond tiles).
  Two `TileMapLayer`s (floor, Y-sorted walls).
- **Placeholder iso tile generator** — `tools/gen_iso_placeholder_tiles.gd` —
  `@tool` `EditorScript` that (re)draws the flat-colour diamond floor/wall
  tiles (File > Run in the editor). Swap for real pixel art later.

## Dev tooling

- **Screenshot/smoke-test harness** — `tests/screens_smoke_test.*` (UI
  screens) and `tests/worlds_smoke_test.*` (world scenes, incl. a real
  movement + wall-collision check, not just a screenshot) — each test script
  is headed with a `<godot> res://tests/x.tscn (windowed; renders)` comment
  documenting how to invoke it (needs a real window to capture
  `get_viewport().get_texture()`; `--headless` won't render). Screenshots
  land in `tests/screenshots/`.

## Typography & theme

- **Pixelify Sans** — `assets/typography/` — variable + static weights,
  [SIL Open Font License](assets/typography/OFL.txt), applied as the
  project's default `Theme` (`assets/typography/ui_theme.tres`).

## Third-party

- **[Dialogic](https://github.com/dialogic-godot/dialogic)**
  (`addons/dialogic/`, v2.0-Alpha-20, MIT license) — installed and enabled,
  autoloaded as `Dialogic`. Not wired into any scene/content yet — installed
  ahead of need for future dialogue-driven systems.
- **[Character Templates Pack](https://erisesra.itch.io/character-templates-pack)**
  by Eris Esra — reserved for future placeholder character art (not added to
  the repo yet). Its license only covers finished work built with it: the
  templates themselves may not be resold/redistributed as a standalone pack.
  See [LICENSE](LICENSE) for the full terms and required credit.

## Deliberately deferred

- Isometric world's wall/floor art is placeholder-only; real pixel art is a
  separate pass.
- Options screen has no save/load — add a `ConfigFile`-backed settings
  system when it's actually needed.
- No save/load system for gameplay state yet.
