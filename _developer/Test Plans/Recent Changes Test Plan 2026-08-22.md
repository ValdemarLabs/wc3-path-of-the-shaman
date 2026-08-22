# Recent Changes Test Plan - 2026-08-22

## Purpose and scope

Use this plan to validate the large gameplay, UI, quest, travel, vendor, audio, and tooling changes recorded from 2026-08-14 through 2026-08-21. It is a focused release-regression plan, not a replacement for the older backlog in `_developer/Known Issues.md`.

Run P0 tests first. Stop and fix the build if a P0 test fails. Run multiplayer-marked tests with at least two human clients because local-frame and synchronized-state defects may not appear in single player.

## Test run

| Field | Value |
|---|---|
| Map/build | 5007 |
| Git commit | |
| Warcraft III version | 2.0.4.23745|
| Test map or full map | Full map |
| Tester(s) | Valdemar |
| Date started | 22.8.2026 |
| Date completed | |
| Single-player result | Not run |
| Multiplayer result | N/A |
| Overall result | Not run |

Status values: `Not run`, `Pass`, `Fail`, or `Blocked`.

Priority values: `P0` blocks all further testing, `P1` blocks release, and `P2` is important regression or presentation coverage.

## Execution index

Update this table as tests are completed. Put detailed observations in the matching test record below.

