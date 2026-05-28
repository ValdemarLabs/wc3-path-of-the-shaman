library Zones initializer Init requires Table, DNC, ExMusic
//===========================================================================
// Full Zones System - Patched for WeatherSystem integration
//===========================================================================

globals
    // Titles & colors
    private constant string ZONE_DISCOVERED_PREFIX = "Discovered |n"
    private constant string ZONE_ENTERED_PREFIX = "Entered |n"
    private constant string ZONE_DISCOVERED_COLOR = "|cFF32CD32"
    private constant string ZONE_ENTERED_COLOR = "|cFFFFFFFF"
    private constant string ZONE_NAME_COLOR = "|cFFFFCC00"
    private constant string COLOR_END = "|r"

    // Weather constants
    private constant integer ZONE_WEATHER_NONE   = 0
    private constant integer ZONE_WEATHER_LIGHT  = 1
    private constant integer ZONE_WEATHER_MEDIUM = 2
    private constant integer ZONE_WEATHER_HEAVY  = 3

    // System variables
    private boolean systemEnabled = true
    private integer currentZone = 0
    private boolean zoneDayNightEvent = false
    private boolean array zoneDiscovered
    private integer array zoneEnabled
    private integer array excludedUnitTypes
    private integer excludedUnitTypeCount = 0

    // Zone Data
    private ZoneData array zoneDatabase
    private integer array zones // quest log flags

    // Triggers
    private trigger array zoneTriggers
    private trigger array zoneLeaveTriggers
    private Table triggerToZoneId

    // Ambient sounds
    private sound array zoneAmbient[10]
    private integer zoneAmbientCount = 0

    // Day/Night timers
    private trigger dayNightEventTrigger = null
    private timer dayNightUpdateTimer = null
    private timer dayNightResetTimer = null

    // Sounds
    private sound ZONE_DISCOVER_SOUND = null
    private sound ZONE_ENTER_SOUND = null
    private sound DUNGEON_DISCOVER_SOUND = null
    private sound DUNGEON_ENTER_SOUND = null

    // Player reference
    private player array fog_Player

    // Last entering unit
    private unit z_EnteringUnit = null
endglobals

//===========================================================================
// Zone Data Structure
//===========================================================================
struct ZoneData
    integer zoneId
    string name
    string environmentType
    integer musicTrack
    string dncName
    boolean isDungeon
    boolean playSoundOnEnter
    boolean hasSpecialCamera
    boolean setSkyClear
    boolean hasLeaveHandler
    string questTitle
    string questDescription
    string questLevelReq
    string factions
    string notableEntities
    string notableCharacters
    string iconPath

    rect array regions
    string ambientDaySound
    string ambientNightSound

    real array fogDay[5]
    real array fogNight[5]
    real array fogWeatherLight[5]
    real array fogWeatherMedium[5]
    real array fogWeatherHeavy[5]

    integer weatherState

    static method create takes integer id, string zoneName returns thistype
        local thistype this = thistype.allocate()
        set .zoneId = id
        set .name = zoneName
        set .environmentType = "Unknown"
        set .musicTrack = 0
        set .dncName = "Outdoors"
        set .isDungeon = false
        set .playSoundOnEnter = true
        set .hasSpecialCamera = false
        set .setSkyClear = false
        set .hasLeaveHandler = false
        set .questTitle = "Zone: " + zoneName
        set .questDescription = ""
        set .questLevelReq = "|cFFFFCC00Level:|r |cFFFFFFFF??|r"
        set .factions = "Unknown"
        set .notableEntities = "Unknown"
        set .notableCharacters = "Unknown"
        set .iconPath = "ReplaceableTextures\\CommandButtons\\BTNSunderingBlades.blp"
        set .ambientDaySound = ""
        set .ambientNightSound = ""
        set .weatherState = ZONE_WEATHER_NONE
        return this
    endmethod
endstruct

