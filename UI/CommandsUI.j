/**
    CommandsUI

    Author: Valdemar
    Version: 1.3.0

    Description:
    Shows a categorized, reference-only list of gameplay commands and legacy
    cheat/debug commands. Rows describe commands but do not execute them.

    Credits:
    - Tasyen for TasQuestBox

    How to install:
    Import after Table, MasterUI, Interface, and the TasQuestBox TOC.

    API:
    - CommandsUI_Show()
    - CommandsUI_Hide()
    - CommandsUI_ForceUpdate()

**/
library CommandsUI initializer AutoInit requires Table, MasterUI, Interface

globals
    private constant integer CUI_BUTTON_COUNT = 8
    private constant integer CUI_FRAME_CONTEXT = 4

    private boolean CUI_Initialized = false
    private boolean CUI_SyncingSlider = false
    private boolean CUI_HandlingSliderAction = false
    private integer CUI_DefinitionCount = 0
    private integer CUI_SliderMaxCache = -1
    private integer CUI_SliderValueCache = -1

    private string CUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string CUI_Title = "Commands"
    private string CUI_ReturnButtonText = "Return"

    private integer array CUI_ViewOffset
    private integer array CUI_SelectedCommandId

    private string array CUI_CommandName
    private string array CUI_CommandCategory
    private string array CUI_CommandIcon
    private string array CUI_CommandBody

    private framehandle CUI_Parent = null
    private framehandle CUI_ReturnButton = null
    private framehandle CUI_Slider = null
    private framehandle CUI_TitleFrame = null
    private framehandle CUI_TextArea = null
    private framehandle array CUI_Button
    private framehandle array CUI_ButtonIcon
    private framehandle array CUI_ButtonText

    private trigger CUI_CloseTrigger = null
    private trigger CUI_ReturnTrigger = null
    private trigger CUI_ClearFocusTrigger = null
    private trigger CUI_WheelTrigger = null
    private trigger CUI_SliderTrigger = null
    private trigger CUI_ButtonTrigger = null

    private Table CUI_ButtonRow = 0
endglobals

private function CUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function CUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function CUI_RegisterCommand takes string commandName, string category, string iconPath, string bodyText, boolean showInList returns integer
    local integer commandId = CUI_DefinitionCount + 1

    if not showInList then
        return 0
    endif
    set CUI_DefinitionCount = commandId
    set CUI_CommandName[commandId] = commandName
    set CUI_CommandCategory[commandId] = category
    set CUI_CommandIcon[commandId] = iconPath
    set CUI_CommandBody[commandId] = bodyText
    return commandId
endfunction

