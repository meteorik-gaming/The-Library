# Changelog

Not strict semver — versioning here tracks how The Library grows:
**+0.1** per new system added, **+0.0.1** per bugfix or small step within an
existing system. There was never a formal release before this, so the
current, already-substantial state starts at **1.0.0** rather than 0.1.0.

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
