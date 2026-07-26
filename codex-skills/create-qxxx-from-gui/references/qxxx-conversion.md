# qXXX GUI Conversion Reference

Use this reference after reading `SKILL.md` and before writing a qXXX library.

## Reading Order

1. Old GUI trigger export for the target questgiver.
2. `QuestsAndDialogs/QuestGivers/qAradion.j`, focusing on structure rather than copying Aradion-specific encounter logic.
3. `QuestsAndDialogs/QuestGiver.j` for qXXX-facing wrappers and requirement trackers.
4. `QuestsAndDialogs/QuestMaster.j` for `QuestData`, quest states, rewards, availability, icons, and templates.
5. `QuestsAndDialogs/DialogInteraction.j` for selection gates, dialog entry/exit transitions, greet state, and camera transition helpers.
6. `QuestsAndDialogs/DialogSystem.j` for sequence and dialog button primitives.
7. `Camera/DialogCamera.j` when custom camera behavior is needed.
8. Optional: `QuestsAndDialogs/QuestGivers/tools/qxxx-generator.html` for a starting scaffold only.

## Standard qXXX Shape

Create one library per questgiver:

```jass
library qXXX initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem
```

Add more `requires` only for real quest-specific dependencies such as `FollowSystem`, `PatrolSystem`, `UnitSpawn`, `Companions`, `IconQuery`, `ItemLootSystem`, `ZonesCore`, `Reputation`, `CreepRespawn`, or voiceline libraries.

Use this section order unless nearby code gives a stronger reason:

- Header and library declaration.
- Globals: debug flag, quest name constants, object ids, dialog/camera config, unit references, dialogs, timers, triggers, and quest-specific state.
- `DebugMsg`.
- Unit and state helpers such as `SyncUnitReferences`, hero resolution, and quest-specific condition functions.
- Quest-specific runtime helpers: spawns, patrols, companions, objective progress, failure/reset cleanup.
- Dialog line registration and sequence helpers.
- Accept, complete, fail, and recovery handlers.
- `BuildDialog`.
- `RebuildAndShowDialog`, `ContinueToDialogAfterSelection`, and `OnSelected`.
- `CreateQuests`.
- Delayed-discovery/state-change callbacks if needed.
- `InitDelayed` and `Init`.
- Public hooks called from external map events or other libraries.

## Master API Mapping

Prefer these conversions from old GUI trigger intent to qXXX implementation:

| Old GUI intent | Preferred qXXX implementation |
| --- | --- |
| Register/select questgiver NPC | `QuestGiver_Register(npc)` and `DialogInteraction_RegisterSelectionHandler(npc, function OnSelected)` |
| Create quest | `QuestGiver_CreateConfiguredQuest(...)` |
| Set title/icon/description/level/faction/receiver | Arguments to `CreateConfiguredQuest`, or `QuestGiver_ApplyQuestMetadata` for template quests |
| Set rewards | `QuestGiver_SetQuestRewards(q, xpActive, xpAdjust, goldActive, goldAdjust, arenaActive, arenaAdjust, repActive, repAdjust, repLinked)` |
| Required reputation | `QuestGiver_SetQuestRequiredReputation(q, reputationValue)` |
| Required completed quest | `QuestGiver_AddQuestPrerequisite(q, prereqName, prereqGiver)` |
| Custom availability condition | Create a trigger condition and pass it to `QuestGiver_SetQuestCustomCondition(q, trigger)` |
| Static objectives | `QuestGiver_SetRequirements(q.id, heading, r1, r2, ..., r8)` |
| Accept quest | `QuestGiver_AcceptQuestByNameAndGiver(questName, giver)` |
| Complete quest | `QuestGiver_CompleteQuestByNameAndGiver(questName, giver)` |
| Fail quest | `QuestGiver_FailQuestByNameAndGiver(questName, giver, reason)` |
| Query quest state | `QuestGiver_QuestExistsByNameAndGiver`, `IsQuestDiscoveredByNameAndGiver`, `IsQuestCompletedByNameAndGiver`, `IsQuestFailedByNameAndGiver`, `GetStateByNameAndGiver` |
| Manual objective completion | `QuestGiver_SetRequirementCompleted`, `QuestGiver_UpdateRequirementText`, `QuestGiver_SetStateByNameAndGiver`; add return requirement when the quest should turn in at the giver |
| Item objective | `QuestGiver_RegisterItemRequirement(q.id, giver, reqIndex, itemTypeId, amount)` |
| Kill objective | `QuestGiver_RegisterUnitKillRequirement(q.id, giver, reqIndex, unitTypeId, amount)` |
| Escort objective | `QuestGiver_RegisterEscortRequirement(q.id, giver, reqIndex, escortUnit, destinationRect, destName)` and unregister on completion/failure |
| Talk objective | `QuestGiver_RegisterTalkToRequirement` and `QuestGiver_CompleteTalkToRequirement` |
| Find NPC objective | `QuestGiver_RegisterFindNPCRequirement` |
| Go to place objective | `QuestGiver_RegisterGoToPlaceRequirement` |
| Reputation objective | `QuestGiver_RegisterReputationRequirement` |
| Investigate objective | `QuestGiver_RegisterInvestigateRequirement` and `QuestGiver_CompleteInvestigateRequirement` |
| Give quest item | `QuestGiver_GiveQuestItemToHero` or `QuestGiver_GiveUniqueQuestItemToHero` |
| Recover lost quest item | `QuestGiver_AddQuestItemRecoveryButton` or `QuestGiver_AddQuestItemRecoveryButtonEither` |
| Add/remove companion | `QuestGiver_AddCompanion` and `QuestGiver_RemoveCompanion` |
| Dialog selection gate | `DialogInteraction_GetDialogSelectionHero` plus `DialogInteraction_PassDialogSelectionGate` |
| Dialog entry transition | `DialogInteraction_StartConfiguredDialogEntryTransition` |
| Dialog exit transition | `DialogInteraction_StartConfiguredDialogExitTransition` |
| Greet order and first greet state | `DialogInteraction_SetGreetOrder`, `SetFirstGreetDone`, and related `QuestGiver` wrappers |
| Quest accept/complete/fail buttons | `QuestGiver_AddAvailableQuestAcceptButton`, `QuestGiver_AddReadyQuestCompleteButton`, `QuestGiver_AddFailedQuestButton` |

