library ZoneEvent initializer Init requires ZonesCore, Table, DNC, ExMusic, TasQuestBox, CameraControl
//===========================================================================
/*
    ZoneEvent

    Author: Valdemar
    Version: 1.0 (updated header & API usage)

    Purpose:
        Central handler for per-zone behaviour and transitions. Responsibilities
        include applying music, fog, DNC (day/night), ambient sounds, quest
        discovery, weather-influenced fog, and any zone-specific special
        effects. Supports multiple regions per zone and integrates with
        external systems (ExMusic, DNC, Weather, TasQuestBox, etc.).

    Key features:
        - Automatic music switching via ExMusic
        - Day/Night triggers and adaptive effects via DNC
        - Per-player fog application (AddFogForPlayer integration)
        - Ambient sound management (multiple sounds per zone)
        - Zone discovery / entered UI titles and sounds
        - Optional zone leave cleanup handlers
        - Zone data driven by ZonesCore (zone definitions held there)

    Public API (functions provided by this library):
        - ZoneEvent_GetCurrentZone() returns integer
            Returns the currently active zone ID (0 if none).

        - ZoneEvent_ForceUpdate(unit whichUnit) returns nothing
            Re-applies current zone effects for the given unit (fog, ambient,
            music, DNC). Useful after day/night transitions or when forcing
            updates for a particular unit.

        - ZoneEvent_Enable(boolean enable) returns nothing
            Globally enables/disables the zone system.

        - ZoneEvent_EnableZone(integer zoneId, boolean enable) returns nothing
            Enable or disable a specific zone's enter triggers. (Proxy to
            ZonesCore_EnableZone in the core module.)

        - ZoneEvent_IsZoneEnabled(integer zoneId) returns boolean
            Query whether a zone is enabled.

        - ZoneEvent_GetZoneName(integer zoneId) returns string
            Retrieve the human-readable zone name from ZonesCore.

        - ZoneEvent_EnterZone(integer zoneId, unit whichUnit) returns nothing
            Manually trigger the full zone entry flow for the specified unit.

        - ZoneEvent_SetZoneSilent(integer zoneId) returns nothing
            Set the current zone without triggering discovery/enter effects
            (useful for teleport/travel where you want to set zone state
            before applying effects explicitly).

        - ZoneEvent_ResetZone() returns nothing
            Clear the current zone (use prior to teleporting to avoid
            unintended leave/enter sequences).

        - ZoneEvent_TriggerLeaveCleanup(integer zoneId, unit whichUnit) returns nothing
            Manually invoke the zone leave cleanup handler for a zone.

        - ZoneEvent_EnableLeaveHandler(integer zoneId, boolean enable) returns nothing
            Enable or disable the leave handler trigger for a specific zone.

    Example usage:
        // Disable Zone 11 (Deadwoods) entry events
        call ZoneEvent_EnableZone(11, false)

        // Re-enable later
        call ZoneEvent_EnableZone(11, true)

        // Check before teleporting
        if ZoneEvent_IsZoneEnabled(18) then
            call ZoneEvent_EnterZone(18, udg_PlayerHero)
        endif

        // Teleport player without immediate effects, then trigger effects
        call ZoneEvent_SetZoneSilent(3)
        call SetUnitPosition(hero, x, y)
        call ZoneEvent_EnterZone(3, hero)

        // Force update after a DNC change
        call ZoneEvent_ForceUpdate(udg_PlayerHero)

    Adding new zones:
        1. Add a zone block in ZonesCore zone configuration.
        2. Ensure enter/leave regions are assigned in initialization.
        3. Configure fog, music, DNC name and ambient sounds in ZonesCore.

    Notes:
        - Zone definitions and region handles live in `ZonesCore`.
        - This library assumes `AddFogForPlayer`, `ExMusic_PlayTrack`, and
          the DNC API functions exist and are available in the map.
*/
//===========================================================================

