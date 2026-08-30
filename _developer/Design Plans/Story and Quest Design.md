# Story and Quest Design

- **Status:** Living master design plan
- **Created:** 22 August 2026
- **Last reviewed:** 30 August 2026
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
| Zul'kis | Zulkis | Use Zul'kis in player-facing text. Keep `Zulkis` in raw identifiers, globals, filenames, and API names where renaming would break current code. |
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
| Erduk | `o61C` | Ghostwalk Ridge murloc-pressure side quest giver on the outskirts of Ironspine Post |
| Graknar | `o61S` | Bag merchant and Mistaken Kin quest giver; reserve this rawcode for the canonical Graknar and verify his final placement |
| Boom Brothers | `n013` | Sirensong engineering chain and Boom Mine dungeon |
| Atex Blix | `n01A` | Boom-chain contractor, betrayer, and dungeon boss identity |
| Kribugs | `n61E` | Comic Ogre side-quest hub |
| Quinx | `udg_Quinx`; rawcode pending WE verification | Goblin shredder operator and Shredder Fuel side-quest giver |
| Prince Zaekolaerr | `n62W` | Satyr diplomacy branch endpoint and manipulator |
| Velyssara | `n636` | Female satyr/succubus tied to Chains of Seduction and Zaekolaerr's corruption arc |
| Zul'karak | `n65F`, `udg_Zulkarak` | Existing preplaced troll unit referenced by the World Editor unit variable; Zul'kis's older brother and a possible later recruit |
| Aradion | `h00A` | Elarindor leader and late-midgame story hub |
| Valeria | `n01W` | Elarindor ranger, companion, and story quest giver |
| Kaelthir | `n01X` | Elarindor wretched survivor whose fate branches between mercy, mana-wraith transformation, and Aradion's failed cure |

Valeria and other characters still have unexported GUI triggers in the map. Recover those triggers before deleting, replacing, or claiming full parity with their legacy quests. Erduk, Boom Brothers, Atex Blix, Granis, Garthork, Krezgrel, Grim, Graknar, and Grum Bloodfang now have recovered trigger exports and modern qXXX conversions.

## 4. Zone progression and narrative use

`Zones/ZonesCore.j` is the location authority for zone IDs, hierarchy, levels, factions, and named bosses. Every new quest must record a zone ID and, when known, a concrete rect, unit, subzone, cave, or dungeon objective location.

