# DoodadRenderManager — Implementation Plan

## 1. Objective

Implement a pure in-game JASS/vJASS `DoodadRenderManager` that reduces rendering load from selected preplaced doodad types by hiding doodads outside a configurable camera-centered render area.

The system must work with the existing map as-is:

- No Python or external preprocessing.
- No parsing of `war3map.doo`.
- No conversion of doodads to destructables.
- No re-insertion of the existing ~50,000 doodads in World Editor.
- No per-instance doodad handles or registration.
- No modification to the doodad placement workflow.
- Only selected doodad **types/rawcodes** are managed.
- Existing destructable hiding functionality remains unchanged.

The implementation should follow the same high-level camera-grid concept already used by:

`_CoreSystems/Imported/DestructibleHider.j`

---

# 2. Core Warcraft III Limitation

JASS cannot enumerate doodads or obtain a handle to an individual doodad.

Therefore this cannot be implemented like `DestructableHider`, which can:

1. enumerate destructables,
2. register their handles into spatial tiles,
3. call `ShowDestructable()` on individual objects.

For doodads, the usable native interface is instead:

```jass
native SetDoodadAnimation takes real x, real y, real radius, integer doodadID, boolean nearestOnly, string animName, boolean animRandom returns nothing
native SetDoodadAnimationRect takes rect r, integer doodadID, string animName, boolean animRandom returns nothing
```

Using:

```jass
"hide"
"show"
```

allows already-placed doodads of a specific rawcode inside an area to be visually hidden or shown.

Therefore the architecture must be:

```text
camera position
      |
      v
camera grid cell
      |
      v
determine entering/leaving render regions
      |
      v
SetDoodadAnimationRect(...)
      |
      v
selected preplaced doodad types hidden/shown
```

No knowledge of the individual 50,000 doodads is required.

---

# 3. Proposed Architecture

Create:

```text
_CoreSystems/Imported/DoodadRenderManager.j
```

or, if this is considered a project-owned system rather than imported code:

```text
_CoreSystems/DoodadRenderManager.j
```

Recommended library structure:

```jass
library DoodadRenderManager initializer init
```

The manager owns:

- camera polling timer,
- map dimensions,
- grid geometry,
- currently active camera cell,
- one reusable temporary `rect`,
- list of managed doodad rawcodes,
- render distance/radius for each managed rawcode,
- initialization hide/show pass.

It does **not** store:

- doodad instances,
- doodad coordinates,
- doodad handles,
- one rect per cell,
- one entry per placed doodad.

Memory consumption therefore depends on the number of managed doodad **types**, not the number of placed doodads.

---

# 4. Reuse Existing DestructableHider Geometry

Current `DestructableHider.j` uses approximately:

```jass
INTERVAL       = 0.2
DRAW_DISTANCE  = 5120
TILE_RESOLUTION = 10
TILESIZE       = DRAW_DISTANCE / TILE_RESOLUTION
```

This results in:

```text
TILESIZE = 512 Warcraft III units
```

`DoodadRenderManager` should initially use the same:

```text
UPDATE_INTERVAL = 0.20
TILE_SIZE       = 512.00
```

Benefits:

- camera movement is evaluated at the same spatial granularity;
- behavior is easier to reason about;
- performance testing can compare doodad and destructable systems directly;
- changing camera cell requires movement of ~512 units rather than triggering work every timer tick.

Do **not** make `DoodadRenderManager` depend directly on private globals from `DestructableHider`.

Keep the two libraries independent in v1.

Later, if desired, their common camera-grid logic can be extracted into a shared library.

---

# 5. Configuration Model

## 5.1 Register types, not instances

The only manual configuration should be a list of doodad rawcodes.

Example conceptual configuration:

```jass
call RegisterType('D001', 3072.00)
call RegisterType('D002', 3072.00)
call RegisterType('D003', 4096.00)
call RegisterType('D004', 2048.00)
```

This is one entry per **doodad type**, regardless of whether the map contains:

```text
50 doodads
500 doodads
10,000 doodads
```

of that type.

No existing doodad needs to be touched in World Editor.

---

