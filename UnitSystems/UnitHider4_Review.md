# UnitHider version review

## Recommendation

Use `UnitHider4.j`. Keep `UnitHider.j`, `UnitHider2.j`, and
`UnitHider3_Optimized.j` only as historical references. Import exactly one
UnitHider implementation because the versions expose overlapping public API
names.

## Changelog evidence

- 21 June 2025: UnitHider 1.1 was reported not working and producing more lag;
  the map reverted to UnitHider 1.0.
- 31 July 2025: testing without AI and UnitHider removed the observed lag, but
  the notes did not isolate which of those two systems was responsible.
- 12 October 2025: UnitHider 2 was disabled because hiding was slow and severe
  lag appeared while it was active.
- 13 October 2025: UnitHider 3 was reported working, but it remained disabled.

The archive therefore supports v1.0 as the last reliable fallback and v3 as a
promising functional revision. It does not establish any older version as both
correct and performant enough for permanent use.

## Implementation differences

| Version | Useful behavior | Main problems |
|---|---|---|
| `UnitHider.j` (1.0) | Simple two-phase ownership: check owned hidden units for showing, then visible units for hiding. It was the known working fallback. | Enumerates the full map every 0.5 seconds; creates and destroys a reference group for every proximity test; uses `SquareRoot`; leaks a newly created work group on every disabled timer tick; and does not recognize current companion/pet registrations. |
| `UnitHider2.j` | Reuses work groups, filters invalid units, compares squared distances, and keeps the reliable two-phase flow. | Still enumerates nearly every eligible map unit every 0.5 seconds and copies the full reference group for every proximity test. `Table` state duplicates the authoritative hidden group without improving behavior. The archived runtime result was slow hiding and severe lag. |
| `UnitHider3_Optimized.j` | Caches reference positions, uses squared distances, reuses main work groups, and retains the reliable two-phase flow. The archive says it worked. | Still performs a full-world enumeration every 0.5 seconds; creates a temporary reference group each cycle; limits references to 20; aborts with zero references without restoring already hidden units; does not consume current array registrations; and can show units another system intentionally hid because visibility ownership is not transferred on foreign `ShowUnit` calls. |
| `UnitHider4.j` | Drains a merged world/known/indexed snapshot for every complete settlement using the known-working UnitHider 1.0 traversal, spatially buckets hidden units, checks only nearby buckets for revealing, preserves foreign visibility ownership, and retains hide/show hysteresis. Player-controlled heroes, configured basic AI heroes, and registered companions/pets are automatic revealers; other intentional revealers use the explicit API. Cinematic begin/end calls narrow reveal coverage to the staged scene and synchronously restore normal distance ownership. | Requires full-map runtime validation because hiding units changes simulation behavior by design. Version 4.8 performs complete authoritative settlements at initialization and cinematic boundaries, then checks at most 128 managed visible units and 8 recovery units per 0.10-second tick. Hidden units outside revealer cells receive no continuous per-unit polling. |

Some older UnitHider Markdown files describe an earlier proposed "smart filter"
and quote estimated operation reductions. The final `UnitHider3_Optimized.j`
does not implement that positional filter: its filter removes dead, reference,
ignored, and Locust units, then its main loop still checks every remaining unit.
Treat those estimates as historical planning notes rather than measured results.

## PotS integration in UnitHider4

- Player-controlled heroes and AI profiles explicitly marked through
  `AI_SetProfileUnitHiderRevealer` act as automatic revealers and remain
  shown. Warrior, Orc Warlock, Undead Warlock, Restoration Shaman, Rogue,
  Engineer/Shredder, and Paladin profiles are marked. Merely having a global AI
  instance does not make an unrelated hero-type NPC a revealer.
- Current companion and pet registration is recognized through
  `udg_UnitHider_ReferenceUnits` together with `udg_Companion_Group` and
  `udg_TamedUnits`.
- Combat or casting state does not exempt a unit from distance hiding. Combat
  occurring around a tracked revealer remains visible normally; remote combat
  cannot keep otherwise inactive map population active.
- Ordinary nonhero vendors and quest givers remain eligible for distance
  hiding. Their `AI_REGISTER_ROLE_VENDOR` or `AI_REGISTER_ROLE_SCRIPTED`
  registration does not make them revealers; only companion/pet membership or
  an explicit UnitHider registration overrides that behavior.
- `udg_UnitHider_ReferenceGroup` remains compatible for player-controlled
  heroes and registered companions/pets. Remote heroes and obsolete nonhero
  members no longer reveal or protect an area; intentional remote revealers
  must use the public register API.
- `udg_UnitHider_IgnoredUnits`, Locust units, loaded units, dead units, and
  retained fallen-hero bodies are never newly hidden.
