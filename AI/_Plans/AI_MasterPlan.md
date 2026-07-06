# AI Master Plan

Last updated: 2026-07-05

This document is the required planning artifact before creating `AI.j` and the
AI sublibraries. It records how the old GUI AI triggers in
`AI/_OldGUI_triggers/` should be migrated into a JASS-native system while
keeping gameplay parity, improving memory behavior, supporting many independent
AI instances, and integrating cleanly with the newer companion and dialog
systems.

## Goals

- Preserve the old GUI AI behavior unless this document explicitly calls out a
  safe bug fix or improvement.
- Replace old per-class GUI trigger patterns with one JASS master library,
  `AI.j`, plus small sublibraries for class/profile-specific logic.
- Support many independent AI units of the same class, profile, and unit type.
- Avoid building the new system around singleton globals such as
  `udg_NPC_Horde_AI_Warrior`.
- Use Table v6 for persistent AI state, registry lookups, caps, and cooldowns.
- Use `DialogSystem` / `ExSound` for all new AI chatter.
- Keep `Companions.j` authoritative for companion party membership, movement,
  modes, focus, and pet/companion command handling.
- Make future AI types easy to add without copying a full trigger tree.

## JASS Naming Rule

File names may keep underscores, for example `AI_Generic.j` and
`AI_Valeria.j`. vJASS `library` identifiers cannot use underscores in this
project import style, so the actual library names and generated public function
prefixes must use names such as `AIGeneric`, `AIWarlock`, `AIValeria`, and
`AIAradion`.

Examples:

- file `AI/Generic/AI_Generic.j` contains `library AIGeneric`;
- file `AI/Specific/AI_Valeria.j` contains `library AIValeria`;
- public calls use generated names such as `AIValeria_Enable`,
  `AIAradion_SetCombatOrders`, and `AIGeneric_RegisterProfile`;
- ordinary globals may keep underscores when that matches project style, such
  as `AI_Valeria_ProfileId`.

## Current Source Systems

The old GUI export is split into common helpers, Horde heroes, neutral heroes,
and Riverbane heroes. The migration must treat these as behavior reference, not
as final architecture.

### AI Common

- `NPC Ability Array`: defines class ability pools for Warlock, Warrior, Rogue,
  Shaman, Paladin, and Engineer.
- `NPC Ability Learn`: randomly increases an ability when an AI hero levels.
  This must be rebuilt to use each class/profile's real ability count instead
  of the old hard-coded random range.
- `NPC Chat Dialogue`: clears `udg_CompanionDialogueActive` after the old
  dialogue timer expires.
- `NPC Levels up`: restores life and mana on level up, with Warrior using no
  mana restoration.
- `NPC Pick Items`: orders Player 2 hero killers to pick items around dead
  units.
- `NPC Revival Move Dungeon`: moves companions/pets to dungeon return points
  after UnitEvent death/revival events.
- `NPC Shield Use`: gives Rogue, Warrior, Paladin, and Engineer shield-block
  reactions when attacked.
- `NPC ShopItems`: configures common shop item choices.

### Main State Pattern

The Horde Warrior, Rogue, Warlock, and Restoshaman main state triggers share the
same pattern:

- periodic 1 second think loop;
- skip null, hidden, or dead units;
- autonomous wander/attack when not a companion;
- idle order reset and random idle cooldown;
- ability and item usage when not casting, buying, selling, or retreating;
- combat retreat and base retreat at low health;
- no low-health retreat while in `udg_Companion_Group`.

Paladin and Engineer have action, chat, and revival triggers, but their old
main state export is missing or incomplete. The new system must register them
into the same shared state engine.

### Shared Action Pattern

The Warrior action set is the clearest template for common AI behavior:

- wander by attack-moving to a random playable-map point;
- buy by moving to a random shop and creating/giving a random shop item;
- sell by dropping or giving away inventory items when inventory is full;
- camp at night by using a camp-fire item and waiting through camp cooldowns;
- retreat-combat by moving a short random distance away from current position;
- retreat-base by moving to a configured retreat point;
- temporary ability swap/remove patterns for special casts.

