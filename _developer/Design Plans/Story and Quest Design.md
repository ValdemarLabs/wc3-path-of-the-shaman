# Story and Quest Design

- **Status:** Living master design plan
- **Created:** 22 August 2026
- **Last reviewed:** 26 August 2026
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
4. Dated design notes under `_developer/_Other/` as legacy brainstorming evidence, not current implementation specifications.
5. `_developer/_articyExports/` as design evidence. Its story and quest objects are marked outdated and must not override current implementation automatically.
6. New proposals in this plan.

An unexported GUI trigger is missing evidence, not permission to invent its exact objectives, rewards, or state transitions. Inspect it in World Editor before converting the affected quest.

### Evidence reviewed for this revision

- `Zones/ZonesCore.j` for active zone IDs, hierarchy, level ranges, factions, caves, dungeons, and named encounters.
- Current `QuestsAndDialogs/QuestGivers/q*.j` libraries and the vendor quest README for implemented QuestData, prerequisites, objective locations, and external hooks.
- Current narrator, Granis, Garthork, Krezgrel, Boom Brothers, Atex Blix, and Grum Bloodfang voice-line libraries for recoverable authored intent.
- Current dungeon/boss libraries for Rol'jin, Boom Mine, and Mad Blix.
- `_developer/_articyExports/Articy XML/Path of the shaman.xml` and the companion document export for flow hierarchy, quest banks, entities, and connections.
- `_developer/_Other/WC3 Pots notes.odt` and `_developer/_Other/WC3 Pots notes other.odt` for older prologue, Shadowclaw, Ghostwalk/Deadwoods, Crypt, and character concepts. The first document has a May 2024 creation timestamp; the second is user-identified as 2024/2025 legacy material.
- `_developer/gui-variables.md` and unit-assignment evidence for named map globals/rawcodes.

The Articy export was useful as a graph, but its story and quest records are marked `Outdated`. Act I contains the densest connected flow, Act II is mostly a loose quest bank, and Act III is empty. Most exported dialogue is placeholder-level except for recoverable Granis material. Articy therefore informs missing intent; it does not certify current names, placement, or implementation.

The ODT notes contain more concrete objectives than Articy for the prologue, Shadowclaw's demise, the Ghostwalk-to-Felfire campaign, and the Crypt. They also use obsolete geography and generic boss names. Their strongest encounter and emotional beats are retained below, while current `ZonesCore`, current rawcodes, and current boss rosters remain authoritative.

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
| Valeria | Some old Elarindor GUI references say Velaria | Use Valeria for the Elarindor ranger and companion. Treat “Velaria” near Aradion or companion logic as a probable old misspelling and verify its unit rawcode. |
| Velyssara | Velaria | Use Velyssara for the separate female satyr/succubus, unit `n636`, and Chains of Seduction antagonist. Keep “Velaria” only as a legacy Articy/GUI search term. |
| Garthork | Gar'thork | Use Garthork in current code and player-facing text. |
| Outcast Jin'Zun | Jin'Zun variants | Use Outcast Jin'Zun on first reference and Jin'Zun afterward. |
| Emberpeak Highlands | Emperpeak | Use Emberpeak; the other spelling survives in some voice evidence only. |
| Deadwoods | Dead Woods | Use Deadwoods. |
| Ghostwalk Ridge | Ghostridge | Use Ghostwalk Ridge for zone `19`. Legacy quest titles may retain Ghostridge only until they receive final player-facing names. |
| Dawnhold | Legacy ruined “Vanguard” city and docks | The map author confirms that the old ruined undead city and docks are current Dawnhold `20`. Vanguard Vale `9` remains Elarindor and must never inherit this legacy content because of the shared “Vanguard” wording. |

`_MISC/war3map.wts` is a read-only export from one point in the map's history, not an editable source of truth. Its remaining “Velaria” unit and Chains of Seduction strings mean the Velyssara rename still requires a manual World Editor change by the map author; a later export may then reflect it.

### Existing named-unit evidence

These rawcodes or named globals are evidence that the character already exists in the map data. They do not, by themselves, prove the final location or active trigger state.

| Character | Rawcode evidence | Planned role |
|---|---:|---|
| Chieftain Thork | `O606` | Horde authority and Act I progression gate |
| Ragno | `o61L` | Sereneglade outpost commander and repeatable hub |
| Granis | `o60F` | Thornwoods military quest giver; Rol'jin and outpost defense |
| Garthork | `o60A` | Shadowmoon shaman; magical investigation and Nazgrek lore |
| Krezgrel | `o608` | Thornwoods grunt commander; Murloc Fins and Rescue The Grunts daily quests |
| Grim | `o60C` | Thornwoods hunter and Big Bear Tooth daily quest giver |
| Grum Bloodfang | `o62R` | Emberpeak dragon-hunt chain |
| Outcast Jin'Zun | `o60X` | Sereneglade/Crypt nature and undeath side story |
| Gar | `n60Z` | Existing Deadwoods unit; legacy notes describe a flesh-golem experiment tied to Dawnhold's necromancer |
| Drek'thor | `o60D` | Thornwoods supporting quest giver; exact GUI role to recover |
| Ogmar | `o612` | Existing supporting NPC; verify current placement and triggers |
| Erduk | `o61C` | Existing quest-giver candidate; exact GUI story to recover |
| Graknar | `o61S` | Bag merchant and Mistaken Kin quest giver; reserve this rawcode for the canonical Graknar and verify his final placement |
| Boom Brothers | `n013` | Sirensong engineering chain and Boom Mine dungeon |
| Atex Blix | `n01A` | Boom-chain contractor, betrayer, and dungeon boss identity |
| Kribugs | `n61E` | Comic Ogre side-quest hub |
| Prince Zaekolaerr | `n62W` | Satyr diplomacy branch endpoint and manipulator |
| Velyssara | `n636` | Female satyr/succubus tied to Chains of Seduction and Zaekolaerr's corruption arc |
| Zul'karak | `n65F` | Existing troll unit; legacy notes describe Zul'kis's warrior brother and a possible later recruit |
| Aradion | `h00A` | Elarindor leader and late-midgame story hub |
| Valeria | `n01W` | Elarindor ranger, companion, and story quest giver |
| Kaelthir | `n01X` | Elarindor wretched survivor whose fate branches between mercy, mana-wraith transformation, and Aradion's failed cure |