| ID | Priority | Test | Associated libraries | Status |
|---|---|---|---|---|
| BUILD-01 | P0 | Import order and full-map compile | `QuestMaster`, `QuestUI`, `MasterUI`, `TravelSystem`, `Drunk`, `qANightToRemember` | Pass |
| BUILD-02 | P0 | Map startup and movement smoke test | `Events`, `VendorFloatingText`, `MasterUI` | Pass |
| QUI-01 | P1 | Open, close, and reopen the custom journal | `QuestUI`, `MasterUI` | Pass |
| QUI-02 | P1 | Type and content filters | `QuestUI`, `QuestMaster` | Not run |
| QUI-03 | P1 | Quest details and empty states | `QuestUI`, `QuestMaster`, `QuestGiver` | Not run |
| QUI-04 | P1 | Reward display | `QuestUI`, `QuestMaster` | Not run |
| QUI-05 | P1 | Live objective and status refresh | `QuestUI`, `QuestMaster`, `QuestsGeneric` | Not run |
| QUI-06 | P1 | Daily, repeatable, and legacy quest compatibility | `QuestUI`, `QuestMaster`, `QuestGiver`, `QuestsGeneric` | Not run |
| QUI-07 | P2 | Quest notification, cinematic, and panel lifecycle | `QuestUI`, `MasterUI`, `QuestMaster` | Not run |
| DRK-01 | P1 | Alcohol raises the Drunk stat | `Drunk`, `ProfessionsCooking`, `DEquipment` | Not run |
| DRK-02 | P1 | Threshold notices and natural sobering | `Drunk` | Not run |
| DRK-03 | P1 | Puke effect and penalties | `Drunk` | Not run |
| DRK-04 | P1 | Pass-out, camera, protection, and wake-up | `Drunk`, `FixedCameraLock`, `CameraControl` | Not run |
| DRK-05 | P1 | Hangover presentation and recovery | `Drunk`, `DEquipment` | Not run |
| DRK-06 | P2 | Drunk debug inspection and boundary values | `Drunk`, `DebugCommands` | Not run |
| DRK-07 | P1 | Multiplayer ownership and local presentation | `Drunk`, `DEquipment` | Not run |
| ANR-01 | P1 | Quest start and witness assignment | `qANightToRemember`, `QuestMaster`, `VendorDialogs` | Not run |
| ANR-02 | P1 | AI witness persistence after leaving the party | `qANightToRemember`, `DialogInteraction` | Not run |
| ANR-03 | P1 | Last Night questions and matched recollections | `qANightToRemember`, `Voicelines_Drunk` | Not run |
| ANR-04 | P1 | Kill make-amends task | `qANightToRemember`, `QuestMaster` | Not run |
| ANR-05 | P1 | Supply replacement task | `qANightToRemember`, `VendorDialogs` | Not run |
| ANR-06 | P1 | Apology task and dialog priority | `qANightToRemember`, `DialogInteraction` | Not run |
| ANR-07 | P1 | Quest completion and repeatability | `qANightToRemember`, `QuestMaster`, `QuestUI` | Not run |
| ANR-08 | P2 | Zone/subzone directions and story variety | `qANightToRemember`, `ZonesCore`, `Voicelines_Drunk` | Not run |
| TRV-01 | P1 | Discovery, destinations, and fare rules | `TravelSystem`, `TravelUI`, `TravelWyvern`, `TravelZeppelin` | Not run |
| TRV-02 | P1 | Player wyvern flight | `TravelSystem`, `TravelWyvern`, `TravelUI` | Not run |
| TRV-03 | P1 | AI flight and arrival | `TravelSystem`, `TravelAI`, `PatrolSystem` | Not run |
| TRV-04 | P1 | Ship A scheduled route and stop prompts | `TravelSystem`, `TravelShipA`, `TravelUI` | Not run |
| TRV-05 | P1 | Ship B boarding and route | `TravelSystem`, `TravelShipB`, `PatrolSystem` | Not run |
| TRV-06 | P1 | Travel camera and passenger presentation | `TravelSystem`, `FixedCameraLock`, `CameraControl` | Not run |
| TRV-07 | P1 | Cancel an ESC prompt | `TravelSystem`, `TravelUI`, `FullscreenUI` | Not run |
| TRV-08 | P1 | Confirm skip or drop-out | `TravelSystem`, `TravelUI` | Not run |
| TRV-09 | P2 | Crafting camera regression | `CraftingUI`, `CameraControl`, `FixedCameraLock` | Not run |
| TRV-10 | P1 | Multiplayer travel isolation | `TravelSystem`, `TravelUI`, `MasterUI` | Not run |
| VND-01 | P1 | Vendor dialogue and shop lifecycle | `VendorDialogs`, `VendorLines`, `ShopUI` | Not run |
| VND-02 | P1 | Combat interruption guard | `DialogInteraction`, `DialogSystem`, `VendorDialogs`, `ShopUI` | Not run |
| VND-03 | P1 | Bound vendor voice profiles | `VendorLines`, `VendorCatalogs`, `Voicelines_VendorLines` | Not run |
| VND-04 | P1 | Generic quest voice/reply matching | `QuestsGeneric`, `QuestsVendor`, `Voicelines_Quests` | Not run |
| VND-05 | P2 | Missing-audio fallback | `ExSound`, `VendorLines`, `VendorDialogs` | Not run |
| VND-06 | P2 | Kribugs and Mogsnort speaker/navigation paths | `qKribugs`, `Voicelines_Kribugs`, `ShopUI` | Not run |
| EVT-01 | P0 | Existing and newly created unit movement | `Events`, `VendorFloatingText` | Not run |
| EVT-02 | P1 | Vendor discovery and floating text | `Events`, `VendorFloatingText` | Not run |
| EVT-03 | P1 | Extended unit-enter and performance regression | `Events`, `VendorFloatingText`, `FrostbiteSystem` | Not run |
| TOOL-01 | P1 | ItemManager build and launch | `WC3ItemManager` | Not run |
| TOOL-02 | P1 | Drunk stat item-data round trip | `ItemEditForm`, `ProfessionItemStatsSeeder`, `DEquipment` | Not run |
| TOOL-03 | P2 | Exact-key voice generation | `generate-drunk-voicelines.ps1`, `voicelines.ps1` | Not run |
| INT-01 | P1 | Master UI panel integration | `MasterUI`, `QuestUI`, `ShopUI`, `CraftingUI`, `TravelUI` | Not run |
| INT-02 | P1 | Full gameplay loop | All libraries in this plan | Not run |
| INT-03 | P2 | Long-session stability | All runtime libraries in this plan | Not run |

## Build and startup

### BUILD-01 - Import order and full-map compile

**Preconditions:** Import the new libraries and required FDF/TOC assets into a current full-map copy. Place dependencies before their consumers; in particular, load `QuestUI` after `QuestMaster`, `MasterUI`, `Interface`, and `Table`.

**Steps:**

1. Disable any explicitly replaced legacy GUI triggers.
2. Run the normal JassHelper full-map compile.
3. Save and launch the compiled map.

**Expected:** The map compiles without errors or missing-library messages. No frame, sound, object-data, or initialization error appears at launch.