These should become `AI.j` helpers and state transitions. GUI waits must be
replaced with state deadlines or one-shot timers owned by the master library.

### Class Ability Patterns

Sublibraries should keep the unique decision logic, but they should use common
targeting, cooldown, consumable, and temporary-ability helpers from `AI.j`.

- Warrior: Battle Shout, Bloodrage, Charge, Heroic Strike, Rend, Sunder Armor,
  Thunder Clap, Challenging Shout, Retaliation, Recklessness.
- Rogue: Evasion, Garrote, Shadowstep, Sinister Strike, Slice and Dice,
  Surprise Attack, Toxic Venom.
- Warlock: Summon Imp, Life Tap, Shadow Bolt, Curse of Agony, Life Drain,
  Fear, Rain of Fire, Banish, imp follow/firebolt.
- Restoshaman: Healing Wave, Chain Heal, Chain Lightning, Hex, Earth/Fire/Water/
  Wind totems, Earthbind while retreating.
- Paladin: Inner Fire, Holy Light, Judgement Strike, Divine Shield, Taunt,
  Lay On Hands.
- Engineer: Grenade, Mechanical Construct, Shredder form, Turret, Smoke Bomb,
  Drone, Shredder Shred/Slam/Charge/Cluster Rockets.

### Death, Revival, And Chat

- Old death triggers display companion death text, start class revive timers,
  and clear some action flags.
- Old revival triggers choose a companion graveyard or random graveyard, revive
  at 50 percent life/mana, ping for companions, and move Warlock imp as needed.
- Old AI chat triggers include greet, passive, normal, aggressive, hold, drop,
  kicked, item given, attacking, casting, killing, other companion dies, idle,
  and moving lines.
- Old chat uses GUI cinematic transmissions and generated sounds. New chat must
  use `DialogSystem` / `ExSound`, following the style already used by quest
  givers such as `qAradion`.

## Core Model

The new system must separate identity levels so generic AI types are not forced
into one global variable per class.

- `AI class`: broad reusable behavior, such as Warrior, Rogue, Warlock,
  Restoshaman, Paladin, Engineer, Mage, Knight.
- `AI profile`: concrete behavior/config definition, such as Horde Warrior,
  Riverbane Paladin, Neutral Engineer, Fel Orc Warlord, Human Knight.
- `unit type id`: Warcraft object editor rawcode used for unit-type events and
  unit-type caps.
- `AI instance id`: unique integer assigned to every registered AI unit.
- `unique id`: optional id for named special characters only. Generic units use
  `0`.

Singleton globals like `udg_NPC_Horde_AI_Warrior` must not be read by new AI
logic. If old GUI, cinematic, or UI glue still needs a named unit during
migration, it should be migrated to one of these patterns:

- unit-type lookup when the logic applies to all units of a rawcode;
- profile lookup when the logic applies to all units of an AI profile;
- unique-id lookup when the logic is truly for one named character;
- companion registry lookup when the logic is about party membership.

## Caps And Instance Identity

Caps must be configurable independently:

- class cap: maximum active units for a broad class;
- profile cap: maximum active units for a concrete AI profile;
- unit-type cap: maximum active units of a raw Warcraft unit type;
- unique cap: default `1` for named unique units.

`AI.j` should reject or delay spawns that would exceed any active cap. Dead units
waiting on revive should still count as active unless a profile explicitly says
dead units free their slot. Traveling units should count as active.

## Master Library Design

`AI.j` should be the only library that owns AI instance storage, common state
transitions, shared events, spawn/cap checks, travel, boss evasion, revival, and
chatter dispatch.

Expected requirements:

- `Table`
- `Companions`
- `UnitDeathEvent`
- `DamageEngine`
- `DialogSystem`
- `ExSound`

Expected public API shape:

