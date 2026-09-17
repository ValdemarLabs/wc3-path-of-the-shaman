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
| `UnitHider4.j` | Uses Unit Event's indexed registry in fixed batches; caches reference positions; preserves foreign visibility ownership; has hide/show hysteresis; treats player-controlled and registered AI heroes, registered companions/pets, and active combat/casting units as revealers; honors explicit reference/ignored groups; suspends mutation during cinematics. | Requires full-map runtime validation because hiding units changes simulation behavior by design. Its current tuning is 128 indexed slots plus up to 256 already-hidden units per 0.03125-second tick, a 5500 hide radius, and a 5200 show radius. |

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
  protected and temporarily act as revealers.
- `udg_UnitHider_ReferenceGroup` remains an explicit override for existing GUI
  work. The public register/unregister API supports new JASS systems.
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
  allocated index has grown after many temporary units.

## Full-map validation

1. Import UnitHider4 after Unit Event and `FallenHeroState`; disable or remove
   every earlier UnitHider implementation and its GUI timer/toggle triggers.
2. Confirm initial hiding around all player and AI heroes, including AI heroes
   using nonstandard owners.
3. Move an AI hero through a populated area and verify units appear before
   combat acquisition, remain interactive through combat/casting, and hide
   again after every revealer leaves.
4. Repeat with normal companions, Shadowclaw, and a tamed pet.
5. Exercise travel, dialog cinematics, scripted quest hides, hero death/revive,
   transports, and enable/disable cycles. No foreign-hidden unit should be
   force-shown.
6. Test with zero valid revealers. UnitHider-owned units should be restored and
   no new unit should hide.
7. Enable debug temporarily and compare complete-sweep counts and frame pacing
   during a long session. Tune `UnitHider4_UNITS_PER_TICK` only from measured
   full-map results.