| Level band | Zone IDs and hubs | Narrative and quest use |
|---|---|---|
| 1–9 | Sereneglade `2`, Twilight Grove `1` | Prologue, Ragno, Jin'Zun, Kribugs, early Horde contact, wildlife and local-threat quests |
| 1–10 | Thornwoods `6`, Stonetooth Camp `601`, Bloodtusk Tribe `602`, Horde Scout Base `8810` | Chieftain Thork, Granis, Garthork, Rol'jin, murloc and gnoll pressure, Horde acceptance |
| 1–5 | Bramblehide Village `701` | Bloodtusk forest-troll village in Havenwoods; Zul'kis rescues Zul'karak here during the parallel prologue |
| 5–15 | Havenwoods `7`, Bonecrush Stronghold `8`, Riverbane `10`, inns/cellars `12010`–`12021` | Alliance/Ogre/Bonecrusher relations, patrols, trade, and faction consequences |
| 5–14 | Ghostwalk Ridge `19`, Ironspine Post `1901`, Deadwoods `11`, Crypt `102` | Erduk's murloc pressure, Shadowclaw tragedy, corruption, undeath, Jin'Zun follow-up, and Dawnhold approach |
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
| `qNazgrek.j` | Wolf Hunt I; Nazgrek's Flask | **Partial prologue JASS.** Two self-discovered Normal + Story quests in Sereneglade `2`. Nazgrek's intro cinematic must call `qNazgrek_StartIntroQuestChain()` from its shared normal/ESC completion path so Wolf Hunt I begins only after the cinematic. Killing six current wolf/alpha-wolf units and collecting six Wolf Skin `I61F` auto-completes it and starts the converted legacy flask quest. The flask tracks six Forest Flower `I60Y`, three Agave `I60W`, two Earth Roots `I60X`, six Stag Hair `I614`, two Frog Slime `I615`, and the delayed Empty Flask `I61M` reminder, then auto-completes when existing flask `I61L` is crafted or acquired. Wolf Hunt II–III remain planned until their unique trophy and Shamanic Cowl objects/recipe are defined. |
| `qZulkis.j` | Meet with Chieftain Thork; Rescue the Brother | **Implemented prologue JASS; runtime validation pending.** `qZulkis_StartPrologue()` owns the six-camera river arrival, temporary `'odes'` ship, living Darkspear shore party, Thork meeting, off-screen corpse/captive staging immediately after Thork's return order, wounded-witch-doctor testimony and interrupted death vocal, the chance arrival of a four-grunt orc patrol, Zul'karak relocation through `udg_Zulkarak`, rescue in Bramblehide Village `701`, Horde-base staging, and fade back to Nazgrek. Each cinematic suspends the gameplay camera controller; the arrival snaps to `IntroZulkisCam2` before its timed movement toward camera 1, then cuts to camera 5 and moves toward camera 6, while the landing snaps to camera 3 before its timed movement toward camera 4. Darkspear corpses use the recovered GUI permanent-flesh staging throughout Zul'kis gameplay, while the wounded witch doctor dies as the same unit and joins their suspended-decay lifecycle; all six resume normal decay when the prologue ends. The patrol joins as four temporary companion grunts for Rescue the Brother, bypasses the ordinary low-level companion cap for this scripted section, and is unregistered and removed when Zul'kis's prologue ends. When his playable section begins, `Start.j` equips Zul'kis with Shadowcaster's Scepter and a mostly common, deliberately weak Darkspear travel set, plus two Mana Potions, one Healing Potion, and Purified Water in his native inventory. Graveyard `2` (`Graveyard02`) temporarily replaces the player's stored revival point for Zul'kis gameplay, and the exact prior graveyard selection is restored at prologue completion. Nazgrek is hidden, invulnerable, paused, and neutral-passive while Zul'kis is playable; Shadowclaw is likewise removed from the active pet/companion state and hidden, then both are restored from their saved state only after the prologue. Its completion query gates the existing Call of the Horde convergence. Zul'karak's later quest-giver quests, recruit unlock, and dedicated combat/home AI remain planned separately. |
| `qRagno.j` | Protect the Outpost; Gnoll Headcount; Lumberjack Duties; Kobold Thieves; Satyr Negotiations; Call of the Horde | **Implemented JASS.** Protect the Outpost is externally started and auto-completed by its scripted defense. Its intro plays the `OrcGrunt_0012` attack warning, waits four seconds, and then continues with the `OrcGrunt_0013` overwhelmed response and Nazgrek's reply; its independent camera shots include the same delay. Active gnolls left idle or inside a wave spawn region are periodically ordered to attack the Horde mountain outpost. The intro restores CameraControl to the player's pre-cinematic camera unit on both normal completion and ESC skip. Quest acceptance occurs when the gnoll-attack intro cinematic ends, so the shared five-second discovery delay presents the quest after the scene instead of interrupting it. Delayed initialization also starts the encounter when an owned hero is already inside one of its entry regions, preventing its completion-gated follow-up quests from remaining unavailable after a missed region-enter event. If the encounter interrupts a Ragno interaction, it first skips the active sequence and closes its menu so no pending-dialog state survives into the cinematic. Gnoll Headcount, Lumberjack Duties, Kobold Thieves, and Satyr Negotiations all require its completion and become available afterward. Ragno's ordinary greeting, quest, and farewell sequences use the shared DialogSystem ESC skipper and exit callbacks without a quest-giver-specific transition escape override. Its legacy `QUEST_MOUNTAIN_DEFENSE` alias still points to Protect the Outpost internally. Granis owns the separate QuestData for the later Mountain Defense, but Ragno remains that quest's field commander, encounter anchor, required survivor, and principal battlefield speaker. Satyr Negotiations reaches Zaekolaerr; its arena outcome now waits for a successful Coliseum challenge started through satyr arena master `n62V`, while the escape, betrayal, and trust follow-ups remain partial. Call of the Horde requires Protect the Outpost and an external unlock, and is unit-specific to Nazgrek so its giver/receiver markers stay inactive while Nazgrek is neither owned nor a companion. Protect the Outpost stages active Shadowclaw beside Nazgrek for its completion and preserves that position through the Zul'kis prologue before returning to Nazgrek gameplay. Its completion explicitly unlocks the one-shot southern mountain-camp grunt exchange through `HordeUnitsRandomChat_EnableMountainChat()`, then hands its black-screen completion directly to `qZulkis_StartPrologue()`. |
| `qChieftainThork.j` | Duty For The Horde | **Implemented JASS with Zul'kis convergence gate.** Tracks Granis's Punish and Garthork's The Magical Eye as separate proof requirements, receives explicit completion reports, and recovers their state from completed QuestData. During the separate Zul'kis section, Thork selection is consumed and redirected to `qZulkis` so generic selection dialogue cannot overlap the prologue meeting; Call of the Horde cannot become ready or complete until Rescue the Brother is complete, after which the existing meeting positions Nazgrek in front of Thork and enables Zul'kis. Later Thork branches remain external/legacy. |
| `qGranis.j` | Punish; Mountain Defense | **Implemented JASS.** Punish targets the existing Rol'jin boss and item `I600`. Granis commissions, owns, and rewards Mountain Defense, while Ragno commands the battle in the field. The distinct second outpost assault uses nine reusable `UnitWaves` stages, fails if Ragno dies or fewer than five temporary defenders survive, and supports retry cleanup. Both are Normal + Story in Thornwoods `6`. |
| `qGarthork.j` | The Magical Eye | **Implemented JASS.** Spawns/reuses Mur'gal `n607`, tracks Eye of Mur'gal `I601`, awards Adept Shaman Claws `I66R`, and reports the completed proof task to Thork. Normal + Story in Thornwoods `6`. |
| `qElementalMaster.j` | Element of Air; Element of Earth; Element of Fire; Element of Water | **Implemented JASS.** Every placed Elemental Master `o627` can start the ordered Normal + Class covenant chain, but each accepted rank must be returned to that exact trainer. The quests consume the matching Air `I6C7`, Earth `I6C8`, Fire `I6C5`, and Water `I6C6` essences and grant Summon Elemental ranks 1–4 in that order; Stormcaller remains mandatory. Rank 5 remains the normal Greater Elemental AP upgrade after the four covenants. |
| `qKrezgrel.j` | Murloc Fins; Rescue The Grunts | **Implemented JASS.** Both are Daily quests in Thornwoods `6`. Rescue targets use invisible selectable grunt proxies paired with negative-pitch special effects and randomized positions in `gg_rct_UpsideGrunt01` through `08`; targets recycle after 240 seconds. The old placed upside-down grunt units must be removed in World Editor. |
| `qErduk.j` | Heads of the Murlocs | **Implemented JASS.** Level-8 Normal side quest for Nazgrek in Ghostwalk Ridge `19`, where Erduk `o61C` stands on the outskirts of Ironspine Post `1901`. It targets and reveals legacy rect `gg_rct_LakeAmbient042`, tracks and consumes 40 Murloc Heads `I610`, then rewards level-scaled XP and gold plus 100 Horde reputation. |
| `qGrim.j` | Big Bear Tooth | **Implemented JASS.** Daily quest in Thornwoods `6`; tracks Big Bear Tooth `I6AB`, preserves Grim's recovered voiced greeting/acceptance/completion/farewell dialogue, and relies on the existing bear loot definitions. |
| `qGraknar.j` | Mistaken Kin | **Implemented JASS.** Level 2 Normal side quest that spawns Kodo `o008` at `gg_rct_KodoSpawn`, finds it at 500 range, escorts it through `FollowSystem`, and returns it to Graknar before turn-in. Graknar's Trade option opens the existing bag shop rather than the legacy 30-second trade timer. The quest's zone and canonical `o61S` placement still require WE verification; every other bag merchant currently using `o61S` needs a distinct unit rawcode and identity. |
| `qGrumBloodfang.j` | Whelps of Destruction; Dragon Egg Hunt; Drake Hunt; The Desolator | **Implemented JASS.** Four sequential Normal + Story quests in Emberpeak Highlands `3`, at levels 10, 10, 12, and 15. They track ten Whelp Scales `I00S`, six Dragon Eggs `I00P`, six kills shared across the four current red/scorching drake types, and one Scale of Mordrax `I00T`. The recovered periodic Scorching Drake attack at Grum is also converted. Egg delivery and Mordrax completion have semantic public queries; the eggs' later treatment remains unresolved. |
| `qBoomBrothers.j` | Explosive Crisis; Boomsite Compliance Inspection; Dust Isn't Just Dirt - It's Combustible Culture; Mandatory Training; Boom Will Be Back | **Implemented JASS.** Owns the sequential Normal/Story chain and level-15 Dungeon conclusion, the carried-barrel detonation risk, Mandatory Training escort through `gg_rct_KoboldCamp`, Atex's betrayal at `gg_rct_BoomBrotherMineEntrance`, temporary Mad Blix reveal, hostile turret handoff, semantic mine-state queries, and the boss-death report consumed from `BossMadBlix.j`. `Boom Will Be Back` targets Boom Mine zone `104`; the current dungeon remains physically ungated until its portal/access policy is implemented. |
| `qAtexBlix.j` | Boomsite Compliance Inspection; Dust Isn't Just Dirt - It's Combustible Culture | **Implemented JASS receiver support.** Atex consumes one Pile Of Wood `I60K` per inspection with the recovered 50% approval chance until ten logs pass, then receives Dust Collector M25 `I00I`, Dustfilter 9000-BA `I00G`, and Vent-o-Matic Blower R200 `I00H`. Atex is hidden when the betrayal removes his contractor identity from the mine entrance. |
| `qAradion.j` | Ranger Missing; Crystals of Hope; Fading Sparks; Rifts of Corruption | **Implemented JASS.** Ranger Missing leads to two parallel collection/investigation quests, then Rifts requires all three. Uses Vanguard Vale, Verdant Plains, and Redwind Pass. Test quests are disabled. Valeria's post-reunion Dash rawcode remains a TODO. |
| `qValeria.j` | Token of Love; Lost Supplies | **Implemented JASS.** Token follows Ranger Missing; Lost Supplies follows Token. Uses dedicated token and seven supplies rects. |
| `qKaelthir.j` | Kaelthir's Struggle; Kaelthir's Hunger | **Implemented JASS.** Normal + Story in Vanguard Vale `9`. Struggle consumes one Mana Crystal `I00Y`. Hunger requires Struggle and records one durable QuestData outcome: mercy, feeding Kaelthir into a Mana Wraith `n002`, or escorting him to Aradion for a failed cure. The Aradion path uses `gg_rct_AradionPlace`. |
| `qOutcastJinzun.j` | Plague Upon Trees; Lurking In The Shadows; Unknown Entity; Seeds of Life; Resurgence of Dead I; Resurgence of Dead II; Da Fishing Pole Missing | **Implemented JASS.** Forms a nature-to-undeath side arc through tree runes, lake, dead trees, graveyard, Zaekolaerr inquiry, and Crypt-facing escalation. |
| `qVelyssara.j` | Chains of Seduction | **Implemented JASS.** Normal + Story in Sereneglade `2`, available to Nazgrek. Accepting Velyssara's charm confines him to Sereneglade and makes her follow him while he spreads four rumors, steals Gnoll Pillage `I6A4`, kills a Horde member, and dies/revives. Jin'Zun can instead dispel the charm and redirect the quest to killing Velyssara. Completion awards 300 XP and Orb of Lifesteal `I6A5`. The library preserves legacy "Succubus" behavior under canonical Velyssara and exposes confinement, escape-attempt, teleport, dispel, and respawn hooks. |
| `qKribugs.j` | Ogre Lost His Sandwich; Kribugs Lost His Satchel; Ogre Is Very Thirsty; Meat For The Ogre; Ogre Ate Too Much; Angry Customers | **Implemented JASS.** Three early normals, two repeatables, and one gnoll-kill follow-up. Keep as comic relief rather than a main-story gate. |
| `qQuinx.j` | Shredder Fuel | **Implemented JASS; WE placement verification required.** Level-5 Normal side quest for both heroes. It consumes Goblin Rocket Fuel `j4c2`, confirmed by the map author and sold through the specialized goblin explosives/reagents catalog, then makes Quinx's shredder repeatedly harvest nearby valid trees with short pauses. Confirm Quinx's unit rawcode, zone, placed `udg_Quinx` assignment, and nearby harvestable trees in World Editor. |
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
| Boom Mine | `DungeonBoomBrothersMine.j` registers zone `104`, patrol waves, and explosive/barrel events; `qBoomBrothers.j` targets that dungeon and exposes reclaimed/access state. | The converted chain now leads into the real dungeon. The dungeon portal is still physically ungated, so the semantic access flag must be consumed if chain-gated entry or post-completion ore access is added. |
| Mad Blix | `BossMadBlix.j` contains the recoverable mana-absorption mechanic and reports `BOSS_EVENT_DEATH` to `qBoomBrothers_ReportMadBlixDefeated`; legacy phase files are empty. | Quest completion is wired, but the boss remains **Partial** until additional mechanics are deliberately designed and tested. |
| Rol'jin | `BossRoljin.j` exists. | Granis's voiced Rol'jin hunt can target an existing boss encounter. |
| Nazgrek's Flask | Item `I61L`, its six-material recipe, item ability evidence `A63V`, and the converted `qNazgrek.j` quest all exist. | **Implemented/rebalanced for the prologue.** The existing reusable flask is deliberately reused rather than replaced by a disposable vision draught. Its recipe retains the recovered GUI material costs but now requires Alchemy 0 so the level-1 story is possible. Runtime balance and the flask's exact advantage against Wolf Mother still need testing/design. |
| Zul'karak | Unit `n65F` is present in the debug object registry and reputation unit list, is already preplaced on the Darkspear shore, and is bound to `udg_Zulkarak`. | `qZulkis` now treats `udg_Zulkarak` as the authoritative handle and relocates that unit through the landing, captivity, rescue, and Horde-base states. His older-brother dialogue and rescue are implemented. His later Horde-base quests, recruit unlock, simple berserker AI, and dismissal/home-return behavior remain planned. |
| Crypt boss roster | `ZonesCore` names Skullreaver, Rotspine, Bone Golem, Darkmaw the Soul Devourer, and Marduk the Endbringer for Crypt `102`. | Treat the ODT's Warden, Cryptlord, and king's shade as encounter roles or discarded working names until deliberately mapped to current bosses. |
| Gar | `BossGar.j` creates unit `n60Z` only through `BossGar_Spawn()`, then patrols `gg_rct_GarWP01` through `gg_rct_GarWP06` at 60 movement speed. | **Partial JASS.** The reusable two-phase encounter and quest/event spawn hook are implemented in Deadwoods. Quest ownership, explosives, reward, and canonical outcome remain open. |
| Dawnhold ship service | `TravelShipA.j` already owns an active Sirensong–Dawnhold–Stormhaven neutral route and registers Dawnhold stop `20`. | Legacy Fix the Ship must not blindly unlock baseline travel. Use it for a separate goblin vessel, route/service upgrade, fare benefit, repair incident, or an intentional availability gate designed with the current travel system. |
| Human patrols | `World/HumanPatrols.j` creates a configurable random total of one or two recurring human patrols after 60 seconds. Each patrol receives one fixed route class: Sereneglade `2`–Twilight Grove `1`, or Havenwoods-only `7`. When two spawn, one uses each route; when one spawns, its route is random. Patrols independently move in formation, camp, respawn, and may share one active Captain Maelhood `h602` scout between them. All system-owned patrol units and tents are excluded from normal `CreepRespawn`. | **Ambient JASS implemented; quest chain proposed.** Indexed APIs expose each patrol's group, tent, leader, route, camp state, and destination while the original singular getters remain compatible. The ambient system does not itself award quest credit, drop the letter, capture a prisoner, or start garrison attacks. |
| Mok'natha battle | `World/MoknathaBattle.j` recreates the two-lane orc/ogre skirmish and seven crater ubersplats with small randomized spawn-count and route variations. | **Ambient JASS implemented.** The battle is independent of quest state for now, but exposes start, stop, force-cycle, group, and crater-visibility hooks for the future Sirensong regional arc. |
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
Nazgrek prologue: Shadowclaw -> Wolf Hunt I -> Nazgrek's Flask -> Wolf Hunt II
    -> optional Wolf Hunt III crafting epilogue
    -> Protect the Outpost -> fade to Zul'kis
