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

Use QuestsGeneric directly for lightweight Kill, Fetch, Talk, and Escort
definitions. Register the placed NPC with QuestsGeneric_RegisterUnit and add
its quest choices with QuestsGeneric_AddDialogButtons from the owning
selection-dialog integration. A generic giver needs no Shop catalog and must
not be routed through vendor greetings or Trade UI.

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