**Result:** Pass  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### BUILD-02 - Map startup and movement smoke test

**Preconditions:** BUILD-01 passes.

**Steps:** Start the full map, select both player heroes, order several nearby units to move, open and close the Game menu, and interact with one vendor.

**Expected:** Startup completes normally; all tested units accept and finish movement orders; the UI responds; the vendor interaction opens without a script error.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## Custom quest journal

### QUI-01 - Open, close, and reopen the custom journal

**Preconditions:** At least one active quest exists.

**Steps:** Use the replacement Quests button, close with its close control, reopen it, close with ESC, then reopen it again.

**Expected:** The custom journal replaces the native log, opens once per action, accepts all close methods, and remains usable after repeated open/close cycles. Frame focus does not trap keyboard or camera controls.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### QUI-02 - Type and content filters

**Preconditions:** Have quests covering at least two types and two content categories.

**Steps:** Exercise Normal, Daily, and Repeatable type filters and Story, Dungeon, Class, and Profession category filters. Clear filters and combine one type with one category.

**Expected:** Only matching quests appear, combinations apply together, clearing restores the full list, and no quest is duplicated or left incorrectly hidden.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### QUI-03 - Quest details and empty states

**Preconditions:** Prepare quests with full metadata and quests missing optional objectives, rewards, giver, or turn-in data.

**Steps:** Select each prepared quest and inspect Quest Details, Description, Objectives, Rewards, quest giver, and turn-in contact.

**Expected:** Sections are consistently ordered and readable. Present metadata is correct, and missing objectives or rewards use explicit empty states rather than blank or stale content.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### QUI-04 - Reward display

**Preconditions:** Prepare quests awarding XP, gold, arena marks, faction reputation, one item, multiple items, and no rewards.

**Steps:** Select each quest before completion and compare the Rewards section with its configured reward flags and item data.

**Expected:** Every configured reward appears once with correct text and values. Item lines are consistently formatted. Unconfigured rewards do not appear, and the no-reward state is explicit.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### QUI-05 - Live objective and status refresh

**Preconditions:** Track one kill, one fetch, and one talk quest while the journal is open.

**Steps:** Advance each objective without closing the journal, complete an objective, then complete or fail a test quest where supported.

**Expected:** Counts, completion markers, detail text, list state, and selection refresh immediately without reopening the panel. No stale details from another quest remain.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### QUI-06 - Daily, repeatable, and legacy quest compatibility

**Preconditions:** Have one daily quest, one repeatable quest, and one quest still using a native/GUI compatibility path.

**Steps:** Accept and complete all three. Run the normal daily reset, reacquire eligible quests, and inspect any legacy script that reads its native quest handle.

**Expected:** Daily reset and repeatable reacquisition work; custom journal state remains correct; hidden native mirrors continue to satisfy legacy code without exposing the native log.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### QUI-07 - Quest notification, cinematic, and panel lifecycle

**Preconditions:** The journal is closed and a test quest can be discovered or updated.

**Steps:** Trigger a new-quest notification, observe the replacement quest button, open another major UI panel, start a cinematic, end it, and reopen the journal.

**Expected:** Quest-button notification/flash appears correctly; major panels do not overlap; the journal hides during cinematics and returns to a valid closed/open state afterward.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## Drunk and Hangover system

### DRK-01 - Alcohol raises the Drunk stat

**Preconditions:** Use a clean hero with zero Drunk and several alcoholic cooking drinks.

**Steps:** Consume drinks with different configured strengths and inspect the displayed dummy stat after each drink.

**Expected:** `udg_Stats_Drunk[]` increases by the configured amounts, remains within 0-100, and the equipment/stat presentation matches the runtime value.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### DRK-02 - Threshold notices and natural sobering

**Preconditions:** Place the hero just below each configured intoxication threshold.

**Steps:** Cross each threshold with a drink, wait through multiple sobering ticks, and observe party messages and stat changes.

**Expected:** Each intended threshold notice appears only for the owning party at the correct crossing. Drunk decreases at the configured pace without going below zero or repeatedly replaying a crossing notice.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### DRK-03 - Puke effect and penalties

**Preconditions:** Raise Drunk enough to make puke likely; note baseline hit and armor stats.

