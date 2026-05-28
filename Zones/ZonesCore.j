library ZonesCore initializer Init
//===========================================================================
/*
    ZonesCore Library
    
    Author: [Valdemar]
    Version: 1.0

    Description:
    This library provides core functionality for managing zones within the game.
    It defines shared constants, data structures, and initialization routines
    that can be utilized by other libraries such as Zones, WeatherSystem.
    
*/
//===========================================================================

//===========================================================================
// GLOBALS
//===========================================================================
globals

// Constants
    private constant boolean DEBUG = false               // Enable/disable debug messages
    private string array DEFAULT_WEATHER_TYPES

// Internal variables
    private integer currentZone = 0
    private integer array zoneDatabase
    private boolean array zoneEnabled
    private boolean array zoneDiscovered
    private boolean systemEnabled = true
    

endglobals

//===========================================================================
// Zone Data Structure
//===========================================================================
struct ZoneData

    // Basic info
    integer zoneId
    integer parentZoneId // Explicit parent zone link (0 = none)
    string name
    string environmentType // e.g., Forest, Desert, Dungeon, City, etc.

    // Music & atmosphere
    integer musicTrack
    string dncName  // DNC function to run ("Outdoors", "Underground", "DarkPlace", etc.)
    string weatherSeason  // Season for weather (e.g., "auto, spring", "summer", "autumn", "winter")

    // Fog settings
    real array fogDay[5] // start, end, r, g, b
    real array fogNight[5]
    real array fogWeatherLight[5]
    real array fogWeatherMedium[5]
    real array fogWeatherHeavy[5]

    // Ambient sounds (region names to add ambient to)
    string ambientDaySound  // Ambient sound name for day (empty = none)
    string ambientNightSound  // Ambient sound name for night (empty = none)
    string ambientRegion  // Region name to add ambient across

    // Special flags
    boolean playSoundOnEnter  // Play enter sound
    boolean hasSpecialCamera  // Has special camera setup (like Boom Mine)
    boolean setSkyClear  // Set sky to None/Clear
    boolean hasLeaveHandler  // Has leave event handler (for cleanup)
    boolean isDungeon

    // Quest log
    string questTitle
    string questDescription
    string questLevelReq
    string factions
    string notableEntities
    string notableCharacters
    string iconPath

    // Weather allowed for this zone (default TRUE)
    boolean weatherAllowed
    // For subzones: inherit weather from the parent/main zone (default TRUE)
    boolean weatherInheritFromParent
    // Weather types for this zone (array of strings)
    string array weatherTypes[10]
    integer weatherTypeCount

    // Weather feature toggles
    boolean weatherEnableThunder
    boolean weatherEnableClouds

    real array weatherTypeChance[10] // Chance for each weather type (0.0-1.0)

    // Snow weather rects for this zone (used by WeatherSystem)
    rect array weatherSnowRects[100] // Up to 100 snow weather rects per zone
    integer weatherSnowRectCount
    
    // Weather rects for this zone (used by WeatherSystem)
    rect array weatherRects[100] // Up to 100 weather rects per zone
    integer weatherRectCount

    // Gather-node spawn restriction rects
    rect array nodeItemRestrictRects[100]
    integer nodeItemRestrictRectCount
    rect array nodeUnitRestrictRects[100]
    integer nodeUnitRestrictRectCount
    rect array nodeWaterIgnoreRects[100]
    integer nodeWaterIgnoreRectCount

    // Current weather state for this zone
    string currentWeatherState

    // Moving units to different regions (zones) - OPTIONAL
    rect startRegion    // Region to where to move the unit when entering the zone
    rect moveRegion     // Region to where to issue movement order when entering the zone
    rect exitRegion     // Region where units are moved when leaving the zone (can be same as startRegion or different)
    rect outRegion      // Region to where to move the unit when exiting the zone
    rect moveOutRegion  // Region to where to issue movement order when exiting the zone

    // Enter/Leave regions for this zone
    rect array enterRegions[100] // Up to 100 enter regions (rect) per zone
    integer enterRegionCount
    rect array leaveRegions[100] // Up to 100 leave regions (rect) per zone
    integer leaveRegionCount

    // Add an enter region and increment count automatically
    method addEnterRegion takes rect r returns nothing
        if this.enterRegionCount < 100 then
            set this.enterRegions[this.enterRegionCount] = r
            set this.enterRegionCount = this.enterRegionCount + 1
        endif
    endmethod

    // Add a leave region and increment count automatically
    method addLeaveRegion takes rect r returns nothing
        if this.leaveRegionCount < 100 then
            set this.leaveRegions[this.leaveRegionCount] = r
            set this.leaveRegionCount = this.leaveRegionCount + 1
        endif
    endmethod

    method setParentZone takes integer zoneId returns nothing
        set this.parentZoneId = zoneId
    endmethod

    method getParentZoneId takes nothing returns integer
        return this.parentZoneId
    endmethod

    method hasParentZone takes nothing returns boolean
        return this.parentZoneId > 0
    endmethod

    // Add a weather rect and increment count automatically
    method addWeatherRect takes rect r returns nothing
        if this.weatherRectCount < 100 then
            set this.weatherRects[this.weatherRectCount] = r
            set this.weatherRectCount = this.weatherRectCount + 1
        endif
    endmethod

    method addNodeItemRestrictRect takes rect r returns nothing
        if this.nodeItemRestrictRectCount < 100 then
            set this.nodeItemRestrictRects[this.nodeItemRestrictRectCount] = r
            set this.nodeItemRestrictRectCount = this.nodeItemRestrictRectCount + 1
        endif
    endmethod

    method addNodeUnitRestrictRect takes rect r returns nothing
        if this.nodeUnitRestrictRectCount < 100 then
            set this.nodeUnitRestrictRects[this.nodeUnitRestrictRectCount] = r
            set this.nodeUnitRestrictRectCount = this.nodeUnitRestrictRectCount + 1
        endif
    endmethod

    method addNodeWaterIgnoreRect takes rect r returns nothing
        if this.nodeWaterIgnoreRectCount < 100 then
            set this.nodeWaterIgnoreRects[this.nodeWaterIgnoreRectCount] = r
            set this.nodeWaterIgnoreRectCount = this.nodeWaterIgnoreRectCount + 1
        endif
    endmethod

    // Returns the i-th weather rect for this zone
    method getWeatherRect takes integer i returns rect
        if i >= 0 and i < this.weatherRectCount then
            return this.weatherRects[i]
        endif
        return null
    endmethod

    // Add a snow weather rect and increment count automatically
    method addWeatherSnowRect takes rect r returns nothing
        if this.weatherSnowRectCount < 100 then
            set this.weatherSnowRects[this.weatherSnowRectCount] = r
            set this.weatherSnowRectCount = this.weatherSnowRectCount + 1
        endif
    endmethod

    // Returns the i-th snow weather rect for this zone
    method getWeatherSnowRect takes integer i returns rect
        if i >= 0 and i < this.weatherSnowRectCount then
            return this.weatherSnowRects[i]
        endif
        return null
    endmethod

    // Returns the main weather region for this zone
    method getMainWeatherRect takes nothing returns rect
        // Return the first weather rect if exists, else first enter region, else null
        if this.weatherRectCount > 0 then
            return this.weatherRects[0]
        elseif this.enterRegionCount > 0 then
            // If no explicit weather rects defined, promote first enter region to weather rect
            call this.addWeatherRect(this.enterRegions[0])
            if DEBUG then
                call BJDebugMsg("[Zones] getMainWeatherRect: promoted enterRegion[0] to weatherRect for zone: " + this.name)
            endif
            return this.weatherRects[0]
        endif
        return null
    endmethod

    // Returns weather types for this zone; defaults if none set
    method getWeatherType takes integer i returns string
        if this.weatherTypeCount > 0 and i < this.weatherTypeCount then
            return this.weatherTypes[i]
        endif
        // Fallback to default
        if i < 8 then
            set i = 8
            return DEFAULT_WEATHER_TYPES[i]
        endif
        return ""
    endmethod

    // Add a weather type string and increment count automatically
    method addWeatherType takes string s returns nothing
        if this.weatherTypeCount < 10 then
            set this.weatherTypes[this.weatherTypeCount] = s
            set this.weatherTypeCount = this.weatherTypeCount + 1
        endif
    endmethod

    // Set chance for a weather type by string
    method weatherChance takes string weatherType, real chance returns nothing
        local integer i = 0
        loop
            exitwhen i >= this.weatherTypeCount
            if this.weatherTypes[i] == weatherType then
                set this.weatherTypeChance[i] = chance
                return
            endif
            set i = i + 1
        endloop
    endmethod

    // Set the current weather state for this zone
    method SetWeatherState takes string weatherState returns nothing
        set this.currentWeatherState = weatherState
    endmethod

    // Get the current weather state for this zone
    method GetWeatherState takes nothing returns string
        return this.currentWeatherState
    endmethod

    // Returns a string listing all weather rects for this zone (for debugging)
    method listWeatherRects takes nothing returns string
        local string s = "WeatherRects for zone '" + this.name + "':\n"
        local integer i = 0
        local rect r
        loop
            exitwhen i >= this.weatherRectCount
            set r = this.weatherRects[i]
            if r != null then
                set s = s + "  [" + I2S(i) + "]: minX=" + R2S(GetRectMinX(r)) + ", minY=" + R2S(GetRectMinY(r)) + ", maxX=" + R2S(GetRectMaxX(r)) + ", maxY=" + R2S(GetRectMaxY(r)) + "\n"
            else
                set s = s + "  [" + I2S(i) + "]: null\n"
            endif
            set i = i + 1
        endloop
        return s
    endmethod

    // Returns a string listing all snow weather rects for this zone (for debugging)
    method listWeatherSnowRects takes nothing returns string
        local string s = "WeatherSnowRects for zone '" + this.name + "':\n"
        local integer i = 0
        local rect r
        loop
            exitwhen i >= this.weatherSnowRectCount
            set r = this.weatherSnowRects[i]
            if r != null then
                set s = s + "  [" + I2S(i) + "]: minX=" + R2S(GetRectMinX(r)) + ", minY=" + R2S(GetRectMinY(r)) + ", maxX=" + R2S(GetRectMaxX(r)) + ", maxY=" + R2S(GetRectMaxY(r)) + "\n"
            else
                set s = s + "  [" + I2S(i) + "]: null\n"
            endif
            set i = i + 1
        endloop
        return s
    endmethod

    static method create takes integer id, string zoneName returns thistype
    
        local thistype this = thistype.allocate()
        set this.zoneId = id
        set this.parentZoneId = 0
        set this.name = zoneName
        set this.environmentType = "Unknown" // Default value, set per zone
        // Default values
        set this.musicTrack = 0
        set this.dncName = "Outdoors"
        // Default fog (neutral gray)
        set this.fogDay[0] = 1000.0                 // Default fog values
        set this.fogDay[1] = 8000.0
        set this.fogDay[2] = 75.0
        set this.fogDay[3] = 75.0
        set this.fogDay[4] = 75.0
        set this.fogNight[0] = 3000.0
        set this.fogNight[1] = 15000.0
        set this.fogNight[2] = 15.0
        set this.fogNight[3] = 15.0
        set this.fogNight[4] = 50.0
        set this.fogWeatherLight[0] = 2000.0        // Default fog weather values
        set this.fogWeatherLight[1] = 12000.0
        set this.fogWeatherLight[2] = 60.0
        set this.fogWeatherLight[3] = 60.0
        set this.fogWeatherLight[4] = 70.0
        set this.fogWeatherMedium[0] = 1200.0
        set this.fogWeatherMedium[1] = 9000.0
        set this.fogWeatherMedium[2] = 40.0
        set this.fogWeatherMedium[3] = 40.0
        set this.fogWeatherMedium[4] = 60.0
        set this.fogWeatherHeavy[0] = 400.0
        set this.fogWeatherHeavy[1] = 2000.0
        set this.fogWeatherHeavy[2] = 20.0
        set this.fogWeatherHeavy[3] = 20.0
        set this.fogWeatherHeavy[4] = 40.0
        set this.ambientDaySound = ""
        set this.ambientNightSound = ""
        set this.ambientRegion = ""
        set this.playSoundOnEnter = true        // Default true
        set this.hasSpecialCamera = false       // Default false
        set this.setSkyClear = false            // Default false
        set this.hasLeaveHandler = false        // Default false
        set this.questTitle = "Zone: " + zoneName
        set this.questDescription = ""
        set this.questLevelReq = "|cFFFFCC00Level:|r |cFFFFFFFF??|r" // Placeholder, set per zone
        set this.factions = "Unknown"
        set this.notableEntities = "Unknown"
        set this.notableCharacters = "Unknown"
        set this.iconPath = "ReplaceableTextures\\CommandButtons\\BTNSunderingBlades.blp"
        set this.isDungeon = false              // Default false
        set this.enterRegionCount = 0
        set this.leaveRegionCount = 0
        set this.startRegion = null
        set this.moveRegion = null
        set this.exitRegion = null
        set this.outRegion = null
        set this.moveOutRegion = null
        set this.weatherRectCount = 0
        set this.weatherSnowRectCount = 0
        set this.nodeItemRestrictRectCount = 0
        set this.nodeUnitRestrictRectCount = 0
        set this.nodeWaterIgnoreRectCount = 0
        set this.weatherAllowed = true          // Default allowed
        set this.weatherInheritFromParent = true // Default inherit from parent for subzones
        set this.weatherTypeCount = 0
        set this.weatherEnableThunder = true    // Default enabled
        set this.weatherEnableClouds = true     // Default enabled
        set this.weatherSeason = "auto"         // Default season
        set this.currentWeatherState = "none"   // Default weather state   
        return this
    endmethod