Zul'kis prologue: Darkspear landing -> Thork -> destroyed landing camp
    -> Rescue the Brother -> return to the Horde base -> fade to Nazgrek
Nazgrek: Call of the Horde -> Nazgrek and Zul'kis meet at Thork
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
| ST-P-02 | Wolf Hunt I | **Implemented JASS; WE intro-finish hook required** | The shared normal/ESC completion path of Nazgrek's intro cinematic calls `qNazgrek_StartIntroQuestChain()` to begin the self-discovered hunt only after gameplay returns. The quest kills six wolves across the current Sereneglade wolf/alpha-wolf rawcodes and gathers six Wolf Skin `I61F`. It is a compact player-control beat rather than a separate quest-giver conversation, and its completion starts Nazgrek's Flask without consuming the skins needed by the later cowl. |
| ST-P-03 | Nazgrek's Flask | **Implemented JASS; runtime balance pending** | Nazgrek realizes ordinary preparation may not be enough for the Wolf Mother. The converted quest uses the recovered six Forest Flower, three Agave, two Earth Roots, six Stag Hair, two Frog Slime, and one delayed Empty Flask requirements, then completes on acquisition of existing flask `I61L`. The existing alchemy recipe is deliberately reused at skill 0 and remains a reusable item; define/test what advantage it gives in the Wolf Mother encounter. |
| ST-P-04 | Wolf Hunt II | **Planned; object/encounter work required** | Enter Wolf Den `12111` in northern Sereneglade, defeat Wolf Mother `n648`, and recover one unique trophy. Use a dedicated Wolf Mother's Head or Pelt item; ordinary Wolf Skin cannot distinguish this kill from Wolf Hunt I. The trophy naming decision must also satisfy Wolf Hunt III. |
| ST-P-05 | Wolf Hunt III | **Planned optional crafting epilogue** | Create a Shamanic Cowl from the Wolf Mother trophy, the retained six Wolf Skin `I61F`, two Light Leather `I6A6`, and one Thread `I66L`. It should be a skill-0 introductory Leatherworking recipe and must not delay Protect the Outpost or the Zul'kis handoff. Define the cowl/trophy rawcodes, confirm early Light Leather and Thread acquisition, and decide whether the trophy is the head, pelt, or both before implementation. |
| ST-P-06 | Protect the Outpost | **Implemented JASS** | First visible act of service. The gnoll-attack cinematic completes before quest acceptance, leaving the shared five-second discovery delay to present the objective after the scene. Ragno survives, notices Nazgrek, and gives the Call of the Horde letter. Its completion ends the separate Nazgrek section with a fade to Zul'kis's intro. |

