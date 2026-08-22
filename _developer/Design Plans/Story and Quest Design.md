# Story and Quest Design

- **Status:** Living master design plan
- **Created:** 22 August 2026
- **Scope:** Main story, side stories, generic quests, dungeon quests, quest-giver connections, and world-event dependencies

## 1. Purpose

This file is the shared source of truth for the intended *Path of the Shaman* story and quest structure. Read it before creating or materially changing a quest, quest giver, story dialogue, dungeon quest, or story-driven world event.

The plan does not replace the map, current JASS, or recovered GUI triggers. It connects those sources and records which ideas are current, incomplete, legacy, proposed, or still need World Editor verification. When implementation reveals better information, update this plan instead of allowing the design and code to drift apart.

The immediate design goals are:

- preserve already implemented quests and their working dependencies;
- turn the strongest Articy and legacy GUI ideas into one coherent story arc;
- give every major zone a useful mix of story, normal, daily, repeatable, and dungeon content;
- connect generic quests to characters, factions, dungeons, and later story payoffs;
- avoid gating the main story behind daily or repeatable grinding;
- make branch decisions visible later without requiring several wholly separate campaigns;
- identify conflicts and missing evidence before they become new canon.

## 2. Authority, evidence, and status

### Source priority

When sources disagree, use this order unless a deliberate redesign is recorded here:

1. Current JASS behavior, current World Editor objects/placements, and `Zones/ZonesCore.j`.
2. Current voice-line constants, current names, and the changelog.
3. Recoverable GUI triggers and other map-authored legacy behavior.
4. `_developer/_articyExports/` as design evidence. Its story and quest objects are marked outdated and must not override current implementation automatically.
5. New proposals in this plan.

An unexported GUI trigger is missing evidence, not permission to invent its exact objectives, rewards, or state transitions. Inspect it in World Editor before converting the affected quest.

### Evidence reviewed for this revision

- `Zones/ZonesCore.j` for active zone IDs, hierarchy, level ranges, factions, caves, dungeons, and named encounters.
- Current `QuestsAndDialogs/QuestGivers/q*.j` libraries and the vendor quest README for implemented QuestData, prerequisites, objective locations, and external hooks.
- Current narrator, Granis, Garthork, Boom Brothers, Atex Blix, and Grum Bloodfang voice-line libraries for recoverable authored intent.
- Current dungeon/boss libraries for Rol'jin, Boom Mine, and Mad Blix.
- `_developer/_articyExports/Articy XML/Path of the shaman.xml` and the companion document export for flow hierarchy, quest banks, entities, and connections.
- `_developer/gui-variables.md` and unit-assignment evidence for named map globals/rawcodes.

The Articy export was useful as a graph, but its story and quest records are marked `Outdated`. Act I contains the densest connected flow, Act II is mostly a loose quest bank, and Act III is empty. Most exported dialogue is placeholder-level except for recoverable Granis material. Articy therefore informs missing intent; it does not certify current names, placement, or implementation.

### Status legend

| Status | Meaning |
|---|---|
| **Implemented JASS** | A current qXXX or other runtime library defines the content. This does not imply that full-map runtime validation is complete. |
| **Partial** | Some quest, dialogue, boss, dungeon, or event support exists, but the full designed path does not. |
| **Legacy evidence** | Articy, voice lines, or GUI behavior describes the content; current qXXX implementation is absent. |
| **Proposed** | New synthesis intended for future implementation. Names and details may still change. |
| **Verify in WE** | The placed unit, rect, rawcode, GUI trigger, or Object Editor data must be inspected before implementation. |
| **Blocked by decision** | Conflicting identities or story outcomes require an explicit canon decision first. |

### Quest metadata contract

The current quest system separates type from category:

- `questType`: `normal`, `daily`, or `repeatable` only.
- `category`: `story`, `dungeon`, `class`, `profession`, or uncategorized side content.

A one-time story quest is therefore `normal` + `story`. A repeatable dungeon task is `repeatable` + `dungeon`. Do not introduce `story`, `dungeon`, or `weekly` as a quest type without first extending the shared systems and UI. Main-story progression must never depend on a daily reset or repeatable grind.

## 3. Canonical world and naming baseline

### Names that require normalization

| Current canonical name | Legacy or conflicting form | Rule |
|---|---|---|
| Chieftain Thork | Thork Hellscream | Use Chieftain Thork. Treat the surname as obsolete unless deliberately restored. |
| Valeria | Velaria | Current unit variable, qXXX library, and Elarindor story use Valeria. “Velaria” is a legacy alias or possibly a different character; do not merge identities silently. |
| Garthork | Gar'thork | Use Garthork in current code and player-facing text. |
| Outcast Jin'Zun | Jin'Zun variants | Use Outcast Jin'Zun on first reference and Jin'Zun afterward. |
| Emberpeak Highlands | Emperpeak | Use Emberpeak; the other spelling survives in some voice evidence only. |
| Deadwoods | Dead Woods | Use Deadwoods. |

### Existing named-unit evidence

These rawcodes or named globals are evidence that the character already exists in the map data. They do not, by themselves, prove the final location or active trigger state.

