# Warcraft III 3.0 Upgrade

This folder is the documentation home for planned, implemented, and validated Path of the Shaman upgrades targeting Warcraft III 3.0.0, build 24268. Add future 3.0 workstream designs, compatibility notes, test matrices, and rollout records here rather than under `_developer/Issues`.

## Documents

- [Warcraft III 3.0 Systems Upgrade Plan](Warcraft%20III%203.0%20Systems%20Upgrade%20Plan.md) — authoritative workstream scope, task IDs, priorities, constraints, and validation gates.
- [Warcraft III 3.0 P0/P1 Validation Log](Warcraft%20III%203.0%20P0-P1%20Validation%20Log.md) — executable full-map validation procedure and evidence record for the current camera, fog, doodad, and harness work.

## Evidence hierarchy

1. Active [`_Blizzard/common.j`](../../../_Blizzard/common.j) and [`_Blizzard/blizzard.j`](../../../_Blizzard/blizzard.j) declarations for exact native availability and signatures.
2. Current World Editor Object Editor data, exported map object data, and the recorded PotS Game Data Version for ability-backed or data-version-dependent features.
3. Full-map runtime and multiplayer results on Warcraft III 3.0.0.24268.
4. Patch notes, jassdoc, and community research as discovery sources that still require local verification.

## Scope boundary

Resolved failures remain incident records under `_developer/Issues`. In particular, the [Warcraft III 3.0 import crash investigation](../../Issues/2026-09-patch3/Warcraft%20III%203.0%20Import%20Crash%20Investigation.md) and its model-repair evidence stay there because they document a closed compatibility incident, not an active systems-upgrade workstream.

Do not move unrelated Warcraft III 3.0 bugs into this folder merely because they occurred on the same patch. Put a document here when it defines or validates an intentional PotS upgrade.