- Initial and cinematic-boundary settlements enumerate the world bounds, merge
  the snapshot with UnitHider's known-unit group and every current
  `udg_UDexUnits` handle, then drain the disposable snapshot with
  `FirstOfGroup` before changing visibility. World enumeration remains the
  primary visible-unit source; Unit Event is supplemental inventory for units
  already hidden by cinematic or scripted systems.
- `UnitHider_BeginCinematic` synchronously changes the reference cache to the
  active scene and explicit scripted references, hiding unrelated population
  before the cinematic camera proceeds. Automatic player/basic-AI/party
  references remain protected units but do not keep their surrounding map areas
  revealed during the scene. `UnitHider_EndCinematic` restores the normal
  reference cache and performs another synchronous settlement without first
  unhiding the whole map.
- A `ShowUnit` hook removes foreign visibility changes from UnitHider4's owned
  hidden set. Consequently, disabling or proximity showing affects only units
  whose hidden state UnitHider4 still owns.
- With zero valid revealers, ordinary eligible units remain hidden by default.
  Creating or restoring a tracked revealer exposes its nearby spatial cells on
  the next timer update.
- Hidden units are stored in a 64-by-64 world grid. Each update visits only the
  cells intersecting a revealer's 5,200 range instead of polling the complete
  hidden population. Units still visible around revealers are kept in a much
  smaller managed-visible group and hide after leaving the 5,500 range.
- `Events_RegisterUnitEnter` adds newly entering units to the known-unit group
  immediately. Unit Event's fully-created callback supplies a second indexed
  discovery path and deindex cleanup, while complete settlements numerically
  merge current indexed handles. Foreign-show units use the same next-update
  queue, while a low 8-unit, 64-slot recovery scan over known units repairs
  other changing exclusions without making hidden population continuous work.
- Debug APIs can force-hide every eligible non-tracked unit or unhide every
  UnitHider-owned unit without changing the enabled state. Foreign-hidden,
  ignored, Locust, loaded, and dead units retain their existing ownership or
  engine-sensitive state.

## 10 October 2026 revealer-scope correction

The force-hide debug command proved that world enumeration and
`ShowUnit(false)` were functioning. Its result differed from normal processing
because it deliberately ignores the 5,500 hide radius, while normal processing
retains every eligible unit inside any reference bubble.

The global AI system now registers a broad NPC population. Treating every
registered hero-type NPC as an automatic UnitHider reference allowed unrelated
hero NPCs to create overlapping reveal bubbles across much of the map. Version
4.7 replaces that broad test with an explicit AI profile flag. The standard
Warrior, Orc and Undead Warlock, Restoration Shaman, Rogue, Engineer/Shredder,
and Paladin profiles retain their required automatic reveal behavior.
Player-controlled heroes and current companions/pets also remain automatic;
other intentional remote cases use the explicit UnitHider API.

`AI_RegisterUnit` no longer writes every heavy AI instance into
`udg_UnitHider_ReferenceUnits`. That index-based legacy array was inconsistent
(lightweight AI never wrote it) and AI unregister did not clear it. Companion,
pet, and quest-companion registration still maintain the array where current
legacy GUI compatibility needs it. This revealer array is separate from Unit
Event's `udg_UDexUnits` inventory, which UnitHider 4.8 now consumes only as a
supplement to world enumeration and `Events` discovery.

`/debug unithider audit` reports reference count, exempt population,
UnitHider-owned hidden population, foreign-hidden population, visible units
inside reference range, and visible eligible units outside the hide range.
After an active settlement, `visible outside hide range` should be zero. A
large `visible near references` count instead identifies reference coverage,
not another system showing distant units.

The cinematic GUI continues to own movement, player-unit ownership, pause
groups, UI state, and temporary invisibility abilities. UnitHider now owns both
normal distance culling and the cinematic visibility boundary. Cinematic ON/OFF
must call the begin/end API after staging/restoration and must not disable or
enable UnitHider; disabling it would immediately unhide every UnitHider-owned
unit.

## 10 October 2026 cinematic visibility ownership correction

The repeated symptom—distant units remaining visible until a revealer visited
their area—matches an incomplete inventory transition rather than a Warcraft
group-size limit. A full-world group snapshot can disagree with the set of
units already hidden by another system, and relying on a later foreign
`ShowUnit(true)` hook leaves correctness dependent on trigger order.

Version 4.8 makes every complete settlement merge three sources: current world
enumeration, persistent known handles, and current Unit Event handles. The Unit
Event registry is supplemental rather than authoritative, preserving the 4.6
world traversal while retaining units that were hidden before enumeration.