## 5.2 Per-type render distance

Support a render distance per rawcode.

Internally convert distance into integer tile radius:

```text
radiusTiles = ceil(drawDistance / TILE_SIZE)
```

Recommended additional safety margin:

```text
effectiveRadiusTiles = radiusTiles + OVERSCAN_TILES
```

Default:

```text
OVERSCAN_TILES = 1
```

This prevents large doodad models from disappearing too early merely because their model origin is outside the active area while part of their geometry is still visible.

Example:

```text
Requested distance     3072
Tile size               512
Base radius               6 tiles
Overscan                  1 tile
Effective radius          7 tiles
```

---

# 6. Data Model

Pure JASS arrays are sufficient.

Conceptually:

```jass
private integer typeCount
private integer array typeId
private integer array typeRadius
```

Example:

```text
typeId[1]     = 'D001'
typeRadius[1] = 7

typeId[2]     = 'D002'
typeRadius[2] = 5
```

Optional later fields:

```jass
private boolean array typeEnabled
```

Avoid a hashtable unless future requirements justify it.

For the expected number of managed rawcodes, arrays are simpler and faster.

---

# 7. Reusable Rectangle

Do not create/destroy rect handles continuously.

Create one private rectangle once:

```jass
private rect workRect
```

Initialization:

```jass
set workRect = Rect(0.00, 0.00, 0.00, 0.00)
```

Before each area operation:

```jass
call SetRect(workRect, minX, minY, maxX, maxY)
call SetDoodadAnimationRect(workRect, doodadId, "hide", false)
```

or:

```jass
call SetDoodadAnimationRect(workRect, doodadId, "show", false)
```

This avoids handle churn and timer-driven rect leaks.

---

# 8. Initialization Sequence

## Phase A — Determine map geometry

Read:

```jass
GetRectMinX(bj_mapInitialPlayableArea)
GetRectMinY(bj_mapInitialPlayableArea)
GetRectMaxX(bj_mapInitialPlayableArea)
GetRectMaxY(bj_mapInitialPlayableArea)
```

Store:

```text
mapMinX
mapMinY
mapMaxX
mapMaxY
columns
rows
```

Grid conversion should match `DestructableHider`:

```text
column = floor((x - mapMinX) / TILE_SIZE)
row    = floor((y - mapMinY) / TILE_SIZE)
```

Clamp all generated grid coordinates to map boundaries.

---

## Phase B — Register managed rawcodes

Call one private configuration function:

```jass
private function ConfigureTypes takes nothing returns nothing
```

Example:

```jass
private function ConfigureTypes takes nothing returns nothing
    call RegisterType('D001', 3072.00)
    call RegisterType('D002', 3072.00)
endfunction
```

This keeps initial implementation deterministic and avoids initializer-order complexity between multiple libraries.

A public runtime registration API can be added later if genuinely required.

---

## Phase C — Initial global hide

For every registered rawcode:

```jass
call SetDoodadAnimationRect(
    bj_mapInitialPlayableArea,
    typeId[i],
    "hide",
    false
)
```

This is the only operation that intentionally scans the full playable map.

It occurs once during initialization.

Complexity:

```text
O(number of managed doodad types)
```

not:

```text
O(number of doodad instances)
```

---

## Phase D — Show the initial camera neighborhood

Read:

```jass
GetCameraTargetPositionX()
GetCameraTargetPositionY()
```

Determine the current camera cell.

For every managed type:

1. calculate its configured tile radius;
2. create a rectangle covering that cell neighborhood;
3. clamp rectangle to playable map bounds;
4. call:

```jass
SetDoodadAnimationRect(workRect, typeId[i], "show", false)
```

Store:

```text
lastColumn
lastRow
```

---

## Phase E — Start periodic timer

Use:

```text
0.20 s
```

initially to match the current destructable hider.

The timer should perform almost no work unless the camera crosses a grid-cell boundary.

---

# 9. Periodic Runtime Algorithm

Every timer tick:

```text
1. Read camera X/Y.
2. Convert camera X/Y to column/row.
3. Compare against last column/row.
4. If unchanged:
      return immediately.
5. If changed:
      update visible regions.
6. Save new column/row.
```