endstruct

//===========================================================================
// Default Weather Types
//===========================================================================
private function DefaultWeather takes ZoneData z returns nothing
    // Define default weather types (default usage)
    call z.addWeatherType("rain_light")
    call z.addWeatherType("rain_medium")
    call z.addWeatherType("rain_heavy")
    call z.addWeatherType("snow_light")
    call z.addWeatherType("snow_medium")
    call z.addWeatherType("snow_heavy")
    call z.addWeatherType("storm")
    call z.addWeatherType("wind")

    // Define default chances for each weather type
    call z.weatherChance("rain_light", 0.5)
    call z.weatherChance("rain_medium", 0.3)
    call z.weatherChance("rain_heavy", 0.2)
    call z.weatherChance("snow_light", 0.5)
    call z.weatherChance("snow_medium", 0.3)
    call z.weatherChance("snow_heavy", 0.2)
    call z.weatherChance("storm", 0.1)
    call z.weatherChance("wind", 0.4)

endfunction

private function SetDryMountainWeather takes ZoneData z returns nothing
    call z.addWeatherType("wind")

    call z.weatherChance("wind", 0.60)
endfunction

//===========================================================================
// Zone Registration & Storage
//===========================================================================
private function RegisterZone takes ZoneData z returns nothing
    local rect mainR

    set zoneDatabase[z.zoneId] = z
    set zoneEnabled[z.zoneId] = true  // Zones enabled by default

    if z.parentZoneId == z.zoneId then
        set z.parentZoneId = 0
        if DEBUG then
            call BJDebugMsg("[Zones] Removed self-parent link for zone: " + I2S(z.zoneId) + ": " + z.name)
        endif
    endif

    // If no weather types defined, set to default types
    if z.weatherTypeCount == 0 then
        call DefaultWeather(z)
        if DEBUG then
            call BJDebugMsg("[Zones] Default weather set for:  " + I2S(z.zoneId) + ": " + z.name)
        endif
    endif

    if DEBUG then
        call BJDebugMsg("[Zones] Registered Zone " + I2S(z.zoneId) + ": " + z.name)
    endif
    
    // Ensure zone has at least one weather rect (promote enterRegion if needed)
    if z.weatherRectCount == 0 then
        call z.getMainWeatherRect()
    endif
    // Ensure zone has at least one snow weather rect; if none, promote main weather rect
    if z.weatherSnowRectCount == 0 then
        set mainR = z.getMainWeatherRect()
        if mainR != null then
            call z.addWeatherSnowRect(mainR)
            if DEBUG then
                call BJDebugMsg("[Zones] Promoted main weather rect to weatherSnowRect for zone: " + I2S(z.zoneId) + ": " + z.name)
            endif
        endif
    endif

    // Default weather state
    call z.SetWeatherState("none")

    // REGISTER COMPLETE