//===========================================================================
// Configure Zones
//===========================================================================
private function ConfigureZones takes nothing returns nothing
    local ZoneData z

    //========================
    // Zone 01: Twilight Grove
    //========================
    set z = ZoneData.create(1, "Twilight Grove")
    set z.environmentType = "Ancient Forest"
    set z.musicTrack = 18
    set z.dncName = "Outdoors"
    set z.weatherState = ZONE_WEATHER_NONE
    set z.fogDay[0] = 400.0
    set z.fogDay[1] = 3000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 100.0
    set z.fogNight[1] = 1000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.fogWeatherLight[0] = 200.0
    set z.fogWeatherLight[1] = 1200.0
    set z.fogWeatherLight[2] = 60.0
    set z.fogWeatherLight[3] = 60.0
    set z.fogWeatherLight[4] = 70.0
    set z.fogWeatherMedium[0] = 120.0
    set z.fogWeatherMedium[1] = 900.0
    set z.fogWeatherMedium[2] = 40.0
    set z.fogWeatherMedium[3] = 40.0
    set z.fogWeatherMedium[4] = 60.0
    set z.fogWeatherHeavy[0] = 60.0
    set z.fogWeatherHeavy[1] = 500.0
    set z.fogWeatherHeavy[2] = 20.0
    set z.fogWeatherHeavy[3] = 20.0
    set z.fogWeatherHeavy[4] = 40.0
    set z.ambientDaySound = "gg_snd_Ambient_EnchantedForestDay"
    set z.ambientNightSound = "gg_snd_Ambient_ForestNight"
    set z.regions[0] = gg_rct_001TwilightGrove
    set z.regions[1] = gg_rct_001TwilightGroveFull
    set z.questDescription = "This eerie forest is dominated by a colossal dead tree..."
    set z.questLevelReq = "3-8"
    set z.factions = "-"
    set z.notableEntities = "Wolf, Bear, Salamander"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone01_twilightgrove.blp"
    call RegisterZone(z)

    //========================
    // Dungeon 01: Gnoll Hideout
    //========================
    set z = ZoneData.create(101, "Gnoll Hideout")
    set z.environmentType = "Underground"
    set z.musicTrack = 4
    set z.dncName = "Underground"
    set z.isDungeon = true
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 6000.0
    set z.fogDay[2] = 0.0
    set z.fogDay[3] = 0.0
    set z.fogDay[4] = 6.0
    set z.fogNight[0] = 1000.0
    set z.fogNight[1] = 6000.0
    set z.fogNight[2] = 0.0
    set z.fogNight[3] = 0.0
    set z.fogNight[4] = 6.0
    set z.ambientDaySound = "gg_snd_Ambient_DungeonNormal"
    set z.ambientNightSound = "gg_snd_Ambient_DungeonNormal"
    set z.regions[0] = gg_rct_Dungeon01Area
    set z.questDescription = "A dark hideout infested with gnolls and other... beings."
    set z.questLevelReq = "5-12"
    set z.factions = "-"
    set z.notableEntities = "Gnoll, Undead"
    set z.notableCharacters = "Impaler, Deathlord Fel'Dok"
    set z.iconPath = "zones\\zone06_thornwoods.blp"
    call RegisterZone(z)

    //========================
    // Dungeon 05: Firelands
    //========================
    set z = ZoneData.create(105, "Firelands")
    set z.environmentType = "Volcano"
    set z.musicTrack = 9
    set z.dncName = "DarkPlace"
    set z.isDungeon = true
    set z.hasLeaveHandler = true
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 60.0
    set z.fogDay[3] = 20.0
    set z.fogDay[4] = 20.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 60.0
    set z.fogNight[3] = 20.0
    set z.fogNight[4] = 20.0
    set z.ambientDaySound = "gg_snd_Ambient_FirelandsDay"
    set z.ambientNightSound = "gg_snd_Ambient_FirelandsNight"
    set z.regions[0] = gg_rct_016Firelands
    set z.questDescription = "The volcanic region burns with fire and molten rivers."
    set z.questLevelReq = "12-20"
    set z.factions = "Fire Clan"
    set z.notableEntities = "Lava Elemental, Fire Drake"
    set z.notableCharacters = "Lord Magmus"
    set z.iconPath = "zones\\zone_firelands.blp"
    call RegisterZone(z)