| Character | Rawcode evidence | Planned role |
|---|---:|---|
| Chieftain Thork | `O606` | Horde authority and Act I progression gate |
| Ragno | `o61L` | Sereneglade outpost commander and repeatable hub |
| Granis | `o60F` | Thornwoods military quest giver; Rol'jin and outpost defense |
| Garthork | `o60A` | Shadowmoon shaman; magical investigation and Nazgrek lore |
| Krezgrel | `o608` | Thornwoods/Horde supporting quest giver; exact GUI role to recover |
| Grim | `o60C` | Existing quest-giver candidate; exact GUI story to recover |
| Grum Bloodfang | `o62R` | Emberpeak dragon-hunt chain |
| Outcast Jin'Zun | `o60X` | Sereneglade/Crypt nature and undeath side story |
| Drek'thor | `o60D` | Thornwoods supporting quest giver; exact GUI role to recover |
| Ogmar | `o612` | Existing supporting NPC; verify current placement and triggers |
| Erduk | `o61C` | Existing quest-giver candidate; exact GUI story to recover |
| Graknar | `o61S` | Existing supporting NPC; verify current placement and triggers |
| Boom Brothers | `n013` | Sirensong engineering chain and Boom Mine dungeon |
| Atex Blix | `n01A` | Boom-chain contractor, betrayer, and dungeon boss identity |
| Kribugs | `n61E` | Comic Ogre side-quest hub |
| Prince Zaekolaerr | `n62W` | Satyr diplomacy branch endpoint and manipulator |
| Aradion | `h00A` | Elarindor leader and late-midgame story hub |
| Valeria | `n01W` | Elarindor ranger, companion, and story quest giver |

Granis, Garthork, Boom Brothers, Grum Bloodfang, Erduk, Grim, Valeria, and other characters still have unexported GUI triggers in the map. Recover those triggers before deleting, replacing, or claiming full parity with their legacy quests.

## 4. Zone progression and narrative use

`Zones/ZonesCore.j` is the location authority for zone IDs, hierarchy, levels, factions, and named bosses. Every new quest must record a zone ID and, when known, a concrete rect, unit, subzone, cave, or dungeon objective location.

| Level band | Zone IDs and hubs | Narrative and quest use |
|---|---|---|
| 1–9 | Sereneglade `2`, Twilight Grove `1` | Prologue, Ragno, Jin'Zun, Kribugs, early Horde contact, wildlife and local-threat quests |
| 1–10 | Thornwoods `6`, Stonetooth Camp `601`, Bloodtusk Tribe `602`, Horde Scout Base `8810` | Chieftain Thork, Granis, Garthork, Rol'jin, murloc and gnoll pressure, Horde acceptance |
| 5–15 | Havenwoods `7`, Bonecrush Stronghold `8`, Riverbane `10`, inns/cellars `12010`–`12021` | Alliance/Ogre/Bonecrusher relations, patrols, trade, and faction consequences |
| 5–14 | Ghostwalk Ridge `19`, Ironspine Post `1901`, Deadwoods `11`, Crypt `102` | Shadowclaw tragedy, corruption, undeath, Jin'Zun follow-up, and Dawnhold approach |
| 10–18 | Felfire Bastion `12`, Felfire Citadel `1201`, Stormhaven `13`, Dawnhold `20` | Fel escalation, refugees, necromancer activity, outpost and ship-repair progression |
| 10–20 | Sirensong Isles `14`, Mok'natha `1401`, Zul'Garok Ruins `1402`, Urgmar `1403`, Serpentshore `1404`, Zul'Gurak `15` | Boom Brothers, goblins, naga/hydra pressure, island factions, Boom Mine `104` |
| 15–20 | Verdant Plains `17`, Chimairo's Roost `1701`, Weeping Hollow `1702`, Redwind Pass `1703`, settlement TBD `1704`, Vael'Anorath `1705`, Vanguard Vale `9` | Elarindor, Aradion, Valeria, mana rifts, satyrs, void escalation |
| 20–30 | Dragonfire Peaks `4`, Ashfang Outpost `401`, Wyrmfall `402`, Morgrim's Claim `403`, Maw of Cinders `404`, Ashfang Falls `405` | Grum's dragon chain, Dark Horde, dragons, elemental crisis, endgame assaults |
| Dungeon/endgame | Gnoll Hideout `101`, Wyrmhold Sanctum `103`, Firelands `105`, Dreadforge `106` | Major story reveals, boss conclusions, and replayable dungeon objectives |
| Competitive | Coliseum of Ages `18`, Circle of Blood `21` | Optional arena introductions, daily trials, and reputation outcomes |
| Local caves | Cinderfall `12110`, Wolf Den `12111`, Shadowmaw `12112`, Kobold Mine `12113`, Blazehollow `12114` | Focused normal, daily, and repeatable quest destinations |

Zone `1704` still has a placeholder settlement name. Do not make its name part of quest IDs or voiced dialogue until the zone is named.

## 5. Current implementation ledger

This section records current qXXX content at the time this plan was created. Update it whenever a quest is added, removed, renamed, or materially restructured.

### Main and character quest libraries

| Library / giver | Current quests | Status and important dependencies |
|---|---|---|
| `qRagno.j` | Protect the Outpost; Gnoll Headcount; Lumberjack Duties; Kobold Thieves; Satyr Negotiations; Call of the Horde | **Implemented JASS.** Protect the Outpost is externally started and auto-completed by its scripted defense. The current `QUEST_MOUNTAIN_DEFENSE` alias shares this same QuestData instead of defining a second battle. Satyr Negotiations currently reaches Zaekolaerr and immediately resolves after the dialogue choice; the arena, escape, betrayal, and trust consequences are not implemented. Call of the Horde requires Protect the Outpost and an external unlock. |
| `qChieftainThork.j` | Duty For The Horde | **Implemented JASS, partial chain.** It waits for completion signals from Granis and Garthork tasks, but their modern qXXX libraries are absent. Later Thork branches remain external/legacy. |
| `qAradion.j` | Ranger Missing; Crystals of Hope; Fading Sparks; Rifts of Corruption | **Implemented JASS.** Ranger Missing leads to two parallel collection/investigation quests, then Rifts requires all three. Uses Vanguard Vale, Verdant Plains, and Redwind Pass. Test quests are disabled. Valeria's post-reunion Dash rawcode remains a TODO. |
| `qValeria.j` | Token of Love; Lost Supplies | **Implemented JASS.** Token follows Ranger Missing; Lost Supplies follows Token. Uses dedicated token and seven supplies rects. |
| `qOutcastJinzun.j` | Plague Upon Trees; Lurking In The Shadows; Unknown Entity; Seeds of Life; Resurgence of Dead I; Resurgence of Dead II; Da Fishing Pole Missing | **Implemented JASS.** Forms a nature-to-undeath side arc through tree runes, lake, dead trees, graveyard, Zaekolaerr inquiry, and Crypt-facing escalation. |
| `qKribugs.j` | Ogre Lost His Sandwich; Kribugs Lost His Satchel; Ogre Is Very Thirsty; Meat For The Ogre; Ogre Ate Too Much; Angry Customers | **Implemented JASS.** Three early normals, two repeatables, and one gnoll-kill follow-up. Keep as comic relief rather than a main-story gate. |
| `qANightToRemember.j` | A Night To Remember | **Implemented JASS.** Repeatable, zone-aware social quest with three witnesses and randomized make-amends tasks. It is an optional character vignette, not a canonical story requirement. |
| `qZaekolaerr.j` | Satyr Negotiations and fishing-pole dialogue endpoints | **Partial support.** It does not own a QuestData definition. Treat it as an external dialogue endpoint until the satyr branch is implemented deliberately. |