Important:

```text
Timer tick != visibility update
```

Most timer ticks should only perform:

- two camera native calls,
- two grid calculations,
- one comparison.

---

# 10. Visibility Transition Algorithm

Two transition paths are recommended.

---

## 10.1 Normal movement: one-cell delta

When:

```text
abs(newColumn - oldColumn) <= 1
AND
abs(newRow - oldRow) <= 1
```

update only the strips entering/leaving the visible square.

Example: camera moves one cell east.

Old:

```text
+-----------+
|           |
|    OLD    |
|           |
+-----------+
```

New:

```text
    +-----------+
    |           |
    |    NEW    |
    |           |
    +-----------+
```

Only:

```text
left outgoing strip  -> HIDE
right incoming strip -> SHOW
```

needs processing.

For each managed doodad type:

```text
HIDE old left strip
SHOW new right strip
```

This means a normal camera-cell transition costs approximately:

```text
2 × managedTypeCount
```

`SetDoodadAnimationRect` calls for horizontal/vertical movement.

Diagonal movement requires up to:

```text
4 × managedTypeCount
```

calls.

This is preferable to reprocessing the entire render square.

---

# 11. Teleports / Cinematic Camera Jumps

Camera systems and cinematics can move the camera by many cells instantly.

If:

```text
abs(deltaColumn) > 1
OR
abs(deltaRow) > 1
```

do not attempt to process every intermediate cell.

Use fallback:

```text
for each managed type:
    HIDE complete old visible area
    SHOW complete new visible area
```

Cost:

```text
2 × managedTypeCount
```

calls.

This also prevents unnecessary loops during:

- cinematic camera snaps,
- teleportation,
- map transitions,
- camera reset functions,
- debug camera movement.

---

# 12. Rectangle Calculation

Implement one internal utility conceptually equivalent to:

```jass
SetCellAreaRect(centerColumn, centerRow, radiusTiles)
```

Convert cell coordinates to world coordinates:

```text
minX = mapMinX + (centerColumn - radiusTiles)     * TILE_SIZE
minY = mapMinY + (centerRow    - radiusTiles)     * TILE_SIZE

maxX = mapMinX + (centerColumn + radiusTiles + 1) * TILE_SIZE
maxY = mapMinY + (centerRow    + radiusTiles + 1) * TILE_SIZE
```

Then clamp:

```text
minX >= mapMinX
minY >= mapMinY
maxX <= mapMaxX
maxY <= mapMaxY
```

The same coordinate rules must be used by:

- full area show/hide,
- left/right strips,
- top/bottom strips.

Keep coordinate math centralized to prevent off-by-one gaps.

---

# 13. Hysteresis / Pop-in Control

Because the system is tile-based, natural spatial hysteresis already exists:

- visibility changes only when a camera cell changes;
- the one-tile overscan keeps doodads active slightly beyond the requested distance.

Recommended initial behavior:

```text
TILE_SIZE      = 512
OVERSCAN_TILES = 1
INTERVAL       = 0.20
```

Do not add a separate show-distance/hide-distance state machine in v1 unless testing shows visible flicker.

The cell system already provides a coarse equivalent.

---

# 14. Camera Position

Use:

```jass
GetCameraTargetPositionX()
GetCameraTargetPositionY()
```

rather than hero/unit position.

Reason:

The renderer should follow what the player can actually see.

This matters for:

- cinematics,
- camera panning,
- free camera movement,
- camera offsets,
- observing scenery while the hero remains elsewhere.

This also matches the camera-driven approach already present in `DestructableHider.j`.

---

# 15. Multiplayer / Local Camera Consideration

Camera position is local to each client.

For the current implementation, preserve the same camera-driven behavior already used by the project.

However, `DoodadRenderManager` must be treated as a **visual-only system**:

- it must never alter gameplay state;
- it must never make gameplay decisions based on whether a doodad is currently hidden;
- no synchronized object creation/destruction should depend on its local state.

`SetDoodadAnimationRect` is being used strictly for rendering/animation visibility.