Legacy intro beats worth retaining are Shadowclaw reacting defensively when the patrol mocks Nazgrek, Nazgrek choosing restraint, and the hut serving as the first quiet player-controlled space. Keep new cinematics short: the wolf/flask objectives carry the playable introduction, Wolf Hunt III is optional, and no extra Nazgrek quest should be inserted before Protect the Outpost without replacing an existing beat.

Current self-discovered scope is limited to Wolf Hunt I–III and Nazgrek's Flask. No other Nazgrek-owned self-discovered quest is approved in this plan. The later elemental and ancestral shaman progression may contain spontaneous spirit encounters, but those class quests still need confirmed trainers/spirits, ability rewards, and rawcodes and should not be treated as additional prologue errands.

### Parallel prologue — Zul'kis and the broken landing (levels 1–3)

Zul'kis's separate playable opening begins only after Nazgrek completes Protect the Outpost. It ends before Nazgrek turns in Call of the Horde, so the two heroes first meet during that existing completion scene at Chieftain Thork. This parallel section is deliberately short and linear.

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-ZP-01 | Darkspear landing cinematic | **Implemented JASS; runtime validation pending** | `qZulkis` takes over behind a controlled black-screen handoff, initializes Zul'kis's inventory/equipment and grants his one-time starter loadout through `Start.j`, temporarily changes `udg_GraveyardSelect` to Graveyard02 ID `2`, and suspends the gameplay camera controller. Before every zero-second camera setup, the scripted-camera takeover clears stale target bindings, stops queued gameplay-camera movement, and disables smoothing so the setup is a true hard cut. The river view applies `IntroZulkisCam2` at `0.00` seconds and moves toward camera 1 over 20 seconds; five seconds later it applies camera 5 at `0.00` seconds and moves toward camera 6 over 15 seconds. The shore dialogue applies camera 3 at `0.00` seconds and moves toward camera 4 over 20 seconds. The exact prior graveyard ID is restored at prologue completion. The loadout uses Shadowcaster's Scepter, eight mostly flavor-only common Darkspear travel pieces, two Mana Potions, one Healing Potion, and Purified Water. It creates ship `'odes'` at `gg_rct_ZulkisShipWP1`, moves it to `gg_rct_ZulkisShipWP2`, removes it on arrival, and stages Zul'kis plus six living Darkspear trolls on the confirmed shore rects. ESC skips the non-dialogue ship movement into the shore scene, and the transition state prevents repeat fade scheduling. |
| ST-ZP-02 | Brothers on the shore | **Implemented dialogue** | Two minimal narrator lines begin with the river-arrival cinematic, establishing that Zul'kis and his Darkspear tribe are arriving along Havenwoods' eastern river after answering Thork's call to aid the orcish clan, and identifying Zul'karak as Zul'kis's elder brother. The later shore sequence begins directly with the brothers and leaves all tension and foreshadowing to the characters. Zul'karak warns that the tribe's wise one sensed a dark threat, Zul'kis trusts Thork's promise of a quick meeting, and Zul'karak remains to guard the landing. Speaker-owned constants live in `Voicelines_Narrator.j`, `Voicelines_Zulkis.j`, and `Voicelines_Zulkarak.j`. |
| ST-ZP-03 | Meet with Chieftain Thork | **Implemented Normal + Story** | The first `qZulkis` quest begins after the shore conversation. Thork selection is redirected from `qChieftainThork` while the prologue is active; he questions the tribe's absence and orders Zul'kis back while warning about Havenwoods humans. The same quest then tracks the return to shore. |
| ST-ZP-04 | The broken landing | **Implemented continuation; runtime validation pending** | Immediately after Thork orders Zul'kis back, the unseen shore swaps the five headhunters to permanent fleshy corpses through the recovered GUI staging helper, moves `udg_Zulkarak` to `gg_rct_ZulkarakCaptive`, and places the witch doctor at 03 in a slowed death pose with intermittent chest blood effects. Returning near `gg_rct_ZulkisStart` reveals that already-completed staging and plays his testimony; his final line is cut short when the same witch-doctor unit is killed, stopping its bleeding and suspending its decay without replacing or restaging the resulting corpse. Almost immediately, four orc grunts patrolling from the Horde's direction enter the same uninterrupted cinematic, find Zul'kis by chance, and offer to help him fight through the forest trolls while he supports them. All six Darkspear corpses remain preserved during Zul'kis gameplay and resume normal decay when the prologue ends. Fire effects mark the destroyed landing after the intro ship has already been removed. |
| ST-ZP-05 | Rescue the Brother | **Implemented Normal + Story** | Rescue the existing `udg_Zulkarak` (`n65F`) in Bloodtusk-controlled Bramblehide Village `701`. No artificial enemy guard wave is created; the village's existing forest trolls supply the danger. The four-grunt patrol joins Zul'kis through the companion controller in Normal mode, temporarily exceeds the ordinary level-based party cap, accepts the shared group modes and companion Move/Attack orders, and is removed completely after the prologue. A dedicated hint recommends keeping Zul'kis behind the grunts to heal and support them. Zul'karak identifies his captors only as forest trolls and says they questioned him about what he witnessed at the shore; he does not know they carried out Thork's false-flag attack. Reaching Zul'karak completes the rescue scene, stages him at `gg_rct_ZulkarakHordeHome`, stages Zul'kis at `gg_rct_ZulkisHordeStage`, and fades back to Nazgrek. |
| ST-ZP-06 | Call of the Horde convergence | **Implemented integration; runtime validation pending** | `qRagno` starts the Zul'kis prologue from Protect the Outpost's completion fade. `qChieftainThork` gates letter readiness/completion on `qZulkis_IsPrologueCompleted()` and only then restores Zul'kis as a visible, vulnerable Player 1 companion during the existing Nazgrek meeting. |