endfunction
//===========================================================================
// ZONE CONFIGURATION - EDIT THIS SECTION TO ADD/MODIFY ZONES
//===========================================================================
private function ConfigureZones takes nothing returns nothing
    local ZoneData z
    
    // Zone 01: Twilight Grove
    set z = ZoneData.create(1, "Twilight Grove")
    set z.musicTrack = 18
    set z.dncName = "Outdoors"
    set z.environmentType = "Ancient Forest" 
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
    set z.ambientDaySound = "gg_snd_Ambient_EnchantedForestDay"
    set z.ambientNightSound = "gg_snd_Ambient_ForestNight"
    set z.ambientRegion = "001TwilightGroveFull"
    set z.questDescription = "This eerie forest is dominated by a colossal dead tree, its twisted branches reaching out like skeletal fingers to the sky. Shadows dance among the gnarled roots, hinting at ancient secrets buried deep within the forest's heart."
    set z.questLevelReq = "3-8"
    set z.factions = "-"
    set z.notableEntities = "Wolf, Bear, Salamander"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone01_twilightgrove.blp"
    call z.addEnterRegion(gg_rct_001TwilightGrove)
    call z.addEnterRegion(gg_rct_001TwilightGroveFull)
    call z.addWeatherRect(gg_rct_001TwilightGroveFull)
    call z.addWeatherSnowRect(gg_rct_001TwilightGroveFull)
    call z.addWeatherType("rain_light")
    call z.addWeatherType("rain_medium")
    call z.addWeatherType("rain_heavy")
    call z.addWeatherType("snow_light") 
    call z.addWeatherType("snow_medium")
    call z.addWeatherType("snow_heavy")
    call z.weatherChance("rain_light", 0.95)
    call z.weatherChance("rain_medium", 0.3)
    call z.weatherChance("rain_heavy", 0.1)
    call z.weatherChance("snow_light", 0.5)
    call z.weatherChance("snow_medium", 0.3)
    call z.weatherChance("snow_heavy", 0.1)

    call RegisterZone(z)
    
    // Zone 02: Sereneglade
    set z = ZoneData.create(2, "Sereneglade")
    set z.musicTrack = 9
    set z.dncName = "Outdoors"
    set z.environmentType = "Forest"
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = "gg_snd_Ambient_ForestDay"
    set z.ambientNightSound = "gg_snd_Ambient_ForestNight"
    set z.ambientRegion = "02SereneGlade"
    set z.questDescription = "A tranquil forest expanse with a pristine lake at its heart, where nature thrives in harmony and the air is filled with a sense of peace and tranquility."
    set z.questLevelReq = "1-9"
    set z.factions = "Horde, Satyr, Gnolls"
    set z.notableEntities = "Kobold, Gnoll, Salamander, Wolf, Spider, Stag, Crab, Frenzy"
    set z.notableCharacters = "Outcast Jin'Zun, Ragno, Prince Zaekolaerr, Velaria"
    set z.iconPath = "zones\\zone02_sereneglade.blp"
    call z.addEnterRegion(gg_rct_02SereneGlade)
    call z.addWeatherRect(gg_rct_02SereneGlade)
    call z.addWeatherRect(gg_rct_02SereneGlade2)
    call z.addWeatherSnowRect(gg_rct_02SereneGladeSnow1)
    call z.addWeatherSnowRect(gg_rct_02SereneGladeSnow2)
    call z.addWeatherSnowRect(gg_rct_02SereneGladeSnow3)
    call z.addWeatherSnowRect(gg_rct_02SereneGladeSnow4)
    call z.addWeatherType("rain_light")
    call z.addWeatherType("rain_medium")
    call z.addWeatherType("rain_heavy")
    call z.addWeatherType("snow_light") 
    call z.addWeatherType("snow_medium")
    call z.addWeatherType("snow_heavy")
    call z.weatherChance("rain_light", 0.95)
    call z.weatherChance("rain_medium", 0.3)
    call z.weatherChance("rain_heavy", 0.1)
    call z.weatherChance("snow_light", 0.5)
    call z.weatherChance("snow_medium", 0.3)
    call z.weatherChance("snow_heavy", 0.1)
    call RegisterZone(z)
    
    // Zone 03: Emberpeak Highlands
    set z = ZoneData.create(3, "Emberpeak Highlands")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Mountains"
    set z.environmentType = "Burned Forest, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 15.0
    set z.fogDay[4] = 15.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 35.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Towering crags of ashen stone pierce the heavens, home to enigmatic stone golems and the fiery guardians of earth, their presence casting an ominous shadow over the desolate landscape."
    set z.questLevelReq = "10-15"
    set z.factions = "-"
    set z.notableEntities = "Dragon, Salamander, Golem, Fire Elemental"
    set z.notableCharacters = "Grum Bloodfang, Colossus, Mordrax the Desolator"
    set z.iconPath = "zones\\zone03_emberpeakhighlands.blp"
    call z.addEnterRegion(gg_rct_03EmberpeakHighlands) 
    call SetDryMountainWeather(z)
    call RegisterZone(z)
    
    // Zone 04: Dragonfire Peaks
    set z = ZoneData.create(4, "Dragonfire Peaks")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.environmentType = "Volcanic, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 5.0
    set z.fogDay[4] = 5.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 66.0
    set z.fogNight[3] = 6.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A treacherous mountainous terrain where fierce dragons reign supreme, their fiery breaths lighting up the sky as they clash with fire and earth elementals amidst the rocky crags."
    set z.questLevelReq = "20-30"
    set z.factions = "Horde, Dark Horde, Bonecrusher Clan, Dwarf Mining Consortium"
    set z.notableEntities = "Dragon, Salamander, Basilisk, Fire Elemental, Earth Elemental, Ogre, Dwarf"
    set z.notableCharacters = "Morgrok, Scorchion"
    set z.iconPath = "zones\\zone04_dragonfirepeaks.blp" 
    call z.addEnterRegion(gg_rct_04DragonfirePeaks)
    call SetDryMountainWeather(z)
    call RegisterZone(z)

    // Zone 0401: Ashfang Outpost
    set z = ZoneData.create(401, "Ashfang Outpost")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.environmentType = "Volcanic, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 5.0
    set z.fogDay[4] = 5.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 66.0
    set z.fogNight[3] = 6.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Orcish outpost in Dragonfire Peaks."
    set z.questLevelReq = "20-30"
    set z.factions = "Horde"
    set z.notableEntities = "Orc"
    set z.notableCharacters = "Morgrok the Shadowbinder"
    set z.iconPath = "zones\\zone04_dragonfirepeaks.blp"
    call z.setParentZone(4)
    call z.addEnterRegion(gg_rct_04AshfangOutpost)
    call SetDryMountainWeather(z)
    call RegisterZone(z)

    // Zone 0402: Skaldrath
    set z = ZoneData.create(402, "Skaldrath \"Wyrmfall\"")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.environmentType = "Volcanic, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 5.0
    set z.fogDay[4] = 5.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 66.0
    set z.fogNight[3] = 6.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Ancient dragon graveyard in Dragonfire Peaks."
    set z.questLevelReq = "20-30"
    set z.factions = "-"
    set z.notableEntities = "Dragon, Fire Elemental, Earth Elemental"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone04_dragonfirepeaks.blp"
    call z.setParentZone(4)
    call z.addEnterRegion(gg_rct_04Skaldrath)
    call SetDryMountainWeather(z)
    call RegisterZone(z)

    // Zone 0403: Morgrim's Claim
    set z = ZoneData.create(403, "Morgrim's Claim")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.environmentType = "Volcanic, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 5.0
    set z.fogDay[4] = 5.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 66.0
    set z.fogNight[3] = 6.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Dwarven mine claim in Dragonfire Peaks."
    set z.questLevelReq = "20-30"
    set z.factions = "Dwarf Mining Consortium"
    set z.notableEntities = "Dwarf"
    set z.notableCharacters = "Morgrim"
    set z.iconPath = "zones\\zone04_dragonfirepeaks.blp"
    call z.setParentZone(4)
    call z.addEnterRegion(gg_rct_04MorgrimsClaim)
    call SetDryMountainWeather(z)
    call RegisterZone(z)

    // Zone 0404: Maw of Cinders
    set z = ZoneData.create(404, "Maw of Cinders")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.environmentType = "Volcanic, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 5.0
    set z.fogDay[4] = 5.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 66.0
    set z.fogNight[3] = 6.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Entry to mysterious caverns and an ancient altar high atop the fiery peaks."
    set z.questLevelReq = "20-30"
    set z.factions = "Dark Horde"
    set z.notableEntities = "Orc, Basilisk, Dragon"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone04_dragonfirepeaks.blp"
    call z.setParentZone(4)
    call z.addEnterRegion(gg_rct_04MawOfCinders)
    call SetDryMountainWeather(z)
    call RegisterZone(z)

    // Zone 0405: Ashfang Falls
    set z = ZoneData.create(405, "Ashfang Falls")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.environmentType = "Volcanic, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 5.0
    set z.fogDay[4] = 5.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 66.0
    set z.fogNight[3] = 6.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A violent cascade of molten lava pouring from the fractured cliffs of an ancient volcanic ridge. The air around Ashfang Falls burns with ash and sulfur. Fire elementals and their leader Scorchion — a colossal elemental born from the heart of the mountain itself, dwell here."
    set z.questLevelReq = "20-30"
    set z.factions = "-"
    set z.notableEntities = "Fire Elemental"
    set z.notableCharacters = "Scorchion"
    set z.iconPath = "zones\\zone04_dragonfirepeaks.blp"
    call z.setParentZone(4)
    call z.addEnterRegion(gg_rct_04AshfangFalls)
    call SetDryMountainWeather(z)
    call RegisterZone(z)
    
    // Zone 06: Thornwoods
    set z = ZoneData.create(6, "Thornwoods")
    set z.musicTrack = 5
    set z.environmentType = "Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A peaceful forest teeming with life, yet fraught with danger as forest trolls, gnolls, and murlocs lurk among the verdant foliage, each vying for dominance over their domain."
    set z.questLevelReq = "1-10"
    set z.factions = "Horde, Gnolls, Bloodtusk Tribe, Murlocs"
    set z.notableEntities = "Wolf, Gnoll, Forest Troll, Murloc, Bear, Stag, Pig"
    set z.notableCharacters = "Chieftain Thork, Granis, Garthork, Krezgrel, Drek'thor, Rol'jin, Murgal, Grim, Goblin XXX"
    set z.iconPath = "zones\\zone06_thornwoods.blp"   
    call z.addEnterRegion(gg_rct_06Thornwoods)
    call RegisterZone(z)
    
    // Zone 0601: Stonetooth Camp
    set z = ZoneData.create(601, "Stonetooth Camp")
    set z.musicTrack = 72
    set z.environmentType = "Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A gnoll encampment in the Thornwoods."
    set z.questLevelReq = "1-10"
    set z.factions = "Gnolls"
    set z.notableEntities = "Gnoll"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone_stonetoothcamp.blp"   
    call z.setParentZone(6)
    call z.addEnterRegion(gg_rct_StonetoothCamp)
    call RegisterZone(z)
    
    // Zone 0602: Bloodtusk Tribe
    set z = ZoneData.create(602, "Bloodtusk Tribe")
    set z.musicTrack = 70
    set z.environmentType = "Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 15.0
    set z.fogDay[3] = 80.0
    set z.fogDay[4] = 15.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "The village of the Bloodtusk Tribe trolls."
    set z.questLevelReq = "1-10"
    set z.factions = "Bloodtusk Tribe"
    set z.notableEntities = "Forest Troll"
    set z.notableCharacters = "Rol'jin"
    set z.iconPath = "zones\\zone0602_bloodtusktribe.blp"    
    call z.setParentZone(6)
    call z.addEnterRegion(gg_rct_BloodtuskTribe) 
    call RegisterZone(z)
    
    // Zone 07: Havenwoods
    set z = ZoneData.create(7, "Havenwoods")
    set z.musicTrack = 81
    set z.environmentType = "Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A tranquil forest retreat where humans and murlocs coexist in surprising harmony, their simple settlements nestled amidst the towering trees, a beacon of peace in a troubled world."
    set z.questLevelReq = "5-15"
    set z.factions = "Alliance, Bonecrusher Clan, Murlocs"
    set z.notableEntities = "Forest Troll, Murloc, Ogre, Bear, Stag, Pig, Human"
    set z.notableCharacters = "Ogre Lord Mag'thok, Human XXX"
    set z.iconPath = "zones\\zone07_havenwoods.blp"
    call z.addEnterRegion(gg_rct_07Havenwoods)
    call RegisterZone(z)
    
    // Zone 08: Bonecrush Stronghold
    set z = ZoneData.create(8, "Bonecrush Stronghold")
    set z.musicTrack = 94
    set z.environmentType = "Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A formidable fortress carved into the rugged mountainside, where ogres reign supreme. Massive gates loom ominously over the surrounding landscape, daring any who would challenge the might of the ogre warlords to enter their domain."
    set z.questLevelReq = "10-15"
    set z.factions = "Bonecrusher Clan"
    set z.notableEntities = "Ogre"
    set z.notableCharacters = "Ogre Lord Mag'thok"
    set z.iconPath = "zones\\zone08_bonecrushstronghold.blp"
    call z.addEnterRegion(gg_rct_008BonecrushStrongHold) 
    call RegisterZone(z)
    
    // Zone 09: Vanguard Vale
    set z = ZoneData.create(9, "Vanguard Vale")
    set z.musicTrack = 78
    set z.environmentType = "Magical, Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "In this once elven-dominated territory, the air hums with the presence of wraiths and arcane magic, ever vigilant against the encroaching dangers that lurk beyond the borders of their domain."
    set z.questLevelReq = "10-20"
    set z.factions = "Elarindor"
    set z.notableEntities = "Elf, Wretched Elf, Mana Wraith, Lynx, Moth, Basilisk, Human"
    set z.notableCharacters = "Aradion The Farseer, Valeria, Lady Serenthia, Elf Mage XXX, Void Entity "
    set z.iconPath = "zones\\zone09_vanguardvale.blp"    
    call z.addEnterRegion(gg_rct_009VanguardVale)
    call RegisterZone(z)
    
    // Zone 10: Riverbane
    set z = ZoneData.create(10, "Riverbane")
    set z.musicTrack = 2
    set z.environmentType = "Riverine, Forest, Seaside"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Along the winding river, scattered settlements offer respite to weary travelers, but danger lurks in the shadows as bandits prowl the dense undergrowth."
    set z.questLevelReq = "8-12"
    set z.factions = "Riverbane Citizen, Bandits, Horde"
    set z.notableEntities = "Vulture, Crocolisk, Bandit, Human, Stag, Snake, Basilisk"
    set z.notableCharacters = "Bandit Leader XXX, Mysterious Wizard, Sarlacc, Turtles"
    set z.iconPath = "zones\\zone010_riverbane.blp"
    call z.addEnterRegion(gg_rct_010RiverBane)
    call RegisterZone(z)
    
    // Zone 11: Deadwoods
    set z = ZoneData.create(11, "Deadwoods")
    set z.musicTrack = 21
    set z.dncName = "Death1"
    set z.environmentType = "Haunted Forest"
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 0.0
    set z.fogDay[3] = 0.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 0.0
    set z.fogNight[3] = 0.0
    set z.fogNight[4] = 30.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A haunting forest where ethereal specters roam amidst the twisted trees, their mournful wails echoing through the mist-shrouded glades, alongside the resilient spirit of a small human settlement."
    set z.questLevelReq = "8-14"
    set z.factions = "-"
    set z.notableEntities = "Undead, Flesh Beast, Fel Boar, Diseased Stag"
    set z.notableCharacters = "Seralyth, Gar"
    set z.iconPath = "zones\\zone011_deadwoods.blp"  
    call z.addEnterRegion(gg_rct_011Deadwoods)
    call RegisterZone(z)
    
    // Zone 12: Felfire Bastion
    set z = ZoneData.create(12, "Felfire Bastion")
    set z.musicTrack = 93
    set z.environmentType = "Fel Imbused, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 15.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 15.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A dark forest tainted by the presence of fel orcs, their savage war cries echoing through the trees as they lay siege to any who dare to oppose them. At the heart of the stronghold, a towering fortress rises ominously against the blood-red sky, a beacon of despair in a land consumed by darkness."
    set z.questLevelReq = "12-15"
    set z.factions = "Dark Horde"
    set z.notableEntities = "Fel Orc, Fel Boar"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone012_felfirebastion.blp"   
    call z.setParentZone(12)
    call z.addEnterRegion(gg_rct_012FelfireBastion)     
    call RegisterZone(z)
    
    // Zone 1201: Felfire Citadel
    set z = ZoneData.create(1201, "Felfire Citadel")
    set z.musicTrack = 44
    set z.environmentType = "Fel Imbused, Mountainous"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 15.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 15.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "The heart of fel corruption."
    set z.questLevelReq = "12-15"
    set z.factions = "-"
    set z.notableEntities = "Fel Orc"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone01201_felfirecitadel.blp"  
    call z.addEnterRegion(gg_rct_012FelfireBastion)     
    call RegisterZone(z)
    
    // Zone 13: Stormhaven
    set z = ZoneData.create(13, "Stormhaven")
    set z.musicTrack = 51
    set z.environmentType = "Cityscape"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A human town, where the human denizens thrive amidst the comforting embrace of their quaint town, shielded from the chaos that lurks beyond its borders."
    set z.questLevelReq = "12-18"
    set z.factions = "Alliance XXX"
    set z.notableEntities = "Human"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone013_stormhaven.blp"    
    call z.addEnterRegion(gg_rct_013Stormhaven)
    call RegisterZone(z)
    
    // Zone 14: Sirensong
    set z = ZoneData.create(14, "Sirensong")
    set z.musicTrack = 7
    set z.environmentType = "Jungle, Seaside"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 55.0
    set z.fogDay[3] = 65.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Enveloped by the lush foliage of the jungle and the vast expanse of the ocean's embrace, this zone invites contemplation and exploration. Among the foliage, trolls and ogres carve out their territories with blood."
    set z.questLevelReq = "10-15"
    set z.factions = "Horde, Goblins"
    set z.notableEntities = "Tiger, Panther, Raptor, Turtle, Crab, Naga, Troll, Ogre, Crocolisk, Frenzy"
    set z.notableCharacters = "Boom Brothers, Blix, Golgar, Vorkatha"
    set z.iconPath = "zones\\zone014_sirensong.blp"    
    call z.addEnterRegion(gg_rct_014Sirensong)
    call RegisterZone(z)
    
    // Zone 1401: Moknatha
    set z = ZoneData.create(1401, "Mok'natha")
    set z.musicTrack = 71
    set z.environmentType = "Jungle, Seaside"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 55.0
    set z.fogDay[3] = 65.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Near the mighty ocean shoreline lies orc settlement of Mok'natha."
    set z.questLevelReq = "-"
    set z.factions = "Horde"
    set z.notableEntities = "-"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone014_sirensong.blp"   
    call z.setParentZone(14)
    call z.addEnterRegion(gg_rct_014Moknatha) 
    call RegisterZone(z)
    
    // Zone 1402: Zulgarok
    set z = ZoneData.create(1402, "Ruins of Zul'Garok")
    set z.musicTrack = 70
    set z.environmentType = "Jungle, Seaside, Ancient Ruins"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 55.0
    set z.fogDay[3] = 65.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Zul'Garok was a small temple settlement of the Sirensong trolls, destroyed by the mighty hydra demigod Jinvorrak, whom the trolls worship. The settlement is still occupied by the trolls to this day, as they desperately try to summon the hydra again."
    set z.questLevelReq = "10-15"
    set z.factions = "-"
    set z.notableEntities = "Jungle Trolls"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone014_sirensong.blp"   
    call z.setParentZone(14)
    call z.addEnterRegion(gg_rct_014Zulgarok)
    call RegisterZone(z)
    
    // Zone 1403: Urgmar
    set z = ZoneData.create(1403, "Urgmar")
    set z.musicTrack = 94
    set z.environmentType = "Jungle, Seaside"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 55.0
    set z.fogDay[3] = 65.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Ogre settlement by the river in Sirensong."
    set z.questLevelReq = "10-15"
    set z.factions = "-"
    set z.notableEntities = "Ogres"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone014_sirensong.blp"   
    call z.setParentZone(14)
    call z.addEnterRegion(gg_rct_014Urgmar)
    call RegisterZone(z)
    
    // Zone 1404: Serpentshore
    set z = ZoneData.create(1404, "Serpentshore")
    set z.musicTrack = 7
    set z.environmentType = "Jungle, Seaside"
    set z.fogDay[0] = 800.0
    set z.fogDay[1] = 7000.0
    set z.fogDay[2] = 55.0
    set z.fogDay[3] = 65.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 800.0
    set z.fogNight[1] = 9000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Naga serpent worshippers by the Sirensong sea shore."
    set z.questLevelReq = "10-15"
    set z.factions = "-"
    set z.notableEntities = "Naga"
    set z.notableCharacters = "Kelziss"
    set z.iconPath = "zones\\zone014_sirensong.blp"    
    call z.setParentZone(14)
    call z.addEnterRegion(gg_rct_014Serpentshore)
    call RegisterZone(z)
    
    // Zone 15: Zul'Gurak
    set z = ZoneData.create(15, "Zul'Gurak")
    set z.musicTrack = 3
    set z.environmentType = "Jungle, Ancient Ruins"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 55.0
    set z.fogDay[3] = 65.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Amidst the dense jungle foliage, ancient Gurak'jin Tribe trolls gather in worship of their primal gods, their rituals echoing through the verdant canopy as they pay homage to powers older than time itself."
    set z.questLevelReq = "15-20"
    set z.factions = "-"
    set z.notableEntities = "Jungle Troll"
    set z.notableCharacters = "Jinnvorrak"
    set z.iconPath = "zones\\zone015_zulgurak.blp"    
    call z.addEnterRegion(gg_rct_015ZulGurak1)
    call z.addEnterRegion(gg_rct_015ZulGurak2)
    call z.addEnterRegion(gg_rct_015ZulGurak3)
    call z.addEnterRegion(gg_rct_015ZulGurak4)
    call RegisterZone(z)
    
    // Zone 17: Verdant Plains
    set z = ZoneData.create(17, "Verdant Plains")
    set z.musicTrack = 11
    set z.environmentType = "Swamp, Forest, Mountainous"
    set z.fogDay[0] = 1800.0
    set z.fogDay[1] = 9500.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 85.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "XXX An expansive landscape of open fields and lush forests, dotted with small human settlements that thrive amidst the natural beauty of their surroundings."
    set z.questLevelReq = "15-20"
    set z.factions = "Satyr"
    set z.notableEntities = "Chimaera, Bog Beast, Faerie Dragon, Satyr"
    set z.notableCharacters = "Chimairo, Morthun"
    set z.iconPath = "zones\\zone017_verdantplains.blp"     
    call z.addEnterRegion(gg_rct_017VerdantPlains)
    call RegisterZone(z)
    
    // Zone 1701: Chimairos Roost
    set z = ZoneData.create(1701, "Chimairo's Roost")
    set z.musicTrack = 11
    set z.environmentType = "Swamp, Forest, Mountainous"
    set z.fogDay[0] = 1800.0
    set z.fogDay[1] = 9500.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 85.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Roost of the mighty chimera."
    set z.questLevelReq = "15-20"
    set z.factions = "-"
    set z.notableEntities = "Chimaera"
    set z.notableCharacters = "Chimairo"
    set z.iconPath = "zones\\zone017_verdantplains.blp"    
    call z.setParentZone(17)
    call z.addEnterRegion(gg_rct_017Chimaira)
    call RegisterZone(z)
    
    // Zone 1702: Weeping Hollow
    set z = ZoneData.create(1702, "The Weeping Hollow")
    set z.musicTrack = 46
    set z.environmentType = "Swamp, Forest, Mountainous"
    set z.fogDay[0] = 1800.0
    set z.fogDay[1] = 9500.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 85.0
    set z.fogDay[4] = 55.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Satyr encampment deep in the swamp of the Verdant Plains.Named after the constant dripping and crying of lost spirits or tormented flora."
    set z.questLevelReq = "15-20"
    set z.factions = "Satyr"
    set z.notableEntities = "Satyr"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone017_verdantplains.blp" 
    call z.setParentZone(17)
    call z.addEnterRegion(gg_rct_017WeepingHollow)
    call RegisterZone(z)
    
    // Zone 1703: Redwind Pass
    set z = ZoneData.create(1703, "Redwind Pass")
    set z.musicTrack = 74
    set z.environmentType = "Mountainous"
    set z.fogDay[0] = 1800.0
    set z.fogDay[1] = 9500.0
    set z.fogDay[2] = 85.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Mysterious, but beautiful high mountain pass to travel between the Verdan Plains and the Havenwoods."
    set z.questLevelReq = "15-20"
    set z.factions = "-"
    set z.notableEntities = "Bandit, Basilisk"
    set z.notableCharacters = "Zephyros the Tempest, Mountain Giant"
    set z.iconPath = "zones\\zone017_redwindpass.blp"
    call z.setParentZone(17)
    call z.addEnterRegion(gg_rct_017RedwindPass)
    call RegisterZone(z)
    
    // Zone 1704: xxxSettlement
    set z = ZoneData.create(1704, "xxxSettlement")
    set z.musicTrack = 74
    set z.environmentType = "Magical, Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A mysterious settlement."
    set z.questLevelReq = "10-20"
    set z.factions = "-"
    set z.notableEntities = "Wretched Elf, Mana Wraith"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone09_vanguardvale.blp" 
    call z.setParentZone(17)
    call z.addEnterRegion(gg_rct_017xxxSettlement)
    call RegisterZone(z)
    
    // Zone 1705: VaelAnorath
    set z = ZoneData.create(1705, "Vael'Anorath")
    set z.musicTrack = 74
    set z.environmentType = "Magical, Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A quiet elven refuge populated by the elven remnants of Elarindor."
    set z.questLevelReq = "10-20"
    set z.factions = "Elarindor"
    set z.notableEntities = "Elf"
    set z.notableCharacters = "Elf Mage XXX"
    set z.iconPath = "zones\\zone09_vanguardvale.blp"
    call z.setParentZone(17)
    call z.addEnterRegion(gg_rct_017VaelAnorath)
    call RegisterZone(z)
    
    // Zone 18: Coliseum of Ages
    set z = ZoneData.create(18, "Coliseum of Ages")
    set z.musicTrack = 10
    set z.environmentType = "Arena"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 75.0
    set z.fogDay[3] = 75.0
    set z.fogDay[4] = 75.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Within the crumbling ruins of this ancient arena, warriors clash in epic battles for glory and honor, their deeds echoing through the annals of history."
    set z.questLevelReq = "-"
    set z.factions = "-"
    set z.notableEntities = "-"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone_ashran.blp"
    call z.addEnterRegion(gg_rct_018ColiseumOfAges)
    call RegisterZone(z)
    
    // Zone 19: Ghostwalk Ridge
    set z = ZoneData.create(19, "Ghostwalk Ridge")
    set z.musicTrack = 62
    set z.environmentType = "Eerie Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 60.0
    set z.fogDay[3] = 80.0
    set z.fogDay[4] = 70.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Along the borderlands of the haunted Deadwoods, this treacherous realm harbors a coveted gold mine, where orcs maintain a tenuous outpost amidst the lingering spectres of the past."
    set z.questLevelReq = "5-10"
    set z.factions = "-"
    set z.notableEntities = "Diseased Stag, Undead, Spider"
    set z.notableCharacters = "Watcher XXX, Watcher YYY"
    set z.iconPath = "zones\\zone018_ghostwalkridge.blp"
    call z.addEnterRegion(gg_rct_019GhostwalkRidge)
    call RegisterZone(z)
    
    // Zone 1901: Ironspine Post
    set z = ZoneData.create(1901, "Ironspine Post")
    set z.musicTrack = 68
    set z.environmentType = "Eerie Forest"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 60.0
    set z.fogDay[3] = 80.0
    set z.fogDay[4] = 70.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "A fortified orcish outpost in hostile territory."
    set z.questLevelReq = "-"
    set z.factions = "Horde"
    set z.notableEntities = "-"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone018_ghostwalkridge.blp" 
    call z.setParentZone(19)
    call z.addEnterRegion(gg_rct_IronspinePost)
    call RegisterZone(z)
    
    // Zone 20: Dawnhold
    set z = ZoneData.create(20, "Dawnhold")
    set z.musicTrack = 47
    set z.environmentType = "Haunted Ruins"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 0.0
    set z.fogDay[3] = 0.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "Dawnhold, once mighty city of humans, destroyed by the fel orcs and left in ruins. Only a small harbour was left intact. Eerie sounds echo within the city's walls; is it desolace after all?"
    set z.questLevelReq = "15-18"
    set z.factions = "-"
    set z.notableEntities = "Undead"
    set z.notableCharacters = "Skeleton Mage XXX, Watcher XXX"
    set z.iconPath = "zones\\zone020_dawnhold.blp"
    call z.addEnterRegion(gg_rct_Dawnhold)
    call RegisterZone(z)
    
    // Zone 8810: Horde Scout Base
    set z = ZoneData.create(8810, "Horde Scout Base")
    set z.musicTrack = 0
    set z.environmentType = "Orcish settlement"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 60.0
    set z.fogDay[3] = 80.0
    set z.fogDay[4] = 70.0
    set z.fogNight[0] = 3000.0
    set z.fogNight[1] = 15000.0
    set z.fogNight[2] = 15.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 50.0
    set z.ambientDaySound = ""
    set z.ambientNightSound = ""
    set z.ambientRegion = ""
    set z.questDescription = "XXX"
    set z.questLevelReq = "-"
    set z.factions = "-"
    set z.notableEntities = "-"
    set z.notableCharacters = "-"
    set z.iconPath = "zones\\zone06_thornwoods.blp"  
    call z.addEnterRegion(gg_rct_HordeScoutBase)
    call RegisterZone(z)
    
    //=======================================================================
    // DUNGEONS
    //=======================================================================
    
    // Dungeon 01: Gnoll Hideout
    set z = ZoneData.create(101, "Gnoll Hideout")
    set z.musicTrack = 4
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false  
    set z.isDungeon = true
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.ambientDaySound = "gg_snd_Ambient_DungeonNormal"
    set z.ambientNightSound = "gg_snd_Ambient_DungeonNormal"
    set z.ambientRegion = "Dungeon01Area"
    set z.questDescription = "A dark hideout infested with gnolls and other... beings."
    set z.questLevelReq = "5-12"
    set z.factions = "-"
    set z.notableEntities = "Gnoll, Undead"
    set z.notableCharacters = "Impaler, Deathlord Fel'Dok"
    set z.iconPath = "zones\\zone06_thornwoods.blp"   
    call z.addEnterRegion(gg_rct_Dungeon01Area)
    call RegisterZone(z)

    // Dungeon 02: Crypt
    set z = ZoneData.create(102, "The Crypt")
    set z.musicTrack = 20
    set z.dncName = "DarkerPlace"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false  
    set z.isDungeon = true
    set z.setSkyClear = true
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 6000.0
    set z.fogDay[2] = 0.0
    set z.fogDay[3] = 60.0
    set z.fogDay[4] = 20.0
    set z.fogNight[0] = 1000.0
    set z.fogNight[1] = 6000.0
    set z.fogNight[2] = 0.0
    set z.fogNight[3] = 60.0
    set z.fogNight[4] = 20.0
    set z.ambientDaySound = "gg_snd_Ambient_DungeonCrypt3"
    set z.ambientNightSound = "gg_snd_Ambient_DungeonCrypt3"
    set z.ambientRegion = "DungeonCrypt"
    set z.questDescription = "An ancient crypt filled with undead."
    set z.questLevelReq = "8-20"
    set z.factions = "-"
    set z.notableEntities = "Undead, Rat, Cockroach"
    set z.notableCharacters = "Skullreaver, Rotspine, Bone Golem, Darkmaw the Soul Devourer, Marduk the Endbringer"
    set z.iconPath = "zones\\zone_crypt.blp"
    call z.addEnterRegion(gg_rct_DungeonCrypt01A)
    call z.addEnterRegion(gg_rct_DungeonCrypt01B)
    call z.addEnterRegion(gg_rct_DungeonCrypt01C)
    call RegisterZone(z)

    // Dungeon 03: Wyrmhold Sanctum
    set z = ZoneData.create(103, "Wyrmhold Sanctum")
    set z.musicTrack = 25
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false  
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 30.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 10.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 30.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 10.0
    set z.ambientDaySound = "gg_snd_Ambient_DungeonDragon"
    set z.ambientNightSound = "gg_snd_Ambient_DungeonDragon"
    set z.ambientRegion = "05WyrmholdSanctum"
    set z.questDescription = "Deep within this cavern, the dragon mother slumbers..."
    set z.questLevelReq = "20-25"
    set z.factions = "-"
    set z.notableEntities = "Dragon"
    set z.notableCharacters = "Dragon Mother Seretha"
    set z.iconPath = "zones\\zone_blackrock.blp" 
    call z.addEnterRegion(gg_rct_05WyrmholdSanctum)
    call RegisterZone(z)

    // Dungeon 04: Boom Mine
    set z = ZoneData.create(104, "Boom Mine")
    set z.musicTrack = 23
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false  
    set z.hasSpecialCamera = true
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 2000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 2000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.ambientDaySound = "gg_snd_Ambient_DungeonNormal"
    set z.ambientNightSound = "gg_snd_Ambient_DungeonNormal"
    set z.ambientRegion = "BoomBrothersMine"
    set z.questDescription = "XXX"
    set z.questLevelReq = "10-15"
    set z.factions = "Goblins"
    set z.notableEntities = "Goblin"
    set z.notableCharacters = "Mad Blix"
    set z.iconPath = "zones\\zone_boommine.blp"   
    call z.addEnterRegion(gg_rct_BoomBrothersMine)
    call RegisterZone(z)

    // Dungeon 05: Firelands
    set z = ZoneData.create(105, "Firelands")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Firelands"
    set z.environmentType = "Elemental Place"
    set z.weatherAllowed = false 
    set z.hasLeaveHandler = true  // Cleanup VolcanoLoop sound on leave
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 30.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 10.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 30.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 10.0
    set z.ambientDaySound = "gg_snd_Ambient_VolcanicDay"
    set z.ambientNightSound = "gg_snd_Ambient_VolcanicDay"
    set z.ambientRegion = "016Firelands"
    set z.questDescription = "One of the areas of elemental fire, eternally burning."
    set z.questLevelReq = "20-30"
    set z.factions = "-"
    set z.notableEntities = "Fire Elemental, Earth Elemental"
    set z.notableCharacters = "Ragnaros, Core Hound"
    set z.iconPath = "zones\\zone_firelands.blp"   
    call z.addEnterRegion(gg_rct_016Firelands)
    call z.addLeaveRegion(gg_rct_016Firelands)
    call RegisterZone(z)

    // Dungeon 06: Dreadforge (Felfire orcs)
    set z = ZoneData.create(106, "Dreadforge")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 30.0
    set z.fogDay[4] = 10.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 30.0
    set z.fogNight[4] = 10.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "-"
    set z.notableEntities = "Demon, Fel Orc"
    set z.notableCharacters = "Demon XXX"
    set z.iconPath = "zones\\zone_dreadforge.blp"   
    set z.startRegion = gg_rct_106DreadforgeA
    set z.moveRegion = gg_rct_106DreadforgeB
    set z.exitRegion = gg_rct_106DreadforgeExit
    set z.outRegion = gg_rct_106DreadforgeOut
    set z.moveOutRegion = gg_rct_106DreadforgeMoveOut

    call z.addEnterRegion(gg_rct_106Dreadforge)
    call RegisterZone(z)

    //=======================================================================
    // Interior / caves
    //=======================================================================

    // Interior: Inn - RiverbaneInn
    set z = ZoneData.create(12010, "Riverbane Inn")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Interior"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 50.0
    set z.fogNight[3] = 50.0
    set z.fogNight[4] = 50.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "Riverbane Citizen, Bandits"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone_inn.blp"   
    set z.startRegion = gg_rct_InteriorInnTransit
    set z.moveRegion = gg_rct_InteriorInnEnter
    set z.exitRegion = gg_rct_InteriorInnExitFinal
    set z.outRegion = gg_rct_InnRiverbaneOut
    set z.moveOutRegion = gg_rct_InnRiverbaneMoveOut
    //
    // cellar handling/Setting ----- In region/ Out region
    //
    call z.addEnterRegion(gg_rct_InnRiverbane)
    call RegisterZone(z)

    /* 
    // Interior: Cellar - RiverbaneCellar
    set z = ZoneData.create(12011, "Riverbane Cellar") 
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Interior"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 50.0
    set z.fogNight[3] = 50.0
    set z.fogNight[4] = 50.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "Riverbane Citizen, Bandits"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone_inn.blp"   

    set z.startRegion = gg_rct_InteriorCellarXXX
    set z.moveRegion = gg_rct_InteriorCellarXXX
    set z.exitRegion = gg_rct_InteriorCellarXXX
    set z.outRegion = gg_rct_InteriorCellarXXX
    set z.moveOutRegion = gg_rct_InnHavenwoodsMoveOut

    call z.addEnterRegion(gg_rct_CellarRiverbane)
    call RegisterZone(z)
    */ 

    // Interior: Inn - HavenwoodsInn
    set z = ZoneData.create(12020, "Havenwoods Inn")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Interior"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 50.0
    set z.fogNight[3] = 50.0
    set z.fogNight[4] = 50.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone_inn.blp"     
    set z.startRegion = gg_rct_InteriorInnTransit
    set z.moveRegion = gg_rct_InteriorInnEnter
    set z.exitRegion = gg_rct_InteriorInnExitFinal
    set z.outRegion = gg_rct_InnHavenwoodsOut
    set z.moveOutRegion = gg_rct_InnHavenwoodsMoveOut
    //
    // cellar handling/Setting ----- In region/ Out region
    //
    call z.addEnterRegion(gg_rct_InnHavenwoods)
    call RegisterZone(z)

    /*
    // Interior: Cellar - HavenwoodsCellar
    set z = ZoneData.create(12021, "Havenwoods Cellar")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Interior"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 50.0
    set z.fogNight[3] = 50.0
    set z.fogNight[4] = 50.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone_inn.blp"     
    call z.addEnterRegion(gg_rct_CellarHavenwoods)
    call RegisterZone(z)
    */ 

    // Interior: Inn - StormhavenInn
    set z = ZoneData.create(12030, "Stormhaven Inn")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Interior"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 50.0
    set z.fogNight[3] = 50.0
    set z.fogNight[4] = 50.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone_inn.blp"     
     set z.startRegion = gg_rct_InteriorInnTransit
    set z.moveRegion = gg_rct_InteriorInnEnter
    set z.exitRegion = gg_rct_InteriorInnExitFinal
    set z.outRegion = gg_rct_InnStormhavenOut
    set z.moveOutRegion = gg_rct_InnStormhavenMoveOut
    //
    // cellar handling/Setting ----- In region/ Out region
    //
    call z.addEnterRegion(gg_rct_InnStormhaven)
    call RegisterZone(z)

    /* 
    // Interior: Cellar - StormhavenCellar
    set z = ZoneData.create(12031, "Stormhaven Cellar")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Interior"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 5000.0
    set z.fogDay[2] = 50.0
    set z.fogDay[3] = 50.0
    set z.fogDay[4] = 50.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 5000.0
    set z.fogNight[2] = 50.0
    set z.fogNight[3] = 50.0
    set z.fogNight[4] = 50.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "zones\\zone_inn.blp"     
    call z.addEnterRegion(gg_rct_CellarStormhaven)
    call RegisterZone(z)
    */

    // Interior: Cinderfall (Emberpeak Highlands)
    // cave type: Cave04
    set z = ZoneData.create(12110, "Cinderfall")
    set z.musicTrack = 23
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 2000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 2000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "SHOCKWAVEWATER1.BLP"  
    set z.startRegion = gg_rct_Cave04A
    set z.moveRegion = gg_rct_Cave04B
    set z.exitRegion = gg_rct_Cave04Exit
    set z.outRegion = gg_rct_CaveCinderfallOut
    set z.moveOutRegion = gg_rct_CaveCinderfallMoveOut
    call z.setParentZone(3)
    call z.addEnterRegion(gg_rct_CaveCinderfall)
    call RegisterZone(z)

    // Interior: Wolf Den (Sereneglade)
    // cave type: Cave06
    set z = ZoneData.create(12111, "Wolf Den")
    set z.musicTrack = 24
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 2000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 2000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "SHOCKWAVEWATER1.BLP"     
    set z.startRegion = gg_rct_Cave06A
    set z.moveRegion = gg_rct_Cave06B
    set z.exitRegion = gg_rct_Cave06Exit
    set z.outRegion = gg_rct_CaveWolfDenOut
    set z.moveOutRegion = gg_rct_CaveWolfDenMoveOut
    call z.setParentZone(2)
    call z.addEnterRegion(gg_rct_CaveWolfDen)
    call RegisterZone(z)

    // Interior: Shadowmaw Cave (Sirensong,Mal'kiri panther)
    // cave type: Cave06
    set z = ZoneData.create(12112, "Shadowmaw Cave")
    set z.musicTrack = 25
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 2000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 2000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "SHOCKWAVEWATER1.BLP"     
    set z.startRegion = gg_rct_Cave06A
    set z.moveRegion = gg_rct_Cave06B
    set z.exitRegion = gg_rct_Cave06Exit
    set z.outRegion = gg_rct_CaveShadowmawOut
    set z.moveOutRegion = gg_rct_CaveShadowmawMoveOut
    call z.setParentZone(14)
    call z.addEnterRegion(gg_rct_CaveShadowmaw)
    call RegisterZone(z)

    // Interior: Kobold Mine (Sereneglade)
    // cave type: Dragoncave01
    set z = ZoneData.create(12113, "Kobold Mine")
    set z.musicTrack = 25
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 2000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 2000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "SHOCKWAVEWATER1.BLP"     
    set z.startRegion = gg_rct_DragonCave01A
    set z.moveRegion = gg_rct_DragonCave01B
    set z.exitRegion = gg_rct_DragonCave01Exit
    set z.outRegion = gg_rct_CaveKoboldMineOut
    set z.moveOutRegion = gg_rct_CaveKoboldMineMoveOut
    call z.setParentZone(2)
    call z.addEnterRegion(gg_rct_CaveKoboldMine)
    call RegisterZone(z)

    // Interior: Blazehollow (in Dragonfire Peaks)
    // cave type: boreanmagnataurmicro
    set z = ZoneData.create(12114, "Blazehollow")
    set z.musicTrack = 23
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
    set z.weatherAllowed = false 
    set z.fogDay[0] = 500.0
    set z.fogDay[1] = 2000.0
    set z.fogDay[2] = 10.0
    set z.fogDay[3] = 10.0
    set z.fogDay[4] = 30.0
    set z.fogNight[0] = 500.0
    set z.fogNight[1] = 2000.0
    set z.fogNight[2] = 10.0
    set z.fogNight[3] = 10.0
    set z.fogNight[4] = 30.0
    set z.questDescription = "XXX"
    set z.questLevelReq = "XX-XX"
    set z.factions = "XXX"
    set z.notableEntities = "XXX"
    set z.notableCharacters = "XXX"
    set z.iconPath = "SHOCKWAVEWATER1.BLP"     
    set z.startRegion = gg_rct_MagnaCaveA
    set z.moveRegion = gg_rct_MagnaCaveB
    set z.exitRegion = gg_rct_MagnaCaveExit
    set z.outRegion = gg_rct_CaveBlazehollowOut
    set z.moveOutRegion = gg_rct_CaveBlazehollowMoveOut
    call z.setParentZone(4)
    call z.addEnterRegion(gg_rct_CaveBlazehollow)
    call RegisterZone(z)