**Steps:** Trigger puke, observe the effect attachment and duration, inspect temporary penalties, and wait for recovery.

**Expected:** The corrosive stream attaches to the hero's head, does not persist indefinitely, uses valid visuals, applies intended hit/armor penalties once, and restores the exact baseline afterward.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### DRK-04 - Pass-out, camera, protection, and wake-up

**Preconditions:** Configure valid wake rects and raise Drunk enough to force or reliably trigger a pass-out.

**Steps:** Trigger pass-out in a safe area and again while enemies are nearby. Observe the staged fullscreen camera, sleep animation, invulnerability, wake relocation/fade, and restored controls.

**Expected:** Camera stages run once; the hero cannot be harmed while asleep; supported models present sleep correctly or use the configured fallback; wake-up relocates only when intended and restores selection, camera, vulnerability, and control.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### DRK-05 - Hangover presentation and recovery

**Preconditions:** Complete a pass-out/wake cycle.

**Steps:** Inspect the Hangover effect and stats immediately after waking, listen for the vendor/hero presentation, then wait for or force the five-minute expiry.

**Expected:** Hangover begins once, lasts the configured duration, uses the correct presentation/audio, and removes every temporary effect and penalty when it expires.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### DRK-06 - Drunk debug inspection and boundary values

**Preconditions:** Have a controllable hero and drinks capable of reaching the maximum Drunk value.

**Steps:** Run `/debug drunk` with no unit selected, then select the hero and run it at zero, a middle value, and after consuming enough drinks to exceed 100 before clamping.

**Expected:** The command gives a clear no-selection message or reports the selected unit's current value as `0-100`. Drinking clamps the runtime value at 100 and the command does not alter state.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### DRK-07 - Multiplayer ownership and local presentation

**Preconditions:** At least two human clients with heroes in different locations.

**Steps:** Raise Drunk, trigger threshold messages, puke, pass-out, and wake-up for one client's hero while the other client moves and uses UI/camera controls.

**Expected:** Gameplay state remains synchronized. Only intended players receive local messages/camera/fullscreen effects. The uninvolved client retains unit and camera control, and no desync occurs.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## A Night To Remember

### ANR-01 - Quest start and witness assignment

**Preconditions:** A hero completes the Hangover trigger conditions; eligible Horde vendors and AI companions exist.

**Steps:** Start the quest repeatedly from clean test states and record the other hero plus three assigned witnesses.

**Expected:** The quest starts once per eligible cycle, assigns valid distinct witnesses, allows one or two AI witnesses when available, and exposes correct objectives in QuestUI.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-02 - AI witness persistence after leaving the party

**Preconditions:** An active quest has an AI company hero assigned as a witness.

**Steps:** Remove that AI from the party, find/select the stored witness, and finish its required conversation or task.

**Expected:** The stored unit reference remains valid after party removal, its quest interaction still takes priority, and the witness requirement can complete.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-03 - Last Night questions and matched recollections

**Preconditions:** Start conversations with the other player hero and several witness types.

**Steps:** Record the randomized Nazgrek/Zul'kis question, witness recollection, hero reply, text, speaker name, audio key, and playback order over multiple runs.

**Expected:** The question is voiced; each of the five recollection categories uses a matching hero reply; text and audio agree; no unrelated or duplicate response interrupts the sequence.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-04 - Kill make-amends task

**Preconditions:** Generate a witness requirement with the kill task.

**Steps:** Kill targets with the hungover hero, the other owned hero, a party companion, and an unrelated unit; leave and rejoin the area during progress.

**Expected:** Only intended party kills grant credit, progress survives normal movement/interaction changes, completion is reported once, and returning to the witness advances forgiveness.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-05 - Supply replacement task

**Preconditions:** Generate a witness requirement with the supply task; test with insufficient and sufficient supplies.

**Steps:** Select the witness, inspect its dynamic vendor/action button, attempt the handoff without enough supplies, acquire supplies, and retry.

**Expected:** The action appears only in the correct state, insufficient supply gives clear feedback without consuming items, valid handoff consumes the exact cost once, and forgiveness progress updates.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-06 - Apology task and dialog priority

**Preconditions:** Generate a witness requirement with an apology task on an NPC/AI that also has ordinary selection dialogue.

**Steps:** Select the witness before, during, and after the apology requirement and complete the paired dialogue.