Hidden story truth: Thork paid the local forest trolls to destroy the Darkspear landing and leave no survivors before Zul'kis returned. The attack was staged to implicate humans, binding a grieving Zul'kis to Thork's Horde through a manufactured common enemy. Zul'karak's survival and capture were not part of Thork's plan, nor was Zul'kis meant to find him; the wounded witch doctor's brief survival was another failure in the cleanup. The captors question Zul'karak about what he saw because they need to know whether the false flag was exposed, but Zul'karak cannot identify the shore attackers. Do not reveal Thork's role during the prologue. Seed recoverable inconsistencies—human-looking weapon marks, the attack timing, missing supplies, forest-troll payment, or survivor testimony—for the later investigation.

Zul'karak's post-rescue arc uses two phases. First he gives a short, non-gating quest set from the Horde base. After those quests, he becomes recruitable through the shared companion system. His combat support should use a small dedicated berserker AI—assist Zul'kis's current target, use one or two configured combat abilities, leash/teleport back when separated, and stop while dismissed or at home—not the advanced role logic used by `AIWarrior`. Kicking him removes companion ownership and orders him home; if he does not reach the verified Horde-base home rect within the timeout, teleport him there and restore quest-giver state.

Use the witch doctor at `gg_rct_CorpseTroll03` as the dying survivor, so every visible arrival troll has a return-scene outcome and the sixth corpse appears naturally after the testimony. Move or hide `udg_Zulkarak` when the landing is destroyed, then relocate that same unit to captivity; never leave a shore copy behind, search for another `n65F`, or create a second brother for the rescue.

### Act I — Earning a place (levels 3–10)