If multiplayer support is a requirement, explicitly test two clients with independently moving cameras before considering the system production-ready.

---

# 16. Pathing and Gameplay Behavior

Hiding a doodad with:

```jass
"hide"
```

does not turn it into a destructable and should not be used to alter gameplay/pathing behavior.

Desired behavior:

```text
rendering -> hidden
pathing   -> unchanged
gameplay  -> unchanged
```

This is appropriate for a render optimization system.

Do not use `DoodadRenderManager` for:

- opening/closing routes,
- collision management,
- destructible trees,
- gameplay state,
- quest state,
- interaction logic.

---

# 17. Rawcode-Level Limitation

The JASS doodad API identifies doodads by:

```text
rawcode + area
```

not by individual instance.

Therefore all instances of a managed rawcode inside the affected rectangle receive the same show/hide command.

Example:

```text
'D001' is managed at 3072 range.
```

Every `'D001'` doodad follows that rule.

If some instances of the same rawcode must always stay visible while others should be culled, v1 cannot distinguish them automatically.

Possible later solutions:

1. use a separate doodad rawcode for permanently visible landmark variants;
2. define explicit exclusion regions;
3. leave large/important doodad types unmanaged.

Do not introduce instance-coordinate databases in v1.

---

# 18. Recommended Doodads to Manage

Best candidates:

- small rocks,
- grass clusters,
- bushes,
- flowers,
- small mushrooms,
- debris,
- minor environmental clutter,
- repeated decorative props,
- dense forest undergrowth,
- distant cosmetic detail.

Avoid initially:

- landmark structures,
- large buildings,
- giant trees with very large model extents,
- doodads used as major silhouettes,
- important quest scenery,
- doodads whose disappearance is noticeable from long distance.

Start with the highest-count decorative types.

---

# 19. Public API — Initial Recommendation

Keep v1 minimal.

Required API:

```text
RegisterType(rawcode, drawDistance)
Enable()
Disable()
Refresh()
```

Possible semantics:

### `RegisterType`

Registers one doodad rawcode and its desired draw distance.

### `Enable`

Starts camera-based culling.

### `Disable`

Stops culling and shows all managed doodad types globally.

### `Refresh`

Re-evaluates the current camera area.

Useful after:

- camera reset,
- cinematic transitions,
- configuration changes,
- debugging.

For the first implementation, `RegisterType` can remain private/configuration-only if runtime type registration is unnecessary.

---

# 20. Optional Debug Mode

Add a compile-time constant:

```jass
private constant boolean DEBUG = false
```

When enabled, optionally display:

```text
DoodadRenderManager
Camera tile: 124, 87
Managed types: 12
Cell transition: EAST
Full refresh: false
```

Do not print every doodad operation.

Useful measurements:

- number of camera-cell transitions;
- number of `SetDoodadAnimationRect` calls;
- number of full refreshes caused by camera jumps.

This helps determine whether:

```text
TILE_SIZE = 512
```

is appropriate.

---

# 21. Performance Strategy

The primary performance rule:

> Never scale runtime JASS work with the number of doodad instances.

The manager should scale approximately with:

```text
number of managed doodad rawcodes
```

not:

```text
number of doodads on the map
```

Target runtime behavior:

```text
50,000 placed doodads
20 managed rawcodes

camera remains inside cell:
    0 SetDoodadAnimationRect calls

camera crosses one cell horizontally:
    ~40 SetDoodadAnimationRect calls

camera teleports:
    ~40 SetDoodadAnimationRect calls
```

Exact call count depends on transition implementation and number of registered types.

---

# 22. Do Not Implement These in v1

Avoid premature complexity.

Do **not** initially implement:

- war3map.doo parsing;
- external scripts;
- doodad coordinate extraction;
- per-instance distance checks;
- hashtable database of fake doodad records;
- 50,000 registration entries;
- runtime model replacement;
- conversion to destructables;
- object recreation;
- one rect handle per grid cell;
- per-frame updates;
- exact Euclidean circle culling;
- integration with gameplay pathing.

The first version should answer one question:

> Does area-based rawcode culling materially improve FPS without visible pop-in?

---

