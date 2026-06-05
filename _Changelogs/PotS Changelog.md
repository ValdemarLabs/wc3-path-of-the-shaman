# WC3 - Path of the Shaman
## CHANGELOG

> Changelog template / usage notes
>
> Use ###`Player-Facing Updates` for clear gameplay changes, player experience changes, UI changes players directly notice, balance/content changes, or anything that directly affects normal play.
>
> Use ###`Technical Updates` for map-development work such as JASS libraries, trigger refactors, performance/stability work, frame/UI implementation details, data structure changes, and other general mapping-related technical work.
>
> Use ###`Tool Updates` for `WC3ItemManager`, PotS SQL Server related work, and other similar internal development tools. These are usually not player-facing by themselves, even if they may later affect gameplay data.
>
> Use ###`Known Issues` for current confirmed problems, validation gaps, or incomplete/problematic behavior that still needs checking.
>
> Use ###`Actions Remaining` for follow-up work, cleanup, validation, polish, or tasks intentionally left for later.

## [6.6.2026]

### Technical Updates
- `ProfessionsUI.j`
  Investigated the slowly worsening UI-side FPS drop path against the earlier scrollbar and refresh hardening already applied in `AbilitiesLiteUI.j` and `ReputationUI.j`.
  Reworked the professions refresh path so periodic updates stop blindly reapplying unchanged row text, row icons, row highlight state, detail icon/title, progress-bar values, and detail-body text every refresh tick.
  Added cached list-scroll and detail-scroll synchronization, guarded slider callback state, and clamped wheel movement so programmatic frame refreshes no longer churn extra slider updates while the panel is open.
  Added detail-body cache invalidation tied to selected profession, current skill, and milestone rebuild state so the right-side unlock text only rebuilds when the actual profession data changed.
  Synced the open-button toggle path with the visibility-based refresh timer so the professions panel resumes refreshing when opened and reliably pauses again when closed through the same button.

### Player-Facing Updates
- `ProfessionsUI`
  Leaving the professions panel open, switching tracked gatherers, and scrolling both panes should now produce much less long-session UI-side FPS decay than before.

### Actions Remaining
- `ProfessionsUI.j`
  Re-test the panel in-game under longer open-idle, repeated list/detail scrolling, and tracked-gatherer switching so the slow FPS-drop path can be confirmed gone after the latest cache/sync cleanup.

## [5.6.2026]

### Technical Updates
- `ReputationUI.j`, `ProfessionsUI.j`
  Continued rebuilding the right-side detail presentation after the earlier hidden `TasQuestBox` reuse kept leaking imported frame ornament art into the panel and produced black-backdrop spill outside the intended area.
  Removed the hidden `TasQuestBox` text-area host approach from both UIs and replaced it with native right-pane detail backdrops, native body backdrops, and native text-frame content areas.
  Kept the standalone list scrollbars for the left-side lists while restructuring the right-side detail stack closer to the safer native-frame pattern already used by `AbilitiesLiteUI` and `StatsUI`.

### Player-Facing Updates
- `Sirensong`
  Continued terraining work in the `Sirensong` zone, focused mostly on the river route and the troll-side areas.

### Actions Remaining
- `ReputationUI.j`, `ProfessionsUI.j`
  Re-test the rebuilt native right-side detail panes in-game and confirm the earlier lower-center ornament leak and black-background overflow are actually gone.
  Continue polishing the right-side description-card presentation until it fully matches the intended final look.

## [4.6.2026]

### Technical Updates
- `ReputationUI.j`, `ProfessionsUI.j`
  Reworked the right-side description panel approach again after the stretched tooltip-texture backdrop experiment produced broken vertical gold-strip artifacts instead of the intended `TasQuestBox` panel look.
  Embedded a hidden helper `TasQuestBox` instance inside each custom right pane and started reusing the imported `TasQuestBoxTextArea1` child for the description area so these panels can move closer to the same framed detail presentation used by `HintsUI` and the other `TasQuestBox`-based UIs.
  Added separate frame contexts and local imported-frame lookups so the custom profession / reputation panels can reuse the shared imported text-area frame without colliding with the existing `TasQuestBox` users elsewhere in the map.

### Actions Remaining
- `ReputationUI.j`, `ProfessionsUI.j`
  The right-side description area and its surrounding outer frame/panel layout still need more adjustment work before the final look fully matches the intended `TasQuestBox` presentation.
  Validate the imported text-area alignment, sizing, spacing, and any remaining overlap / anchoring issues in-game, then finish polishing the outside frame treatment around the reused description panel.

## [3.6.2026]

### Technical Updates
- `AbilitiesLiteUI.j`, `ReputationUI.j`
  Finished fixing the custom left-list scrollbar system so the slider track uses explicit sizing instead of stretched bottom anchoring.
  Corrected the slider value mapping so opening the list at the top also places the thumb at the top of the visible rail.
  Stabilized the click / drag / wheel path and initial hide-state so the thumb stays inside the intended scrollbar frame and only appears when scrolling is actually needed.
- `ProfessionsUI.j`
  Updated both the left profession list and the right detail-text scrollbar to use the same corrected top-resting slider mapping.
  Replaced the old stretched left-list scrollbar setup with explicit sizing based on the visible-row region, matching the working list-scroll system used in the repaired UIs.
  Added the same initial hide-state behavior used by the repaired list UIs so stale slider thumbs do not appear before refresh.
- `HintsUI.j`, `CommandsUI.j`, `AchievementsUI.j`, `SecretsUI.j`, `CheatsUI.j`, `TasQuestBoxLight_PotS.j`
  Standardized the page-slider logic so these `TasQuestBox`-style UIs now use the same top-resting scrollbar behavior as the fixed abilities / reputation lists.
  Added cached slider sync, integer step sizing, clamped wheel movement, conditional slider visibility, and guarded slider callback handling so programmatic refreshes no longer feed back into slider events or cause the earlier slider-related crashes.
- `MasterUI.j`
  Added configurable per-button icon constants for the `Game` menu so each submenu entry can be given its own small left-side icon or left text-only by setting the path to `""`.
  Rebuilt the menu buttons as composite button/icon/text frames and widened the panel/button layout slightly so the grouped menu can fit icons without crowding the labels.
- `TerrainDamage.j`
  Adjusted `LAVA_EFFECT_SCALE_START`, `LAVA_EFFECT_SCALE_END`, `FEL_EFFECT_SCALE_START`, and `FEL_EFFECT_SCALE_END` closer to `1.00`.
  This tones down the ramped terrain-damage special-effect growth so the end-state visuals no longer become too large.

### Player-Facing Updates
- `AbilitiesLiteUI`, `ReputationUI`, `ProfessionsUI`, `Hints`, `Commands`, `Achievements`, `Secrets`, `Cheats`, `Zones`
  The affected scrollbars now start visually from the top when the list itself is at the top, move in the expected direction, and hide themselves when no scrolling is needed.
  The latest slider pass also resolved the known slider drag / click instability, and no slider crashes are currently known after these fixes.
- `Game` menu
  The `Game` menu buttons can now show matching submenu icons while keeping the existing grouped multi-column layout.
  The menu frame and button widths were adjusted slightly so the new icons fit cleanly beside the labels.
- `Terrain damage visuals`
  Lava / fel damage effects now stay closer to normal unit scale during the ramp instead of growing overly large near the end.

## [2.6.2026]

### Technical Updates
- `AbilitiesLiteUI.j`, `ReputationUI.j`
  Continued fixing the left-side list sliders after drag/click problems and incorrect thumb placement.
  Re-anchored the slider track to the visible row area instead of letting the thumb drift outside the intended frame region.
  Corrected the vertical slider value mapping so the list starts at the top while the thumb also begins at the top of the visible gold track.
  Added stricter wheel/drag clamping so slider movement stays within the intended min/max range of the drawn scrollbar.
  Despite these changes, the latest slider iteration did not actually improve the broken behavior yet and still needs more work.

### Player-Facing Updates
- `Terraining`
  Continued terraining work in the `Sirensong` area, focused mostly on the `Panthera` miniboss entrance area.
- `AbilitiesLiteUI`, `ReputationUI`
  The left-side scrollbars were adjusted so their thumb position should now better match the visible scrollbar art and start from the top instead of the bottom.
  In practice, this slider pass did not yet produce a real improvement and the UI scrollbars still behave incorrectly.

## [1.6.2026]

### Technical Updates
- `AbilitiesLiteUI.j`
  Continued rebuilding the abilities browser around real player-shaman ability data instead of placeholder sample entries.
  Added the larger rawcode-backed `Player Shaman` ability pool for `Elemental`, `Enhancement`, `Restoration`, and `Totemic` abilities so names, icons, and tooltip text can come from Warcraft object data.
  Refined ability presentation so the visible classification line uses shared style such as `Shaman - Elemental` instead of separate `Player Shaman` / `NPC Shaman` display text.
  Changed visible ability-title lookup to prefer the normal tooltip text and strip trailing level-style suffixes such as ` - [Level X]` before display.
  Continued iterating on left-side slider/list behavior, wheel handling, and row-click interaction after repeated crash and drag issues.
  Refined the ability list/detail presentation so single-rank abilities no longer show unnecessary level text.
  Added mana-cost display to rawcode-driven ability details.
  Repositioned and enlarged the detail-text area to better fit the intended right-side description region.
  Reduced the `Not learned` row-text scale slightly and added a subtle dark overlay on unlearned ability icons so unavailable abilities read more clearly.
- `ReputationUI.j`
  Continued reworking the left-side faction-list slider and click/scroll behavior to move it closer to the proven `TasQuestBoxLight_PotS` pattern.
  Adjusted row visibility handling, slider interaction, and left-list click behavior after drag/click regressions during the reputation-panel refactor.
- `MasterUI.j`, `AbilitiesLiteUI.j`
  Added the `Abilities` entry into the `Game` menu layout and updated the open flow so `MasterUI` uses the same `ExecuteFunc(...)` pattern as the other sub-UIs.
  Moved the selected-hero resolution into `AbilitiesLiteUI`, where the panel now determines whether to open for `Nazgrek` or `Zul'kis`, defaulting to `Nazgrek` when neither is selected.
- `MasterUI.j`
  Added public `ShowGameButton` / `HideGameButton` API support for the `Game` menu button itself.
  Wired cinematic trigger usage so `Cinematic ON` / `Cinematic OFF` can now hide/show the `Game` button cleanly through the new API.
- `CameraControl.j`
  Fixed advanced camera mode so switching into `Advanced` now also binds arrow-key movement through `SetMovementUnit(...)`.
  This makes the advanced movement helper apply consistently on mode switch, target refresh/reselection, and resume because those already flow through the shared advanced bind path.
- `CameraUI.j`
  Reworked camera UI initialization so TOC loading and frame creation happen through a delayed init instead of immediate `AutoInit`.
  This was done because the missing-slider issue appears to be tied to custom slider-template frame creation happening too early in the main map, not to `Nazgrek` / `Zul'kis` initialization timing.
  Added slider-value resync on `Show()` so the visible controls refresh to current camera values when the panel is opened.
- `Camera` / cinematic cleanup
  `Intro Orc Cleanup` still contained obsolete GUI-side camera-control calls that were interfering with the newer JASS camera-control flow in the main map.
  Those old GUI camera-control function calls were disabled for now and should later be removed entirely as obsolete.
  This also highlighted that other older triggers may still be calling first-person / GUI camera controls unnecessarily and need further cleanup.

### Player-Facing Updates
- `AbilitiesLiteUI`
  Player shamans now expose a broader real ability list with names/icons/tooltips pulled from actual object data instead of only a few placeholder definitions.
  Ability names and specialization labels are being presented in a cleaner format that better matches the intended class/spec display.
  Ability details now show mana cost where available, use a better-sized description area, and make unlearned abilities easier to distinguish visually.
- `Game` menu
  The `Game` menu now includes direct access to `Abilities`, with the panel opening for the currently selected main shaman hero when possible.
  The `Game` button can now be hidden during cinematics and restored afterward through the newer cinematic trigger flow.
- `Camera`
  Advanced camera mode now restores working arrow-key movement instead of only changing the camera view.
- Sirensong small terraining
- Dragonpeak Mountain high mountain terraining

### Known Issues
- `AbilitiesLiteUI`
  The left-side abilities list still has unresolved slider/drag stability problems and has remained one of the main crash-prone UI areas during this session.
  Row selection and scroll behavior still need in-map validation after the latest slider parenting and click-interaction changes.
- `ReputationUI`
  The left-side faction list still needs more validation; drag/click/scroll behavior has been unstable while trying to match the quest-box pattern.
- `Camera`
  There may still be other old GUI-trigger paths that call outdated first-person / camera GUI functions and can conflict with the newer camera-control system.
  `CameraUI` slider controls are not appearing correctly in the main map even though they work in the test map.
  Current suspicion is that custom slider-template frames from `templates.toc` are being created too early in the main map load flow rather than the issue being caused by `Nazgrek` / `Zul'kis` variable initialization.

### Actions Remaining
- `AbilitiesLiteUI`
  Finish stabilizing the left-side ability-list slider and drag behavior until it safely matches `TasQuestBoxLight_PotS`.
  Continue filling and validating class ability definitions, especially for NPC-only classes that still only have template sections.
- `ReputationUI`
  Finish stabilizing the left-side faction list slider and drag behavior and continue aligning it with the quest-box style interaction model.
- `Camera` cleanup
  Continue searching for other old GUI-trigger references to first-person / GUI camera controls and remove or disable them so only the newer JASS camera-control flow remains active.
  Re-test whether delayed `CameraUI` frame creation resolves the main-map-only slider issue; if not, inspect the built-map slider template import state rather than unit-variable timing.
- `MasterUI` / cinematics
  Re-test the new `Game` button hide/show flow during `Cinematic ON` / `Cinematic OFF` and any other trigger paths that should suppress menu access temporarily.

## [31.5.2026]

### Technical Updates
- `MasterUI.j`, `AbilitiesLiteUI.j`
  Added an `Abilities` button to the `Game` menu and updated the grouped menu layout/order to fit the new entry.
  Switched the menu-side open flow back to the same `ExecuteFunc(...)` style used by the other sub-UIs.
  Moved hero resolution into `AbilitiesLiteUI`, so opening the abilities panel now checks the current selected hero between `Zul'kis` and `Nazgrek`, with `Nazgrek` as the default fallback when neither is selected.
- `AbilitiesLiteUI.j`
  Reworked the class-pool configuration so only `Player Shaman` exists as a player pool, while the other class sections remain NPC-only templates for future filling.
  Added clearer `// ====== CONFIGURE` guidance and class-template notes for future ability authoring.
  Replaced the earlier 4-entry placeholder player-shaman setup with a much larger real rawcode-backed player-shaman registration list covering `Elemental`, `Enhancement`, `Restoration`, and `Totemic` abilities.
  Added duplicate-safe auto-registration helpers so reopening the panel does not keep stacking ability definitions.
  Continued reducing the earlier heavy/detail-refresh approach and adjusted the left-side scroll handling to move closer to the `TasQuestBox` slider style.
- `ReputationUI.j`
  Continued iterating on the left-side factions list and slider behavior so the panel can move away from the earlier unstable scroll handling.
  Refined row visibility/highlight handling and continued trying to align the list/slider interaction more closely with `TasQuestBoxLight_PotS`.

### Player-Facing Updates
- `Game` menu
  The main `Game` menu now includes `Abilities` as a direct submenu entry.
- `AbilitiesLiteUI`
  Player shamans now expose a much larger real ability list based on actual ability rawcodes instead of only a few placeholder sample abilities.
  Opening the panel from the main menu now targets the currently selected main hero, or defaults to `Nazgrek` if neither player hero is selected.

### Known Issues
- `AbilitiesLiteUI`
  The left-side ability list scroll/slider path is still unstable and has been causing lag or crashes during drag/scroll interaction.
  Left-side row interaction and scroll behavior still need full validation after the latest slider changes.
- `ReputationUI`
  The left-side faction slider/list interaction is still not fully stable and needs more work to properly match the intended `TasQuestBox`-style behavior.
  Layout/interaction validation is still needed for the left-side list after the latest scroll fixes.

### Actions Remaining
- `AbilitiesLiteUI`
  Continue correcting the left-side slider/list interaction until it behaves safely and consistently like `TasQuestBoxLight_PotS`.
  Finish authoring/validating the player-shaman rawcode list and continue filling NPC class ability definitions.
- `ReputationUI`
  Finish stabilizing the left-side faction scrolling and dragging behavior and fully mirror the proven `TasQuestBox` left-list interaction pattern.

## [30.5.2026]

### Technical Updates
- `CameraControl.j`, `CameraUI.j`, `MasterUI.j`, `ProfessionsUI.j`, `ReputationUI.j`, `StatsUI.j`
  Added short purpose-focused header descriptions to the newer JASS UI libraries so their main intent is easier to identify at a glance.
- `Reputation.j`, `ReputationUI.j`
  Retired the old reputation multiboard from active use while keeping the code in place as legacy fallback.
  `ReputationUI` no longer commands the old multiboard, and `ReputationBoard` init/show flow was disabled so the frame UI is the active visual path.
- `StatsUI.j`
  Reworked the stats panel around UI-side unit selection instead of Warcraft's current map selection.
  Added broader stat coverage based on `DEqStatNames`, split the view into summary stats plus a denser lower-right stat grid, and removed the old detail scrollbar path.
  Added class/type placeholders and later hardcoded fallback metadata for player-shaman examples such as Nazgrek.
  Added a black detail backdrop for clearer reading and wired an `Abilities` button into the unit detail view.
  Removed direct multiboard hiding from `StatsUI` to avoid conflicts with external multiboard triggers.
- `AbilitiesLiteUI.j`
  Added a new lightweight ability browser opened from `StatsUI`, with separate player-shaman vs companion-shaman definition routing so their ability pools do not mix.
  Added hardcoded starter shaman templates for `Lightning Bolt`, `Stormstrike`, `Healing Wave`, and `Stoneskin Totem`.
  Added support for player-hero learn-state display so unlearned Nazgrek / Zulkis abilities can show greyed `Not learned` state based on real ability level checks.
  Simplified the detail panel away from the earlier heavy scroll/body-refresh path, restored lightweight body wrapping, and began adding full black backdrop treatment similar to `StatsUI`.
- `ReputationUI.j`
  Kept live timed refresh, but narrowed it to cached visible-row/detail updates instead of full panel rewrites each refresh tick.
  Added more caching around row visibility, row status text, slider sync, and detail text updates to reduce repeated frame churn while the panel is open.
- `CheatsUI.j`
  Replaced placeholder cheat examples with the real current cheat list and removed redundant category text duplication by making the UI render the category once from stored data.
  Continued hardening scroll/slider behavior after crash investigation by removing brittle event coupling and reducing unsafe slider-sync paths.

### Player-Facing Updates
- `StatsUI`
  The stats panel now shows fuller unit information through the new frame layout, including expanded summary fields and broader derived stats.
  Unit details are now meant to follow the row selected inside the stats UI itself rather than depending on the current world selection.
- `AbilitiesLiteUI`
  Units opened through `StatsUI` now have a separate ability list and description view, with player shamans showing richer specialization-style text.
- `Reputations`
  Reputation display is now intended to use the frame UI instead of the old multiboard presentation.

### Tool Updates
- `WC3_Database/WC3ItemManager`
  Modernized `WC3ItemManager` from the old `.NET 5` setup to a supported desktop stack using `.NET 10 SDK` with the app targeting `net8.0-windows`.
  Updated package/runtime configuration for the newer build chain and verified successful Debug build plus self-contained Release publish.
  Replaced the brittle old WinForms/WPF assembly-reference setup with explicit desktop project configuration.
- `WC3_Database/WC3ItemManager/Assets`
  Moved the integral icon texture libraries out of the old `bin\Debug\net5.0-windows` output tree into a proper source location under `Assets\blizzard` and `Assets\custom`.
  Updated the project so both Debug and published outputs now copy the full icon libraries from `Assets` automatically.
- `WC3_Database/WC3ItemManager/IconPathConfig.cs`
  Changed default icon lookup paths to prefer app-local `blizzard` and `custom` folders so the newer build outputs remain self-contained even without a hand-written config file.

### Known Issues
- `AbilitiesLiteUI`
  Ability definitions are still only partially populated, and the frame still needs more visual tuning around layout, text balance, and overall readability.
- `ReputationUI`
  The factions list is still not fully aligned inside the main frame and needs more follow-up layout work.
- `StatsUI`, `AbilitiesLiteUI`, `ReputationUI`
  These newer frame UIs have had several performance/stability corrections, but they still need full in-map validation after the latest refresh/scroll/backdrop changes.

### Actions Remaining
- `AbilitiesLiteUI`
  Add many more manually configured ability rawcodes for player and companion unit types, plus the needed configuration/text authoring work for each ability definition.
  Continue visual adjusting so the panel layout, text blocks, icon presentation, and detail area feel finalized.
- `Companions` / `Tamed`
  Create a proper `Companions.j` JASS library and merge logic from the current GUI versions.
  This is a heavy change because many systems still depend on the GUI companion / tamed trigger flow and shared `udg_` globals.
- `ReputationUI`
  Continue fixing the left-side faction list layout so entries stay fully inside the main reputations frame.
- UI backdrop idea
  Consider using the same style of black backdrop frame more broadly across newer UIs, as it makes text much easier to read during gameplay.
- `WC3ItemManager`
  Re-test normal item editing, icon browsing, imports, and exports in the upgraded app during regular use to confirm there are no behavior regressions beyond successful build/startup verification.


## [26.5.2026]

### Technical Updates
- `MasterUI.j`
  Refined the central `Game` menu toward a cleaner grouped multi-column layout.
  Continued tuning frame width/height, button width, spacing, and title presentation.
  Added and refined the `Path of the Shaman` heading styling in the main menu frame.
- `HintsUI.j`
  Simplified hints to one shared text body used by both popup/chat output and the hints panel.
  Repeated `SetHintText(...)` calls now append paragraphs automatically, so multi-paragraph hints are easier to author and edit.
  Removed the remaining one-off hardcoded hint formatting path so hint display stays data-driven.
  Popup hint formatting was aligned to `Hint - <title>` followed by the hint text on the next line.
  Added conversion from frame-style `|n` paragraph breaks to real chat newlines for popup display.
  Added hint popup sound support using `Sound\\Interface\\Hint.wav`.
- `SecretsUI.j`, `AchievementsUI.j`, `ReputationUI.j`
  `SecretsUI.j` now hides the icon and real title for unfound secrets, showing greyed-out `Undiscovered` entries instead.
  `SecretsUI.j` now displays `Secrets - Undiscovered` for locked entries in the detail view.
  Removed `Owner player` text from `ReputationUI.j` so the reputation detail pane stays focused on faction-facing information only.
  Added unlock sound support to `AchievementsUI.j` using `Sound\\Inferface\\AchievementEarned.wav`.
  Added unlock sound support to `SecretsUI.j` using `Sound\\Interface\\SecretFound.wav`.

### Player-Facing Updates
- `Game` menu
  The `Game` menu continues to become a cleaner hub for newer systems.
  Menu presentation is now tighter and more readable as the grouped multi-column layout is refined.
  The main menu title and button presentation are being tuned toward a more polished in-game menu feel.
- Discovery / collection feedback
  Hints now pop with a matching hint sound and cleaner popup formatting.
  Unfound secrets no longer spoil their title or icon in the secrets list.
  Achievements and secrets now give their own unlock sounds when earned/found.

### Known Issues
- `MasterUI.j`
  The grouped `Game` menu still needs visual tuning; frame width, heading scale, and button spacing are not finalized yet.
- `HintsUI.j`, `AchievementsUI.j`, `SecretsUI.j`
  The new popup/unlock sound paths still need full in-map validation to confirm they resolve correctly in the target build.

### Actions Remaining
- `MasterUI.j`
  Continue refining sizing, spacing, and title presentation until the grouped menu feels finalized.
  Re-test the grouped `Game` menu against all currently wired sub-UIs after more layout changes.
- UI feedback / audio
  Re-check hint popup line breaks and sound playback in normal gameplay flow.
  Re-check achievement and secret unlock sounds to make sure the chosen paths are valid in the target map build.
  Continue refining hidden/locked presentation for collection-style UIs where needed.



============================================================================
25.5.2026 - List of Actions:

======================== Technical Updates: 

UI / Camera / Master Menu
- Continued the new frame-based UI migration with more systems moved under the `Game` menu flow
>> Added and iterated on `CameraUI.j` and `CameraControl.j` as the new JASS-side camera split for camera controls and camera settings
>> Imported `templates.toc` from `PotS_JASS\\_tocs` for `CameraUI` so the newer slider templates can be used by the camera frame UI
>> Continued refining `MasterUI.j` button grouping, order, spacing, return flow, and visual styling while keeping the old systems in place underneath
>> Reworked `MasterUI` toward a multi-column `Game` menu layout instead of a single long vertical list
>> Added a centered `Path of the Shaman` heading to the `Game` menu and continued tuning frame width / height and button sizing to better fit the grouped menu layout
>> Added newer collection / utility frame UIs such as `HintsUI`, `AchievementsUI`, `SecretsUI`, `CommandsUI`, and `CheatsUI` as part of the broader `Game` menu expansion

UI / Camera / Legacy Trigger Retirement
- Began properly retiring the older GUI-driven camera control layer
>> Disabled the old camera-control triggers in the folders `Camera commands testing`, `Camera Keyboard Actions`, `Camera Settings`, and `Camera Commands`
>> These older GUI trigger folders are intended to be removed later entirely once the new JASS-side camera flow is fully validated
>> Moved `FixedCameraLock` and `AdvancedCameraSystem` into the upper-level `Camera` folder structure for cleaner organization around the newer camera libraries

Camera / Controls / Cinematics
- Updated cinematic camera transition handling to use the new camera-control API instead of the older mixed GUI/JASS references
>> `Cinematic ON` now calls `CameraControl_Suspend(Player(0))`
>> Removed the old camera GUI / JASS references from `Cinematic ON`
>> `Cinematic OFF` now calls `CameraControl_Resume(Player(0))`
>> Removed the old camera GUI / JASS references from `Cinematic OFF`
>> Added a `ResumeQuick` variant so the camera library now supports both instant and smooth resume behavior when restoring a suspended camera mode

UI / Stability / Performance
- Continued correcting the newer frame UIs now that the main catastrophic startup FPS issue had already been isolated
>> Follow-up testing continued to confirm that the severe startup FPS drop / fast crash was caused by `ProfessionsUI.j`, not by the gather-node runtime itself
>> Continued hardening scroll handling, refresh timing, and open/close behavior across the newer frame UIs
>> `ProfessionsUI`, `ReputationUI`, and `StatsUI` were refined further so they only refresh while actually open, with additional guarding against update/scroll recursion

UI / Hints
- Simplified `HintsUI.j` so hint authoring and display are more data-driven and easier to maintain
>> Removed the older split between separate primary / secondary popup messages and moved hints to one shared text body per hint
>> Simplified hint definitions so multi-paragraph hints can now be built with repeated `SetHintText(...)` calls instead of embedding all formatting into one long registration line
>> Removed the hardcoded special-case formatting path for individual hints so the popup/panel flow is now driven by hint data rather than one-off logic
>> Aligned the popup text format with the hint panel format as `Hint - <title>` followed by the hint text on the next line
>> Added conversion so frame-style `|n` paragraph breaks still display correctly when the same hint text is shown through chat-style popup output

======================== Player-Facing Updates:

Game UI / Navigation
- The in-game `Game` menu is expanding toward being the central access point for newer systems
>> Camera, Hints, Achievements, Secrets, Commands, and Cheats are now part of the broader frame-UI migration path
>> More of the old top-bar / GUI-trigger based access points are being retired in favor of the new centralized menu flow
>> The `Game` menu itself is being reshaped toward a more compact grouped multi-column layout instead of a single tall stack of buttons

Camera / Cinematics
- Camera handling is moving toward one cleaner JASS-side control model
>> Cinematics can now suspend and resume the currently used camera mode through `CameraControl`
>> This reduces reliance on the older mixed GUI/JASS camera setup and prepares the map for later cleanup of redundant camera triggers

======================== Actions Remaining:

UI / Camera
- The new camera UI and camera-control split still need more in-map validation before the older systems can be removed
>> Continue validating `CameraUI` frame stability, slider placement, and open/close behavior
>> Re-check that smooth `CameraControl_Resume` behavior feels distinct from `ResumeQuick`
>> Continue testing arrow-key behavior so only `Normal` mode uses keyboard rotation controls
>> Remove the older disabled GUI camera trigger folders entirely later once the new system is confirmed stable

UI / General
- The newer frame-UI layer remains WIP and still needs more polish
>> Continue refining `MasterUI` layout and submenu presentation
>> Continue polishing the new `Game` menu width, heading scale, and grouped button spacing now that the layout has shifted to multiple columns
>> Continue stress-testing `ProfessionsUI` rapid switching / scrolling to confirm the remaining crash paths are gone
>> Continue validating `HintsUI` popup formatting and panel text presentation now that hints use one shared text body for both outputs
>> Keep older redundant systems (such as multiboards and older trigger-based flows) in place only until the new replacements are proven stable

============================================================================

============================================================================
24.5.2026 - List of Actions:

======================== Technical Updates: 

UI / Master Menu / Frame UIs
- Began a broader UI consolidation pass under a new master menu flow
>> Added a new `MasterUI.j` library that places a `Game` button in the old top-bar `Zones` slot
>> `Game` now opens a central master menu with entries such as `Zones`, `Professions`, `Reputations`, `Stats`, `Camera`, and `Hints`
>> Added close handling and sub-UI return flow so child frame UIs can return back to the master menu
>> Broke a compile-order / requirement-cycle issue by letting sub-UIs require `MasterUI` while `MasterUI` avoids direct compile-time dependency on them

UI / Zones / Professions / Reputations / Stats
- Continued moving UI access into frame-based menus, though the whole pass is still very much work-in-progress
>> `TasQuestBoxLight_PotS.j` (`Zones`) no longer needs its own permanent top-bar open button when used through `MasterUI`
>> `ProfessionsUI.j` no longer needs its own permanent top-bar open button when used through `MasterUI`
>> Added `Return` buttons in the newer frame UIs so they can return to `MasterUI`
>> Reputations and Stats received new frame-based UI work using the same broad visual language as `ProfessionsUI`
>> Continued refining positions, panel layout, row highlight sprite style, and detail-pane behavior across the newer UIs

UI / Professions / Performance
- Corrected the root cause of the severe startup FPS drop / rapid crash investigated during this session
>> The major FPS collapse after game start was caused by `ProfessionsUI.j`, not by `GatherNodes` runtime changes
>> The professions UI refresh / update behavior was reworked to reduce unnecessary continuous UI churn
>> Follow-up profiling/validation is still needed while the professions panel is open, but the main startup regression was traced away from gather-node spawning logic

UI / Legacy Systems
- Kept older systems in place as redundant backends while newer frame UIs are being layered on top
>> Old multiboard-based systems such as Reputations and Stats still remain in the map for now
>> The new frame UIs are currently additive / replacement-facing, but not yet the only remaining implementations

Zones / Events
- Updated `ZoneEvent.j`
>> Added the needed library requirement to `TasQuestBox`

World / Time / Test Map Sync
- Updated `DNC.j`
>> Brought it up to date where the test map had been behind the latest script state

======================== Player-Facing Updates:

Game UI / Navigation
- The UI is moving toward one central in-game menu instead of many separate top-bar entry buttons
>> `Game` now acts as the main access point for newer frame-based interfaces
>> Zones, Professions, Reputations, and Stats are being reorganized around this master-menu flow

Stability / Performance
- The earlier fast FPS collapse after game start was not caused by gather-node spawning itself
>> Current investigation indicates the main offender was `ProfessionsUI`
>> This means gather-node runtime work should be re-validated separately from the UI performance regression

======================== Actions Remaining:

UI / Validation
- The new UI layer is still in active WIP state and needs more in-map verification
>> Continue testing `MasterUI` open/close/return flow across all sub-UIs
>> Continue aligning `ReputationUI` and `StatsUI` detail views and data presentation
>> Re-check `ProfessionsUI` while the panel stays open to ensure the main lag path is fully resolved
>> Decide later when the old redundant multiboard-based UIs can actually be retired instead of just hidden / left in place

Gather Nodes / Separation of Concerns
- Now that the worst startup FPS issue was traced to `ProfessionsUI`, gather-node runtime stability should be validated again on its own merits
>> Re-test natural despawn / respawn timing, glow cleanup, and harvest flow without conflating them with UI-side performance issues

============================================================================
23.5.2026 - List of Actions:

======================== Technical Updates: 

Gather Nodes / Skills / ItemManager
- Continued refinement of gather-skill gating, harvest rewards, and ItemManager clarity
>> `/skills` now shows only the currently selected tracked gatherer (Nazgrek or Zulkis), and falls back to Nazgrek if no tracked unit is selected
>> `/skills` now prints the hero proper name instead of the raw unit type name
>> Successful gathering now displays a blue skill-up message showing the unit name, profession, and new skill value
>> Skill-up text was cleaned so the new value no longer prints with quotation marks
>> Gather failure bark / text now uses a longer timeout between repeated messages to reduce spam
>> Gather failure handling was improved so missing node names now fall back safely instead of showing blank text
>> Blocked low-skill item pickup was tightened so gather items should no longer remain stored in PoTs DInventory when the gatherer lacks the required skill
>> Low-skill gather attempts now abort more aggressively so units stop instead of continuing to move toward item nodes or attack unit nodes
>> Skill gain from lower-tier nodes now tapers off and can eventually stop once the gatherer's profession skill significantly exceeds the node's required skill

Gather Nodes / Unit Harvest Rewards
- Corrected and clarified the unit-node reward model to better match the old GUI mining ideology
>> Clarified the difference between the node's main reward pool and per-hit reward quantities
>> Main / Secondary groups continue to pick one weighted reward from their own group when the group roll succeeds
>> Secondary rewards still roll only after a successful main reward
>> Hardened group reward selection so `Main` / `Secondary` use an explicit candidate list and weighted pick per group
>> Fixed JASS issues found during cleanup, including source-order problems in `GatherNodeSkills`, uninitialized locals in unit reward rolling, and later-declared respawn calls in timed-despawn handlers

ItemManager / Harvest Reward UI
- Improved unit-node harvest editor wording so reward behavior is easier to understand
>> Renamed labels such as `Harvest Yield` to `Main Reward Pool`, and clarified that reward rows define per-hit quantities
>> Added inline help text to explain successful-hit chance, main / secondary group chance, and the difference between pool size and reward amount
>> Updated reward-grid and reward-dialog labels to clearer terms like `Drop Group`, `Pick Weight`, `Reward %`, and `Per-Hit Qty`

Gather Nodes / Lifecycle / Cleanup
- Aligned node cleanup, glow tracking, and respawn timing more consistently
>> Timed despawn now follows the same lifecycle model as gather / kill: remove node, wait its respawn delay, then roll a fresh spawn attempt
>> Added watchdog cleanup for item nodes so if an external system removes a tracked gather item, the gather system unregisters it and schedules the next spawn attempt correctly
>> Added watchdog cleanup for unit nodes so externally removed gather units also clear glow/tracking and re-enter the respawn cycle correctly
>> Simplified unit-node glow tracking so unit glow is now managed only by the shared gather master system instead of dual local/shared tables
>> This was aimed at fixing cases where old vein glow remained in place or appeared to belong to the wrong newly spawned node
>> Reworked timed-despawn dispatchers in both item and unit systems to use trigger actions / `TriggerExecute` instead of condition-style evaluation, to make lifetime expiry handling more reliable
>> Follow-up source-order cleanup was also done so the newer item/unit gather helpers no longer depend on later-declared functions in the library file

UI / Professions
- Added the first dedicated professions UI runtime under `UI/Professions`
>> Added a new standalone `ProfessionsUI` library with a `Professions` open button near the upper-left quest/zones button area
>> The panel uses a two-column list/detail layout: all 9 professions on the left, selected profession details on the right
>> Each profession row now shows its icon, name, and current skill as `x/100`
>> The detail pane now shows profession icon, colored title, current skill, progress bar, short description, and next milestone / unlock text
>> The UI follows the currently tracked gatherer selection and falls back safely to Nazgrek or Zulkis if no tracked gatherer is selected
>> Added lightweight profession presentation metadata such as icon, accent color, and description text inside the UI library
>> Added milestone scanning so the UI can derive `Next unlock` hints from exported gather item/unit definition skill requirements
>> Added a public `GNS_GetUITargetUnit()` helper and gather-definition query helpers so the professions UI can read current tracked hero skill data cleanly
>> Follow-up UI pass moved the `Professions` open button to the left side of the vanilla `Quests` button instead of below the upper-left stack
>> Reworked the detail pane to use a proper scrollable text body so longer descriptions and milestone text stay inside the panel border
>> Removed redundant `x/100` text from the detail pane so the progress presentation is less noisy while keeping profession row values visible in the left list
>> Promoted key UI strings and textures such as button text, close text, fallback icon, panel texture, progress bar texture, and profession icon/description/accent data into configurable globals instead of burying them in frame creation logic

Gather Nodes / Glow Tracking
- Fixed a tracking bug found through `/gathernodes glowtest` and `/gathernodes glowclear`
>> Shared gather glow effects were being created into the typed `effect` child table but checked/removed through the parent glow table, which made debug glow logs report `tracked=false` even while the effect still existed visually
>> Corrected glow tracking/removal to use the same typed glow-effect table consistently, so new debug test glows and gather-node point glows can now be found and destroyed correctly

Item Systems / Cleanup
- Added a new `ItemCleanup.j` library in `ItemSystems`
>> Combines the old GUI map-clutter cleanup and dead-item/tome cleanup into one JASS runtime library
>> Protects gather node items, campaign / quest items, DInventory-managed items, and manually protected item instances / item types
>> Supports two intended cleanup purposes: long-lived ground clutter cleanup and used-tome / zero-life leftover cleanup
>> Added source credits in the library header for Bribe, Tirlititi, and Vexorian

Item Systems / Legacy GUI Cleanup
- Disabled the old GUI cleanup triggers now replaced by `ItemCleanup.j`
>> `Item Remove`
>> `Item Picked`
>> `Item Cleanup`

======================== Player-Facing Updates:

Gathering / Feedback
- Gather-node profession feedback should now read more clearly in-game
>> Skill increases now announce visibly when a successful gather improves Mining / Herbalism / other professions
>> Skill checks now identify the required node more clearly when a gather attempt fails
>> Profession progression from low-tier nodes should now slow down naturally as the character outlevels that node's required skill

ItemManager / Reward Authoring
- Harvest reward setup for unit nodes is now easier to read
>> The editor now makes it clearer that the node defines the total main reward pool, while each reward row defines what one successful harvest can actually give

======================== Actions Remaining:

Gather Nodes / Validation
- More in-map verification is still needed around the newest gather gating and reward changes
>> Confirm that low-skill gatherers cannot continue into pickup / attack / harvest through edge cases
>> Confirm that DInventory never retains a blocked gather item
>> Re-verify unit-node reward behavior against the intended old GUI-style pool logic, especially weighted selection inside `Main` / `Secondary`
>> Re-test node lifetime despawn timing to confirm nodes now wait through respawn delay before the next spawn roll
>> Re-test external item cleanup interaction so removed gather items properly re-enter the spawn cycle
>> Re-test unit and item glow cleanup on kill, gather, timed despawn, and refresh

UI / Professions
- The new professions UI still needs live in-map validation
>> Confirm the `Professions` button appears consistently both with and without the zones `MapInfoButton` active
>> Verify the panel updates correctly when switching between Nazgrek and Zulkis
>> Re-check that milestone text matches current gather-node definition data after fresh exports/imports
>> Verify the new left-of-`Quests` button anchor does not overlap any other custom top-bar button in the current UI stack
>> Verify scrollbar behavior and long-text wrapping in the detail pane with both short and long profession descriptions
>> Continue compile-order cleanup if any remaining gather helper source-order problems are reported by the map compiler

Combat / Daze
- Testing note: `Daze NonMount` is now being exercised again even though daze had previously only been used for mounts, which have been inactive for a long time
>> For a proper long-term implementation, this should become a shared JASS `Daze` library that can handle both mounts and normal units cleanly

============================================================================
22.5.2026 - List of Actions:

======================== Technical Updates: 

Gather Nodes / Skills / Harvest Rewards
- Added a new `GatherNodeSkills` sublibrary for gather profession tracking and enforcement
>> Tracks profession skill values per unit handle instead of assuming `Player(0)`, fixing the earlier behavior where only player 1 skill logic worked reliably
>> Added profession support for gather nodes through ItemManager, exporter, and runtime so both item nodes and unit nodes now author an explicit profession type
>> Added `/skills` chat output for player 1 to print current tracked gather skill values
>> Added gather failure gating and feedback for Nazgrek / Zulkis, including the requested general-error ExSounds and the displayed requirement text for nodes that need higher skill

Gather Nodes / Unit Harvesting
- Reworked unit-node harvesting toward a generic ItemManager-driven reward system
>> Added node-level harvest settings for unit nodes in ItemManager, including yield range, gather success chance, and special behavior support
>> Added ItemManager-authored reward rows for unit nodes and exported them into the gather runtime
>> Added generic runtime reward rolling for ore veins / crystals / similar unit gather nodes while keeping Mana Crystal special behavior handled separately
>> Simplified grouped harvest rewards to two fixed lanes only: `Main` and `Secondary`
>> Unit nodes now define `Main Group %` and `Secondary %`, while each reward row only chooses whether it belongs to `Main` or `Secondary`
>> On each successful gather hit, the system rolls the node's group chances, then picks weighted reward rows inside each passed group

ItemManager / Gather Node Management
- Expanded and cleaned the Gather Node Management tooling for the new harvest flow
>> Added `Profession` authoring for item nodes and unit nodes
>> Added harvest reward editing for unit nodes
>> Adjusted the harvest reward grid/dialog so the grouped reward fields are visible and no longer rely on per-row group-chance input
>> Added `Main Group %` and `Secondary %` fields to unit nodes so the fixed two-group reward model is controlled at the node level

======================== Player-Facing Updates:

Gathering / Professions
- Gather professions are now being prepared as a real per-character progression system
>> Nazgrek and Zulkis can now have separate gather skill values instead of sharing player-based logic
>> Gather nodes can now require a specific profession and skill threshold before they can be harvested correctly

Mining / Reward Behavior
- Unit-based gather nodes now support more structured reward behavior
>> Mining hits can now roll a primary reward lane and an optional secondary bonus lane instead of relying on one flat reward pool
>> This makes ore / crystal node rewards easier to tune in ItemManager while keeping special Mana Crystal behavior separate

======================== Actions Remaining:

Gather Nodes / Validation
- Live Warcraft/JASS validation is still needed for the newest gather-skill and harvest-reward changes
>> Export a fresh `GatherNodeDefinitions` after the latest ItemManager changes
>> Re-import the updated gather JASS files and verify:
>>> item-node skill gating
>>> unit-node mining skill gating
>>> `/skills` output
>>> `Main / Secondary` harvest reward behavior in-map

============================================================================
21.5.2026 - List of Actions:

======================== Technical Updates: 

ItemManager / Spawn Points
- Improved Spawn Points UI support for zone-less setup
>> Added `Any / Not configured` to the Add/Edit Spawn Point dialog zone dropdown, so spawn points can now be created without attaching them to a real zone
>> Added the same `Any / Not configured` option to the Spawn Point Autofill dialog zone dropdown for consistent bulk-creation behavior
>> This aligns spawn point editing with the earlier spawn-group support for unconfigured / global zone usage

======================== Player-Facing Updates:

Spawn Points / Workflow
- Spawn point authoring is now more flexible
>> You can create individual spawn points or autofilled spawn-point batches without forcing them into a specific zone first
>> This makes it easier to prepare global / shared spawn groups and finish zone setup later if needed

======================== Actions Remaining:

ItemManager / Spawn Points
- Continue checking for any other spawn-point related dialogs or filters that should also expose `Any / Not configured` for consistency

============================================================================
20.5.2026 - List of Actions:

======================== Technical Updates: 

Gather Nodes / Glow / Spawn Filters
- Continued gather-node runtime fixes and tooling
>> Reworked gather unit-node glow to use a point-based effect instead of attaching the imported glow effect directly to the unit
>> Added safer glow cleanup handling and debug glow test commands for player 1: `/gathernodes glowtest` and `/gathernodes glowclear`
>> Finished runtime glow support for item nodes as well, so ItemManager item glow settings now actually create and remove glow effects in-game
>> Fixed missing item pickup trigger wiring, so gathered item nodes now properly run cleanup logic instead of leaving stale glow/effects behind
>> Fixed gather-node glow cleanup so both item nodes and unit nodes now remove their point-glow effect correctly on gather, death, timed despawn, and debug refresh
>> Added `ZonesCore` support for gather-node random-spawn restriction rects for both item nodes and unit nodes
>> Added a new node-level spawn filter in ItemManager for both item and unit nodes: prevent spawning in water / amphibious terrain
>> Refined the runtime water filter so it uses floatability only, instead of the earlier broader amphibious-pathing check
>> Added `ZonesCore` support for `addNodeWaterIgnoreRect(...)` so selected shallow-water areas can still allow random node spawning
>> Changed fixed unit spawn points so they ignore only the water check, while still respecting the rest of spawn validation
>> Wired the new water-terrain setting through ItemManager database, export, and gather runtime checks
>> Tightened unit fixed spawn-point selection so nearby living units also block node spawning at that spawn point
>> Tightened random point-in-zone spacing heavily so item and unit nodes no longer spawn too close together

Gather Nodes / Stability
- Resolved two important runtime regressions found during today's testing
>> Fixed shared-pool spawn loops so failed spawn attempts no longer risk looping forever during initial spawn or debug refresh
>> Corrected the earlier terrain-filter regression that could block normal land spawns too aggressively
>> Reworked node lifecycle timing so `respawn min/max` now acts as node lifetime before timed despawn, after which the system immediately rolls a fresh spawn using normal weights / limits / random point logic
>> Gathered or killed nodes now also schedule a fresh delayed spawn event instead of recreating the same node at the same location
>> Cleaned up new gather lifetime / fresh-spawn helper ordering so the JASS runtime no longer depends on lower-declared functions in the latest item/unit node changes
>> Current result: gather nodes are spawning again and the previous gather glow crash path is now working with the new point-based implementation

Bridges / BridgeSystem
- Added a new bridge variant for simple top-lane-only crossing behavior
>> Added `HBridge004.j` for bridges that only need `C/D` movement handling
>> This variant does not use bridge activation/deactivation switching, `A/B` underlane handling, entry blocker points, or under-approach setup
>> Added a persistent-open top-lane option in `BridgeSystem` so selected bridges can keep the bridge top active at all times while still forcing `C/D` units cleanly across

======================== Player-Facing Updates:

Gather Nodes / Stability
- Gather nodes should behave more reliably again after the latest runtime fixes
>> Nodes should no longer fail because of the earlier overly aggressive land/water filtering regression
>> Item and unit node spawning should also avoid some earlier bad spawn clustering, so spawns should look more natural and less stacked together
>> Gather nodes should now cycle more naturally over time, because nodes can despawn after their configured lifetime and the next spawn is rolled fresh instead of simply returning to the same spot

Bridges / Top-Lane-Only Crossing
- Added support for bridges that are always open on top and only use `C/D` crossing flow
>> On these bridges, units approaching from the top-lane bridge sides should now cross directly without the bridge visually toggling open/closed
>> There is no `A/B` under-bridge traffic handoff on this bridge type, so the bridge behaves more like a dedicated always-active top crossing

======================== Actions Remaining:

Gather Nodes / Validation
- Live Warcraft/JASS testing is still needed after the latest runtime changes
>> Re-export and re-import fresh `GatherNodeDefinitions` so the new node-definition signature and water-spawn flag are in sync with runtime
>> Continue content-side `ZonesCore` authoring for any zone-specific node restriction rects and shallow-water water-ignore rects that are still needed

============================================================================
19.5.2026 - List of Actions:

======================== Technical Updates: 

GatherNodes / GatherNodeDefinitions / GatherNodeDebug
- Continued investigation and isolation work for the current post-loadscreen gather-node crash
>> Confirmed an important isolation result: when `GatherNodeDefinitions` is disabled, the game no longer crashes after the loadscreen
>> This means the active crash investigation is currently focused on the exported `GatherNodeDefinitions` library and its delayed initialization / initial spawn flow
>> Split `GatherNodeDebug` out of `GatherNodes.j` into its own file so the master gather library no longer contains two libraries in one script file during crash investigation
>> Reworked `GatherNodeDefinitions` delayed init to use the same trigger-based style as older known-working systems such as `DEquipmentItemDefinitions.j`
>> Removed timer-destruction style from current Gather Node Definitions generation during delayed init cleanup
>> Cleaned Gather Node Definitions generation so duplicate later `globals ... endglobals` blocks are no longer emitted just for delayed-init trigger variables
>> Separated Gather Node Definitions initialization into two stages:
>>> first delayed stage registers all node definitions and spawn-group data
>>> second delayed stage performs the actual initial node spawning later
>> This was done because the strongest suspect inside `GatherNodeDefinitions` was no longer plain registration, but the immediate initial spawn calls:
>>> `GNI_SpawnInitialAll()`
>>> `GNU_SpawnInitialAll()`
>> Further in-map isolation later confirmed:
>>> disabling only `DelayedSpawn` prevents the crash
>>> item-only refresh and item-only initial spawning do not crash
>>> unit refresh (`/gathernodes refresh units`) does crash
>> This narrows the live crash scope away from item nodes and onto the unit-node initial spawn / refresh path

GatherNodeUnits / Glow Effect Crash Isolation
- Narrowed the unit-node crash cause much further during live testing
>> Temporarily disabling both unit-side glow application and per-unit death-event registration made `/gathernodes refresh units` work
>> Further testing then confirmed that commenting out `ApplyGlowEffect(u, defId)` alone is enough to stop the unit refresh crash
>> At this point the strongest confirmed crash path is:
>>> `GNU_SpawnUnitAt(...)`
>>> `ApplyGlowEffect(u, defId)`
>>> `GN_ApplyGlowEffect(...)`
>>> `AddSpecialEffectTarget("war3campImported\\Glow.mdl", u, "origin")`
>>> followed by `BlzSetSpecialEffect*` setup such as scale/color/alpha/height
>> Ongoing next-step isolation is now focused on determining whether the problem is:
>>> the imported `Glow.mdl` effect itself
>>> `BlzSetSpecialEffectHeight(...)`
>>> or heavy glow-effect manipulation during mass unit spawn

GatherNodes / ZonesCore Spawn Rect Usage
- Adjusted random zone spawn rect preference again during investigation
>> Direct `ZoneData` usage was confirmed to be valid by comparing against systems such as `WeatherSystemV4` and `ZoneEvent`
>> However, using the first zone enter rect as the default gather spawn area was found to be risky because some zones use smaller entry rects instead of full-zone coverage
>> Gather random spawning was therefore moved back to prefer the zone's main weather/full rect first, with enter-rect fallback only if needed

GatherNodes / Debug Spawn Visibility
- Improved debug spawn visibility during heavy spawn bursts
>> Item and unit spawn pings were found to be unreliable to observe when many nodes spawned in the same tick
>> Reworked debug minimap spawn pings into a staggered queue so each successful spawn gets a visible ping instead of multiple pings being visually swallowed at once
>> This helps verify real spawning in zones such as Twilight Grove and Sereneglade without confusing lack of visible ping for lack of actual spawn

GatherNodeItems / ZonesCore Validation
- Investigated confusing herb/item random-zone spawn behavior
>> Current exported herb assignments were verified to exist for Twilight Grove and Sereneglade in the latest `GatherNodeDefinitions`
>> Current `ZonesCore` data was also verified to provide valid main weather/full rects for those zones
>> This means the earlier apparent missing spawns in those zones were not explained by missing zone rect data
>> Current understanding is that item spawning itself does work there, and the bigger confusion during testing came from debug visibility / timing rather than the `ZonesCore` zone-rect source

ItemManager / Gather Node Export
- Continued Gather Node export cleanup while isolating the crash source
>> Exported Gather Node Definitions now more closely match the intended delayed-init pattern and current runtime ownership of random zone spawning
>> Current generated files in `GatherSystems/ItemManagerExports` were also patched in-repo so testing can use cleaner exported definitions immediately

======================== Player-Facing Updates:

Gather Nodes / Stability Investigation
- Loadscreen crash investigation is still ongoing
>> The gather system is narrowed down much better than before, but the exact root cause is still not fully proven down to one exact native call
>> Current strongest confirmed scope is no longer general `GatherNodeDefinitions` registration, but the unit-node spawn glow path reached through initial spawn / debug refresh
>> Item-node spawning is currently much less suspicious than unit-node spawning

======================== Actions Remaining:

Gather Nodes / Loadscreen Crash Investigation
- In-map testing is still required to finish proving the exact unit glow crash cause and final safe fix
>> Current most likely remaining causes:
>>> `war3campImported\\Glow.mdl` itself is unsafe in this gather-unit spawn context
>>> `BlzSetSpecialEffectHeight(...)` is unsafe on this attached glow effect during mass node spawn
>>> another `BlzSetSpecialEffect*` manipulation on the created glow effect is the actual bad call
>> Recommended next isolation steps:
>>> keep `ApplyGlowEffect(...)` enabled but temporarily disable `BlzSetSpecialEffectHeight(...)`
>>> if crash still happens, temporarily replace `Glow.mdl` with a safe Blizzard stock effect
>>> if needed, test scale/color/alpha setup individually to isolate the exact bad effect manipulation
>>> once proven, re-enable only the safe subset of glow visuals for gather unit nodes

============================================================================
18.5.2026 - List of Actions:

======================== Technical Updates: 

GatherNodes / GatherNodeItems / GatherNodeUnits
- Refined gather-node debug tooling and spawn visibility
>> Removed the earlier gather-node refresh chat-command queue / timer workaround from the master library path
>> Removed the `ExecuteFunc`-based sublibrary refresh calls from `GatherNodes` debug handling
>> Split gather-node debug chat handling into a dedicated `GatherNodeDebug` library that explicitly requires `GatherNodes`, `GatherNodeItems`, and `GatherNodeUnits`
>> Gather-node refresh chat handling now uses the same broad-chat-listener pattern as other debug systems such as `WeatherSystemV4`, with message filtering inside the handler instead of duplicate exact-match chat registrations
>> Gather-node debug chat registration is now limited to `Player(0)` only
>> Gather-node debug chat features now initialize and run only when gather-node debug mode is enabled
>> Added debug-only minimap spawn pings for gather nodes so real herb/item and vein/unit spawns are easier to verify during tests
>>> herb/item node spawns now ping the minimap in green for 5 seconds
>>> vein/unit node spawns now ping the minimap in orange for 5 seconds
>> Reworked random zone spawning to use `ZonesCore` zone data directly instead of exported gather-zone spawn-region registrations
>> Added `GN_GetZoneSpawnRect(zoneId)` as the shared gather helper for zone-random spawning across both item and unit node subsystems
>> IMPORTANT: random zone spawning now prefers the zone's first enter rect as the spawn area
>>>> Sometimes for some zones this rect can be small opening etc. so when configuring zone enter rects, keep in mind
>>>> IDEA: could make separate node spawn rect that covers always the whole zone!
>> If a zone has no enter rect configured, gather random spawning falls back to that zone's main weather rect from `ZonesCore`

ItemManager / Gather Node Export
- Aligned Gather Node Management export and UI with the final `ZonesCore`-driven random-zone spawning model
>> `GatherNodeExporter` no longer treats random zone spawning as a separate gather-zone rect export concern
>> Exported `RegisterSpawnRegions()` is now intentionally empty because random zone placements use `ZonesCore` rects at runtime
>> Export now only emits explicit spawn-group registrations and spawn points for placement modes that actually need them
>> Removed the earlier temporary herb/item spawn-region fallback behavior from the exporter after the runtime was updated to use `ZonesCore`
>> Hardened gather-node export spawn-mode normalization so old and new placement labels still map correctly to runtime spawn modes
>> Updated Gather Node Management placement labels and help text so `Random In Zone` clearly means `ZonesCore` zone-rect spawning
>> `Spawn Group + Random` is now presented more clearly as `Spawn Group + Zone Random Fallback`

======================== Player-Facing Updates:

Gather Nodes / Debug & Testing
- Gather-node debug visibility is improved during in-map testing
>> When gather debug mode is enabled, node spawns are now easier to notice because new gather nodes ping the minimap on spawn
>> The gather refresh debug command is now restricted to player 1 chat instead of being registered for all player slots

Gather Nodes / Spawn Reliability
- Random zone spawning now follows the central zone setup from `ZonesCore`
>> Zone assignments using `Random In Zone` no longer require separate gather-zone rect setup in exported gather definitions
>> Random herb/item and vein/unit spawns now use the zone rect from `ZonesCore`, with the first enter rect preferred as the actual spawn area
>> This removes duplicate zone-rect authoring for gather random spawns and makes zone placement behavior match the project's main zone data source

======================== Actions Remaining:

Gather Nodes / Debug Refresh Validation
- In-map validation is still needed for the gather-node refresh command path
>> The chat-command plumbing was simplified and moved out of the master library, but refresh behavior still needs live verification in Warcraft after the latest refactor

Gather Nodes / Content Validation
- Gather random spawning still needs another in-map validation pass after the `ZonesCore` integration
>> Verify that zones now spawn gather nodes inside the intended first enter rect coverage and only fall back to weather rects when necessary
>> Review current `ZonesCore` enter-rect setup for any zones where the preferred random spawn area should be broader or narrower than the current first enter rect

============================================================================
17.5.2026 - List of Actions:

======================== Technical Updates: 

GatherNodes / GatherNodeItems / GatherNodeUnits
- Continued Gather Node runtime integration and spawn-control fixes
>> Added shared category-cap support across placements so nodes in the same category can now share one active max in the same zone or spawn group
>> Added type-specific random-spawn occupancy checks so herb/item nodes avoid overlapping other active herb/item nodes and vein/unit nodes avoid overlapping other active vein/unit nodes
>> Item and unit random-spawn occupancy checks do not block each other across types, so herbs do not block veins and veins do not block herbs
>> Fixed JASS function declaration order issues in `GatherNodes.j`, `GatherNodeItems.j`, and `GatherNodeUnits.j` so the updated gather-node scripts compile with the project's declaration-order limitations
>> Added gather-node debug refresh support through chat command `/gathernodes refresh`, which now clears active gather nodes and respawns them from current assignments
>> Added refresh-generation safety for gather-node respawn timers so old timers do not recreate duplicate nodes after a manual refresh
>> Mitigated a post-load gather-node crash risk by moving the new `/gathernodes refresh` chat-trigger registration out of earliest library init and into delayed init after game load
>> Hardened gather-node glow-effect application so glow setup now skips height / color / scale native calls when effect creation fails instead of assuming a valid effect handle exists

ItemManager / Gather Node Management
- Continued Gather Node Management UI and data-model work
>> Added readable spawn-group display names in spawn-point / placement selectors instead of raw class-name object text
>> Improved Add/Edit Zone Assignment dialog layout and help text for shared category max usage
>> Added clearer shared-pool chance visibility in Gather Management so zone/group placement rows now show effective weight and relative chance within the shared pool instead of only raw override values
>> Added persistent item-node and unit-node display ordering plus `Move Up` / `Move Down` controls in Gather Management for easier authoring / export control
>> Gather-node export ordering now follows the managed node order more closely instead of relying only on alphabetical output inside categories
>> Added unit-node glow height authoring and export support so vein glow visuals can be offset vertically per node
>> Added `Any / Not configured` zone support in spawn-group and zone-assignment editing for manual authoring cases where a concrete zone should not be required yet
>> Reworked unit-node owner-player editing to use Warcraft slot-style owner labels instead of raw JASS index guessing, so `Player 24` now maps correctly to `Player(23)` while neutral owners remain explicit options

Gather Node Authoring / Export / Imported Runtime
- Imported new working versions of:
>> `GatherNodes.j`
>> `GatherNodeItems.j`
>> `GatherNodeUnits.j`
>> Also continued configuration work in ItemManager Gather Node Management and exported a newer `GatherNodeDefinitions` version for current testing
>> Tightened unit spawn-point export for mixed spawn groups so ore-family nodes and crystal-family nodes no longer share the same unrestricted spawn-point pool when the exported group data contains both families
>> This was added after content testing exposed a case where `Gold Vein` could use a spawn rect from the wrong mixed unit spawn group content set

======================== Player-Facing Updates:

Gather Nodes / Authoring Progress
- Gather node setup is now in a better work-in-progress state for real map-side iteration
>> Shared caps, spawn-group targeting, occupancy control, placement editing, and clearer chance visibility are now in place for further balancing and content setup
>> Manual gather-node refresh is now available in-map through `/gathernodes refresh`, making it easier to re-test imported gather-node data and placement changes without relying only on natural despawn/respawn flow
>> Current gather-node data and placement setup still needs more work, especially herb definitions / herb spawn rect coverage and general placement polish

======================== Actions Remaining:

Gather Nodes / Content Pass
- Herb nodes and their spawn-rect setup still need more authoring and testing work
>> Current state is usable as a stronger WIP baseline, but herb placements in particular still need more configuration / cleanup in ItemManager and in-map verification
- Further balancing is still needed for shared spawn pools
>> Recommended next pass:
>>> review per-zone / per-group shared category max values
>>> review spawn-weight splits such as copper / tin / silver distribution in each pool
>>> verify exported `GatherNodeDefinitions` against current imported `GatherNodes` runtime files in the map

============================================================================
16.5.2026 - List of Actions:

======================== Technical Updates: 

BridgesAndGates / BridgeSystem
- Added optional top-lane entry-centering for `BridgeSystem.j` `C/D` crossings
>> Added per-bridge boolean config/API:
>>> `BridgeSystem_SetTopLaneEntryCentering`
>> Default behavior is now `true`
>> When enabled, a unit entering from `C` or `D` first moves to that side's activation rect center before the normal forced move continues toward the opposite `C/D` exit
>> This was added to keep top-lane bridge crossings visually centered instead of starting the forced bridge move from an off-center edge approach

Zones / ZonesCore
- Refactored parent-zone relationships into explicit `ZonesCore` data
>> `ZoneData` now stores an explicit `parentZoneId` instead of relying on other systems to infer parent/child links from numeric zone ID patterns
>> Added reusable parent-zone helpers/API in `ZonesCore.j`:
>>> `setParentZone`
>>> `getParentZoneId`
>>> `hasParentZone`
>>> `GetParentZoneId`
>>> `GetParentZoneData`
>>> `HasParentZone`
>>> `IsChildZoneOf`
>> Wired explicit parent links into current known child zones / interiors so the relationship can now be reused by systems beyond weather

EnvironmentSystems / WeatherSystemV4
- Refactored `WeatherSystemV4.j` to use explicit parent-zone links from `ZonesCore`
>> Removed the old weather-side parent-zone inference based on numeric zone ID formatting
>> Weather inheritance / propagation now reads the parent zone relationship directly from `ZonesCore`
>> This makes weather inheritance data-driven and keeps zone hierarchy ownership centralized in `ZonesCore`

CreepRespawn
- Refactored `CreepRespawn.j` respawn scheduling to remove `TriggerSleepAction` from the death-event flow
>> Replaced the old wait-based respawn path with `TimerUtils` timer scheduling, so each death now creates an isolated respawn timer instead of sleeping inside trigger execution
>> Stored respawn payload data per scheduled timer and moved actual unit recreation into a timer-expire callback, which is a safer library pattern for JASS/vJASS systems
>> Fixed respawn delay behavior so the 80-240 second delay is now rolled per death instead of being randomized once at map init and then reused for the whole game

======================== Player-Facing Updates:

Bridges / Top-Lane Crossing
- `C/D` bridge crossings should now stay more centered when entering the bridge
>> Units coming from the top-lane bridge sides now first align to the bridge entry center before crossing to the opposite side
>> This should reduce sideways-looking entry movement and make bridge traversal look cleaner on bridges using the standard `C/D` top lane setup

Zones / System Foundations
- Parent-child zone relationships are now defined explicitly in the zone system
>> This does not mainly change immediate gameplay on its own, but it gives better control for future zone-specific behavior, inheritance, and linked system logic

CreepRespawn
- Creeps now use proper delayed respawn scheduling internally
>> Respawn timing remains in the same 80-240 second range, but the delay now varies correctly per individual death instead of all affected units sharing the same rolled value for the full session

ItemManager / Gather Node Management
- Refactored Gather Node authoring toward main-table-backed nodes and explicit spawn placement targeting
>> Item gather nodes now validate against the main `items` table before save instead of relying on `gather_herb_definitions` as the source of truth
>> Unit gather nodes now validate against the main `unit_types` table before save instead of relying on `gather_vein_definitions` as the source of truth
>> `gather_herb_definitions` and `gather_vein_definitions` remain available as preset metadata pickers, but they no longer bypass the main database tables for authoritative codes
>> Added spawn-point groups to the Gather Node database / UI / export path so nodes can now target selected spawn-point groups instead of only broad zone-level region lists
>> Zone placement authoring now uses the clearer model:
>>> `Random In Zone`
>>> `Spawn Group`
>> Gather-node export/runtime was updated so group-targeted placement data is exported and used by both `GatherNodeItems.j` and `GatherNodeUnits.j`
>> Item and unit spawn placement support now shares the same conceptual targeting flow instead of items remaining random-only
- Added practical multi-edit for Gather Node management
>> Added bulk category assignment for selected item nodes
>> Added bulk category assignment for selected unit nodes
>> Added multi-select placement management for node zone placements
>>> Selected placements can now be removed together
>>> Selected placements can now be enabled / disabled together
- Improved spawn-point authoring workflow
>> Added spawn-point group management in the Spawn Points tab
>> Added spawn-point autofill by numeric pattern so batches such as `RegionXXX0001` to `RegionXXX0010` can be created while retaining the selected zone / node type / optional spawn group context
>> This gives a cheaper authoring path for large rect sets without requiring Excel-style drag fill yet

ItemManager / Items / Drop Sources
- Fixed the unsaved-item foreign-key failure in Drop Sources
>> `Add Drop Source` is now disabled until the item exists in the main `items` table
>> Drop-source actions now hard-check that the item was saved first, preventing the `23503` / `fk_usd_item` crash path from trying to insert orphan `unit_specific_drops` rows

======================== Actions Remaining:

ItemManager / Gather Nodes
- In-game verification is still needed for the new gather-node spawn-group export/runtime path in the actual map
>> Recommended checks:
>>> one herb using `Random In Zone`
>>> one herb using `Spawn Group`
>>> one vein using `Spawn Group`
>>> mixed-zone setups where one zone uses group targeting and another uses random placement
- Extra bulk-edit tools can still be expanded later if needed
>> likely next useful additions would be batch placement-mode updates and batch spawn-group reassignment for selected placement rows
- Excel-style drag fill for spawn-point rows is still not implemented
>> pattern autofill was added first because it solves the higher-value authoring case with much less UI complexity

============================================================================
15.5.2026 - List of Actions:

======================== Technical Updates: 

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` patrol and timeout fallback fixes
>> Bridge-triggered patrol handling now uses a relocation-safe patrol pause path instead of issuing `stop` / `holdposition` before the bridge snap
>> Top-lane timeout fallback was adjusted to be less aggressive
>>> `BRIDGE_TOP_LANE_FORCE_EXIT_TIMEOUT` increased from `6.0` to `10.0`
>> Stuck `C/D` timeout recovery now snaps units to the saved forced overshoot destination past the far exit, instead of the opposite exit entry center
>> This should reduce false timeout recoveries and prevent timeout teleports from immediately re-triggering `BridgeSystem_AddActivateRect` top-lane activation
>> Under-lane `A/B` bridge relocation now tells bridge-paused patrol units to skip the stale currently awaited waypoint after the bridge move

PatrolFollowSystems / PatrolSystem
- Refined bridge relocation patrol resume behavior again
>> Added `PatrolSystem_PauseForRelocation(unit)` so systems like `BridgeSystem` can pause patrol state/timers without forcing a visible stop first
>> `PatrolSystem_ResumeFromCurrentPosition(unit)` now keeps advancing patrol index when a relocated unit is clearly closer to later waypoint legs than the stale stored target
>> This should prevent patrol units from pausing briefly after a bridge move and then trying to walk backward toward the pre-bridge waypoint
>> Added `PatrolSystem_ResumeFromCurrentPositionEx(unit, skipCurrentWaypoint)` for systems that need explicit post-relocation waypoint skipping
>> `BridgeSystem` now uses that path for under-lane `A/B` patrol relocations so patrol units continue to the next waypoint instead of trying to finish the pre-bridge one

Zones / ZonesCore
- Added new `Dragonfire Peaks` subzones to `ZonesCore.j`
>> `0401` `Ashfang Outpost`
>> `0402` `Skaldrath "Wyrmfall"`
>> `0403` `Morgrim's Claim`
>> `0404` `Maw of Cinders`
>> `0405` `Ashfang Falls`
- Updated volcanic-zone weather setup in `ZonesCore.j`
>> `Emberpeak Highlands` and `Dragonfire Peaks` now use a dry weather profile without rain or storm rolls
>> The outdoor `Dragonfire Peaks` subzones now use the same dry profile
>> Added per-zone toggle `weatherInheritFromParent` (default `true`) so subzones can either inherit their parent zone weather or roll their own seasonal weather
>> Current use case: `04xx` outdoor `Dragonfire Peaks` subzones inherit the parent zone weather by default unless explicitly overridden

EnvironmentSystems / WeatherSystemV4
- Expanded subzone weather inheritance handling in `WeatherSystemV4.j`
>> Added parent-zone lookup for subzones based on the current zone ID layout
>> Parent-zone weather start / stop now propagates to inheriting subzones instead of treating them as completely separate outdoor weather islands
>> Seasonal weather checks now scan the wider zone ID range and skip only subzones that inherit from a parent
>> Subzones with `weatherInheritFromParent = false` can now keep their own seasonal weather behavior while inheriting subzones follow the parent zone state

EnvironmentSystems / TerrainDamage
- Expanded `IgnoreTerrainDamage` ability coverage
>> Added `IgnoreTerrainDamage` to many units that needed it, especially dummy units and other units that should never be affected by terrain hazards
>> This should reduce incorrect lava / hazard damage on helper units and special-purpose noncombat units
- Added terrain effect scale ramp-up visuals
>> Lava / fel terrain special effects can now scale up gradually during the existing terrain damage ramp
>> Added configurable start / end effect scale constants per terrain type
>> Effect scale growth now includes random upward-trending variation during the ramp instead of a perfectly constant increase

======================== Player-Facing Updates:

Bridges / Patrol Movement
- Patrol units moved by bridge logic should now continue more smoothly after the transfer
>> Reduced the visible pause caused by bridge patrol handoff
>> Reduced cases where a patrol unit tries to return backward toward the old side because its previous waypoint was still being waited on
>> Under-lane `A/B` patrol units moved by the bridge should now continue to their next patrol waypoint instead of trying to complete the stale pre-bridge waypoint

Bridges / Timeout Recovery
- Top-lane bridge stuck recovery was made safer
>> `C/D` timeout fallback should now trigger less prematurely
>> When recovery does happen, the forced exit snap should land beyond the far exit instead of directly on the opposite bridge entry, reducing accidental re-activation loops

Dragonfire Peaks
- Added more subzone groundwork in `Dragonfire Peaks`
>> `Ashfang Outpost`
>> `Skaldrath "Wyrmfall"`
>> `Morgrim's Claim`
>> `Maw of Cinders`
>> `Ashfang Falls`

Dragonfire Peaks / Emberpeak Highlands
- Removed rainy weather from the volcanic mountain zones
>> `Dragonfire Peaks`, its outdoor subzones, and `Emberpeak Highlands` no longer roll rain-based weather
>> These areas now follow a drier weather pattern, favoring wind and limited snow instead

Hazards / Unit Immunities
- More units now correctly ignore terrain hazard damage
>> Especially dummy / helper units should no longer take incorrect lava or similar terrain damage

Hazards / Terrain Visuals
- Damaging terrain effects now intensify visually over time
>> Lava / fel effect scale ramps up gradually while a unit remains on the damaging terrain, with some variation instead of a perfectly even increase

============================================================================
14.5.2026 - List of Actions:

======================== Technical Updates: 

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` fixes and bridge compatibility updates
>> Added destructable type `OTis` to the default controlled bridge platform types
>>> `OTis` // invisible platform (small)
>> This ensures bridges using the smaller invisible platform type are now included in bridge init / open / close platform handling just like `OTip` bridges
>> Follow-up fix: companion/stat/reputation-related units should no longer become incorrectly exposed to death because of mismatched bridge platform state or bridge-managed vulnerability/state cleanup edge cases
>> Top-lane shadow hiding now swaps the unit shadow image to `NONE` and restores the original shadow image afterward, instead of only changing shadow size/offset fields
>> Added bridge-managed unit death cleanup so a `C/D` unit dying on the bridge is removed from active bridge handling immediately
>> Added a top-lane timeout fallback so stuck `C/D` units are forced to the opposite exit entry and released instead of leaving the bridge permanently active

BridgesAndGates / Bridges
- Added new bridge sublibrary: `HBridge003`

Terrain / Pathing
- Adjusted pathing blockers in many cliff areas
>> Continued cleanup of terrain movement edges and pathing flow around cliffside sections

Terrain / Subzones / Zone Drafting
- Created new draft subzone rects for `04DragonfirePeaks`
>> `04AshfangOutpost` - orcish outpost
>> `04Skaldrath` (`Wyrmfall`) - ancient dragon graveyard
>> `04MorgrimsClaim` - dwarven mine claim

EnvironmentSystems / TerrainDamage
- Expanded terrain-damage immunity coverage
>> Added `IgnoreTerrainDamage` to more units, especially lava / fire-themed units that should naturally ignore those hazards

======================== Player-Facing Updates:

Bridges / Companion Safety
- Bridge behavior was corrected on another bridge variant using smaller invisible bridge platforms
>> This should make bridge state changes more reliable and should also prevent cases where companion/stat/reputation-related units could die incorrectly near bridge logic
>> Bridge crossings should now also recover more safely if a unit dies mid-crossing or gets stuck before reaching the far side

Bridges
- Added a new bridge: `HBridge003`

World / Traversal
- Improved movement around many cliff areas by adjusting pathing blockers

Dragonfire Peaks
- Added groundwork for new subzones in `Dragonfire Peaks`
>> `Ashfang Outpost` - an orcish outpost area
>> `Skaldrath` / `Wyrmfall` - an ancient dragon graveyard area
>> `04MorgrimsClaim`  - dwarven mine claim

Hazards / Creature Logic
- More lava / fire-like units now ignore terrain damage where it makes sense

Attributes & Stats:
- Attack Speed Bonus per Agility Point reduced from 0.020 to 0.010
- Defense bonus per Agility Point reduced from 0.100 to 0.050


============================================================================
13.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` fixes and API improvements
>> Top-lane shadow hiding was strengthened by also zeroing shadow width / height while a `C/D` unit is bridge-managed, then restoring the original values on cleanup
>> Added new ignore API for bridge handling:
>>> `BridgeSystem_AddIgnoredUnit`
>>> `BridgeSystem_RemoveIgnoredUnit`
>>> `BridgeSystem_AddIgnoredGroup`
>>> `BridgeSystem_RemoveIgnoredGroup`
>> Added delayed bridge config hooks similar to TerrainDamage:
>>> `BridgeSystem_InitIgnoredUnits`
>>> `BridgeSystem_InitIgnoredGroups`
>> Ignored units / groups are now skipped by bridge activation, approach redirect, bridge adoption, and cleanup validation

BridgesAndGates / HBridge008
- Corrected bridge-specific assumptions
>> Removed an incorrect temporary ship-only top-lane activate filter after verifying `HBridge008` currently follows the same `A/B` and `C/D` rect logic as `HBridge001`

BridgesAndGates / HBridge002
- Created HBridge002

PatrolFollowSystems / PatrolSystem
- Refined bridge patrol resume behavior
>> `PatrolSystem_Pause` now stores the patrol state that was active before the bridge pause
>> `PatrolSystem_ResumeFromCurrentPosition` now resumes toward the correct current patrol leg using the stored patrol direction / state instead of choosing a nearest waypoint that could make the unit continue backwards

EnvironmentSystems / TerrainDamage
- Continued `TerrainDamage.j` optimization and behavior changes
>> Added optional rect-local player tracking for registered players so terrain tracking can be limited to configured `gg_rct_...` hazard areas instead of always maintaining the whole player-owned unit set
>> Added new API / config hook:
>>> `TerrainDamage_RegisterPlayerTrackRect`
>>> `TerrainDamage_InitPlayerTrackRects`
>> Player tracking bootstrap and periodic resync now use those configured rects when present, which should reduce expensive whole-player scan overhead
>> Terrain damage on dead units was changed so dead corpses no longer take actual damage, but terrain effects still play while the corpse remains on the damaging terrain
>> Corpse terrain sounds now play at reduced `50%` volume instead of full volume
>> Object Editor follow-up: added `IgnoreTerrainDamage` ability to many fire / similar appropriate units so they are ignored by terrain damage without needing extra script-side exclusions

EnvironmentSystems / FogSystem / WeatherSystem / ZoneEvent
- Reduced repeated fog application spam
>> `FogSystem.j` now ignores exact repeated fog requests for the same player instead of logging / reapplying them again
>> Fixed `FogSystem` init so it no longer repeatedly applies startup fog to `Player(0)` inside the user-player loop
>> `FogSystem` now still applies valid fog distance-only changes even when fog color stays the same
>> Important branch correction: `WeatherSystemV4.j` is now the current master WeatherSystem script in use
>> The earlier note that referenced `WeatherSystemv3.j` for these latest fog/weather stop-start fixes was wrong; the relevant logic must live in `WeatherSystemV4.j` instead
>> `WeatherSystemV4.j` stop/start flow was cleaned up to avoid some redundant `ZoneEvent_ApplyCurrentZoneEffects()` calls and region-stop / zone-stop reapply duplication that could contribute to repeated fog reapplication
>> `WeatherSystemv3_maybeWorkingVersion.j` was renamed to `WeatherSystemV4.j` to make the active master branch clearer

=================================================================================================================================================
12.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` bridge fixes / behavior safeguards
>> Bridge-managed patrol units now resume patrol from their current position by selecting the nearest saved patrol waypoint instead of returning toward their old patrol-side location
>> Added shared lane-trigger guard logic so a unit already managed on one bridge lane cannot be immediately picked up by the opposite lane trigger on the same bridge
>> This was aimed especially at `HBridge008`, where overlapping / sensitive rect behavior could cause weird state flips such as bridge mode changing unexpectedly and top-lane shadow / bridge-state behavior not staying consistent

PatrolFollowSystems / PatrolSystem
- Added patrol resume helper for bridge integration
>> New helper: `PatrolSystem_ResumeFromCurrentPosition(unit)`
>> When used by `BridgeSystem`, patrol now continues from the nearest waypoint based on the unit's current location instead of forcing a return toward the previous patrol target

EnvironmentSystems / TerrainDamage
- Fixed dead-unit terrain timer cleanup more aggressively
>> `TerrainDamage.j` now requires `UnitDeathEvent` and clears armed terrain damage timers immediately when a tracked unit dies
>> Added extra dead-unit bailout in the per-unit terrain timer callback so stale terrain timers do not continue damaging corpses while waiting for periodic rescan cleanup

CreepRespawn / Neutral Passive hostile-temporary flow
- Continued Neutral Passive respawn fixes for units temporarily turned hostile
>> `CreepRespawn.j` now stores the intended respawn owner together with saved respawn position/facing data, using saved owner state instead of only the unit's current owner at death time
>> Fixed respawnable-owner checks so units temporarily changed from Neutral Passive to Player 23 are still accepted by respawn logic and recreated as their original saved owner
>> Also corrected saved respawn data layout so owner storage no longer overlaps another saved unit's position/facing slots
>> GUI integration note: added `call CreepRespawn_OnUnitEnter(udg_DamageEventTarget)` before the GUI ownership swap in the `Neutral Creature Attacked` trigger, so temporary-hostile critters save their original Neutral Passive respawn owner before being changed to Player 23

=================================================================================================================================================
11.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` bridge fixes / cleanup
>> Top-lane `C/D` units now hide their shadow while crossing and restore the original shadow values after leaving bridge control
>> Added patrol-aware under-lane `A/B` handling so bridge teleports pause / resume `PatrolSystem` when needed instead of letting patrol orders snap units back toward old locations
>> Added extra forced-state cleanup safety so stuck `C/D` units are freed more reliably if bridge state becomes stale
>> Fixed a regression where `C/D` units could lose invulnerability too early while crossing because top-lane safety release was firing outside the main bridge rect gap

EnvironmentSystems / TerrainDamage
- Optimized `TerrainDamage.j` periodic scanning
>> Removed the expensive every-`0.40` full-player fallback scan from the hot loop; registered player units are now mainly processed through the maintained tracked group
>> Added a slower periodic player resync safety pass instead of rescanning all registered players every terrain tick
>> Added per-pass duplicate-scan suppression so the same unit is not reprocessed multiple times in one terrain scan cycle when present in overlapping sources
>> Dead units are now filtered out before terrain damage ticks are applied
>> Added easier ignore configuration helpers for unit-types / players, useful for cases like ore veins without adding ignore ability manually to every unit

CreepRespawn / UnitDeathEvent
- Fixed Neutral Passive respawn support
>> Found that `_CoreSystems/UnitDeathEvent.j` used Blizzard `TriggerRegisterAnyUnitEventBJ`, which does not cover extended neutral player slots needed by this map setup
>> Replaced the centralized death registration with explicit `Player(0)` to `Player(27)` registration so Neutral Passive / other extended-slot deaths reach respawn callbacks reliably
>> Fixed `CreepRespawn.j` so units temporarily moved to Player 23 (Emerald) now actually respawn back as Neutral Passive instead of only changing a local owner variable during death checks

=================================================================================================================================================
10.5.2026 - List of Actions:

UnitEvent
- added: constant integer `UNIT_EVENT_MAX_PLAYER_INDEX = 27`
- replaced old reliance on Blizzard `bj_MAX_PLAYER_SLOTS`, which only covers 16 players in older WC3 format
- fixed preplaced unit bootstrap enumeration to use an explicit reusable group instead of fragile `bj_lastCreatedGroup` usage
- result: neutral passive / neutral aggressive preplaced units now index correctly for systems depending on `GetUnitUserData`
- likely root cause note: the earlier incorrect `UNIT_EVENT_MAX_PLAYER_INDEX` value was very likely also behind issues where Neutral Passive units turned hostile and Neutral Passive units did not respawn correctly
- follow-up check recommended: audit other existing systems for hardcoded max-player values such as `26` or use of Blizzard max-player slot natives/constants, and replace with `27` or another verified higher value where required by the map setup

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` bridge traffic fixes / refinements
>> Added configurable per-bridge approach redirect helpers for entry pathing:
>>> `BridgeSystem_SetTopApproach`
>>> `BridgeSystem_SetUnderApproach`
>> `C/D` approach redirect now re-orders units to the entry rect when movement is issued through the bridge area before invisible platforms are active
>> `A/B` under-lane bridge control is now only active while top-lane `C/D` traffic is active
>> Default idle state now leaves `A/B` fully normal / free when bridge traffic is cleared
>> Under-lane bridge pass handling was adjusted so `A/B` special movement can start while top-lane movement is active instead of being left stuck in queue flow
>> Refactored managed-state cleanup helper ordering to avoid function declaration-order issues in JASS
>> Current status: `BridgeSystem` now seems to work pretty well overall after the latest top / under-lane fixes

- Remaining notes
>> There may still be edge cases that require more in-game testing
>> Each bridge still needs careful editor setup for rect placement, pathing blockers, and invisible platforms

EnvironmentSystems / TerrainDamage
- Refactored `TerrainDamage.j` terrain tick handling
>> Reworked the system so the global timer is now only a terrain scanner and units on damaging terrain own their own local damage timers
>> Terrain damage ticks are no longer fully synchronized for all units standing on the same terrain at the same time
>> Added per-unit timer state / revalidation so each unit timer checks that the unit is still alive, still tracked by the terrain system, not protected by bridge state, and still standing on the same terrain type before applying damage
>> Registered-player tracking was refactored toward UnitIndexer / `UnitEvent`-driven maintenance, while keeping a direct player rescan fallback for stability / resync
>> Added deterministic first-tick phase offset so units entering lava / fel do not feel as lockstep as before
>> Added per-terrain interval ramp configuration:
>>> `*_INTERVAL_START`
>>> `*_INTERVAL_END`
>>> `*_RAMP_DURATION`
>> Interval ramp currently affects tick frequency only; damage amount still uses the configured terrain damage percent
>> Added per-terrain sound pitch variation configuration:
>>> `*_SOUND_VARIATION`
>>> `*_SOUND_PITCH_MIN`
>>> `*_SOUND_PITCH_MAX`
>> Terrain damage sounds can now optionally randomize pitch slightly on each playback to add variation
>> Sound pitch is explicitly reset to `1.00` when variation is disabled so recycled SoundTools handles do not keep an old altered pitch
>> Added configurable ignore-marker ability:
>>> `TERRAIN_DAMAGE_IGNORE_ABILITY`
>> Units with the configured ignore ability are skipped by terrain qualification checks
>> Added extra safety guard at actual damage application so ignored units do not take terrain damage even from an already armed stale timer
>> Changed terrain damage application to non-attack `UnitDamageTarget(..., false, false, ...)` behavior so units without a normal attack setup can still be damaged correctly
>> Flat interval behavior remains the default when start / end interval are equal or ramp duration is `0.00`
>> Existing group / unit / player registration API was kept intact
>> Fel terrain effect cleanup still uses `SpeciFX_DestroyTimed(...)` instead of immediate destroy

=================================================================================================================================================
2.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Reworked bridge traffic handling into lane-based movement control
>> `C/D` now act as the top-of-bridge lane and `A/B` as the under-bridge lane
>> Units entering either lane are force-moved toward the opposite rect of that same lane
>> Added lane priority / queue handling so only one bridge lane is active at a time per bridge
>> Added periodic bridge evaluation to keep active lane units moving out of the bridge area and to recover from paused deadlock states
>> Added forced-order interception so bridge-managed units keep their system-issued crossing movement instead of getting stuck on conflicting orders
>> Top-lane units now gain `Ghost (visible)` during forced crossing to disable collision and have it removed on cleanup
>> Completion / cleanup logic now also resolves based on actual destination reach / proximity, not only trigger rect transitions

- Updated bridge-specific sublibraries:
>> `HBridge001.j`
>>> Removed old Player 1 / owner restrictions so bridge behavior applies to any unit
>> `HBridge008.j`
>>> Removed old ship-name-based restriction so bridge behavior applies to any unit

- Updated bridge template:
>> `HBridgeTemplate.j`
>>> Documented slot-order contract and lane-based top / under bridge movement behavior

=================================================================================================================================================
1.5.2026 - List of Actions:

SpeciFX
- Added timed special effect destroy support
>> New API: `SpeciFX_Duration(real duration)` to destroy the latest created SpeciFX/GUI effect after the given duration
>> Added `SpeciFX_DestroyTimed(effect whichEffect, real duration)` for explicit timed cleanup of native JASS-created effect handles
>> Timed destroy now reuses SpeciFX tracking/cleanup so delayed-destroyed effects are also unregistered correctly

Models
- Imported Sindu elf - recolored version (credits Missing Shadowsong (sponsor), Commedia, Xiaoyuezhen, Blizzard Entertainment)
>> to be decided whether to actually use the model and what permissions (e.g., the skin recolor)

BridgesAndGates / BridgeSystem
- Added new JASS-based bridge core library: `BridgesAndGates/Bridges/BridgeSystem.j`
>> Replaces old GUI-style bridge handling with reusable bridge registration API
>> Handles bridge init state, bridge pathing/platform destructibles, entry blockers, activate/deactivate trigger flow, and unit invulnerability toggling while crossing
>> Automatically updates GUI boolean array state with `udg_IsUnitOnBridge[GetUnitUserData(unit)] = true/false`
>> Added public helper API for manual control and queries:
>>> `BridgeSystem_SetUnitOnBridge`
>>> `BridgeSystem_SetUnitOnBridgeByCustomValue`
>>> `BridgeSystem_IsUnitOnBridge`
>>> `BridgeSystem_Activate`
>>> `BridgeSystem_Deactivate`

- Added bridge-specific sublibraries:
>> `Bridge_HBridge001.j`
>>> Mirrors old GUI logic for HBridge001
>>> Uses Player 1 (Red) owner checks for activate/deactivate
>> `Bridge_HBridge008.j`
>>> Mirrors old GUI logic for HBridge008
>>> Uses ship-only deactivate filter based on current bridge notes / unit names

- Added bridge template sublibrary:
>> `BridgesAndGates/Bridges/Bridge_HBridgeTemplate.j`
>>> Copyable template for creating new bridge sublibraries faster
>>> Includes placeholders for bridge rects, blocker point rects, optional conditions, and optional custom activate/deactivate callbacks

- Documentation / comments
>> Added usage comments and API examples directly into `BridgeSystem.j`
>> Documented relevant sections so future bridge additions are easier to maintain

- Follow-up bridge fixes / behavior corrections
>> Corrected bridge rect semantics in sublibraries and template:
>>> Upper bridge-entry rects now activate bridge-top state / invulnerability
>>> Underneath rects now deactivate bridge-top state
>> Updated `HBridge001.j`, `HBridge008.j`, `HBridgeTemplate.j`, and `BridgeSystem.j` comments/examples to match the corrected bridge logic
>> Added bridge-state cleanup safety handling in `BridgeSystem.j`
>>> Units now have `udg_IsUnitOnBridge[...]` reset to false if they leave the bridge area without hitting the normal deactivate rects
>>> Covers unexpected exits such as teleporting out of the bridge area or leaving via upper-side routes
>>> Also clears the temporary invulnerability state during this cleanup
>> Updated `TerrainDamage.j`
>>> Terrain damage no longer affects units while `udg_IsUnitOnBridge[GetUnitUserData(unit)]` is true

=================================================================================================================================================
26.4.2026 - List of Actions:

TerrainDamage
- In main map - need to consider to re-add Nazgrek/Zulkis if the variable is re-assigned...
- Now runs necessary init functions again in "Game Start" -trigger

Wyrmhold Sanctum
- terrained lava doodads around Dragon Mother boss area
>>> more pathing blockers + invisible platforms
>>> rocks

=================================================================================================================================================
25.4.2026 - List of Actions:

Imported "new" DNC to test with different fixed ambient intensity value
- test with 0.01 ambient intensity (command dnc lordfixed); Result: only map center area is affected and borders of the map are without any DNC (similar result as in previous DNC tests...)

Wyrmhold Sanctum
- terrained lava doodads around Dragon Mother boss area
>>> lava
>>> more pathing blockers + invisible platforms

TerrainDamage -library
- created
- damages units added to the system depending if they are on the defined terrain type, e.g., Lava Cracks
- pretty caveman library but should do its job

SoundTools (Credits Magtheridon96)
- imported to map
- was necessary to utilize more advanced sound functionalities and my custom ExSound does provide functionality to have multisounds for internal WC3 sounds 



=================================================================================================================================================
20.4.2026 - List of Actions:

GatherNodes.j
- GN_RANDOM_SPAWN_ATTEMPTS - Changed from private constant to constant in GatherNodes.j:46-47 so GatherNodeItems.j and GatherNodeUnits.j can access it

ItemManager / UI:
- GatherNodeDefinitions - C# Export Fixes:
>> Decimal separator bug - Added CultureInfo.InvariantCulture for all real number formatting in GatherNodeExporter.cs. Real values like 5.0 were exported as 5,0 causing JASS parse errors
- UI Additions:
>> Enable/Disable buttons added to all three tabs:
>>>> Item Nodes: Enable/Disable buttons for selected items
>>>> Unit Nodes: Enable/Disable buttons for selected units
>>>> Spawn Points: Enable/Disable buttons for selected spawn points




=================================================================================================================================================
15.4.2026 - List of Actions:
==== Item Manager and SQL Database

Pre-defined Loot Tables Feature
- Database
>> Added loot_tables and loot_table_items tables
>>Added loot_table_id column to unit_types and destructible_types
>> Created 24 pre-defined loot tables for all level ranges (1-5 through 31+)

- Models
>> Added LootTable and LootTableItem model classes

- Repositories
>> Added LootTableRepository and LootTableItemRepository
>> Updated UnitTypeRepository and DestructibleTypeRepository to support loot_table_id
- UI

>> Added new Loot Table Management form (LootTableForm) with:
>>>> Table list with category filtering
>>>> Add/Edit/Delete/Duplicate tables
>>>> Item management within tables
>> Added "Loot Table" dropdown to Unit Type form
>> Added "Loot Table" dropdown to Destructible Type form
>> Added "Manage Loot Tables..." menu item to main menu

- Updated User Guide / FAQ

- GatherNodes System (big update)
>> Random spawning across zone area
>> Fixed spawn points (like your existing OreRegions[] system)
>> Per-zone spawn mode: random, fixed, or both
>> Integration with Zones.j for zone tracking
>> Respawn timers per node
>> Max nodes per zone limits
>> Use either Units or Items as "Nodes"

JASS Library additions;
- GatherNodes.j - Master library with:
>>> System enable/disable
>> Zone tracking
>> Glow effect system
>> Debug commands
- GatherNodeItems.j - Herb/item spawning:
>> Random zone spawning
>> Pickup detection & respawn
>> Skill requirements
- GatherNodeUnits.j - Vein/unit spawning:
>> Fixed spawn points support
>> Death event handling
>> Vein glow effects



=================================================================================================================================================
14.4.2026 - List of Actions:


==== Item Manager and SQL Database
- Added support for destructible loot management
- Feature to export ItemLootDestructibles.j

ItemLootSystem
- added sublibrary support for ItemLootDestructibles

=================================================================================================================================================
13.4.2026 - List of Actions:

==== Item Manager and SQL Database
- Slight improves to overall GUI experience, QoL updates

ItemLootSystem + sublibraries _Generic and _Specific
- TESTING; started testing these systems in ZoneTests -map
>> with imported W3T Item Data
>> with imported ItemLootSystem JASS sublibraries
- fixed issues with incorrect use of Briebe's table
- fixed issues with integer-to-Boolean and boolean-to-integer usage
- fixed some other minor issues with the system preventing compiling in WE
>> Initial results: works, but some bugs, item creation related wc3 engine timing related?
- Floating text hovering above item when dropped by either ItemDropSystem or unit dropping from inventory
>> API to external systems how to use:
// When your system creates an item:
local item newItem = CreateItem('I000', x, y)
call ItemLoot_CreateFloatingText(newItem, ITEM_RARITY_RARE)

// Or with custom name/color:
call ItemLoot_CreateFloatingTextCustom(newItem, "Special Reward", 255, 215, 0)


=================================================================================================================================================
11.4.2026 - List of Actions:

==== Item Manager and SQL Database
1. W3U Parser & Import
- Fixed binary parser to correctly handle version 3 format
- Correct field order: SetCount → Level → FieldCount → [FieldId → Type → Value → EndMarker]*
- Successfully parses 653 units (122 modified + 531 custom)
- mport dialog with Expected vs Parsed verification
2. ItemSelectorDialog
- Created new Dialogs/ItemSelectorDialog.cs
- Searchable item grid with rarity-colored rows
- Drop configuration: Chance, Guaranteed, Min/Max Qty, Weight, Notes
3. UnitTypeForm Improvements
- Added specific drops grid with Code, Name, Rarity (colored), Chance, Qty columns
- Integrated ItemSelectorDialog for "Add Drop" functionality
- Fixed SQL joins (r.rarity_id → r.id)
4. ItemEditForm Drop Sources
- Added "Drop Sources" tab showing which units drop the item
- Displays: Unit Code, Unit Name, Drop Chance, Guaranteed, Quantity, Notes
5. Database/SQL
- All 6 loot migrations confirmed working
- 7 tiers seeded with rarity weights
6. Logs Tab - Added to MainForm
- Created LogsViewerForm.cs with live updates, color-coded entries, file selection
- Added "Logs" menu with "📋 View Logs..." and "Open Logs Folder"
7. Unit Icons - Added to UnitTypeForm
- Icon column in unit list grid (32x28 thumbnails)
- Selected unit icon display (64x64)
8. TooltipPhrases.json - Expanded to v2.0
- All 38+ stat codes mapped in statCodeMapping
- New itemSuffixes section (14 animal, 12 archetype, 10 elemental - WoW-inspired)
- 24 phrases per rarity (6 rarities) and class (7 classes)
- 20+ phrases for 24 stat categories in byDominantStat
- New sections: closingLines, classSpecificClosing, loreHints, prefixes
9. Bug Fix - UnitTypeForm boss message


=================================================================================================================================================
23.3.2026 - List of Actions:

ItemManager / SQL Database
- modified wc3_base_items table to contain same items as Wc3 has (with Casc viewer from SLK file)
>>> Wc3_base_items -table: we could take advantage of this fully blizzard/WE like table structure if NEEDED

Terraining
- Wyrmhold Sanctum

=================================================================================================================================================
21.3.2026 - List of Actions:

Import more icons from WoW (classic and more recent):
Armor - Necklace
Armor - Rings
Armor - Shields
Armor - Shirts
Armor - Shoulders
Characters and Creatures
Miscellaneous
Trade
Weapons - ShortBlade
Weapons - Staff
Weapons - Wands

Exported into path:
ReplaceableTextures\

Updated also to ItemManager (as PNG format)

ItemManager
- wc3_w3t_exporter.py
>>> The exporter now supports a per-item toggle (copy_base_abilities) to always copy abilities (iabi) from the base item.
>>> If a custom item does not have a cooldown group (icid), it will inherit it from the base item if available.
- NOT implemented; Update Item Add/Edit UI to add the toggle button and bind it to "copy_base_abilities" column !
- bug found: base item IDs are not all correct - e.g., "sor6" reads as its "Scroll of Mana" but in reality sor6 is "Shadow Orb +6 - this will fuck up item creation


=================================================================================================================================================
19.3.2026 - List of Actions:

ItemManager
- fixed DEquipment export
>>> Init was not done correctly like in the original DEquipmentItemDefinitions.j file (delayed Init)
- Dodge stat was named Evasion
>>> Fixed

New Units (Mining)
- Truesilver Vein (lower level places special)
- Fel Iron Vein (Fel orc places)
- Gem Vein (caves etc)
- Incendicite Vein (fiery places)
>>> need to create logic for spawning these and also the item versions of: XXX Ore and XXX Bar
Vein models for reference:
world_skillactivated_tradeskillnodes_ancientgem_miningnode_01
world_skillactivated_tradeskillnodes_incendicite_miningnode_01
world_skillactivated_tradeskillnodes_mithril_miningnode_01
world_skillactivated_tradeskillnodes_tin_miningnode_01
world_skillactivated_tradeskillnodes_truesilver_miningnode_01
world_skillactivated_tradeskillnodes_feliron_miningnode_01

======= Abilities (model attachments) for items created:
item_objectcomponents_weapon_misc_1h_bone_a_01
item_objectcomponents_weapon_misc_1h_book_a_01
item_objectcomponents_weapon_misc_1h_book_b_01
item_objectcomponents_weapon_misc_1h_book_b_02
item_objectcomponents_weapon_misc_1h_book_c_01
item_objectcomponents_weapon_misc_1h_book_c_02
item_objectcomponents_weapon_misc_1h_bottle_a_01
item_objectcomponents_weapon_misc_1h_bottle_a_02
item_objectcomponents_weapon_misc_1h_bread_a_01
item_objectcomponents_weapon_misc_1h_bread_a_02
item_objectcomponents_weapon_misc_1h_bucket_a_01
item_objectcomponents_weapon_misc_1h_fish_a_01
item_objectcomponents_weapon_misc_1h_flower_a_01
item_objectcomponents_weapon_misc_1h_flower_a_02
item_objectcomponents_weapon_misc_1h_flower_a_03
item_objectcomponents_weapon_misc_1h_flower_a_04
item_objectcomponents_weapon_misc_1h_flower_b_01
item_objectcomponents_weapon_misc_1h_flower_b_02
item_objectcomponents_weapon_misc_1h_gizmo_a_01
item_objectcomponents_weapon_misc_1h_glass_a_01
item_objectcomponents_weapon_misc_1h_glass_a_02
item_objectcomponents_weapon_misc_1h_holysymbol_a_01
item_objectcomponents_weapon_misc_1h_lantern_a_01
item_objectcomponents_weapon_misc_1h_lantern_b_01
item_objectcomponents_weapon_misc_1h_mutton_a_01
item_objectcomponents_weapon_misc_1h_mutton_a_02
item_objectcomponents_weapon_misc_1h_mutton_b_01
item_objectcomponents_weapon_misc_1h_mutton_b_02
item_objectcomponents_weapon_misc_1h_orb_a_01
item_objectcomponents_weapon_misc_1h_orb_a_02
item_objectcomponents_weapon_misc_1h_orb_c_01
item_objectcomponents_weapon_misc_1h_potion_a_01
item_objectcomponents_weapon_misc_1h_potion_b_01
item_objectcomponents_weapon_misc_1h_random
item_objectcomponents_weapon_misc_1h_rollingpin_a_01
item_objectcomponents_weapon_misc_1h_seal_a_01
item_objectcomponents_weapon_misc_1h_seal_b_01
item_objectcomponents_weapon_misc_1h_seal_c_01
item_objectcomponents_weapon_misc_1h_skull_b_01
item_objectcomponents_weapon_misc_1h_sparkler_a_01blue
item_objectcomponents_weapon_misc_1h_sparkler_a_01red
item_objectcomponents_weapon_misc_1h_sparkler_a_01white
item_objectcomponents_weapon_misc_1h_tankard_a_01
item_objectcomponents_weapon_misc_1h_waterwand_a_01
item_objectcomponents_weapon_misc_1h_wrench_a_01

item_objectcomponents_weapon_misc_2h_broom_a_01
item_objectcomponents_weapon_misc_2h_fishingpole_a_01
item_objectcomponents_weapon_misc_2h_harpoon_b_01
item_objectcomponents_weapon_misc_2h_pitchfork_a_01
item_objectcomponents_weapon_misc_2h_shovel_a_01

item_objectcomponents_weapon_stave_2h_ahnqiraj_d_01
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_02
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_03
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_04
item_objectcomponents_weapon_stave_2h_blackwing_a_01
item_objectcomponents_weapon_stave_2h_blackwing_a_02
item_objectcomponents_weapon_stave_2h_epic_a_01
item_objectcomponents_weapon_stave_2h_flaming_d_01
item_objectcomponents_weapon_stave_2h_jeweled_a_01
item_objectcomponents_weapon_stave_2h_jeweled_a_02
item_objectcomponents_weapon_stave_2h_jeweled_a_03
item_objectcomponents_weapon_stave_2h_jeweled_b_01
item_objectcomponents_weapon_stave_2h_jeweled_b_02
item_objectcomponents_weapon_stave_2h_jeweled_c_01
item_objectcomponents_weapon_stave_2h_jeweled_d_01
item_objectcomponents_weapon_stave_2h_long_a_01
item_objectcomponents_weapon_stave_2h_long_a_02
item_objectcomponents_weapon_stave_2h_long_a_03
item_objectcomponents_weapon_stave_2h_long_a_04
item_objectcomponents_weapon_stave_2h_long_b_01
item_objectcomponents_weapon_stave_2h_long_b_02holy
item_objectcomponents_weapon_stave_2h_long_b_03
item_objectcomponents_weapon_stave_2h_long_b_04
item_objectcomponents_weapon_stave_2h_long_c_01
item_objectcomponents_weapon_stave_2h_long_c_02
item_objectcomponents_weapon_stave_2h_long_d_01
item_objectcomponents_weapon_stave_2h_long_d_05
item_objectcomponents_weapon_stave_2h_long_epicpriest01
item_objectcomponents_weapon_stave_2h_long_epicpriest02
item_objectcomponents_weapon_stave_2h_medivh_d_01
item_objectcomponents_weapon_stave_2h_other_a_01
item_objectcomponents_weapon_stave_2h_other_b_01
item_objectcomponents_weapon_stave_2h_other_c_01
item_objectcomponents_weapon_stave_2h_other_c_02
item_objectcomponents_weapon_stave_2h_other_d_01
item_objectcomponents_weapon_stave_2h_pvpalliance_a_01
item_objectcomponents_weapon_stave_2h_pvphorde_a_01
item_objectcomponents_weapon_stave_2h_scythe_c_03
item_objectcomponents_weapon_stave_2h_stratholme_d_01
item_objectcomponents_weapon_stave_2h_stratholme_d_02
item_objectcomponents_weapon_stave_2h_stratholme_d_03
item_objectcomponents_weapon_stave_2h_zulgurub_d_01
item_objectcomponents_weapon_stave_2h_zulgurub_d_02
item_objectcomponents_weapon_stave_2h_zulgurub_d_03

===== Herbs added into database as items:
>>> some added into testing area in main map
world_skillactivated_tradeskillnodes_bush_ancientlichen
world_skillactivated_tradeskillnodes_bush_arthastears
world_skillactivated_tradeskillnodes_bush_azsharasveil
world_skillactivated_tradeskillnodes_bush_blacklotus
world_skillactivated_tradeskillnodes_bush_blindweed
world_skillactivated_tradeskillnodes_bush_bloodthistle
world_skillactivated_tradeskillnodes_bush_bruiseweed01
world_skillactivated_tradeskillnodes_bush_chameleonlotus
world_skillactivated_tradeskillnodes_bush_cinderbloom
world_skillactivated_tradeskillnodes_bush_constrictorgrass
world_skillactivated_tradeskillnodes_bush_crownroyal01
world_skillactivated_tradeskillnodes_bush_dragonsteeth
world_skillactivated_tradeskillnodes_bush_dreamfoil
world_skillactivated_tradeskillnodes_bush_dreamingglory
world_skillactivated_tradeskillnodes_bush_evergreenmoss
world_skillactivated_tradeskillnodes_bush_fadeleaf01
world_skillactivated_tradeskillnodes_bush_felweed
world_skillactivated_tradeskillnodes_bush_firebloom
world_skillactivated_tradeskillnodes_bush_fireweed
world_skillactivated_tradeskillnodes_bush_flamecap
world_skillactivated_tradeskillnodes_bush_foolscap
world_skillactivated_tradeskillnodes_bush_frostlotus
world_skillactivated_tradeskillnodes_bush_frostweed
world_skillactivated_tradeskillnodes_bush_frozenherb
world_skillactivated_tradeskillnodes_bush_goldclover
world_skillactivated_tradeskillnodes_bush_goldenlotus
world_skillactivated_tradeskillnodes_bush_gravemoss01
world_skillactivated_tradeskillnodes_bush_gromsblood
world_skillactivated_tradeskillnodes_bush_heartblossom
world_skillactivated_tradeskillnodes_bush_icecap
world_skillactivated_tradeskillnodes_bush_jadetealeaf
world_skillactivated_tradeskillnodes_bush_khadgarswhisker01
world_skillactivated_tradeskillnodes_bush_magebloom01
world_skillactivated_tradeskillnodes_bush_manathistle
world_skillactivated_tradeskillnodes_bush_mountainsilversage
world_skillactivated_tradeskillnodes_bush_mushroom03
world_skillactivated_tradeskillnodes_bush_mushroom02
world_skillactivated_tradeskillnodes_bush_mushroom01
world_skillactivated_tradeskillnodes_bush_netherbloom
world_skillactivated_tradeskillnodes_bush_nightmarevine
world_skillactivated_tradeskillnodes_bush_peacebloom01
world_skillactivated_tradeskillnodes_bush_plaguebloom
world_skillactivated_tradeskillnodes_bush_purplelotus
world_skillactivated_tradeskillnodes_bush_ragveil
world_skillactivated_tradeskillnodes_bush_rainpoppy
world_skillactivated_tradeskillnodes_bush_sansam
world_skillactivated_tradeskillnodes_bush_shaherb
world_skillactivated_tradeskillnodes_bush_silkweed
world_skillactivated_tradeskillnodes_bush_silverleaf01
world_skillactivated_tradeskillnodes_bush_snowlily
world_skillactivated_tradeskillnodes_bush_spineleaf
world_skillactivated_tradeskillnodes_bush_stardust
world_skillactivated_tradeskillnodes_bush_starflower
world_skillactivated_tradeskillnodes_bush_steelbloom01
world_skillactivated_tradeskillnodes_bush_stormvine
world_skillactivated_tradeskillnodes_bush_stormvinebubbles
world_skillactivated_tradeskillnodes_bush_stranglekelp01
world_skillactivated_tradeskillnodes_bush_sungrass
world_skillactivated_tradeskillnodes_bush_swiftthistle01
world_skillactivated_tradeskillnodes_bush_taladororchid
world_skillactivated_tradeskillnodes_bush_talandrasrose
world_skillactivated_tradeskillnodes_bush_goldthorn01
world_skillactivated_tradeskillnodes_bush_icethorn
world_skillactivated_tradeskillnodes_bush_terrocone
world_skillactivated_tradeskillnodes_bush_tigerlily
world_skillactivated_tradeskillnodes_bush_twilightjasmine
world_skillactivated_tradeskillnodes_bush_whiptail01
world_skillactivated_tradeskillnodes_bush_whispervine
world_skillactivated_tradeskillnodes_bush_wintersbite01
world_skillactivated_tradeskillnodes_stranglekelp_01
world_skillactivated_tradeskillnodes_bush_liferoot01
world_skillactivated_tradeskillnodes_bush_snakeroot
world_skillactivated_tradeskillnodes_bush_thornroot01



=================================================================================================================================================
18.3.2026 - List of Actions:

ItemManager GUI / SQL Database
- Problem: Items couldn't be equipped in DEquipment slots
  Fix: DEquipment Export fixed slot definitions

- Cleave Stat Text - FIXED

- Probem: Healing potions couldn't be right-clicked to use
  Root Causes:
    actively_used = FALSE (WC3 requires TRUE for usable items)
    is_perishable = FALSE and max_charges = NULL (needed for consumables)

  Fixes Applied:

    Set actively_used = TRUE for all potions (7 items updated)
    Set is_perishable = TRUE (item disappears when charges used)
    Set max_charges = 1 for single-use consumables

UnitStats.j
- API for DInventory "UnitStats_RecalculateHero(u)"
- UnitStats clears all tracking and recalculates from hero's remaining abilities

DInventory.j
- Added optional UnitStats to library requirements (won't fail if UnitStats not present)
- Added call to UnitStats_RecalculateHero(u) in ItemPickedUpActions() function
- Triggers after StoreItemForPIDBID() completes (item stored in DInventory)
- Only calls for hero units to avoid unnecessary processing

DEquipment Export from ItemManager:
- DEquipmentItemDefinitions_20260318-1814

Re-imported W3T export from ItemManager
- ItemData_20260318_181431.w3t

Terranining
- Sirensong

Debug Spellpower Flat
- chat command "spelldmg" / "debugstats"

QuestGiver.j
- debug set to FALSE


=================================================================================================================================================
17.3.2026 - List of Actions:

Note Merge Items:
- Last version before merge items from ItemManager/PotS SQL Database: Epic Quests-2026-03-18-0203.zip
- Merged Item Data from ItemManager (Epic Quests-2026-03-18-0218-ItemsMerged.zip)

Trailer2 added
- fast trailer to showcase some latest areas
- use chat command " trailer2 " to play it


ItemManager GUI / SQL Database
- w3t importer works more better
- w3t exporter works more better
- many other minor improvements to e.g., default item model path / cooldown group / wc3 classification by default
- drop-down-menu to select model attachment ability for the item
- StatsMapper updated to work with with more wider stats abilities range

UnitStats
- updated to include SpellPowerFlat

New stats abilities created + export W3A file "POTS_AbilitySettings-2026-03-17-2331.w3a"

HP REGEN % (hp_regen_pct) - Health % regeneration per second:
A09Q +10.0 HP%/sec
A09R +5.0 HP%/sec
A09S +2.5 HP%/sec
A09T +1.0 HP%/sec
A09U +0.5 HP%/sec
A09V +0.1 HP%/sec

MANA REGEN % (mp_regen) - Mana % regeneration per second:
A09W +10.0 MP%/sec
A09X +5.0 MP%/sec
A09Y +2.5 MP%/sec
A09Z +1.0 MP%/sec
A0A0 +0.5 MP%/sec
A0A1 +0.1 MP%/sec

MELEE DAMAGE (melee_dmg) - Flat melee damage bonus:
A0AO +100 melee_dmg
A0AP +50 melee_dmg
A0AQ +25 melee_dmg
A0AR +10 melee_dmg
A0AS +5 melee_dmg
A0AT +1 melee_dmg

MELEE DAMAGE % (melee_dmg_pct) - Percentage melee damage:
A0AU +50% melee_dmg_pct
A0AV +25% melee_dmg_pct
A0AW +10% melee_dmg_pct
A0AX +5% melee_dmg_pct
A0AY +2% melee_dmg_pct
A0AZ +1% melee_dmg_pct


RANGED DAMAGE (ranged_dmg) - Flat ranged damage bonus:
A0A2 +100 ranged_dmg
A0A3 +50 ranged_dmg
A0A4 +25 ranged_dmg
A0A5 +10 ranged_dmg
A0A6 +5 ranged_dmg
A0A7 +1 ranged_dmg

RANGED DAMAGE % (ranged_dmg_pct) - Percentage ranged damage:
A0A8 +50% ranged_dmg_pct
A0A9 +25% ranged_dmg_pct
A0AA +10% ranged_dmg_pct
A0AB +5% ranged_dmg_pct
A0AC +2% ranged_dmg_pct
A0AD +1% ranged_dmg_pct

CLEAVE % (cleave_pct) - Cleave damage percentage:
A0AE +50% cleave_pct
A0AF +25% cleave_pct
A0AG +10% cleave_pct
A0AH +5% cleave_pct
A0AI +2% cleave_pct
A0AJ +1% cleave_pct

CLEAVE AREA (cleave_area) - Cleave attack radius:
A0AK +300 cleave_area
A0AL +200 cleave_area
A0AM +100 cleave_area
A0AN +50 cleave_area

LIFESTEAL (lifesteal) - Lifesteal percentage:
A0B0 +50% lifesteal
A0B1 +25% lifesteal
A0B2 +10% lifesteal
A0B3 +5% lifesteal
A0B4 +2% lifesteal
A0B5 +1% lifesteal

THORNS (thorns_flat) - Return damage on hit (flat):
A0B6 +100 thorns_flat
A0B7 +50 thorns_flat
A0B8 +25 thorns_flat
A0B9 +10 thorns_flat
A0BA +5 thorns_flat

THORNS % (thorns_pct) - Return damage percentage:
A0BZ +50% thorns_pct
A0C0 +25% thorns_pct
A0C1 +10% thorns_pct
A0C2 +5% thorns_pct
A0C3 +2% thorns_pct
A0C4 +1% thorns_pct

ARMOR % (armor_pct) - Armor percentage bonus:
A0BH +50% armor_pct
A0BI +25% armor_pct
A0BJ +10% armor_pct
A0BK +5% armor_pct
A0BL +2% armor_pct
A0BM +1% armor_pct

MAGIC DAMAGE TAKEN (magic_dmg_taken) - Magic damage reduction:
A0BN -50% magic_dmg_taken
A0BO -25% magic_dmg_taken
A0BP -10% magic_dmg_taken
A0BQ -5% magic_dmg_taken
A0BR -2% magic_dmg_taken
A0BS -1% magic_dmg_taken
A0BT +50% magic_dmg_taken
A0BU +25% magic_dmg_taken
A0BV +10% magic_dmg_taken
A0BW +5% magic_dmg_taken
A0BX +2% magic_dmg_taken
A0BY +1% magic_dmg_taken

MELEE DAMAGE TAKEN (melee_dmg_taken) - Melee damage reduction:
A0BB -50% melee_dmg_taken
A0BC -25% melee_dmg_taken
A0BD -10% melee_dmg_taken
A0BE -5% melee_dmg_taken
A0BF -2% melee_dmg_taken
A0BG -1% melee_dmg_taken
A0C5 +50% melee_dmg_taken
A0C6 +25% melee_dmg_taken
A0C7 +10% melee_dmg_taken
A0C8 +5% melee_dmg_taken
A0C9 +2% melee_dmg_taken
A0CA +1% melee_dmg_taken

PIERCE DAMAGE TAKEN (pierce_dmg_taken)) - Melee damage reduction:
A09E -50% pierce_dmg_taken
A09F -25% pierce_dmg_taken
A09G -10% pierce_dmg_taken
A09H -5% pierce_dmg_taken
A09I -2% pierce_dmg_taken
A09J -1% pierce_dmg_taken
A09K +50% pierce_dmg_taken
A09L +25% pierce_dmg_taken
A09M +10% pierce_dmg_taken
A09N +5% pierce_dmg_taken
A09O +2% pierce_dmg_taken
A09P +1% pierce_dmg_taken

MOVEMENT SPEED BONUS (ms_bonus) - Movement speed bonus (already created - just slight naming fixes):
A08B +1 ms_bonus
A08C +2 ms_bonus
A08D +3 ms_bonus
A08E +4 ms_bonus
A08F +5 ms_bonus
A08G +10 ms_bonus
A08H +20 ms_bonus
A08I +30 ms_bonus
A08J +40 ms_bonus
A08K +50 ms_bonus

MOVEMENT SPEED % (ms_pct) - Movement speed percentage:
A092 +50% ms_pct
A093 +25% ms_pct
A094 +10% ms_pct
A095 +5% ms_pct
A096 +2% ms_pct
A097 +1% ms_pct
A098 -50% ms_pct
A099 -25% ms_pct
A09A -10% ms_pct
A09B -5% ms_pct
A09C -2% ms_pct
A09D -1% ms_pct

SPELL POWER % (spell_power_pct) - Spell power percentage (check that StatsMapper correctly maps to percentage bonus):
A01E +100% spell_power_pct
A01D +90% spell_power_pct
A01C +75% spell_power_pct
A01B +60% spell_power_pct
A01A +50% spell_power_pct
A019 +40% spell_power_pct
A018 +35% spell_power_pct
A6F6 +30% spell_power_pct
A6F5 +25% spell_power_pct
A6F4 +20% spell_power_pct
A6F3 +15% spell_power_pct
A6F2 +10% spell_power_pct
A6F1 +5% spell_power_pct
A06P +4% spell_power_pct
A06O +3% spell_power_pct
A06N +2% spell_power_pct
A06M +1% spell_power_pct

SPELL POWER FLAT BONUS (spell_power_flat_bonus) - Spell power flat bonus (chech that StatsMapper correctly maps flat bonus):
A091 +300 spell_power_flat_bonus
A08V +100 spell_power_flat_bonus
A08W +50 spell_power_flat_bonus
A08X +25 spell_power_flat_bonus
A08Y +10 spell_power_flat_bonus
A08Z +5 spell_power_flat_bonus
A090 +1 spell_power_flat_bonus


=================================================================================================================================================
16.3.2026 - List of Actions:

Note Merge Items:
- Last version before merge items from ItemManager/PotS SQL Database: Epic Quests-2026-03-16-2308

ItemManager GUI / SQL Database
- continue improving
- bug fixes
- Greatest challenge remains;
>> More stats abilities and system to handle giving relevant stats to unit based on what stats abilities he has
>> Note that some stats abilities increment/decrement e.g., Stat_Crit[custom value of unit]
>> And some stat abilities add ability to unit and change its value
>> See SharedDInvLibrary how it handles this in DEquipment system (separate system handling DInventory and DEquipment item stats)

UnitStats
- added new stats abilities
- added to handle vanilla inventory custom stats abilities for heroes picking/dropping items
- Now should co-exist as parallel system with DEquipment & DInventory system

New stats abilities created;
A06M (1% Spell)
A06N (2% Spell)
A06O (3% Spell)
A06P (4% Spell)

A06X (Strength bonus 1)
A06Y (Strength bonus 3)
A06Z (Strength bonus 4)
A070 (Strength bonus 5)
A071 (Strength bonus 6)
A072 (Strength bonus 7)
A073 (Strength bonus 9)

A06Q (Agility bonus 1)
A06R (Agility bonus 3)
A06S (Agility bonus 4)
A06T (Agility bonus 5)
A06U (Agility bonus 6)
A06V (Agility bonus 7)
A06W (Agility bonus 9)

A074 (Intelligence bonus 1)
A075 (Intelligence bonus 3)
A076 (Intelligence bonus 4)
A077 (Intelligence bonus 5)
A078 (Intelligence bonus 6)
A079 (Intelligence bonus 7)
A07A (Intelligence bonus 9)

A07K (Life bonus 1)
A07J (Life bonus 5)
A07I (Life bonus 10)
A66A (Life bonus 25)
A643 (Life bonus 50)
A63E (Life bonus 100)
A63Y (Life bonus 150)
A63Z (Life bonus 200)
A6D8 (Life bonus 250)
A641 (Life bonus 500)
A642 (Life bonus 1000)


A07B (Mana bonus 1)
A07C (Mana bonus 5)
A07D (Mana bonus 10)
A07E (Mana bonus 25)
A644 (Mana bonus 50)
A07F (Mana bonus 100)
A64U (Mana bonus 150)
A07G (Mana bonus 200)
A645 (Mana bonus 250)
A646 (Mana bonus 500)
A07H (Mana bonus 1000)

A07L (Damage bonus 1)
A07M (Damage bonus 2)
A07N (Damage bonus 3)
A07O (Damage bonus 4)
A07P (Damage bonus 5)
A07Q (Damage bonus 10)
A07R (Damage bonus 15)
A07S (Damage bonus 20)
A07T (Damage bonus 30)
A07U (Damage bonus 40)
A07V (Damage bonus 50)
A07W (Damage bonus 100)
A07X (Damage bonus 200)
A07Y (Damage bonus 500)

A07Z (armor bonus 1)
A080 (armor bonus 2)
A081 (armor bonus 3)
A082 (armor bonus 4)
A083 (armor bonus 5)
A084 (armor bonus 10)
A085 (armor bonus 15)
A086 (armor bonus 20)
A087 (armor bonus 30)
A088 (armor bonus 40)
A089 (armor bonus 50)
A08A (armor bonus 100)

A08L (attack speed bonus 0.01)
A08M (attack speed bonus 0.02)
A08N (attack speed bonus 0.03)
A08O (attack speed bonus 0.04)
A08P (attack speed bonus 0.05)
A08Q (attack speed bonus 0.1)
A08R (attack speed bonus 0.2)
A08S (attack speed bonus 0.3)
A08T (attack speed bonus 0.4)
A08U (attack speed bonus 0.5)

A08B (movement speed bonus 0.01)
A08C (movement speed bonus 0.02)
A08D (movement speed bonus 0.03)
A08E (movement speed bonus 0.04)
A08F (movement speed bonus 0.05)
A08G (movement speed bonus 0.1)
A08H (movement speed bonus 0.2)
A08I (movement speed bonus 0.3)
A08J (movement speed bonus 0.4)
A08K (movement speed bonus 0.5)


A64J (1% block chance)
A64T (100% block chance)
A64K (2% block chance)
A64L (3% block chance)
A64M (4% block chance)
A64N (5% block chance)

A64E (1% crit chance)
A64F (2% crit chance)
A64G (3% crit chance)
A64H (4% crit chance)
A64I (5% crit chance)

A64O (1% dodge chance)
A64P (2% dodge chance)
A64Q (3% dodge chance)
A64R (4% dodge chance)
A64S (5% dodge chance)

A649 (1% hit chance)
A64A (2% hit chance)
A64C (3% hit chance)
A64D (4% hit chance)
A64B (5% hit chance)

Old stats abilities linked to database/UnitStats;
=================================================================================================================================================
15.3.2026 - List of Actions:

ItemManager GUI / SQL Database
- many improvements (huge list so i dont list them here)


=================================================================================================================================================
12.3.2026 - List of Actions:

Imported models from UTM 4.0:
BlueLight
bush2
Cloudx-blend
Glow
TerrainGlow
TerrainGlow2
Ufergras

Imported models from Hive:
IcyMist2
CloudOfFog
>>> implement to object editor

Testing moving clouds for later clouds system modification:
debug cloudunit
>>> idea test good and should be implemented as special effect

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ItemManager GUI:

Implemented Features (shit ton):

1. DataGrid Enhancements:
✓ Column sorting (click headers)
✓ Column resizing with persistence (MainFormSettings.ini)
✓ Right-click context menu (Edit, Duplicate, Delete, Copy Code, Batch Delete)
✓ Double-click to edit (already existed)
✓ Multi-select enabled (Ctrl+Click, Shift+Click)

2. Advanced Filters:
✓ Multi-field search (Name, Code, Description, Abilities)
✓ Collapsible advanced panel ("▼ Advanced" button)
✓ Cost range filters (min/max)
✓ "Has Abilities" checkbox
✓ "Has Stats" checkbox
✓ "✖ Clear All" button

3. Item Preview Panel:
✓ Split-view layout (resizable)
✓ WC3-style tooltip rendering with rarity colors
✓ Icon preview placeholder with rarity-colored border
✓ Updates on selection change

4. Copy/Duplicate:
✓ Duplicate item functionality with auto-code generation
✓ Copy item code to clipboard

5. Smart Assistance:
✓ Duplicate name detection
✓ Missing data alerts (icon, model, tooltip)
✓ Balance suggestions (price vs level)
✓ Code format validation
✓ Basic spell checking

6. Visual Enhancements:
✓ Rarity-colored borders and text
✓ Styled DataGrid (blue headers, alternating rows)
✓ Color-coded buttons
✓ Modern flat design

Button Added: Export DEquipment (appears when connected)

Orange button on main toolbar
Exports to: .j JASS library format
Auto-generates: Equipment slots, stats, gold costs, abilities
Smart detection: Recognizes slots from item class (Head Armor → "Head" slot)
Full integration: Created Python exporter script (export_dequipment_cli.py)

Checkbox Added: Show WC3 Colors

Currently triggers data refresh
Preview panel (right side) already shows WC3 colors with rarity-based formatting

Automatic Rarity Color Codes for Item Names:

In the Database: Item names are now stored WITH WC3 hex color codes (e.g., |c00FF8000Legendary Sword|r)

In the GUI: Names are displayed WITHOUT color codes for easy editing and viewing

Color Codes by Rarity:

Common: |c00FFFFFF (White)
Uncommon: |c001EFF00 (Green)
Rare: |c000070DD (Blue)
Epic: |c00A335EE (Purple)
Legendary: |c00FF8000 (Orange)
How It Works:

When Loading Items: Color codes are automatically stripped from item_name using regex, so the edit fields show clean text
When Saving Items: The clean name is automatically wrapped with the appropriate color code based on the selected rarity
MainForm DataGrid: Also strips color codes for clean display in the item list
Tooltips & Previews: Continue to render the colors properly using the existing WC3 color rendering system
The system is fully automatic - users just type the item name normally, select a rarity, and the color codes are added behind the scenes when saving to the database!


Icon Selector Implementation
New Files Created:

IconPathConfig.cs - Configuration manager for icon paths

Stores paths for Blizzard WC3 icons and custom icons
Saves/loads from IconPathConfig.ini
Resolves icon paths automatically
Scans directories for BLP, TGA, PNG, JPG files
IconSelectorDialog.cs - Grid view icon selector dialog

Search and filter by name/source (Blizzard/Custom)
Grid layout showing up to 500 icons
Click to select, double-click to confirm
Configuration button to set icon paths
Supports PNG/JPG preview (BLP/TGA show placeholders)
Updated Features:

ItemEditForm:

Added "🔍 Browse Icons" button next to Icon Path field
Opens icon selector dialog when clicked
Selected icon path is populated into the text field
MainForm:

Updated SQL query to include icon_path column
Preview panel now loads and displays item icons
Supports PNG/JPG formats (BLP/TGA show colored placeholders)
Icons scale to fit 64x64 preview area
Rarity-colored borders when icon is missing
Configuration:

Default Blizzard path: C:\Program Files (x86)\Warcraft III\UI\
Default Custom path: .\CustomIcons\
Users can configure paths via "⚙ Configure Paths" button in icon selector
Settings persisted in IconPathConfig.ini
Usage:

Open item editor or create new item
Click "Browse Icons" button in WC3 Properties tab
Search/filter icons from configured directories
Click icon to select, double-click or press Select button
Icon path is saved relative to configured directories
Icons display in preview panel (larger) when item is selected in main grid

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

=================================================================================================================================================
11.3.2026 - List of Actions:

Terraining;
- Vanguard Vale
- Havenwoods
- Stormhaven surroundings
- Deadwoods

Imported more models (Credits Talavaj)
HFMBush_CoveA
HFMBush_CoveADEAD
HFMBush_ValeA
HFMBush_ValeADEAD
HFMC0Tree_Autumnal
HFMC0Tree_Lush
HFMC0Tree_Vermilion
HFMCBush_Autumnal
HFMCBush_Umbra
HFMCBush_Vermilion
HFMCGrass_Vermilion
HFMCTree_Autumnal
HFMCTree_Lush
HFMCTree_Vermilion
HFMFlowers_CoveA
HFMFlowers_ValeA
HFMLog_Fallen
HFMLog_Stump
HFMShrub_ValeA
HFMShrub_ValeB
HFMShrub_ValeC
HFMTree_CoveA
HFMTree_CoveADEAD
HFMTree_CoveB
HFMTree_CoveBDEAD
HFMTree_CoveC
HFMTree_CoveCDEAD
HFMTree_ValeA
HFMTree_ValeADEAD
HFMTree_ValeC
HFMTree_ValeCDEAD

SQL database
- continued work
- now seems to work pretty well
- import/export scripts seem to work

GUI application for item management;
- created application for more convenient item creation/modification/view, ....
- idea is to use this as master to create/generate items

=================================================================================================================================================
10.3.2026 - List of Actions:

SQL database
- started creating database mainly to create/import/export/manage POTS items
- created using POSTGRESQL
- can import .w3t file and migrate/update to SQL database
- export function to WC3 WE not tested
- issues... as always - could work...
- tables need editing
>>> not all item_types defined / incorrect
>>> item_classes seem to be define the "chest", "head" etc. armor types

=================================================================================================================================================
1.3.2026 - List of Actions:

ZonesCore
- z.Data; added rect definitions: startRegion, moveRegion, exitRegion

ZoneEvent
- Added MoveIn (used by HandleZoneLeave)
- Added MoveOut (used by HandleZoneEnter)
- Added RegisterZoneExitRegions (used to register exit region triggers per zone)
- updated HandleZoneEnter to handle moving the units if that is defined by the zone (ZonesCore zone definitions)
- updated HandleZoneLeave to handle moving the units if that is defined by the zone (ZonesCore zone definitions)

Terraining
- caves
- setting up regions (enter/exit/move,...)

Shield attachment testin
- added more shields to testing area to analyze Nazgrek shield attachment problem



=================================================================================================================================================
28.2.2026 - List of Actions:

Nazgrek model notes:
- previously some time ago fixed model of Nazgrek is in wrong path (war3mapImported/)
>>> remove it from there, only one "nazgrek.mdx" file be in map
- fixed cape texture issues - was using twosided option in material
- cape style "blend" or "transparent" should be checked -> now selection circle is shown through it and maybe other stuff...
>>> Filter mode set to "none"
- testing editing Nazgrek Hand Right/Left Ref attachement points
>>> RESULT: now 1H/2H weapons are off and also the edit went somehow wrongly to shields (Retera studio attachement point dont match - maybe the follow some bone logic etc...)
>>> Testing addind custom "Shield" attachment point to Nazgrek
>>>>> Result: didn't work???

Terraining;
- Wyrmhold Sanctum
- Mini dungeons / caves

ZonesCore
- set z.weatherAllowed = false -> For all dungeons
- edited fog settings for most dungeons
- edited Wyrmhold Sanctum (zone icon, texts)
- Emberpeak Highlands DNC to "Outdoors Mountains"
- More dungeons to be added to ZonesCore (Some are meant to be multipurposed)

>>> cave04
>>>>>>> use case 1: Cinderfall (Emberpeak Highlands)

>>> Cave06
>>>>>>> use case 1: Wolf Den (Sereneglade)
>>>>>>> use case 2: Shadowmaw Cave (Sirensong,Mal'kiri panther)

>>> Dragoncave01
>>>>>>> use case 1: Kobold Mine (Sereneglade

>>> boreanmagnataurmicro
>>>>>>> use case 1: Blazehollow (in Dragonfire Peaks)

>>> hellfirecave (not placed on maps properly)
>>>>>>> use case: Dustfire Cave (Emberpeak Highlands)

>>> ragefire_micro
>>>>>>> use case: Dreadforge

>>> Cellar
>>>>>>> use case 1: Riverbane Inn Cellar
>>>>>>> use case 2: Havenwoods Inn
>>>>>>> use case 3: Stormhaven Inn

>>> Inn / Tavern
>>>>>>> use case 1: Riverbane Inn
>>>>>>> use case 2: Havenwoods Inn
>>>>>>> use case 3: Stormhaven Inn

Inn - RiverbaneInn
Inn - HavenwoodsInn
Inn - StormhavenInn
Cave - Cinderfall
Cave - Wolf Den
Cave - Shadowmaw Cave
Cave - Kobold Mine
Cave - Blazehollow
Cave - Dustfire Cave


DNC
- updated DNC_Firelands to change DNC model
- added DNC_OutdoorsMountains (to be used by Emperpeak Highlands)

ZoneEvent
- Added API call to DNC_OutdoorsMountains





=================================================================================================================================================
27.2.2026 - List of Actions:

- shield test item created (right corner of map)
>>> if ok --> need to do same bone node position edit
>>> note shield attachement was not with the shield models but with nazgrek.mdx model itself (WowConverter issue setting up correct attachement point)

- terraining; cavemicro / drafting for Fel orc / Demon lair boss



=================================================================================================================================================
26.2.2026 - List of Actions:

WeatherSystemv3_maybeWorkingVersion (dont ask...)
- private boolean FPS_CloudsDisabled          => set to true  // Disable clouds for FPS
- private boolean FPS_RipplesDisabled         => set to true  // Disable ripples for FPS
>>> These are temporarily disabled, we need to implement them properly / different way (at least clouds, rippes itself doesn't even seem finished)

DNC
- added DNC_Death1

ZonesCore
- Deadwoods to use DNC_Deat1

ZoneEvent
- updated RunDNC to include DNC_Death1

Note about libraries;
- As some time has passed between development of these libraries (some issues/bugs when last visiting them), 
- it is not clear whether the MAIN map has the latest libraries using same as in TEST map


Skybox testing vol66.6
Via testing with debug commands:
- debug skybox death1 -> to test skybox when all hero players are dead
>>> very good, use for Deadwoods, and when all hero players are dead
- debug skybox death2 -> to test skybox when all hero players are dead
>>> looks good, use e.g., for Emberpeak Highlands
- debug skybox sethral -> random skybox test
>>> looks ok, for dungeon usage - although definitely needs good FOG setting
- debug skybox strat -> random skybox test
>>> Looks ok for fiery place, but has problem with scale maybe... COMPARE to Lordaeron SkyRed
- debug skybox voidsky01 -> random skybox test, maybe for Void related quests
>>>
- debug skybox darkportal -> random skybox test
>>> looks good, suitable for Felfire Bastion area
- debug skybox volcanos -> random skybox test
>>> TO BE REMOVED - does not work good as it is
- debug skybox ruby -> random skybox test
>>> Not remove, very suitable for Vanguard Vale
- debug skybox cavemicro -> random skybox test, for dungeons?
>>> not so good, could be removed?

Other Skybox:
>>> Firelands used skybox looks bad
>>> battleskyboxdirty looks bad

Skyboxes that look promising (even with compressed quality):
- sethral => For Gnoll hideout
- cavemicro => For cave dungeons
- ruby => for Elarindor
- death1 => for when all player heros dead
- ... there were maybe others but texture compression affected the "review"


Added test items for Shields (to see if conversion from WoW worked);
item_objectcomponents_shield_buckler_damaged_a_01
item_objectcomponents_shield_buckler_damaged_a_02
item_objectcomponents_shield_buckler_oval_a_01
item_objectcomponents_shield_buckler_round_a_01
item_objectcomponents_shield_shield_ahnqiraj_d_01

Terraining;
- Havenwoods (dwarven area - modified from murloc area)
- Firelands; red visual blockers and fire testing, very draft still and needs in-game checks
- Sirensong; very small terraining
- Stormhaven; testing adding wall related entrance to the city (staircase, might need less pitch....)

Re-import textures for following skyboxes:1) Make list of all skyboxes (before Folder26 texture update)
1) Make list of all skyboxes (before Folder26 texture update)
war3campImported\\SummerSphereCT2.mdx
	Environment\Sky\LordaeronSummerSky\LordaeronSummerSky.blp (INGAME TEXTURE)
	Textures\cloudstile1.blp
	Textures\cloudstile2.blp
	UI\Glues\SinglePlayer\Orc_Exp\Stars3.blp
	UI\Glues\SinglePlayer\Orc_Exp\moon.blp
	Textures\Flare.blp
	Textures\sun.blp
	Textures\star4.blp
	Textures\Star8.blp
	Textures\Star7b.blp

environments_stars_skywallskybox.mdx
	wow/environments/stars/skwall_skybox_topsky.blp
	wow/environments/stars/skwall_skybox_mist.blp
	wow/environments/stars/skwall_skybox_frontbottom.blp
	wow/environments/stars/skwall_skybox_front.blp
	wow/environments/stars/skwall_skybox_backsky.blp
	wow/environments/stars/skwall_skybox_bottom.blp
	wow/environments/stars/skwall_skybox_back.blp

environments_stars_battlefield_dirty_skybox.mdx
	wow/environments/stars/battlefield_edgesky01.blp
	wow/environments/stars/battlefieldcloudsorange2.blp
	wow/environments/stars/battlefield_dirty_edgeclouds02.blp

war3mapImported\\LordaeronWinterSkyRedCustom.mdx
	Environment\Sky\LordaeronWinterSkyRed\Custom\LordaeronWinterSkyRed.blp

environments_stars_firelandssky01.mdx
	wow/environments/stars/firelandssky_foglayer.blp
	wow/environments/stars/firelandsskyclouds02.blp
	wow/environments/stars/firelandsskyhotspot01.blp
	wow/environments/stars/firelandsskyclouds01.blp
	wow/environments/stars/firelandsskyhorizon01.blp

2) Made list of all new skyboxes
- only handful re-imported
- 95% of them are 3-20mb files
3) Re-imported original textures of these skyboxes



>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Created and imported "visual blockers":
visual\VisualBlocker_black.mdx
visual\VisualBlocker_blue.mdx
visual\VisualBlocker_darkgrey.mdx
visual\VisualBlocker_grey.mdx
visual\VisualBlocker_lightblack.mdx
visual\VisualBlocker_lightwhite.mdx
visual\VisualBlocker_red.mdx

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ITEM Models (Vanilla classic) imported from WoW:
- Shields
- Staves
- Misc_1h
- Misc_2h

item_objectcomponents_shield_buckler_damaged_a_01
item_objectcomponents_shield_buckler_damaged_a_02
item_objectcomponents_shield_buckler_oval_a_01
item_objectcomponents_shield_buckler_round_a_01
item_objectcomponents_shield_shield_ahnqiraj_d_01
>>>> Up-to-this point created test items 

item_objectcomponents_shield_shield_ahnqiraj_d_02
item_objectcomponents_shield_shield_ahnqiraj_d_03
item_objectcomponents_shield_shield_blackwing_drakeadon
item_objectcomponents_shield_shield_blackwing_reddragon
item_objectcomponents_shield_shield_crest_a_01
item_objectcomponents_shield_shield_crest_a_02
item_objectcomponents_shield_shield_crest_b_01
item_objectcomponents_shield_shield_crest_b_02
item_objectcomponents_shield_shield_crest_b_03
item_objectcomponents_shield_shield_engineer_a_01
item_objectcomponents_shield_shield_engineer_b_01
item_objectcomponents_shield_shield_engineer_c_01
item_objectcomponents_shield_shield_epic_a_01
item_objectcomponents_shield_shield_epic_b_01
item_objectcomponents_shield_shield_horde_a_01
item_objectcomponents_shield_shield_horde_a_02
item_objectcomponents_shield_shield_horde_a_03
item_objectcomponents_shield_shield_horde_a_04
item_objectcomponents_shield_shield_horde_b_01
item_objectcomponents_shield_shield_horde_b_02
item_objectcomponents_shield_shield_horde_b_03
item_objectcomponents_shield_shield_horde_b_04
item_objectcomponents_shield_shield_horde_c_02
item_objectcomponents_shield_shield_horde_c_03
item_objectcomponents_shield_shield_lion_a_01
item_objectcomponents_shield_shield_militia_a_01
item_objectcomponents_shield_shield_naxxramas_d_01
item_objectcomponents_shield_shield_naxxramas_d_02
item_objectcomponents_shield_shield_naxxramas_d_03
item_objectcomponents_shield_shield_oval_a_01
item_objectcomponents_shield_shield_pvpalliance_a_01
item_objectcomponents_shield_shield_pvphorde_a_01
item_objectcomponents_shield_shield_rectangle_a_01
item_objectcomponents_shield_shield_rectangle_b_01
item_objectcomponents_shield_shield_round_a_01
item_objectcomponents_shield_shield_round_b_01
item_objectcomponents_shield_shield_stratholme_d_01
item_objectcomponents_shield_shield_stratholme_d_02
item_objectcomponents_shield_shield_wheel_b_01
item_objectcomponents_shield_shield_zulgurub_d_01
item_objectcomponents_shield_shield_zulgurub_d_02

item_objectcomponents_weapon_misc_1h_bone_a_01
item_objectcomponents_weapon_misc_1h_book_a_01
item_objectcomponents_weapon_misc_1h_book_b_01
item_objectcomponents_weapon_misc_1h_book_b_02
item_objectcomponents_weapon_misc_1h_book_c_01
item_objectcomponents_weapon_misc_1h_book_c_02
item_objectcomponents_weapon_misc_1h_bottle_a_01
item_objectcomponents_weapon_misc_1h_bottle_a_02
item_objectcomponents_weapon_misc_1h_bread_a_01
item_objectcomponents_weapon_misc_1h_bread_a_02
item_objectcomponents_weapon_misc_1h_bucket_a_01
item_objectcomponents_weapon_misc_1h_fish_a_01
item_objectcomponents_weapon_misc_1h_flower_a_01
item_objectcomponents_weapon_misc_1h_flower_a_02
item_objectcomponents_weapon_misc_1h_flower_a_03
item_objectcomponents_weapon_misc_1h_flower_a_04
item_objectcomponents_weapon_misc_1h_flower_b_01
item_objectcomponents_weapon_misc_1h_flower_b_02
item_objectcomponents_weapon_misc_1h_gizmo_a_01
item_objectcomponents_weapon_misc_1h_glass_a_01
item_objectcomponents_weapon_misc_1h_glass_a_02
item_objectcomponents_weapon_misc_1h_holysymbol_a_01
item_objectcomponents_weapon_misc_1h_lantern_a_01
item_objectcomponents_weapon_misc_1h_lantern_b_01
item_objectcomponents_weapon_misc_1h_mutton_a_01
item_objectcomponents_weapon_misc_1h_mutton_a_02
item_objectcomponents_weapon_misc_1h_mutton_b_01
item_objectcomponents_weapon_misc_1h_mutton_b_02
item_objectcomponents_weapon_misc_1h_orb_a_01
item_objectcomponents_weapon_misc_1h_orb_a_02
item_objectcomponents_weapon_misc_1h_orb_c_01
item_objectcomponents_weapon_misc_1h_potion_a_01
item_objectcomponents_weapon_misc_1h_potion_b_01
item_objectcomponents_weapon_misc_1h_random
item_objectcomponents_weapon_misc_1h_rollingpin_a_01
item_objectcomponents_weapon_misc_1h_seal_a_01
item_objectcomponents_weapon_misc_1h_seal_b_01
item_objectcomponents_weapon_misc_1h_seal_c_01
item_objectcomponents_weapon_misc_1h_skull_b_01
item_objectcomponents_weapon_misc_1h_sparkler_a_01blue
item_objectcomponents_weapon_misc_1h_sparkler_a_01red
item_objectcomponents_weapon_misc_1h_sparkler_a_01white
item_objectcomponents_weapon_misc_1h_tankard_a_01
item_objectcomponents_weapon_misc_1h_waterwand_a_01
item_objectcomponents_weapon_misc_1h_wrench_a_01

item_objectcomponents_weapon_misc_2h_broom_a_01
item_objectcomponents_weapon_misc_2h_fishingpole_a_01
item_objectcomponents_weapon_misc_2h_harpoon_b_01
item_objectcomponents_weapon_misc_2h_pitchfork_a_01
item_objectcomponents_weapon_misc_2h_shovel_a_01

item_objectcomponents_weapon_stave_2h_ahnqiraj_d_01
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_02
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_03
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_04
item_objectcomponents_weapon_stave_2h_blackwing_a_01
item_objectcomponents_weapon_stave_2h_blackwing_a_02
item_objectcomponents_weapon_stave_2h_epic_a_01
item_objectcomponents_weapon_stave_2h_flaming_d_01
item_objectcomponents_weapon_stave_2h_jeweled_a_01
item_objectcomponents_weapon_stave_2h_jeweled_a_02
item_objectcomponents_weapon_stave_2h_jeweled_a_03
item_objectcomponents_weapon_stave_2h_jeweled_b_01
item_objectcomponents_weapon_stave_2h_jeweled_b_02
item_objectcomponents_weapon_stave_2h_jeweled_c_01
item_objectcomponents_weapon_stave_2h_jeweled_d_01
item_objectcomponents_weapon_stave_2h_long_a_01
item_objectcomponents_weapon_stave_2h_long_a_02
item_objectcomponents_weapon_stave_2h_long_a_03
item_objectcomponents_weapon_stave_2h_long_a_04
item_objectcomponents_weapon_stave_2h_long_b_01
item_objectcomponents_weapon_stave_2h_long_b_02holy
item_objectcomponents_weapon_stave_2h_long_b_03
item_objectcomponents_weapon_stave_2h_long_b_04
item_objectcomponents_weapon_stave_2h_long_c_01
item_objectcomponents_weapon_stave_2h_long_c_02
item_objectcomponents_weapon_stave_2h_long_d_01
item_objectcomponents_weapon_stave_2h_long_d_05
item_objectcomponents_weapon_stave_2h_long_epicpriest01
item_objectcomponents_weapon_stave_2h_long_epicpriest02
item_objectcomponents_weapon_stave_2h_medivh_d_01
item_objectcomponents_weapon_stave_2h_other_a_01
item_objectcomponents_weapon_stave_2h_other_b_01
item_objectcomponents_weapon_stave_2h_other_c_01
item_objectcomponents_weapon_stave_2h_other_c_02
item_objectcomponents_weapon_stave_2h_other_d_01
item_objectcomponents_weapon_stave_2h_pvpalliance_a_01
item_objectcomponents_weapon_stave_2h_pvphorde_a_01
item_objectcomponents_weapon_stave_2h_scythe_c_03
item_objectcomponents_weapon_stave_2h_stratholme_d_01
item_objectcomponents_weapon_stave_2h_stratholme_d_02
item_objectcomponents_weapon_stave_2h_stratholme_d_03
item_objectcomponents_weapon_stave_2h_zulgurub_d_01
item_objectcomponents_weapon_stave_2h_zulgurub_d_02
item_objectcomponents_weapon_stave_2h_zulgurub_d_03

=================================================================================================================================================
25.2.2026 - List of Actions:

Crit note:
- skybox texture quality got really horrible after compression with BLP Lab!
- this may effect already previously imported models!
- may need re-import skybox textures!
- Check older versions from EpicQuestsFolder28 or 27 etc. maybe 26? older can do as well...


Added debug commands:
- debug blackmask1 -> to test whether we could use black mask to hide unwanted visibility of areas
>>> Didnt do shit
- debug skybox death1 -> to test skybox when all hero players are dead
- debug skybox death2 -> to test skybox when all hero players are dead
- debug skybox sethral -> random skybox test
- debug skybox strat -> random skybox test
- debug skybox voidsky01 -> random skybox test, maybe for Void related quests
- debug skybox darkportal -> random skybox test
- debug skybox volcanos -> random skybox test
- debug skybox ruby -> random skybox test
- debug skybox cavemicro -> random skybox test, for dungeons?

Skyboxes that look promising (even with compressed quality):
- sethral => For Gnoll hideout
- cavemicro => For cave dungeons
- ruby => for Elarindor
- death1 => for when all player heros dead
- ... there were maybe others but texture compression affected the "review"





Re-edited (maybe this time?) models causing lag in-game and in WE (at least for AMD GPU/CPU randomly):
md_cryptsimpleent2.mdx

>>> Will many re-checks (different PC shutdown / WC3 / WE starts) to evaluate is the lag gone, because sometimes before there was no lag, and other WE map loading there was lag


Check for crypt models:
world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo 
>>> not used (older model?)

world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e2.wmo
>>> OK no lag
world_wmo_dungeon_md_crypt_md_cryptsimpleent_md_cryptsimpleent_md.wmo
>>> OK no lag
world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo
>>> causes lag
md_cryptsimpleent2
>>> causes lag


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ENVIRONMENTAL / PROPS Models imported from WoW:
environments_stars_8des_sethralisssky04
environments_stars_deathclouds
environments_stars_deathskybox__e38898f61f50c7ebf4f12515f3390ceb
environments_stars_lostislevocanoskybox
environments_stars_rubysanctumsky
environments_stars_shadowmoonburialgrounds_voidsky01
environments_stars_stratholmeskybox
environments_stars_tanaan_darkportal_front_sky01
environments_stars_tanaan_patch_infernalball_01
world_azeroth_karazahn_activedoodads_karazahn_chessroomdoors
world_azeroth_karazahn_activedoodads_karazahn_secretroomdoor
world_expansion02_doodads_scholazar_waterfalls_sholazarsouthoceanwaterfall-06
world_expansion03_doodads_firelands_ragnaros_firewall_ragnaros_firewall
world_expansion03_doodads_grimbatolraid_grimbatolraid_fire_wall_01
world_expansion03_doodads_grimbatolraid_grimbatolraid_fire_wall_02
world_expansion05_doodads_fx_6fx_firewall_door
world_expansion05_doodads_fx_6fx_firewall_door_sm
world_expansion05_doodads_fx_6fx_firewall_doorfel
world_expansion05_doodads_fx_6fx_firewall_doorsmfel
world_expansion05_doodads_nagrand_doodads_6ng_burningblade_micro_lavafall01
world_expansion07_doodads_fx_8fx_firewall_door
world_expansion07_doodads_fx_8fx_firewall_door_small
world_kalimdor_hyjal_passivedoodads_fire_hyjal_red_wall_fire_01
world_wmo_brokenisles_7xp_karazhanroom01
world_wmo_dungeon_hellfire_hellfire_wall01.wmo__57d3e71d89d4fa666f61b1738d82091f
world_wmo_dungeon_hellfire_hellfire_wall02.wmo__28a564e9bc7e0d778a9c8386f1c56422
world_wmo_dungeon_hellfire_hellfire_wall03.wmo__584af82697e25625678c8f680bbfe170
world_wmo_dungeon_hellfire_hellfire_wall04.wmo__c84087523ed30450ba8d3a4bdd5b6940
environments_stars_8des_cavemicrosky01

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BUILDING / INTERIOR Models imported from WoW:
world_expansion01_doodads_pvp_activedoodads_doors_pvp_ogre_door_interior
world_expansion01_doodads_pvp_activedoodads_doors_pvp_orc_door_interior
world_wmo_brokenisles_vrykul_7vr_vrykul_dwellingmedium01_interior
world_wmo_dungeon_boreanmagnataurmicro_boreanmagnataurmicro_1room
world_wmo_kalimdor_buildings_orctower_abandonedorctower
world_wmo_kalimdor_buildings_orctower_abandonedorctower_alt
world_wmo_khazmodan_buildings_dwarven_tavern_wetlands_tavern_wet_tavern
world_wmo_northrend_buildings_human_nd_human_inn_nd_human_inn
world_wmo_pandaria_jadeforest_orcrefuge_orcrefugetent


Terraining;
- Minizones (minimap rooms) added, located near Firelands
- Firelands zone desperately needs visual barricades to block view outside Firelands and especially seeing these minizone rooms/caves, whatever



=================================================================================================================================================
24.2.2026 - List of Actions:


Todo;
- Check minizones / subzones draft locations in-game (Firelands refactored area)
- Crypt are lag caused by "crypt" models;
>>> Extends and whatever most likely broken as Crypt related doodads could be accidently clicked far away from the model (collision boxes reaching far)
>>> Need to make necessary fixes in Retera Studio (or are there already fixed models because something was done before in Retera related to extends / geosets, etc.)

Zone ideas:
- murloc are near orcs to be smaller and add goblin area there (draft building remarking the spot)

Terraining:
- Dragonpeak Mountains / Wyrmhold Sanctum layout drafting
- Thornwoods; Check what thorns / roots work best for Thornwoods "look"

>>>>>> Many exported models made into doodads;

world_kalimdor_mulgore_passivedoodads_thorns_mullgorethornspike
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn07
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn06
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn05
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn04
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn03
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn02
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn01
world_outland_passivedoodads_thorns_outlandthorn07
world_outland_passivedoodads_thorns_outlandthorn06
world_outland_passivedoodads_thorns_outlandthorn05
world_outland_passivedoodads_thorns_outlandthorn04
world_outland_passivedoodads_thorns_outlandthorn03
world_outland_passivedoodads_thorns_outlandthorn02
world_outland_passivedoodads_thorns_outlandthorn01__61d808f48932cb35e09b4aa787da4c40
world_outland_passivedoodads_roots_outlandroot03
world_outland_passivedoodads_roots_outlandroot02
world_outland_passivedoodads_roots_outlandroot01

Added many models into doodad objects (from latest exports)
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash01
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash02
world_expansion02_doodads_generic_scourge_icecrown_stairs01
world_expansion02_doodads_generic_scourge_sc_stairs2
world_expansion03_doodads_firelands_towerflame_firelands_towerflame01

world_wmo_brokenisles_araknashal_7an_dragoncave01
world_wmo_brokenisles_araknashal_7an_dragoncave02
world_wmo_brokenisles_araknashal_7an_dragoncave03
world_wmo_brokenisles_azsuna_7az_sinkhole_cave01
world_wmo_brokenisles_legion_7lg_legion_cave01
world_wmo_brokenisles_legion_7lg_legion_cave02
world_wmo_brokenisles_legion_7lg_legion_cave03
world_wmo_brokenisles_legion_7lg_legion_cave04
world_wmo_brokenisles_legion_7lg_legion_cave05
world_wmo_brokenisles_legion_7lg_legion_cave06
world_wmo_scenario_ragefire_ragefire_micro

>>>> Maybe modify into smaller models?
world_wmo_brokenisles_legion_7lg_legion_cave01
world_wmo_brokenisles_legion_7lg_legion_cave05 ???? not working?


=================================================================================================================================================
23.2.2026 - List of Actions:

Fixed following models:
world_wmo_dungeon_kl_orgrimmarlavadungeon_lavadungeon
world_wmo_scenario_ragefire_ragefire_micro

Some terraining
- e.g., Dragon boss area drafting


=================================================================================================================================================
22.2.2026 - List of Actions:

Requirements_DialogSystemPlan
- added ESC key function (configurability)
- dialog outcomes / flows / paths

Other:
- Testing compressing textures which hugely reduces the overall map size

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Models imported from WoW:
world_wmo_brokenisles_valsharah_7vs_gilneas_building01
world_wmo_brokenisles_valsharah_7vs_gilneas_building02
world_wmo_brokenisles_valsharah_7vs_gilneas_building03
world_wmo_brokenisles_valsharah_7vs_gilneas_building04
world_wmo_brokenisles_valsharah_7vs_gilneas_building05
world_wmo_brokenisles_valsharah_7vs_gilneas_building06
world_wmo_brokenisles_valsharah_7vs_gilneas_building07
world_wmo_brokenisles_valsharah_7vs_gilneas_building08
world_wmo_brokenisles_valsharah_7vs_gilneas_building09
world_wmo_brokenisles_valsharah_7vs_gilneas_building10
world_expansion07_doodads_barbarianzone_8dru_fallingleaves_b01
world_expansion05_doodads_nagrand_doodads_6ng_fallingleaves_arid01
world_expansion03_doodads_gilneas_trees_fallingoakleaves01
world_expansion03_doodads_gilneas_trees_fallingoakleaves02
world_expansion03_doodads_gilneas_detaildoodads_gnleaves01
world_expansion03_doodads_gilneas_detaildoodads_gnleaves02
world_expansion03_doodads_gilneas_detaildoodads_gnleaves03
world_expansion03_doodads_gilneas_trees_oaktree01
world_expansion03_doodads_gilneas_trees_oaktree02
world_expansion03_doodads_gilneas_trees_oaktree03
world_expansion03_doodads_gilneas_trees_oaktree04
world_expansion03_doodads_gilneas_trees_oaktree05
world_expansion03_doodads_gilneas_trees_oaktreeroot01
world_expansion03_doodads_gilneas_trees_oaktreeroot02
world_expansion03_doodads_gilneas_trees_oaktreeroot03
world_expansion03_doodads_gilneas_trees_oaktreeroot04

creature_worgen_worgen

>>> The following are to be used for Alchemy / Herbalism / Mining
world_skillactivated_tradeskillnodes_ancientgem_miningnode_01
world_skillactivated_tradeskillnodes_incendicite_miningnode_01
world_skillactivated_tradeskillnodes_mithril_miningnode_01
world_skillactivated_tradeskillnodes_tin_miningnode_01
world_skillactivated_tradeskillnodes_truesilver_miningnode_01
world_skillactivated_tradeskillnodes_feliron_miningnode_01
world_skillactivated_tradeskillnodes_bush_ancientlichen
world_skillactivated_tradeskillnodes_bush_arthastears
world_skillactivated_tradeskillnodes_bush_azsharasveil
world_skillactivated_tradeskillnodes_bush_blacklotus
world_skillactivated_tradeskillnodes_bush_blindweed
world_skillactivated_tradeskillnodes_bush_bloodthistle
world_skillactivated_tradeskillnodes_bush_bruiseweed01
world_skillactivated_tradeskillnodes_bush_chameleonlotus
world_skillactivated_tradeskillnodes_bush_cinderbloom
world_skillactivated_tradeskillnodes_bush_constrictorgrass
world_skillactivated_tradeskillnodes_bush_crownroyal01
world_skillactivated_tradeskillnodes_bush_dragonsteeth
world_skillactivated_tradeskillnodes_bush_dreamfoil
world_skillactivated_tradeskillnodes_bush_dreamingglory
world_skillactivated_tradeskillnodes_bush_evergreenmoss
world_skillactivated_tradeskillnodes_bush_fadeleaf01
world_skillactivated_tradeskillnodes_bush_felweed
world_skillactivated_tradeskillnodes_bush_firebloom
world_skillactivated_tradeskillnodes_bush_fireweed
world_skillactivated_tradeskillnodes_bush_flamecap
world_skillactivated_tradeskillnodes_bush_foolscap
world_skillactivated_tradeskillnodes_bush_frostlotus
world_skillactivated_tradeskillnodes_bush_frostweed
world_skillactivated_tradeskillnodes_bush_frozenherb
world_skillactivated_tradeskillnodes_bush_goldclover
world_skillactivated_tradeskillnodes_bush_goldenlotus
world_skillactivated_tradeskillnodes_bush_gravemoss01
world_skillactivated_tradeskillnodes_bush_gromsblood
world_skillactivated_tradeskillnodes_bush_heartblossom
world_skillactivated_tradeskillnodes_bush_icecap
world_skillactivated_tradeskillnodes_bush_jadetealeaf
world_skillactivated_tradeskillnodes_bush_khadgarswhisker01
world_skillactivated_tradeskillnodes_bush_magebloom01
world_skillactivated_tradeskillnodes_bush_manathistle
world_skillactivated_tradeskillnodes_bush_mountainsilversage
world_skillactivated_tradeskillnodes_bush_mushroom03
world_skillactivated_tradeskillnodes_bush_mushroom02
world_skillactivated_tradeskillnodes_bush_mushroom01
world_skillactivated_tradeskillnodes_bush_netherbloom
world_skillactivated_tradeskillnodes_bush_nightmarevine
world_skillactivated_tradeskillnodes_bush_peacebloom01
world_skillactivated_tradeskillnodes_bush_plaguebloom
world_skillactivated_tradeskillnodes_bush_purplelotus
world_skillactivated_tradeskillnodes_bush_ragveil
world_skillactivated_tradeskillnodes_bush_rainpoppy
world_skillactivated_tradeskillnodes_bush_sansam
world_skillactivated_tradeskillnodes_bush_shaherb
world_skillactivated_tradeskillnodes_bush_silkweed
world_skillactivated_tradeskillnodes_bush_silverleaf01
world_skillactivated_tradeskillnodes_bush_snowlily
world_skillactivated_tradeskillnodes_bush_spineleaf
world_skillactivated_tradeskillnodes_bush_stardust
world_skillactivated_tradeskillnodes_bush_starflower
world_skillactivated_tradeskillnodes_bush_steelbloom01
world_skillactivated_tradeskillnodes_bush_stormvine
world_skillactivated_tradeskillnodes_bush_stormvinebubbles
world_skillactivated_tradeskillnodes_bush_stranglekelp01
world_skillactivated_tradeskillnodes_bush_sungrass
world_skillactivated_tradeskillnodes_bush_swiftthistle01
world_skillactivated_tradeskillnodes_bush_taladororchid
world_skillactivated_tradeskillnodes_bush_talandrasrose
world_skillactivated_tradeskillnodes_bush_goldthorn01
world_skillactivated_tradeskillnodes_bush_icethorn
world_skillactivated_tradeskillnodes_bush_terrocone
world_skillactivated_tradeskillnodes_bush_tigerlily
world_skillactivated_tradeskillnodes_bush_twilightjasmine
world_skillactivated_tradeskillnodes_bush_whiptail01
world_skillactivated_tradeskillnodes_bush_whispervine
world_skillactivated_tradeskillnodes_bush_wintersbite01
world_skillactivated_tradeskillnodes_stranglekelp_01
world_skillactivated_tradeskillnodes_bush_liferoot01
world_skillactivated_tradeskillnodes_bush_snakeroot
world_skillactivated_tradeskillnodes_bush_thornroot01

>>> Many of these intended for Thornwoods
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethornspike
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn07
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn06
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn05
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn04
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn03
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn02
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn01
world_outland_passivedoodads_thorns_outlandthorn07
world_outland_passivedoodads_thorns_outlandthorn06
world_outland_passivedoodads_thorns_outlandthorn05
world_outland_passivedoodads_thorns_outlandthorn04
world_outland_passivedoodads_thorns_outlandthorn03
world_outland_passivedoodads_thorns_outlandthorn02
world_outland_passivedoodads_thorns_outlandthorn01__61d808f48932cb35e09b4aa787da4c40
world_wmo_azeroth_buildings_stranglethorn_bootybay_bootybay_railing
world_wmo_azeroth_buildings_stranglethorn_bootybay_bootybay_house2
world_wmo_azeroth_buildings_stranglethorn_bootybay_bootybay_house1
world_kalimdor_kalidar_passivedoodads_kalidarroots_kalidarroots03
world_kalimdor_kalidar_passivedoodads_kalidarroots_kalidarroots02
world_kalimdor_kalidar_passivedoodads_kalidarroots_kalidarroots01
world_outland_passivedoodads_roots_outlandroot03
world_outland_passivedoodads_roots_outlandroot02
world_outland_passivedoodads_roots_outlandroot01
world_generic_quilboar_passive doodads_thorncanopies_thorncanopy_03
world_generic_quilboar_passive doodads_thorncanopies_thorncanopy_02
world_generic_quilboar_passive doodads_thorncanopies_thorncanopy_01

creature_northrendworgen_northrendworgen

world_wmo_azeroth_buildings_gilneas_gilneas_marketquarter
world_wmo_brokenisles_valsharah_7vs_gilneas_town01

>>> Many of these are as inspiration for Firelands / Dragon Den dungeon:
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash01
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash02
world_expansion02_doodads_generic_scourge_icecrown_stairs01
world_expansion02_doodads_generic_scourge_sc_stairs2
world_expansion03_doodads_firelands_towerflame_firelands_towerflame01
world_expansion03_doodads_grimbatol_lava_grimbatol_cave_lavafalls_01
world_expansion03_doodads_grimbatol_lava_grimbatol_cave_lavafalls_02
world_generic_human_passive doodads_woodenstairs_woodenstairs01
world_generic_human_passive doodads_woodenstairs_woodenstairs02
world_wmo_azeroth_buildings_gilneas_gilneas_cellar_1
world_wmo_azeroth_buildings_gilneas_gilneas_manor
world_wmo_azeroth_buildings_stormwind_sw_staircase
world_wmo_brokenisles_araknashal_7an_dragoncave01
world_wmo_brokenisles_araknashal_7an_dragoncave02
world_wmo_brokenisles_araknashal_7an_dragoncave03
world_wmo_brokenisles_azsuna_7az_sinkhole_cave01
world_wmo_brokenisles_legion_7lg_legion_cave01
world_wmo_brokenisles_legion_7lg_legion_cave02
world_wmo_brokenisles_legion_7lg_legion_cave03
world_wmo_brokenisles_legion_7lg_legion_cave04
world_wmo_brokenisles_legion_7lg_legion_cave05
world_wmo_brokenisles_legion_7lg_legion_cave06
world_wmo_brokenisles_valsharah_7vs_cavemicro01
world_wmo_dungeon_kl_orgrimmarlavadungeon_lavadungeon
world_wmo_hozu_huts_hz_mountaincaveclosed2.wmo__8dde19c967e0ce85e82c43c76d0dc9b4
world_wmo_scenario_ragefire_ragefire_micro

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

>>> Terraining Havenwoods / Stormhaven outside area
>>> Terraining Emberpeark Highlands

=================================================================================================================================================
19.2.2026 - List of Actions:

Created requirements files to update DialogSystem, QuestGiver, QuestMaster;
- Requirements_DialogSystem.md
- Requirements_DialogSystemPlan.md
- Requirements.Quests.md

No changes yet to the systems themselves.


=================================================================================================================================================
15.2.2026 - List of Actions - CRASH debug log:
2/15 22:29:29.364  Opening map - C:/Users/Valtteri/Documents/Warcraft III/Maps/EpicQuests/Epic Quests.w3x
2/15 22:29:40.258  model creation failed - war3mapImported\Build.mdx
2/15 22:29:40.258  model creation failed - war3mapImported\DecayMesh.mdx
2/15 22:29:51.310  model creation failed - 
2/15 22:29:51.551  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.551  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.566  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.566  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.632  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.448  model creation failed - 
2/15 22:29:52.448  model creation failed - 
2/15 22:29:53.040  model creation failed - 
2/15 22:29:55.280  model creation failed - https://www.hiveworkshop.com/members/sarsaparilla.295950/
2/15 22:29:55.280  model creation failed - https://www.patreon.com/user?u=52986355
2/15 22:29:55.449  model creation failed - https://www.hiveworkshop.com/members/sarsaparilla.295950/
2/15 22:29:55.449  model creation failed - https://www.patreon.com/user?u=52986355
2/15 22:29:56.495  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 22:29:56.495  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//5) Error, string /SimpleInfoPanelTitleTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//11) Error, string /SimpleInfoPanelTitleTextDisabledTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//15) Error, string /SimpleInfoPanelDescriptionTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//21) Error, string /SimpleInfoPanelDescriptionHighlightTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//24) Error, string /SimpleInfoPanelDescriptionDisabledTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//28) Error, string /SimpleInfoPanelLabelTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//36) Error, string /SimpleInfoPanelLabelHighlightTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//39) Error, string /SimpleInfoPanelLabelDisabledTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//43) Error, string /SimpleInfoPanelValueTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//47) Error, string /SimpleInfoPanelObserverValueTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//56) Error, string /SimpleInfoPanelAttributeTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//62) Error, string /SimpleInfoPanelAttributeDisabledTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//66) Error, string /InfoPanelIconTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//72) Error, string /ResourceIconTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//77) Error, string /ResourceTextTemplate already exists!
2/15 22:40:30.014  model creation failed - 
2/15 22:41:20.749  model creation failed - 
2/15 22:41:26.785  model creation failed - 
2/15 22:41:32.808  model creation failed - 
2/15 22:42:16.784  model creation failed - 
2/15 22:42:34.872  model creation failed - 
2/15 22:42:46.923  model creation failed - 
2/15 22:44:10.165  model creation failed - 
2/15 22:45:04.344  model creation failed - 
2/15 22:46:58.625  model creation failed - 
2/15 22:47:12.396  model creation failed - 
2/15 22:47:16.925  model creation failed - 
2/15 22:47:25.549  model creation failed - 
2/15 22:47:30.871  model creation failed - 
2/15 22:47:49.387  model creation failed - 
2/15 22:47:51.257  model creation failed - 
2/15 22:48:01.450  model creation failed - 
2/15 22:48:03.384  model creation failed - 
2/15 22:48:18.864  model creation failed - 
2/15 22:48:23.055  model creation failed - 
2/15 22:48:27.659  model creation failed - 
2/15 22:48:33.735  model creation failed - 
2/15 22:48:35.253  model creation failed - 
2/15 22:48:51.943  model creation failed - 
2/15 22:49:19.927  model creation failed - 
2/15 22:49:38.220  model creation failed - 
2/15 22:50:08.617  prism: Error Invalid (0x80070057): pm_dx11::Device::CreateBuffer: CreateBuffer Failed
2/15 22:50:42.670  model creation failed - 
2/15 22:51:12.729  model creation failed - 
2/15 22:51:24.947  model creation failed - 
2/15 22:51:46.694  model creation failed - 


=================================================================================================================================================
15.2.2026 - List of Actions:

Terraining
- Vanguard Vale
- Verdant Plains
- Havenwoods / Stormhaven

Continued coding libraries for following:
- QuestMaster
- QuestGiver
- qAradion

Changes to above;
- Support messages for Return to questGiver / questReceiver
- Quest map icon / effect on questgiver/receiver unit is updated delayed same as with the quest messages for more synchronized visuality
- When creating quests in qSublibrary; If the quest giver and quest receiver are the same unit (like Aradion), you only need to call setReceiverDisplayName(giverName).

------------------------------------------------------------------ Main map todos;
Note: if any updates later in test map, copy updated scripts to main map!

- Create Folder Quests (-----> DONE)
- Create Folder QuestGivers (-----> DONE)
These from top onwards order;
- Create script QuestMaster and copy from VS Code  (-----> DONE)
- Create script DialogSystem and copy from VS Code  (-----> DONE)
- Create script QuestGiver and copy from VS Code   (-----> DONE)
- Create script qAradion and copy from VS Code (-----> DONE)

Old systems:
- Disable Triggers in Quest Handling System
>>> Rename the folder Quest Handling System OLD
- Disable script QuestIconSystem (-----> DONE)
- Disable script QuestEvaluationSystem (-----> DONE)
>>> Rename folder "Quest Icon System OLD" (-----> DONE)
>>> Rename folder "Quest Evaluation System OLD" (-----> DONE)
>>> disable "Call QuestEvaluateSystemInit()" in trigger Orc Cleanup (-----> DONE)

=========================
CRITICAL NOTE: if disabling old quest system related scripts and triggers, all other quest giver related triggers will fail to compile because they are heavily utilizing them!
=========================
CRITICAL NOTE2: The following quests / associated triggers are disabled/broken and yet to utilize new QuestSystems 

Whelps of Destruction
Dragon Egg Hunt
Desolator

Mistaken Kin

Token Love
Lost Supplies

Kaelthir Struggle
Kaelthir Hunger

Ogre Lost His Sandwitch
Kribugs Lost His Satchel
Ogre Is Very Thirsty
Meat For The Ogre
Angry Customers

Explosive Crisis
Boomsite Compliance
More Hazard Mitigation
Mandatory Training
Boom Will Be Back

Other:
BOSS Mad Blix dies - had call to QuestIcon system

=========================
CRITICAL NOTE 3: All other quest givers except Aradion and older (ancient) quest style npcs ARE NOW DISABLED
- meaning no dialogue/dialog/quests for these
- these are to be refactored into qQuestGiverName libraries!
=========================

Folder "Aradion the Farseer"
- set all triggers disabled - do not remove yet (-----> DONE)
- there are still some triggers we need to check like in the "Events" -folder

Later todos:
- No need for following variables (handled by DialogSystem)
>>> All variables in "DIALOGS" -folder
- All quest folders to be scrapped, but one by one - because we need to convert them to qSublibrary scripts

Update Following:
- SharedDInvLib (-----> DONE)
- HeroItemCheck (-----> DONE)
- Reputation (-----> DONE)
- CreepUnitAssignment (-----> DONE)

------------------------------------------------------------------


=================================================================================================================================================
14.2.2026 - List of Actions:

Reputation
- Changed the reputation tier constants from private to public so they can be accessed from other libraries
- Now accessible as Reputation_REP_ENEMY, Reputation_REP_HOSTILE, Reputation_REP_UNFRIENDLY, Reputation_REP_NEUTRAL, Reputation_REP_FRIENDLY, Reputation_REP_COVENANT, Reputation_REP_EXALTED

SharedDInvLib.j
- Updated function "GetDInvItemChargesByType" to also check vanilla inventory
- Critical for QuestGiver.j item gather progress function checks

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- QuestGiver
- QuestMaster
- qAradion

Updates to Quest Systems in short: 
- Support for separate QuestGiver and QuestReceiver NPCs
- added new quest types: TalkTo, FindNPC, GoToPlace, GetRep,Investigate
- The previously mentioned systems are becoming closer and closer to ready systems
- Escort quest type possibility added utilizing FollowSystem.j
- qAradion / qSublibrary should be more easier to copy-paste for other quest givers, there is still quite many manual work involved...
>>> Though it might not be wise to make qSubLibrary as generic as possible because we want to have control per qGiver
>>> Still need to check most generic uses and could those be implemented as functions inside QuestGiver or DialogSystem and in qSublibrary only minimial effort required, like change unit / durations, texts, etc.

Critical error;
- Game crashes randomly, the issue trying to get fixed by having safety checks on Quests Systems related libraries for edge-cases,
- but it is starting to look that the crash causer might be related to other systems than Quests system related
- Could be WeatherSystem or Zones related crash, but this is not known
- the crash/critical error is totally random

Some info from crash.txt / Error log: 2026-02-15 00.15.38 fa6fb12c
<Exception.Summary:>
ACCESS_VIOLATION (Failed to write address 0x0000000000000000 at instruction 0x00007FF6F7F67732) DBG-OPTIONS<FunctionsOnly SingleLine> DBG-ADDR<00007FF6F7F67732>("Warcraft III.exe") <- DBG-ADDR<0000029CEF6F9850>("") <- DBG-ADDR<0000029CEEBF7650>("")  DBG-OPTIONS<>
<:Exception.Summary>

Also these errors in War3Log.txt:
2/15 00:08:10.797  Opening map - C:/Users/Valtteri/AppData/Local/Temp/WorldEditTestMap.w3x
2/15 00:08:12.123  model creation failed - war3campImported\SummerSphereCT2.mdx
2/15 00:08:12.123  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:08:12.123  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:08:12.158  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 00:08:12.158  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 00:08:20.672  model creation failed - environments_stars_battlefield_dirty_skybox.mdx
2/15 00:08:20.672  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:08:20.672  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:45.973  model creation failed - war3campImported\SummerSphereCT2.mdx
2/15 00:13:45.973  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:45.973  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:56.652  model creation failed - environments_stars_battlefield_dirty_skybox.mdx
2/15 00:13:56.652  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:56.652  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:15:38.714  Played C:/Users/Valtteri/AppData/Local/Temp/WorldEditTestMap.w3x

>>> Fixed these errors for the testing map by importing them (they were missing...)
>>> Could most likely just been the causes of the random crashes



=================================================================================================================================================
13.2.2026 - List of Actions:

Imported following models from WoW:
world_expansion02_doodads_zuldrak_waterfalls_zuldrak_waterfalls_set1_high_ripples.mdx
world_expansion05_doodads_ashran_6as_a_graveyard_set_1.mdx
world_expansion06_doodads_suramar_7sr_dungeonwaterfall02.mdx
world_expansion07_doodads_dungeon_doodads_8du_cityofgoldwaterfall_01.mdx
world_expansion07_doodads_dungeon_doodads_8du_cityofgoldwaterfall_02.mdx
world_expansion07_doodads_zuldazarzone_8zul_cityofgoldwaterfall_b17.mdx

world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_01.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_02.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_03.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_04.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_05.mdx
world_expansion01_doodads_bladesedge_bush_bladesedgebush01.mdx
world_expansion01_doodads_bladesedge_bush_bladesedgebush02.mdx
world_expansion03_doodads_worgen_walls_worgen_citywall_01_broken.mdx
world_expansion06_doodads_7xp_fel_largerock_c01.mdx
world_expansion06_doodads_7xp_fel_largerock_c02.mdx
world_expansion06_doodads_7xp_fel_largerock_c03.mdx
world_expansion06_doodads_suramar_7sr_citygroundbush_a01.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter02.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter03.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter04.mdx
world_generic_human_passive doodads_stormwind_stormwindfountain_03.mdx
world_generic_human_passive doodads_stormwind_waterfalls_stormwind_waterfall_03.mdx
world_generic_human_passive doodads_vendorawnings_stormwindvendorawning01.mdx
world_wmo_brokenisles_fel_7xp_fel_largerock_c03.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b01.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b02.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b03.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b04.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b05.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b06.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b07.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b08.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b09_bone.mdx
world_wmo_lorderon_undercity_8xp_lordaeronboulderwmo.mdx

==> And some already placed on the map

Terraining
- Stormhaven / Havenwoods

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- DiagloSystemPlayer
- QuestGiver
- QuestMaster
- qAradion

==> Most notable updates/implementations regarding above; 
>>> Cinematic mode, mover, unit facing, head facing, quest messages correctly

=================================================================================================================================================
12.2.2026 - List of Actions:

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- DiagloSystemPlayer
- QuestGiver
- qAradion


=================================================================================================================================================
11.2.2026 - List of Actions:

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- DiagloSystemPlayer
- QuestGiver
- qAradion

List of todo / suggestion to qSublibrary (Aradion) to move generic functions elsewhere:
>>> GPT 5.2 Codex:
Here is a focused review of the generic-looking logic in qAradion that should move into a shared library (QuestGiver or DialogSystem) so qAradion only supplies content, flags, and minimal custom gating.

Generic helpers that can be centralized
Debug/logger wrapper and quest lookup are generic and not content-specific; GetQuest is unused. Consider moving to QuestGiver or removing. qAradion.j:62-74
Camera preset wrappers are generic and currently unused; either move to DialogSystem or remove. qAradion.j:85-92

Generic “sequence end” handlers
These all do the same sequence-close pattern (close dialog, cooldown, stop camera). That should be a reusable QuestGiver helper:
Info end/start flow. qAradion.j:95-107
Accept/fail/complete end handlers for quests 1–4. qAradion.j:200-420
Farewell end handler. qAradion.j:434-438

Generic accept/complete/farewell sequence scaffolding
Each accept sequence repeats: create sequence → set default speaker → set callbacks → add hero accept line → add NPC accept line → custom lines → play. This should be a QuestGiver helper that takes custom lines as input. qAradion.j:207-355 and qAradion.j:386-413
Farewell sequence is also boilerplate aside from the NPC text pool. qAradion.j:440-456

Generic dialog-building rules
BuildDialog is mostly state-driven button logic (accept/complete/fail). This is prime for a data-driven builder in QuestGiver, with qAradion only supplying per-quest button rules and a few custom conditions (e.g., RangerMissingReq1Complete, Valeria proximity). qAradion.j:466-540

Generic dialog show + selection gating
ShowDialog and OnSelected are standard flow control (selection gate, first greet, then normal greet, camera start). These should be in QuestGiver as a default selection handler with callbacks for greet sequences and dialog build. qAradion.j:542-587

Generic quest creation boilerplate
CreateQuests is almost entirely data setup; better as a QuestGiver “create from defs” helper (list of quest defs with id/title/icon/desc/reqs/etc). qAradion.j:590-643
Generic init/wait-for-udg flow

InitDelayed + Init are likely identical across quest givers; move to QuestGiver with a registration function that takes unit refs and a config struct. qAradion.j:645-669

What qAradion should keep (content/inputs only)
Quest definitions (ids, titles, icons, descriptions, requirements).
Text lines and sound ids for greet/backstory/accept/complete.
Custom gating flags like AradionBackstorySeen, RangerMissingReq1Complete, Valeria in range.
A small number of callbacks that supply “custom lines” into generic sequence builders.

Suggested QuestGiver abstractions
QuestGiver_HandleSequenceEnd(giver, cooldownTimer, cooldownSeconds, stopCamera, reopenDialog)
QuestGiver_PlayAcceptSequence(giver, heroOptions, onEnd, customLinesFn)
QuestGiver_PlayFarewellSequence(giver, heroOptions, onEnd)
QuestGiver_BuildDialogFromRules(giver, dialog, rules[])
QuestGiver_ShowDialog(giver, dialog, cameraConfig, greetFn)
QuestGiver_OnSelectedDefault(config) (handles selection gate, first greet, normal greet)
QuestGiver_CreateQuestsFromDefs(giver, defs[])
If you want, I can start by extracting the generic helpers into QuestGiver and refactor qAradion to only pass in definitions and custom lines.
>>>


=================================================================================================================================================
10.2.2026 - List of Actions:

DialogSystem
- Added full dialogue creation with sequence order etc. stuff - huge update
- added generic Greet, Farewell, Exit, Follow, Stop, etc. lines usage

DialogSystemNazgrek
- defined generic Nazgrek lines

QuestMaster
- some updates

QuestGiver
- some update

qAradion (sublibrary)
- editing to get the sublibrary as easy as possible to re-use for other qGivers

TODO

- Nazgrek (or Zulkis) play relevant generic lines to be added function calls to relevant places
- in cinematic,
- .... and more

(DONE - to be checked)
- DialogSystem
>>> - also play their action lines (like DialogSystem\_PlayAccept) for other buttons, Trade line are played when button "Trade" is pressed, Exit line is played when "Exit" button is played, Follow line are played when "Follow button is pressed, Stop line is played when "Stop" button is pressed, Decline is played when "Decline" button is pressed, Accept is played when quest accept button is pressed (e.g. Ranger Missing (Accept)), quest accept button always follows then qGiver built sequence for that quest accept 


=================================================================================================================================================
9.2.2026 - List of Actions:

QuestMaster
 - Added core quest-giver registry + availability evaluation to QuestMaster so all logic stays centralized, and exposed public APIs QuestGiver can call. Main changes are in QuestMaster.j (giver list storage, evaluation timer, requirement checks, event flags, and public register/query helpers).
- NOTE: Rewards missing
- NOTE 2: Icon not present

DialogSystem
- First version;
- lightweight dialog creation + button routing for quest givers.

QuestGiver
- Note: Dialogs not done / sublibrary

HeroItemCheck.j (DInv related helper functions)
- Wrapped in library

qAradion
- created first questGiver sublibrary
>>> need to analyze how well this sublibrary style can be "copy-pasted" for other questGivers - it looks very manual >>> re-occurring things should be easy to use or perhaps set in QuestGivers.j

======= key notes for qAradion.j
 	Built the qAradion quest giver library with quest creation, dialog gating, and button actions that mirror the OLDGUI logic, using QuestMaster/QuestGiver/DialogSystem and a selection 	trigger with cooldown. All logic lives in qAradion.j.

 	Key notes:

 	Item IDs are placeholders (ITEM_MANA_CRYSTAL, ITEM_WRAITH_ESSENCE, ITEM_TELANOR_ROD are set to 'I000').
 	Dialog/cinematic narrative lines from OLDGUI are not ported yet; only the structural flow and quest actions are in place.
 	Two public helpers exist for external progression signals: qAradion_SetBackstorySeen and qAradion_SetRangerMissingReq1Complete.
 	If you want me to continue, I can:
=================================

Note about Weather, ZonesCore, ZoneEvent;
- WeatherSystemv3_maybeWorkingVersion - is the current version (older version that worked, lol... some breaking stuff in new under "construction"

=================================================================================================================================================
7.2.2026 - List of Actions:
Terraining
- Stormhaven;
>>> Continue area construction
>>> Need some stairs to the walls...
- Havenwoods;
>>> Small terraining; e.g., destroyed human barracks near the human camp - this can be used either/and/or to quests helping humans discover who destroyed their barracks or as background that orcs OR ogres destroyed the barracks, ....

Quest Systems; QuestMaster.j
- Some development steps forwards slowly
- Here is some what has been done this day;
Added quest fields (requirements, faction/rep, failure text, reward item), reward text building, reward payout, and message helpers.
Added QuestMaster-owned icon logic (overhead effects + minimap pings) modeled after QuestIconSystem.
Added API functions for discover/fail/turn-in, requirement management, update/fail messages, templates, and TableV6-based save/load stubs.

Potential follow-ups:
>>> AddReputation and AddReputationLinked to be optional, add guards or hooks?
>>> different reward distribution targets (companions/group)?
>>> wire icon priority to per-giver lists and tighten quest log formatting (including requirement headings) to mirror OLDGUI output more closely?




=================================================================================================================================================
7.2.2026 - List of Actions:

Terraining
- Stormhaven;
>>> made the area large by removing waterside section
>>> could also remove the pathway from Redwind Pass to make the city or atleast the village area "larger"

Breaking changes incoming; Quests Systems huge overhaul
- Started creating new quest systems purely JASS based instead of current GUI triggers / JASS combinations
- This will reduce the amount of triggers by huge amount
- More detailed stuff is written to Requirements.md in Visual Code project folder




=================================================================================================================================================
4.2.2026 - List of Actions:

WeatherSystem
- refactored Stop weather related functions (confusing redundant functions)
>>> The stop logic has been refactored: StopRegionWeatherInternal now only stops weather for a single region, with all zone-wide stopping handled by StopZoneWeatherInternal. This prevents recursive start/stop conflicts and clarifies the API. Now can safely call StopZoneWeatherInternal(zoneIndex) to stop all weather in a zone, and StopRegionWeatherInternal(regionIndex) for single regions (if needed).
- root cause of multiple issues; RegisterAllZoneRects
>>> WeatherSystem expects to operate on its own RegionRect array, but the authoritative source of rects is ZonesCore.
>> If ZonesCore and WeatherSystem create rects separately, their handles will not match, causing failures in FindRegionIndex and incomplete weather stopping.
- Note: still issues with system and there are multiple coding practice failures / copy-paste from older systems / globals define twice etc
- Note 2!: revert to WeatherSystemv3_mayWorkingVersion.j




=================================================================================================================================================
1.2.2026 - List of Actions:

WeatherSystem
- index/registering debugging
- Now correctly sets the weather of zone to "none" when weather stops for that zone


ZonesCore
- Added API method to get list of registered weather and snow rects

Stormhaven terraining started
- issues; area too small



=================================================================================================================================================
24.1.2026 - List of Actions:

WeatherSystem
- Updated Storm/Thunder logic that was not sending random integer Variant properly
- added 50 % chance per timer interval to cause storm effect (might have to lower the chance)
- thunder/storm timer call back every 10s
- Snow should now spawn gradually in waves (waves and the amount spawned per waves defined in the constants further modified by the size of snowRects)

Storm
- back to using the original library with some modifications
- the other modified library was shittified
- trying get dynamic fog internal Storm functionality working but problem was that it alters the current weather fog and cant somehow restore it back to normal

FogSystem
- updated timer variable name...

ZonesCore
- added set method: SetWeatherState
- added get method: GetWeatherState
>>> Used to set weather state for checking the current weather by other systems

ZoneEvent
- modified ApplyFog (to use getWeatherState)
- modified ApplyCurrentZoneEffects

SnowSystem
- multiple changes / fixes to gradual destroy of snow
- now instead of destroying snow from last index to first, the snow is destroyed randomly and random amount of units depending on snow_light / snow_medium / snow_heavy

Testing related:
- import ubersplats file ZonesTest map OK
- import snow unit to ZonesTest map OK
- Import Ubersplat triggers OK
- Import frostbite (optionally)

TEMP: List of libraries to be updated to main map
subject to re-update!
- Storm 	OK
- FogSystem 	OK
- WeatherSystem OK
- zonesCore 	OK
- ZoneEvent  OK
- Snow	OK

============= ISSUES
ApplyCurrentZoneEffects / ApplyFog
- does not change the fog...
- ApplyCurrentZoneEffects return weather Heavy - while the weather should be already none
-something wrong getting the ZoneData / or retrieving the zone weatherState?
WeatherSystem: incorrectly sets the weatherState or something because it gets stuck in this mode / OR ApplyFog in ZoneEvent has some faulty logic
- incorrect indexing / ID wrong usage?
>>>>>> MOST CRITICAL ISSUE THAT MOST LIKELY BUGS OTHER ZONES AS WELL!

WeatherSystem
- despite StopZoneWeatherInternal
call z.SetWeatherState(WEATHER_NONE)
- it doesn't set the weather to "none" and ApplyFog applies the previously set WeatherState (heavy fog) after Storm


=================================================================================================================================================
23.1.2026 - List of Actions:

Terraining
- Verdant Plains
- Thornwoods
- Emberpeak Highlands

Imported new models (credits Lord of Souls)
Ashland Plants\imp\AshGrass.mdx
Ashland Plants\imp\AshGrass1.mdx
Ashland Plants\imp\AshYam.mdx
Ashland Plants\imp\FireFern1.mdx
Ashland Plants\imp\FireFern2.mdx
Ashland Plants\imp\Trama_Tree2.mdx
Ashland Plants\imp\Trama_Tree3.mdx
Ashland Plants\imp\Trama_Tree4.mdx
Ashland Plants\imp\TramaRoot1.mdx
Ashland Plants\imp\TramaRoot2.mdx
Ashland Plants\imp\TramaShrub.mdx
Ashland Plants\imp\TramaTree1.mdx



=================================================================================================================================================
22.1.2026 - List of Actions:

Working with these:
- ZonesCore
>>> Weather: Define weather/snow regions and chances under construction, ready zones:
>>>>> Twilight Grove
>>>>> Sereneglade
>>> Fog: adjust by testing good fog values for each zone (fogDay, fogNight, weather fogs; fogLight, fogMedium, fogHeavy)
- ZoneEvent (renamed from Zonesv2)
- WeatherSystemv3
- Storm (Storm still has issue - cant figure out how to restore from "black fog" DNC taken over)
>>> tried to add calls to  "call ZoneEvent\_ApplyCurrentZoneEffects()" and use DNC\_Storm - no results
- DNC


=================================================================================================================================================
20.1.2026 - List of Actions:

Breaking changes in short;
- ZonesCore (master library containg all zone data) - maybe rename to Zones
- Zonesv2 - handles now zone events but not configuration for zones - Maybe rename to ZoneEvent
- WeatherSystemv2 - refactored to use ZonesCore
==> All data is fetched from ZonesCore!

=================================================================================================================================================
19.1.2026 - List of Actions:

Zones
- DayNighEvent runs "Zones_ApplyCurrentZoneEffects" -function after 1s timer (vs. 0.5s) DNE_IsDaytime Boolean didn't update correctly with faster timer
>>> Note that the underlying issue is with DNE DayNightEvent events not always firing Day or Night especially when using cheat code to toggle DayNightEvent
>>> Now zone correctly applies night related settings (fogNight) when DayNightEvent occurs

DayNightEvent
- added timer to evaluate DNE_IsDaytime Boolean (if skips etc. occur) triggered by DayNightEvent

WeatherSystem
- now calls "Zones_ApplyCurrentZoneEffects()" from Zones library mainly to change the Fog effect to match with the weather
- Note: WeatherSystem cant call it "undeclared function" even though Zones library is above WeatherSystem and Zones requires WeatherSystem

WeatherShared -library created but unused
- WeatherSystem.j (to be set to require it)
- Zones.j (to be set to require it)
- Storm.j (to be set to require it)


=================================================================================================================================================
18.1.2026 - List of Actions:


FCL / FixedCameraLock
- function FCL_Lock: changed Y value of SetCameraTargetController from "200" back to "200"

FogSystem
- Refactored new library "FogSystem" from The_Flood (Flood @ hiveworkshop) system

Zones
- Added Debug message to display the fog values of the entered zone
>>> To be used to debug application of fog / FogSystem
- DNE_DayNightEvent's global variable udg_DNE_Daytime used to track whether it is day or night (previously was not correctly checked)
- Now should correctly work to apply different effects whether day or night


=================================================================================================================================================
17.1.2026 - List of Actions:

Zones
- Added icon paths in library to various zones

Imports
- various zone icons with path "zones\zone_xxx.blp"
- "Fish" by MiniMage (Fesh_Final.mdx)
- Sonya by Razorclaw_X / Blizzard Entertainment (Sonya.mdx)
- Gnoll Camp Doodads pack (or part of them) by RatzRatzzz:
10gl_gnoll_bag01.mdx
10gl_gnoll_bag02.mdx
10gl_gnoll_banner01.mdx
10gl_gnoll_barrel_large01.mdx
10gl_gnoll_barrel_large01_open01.mdx
10gl_gnoll_barrel01.mdx
10gl_gnoll_bed01.mdx
10gl_gnoll_bench01.mdx
10gl_gnoll_cage01.mdx
10gl_gnoll_cage02.mdx
10gl_gnoll_cage03.mdx
10gl_gnoll_cage04.mdx
10gl_gnoll_campfire02_off.mdx
10gl_gnoll_chair01.mdx
10gl_gnoll_crate02.mdx
10gl_gnoll_hangingtrinket02.mdx
10gl_gnoll_hangingtrinket03.mdx
10gl_gnoll_rope03.mdx
10gl_gnoll_ropecoil01.mdx
10gl_gnoll_ropecoil02.mdx
10gl_gnoll_spikes01.mdx
10gl_gnoll_spit01_boarroast01.mdx
10gl_gnoll_table01.mdx
10gl_gnoll_tent01.mdx
DoodadWeaponRackGnoll.mdx

Terraining;
- Havenwoods; Slight terraining at old forest troll area
- Thornwoods / Sereneglade gnoll camps terraining

Fixed model(s):
world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo (caused lag - huge box / extends)


=================================================================================================================================================
15.1.2026 - List of Actions:

UnitExperience
- Show pet lvl up using RegionTitlesLight (function ShowSingleLineText)

Hero Dies (Nazgrek or Zulkis)
- Show message using RegionTitlesLight (function ShowSingleLineText)

Engineer Dies
- As test; Show message using RegionTitlesLight (function ShowSingleLineText)

Storm (drafting)
- To checks whats the player's current zone - if the zone doesn't match - then Storm effect are not applied - NOT WORKING CHECK
- Note: Need to think careful what system handles what - i.e., does Storm give information of storm ended in zone and then the other system handles applying normal zone settings

SpeciFX library
- Added two functions to make easier to create special effect on location (if called e.g., from GUI trigger) vs. strict point X and Y values
>>> SpeciFX\_AddToLocation
>>> SpeciFX\_AddToLocationEx

CastingBarSystem
- Tried to resolve issues with some abilities not working correctly (channel vs cast ability?)
>>> Created into new file "CastingBarSystem\_testing2025-01-15.j" if to be used
>>> Note: didn't work properly for normal abilities like "Firebolt" but channeled abilities worked (maybe just not calling Bar text creation function etc.?

Havenwoods
- Slight terraining at old forest troll area


=================================================================================================================================================
13.1.2026 - List of Actions:

DynamicMinimap
- Working on the library to fix XY drift; Results: Several version test - always something is out-of-place non-working
- Best to use DynamicMinimap_LastWorking.j at this point / as starting point to fix the system
>>> DynamicMinimap\_LatestBuggy.j have some good better globals usage etc. but its buggy - the unit jumps between the chunks (like in previous older versions)
>>>>> It can update the camera bounds but not the minimap chunk etc. buggyness

DynamicMinimap_lastWorking
- Added sounds for minimap enlarge (minimap open) and minimap normal (minimap close)
- Note: when working with other version of DynamicMinimap - remember to transfer these related changes to the library

RegionTitlesLight
- Now has two text frames; one to be used mainly for Zone "Entered" or "Discovered" message and the other text frame for the zone name
- Note: This system current implementation is mainly for Zones.j, but it should maybe be more modular and usable for other text displaying
- Added function; ShowSingleLineText takes string text, real fadeIn, real duration, real fadeOut, real scale

Zones
- Updated RegionTitles usage for enter/discover zone/dungeon
- Added sounds for zone/dungeon enter/discover
- DayNight_UpdateZone; now uses "Zones_ApplyCurrentZoneEffects() instead of HandleZoneEnter
- updated Zone texts
- added new field for common entities, notable characters, environment type
- added "z.isDungeon" Boolean - used basically for different sounds enter/discover - more use cases could be

TasQuestBox_PotS
- change color of button
- "Zones" button as variable
- added functions to hide/unhide with;
call TasQuestBox_Hide()
call TasQuestBox_Unhide()

ON Cinematic -trigger
- added call to hide TasQuestBox
OFF Cinematic -trigger
- added call to unhide TasQuestBox

FCL / FixedCameraLock
- function FCL_Lock: changed Y value of SetCameraTargetController from "0" to "200"

Clouds
- GetLocZ disabled
- use fixed Z 2200.0 (previously 200.0 which meant the clouds clipping through various stuff like terrain)

Hero Levelup trigger
- Uses now RegionTitlesLight's ShowSingleLineText function to display Hero levelup with frame text native

=================================================================================================================================================
12.1.2026 - List of Actions:

Zones
- Issue with the system not working upon unit entering zone region but working manually was found at ExMusic using Wait 2s
- Updated dayNightEvent functions to not use Waits

ExMusic
- Previously used wait in fuction PlayTrack when changing the track, this causes unpredictable issues when using Events etc.
- The wait function replaced with timers
- Purpose was to reduce when music track changes - so the old track has time to die before new is played
- Update:
>>> Fade-completion handler added
>>> Refactored ExMusic\_PlayTrack
>>> Instant cut option
>>> Some description updates etc.
- Updated to main map

DynamicMinimap
- added these in globals;
local real MAP_WIDTH  = MAP_WORLD_MAX_X - MAP_WORLD_MIN_X
local real MAP_HEIGHT = MAP_WORLD_MAX_Y - MAP_WORLD_MIN_Y

In UpdateMinimapAndBounds;
- replaced this...;
set centerX = MAP_WORLD_MIN_X + (I2R(chunkCoordX) * scaleFactor * 128.0) + (actualChunkSizeInMapTiles * 128.0 / 2.0)
set centerY = MAP_WORLD_MIN_Y + (I2R(chunkCoordY) * scaleFactor * 128.0) + (actualChunkSizeInMapTiles * 128.0 / 2.0)
... with;
// Normalize chunk position (0..1)
local real nx = I2R(chunkCoordX) / I2R(CHUNK_COORDINATE_SYSTEM)
local real ny = I2R(chunkCoordY) / I2R(CHUNK_COORDINATE_SYSTEM)

// Chunk size in world units
local real chunkWorldSize = actualChunkSizeInMapTiles * 128.0

// World-space center
set centerX = MAP_WORLD_MIN_X + nx * MAP_WIDTH  + chunkWorldSize * 0.5
set centerY = MAP_WORLD_MIN_Y + ny * MAP_HEIGHT + chunkWorldSize * 0.5

In PeriodicUpdate;
- added;
// Clamp to valid range in map tile coordinates to prevent edge drift when camera is nudged against bounds.
    if unitTileY < 0 then
        set unitTileY = 0
    elseif unitTileY > MAP_SIZE_TILES - 1 then
        set unitTileY = MAP_SIZE_TILES - 1
    endif
 

=================================================================================================================================================
11.1.2026 - List of Actions:

Zones -library
- Some modifications, e.g., to use DNC library
- texts modified

DNC -library
- created
- some triggers to use call DNC_XXX instead of old triggers that were used

RegionTitles
- some modifications, NOTE: cant get custom TOC to work properly....

Notes on this day:
- Zones, Weather, Storm all have many things that need to worked on...
Known issues:
- Storm: Storm not properly working for: Checking current zone + Re-applying current zone DNC after the STORM
- Storm: Storm system used old udg_ZoneCurrent stuff that needs heavy modification for Zone system
- WeatherSystem not fully tested; Ambient sounds may not work as intended
- Zones; Ambient sounds may not work as intended
- Zones; missing enter/discover sounds
- Zones; missing zone specific enter/discover sounds
- Zones; some old GUI variables weirdly transformed over to system by AI (some may not be fully used or used wrongly)
- Zones/Weather System; Linking: weather.j to use region/other data straight from Zones.j to limit multiple config areas (e.g. regions of the zones)
- TasQuestBox needs to be hidden when InCinematic / CInematic ON and re-enabled when over
- Zones; Icons for TasQuestBox to be added per zone -> All zones have similar texture and dungeons own / unique or ALL zones have unique texture paths?
- RegionTitles; FDF and TOC files not imported to main map! Note: also they didn't seem to modify text at all from native blizzard text???

- All new systems updated to main map (with notes / known issues in mind...)


=================================================================================================================================================
10.1.2026 - List of Actions:

Zones -library (testing version)
- Zones_EnterZone will now also enable the zone by calling "Zones_EnableZone", because otherwise the zone handle will not work
- Zones_EnterDungeon will now also enable the zone by calling "Zones_EnableDungeon", because otherwise the zone handle will not work
- Added Table utilization for zone ID - simple integer array would also do the trick
- dungeon IDs changed to unique (were previously using already used ids)
- Note: many stupid coding practices leftover from AI... - could be simplified...
- Started utilizing Tasyen TasQuestBox for Zones descriptions
- Started utilizing RegionTitles by Antares for Zones titles




=================================================================================================================================================
8.1.2026 - List of Actions:

- Issue: camerabounds / units positioning on map is not almost exact vs. how they are positioned in the real word - see older "known" working system have different ways to handle? - each time chunk minimap is updated - units go slightly wrong position relativily
>>> Fix: Hardcoded symmetric bounds (leftover from testing) changed to use GetRectMinX / Y (bj\_mapInitialPlayableArea)'
- Issue: Minimap toggle M (enlarge / normal) sometimes only the background frame is visible but minimap is invisible - togglin on/off/on might bring the minimap visible
>>> Fix: Always set minimap visibility explicitly during toggle, Re-assert frame levels after toggling
- added ESC key detection to reset chatWindowOpen state
- Remove GetLocalPlayer() check for border operations (unnecessary)

Zones -library
- Transform the current GUI triggers into more flexible JASS library
- Note: not all zones in GUI triggers where finished - these were not copied
- Not yet implemented into main map - as there are some unfinished things in the library
->>> many Todos - see MS To-do list
- Fog Intensity by Weather Type; ApplyWeatherFog() function to adjust fog based on weather intensity:
>>> Heavy fog: rain\_heavy, snow\_heavy, storm (uses full fog settings)
>>> Medium fog: rain\_medium, snow\_medium (fog pushed 30-50% further back)
>>> Light fog: rain\_light, snow\_light, wind, other types (fog pushed 60-100% further back)


WeatherSystem
- Storm Zone-Specific Triggering; Storm effects (lightning/thunder) now only trigger visually and audibly for players whose selected unit is in the storm's zone
- Storm DNC Trigger Timing; The zone's DNC trigger (udg_ZoneTrigger[udg_ZoneCurrent]) is now called AFTER storm effects fully complete, not during
- Storm Always Has Rain; Storm weather now ALWAYS includes rain companion weather:
>>> 70% chance: rain\_heavy with storm
>>> 30% chance: rain\_medium with storm
- Increased Snow in Specified Zones; Updated snow chances and enabled snow spawning in these zones:
>>> TwilightGrove (Zone 1): Added snow (55% chance), enabled spawning
>>> Serenaglade (Zone 2): Increased from 75% to 85%, enabled spawning in main region
>>> Thornwoods (Zone 6): Added snow (45% chance), enabled spawning
>>> Havenwoods (Zone 7): Added snow (60% chance), enabled spawning
---- All zones also have steam breath effects enabled for cold weather atmosphere.

=================================================================================================================================================
7.1.2026 - List of Actions:

DynamicMinimap
- Adjusted after intensive testing (crash causer troubleshooting) version

DynamicMinimapTesting
- Made simplified testing library to see if crashes still occur without frame natives (BlzChangeMinimapTerrainTex kinda is still though)
- only functions; chunked view, full view - no enlarge function for map
- Temporarily changed DynamicMinimap and related calls (in Cinematic ON and Cinematic OFF) in main map to refer to DynamicMinimapTesting library
- RESULT: Still crash - verify that indeed testing version was used
>>> This should help troubleshooting
- The main suspects:
>>> originalCameraBounds might be invalid - GetEntireMapRect() might not be safe
>>> Calling SetCameraBoundsToRect during/after cinematic - Camera state might be locked or in transition
>>> No validation before SetCameraBoundsToRect - Should check if rect is valid
Key changes made to fix the crash:
1. Using bj_mapInitialPlayableArea directly instead of GetEntireMapRect() - this is more reliable
2. Added rect validation - Checks that the rect is non-null and not degenerate before calling SetCameraBoundsToRect
3. Changed order of operations - Applies texture BEFORE changing camera bounds to avoid conflicts
4. Added safety checks - Validates rect dimensions (maxX > minX, maxY > minY)
5. PeriodicUpdate calling:
>>> Only the timer calls PeriodicUpdate()
>>> No race conditions between manual and timer-based calls
>>> No rapid successive BlzChangeMinimapTerrainTex() or SetCameraBoundsToRect() calls
>>> At most 0.1 second delay before chunk updates, which is imperceptible

=========> Results after all these changes:
- No crash at least immediately after intro cinematic over
- for some reason camera is not tracked to Nazgrek / Nazgrek not selected?
- then when minimap (chunked version) updates to new chunks (couple of updates) -> units disappear from map => Meaning camerabounds are getting messed up -> Crash (out of bounds?)
- intensive use of "get bj_mapInitialPlayableArea" leading crash causer (does not show stress in testing map because not full of stuff)
- issue found:
>>> Using SetCameraField(CAMERA\_FIELD\_ROTATION) with some values and together calling SetCameraBounds will crash the game
>>> source: https://www.hiveworkshop.com/threads/setcamerabounds-camera-rotation-bug.319374/
>>> Now with Camera rotation safe checks DynamicMinimapTesting.j does not cause crash to map
>>> Have to adjust the full version

WeatherSystem
- Clouds now use GetLocationZ() to spawn at terrain height + 200 offset, so they appear higher on mountains and lower in valleys
- larger regions automatically get more clouds (up to 20 per region).
- Clouds now only spawn for: rain_medium, rain_heavy, snow_medium, snow_heavy
- No clouds for: rain_light, snow_light, storm, or wind
- Added 3 new functions:
>>> IsWeatherActive(pattern) - Check if weather exists anywhere (supports "rain\_any", "snow", zone names like "Sirensong")
>>> GetWeatherInZone(zoneName, pattern) - Get specific zone's weather with pattern matching
>>> CountZonesWithWeather(pattern) - Count zones with matching weather
- Snow Duration Varies by Intensity
>>> snow\_light: 30-120 seconds (much shorter)
>>> snow\_medium: 90-240 seconds
>>> snow\_heavy: 120-300 seconds (longest)
- Snow Waves/Units Vary by Intensity
>>> snow\_light: 3 waves, 30 units/wave (~90 total)
>>> snow\_medium: 6 waves, 60 units/wave (~360 total)
>>> snow\_heavy: 8 waves, 90 units/wave (~720 total)

- Added MasterZoneID[] array to track zone IDs
- Updated ZoneThunderCallback() to use zone-specific storm calls
- Added WeatherSystem_SetZoneID() function
- Configured all 28 zones with their udg_ZoneCurrent values (1, 2, 3, 4, 6, 601, 602, 7-20, 1401-1404, 1701-1704, 1901)

Storm
- Zone-Based Effect Visibility
Storm effects (lightning, thunder, fog) now only visible to players whose selected unit is in the storm's zone
Uses udg_ZoneCurrent to check player's current zone
Zone ID 0 = global (backward compatible)
- DNC Restoration
Stores fog settings before storm starts
After last storm ends, restores fog and executes udg_ZoneTrigger[udg_ZoneCurrent] to restore zone-specific day/night cycle

Terraning
- Deadwoods
- Verdant Plains

Zones:
- added call check to WeatherSystem_GetZoneWeather("ZoneName") to change the fog if any weather is active for that zone
- Note 1: mentioned call is added only to majority of zone triggers but not all - also could be implemented better...
- Note 2: maybe could also use ZoneTrigger[ZoneCurrent] run from WeatherSystem?

=================================================================================================================================================
6.1.2026 - List of Actions:

DynamicMinimap
- Trying to solve crashing issues appearing only in the main PotS map that do not occur in the light-weight testing map...
- added border frame to minimap
>>> Note: Because minimap is part of GameUI - we cant (or I cant) set the border to be between gameUI frames and minimap frames - various tests and always resulting minimap being under the minimapborder frame
>>> Temporarily checking with custom background / positioning / etc. that is more than just border and more background-like
- TestingMap: no crashes
- MainMap: random crash after intro cinematic and starting moving (no using of enlarge map/full map
>>> Could be multiple causes; here some listed:
>>>>> GetRectMinX(bj\_mapInitialPlayableArea) could cause crash in main map
>>>>> ChatBox checking
>>>>> PeriodicUpdate interval too high 0.1s? > Result: even faster crash when using higher value 1.0s
>>>>> Incorrect use of frame natives
>>>>> Null pointer etc.
>>>>> Here could be found some help: https://www.hiveworkshop.com/pastebin/e23909d8468ff4942ccea268fbbcafd1.20598
>>> Temporarily disabled DynamicMinimap and related calls (in Cinematic ON and Cinematic OFF) from main map
>>> The reason for crashing needs to be solved

Temporarily disabled all WeatherSystem related (to check whether Game crash is because of this or DynamicMap)

Terraining
- Deadwoods
- Vanguard Vale / Elf Remnants small village / etc.
- Verdant Plains


=================================================================================================================================================
5.1.2026 - List of Actions:

DynamicMinimap
- Trying solve camera bounds / unit position on real map grid vs. position on minimap, ....
- added chat commands to change modes/help/info etc.
- show commands with " -minimap help "
- Camera bounds / minimap misalignment was caused by BOUNDS_PADDING_MULTIPLIER = set to 2.0
>>> This makes the camera bounds twice the size of the minimap chunk, which breaks the alignment between what the player sees and what's on the minimap.
>>> changed BOUNDS\_PADDING\_MULTIPLIER = 1.0
>>> Stable working version: Jan 6, 2026 at 2:08 AM
- Note in the map enabling/disabling etc. different calls might need to be checked within triggers especially Cinematic ON and Cinematic OFF

Models imported (credits ScorpioT1000 XGM Guru)
D_L_BurningBoards.MDX
D_L_Campfire.MDX
D_L_AshenLamp1.MDX
D_L_DarnassusStreetLamp01.mdx
D_L_DarnassusWreckedStreetLamp02.mdx
D_L_DifficultTorch.mdx
D_L_DifficultTorchHanded.mdx
>> Replace vanilla torch with these torch models!
(old versio as item ability: war3campImported\TinyTorch1.mdx)

Models imported (credits XXX
Night Elf FencesWalls
- 8ne_pvp_warsongbg_nightelfwall01.mdx
- 8ne_pvp_warsongbg_nightelfwall02.mdx
- 8ne_pvp_warsongbg_nightelfwall03.mdx
>>> Vanguard Vale?
Vampire Stone Fences
- 9vm_vampire_rural_fence01_destroyed01.mdx
- 9vm_vampire_rural_fence02.mdx
- 9vm_vampire_rural_fence02_destroyed01.mdx
- 9vm_vampire_rural_fencepole01.mdx
>>> Crypt / Dawnhold?

=================================================================================================================================================
4.1.2026 - List of Actions:

SpeciFX
- Added Terrain Alignment API (by Antares) + GetLocZ function usage
- Added global variable udg_SpeciFXEffect (for temp usage)

WeatherSystem
- Added debug messages / mode
- Water Ripples spawning on rain
- Water Ripples should only be spawned on water
- The amount of Water Ripples depends on rain_light, rain_medium, rain_heavy

CloudsSystem
- Adjusted to only spawn on set region
- Adjusted the amount of clouds to be spawned - dynamically calculates the number of clouds based on region size (min 1 cloud per region, max 20 clouds)

CreepRespawn
- Again checking this: - Player 23 (Emerald) units will be changed to Neutral Passive at death event by this system

Minimap - named as " DynamicMinimap "
- New idea figured out - needs intensive testing / modification to maybe to minimap chunk .blp files etc.
- also the camera bounds thing might need adjusting etc.
- Implemented into main map
- Functions:
>>> HQ map in minimap adjusted to small camera bound section that updates when based on camera location
>>> Enlarge / Normalize map function - The map is brought to center of screen enlarged for better view


=================================================================================================================================================
3.1.2026 - List of Actions:

Minimap
- custom minimap development under construction (issues trying to scale / re-scale back to vanilla minimap...)
- Note: not implemented into main map! Only in test map

Neutral Mobs
- Added game debug message for when Neutral unit (turnt hostile) dies to check whether it changed to neutral passive

Lumberjack Duties
- Fixed bugs with FollowSystem related incorrect unit assignment

CreepRespawn library
- Added DEBUG_MODE constant (set to true) that controls all debug messages
- Fixed the exclusion list bug - All 7 unit types were using index [0], so only the last one was actually excluded. Now each uses indices 0-6, and EXCLUDED_COUNT is properly set to 7.
- Added debug messages showing:
>>> Unit ownership at death - Shows Player ID and HandleID
>>> Whether saved position data exists for the unit
>>> Why units are skipped (summoned, wrong owner, excluded type)
>>> When units will respawn and confirmation when they spawn
>>> Initialization details and respawn timer value
- Player 23 (Emerald) units will be changed to Neutral Passive at death event by this system

WeatherSystem
- First draft of the massive immersive weather system (combined logic for controlling the weather with seasonal etc. settings)
- This system also affected / needed refactoring of following systems:
>>> SteamBreath
>>> SnowSystem
>>> CloudsSystem
- Listed libraries were previously just functions called from GUI triggers
- NOTE: This system will require intensive testing and also creation of subregions for each zones, also checking what weather settings for each zones, subzones, etc.

FrostbiteSystem
- Removed player 2 from affected units

=================================================================================================================================================
1.1.2026 - List of Actions:

SpeciFX
- New library for creation of special effects (handling inside library)
- Configurable effects, easily managed and destroyed
- Utilizes tag system to separate effects per unit or globally

FollowSystem
- All 5 effect creation points now call SpeciFX_MarkAsExcluded()

QuestIconSystem
- Quest icon effects now marked as excluded (SpeciFX)

Intro Cinematic
- Trying to fix why orc patrol does not move by unpausing them Intro Orc Setup -trigger
- Trying to fix Shadowclaw unmovement by unpausing it in Intro Orc Setup -trigger

Kodo quest (Mistaken Kin)
- Updated triggers to make Kodo as Horde (Player 6) owned when following to get neutral hostile attack it

CreepUnitAssignment
- Added Graknar, KodoGrak
- KodoGrak will have FollowSystem assigned if quest Mistaken Kin is active but not completed

Valeria
- fix respawn issue by changing ownership of Valeria back to Neutral Passive (if killed upon Ranger Missing Valeria Encounter situation)

ItemDropSystem with sub-libraries created (based of current GUI triggered version)
- First versions are strictly old version based JASS versions
- Trying to draft versions utilizing Briebe's TableV6
- NOTE! Not utilized in the map currently - the system has to be designed/planned well ahead before usage

Quest Lumberjack Duties
- Now uses the new FollowSystem for udg_LumberPeon


=================================================================================================================================================
Epic Quests 31.12.2025 - List of Actions:

Imports:
- LootEFFECT.mdx (by Geries from WoW)
>>> For Item drops?
>>> Added as ability (effect) for dropped items (IDEA, not implemented)
>>> Remove loot effect ability when picked up (IDEA, not implemented)
- QuestMarking.mdx (by stan0033)
>>> Used at least by Followystem NPCs

ItemHook (not transferred into map yet, just VS code level stuff)
- https://www.hiveworkshop.com/threads/itemhook-create-remove.318849/ - Based of this LUA version, JASS library was created
- see widgets etc that could be utilized for Item events; https://www.hiveworkshop.com/threads/event-item-dies-is-it-possible.294411/

Aradion - Ranger Missing
- Fixed: After ranger missing dialog Failed button pressed - it should not be able to pressed again

Quest Mistaken Kin
- Adjusted Kodo follow range
- Salamanders will now attack the player when reaching Kodo
- Adjusted texts
- Adjuste Kodo end positioning triggers

Chimairo
- Trying fixing Corrosive Venom ability dummy casting
- try "debug chimairo2" to get TesterGuy unit


=================================================================================================================================================
Epic Quests 30.12.2025 - List of Actions:

CinematicMover
- trying fixing: moving revived unit to off-map before killing - does not work?
- trying fixing: unit is not re-killed after cinematic is over (when was dead before cinematicmover) - but revive timer seemed to continue (not visible in multiboard, because alive by CInematicMover system)

FollowSystem
- created first version
- makes units follow target units with (annoying :D) RPG style
- see jass library for documentation / how to use
- make escort related quests utilize the FollowSystem

Valeria
- Ranger Missing quest failed additions

DInv - DItemTransfer
- DItemTransfer addon created to transfer items and equipment between units
- main reason: Resetting abilities aka replacing old unit with new unit, Ghost wolf ability usage, special cases,...

=================================================================================================================================================
Epic Quests 29.12.2025 - List of Actions:

CastingBarSystem
- Reworked the system / made some fixes and adjustments
- Additional configuration options made
- dynamic visibility check and owner tracking

CinematicMover
- Clean death animation: Revived units are now moved to off-map corner coordinates (-15000, -15000) before being killed, so the death animation won't be visible to players. Added a 0.05s delay to ensure position update completes.
- Revive timer preservation: The system already had StoreAndPauseReviveTimer() and ResumeReviveTimer() functions. I ensured they're called correctly:
>>> When reviving during cinematic: Stores remaining timer value and pauses it
>>> When returning to dead state: Resumes timer with the stored remaining time (continues from where it left off, doesn't restart)

CreepUnitAssignment / QuestEvaluationSystem / QuestIconSystem
- Trying to make quest repop again when unit respawns...

HealEngine
- added FIRE_REGEN_EVENT constant set to false which prevents regeneration from triggering the AfterHealEvent. Self-regeneration will no longer fire the event that displays floating heal text

Chimairo
- Corrosive Venom damage engine related triggering work (needs testing)

=================================================================================================================================================
Epic Quests 28.12.2025 - List of Actions:

Lag Resolve (maybe?):
- causer: world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo --> When deleted - lag is gone
- testing to set shadows for all the related crypt wmo doodads to "false"
- Note: in-game check >>> Still lag!!!

UnitExperience
- debug messages now only shown if private debugmode enabled

CreepUnitAssignment / QuestEvaluationSystem / QuestIconSystem
- When a quest giver unit respawns, this system automatically triggers quest re-evaluation, QuestEvaluationSystem will restore any pre-configured quests (states 1 & 2)
>>> QuestEvaluationSystem: Added QuestEval\_ForceUpdateForNPC(unit npc) and QuestIcon\_RestoreQuestData(u) - Forces immediate quest evaluation for a specific NPC
>>> CreepUnitAssignment: Added TriggerQuestEvaluation(unit u) helper function with small delay
>>> QuestIconSystem: BACKUP QUEST DATA (for respawn) - Stores active quest data by unit-type ID so it can be restored on respawn
- Active quests (states 3 & 5) must be managed by quest triggers separately

Terraining
- Crypt (e.g., pathing blockers)

Batrider (Zul'kis)
- model changed -> not looking that great, but utilized

Vanguard Vale
- Sky changed to DNC Outdoor version that most other zones use

Valeria
- Added Rapid Fire ability (berserk based)
- Added Fan of Knives ability
- Added Aimed Shot ability
- When as "companion" - will not be removed from companion group upon death and will use Player's selected Graveyard

Hero / Companion revival
- Added ping map for companion heroes when revived to indicate their revival location
- fixed leak in player hero ping map upon revival

Chimairo
- Venomous Breath; updated missiles and their speed
- Trigger updated: Init Boss Units
- Created boss related triggers (Draft)
- Note: Need to update CreepUnitAssignment for BossChimairo -unit
- Added dummy Corrosive Venom unit / related trigger (Note: currently maybe works for all harmful abilities cast by Chimairo on DamageEventTarget - needs to be somehow checked what the ability was (i.e., Venomous Breath hitting unit)

Multiboard - Companions / Stats
- Fixed issue of not correctly updating all companion rows

Aradion / Valeria / Ranger Missing quest
- Valeris initially invisible (ghost ability)
- Valeria is made visibile when Ranger missing quest is accepted
- Valeria can only be encounted when Ranger Missing quest is discovered
- Quest Failed activity added
- When talking to Aradion after failing quest, Elarindor will turn temporarily hostile to player
- Ranger Missing quest may be started again after Elarindor is atleast unfriendly / not temporarily hostile

CastingBarSystem
- New JASS system to replace old CastingBar
- This new system works for all abilities without manually needed to put ability codes etc. work
- has exclusion list which can be utilized for abilites not desired to show casting bar

Revive system
- added informational text about companion dying / revived

Companions - Hired units
- Fixed issue with trigger removing incorrectly previous multiboard row stored in the variable as the sold unit was never added to multiboard when group size is full

=================================================================================================================================================
Epic Quests 27.12.2025 - List of Actions:

Models (from WoW)
- unshaded models modified into shaded models:
>>> dark-ranger
>>> duskwither-apperentice
>>> nazgrek
>>> elf-sorcerer

Imported models:
- Chimera.mdx     (CREDITS: ZugothNDeadly)
- BatRider.mdx   (CREDITS: Zenonoth)
- Portals:      (CREDITS: Izhael_DC)
>>> Portal\_ArcaneBlue\_I.mdx
>>> Portal\_ArcaneBlue\_II.mdx
>>> Portal\_Bloody\_I.mdx
>>> Portal\_Bloody\_II.mdx
>>> Portal\_Divine\_I.mdx
>>> Portal\_Divine\_II.mdx
>>> Portal\_Fel\_I.mdx
>>> Portal\_Fel\_II.mdx

DNC:
- DNC DarkerPlace trigger now uses the later tested "dnc darkplace3c" as the DNC model
- No need to adjust other triggers etc.

QuestEvaluateSystem / QuestIconSystem
- QuestIconSystem Icon logic: // Unavailable (gray exclamation) - show overhead icon but NO minimap marker
- debug messages now only shown if private debugmode enabled

Item mysterious vanishing from DInv:
- Added condition "Made invisible - IsItemVisible() == FALSE" to check if picked item is hidden into triggers "Item Remove" and "Item Cleanup" in Item Systems Folder / Item Removing After Time / Item Cleamup
>>> UNADDED: Additional check could be used to check if the item is located in bottom-left corner of map:
>>> stored at (MapMinX, MapMinY) which is typically (0, 0) or negative coordinates


Boss Chimairo (Verdant Plaints)
- Model changed (CREDITS: ZugothNDeadly)
- Abilities and fight drafted;
>>> Ability 1: Caustic Fang - Draft
>>> Ability 2: Venomous Breath (Frontal AoE Cone) - Draft
>>> Ability 3: Acidic Rupture (Venom Spread / Anti-Clump) - Not started
>>> Ability 4: Sky Rend Charge (Fly-Charge) - Not started 
>>> Ability 5: Rending Talons (Cleave Strike) - Draft
>>> Ability 6: Predator’s Frenzy (Enrage / Phase Ability) - Not started

New dungeon portals:
- added ghost (visible) abilities
- removed some old portal doodads

UnitsStats
- debug messages now only shown if Boolean debugEnabled true

Lag Resolve (maybe?):
- Fog FX doodad at Crypt (old entrance) had "Shadows = Enabled" - this probably caused heavy GPU work
- In WE resolved, but in-game crypt old entrace area causes heavy GPU utilization and lag

Terraining:
- The Crypt
- Vanguard Vale / Verdant Plains human lumber mill area

=================================================================================================================================================
Epic Quests 24.12.2025 - List of Actions:

QuestEvaluateSystem
- Added API functions to get evaluate in GUI trigger the quest giver NPC quest state(s)
- Red Quest Exclamation mark should now be displayed on the unit if quest is not available (unavailable state)

DNC
- Added default dark DNC test with " dnc darkplacedef "
>>> Works only on small part of the map

- Added few more custom DNC tests;
dnc darkplace3e (Ambient 0.02)
>>> Works only on small part of the map

dnc darkplace3f (Directional 0.02)
>>> Works only on small part of the map

Terraining
- Sirensong

Crypt
- Entrance (Original) location has lag, its not all around - some model causing it?


=================================================================================================================================================
Epic Quests 12.12.2025 - List of Actions:

DNC testing by chaning ambient light node settings
- test with:
 dnc darkplace3b
 dnc darkplace3c
 dnc darkplace3d
RESULTS: No difference in models
IDEA: what about setting ambient light node 0.0?


Terraining
- Verdant Plains lite terraining > testing new doodads

=================================================================================================================================================
Epic Quests 7.12.2025 - List of Actions:

QuestEvaluateSystem
- Init run after intro cinematic (trigger "Intro Cinematic Cleanup"

Fixing ceiling/walls of the models from previous edit:
world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a2.wmo.mdx (1st part)
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4f.wmo.mdx (2nd part)
>>> for some reason bth model causes heavy lag of PC / map in WE
>>> Is this model related issue or PC CPU / RAM related (changes in RAM done lately)
>>> Also... northrend4a.wmo didn't have any ceiling so there never was wall/ceilings that are now missing, either removed earlier or intended

Other:
- onyxia lair as dragon dungeon (to be edited into parts)
DUNGEON: world_wmo_dungeon_kl_onyxiaslair_kl_onyxiaslair_a1.wmo.mdx
- textures missing (why)
DUNGEON: world_wmo_dungeon_kl_onyxiaslair_kl_onyxiaslair_b1.wmo.mdx
- textures missing (why)
SIGN: world_dungeon_goldmine_passivedoodads_caveminekobolds_cavekobolddangersign_red_01.mdx
TREE: world_expansion04_doodads_valleyoffourwinds_willowtree_vfw_riverwillow02.mdx

DNC, testing "" style with
call SetDayNightModels("","")

- use command " dnc darkstock " to test
- notice that call has "","". While you have used only "" within the call, DNC Model + unit need to be both?
Example: call SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl" , "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")

=================================================================================================================================================
Epic Quests 3.12.2025 - List of Actions:

world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx
- edited (missing texture / bad)
- saved and imported as world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo.mdx
- re-placed the model at Crypt entrance location

world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo.mdx (1st part)
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e.wmo.mdx (2nd part)
>>> might still need to change the XY position, because too far in XY grid? test
>>> still does disappearing with separated models, might because of some model settings e.g., related ceiling or the grid position
>>> cause found: extends had to be re-calculated + grid position of the model to 0,0
>>> re-placed models at crypt
NOTE: ...e2 and 4d models missing some parts (ceiling + some walls), that maybe got deleted when separating the models....

DNC testing
- added debug commands to test DNCs
>>> dnc darkerplace (what crypt uses currently)
- seems to work across the map more widely when used 2nd time - Colossal Arena not covered - but this happened at some gameplay only... ==> game engine related bug
>>> dnc darkplace
- brighter than "darkerplace", but works across the whole map
>>> dnc underground (same as dnc darkplace but with sky set to none)
>>> dnc7
- good, not broken, bright
>>> dnc9
- good, not broken, but not that dark

>>> dnc darkerplaceoffset
- very weird, unshaded units, and the placement seems to be more at EAST

Testing new DNC with offset model position:
X: 5000
Y: -29000
- model name: DNCAnimated2_Darker5_offset.mdx

=================================================================================================================================================
Epic Quests 30.11.2025 - List of Actions:

QuestEvaluationSystem:
1. Only show AVAILABLE quests (state 2)
Unavailable quests (requirements not met) are now removed completely - no red exclamation marks shown
Only when requirements ARE met does the quest icon appear (yellow/blue !)

2. State change tracking
Added SlotLastState array to remember what state each slot is in
Only calls QuestIcon_RegisterQuest or QuestIcon_RemoveQuest when state actually changes
Prevents unnecessary re-registration of the same quest state

3. Dynamic updates
When hero reaches level 10 and has neutral Horde rep, Grum's quest will automatically appear
When requirements stop being met, the quest icon is removed
System efficiently only updates when changes occur

How it works now:
Requirements NOT met → No quest icon (removed if it was showing)
Requirements met → Yellow/blue ! appears (only registered once until state changes)
Active quest exists → Dummy icon removed (real quest takes over)
Quest completes → Dummy icon reappears if requirements still met

Terraining:
- Sirensong; testing new rocks
- Serenaglade; testing new rocks
- Crypt; testing new wmo


Imported following models:

Crypt related (credits Blizzard):
Darkshire Entrace texture edit to not contain "darkshire
md_cryptsimpleent1.mdx
md_cryptsimpleent2.mdx
md_cryptsimpleent3.mdx
world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx
world_wmo_dungeon_md_crypt_md_crypt_f_northrend3.wmo.mdx
world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx

Rocks (Credits Blizzard submitted by Renn01):
Elsecaro_Large_Rock_04.mdx
Elsecaro_Large_Rock_05.mdx
Elsecaro_Large_Rock_06.mdx
Elsecaro_Large_Rock_07.mdx
Elsecaro_Medium_Rock_00.mdx
Elsecaro_Medium_Rock_01.mdx
Elsecaro_Medium_Rock_02.mdx
Elsecaro_Medium_Rock_03.mdx
Elsecaro_Medium_Rock_04.mdx
Elsecaro_Medium_Rock_05.mdx
Elsecaro_Medium_Rock_06.mdx
Elsecaro_Medium_Rock_07.mdx
Elsecaro_Medium_Rock_08.mdx
Elsecaro_Medium_Rock_09.mdx
Elsecaro_Medium_Rock_Group_00.mdx
Elsecaro_Medium_Rock_Group_01.mdx
Elsecaro_Medium_Rock_Group_02.mdx
Elsecaro_Medium_Rock_Group_03.mdx
Elsecaro_Medium_Rock_Group_04.mdx
Elsecaro_Medium_Rock_Group_05.mdx
Elsecaro_Medium_Rock_Group_06.mdx
Elsecaro_Medium_Rock_Group_07.mdx
Elsecaro_Rock_Ramp_00.mdx
Elsecaro_Rock_Ramp_01.mdx
Elsecaro_Small_Rock_00.mdx
Elsecaro_Small_Rock_01.mdx
Elsecaro_Small_Rock_02.mdx
Elsecaro_Small_Rock_03.mdx
Elsecaro_Small_Rock_04.mdx
Elsecaro_Small_Rock_05.mdx
Elsecaro_Small_Rock_Group_00.mdx
Elsecaro_Small_Rock_Group_01.mdx
Elsecaro_Small_Rock_Group_02.mdx
Elsecaro_Small_Rock_Group_03.mdx
Elsecaro_Large_Rock_00.mdx
Elsecaro_Large_Rock_01.mdx
Elsecaro_Large_Rock_02.mdx
Elsecaro_Large_Rock_03.mdx


=================================================================================================================================================
Epic Quests 16.11.2025 - List of Actions:

Imported many models from WoW (mainly Crypt-dungeon targeted, but other misc models as well:
CRYPT / UNDEAD
 	md_cryptsimpleent_part1.mdx
 	md_cryptsimpleent_part2.mdx
 	md_cryptsimpleent1.mdx
 	world_wmo_dungeon_md_cryptsimpleent_md_cryptsimpleent.wmo.mdx
 	world_azeroth_karazahn_activedoodads_karazahn_gatedoors.mdx
 	world_azeroth_karazahn_passivedoodads_rubble_karazahnrockrubble01.mdx
 	world_azeroth_karazahn_passivedoodads_rubble_karazahnrockrubble02.mdx
 	world_expansion02_doodads_generic_scourge_sc_platform2.mdx
 	world_expansion02_doodads_generic_scourge_sc_spirits_02.mdx
 	world_expansion02_doodads_generic_scourge_sc_spirits_03.mdx
 	world_expansion02_doodads_generic_scourge_sc_stairs2.mdx
 	world_generic_human_passive doodads_fire_undeadcampfire.mdx
 	world_generic_passivedoodads_deathskeletons_scourgefemaledeathskeleton.mdx
 	world_generic_passivedoodads_deathskeletons_scourgemaledeathskeleton.mdx
 	world_generic_undead_passive doodads_undeadalchemytable_undead_alchemy_table.mdx
 	world_generic_undead_passive doodads_undercityslimefalls_undercityslimefalls01.mdx
 	world_lordaeron_arathi_passivedoodads_impalingstonecorpses_impalingstone_corpse_01.mdx
 	world_lordaeron_arathi_passivedoodads_impalingstonecorpses_impalingstone_corpse_02.mdx
 	world_lordaeron_plagueland_passivedoodads_hangingscourge_scourgebodyhangingfemale01.mdx
 	world_lordaeron_plagueland_passivedoodads_hangingscourge_scourgebodyhangingfemale02.mdx
 	world_lordaeron_scholomance_passivedoodads_bookshelves_scholme_bookshelf.mdx
 	world_lordaeron_scholomance_passivedoodads_bookshelves_scholme_bookshelflarge.mdx
 	world_lordaeron_scholomance_passivedoodads_bookshelves_scholme_bookshelfsmall.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlescorner01.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlescorner01green.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight02.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight02green.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight04.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight04green.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_scholme_greenrug.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_scholme_purplerug.mdx
 	world_lordaeron_scholomance_passivedoodads_cauldrons_greenbubblingcauldron.mdx
 	world_lordaeron_scholomance_passivedoodads_operationtables_creepyoperationtable01.mdx
 	world_lordaeron_stratholme_activedoodads_doors_largeportcullis.mdx
 	world_lordaeron_stratholme_activedoodads_doors_smallportcullis.mdx
 	world_lordaeron_stratholme_passivedoodads_anvil_nox_anvil.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_bodies_massgrave.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_bodies_scourgebodyhanging01.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_bodies_scourgebodyhanging03.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_graves_brillgraves01.mdx
 	world_wmo_azeroth_buildings_chapel_duskwoodchapel.wmo.mdx
 	world_azeroth_duskwood_passivedoodads_darkshireentrance_darkshireentrance01.mdx

BANNERS
 	world_expansion02_doodads_generic_highelf_he_banner_03.mdx
 	world_expansion02_doodads_generic_scourge_sc_banner_03.mdx
 	world_expansion02_doodads_generic_scourge_sc_banner_04.mdx
 	world_expansion02_doodads_generic_scourge_sc_banner_06.mdx

COFFINS
 	world_expansion01_doodads_auchindoun_passivedoodads_coffin_ancient_d_coffin.mdx
 	world_azeroth_duskwood_passivedoodads_coffin_coffin.mdx
 	world_azeroth_duskwood_passivedoodads_coffinlid_coffinlid.mdx
 
OTHER	world_critter_fireflies_fireflies01.mdx
 	world_azeroth_burningsteppes_passivedoodads_warlockshrine_warlockshrine.mdx
 	world_azeroth_duskwood_passivedoodads_duskwoodscarecrow_duskscarecrow.mdx
 
FIRE
 	creature_8fx_generic_fire_basic_bonfirehuge_smoke_8fx_generic_fire_basic_bonfirehuge_smoke.mdx
 	spells_stratholmefloatingembers_centered.mdx
 	world_generic_pvp_fires_lowpolyfire.mdx
 
SKYBOX
 	environments_stars_deathknightfireskybox.mdx
 	environments_stars_firelandssky01.mdx
 	environments_stars_orgrimmarraid_firesky01.mdx
 	environments_stars_skywallskybox.mdx
 	environments_stars_battlefield_dirty_skybox.mdx
 
WAGONS
 	world_generic_human_passive doodads_gypsywagons_stormwindgypsywagon01.mdx
 	world_kalimdor_mulgore_passivedoodads_burnedwagons_burnedgypsywagon01.mdx
 	world_kalimdor_mulgore_passivedoodads_burnedwagons_burnedgypsywagon02.mdx


Skybox
- Testing DNC Outdoors Cloudy for Vanguard Vale
- Testing DNC Firelands for Firelands
- Testing DNC Outdoors Dirty for Emberpeark Highlands
>>> Results: these skyboxe are too lowpoly vs. DNC Outdoor/DNC Hellish
>>> Option: Upscale textures to 512x512

QuestEvaluateSystem
- Fixing issues not working for pre-configured units


=================================================================================================================================================
Epic Quests 14.11.2025 - List of Actions:

QuestEvaluateSystem
- made the system more "automatic";
- usage example:
// In ConfigureQuestRequirements():
call AddQuest(1, udg_Thrall, 5, Faction.getFaction("Horde"), 3000, "normal")

QuestIconSystem
- hashtable made public so QuestEvaluatinSystem can access it

Quest System Quest Givers -trigger
-previously used to set initial quest icons (dummy)

=================================================================================================================================================
Epic Quests 13.11.2025 - List of Actions:

QuestEvaluateSystem -created
- QuestEvaluationSystem.j - The main system library
- Evaluates quest availability every 5 seconds
- Checks level, reputation, events, and custom conditions
- Integrates with QuestIconSystem and Reputation library
- Key Features:
>>> Automatic evaluation every 5 seconds
>>> Level requirements - Hero level checking
>>> Reputation requirements - Uses your Reputation system API
>>> Event-based quests - Support for boolean flag requirements
>>> Custom conditions - Advanced requirement functions
>>> Quest types - Normal, daily, repeatable, dungeon
>>> Dynamic icons - Automatically shows gray ! (unavailable) or yellow/blue ! (available)
>>> No duplicates - Prevents duplicate icons when quest becomes active
>>> Easy configuration - All setup in two functions
- How to use:
1. Configure quest givers in ConfigureQuestGivers():
call QuestEval_RegisterGiver(udg_YourNPC)
2. Configure quest requirements in ConfigureQuestRequirements():
call AddQuestRequirement(questID, npc, minLevel, faction, minRep, "normal")
3. In your quest triggers, when player accepts quest:
call QuestEval_MarkQuestActive(questID)
4. When quest is turned in:
call QuestEval_MarkQuestInactive(questID)

=================================================================================================================================================
Epic Quests 1.11.2025 - List of Actions:

Reputation
- debug messages hidden/shown with DEBUG variable (=set to FALSE to hide)
- mapped players to faction all should follow the primary faction player alliance state
- added debug calls for GUI debug commands:
>>> call SetFactionReputation(Player(0), "Horde", 5000)
>>> call TriggerFactionTemporalHostility("Horde")
>>> call SetReputationMultiplier(true)  // Enable 10x
>>> call SetReputationMultiplier(false) // Disable

Patrol System
- debug messages hidden/shown with DEBUG variable (=set to FALSE to hide)

Patrol Group System
- debug messages hidden/shown with DEBUG variable (=set to FALSE to hide)

Neutral Creeps
- lightning lizard
- removed all unit-type checks from "Neutral Unit Dies", not needed

Companions
- When kicked will change the AI heroes ownership to original player (hardcoded...)
- using udg_NPC_AI_XXX == no unit -> to check it the AI hero of is already created...
>>> This logic in spawnging AI heroes could be more dynamic/versatile...

=================================================================================================================================================
Epic Quests 31.10.2025 - List of Actions:

Reputation
- when temporal hostility for faction is active - show icon "Hostile" then revert to what ever icon status of that faction is
- show temporal hostility time left

Companion abilities
- should now work on Neutral units

Patrol System
- The units should now properly engage in combat when attacked without constantly being stopped




=================================================================================================================================================
Epic Quests 30.10.2025 - List of Actions:

Reputation
- faction temporarily hostility when attacked/unit killed by player0
>>> When Player(0) attacks/kills a non-hostile faction unit → faction becomes temporarily hostile
>>> After configured duration → faction returns to original status (based on reputation)
>>> Already hostile/enemy factions are not affected (they're already hostile
- Note: Alliances set in Init triggers for Player needs to be re-adjusted, because Reputation system is now the master (for Player 1)
- companion player (player(18)) alliance to follow player0's status with each faction (configurable by false/true boolean)

CreepRespawn
- Added way to configure unit-types that will not be respawned

AI Heroes
- Horde heroes changed to Player6 (HORDE)
- Note: may be breaking change and some things may not be correct as of this change!
- When invited to Companion Group, are now changed to Player 19
- When kicked, then changed back to their original player ownerships (WIP)

Import:
- Imported faction icons
- Imported faction status icons

Vanguard Vale
- some terraining


=================================================================================================================================================
Epic Quests 29.10.2025 - List of Actions:

PatrolSystem & PatrolGroupSystem
- Now should work
- unified PatrolSystem4.j under work and buggy (not used in map currently)
- added functionalities to have patrol group waypoint be random at set region OR manually set waypoints from regions

Reputation
- added faction status icons
- added faction icons
- all factions now use same status icons
- Reputation system is now the master system determine alliances for Player0, every computer unit alliances towards each other could also determined with this system with configurable boolean to utilize it or not
- added function to not show faction related rep increase/decrease messages and be visible in multiboard


=================================================================================================================================================
Epic Quests 27.10.2025 - List of Actions:

Reputation
- Fixes long-lasting issues with the library (failing silently)
- Now unit death event works because the library is completely initialized properly

CreepRespawn
- fixed wrong players in the configuration

PatrolGroupSystem
- still trying to get patrol group units moving - maybe try in test map...


=================================================================================================================================================
Epic Quests 26.10.2025 - List of Actions:

Reputation system
- small bug fixes
- use " debug alliancestatus " to check if the selected unit's player is enemy with player1
- Added Player-to-Faction Mapping System
>>> Configured Player 2 and Player 6 as Horde
- To add more players to certain faction (EXAMPLE):
>>> call Faction.mapPlayerToFaction(Player(1), horde)  // Player 2
>>> call Faction.mapPlayerToFaction(Player(9), horde)  // Player 10 is also Horde
>>> call Faction.mapPlayerToFaction(Player(4), alliance)  // Player 5 is Alliance
- Big issue: UNIT DEATH EVENT NOT WORKING

Ghost Wolf
- Items picked in Ghost Wolf shall now be transferred to invisible (real) morphed unit

Creep Unit Assignment
- Updated; added BossMountainGiant
- Elarindor player units should now respawn

Rifts Corrution
- Testing different channel based abiity for Aradion ritual spell
>>> test with: " debug aradion "
>>> stop test with: " ddebug aradion stop "
- should now display quest as Failed when Aradion or Valeria dies
- Valeria/Aradion should now return to their place when quest is failed
- all Ritual related timer/trigger should now be disabled when quest is failed

CinematicMover
- added new move mode: 9 = No Return (move all units but don't return them)
>>> Useful for cinematics / quests where you dont want to return any unit back

DInventory system
- Bug: DInventory - Stacking bug - After picking full stack of items of Item-type XXX, then next item of that item-type are inserted into DInventory as individual 1x charges and not adding the stacks (e.g., 6x -> 1x -> 1x -> 1x, etc.)
- Root Cause: The FirstStackableItemSlotOfBID function in SharedDInvLib.j was finding and returning any existing stack of the same item type, without checking if that stack was already full.
- Modified the FirstStackableItemSlotOfBID function to check if a stack has available capacity before returning it
- File Modified: SharedDInvLib.j / Function: FirstStackableItemSlotOfBID (lines 675-710)

Patrol System

Patrol Group System
- Death Check Filter Issue (PatrolGroupSystem.j)
>>> Added IsUnitInGroup() verification to ensure only deaths of actual patrol group members trigger the respawn check.
- The delayed patrol start timer was only paused, not destroyed, causing potential memory leaks.
>>> Changed PauseTimer() to DestroyTimer() and set to null.
- Critical Bug in PatrolSystem.j - Wrong Data Stored
>>> Added new hashtable key 11 to store unit count
>>> Updated PatrolSystem\_GroupStart to save waypointCount in key 6 and unitCount in key 11
>>> Updated all 9 functions that read unit count to use key 11 instead of key 6

UnitDeathEvent (new system)
- this is to centralize generic UnitDeathEvent

Creep Respawn
- new jass library CreepRespawn created to replace old GUI format
- utilizes UnitDeathEvent

Companions
- The logic of checking if the target unit IS an enemy backwards; this should fix inviting new companion units from AI heroes


=================================================================================================================================================
Epic Quests 25.10.2025 - List of Actions:

Heal Engine - Spell Power Percentual and Flat bonus
- modified logic for both Percentual and Flat spell power bonus for healing

DInventory system (bag slots)
- 12 slots initially
- Changes Made:
>>> DConfigurationArea.j - Initial Inventory Size
>>>>> Changed initial inventory from 25 slots (5×5) to 12 slots (3×4)
>>>>> Added comprehensive documentation header explaining how to use the bag expansion system
>>>>> Configuration:
integer InventoryColumns = 4
integer InventoryRows = 3
integer InventoryCapacityBase = 12

>>> SharedDInvLib.j - Added Vendor Functions
>>>>> Added two new convenience wrapper functions specifically for vendors:

DInvAddSlotsForPlayerVendor(playerId, numberOfSlots)
- For "1PerPlayer" paradigm
- Adds slots and shows confirmation message

DInvAddSlotsForHeroVendor(heroUnit, numberOfSlots)
- For "1PerHero" paradigm (current setting)
- Auto-detects paradigm and calls appropriate function
- Adds slots and shows confirmation message

>>> New Files Created
>>>>> EXAMPLE\_BagVendor.j - Complete working example with:
>>>>>>>>>> Item usage triggers (consumable bags)
>>>>>>>>>> Vendor purchase functions
>>>>>>>>>> Shop dialog system
>>>>>>>>>> Chat command testing (-bag 1, -bag 2, etc.)
>>>>> BAG\_EXPANSION\_GUIDE.md - Comprehensive documentation covering:
>>>>>>>>>> How the system works
>>>>>>>>>> All available functions
>>>>>>>>>> Suggested bag tiers and pricing
>>>>>>>>>> Multiple implementation methods
>>>>>>>>>> Testing instructions
>>>>> BAG\_QUICK\_REFERENCE.j - Copy-paste ready code snippets for:
>>>>>>>>>> Vendor functions
>>>>>>>>>> Consumable bag items
>>>>>>>>>> Dialog shop menus
>>>>>>>>>> Testing commands
>>>>>>>>>> Region-based vendor interactions
>>>>>>>>>> Existing Functions (Already in the System)

// Examples and testing6
// In your shop/vendor trigger:
call DInvAddSlotsForHeroVendor(buyerHero, 12)  // Adds 12 slots
Use the chat command system from EXAMPLE_BagVendor.j:

- Bag Vendor
>>> Now sells bag items (powerups) to be used to increase bag slots for the unit 
>>> Small, Medium, Large Bags powerup items created
>>> uses call DInvAddSlotsForHeroVendor(unit, integer)

Vanguard Vale
- Added Mountain Giant to wander at Redwind Pass

Reputation
- Fixed Linked Faction Reputation Bug
- Added Reputation Change Messages with Blue Text and Quick Fade
- Fixed Missing Faction Status Change Messages

Krolm (outcast ogre)
- added to Thornwoods
- chat/quest WIP

Patrol System
- Fixed Patrol Speed Not Reverting When Paused/Stopped
- Added Complete Group Patrol Functionality, with functions:
>>> PatrolSystem\_GroupStart(group, waypointCount, resetTime, pathStyle, autoResume, moveOrder, patrolSpeed) → returns groupId
>>> PatrolSystem\_GroupPause(groupId)
>>> PatrolSystem\_GroupResume(groupId)
>>> PatrolSystem\_GroupStop(groupId)
>>> PatrolSystem\_GroupContinue(groupId)

Patrol Group System (helper library)
- created

ThornwoodsHordePatrol (subfunction using Patrol Group System)
-created

Rifts of Corruption
- Accept quest; Valeria teleported outside camera at start and shall move near Aradion.
>>> Would need another trigger to wait for Valeria enter the spot and then issue face towards player / angle 192.0
- Added debug " debug Aradion " to test Channel spell on Nazgrek's position


=================================================================================================================================================
Epic Quests 24.10.2025 - List of Actions:

WaveSpawner (UnitSpawner)
- renamed to UnitSpawner
- refactor to be library using Briebe's table v6
- each spawned unit "wave" can be removed individually

Floating Text Spell
- Disabled "Floating Texts Config"
- Disabled "Flaoting Texts SPell Event"
>>> To test if these are the causes of random lag spikes
>>> If they are;
>>>>> then FloatingTextTag jass system / usage must be checked
>>>>> the triggers and function/condition usage withing the triggers themselves

HealEngine
- Fixed Critical CheckLoop Bug (Lines 173-241)
>>> Separated loop counter i from unitIndex to prevent infinite loops/skipped units
>>> This was the primary cause of unpredictable lag spikes
- Removed BJ Function Overhead
>>> Replaced RMaxBJ(0.00, regen\[unitIndex]) with inline comparison
>>> Replaced StartTimerBJ() with native TimerStart()
- Reduced Timer Frequency
>>> Changed HEAL\_CHECK\_INTERVAL from 0.05 to 0.10 seconds
>>> Cuts CheckLoop executions from 20/sec to 10/sec = 50% reduction
- Added Per-Frame Heal Limiter
>>> New constant: MAX\_HEALS\_PER\_FRAME = 25
>>> Prevents processing 100+ heals in one frame
>>> Excess heals automatically deferred to next frame
- Improved Loop Reset
>>> Added i = 1.00 reset between heals to prevent PreHealEvent counter issues

Heal Engine - Spell Power Percentual bonus
- modified, test if it works for native heals now when unit has Stat Spell power %

HeroItemCheck.j
- There were random issues with items disappearing from Inventory when calling these functions; main culprit seems to have been using wait(s)
- It has to be ensured that the system still works after the modifications and especially not using wait anymore, as there was reason for the wait to work for Quest Update triggers
>>> Race Condition: HeroItemCheck had a TriggerSleepAction(0.05) that created a 50ms window where game state could change between checks
>>> Global Variable Pollution: HeroItemCheckBoth used udg\_DInvUnit as a side effect, causing items to be removed from the wrong hero when multiple checks happened rapidly
>>> Non-Atomic Operations: Time gap between checking and removing allowed items to disappear or be consumed
- Fixes applied:
>>> Removed TriggerSleepAction from HeroItemCheck - now instant, no delays
>>> Made HeroItemCheckBothAndRemove atomic - check and remove happen together using local variables

Reputation system
- modified reputation states; enemy, hostile, unfriendly, neutral, friendly, covenant, exalted
>>> Enemy: some factions will hunt you
>>> Hostile = You will always be attacked on sight 
>>> Unfriendly = cannot buy items or companions, cant talk if quest givers / etc talk
>>> Neutral = can buy basic items, can talk
>>> Friendly = can buy more items, can talk
>>> Covenant = can buy more items, can hire companion units, can talk
>>> Exalted = can buy more items, can hire companion units, can talk, special item reward is given and title?

Aradion
- Rifts of Corruption:
>>> will not say unfinished lines when quest is failed
>>> the quest can be started again if its failed

=================================================================================================================================================
Epic Quests 23.10.2025 - List of Actions:

DInv & DEquipment system(s):
Updated the RemoveDInvItemChargesByType function in SharedDInvLib.j with:
- Comprehensive debug logging that tracks every step of the removal process
- Separated null and type checks for clearer logic flow
- Added a critical safety check that re-verifies the item type immediately before deletion to prevent any wrong items from being deleted
- Better error reporting that will show exactly which items are being processed and why

Updated HeroItemCheck.j & GetDInvItemChargesByTypeThreshold + RemoveDInvItemChargesByType in (in SharedDInvLib.j)
- Now operates in two phases:
>>> Phase 1: Removes items from DInventory (as before)
>>>Phase 2: If still need to remove more items, removes from vanilla inventory
- Uses the same logic for both:
>>> Handles 0-charge items (treats as 1 item)
>>> Handles partial removal (when an item has more charges than needed)
>>> Handles complete removal (when an item has equal or fewer charges)
>>> Enhanced debug messages show which phase is executing and from which inventory items are being removed

How It Works:
- When you call HeroItemCheckAndRemove(hero, 'I000', 10):
>>> First checks if the hero has 10+ items of type 'I000' in DInventory + vanilla inventory combined
>>> If yes, removes 10 items, prioritizing DInventory first, then vanilla inventory
>>> Returns true if successful, false if not enough items

ItemSearch.j
- Added requires SharedDInvLib to access DInventory functions and data structures
- Updated Documentation
- Added note that it now searches BOTH inventories
- Clarified that DInventory is searched first, then vanilla inventory
- Two-Phase Search Logic
>> Phase 1: Search DInventory
>>> Checks if unit has a DInventory (bid != -1)
>>> Searches all slots in DInventory
>>> Returns immediately if match is found
>> Phase 2: Search Vanilla Inventory
>>> Only executes if no match found in DInventory
>>> Searches all 6 vanilla inventory slots
>>> Returns if match is found
- Enhanced Debug Messages
>>> Shows which phase is executing
>>> Labels slots as "DInv Slot" or "Vanilla Slot" for clarity
>>> Shows which inventory the match was found in

How It Works:
When you call ItemSearch_FindItemByKeyword(udg_hero, "meat"):

- First searches the hero's DInventory for any item with "meat" in its name
- If found, sets udg_QuestItemTemp to that item's type ID and returns
- If not found, continues to search the vanilla inventory
- If found there, sets udg_QuestItemTemp to that item's type ID
- If no match in either inventory, sets udg_QuestItemTemp = 0
This ensures that quest items or special items can be found regardless of which inventory they're in!

Blood Splats Ground
- added condition to not trigger if the unit-type is "Totem"

Rifts of Corruption
- Ritual Prepare:
>>> Aradion is now moved near RiftCurrent Unit
>>> Aradion should now move to position of 500 away from from RiftCurrent unit from the direction of where Aradion is (=to not make him move to opposite side of Rift / walk pass the riftCurrent unit)
>>> Adjusted DialogCamera; double the distance and different angle
>>> Removed Wander ability from Aradion at start of trigger
- Fixed incorrect voicefiles for quest unfinished talk with Aradion
- Quest Req2 should now be also completed when all rifts closed

UnitStats
- The Problem:
>>> Scanned entire map every 3 seconds using GetWorldBounds()
>>> Processed hundreds of units repeatedly with 65+ ability checks each
>>> Caused severe lag spikes: 100 fps → 2 fps
- Fixes:
>>> 1. Event-Driven System (NO MORE PERIODIC SCANNING!)
>>>>> Units are processed only once when they spawn via trigger "Init 07 Unit Event Enters" and with function "call UnitStats\_ProcessUnit(GetTriggerUnit())"
>>>>> Uses triggers to detect unit creation automatically
>>>>> No more expensive map-wide scans
>>> 2. Smart Caching
>>>>> Tracks which units have been processed in a processedUnits table
>>>>> Never processes the same unit twice (unless you explicitly refresh)
>>>>> Instant checks, no redundant work
>>> 3. One-Time Initial Scan
>>>>> Runs once at map start (2 seconds delay)
>>>>> After that, only new units trigger processing
>>>>> No periodic lag after initialization

Kaelthir
- added item check and remove for quest Kaelthir Struggle
- voiceline (Kaelthir_0003) was missing from greet - edited to not include it

WavesSpawner.j
- Created
- To be utilized as waves of units easy spawning around point
- Current form should be separated, and create lite scripts that utilize this WaveSpawner to not fill it with quest/event specific scripts...

Multiboard Remove Companion
- For the Remove Companion trigger added clearing of texts of each column/row

Multiboard Add Companion
- changed "For each (Integer Multiboard_Int2) from 1 to 9, do (Actions)" to:
>>> "For each (Integer Multiboard\_Int2) from 1 to Multiboard\_RowVar, do (Actions)"
>>> This ensures that all rows (including newly added companion rows) get their widths set correctly.

Vanguard Vale
- Some terraining

=================================================================================================================================================
Epic Quests 22.10.2025 - List of Actions:

DInv & DEquipment system(s):
- Bug 1: Issue with using HeroItemCheck and GetDInvItemChargesByTypeThreshold(whichHero, itemId, requiredAmount) in SharedDInvLib will seems to randomly remove charges from items where it should not removed them
- Bug 2: Campaign items (and other item types) were showing charge numbers even when they shouldn't
- Bug 3: HeroItemCheck for 0-Charge Items / single items didn't work


BUG 1 FIX: RemoveDInvItemChargesByType
When using HeroItemCheck or any function that removes items from DInventory, there was a critical loop bug causing random items to disappear.

The Bug:
In RemoveDInvItemChargesByType (SharedDInvLib.j), when deleting items:

Item deleted from slot 3 → all items shift down (slot 4→3, 5→4, etc.)
Loop counter ALWAYS incremented → next check at slot 4
Result: Item that shifted from slot 4 to slot 3 was SKIPPED! ❌
Example:
Inventory: Gold(0), Water(1), Potion(2), Water(3), Mana(4)

Command: Remove 6 Water charges

BUG 2 FIX:
Campaign item with Level = 0 (not stackable) was showing "0" or "1"
Should only show charges if the item can actually stack (Level > 0)
The Fix: Updated DInventoryIsItemStackable to check Item Level

BUG 3 FIX:
- Now treat 0-charge items as 1 item when checking for item
- Treat 0-charge items as 1 item when removing item


Aradion
- edited Fading Sparks voicelines slightly
- All Aradion quest descriptions missed \n\n - fixed
- Fading Sparks quest title was incorrectly Crystal of Hope - fixed
- Rifts quest should now have Aradion properly added to multiboard when starting

Rifts Corruption
- wrong create trigger was used, fixed and it should now work
- Cinematic will start when preparing for RIFT closing
- Valeria + Player and companions are move near Aradion when preparing for RIFT closing
- Aradion should cast life drain based channel spell on DummyTargetUnit
- Added enabling fail conditions (Valeria or Aradion) dies to triggers upon quest start
- Added disabling fail conditions (Valeria or Aradion) dies to triggers upon quest complete

Fading Sparks
- changed Rod to cause attack type Spells and damage type Normal when using of Mana Wraith

CinematicMover
- Added distance check in MoveCompanionCallback
- Added distance check in MoveTamedCallback
Added new constant:
>>> MAX\_MOVE\_RANGE = 1200.0 - Controls when to skip moving companions/pets during cinematic start
- Kept existing constant:
>>> MAX\_RETURN\_RANGE = 1200.0 - Controls when to skip returning units after cinematic ends
- Updated functions:
>>> MoveCompanionCallback - Now uses MAX\_MOVE\_RANGE for distance check
>>- MoveTamedCallback - Now uses MAX\_MOVE\_RANGE for distance check



---



=================================================================================================================================================
Epic Quests 19.10.2025 - List of Actions:

DInv & DEquipment system(s): Serious BUG - Some item may (Spring Water 3rd slot in this case) lose charges / get disappeared - Is it because of some function?
- Bugs found:
>>> 1. CRITICAL BUG in Item Swapping (DInventory.j, lines 857-865)
>>> 2. CRITICAL BUG in Equipment Transfer (SharedDInvLib.j, line 4829)
>>> 3. Item Stacking Issues (SharedDInvLib.j, lines 3615-3670)
>>> 4. 4. Missing Handle DB Updates in Unequip (SharedDInvLib.j, line 4683)
- Bugs Fixed:
>>> Item Swap Bug (DInventory.j)
Problem: When swapping items, the system never updated the slot tracking database
Result: Items appeared to move but system thought they were in old slots → deleted wrong items
Fixed: Now updates DInvItemHandleDB[].integer[2] for both items after every swap

>>>Equipment Transfer Bug (SharedDInvLib.j)

Problem: Code accessed item data AFTER removing it from inventory
Result: Corrupted references, unpredictable item loss
Fixed: Now stores item handle ID before deletion
>>> Missing Slot ID Storage (SharedDInvLib.j, 2 locations)

Problem: When storing items, the slot ID field was never set
Result: System couldn't reliably locate items for later operations
>>>Fixed: Now properly stores slot ID in integer\[2] field

Vanguard Vale / Elarindor story acts
- more lines for Rifts of Corruption quest
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Valeria Dies
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Aradion Dies
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Prepare
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Combat
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual CombatIncoming
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual FinishOne
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual FinishAll

Vanguard Vale
- terraining

Mana Crystals
- Created "Mana Crystal" unit
- Logic for spawning mana crystals
- Logic for mining mana crystals (including random explode chance)
- adjusted scale and height of vein glow for mana crystals
- debug spawn: manacrystalstest

Aradion
- Adjusted quests for new Reputation system, DInv item check & remove functions
- Created Fading Sparks quest and related events (Rod that is used to harvest the essences and its associated triggers)
- Created Rifts of Corruption quest and related events

Valeria
- Adjusted quests for new Reputation system, DInv item check & remove functions

Note on abilities:
- Item abilities need to be temporalily made non-item ability to change the Description tooltip that will be shown in-game!

Reputations system
- Disabled debug messages

UnitExperience system
- Disabled most debug messages

RangeCheck
- BossMordax and BossVoidEntity; fixed wrong player (Player1) instead to be Player0

SharedDInvLib
- modified GetDInvItemChargesByTypeThreshold because it only worked for more than 1 charges item-type check
- Campaign classified items should now stack

Crypt
- Attemp to fix crash at Crypt Trap1

=================================================================================================================================================
Epic Quests 18.10.2025 - List of Actions:

Redone storyline / voicelines for Vanguard Vale / Elarindor story acts
- still needs heavy editing before advancing to creating the voice files / quests
- Now should be able to edit/make voicelines/quests/events until the quest "The Witch's Smile"
- WIP: Continue from Aradion / Valeria quests

Crypt Trap
- edited trap trigger



=================================================================================================================================================
Epic Quests 15.10.2025 - List of Actions:


DummyUnits
- set Art - Backswing = 0.00.
- set Cast Point = 0.00
- set Speed Base 0
- set Movement Type = None

UnitExperience
- added function ForceLevelUp
- added debug to levelup pet with " debug pet levelup "
- added debug to retrieve pet xp to level with " debug pet status "

Terraining
- Crypt; walling / trap testing
- Elarindor (walls)

RangeCheck
- new library that provides functions to check the range from a unit or point to the closest unit owned by a specified player.




=================================================================================================================================================
Epic Quests 14.10.2025 - List of Actions:

Reminder: RUN " debug aidisablemainstates " to disable Ai

BoomBrothers
- added safety instructions item to "Mandatory Training"
- BoomBrothers EDIT / SOUNDS/CAMERAS/CINEMATIC SETTINGS/QUEST CREATION - continued working on THIS > Mostly done
>>> Need to edit still: Cameras, cinematic settings, quest creations, DInv \& DEquip related item removal from inventory and checking

Dragonpeaks
- Testing adjusting fog

HealEngine
- Disabled trigger "Heal Adjust On Damage"
- Disabled trigger "Heal Adjust After Damage"
>>> These one caused atleast Nazgrek have "Healed XXX" texts...
- set in library: "IS_NATIVE_REGEN_SELF"   = true

UnitExperience
- Will only remove units that are: Have a valid Custom Value (id > 0), AND Are actually registered in the XP system (registered.boolean[id])
- Changed the registration logic to initialize the unit with 0 XP at their current level, rather than calculating cumulative XP. This way:
>>> E.g., Unit registers at level 6 with 0 XP
>>> They start fresh and need to gain XP to progress to level 7
>>> No immediate level-ups upon registration

Imported:
- Unit models
>>> Skeleton
>>> SkeletonNaked
>>>>> These should replace regular skeleton units
>>> Dwarf Prospector Gehn.mdx


- Axes;
>>> Axe\_1H\_Flint\_A\_01
>>> Axe\_1H\_Hatchet\_A\_01
>>> Axe\_1H\_Hatchet\_A\_02
>>> Axe\_1H\_Hatchet\_A\_03

- Fires
>>> LargeBuildingFire0, 2, 2
>>> SmallBuildingFire0, 1, 2

-Staves
>>> Stave1, 2, 3, 4, 5, 6, 7, 8, 9

- Tools
>>> itemWeaponAxe1.mdx"
>>> itemWeaponBroom.mdx"
>>> itemWeaponHammer.mdx"
>>> itemWeaponPick1.mdx"
>>> itemWeaponPitchfork.mdx"
>>> itemWeaponRake.mdx"
>>> itemWeaponShovel.mdx"
>>> itemWeaponWrench.mdx"
>>> WeaponAxe1.mdx"
>>> WeaponBroom.mdx"
>>> WeaponHammer.mdx"
>>> WeaponPick1.mdx"
>>> WeaponPitchfork.mdx"
>>> WeaponRake.mdx"
>>> WeaponShovel.mdx"
>>> WeaponSickle1.mdx"
>>> WeaponWrench.mdx"
>>> ... And also suitable Icons for these models

- Swords
>>> Sword\_Bronze
>>> Sword\_Ebonite
>>> Sword\_Iron
>>> Sword\_Steel
>>> Almalexia\_Scimitar
>>> Bipolar\_Blade
>>> Chrisamer
>>> IceMonarch
>>> Umbra
>>> Sword of Death

Shields
>>> Buckler\_Damaged\_A\_01.m2"
>>> Buckler\_Damaged\_A\_02.m2"
>>> Buckler\_Oval\_A\_01.m2"
>>> Buckler\_Round\_A\_01.m2"
>>> Shield\_Crest\_A\_01.m2"
>>> Shield\_Crest\_A\_02.m2"
>>> Shield\_Crest\_B\_01.m2"
>>> Shield\_Crest\_B\_02.m2"
>>> Shield\_Crest\_B\_03.m2"
>>> Shield\_Engineer\_A\_01.m2"
>>> Shield\_Horde\_B\_04.mdx"
>>> Shield\_Horde\_B\_03.mdx"
>>> Shield\_Horde\_B\_02.mdx"
>>> Shield\_Horde\_B\_01.mdx"
>>> Shield\_Horde\_A\_04.mdx"
>>> Shield\_Horde\_A\_03.mdx"
>>> Shield\_Horde\_A\_02.mdx"
>>> Shield\_Horde\_A\_01.mdx"
>>> Shield\_Engineer\_C\_01.mdx"
>>> Shield\_Engineer\_B\_01.mdx"

Multicategory weapons
>>> Adamantium\_Claymore.mdx"
>>> Adamantium\_Mace.mdx"
>>> Adamantium\_Shortsword.mdx"
>>> Adamantium\_Spear.mdx"
>>> Adamantium\_WarAxe.mdx"

Maces
>>> Mace\_2H\_Spiked\_A\_02\\Mace\_2H\_Spiked\_A\_02.mdx"
>>> Mace\_2H\_Spiked\_A\_03.mdx"
>>> Mace\_2H\_Spiked\_B\_02.mdx"
>>> Mace\_2H\_ZulGurub\_D\_01.mdx"
>>> Mace\_2H\_Stratholme\_D\_02.mdx"
>>> Mace\_2H\_Spiked\_B\_01.mdx"
>>> Mace\_2H\_Standard\_A\_02.mdx"
>>> Mace\_2H\_Standard\_A\_03.mdx"
>>> Mace\_2H\_Standard\_A\_01.mdx"
>>> Mace\_1H\_Blood\_A\_01.mdx"
>>> Mace\_1H\_AhnQiraj\_D\_03.mdx"
>>> Mace\_1H\_AhnQiraj\_D\_02.mdx"
>>> MaceNaxxramas01.mdx"
>>> MaceBlackWing01.mdx"
>>> MaceBlacksmithing03.mdx"
>>> MaceBlackWing02.mdx"
>>> MaceCoilfang01.mdx"
>>> MaceAhnQiraj01.mdx"
>>> MaceHellfire.mdx"
>>> MaceBlood02.mdx"

=================================================================================================================================================
Epic Quests 13.10.2025 - List of Actions:


UnitExperience -v3
- Updating

Tamed Unit Dies
- Changed pause to be after animation to try to solve why Stand animation gets stuck for tamed unit

Imported:
- HarvestMana model
- Mythic Storms models
- Overhead Buff Pack models

Taming
- should now take 75 % more dmg during taming
- new tame issue not registering should be fixed now

VeinGlow
- should now be correctly positioned in Z height

UnitHider V3 worked, but disabled for now,...

Dead Woods
- terraining (draft)


=================================================================================================================================================
Epic Quests 12.10.2025 - List of Actions:

Major updates:

UnitExperience -v3
- Now using custom value of unit vs. previously unit handle
- massively updated the system, to also include unit-type predefined stats, e.g., turtle having more HP / block per level vs. tiger etc.

UnitHider v2
- revamped the whole system to use Table by Briebe and TimerUtils (unsure about this)
- needs to be tested is it now useable all the time
- Disabled for now as there are issues with:
>>> UnitHider: not working correctly - it hides most, it seems to hide units very slowly
>>> UnitHider: severe lag introduced when now in use

Tamed Unit - multiboard
- Stats will now be added initially when pet is added to multiboard

UnitStats v1
- jass library version created and old GUI version disabled for now
- also added HIT stats, although for unit may not be used...

Old bags systems related
- Disabled trigger "Bag Follow"
- Disabled trigger "Bag Add"
- Preplace bag unit deleted
- Disabled bag related variable setting in Initialization and Init 01a Units triggers
>>> To be replaced with new logic that will expand DInv slots
>>> Also DInv initial slots should be like 6 or 12 slots

EDIT / SOUNDS/CAMERAS/CINEMATIC SETTINGS/QUEST CREATION
- Intro Cinematic -> Done
- BoomBrothers -> started


=================================================================================================================================================
Epic Quests 11.10.2025 - List of Actions:

Pet related
- Shadowclaw will now be vulnerable when invited back into the group (as TamedUnit)
- Pet crit, block, dodge, hit, spell power are now shown in multiboard
- Pet values are correctly cleaned after pet removed from multiboard
- Pet death counter functionality added

UnitExperience
- Testing with different methods why only the 1st unit register works
- Testing filter methods to reduce lag for XP gaining when unit dies near
- The library left in error state - needs fixing

Dark Shamans (Boss Scorchion)
- Removed IsUnitAlive(CV) check from Reset trigger - needs testing that the Reset trigger works correctly


=================================================================================================================================================
Epic Quests 10.10.2025 - List of Actions:

Reputation System
- updated library; multiboard silently failing

Shadowclaw Stats trigger disabled as now using generic UnitExperiece stats increase logic

BossScorchion
- Dark Shamans should not correctly stay in combat and not reset in the middle of combat (wrong logic in the loop)

Vanguard Vale
- terraining
- created B yellow version of Bush
- added brambles04 and bushes around the Vanguard Vale trees

Tame Beast Start
- added more units that can be tamed (unfinished)

Tamed Units animation
- tried to fix stuck animation after death (test)

Tamed Units level up
- added triggr MultiboarUpdateLevelTamed to be used by UnitExperience system when unit levels up

UnitExperience
- added ScaleUnitStats function that will increase the following stats of the pet;
>>> armor
>>> hp
>>> hp regen
>>> min dmg
>>> max dmg
>>> secondary stats; block, crit, hit, dodge 
- Still to be decided whether this is good way to increase stats, also is there possibility of very overpowered pets at high levels?

CinematicTrailer1
- testing FoV 120


NOTE: CRASH UPON SAVE!!!!
- all these editions below not saved!
- causer: UnitExperience system! Some incorrect function usage perhaps
- Redone the edits...

=================================================================================================================================================
Epic Quests 9.10.2025 - List of Actions:

Quest Hashtable System
- Added reward Reputation with Faction to the system
>>> Note: needs to be implemented to already created ones!

Reputation and Stats -dummy units
- created
- setting variables at Init 01a Units
- testing to use these to Open either multiboard Reputations or Stats
- NOTE: Has to be taken into account possibly in many triggers...

Pets
- Tamed pet should now be added to focus unit group Nazgrek or Zulkis depending who was the "tamer"
- Pet name should now update after renaming pet
- pet level should be erased from multiboard when kicked out
- pet level should now update correctly to multiboard
- if the pet was previously registered to UnitExperience system, XP is just enabled again, not registered again

UnitExperience
- pet level will be taken into account upon registering to the system

Invite / Kick Companion
- Shadowclaw should now be able to be invited to group
- Shadowclaw XP is just enabled again, not registered again
- kicking TamedUnit will disable it's XP gain in UnitExperience system

Reputation system
- fixed incorrect index using in loops from "0" to "1"

Imported WoW models wit fixes to "head" attachement point
- nazgrek
- elf-sorcerer (Evil witch elf illusion)
- magister-duskwither (Aradion)
- dark-ranger (Valeria)

Imported (finally) big amount of Icons for items to be used
- axes
- bags
- belts
- boots
- boxes and barrels
- bracers
- chests
- cloaks
- cloth and leather
- food
- gloves
- hammers
- heads
- helmets
- herbs
- keys
- maces
- mail
- necklaces
- other
- pelts
- potions and bottles
- rings
- shields
- staves
- swords

Imported following item weapon models and set as ability attachement items for future item creations:
itemweapons\Ashkandi, Greatsword of the Brotherhood.mdx
itemweapons\axe_1h_pvehorde_d_01_Green.mdx
itemweapons\axe_1h_pvehorde_d_01_red.mdx
itemweapons\Betrayer of Humanity.mdx
itemweapons\Blade of the Warlord - D3.mdx
itemweapons\Bloodmaw Magus-Blade.mdx
itemweapons\bloodrazor.mdx
itemweapons\Bonereaver's Edge.mdx
itemweapons\Crux of the Apocalypse.mdx
itemweapons\Deadly Strike of the Hydra.mdx
itemweapons\Iridal, the Earth's Master.mdx
itemweapons\jelly-sword.mdx
itemweapons\Kalimdor's Revenge.mdx
itemweapons\Kang the Decapitator.mdx
itemweapons\MaldraxxusLordAxe.mdx
itemweapons\Seraph's Strike.mdx
itemweapons\Shin'ka, Execution of Dominion.mdx
itemweapons\Starshatter.mdx
itemweapons\Stave_2H_Jeweled_D_01.mdx
itemweapons\sword_1h_long_d_03.mdx
itemweapons\Syphon of the Nathrezim.mdx
itemweapons\Teebu's Blazing Longsword.mdx
itemweapons\The Gidbinn.mdx
itemweapons\The Turning Tide.mdx
itemweapons\The Widow's Embrace.mdx
itemweapons\Tomb Reaver .mdx
itemweapons\Verigan'sFist.mdx
itemweapons\Whirlwind Axe.mdx


=================================================================================================================================================
Epic Quests 8.10.2025 - List of Actions:

Reputation system
- continued creating the jass library and now compiled without errors
- will need proper testing; debugging
- show multiboard: debug repmb show
- hide multiboard: debug repmb hide
- multiple edits
- added possibility for unit type factions - e.g., neutral hostile gnolls as faction etc.

Patrol System
- V2 using Table and TimerUtils is under draft

debug changeowner -command added
- changes the selecte unit(s) to player 1 ownership

UnitExperience V2
- fixed not giving any XP - missing initializer Init at the library header...

Multiboard (stats)
- reverted: - MultiboardCreate on map init vs. previously after 1s game time

Companion Invite
- added inviting Shadowclaw possible if player doesn't have any tamed unit

FloatingTextTagSimple
- added boolean to control if we want the text to drift upwards or not
- added boolean to control if we want the text to follow the unit

Tamed Unit Dies
- floating text tag should now remain still with new modifications to FloatingTextTag.create function

Mordrax
- added "death flight" when Mordrax has been defeated


=================================================================================================================================================
Epic Quests 7.10.2025 - List of Actions:

Reputation system
- Started drafting reputation library in vjass that will replace the current draft reputation system
- Note: May require intensive testing and good API for quests to add rep properly
- Idea is for the GUI triggering to only call ADD or REMOVE REP in quests or events, death events will be handled by the system internally
- ADDING or REMOVING REP by quest should not be linked to other functions? only killing?
- Continue editing the LIBRARY

Tamed Units
- fixed wrong UnitExperience register unit when Finishing tame beast
- when kicking Tamed unit, it's XP will be disabled but it can be continued as long as that unit stays alive
- fixed some multiboard tamed unit related bugs

UnitExperience
- added function UnitExperience_DisableXP
- V2 that should be more lag-free and perform better utilizing Table under testing

Tame Beast -abilities
- changed Hit points drained to 0; note that it can affect the unit not attacking the taming unit

Mordrax
- created voicelines for combat and register to ExSound
- triggered voicelines to Boss Mordrax

Models uploaded/updated
- old Nazgrek model replaced
- new elf model: elventowersilithus01.mdx
- Faerie Dragon ghost form: FaerieDragon_Ghost.mdx
- elf sorcerer model added (witch illusion): elf-sorcerer.mdx
- elf statue: StatueofAzshara1.mdx

Sound files (NOTE: IMPORTANT) <<<<<<<<<<<<<<<<<<<<<<<<
- removed all imported voicefiles except AIHero lines for now
- remove reason: now using external sound files that are called by ExSound system
- note: that most sounds/cinematics wont work, because need to use ExSound!
- copy style for older cinematics/dialogues from Grum/Aradion for example, check the camera / DInv stuff as well.

CinematicMover
- edited Shadowclaw out, and use only TamedUnit / RevivalTimerPet
- pets dont really die, so we have to use "fake" triggers
- using trigger Tamed Unit Dies (to "kill" pet) and triger Tamed Unit Revival to "revive" pet

Multiboard (Stats)
- MultiboardCreate on map init vs. previously after 1s game time
>>> Reason: Reputation system uses/calls udg\_Multiboard (stats)

Vein Glow
- now using position of vein unit instead of attachement point, as there were not attachement point for OreVeins or Crystals

=================================================================================================================================================
Epic Quests 6.10.2025 - List of Actions:

CinematicMover
- added debug commands;
>>> debug cinematicmove
>>> debug cinematicmove withpoints (target of current camera view)
>>> debug cinematicreturn
- fixed not moving companions/tamed units in "CinematicMove
- fixed moved CinematicTriggerUnit also returning to init location
>>> Note: It maybe sometimes wanted to move the unit to return location?

Tamed Units (pets)
- Tamed units now won't completely die when killed, instead they are kind of freezed for RevivalTimerPet and after that they are back to normal
- Before this only Shadowclaw was revived, but now all pets share same logic, otherwise leveling pet wouldn't make sense in case they die and progress is lost
>>> Note: Pet Death Animation and animation when Revived needs to be sorted out - How do we play Death animation for the pet and how do we keep the pet staying in paused death animation?
>>> Note: may have to adjust FloatingTextSimple, we want the new floating text to act similarly as the old one; floating slowly above the dead pet

Multiboard
- Added pet level (when new pet is added and update multiboard
- Changed ReviveTimerShadowclaw to ReviveTimerPet

Pets (Tamed Units)
- Added Pet Rename function; player can change the pets name by typing: /pet rename <name>


=================================================================================================================================================
Epic Quests 5.10.2025 - List of Actions:

DestructibleDeathEngine
- created simple destructible death event that utilizes DestructibleRevival system for getting the dying destructible
DestructibleRevival
- added hook after "set argDest = GetTriggerDestructable() -- call FireDestructibleDeathEvent(argDest)

Destructible Item Spawn
- created first trigger to try spawn items from dying destructibles - note how to get level area of destructible?
- createde various range of Crates and use Editor suffix (Level 1-5) etc.
- Note: do for barrels etc.
- Note: Fill the map with zone / specific destructibles
- Note: Drop rate could be lower? / less crap?

CinematicMover
- once again fixing companions and tamed units not storing...

Floating Spell Event Text
- Once again trying to use Arcing TT Linear function (will see if this one still lags)

FloatingTextTag
- created similar style library for simple text tags

Vanguard Vale
- terraining

Sirensong
- terraining

Morthun
- Added patrol slow speed and when engaged normal speed triggers
- adjusted animation walk and run speeds

Mordrax
- removed movement speeds settings as PatrolSystem now handles it on its own

Valeria
. added ValeriaEncounterReset Boolean to prevent random movement triggering from periodic timer

Cloned more voices for future quest givers and bosses etc.

Boom Brothers
- Added CinematicMove related positioning - to test how companion units are moved (if at all)

=================================================================================================================================================
Epic Quests 4.10.2025 - List of Actions:

UnitExperience
- fixing issues with lag / wrong xp gain

CinematicMove -library
- editing the library

Morthun
- Mini boss added to Verdant Plains wandering around the area

Vanguard Vale
- terraining

Vein Glow
- Fixed special effect not showing
- Note: there mighty be issues with Crystal and Ore vein spawn triggers as they use utilize same locations when spawning at once, therefore possibility of point being null and the ore spawning at the center of the map

Arcing TT
- again, some fixing (try)

DestructibleRevival
- added DESTRUCTABLE DEATH CALLBACKS / hook to when destructible dies
- to be used in trigger(s) to spawn items from crates, barrels, etc.


=================================================================================================================================================
Epic Quests 3.10.2025 - List of Actions:

UnitExperience
- some fixes
- debug messages to help checking the system

Arcing TT
- changed camera distance to 2500 from 1200

CinematicMove -library
- to make simple cinematic storing / restoring of units for and after cinematic
- CinematicTriggerUnit = Nazgrek (Quests of Grum trigger)
--- this basically handles around what unit things will be moved
- unfinished yet and definitely needs some testing etc. setting up


=================================================================================================================================================
Epic Quests 2.10.2025 - List of Actions:

Floating Spell Event Text
- made some modifications fix lag caused by heavy stringHash color conversion before creating Arcing text

Arcing TT
- some fixes

=================================================================================================================================================
Epic Quests 1.10.2025 - List of Actions:

DInv & DEquip system
- HeroItemCheck and HeroItemCheckBoth (Nazgrek and Zulkis) added as "addon"
>>> These help fastly check whether either hero has item of type and with amount for quests/dialogs etc.
- Note on getting item of type from hero Inventory:
>>> In SharedDInvLib.j there are also: DInvUnitHasItemType and DInvUnitGetItemSlotOfFirstItemByItemType original functions
>>> We currently utilize our own GetDInvItemChargesByTypeThreshold
- Added "RemoveDInvItemChargesByType" function
>>> This is to be used together with HeroItemCheckBoth or HeroItemCheck

Arcing TT
- added createLinear method for simple floating texts
- changed this: "set .t = duration" >>> "set .t = TIME_LIFE" like originally is to try fix texts disappearing

Grum Bloodfang
- added proper item checks for Whelps of Destruction, Dragon Eggs and GrumDialog completion checks

Quest Icon System V1.0 -> V1.1
- fixed not properly saved and handled minimap ping icons

DInv and DEquip initialized for Zulkis in triggers (unfinished / need remake) Giving The Letter Q / Giving The Letter Q debug (command "debug givezulkis")

ExMusic
- wait before starting new track increased from 1.00s to 2.00s to reduce lag caused by music, might not help at all

Zones
- Added ZoneDayNightEvent Boolean to prevent "Entered Zone XXX" appearing during DayNightEvent

=================================================================================================================================================
Epic Quests 30.9.2025 - List of Actions:

GetItemCost -added
- use GetItemTypeIdGoldCost to get item cost (gold)
- use GetItemTypeIdWoodCost to get item cost (lumber)
>> Note: still cant use them as DInv system says undeclared function - something needs setting up even though setting GetItemCost as "requires"

DInv & DEquip system
- Stacking now works without player needing to press "Infite Stacking"
- SharedDInvLib.j
 	>>> Changed the texts and the order of texts in function UpdateDEqCSheet
 	>>> Added colors to the stat texts
 	>>> Note: the coloring / stat names have to match also on the item itself vs. DEqCSheet
 	>>> GenerateDEqTooltip function:
 		>>> Modified texts + some modifications to showing the numbers
 		>>> If item contains ability with string containing "EQUIP" it wont be displayed

- DInventory.j
 	>>> function InitializeDInventoryForUnit
 		>>> added: set PlayerStackingMode[pid] = 2
 		>>> this should allow stacking of charges.

- Spell damage changed to Spell Power (now there can be "+ XX % Spell Power" (perc amount) and "+ XX Spell Power (flat amount)"

- Spell power flat amount increase needs to be created as system;
 	Stat_SpellPowerPerc[ ] 	- Original variable
 	Stat_SpellPowerFlat[ ]	- New variable

- trigger "Stat Spell Power Damage" -added flat spell damage increase
- trigger "Stat Spell Power Healing" -added flat spell healing increase

Block Chance
- fixed incorrect damage amount block; previously blocked only 25 % when it should be other way around and block 75 %
- TBD: Block reflection damage of DMG event amount x 0.25 that is caused by block to the DMG event source

UnitExperience
- created to system for unit experience (tamed pets in mind)
- first iteration only considers increasing Shadowclaw's stats when it levels up - other pets should also level up, but stat increase are not implemented

Ore Veins and Crystals
- Added glow effect to some veins, upon death the effect is removed


=================================================================================================================================================
Epic Quests 29.9.2025 - List of Actions:

Item Unstack system
- Added debug messages
- Fixed item disappearing when splitting charge
- Note: split charge item will go from vanilla inventory to the new Custom inventory
- Note 2: should the unstack/split function be inside the new custom inventory?

Heal Engine
- DRAFT (WIP): Stat Healing bonus -trigger: If unit has Spell bonus, it should now adjust healing received

DInv & DEquip system
- modified stat names in DEquipment.j
- modified item slot names in DEquipment.j
- Note: Modify what the stats do in "SharedDInvLib.j"
>>> added definitions to add Crit, Dodge, Block, Hit, Spell Power
- DInventory.j
 	>>> change PlayerStackingMode[24] to PlayerStackingMode[1]
 	>>> Maybe need to test whether it must be 1 or 2?
- SharedDInvLib.j
 	>>> Added max charge functionality by using Item levels as charge
- SharedDInvLib.j
 	>>> Modified function UpdateDEqCSheet for correct percentage Crit, Dodge, Hit, Block, Spell Power, ...
- SharedDInvLib.j
 	>>> Added function to easily returns the number of charges of a given item-type carried by a unit.
 	Usage:
 	DInvUnit = unit
 	DInvItemType = item to be searched
 	DInvItemAmount = how many items
 	set udg_DInvItemCarrierHasItems = GetDInvItemChargesByTypeThreshold(udg_DInvUnit, udg_DInvItemType, udg_DInvItemAmount)

ExMusic
- Added stop with fade with wait + then stop music immediately to PlayMusic function to prevent lag spike occurring

Following doodads has been imported:
Aiur_Plantlife_00
Aiur_Plantlife_01
Aiur_Plantlife_02
Aiur_Plantlife_03
Aiur_Plantlife_16

Elsecaro_Curtain1x1_00
Elsecaro_Curtain1x1_01
Elsecaro_Curtain1x1_02
Elsecaro_Curtain1x1_03
Elsecaro_Curtain1x1_04
Elsecaro_Curtain2x2_00
Elsecaro_Curtain2x2_01
Elsecaro_Curtain2x2_02
Elsecaro_Curtain2x2_03
Elsecaro_Curtain2x2_04
Elsecaro_Curtain4x2_00
Elsecaro_Curtain4x2_01
Elsecaro_Curtain4x2_02
Elsecaro_Curtain4x2_03
Elsecaro_Curtain4x2_04

credits Renn01

These are mainly to be used in Sirensong zone and subzones


=================================================================================================================================================
Epic Quests 28.9.2025 - List of Actions:

HealEngine
- IS_NATIVE_REGEN_SELF set to false
- HealingDisplay; added condition HealSource Equal to No unit
- RegenerationDisplay; added condition; (HealTarget has buff Warmth ) Equal to False
>>> This maybe redundant with IS\_NATIVE\_REGEN\_SELF

Blood Splats
- added condition to return (skip creating blood splat) if the dying unit has "Locust" (Aloc) ability

Item Drop System
- added condition to return (not spawn any item) if the dying unit has "Locust" (Aloc) ability

DInv
- added wait 0.05s to GetDInvItemChargesByTypeThreshold to help system see proper charges when unit acquires item
- The wait worked, but is it good practice - no, but can be thinked later maybe...
>>> Note: waits should not be used here, maybe use timer and refresh?

Item Unstack system created and added

=================================================================================================================================================
Epic Quests 27.9.2025 - List of Actions:

Unit Within Range 1.5 (by Tasyen - New System added)
- all current range check (that most currently leak position) should be replaced with this?
- remember need to register unit again if the unit dies and respawns

Void Entity
- fixed voicelines triggers spamming

Boss Scorchion
- Fixed following issue: After engage reset - Scorchion is not set vulnerable again
- Fixed following issue: Darkshamans during engage voicelines?
- NOTE: To be fixed: When engage reset is triggered, dark shaman voiceline should only be played if player unit is near
- NOTE: To be fixed: last dark shaman will stay for voiceline and then die before Scorchion boss fight starts
- Added: Extra high HP regen to Scorchion before Boss Fight and set HP regen to normal when the fight starts and set to High again when combat resets

Destroyer Inventory - Charges
- Testing how to retrieve charges of item type from the custom inventory with added API function "GetUnitItemChargesByType" to SharerdDInvLib
- Test on trigger Quest Whelps of Destruction Update - the quest should now update when player picks the 10th item


Imported doodads specifically for Vanguard Vale zone in mind

Debug
- added debug that will see what dying dummy unit is
>>> Solve what unit is causing these blood splats spawning everywhere

=================================================================================================================================================
Epic Quests 26.9.2025 - List of Actions:

Dark Shamans (by BossScorchious)
- Added voicelines Engage, Start, Reset, Distant (filmed from far away)
--- NOTE: need to trigger last shaman dying and stopping animation for the line and then "finish" him off before Scorchion starts fully

AI Heroes
- Closest unit functions (Rogue, Warrior, Paladin, Engineer (shredder form); Leak inside "Pick every unit in Closest_Group" removed (cascading point leaks)
- dsiabled debug messages from AI actions

AI Heroe - New vJass system on develop
- Aim is to be more event-driven logic, and easy to maintain
- basic actions should be functions that can be easily bug fixed etc.
- Must be lag free vs. current Logic tree style made in GUI triggers is heavy process on map

Disabled most found debug messages from Abilities

BossScorchion
- disabled debug messages (dark shamans Engage Reset)
- disabled debug messages (Fire Orbs Start Q, Loop, End)
- disabled debug messages (Temporal Instability)
- disabled debug messages (Fire Ward)

Cinematic ON
- enabling / disabling Isometric Camera disabled with bool "AlwaysFALSE" - this interfered with old cinematic dialogues

Void Entity
- Added chat related triggers

Note on Lag previously known to be caused by AI Heroes logic
- Now no lag spikes - issue was "closest unit function point leaks"

=================================================================================================================================================
Epic Quests 25.9.2025 - List of Actions:

Inventory systems
- EasyItemStacking system disabled - it interfered with DestroyerInventory system
>>> Note: may need to enable stacking from gameplay constants

Void Entity
- started adding some triggers

=================================================================================================================================================
Epic Quests 23.9.2025 - List of Actions:

Cinematic Trailer
- created script for creating cinematic teaser trailers
- played with command: " trailer1 "
- with snow: " trailer1snow "
- Using command:
--- disables/releases Isometric camera lock
--- disables AI heroes
--- Runs Cinematic ON trigger
RUN debug aidisablemainstates to disable Ai

AI Heroes lag NOTE
- Note: when multiple AI heroes spawned, fps dropped to 2 fps.
- There is definitely somethings very wrong there...

PDMS Periodic Damage added
- not configured yet / nothing using it atm

NOTE new lag:
- some system is causing periodic lag - PDMS?

A-B cam pan did not work

AI Heroes
- Will now start spawning only after Intro Cinematic

Imported Entropius model by Sarsaparilla
- to be used as Void Entity boss at Vanguard Vale

Started testing DestroyerEquipment custom definitions
- with Colossus loot

Arcing TT by Maker
- Modified to prevent seeing far away occurring floating texts
- added RGB
- DamageEngine, HealEngine, FloatingSpellEventText now use the modified ArcingText

=================================================================================================================================================
Epic Quests 22.9.2025 - List of Actions:

Destroyer Inventory & Equipment System
- testing again
- apparently previous lag / unit pathing errors were caused by some getWorldBounds / PlayableMapArea related functions?
- Works after these modifications DConfigurationArea:
--- boolean AutomaticallyAddHeroesToTheDEqSystem = FALSE (default TRUE)
--- boolean AutomaticallyAddHeroesToTheSystem = FALSE (default TRUE)

TasQuestBox
- Added
- Initial idea to use for quests, but probably too much rework to current Quest system?
- To be used for Zone descriptions etc.? / Info?
>>> If used for info/general/etc. then normal quest dialog could be changed to have Normal quests and daily quests separated?

Valeria
- Token of Love triggers fixing
- Lost Supplies triggers fixing
- Added patrol after Ranger Missing is completed
--- NOTE: Neutral passive cant Patrol because it will always return to its initial location - Either way need to utilize some PlayerX for the Valeria, so that she attacks hostile units...

ExMusic
- Preload function changed to similar as in ExSound (all music files preloaded and played as "sounds"
--- NOTE: Umm... now music files dont work at all - reverted to old style which still doesn't completely preload music files

ShowUnitLevel by Tasyen
- Added

Other minor fixes / terraning Vanguard Vale

=================================================================================================================================================
Epic Quests 21.9.2025 - List of Actions:

Valeria & Aradion & Nazgrek
- Created more voicelines
- Created 3 quests and related voicelines and dialogues for Aradion (wip)

TasInventoryEx
- Added "call TasInventoryEx_ReAddInventories(unit)" to CinematicOFF and Game Start triggers
--- This function needs to be called: after revive/reinc, unpause, channel ability with "disable other abilities", doom ability debuff, Probably for all skills/situations that silence inventories. Right after you unpause the unit tell the system to readd the inventories and items. Otherwise the unit can only fill the main inventory with items (no more additional inventories). - Tasyen

Stealth
- trying to fix spin attack animation (stuck animation when casting stealth when unit not moving)

=================================================================================================================================================
Epic Quests 20.9.2025 - List of Actions:

Valeria & Aradion related
- fixed some issues related to cameras, movements, etc.
- Added Token of Love, Lost Supplies quests to Valeria, some work still need to be done

Cinematic Store/Move units function
- Added pets (TamedUnits unitgroup)

TasInventoryEx
- under testing, issued found with items not being inserted into custom inventory, ...

Stealth
- Now should not break when directly behind the enemy even if close to enemy

Tiles
- Added some new tiles to create variation to zones

=================================================================================================================================================
Epic Quests 19.9.2025 - List of Actions:

Grum Bloodfang
- Fixed some quests related issues
- Drake attack can now occur in the middle of dialogue, and when occurs will interrupt it.

Cinematics
- Added triggers to store and restore player units locations and pet/companion locations
- If CinematicRestoreNazgrek = true -> moves Nazgrek to stored location after cinematic
- If CinematicRestoreZulkis = true -> moves Zulkis to stored location after cinematic
- Currently pet and companions will always be restored to their stored location before the cinematic

Valeria fight / negotiate dialog triggering
- continued editing
- Added more cinematic/dialogue movements/events

Ranger Missing
- added quest related triggers and dialogues

Creep Respawn system
- Added some fix to Creep Respawn trigger to respawn specific Player 19 units

Vanguard Vale
- some lite terraining to sketch the zone

Nazgrek
- Unit model updated once again; could use some torn / fur-like cloak to make it complete?

=================================================================================================================================================
Epic Quests 18.9.2025 - List of Actions:

Inventory system under testing: https://www.hiveworkshop.com/threads/a-modern-inventory-and-equipment-system-prototype.351433/
- Result: game break (maybe related to unit enters playable map area ? - search if there is such function inside jass scripts)
>>> Removed for now....

Updated Valeria, Aradion, Nazgrek dialogues

Mana Wraiths
- Fixed DamageEngine issue with all units being immune to physical dmg

Nazgrek
- Created more greet / farewell lines

Valeria fight / negotiate dialog triggering started (WIP)

=================================================================================================================================================
Epic Quests 17.9.2025 - List of Actions:

Lirael -> Valeria (new name)

Updated Valeria, Aradion, Nazgrek related dialogues

Updated (under testing) Easy Item Stack n Split v3

Mana Wraiths
- Now immune to physical dmg by using DamageEngine

=================================================================================================================================================
Epic Quests 16.9.2025 - List of Actions:

Vanguard Vale elves Storyline
- Drafted storyline, npcs, quests, locations for elf questlne

Imported new models:
- model for Wretched elf
- model for Aradion the Farseer
- model for Lirael Dawnwhisper

Draft for Quests/dialogs/... for:
- Aradion the Farseer
- Lirael Dawnwhisper
- Kaelthir

Added Wretched units

Aradion
- continued dialogs/first quest (WIP)

Mana wraiths
- Made attackable with spells and magic only by discarding "Ethereal" ability and instead use Hardened Skin and Elune's Grace

Kaelthir
- added dialogue and first quest (WIP)

Grum Bloodfang
- fixed issue with voicelines triggerent without player presence in the zone / near

=================================================================================================================================================
Epic Quests 15.9.2025 - List of Actions:

Mana Wraiths
- Added abilities Arcane Bolt, Shadowstep, Siphon Life and Mana

Intro Cinematic
- Switched "Intro Setup" trigger to be after "CINEMATIC ON" Trigger

Grum Bloodfang
- Created voicelines for Nazgrek
- Created more voicelines to Drake attack event

=================================================================================================================================================
Epic Quests 12.9.2025 - List of Actions:

Zones
- Changed Blizzard music functions to call ExMusic system external music files

HeroDeath Animation (WIP)
- Added to try remove hero dissipation animation

ExMusic
- added function to get current track name / index
- added in-game function to display current track name with command " /music current "
- added in-game function to play random music with command " /music random "

Intro Cinematic
- Trying to solve issues with grunts not moving

Mana Wraiths
- added "Ethereal" ability to make them only attackable with spells and magic and also to prevent Blood Splat visual effects for these

=================================================================================================================================================
Epic Quests 10.9.2025 - List of Actions:

Triggers
- Reorganized Utility & core, and main map system triggers to upper part of triggers (after Global variables and Init)
>>> Some systems might still be across the trigger folders, but main systems are now in upper part.


Kodo Beast Drums
- Imported empty KodoDrum1.wav and KodoDrum2.wav to bypass drum sounds (that could be heard with Salamanders....)

DestructibleRevival system
- Added to map with necessary Util systems
>>> Note: Need to configure

=================================================================================================================================================
Epic Quests 9.9.2025 - List of Actions:

Grum Bloodfang
- All voicelines now modified for ExSound -system

ExSound system
- Added all <CURRENT> voicelines to register paths
- removed automatic preload within the code itself, instead map will call preload function manually
- commented out (=disabled) fallback to constant duration if no sound and text is not provided, because sound and/or dialogtext should always be provided

ExMusic system
- removed automatic preload within the code itself, instead map will call preload function manually

PatrolSystem
- removed all debug calls
- Added option to choose what movestyle (order issue) patrol unit has; "move", "attack", "patrol", ...
- Updated all PatrolSystem related calls in WE side to take into account the new movestyle

TravelShip
- Enabled again

Quest updates twice when picking up all required items
- this might be because of EasyItemSystem
--- to prevent this - need to add EasyItem_SystemActive == false in conditions >> TEST

Mordrax
- fixed Reset trigger issue not working
- adjusted attacking flying height

=================================================================================================================================================
Epic Quests 8.9.2025 - List of Actions:

ExSound system
- Added fallback value to ExSoundDuration that will be based on the length of the ExSoundString (if provided), if ExSoundString == null, then use constant value fallback_duration (5s)
- added preload function
- added "takes string dialogtext" to play/playUnit/playPoint functions

Grum Bloodfang
- started doing ExSound -modification - WIP on "Quests of Grum"
- fixed some errors related to quest creation (used TriggerExecute instead of correct ConditionalTriggerExecute)
- Drake attack interval increased
- typo fixed in Whelps of Destruction
- Some other minor fixes to quests triggers

TravelShip
- Temporary disabled UnitAttach to travel ship and using Hide unit instead

Map Init
- Added Preload trigger on map start
- Game start and init related triggers need to be re-organized, its a slightly messy

=================================================================================================================================================
Epic Quests 7.9.2025 - List of Actions:

BOSS Mordrax
- Created WayPoints
- Added PatrolSystem triggers
- Added attacked/attacking start and reset related triggers

Creep Unit Assignment
- Added Mordrax to list
- Added PatrolSystem start trigger calls to relevant unit
>>> Note: one should also call QuestIcon systems for relevant units!

Whelps
- Edited item drop loot tables
- Added dragon related misc items

ExSound -system
- Created first version
- Added testing trigger "exsound test1" that can be triggered with command " exsound test1 " & " exsound test2 " - it should Play Nazgrek_0001 sound
- API:
    call ExSound_Register(key, path)
    call ExSound_RegisterSequence("Nazgrek_", 1, 50, "Pots\\Sound\\Dialogs\\")
    call ExSound_Play("Nazgrek_0001")
    call ExSound_PlayAtUnit("Nazgrek_0002", udg_Hero)
    call ExSound_PlayAtPoint("Nazgrek_0003", x, y)

    call ExSound_Stop()
    call ExSound_PlayAmbience(udg_ExSoundRegion, "ForestAmbience")
    call ExSound_StopAmbience(udg_ExSoundRegionn)

    duration of played sound can be get from variable: udg_ExSoundDuration

Unit Sounds Attacked/Attacking
- Salamander added

=================================================================================================================================================
Epic Quests 6.9.2025 - List of Actions:

Grum Bloodfang
- Drake attack trigger edited
- Updated quest related update quest triggers

ExMusic (external music system)
- Created and under testing

Item Drops
- Whelp Scales drop added
- Scale of Mordrax drop added
- temp Dragon egg drop added

Thornwoods / Emberpeak Highlands
- Slight terraining

Orc Spearthrower
- Added level 12 variant and changed these to Grum location to match zone level units

=================================================================================================================================================
Epic Quests 5.9.2025 - List of Actions:

Grum Bloodfang
- Created voicelines and audio files
- Note: Need to create small lines for Nazgrek
- Created dialog/quest related triggers

Travel system
- Added Cinematic mode for travel (test)
- Note: camera should be freely rotated during the travel
- Note: it should be possible to skip the travel by using ESC key?
>>>> This can be hard to implement, as we would need a way for the PatrolSystem unit to skip it's waypoint
>>>> Maybe can implement function into PatrolSystem with function like PatrolSystem\_SkipToWP takes integer index, etc....


=================================================================================================================================================
Epic Quests 4.9.2025 - List of Actions:

Travel system
- Edited TravelShipB Patrol waypoints / wait times / using PathStyle 0
- Created simple TravelShipB_MovementStart jass script (because of way too many regions, that are more easier to set in JASS vs. GUI...)
- Transport ship speed and turn rate reduced

- Added shipmaster[1] (MOKNATHA) - travel related triggers
- Added logic for when ship arrives at each dock
- Shipmaster (goblin) lines created and imported

Items
- Shovel fixed missing item attachment ability
- Note: looks like shit when attached to unit hand!

Boom Brothers Mine
- Fixed wrong point at AoE barrels of explosives damage at rocks1 & rocks2
- Goblins should return to their init location / area after they are turned back to Neutral Passive

Grum Bloodfang
- Started doing dialogs and quests
- Note: Unfinished Button Pressed in...
- Note: Unfinished DialogOver
- Note: Unfinished Quests

UnitAttch jass script added
- Utilized in TravelShip visualization of Hero being onboard the ship

=================================================================================================================================================
Epic Quests 3.9.2025 - List of Actions:

Imported:
- Potions - various shapes and colors by stan0033
- Shovel model Narberal Gamm (XGM Guru)
- Webbed victim by Zenonoth

ItemDropLocationUnits
- added trigger to drop any not Campaign class item immediately, Campaign class item will also be dropped from the unit after 5s wait (to prevent player misplacing items into ItemDropLocation unit's inventory)

Kribugs
- Added more debug commands to test special effect overhead on Kribugs

Zones
- Zone "entered" text was not shown for Twilight Grove and Serenaglade, because they had old LocalPlayer handle usage, but this was not anymore used thus no message was displayed

FindItemByKeyword
- Fixed wrong string parsing in the function
- Now works with any keyword e.g., "meat", "gnollhead"
- Unsure if this works when keywords is two words; e.g., "Angry Chicken"
- Renamed to "ItemSearch"
- Made as library with private functions and private global variables
- Function now to use: call ItemSearch_FindItemByKeyword(unit, string)

Travel system
- Started drafting this old system...
- Travel Ship Moknatha patrol system utilized to create movement between travel locations
- Added Shipmasters (goblins) on the map
- Added Flight point icons on map for current flight masters (Control Point Ally)

=================================================================================================================================================
Epic Quests 2.9.2025 - List of Actions:

Kribugs
- Added quests
- Made DialogButtons (global) as normal variables to be used
- IMPORTANT NOTE!: Utilize the same logic to other NPCS! - REMOVE THE UNNECESSARY UNIC SPECIFIC DIALOG BUTTON VARIABLES - THIS NEEDS SOME TIME EDITING...
- Added dialogs
- Added function inside Complete Quest 4 to loop-check hero's inventory and first item with the word "meat" will be set as QuestItemTemp item-type
--- Note: this would be better if this was a JASS Script and we pass string e.g., "meat" and the jass function will return back with Item-type
- Fixed wrong quest Discovered/create triggers
- Fixed wrong conditions for "Meat For the Ogre" quest completion dialog button visibility

- added debug command: " debug kribugs questmark " to test create normal quest exclamation mark
- added debug command: " debug change kribugs " to change the kribugs unit

- Test quest Meat For The Ogre - can it be re-done and re-completed?

FindItemByKeyword -JASS function created
- This can be utilized to check if UNIT has item in inventory with specific keyword like "meat"

DialogCamera
- Added IsCameraBlocked function (when destructibles in the way of camera)

ItemDropLocation
- Added debug functions to test how to drop items to its inventory
- Added Init 04b Players - 1s gametime set Player 1 friendly with spells with Player 17

Indicators
- Imported https://www.hiveworkshop.com/threads/target-and-circle-indicator-tc-vfx.349193/
- Imported https://www.hiveworkshop.com/threads/skill-indicator.357350/
- These can be used to indicate:
--- AoE / incoming damage
--- Objective location
--- Item drop location
--- Secret location
--- Quest / event location point of interest
--- etc.

Quest Icon system
- Edited Dummy Icon/marker function

Boom Brothers Mine
- removed range for leave region triggers (for now)
- Added Shredder units
--- Note: Edit the abilities to be unique to Shredder vs. now using Mad Blix abilities

Interface Dialog Sounds
- Added 0.1s wait before playing InterfaceSound

=================================================================================================================================================
Epic Quests 1.9.2025 - List of Actions:

DeatCamera
- Angle adjustd
- Rotating camera 30s --> change to 45s

Neutral Player (Player 17)
- Adjusted Player 1 to have friendly with spells towards Player 17
- This should have effect to be able to place items inside that player units inventory

Player Bounties
- Added player bounties for other players in addition of neutral hostile

ItemDropLocation -unit
- Adjusted model again

Moknatha Battle
- Fixed and edited ogre and orc attack waves triggers
- added craters with Ubersplats

Boom Brothers Mine
- Edited BoomMine AttackWave R7 trigger to have range check before turning the hostile goblins to Neutral Passive

DialogButtons (global)
- Testing using global DialogButton_XXX variables instead of unit specific dialog button variables for KRIBUGS

Moknatha Craters
- Added
- Note: not working / visible

Moknatha Catapults
- make attack speed very slow
- make damage very high - almost instant death if hit?

Zones:
- Note: Serenaglade entered text not working
- Note: Twilight Gtove entered text not working
- Note: see other zones e.g., Riverbane, Sirensong that work

=================================================================================================================================================
Epic Quests 31.8.2025 - List of Actions:

Dialog Camera
- Added NearZ
- Added default cam time, and set to 0 instead of 0.5

Boom Brothers Mine
- more terraining

See more notes at To-Do app....


=================================================================================================================================================
Epic Quests 29.8.2025 - List of Actions:

Sounds
- Imported many Ambient, Interface related sounds
--- To be used for many events player does (like selecting unit) and also ambient sounds for dungeons, lakes, etc.

Dialogamera
- Modified
- Testing with Kribugs
- OutcastJinzun settings may be now wrong...

Boom Brothers Mine
- more terraining
- triggering events

Ambient sounds
- Testing ambient sounds for Zones
--- Note: Need a way to remove the ambient sound from zone that the Player no longer is in / switched to other zone

Interface sounds
- Started creating interface sounds, e.g., levelup, dialog button pressing

NOTE: Test checking how to use local audio files for WE / WC3!

=================================================================================================================================================
Epic Quests 27.8.2025 - List of Actions:

OutcastJinzun
- Camera distance and angle modified
>>> Result: BAD
>>> Camera position seems like its off many units, why?
>>> What would be best all-time use generic camera parameters for dialog NPCs? Note that the location may sometimes be more smaller and could have doodads etc blocking the view

Kribugs
- Deleted IsUnitMoving condition from "Quests of Kribugs" initial check

DeathCamera
- Modified angle/distance etc.

Boom Brothers Mine
- Added draft events for:
--- exploding rocks
--- attacking units (note: Event triggers many times - it should have timer e.g. 360s etc. - also the spawned units should be removed or something and/or not to spawn more units if they are still alive?

=================================================================================================================================================
Epic Quests 26.8.2025 -2 - List of Actions:

PatrolSystem
- Fixed patrol unit not stopping when damaged or attacked or paused

DialogCamera (NEW)
- Added function to use generic DialogCamera that should make dialog cinematic cameras more easy
- NOTE: DialogCamera didn't work - Reason: no camera settings was applied >> DialogNPC was = No unit

Kribugs
- Movement speed increased from 50 to 140
- Added 3 quests
- Added dialog system
- A way to "trade"

Note:
- Something might have gone wrong with BoomBrother triggers - because falsely editing them instead of Kribugs triggers

Outcast Jinzun
- Sounds when issued order "move" added additional conditions to consider only orders o Outcast Jinzun

Raining
- Added FX_Ripples -doodads that can be used with Play Animation Stand - 100 and Death
- These can be preplaced or placed via Special Effect (TBD)

Warlock Blood Pact
- Heal Engine text reads funnily when unit gets Blood Pact aura
---- Is there way to prevent text for this?

Curse of Agony / garrote / and other similar abilities based of "Parasite" will not work when the unit is close to death
- Add triggered damage to kill the unit with DamageEngine? Maybe not...
---- Stacking type of the ability to: "Kill Unit" - TEST

NOTES===
- Camera for Jinzun too close, maybe set distance to 1000?
- Now Jinzun seems to stay and not wander during PatrolSystem_Pause
- Selecting Kribugs did not start anything
- DeathCamera to be more further distance (maybe 1400) + angle can be more +30? Maybe 315?

=================================================================================================================================================
Epic Quests 26.8.2025 - List of Actions:

Outcast Jinzun
- Added PatrolSystem call
- Removed old movement trigger
- NOTE: Sounds triggers does work poorly
-----> Need to add condition "issued order is move" to the sound trigger
- NOTE: Was not properly paused when starting to talk to Jinzun

Kribugs
- Added as Quest Neutral folder
- Added PatrolSystem call
- Removed old movement trigger

### Notes on Patrol System:
- Tested with multiple units, seems to work fine
- unit is not stopped when it is attacked or damaged!


Death Camera
- Works poorly, should disable player control (see in Cinematics - disable control for Player)
- Camera is off compared to that it should be hovering near the dead player unit

=================================================================================================================================================
Epic Quests 25.8.2025 - List of Actions:

Patrol System
- Modified the script
--- NOTE 1: Now it works like it should; the unit can be paused, and will continue where it was going
>>> To be teste with multiple settings and multiple units


=================================================================================================================================================
Epic Quests 23.8.2025 - List of Actions:

Patrol System
- Modified the script
--- NOTE 1: Pause didnt work + no debug msg
--- NOTE 2: Stop didnt work - debug msg came
--- NOTE 3: unit is still going to some nonsense location
--- NOTE 4: Saved WP that is debug messaged from system itself matches with the waypoint location debug msg in GUI trigger

=================================================================================================================================================
Epic Quests 22.8.2025 - List of Actions:

Patrol System
- Added patrol / waypoint system that can be used to set NPC to walk certain path with settings like; how long the NPC waits at each waypoint etc.
--- NOTE: Need to test the system with multiple Patrol NPCs and different settings!
--- NOTE 2: there was issue with WayPoints! (not set correctly?)
--- NOTE 3: debugging the waypoints; waypoints are set correctly, however something wrong with the JASS system itself, as it seems that the NPC is walking towards map center 0.0, 0.0
--- NOTE 4: New version in VSCode to be transferred to World Editor and to be tested....

Boom Brothers Mine
- Continued terrain
- Added Pathing Blockers (Both air & ground)
- Note: next time; lower the torch "lights"

=================================================================================================================================================
Epic Quests 15.8.2025 - List of Actions:

Creep Respawn System - Creep Unit Assignment
- Added JASS script that will be called from Creep Respawn -trigger. This script will assign global unit variable to the last created unit if unit-type matches.
--- The JASS script will be faster to update vs. using the huge and in the end messy custom script wall of text within the respawn trigger itself.

SteamBreath
- Added functions to remove the steam breath effect from dying unit using;
--- function SteamBreath_Death
--- function RemoveSteamEffectUnit
--- function HasSteamEffect

Spirit Shards
- Modified "Revive" ability item ability to false and changed tooltip text to "Revive"
- Changed "Deceased" unit back to Hover
- Changed height from 100 to 75
- Changed scale to 1.5 from 1.2

Revival
- Changed AI hero revival time from 20s to 60s
- Changed player Hero revival time from 20s to 30s
- Added circling camera to pan slowly around the died player hero if:
--- Both Nazgrek and Zulkis are dead
--- Nazgrek dies and Zulkis is not yet playable
- Note: The camera settings need to go back to the normal used by the player when reviving
- Note: The camera should be locked and player should not be able to move the camera during the Death Camera time

Zone Entering
- Changed location of Turn off this trigger, might not affect the trigger firing 2nd time for other unit - needs thinking

Quest Icon System
- modified Boomsite Compliance Ready trigger - see if yellow question mark now for BoomBrothers
- Added dummy quest icon creation / removal to differ from the real quest icon register system:
--- call CreateDummyQuestIcon(someUnit, "normal", 2)
--- call RemoveDummyQuestIcon(someUnit)

Quest Mandatory Training
- Goblin Miners and BoomBrothers follow logic improved; Miners should only follow BoomBrothers without any distance check and BoomBrothers should only follow Nazgrek is the distance is less than 1000, forcing player to "escort" the BoomBrothers
- Mad Blix temp unit spawn location changed closer to entrance (fitting / collision reasons)
- Removed generic timer and replaced with Enters Region to remove BossMadBlixTemp unit

Quest Boom Will Be Back
- EDITED: Cameras dont pan to right location (at least in Quests of Boom Brothers, individual event after pressing Dialog button might need adjustment OR/AND move the Boom Brothers to correct location after turrets are destroyed,...
- NOTE: BoomBrothers should move to BoomBrotherWP0XXX and have new dummy quest available after the turrets / enemies are dead
- EDITED: Quest mark should be yellow question (ready to turn in / quest state 5) when Mad Blix is defeated
- EDITED: After completing the quest - dialog button Boom Will Be Back (completion) is created, when it should not be visible anymore

Boom Brothers Mine Cam
- Camera should change for the first entering OR leaving PLAYER 1 unit
--- Player 2 (AI Heroes) cant make this occur
--- THINK: what about if the other PLAYER 1 hero is outside the dungeon and we click/ change to him? The Camera should change back to normal and when we change to the unit that is inside the dungeon the Camera should change to Dungeon Camera
>>>> This kind of action should also make RUN DNC OUTDOORS / INDOORS AND FOGS etc. depending on where the outside HERO is and where inside dungeon HERO is
>>>>>>>>

=================================================================================================================================================
Epic Quests 14.8.2025 - List of Actions:

Item abilities:
- If the ability is set to "Item ability" true; then its tooltips will be hidden
>>> Item ability must be set to false to modify the tooltip that will be shown when ability is cast

Spirit Shards
- Modified "Revive" ability item ability to false and changed tooltip text to "Revive"
- Changed "Deceased" unit from Hover unit to Flying unit
- Changed height from 50 to 100
>>> Note: this looked worse than original Hover + 50 Height setting and clickability did not improve!

Note on graveyard revive:
- Should the time for revival be something like 60s? or be 30s but have option to "release" the corpse
>>> This would add time to decide whether to use Spirit shard or if AI Hero is close and can resurrect
>>> AI heroes to have longer respawn, e.g., 60-120s time

Quest Icon troubleshooting
- There was unnecessary / improper use of functions like RemoveQuest / UpdateNPC in wrong places;
- Quest Icon Refresh had RemoveQuest, which does delete the quest with ID XXX, so if we want to update quest's status to 5 etc. we cant remove the quest
>>> Use: call QuestIcon\_RegisterQuest -function with same questID to refresh the quest's state.

Creep Unit Assignments -trigger created
- Started mapping units to proper unit variables when they are respawned (e.g., Quest givers, important npcs which Unit variable must be set)
>>> Note: Made first trigger but realized that the Creep Respawn trigger uses local variables that are important to respawn / variable re-assignment and so thus transferred unit assignments into "Creep Respawn" trigger

Debug DayNight
- using "debug daynight" command: it returns FALSE (NIGHT) when it is DAY (6:45) and it should be TRUE
>>> THIS CAN AFFECT CAMPING FOR AI HEROES ETC MANY OTHER TRIGGERS which use Boolean DNE\_IsDay

Zone DayNight
- event seems to work now and will change fog to night setting or day setting when night or day event is fired

Zone Entering texts
- NOTE: Discovered zone + followed by Entered zone when coming with Zulkis after Nazgrek, then it wont refire again
>>> Edit: this only seemed to occur atleast for Riverbane, but e.g. Siresong worked properly

Quest Explosive Crisis
- NOTE: Quest Update Ready to turn in only triggered when Nazgrek had more than 6 Barrels in inventory,
- it did not set the Question mark to yellow (State 5)
- it also trigger 2 times
- Quest Requirement was not completed - but is this wanted (if the player is attacked and thus barrels might be removed, the quest requirement should be set back to discovered)

Quest Boomsite Compliance
- NOTE: Quest mark for Boom Brothers did not change to yellow question mark (QuestState 5)
- NOTE: Quest mark of AtexBlix was not removed
>>> Something probably not correct in QuestIcon System jass

Quest More Hazard Mitigation
- NOTE:Quest is updated twice when Quest item is acquired, is still related to Item Stack system?

Quest Mandatory Training
- NOTE: Goblin miners are not following BoomBrothers / tried to follow but stopped???
>>> They followed BoomBRothers when they were close to BoomBrothers - some InRange typish check logic is now wrong and needs modification
- Note: Mad Blix Temp cant get through the mine to the entrance, too big collision - Ghost visible did not seem to work - change spawn location more closer to entrance
- Note: has to remove the Mad Blix after some time / entering region, because now using generic timer for unit - causes him to die in tunnel which looks poor

Quest Boom Will Be Back
- NOTE: Cameras dont pan to right location
- NOTE: BoomBrothers should move to BoomBrotherWP0XXX and have new dummy quest available after the turrets / enemies are dead
- NOTE: Quest mark should be yellow question (ready to turn in / quest state 5) when Mad Blix is defeated
- NOTE: After completing the quest - dialog button Boom Will Be Back (completion) is created, when it should not be visible anymore

SteamBreath
- NOTE: SteamBreath stuck on even when its not raining!
- NOTE: SteamBreath remains on unit that is dead, it should be removed when the unit dies!

Zone/Dungeon - Boom Mine
- NOTE: No trigger to trigger Sirensong Zone after leaving the Mine! Stuck on Boom Mine fog / etc setting
- NOTE: Add pan camera function

=== LAG PREVENTION NOTE:
use command "debug aidisablemainstates" to prevent AI Hero system causing lag
>>> Testing for longer time the map without AI - theres no lag / spikes - so look for AI system to remove Leaks / etc.

=================================================================================================================================================
Epic Quests 13.8.2025 - List of Actions:

Modular Quests:
- Empty space \n\n added to proper space in Quest Discovered trigger
- Added "- " to all Quest Requirements

Quest Icon system / Quests
- After completing "Explosive Crisis":
--> Quest Grey mark was removed - OK
--> No new "dummy" quest icon marks for Atex Blix and Boom Brothers were created!
--> After getting Boom Compliance quest (CREATE) - both Atex Blix and Boom Brothers have Grey Quest mark (normal quest) - is it wanted?
- Also new quest markers for these quest should be updated when QUEST 1Q1C etc is run at the end (after all the chat)
>>> EDIT: Reason was; using QuestState that was set to 4 (for previous quest), dummy quest icon needs QuestState = 2 - corrected and also placed "New Quest" to place after dialogs (vs. not immediately after completing the quest)

Quest Explosive Crisis
- Added turn on Quest Update and turn off Quest Update calls
>>> This Quest Ready to turn in did not seem to work...

Boomsite Compliance
- Remove quest mark from Atex Blix when all wood collected
>>> EDITED and added Quest Ready trigger that will be run during AtexBlix dialog if all 10 woods are accepted
- Change BoomBrothers quest icon "Ready to turn in" when all wood collected
>>> EDITED and added Quest Ready trigger that will be run during AtexBlix dialog if all 10 woods are accepted
>>> When Quest Update ready to turn in, BoomBrothers dont have any Yellow question mark! 
>>>>>> Reason: Call QuestIcon\_RemoveQuest(unit u, integer questID) was called, this will delete the Quest from NPC, which should not be used but only when completing the quest!

Abilities:
- NOTE: Texts for many abilities wrong e.g., Healing Wave does not match what it heals (base heal amount)

NIGH / DAY + Zones:
- When NighEvent or DayEVent triggers - Run some zone trigger that will check what zone player is in - then run that zones Zone specific trigger
---> might need some array system to run the proper zone! + store where player currently is!
>>> EDITED: added DayNightEvent to run Zone trigger based on what the current Zone/Dungeon the player is in
>>>>> Does not 1st time work, 2nd time works, 3rd time Zone is stuck in NightTime fog setting

Zones:
- Added zoneCurrent and ZoneLast functionalities; Zone trigger must trigger only once, but work other time when coming from other zone
>>> Logic:
>>>>>> First hero to enter a specific zone triggers it.
>>>>>>Any other hero entering that same zone right after won’t trigger it again.
>>>>>>If you move to another zone, that zone’s trigger still works normally.
- Needs to be tested, maybe the setup now is too complicated vs. what the function needed is....

> ZoneCurrent/ZoneLast logic did not work, other unit entering the region also triggered the trigger
>>> EDITED; Streamlined and made the logic much more simpler....

Spirit Shards
- Wrong tooltip / shows Storm Bolt (Level 1) when it should show "Revive Hero" / "Spirit Shard" / "Resurrect"
- Maybe should resurrect the fallen Hero at the location of the resurrecting hero
- Hard to click the "!" unit - maybe make it hover / fly +200 etc. and test if its easier to click?

=================================================================================================================================================
Epic Quests 11.8.2025 - List of Actions:

Boom Brothers
- EDITED: prevent "normal talk" when Quest Boom Will Be Back is discovered
- EDITED: did not stop following after completing quest Mandatory Training
- EDITED: Boom Will Be Back could not be completed after Defeating Mad Blix -> no dialog button to complete

AtexBlix
- EDITED: did not fit through mine pathing blockers to come at the entrance - need to at abilty Ghost (visible) to him

Modular quests:
- EDITED: Note that there should be empty space with "|n|n" after Quest Discovered + Quest TItle + (here) + Quest Requirement + n....
- Note: QuestGiverUnit should be stored per QuestID related to the quest to QuestData hashtable
--- This is stored into questData already, but not utilized properly, >> now should be used
- EDITED: Modified quest create / quest complete triggers; set quest that is being completed QuestState to 4 (complete) - then create new dummy quest with id 9990 to create visual effect of new Quest available (yellow exclamation mark)
- EDITED: Save hashtable trigger - separated from Quest Create triggers
- EDITED: QuestGiverUnit[QuestID / QuestID_Temp] created + now using QuestGiverUnitTemp to initially set the Quest Giver unit that will be stored into QuestGiverUnit[QuestID]

Quest Explosive Crisis
- Added Quest Update trigger to update "Ready to turn in" state for Boom Brothers - needs testing that all relevant Call QuestIcon_xxx are used
>>> TEST RESULT: OK

Terrain:
- Minor continue of Boom Brother mine (almost ready Major terrain parts)

=================================================================================================================================================
Epic Quests 10.8.2025 - List of Actions:

QUEST ICON SYSTEM
- reworked the system
- related quest system triggers call scripts updated to match the updated quest icon system function calls
- Testing;
>> Red (Grey) Exclamation mark on BoomBrothers Init Icon
>>>>> Also this mark came when Quest was COMPLETED!
>>>>>> EDITED - should be now fixed - State was set to 1 (unavailable) instead of 2 (available)
>> Grey question mark when quest is accepted (CREATED) >> OK
>> Note: Set quest requirement complete when you have requirement complete and then set the QuestIcon to Yellow Question mark (Ready to turn in)
>> Note: Should the MapIcon be Question mark when quest is "in Progress?"

>> Note: after edits, now yellow exclamation mark when it should be Grey Question mark when Quest is CREATED! - Previosly it worked, it seems that priority system is taking affect???
>> note: "Debug quest reward item" -message was shown when quest is CREATED! >> REMOVED TEXT

Modular quests:
- Note that there should be empty space with "|n|n" after Quest Discovered + Quest TItle + (here) + Quest Requirement + n....

AtexBlix
- did not fit through mine pathing blockers to come at the entrance - need to at abilty Ghost (visible) to him

Boom Brothers
- prevent "normal talk" when Quest Boom Will Be Back is discovered
- did not stop following after completing quest Mandatory Training
- Boom Will Be Back could not be completed after Defeating Mad Blix -> no dialog button to complete

Bridges:
- Added bridge008 activate/deactivate triggers in Sirensong
- Switched entering regions Event logic, should be now correct? >>> Yes.
- Note# Need to add check target of issue of the unit to move the units correctly near the bridge (especially when the pathing blockers on bridge entering sides are active)
- Make the related triggers (e.g. creating side pathing blockers) more easy using "For Each Loops"

Terrain:
- Minor continue of Boom Brother mine

Lag note:
- Without disabling ai with "debug aidisablemainstates" - things get pretty stuttering and laggy at some point
- However, when disabling ai with above command, things settle and fps kind of stabilizes, there are some spikes still

=================================================================================================================================================
Epic Quests 9.8.2025 - List of Actions:

QUEST ICON SYSTEM
- working on making the system working and without compiler errors
- Testing results:
--- Init trigger - quest icon/marker on map works
--- On Quest Discover - quest icon/marker correctly changed - except - on map the icon is yellow Turn In question mark (is it wanted or more preferable to have no icon on map when quest is in-progress?
--- After completing the quest;
>>>>> Quest Turnin map icon was not removed
>>>>> Quest Exclamination mark was not created on the BoomBrothers or on the map
>>>>>>>>>> Probably trigger related stuff..
>>>>> But then when getting NEW quest - correctly made Question mark on the Unit/map

>>> EDITED by setting QuestState to 2 after quest completion and when no quests anymore to 4, now test!

MODULAR QUESTS
- Quest System Complete Rewards added - all rewards related are now also generic, which is run from the unique Quest XXX Completed trigger

=================================================================================================================================================
Epic Quests 8.8.2025 - List of Actions:

MODULAR QUESTS
- added QuestType and QuestState and QuestGiverUnit
- Load Hashtable, Complete, Discover related Generic functions made into separate triggers, which are called by the unique Quest XXX Discover/Quest XXX Completed triggers
>>> things that don't change quest by quest, this way easier to manage if changes to design of the Hashtables / etc. error finding.

QUEST ICON SYSTEM added
- modular quests will have calls to this system
- multiple Quest Icon MAP related errors; can not be used with Hashtables?
- see if the code can be adjusted, notice that the latest script is not in the map!

=================================================================================================================================================
Epic Quests 6.8.2025 - List of Actions:

MODULAR QUESTS
- Modified strings for linebreaks "\n"
- Added generic kill and gather arrays + texts if using those (Boolean Active = TRUE)

XP:
- Modified Cinematic OFF trigger to prevent enabling XP gain for other units than Nazgrek and Zulkis (e.g., bag, companiondummy unit, etc.)

=================================================================================================================================================
Epic Quests 5.8.2025 - List of Actions:

MODULAR QUEST REWARDS:
- Quest reward item name get function created
- Finalized rewards texts
- added Quest Icon Path array string
- Now should be fully usable for new (+ re-edit older quests) quests, there is still some manual work, but now should be less work involved...

- Issues found so far:
--- Quest discovered Text reads QUEST|n|n|n|n
>>> Edited; Should now work, as reading from hashtable was set too early before creating the quest, meaning nothing was really stored inside the quest

--- Quest requirement text does not need additional "-" sign, Quest log will add it automatically, however Quest Display text wont have it..., so ...
>> Edited

--- Quest Completed text reads: Rewards|nXP: 500|nGold: 500 - however in Message log it looks properly
>> EDITED - TEST!

--- QUEST COMPLETED|nBoomsite Compliance (in message log it reads correctly...)
>> EDITED - TEST!

- Notes:
--- After Boomsite Compliance - set Boom Brothers to go "inside" the mine and then return (set collision to 0 / add ghost visible ability and then remove it
--- After Dust Migation - set AtexBlix to go "inside" the mine and then return (set collision to 0 / add ghost visible ability and then remove it
>> EDITED and added

- Boom Brothers if killed, should then respawn and continue following Player
- Goblin miners if killed, should then respawn at Boom Brothers and continue following player (stop respawn/follow) and remove units when quest completed
----- NOT ADDED LOGIC YET!

- If Nazgrek is further than 1000-2000 yards, stop follow for goblin miners and Boom Brothers
>> EDITED - TEST!

- Add Grenade ability to Boom Brothers and other gadgets, but not normal attack
- will assist player if player units are attacked (= make them as companions player units, but not add into companion group)
>> EDITED - TEST!

- maybe goblin miners should follow Boom Brothers instead of player
>> EDITED - TEST!

- when player selects Boom Brothers;
--- camera must pan to BOom Brothers
--- dialog button to command Hold position
--- dialog button to follow
------ ADDED: logic created inside "Button Pressed..." - TEST

- When AT KOBOLD MINE; Camera looks weird, because panned to Boom Brothers but angle/etc. camera settings make camera go underground
>> EDITED - TEST!

- Returning back to Boom Brother mine did not trigger
--- Issue with CV not set to BoomBrothers -unit -- probably
>> EDITED - TEST!

=================================================================================================================================================
Epic Quests 2.8.2025 - List of Actions:

MODULAR QUEST REWARDS:
- Started using strings also during QUEST ID creation -
---> Make changes to Boom Brother quests so that they follow the template (there will be some work.....)
- Rewards:
--- Added Arena Marks as option for reward
--- Added Item-type as option for reward
------ Note: Need a way to get a name of Item-Type, so less manual work. ELSE NEED TO WRITE DOWN THE NAME OF THE ITEM (but it could be useful)
--- Rewards Texts still under work in Quest System Create and all the QUEST TEMPLATES
--- Note#: RewardsText may look funny now if there are no e.g., Gold reward with those "| " lines
--- Note#: RewardsText to be separate for QUEST DISCOVERED and for inside the QUEST DESCRIPTION!
--- NOTE#:  local item i = CreateItem(udg_QuestRewardItem[QuestID],0,0) does not work as locals are only supported at the top of the function!

=================================================================================================================================================
Epic Quests 1.8.2025 - List of Actions:

Lag testing
--- LAG severly got less bad when disabling AI using "debug aidisablemainstates"
------ Still some lag spikes after this, probably Steam Breath affects
------ Try adding debug disable SteamBreath / Thunderstorm

MODULAR QUEST REWARDS:
--> RESULT: Seems to work fine other than text rows needs some editing.
- EXTRA TESTS: Try discovering QUESTS in random order then complete them in random order --> Verify that Player is receiving correct REWARDS related to the quest - to see that QUEST ID / HASHtable is working

---> See if you could get less re-writing of STRINGS, by possible storing string values into QuestID and retrieve them through Hashtable!

=================================================================================================================================================
Epic Quests 31.7.2025 - List of Actions:

Lag checking:
- When checking memory used by Warcraft III.exe, it keeps incrementing where rabidly, over 4- up to 5GB RAM

- To be tested:
---- Disable UnitHider again
---- Disable New added Heal Engine - this could be source of new lag - despite the effort cleaning older triggers from memory leaks...
---- SteamBreath / Rain / Thunderstorm causing laggyness?

AI
--- Added command "debug aidisablemainstates" - that will disable AI mainstates AND prevent new AI Hero Spawn

Without AI and UnitHider systems, there seems to be lingering lag spikes;
--- Try disable Heal Engine and see how it works then

BUT RESULT: >>>>>> NO LAG
--- LAG Causer either: AI system related triggers or AND UnitHider system
---

#Note regarding LAG:
--- Memory keeps increasing steadily, but FPS remains OK (this might still be ok, as map has lots of things going on the background (item spawns, etc.)

Quest System
--- Modification to make modular quest rewards / texts system
--- Problems with Hashtable / arrays to fetch proper QuestIDs - WIP!
--- There needs to be way to check not to run QUEST ID etc related generation when QUEST DISCOVERED / QUEST COMPLETED ARE RUN
--- Quest description text didnt work as planned: description of the text was old and Rewads only text without gold /XP ----> Reason: Create trigger has old stuff, latest ones are inthe Quest System trigger
--- Now done for quests QuestExplosiveCrisis & BoomsiteCompliance
------> To be tested

-Continued Boom Brother Mine terraining


Quest Mandatory Training
- Wrong quest More Hazard Trainign was discovered!
- Goblins dont follow Nazgrek
->> Should be NOW fixed.

=================================================================================================================================================
Epic Quests 30.7.2025 - List of Actions:

AI triggers added/modified:
- New "Horde NPC Inventory State XXX"
--- will trigger when AI hero loses/acquires/uses item and then logic is made whether to go buy new item(s) or go sell item(s)
--- Logic transferred from MAIN STATE trigger
- New "Horde NPC Buy Items Q XXX"
--- Logic transferred from MAIN STATE -trigger "ITEMS BOUGHT"
- New "Horde NPC Sell Items Q XXX" trigger
--- Logic transferred from MAIN STATE -trigger "ITEMS SOLD"
- New "Horde NPC Camp Night Time XXX" -trigger - where actually start AI camping when night starts (vs. not check periodically is it night)
--- previous camp trigger name changed to "Horde NPC Camp Night Time Q XXX"
- These changes made to Rogue, Warlock, Warrior

- Started thinking and drafting "Quest Rewards" template that is to be used in every quest related XP / Gold / other rewards

=================================================================================================================================================
Epic Quests 29.7.2025 - List of Actions:

- Heal Engine 1.0.4 by Marchombre
--- System added to the map

- NPC AI Heroes:
--- CampFire position memory leaks fixed
--- Shop BUY - multiple position memory leaks fixed - Note: Can there be conflict using same NPC_VarPointX for each AI Hero MAIN STATE triggers?
--- Note: AI logic system can be the cause of lags / memory leaks staggering up

- Experience / Rested experience
--- Disabled: Experience Rested Unit Dies
--- Disabled: Experience Rested System Init
--- Cause: XP floating text comes 2 times or more
--- Created Experience Rested Unit Dies Test for testing XP floating text

=================================================================================================================================================
Epic Quests 28.7.2025 - List of Actions:

- Trying to fix leaks:
--- SteamBreath edited -> Script combined into one single script instead of "create" & "destroy"
--- FrostbiteSystem edited
--- Item Remove trigger edited
--- Destroy Crystals Limit trigger edited
--- Destroy Ore Limits trigger edited
--- Bag Follow trigger edited
--- HeroDeathRessurect AI Hero Reviver + Loop triggers disabled as they could be worked more + they are not working currently + possible causers of lag
--- Notes: Gar & Gor movement triggers are shit, poor / no conditions
--- Notes: AI hero states can cause lag, especially if they get stuck repeat on some actions like warrior's buy
--- Notes: RAGE ENERGY SYSTEM could cause lags - especially if the unit tries to keep using item, but its denied
--- Fog Fade system (The_Flood's Fog System) - could it cause lag?
--- Disabled Wandering Hostile NPCs triggers - these should be checked/re-edited to be more fine adjusted + check no leaks
--- ... lots of more triggers to check....

=================================================================================================================================================
Epic Quests 27.7.2025 - List of Actions:

- Cinematic Player (Player 22 Snow) now treated as ally by all players (previously was neutral and was attacked during a cinematic cutscene)
--- Problem with this version is; Player 22 or vise versa could go assist others which can break the immersion

- AtexBlix and BoomBrothers quest / dungeon continue

=================================================================================================================================================
Epic Quests 26.7.2025 - List of Actions:

- AtexBlix
--- Fixing dialog

- Boom Brothers Mine
--- Terraining / doodads

- UnitHider; now re-enabled - cause of lag must be found from other periodic triggers/newer JASS scripts (like Frostbite system / etc.)

=================================================================================================================================================
Epic Quests 25.7.2025 - List of Actions:

Create neutral sea life creatues (crab, turtle, ...) with proper levels
--- Created 10, 12, 14 level Spider Crabs
--- Created 10, 15, 14 level Sea Turtles + 16 level Azuron - sea turtle miniboss
--- Spider Crab Shorecrawler, Sea Turtle (lvl 10) + Giant Sea Turtle (lvl 15) added Neutral unit trigger

- AtexBlix
--- Clicking Blix before his quests will result in just Blix turning to Nazgrek, and no dialog / etc.
--- need to add normal greets/ etc?, or just can be talked when: 1st quest complete, 2nd quest discovered

- Sounds
--- Finalized adding seaturtle, Firefly (Moth), crab sound files (attacked/attacking / death)

- Sky
--- SkyHellish + SkyDungeon removed (related triggers + model files)

DNC
- added String-type condition check to not run the trigger, if its setting is already run before
- added DNC_OutdoorsRed

Zones:
--- Combined Discovered and normal Zone triggers into one for more clearer structure/readability + less same kind of triggers...
--- Added some new zones to Sirensong, Verdant Plains

Boom Brothers / Atex Blix:
- Continued with more quests / voicelines
- Created Boom Brothers Mine -dungeon - not finished yet

=================================================================================================================================================
Epic Quests 22.7.2025 - List of Actions:

- Fixed issues related to AtexBlix / BoomBrothers quests/events - not finished yet...
--- Note 6 fixed
--- Note 2, 3, 6 could be fixed now - cause was DialogSkipped was set to TRUE, causing the triggers not to continue... Now each DialogOver trigger contains DialogSkipped = False at the end
--- Note 4; created Atex wood inspection, could be improved though
----- Need to remove completion at Boom Brothers for these quests (Note 5 related)
--- More Hazard Mitigation quest created; could need some more work with lines, etc. way of handling the quest

=================================================================================================================================================
Epic Quests 21.7.2025 - List of Actions:

- Boom Brothers / "AtexBlix" quests continued working
--- Note #1: All quests available at dialog - should be 1 at a time, check conditions in trigger "Create BoomBrotherDialog01"
--- Note #2: Completing Explosive Crisis results in new camera angle, but nothing happens after that and stuck in cinematic mode, it could however be skipped and then Explosive Crisis will be completed
--- Note #3: Nothing happens when clicking Boomsite Compliance, but using ESC key to skip, then the quest is discovered
--- Note #4: add return / click trigger to AtexBlix after quest is discovered
--- Note #5: quest will be completed at AtexBlix, not BoomBrothers
--- Note #6: same thing when completing BoomSite compliance, skipping works, but no dialogue before that
--- Note #7: Whoa whoa whoa -line only should have one "whoah" for AtexBlix
- Added triggers for attacked/attacking sounds for Tigers, panthers, lynx, stags/deers
- Skybox testing;
--- SkyDungeon edited now as static
--- SkyHellish red and animated
--- Notes: Sky sphre looks shit, and also sometimes looks black???/
--- SkyDungeon sky crashed game, could be just Blizzard bug, but also could be model issus / corrupt of deleting Global Sequence / animation...

=================================================================================================================================================
Epic Quests 20.7.2025 - List of Actions:

- Fixed Boom Brothers moving / couldn't talk to him bug
- Added "Explosive Risk Assessor Blix" with quest follow ups for Boom Brothers
--- Voicelines + voice files
--- Triggers; Buttons pressed / dialogues / quest creation
- Note 1#: Cannot complete quest with 6 barrels in inventory, just says the lines when not all items in inventory
- Note 2#: if not taken any quests, there are no "NORMAL GREET" -lines - should there be?

- Skybox testing:
--- Sky is animated; remove animation for SkyDungeon
--- Sky (RED) can be animated, but requires testing

- Sirensong; continued terraining

- NPCs;
--- Tigers with proper levels
--- Panthers with proper levels
--- Raptors with proper levels

- Sounds
--- Added raptor, tiger, seaturtle, nagaFemale, deer/elk, Firefly, crab sound files (attacked/attacking / death)
--- abilities; could create new variations to Dash/Shred/RIP etc.

- TO BE Removed 2nd player / GetLocalPlayer features --> 2-player playable map feature discarded as too much work would be involved - Zul'kis will remain as 2nd playable hero for Player 1
-- TO BE Edited following associated triggers/functions/configurations:
--- XXX

=================================================================================================================================================
Epic Quests 19.7.2025 - List of Actions:
- Testing skyboxes (see previous notes)
--- Note: Added skyboxes dont stretch, and are displayed like normal models, it can be seen around the camera, --> not looking great!
--- Modified to Zones / DNCs / Entering/leaving Gnoll Hideout
- Fixed Boomer Brothers dialog if/elses + now correct quest should be discovered
- Added random movement to Boom Brothers;
--- Bug on; wait for issue order stop is not working, the Boomer is stuck on "Moving"
--- See if it could be simplified more + usable for other NPCs in the map
--- Safety-mechanism should be added in case the NPC gets stuck for any reason (other unit blocking, etc.) --> If not using "current order not equal smart / or move...", maybe it will work
- Add "Unstable explosives" buff to unit carrying 1 or more "Barrel of Explosives" -> When carrying Barrel of Explosives, there is 25 % chance for them to explode, greatly damaging the carrier!
- Camera lock bugged after new patch 2.03! --> Lock to unit does not work
- Discovery? AI heroes, especially different periodically run triggers causes lag spikes

=================================================================================================================================================
Epic Quests 18.7.2025 - List of Actions:

- Creep Respawn System / Creep Respawn -trigger
--- Modified to set Unit variable e.g., Ragno if the respawning unit-type is Ragno etc.
--- Test now with Ragno 1) kill Ragno 2) wait for respawn 3) try to click him to get dialogue / quest(s), if it works, the system works and you should add all important units like quest givers to the Creep Respawn -trigger if they are not invulnerable and can be killed.
- Imported dungeon like skybox shibi.mdx and hellish/fiery skybox xingkong3.mdx
--- Use shibi.mdx for dungeons like: Gnoll Hideout, The Crypt
--- Use xingkong3.mdx for: The Firelands, Dragon Lair
- Sirensong;
--- goblins "Boom Brothers" created; fixed / edited dialogue triggers (bug on Farewell, etc.)
--- Some lite terraining

=================================================================================================================================================
Epic Quests 10.7.2025 - List of Actions
- Sirensong;
--- Added draft idea for goblin sappers at the entrance of old mine who will need the Hero to search for Explosive barrels, barrels are highly unstable
--- Created base for quest dialogs

=================================================================================================================================================
Epic Quests 6.7.2025-2 - List of actions:
- Blood/bleed effects:
--- Fixed Point for the generic blood splat unit
--- Added SFX for the Blood Effect
- Units:
--- Added Panther boss and renamed Devilsaur as boss
- Terrain:
--- Continued Sirensong

=================================================================================================================================================
Epic Quests 5.7.2025 - List of actions:
- Blood/bleed effects:
--- Added Blood Splats and modified Bleed triggers, there is a chance to spawn blood effects on ground when attacked and under 25% hp or when the unit dies

=================================================================================================================================================
Epic Quests 4.7.2025 - List of actions:
- Sirensong:
-- Continued terraining southern end of the map, ogre / mine entrance areas
- Added models:
-- zombie, ghoul, moth, potions (potions models not used by any item, but imported)
-- Withering Presence (based on immolation)
-- Endemic Field (added as ability (test) for Soul Devourer Undead boss
- Blood/bleed effects added when unit is 25% low and taking damage and chance to spawn blood effect on the unit
-- Chance to occur maybe too low? + maybe start bleeding when below 25 %? or that kind of thing only for Heroes?

==================================================================================================================================================
Epic Quests 1.7.2025 - List of actions:
- Sirensong:
-- Continued terraining southern end of the map, sea shore area
-- Bridge lifted near naga area
- DestructibleHider >> enabled
- Floating Text Spell:
--- Modified floating text: "level of ability being cast -1
--- Note: "tooltip missing" e.g., when using item (e.g., Spring Water)
--- coloring now just uses the fixed coloring that is set in the tooltip text itself, its ok.
- Camera:
--- Interesting view by using: FoV 50-60, Dist 2200
--- Rotate left & right should be inversed?
--- BUG cinematics: if using arrow keys to rotate while transiting to Cinematic, camera will bug out in the cinematic but it will also remain bugged and stuck moving after the cinematic, can only be reset via /camera normal /cameral default etc. trying to use arrow keys....
- Note on Riverbane bridge: need to lower bridge end/start Invisible platforms
- Note on lag:
--- It is possible that Frostbite system or other newest system cause lag by utilizing periodic timers...

==================================================================================================================================================
Epic Quests 30.6.2025 - List of actions:

- Floating texts:
-- Added "Floating Spell Name" + Floating Spell Configuration triggers to have floating texts for spells;
--- This will need some conditions for blocking dummy units, and some wc3 internal spells e.g., critical strike, etc.
--- Critical note: Can't use "unit enters playable map area" as event, because of the huge number of pre-placed units OR/AND many unit enters region events
--- NEW: Init 07 on SETUP for "unit enters playable map area" events --> only use this trigger to run other triggers that need this event (SINGLE place for the generic event)
--- Note: need to add "level of ability being cast + 1", now its level 1 for e.g., level 2 ability
--- Note: coloring of ability does not work, it only works for some abilities tooltips as they already might have HEX coloring in them, so results is not clear always, best would be to have the ability text without coloring and then only the level is in different color
- Sirensong:

==================================================================================================================================================
Epic Quests 27.6.2025 - List of actions:

- Sirensong:
-- Continued terraining southern end of the map, sea shore area

==================================================================================================================================================
Epic Quests 25.6.2025 - List of actions:

- Note on textures: lots of imported duplicate textures with path war3mapImported / war3campImported .blp files that should be removed
- Note on re-imported textures:
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_floor_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_floor_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_floor_03.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_trim_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_trim_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_wall_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_wall_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_roof_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_roof_03.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_trim_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_trim_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_wall_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_wall_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_window_01.blp"
---> Now black / glitching occurs also on orc hut!!!!!! Previous textures worked better!
- Sirensong:
-- Continued terraining southern end of the map, sea shore area

- Note on lag issues:
-- Previously disabled Stats check 2 -trigger was not the (main) cause of lag, still getting laggier after some time
-- Also; when units shown? or area near at water elemental boss caused fps to drop to 2 fps, could also be because of overlapping of Unit hider on AI / other units??
-- Now testing:
----- disabled UnitHider + related triggers and functions in CinematicON, CinematicOFF, Intro Cinematic Cleanup
----- disabled DestructibleHider

==================================================================================================================================================
Epic Quests 24.6.2025 - List of actions:

- Crash after doing countless regions for zones + some STV/jungle like doodad search, nothing fully inserted
-- Crash caused by STV_root01, could be others that may cause similar crash, or its related to the weirdly huge sizes, but most likely texture issue.
- modify Valkier to be "on foot" instead of on air, still need to fix her stand animation OR remove
- Stats check 2 -trigger disabled temporally
-- To check if this is causing lag / memory leak
--- seemed to be better, but needs more testing, still some minor peaks not that bad?

==================================================================================================================================================
Epic Quests 21.6.2025 - List of actions:

- Testing UnitHider1.1
-- whether it even works AND if memory leaks are reduced
-- Results: it does not work AND it lags even more!
-- Reverting to UnitHider1.0

Added units in WE:
- Core Hound
- NorthrendskeletonmaleBosses (Skullreaver)
- Valkier (Seralyth)

Terrain / doodads
- Added altar of storms to Dragonfire Peaks
- Added fel orcs at the altar of storms, some quest related to multiple Altar of Storms located in multiple locations in the map
- Sirensong terraining forward slightly
-- Sirensong Orc base edited forward
-- Sirensong orc base doodads some may require some editing (black textures when viewed from afar

Issues after testing:
- Valkier model bad; in air + changing stand animation to flying

Orc doodads (zeppelin):
- Tried to use UV remapping on black/glitchy orc zeppelin -> did not work
- Tried to use wrap width & wrap height on orc zeppelin and re-import the model (without re-importing textures) -> did not work, maybe need to re-import textures or related to Material filter modes

- Progressive lag / memory leak; gets bad quite quickly;
-- To test in next revision:
--- Disable UnitHider
--- Disable DestructibleHider
--- Disable AI hero spawning >> a)
--- Disable AI hero spawning, but leave UnitHider enabled >> b)

==================================================================================================================================================