```jass
function AI_RegisterClass takes string className returns integer
function AI_RegisterProfile takes integer classId, integer unitTypeId, string profileName returns integer
function AI_RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
function AI_RegisterUnitByType takes unit whichUnit, integer uniqueId returns integer
function AI_UnregisterUnit takes unit whichUnit returns nothing
function AI_GetInstance takes unit whichUnit returns integer
function AI_GetUnitByInstance takes integer instanceId returns unit
function AI_GetUnitByUniqueId takes integer uniqueId returns unit
function AI_GetProfileId takes unit whichUnit returns integer
function AI_GetClassId takes unit whichUnit returns integer
function AI_SetClassCap takes integer classId, integer cap returns nothing
function AI_SetProfileCap takes integer profileId, integer cap returns nothing
function AI_SetUnitTypeCap takes integer unitTypeId, integer cap returns nothing
function AI_SetProfileRandomUniqueId takes integer profileId, integer uniqueId returns nothing
function AI_SetUnitTypeDefaultProfile takes integer unitTypeId, integer profileId returns nothing
function AI_SetProfileAutonomous takes integer profileId, boolean enabled returns nothing
function AI_SetProfileSpawnOwner takes integer profileId, player owner returns nothing
function AI_SetProfileRegisterCallback takes integer profileId, code callback returns nothing
function AI_AddRandomSpawnProfile takes integer profileId returns nothing
function AI_SetRandomSpawnHardCap takes integer cap returns nothing
function AI_SetRandomSpawnActiveCap takes integer cap returns nothing
function AI_SpawnRandomHero takes boolean showMessage returns unit
function AI_StartTravel takes unit whichUnit, real duration, real returnX, real returnY returns nothing
function AI_ReturnFromTravel takes unit whichUnit returns nothing
function AI_RequestBark takes unit speaker, integer barkType returns boolean
function AI_SetBossFightActive takes boolean active returns nothing
function AI_RegisterBossCastAbility takes integer abilityId, real evadeRadius, real evadeDistance returns nothing
```

The exact JASS names can be tightened during implementation, but the capability
set should remain intact.

## Master State Data

Persistent per-instance data should be Table-backed and keyed by AI instance id
or unit handle id, depending on lookup direction.

Store at minimum:

- unit handle;
- unit type id;
- class id;
- profile id;
- unique id;
- current state;
- previous state;
- alive/dead/traveling flags;
- companion-controlled flag cache;
- next think time;
- next ability time;
- next item-use time;
- next chat time;
- low-health retreat deadline;
- base-retreat deadline;
- camp deadline;
- travel return time;
- revive deadline or revive timer handle id;
- spawn/home/retreat/shop point indexes;
- active cap counters for class/profile/unit type/unique id.
- random-managed spawn flags and cap-hidden flags for units created by the
  random AI population manager.

Use a small active-instance array for iteration. Do not enumerate all possible
handle ids.

## Random Spawn Manager

`AI.j` owns random AI hero spawning instead of recreating the old singleton GUI
create triggers.

Implemented behavior:

- first-wave Warrior, Rogue, Warlock, Restoshaman, Paladin, normal Engineer, and
  Aveline profiles opt into the random spawn pool;
- random spawn points come from `AI_LegacyLocations.j` profile spawn rects, with
  a playable-map fallback if a profile has no registered spawn points;
- random spawns use profile-specific owners matching old GUI intent where known:
  Horde profiles use Player 2, Riverbane profiles use Player 15, and Neutral
  Engineer uses Player 7;
- successful random world entries are announced with the profile name;
- `/debug aispawn` and legacy `aispawn` on Player 1 call the same random spawn
  path for testing.

Caps are separated from normal AI registration:

- hard random cap limits how many random-managed AI instances can exist at once;
- active random cap limits how many random-managed AI heroes may be visible and
  active at once;
- class/profile/unit-type/unique caps still apply through the normal registry;
- named unique random profiles can provide a profile random unique id so debug
  and automatic random spawning respect unique lookup and duplicate prevention;
- quest, cinematic, and manually registered unique AI are not counted against
  random-managed hard/active caps unless they were spawned through this manager.