Boom Brothers, Erduk, Valeria, and other characters still have unexported GUI triggers in the map. Recover those triggers before deleting, replacing, or claiming full parity with their legacy quests. Granis, Garthork, Krezgrel, Grim, Graknar, and Grum Bloodfang now have recovered trigger exports and modern qXXX conversions.

## 4. Zone progression and narrative use

`Zones/ZonesCore.j` is the location authority for zone IDs, hierarchy, levels, factions, and named bosses. Every new quest must record a zone ID and, when known, a concrete rect, unit, subzone, cave, or dungeon objective location.

| Level band | Zone IDs and hubs | Narrative and quest use |
|---|---|---|
| 1–9 | Sereneglade `2`, Twilight Grove `1` | Prologue, Ragno, Jin'Zun, Kribugs, early Horde contact, wildlife and local-threat quests |
| 1–10 | Thornwoods `6`, Stonetooth Camp `601`, Bloodtusk Tribe `602`, Horde Scout Base `8810` | Chieftain Thork, Granis, Garthork, Rol'jin, murloc and gnoll pressure, Horde acceptance |
| 5–15 | Havenwoods `7`, Bonecrush Stronghold `8`, Riverbane `10`, inns/cellars `12010`–`12021` | Alliance/Ogre/Bonecrusher relations, patrols, trade, and faction consequences |
| 5–14 | Ghostwalk Ridge `19`, Ironspine Post `1901`, Deadwoods `11`, Crypt `102` | Shadowclaw tragedy, corruption, undeath, Jin'Zun follow-up, and Dawnhold approach |
| 10–15 | Emberpeak Highlands `3`, Cinderfall `12110` | Grum's dragon-hunt chain, the Mordrax confrontation, and the unresolved fate of the recovered eggs |
| 10–18 | Felfire Bastion `12`, Felfire Citadel `1201`, Stormhaven `13`, Dawnhold `20` | Fel escalation, refugees, necromancer activity, Dawnhold's ruined undead city and docks, and ship-repair progression |
| 10–20 | Sirensong Isles `14`, Mok'natha `1401`, Zul'Garok Ruins `1402`, Urgmar `1403`, Serpentshore `1404`, Zul'Gurak `15` | Boom Brothers, goblins, naga/hydra pressure, island factions, Boom Mine `104` |
| 15–20 | Verdant Plains `17`, Chimairo's Roost `1701`, Weeping Hollow `1702`, Redwind Pass `1703`, settlement TBD `1704`, Vael'Anorath `1705`, Vanguard Vale `9` | Elarindor, Aradion, Valeria, mana rifts, satyrs, void escalation |
| 20–30 | Dragonfire Peaks `4`, Ashfang Outpost `401`, Wyrmfall `402`, Morgrim's Claim `403`, Maw of Cinders `404`, Ashfang Falls `405` | Dark Horde, dragons, elemental crisis, and endgame assaults that can react to Grum's earlier Emberpeak chain |
| Dungeon/endgame | Gnoll Hideout `101`, Wyrmhold Sanctum `103`, Firelands `105`, Dreadforge `106` | Major story reveals, boss conclusions, and replayable dungeon objectives |
| Competitive | Coliseum of Ages `18`, Circle of Blood `21` | Optional arena introductions, daily trials, and reputation outcomes |
| Local caves | Cinderfall `12110`, Wolf Den `12111`, Shadowmaw `12112`, Kobold Mine `12113`, Blazehollow `12114` | Focused normal, daily, and repeatable quest destinations |

Zone `1704` still has a placeholder settlement name. Do not make its name part of quest IDs or voiced dialogue until the zone is named.

## 5. Current implementation ledger

This section records current qXXX content at the time this plan was created. Update it whenever a quest is added, removed, renamed, or materially restructured.

### Main and character quest libraries