endfunction

//===========================================================================
// Helpers
//===========================================================================
private function B2I takes boolean b returns integer
    if b then return 1 endif
    return 0
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

//===========================================================================
// Ambient Sounds
//===========================================================================
private function ClearAmbientSounds takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= 10
        if zoneAmbient[i] != null then
            call StopSound(zoneAmbient[i], false, true)
            set zoneAmbient[i] = null
        endif
        set i = i + 1
    endloop
    set zoneAmbientCount = 0
endfunction

private function AddAmbientSound takes string soundName, rect r returns nothing
    if soundName == "" then return endif
    local sound s
    local real x
    local real y
    if r != null then
        set x = (GetRectMinX(r) + GetRectMaxX(r)) * 0.5
        set y = (GetRectMinY(r) + GetRectMaxY(r)) * 0.5
    else
        set x = 0
        set y = 0
    endif
    set s = CreateSound(soundName, false, true, true, 10, 10, "")
    call SetSoundPosition(s, x, y, 0)
    call SetSoundDistanceCutoff(s, 5000)
    call StartSound(s)
    set zoneAmbient[zoneAmbientCount] = s
    set zoneAmbientCount = zoneAmbientCount + 1
endfunction

//===========================================================================
// Fog Application
//===========================================================================
private function ApplyFog takes ZoneData z, boolean isDay, player p returns nothing
    local real array fog[5]
    local integer i
    // For simplicity, just day/night; WeatherSystem pushes weatherState
    if z.weatherState == ZONE_WEATHER_HEAVY then
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherHeavy[i]
            set i = i + 1
        endloop
    elseif z.weatherState == ZONE_WEATHER_MEDIUM then
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherMedium[i]
            set i = i + 1
        endloop
    elseif z.weatherState == ZONE_WEATHER_LIGHT then
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherLight[i]
            set i = i + 1
        endloop
    elseif isDay then
        loop
            exitwhen i > 4
            set fog[i] = z.fogDay[i]
            set i = i + 1
        endloop
    else
        loop
            exitwhen i > 4
            set fog[i] = z.fogNight[i]
            set i = i + 1
        endloop
    endif
    call AddFogForPlayer(fog[0], fog[1], fog[2], fog[3], fog[4], p)
endfunction

//===========================================================================
// DNC
//===========================================================================
private function RunDNC takes string dncName returns nothing
    if dncName == "Outdoors" then call DNC_Outdoors()
    elseif dncName == "Underground" then call DNC_Underground()
    elseif dncName == "DarkPlace" then call DNC_DarkPlace()
    elseif dncName == "DarkerPlace" then call DNC_DarkerPlace()
    elseif dncName == "Outdoors Red" then call DNC_OutdoorsRed()
    elseif dncName == "Outdoors Dirty" then call DNC_OutdoorsDirty()
    elseif dncName == "Firelands" then call DNC_Firelands()
    endif
endfunction

//===========================================================================
// Zone Registration
//===========================================================================
private function RegisterZone takes ZoneData z returns nothing
    set zoneDatabase[z.zoneId] = z
    set zoneEnabled[z.zoneId] = true
endfunction

private function GetZoneData takes integer zoneId returns ZoneData
    return zoneDatabase[zoneId]
endfunction