Shop-sold or hired units should be initialized through `AI_RegisterUnitByType`
and `AI_SetUnitTypeDefaultProfile`, using the `EVENT_PLAYER_UNIT_SELL` hook.
Do not add generic AI setup to playable-map-enter triggers; PotS routes those
critical enter-time systems through the existing `Init 07 Unit Event Enters`
trigger only.

When the active random cap is full:

- new random spawn attempts stop instead of creating another unit;
- a returning traveled or revived random-managed unit remains hidden/paused if
  there is no visible slot;
- the travel timer periodically tries to unhide one cap-hidden random-managed
  unit when visible capacity opens.

## Common AI States

The first `AI.j` implementation should support these states:

- inactive;
- idle;
- wander;
- combat;
- retreat-combat;
- retreat-base;
- buy;
- sell;
- camp;
- travel;
- dead;
- companion-controlled;
- boss-evade.

State transitions should use timestamps and helper checks rather than GUI waits.
The master tick should be pooled and bounded. A 0.50 to 1.00 second tick is
appropriate for parity; expensive scans should be throttled per instance.

## Memory And Performance Rules

- Prefer XY math over locations for movement and distance checks.
- Reuse private temporary groups where safe, and always `GroupClear` before
  reuse.
- Destroy created groups/forces/locations/timers/triggers/effects when they are
  not intentionally persistent.
- Null local handle variables before function exit.
- Avoid per-instance periodic triggers.
- Avoid GUI waits.
- Avoid repeated full-map scans inside every AI tick.
- Use UnitEvent, UnitDeathEvent, DamageEngine, and shared spell/order events
  instead of duplicate per-class event registrations when practical.

## Companion Integration

`Companions.j` already owns:

- `udg_Companion_Group`;
- companion add/remove;
- mode application;
- normal/aggressive/passive/hold behavior;
- focus handling;
- command-card casts;
- idle state maintenance;
- companion information output;
- pet registration through `Pet.j`;
- GUI compatibility for companion arrays and UnitHider references.

AI must not duplicate that controller.

While an AI unit is in `udg_Companion_Group`:

- disable autonomous wander, buy, sell, camp, travel, and normal low-health
  retreat by default;
- keep combat ability usage active;
- keep chatter active;
- keep death/revival active;
- allow boss-cast evade even in boss fights;
- let `Companions.j` continue issuing movement and mode orders.

AI can detect companion membership through group checks and cache changes in the
instance state. This avoids a hard dependency from `Companions.j` back into
`AI.j`.

## UDG Policy

Keep `udg_` variables when they are shared state owned by another system or
still required by generated map globals.

Keep using or respecting:

- `udg_Companion_Group`;
- `udg_CompanionFocusNazgrek`;
- `udg_CompanionFocusZulkis`;
- `udg_CompanionCount`;
- `udg_CompanionUnit[]`;
- `udg_CompanionIndex[]`;
- `udg_CompanionIcon[]`;
- `udg_Companion_GroupSize`;
- `udg_CompanionUnitKicked`;
- `udg_TamedUnits`;
- `udg_TamedUnit`;
- `udg_Shadowclaw`;
- `udg_InCinematic`;
- `udg_IsUnitAlive[]`;
- `udg_UnitIsCasting[]`;
- `udg_UnitMoving[]`;
- `udg_GCSM_UnitInCombat[]`;
- `udg_CompanionDialogueActive`;
- `udg_CompanionUnitIdle[]`;
- `udg_UnitHider_ReferenceUnits[]`;
- `udg_DamageEventTarget`;
- `udg_DamageEventAmount`;
- `udg_DeathEvent`;
- `udg_UDex`;
- `udg_UDexUnits[]`;
- `udg_GraveyardSelect`;
- `udg_ExSoundDuration`;
- `udg_ExSoundString`.

Replace AI-only GUI globals with `AI.j` instance/profile/class state:

- old wander/buy/sell/camp/retreat booleans;
- old class casting timers;
- old temporary ability timers;
- old temporary points/groups;
- old class ability arrays;
- old singleton AI unit globals for AI decisions;
- old per-class main-state trigger enabled/disabled flags.