| Library / giver | Current quests | Status and important dependencies |
|---|---|---|
| `qRagno.j` | Protect the Outpost; Gnoll Headcount; Lumberjack Duties; Kobold Thieves; Satyr Negotiations; Call of the Horde | **Implemented JASS.** Protect the Outpost is externally started and auto-completed by its scripted defense. Its legacy `QUEST_MOUNTAIN_DEFENSE` alias still points to Protect the Outpost internally. Granis owns the separate QuestData for the later Mountain Defense, but Ragno remains that quest's field commander, encounter anchor, required survivor, and principal battlefield speaker. Satyr Negotiations reaches Zaekolaerr; its arena outcome now waits for a successful Coliseum challenge started through satyr arena master `n62V`, while the escape, betrayal, and trust follow-ups remain partial. Call of the Horde requires Protect the Outpost and an external unlock. |
| `qChieftainThork.j` | Duty For The Horde | **Implemented JASS.** Tracks Granis's Punish and Garthork's The Magical Eye as separate proof requirements, receives explicit completion reports, and recovers their state from completed QuestData. Later Thork branches remain external/legacy. |
| `qGranis.j` | Punish; Mountain Defense | **Implemented JASS.** Punish targets the existing Rol'jin boss and item `I600`. Granis commissions, owns, and rewards Mountain Defense, while Ragno commands the battle in the field. The distinct second outpost assault uses nine reusable `UnitWaves` stages, fails if Ragno dies or fewer than five temporary defenders survive, and supports retry cleanup. Both are Normal + Story in Thornwoods `6`. |
| `qGarthork.j` | The Magical Eye | **Implemented JASS.** Spawns/reuses Mur'gal `n607`, tracks Eye of Mur'gal `I601`, awards Adept Shaman Claws `I66R`, and reports the completed proof task to Thork. Normal + Story in Thornwoods `6`. |
| `qKrezgrel.j` | Murloc Fins; Rescue The Grunts | **Implemented JASS.** Both are Daily quests in Thornwoods `6`. Rescue targets use invisible selectable grunt proxies paired with negative-pitch special effects and randomized positions in `gg_rct_UpsideGrunt01` through `08`; targets recycle after 240 seconds. The old placed upside-down grunt units must be removed in World Editor. |
| `qGrim.j` | Big Bear Tooth | **Implemented JASS.** Daily quest in Thornwoods `6`; tracks Big Bear Tooth `I6AB`, preserves Grim's recovered voiced greeting/acceptance/completion/farewell dialogue, and relies on the existing bear loot definitions. |
| `qGraknar.j` | Mistaken Kin | **Implemented JASS.** Level 2 Normal side quest that spawns Kodo `o008` at `gg_rct_KodoSpawn`, finds it at 500 range, escorts it through `FollowSystem`, and returns it to Graknar before turn-in. Graknar's Trade option opens the existing bag shop rather than the legacy 30-second trade timer. The quest's zone and canonical `o61S` placement still require WE verification; every other bag merchant currently using `o61S` needs a distinct unit rawcode and identity. |
| `qGrumBloodfang.j` | Whelps of Destruction; Dragon Egg Hunt; Drake Hunt; The Desolator | **Implemented JASS.** Four sequential Normal + Story quests in Emberpeak Highlands `3`, at levels 10, 10, 12, and 15. They track ten Whelp Scales `I00S`, six Dragon Eggs `I00P`, six kills shared across the four current red/scorching drake types, and one Scale of Mordrax `I00T`. The recovered periodic Scorching Drake attack at Grum is also converted. Egg delivery and Mordrax completion have semantic public queries; the eggs' later treatment remains unresolved. |
| `qAradion.j` | Ranger Missing; Crystals of Hope; Fading Sparks; Rifts of Corruption | **Implemented JASS.** Ranger Missing leads to two parallel collection/investigation quests, then Rifts requires all three. Uses Vanguard Vale, Verdant Plains, and Redwind Pass. Test quests are disabled. Valeria's post-reunion Dash rawcode remains a TODO. |
| `qValeria.j` | Token of Love; Lost Supplies | **Implemented JASS.** Token follows Ranger Missing; Lost Supplies follows Token. Uses dedicated token and seven supplies rects. |
| `qKaelthir.j` | Kaelthir's Struggle; Kaelthir's Hunger | **Implemented JASS.** Normal + Story in Vanguard Vale `9`. Struggle consumes one Mana Crystal `I00Y`. Hunger requires Struggle and records one durable QuestData outcome: mercy, feeding Kaelthir into a Mana Wraith `n002`, or escorting him to Aradion for a failed cure. The Aradion path uses `gg_rct_AradionPlace`. |
| `qOutcastJinzun.j` | Plague Upon Trees; Lurking In The Shadows; Unknown Entity; Seeds of Life; Resurgence of Dead I; Resurgence of Dead II; Da Fishing Pole Missing | **Implemented JASS.** Forms a nature-to-undeath side arc through tree runes, lake, dead trees, graveyard, Zaekolaerr inquiry, and Crypt-facing escalation. |
| `qVelyssara.j` | Chains of Seduction | **Implemented JASS.** Normal + Story in Sereneglade `2`, available to Nazgrek. Accepting Velyssara's charm confines him to Sereneglade and makes her follow him while he spreads four rumors, steals Gnoll Pillage `I6A4`, kills a Horde member, and dies/revives. Jin'Zun can instead dispel the charm and redirect the quest to killing Velyssara. Completion awards 300 XP and Orb of Lifesteal `I6A5`. The library preserves legacy "Succubus" behavior under canonical Velyssara and exposes confinement, escape-attempt, teleport, dispel, and respawn hooks. |
| `qKribugs.j` | Ogre Lost His Sandwich; Kribugs Lost His Satchel; Ogre Is Very Thirsty; Meat For The Ogre; Ogre Ate Too Much; Angry Customers | **Implemented JASS.** Three early normals, two repeatables, and one gnoll-kill follow-up. Keep as comic relief rather than a main-story gate. |
| `qANightToRemember.j` | A Night To Remember | **Implemented JASS.** Repeatable, zone-aware social quest with three witnesses and randomized make-amends tasks. It is an optional character vignette, not a canonical story requirement. |
| `qZaekolaerr.j` | Satyr Negotiations and fishing-pole dialogue endpoints | **Partial support.** It owns the durable negotiation outcome and completes the arena route only after a successful Coliseum challenge started through satyr arena master `n62V`; Ragno still owns the QuestData and reward. The hostile escape and false-alliance consequences remain future work. |