At this revision, the core named qXXX libraries do not consistently assign the new content categories. The Story/Dungeon labels in this plan are design intent until an explicit category pass is implemented and validated.

### Generic vendor quests

`QuestsAndDialogs/QuestGivers/Vendors/README.md` is the implementation ledger for the vendor quest set. It currently records 58 quests across 50 qVendor libraries: 43 Daily and 15 Normal. Keep that README authoritative for exact vendor quest titles, rawcodes, objectives, and setup.

The generic quest plan below complements that set; it must not recreate an existing vendor task under a second quest ID. Exact vendor and generic-NPC placements must be checked in World Editor because the source repository does not provide a complete placement inventory.

### Existing runtime systems tied to planned content

| System | Current evidence | Design consequence |
|---|---|---|
| Boom Mine | `DungeonBoomBrothersMine.j` registers zone `104`, patrol waves, and explosive/barrel events. | The Boom Brothers chain can lead into a real dungeon rather than a disconnected narrative instance. |
| Mad Blix | `BossMadBlix.j` contains a recoverable mana-absorption mechanic; legacy phase files are empty. | Mark the boss **Partial**. Design additional mechanics only after testing the current encounter and recovering GUI evidence. |
| Rol'jin | `BossRoljin.j` exists. | Granis's voiced Rol'jin hunt can target an existing boss encounter. |
| Quest journal | `QuestMaster`, `QuestGiver`, `QuestsGeneric`, and `QuestUI` expose quest type/category and live objectives. | New story and dungeon quests should set their categories instead of relying only on title or description. |

## 6. Story pillars and player role

Nazgrek is an outcast shaman who refused Mannoroth's blood while his clan fell. He enters Sereneglade with Shadowclaw seeking spiritual and natural sanctuary, then has to decide what strength, loyalty, and Horde identity mean without surrendering to corruption.

The main themes are:

- **Belonging without obedience:** Nazgrek earns trust but is not required to accept every cruel or shortsighted order.
- **Strength versus exploitation:** demons, satyrs, necromancers, the Dark Horde, and reckless engineers all turn living or elemental power into a tool.
- **Stewardship of spirits and land:** shaman class quests and regional stories should change how Nazgrek understands the elements, ancestors, beasts, and dead.
- **Consequences with convergence:** choices alter dialogue, support, reputation, patrols, and encounter assistance while the main geographical journey remains buildable.
- **Companions are story anchors:** Shadowclaw carries the early emotional arc; Valeria and faction allies expose later moral and magical stakes.

Daily and repeatable quests should reinforce these themes locally, but they are gameplay texture rather than mandatory canon.

## 7. Proposed coherent story arc

The following is the recommended canonical synthesis. Existing quest titles are retained where practical. Design IDs are planning references, not current QuestData IDs.

### Story flow overview

```text
Prologue: Nazgrek + Shadowclaw in Sereneglade
    -> Ragno's outpost defense
    -> Call of the Horde
    -> Duty For The Horde
       -> Granis military task ----\
       -> Garthork spirit task -----+-> Gnoll / satyr truth -> accepted but tested
       -> Satyr choice -------------/
    -> Ghostwalk and Deadwoods: Shadowclaw + corruption
    -> Stormhaven / Sirensong: allies, ship, Boom Mine, regional threats
    -> Elarindor: Aradion + Valeria + mana rifts
    -> Emberpeak / Dragonfire: dragons, Dark Horde, elemental exploitation
    -> Wyrmhold / Firelands / Dreadforge finale and Nazgrek's choice
```

### Prologue — The outcast and the wolf (levels 1–3)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-P-01 | Intro cinematic: Nazgrek and Shadowclaw | **Partial / current voice evidence** | Establish the blood-refusal backstory, the bond with Shadowclaw, and Sereneglade as a hoped-for sanctuary. Keep exposition short and let the first hunt teach controls. |
| ST-P-02 | First signs of unrest | **Proposed** | A short wildlife/gnoll trail sends the player toward Ragno. This can absorb a valid recovered objective from Articy's “Nazgrek's Flask” only if the GUI/map evidence supports it. |
| ST-P-03 | Protect the Outpost | **Implemented JASS** | First visible act of service. Ragno survives, notices Nazgrek, and becomes the early repeatable hub. |

Do not make “Nazgrek's Flask” mandatory from its Articy title alone; its reliable current objectives have not been recovered.