endfunction

//=======================================================================
// STATES AND HELPERS
//=======================================================================
public function GetZoneData takes integer zoneId returns ZoneData
    return zoneDatabase[zoneId]
endfunction

public function GetParentZoneId takes integer zoneId returns integer
    local ZoneData z = GetZoneData(zoneId)

    if z != 0 then
        return z.getParentZoneId()
    endif

    return 0
endfunction

public function GetParentZoneData takes integer zoneId returns ZoneData
    return GetZoneData(GetParentZoneId(zoneId))
endfunction

public function HasParentZone takes integer zoneId returns boolean
    return GetParentZoneId(zoneId) > 0
endfunction

public function IsChildZoneOf takes integer zoneId, integer parentZoneId returns boolean
    return GetParentZoneId(zoneId) == parentZoneId
endfunction

// Returns the zone id for a given zone name, or 0 if not found
public function GetZoneIdByName takes string zoneName returns integer
    local integer i = 0
    local ZoneData z
    call BJDebugMsg("[ZonesCore] GetZoneIdByName: searching for '" + zoneName + "'")
    // Zone IDs can be sparse (1,2,6,601, ...). Don't stop at first null.
    // Iterate up to a reasonable upper bound and check non-null entries.
    loop
        exitwhen i > 9000
        set z = zoneDatabase[i]
        if z != 0 then
            call BJDebugMsg("[ZonesCore] GetZoneIdByName: index=" + I2S(i) + ", z.name='" + z.name + "'")
            if z.name == zoneName then
                call BJDebugMsg("[ZonesCore] GetZoneIdByName: match found at index " + I2S(i) + ", zoneId=" + I2S(z.zoneId))
                return z.zoneId
            endif
        endif
        set i = i + 1
    endloop
    call BJDebugMsg("[ZonesCore] GetZoneIdByName: no match found for '" + zoneName + "'")
    return 0