**Expected:** Quest-specific dialogue consumes the selection before ordinary dialogue while active, the requirement completes only after the paired exchange finishes, and normal dialogue returns afterward.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-07 - Quest completion and repeatability

**Preconditions:** Complete the other-hero requirement and all three witness/forgiveness requirements.

**Steps:** Watch the last requirement complete, inspect QuestUI and rewards/state, then satisfy the conditions for another run.

**Expected:** The quest self-completes exactly once only after all requirements finish, cleans temporary buttons/state, records the completed state correctly, and can repeat only according to its configured rules.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### ANR-08 - Zone/subzone directions and story variety

**Preconditions:** Run the quest with witnesses distributed across several supported zones.

**Steps:** Compare objective hints with actual witness locations and sample recollections across Stormhaven, Twilight Grove, Ashfang Falls, Bonecrush Stronghold, Havenwoods, Riverbane, Maw of Cinders, Morgrim's Claim, Ruins of Zul'Garok, Serpentshore, Redwind Pass, Ironspine Post, and Circle of Blood where available.

**Expected:** Directions name the correct zone/subzone, story text matches the selected location and speaker, and Paladin/Aveline retain their distinct Stormhaven incidents.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## Travel and camera systems

### TRV-01 - Discovery, destinations, and fare rules

**Preconditions:** Use one undiscovered and one discovered endpoint for each travel method.

**Steps:** Discover stations, inspect the discovery presentation, open destination lists before/after discovery, and attempt routes with insufficient/exact/excess party gold.

**Expected:** Discovery text and color are correct; route visibility follows each method's endpoint policy; fares are charged once from the intended party pool; failed purchase changes no travel state.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-02 - Player wyvern flight

**Preconditions:** Discover two connected wyvern stations, including a newly added destination where possible.

**Steps:** Buy travel in both directions, observe boarding, takeoff, route, descent, arrival, and cleanup.

**Expected:** The correct carrier/path is used, height changes are gradual, the hero arrives at the correct endpoint, control returns, and no carrier/passenger effect or travel state remains stuck.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-03 - AI flight and arrival

**Preconditions:** Have an eligible AI hero travel by wyvern and zeppelin.

**Steps:** Start AI travel, observe approach/boarding, route completion, low-height landing fallback, and post-arrival behavior.

**Expected:** AI treats configured points as discovered, uses the physical carrier, completes arrival even if fly height stalls, resumes normal behavior, and does not rebuild patrol paths continuously.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-04 - Ship A scheduled route and stop prompts

**Preconditions:** Board Ship A and test both route directions through Sirensong, Dawnhold, and Stormhaven.

**Steps:** Observe boarding, scheduled movement, deck passengers, Dawnhold drop-out prompt, continue option, drop-out option, and final arrival.

**Expected:** Route order and prompt choices match travel direction, passengers remain positioned on deck, each choice is clickable, and both intermediate and final exits restore units and control correctly.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-05 - Ship B boarding and route

**Preconditions:** Use Mok'natha, Frontbase, and Ironspine boarding points.

**Steps:** Board at each supported point, complete both route directions, and observe configured Nazgrek/Zul'kis deck models.

**Expected:** Each master binds to the correct active Ship B route, old camera triggers do not conflict, deck models use configured offsets/standing animation, and arrival cleanup is complete.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-06 - Travel camera and passenger presentation

**Preconditions:** Test a wyvern/zeppelin and both ship types.

**Steps:** Rotate and adjust the camera with arrow keys throughout travel, inspect ship framing and passenger positions, then complete travel.

**Expected:** Camera remains locked to the active vehicle while accepting allowed user rotation/angle input; ships frame the deck rather than hull/water; passenger effects/models do not drift; normal camera is restored on arrival.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-07 - Cancel an ESC prompt

**Preconditions:** Begin travel and open a skip or intermediate-stop confirmation prompt.

**Steps:** Press ESC to cancel, then immediately use camera rotation/angle keys and click the prompt controls on a second attempt.

**Expected:** Cancel closes only the prompt, keeps travel/fullscreen state valid, releases hidden button focus, and preserves responsive camera rotation and angle controls.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-08 - Confirm skip or drop-out

**Preconditions:** Have enough gold for any configured skip charge and open each supported confirmation prompt.