| Design ID | Quest / beat | Status | Purpose and connection |
|---|---|---|---|
| ST-A1-01 | Call of the Horde | **Implemented JASS with Zul'kis gate** | After both separate prologues, carry Ragno's blood-signed letter to Chieftain Thork. Its completion is the first Nazgrek/Zul'kis meeting and the point where shared gameplay begins; `qChieftainThork` now requires `qZulkis_IsPrologueCompleted()` before readiness, completion, or enabling Zul'kis. |
| ST-A1-02 | Duty For The Horde | **Implemented JASS** | Thork requires the separately tracked completion of Granis's Punish and Garthork's The Magical Eye. It is the Act I spine, not a generic reputation grind. |
| ST-A1-03 | Punish / Rol'jin's Head | **Implemented JASS** | Granis sends Nazgrek to kill the existing Rol'jin boss and return item `I600`; completion reports Granis's proof to Thork. |
| ST-A1-04 | The Magical Eye | **Implemented JASS** | Garthork identifies Nazgrek's Thunderlord past, requests Mur'gal's eye `I601`, and reports the proof to Thork. The later spiritual-sight follow-up remains proposed. |
| ST-A1-05 | Mountain Defense | **Implemented JASS** | Granis commissions the quest and receives the final report, but Ragno is its field commander and operational story anchor. It is a distinct second assault after Ragno's Protect the Outpost, with nine staged waves, defender/Ragno survival rules, and retry cleanup. |
| ST-A1-06 | Gnoll camp clue → Gnoll Hideout | **Legacy Articy; proposed bridge** | A southern-camp objective reveals stolen Horde resources and an external organizer, then unlocks dungeon `101`. The dungeon book/ledger becomes story evidence instead of a standalone collectible. |
| ST-A1-07 | Satyr Negotiations | **Implemented opening and arena gate; partial branches** | Zaekolaerr offers an arena test, a hostile rupture/escape, or apparent cooperation. `qZaekolaerr` records the selected outcome; the arena route requires completing any challenge in the Coliseum of Ages through satyr arena master `n62V`. The later escape, betrayal, trust, and convergence consequences remain to be implemented. |
| ST-A1-08 | Thork's judgement | **Proposed** | Thork evaluates Granis, Garthork, dungeon, and satyr outcomes. Nazgrek gains conditional standing with the Horde and a route toward Ghostwalk Ridge. |
| ST-A1-09 | Tents in the Woods | **Ambient support implemented; quest proposed** | After Duty For The Horde, Thork points Nazgrek toward recurring human patrol camps. One or two patrols operate independently, assigned either to the Sereneglade `2`–Twilight Grove `1` route or to Havenwoods `7`; destroy three patrol tents. Captain Maelhood is unique and only has a chance to accompany one active patrol, so finding him cannot be assumed on every camp cycle. |
| ST-A1-10 | Orders in Ink | **Proposed** | Kill Captain Maelhood and recover his letter. The letter records reconnaissance for hostile threats and the captain's findings; it is evidence that the Havenwoods garrison is watching Horde activity, not proof that the Alliance had already committed to an invasion. |
| ST-A1-11 | A Living Witness | **Proposed** | Subdue and escort one patrol member alive to the Horde base while the captive may attempt escape or resistance. Interrogation reveals that at least one patrol report likely reached the nearby Havenwoods garrison and that its readiness may increase. |
| ST-A1-12 | Before They March | **Proposed** | Thork orders a pre-emptive strike on the Havenwoods garrison: place timed explosive barrels at the barracks, watchtower, and stables, defend each one-minute fuse, and leave each objective area burning. A hero may carry at most three quest barrels and can replenish them at the Horde base. Exact structures, rects, barrel rawcode, fire state, blast damage, defenders, and failure/reset rules require World Editor verification. |
| ST-A1-13 | Ashes and Warnings | **Proposed** | After all three targets burn, a named reinforcement officer arrives, promises retaliation, and escapes before the player reports to Thork. This starts recurring human counterattacks until a later reconciliation or military follow-up resolves them; the chain pauses here for now. |

Recommended satyr consequences:

- **Arena:** complete an optional combat trial; earn respect and cleaner access to Zaek's information.
- **Hostile rupture:** escape satyr territory and report to Granis; later satyr patrols are more aggressive.
- **False alliance:** perform one morally suspicious reconnaissance task, discover the planned betrayal, then expose or reject Zaek. Do not require killing Ragno or burning the Horde base as an irreversible main-story action.

Legacy concepts such as draining orc life, killing Ragno, and setting the base on fire can survive as threatened outcomes, illusions, failed-state content, or an explicitly selected dark branch. They should not silently replace the stable Act I hub.

The Havenwoods patrol chain should deepen Thork's morally ambiguous leadership rather than make the human garrison secretly part of the Dark Horde. Thork frames incomplete reconnaissance evidence as grounds for pre-emption, and the later human attacks are a consequence of the player's sabotage. The genuine Dark Horde conflict in Dragonfire Peaks remains a distinct later escalation; a later reveal may compare or exploit the two conflicts, but should not erase the agency of either faction.

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
| ST-A3-06 | Sirensong regional arc | **Ambient battle implemented; quest synthesis proposed** | `MoknathaBattle.j` now supplies a recurring randomized orc/ogre skirmish and battlefield craters at Mok'natha `1401`. Link that event with Zul'Garok Ruins, Urgmar, Serpentshore, Kelziss, and Jinnvorrak through raids, ruins, and a growing naga/hydra threat without requiring the ambient battle to be a quest gate. |
| ST-A3-07 | Boom Brothers chain | **Implemented JASS + partial dungeon boss** | The five voiced quests now run through `qBoomBrothers.j` and `qAtexBlix.j`, culminating in Mad Blix's death in Boom Mine `104`. Completion exposes free/friendly mine-access state; a physical portal gate and renewable ore benefit remain follow-up dungeon work. |
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

Implemented Boom Brothers sequence:

1. **Explosive Crisis** — bring six Barrel of Explosives `I00F`; carried barrels retain the recovered one-in-five damage-triggered detonation risk. Thieves remain the primary route, while Sirensong reagent merchant Snikka Sparkdust `n047` sells a costly fallback at 500 gold per barrel, two in stock, replenishing one every 600 seconds.
2. **Boomsite Compliance Inspection** — Atex consumes Pile Of Wood `I60K` one at a time, approving each with the recovered 50% chance until ten pass.
3. **Dust Isn't Just Dirt — It's Combustible Culture** — bring Dust Collector M25 `I00I`, Dustfilter 9000-BA `I00G`, and Vent-o-Matic Blower R200 `I00H` to Atex.
4. **Mandatory Training** — escort the invulnerable Boom Brothers follower to `gg_rct_KoboldCamp`, then return them to `gg_rct_BoomBrotherMineEntrance`; Atex disappears, two `n01I` turrets turn hostile, and a temporary `n01B` Mad Blix reveals the theft.
5. **Boom Will Be Back** — defeat the registered Mad Blix boss in Boom Mine `104`, return to the Boom Brothers, receive Crown of Kings +5 `ckng`, and set the mine-reclaimed/access state.

The escort giver is temporarily invulnerable so ordinary combat cannot strand the chain without a valid quest giver. World Editor integration must keep the referenced rects and placed globals, disable the recovered GUI folders, and compile both new qXXX libraries after their dependencies.

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

The Articy bank contains Elemental Fire, Water, Air, Earth, Ghost Wolf, Ancestral Ward, and Totemic Resurgence. The four elemental covenants are implemented as an ordered Elemental Master chain—Air, Earth, Fire, then Water—because they directly unlock Summon Elemental ranks 1–4. They use `normal` + `class` metadata and can begin at any Elemental Master, while turn-in remains bound to the trainer who started that rank. Future dialogue or regional objectives may connect the hunts more tightly to the story without changing this trainer contract. Ghost Wolf, Ancestral Ward, and Totemic Resurgence should still be tied to story revelations rather than becoming disconnected trainer errands.