globals
    // Title display configuration
    private constant string ZONE_DISCOVERED_PREFIX = "Discovered |n"
    private constant string ZONE_ENTERED_PREFIX = "Entered |n"
    private constant string ZONE_DISCOVERED_COLOR = "|cFF32CD32" // green
    private constant string ZONE_ENTERED_COLOR = "|cffffffff"    // white
    private constant string ZONE_NAME_COLOR = "|cffffcc00"       // orange
    private constant string COLOR_END = "|r"
    // Track discovered zones for Player(0) only
     private boolean array zoneDiscovered

    //===========================================================================
    // CONFIGURATION
    //===========================================================================
    private constant boolean DEBUG = false               // Enable/disable debug messages
    private constant integer MAX_ZONES = 90000          // Support up to zone ID 10000
    private constant integer MAX_AMBIENT_SOUNDS = 10    // Max ambient sounds per zone
    
    // Unit types to exclude from zone detection (easy to extend - just add more!)
    private constant integer MAX_EXCLUDED_UNIT_TYPES = 10
    private integer array excludedUnitTypes
    private integer excludedUnitTypeCount = 0
    
    //
    // SYSTEM VARIABLES (DO NOT MODIFY)
    //===========================================================================
    private boolean systemEnabled = true
    private boolean zoneDayNightEvent = false           // Set to true when triggered by day/night cycle
    private sound array zoneAmbient[MAX_AMBIENT_SOUNDS] // Ambient sound handles
    private integer zoneAmbientCount = 0
    private trigger array zoneTriggers                  // Trigger handles for each zone
    private trigger array zoneLeaveTriggers             // Trigger handles for zone leave events
    private Table triggerToZoneId                       // Table mapping triggers to zoneIds
    private trigger dayNightEventTrigger = null         // Trigger for day/night transitions
    private timer dayNightUpdateTimer = null            // Timer for periodic day/night updates
    private timer dayNightResetTimer  = null            // Timer to reset day/night event flag
    // Configurable sounds for zone discover/enter
    private sound ZONE_DISCOVER_SOUND = null
    private sound ZONE_ENTER_SOUND = null
    private sound DUNGEON_DISCOVER_SOUND = null
    private sound DUNGEON_ENTER_SOUND = null

    // Set which hero to use for Day/Night event updates
    private unit UPDATE_UNIT = null
    
    // Player group check (assumes udg_PlayerGroup from GUI)
    // Note: You may need to adjust this based on your actual player group variable
    
    // Morph detection (assumes these exist from GUI)
    // Note: Adjust if variable names differ
    
    private string tempString = ""
    private unit z_EnteringUnit = null
    private boolean cheat_Camlock = false
    
    // Zone questbox tracking
    private integer array zones  // 1 if TasQuestBox_Add called for zone, else 0
    
    // Zone data storage (declared here, populated after struct definition)
    private integer array zoneDatabase

    // External variables (GUI) and systems
    /* ===  DNEEvent
            udg_IsDayTime
    */ 

endglobals
//===========================================================================
// Helper Functions
//===========================================================================
// Helper: Boolean to Integer
function B2I takes boolean b returns integer
    if b then
        return 1
    endif
    return 0
endfunction

// Debug output
private function Debug takes string msg returns nothing
    if DEBUG then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[ZoneEvent] " + msg)
    endif
endfunction

private function IsUnitTypeExcluded takes integer unitTypeId returns boolean
    local integer i = 0
    loop
        exitwhen i >= excludedUnitTypeCount
        if excludedUnitTypes[i] == unitTypeId then
            return true
        endif
        set i = i + 1
    endloop
    return false
endfunction

private function ClearAmbientSounds takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > MAX_AMBIENT_SOUNDS
        if zoneAmbient[i] != null then
            // Destroy ambient sound
            call StopSound(zoneAmbient[i], false, true)
            set zoneAmbient[i] = null
        endif
        set i = i + 1
    endloop
    set zoneAmbientCount = 0
endfunction

private function AddAmbientSound takes string soundName, rect whichRegion returns nothing
    local sound s
    local real x
    local real y
    if soundName == "" or whichRegion == null then
        return
    endif
    // Get center of region for 3D sound
    set x = (GetRectMinX(whichRegion) + GetRectMaxX(whichRegion)) * 0.5
    set y = (GetRectMinY(whichRegion) + GetRectMaxY(whichRegion)) * 0.5
    set s = CreateSound(soundName, false, true, true, 10, 10, "")
    call SetSoundPosition(s, x, y, 0)
    call SetSoundDistanceCutoff(s, 5000)
    call StartSound(s)
    set zoneAmbient[zoneAmbientCount] = s
    set zoneAmbientCount = zoneAmbientCount + 1
    if DEBUG then
        call Debug("Adding ambient: " + soundName)
    endif
endfunction