`UnitHider_BeginCinematic(sceneReference)` is called after cinematic movement,
ownership, pause, and invisibility staging. It synchronously hides unrelated
population and reveals the active scene before the camera continues.
`UnitHider_EndCinematic()` is called after units have been restored; it switches
back to normal references and synchronously reclassifies the complete merged
inventory. Both modes use the same owned-hidden group, so distant cinematic
units transfer directly into normal hidden state instead of being globally
shown and slowly hidden again. Units hidden by a foreign system remain foreign
owned and are not force-shown.

## 8 October 2026 authoritative inventory correction

Runtime testing still showed distant units remaining visible until the recovery
scan encountered them, after which approaching a revealer made them enter the
normal visible-and-hide lifecycle. That proved the indexed registry was not a
safe authority for UnitHider's core hidden-by-default decision.

Version 4.5 enumerated the world bounds into its own persistent known-unit group
for every full settlement. Hidden-cell ownership is keyed by unit handle rather
than Unit Event user data, so even a unit missed or not yet indexed by Unit
Event could be hidden, tracked, and revealed correctly. In that version, Unit
Event supplied only incremental starts-existing, fully-created, and removal
notifications. The first full settlement also ran during the opening cinematic;
later cinematic ticks paused mutations and cinematic exit performed another
complete world settlement.

Runtime testing showed that 4.5 still did not restore the old reliable result.
The remaining behavioral difference was that the old working versions drained
a disposable full-world group with `FirstOfGroup`, removing each unit before
calling `ShowUnit`, while 4.5 performed random-access traversal over its
persistent known-unit group. Version 4.6 restores the proven disposable
snapshot traversal for authoritative settlements. It also replaces Unit
Event's creation notifications with the central `Events` world-enter callback.
In version 4.6, `udg_UDexUnits` was read only during Unit Event's deindex
callback before Unit Event cleared that slot; version 4.8 later restored the
registry as a supplemental hidden-unit inventory.

## 7 October 2026 cinematic visibility correction

Version 4.4.1 queues units affected by foreign `ShowUnit(..., true)` calls and
reclassifies the complete queue on the next active update. This prevents an
intro or cinematic teardown from exposing distant population in visible waves
while the eight-unit recovery scan eventually finds it.

Registering an explicit reference now also reveals the already-managed hidden
cells around it immediately. Scripted scenes can therefore register a moving
camera anchor before applying the camera without waiting for the periodic
timer. Zul'kis's temporary arrival ship uses this contract and unregisters
before removal.

## 20 September 2026 performance correction

The initial 4.0 tuning could execute 128 indexed and 256 hidden-unit passes at
32 Hz: up to 12,288 `UnitHider4_ProcessUnit` calls per second. Each eligible
unit then performed a linear scan across every cached revealer. Because every
GCSM combat/casting unit also became a revealer, large combat state could turn
that into millions of interpreted JASS distance comparisons per second.

Version 4.1 reduces the bound to 64 indexed and 128 hidden-unit passes at 10 Hz
(1,920 maximum calls per second before early exits), prevents duplicate
indexed/hidden processing, and limits automatic revealers to the player/party
units that actually define populated areas. Combat and casting protection is
retained per unit. This removes about 84% of the raw scheduled unit passes and,
more importantly, prevents combat population from multiplying every distance
check.

## 23 September 2026 visibility correction

Version 4.1 advanced numerically from index 1 through `udg_UDexMax`. Unit Event
recycles removed indices but does not reduce that historical maximum, so a
long-running map could spend most of each 64-unit batch walking empty slots.
Version 4.2 follows Unit Event's active `udg_UDexNext` list instead, keeping each
normal sweep proportional to current units rather than historical churn.

The legacy GUI reference group is now filtered to heroes and registered
companions/pets. This prevents obsolete nonhero generic NPC, vendor,
quest-giver, and dummy entries from protecting themselves and revealing
overlapping 5,500-range areas. New intentional nonhero revealers must call
`UnitHider_RegisterReference`. The already-hidden revisit budget rises from 128
to 256 per tick to reduce delayed pop-in while moving; the total scheduled
ceiling is 3,200 unit passes per second, still about 74% below the original 4.0
ceiling.

## 28 September 2026 registry correction

Runtime testing showed that Unit Event's compatibility `udg_UDexNext` list was
not a reliable complete unit inventory in the live map. Version 4.2 could
therefore miss most units and, when it also missed the player hero, remain in
the zero-reference fail-open state that intentionally performs no hiding.

Version 4.3 scans the authoritative `udg_UDexUnits` registry numerically again,
but no longer allows historical recycled holes to consume an unbounded sweep.
Each tick inspects at most 512 array slots and performs the normal visibility
work for at most 64 current nonhidden units. This keeps registry recovery
bounded while ensuring all indexed units and automatic hero revealers are
eventually discovered. The already-hidden pass remains separately bounded at
256 units per tick.

