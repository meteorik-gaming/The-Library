# Character Sprites Key

The convention every character spritesheet in this folder follows, and how
`scenes/common/character_sprite.gd` (`CharacterSprite`) reads it. Keep this
file in sync if the convention changes — it's the source of truth for both
the code and anyone adding new character art to The Library.

## File naming

```
<identifier>-<AnimationType>-Sheet.png
```

- `identifier` — the character's name. Can be anything, including its own
  hyphens (e.g. `Forest-Slime-King-Idle-Sheet.png` has identifier
  `Forest-Slime-King`). Parsing anchors from the **end** of the filename, so
  the identifier is "everything before the fixed `-AnimationType-Sheet.png`
  suffix."
- `AnimationType` — one of a fixed, expandable list (current set below).
  Case-sensitive, must match exactly.
- The placeholder character shipped in this repo uses identifier `Template`
  (e.g. `Template-Walk-Sheet.png`).

### Current AnimationTypes

`Attack`, `Idle`, `Interact`, `Jump`, `Rotate`, `Run`, `Walk`

This list can grow (ask, don't just add a type and expect it to render —
`CharacterSprite.ANIMATION_TYPES` needs the new entry too). A character
doesn't need every type; `CharacterSprite` only builds animations for
sheets that actually exist for that identifier.

## Sheet layout

Every frame is **32x32px** in the source file. `CharacterSprite` displays it
at **2x** (`DISPLAY_SCALE`) with nearest-neighbor filtering (no
interpolation) so every source pixel becomes a crisp 2x2 block on screen —
change `DISPLAY_SCALE` there if the target size ever needs to move. Columns
are animation frames (left to right); frame count varies per animation
(e.g. Idle might be 4 frames, Attack 7) but every animation **loops**.

Rows (top to bottom) are facing directions — **5 rows**, except `Rotate`
(see below):

| Row | Name            |
|----:|-----------------|
|   0 | Front           |
|   1 | Diagonal Front  |
|   2 | Side            |
|   3 | Diagonal Back   |
|   4 | Back            |

### `Rotate` is different

`Rotate` has no directional rows — it's a single row of frames meant for
character-select screens / inventory previews (spinning the character in
place), not tied to any movement key. `CharacterSprite` treats it as one
flat animation, not five.

## Which row plays for which key, per world type

The same 5 rows serve **both** room types in this repo, because Top-Down
only ever needs 3 of them (no diagonals) and Isometric only needs the other
2 (nothing but diagonals — see [[Isometric grid movement]] in `SYSTEMS.md`
for why W/A/S/D read as screen diagonals there). A row without a natural
mirror gets flipped horizontally (`flip_h`) for the opposite key instead of
needing a 6th/7th row:

| Direction (W/A/S/D) | Top-Down row      | Isometric row            |
|----------------------|-------------------|---------------------------|
| S (south)             | Front              | Diagonal Front            |
| A (west)              | Side, flipped      | Diagonal Front, flipped   |
| D (east)              | Side               | Diagonal Back             |
| W (north)             | Back               | Diagonal Back, flipped    |

This is exactly `CharacterSprite.TOPDOWN_ROW_MAP` / `ISO_ROW_MAP` in code —
if you change this table, change those too.

## Picking an animation when input sums to a diagonal

The player can hold multiple movement keys at once (see `DirectionalFacing`
in `scenes/common/directional_facing.gd`) — free continuous movement always
vector-sums, per Alan's rule that **only the player** moves this way (NPCs
are grid-only, pathfinding with `AStarGrid2D` — see `scenes/npc/grid_actor.gd`
and `npc.gd`). Since a sprite can only face/animate one direction at a time,
the direction actually shown when multiple keys are held is:

1. Whichever key has the **greatest input strength** (relevant for analog
   input; keyboard presses are all strength 1.0).
2. On a tie, whichever of the currently-held keys was **pressed first**
   (i.e. has been held the longest continuously).

## Tint

Characters are meant to be recolorable without new art — e.g. many slime
colors from one sheet — via `CharacterSprite.tint` (`Color`), applied as
`modulate`. Current placeholders:

- **Player** — blue, `Color(0.498, 0.839, 1, 1)` (matches the UI accent
  color used elsewhere).
- **NPC** — orange, `Color(1, 0.65, 0.3, 1)`.

## Movement state -> AnimationType

Right now `CharacterSprite` is only driven for `Idle` (not moving) and
`Walk` (moving) by Player/IsoPlayerMover/NPC. `Attack`/`Interact`/`Jump`/
`Run`/`Rotate` are sliced and ready to use (`sprite.play(animation_type,
direction)`-equivalent — see `_play()`) whenever a system that needs them
gets built.
