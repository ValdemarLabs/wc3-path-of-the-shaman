# WC3 Manager Quest Designer

The Quest Designer is a database-backed authoring and review tool for PotS quest givers, quest metadata, objectives, rewards, prerequisite relationships, dialog/event sequences, voiceline references, and World Editor dependencies. It is deliberately bounded by the current `QuestGiver`, `QuestMaster`, `DialogInteraction`, `DialogSystem`, `QuestUI`, and qXXX conventions.

## Source-of-truth boundary

The database does not replace current JASS or World Editor state. Current qXXX sources, current master libraries, `Zones/ZonesCore.j`, and current World Editor data remain authoritative. `_MISC/war3map.wts` may be inspected as evidence but must never be edited.

Each giver has one ownership mode:

- `managed`: standard metadata, menus, linear sequences, supported trackers, prerequisites, and rewards can be generated.
- `hybrid`: the exporter generates a timestamped scaffold and explicit hook markers for hand-owned behavior.
- `external`: data may be used for previews and relationships, but the exporter never creates or overwrites the existing qXXX source.

Use `external` for large existing libraries such as qAradion unless they are deliberately migrated in a separately reviewed change. Use `hybrid` for waves, companions, patrols, timers, branching story state, boss/dungeon ownership, repeatable reset policies, custom item consumption, failure cleanup, or other behavior that cannot be expressed safely through the shared APIs.

## Synchronizing existing JASS

Use **Sync existing JASS...** in the Quest Designer toolbar and select either the repository root or `QuestsAndDialogs`. A single run scans both active source roots:

- `QuestsAndDialogs/QuestGivers/`, including vendor qXXX libraries using fetch, kill, and supply registrations.
- `QuestsAndDialogs/GenericQuests/`, including giverless/runtime-assigned quests.

Old GUI, plan, tool, backup, and test paths are excluded. Each source file becomes an `external` read-only giver or source container, and supported quest registrations populate the preview, objectives, rewards, turn-in relationships, prerequisites, and qXXX library links. Dynamic requirement text and custom runtime behavior remain source-owned and are reported as warnings rather than guessed.

The synchronizer stores a separate SHA-256 source fingerprint on each imported giver and quest. Unchanged files do not rewrite quest details. Managed/hybrid rows are protected from source import, and the exporter continues to ignore external rows. To update imported content, edit JASS and synchronize again.

### Which copy should be edited?

- **Synchronized/external library:** edit the existing `.j` file under `QuestsAndDialogs`, then synchronize. WC3 Manager treats its database rows as a read-only projection and never writes to that source file.
- **Managed library:** edit the database record in WC3 Manager, then export. Treat generated JASS as build output; hand edits are not imported back and a later export may supersede them.
- **Hybrid library:** edit supported metadata in WC3 Manager, export a new scaffold, and manually reconcile the explicitly hand-owned hooks. There is no automatic three-way merge.

Do not change an imported row from `external` to `managed` merely to make it editable. That changes the source-of-truth contract and can create a second generated implementation of an existing library. If a library is intentionally being migrated to database ownership, use a reviewed conversion: preserve the original file, resolve library-name/import-order conflicts, compare generated behavior, compile with JassHelper, and runtime-test before replacing the hand-owned source.

The same operation is available for diagnostics or automation:

```powershell
dotnet .\WC3_Database\WC3ItemManager\bin\Debug\net8.0-windows\WC3ItemManager.dll --sync-quest-sources .\QuestsAndDialogs
```

## Database setup

Run the idempotent migration from `WC3_Database/migrations`:

```powershell
psql -U postgres -d wc3_pots -f .\run_all_quest_migrations.sql
```

On a disposable database, run it twice and verify all nine quest tables are reported both times. The migrations create relationship views, `updated_at` triggers, and source-provenance fields as well as the authoring tables.

## Authoring workflow

1. Create a giver and assign its stable key, qXXX library name, faction/zone, allowed heroes, and either a placed-unit JASS variable or fallback rawcode.
2. Select `managed`, `hybrid`, or `external` ownership and record the existing source path when applicable.
3. Create quests with stable keys/internal names, player-facing text, type/category, level and reputation gates, giver/turn-in relationship, faction/zone, objectives, rewards, and prerequisites.
4. Create ordered sequences for greeting, information, acceptance, completion, failure, farewell, or custom dialog options. Link verified voiceline constants where source/audio evidence exists.
5. Record every placed unit, rect, camera, rawcode, GUI trigger, Object Editor field, or audio asset that must be reconciled manually.
6. Review the Details, Description, Objectives, and Rewards preview. The preview follows the current QuestUI information model and reward formulas; it is not a pixel-perfect frame renderer.
7. Clear `Draft`, save, export, then review all four artifacts before importing anything into the map.

## Enforced runtime limits

- QuestMaster has eight objective slots. A quest that returns to a giver reserves one, leaving at most seven authored objectives.
- QuestMaster has four prerequisite slots.
- DialogSystem sequences have at most 100 steps.
- Main-story quests cannot be daily/repeatable or depend on daily/repeatable quests.
- A cross-giver prerequisite or turn-in relationship needs a concrete placed-unit variable.
- Multiple automatic trackers are not generated as a complete multi-objective state machine; use hybrid ownership and an explicit aggregator.
- Item possession tracking does not define item consumption. A consume/reset policy requires hybrid ownership.
- Repeatable reset behavior, custom actions, and runtime auto-completion need explicit hooks and review.

## Export artifacts

**Quests > Export Changed qXXX Quest Libraries** writes timestamped files to the selected directory:

- `qName_YYYYMMDD_HHMMSS.j` or `.hybrid.j`: generated source/scaffold.
- `.json`: complete database snapshot for review and future conversion work.
- `.validation.txt`: blocking errors and non-blocking warnings.
- `.we-dependencies.txt`: manual World Editor/import-order checklist.

The exporter does not write directly into `QuestsAndDialogs/QuestGivers/` and does not overwrite the source path recorded on a giver. A successful export still requires a focused JassHelper test-map compile, runtime validation, and then a full-map compile. Standalone pjass is not sufficient for the project libraries.

The exporter calculates SHA-256 over the exact deterministic generated JASS for each giver and stores the fingerprint on that giver's database row only after all artifacts are written successfully. Later exports skip an identical giver. This detects indirect changes such as receiver globals, prerequisite names, referenced voiceline constants, and generator changes because those alter the generated source. Validation failures never advance the stored fingerprint.

## Validation checklist

- Confirm canonical title, ID, category, type, zone ID, giver, receiver, prerequisites, and durable story effects against `_developer/Design Plans/Story and Quest Design.md`.
- Inspect unexported GUI triggers and World Editor placement before replacing legacy behavior.
- Verify every voice constant against its source-owned `Voicelines_*.j` library and actual audio asset.
- Exercise accept, decline, in-progress, ready, complete, failure, retry, abandon, and unavailable-giver paths where applicable.
- Verify cleanup for escorts, companions, waves, bosses, dungeons, cinematics, and multiplayer-sensitive UI/state.
- Update the design ledger when story identity/status/dependencies change and always update the current-date PotS changelog for implementation work.
