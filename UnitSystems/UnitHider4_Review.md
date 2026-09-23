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
| `UnitHider.j` (1.0) | Simple two-phase ownership: check owned hidden units for showing, then visible units for hiding. It was the known working fallback. | Enumerates the full map every 0.5 seconds; creates and destroys a reference group for every proximity test; uses `SquareRoot`; leaks a newly created work group on every disabled timer tick; does not recognize the `UnitHider_ReferenceUnits` registrations used by current AI, companions, and pets. |
| `UnitHider2.j` | Reuses work groups, filters invalid units, compares squared distances, and keeps the reliable two-phase flow. | Still enumerates nearly every eligible map unit every 0.5 seconds and copies the full reference group for every proximity test. `Table` state duplicates the authoritative hidden group without improving behavior. The archived runtime result was slow hiding and severe lag. |
| `UnitHider3_Optimized.j` | Caches reference positions, uses squared distances, reuses main work groups, and retains the reliable two-phase flow. The archive says it worked. | Still performs a full-world enumeration every 0.5 seconds; creates a temporary reference group each cycle; limits references to 20; aborts with zero references without restoring already hidden units; does not consume current array registrations; and can show units another system intentionally hid because visibility ownership is not transferred on foreign `ShowUnit` calls. |
| `UnitHider4.j` | Uses Unit Event's active linked registry in fixed batches; caches reference positions; preserves foreign visibility ownership; has hide/show hysteresis; treats player-controlled and registered AI heroes plus registered companions/pets as revealers; protects combat/casting units without turning every combatant into a revealer; honors explicit API references and ignored units; suspends mutation during cinematics. | Requires full-map runtime validation because hiding units changes simulation behavior by design. Version 4.2 processes 64 active indexed units plus up to 256 already-hidden units per 0.10-second tick, a 5500 hide radius, and a 5200 show radius. |

Some older UnitHider Markdown files describe an earlier proposed "smart filter"
and quote estimated operation reductions. The final `UnitHider3_Optimized.j`
does not implement that positional filter: its filter removes dead, reference,
ignored, and Locust units, then its main loop still checks every remaining unit.
Treat those estimates as historical planning notes rather than measured results.

## PotS integration in UnitHider4

- Every hero is protected from hiding. Player-controlled heroes and heroes
  registered by the AI system act as revealers. AI identity comes from the AI
  registry rather than owner slots, which are not stable in that system; static
  hero-type NPCs outside the AI registry do not keep their areas populated.
- Current companion and pet registration is recognized through
  `udg_UnitHider_ReferenceUnits` together with `udg_Companion_Group` and
  `udg_TamedUnits`.
- Units marked by GCSM as in combat, or by the casting system as casting, are
  protected from hiding but do not reveal unrelated nearby map populations.
  This prevents large or remote combats from multiplying every proximity scan.
- Ordinary nonhero vendors and quest givers remain eligible for distance
  hiding. Their `AI_REGISTER_ROLE_VENDOR` or `AI_REGISTER_ROLE_SCRIPTED`
  registration does not make them revealers; only companion/pet membership or
  an explicit UnitHider registration overrides that behavior.
- `udg_UnitHider_ReferenceGroup` remains compatible for heroes and registered
  companions/pets. Obsolete nonhero members no longer reveal or protect an
  area; intentional nonhero revealers must use the public register API.
- `udg_UnitHider_IgnoredUnits`, Locust units, loaded units, dead units, and
  retained fallen-hero bodies are never newly hidden.
- While `udg_InCinematic` is true, no visibility mutation occurs. The scan and
  reference positions refresh when the cinematic ends.
- A `ShowUnit` hook removes foreign visibility changes from UnitHider4's owned
  hidden set. Consequently, disabling or proximity showing affects only units
  whose hidden state UnitHider4 still owns.
- If the reference cache becomes empty, UnitHider4 fails open and restores the
  units it hid.
- A separate bounded pass revisits already-hidden units before the normal
  indexed scan, keeping reveal response bounded even when Unit Event's maximum
  allocated index has grown after many temporary units. The indexed pass skips
  those hidden units, so one timer tick cannot process the same unit twice.
- Re-enabling the system rebuilds the automatic revealer set once before hiding
  resumes, so references created while disabled are not missed.

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

## Full-map validation

1. Import UnitHider4 after Unit Event and `FallenHeroState`; disable or remove
   every earlier UnitHider implementation and its GUI timer/toggle triggers.
2. Confirm initial hiding around all player and AI heroes, including AI heroes
   using nonstandard owners, after heavy unit create/remove churn.
3. Move an AI hero through a populated area and verify units appear before
   combat acquisition, remain interactive through combat/casting, and hide
   again after every revealer leaves.
4. Repeat with normal companions, Shadowclaw, and a tamed pet.
5. Confirm distant nonhero vendors and quest givers hide, reveal before the
   player reaches interaction range, and still open their normal shop/dialog.
6. Exercise travel, dialog cinematics, scripted quest hides, hero death/revive,
   transports, and enable/disable cycles. No foreign-hidden unit should be
   force-shown.
7. Test with zero valid revealers. UnitHider-owned units should be restored and
   no new unit should hide.
8. Enable debug temporarily and compare complete-sweep counts and frame pacing
   during a long session. Tune `UnitHider4_UNITS_PER_TICK` only from measured
   full-map results.
9. Temporarily place ordinary vendors, quest givers, and dummies in the legacy
   reference group. They should remain hideable and must not reveal nearby
   populations; an intentional nonhero registered through the API should still
   reveal normally.

## World Editor trigger migration

Keep the old `UnitHider ReferecedUnits Init` trigger disabled:

- Nazgrek and an owned Zulkis are detected as player-controlled heroes.
- Registered AI heroes are detected through the AI registry.
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

Do not call `UnitHider_SetSystemEnabled(false)` from Cinematic ON or
`UnitHider_SetSystemEnabled(true)` from Cinematic OFF. UnitHider4 suspends all
visibility mutation while `udg_InCinematic` is true and refreshes after it
becomes false. Disabling the system would immediately show every unit it owns
across the map, causing unnecessary visibility churn and potentially affecting
the cinematic setup.