//===========================================================================
// Quest Log
//===========================================================================
private function CreateQuestLog takes ZoneData z returns nothing
    local integer id = z.zoneId
    if zones[id] == 1 then return endif
    local string boxText
    set boxText = "|cffffcc00Description|r|n" + z.questDescription
    set boxText = boxText + "|n|n|cffffcc00Environment|r|n" + z.environmentType
    set boxText = boxText + "|n|n|cffffcc00Level|r|n" + z.questLevelReq
    set boxText = boxText + "|n|n|cffffcc00Factions|r|n" + z.factions
    set boxText = boxText + "|n|n|cffffcc00Notable Characters|r|n" + z.notableCharacters
    set boxText = boxText + "|n|n|cffffcc00Entities|r|n" + z.notableEntities
    call TasQuestBox_Add(z.name, boxText, z.iconPath)
    set zones[id] = 1
endfunction

//===========================================================================
// Zone Enter / Leave
//===========================================================================
private function HandleZoneEnter takes integer newZoneId, unit triggeringUnit returns nothing
    local ZoneData z = GetZoneData(newZoneId)
    if z == null then return endif
    set currentZone = newZoneId
    local player p = GetOwningPlayer(triggeringUnit)
    local boolean isDay = udg_DNE_IsDaytime

    // Titles
    if not zoneDiscovered[newZoneId] then
        set zoneDiscovered[newZoneId] = true
        call ShowRegionTitle(ZONE_DISCOVERED_PREFIX, z.name)
        if z.isDungeon then
            if DUNGEON_DISCOVER_SOUND != null then call StartSound(DUNGEON_DISCOVER_SOUND)
        else
            if ZONE_DISCOVER_SOUND != null then call StartSound(ZONE_DISCOVER_SOUND)
        endif
    else
        call ShowRegionTitle(ZONE_ENTERED_PREFIX, z.name)
        if z.isDungeon then
            if DUNGEON_ENTER_SOUND != null then call StartSound(DUNGEON_ENTER_SOUND)
        else
            if ZONE_ENTER_SOUND != null then call StartSound(ZONE_ENTER_SOUND)
        endif
    endif

    // Music
    call ExMusic_PlayTrack(z.musicTrack)

    // DNC
    call RunDNC(z.dncName)

    // Fog
    call ApplyFog(z, isDay, p)

    // Ambient
    call ClearAmbientSounds()
    if isDay and z.ambientDaySound != "" then call AddAmbientSound(z.ambientDaySound, null)
    if not isDay and z.ambientNightSound != "" then call AddAmbientSound(z.ambientNightSound, null)

    // Quest Log
    if not zoneDayNightEvent then call CreateQuestLog(z)

    // Special effects
    if z.setSkyClear then call SetSkyModel(null)
    if z.hasSpecialCamera then
        // Custom camera handling here
    endif

    set z_EnteringUnit = triggeringUnit
endfunction

private function HandleZoneLeaveCleanup takes integer zoneId, unit triggeringUnit returns nothing
    local ZoneData z = GetZoneData(zoneId)
    if z == null or not z.hasLeaveHandler then return endif
    // Add per-zone leave logic here
endfunction

//===========================================================================
// Public API
//===========================================================================
function Zones_ApplyCurrentZoneEffects takes nothing returns nothing
    if currentZone == 0 then return endif
    local ZoneData z = GetZoneData(currentZone)
    if z == null then return endif
    call HandleZoneEnter(currentZone, z_EnteringUnit)
endfunction

function Zones_GetCurrentZone takes nothing returns integer
    return currentZone
endfunction

function Zones_EnterZone takes integer zoneId, unit whichUnit returns nothing
    call HandleZoneEnter(zoneId, whichUnit)
endfunction

function Zones_TriggerLeaveCleanup takes integer zoneId, unit whichUnit returns nothing
    call HandleZoneLeaveCleanup(zoneId, whichUnit)
endfunction

function Zones_Enable takes boolean enable returns nothing
    set systemEnabled = enable
endfunction

function Zones_EnableZone takes integer zoneId, boolean enable returns nothing
    set zoneEnabled[zoneId] = enable
endfunction

function Zones_IsZoneEnabled takes integer zoneId returns boolean
    return zoneEnabled[zoneId]