### Act I — Earning a place (levels 3–10)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A1-01 | Call of the Horde | **Implemented JASS** | Carry Ragno's blood-signed letter to Chieftain Thork after the defense. |
| ST-A1-02 | Duty For The Horde | **Implemented JASS, partial dependencies** | Thork requires proof from both Granis and Garthork. It is the Act I spine, not a generic reputation grind. |
| ST-A1-03 | Punish the Traitor / Rol'jin's Head | **Legacy voice + GUI evidence** | Granis sends Nazgrek to kill Rol'jin and return his head. Confirm the exact old title, reward, rects, and completion event before creating `qGranis.j`. |
| ST-A1-04 | The Magical Eye | **Legacy voice + GUI evidence** | Garthork identifies Nazgrek's Thunderlord past and requests Mur'gal's eye. Use the task to introduce spiritual sight and hint that local aggression is being directed. |
| ST-A1-05 | Defense of the Mountain Outpost | **Legacy voice + Articy evidence; reconciliation required** | Granis sends Nazgrek back to Ragno for a later defense. This must be a distinct second assault with a new QuestData ID, or its dialogue must be folded into Protect the Outpost. Do not alias both battles to one state. |
| ST-A1-06 | Gnoll camp clue → Gnoll Hideout | **Legacy Articy; proposed bridge** | A southern-camp objective reveals stolen Horde resources and an external organizer, then unlocks dungeon `101`. The dungeon book/ledger becomes story evidence instead of a standalone collectible. |
| ST-A1-07 | Satyr Negotiations | **Implemented opening, partial branches** | Zaekolaerr offers an arena test, a hostile rupture/escape, or apparent cooperation. Record the outcome as durable story state and let all routes converge on proof that Zaek is manipulating both factions. |
| ST-A1-08 | Thork's judgement | **Proposed** | Thork evaluates Granis, Garthork, dungeon, and satyr outcomes. Nazgrek gains conditional standing with the Horde and a route toward Ghostwalk Ridge. |

Recommended satyr consequences:

- **Arena:** complete an optional combat trial; earn respect and cleaner access to Zaek's information.
- **Hostile rupture:** escape satyr territory and report to Granis; later satyr patrols are more aggressive.
- **False alliance:** perform one morally suspicious reconnaissance task, discover the planned betrayal, then expose or reject Zaek. Do not require killing Ragno or burning the Horde base as an irreversible main-story action.

Legacy concepts such as draining orc life, killing Ragno, and setting the base on fire can survive as threatened outcomes, illusions, failed-state content, or an explicitly selected dark branch. They should not silently replace the stable Act I hub.

### Act II — The wolf and the wound (levels 8–15)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A2-01 | A Howl Silenced | **Legacy Articy** | Shadowclaw behaves erratically or vanishes near Ghostwalk Ridge. Begin with tracking, not immediate villain framing. |
| ST-A2-02 | Blood Trail | **Legacy Articy** | Follow signs through Wolf Den `12111` and Ironspine approaches; connect wildlife corruption to the wider force. |
| ST-A2-03 | Broken Chains | **Legacy Articy** | Reveal attempted control, imprisonment, or corruption of beasts and spirits. Recover any map-specific captor before choosing the antagonist. |
| ST-A2-04 | Curse of Ghostridge | **Legacy Articy** | Garthork/Jin'Zun helps identify the curse. Give the player a cleansing attempt and evidence that death/fel/void forces overlap. |
| ST-A2-05 | Whispers in the Void | **Legacy Articy** | The first explicit void clue points toward later Elarindor mana rifts without revealing the full antagonist. |
| ST-A2-06 | Lair of Rage | **Legacy Articy** | Confront the controller or corrupted pack in a bespoke lair/world event. |
| ST-A2-07 | Shadowclaw's Demise | **Legacy Articy cinematic** | Recommended canon: the cure fails or succeeds only spiritually; Shadowclaw dies free and later returns as an ancestral guide motif. Do not implement the death until companion-system cleanup, future summon behavior, and cinematic state are designed together. |
| ST-A2-08 | Deadwoods and the Ghost | **Proposed synthesis** | Route Ironspine Post into Deadwoods, Jin'Zun's resurgence/Crypt content, and the threatened road to Dawnhold. |

The “Chains of Seduction” and fight against “Velaria” concept is **Blocked by decision**. Current Valeria is an Elarindor ranger and companion. Determine whether the Articy figure was an obsolete version of Valeria, a disguised satyr, or a separate character before reusing any part of that chain.

### Act III — Roads, islands, and uneasy allies (levels 10–18)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A3-01 | Ironspine supply and scouting chain | **Legacy Articy / proposed consolidation** | Combine Scouting Party, Totems of Strength, Supply Lines, Wandering Berserker, and Fel Contamination into a focused route through Deadwoods, Felfire, and Stormhaven. Avoid five unrelated fetch quests. |
| ST-A3-02 | Dawnhold curse | **Legacy Articy** | Investigate the necromancer threat and the “Gar the Mighty Giant” lead. Decide whether Gar is ally, victim, or boss after recovering map triggers. |
| ST-A3-03 | The Goblin Negotiator / Fix the Ship | **Legacy Articy** | Secure passage to or from Sirensong. Outcomes from the Boom Brothers and local goblin reputation reduce cost or create an alternate repair solution. |
| ST-A3-04 | Sirensong regional arc | **Proposed synthesis** | Link Mok'natha, Zul'Garok Ruins, Urgmar, Serpentshore, Kelziss, and Jinnvorrak through raids, ruins, and a growing naga/hydra threat. |
| ST-A3-05 | Boom Brothers chain | **Legacy voiced design + partial dungeon** | A comedic engineering story becomes useful to the main route because its explosives or tools open a blocked passage/ship repair. Completion grants free or friendly Boom Mine access, not a mandatory grind. |
| ST-A3-06 | Felfire evidence | **Proposed synthesis** | Evidence from the Citadel shows the corruption is organized and linked to elemental/dragon exploitation farther east. |

Boom Brothers legacy sequence to preserve when converting `qBoomBrothers.j`:

1. **Explosive Crisis** — recover or replace stolen explosive barrels.
2. **Boomsite Compliance Inspection** — obtain ten suitable logs through Atex Blix.
3. **Dust Isn't Just Dirt — It's Combustible Culture** — install or recover ventilation, filter, blower, and vacuum parts.
4. **Mandatory Training** — escort the crew to a kobold safety camp; Blix betrays them and takes the mine.
5. **Boom Will Be Back** — defeat Mad Blix in Boom Mine `104` and reclaim it.