# 23. Implementation Phases

## Phase 1 — Minimal functional prototype

Implement:

- library skeleton;
- map bounds;
- `TILE_SIZE = 512`;
- reusable rect;
- manually configured rawcode list;
- one common render radius for all managed types;
- initial global hide;
- show current camera neighborhood;
- timer;
- update only when camera cell changes;
- simple full-old-area hide + full-new-area show.

Purpose:

Validate that the native approach produces the expected rendering/performance improvement.

Do not optimize strip transitions yet.

---

## Phase 2 — Per-type distances

Add:

```text
typeRadius[]
```

Allow:

```text
grass    -> short
bushes   -> short
rocks    -> medium
large art -> unmanaged
```

Validate different draw distances.

---

## Phase 3 — Strip-delta optimization

Replace full-area updates during normal one-cell camera movement with:

- outgoing horizontal/vertical strips;
- incoming horizontal/vertical strips.

Keep full-area fallback for large camera jumps.

This reduces native calls and the area scanned by each native.

---

## Phase 4 — Integration polish

Add:

- `Enable`;
- `Disable`;
- `Refresh`;
- debug counters;
- safeguards against duplicate rawcode registration;
- map-edge tests;
- cinematic-camera tests.

---

# 24. Suggested Internal Function Breakdown

Recommended responsibilities:

```text
ConfigureTypes
    Defines managed rawcodes.

RegisterType
    Stores rawcode + radius.

WorldToColumn
WorldToRow
    Converts camera coordinates to grid position.

SetWorkRect
    Converts grid bounds to clamped world rectangle.

SetTypeArea
    Calls SetDoodadAnimationRect for one rawcode.

HideAllManagedTypes
    Initial/global cleanup operation.

ShowCurrentAreas
    Shows registered types around current camera cell.

UpdateTypeHorizontal
    Handles east/west one-cell strip change.

UpdateTypeVertical
    Handles north/south one-cell strip change.

UpdateTypeFull
    Handles camera teleport/full refresh.

UpdateVisibility
    Selects strip update vs full update.

Periodic
    Detects camera-cell transition only.

Enable
Disable
Refresh

init
```

Keep rectangle math separate from transition logic.

---

# 25. Pseudocode

```text
init
    determine map bounds
    create reusable rectangle

    ConfigureTypes()

    for each managed type
        hide type over entire playable map

    currentCell = camera cell

    for each managed type
        show visible area around currentCell

    lastCell = currentCell

    start 0.20 second timer
```

Periodic:

```text
Periodic
    currentCell = camera cell

    if currentCell == lastCell
        return

    dx = currentColumn - lastColumn
    dy = currentRow - lastRow

    if abs(dx) <= 1 AND abs(dy) <= 1
        for each type
            process leaving strips
            process entering strips
    else
        for each type
            hide old full area
            show new full area

    lastCell = currentCell
```

---

# 26. Failure Modes to Test

## A. Doodad does not hide

Possible reason:

- model/rawcode does not respond as expected to `"hide"`.

Action:

- remove that rawcode from manager or investigate model animation behavior.

---

## B. Doodad remains hidden when approaching

Likely causes:

- off-by-one rectangle calculation;
- incorrect map origin handling;
- radius conversion error;
- map-edge clamp error.

---

## C. Visible popping

Possible fixes, in order:

1. increase `OVERSCAN_TILES`;
2. increase that rawcode's render distance;
3. leave that doodad type unmanaged.

Do not immediately reduce tile size.

---

## D. Performance becomes worse

Measure:

- number of managed rawcodes;
- native calls per transition;
- frequency of full camera jumps;
- update interval;
- area size passed to `SetDoodadAnimationRect`.

Then:

1. reduce managed rawcode count to high-value types;
2. implement strip updates;
3. increase tile size if camera crosses cells too frequently.

---

## E. Camera cinematic exposes hidden scenery

Because the manager follows the camera rather than hero position, normal cinematics should already work.

Test specifically:

- instant camera snaps;
- long pans;
- cinematic mode transitions;
- camera bounds changes;
- return-to-gameplay camera.

---