**Steps:** Confirm a paid skip, confirm an intermediate ship drop-out, and rapidly click/press ESC around confirmation once.

**Expected:** The selected action occurs once, charges at most once, uses a fade-safe transition, places all intended units correctly, closes the prompt, and restores camera/control without duplicate arrival logic.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-09 - Crafting camera regression

**Preconditions:** Open crafting with a valid profession unit and a repeatable recipe.

**Steps:** Rotate/adjust the camera, craft once, use repeat/query crafting, switch recipes, and close the panel with its controls and ESC.

**Expected:** Camera stays locked to the active crafting unit throughout normal and repeated crafting, input remains responsive, and closing restores the correct normal camera and frame focus.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TRV-10 - Multiplayer travel isolation

**Preconditions:** At least two human clients; only one begins travel.

**Steps:** Client A travels, opens/cancels/confirms prompts, and arrives while Client B moves units, changes camera, and uses another major UI panel.

**Expected:** Only Client A receives travel camera/UI effects; shared fare/state stays synchronized; Client B remains fully interactive; both clients finish without desync.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## Vendors, dialogue, and audio

### VND-01 - Vendor dialogue and shop lifecycle

**Preconditions:** Use ordinary, quest-giving, and composite vendors from multiple factions.

**Steps:** Enter, greet, open the shop, buy, sell, return to dialogue, and exit repeatedly.

**Expected:** The correct vendor and hero remain bound throughout; each UI transition works once; trade responses match the action; camera/audio/UI clean up on exit.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### VND-02 - Combat interruption guard

**Preconditions:** Prepare dialogue, ShopUI, quest dialogue, and an explicit test interaction configured with `endOnCombat = false`.

**Steps:** During each guarded interaction, make the hero attack, be attacked, enter combat, and die; repeat for the vendor. Then enter combat during the opt-out interaction.

**Expected:** Guarded sequences, transmissions, fields, audio, camera, and UI end immediately and cleanly for every combat/death path. The opt-out interaction remains open as configured.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### VND-03 - Bound vendor voice profiles

**Preconditions:** Sample Human, Orc, Troll, Goblin, Tauren, Satyr, Morgrim dwarf, Elarindor, and Bonecrusher vendors.

**Steps:** Trigger greeting, shop-open, catalog, transaction, and farewell lines for male/female and multiple numbered profiles.

**Expected:** Each unit retains its bound reusable race/gender profile across roles and interactions; text, speaker, key, folder, and sound match; one NPC is not mistaken for another sharing the unit type.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### VND-04 - Generic quest voice/reply matching

**Preconditions:** Use vendor quests with Nazgrek, Zul'kis, and several generic voice families.

**Steps:** Trigger acceptance, kill completion, talk completion, fetch completion, progress, supply handoff, purchase, and daily follow-up paths.

**Expected:** The selected hero and vendor play the matching category variant; randomized text and sound use the same variant; quest-giving vendors keep the same profile used for trading.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### VND-05 - Missing-audio fallback

**Preconditions:** In a disposable test build, reference one intentionally unavailable ExSound key.

**Steps:** Trigger the line and continue through the interaction.

**Expected:** A useful missing-key warning is reported, displayed text remains long enough to read using estimated duration, and the surrounding dialogue does not stall or skip required actions.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### VND-06 - Kribugs and Mogsnort speaker/navigation paths

**Preconditions:** Interact with the Kribugs/Mogsnort composite unit.

**Steps:** Trigger normal greetings, Mogsnort interjections, shop Back, buy/sell reactions, Special Deal success, insufficient gold, inventory full, close, and reopen.

**Expected:** Text/audio/camera identify the correct speaker; Back returns to dialogue choices; errors remain visible in the panel; Special Deal state is clear; no path becomes stuck.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## Events, movement, and performance

### EVT-01 - Existing and newly created unit movement

**Preconditions:** BUILD-01 passes with `VendorFloatingText` registered through the centralized `Events` dispatcher.

**Steps:** At startup, move player, neutral, hostile, summoned, revived, and AI units in several zones. Create or spawn new units after initialization and order them to move.

**Expected:** Every unit accepts movement orders normally. No map-wide freeze occurs at startup or after a new unit enters the playable map.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### EVT-02 - Vendor discovery and floating text