private function ApplyFog takes ZoneData z, integer zoneIndex, boolean isDay, player p returns nothing
    local string weather = ""
    local real array fog
    local integer i

    set z = ZonesCore_GetZoneData(zoneIndex)

    if z.name != "" then
        set weather = z.GetWeatherState() // Get current weather state from ZoneData 
    endif

    if DEBUG then
        call Debug("ApplyFog called for zone: " + z.name + " (ID: " + I2S(zoneIndex) + "), isDay=" + I2S(B2I(isDay)) + ", weather=" + weather)
    endif
    
    if weather == "rain_heavy" or weather == "snow_heavy" or weather == "storm" then
        if DEBUG then
            call Debug("Fog - Applying HEAVY weather fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherHeavy[i]
            set i = i + 1
        endloop
    elseif weather == "rain_medium" or weather == "snow_medium" then
        if DEBUG then
            call Debug("Fog - Applying MEDIUM weather fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherMedium[i]
            set i = i + 1
        endloop
    elseif weather == "rain_light" or weather == "snow_light" or weather == "wind" then
        if DEBUG then
            call Debug("Fog - Applying LIGHT weather fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherLight[i]
            set i = i + 1
        endloop
    elseif isDay then
        if DEBUG then
            call Debug("Fog - Applying DAY fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogDay[i]
            set i = i + 1
        endloop
    else
        if DEBUG then
            call Debug("Fog - Applying NIGHT fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogNight[i]
            set i = i + 1
        endloop
    endif

    if DEBUG then
        call Debug("AddFogForPlayer debug: fog[0]=" + R2S(fog[0]) + ", fog[1]=" + R2S(fog[1]) + ", fog[2]=" + R2S(fog[2]) + ", fog[3]=" + R2S(fog[3]) + ", fog[4]=" + R2S(fog[4]))
    endif

    // Apply fog to player
    call AddFogForPlayer(fog[0], fog[1], fog[2], fog[3], fog[4], p)

endfunction

// Calls the correct DNC function from DNC.j based on dncName
private function RunDNC takes string dncName returns nothing
    if dncName == "Outdoors" then
        call DNC_Outdoors()
    elseif dncName == "Underground" then
        call DNC_Underground()
    elseif dncName == "DarkPlace" then
        call DNC_DarkPlace()
    elseif dncName == "DarkerPlace" then
        call DNC_DarkerPlace()
    elseif dncName == "Outdoors Red" then
        call DNC_OutdoorsRed()
    elseif dncName == "Outdoors Dirty" then
        call DNC_OutdoorsDirty()
    elseif dncName == "Outdoors Mountains" then
        call DNC_OutdoorsMountains()
    elseif dncName == "Firelands" then
        call DNC_Firelands()
    elseif dncName == "Death1" then
        call DNC_Death1()
    endif
    if DEBUG then
        call Debug("Running DNC: " + dncName)
    endif
endfunction

private function HandleSpecialEffects takes ZoneData z, unit triggeringUnit returns nothing
    local player whichPlayer = Player(0)
    // Handle special zone effects (camera, sky, etc.)

    if triggeringUnit != null then
        set whichPlayer = GetOwningPlayer(triggeringUnit)
    endif
    
    if z.setSkyClear then
        call SetSkyModel(null)
    endif
    
    if z.hasSpecialCamera and z.zoneId == 104 then
        // Boom Mine special camera
        call CameraControl_SetSpecialMode(whichPlayer, CameraControl_CAMERA_SPECIAL_MODE_BOOMMINE)
        if DEBUG then
            call Debug("Applying special camera for Boom Mine")
        endif
    else
        call CameraControl_ClearSpecialMode(whichPlayer)
    endif

    set whichPlayer = null
endfunction

private function CreateQuestLog takes ZoneData z returns nothing
    local integer id = z.zoneId
    local string boxText
    if zones[id] == 0 then
        // Build rich TasQuestBox text
        set boxText = "|cffffcc00Description|r|n" + z.questDescription
        set boxText = boxText + "|n|n|cffffcc00Environment|r|n" + z.environmentType
        set boxText = boxText + "|n|n|cffffcc00Level|r|n" + z.questLevelReq
        set boxText = boxText + "|n|n|cffffcc00Factions|r|n" + z.factions
        set boxText = boxText + "|n|n|cffffcc00Notable characters|r|n" + z.notableCharacters
        set boxText = boxText + "|n|n|cffffcc00Common entities|r|n" + z.notableEntities
        call TasQuestBox_Add(z.name, boxText, z.iconPath)
        set zones[id] = 1 // Mark as added to prevent duplicates
        if DEBUG then
            call Debug("Created zone quest: " + z.name)
        endif
    endif
endfunction

// Helper to build colored zone title
private function BuildZonePrefix takes string prefix, string prefixColor returns string
    return prefixColor + prefix + COLOR_END
endfunction

private function BuildZoneName takes string zoneName, string zoneColor returns string
    return zoneColor + zoneName + COLOR_END
endfunction

//======================================================
// Zone - MoveStart Handler
// Move unit to startRegion and issue move to moveRegion
//======================================================
private function MoveStart takes ZoneData z, unit enteringUnit returns nothing
    local real xStart = 0.0
    local real yStart = 0.0
    local real xMove = 0.0
    local real yMove = 0.0
    local unit u
    local group tempGroup

    /* ========== NOTE ==========
    This function is called when a unit enters a zone that has defined startRegion and moveRegion.
    It moves the entering unit to the center of the startRegion, then issues a move order to the center of the moveRegion.
    Additionally, it moves any units in the Companion_Group and TamedUnits groups that are alive, applying the same move logic.

    Other player units and/or Heroes are not affected by this function, as it is only triggered by the unit that entered the region (typically the player's hero).
    E.g., Nazrek enters the region, so Nazrek is moved to startRegion and then ordered to move to moveRegion. Zulkis won't be moved.
    >> We can later decide whether to have range check to move only the nearby alive companions, tamed, player units. 
    >> Use WithinRange library to validate the range between the entering unit and the companions/tamed units before moving them)
    */

    // Basic validation
    if z == null or enteringUnit == null then
        return
    endif

    // Only Player(0)
    if GetOwningPlayer(enteringUnit) != Player(0) then
        return
    endif

    // Check regions exist
    if z.startRegion == null or z.moveRegion == null then
        return
    endif

    // Get center coordinates of startRegion and moveRegion
    set xStart = (GetRectMinX(z.startRegion) + GetRectMaxX(z.startRegion)) * 0.5
    set yStart = (GetRectMinY(z.startRegion) + GetRectMaxY(z.startRegion)) * 0.5
    set xMove  = (GetRectMinX(z.moveRegion) + GetRectMaxX(z.moveRegion)) * 0.5
    set yMove  = (GetRectMinY(z.moveRegion) + GetRectMaxY(z.moveRegion)) * 0.5

    // Move entering unit to startRegion
    call SetUnitPosition(enteringUnit, xStart, yStart)
    call SetUnitFacing(enteringUnit, 215.0)
    // Issue order to move to moveRegion
    call IssuePointOrder(enteringUnit, "move", xMove, yMove)

    // Move all companions and tamed units (IF ALIVE) using ONE tempGroup
    set tempGroup = CreateGroup()
    call GroupAddGroup(udg_Companion_Group, tempGroup)
    call GroupAddGroup(udg_TamedUnits, tempGroup)
    // PLACEHOLDER; player other units/heroes
    ///////////////////////////////

    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        call GroupRemoveUnit(tempGroup, u)
        if IsUnitAliveBJ(u) then
            call SetUnitPosition(u, xStart, yStart)
            call IssuePointOrder(u, "move", xMove, yMove)
        endif
        // PLACEHOLDER: Add range check here if we want to only move nearby companions/tamed units
        ///////////////////////////////
    endloop

    call DestroyGroup(tempGroup)

    set u = null
endfunction

//======================================================
// Zone - MoveOut Handler
// Move unit to outRegion and issue move to moveOutRegion
//======================================================
private function MoveOut takes nothing returns nothing
    local ZoneData z
    local unit u = GetTriggerUnit()
    local player trigPlayer = GetOwningPlayer(u)
    local integer unitType = GetUnitTypeId(u)
    local trigger trig = GetTriggeringTrigger()
    local integer zoneId = 0
    local integer currentZone = ZonesCore_GetCurrentZone()
    local real xStart = 0.0
    local real yStart = 0.0
    local real xMove = 0.0
    local real yMove = 0.0
    local group tempGroup

    /* ========== NOTE ==========
    This function is called when a unit leaves a zone that has defined outRegion and moveOutRegion.
    It moves the entering unit to the center of the outRegion, then issues a move order to the center of the moveOutRegion.
    Additionally, it moves any units in the Companion_Group and TamedUnits groups that are alive, applying the same move logic.

    Other player units and/or Heroes are not affected by this function, as it is only triggered by the unit that entered the region (typically the player's hero).
    E.g., Nazrek leaves the region, so Nazrek is moved to outRegion and then ordered to move to moveOutRegion. Zulkis won't be moved.
    >> We can later decide whether to have range check to move only the nearby alive companions, tamed, player units. 
    >> Use WithinRange library to validate the range between the entering unit and the companions/tamed units before moving them)
    */

    if not IsPlayerInForce(trigPlayer, udg_PlayerGroup) then
        /* Disabled because alot of spammy debug messages
        if DEBUG then
            call Debug("Early exit: Player not in udg_PlayerGroup")
        endif
        */
        return
    endif
    if not IsUnitType(u, UNIT_TYPE_HERO) then
        /* Disabled because alot of spammy debug messages
        if DEBUG then
            call Debug("Early exit: Unit is not a hero")
        endif
        */
        return
    endif
    if IsUnitTypeExcluded(unitType) then
        /* Disabled because alot of spammy debug messages
        if DEBUG then
            call Debug("Early exit: Unit type is excluded")
        endif
        */
        return
    endif
    set zoneId = triggerToZoneId.get(trig)
    if zoneId == 0 then
        if DEBUG then
            call Debug("Could not find zoneId for this trigger")
        endif
        return
    endif

    set z = ZonesCore_GetZoneData(zoneId)

    // Basic validation
    if z == null or u == null then
        return
    endif

    // Only Player(0)
    if trigPlayer != Player(0) then
        return
    endif

    // Check regions exist
    if z.outRegion == null or z.moveOutRegion == null then
        return
    endif

    // Get center coordinates of outRegion and moveOutRegion
    set xStart = (GetRectMinX(z.outRegion) + GetRectMaxX(z.outRegion)) * 0.5
    set yStart = (GetRectMinY(z.outRegion) + GetRectMaxY(z.outRegion)) * 0.5
    set xMove  = (GetRectMinX(z.moveOutRegion) + GetRectMaxX(z.moveOutRegion)) * 0.5
    set yMove  = (GetRectMinY(z.moveOutRegion) + GetRectMaxY(z.moveOutRegion)) * 0.5

    // Move entering unit to outRegion
    call SetUnitPosition(u, xStart, yStart)
    call SetUnitFacing(u, 215.0)
    // Issue order to move to moveOutRegion
    call IssuePointOrder(u, "move", xMove, yMove)

    // Move all companions and tamed units (IF ALIVE) using ONE tempGroup
    set tempGroup = CreateGroup()
    call GroupAddGroup(udg_Companion_Group, tempGroup)
    call GroupAddGroup(udg_TamedUnits, tempGroup)
    // PLACEHOLDER; player other units/heroes
    ///////////////////////////////

    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        call GroupRemoveUnit(tempGroup, u)
        if IsUnitAliveBJ(u) then
            call SetUnitPosition(u, xStart, yStart)
            call IssuePointOrder(u, "move", xMove, yMove)
        endif
        // PLACEHOLDER: Add range check here if we want to only move nearby companions/tamed units
        ///////////////////////////////
    endloop

    call DestroyGroup(tempGroup)

    set u = null
endfunction

//===========================================================================
// Zone Leave Cleanup Handler
//===========================================================================
private function HandleZoneLeaveCleanup takes integer zoneId, unit triggeringUnit returns nothing
    local ZoneData z = ZonesCore_GetZoneData(zoneId)
    if z == 0 or not z.hasLeaveHandler then
        return  // No cleanup needed
    endif
    if DEBUG then
        call Debug("Leaving: " + z.name + " (ID: " + I2S(zoneId) + ") - Running cleanup")
    endif
    // Zone-specific cleanup actions
    // Add cleanup logic for specific zones here
    if zoneId == 5 then
        // Firelands - Remove VolcanoLoop sound
        if DEBUG then
            call Debug("Firelands cleanup: Removing VolcanoLoop sound")
        endif
        // Placeholder: call RemoveSound(gg_snd_VolcanoLoop, gg_rct_016Firelands)
    endif
    // Add more zone-specific cleanup here as needed
endfunction

//===========================================================================
// Zone Music Handler
//===========================================================================
private function Zones_HandleZoneMusic takes ZoneData z returns nothing
    set udg_ExMusicInteger = z.musicTrack
    if DEBUG then
        call Debug("Music track: " + I2S(z.musicTrack))
        call Debug("udg_ExMusicInteger: " + I2S(udg_ExMusicInteger))
    endif

    call ExMusic_PlayTrack(udg_ExMusicInteger)
    
endfunction

//===========================================================================
// Zone Transition Handler
//===========================================================================
private function HandleZoneEnter takes integer newZoneId, unit triggeringUnit returns nothing
    local ZoneData z
    local player triggerPlayer = GetOwningPlayer(triggeringUnit)
    local boolean isDay = udg_DNE_IsDaytime
    local boolean array zoneEnabled
    local integer pid
    local integer discoverKey
    local integer currentZone = ZonesCore_GetCurrentZone()
    
    set zoneEnabled[newZoneId] = ZonesCore_IsZoneEnabled(newZoneId)

    if DEBUG then   
        call Debug("HandleZoneEnter called")
    endif 
    if not systemEnabled then
        if DEBUG then   
            call Debug("System not enabled! (return)")
        endif
        return
    endif
    if not zoneEnabled[newZoneId] then
        if DEBUG then   
            call Debug("ERROR: Zone " + I2S(newZoneId) + " not enabled! (return)")
        endif
        return  // Zone disabled
    endif
    if newZoneId == currentZone then
        if DEBUG then
            call Debug("Already in this zone - " + I2S(newZoneId) + " (return)")
        endif
        return  // Already in this zone
    endif
    set z = ZonesCore_GetZoneData(newZoneId)

    // If this zone has a startRegion/moveRegion, move units
    if z.startRegion != null and z.moveRegion != null then
        call MoveStart(z, triggeringUnit)
    endif

    // Set current zone
    call ZonesCore_SetCurrentZone(newZoneId)

    // Show discovered/entered title
    set pid = GetPlayerId(triggerPlayer)
    if not zoneDiscovered[newZoneId] then
        set zoneDiscovered[newZoneId] = true
        // Zone Discovered
        call ShowRegionTitle(BuildZonePrefix(ZONE_DISCOVERED_PREFIX, ZONE_DISCOVERED_COLOR), BuildZoneName(z.name, ZONE_NAME_COLOR))
        if z.isDungeon then
            if DUNGEON_DISCOVER_SOUND != null then
                call StartSound(DUNGEON_DISCOVER_SOUND)
            endif
        else
            if ZONE_DISCOVER_SOUND != null then
                call StartSound(ZONE_DISCOVER_SOUND)
            endif
        endif
    else
        call ShowRegionTitle(BuildZonePrefix(ZONE_ENTERED_PREFIX, ZONE_ENTERED_COLOR), BuildZoneName(z.name, ZONE_NAME_COLOR))
        if z.isDungeon then
            if DUNGEON_ENTER_SOUND != null then
                call StartSound(DUNGEON_ENTER_SOUND)
            endif
        else
            if ZONE_ENTER_SOUND != null then
                call StartSound(ZONE_ENTER_SOUND)
            endif
        endif
    endif
    if z == 0 then
        if DEBUG then
            call Debug("ERROR: Zone " + I2S(newZoneId) + " not found! (return)")
        endif
        return
    endif
    if DEBUG then
        call Debug("Entering: " + z.name + " (ID: " + I2S(newZoneId) + ")")
    endif
    /* Unused atm
    if z.playSoundOnEnter then
        if DEBUG then
            call BJDebugMsg("[Zones] Playing dungeon enter sound")
        endif
    endif
    */

    // Ambient
    call ClearAmbientSounds()
    if isDay and z.ambientDaySound != "" then
        call AddAmbientSound(z.ambientDaySound, null)
    elseif not isDay and z.ambientNightSound != "" then
        call AddAmbientSound(z.ambientNightSound, null)
    endif

    // Music
    call Zones_HandleZoneMusic(z)

    // DNC
    call RunDNC(z.dncName)
    
    // Fog
    if DEBUG then
        call Debug("ApplyFog: udg_DNE_IsDaytime=" + I2S(B2I(udg_DNE_IsDaytime)) + ", isDay=" + I2S(B2I(isDay)))
    endif
    call ApplyFog(z, newZoneId, isDay, triggerPlayer)

    // Zone Special stuff
    call HandleSpecialEffects(z, triggeringUnit)

    if not zoneDayNightEvent then
        call CreateQuestLog(z)
        if DEBUG then
            call Debug("Entered: " + z.name)
        endif
    endif
    set z_EnteringUnit = triggeringUnit
endfunction

//===========================================================================
// Region Enter Event Handler
//===========================================================================
private function OnUnitEnterRegion takes nothing returns nothing
    local unit trigUnit = GetTriggerUnit()
    local player trigPlayer = GetOwningPlayer(trigUnit)
    local integer unitType = GetUnitTypeId(trigUnit)
    local trigger trig = GetTriggeringTrigger()
    local integer zoneId = 0

    /* Disabled because alot of spammy debug messages
    if DEBUG then
        call Debug("OnUnitEnterRegion triggered")
    endif
    */

    if not IsPlayerInForce(trigPlayer, udg_PlayerGroup) then
        /* Disabled because alot of spammy debug messages
        if DEBUG then
            call Debug("Early exit: Player not in udg_PlayerGroup")
        endif
        */
        return
    endif
    if not IsUnitType(trigUnit, UNIT_TYPE_HERO) then
        /* Disabled because alot of spammy debug messages
        if DEBUG then
            call Debug("Early exit: Unit is not a hero")
        endif
        */
        return
    endif
    if IsUnitTypeExcluded(unitType) then
        /* Disabled because alot of spammy debug messages
        if DEBUG then
            call Debug("Early exit: Unit type is excluded")
        endif
        */
        return
    endif
    if udg_NazgrekMorphing or udg_ZulkisMorphing then
        if DEBUG then
            call Debug("Early exit: Morphing detected")
        endif
        return
    endif
    set zoneId = triggerToZoneId.get(trig)
    if zoneId == 0 then
        if DEBUG then
            call Debug("Could not find zoneId for this trigger")
        endif
        return
    endif
    call HandleZoneEnter(zoneId, trigUnit)

endfunction

//===========================================================================
// Region Leave Event Handler
//===========================================================================
private function OnUnitLeaveRegion takes nothing returns nothing
    local unit trigUnit = GetTriggerUnit()
    local player trigPlayer = GetOwningPlayer(trigUnit)
    local integer unitType = GetUnitTypeId(trigUnit)
    local trigger trig = GetTriggeringTrigger()
    local integer zoneId = 0
    if not IsPlayerInForce(trigPlayer, udg_PlayerGroup) then
        return
    endif
    if not IsUnitType(trigUnit, UNIT_TYPE_HERO) then
        return
    endif
    if IsUnitTypeExcluded(unitType) then
        return
    endif
    if udg_NazgrekMorphing or udg_ZulkisMorphing then
        return
    endif
    set zoneId = triggerToZoneId.get(trig)
    if zoneId == 0 then
        return
    endif
    call HandleZoneLeaveCleanup(zoneId, trigUnit)

endfunction

//===========================================================================
// Public API
//===========================================================================

// Re-applies all effects for the current zone (music, DNC, fog, ambient)
public function ApplyCurrentZoneEffects takes nothing returns nothing
    local ZoneData z
    local player triggerPlayer = Player(0)
    local boolean isDay = udg_DNE_IsDaytime
    local integer zoneIndex = ZonesCore_GetCurrentZone()
    
    if DEBUG then
        call Debug("ApplyCurrentZoneEffects called: currentZone=" + I2S(zoneIndex) + ", isDay=" + I2S(B2I(isDay)))
    endif

    if zoneIndex == 0 then
        if DEBUG then
            call Debug("No current zone (currentZone=0), nothing to apply")
        endif
        return
    endif

    set z = ZonesCore_GetZoneData(zoneIndex)
    if z == 0 then
        if DEBUG then
            call Debug("Zone data not found for currentZone=" + I2S(zoneIndex))
        endif
        return
    endif

    /*
    if DEBUG then
        call Debug("Applying effects for zone: " + z.name + " (ID: " + I2S(zoneIndex) + ")")
    endif
    */

    // Music
    set udg_ExMusicInteger = z.musicTrack
    /*
    if DEBUG then
        call Debug("ApplyCurrentZoneEffects: Setting music track to " + I2S(udg_ExMusicInteger))
    endif
    */
    call ExMusic_PlayTrack(udg_ExMusicInteger)

    /*
    // DNC
    if DEBUG then
        call Debug("ApplyCurrentZoneEffects: Running DNC: " + z.dncName)
    endif
    call RunDNC(z.dncName)
    */

    // Fog
    if DEBUG then
        call Debug("ApplyCurrentZoneEffects: Applying fog (udg_DNE_IsDaytime=" + I2S(B2I(udg_DNE_IsDaytime)) + ", isDay=" + I2S(B2I(isDay)) + ")")
    endif
    call ApplyFog(z, zoneIndex, isDay, triggerPlayer)

    // Ambient
    // Clear existing ambient sounds first
    /*
    if DEBUG then
        call Debug("ApplyCurrentZoneEffects: Clearing ambient sounds and applying appropriate ambient for time of day")
    endif
    */
    call ClearAmbientSounds()
    if isDay and z.ambientDaySound != "" then
        call AddAmbientSound(z.ambientDaySound, null)
    elseif not isDay and z.ambientNightSound != "" then
        call AddAmbientSound(z.ambientNightSound, null)
    endif

    // Zone Special stuff
    /*
    if DEBUG then
        call Debug("ApplyCurrentZoneEffects: Running zone special effects handler")
    endif
    */
    call HandleSpecialEffects(z, null)

endfunction

public function ForceUpdate takes unit whichUnit returns nothing
    local integer currentZone = ZonesCore_GetCurrentZone()
    // Force zone update for a specific unit
    // This can be called by day/night events or manually
    set zoneDayNightEvent = true
    // Re-enter current zone to update fog/ambient
    if currentZone > 0 then
        call HandleZoneEnter(currentZone, whichUnit)
    endif
    set zoneDayNightEvent = false
endfunction

public function Enable takes boolean enable returns nothing
    set systemEnabled = enable
    if DEBUG then
        if enable then
            call Debug("System enabled")
        else
            call Debug("System disabled")
        endif
    endif
endfunction

public function EnterZone takes integer zoneId, unit whichUnit returns nothing
    // Manually trigger zone entry (useful for teleportation, testing, etc.)
    call ZonesCore_EnableZone(zoneId, true)
    call HandleZoneEnter(zoneId, whichUnit) 
endfunction

public function TriggerLeaveCleanup takes integer zoneId, unit whichUnit returns nothing
    // Manually trigger zone leave cleanup (useful when teleporting out)
    call HandleZoneLeaveCleanup(zoneId, whichUnit)
endfunction

public function EnableLeaveHandler takes integer zoneId, boolean enable returns nothing
    // Enable/disable leave trigger for a specific zone
    if zoneLeaveTriggers[zoneId] != null then
        if enable then
            call EnableTrigger(zoneLeaveTriggers[zoneId])
        else
            call DisableTrigger(zoneLeaveTriggers[zoneId])
        endif
        
        if DEBUG then
            if enable then
                call Debug("Leave handler for zone " + I2S(zoneId) + " enabled")
            else
                call Debug("Leave handler for zone " + I2S(zoneId) + " disabled")
            endif
        endif
    endif
endfunction

//===========================================================================
// Day/Night Event System
//===========================================================================

// Timer callback to update zone effects after day/night change
private function DayNight_UpdateZone takes nothing returns nothing
    local integer currentZone = ZonesCore_GetCurrentZone()
    call PauseTimer(dayNightUpdateTimer)

    if currentZone > 0 then
        call ApplyCurrentZoneEffects()
    endif
endfunction

// Timer callback to reset day/night event flag
private function DayNight_ResetFlag takes nothing returns nothing
    call PauseTimer(dayNightResetTimer)
    set zoneDayNightEvent = false

    if DEBUG then
        call Debug("Day/Night event completed")
    endif
endfunction

private function OnDayNightEvent takes nothing returns nothing
    if DEBUG then
        call Debug("Day/Night event triggered")
    endif

    set zoneDayNightEvent = true

    // Init timers once
    if dayNightUpdateTimer == null then
        set dayNightUpdateTimer = CreateTimer()
    endif
    if dayNightResetTimer == null then
        set dayNightResetTimer = CreateTimer()
    endif

    // Restart timers safely
    // Wait for DNE_IsDaytime to update properly
    call TimerStart(dayNightUpdateTimer, 1.00, false, function DayNight_UpdateZone)   
    // Wait 3 seconds before resetting flag  
    call TimerStart(dayNightResetTimer, 3.00, false, function DayNight_ResetFlag)
endfunction

//===========================================================================
// INIT - Register all zone regions here
//===========================================================================
private function RegisterZoneRegions takes nothing returns nothing
    local trigger t
    
    // Register enter triggers for all zones using ZonesCore data
    local integer zoneId = 1
    local ZoneData z
    local integer i
    loop
        exitwhen zoneId > MAX_ZONES
        set z = ZonesCore_GetZoneData(zoneId)
        if z != 0 and z.enterRegionCount > 0 then
            set t = CreateTrigger()
            set i = 0
            loop
                exitwhen i >= z.enterRegionCount
                call TriggerRegisterEnterRectSimple(t, z.enterRegions[i])
                set i = i + 1
            endloop
            call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
            set zoneTriggers[zoneId] = t
            call triggerToZoneId.store(t, zoneId)
        endif
        set zoneId = zoneId + 1
    endloop

endfunction

//===========================================================================
// Register startRegion and exitRegion triggers per zone
// NOTE: only register Exit triggers here, as startRegion triggers will be handled by the MoveStart function when entering the zone.
//===========================================================================
private function RegisterZoneExitRegions takes nothing returns nothing
    local trigger tExit
    local integer zoneId = 1
    local ZoneData z

    loop
        exitwhen zoneId > MAX_ZONES
        set z = ZonesCore_GetZoneData(zoneId)
        if z != null and z.exitRegion != null then

            // Create exit trigger
            set tExit = CreateTrigger()
            call TriggerRegisterEnterRectSimple(tExit, z.exitRegion)
            call TriggerAddAction(tExit, function MoveOut)

            // Store trigger for optional leave handling
            set zoneLeaveTriggers[zoneId] = tExit
            call triggerToZoneId.store(tExit, zoneId)

        endif
        set zoneId = zoneId + 1
    endloop
endfunction

 //=======================================================================
// INIT Variables (WE created global variables)
//=======================================================================
private function InitVariables takes nothing returns nothing
    // Initialize variables to global variables for Day/Night updates
    set UPDATE_UNIT = udg_Nazgrek

    // Initialize sound variables to null
    set ZONE_DISCOVER_SOUND = gg_snd_Interface_ZoneDiscovered
    set ZONE_ENTER_SOUND = gg_snd_ZoneEnter
    set DUNGEON_DISCOVER_SOUND = gg_snd_Interface_DungeonEnter
    set DUNGEON_ENTER_SOUND = gg_snd_Interface_DungeonEnter

endfunction

 //=======================================================================
// INIT
//=======================================================================
private function Init takes nothing returns nothing
    if DEBUG then
        call Debug("Initializing zone system...")
    endif
    
    // Initialize excluded unit types list (EASY TO EXTEND - just add more lines!)
    /*
    set excludedUnitTypes[0] = 'H60H'  // Bag
    set excludedUnitTypes[1] = 'O61E'  // Companions
    set excludedUnitTypes[2] = 'O005'  // Reputations
    set excludedUnitTypes[3] = 'O006'  // Stats
    set excludedUnitTypeCount = 4
    // To add more excluded types, simply:
    // set excludedUnitTypes[2] = 'xxxx'  // Your unit type
    // set excludedUnitTypeCount = 3
    */ 
    
    set triggerToZoneId = Table.create()

    // Register zone enter triggers
    call RegisterZoneRegions() 
    // Register zone exit triggers
    call RegisterZoneExitRegions() 

    // Set up Day/Night event trigger
    set dayNightEventTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(dayNightEventTrigger, "udg_DNE_DayNightEvent", EQUAL, 1.00)
    call TriggerRegisterVariableEvent(dayNightEventTrigger, "udg_DNE_DayNightEvent", EQUAL, 2.00)
    call TriggerAddAction(dayNightEventTrigger, function OnDayNightEvent)

    // Initialize variables (WE created global variables)
    call InitVariables()

    if DEBUG then
        call Debug("Zone system initialized!")
        call Debug("Day/Night event system active")
    endif
endfunction

endlibrary