| Stage | Class quest | Recommended story connection |
|---|---|---|
| Early | Water / Earth | Jin'Zun's damaged trees and Garthork's spirit-sight lesson |
| Mid | Air / Ghost Wolf | Ghostwalk tracking and Shadowclaw's spiritual bond |
| Mid-late | Ancestral Ward / Totemic Resurgence | Shadowclaw aftermath, Deadwoods spirits, and Elarindor rifts |
| Late | Fire | Emberpeak and Firelands; master fire without repeating the enemy's exploitation |

The elemental chain now uses Elemental Master `o627`, Summon Elemental `A67Q`, and essences Air `I6C7`, Earth `I6C8`, Fire `I6C5`, and Water `I6C6`. Stormcaller `A6A3` remains required. Essence sources and chances are owned by WC3 Manager's unit-specific drop data rather than quest-specific JASS: Zephyros and Aqualon are the limited guaranteed Air and Water sources; the configured Lava and golem units provide Earth; and the configured Fire Lords, Fire Spawn, Ragnaros, Scorchion, and Enslaved Fire Spirit provide Fire. The Colossus Earth drop remains pending until its placeholder `XXXX` rawcode is finalized. Ability rewards, rawcodes, and actual trainer ownership for the remaining class quests still require separate design against the current ability system.

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
| GQ-017 | Wolf Hunt I–III | Normal + Story chain | Nazgrek (self-discovered) | Sereneglade / Wolf Den `12111` | Promoted into Nazgrek's prologue. Wolf Hunt I and the interposed Nazgrek's Flask quest are implemented in `qNazgrek`; Wolf Hunt II targets Wolf Mother `n648`, and optional Wolf Hunt III crafts the Shamanic Cowl once its trophy and recipe objects are defined. |

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

### Unplaced side content

| Plan ID | Working title | Type + category | Giver | Objective location | Connection |
|---|---|---|---|---|---|
| GQ-051 | Shredder Fuel | Normal | Quinx | Specialized goblin merchant; return to Quinx | **Implemented JASS; WE verification required.** Bring one Goblin Rocket Fuel `j4c2`; afterward Quinx periodically harvests nearby trees. Confirm Quinx's final zone, rawcode, placement, and tree layout before treating the content as map-integrated. |

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
| Boom Mine `104` | Defeat Mad Blix and return the mine | Engineering materials or hazard-clearing | One-time story chain implemented; runtime dungeon and boss mechanics remain partial |
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
| Nazgrek intro cinematic | `qNazgrek` | Call `qNazgrek_StartIntroQuestChain()` when player control begins; do not start the quest during the opening fade/camera sequence. |
| Wolf Hunt I | Nazgrek's Flask | `qNazgrek` owns the automatic transition and preserves the six Wolf Skin for the later Shamanic Cowl. |
| Nazgrek's Flask | Wolf Hunt II | Add a semantic flask-completion query/encounter gate; decide whether possession, consumption, or a temporary encounter effect overcomes Wolf Mother. |
| Protect the Outpost | Zul'kis prologue | After Ragno's defense and letter award, fade out and transfer active control to Zul'kis without completing or consuming Call of the Horde. |
| Zul'kis landing cinematic | Broken landing | Stage living trolls at `gg_rct_CorpseTroll01`–`06`; after Zul'kis returns from Thork, replace the five headhunters with permanent corpses and keep the witch doctor at 03 alive for his testimony. Kill that same witch-doctor unit during his interrupted final line and preserve its corpse through the same suspended-decay lifecycle. Continue the cinematic through the chance arrival and recruitment of the temporary four-grunt patrol. Disable the legacy elapsed-time trigger so it cannot perform the swap early. |
| Rescue the Brother | Call of the Horde | `qZulkis_IsPrologueCompleted()` is the durable gate; `qZulkis` fades back to Nazgrek and stages Zul'kis at Thork, while `qChieftainThork` enables shared gameplay only after that query is true. |
| Protect the Outpost | Call of the Horde | Stable completion state plus the current external unlock event |
| Protect the Outpost | Horde mountain ambient chat | Call `HordeUnitsRandomChat_EnableMountainChat()` after the completion cinematic; the ambient library owns the one-shot region sequence. |
| Call of the Horde | Duty For The Horde | Thork sees Ragno's letter/completion without duplicating quest state |
| `qGranis` and `qGarthork` | `qChieftainThork` | Public completion notifications for their assigned proof quests; preserve retries and failure cleanup |
| Satyr Negotiations / Zaekolaerr | Later Granis, Elarindor, and Verdant dialogue | One durable outcome enum/flags, not title-string comparisons scattered across libraries |
| Gnoll Hideout story quest | Thork judgement | Dungeon evidence completion signal independent of replayable dungeon tasks |
| Shadowclaw arc | Companion and ability systems | Explicit join/leave/death/spiritual-successor state before the demise cinematic |
| Boom Brothers chain | Boom Mine and Mad Blix | `qBoomBrothers_ReportMadBlixDefeated()` receives the boss death; `qBoomBrothers_IsTrainingActive()`, `qBoomBrothers_IsMineClaimedByBlix()`, `qBoomBrothers_IsMineReclaimed()`, and `qBoomBrothers_IsMineAccessGranted()` expose escort and ownership/access state. |
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
| Erduk | `qErduk.j` converts Heads of the Murlocs, its 40 Murloc Head `I610` objective, `gg_rct_LakeAmbient042` reveal, and recovered dialogue on the outskirts of Ironspine Post | Disable the old Erduk GUI trigger group and runtime-test the lake reveal, modern turn-in, and rewards |
| Valeria | Current qValeria plus unexported legacy triggers | Identify which companion objectives remain missing; verify old “Velaria” references by rawcode so they are not confused with Velyssara |
| Velyssara / Zaekolaerr link | `qVelyssara` now implements the recovered Chains of Seduction tasks, Jin'Zun dispel route, combat event, reward, and Sereneglade confinement | Decide who the unnamed master in Velyssara's combat line is, whether she serves or rivals Zaekolaerr, and whether a future branch can cleanse or spare her. |
| Wolf Hunt II–III | Wolf Mother `n648`, ordinary Wolf Skin `I61F`, Light Leather `I6A6`, Thread `I66L`, Wolf Den `12111`, and the requested Shamanic Cowl conclusion | Create/confirm a unique Wolf Mother trophy and Shamanic Cowl rawcode, settle head versus pelt naming, verify early acquisition for two Light Leather and one Thread, register the introductory recipe, verify the Wolf Den encounter, and define the flask's encounter advantage. |
| Nazgrek's Flask | Existing item `I61L`, the exact recovered GUI ingredients, the active alchemy recipe, and `qNazgrek.j` now align | Import/start the new library, disable the legacy GUI folder, verify the skill-0 recipe and reusable flask balance, and runtime-test delayed Empty Flask discovery plus completion after crafting. The old completion also disabled `Spawn Plants Intro`; confirm that spawner still exists and wire its shutdown to `qNazgrek_IsFlaskCompleted()` or remove the obsolete extra spawn in WE. |
| Zul'kis prologue / Zul'karak | `qZulkis` implements the confirmed cameras/rects, temporary ship, two Normal + Story quests, Bramblehide rescue, corpse staging, hero handoffs, and convergence API. `ZonesCore` registers Bramblehide Village `701`; new Zul'kis, Thork, Zul'karak, and Generic Troll dialogue constants cover the prologue. | Disable the legacy 5-second corpse GUI trigger, import the new libraries in dependency order, add any desired audio files for the prepared keys, compile/runtime-test every fade and ownership transition, and later design Zul'karak's Horde-base quests plus recruit unlock, simple berserker AI, and dismissal/home-return contract. |
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
11. **Boom Mine access benefit:** the converted chain exposes semantic reclaimed/access state, but `DungeonBoomBrothersMine.j` does not yet gate entry or create the promised renewable ore access. Decide whether entry is ever locked and what post-completion mining benefit is safe for the economy.
12. **Wolf Mother trophy and flask effect:** decide whether Wolf Hunt II awards a Head, Pelt, or both; create the Shamanic Cowl output around the planned trophy + six Wolf Skin + two Light Leather + one Thread recipe; and choose a clear encounter mechanic for Nazgrek's reusable flask that does not make the boss impossible after the flask buff expires or the item is lost.
13. **Thork's false-flag reveal:** the premise is resolved: Thork directly paid local forest trolls to kill every Darkspear at the landing and stage the attack as human work, intending to manipulate the bereaved Zul'kis into serving his Horde. Zul'karak's survival/capture and the witch doctor's testimony were unintended loose ends. Decide the evidence trail, when Zul'kis learns the truth, whether the forest trolls remain available as witnesses, and whether confrontation changes Horde standing or only later support/dialogue.