# 27. Test Plan

## Test 1 — One doodad type

Manage one extremely common decorative rawcode.

Set an intentionally short distance so behavior is obvious.

Verify:

- global hide occurs;
- nearby instances show;
- distant instances remain hidden;
- camera movement reveals new doodads;
- old doodads disappear.

---

## Test 2 — Map edges

Move camera to:

- north edge,
- south edge,
- east edge,
- west edge,
- all four corners.

Verify no invalid rectangles or missing edge doodads.

---

## Test 3 — Fast camera movement

Use cinematic camera snap across a large part of the map.

Verify:

- old area hides;
- new area appears immediately;
- no intermediate-cell processing.

---

## Test 4 — Long pan

Pan camera continuously.

Verify:

- no obvious rows/columns of pop-in;
- no doodads remain permanently hidden after returning.

---

## Test 5 — Performance

Compare the same location with:

```text
DoodadRenderManager disabled
vs.
DoodadRenderManager enabled
```

Use a deliberately doodad-dense area.

Measure at minimum:

- average FPS;
- worst FPS while rotating/panning camera;
- stutter during cell transitions;
- map initialization time.

The objective is not merely higher static FPS.

Cell-transition stutter must also remain acceptable.

---

## Test 6 — Existing DestructableHider coexistence

Run both systems simultaneously.

Verify:

- neither changes the other's state;
- destructables continue to hide/show correctly;
- doodads continue to hide/show correctly;
- camera transitions do not produce large spikes.

---

# 28. Acceptance Criteria

The implementation is acceptable when all of the following are true:

- [ ] No existing doodad needs to be reinserted.
- [ ] No doodad is converted to a destructable.
- [ ] No external preprocessing is used.
- [ ] Only JASS/vJASS executes the system.
- [ ] Existing ~50,000 doodads require no instance registration.
- [ ] Configuration is by doodad rawcode.
- [ ] Selected doodads are hidden outside their configured range.
- [ ] Doodads reappear correctly when the camera approaches.
- [ ] Camera teleports/cinematics recover correctly.
- [ ] Map edges are safe.
- [ ] No rect handles are leaked by periodic execution.
- [ ] Existing `DestructableHider` behavior is unchanged.
- [ ] Pathing/gameplay behavior is unchanged.
- [ ] Runtime work scales primarily with managed rawcode count rather than doodad count.
- [ ] Performance is measurably better in a doodad-heavy test area.
- [ ] No noticeable periodic stutter is introduced.

---

# 29. Recommended First Configuration

Start conservatively.

```text
TILE_SIZE        = 512
UPDATE_INTERVAL  = 0.20 s
OVERSCAN_TILES   = 1
```

Manage only approximately:

```text
3–5 very common small decorative rawcodes
```

at first.

Suggested initial render range:

```text
~3072–4096 WC3 units
```

Then compare performance.

If the concept works, progressively add high-count decorative types.

Do not initially register every doodad rawcode in the map.

---

# 30. Final Design Principle

`DestructableHider` optimizes individual destructable handles.

`DoodadRenderManager` cannot do that.

Instead:

```text
DestructableHider
    object-based spatial culling
    ↓
destructable handles stored by tile

DoodadRenderManager
    type-and-area-based spatial culling
    ↓
rawcode + SetDoodadAnimationRect
```

The crucial advantage is that the JASS workload stays small even if the map contains tens of thousands of doodads.

The engine performs the actual lookup of matching preplaced doodads inside each rectangle.

---

# References

- [Project DestructibleHider.j](https://github.com/ValdemarLabs/wc3-path-of-the-shaman/blob/dev/_CoreSystems/Imported/DestructibleHider.j)
- [Hive Workshop — Doodad Hiding System](https://www.hiveworkshop.com/threads/doodad-hiding-system.222622/)
- [Hive Workshop — Doodad Issues / SetDoodadAnimationRect hide/show](https://www.hiveworkshop.com/threads/doodad-issues.203384/)
- [Hive Workshop — How to remove or hide doodads in game](https://www.hiveworkshop.com/threads/how-to-remove-or-hide-doodads-in-game.182319/)