Exact item rawcodes, objective rects, failure handling, and rewards must come from the unexported GUI triggers and WE data.

### Act IV — Rifts of Elarindor (levels 15–20)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A4-01 | Ranger Missing | **Implemented JASS** | Find and escort Valeria; combat or negotiation establishes the player's approach. |
| ST-A4-02 | Token of Love → Lost Supplies | **Implemented JASS side chain** | Humanizes Valeria and rewards exploration without gating Aradion's main chain. |
| ST-A4-03 | Crystals of Hope | **Implemented JASS** | Stabilize Elarindor using Vanguard Vale mana crystals. |
| ST-A4-04 | Fading Sparks | **Implemented JASS** | Use Tel'anor's Rod against wraiths; connect Deadwoods/void clues to Elarindor's crisis. |
| ST-A4-05 | Rifts of Corruption | **Implemented JASS** | Aradion and Valeria perform three rift rituals. This is the Act IV convergence and should expose the endgame source or route. |
| ST-A4-06 | Weeping Hollow / Vael'Anorath consequence | **Proposed** | Use the player's satyr choice and ritual success to alter assistance, enemy composition, and dialogue in Verdant Plains. |
| ST-A4-07 | Chimairo and Morthun | **Proposed zone story** | Optional elite/world-boss arc that proves whether the land is healing; do not make trophy farming a story gate. |

### Act V — Fire, blood, and balance (levels 20–30)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A5-01 | Whelps of Destruction | **Legacy voiced design** | Grum Bloodfang sends Nazgrek for whelp scales in Emberpeak. Frame it as threat assessment, not indiscriminate extermination. |
| ST-A5-02 | Dragon Egg Hunt | **Legacy voiced design** | Recover eggs; Grum's suspicious handling creates a trust question and later consequence. |
| ST-A5-03 | Drake Hunt | **Legacy voiced design** | Kill corrupted/aggressive drakes and survive a possible drake ambush. |
| ST-A5-04 | The Desolator | **Legacy voiced design** | Defeat Mordrax and recover the shattered scale. Confirm the boss's current location and encounter state in WE. |
| ST-A5-05 | Ashfang and Morgrim fronts | **Proposed synthesis** | Morgrok, Morgrim's Claim, Wyrmfall, Maw of Cinders, and Scorchion expose competing Dark Horde and elemental operations. |
| ST-A5-06 | Wyrmhold Sanctum | **Proposed dungeon story** | Confront Dragon Mother Seretha and decide how surviving eggs/dragons factor into the final assault. |
| ST-A5-07 | Firelands / Dreadforge | **Proposed endgame** | Stop the exploitation of elemental power and the forge supplying the campaign. Use the selected final dungeon order to provide distinct allies or encounter advantages. |
| ST-A5-08 | Path of the Shaman | **Proposed finale** | Nazgrek rejects borrowed corruption, restores a damaged spiritual covenant, and defines his relationship with the Horde. Prior choices change who stands with him and the epilogue, not whether the finale is reachable. |

Act III in Articy is empty. The Act IV–V structure above is therefore a new synthesis from current zones, bosses, and implemented Elarindor content, not recovered canon.

## 8. Class and companion arcs

### Shaman progression

The Articy bank contains Elemental Fire, Water, Air, Earth, Ghost Wolf, Ancestral Ward, and Totemic Resurgence. Implement these as `normal` + `class` quests tied to story revelations, not as seven disconnected trainer errands.

| Stage | Class quest | Recommended story connection |
|---|---|---|
| Early | Water / Earth | Jin'Zun's damaged trees and Garthork's spirit-sight lesson |
| Mid | Air / Ghost Wolf | Ghostwalk tracking and Shadowclaw's spiritual bond |
| Mid-late | Ancestral Ward / Totemic Resurgence | Shadowclaw aftermath, Deadwoods spirits, and Elarindor rifts |
| Late | Fire | Emberpeak and Firelands; master fire without repeating the enemy's exploitation |

Ability rewards, rawcodes, and actual trainer ownership require separate design against the current ability system.

### Companion rules

- Story companions must have explicit join, leave, death, revive, and quest-abandon behavior.
- A companion should not be required for a daily/repeatable quest unless the system can restore that companion reliably.
- Shadowclaw's planned demise requires a defined replacement for any combat ability, tracker, or dialogue that assumes the wolf still exists.
- Valeria's current identity and Elarindor allegiance are canonical until an explicit rewrite says otherwise.

## 9. Planned generic and regional quest bank

These are candidates, not promises. Before implementation, search the vendor README and existing qXXX files for overlaps, choose a placed WE unit or create a deliberate new NPC, and replace broad locations with exact rects or units.

“Existing generic WE role” means a suitable guard, scout, hunter, worker, vendor, or resident is expected in the map but its exact placed instance must be selected in World Editor. “New” means the NPC may be created if no existing unit fits.

### Sereneglade and Twilight Grove

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-001 | Lake Without Ripples | Normal | Existing fisher or new Sereneglade net-mender | Sereneglade lake | Investigate poisoned fish and refer the player to Jin'Zun; early environmental foreshadowing. |
| GQ-002 | Scales and Stingers | Daily | Existing hunter | Sereneglade salamander/crab areas | Cull local threats; purely optional hub upkeep. |
| GQ-003 | Shoreline Provisions | Repeatable | Existing cook/vendor | Sereneglade shore | Turn in common meat or shellfish; check vendor quests first. |
| GQ-004 | Roots That Remember | Normal | New Twilight spirit tender | Twilight Grove ancient trees | Place wards or listen at roots; hints that beasts are reacting to distant corruption. |
| GQ-005 | Predators in the Mist | Daily | Existing Grove sentinel | Twilight Grove wolf/bear areas | Rescue travelers or kill marked predators without targeting Shadowclaw's pack identity. |
| GQ-006 | Twilight Samples | Repeatable | Existing herbalist | Twilight Grove | Gather non-unique samples used by Garthork/Jin'Zun research. |

