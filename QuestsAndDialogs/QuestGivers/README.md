# Quest-giver content and voice contract

Quest givers fall into three content classes. Keep the class explicit even when
several characters share a reusable voice profile.

1. **Named story or character giver:** owns a qXXX library, custom state, and
   dialogue written for that character and quest.
2. **Named lightweight giver:** owns one or more QuestsGeneric definitions.
   The offer and completion lines still name the concrete target, place,
   quantity, and local reason. Vendor quests are currently the largest set in
   this class.
3. **Generic regional giver:** a guard, hunter, worker, resident, or similar
   role whose quest can use short objective-safe dialogue. These NPCs must not
   silently become merchants and do not require Shop.

GenericOrcMale1_, GenericHumanFemale2_, and similar identifiers describe a
reusable voice actor/profile. They do not make the speaking character generic.
A named character may share the profile while retaining character-specific
written lines and dedicated sound keys.

## Dialogue layering

Every named quest should use this order:

- a giver-owned offer that explains the exact local problem;
- a short hero acknowledgement;
- for Daily quests only, an optional race/voice follow-up that remains valid
  for any target of the same objective class;
- an objective-specific hero turn-in;
- a giver-owned completion that names the local result;
- optional definition-scoped progress, acceptance, or completion lines for
  Normal quests and any quest with a strong character beat.

Reusable Kill lines must fit wolves, humanoids, undead, and other hostile
targets without celebrating cruelty or naming an unrelated faction. Reusable
Fetch lines must fit plants, ore, food, salvage, and other materials without
assuming a shop transaction. Reusable Talk lines must not assume a parcel,
purchase, or merchant unless the objective is explicitly a supply/purchase
quest.

Vendor greetings, trade chatter, sale responses, and no-transaction lines in
Voicelines_VendorLines.j are not generic quest dialogue. Do not reuse them for
non-vendor quest givers.

## Current reusable voice inventory

Voicelines/Voicelines_Quests.j registers objective-safe Daily pools for:

- nine Orc male profiles;
- Satyr male and female profiles;
- two Human male and two Human female profiles;
- four Goblin male profiles;
- one Bonecrusher Ogre male profile;
- two Elarindor male and two Elarindor female profiles;
- three Tauren male profiles;
- one Morgrim Dwarf male profile;
- two Troll male profiles.

Profiles that do not yet exist in Voicelines_VendorLines.j—including Orc,
Tauren, Troll, Dwarf, Goblin, and Bonecrusher female profiles—need an approved
voice identity, constant, folder, and ExSound registration before a quest uses
them. Do not assign a mismatched male profile merely to fill the gap.

Changed text invalidates an older recording at the same key. Review the full
conversation, then re-record it before including that audio in production.
Missing files may continue to use ExSound's text-duration fallback during
development.

## Pure non-vendor generic givers

Use QuestsGeneric directly for lightweight Kill, Fetch, Find, Talk, and Escort
definitions. `QuestsGenericDialog_RegisterNPC` supplies a complete selectable
dialog for an otherwise standalone NPC, while
`QuestsGenericDialog_RegisterNoticeBoard` supplies the same quest menu with a
text-only board greeting. Neither path has a Shop dependency or a Trade
button. Registration is deliberately explicit so it cannot overwrite a named
qXXX character's custom selection handler.

The canonical wanted-post unit type is `'n05N'`, exposed as
`QuestsGenericDialog_WANTED_POST_UNIT_TYPE`. All wanted posts are preplaced in
World Editor. Pass each exact generated unit handle to
`QuestsGenericDialog_RegisterWantedPost`; the system neither creates posts nor
discovers them by rawcode, and the function ignores units of another type.
Keep `RegisterNoticeBoard` for any other sign model.

If a generic quest belongs in an existing custom NPC dialog, register the unit
with `QuestsGeneric_RegisterUnit`, add choices with
`QuestsGeneric_AddDialogButtons`, and route those actions through
`QuestsGeneric_BeginAction`, `FinishPendingAction`, and
`CancelPendingAction`. Do not also register that unit with
QuestsGenericDialog.

Notice-board quests normally turn in elsewhere. After creating the definition,
bind it to its exact preplaced post with `QuestsGeneric_SetGiverUnit` before
registering any wanted posts. This prevents different `'n05N'` signs from
sharing every wanted-post definition merely because they use the same unit
type. Then call `QuestsGeneric_SetReceiverUnit` for an exact placed NPC or
`QuestsGeneric_SetReceiverUnitType` for a unique unit type, then optionally
configure its completion line with `QuestsGeneric_SetReceiverDialogue`.
Register the receiver before or alongside the board. The quest is not
instantiated until its giver, receiver, and any Find target are available, so a
missing placed unit cannot produce a quest that has no valid completion path.

Each definition begins with one objective and may add up to six more with
`QuestsGeneric_AddKillObjective`, `AddFetchObjective`, `AddTalkObjective`, and
`AddFindObjective`. The authored limit is seven because QuestMaster reserves
the eighth journal slot for the return objective. A combined quest becomes
ready for turn-in only after every authored objective is complete. A single
kill objective with amount 1 covers a named-unit hunt; `RegisterFindQuest` or
`AddFindObjective` uses proximity discovery for a missing-person objective.