If an old singleton global is still read by external GUI glue, migrate that glue
to the new API before removing the global assignment. Do not let these globals
drive new behavior.

## Chatter And ExSound

All AI chat must move into the AI libraries, not into `Companions.j` or `Pet.j`.

Use a shared chatter helper that:

- checks `udg_CompanionDialogueActive`;
- blocks opportunistic AI chatter during `udg_InCinematic` or active
  `DialogSystem` sequences;
- validates speaker alive/visible/companion state;
- verifies at least one player hero is close enough to hear the speaker;
- supports companion-only bark types for invite, mode, drop-items, kicked,
  item-given, idle, moving, and similar party-context lines;
- selects a bark by event type and profile;
- calls `DialogSystem_PlayLine` or `ExSound_PlayAtUnit`;
- reads `udg_ExSoundDuration`;
- keeps the old global dialogue lock until the sound/transmission duration
  ends;
- uses per-instance/per-bark cooldowns plus a short global post-line gap so
  situational barks are not starved but lines never overlap;
- supports multi-speaker idle and moving conversations.

Old chat event types to preserve:

- greet;
- farewell;
- passive;
- normal;
- aggressive;
- hold;
- drop items;
- kicked;
- item given;
- attacking;
- casting;
- killing;
- other companion dies;
- idle;
- moving.

Current sound-data handling:

- Profile `RegisterBarks` functions own the standard/event bark variations for
  commands, combat, item events, idle, moving, death, and similar short
  reactions. They should not register long `Hero*_Chat...` conversation tables.
- First-wave Warrior, Rogue, Warlock, Restoshaman, Paladin, and Engineer bark
  text is migrated from `AI/Voicelines/AI_Voicelines.ods` into
  `AI_Voicelines.j`.
- `AI_Voicelines.j` registers long idle/moving chat tables and paired companion
  reply text through `DialogSystem` / `ExSound` keys, and may refresh standard
  bark text from ODS-backed data when imported after the profile libraries.
- Chat rows are only registered when the primary and reply sound keys exist in
  `ExSound.j`; ODS-only text without an imported sound remains documented data,
  not live runtime bark data.

Known sound-data issue:

- `HeroRogue_ChatGeneral3` and `HeroRogue_ChatPaladin4` have ODS text but no
  primary ExSound registration, so they are not registered as live AI chatter.
- `HeroPaladin_ChatGeneral6Engineer` and
  `HeroPaladin_ChatGeneral7Engineer` were referenced by old chat exports but
  were not found in `ExSound.j`. The migrated runtime skips those two Engineer
  replies until matching ExSound registrations/assets exist.
- `HeroWarlock_ChatGeneral3Warlock` has ODS reply text for a same-profile
  Warlock response but no ExSound registration. Same-profile replies remain
  skipped unless matching sound assets are added.

## Boss Fight And Boss Casting Behavior

`BossGroup`, `BossCasting`, and `BossFight` appear to be backlog concepts rather
than reliable existing globals. `AI.j` should provide the real API and bridge to
future boss triggers.

Rules:

- normal low-health retreat is disabled while boss fight mode is active;
- boss-cast evade is still allowed during boss fights;
- only registered boss abilities trigger boss-cast evade;
- evade should move AI heroes away from the caster or target point by a
  configured distance;
- companion-controlled AI may evade, but should return to companion control
  afterward.

## Travel Behavior

Travel means an AI temporarily leaves the map and returns later.

Implementation default:

- do not remove the unit;
- store state and return position;
- pause and hide the unit;
- suspend normal AI ticks except travel-return checks;
- keep the AI instance active for cap purposes;
- do not auto-travel units currently in `udg_Companion_Group` unless a profile
  explicitly allows it;
- on return, unhide/unpause and restore idle state only if the active random cap
  has room;
- if the active random cap is full, keep the returning random-managed unit hidden
  and paused until the travel timer finds capacity.

## Valeria

Valeria has an `AIValeria` library profile for smarter combat behavior, including
retreat-like movement and defensive logic. This profile must not override active
`qAradion` encounter control.

Implementation rule:

- `AIValeria` periodically registers `udg_Valeria` when the global unit exists;
- the Valeria profile is marked non-autonomous through `AI_SetProfileAutonomous`
  so it can run combat think logic without shared wander/shop/camp/travel;
- `qAradion` or a future `qValeria` can still call `AIValeria_Enable` or
  `AIValeria_Disable` explicitly when a scripted phase needs to refresh control;
- explicit `AIValeria_Disable` suspends the auto-enable timer until
  `AIValeria_Enable` is called again;
- generic AI registration must not put Valeria into the random spawn pool.

## Aradion

Aradion has an `AIAradion` library profile with the same quest-character ownership
model as Valeria. It should keep Aradion registered in `AI.j` for shared state,
defensive reactions, chatter, and future boss-cast evade hooks without taking
movement or ritual orders away from `qAradion`.

Implementation rule:

- `AIAradion` periodically registers `udg_Aradion` when the global unit exists;
- the Aradion profile is marked non-autonomous through `AI_SetProfileAutonomous`
  so shared wander/shop/camp/travel never runs for quest-controlled Aradion;
- low-health defensive movement is allowed, but ordinary attack orders are
  opt-in through `AIAradion_SetCombatOrders`;
- `qAradion` or a future Aradion-specific quest library can call
  `AIAradion_Enable`, `AIAradion_Disable`, and
  `AIAradion_SetCombatOrders` when scripted phases need exact control;
- generic AI registration must not put Aradion into the random spawn pool.

## Sublibrary Plan

First wave:

- file `AI_Warrior.j`, library `AIWarrior`
- file `AI_Rogue.j`, library `AIRogue`
- file `AI_Warlock.j`, library `AIWarlock`
- file `AI_Restoshaman.j`, library `AIRestoshaman`
- file `AI_Paladin.j`, library `AIPaladin`
- file `AI_Engineer.j`, library `AIEngineer`
- file `AI_Valeria.j`, library `AIValeria`
- file `AI_Aradion.j`, library `AIAradion`
- file `AI_Aveline.j`, library `AIAveline`

Reusable generic sublibraries:

- `AI_Generic.j` / `AIGeneric`: light profile factory for units that only need shared `AI.j`
  state and simple attack behavior.
- `AI_Aggressive.j` / `AIAggressive`: hostile profile factory for units that should actively
  attack and use basic combat barks.
- `AI_Passive.j` / `AIPassive`: non-autonomous profile factory for units that avoid combat.
- `AI_Civilian.j` / `AICivilian`: noncombat profile factory for town, quest, and ambient NPCs
  that should flee from nearby hostiles.
- `AI_Guard.j` / `AIGuard`: non-autonomous defender profile factory for guards, sentries,
  and patrol-owned units.
- `AI_Scripted.j` / `AIScripted`: non-autonomous profile factory for quest and cinematic units
  whose movement and orders are owned by external scripts.
- `AI_Vendor.j` / `AIVendor`: noncombat profile factory for shopkeepers and service NPCs that
  should register in the AI system without combat behavior.
- `AI_GenericCaster.j` / `AIGenericCaster`: configurable target-spell caster profile factory.
- `AI_GenericHealer.j` / `AIGenericHealer`: configurable healer/support profile factory.
- `AI_GenericBoss.j` / `AIGenericBoss`: reusable boss profile factory and boss-fight API bridge.

Later profiles/classes:

- `AI_Mage`
- `AI_Knight`
- `AI_Warlord`
- `AI_PrinceZaekolaeer`
- `AI_OgreVendor`
- `AI_DarkApprentice`
- human emissary profile

Each sublibrary should register class/profile configuration and callbacks only.
The master library should own storage, caps, shared targeting helpers, shared
item use, shared retreat, shared death/revival, and shared chatter dispatch.

## Known Old-Trigger Fixes To Apply During Migration

- Ability learning must use real ability-pool sizes per class/profile.
- Rogue Toxic Venom should not be accidentally duplicated unless the profile
  intentionally wants weighted selection.
- Engineer Shredder Charge must order the Engineer/Shredder unit, not the
  Warrior singleton.