At this revision, the core named qXXX libraries do not consistently assign the new content categories. The Story/Dungeon labels in this plan are design intent until an explicit category pass is implemented and validated.

### Generic vendor quests

`QuestsAndDialogs/QuestGivers/Vendors/README.md` is the implementation ledger for the vendor quest set. It currently records 58 quests across 50 qVendor libraries: 43 Daily and 15 Normal. Keep that README authoritative for exact vendor quest titles, rawcodes, objectives, and setup.

The generic quest plan below complements that set; it must not recreate an existing vendor task under a second quest ID. Exact vendor and generic-NPC placements must be checked in World Editor because the source repository does not provide a complete placement inventory.

Graknar `o61S` is a named quest giver as well as the original bag merchant. Do not reuse `o61S` for generic bag sellers: create distinct vendor identities and rawcodes, then bind their intended bag catalogs separately so Graknar's quest reference and respawn hooks remain unambiguous.

### Existing runtime systems tied to planned content

| System | Current evidence | Design consequence |
|---|---|---|
| Boom Mine | `DungeonBoomBrothersMine.j` registers zone `104`, patrol waves, and explosive/barrel events. | The Boom Brothers chain can lead into a real dungeon rather than a disconnected narrative instance. |
| Mad Blix | `BossMadBlix.j` contains a recoverable mana-absorption mechanic; legacy phase files are empty. | Mark the boss **Partial**. Design additional mechanics only after testing the current encounter and recovering GUI evidence. |
| Rol'jin | `BossRoljin.j` exists. | Granis's voiced Rol'jin hunt can target an existing boss encounter. |
| Nazgrek's Flask | Item `I61L` is registered by `ProfessionsAlchemy.j`, equipment exports, loot data, and debug tools; item ability evidence includes `A63V`. | The legacy prologue flask idea now has real object evidence, but the existing reusable alchemy item must not automatically become a disposable tutorial prop. Decide whether the quest unlocks the recipe, creates a separate vision draught, or deliberately rebalances the existing flask. |
| Zul'karak | Unit `n65F` is present in the debug object registry and reputation unit list. | The unit exists, but the older-brother personality, abilities, recruitment timing, and companion behavior remain **Legacy evidence** until confirmed in current WE triggers/code. |
| Crypt boss roster | `ZonesCore` names Skullreaver, Rotspine, Bone Golem, Darkmaw the Soul Devourer, and Marduk the Endbringer for Crypt `102`. | Treat the ODT's Warden, Cryptlord, and king's shade as encounter roles or discarded working names until deliberately mapped to current bosses. |
| Gar | `BossGar.j` creates unit `n60Z` only through `BossGar_Spawn()`, then patrols `gg_rct_GarWP01` through `gg_rct_GarWP06` at 60 movement speed. | **Partial JASS.** The reusable two-phase encounter and quest/event spawn hook are implemented in Deadwoods. Quest ownership, explosives, reward, and canonical outcome remain open. |
| Dawnhold ship service | `TravelShipA.j` already owns an active Sirensong–Dawnhold–Stormhaven neutral route and registers Dawnhold stop `20`. | Legacy Fix the Ship must not blindly unlock baseline travel. Use it for a separate goblin vessel, route/service upgrade, fare benefit, repair incident, or an intentional availability gate designed with the current travel system. |
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
| ST-P-01 | Intro cinematic: Nazgrek and Shadowclaw | **Partial / current voice + legacy ODT evidence** | Establish the blood-refusal backstory, the bond with Shadowclaw, and Sereneglade as sanctuary. The old sequence adds a dismissive orc patrol, the walk to Nazgrek's hut, and a successful rabbit hunt; retain only the beats that fit the current opening's pace and staging. |
| ST-P-02 | Nazgrek's Flask / First signs of unrest | **Legacy ODT + current object evidence; redesign required** | Nazgrek senses spiritual discord, gathers ingredients, and prepares a draught to sharpen his insight before following the disturbance toward Ragno. Exact reagents and regions require GUI/WE recovery. Do not consume or grant existing alchemy item `I61L` by default; a quest-only vision draught or later recipe unlock is safer. |
| ST-P-03 | Protect the Outpost | **Implemented JASS** | First visible act of service. Ragno survives, notices Nazgrek, and becomes the early repeatable hub. |

Legacy intro beats worth retaining are Shadowclaw reacting defensively when the patrol mocks Nazgrek, Nazgrek choosing restraint, the hut serving as the first quiet player-controlled space, and the flask vision turning vague unease into a playable trail. Avoid making the patrol scene a long exposition dump or implying all Horde orcs share the patrol's contempt.