private function CUI_InitDefinitions takes nothing returns nothing
    call CUI_RegisterCommand("/help", "General", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Displays the general help text or command overview when implemented in gameplay logic.", true)
    call CUI_RegisterCommand("/skills", "Professions", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Shows the current tracked gather/profession skill values for the selected supported hero.", true)
    call CUI_RegisterCommand("/leave arena", "Arena", "ReplaceableTextures\\CommandButtons\\BTNBootsOfSpeed.blp", "Leaves the arena map section when arena gameplay is active.", true)
    call CUI_RegisterCommand("/unstuck", "Movement", "ReplaceableTextures\\CommandButtons\\BTNMassTeleport.blp", "Moves selected Nazgrek and/or Zul'kis to the safe arrival point at Nazgrek's Hut. Each moved hero can use /unstuck once every 5 minutes and receives the normal Traveler's Journal cooldown.", true)

    // Set the final argument to false to keep an individual command out of the reference UI.
    call CUI_RegisterCommand("/debug help", "Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Displays the centralized DebugCommands help text.", true)
    call CUI_RegisterCommand("/debug item create '<rawcode-or-name>'", "Object Debug", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Creates an item for the selected unit, or at the synchronized camera target when no unit is selected.", true)
    call CUI_RegisterCommand("/debug item lookup '<rawcode-or-name>'", "Object Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists matching item rawcodes and display names from the generated debug object registry.", true)
    call CUI_RegisterCommand("/debug unit create '<rawcode-or-name>'", "Object Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Creates a player-owned unit at the synchronized camera target.", true)
    call CUI_RegisterCommand("/debug unit lookup '<rawcode-or-name>'", "Object Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists matching unit rawcodes and display names from the generated debug object registry.", true)
    call CUI_RegisterCommand("/debug ability give '<rawcode-or-name>'", "Object Debug", "ReplaceableTextures\\CommandButtons\\BTNManual3.blp", "Adds the resolved ability to the currently selected unit. Alias: /debug ability add.", true)
    call CUI_RegisterCommand("/debug ability lookup '<rawcode-or-name>'", "Object Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists matching ability rawcodes and display names from the generated debug object registry.", true)
    call CUI_RegisterCommand("/debug fishpool spawn", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Spawns a random enabled fishing pool definition in the zone at the synchronized camera target.", true)
    call CUI_RegisterCommand("/debug drunk", "Unit Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Displays the selected unit's Drunk value from 0 to 100.", true)
    call CUI_RegisterCommand("/debug unstuck", "Movement Debug", "ReplaceableTextures\\CommandButtons\\BTNMassTeleport.blp", "Runs the selected-hero unstuck flow while bypassing the normal five-minute cooldown.", true)
    call CUI_RegisterCommand("/debug creeprespawn dungeon respawn [zoneId]", "Dungeon Debug", "ReplaceableTextures\\CommandButtons\\BTNAnimateDead.blp", "Immediately respawns dead dungeon creeps and bosses. Omit zoneId to process every dungeon.", true)
    call CUI_RegisterCommand("/debug unithider hide all", "Visibility Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Force-hides eligible non-tracked units managed by UnitHider.", true)
    call CUI_RegisterCommand("/debug unithider unhide all", "Visibility Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Unhides UnitHider-managed non-tracked units without changing the enabled state.", true)
    call CUI_RegisterCommand("/debug unithider enable", "Visibility Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables UnitHider and schedules a full settlement on its next update.", true)
    call CUI_RegisterCommand("/debug unithider disable", "Visibility Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables UnitHider and reveals every unit it manages.", true)
    call CUI_RegisterCommand("/debug unithider audit", "Visibility Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the UnitHider diagnostic audit.", true)
    call CUI_RegisterCommand("/debug doodadrender distance <distance>", "Rendering Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Sets every DoodadRender distance tier to the supplied non-negative value.", true)
    call CUI_RegisterCommand("/debug performance disable", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNBootsOfSpeed.blp", "Runs the one-way isolation sequence, disabling eleven heavy systems at five-second intervals until the map is reloaded.", true)

    call CUI_RegisterCommand("/debug perf help", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists the isolated performance-candidate diagnostic commands.", true)
    call CUI_RegisterCommand("/debug perf status", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints all destructable, Dynamic Far Z, Storm, and AIRoutines diagnostic states and counters.", true)
    call CUI_RegisterCommand("/debug perf reset", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Resets every performance-candidate diagnostic counter.", true)
    call CUI_RegisterCommand("/debug perf destructable status", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints PERF-001 destructable-hider work counters and diagnostic state. The 'destructible' spelling is also accepted.", true)
    call CUI_RegisterCommand("/debug perf destructable candidate", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets PERF-001 candidate counters.", true)
    call CUI_RegisterCommand("/debug perf destructable control", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Reports that PERF-001 control mode requires a separate control-map build and reload.", true)
    call CUI_RegisterCommand("/debug perf destructable counters on", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets PERF-001 counters.", true)
    call CUI_RegisterCommand("/debug perf destructable counters off", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables PERF-001 counters.", true)
    call CUI_RegisterCommand("/debug perf farz status", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints PERF-002 Dynamic Far Z state, calculations, values, and setter counters.", true)
    call CUI_RegisterCommand("/debug perf farz candidate", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets local PERF-002 candidate counters.", true)
    call CUI_RegisterCommand("/debug perf farz control", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Reports that PERF-002 control mode requires a separate control-map build and reload.", true)
    call CUI_RegisterCommand("/debug perf farz counters on", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets local PERF-002 counters.", true)
    call CUI_RegisterCommand("/debug perf farz counters off", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables local PERF-002 counters.", true)
    call CUI_RegisterCommand("/debug perf storm status", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints PERF-005 Storm timer and callback counters.", true)
    call CUI_RegisterCommand("/debug perf storm candidate", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets PERF-005 candidate counters.", true)
    call CUI_RegisterCommand("/debug perf storm control", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Reports that PERF-005 control mode requires a separate control-map build and reload.", true)
    call CUI_RegisterCommand("/debug perf storm counters on", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets PERF-005 counters.", true)
    call CUI_RegisterCommand("/debug perf storm counters off", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables PERF-005 counters.", true)
    call CUI_RegisterCommand("/debug perf airoutines status", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints PERF-008 AIRoutines processing, transition, order, and callback counters.", true)
    call CUI_RegisterCommand("/debug perf airoutines candidate", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets PERF-008 candidate counters.", true)
    call CUI_RegisterCommand("/debug perf airoutines control", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Reports that PERF-008 control mode requires a separate control-map build and reload.", true)
    call CUI_RegisterCommand("/debug perf airoutines counters on", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables and resets PERF-008 counters.", true)
    call CUI_RegisterCommand("/debug perf airoutines counters off", "Performance Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables PERF-008 counters.", true)

    call CUI_RegisterCommand("/debug wc3 help", "Warcraft Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists the Warcraft 3.0 baseline, camera, fog, doodad, effect, and minimap probes.", true)
    call CUI_RegisterCommand("/debug wc3 status", "Warcraft Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the current Warcraft 3.0 test-harness status.", true)
    call CUI_RegisterCommand("/debug wc3 selftest", "Warcraft Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Runs the non-mutating Warcraft 3.0 baseline self-test.", true)
    call CUI_RegisterCommand("/debug wc3 camera status", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints local camera position, fields, input, ownership, and type diagnostics.", true)
    call CUI_RegisterCommand("/debug wc3 camera orbit on", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables the experimental local camera-orbit input probe.", true)
    call CUI_RegisterCommand("/debug wc3 camera orbit off", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables the experimental local camera-orbit input probe.", true)
    call CUI_RegisterCommand("/debug wc3 camera ownership on", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables experimental local camera-input ownership.", true)
    call CUI_RegisterCommand("/debug wc3 camera ownership off", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables experimental local camera-input ownership. Alias: ownership reset.", true)
    call CUI_RegisterCommand("/debug wc3 camera type", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the current camera diagnostics, including camera type.", true)
    call CUI_RegisterCommand("/debug wc3 camera type set <0-16>", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Applies the requested local camera type from 0 through 16.", true)
    call CUI_RegisterCommand("/debug wc3 camera type reset", "Camera Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Restores the default local camera type.", true)
    call CUI_RegisterCommand("/debug wc3 fog status", "Fog Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the current local fog state and override stack.", true)
    call CUI_RegisterCommand("/debug wc3 fog test parity", "Fog Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Applies the parity fog probe preset.", true)
    call CUI_RegisterCommand("/debug wc3 fog test height", "Fog Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Applies the height fog probe preset.", true)
    call CUI_RegisterCommand("/debug wc3 fog reset", "Fog Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Clears the active fog test before changing zones.", true)
    call CUI_RegisterCommand("/debug wc3 doodads status", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints map doodad counts and probe state.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer status", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the DoodadRender backend, enabled state, and diagnostics.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer area", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Switches DoodadRender to its area-enumeration backend.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer indexed", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Switches DoodadRender to its indexed native backend.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer on", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Enables DoodadRender and prints its state.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer off", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Disables DoodadRender and prints its state.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer refresh", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Forces a DoodadRender refresh and prints its state.", true)
    call CUI_RegisterCommand("/debug wc3 doodads renderer reset", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Resets DoodadRender diagnostics.", true)
    call CUI_RegisterCommand("/debug wc3 doodads scan", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Starts the paced native doodad scan.", true)
    call CUI_RegisterCommand("/debug wc3 doodads scan cancel", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Cancels the active native doodad scan.", true)
    call CUI_RegisterCommand("/debug wc3 doodads inspect <index>", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints native data for the doodad at the non-negative map index.", true)
    call CUI_RegisterCommand("/debug wc3 doodads probe hide <index>", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Hides the indexed doodad for the reversible native probe.", true)
    call CUI_RegisterCommand("/debug wc3 doodads probe reset", "Doodad Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Restores the doodad hidden by the native probe.", true)

    call CUI_RegisterCommand("/debug wc3 effects help", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists the Warcraft 3.0 special-effect animation probes.", true)
    call CUI_RegisterCommand("/debug wc3 effects create", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Creates a synchronized Grunt special-effect probe at the camera target.", true)
    call CUI_RegisterCommand("/debug wc3 effects status", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the current effect handle, animation, queued animation, and blend time.", true)
    call CUI_RegisterCommand("/debug wc3 effects animation <name>", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Requests the named animation on the active special-effect probe.", true)
    call CUI_RegisterCommand("/debug wc3 effects queue <name>", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Queues the named animation on the active special-effect probe.", true)
    call CUI_RegisterCommand("/debug wc3 effects blend <seconds>", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Sets the animation blend time on the active special-effect probe.", true)
    call CUI_RegisterCommand("/debug wc3 effects legacy", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Runs the legacy animation comparison on the active special-effect probe.", true)
    call CUI_RegisterCommand("/debug wc3 effects destroy", "Effect Debug", "ReplaceableTextures\\CommandButtons\\BTNAnimateDead.blp", "Destroys the active effect probe and resets its state. Alias: effects reset.", true)
    call CUI_RegisterCommand("/debug wc3 minimap help", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Lists the Warcraft 3.0 native/imported minimap probes.", true)
    call CUI_RegisterCommand("/debug wc3 minimap status", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Prints the active minimap terrain source and full/chunked view mode.", true)
    call CUI_RegisterCommand("/debug wc3 minimap source imported", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Switches the local dynamic minimap to imported terrain images.", true)
    call CUI_RegisterCommand("/debug wc3 minimap source native", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Switches the local dynamic minimap to native terrain rendering.", true)
    call CUI_RegisterCommand("/debug wc3 minimap view chunked", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Uses the chunked local minimap view.", true)
    call CUI_RegisterCommand("/debug wc3 minimap view full", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Uses the full-map local minimap view.", true)
    call CUI_RegisterCommand("/debug wc3 minimap force", "Minimap Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Forces an immediate local minimap refresh with the active terrain source.", true)

    call CUI_RegisterCommand("/debug aispawn", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Spawns a random managed AI hero and shows its spawn message.", true)
    call CUI_RegisterCommand("/debug ai", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Toggles AI debug mode and prints the active AI population breakdown. Alias: /debug aidebug.", true)
    call CUI_RegisterCommand("/debug aicamp", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNHumanLumberUpgrade2.blp", "Forces eligible visible AI units to begin a night camp.", true)
    call CUI_RegisterCommand("/debug aicraft", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNManual3.blp", "Forces eligible AI units to perform profession crafting at registered stations.", true)
    call CUI_RegisterCommand("/debug aibuy", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Forces eligible AI units with empty inventory space to begin a shop purchase.", true)
    call CUI_RegisterCommand("/debug aisell", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Forces eligible AI units with inventory contents to begin a shop sale.", true)
    call CUI_RegisterCommand("/debug aishop", "AI Debug", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Forces eligible AI units to buy or sell according to their current inventory state.", true)
    call CUI_RegisterCommand("/debug ap add", "Hero Debug", "ReplaceableTextures\\CommandButtons\\BTNManual3.blp", "Adds one ability point to both Nazgrek and Zul'kis.", true)
    call CUI_RegisterCommand("/debug VoidEntity", "Boss Debug", "ReplaceableTextures\\CommandButtons\\BTNAnimateDead.blp", "Reveals the placed Void Entity encounter. This externally owned command uses the displayed capitalization.", true)
    call CUI_RegisterCommand("/gathernodes refresh", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Refreshes every gather item and unit node when GatherNodes debug mode is enabled.", true)
    call CUI_RegisterCommand("/gathernodes refresh items", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", "Refreshes only gather item nodes when GatherNodes debug mode is enabled.", true)
    call CUI_RegisterCommand("/gathernodes refresh units", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Refreshes only gather unit nodes when GatherNodes debug mode is enabled.", true)
    call CUI_RegisterCommand("/gathernodes glowtest", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Applies the GatherNodes glow probe to the last selected unit when debug mode is enabled.", true)
    call CUI_RegisterCommand("/gathernodes glowclear", "Gather Debug", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Removes the GatherNodes glow probe from the last selected unit when debug mode is enabled.", true)

    call CUI_RegisterCommand("Cheats", "Warning", "ReplaceableTextures\\CommandButtons\\btncage.blp", "Warning disclaimer!|n|nCheats can and will break the normal intended gameplay. The cheats are legacy of testing the map's intense features and to speed up testing. The cheats can however add additional layer of fun and thus they remain.|n|nTip:|nRemember to save before using any cheats to easily return to \"unbroken\" game state.", true)
    call CUI_RegisterCommand("/tele", "Movement", "ReplaceableTextures\\CommandButtons\\BTNMassTeleport.blp", "Teleports all Player's units to the current camera view.", true)
    call CUI_RegisterCommand("/levelup", "Heroes", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Levels up all Player's Heroes to level 15.", true)
    call CUI_RegisterCommand("/levelupone", "Heroes", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Levels up all Player's Heroes once.", true)
    call CUI_RegisterCommand("/speedfreak", "Movement", "ReplaceableTextures\\CommandButtons\\BTNBootsOfSpeed.blp", "Highly increased movement speed for the selected units.|n|nDisabled by selecting the units and using the command again.", true)
    call CUI_RegisterCommand("/powerupmyheroes", "Heroes", "ReplaceableTextures\\CommandButtons\\BTNManual3.blp", "Modifies Strength, Intelligence and Agility of Player's Heroes by +50.", true)
    call CUI_RegisterCommand("/cinemaon", "Cinematic", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Turns cinematic mode on.|n|nDisabled upon pressing ESC key.", true)
    call CUI_RegisterCommand("/wood", "Items", "ReplaceableTextures\\CommandButtons\\BTNHumanLumberUpgrade2.blp", "Create item Pile of Wood to Nazgrek.", true)
    call CUI_RegisterCommand("/campfire", "Items", "ReplaceableTextures\\CommandButtons\\BTNHumanLumberUpgrade2.blp", "Create item Camp Fire to Nazgrek.", true)
    call CUI_RegisterCommand("/torch", "Items", "ReplaceableTextures\\CommandButtons\\BTNINV_Torch_Lit.blp", "Create item Torch to Nazgrek.", true)
    call CUI_RegisterCommand("/tent", "Items", "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_LeatherScrap_04.blp", "Create item Tent to Nazgrek.", true)
    call CUI_RegisterCommand("/nazgreksflask", "Items", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Create item Nazgrek's Flask to Nazgrek.", true)
    call CUI_RegisterCommand("/cannon", "Spawning", "ReplaceableTextures\\CommandButtons\\BTNHumanMissileUpThree.blp", "Spawns cannon.", true)
    call CUI_RegisterCommand("/everyoneisdead", "World", "ReplaceableTextures\\CommandButtons\\BTNAnimateDead.blp", "Kills every unit on the map.", true)
    call CUI_RegisterCommand("/hordeiseverywhere", "Faction", "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Changes all units ownership to Horde.", true)
    call CUI_RegisterCommand("/ihavenoallies", "Faction", "ReplaceableTextures\\CommandButtons\\BTNUnsummonBuilding.blp", "Horde is hostile against Player.", true)
    call CUI_RegisterCommand("/reunion", "Faction", "ReplaceableTextures\\CommandButtons\\BTNSpiritLink.blp", "Horde is again friendly to Player.", true)
    call CUI_RegisterCommand("/iamnazgrek", "Fun", "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp", "Use unit model Nazgrek.", true)
    call CUI_RegisterCommand("/animalslaughter", "Fun", "ReplaceableTextures\\CommandButtons\\BTNBeastMaster.blp", "What are you doing with the pigs?!", true)
endfunction

private function CUI_GetSelectedCommandId takes player whichPlayer returns integer
    local integer pid = GetPlayerId(whichPlayer)
    if CUI_SelectedCommandId[pid] >= 1 and CUI_SelectedCommandId[pid] <= CUI_DefinitionCount then
        return CUI_SelectedCommandId[pid]
    endif
    if CUI_DefinitionCount > 0 then
        return 1
    endif
    return 0
endfunction

private function CUI_UpdateUI takes nothing returns nothing
    local integer pid = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer commandId
    local integer maxPage = 0
    local integer selectedCommandId
    local integer frameValue

    if CUI_Parent == null or not BlzFrameIsVisible(CUI_Parent) then
        return
    endif

    if CUI_DefinitionCount > CUI_BUTTON_COUNT then
        set maxPage = (CUI_DefinitionCount - 1) / CUI_BUTTON_COUNT
    endif
    if CUI_ViewOffset[pid] < 0 then
        set CUI_ViewOffset[pid] = 0
    elseif CUI_ViewOffset[pid] > maxPage * CUI_BUTTON_COUNT then
        set CUI_ViewOffset[pid] = maxPage * CUI_BUTTON_COUNT
    endif

    if not CUI_HandlingSliderAction then
        set frameValue = maxPage - (CUI_ViewOffset[pid] / CUI_BUTTON_COUNT)

        set CUI_SyncingSlider = true
        if CUI_SliderMaxCache != maxPage then
            set CUI_SliderMaxCache = maxPage
            call BlzFrameSetMinMaxValue(CUI_Slider, 0.0, I2R(maxPage))
        endif
        if CUI_SliderValueCache != frameValue then
            set CUI_SliderValueCache = frameValue
            call BlzFrameSetValue(CUI_Slider, I2R(frameValue))
        endif
        set CUI_SyncingSlider = false
        call BlzFrameSetVisible(CUI_Slider, maxPage > 0)
    endif

    loop
        exitwhen rowIndex > CUI_BUTTON_COUNT
        set commandId = CUI_ViewOffset[pid] + rowIndex
        if commandId <= CUI_DefinitionCount then
            if CUI_CommandIcon[commandId] != "" then
                call BlzFrameSetTexture(CUI_ButtonIcon[rowIndex], CUI_CommandIcon[commandId], 0, false)
                call BlzFrameSetVisible(CUI_ButtonIcon[rowIndex], true)
            else
                call BlzFrameSetVisible(CUI_ButtonIcon[rowIndex], false)
            endif
            call BlzFrameSetText(CUI_ButtonText[rowIndex], CUI_CommandName[commandId])
            call BlzFrameSetVisible(CUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(CUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedCommandId = CUI_GetSelectedCommandId(GetLocalPlayer())
    if selectedCommandId <= 0 then
        call BlzFrameSetText(CUI_TitleFrame, CUI_Title)
        call BlzFrameSetText(CUI_TextArea, "No commands configured.")
        return
    endif

    set CUI_SelectedCommandId[pid] = selectedCommandId
    call BlzFrameSetText(CUI_TitleFrame, CUI_Title + " - " + CUI_CommandName[selectedCommandId])
    call BlzFrameSetText(CUI_TextArea, "|cffffcc00Category:|r " + CUI_CommandCategory[selectedCommandId] + "|n|n" + CUI_CommandBody[selectedCommandId])
endfunction

public function ForceUpdate takes nothing returns nothing
    call CUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if CUI_Parent != null then
        if BlzFrameIsVisible(CUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        call BlzFrameSetVisible(CUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    set CUI_SliderValueCache = -1
    if CUI_Parent != null and not BlzFrameIsVisible(CUI_Parent) then
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
    endif
    call BlzFrameSetVisible(CUI_Parent, true)
    call CUI_UpdateUI()
endfunction

private function CUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call Hide()
    endif
endfunction

private function CUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function CUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    local integer maxPage = 0
    local integer targetPage

    if CUI_SyncingSlider then
        return
    endif
    set CUI_HandlingSliderAction = true
    if CUI_DefinitionCount > CUI_BUTTON_COUNT then
        set maxPage = (CUI_DefinitionCount - 1) / CUI_BUTTON_COUNT
    endif
    set CUI_SliderValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
    set targetPage = maxPage - CUI_SliderValueCache
    if targetPage < 0 then
        set targetPage = 0
    elseif targetPage > maxPage then
        set targetPage = maxPage
    endif
    set CUI_ViewOffset[pid] = targetPage * CUI_BUTTON_COUNT
    call CUI_UpdateUI()
    set CUI_HandlingSliderAction = false
endfunction

private function CUI_WheelAction takes nothing returns nothing
    local real nextValue
    local real maxValue

    if GetLocalPlayer() == GetTriggerPlayer() then
        if CUI_Slider == null or CUI_Parent == null or not BlzFrameIsVisible(CUI_Parent) or not BlzFrameIsVisible(CUI_Slider) then
            return
        endif

        if CUI_DefinitionCount > CUI_BUTTON_COUNT then
            set maxValue = I2R((CUI_DefinitionCount - 1) / CUI_BUTTON_COUNT)
        else
            set maxValue = 0.0
        endif
        if maxValue <= 0.0 then
            return
        endif

        set nextValue = BlzFrameGetValue(CUI_Slider)
        if BlzGetTriggerFrameValue() > 0.0 then
            set nextValue = nextValue + 1.0
        else
            set nextValue = nextValue - 1.0
        endif

        if nextValue < 0.0 then
            set nextValue = 0.0
        elseif nextValue > maxValue then
            set nextValue = maxValue
        endif

        call BlzFrameSetValue(CUI_Slider, nextValue)
    endif
endfunction

private function CUI_ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = 0
    local integer commandId = 0

    if CUI_ButtonRow.has(GetHandleId(BlzGetTriggerFrame())) then
        set rowIndex = CUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
        set commandId = CUI_ViewOffset[pid] + rowIndex
        if commandId <= CUI_DefinitionCount then
            set CUI_SelectedCommandId[pid] = commandId
            if GetLocalPlayer() == p then
                call CUI_UpdateUI()
            endif
        endif
    endif

    set p = null
endfunction

private function CUI_InitFrames takes nothing returns nothing
    local framehandle frame
    local integer rowIndex = 1

    call BlzLoadTOCFile(CUI_TocPath)

    set CUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, CUI_FRAME_CONTEXT)
    call CUI_PosBox(CUI_Parent)

    set CUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", CUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(CUI_SliderTrigger, CUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(CUI_WheelTrigger, CUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(CUI_Slider, 0.0, 0.0)
    call BlzFrameSetStepSize(CUI_Slider, 1.0)

    set frame = BlzCreateFrameByType("SLIDER", "CommandsUIMoreScroll", CUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(CUI_WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, CUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, CUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set CUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", CUI_FRAME_CONTEXT)
    set CUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", CUI_FRAME_CONTEXT)
    call BlzFrameSetText(CUI_TitleFrame, CUI_Title)

    call BlzTriggerRegisterFrameEvent(CUI_CloseTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", CUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", CUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)

    set CUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "CommandsUIReturnButton", CUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(CUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(CUI_ReturnButton, CUI_ReturnButtonText)
    call BlzFrameSetPoint(CUI_ReturnButton, FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("TasQuestBoxCloseButton1", CUI_FRAME_CONTEXT), FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(CUI_ReturnTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > CUI_BUTTON_COUNT
        set CUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", CUI_Parent, 0, rowIndex + 400)
        if rowIndex > 1 then
            call BlzFrameSetPoint(CUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, CUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set CUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 400)
        set CUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 400)
        set CUI_ButtonRow.integer[GetHandleId(CUI_Button[rowIndex])] = rowIndex
        call BlzTriggerRegisterFrameEvent(CUI_ButtonTrigger, CUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(CUI_ClearFocusTrigger, CUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(CUI_WheelTrigger, CUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(CUI_Button[1], FRAMEPOINT_TOPRIGHT, CUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    call BlzFrameSetVisible(CUI_Parent, false)
endfunction

public function Init takes nothing returns nothing
    if CUI_Initialized then
        return
    endif
    set CUI_Initialized = true

    set CUI_ButtonRow = Table.create()
    call CUI_InitDefinitions()

    set CUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(CUI_CloseTrigger, function CUI_CloseAction)

    set CUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ReturnTrigger, function CUI_ReturnAction)

    set CUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ClearFocusTrigger, function CUI_ClearFocusAction)

    set CUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(CUI_ButtonTrigger, function CUI_ButtonAction)

    set CUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(CUI_SliderTrigger, function CUI_SliderAction)

    set CUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(CUI_WheelTrigger, function CUI_WheelAction)

    call CUI_InitFrames()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