endfunction

public function Zones_GetZoneName takes integer zoneId returns string
    local ZoneData z = GetZoneData(zoneId)
    if z != 0 then
        return z.name
    endif
    return "Unknown Zone"
endfunction

public function IsZoneEnabled takes integer zoneId returns boolean
    local ZoneData z = GetZoneData(zoneId)
    return zoneEnabled[zoneId]
endfunction

public function Enable takes boolean enable returns nothing
    set systemEnabled = enable
    if DEBUG then
        if enable then
            call BJDebugMsg("[ZonesCore] System enabled")
        else
            call BJDebugMsg("[ZonesCore] System disabled")
        endif
    endif
endfunction

public function EnableZone takes integer zoneId, boolean enable returns nothing
    set zoneEnabled[zoneId] = enable
    
    if DEBUG then
        if enable then
            call BJDebugMsg("[ZonesCore] Zone " + I2S(zoneId) + " enabled")
        else
            call BJDebugMsg("[ZonesCore] Zone " + I2S(zoneId) + " disabled")
        endif
    endif
endfunction

public function SetZoneSilent takes integer zoneId returns nothing
    // Set current zone without triggering any effects (useful for teleportation)
    set currentZone = zoneId
    if DEBUG then
        call BJDebugMsg("[ZonesCore] Current zone set to: " + I2S(zoneId) + " (silent)")
    endif