Recommended antagonist structure: use a coalition or chain of exploitation rather than one controller behind everything. Satyrs exploit local division, necromancers exploit death, the Dark Horde and demons industrialize fel/elemental power, and the void presence opportunistically amplifies the damage. This preserves faction identity while giving Nazgrek one thematic conflict.

## 14. Recommended implementation order

1. Import and runtime-test `qNazgrek.j`, the intro cinematic's shared normal/ESC Wolf Hunt I start hook, the skill-0 `I61L` recipe, delayed Empty Flask objective, and legacy GUI replacement; then create the unique Wolf Mother trophy and Shamanic Cowl data needed for Wolf Hunt II–III.
2. Import and runtime-test `qZulkis.j`, Bramblehide Village `701`, all camera/fade/ownership transitions, the removed intro ship, Thork selection redirect, shore corpse swap, Rescue the Brother, Nazgrek return, and Call of the Horde gate. Then design Zul'karak's Horde-base quest set before implementing his recruit unlock, simple berserker AI, and dismissal/home-return behavior.
3. Runtime-validate the implemented second Mountain Defense as distinct from Protect the Outpost and keep their completion/failure state separate while adding the new prologue handoff.
4. Finish Satyr Negotiations outcome state and one convergent follow-up per choice.
5. Add the Gnoll Hideout one-time package and use its evidence in Thork's Act I conclusion.
6. Use Dawnhold `20` for the ODT's ruined Vanguard city/docks and Deadwoods `11` for Gar `n60Z`, then verify exact quest rects plus the northern-outpost and Ghostridge mappings before placing Act II/III objectives.
7. Audit Shadowclaw's current companion systems, decide the death variant, then write the Act II chain without implementing the demise until cleanup/replacement behavior is safe.
8. Reconcile the seven Crypt quests and encounter roles with the current five-boss roster, room layout, and Jin'Zun/Garthork dependencies.
9. Runtime-test the converted Boom Brothers chain against the existing dungeon, then decide the physical mine-access and renewable-ore policy before consuming its semantic access hook.
10. Build the Ironspine–Deadwoods–Dawnhold travel/story bridge and connect the implemented Jin'Zun chain.
11. Complete the Sirensong regional arc and ship route.
12. Categorize and validate the implemented Aradion/Valeria quests as story or side-story content, then add their Verdant consequence quests.
13. Recover Grum's chain and design Dragonfire/Wyrmhold/Firelands/Dreadforge as the endgame campaign.
14. Add generic quests zone by zone after checking the vendor ledger and WE placement, prioritizing hubs that currently have no repeatable support.

## 15. Quest design and implementation checklist

### WC3 Manager Quest Designer contract

`WC3_Database/WC3ItemManager/` now contains a database-backed Quest Designer for structured quest/giver metadata, objective and reward configuration, giver/receiver/prerequisite relationships, dialog/event sequences, voiceline references, QuestUI-style previewing, and validated qXXX scaffold exports. It is an authoring aid, not a replacement source of truth: current JASS, current World Editor state, this ledger, and `ZonesCore` still win when data conflicts.

- Mark ordinary shared-API work `managed`, custom-event work `hybrid`, and existing hand-owned qXXX libraries `external`.
- External sources are previewed and related in the database but are never generated or overwritten.
- Generated files are timestamped review artifacts accompanied by a database snapshot, validation report, and explicit World Editor dependency manifest. WC3 Manager fingerprints the exact generated JASS with SHA-256 and skips giver libraries unchanged since their last successful export.
- Respect the runtime limits enforced by the tool: eight QuestMaster objective slots (seven authored when turn-in reserves one), four prerequisites, and 100 DialogSystem steps.
- Treat multiple automatic trackers, repeatable resets, item consumption, branching story state, waves, companions, bosses/dungeons, timers, failure cleanup, and custom sequence actions as hybrid/hand-owned behavior.
- Reconcile every quest identity and story dependency here before implementation, and compile/test generated work through the normal JassHelper workflow.

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