- Camp offset point must be calculated from the camp point, not from an
  uninitialized/old temp point.
- Paladin and Engineer must be added to the common main-state engine even though
  the old export does not show complete main-state triggers.
- GUI waits in retreat/camp/sell/buy logic must become timestamped states.
- Warlock imp follow/firebolt should become profile-owned helper logic and not
  depend on a single Warlock unit.

## Implementation Order

1. Create this `AI_MasterPlan.md`.
2. Create `AI.j` with registry, classes, profiles, instance ids, caps, active
   iteration, and basic public API.
3. Add common state machine: idle, wander, combat, buy, sell, camp, retreat,
   death, revive, travel.
4. Add common helper APIs: target search, ally search, closest enemy,
   consumables, temporary abilities, shield use, item pickup, point selection.
5. Add companion-aware gates so autonomous behavior pauses while the unit is in
   `udg_Companion_Group`.
6. Add ExSound/DialogSystem chatter infrastructure and migrate short barks
   before long idle/moving conversation tables.
7. Add first-wave class sublibraries in this order: Warrior, Rogue, Warlock,
   Restoshaman, Paladin, Engineer, Valeria, Aradion.
8. Add `AI_CompanionReplies.j` and `AI_Voicelines.j` after the first-wave
   profiles so ODS text updates existing bark/reply sound-key registrations.
9. Add reusable generic AI sublibraries for generic, aggressive, passive,
   civilian, guard, scripted, vendor, caster, healer, and boss NPC profiles.
10. Add boss fight and boss-cast evade API.
11. Add travel API.
12. Migrate or disable old GUI AI triggers only after parity tests pass.

## Test Plan

Static/build tests:

- run the project's normal JASS compile/JassHelper path;
- confirm no forward-reference failures;
- confirm no missing generated globals;
- confirm no missing ExSound keys;
- run parser/leak diagnostics if available.

Instance/cap tests:

- spawn multiple Warriors and Rogues;
- verify each has independent state, cooldowns, retreat, inventory behavior, and
  chatter cooldowns;
- verify class/profile/unit-type caps block only the intended spawns;
- verify unique-id cap keeps named units unique.
- verify `/debug aispawn` uses the random profile pool and respects both hard
  random cap and active random cap.
- verify traveled or revived random-managed AI stay hidden when the active cap
  is full and return when capacity opens.

Behavior parity tests:

- test wander, buy, sell, camp, retreat-combat, retreat-base, item pickup,
  shield use, ability learning, level-up heal/mana, death, and revival;
- test Warrior, Rogue, Warlock, Restoshaman, Paladin, and Engineer ability
  decisions against the old trigger behavior;
- test Warlock imp follow/firebolt with more than one Warlock;
- test Shaman totem gating;
- test Engineer Shredder behavior;
- test dungeon revival move behavior.

Companion tests:

- invite and kick AI companions;
- test passive, normal, aggressive, hold, focus, information, and drop-items
  command flows through `Companions.j`;
- confirm AI does not autonomous-wander/shop/camp/travel while companioned;
- confirm companion combat abilities and chatter still work;
- confirm old multiboard/cinematic systems still see required shared state until
  they are migrated.

Special tests:

- boss fight suppresses normal low-health retreat;
- boss cast abilities trigger evade;
- travel hides and returns units without losing state;
- Valeria AI can remain registered during patrol without taking over patrol or
  `qAradion` scripted movement;
- old AI stutter from many periodic triggers is not reproduced.

## Open Decisions For Later Implementation

- Decide exact rawcodes for new profiles: Mage, Knight, Warlord,
  Prince Zaekolaeer, Ogre Vendor, Dark Apprentice, and emissary.
- Decide whether old singleton globals should remain assigned as temporary
  compatibility aliases during transition or be removed immediately after each
  dependent trigger is migrated.
- Decide whether traveling AI can be visible in UI/companion lists or should be
  treated as unavailable.
- Decide which boss systems will call `AI_SetBossFightActive` and
  `AI_HandleBossCast`.