### Act I — Earning a place (levels 3–10)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A1-01 | Call of the Horde | **Implemented JASS** | Carry Ragno's blood-signed letter to Chieftain Thork after the defense. |
| ST-A1-02 | Duty For The Horde | **Implemented JASS** | Thork requires the separately tracked completion of Granis's Punish and Garthork's The Magical Eye. It is the Act I spine, not a generic reputation grind. |
| ST-A1-03 | Punish / Rol'jin's Head | **Implemented JASS** | Granis sends Nazgrek to kill the existing Rol'jin boss and return item `I600`; completion reports Granis's proof to Thork. |
| ST-A1-04 | The Magical Eye | **Implemented JASS** | Garthork identifies Nazgrek's Thunderlord past, requests Mur'gal's eye `I601`, and reports the proof to Thork. The later spiritual-sight follow-up remains proposed. |
| ST-A1-05 | Mountain Defense | **Implemented JASS** | Granis commissions the quest and receives the final report, but Ragno is its field commander and operational story anchor. It is a distinct second assault after Ragno's Protect the Outpost, with nine staged waves, defender/Ragno survival rules, and retry cleanup. |
| ST-A1-06 | Gnoll camp clue → Gnoll Hideout | **Legacy Articy; proposed bridge** | A southern-camp objective reveals stolen Horde resources and an external organizer, then unlocks dungeon `101`. The dungeon book/ledger becomes story evidence instead of a standalone collectible. |
| ST-A1-07 | Satyr Negotiations | **Implemented opening and arena gate; partial branches** | Zaekolaerr offers an arena test, a hostile rupture/escape, or apparent cooperation. `qZaekolaerr` records the selected outcome; the arena route requires completing any challenge in the Coliseum of Ages through satyr arena master `n62V`. The later escape, betrayal, trust, and convergence consequences remain to be implemented. |
| ST-A1-08 | Thork's judgement | **Proposed** | Thork evaluates Granis, Garthork, dungeon, and satyr outcomes. Nazgrek gains conditional standing with the Horde and a route toward Ghostwalk Ridge. |

Recommended satyr consequences:

- **Arena:** complete an optional combat trial; earn respect and cleaner access to Zaek's information.
- **Hostile rupture:** escape satyr territory and report to Granis; later satyr patrols are more aggressive.
- **False alliance:** perform one morally suspicious reconnaissance task, discover the planned betrayal, then expose or reject Zaek. Do not require killing Ragno or burning the Horde base as an irreversible main-story action.

Legacy concepts such as draining orc life, killing Ragno, and setting the base on fire can survive as threatened outcomes, illusions, failed-state content, or an explicitly selected dark branch. They should not silently replace the stable Act I hub.

### Act II — The wolf and the wound (levels 8–15)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A2-00 | Shadowclaw's Demise | **Legacy ODT/Articy cinematic; canon decision pending** | Shadowclaw follows a scent through a cursed Ghostwalk settlement and is found slain by a fel-orc warrior. Preserve Nazgrek's grief, a brief rage confrontation, and a spiritual farewell. The exact killer, permanence, and later spirit role remain open. |
| ST-A2-01 | A Howl Silenced | **Legacy ODT/Articy** | Inspect the killer's marked weapon or body, then scout the Ghostwalk outskirts for the responsible warband. Shadowclaw's death is the inciting event, not this quest's final reward. |
| ST-A2-02 | Blood Trail | **Legacy ODT/Articy** | Follow blood, disturbed earth, scouts, and warbeasts to a hidden camp. Use Wolf Den `12111` or another verified location only if current WE geography supports it. |
| ST-A2-03 | Broken Chains | **Legacy ODT/Articy** | Destroy fel-orc supplies, free captive villagers forced to work on cursed artifacts, escort survivors, and confront the overseer. Exact captive count and faction remain TBD. |
| ST-A2-04 | Curse of Ghostwalk Ridge | **Legacy title: Curse of Ghostridge** | Destroy three ritual totems under escalating attack and defeat their fel-orc shaman. The shaman reveals demonic support and points toward Felfire Bastion. |
| ST-A2-05 | Whispers in the Void | **Legacy ODT/Articy; terminology review required** | Infiltrate a forward camp, confront the demonic emissary empowering the warband, and sever its link. Decide whether “void” is literal void magic or obsolete wording for Legion/fel influence. |
| ST-A2-06 | The Lair of Rage | **Legacy ODT/Articy** | Assault the fel-orc stronghold with earned allies, defeat its warlord, and destroy the summoning altar. Earlier cleansing, rescue, outpost, and scouting outcomes should alter this battle. |
| ST-A2-07 | Run Free | **Proposed epilogue** | Give Shadowclaw's farewell room after the assault and establish any ancestral-guide motif without undoing the cost of the loss. |
| ST-A2-08 | Deadwoods and the Ghost | **Proposed synthesis** | Route Ironspine Post into Deadwoods, Jin'Zun's resurgence/Crypt content, and the threatened road to Dawnhold. |

The direct fel-orc killing from the old notes is the clearest causal version and gives the later Felfire campaign personal weight. Use it as the leading option, but keep the playable investigation and assault central: Nazgrek's automatic rage strike should be a short emotional beat or boss opening, not a cinematic that resolves the player's revenge for them.

The “Chains of Seduction” and fight against legacy “Velaria” belong to **Velyssara**, a separate female satyr/succubus with unit rawcode `n636`. The identity conflict is resolved: Valeria remains the Elarindor ranger and companion. Her recovered GUI flow is implemented in `qVelyssara`: Nazgrek may submit to four corrupting tasks or have Jin'Zun dispel the charm and fight her. While the charm and quest remain active, Nazgrek is forcibly confined to Sereneglade. Velyssara's allegiance to the unnamed master in her combat line and her durable fate remain open canon decisions.