### Thornwoods and Gnoll Hideout

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-007 | Murloc Fins | Daily | Existing Horde cook/quartermaster | Thornwoods shore | Articy daily candidate; verify it does not duplicate vendor objectives. |
| GQ-008 | Rescue the Grunts | Daily | Existing Horde medic | Thornwoods patrol routes | Recover living patrol members; reinforces the cost of local attacks. |
| GQ-009 | The Big Bear Tooth | Daily | Existing hunter | Thornwoods wildlife area | Articy daily candidate and trophy hunt. |
| GQ-010 | The Road to the Scout Base | Normal | Granis or existing scout | Route to Horde Scout Base `8810` | Clear ambush points and unlock safe travel/patrol visibility. |
| GQ-011 | Teeth Beneath the Hill | Normal + Dungeon | Granis | Gnoll camp → Gnoll Hideout `101` | Breadcrumb quest for the dungeon and its stolen-resource clue. |
| GQ-012 | Deathlord Fel'Dok | Normal + Dungeon | Granis or dungeon survivor | Gnoll Hideout `101` | Kill the dungeon boss; spelling must match current object/boss data. |
| GQ-013 | Stolen Horde Stores | Daily + Dungeon | Horde quartermaster | Gnoll Hideout `101` | Recover supplies after the first clear; never gates story progress. |
| GQ-014 | The Stolen Ledger | Normal + Story + Dungeon | Garthork | Gnoll Hideout `101` | One-time evidence objective feeding the Act I conspiracy reveal. |

### Ghostwalk Ridge, Ironspine, Deadwoods, and Crypt

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-015 | Watchfires in the Fog | Daily | Existing Ironspine guard | Ironspine Post `1901` approaches | Relight posts and report unusual tracks; supports Shadowclaw arc atmosphere. |
| GQ-016 | The Mine That Whispers | Normal | Existing miner or new prospector | Cinderfall Cave `12110` | Rescue workers and recover a corrupted ore sample for Garthork. |
| GQ-017 | Wolf Hunt I–III | Normal chain | Existing hunter | Ghostwalk Ridge / Wolf Den `12111` | Recover Articy's optional chain as tracking and pack-behavior study, not generic wolf slaughter. |
| GQ-018 | Cinderfall Cores | Repeatable | Existing smith | Cinderfall Cave `12110` | Optional materials after GQ-016; check profession quests before implementation. |
| GQ-019 | Whispering Tombs | Normal + Dungeon | Jin'Zun or Deadwoods survivor | Crypt `102` | Introduce the Crypt through voices leaking into Deadwoods. |
| GQ-020 | Restless Souls | Daily + Dungeon | Spirit speaker | Crypt `102` | Release marked spirits; rotate targets only if the objective system supports it cleanly. |
| GQ-021 | Secrets of the Necromancer | Normal + Story + Dungeon | Garthork / Dawnhold contact | Crypt `102` | Recover evidence connecting undead work to the wider corruption. |
| GQ-022 | Grave Wax | Repeatable | Existing alchemist | Deadwoods / Crypt `102` | Optional reagent turn-in; must not compete with a unique story drop. |

### Havenwoods, Bonecrush Stronghold, and Riverbane

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-023 | Nets and Nails | Normal | Existing Havenwoods resident | Havenwoods shore/settlement | Repair defenses against murlocs; introduces civilians before faction conflict. |
| GQ-024 | Boar for the Table | Daily | Existing Havenwoods cook | Havenwoods | Local supply quest; check the vendor ledger for meat overlap. |
| GQ-025 | Trial of Weight | Normal | Existing Bonecrusher envoy or new arena keeper | Bonecrush Stronghold `8` | Nonlethal Ogre audience test that can open dialogue instead of forced hostility. |
| GQ-026 | Bonecrusher Stores | Repeatable | Existing Ogre worker | Bonecrush Stronghold outskirts | Exchange supplies for local reputation or access; rewards require economy design. |
| GQ-027 | Missing at the Bend | Normal | Existing Riverbane innkeeper/guard | Riverbane road and river | Find a caravan or patrol and expose bandit/Horde tension. |
| GQ-028 | River Teeth | Daily | Existing fisher | Riverbane banks | Kill river predators or recover traps; avoid duplicating a vendor fishing quest. |
| GQ-029 | The Cellar Ledger | Repeatable | Riverbane innkeeper | Riverbane cellar `12011` | Recover stolen stock/records from a resettable cellar encounter. |

### Emberpeak and Dragonfire

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-030 | Hearts of Stone | Normal | Grum or existing shaman | Emberpeak golem area | Recover golem hearts for analysis; Articy “Golem Hearts” can support the Colossus reveal. |
| GQ-031 | The Colossus Wakes | Normal | Grum / Emberpeak defender | Emberpeak Highlands `3` | Optional elite conclusion after GQ-030. |
| GQ-032 | Ashfang Supply Lines | Daily | Ashfang quartermaster | Ashfang Outpost `401` routes | Protect or recover endgame supplies; reacts to Morgrok story state. |
| GQ-033 | Bones of Wyrmfall | Repeatable | Existing dragon scholar | Wyrmfall `402` | Collect non-unique remains after area unlock; no living-dragon genocide framing. |
| GQ-034 | Morgrim's Broken Constructs | Daily | Existing sapper/shaman | Morgrim's Claim `403` | Disable or salvage marked constructs. |
| GQ-035 | Venom at the Falls | Normal | Ashfang scout | Ashfang Falls `405` | Investigate Scorchion and unlock its elite encounter. |
| GQ-036 | Blazehollow Cores | Repeatable | Existing forge worker | Blazehollow Cave `12114` | Endgame crafting support; check profession-item ownership. |

