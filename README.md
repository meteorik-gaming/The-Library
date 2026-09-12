# The Library

A free-to-use, SFW catalog of generic, reusable 2D game systems built in
Godot 4.7 — menus, screen flow, placeholder movement/room mechanics, and dev
tooling, meant to be dropped into other projects rather than played as a game
in its own right.

Everything here is intentionally generic: no story, no characters, no
identifiable IP — just mechanics and placeholder visuals. See
[SYSTEMS.md](SYSTEMS.md) for the full, current list of what's implemented.

## Requirements

- [Godot 4.7](https://godotengine.org) (stable)

## Running it

Open the project in Godot 4.7 and press F5, or run a specific scene directly:

```
godot --path . res://scenes/launch_screen/launch_screen.tscn
```

## Tests

`tests/` holds a windowed screenshot/smoke-test harness (needs a real window
to render — `--headless` won't capture a viewport texture). Each test script
starts with a comment documenting how to run it, e.g.:

```
godot --path . res://tests/screens_smoke_test.tscn
godot --path . res://tests/worlds_smoke_test.tscn
```

## License

MIT — see [LICENSE](LICENSE). Bundled third-party components (Pixelify Sans,
Dialogic) keep their own licenses; see the LICENSE file for details.