### Act III — Roads, islands, and uneasy allies (levels 10–18)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A3-01 | The Orc Outpost / Ironspine alliance | **Legacy ODT; proposed remap** | The old northern outpost most naturally maps to Ironspine Post `1901`, subject to WE verification. Defend it, fortify it, and gain troops/intelligence for The Lair of Rage. |
| ST-A3-02 | Ghosts in the Deadwoods | **Legacy ODT/Articy** | Use a spirit amulet to find frightened human survivors, then calm, defend, or escort them. Their trust provides regional knowledge without forcing hostility with all humans. |
| ST-A3-03 | Dawnhold's Curse | **Legacy title: Vanguard's Curse; location resolved** | Defeat undead captains in Dawnhold `20`, assemble pieces of a cursed artifact, and destroy or cleanse it at an altar. Exact captains, artifact pieces, altar, and WE regions remain unverified. |
| ST-A3-04 | Gar the Mighty Giant | **Partial JASS + legacy ODT** | Gar is unit `n60Z` in Deadwoods `11`, described as a flesh golem created by the Dawnhold necromancer. `BossGar.j` now provides an event-controlled spawn at `gg_rct_GarWP01`, a six-point patrol, and a simple frenzy phase. Quest ownership, explosives, crafting reward, and canonical outcome remain unverified. |
| ST-A3-05 | The Goblin Negotiator / Fix the Ship | **Legacy ODT/Articy; reward redesign required** | Recover three classes of ship parts, optionally trade for rare components, and defend repairs. Because Ship A already serves Sirensong–Dawnhold–Stormhaven, reward a separate vessel, fare/service improvement, new destination, or story access rather than claiming to unlock all ship travel. |
| ST-A3-06 | Sirensong regional arc | **Proposed synthesis** | Link Mok'natha, Zul'Garok Ruins, Urgmar, Serpentshore, Kelziss, and Jinnvorrak through raids, ruins, and a growing naga/hydra threat. |
| ST-A3-07 | Boom Brothers chain | **Legacy voiced design + partial dungeon** | A comedic engineering story becomes useful to the main route because its explosives or tools open a blocked passage/ship repair. Completion grants free or friendly Boom Mine access, not a mandatory grind. |
| ST-A3-08 | Felfire evidence | **Proposed synthesis** | Evidence from the Citadel shows the corruption is organized and linked to elemental/dragon exploitation farther east. |

Legacy outpost-support hooks can become a compact preparation layer for The Lair of Rage instead of ten unrelated errands:

| Legacy quest | Useful retained hook | Recommended treatment |
|---|---|---|
| Supply Lines | Meat, abandoned weapons, or negotiated supplies | One normal quest with optional acquisition routes; upgrades outpost consumables or assault support. |
| The Wandering Berserker | Track and subdue an unstable orc without killing him | Character quest; successful cleansing adds the berserker to a later battle. |
| Totems of Strength | Valor, Spirit, and Resilience totems in distinct danger sites | Short optional chain; avoid duplicating shaman class-quest rewards. |
| The Scouting Party | Follow broken weapons/blood signs and rescue survivors | Fold into regional reconnaissance if it duplicates Blood Trail. |
| Spirits of the Past | Free trapped orc souls and perform an altar ritual | Connect the necromancer reveal to Garthork and the Crypt. |
| Echoes of the Forge | Dark ore, molten shard, and ancestral hammer | Profession-support quest or one-time assault upgrade, not both. |
| Fel Contamination | Herbs, poisoned water, fel alchemist, cleansing ritual | Strong regional normal quest with visible outpost recovery. |
| Cursed Captives | Break spectral chains and give dead warriors a proper release | Connect to Restless Souls while keeping living rescues and spirit releases distinct. |
| Silent Negotiations | Recover plans and optionally sabotage the camp | Redesign as reconnaissance/sabotage; do not assume Nazgrek owns a Stealth ability. |
| Goblin Negotiator | Protect a scavenging run and secure trade | Fold into Fix the Ship unless a persistent trade network is implemented. |

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
| ST-A4-05A | Kaelthir's Struggle -> Kaelthir's Hunger | **Implemented JASS side chain** | Give immediate personal stakes to Elarindor's magical collapse. The chosen mercy, mana-wraith, or failed-cure outcome is stored through the completed Hunger requirement for later dialogue. |
| ST-A4-06 | Weeping Hollow / Vael'Anorath consequence | **Proposed** | Use the player's satyr choice and ritual success to alter assistance, enemy composition, and dialogue in Verdant Plains. |
| ST-A4-07 | Chimairo and Morthun | **Proposed zone story** | Optional elite/world-boss arc that proves whether the land is healing; do not make trophy farming a story gate. |