Version 4.3.1 adds a two-sweep catch-up phase at startup, after re-enabling,
and after `UnitHider_Refresh`. Catch-up may inspect 2,048 slots and process 256
current nonhidden units per tick. The first sweep discovers automatic hero
revealers even when their indexes occur late in the registry; the second
quickly applies hiding to units visited before that reference was cached. The
system then returns automatically to the 512-slot and 64-unit steady budget.

## 28 September 2026 hidden-by-default correction

Runtime testing of 4.3.1 showed that bounded hiding still exposed the map in
visible waves and that revisiting 256 hidden units every 0.10 seconds consumed
work after the map had settled. Broad protection for every hero and every
combat/casting unit also contradicted the original UnitHider principle by
leaving remote population active without a tracked revealer.

Version 4.4 performs one complete initial settlement after Unit Event has
indexed the map. Ordinary eligible units outside reveal range are hidden in
that pass, including generic hero-type NPCs and remote combatants. Only tracked
heroes, companions/pets, explicit references, ignored units, Locust units,
loaded units, and nonliving units bypass normal distance hiding.

Hidden units are assigned to a 64-by-64 spatial grid. Revealer movement checks
only intersecting cells and exact distance, while departure checks operate on
the comparatively small managed-visible group. No full or fixed-size hidden
population pass remains in steady state. This restores the intended scaling:
the inactive world stays hidden and ongoing work follows the active areas.

## Full-map validation

1. Import UnitHider4 after `Events`, Unit Event, and `FallenHeroState`;
   disable or remove every earlier UnitHider implementation and its GUI
   timer/toggle triggers.
2. Confirm initial hiding around player-controlled heroes after heavy unit
   create/remove churn, while unrelated AI-registered hero NPCs remain
   hideable.
3. Move each standard Warrior, both Warlocks, Restoration Shaman, Rogue,
   Engineer/Shredder, and Paladin through populated areas. Nearby units must
   reveal before interaction and hide again after every revealer leaves.
4. Repeat with normal companions, Shadowclaw, and a tamed pet.
5. Confirm distant nonhero vendors and quest givers hide, reveal before the
   player reaches interaction range, and still open their normal shop/dialog.
6. Exercise travel, dialog cinematics, scripted quest hides, hero death/revive,
   transports, and enable/disable cycles. Verify cinematic begin hides unrelated
   areas before the camera moves, cinematic end immediately restores normal
   distance visibility, and no foreign-hidden unit is force-shown.
7. Test with zero valid revealers. Ordinary eligible units should remain hidden;
   creating or reviving a tracked hero should reveal only its nearby area.
8. Enable debug temporarily and verify that `Known` matches the expected live
   map population, then compare initial settlement and steady frame pacing
   during a long session. Tune recovery or visible-unit budgets only from
   measured full-map results.
9. Temporarily place ordinary vendors, quest givers, and dummies in the legacy
   reference group. They should remain hideable and must not reveal nearby
   populations; an intentional nonhero registered through the API should still
   reveal normally.

## World Editor trigger migration

Keep the old `UnitHider ReferecedUnits Init` trigger disabled:

- Nazgrek and an owned Zulkis are detected as player-controlled heroes.
- Standard Warrior, both Warlocks, Restoration Shaman, Rogue,
  Engineer/Shredder, and Paladin AI profiles are automatic revealers. Other
  remote AI hero profiles require explicit configuration or registration.
- Shadowclaw and ordinary pets are detected when `Pet` registers them in the
  pet groups and legacy reference array.
- Current companions are detected through the companion group and legacy
  reference array.
- `RepDummy`, `CompDummy`, and `StatsDummy` should not reveal surrounding map
  areas. If a functional dummy ever must remain shown, ignore that unit with
  `UnitHider_SetUnitIgnored` instead of making it a reference.
- Register any intentional nonhero proximity revealer through
  `UnitHider_RegisterReference`; merely adding it to the legacy GUI group is no
  longer sufficient.

In World Editor, add `call UnitHider_BeginCinematic(udg_CinematicTriggerUnit)`
to Cinematic ON after unit movement, ownership, pause, and invisibility staging.
Add `call UnitHider_EndCinematic()` to Cinematic OFF after restoring those unit
states. The checked-in GUI reference files show the exact placement.

Do not call `UnitHider_SetSystemEnabled(false)` or
`UnitHider_SetSystemEnabled(true)` from Cinematic ON/OFF. The begin/end API owns
the visibility transition without globally showing UnitHider-managed units.