### Sirensong, Stormhaven, Dawnhold, and Verdant regions

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-037 | Songs Beneath the Surf | Normal | Existing Mok'natha shaman | Sirensong / Serpentshore `1404` | Investigate enthralled scouts and foreshadow Kelziss. |
| GQ-038 | Serpentshore Venom | Daily | Existing healer | Serpentshore `1404` | Gather antidote components or kill marked venomous creatures. |
| GQ-039 | Totems of Zul'Garok | Repeatable | Existing historian | Ruins of Zul'Garok `1402` | Recover common fragments; unique inscription reserved for story. |
| GQ-040 | Shadowmaw Bounty | Normal | Existing Urgmar hunter | Shadowmaw Cave `12112` | Clear a named threat and make the cave a deliberate destination. |
| GQ-041 | Dawnhold Refugees | Normal | Existing Stormhaven healer | Dawnhold road / Stormhaven | Escort or provision survivors, establishing the curse's human cost. |
| GQ-042 | Smoke Over the Road | Daily | Existing Stormhaven guard | Stormhaven approaches | Break ambushes or signal fires after the route opens. |
| GQ-043 | The Last Bell | Normal | New Dawnhold survivor | Dawnhold `20` | Ring or recover a ward bell during a one-time undead event. |
| GQ-044 | Wards of Weeping Hollow | Normal | Aradion or existing Elarindor keeper | Weeping Hollow `1702` | Stabilize a side effect of the rifts and reflect prior ritual success. |
| GQ-045 | Wraith Control | Daily | Existing Vanguard ranger | Vanguard Vale `9` | Contain residual wraiths after Fading Sparks; unlock only after that story beat. |
| GQ-046 | Relics of Elarindor | Repeatable | Existing Elarindor archivist | Vanguard/Verdant ruins | Recover common fragments; do not reuse quest-critical mana crystals. |
| GQ-047 | Chimairo's Challenge | Normal | Existing Verdant hunter | Chimairo's Roost `1701` | Optional world-boss introduction with a non-repeatable narrative reward. |

### Arenas

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-048 | Trial of the Coliseum | Normal | Existing arena master | Coliseum of Ages `18` | Introduce rules and complete Zaek's arena branch if that choice was made. |
| GQ-049 | Blood on the Circle | Daily | Existing arena master | Circle of Blood `21` | Optional daily match; uses arena rewards, not story progression. |
| GQ-050 | A Champion Remembered | Repeatable | Existing arena historian | Either arena | High-tier challenge with cooldown only if a safe cooldown/reset rule exists. |

## 10. Dungeon quest packages

Each dungeon should eventually have a small package rather than one isolated kill quest:

1. a one-time breadcrumb quest that establishes why the player enters;
2. a one-time story or boss conclusion;
3. zero to two optional daily/repeatable objectives using non-unique drops or rotating targets;
4. a durable completion signal for later dialogue/world state.

| Dungeon | One-time story role | Replayable role | Current state |
|---|---|---|---|
| Gnoll Hideout `101` | Act I stolen resources/ledger and Deathlord Fel'Dok | Supplies, rescues, or marked elites | Zone exists; story package proposed |
| Crypt `102` | Jin'Zun resurgence, necromancer evidence, cursed relic choice | Restless souls or relic recovery | Zone/boss roster exists; Articy quest bank recovered |
| Wyrmhold Sanctum `103` | Dragon Mother Seretha and dragon-fate decision | Scales/eggs only when lore-safe and non-unique | Zone/boss named; package proposed |
| Boom Mine `104` | Defeat Mad Blix and return the mine | Engineering materials or hazard-clearing | Runtime dungeon partial; boss mechanics incomplete |
| Firelands `105` | Elemental covenant/endgame route | Endgame elemental tasks | Zone and boss references exist; story proposed |
| Dreadforge `106` | Stop demon/fel-orc production and final campaign support | Forge sabotage/material recovery | Zone exists; story proposed |

## 11. Quest-giver and event contracts

Future qXXX libraries should expose explicit hooks rather than reading one another's private globals.

| Producer | Consumer | Required contract |
|---|---|---|
| Protect the Outpost | Call of the Horde | Stable completion state plus the current external unlock event |
| Call of the Horde | Duty For The Horde | Thork sees Ragno's letter/completion without duplicating quest state |
| `qGranis` and `qGarthork` | `qChieftainThork` | Public completion notifications for their assigned proof quests; preserve retries and failure cleanup |
| Satyr Negotiations / Zaekolaerr | Later Granis, Elarindor, and Verdant dialogue | One durable outcome enum/flags, not title-string comparisons scattered across libraries |
| Gnoll Hideout story quest | Thork judgement | Dungeon evidence completion signal independent of replayable dungeon tasks |
| Shadowclaw arc | Companion and ability systems | Explicit join/leave/death/spiritual-successor state before the demise cinematic |
| Boom Brothers chain | Boom Mine and Mad Blix | Dungeon unlock, crew escort outcome, boss completion, and mine ownership/access state |
| Jin'Zun/Crypt | Deadwoods/Dawnhold | Undeath evidence state that later NPCs can acknowledge |
| Rifts of Corruption | Verdant and endgame arcs | Ritual outcome and any damaged/saved rift state |
| Grum dragon chain | Wyrmhold/Dragonfire | Egg treatment, Mordrax completion, and dragon-allegiance consequences |

Recommended shared story-state practice:

- Give important choices stable constants or a small owning state library.
- Expose semantic functions such as `SatyrStory_GetOutcome()` instead of sharing qXXX private globals.
- Separate one-time story completion from repeatable dungeon completion.
- Save state if the campaign/save system requires the consequence after reload.
- Let branches modify future dialogue, faction reputation, support units, patrol ownership, shortcuts, and encounter assistance.
- Provide a recovery route when a branch removes a convenient NPC or hub service.

## 12. Legacy content requiring recovery

Before implementing the following, export or inspect the old GUI triggers and compare them with current units, regions, items, and voice constants:

| Owner | Known recoverable intent | Still needed |
|---|---|---|
| Granis | Rol'jin hunt; later mountain-outpost defense | Exact titles, conditions, rects, rewards, boss completion event, relation to Protect the Outpost |
| Garthork | Nazgrek/Shadowmoon greeting; Magical Eye from Mur'gal | Mur'gal unit identity, eye item, objective tracking, reward, follow-up |
| Boom Brothers / Atex Blix | Five-step Boom Mine chain | Exact items, escort route, failure/retry behavior, mine access flags, Mad Blix phases |
| Grum Bloodfang | Whelps, eggs, drakes, Mordrax | Exact counts/items, boss identity/location, reward and egg consequence |
| Erduk | Existing named quest giver | Entire active GUI quest set, placement, and intended arc |
| Grim | Existing named quest giver | Entire active GUI quest set, placement, and intended arc |
| Valeria | Current qValeria plus unexported legacy triggers | Identify which legacy objectives remain missing and whether any use obsolete “Velaria” characterization |
| Other Horde NPCs | Krezgrel, Drek'thor, Ogmar, Graknar and related triggers | Inventory before assigning new generic quests to avoid ownership conflicts |

## 13. Open canon and implementation decisions

Resolve these deliberately and record the answer here:

1. **Valeria versus Velaria:** one revised character, two characters, or obsolete Articy identity?
2. **Mountain outpost defenses:** is the Articy/Granis defense a second battle after Ragno's current Protect the Outpost?
3. **Shadowclaw's fate:** permanent death, spiritual transformation, or player-influenced outcome? What replaces gameplay dependencies?
4. **Zaekolaerr branch limits:** which dark actions are playable, threatened, or discarded, and how can the main hub remain usable?
5. **Main antagonist:** which force connects gnolls, satyrs, undead, void rifts, Dark Horde, and elemental exploitation without making every faction secretly identical?
6. **Granis/Garthork task ownership:** exact QuestData titles and public completion hooks expected by `qChieftainThork`.
7. **Act III settlement `1704`:** final name, faction, services, and narrative purpose.
8. **Dawnhold's Gar:** ally, cursed victim, boss, or obsolete Articy concept?
9. **Grum and the eggs:** protective plan, reckless weaponization, betrayal, or misunderstanding?
10. **Dungeon reset policy:** which objectives are daily versus freely repeatable, and how boss/instance state resets safely.

Recommended antagonist structure: use a coalition or chain of exploitation rather than one controller behind everything. Satyrs exploit local division, necromancers exploit death, the Dark Horde and demons industrialize fel/elemental power, and the void presence opportunistically amplifies the damage. This preserves faction identity while giving Nazgrek one thematic conflict.

## 14. Recommended implementation order

1. Recover Granis and Garthork GUI triggers and create their modern qXXX libraries so Duty For The Horde has real dependencies.
2. Decide and implement the second mountain defense versus current Protect the Outpost.
3. Finish Satyr Negotiations outcome state and one convergent follow-up per choice.
4. Add the Gnoll Hideout one-time package and use its evidence in Thork's Act I conclusion.
5. Audit Shadowclaw's current companion systems, then write the Act II chain without implementing the demise until cleanup/replacement behavior is safe.
6. Convert the Boom Brothers chain against the existing dungeon and recover Mad Blix behavior.
7. Build the Ironspine–Deadwoods–Dawnhold travel/story bridge and connect the implemented Jin'Zun chain.
8. Complete the Sirensong regional arc and ship route.
9. Categorize and validate the implemented Aradion/Valeria quests as story or side-story content, then add their Verdant consequence quests.
10. Recover Grum's chain and design Dragonfire/Wyrmhold/Firelands/Dreadforge as the endgame campaign.
11. Add generic quests zone by zone after checking the vendor ledger and WE placement, prioritizing hubs that currently have no repeatable support.

## 15. Quest design and implementation checklist

Before creating or changing a quest:

- Read this plan, the owning qXXX library, a nearby comparable qXXX library, `Zones/ZonesCore.j`, and the relevant master APIs.
- Search current qXXX and `QuestsAndDialogs/QuestGivers/Vendors/README.md` for duplicate titles, items, targets, or roles.
- Inspect the placed giver, target units, regions, items, and active GUI triggers in World Editor when source evidence is incomplete.
- Record the plan ID, final QuestData ID/title, type, category, level, giver, turn-in NPC, zone ID, exact objective location, prerequisites, and durable story effects.
- Prefer shared QuestGiver objective trackers and dialog wrappers; keep only unique events, spawns, patrols, cinematics, and cleanup in the qXXX library.
- Define accept, decline, in-progress, ready, complete, failed, retry, abandon, and giver-unavailable behavior where relevant.
- Make companion, escort, boss, and dungeon cleanup safe on death, failure, cinematic interruption, and replay.
- Ensure rewards match the quest's role; never require daily/repeatable completion to unlock the main story.
- Set the correct story/dungeon/class/profession category for the custom journal.
- Verify compile success, initialization order, objective tracking, cleanup, dialog re-entry, and prerequisite transitions in a focused test map and then the full map.
- For multiplayer-sensitive UI or synchronized state, test multiplayer behavior explicitly.
- Update this ledger and `_Changelogs/PotS Changelog.md` when implementation status changes.

## 16. Maintenance rules

- Keep working titles until the corresponding dialogue and objectives are approved; do not churn stable QuestData IDs for cosmetic naming changes.
- Never mark a quest **Implemented JASS** from Articy, voice lines, or GUI screenshots alone.
- When a legacy concept is rejected, record the decision and replacement briefly instead of deleting all trace of the conflict.
- When a new NPC is created, add its canonical name, faction, zone, placement, rawcode/global, quest ownership, and later connections to this document.
- When a quest moves zone, update both the quest implementation and this plan; use `ZonesCore` for the final zone identity.
- Keep detailed vendor setup in the vendor README and detailed conversion mechanics in the owning qXXX file. This document should retain the cross-quest story reason and dependency.
- Review the open decisions and implementation ledger after each completed story arc or major zone-content pass.