### Act V — Fire, blood, and balance (levels 10–30)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A5-01 | Whelps of Destruction | **Implemented JASS** | Level 10 Normal + Story quest in Emberpeak `3`; bring ten Whelp Scales `I00S`. The journal frames the hunt around dangerous whelps threatening Emberpeak. |
| ST-A5-02 | Dragon Egg Hunt | **Implemented JASS; consequence open** | Level 10 Normal + Story follow-up; deliver six Dragon Eggs `I00P`. `qGrumBloodfang_AreEggsDelivered()` exposes the delivery, while Grum's intended treatment and its later consequence remain unresolved. |
| ST-A5-03 | Drake Hunt | **Implemented JASS** | Level 12 Normal + Story follow-up; kill six aggressive red or scorching drakes across the current level-10 and level-20 rawcodes. Grum's recovered periodic Scorching Drake attack is active independently of quest progress. |
| ST-A5-04 | The Desolator | **Implemented JASS; encounter verification remains** | Level 15 Normal + Story conclusion; bring Scale of Mordrax `I00T` and receive Dragonslayer's Sword `I00U`. `qGrumBloodfang_IsMordraxDefeated()` exposes completion; confirm Mordrax's current WE encounter and drop path during integration testing. |
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
| GQ-007 | Murloc Fins | Daily | Krezgrel | Thornwoods shore | **Implemented JASS.** Gather ten Murloc Fins `I6AE`; no duplicate title exists in the vendor ledger. |
| GQ-008 | Rescue The Grunts | Daily | Krezgrel | Thornwoods murloc waters | **Implemented JASS.** Rescue three living grunts through eight randomized effect/proxy targets; some selected grunts have already drowned. |
| GQ-009 | Big Bear Tooth | Daily | Grim | Thornwoods wildlife area | **Implemented JASS.** Bring one Big Bear Tooth `I6AB`; the existing bear loot definitions provide the item. |
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

### Crypt `102` legacy design kit

The old ODT provides a useful seven-quest dungeon package. Preserve the functions below, but align all bosses, ruler lore, rooms, and rewards with the current map before implementation.

| Package ID | Legacy quest | Type + category | Retained objective role | Reconciliation |
|---|---|---|---|---|
| DQ-102-01 | The Whispering Tombs | Normal + Dungeon | Find the whispering chamber, destroy a Soul Nexus, and survive its guardian waves. | Corresponds to planned GQ-019; Jin'Zun or Garthork may provide the breadcrumb. |
| DQ-102-02 | Crypt Delvers | Normal + Dungeon | Escort a goblin excavation team, secure its work area, and survive the guardian it awakens. | Connect the reward to ship repairs or goblin services; build robust escort failure/retry cleanup. |
| DQ-102-03 | Shadow of the Cryptlord | Normal + Story + Dungeon | Reach an inner sanctum through traps/puzzles and defeat the dungeon's major abomination. | “Cryptlord” is a legacy role, not an approved boss name. Map it to Skullreaver, Rotspine, Bone Golem, Darkmaw, or Marduk only after inspecting current encounters. |
| DQ-102-04 | The Cursed Crown | Normal + Dungeon | Recover a ruler's crown and choose to return it for release or keep its power and curse. | The old “Vanguard king” now means a former ruler of Dawnhold; the exact identity remains TBD. The keep branch requires durable cursed-item behavior. |
| DQ-102-05 | Secrets of the Necromancer | Normal + Story + Dungeon | Solve library/ward puzzles, collect texts, and confront a projection that reveals identity, motive, or weakness. | Corresponds to planned GQ-021 and should advance the Deadwoods/Dawnhold story rather than award lore with no consumer. |
| DQ-102-06 | Relic Hunters | Normal + Dungeon | Recover several guarded relics and choose one personal reward while the rest aid allies. | Final relic names and power require item-system and reward-balance review. |
| DQ-102-07 | Restless Souls | Daily or Normal + Dungeon | Break warding stones, defend a release ritual, and guide bound spirits onward. | Corresponds to planned GQ-020. Prefer Normal for the authored human-survivor story; create a separate Daily only if repeatable targets make narrative sense. |

Reusable Crypt encounter elements from the notes:

- **Encounter roles:** an entrance warden, a corpse-built inner guardian, and a bound royal shade. These are functional archetypes, not replacements for the current named boss roster.
- **Hazards:** poison-gas pressure plates, readable floor/pit traps, vermin swarms, summoned waves, and puzzle-locked chambers. Use only hazards that remain readable with Warcraft III pathing and camera constraints.
- **Lore objects:** an Ancient Necromancy Tome for Garthork, a former Dawnhold ruler's journal, and a Tome of Forgotten Magic. Each book needs one clear story consumer; avoid three interchangeable book pickups.
- **Branch reward:** returning the crown grants release/blessing, while keeping it grants stronger immediate power with a real persistent curse. Do not offer the keep choice until the equipment/save systems can honor that consequence.

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
| Boom Brothers / Atex Blix | Five-step Boom Mine chain | Exact items, escort route, failure/retry behavior, mine access flags, Mad Blix phases |
| Erduk | Existing named quest giver | Entire active GUI quest set, placement, and intended arc |
| Valeria | Current qValeria plus unexported legacy triggers | Identify which companion objectives remain missing; verify old “Velaria” references by rawcode so they are not confused with Velyssara |
| Velyssara / Zaekolaerr link | `qVelyssara` now implements the recovered Chains of Seduction tasks, Jin'Zun dispel route, combat event, reward, and Sereneglade confinement | Decide who the unnamed master in Velyssara's combat line is, whether she serves or rivals Zaekolaerr, and whether a future branch can cleanse or spare her. |
| Nazgrek's Flask | Existing alchemy item `I61L`; old intro describes a self-made insight flask | Recover the original quest triggers/ingredients and decide between a quest-only vision draught, a later recipe unlock, or deliberate reuse of `I61L` |
| Zul'karak | Existing unit `n65F`; ODT describes Zul'kis's warrior brother and possible later recruit | Confirm current placement, faction, dialogue, companion eligibility, and whether the older-brother relationship remains canon |
| Ghostwalk/Deadwoods/Dawnhold legacy campaign | Shadowclaw death, fel-orc warband, Ironspine-like outpost, human survivors, Dawnhold curse, Gar, and ship | Ruined “Vanguard” maps to Dawnhold `20`; Gar `n60Z` maps to Deadwoods `11`; Ship A already serves Dawnhold. Verify exact rects, triggers, and intended quest-specific vessel/service changes. |
| Crypt `102` | Seven legacy quests, three encounter roles, hazards, books, and a cursed-crown branch | Map roles to current bosses/rooms, identify the buried culture/ruler, validate traps, and design persistent reward consequences |
| Other Horde NPCs | Drek'thor, Ogmar and related triggers | Inventory before assigning new generic quests to avoid ownership conflicts. Krezgrel's two legacy daily quests and Graknar's Mistaken Kin are now recovered and implemented. |