**Preconditions:** Include preplaced vendors and create/register a vendor after map initialization.

**Steps:** Approach both vendor types, observe floating text/availability, remove one, and create several ordinary non-vendor units.

**Expected:** Preplaced and new vendors are discovered once through centralized unit-enter handling; their floating text behaves normally; non-vendors get no vendor text; removed units leave no stale text.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### EVT-03 - Extended unit-enter and performance regression

**Preconditions:** Use a full map with normal AI, vendors, Frostbite zones, summons, and respawns active.

**Steps:** Play for at least 30 minutes while changing zones, spawning/killing units, opening UI, travelling, and visiting vendor clusters. Record FPS at start, 15 minutes, and 30 minutes.

**Expected:** No progressive movement failure, duplicate enter handling, runaway floating text, major periodic spike, or material sustained FPS decline attributable to the changed systems.

**Result:** Not run  
**Tester / date / build:**  
**Actual result and FPS samples:**  
**Evidence or issue link:**

## Tools and generated data

### TOOL-01 - ItemManager build and launch

**Preconditions:** Use the current development environment and a non-production database.

**Steps:** Run `dotnet build .\WC3_Database\WC3ItemManager\WC3ItemManager.csproj`, launch the application, open an existing profession item, and close normally.

**Expected:** Build succeeds without errors, the application launches, and existing item data loads without a schema or control-binding failure.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TOOL-02 - Drunk stat item-data round trip

**Preconditions:** Use a backup/non-production database and a test alcoholic cooking item.

**Steps:** Edit the Drunk value, save, reopen, export item data/definitions, inspect the generated value, import into a disposable map build, and consume the item.

**Expected:** The editor preserves the value; seeding does not overwrite intentional data; export emits the correct stat; `DEquipment`/cooking runtime applies the same amount in-game.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### TOOL-03 - Exact-key voice generation

**Preconditions:** Select one safe review key and preserve any existing output for comparison.

**Steps:** Run the exact-key generator/filter for that key, inspect generated/review output, and confirm unrelated keys and official files are untouched.

**Expected:** Only the requested exact key is selected, its speaker/folder/text mapping is correct, and no unrelated review or official audio is regenerated or replaced.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

## Integration and release pass

### INT-01 - Master UI panel integration

**Preconditions:** Quest, shop, crafting, travel, and Game panels are available.

**Steps:** Open each panel from normal play, switch directly where supported, use ESC, start/end a cinematic, and repeat after travel and crafting.

**Expected:** Only compatible panels are visible, centralized hiding works, ESC affects the top/current context once, the Game button follows configuration, and frame focus never blocks later keyboard/camera input.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### INT-02 - Full gameplay loop

**Preconditions:** All P0 tests and the relevant focused P1 tests pass.

**Steps:** In one uninterrupted full-map session, accept a quest, trade, craft/drink alcohol, pass out, start and finish `A Night To Remember`, travel by air and ship, complete another quest, and inspect the journal throughout.

**Expected:** Systems hand control/state to one another cleanly; objectives/rewards stay correct; audio/cameras/UI clean up; units keep moving; no script error, soft lock, or corrupted state occurs.

**Result:** Not run  
**Tester / date / build:**  
**Actual result:**  
**Evidence or issue link:**

### INT-03 - Long-session stability

**Preconditions:** Use a release-candidate full-map build with normal AI and periodic systems enabled.

**Steps:** Play for at least 60 minutes and repeat journal filtering, vendor entry, crafting, drinking, quest dialogue, travel, combat, death/revive, and zone transitions. Record FPS and handle-visible symptoms every 15 minutes.

**Expected:** No accumulating lag, repeated callback, stale UI/audio/effect, lost control, movement freeze, desync, or material sustained FPS decline appears.

**Result:** Not run  
**Tester / date / build:**  
**Actual result and FPS samples:**  
**Evidence or issue link:**

## Completion summary

| Result | Count |
|---|---|
| Pass | |
| Fail | |
| Blocked | |
| Not run | |

### Release decision

- Decision: Not evaluated
- Blocking test IDs:
- Accepted known issues:
- Retest build/commit:
- Notes:

Release recommendation: all P0 and P1 tests should pass. Any accepted P1 failure should have an issue link, owner, workaround, and explicit release decision recorded above.