Example notice-board setup:

    set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Crocolisk Notice", "normal", 4, "Crocolisk Notice", iconPath, "Cull eight crocolisks and gather four flowers.", 'ncrb', 8, 25, "", 0, noticeText, completionText)
    call QuestsGeneric_SetGiverUnit(definitionId, board)
    call QuestsGeneric_AddFetchObjective(definitionId, 'I60Y', 4)
    call QuestsGeneric_SetReceiverUnit(definitionId, ragmo, "Ragmo")
    call QuestsGeneric_SetReceiverDialogue(definitionId, ragmoVoiceType, ragmoCompleteIndex, ragmoCompleteText)
    call QuestsGenericDialog_RegisterNPC(ragmo, "Ragmo")
    call QuestsGenericDialog_RegisterWantedPost(board, "Wanted Post")

Type-based receiver and Find-target lookup assumes that the rawcode identifies
one current world unit. Use the exact-unit setters when several placed units
share a type.

### Regional wanted posts

`WantedPosts.j` contains **draft, unapproved content**: three candidate quests
for each requested Horde posting. The library does not register them
automatically. Do not call a `WantedPosts_Register...` function in the
production map until that post's quest set has completed the review gate below.

| Preplaced post | Quest set |
|---|---|
| Mok'natha, Sirensong | Raiders of Zul'Garok; Serpentshore Patrol; Songs Beneath the Surf |
| Ironspine Post, Ghostwalk Ridge | Antlers in the Fog; Ichor for Ironspine; Lost Beyond the Watchfires |
| Horde mountain camp, Sereneglade | Scales and Stingers; Frenzy Below the Camp; Lost on the North Slope |
| Horde Scout Base, Thornwoods | Tidecallers at the Ford; Stolen Scout Supplies; The Road to the Scout Base |

Call the matching `WantedPosts_Register...` function with the exact preplaced
`'n05N'` post, its remote receiver, and the optional preplaced missing-person
target. The two local daily/repeatable jobs are always created; the one-time
Find quest is omitted when its target is null. Pass
`registerReceiverDialog = true` only for a generic receiver with no existing
selection handler. When it is false, the function registers quest state but
the receiver's bespoke qXXX dialog must add and route the shared
`QuestsGeneric` buttons.

#### Wanted-post draft review gate

The post's placed location and surrounding zone are the primary authority for
its quest selection. Before approving any candidate quest, inspect the current
World Editor area and decide:

- which enemies, gatherables, missing characters, and safe travel routes are
  actually visible and reachable from the post;
- whether target density, respawn behavior, item drop chance, travel distance,
  and target counts make the objective practical;
- who owns the remote turn-in, whether that NPC already has a qXXX or vendor
  dialog, and whether the post should reveal that receiver explicitly;
- which quests are Normal, Daily, or Repeatable, what unlocks them, and whether
  all choices appear permanently or rotate;
- whether targets, item drops, titles, or story beats overlap another post,
  vendor quest, qXXX quest, dungeon quest, or profession objective;
- whether reputation, gold, level requirements, save/load state, and daily
  reset behavior fit the zone's progression;
- how exact missing-person targets behave when dead, hidden, moved, or absent;
- whether accepting quests from more than one post may safely share progress
  against the same unit types or items.

If those decisions require prerequisites, per-post availability, rotation, or
stronger receiver ownership, design the shared quest-system API first. Do not
encode a one-location workaround into `WantedPosts.j`. After approval, update
the implementation ledger from **Draft** to **Implemented**, add the exact WE
post/receiver/target handles, and validate the focused flow and full map through
World Editor/JassHelper.

For an autonomous Escort objective, use the shared QuestsVendor escort adapter
even when the giver is not a shop. EscortMovement sends the NPC toward its
destination at a configurable speed (200 by default), waits when the accepting
hero leaves the 900-unit default leash, and supports up to 128 ordered point or
rect waypoints without changing the NPC into a vendor. Speaking with the active
escort pauses travel; closing dialogue starts a five-second resume delay. The
active quest dialogue also exposes Wait here / Let's move without requiring a
new recorded line.

Nazgrek and Zul'kis generic hero replies are resolved by hero, quest objective,
dialogue stage, and any definition-scoped override. Kill, Fetch, Talk, and
Escort acceptance/progress use distinct line-type pools, while completion
already uses objective-specific pools. Random selection avoids immediately
repeating the previous line when a pool has more than one existing recording.

The repository cannot choose the final giver from role text alone. Before
adding a planned regional quest, select or create the exact World Editor unit,
record its canonical name/rawcode/faction/zone, inspect active GUI triggers,
and confirm that the objective does not duplicate a vendor or qXXX quest.

## Random regional kill targets

QuestsGeneric_AddKillTargetCandidate adds an explicit approved unit-type
candidate to a Kill definition. Add up to eight candidates, then optionally
call QuestsGeneric_SetKillTargetZone. When the placed giver is registered, the
quest selects randomly among candidate types currently alive in that zone or
one of its child zones. With no explicit zone, it uses the giver's current
zone. If no candidate is present, the original registered target remains the
fallback.

Example:

    set definitionId = QuestsGeneric_RegisterKillQuest(giverType, "Local Threats", "daily", 6, "Local Threats", iconPath, "Reduce the dangerous wildlife near the settlement.", fallbackType, 6, 35, voiceType, 1001, offerText, completeText)
    call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nwlt')
    call QuestsGeneric_AddKillTargetCandidate(definitionId, 'ngno')
    call QuestsGeneric_SetKillTargetZone(definitionId, 2)

Candidate lists are deliberate safety filters. Never enumerate an arbitrary
zone unit and turn its type into a quest target: that can select allied
factions, named bosses, summons, critters, quest actors, or units that do not
respawn. The owning quest library remains responsible for faction safety,
story prerequisites, target count, and runtime validation.

