# Changelog

Not strict semver — versioning here tracks how The Library grows:
**+0.1** per new system added, **+0.0.1** per bugfix or small step within an
existing system. There was never a formal release before this, so the
current, already-substantial state starts at **1.0.0** rather than 0.1.0.

## [1.1.0] - 2026-09-12

### Added
- Shared tabbed Pausa/Inventario/Keybinds/Opciones menu
  (`scenes/screens/tab_strip.gd`/`pause_menu.gd`) — ESC opens on Pausa, E
  opens on Inventario, every tab reachable from either entry point. Opening
  it is a real pause (`get_tree().paused = true`); the Keybinds panel now
  lives as a tab instead of its own E-toggled overlay
- Character rotate preview in the Inventario tab — plays the `Rotate` sheet
  with ◀/⏸/▶ controls: flips spin direction while playing, steps one frame
  at a time while paused
- Options persistence (`autoload/options_store.gd`) — volume/fullscreen
  saved to `user://options.cfg`, applied automatically at boot
- Main Menu hover feedback (`UiKit.add_hover_scale()`) — subtle scale-up +
  glow on any button
- Click-to-attack (left click) / click-to-interact (right click) — plays the
  `Attack`/`Interact` sheets for one timed playthrough, facing the
  character's current direction, in both worlds

### Fixed
- Both worlds' decorative `Background/Void` `ColorRect` defaulted to
  `mouse_filter = STOP` and silently swallowed every click in the game,
  game-wide, since it was first added — surfaced while wiring up
  click-to-attack
- `PauseMenu`'s backdrop/panel weren't actually blocking/allowing input in
  sync with the menu's own visibility toggle
- Inventario's character preview showing `Idle` instead of `Rotate` — it was
  configured before its subtree entered the scene tree, so the animation
  switch silently no-op'd before `_ready()`'s own default overwrote it

## [1.0.0] - 2026-09-12

The first versioned snapshot — everything built so far. See
[SYSTEMS.md](SYSTEMS.md) for the living, detailed catalog of what exists and
where; this file is the historical record of how it got there.

### Added
- Launch screen, Main menu, and the overlay screen system
  (`ScreenBase`/`UiKit`) any secondary screen builds on
- Choose World Type screen (Top-Down / Isometric picker) and Options screen
  (volume, fullscreen)
- Shared free-roam Player controller with corner-assist movement
- Top-Down world: flat-color 10x10 walled room
- Isometric world: a 10x10 walled room built procedurally on an isometric
  `TileSet`, with WASD projected onto the room's own screen-diagonal axes
  (still free/continuous, vector-summed, like Top-Down)
- Generic grid-stepped NPC (`GridActor` + `AStarGrid2D` pathfinding) in both
  worlds — NPCs are grid-only, always; only the player free-roams
- World chrome bundle: day/night ambient lighting + vignette (`GameClock`),
  a Q-toggled devtools grid overlay, an E-toggled rebindable keybinds panel
- Directional character sprites (`CharacterSprite`/`DirectionalFacing`)
  built on the Character Templates Pack, with tint and a documented sheet
  convention (`assets/characters/CHARACTER_SPRITES.md`), displayed at 2x
- Windowed screenshot/smoke-test harness, plus a GIF recorder dev tool for
  bugs a static screenshot can't catch
- Pixelify Sans typography; Dialogic addon installed ahead of need
- Published publicly as "The Library" under a custom no-resale license

### Fixed
- GDScript static-type-inference errors on `InputEvent` property access
- A signal connected via inline lambda to a persistent autoload leaking
  across scene reloads (crashed on the 2nd+ world visited)
- The movement hint label rendering behind the room instead of in front
- NPC losing its 2x display scale whenever its player-proximity reaction
  fired (a tween settling to a hardcoded `Vector2.ONE` instead of the
  actual display scale)