endfunction

public function ResetZone takes nothing returns nothing
    // Clear current zone (for scenarios where player is teleporting out of all zones)
    set currentZone = 0
    if DEBUG then
        call BJDebugMsg("[ZonesCore] Current zone cleared")
    endif
endfunction

public function GetCurrentZone takes nothing returns integer
    return currentZone
endfunction

public function SetCurrentZone takes integer zoneId returns nothing
    set currentZone = zoneId
endfunction

// Debug helper: Print all data for zone with id 1
public function DebugPrintZone1Data takes nothing returns nothing
    local ZoneData z = zoneDatabase[1]
    local integer i
    call BJDebugMsg("--- ZoneData Debug (id=1) ---")
    call BJDebugMsg("zoneId: " + I2S(z.zoneId))
    call BJDebugMsg("name: " + z.name)
    call BJDebugMsg("environmentType: " + z.environmentType)
    call BJDebugMsg("musicTrack: " + I2S(z.musicTrack))
    call BJDebugMsg("dncName: " + z.dncName)
    call BJDebugMsg("weatherSeason: " + z.weatherSeason)
    if z.weatherAllowed then
        call BJDebugMsg("weatherAllowed: true")
    else
        call BJDebugMsg("weatherAllowed: false")
    endif
    call BJDebugMsg("weatherTypeCount: " + I2S(z.weatherTypeCount))
    set i = 0
    loop
        exitwhen i >= z.weatherTypeCount
        call BJDebugMsg("weatherTypes[" + I2S(i) + "]: " + z.weatherTypes[i] + ", chance: " + R2S(z.weatherTypeChance[i]))
        set i = i + 1
    endloop
    call BJDebugMsg("ambientDaySound: " + z.ambientDaySound)
    call BJDebugMsg("ambientNightSound: " + z.ambientNightSound)
    call BJDebugMsg("ambientRegion: " + z.ambientRegion)
    if z.playSoundOnEnter then
        call BJDebugMsg("playSoundOnEnter: true")
    else
        call BJDebugMsg("playSoundOnEnter: false")
    endif
    if z.hasSpecialCamera then
        call BJDebugMsg("hasSpecialCamera: true")
    else
        call BJDebugMsg("hasSpecialCamera: false")
    endif
    if z.setSkyClear then
        call BJDebugMsg("setSkyClear: true")
    else
        call BJDebugMsg("setSkyClear: false")
    endif
    if z.hasLeaveHandler then
        call BJDebugMsg("hasLeaveHandler: true")
    else
        call BJDebugMsg("hasLeaveHandler: false")
    endif
    if z.isDungeon then
        call BJDebugMsg("isDungeon: true")
    else
        call BJDebugMsg("isDungeon: false")
    endif
    call BJDebugMsg("questTitle: " + z.questTitle)
    call BJDebugMsg("questDescription: " + z.questDescription)
    call BJDebugMsg("questLevelReq: " + z.questLevelReq)
    call BJDebugMsg("factions: " + z.factions)
    call BJDebugMsg("notableEntities: " + z.notableEntities)
    call BJDebugMsg("notableCharacters: " + z.notableCharacters)
    call BJDebugMsg("iconPath: " + z.iconPath)
    // Print fogDay
    set i = 0
    loop
        exitwhen i >= 5
        call BJDebugMsg("fogDay[" + I2S(i) + "]: " + R2S(z.fogDay[i]))
        set i = i + 1
    endloop
    // Print fogNight
    set i = 0
    loop
        exitwhen i >= 5
        call BJDebugMsg("fogNight[" + I2S(i) + "]: " + R2S(z.fogNight[i]))
        set i = i + 1
    endloop
    // Print enterRegions
    call BJDebugMsg("enterRegionCount: " + I2S(z.enterRegionCount))
    call BJDebugMsg("-----------------------------")
endfunction

 //=======================================================================
// INIT
//=======================================================================
private function Init takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("[ZonesCore] Initializing zones core components...")
    endif

    call ConfigureZones() 

endfunction

endlibrary