endfunction

function Zones_SetZoneWeatherState takes integer zoneId, integer weather returns nothing
    local ZoneData z = GetZoneData(zoneId)
    if z == null then return endif
    set z.weatherState = weather
    // Apply fog immediately to players if needed
    if z_EnteringUnit != null then
        call ApplyFog(z, udg_DNE_IsDaytime, GetOwningPlayer(z_EnteringUnit))
    endif
endfunction

private function RegisterZoneRegions takes nothing returns nothing
    local integer i
    local integer j
    local trigger t
    local ZoneData z

    // Loop through all zones
    loop
        exitwhen i >= MAX_ZONES
        set z = zoneDatabase[i]
        if z != null then
            //========================
            // Register enter triggers
            //========================
            set j = 0
            loop
                exitwhen j >= z.regions.length
                if z.regions[j] != null then
                    set t = CreateTrigger()
                    call TriggerRegisterEnterRectSimple(t, z.regions[j])
                    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
                    set zoneTriggers[z.zoneId] = t
                    call triggerToZoneId.store(t, z.zoneId)
                endif
                set j = j + 1
            endloop

            //========================
            // Register leave triggers if cleanup required
            //========================
            if z.hasLeaveHandler then
                set j = 0
                loop
                    exitwhen j >= z.regions.length
                    if z.regions[j] != null then
                        set t = CreateTrigger()
                        call TriggerRegisterLeaveRectSimple(t, z.regions[j])
                        call TriggerAddCondition(t, Condition(function OnUnitLeaveRegion))
                        set zoneLeaveTriggers[z.zoneId] = t
                        call triggerToZoneId.store(t, z.zoneId)
                    endif
                    set j = j + 1
                endloop
            endif
        endif
        set i = i + 1
    endloop
endfunction

// Timer callback: update zone effects after Day/Night change
private function DayNight_UpdateZone takes nothing returns nothing
    call PauseTimer(dayNightUpdateTimer)

    if currentZone > 0 then
        call Zones_ApplyCurrentZoneEffects()
    endif
endfunction

// Timer callback: reset Day/Night event flag
private function DayNight_ResetFlag takes nothing returns nothing
    call PauseTimer(dayNightResetTimer)
    set zoneDayNightEvent = false

    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night event completed")
    endif
endfunction

// Triggered when Day/Night changes
private function OnDayNightEvent takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night event triggered")
    endif

    set zoneDayNightEvent = true

    // Create timers if null
    if dayNightUpdateTimer == null then
        set dayNightUpdateTimer = CreateTimer()
    endif
    if dayNightResetTimer == null then
        set dayNightResetTimer = CreateTimer()
    endif

    // Apply zone effects after a short delay
    call TimerStart(dayNightUpdateTimer, 1.00, false, function DayNight_UpdateZone)

    // Reset event flag after 3 seconds
    call TimerStart(dayNightResetTimer, 3.00, false, function DayNight_ResetFlag)
endfunction

// Call this in library Init() to register the Day/Night trigger
private function RegisterDayNightTrigger takes nothing returns nothing
    local trigger t
    set t = CreateTrigger()
    
    // Watch variable that tracks Day/Night (udg_DNE_DayNightEvent)
    call TriggerRegisterVariableEvent(t, "udg_DNE_DayNightEvent", EQUAL, 1.00)
    call TriggerRegisterVariableEvent(t, "udg_DNE_DayNightEvent", EQUAL, 2.00)
    
    call TriggerAddAction(t, function OnDayNightEvent)

    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night trigger registered")
    endif
endfunction

//===========================================================================
// Init
//===========================================================================
private function Init takes nothing returns nothing
    set triggerToZoneId = Table.create()
    set zoneDatabase = ZoneData.createArray(100)
    set zoneEnabled = boolean.createArray(100)
    set zoneDiscovered = boolean.createArray(100)
    set zones = integer.createArray(100)
endfunction

endlibrary