## Dialog Pattern

Use qAradion's selection pattern for most questgivers:

- Resolve and store `SelectedHero`.
- Block invalid interactions with `DialogInteraction_PassDialogSelectionGate`.
- Start configured entry transition with the public callback name, for example `"qValeria_ContinueToDialogAfterSelection"`.
- In `ContinueToDialogInternal`, rebuild and show the dialog or play first-greet logic.
- End dialog sequences through one exit helper that calls `DialogInteraction_StartConfiguredDialogExitTransition`.

In `BuildDialog`, prefer wrapper buttons:

```jass
call QuestGiver_AddAvailableQuestAcceptButton(MyDialog, QUEST_NAME, MyNpc, 2, function OnAcceptQuest1, true, false)
call QuestGiver_AddReadyQuestCompleteButton(MyDialog, QUEST_NAME, MyNpc, 3, function OnCompleteQuest1, true)
call QuestGiver_AddFailedQuestButton(MyDialog, QUEST_NAME, MyNpc, 4, function OnFailQuest1)
```

Use `validateItems = true` for item turn-ins that depend on registered item requirements.

## Quest Creation Pattern

Use `CreateConfiguredQuest` as the default:

```jass
set q = QuestGiver_CreateConfiguredQuest(QUEST_NAME, MyNpc, "normal", 10, null, "Quest Title", "ReplaceableTextures\\CommandButtons\\BTNTome.blp", "Quest description.\n\n", infoText, info2Text, 10, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "FactionName", giverName)
call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 100, false)
call QuestGiver_SetRequirements(q.id, "", "Primary objective", "", "", "", "", "", "", "")
```

Add prerequisites and special availability in `CreateQuests`; do not only hide buttons in `BuildDialog`, because availability and quest icons also need correct state.

## Old GUI Conversion Rules

- Translate GUI events into qXXX hooks only when an external event still needs to call the questgiver library.
- Translate GUI conditions into clear boolean helpers near the state they read.
- Translate GUI waits/timers into named timers or delayed callbacks; clean timers when they are no longer needed.
- Keep old variable names only when they map to existing `udg_` globals or make conversion easier to audit.
- For unit replacement/respawn, resync `udg_` references and refresh selection handlers and availability.
- For old trigger comments or disabled branches, preserve only the gameplay-relevant result.
- If an old GUI trigger performed technical work already handled by a master library, call the master API and omit the old technical steps.

## What Must Stay Quest-Specific

Keep these in qXXX when present:

- Unique dialog/voiceline sequences and speaker choreography.
- Quest-specific encounter state, spawned units, patrol changes, companion ownership, faction/hostility transitions, and failure/retry cleanup.
- Public functions called by map events, spells, regions, or other libraries.
- Special objective progress that is not covered by the generic trackers.

## Final Review Checklist

- The generated qXXX compiles in JASS ordering: helpers appear before callers.
- No direct `QuestMaster_` calls are used where a `QuestGiver_` wrapper exists and fits.
- The old GUI trigger outcomes are represented, but implementation is simplified through master APIs.
- Quest prerequisites and availability are set in quest data, not only in dialog button conditions.
- Dialog/camera transitions consistently restore control and start cooldowns.
- Handle locals are nulled and created handles are destroyed or intentionally retained.
- All temporary scaffold text is replaced before calling the conversion done.