## 13. Open and resolved canon and implementation decisions

Resolve these deliberately and record the answer here:

1. **Resolved - Mountain outpost defenses:** Mountain Defense has separate QuestData owned and rewarded by Granis, but it remains strongly tied to Ragno as the field commander, encounter anchor, required survivor, and battlefield voice. It is a distinct second battle after Ragno's Protect the Outpost.
2. **Shadowclaw's fate:** the old notes explicitly use permanent death by a fel-orc warrior; decide whether current canon keeps that direct murder, adds a failed cleansing attempt, or allows a player-influenced outcome. Define what replaces gameplay dependencies and whether Shadowclaw later appears only as a spirit motif.
3. **Zaekolaerr branch limits:** which dark actions are playable, threatened, or discarded, and how can the main hub remain usable?
4. **Velyssara's allegiance and fate:** Zaekolaerr's agent, independent corrupter, coerced ally, or rival—and can she be cleansed, spared, or only defeated?
5. **Main antagonist:** which force connects gnolls, satyrs, undead, void rifts, Dark Horde, and elemental exploitation without making every faction secretly identical?
6. **Resolved - Granis/Garthork task ownership:** `qChieftainThork` requires Granis's `Punish` and Garthork's `The Magical Eye`; each producer exposes proof-state queries and sends an explicit completion report, while Thork also recovers from QuestData state.
7. **Act III settlement `1704`:** final name, faction, services, and narrative purpose.
8. **Gar's encounter and outcome:** Gar is unit `n60Z` in Deadwoods `11`. His quest-controlled spawn at `gg_rct_GarWP01`, six-point patrol, and simple frenzy phase are implemented in `BossGar.j`; decide the explosives mechanic, quest owner, reward, and whether destruction or another resolution is canonical.
9. **Grum and the eggs:** protective plan, reckless weaponization, betrayal, or misunderstanding?
10. **Dungeon reset policy:** which objectives are daily versus freely repeatable, and how boss/instance state resets safely.

Recommended antagonist structure: use a coalition or chain of exploitation rather than one controller behind everything. Satyrs exploit local division, necromancers exploit death, the Dark Horde and demons industrialize fel/elemental power, and the void presence opportunistically amplifies the damage. This preserves faction identity while giving Nazgrek one thematic conflict.

## 14. Recommended implementation order

1. Decide how the old Nazgrek's Flask prologue relates to existing alchemy item `I61L`, then recover its GUI ingredients/regions and current intro staging.
2. Recover Granis and Garthork GUI triggers and create their modern qXXX libraries so Duty For The Horde has real dependencies.
3. Decide and implement the second mountain defense versus current Protect the Outpost.
4. Finish Satyr Negotiations outcome state and one convergent follow-up per choice.
5. Add the Gnoll Hideout one-time package and use its evidence in Thork's Act I conclusion.
6. Use Dawnhold `20` for the ODT's ruined Vanguard city/docks and Deadwoods `11` for Gar `n60Z`, then verify exact quest rects plus the northern-outpost and Ghostridge mappings before placing Act II/III objectives.
7. Audit Shadowclaw's current companion systems, decide the death variant, then write the Act II chain without implementing the demise until cleanup/replacement behavior is safe.
8. Reconcile the seven Crypt quests and encounter roles with the current five-boss roster, room layout, and Jin'Zun/Garthork dependencies.
9. Convert the Boom Brothers chain against the existing dungeon and recover Mad Blix behavior.
10. Build the Ironspine–Deadwoods–Dawnhold travel/story bridge and connect the implemented Jin'Zun chain.
11. Complete the Sirensong regional arc and ship route.
12. Categorize and validate the implemented Aradion/Valeria quests as story or side-story content, then add their Verdant consequence quests.
13. Recover Grum's chain and design Dragonfire/Wyrmhold/Firelands/Dreadforge as the endgame campaign.
14. Add generic quests zone by zone after checking the vendor ledger and WE placement, prioritizing hubs that currently have no repeatable support.

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
- Treat the original ODT files as read-only legacy evidence. Record accepted ideas and conflicts here instead of rewriting the historical notes.
- When a legacy concept is rejected, record the decision and replacement briefly instead of deleting all trace of the conflict.
- When a new NPC is created, add its canonical name, faction, zone, placement, rawcode/global, quest ownership, and later connections to this document.
- When a quest moves zone, update both the quest implementation and this plan; use `ZonesCore` for the final zone identity.
- Keep detailed vendor setup in the vendor README and detailed conversion mechanics in the owning qXXX file. This document should retain the cross-quest story reason and dependency.
- Review the open decisions and implementation ledger after each completed story arc or major zone-content pass.
