library Zones initializer Init requires Table, DNC, ExMusic, WeatherSystem
//===========================================================================
/*
    Zones System - Dynamic Zone Management
    
    Author: [Valdemar]
    Version: 1.0
    
    Handles all zone transitions including:
    - Music changes (ExMusic integration)
    - Day/Night cycle triggers (DNC)
    - Fog settings (day/night variants)
    - Ambient sounds (day/night variants)
    - Weather system integration
    - Quest log discovery system
    - Multiple regions per zone
    - Special fog effects (multi-layer)
    - Per-zone special features
    
    API:
        Zones_GetCurrentZone() - Get current zone ID
        Zones_ForceUpdate(unit) - Manually trigger zone update for a unit
        Zones_Enable(enable) - Enable/disable entire zone system
        Zones_EnableZone(zoneId, enable) - Enable/disable specific zone trigger
        Zones_IsZoneEnabled(zoneId) - Check if zone is enabled
        Zones_GetZoneName(zoneId) - Get zone name by ID
        Zones_EnterZone(zoneId, unit) - Manually trigger zone entry for a unit
        Zones_SetZoneSilent(zoneId) - Set current zone without triggering effects
        Zones_ResetZone() - Clear current zone (for teleport scenarios)
        Zones_TriggerLeaveCleanup(zoneId, unit) - Manually trigger zone leave cleanup
        Zones_EnableLeaveHandler(zoneId, enable) - Enable/disable leave trigger for a zone

    API Usage examples; 
        // Disable Zone 11 (Deadwoods) entry events
        call Zones_EnableZone(11, false)

        // Re-enable it later
        call Zones_EnableZone(11, true)

        // Check if a zone is enabled before teleporting
        if Zones_IsZoneEnabled(18) then
            call Zones_EnterZone(18, udg_PlayerHero)
        endif

        // Teleport player to a special zone without triggering effects
        call Zones_SetZoneSilent(3)  // Set to Wyrmhold Sanctum silently
        call SetUnitPosition(hero, x, y)
        call Zones_EnterZone(3, hero)  // Now trigger the full entry effects

        // Get zone name for display
        call BJDebugMsg("Current zone: " + Zones_GetZoneName(Zones_GetCurrentZone()))
        
        // Manually trigger leave cleanup when teleporting out of a zone
        if Zones_GetCurrentZone() == 5 then  // Firelands
            call Zones_TriggerLeaveCleanup(5, hero)  // Clean up before teleport
        endif
        call Zones_ResetZone()  // Clear current zone
        // Now teleport unit...
    
    Adding New Zones:
        1. Go to ZONE CONFIGURATION section below
        2. Copy an existing zone configuration block
        3. Fill in the values (zoneId, name, music, fog, etc.)
        4. Add region(s) in initialization section
        5. Done!
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
    private constant boolean DEBUG = true               // Enable/disable debug messages
    private constant integer MAX_ZONES = 10000          // Support up to zone ID 10000
    private constant integer MAX_AMBIENT_SOUNDS = 10    // Max ambient sounds per zone
    
    // Unit types to exclude from zone detection (easy to extend - just add more!)
    private constant integer MAX_EXCLUDED_UNIT_TYPES = 10
    private integer array excludedUnitTypes
    private integer excludedUnitTypeCount = 0
    
    //
    // SYSTEM VARIABLES (DO NOT MODIFY)
    //===========================================================================
    private integer currentZone = 0
    private boolean systemEnabled = true
    private boolean zoneDayNightEvent = false           // Set to true when triggered by day/night cycle
    private sound array zoneAmbient[MAX_AMBIENT_SOUNDS] // Ambient sound handles
    private integer zoneAmbientCount = 0
    private trigger array zoneTriggers                  // Trigger handles for each zone
    private trigger array zoneLeaveTriggers             // Trigger handles for zone leave events
    private Table triggerToZoneId                       // Table mapping triggers to zoneIds
    private boolean array zoneEnabled                   // Enable/disable specific zones
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
    
    private player array fog_Player
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
// Zone Data Structure
//===========================================================================
struct ZoneData
    // Basic info
    integer zoneId
    string name
    string environmentType // e.g., Forest, Desert, Dungeon, City, etc.
    
    // Music & atmosphere
    integer musicTrack
    string dncName  // DNC function to run ("Outdoors", "Underground", "DarkPlace", etc.)
    string weatherZoneName  // Weather system zone name (empty string = no weather)

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
    
    static method create takes integer id, string zoneName returns thistype
        local thistype this = thistype.allocate()
        set .zoneId = id
        set .name = zoneName
        set .environmentType = "Unknown" // Default value, set per zone
        // Default values
        set .musicTrack = 0
        set .dncName = "Outdoors"
        set .weatherZoneName = ""
        // Default fog (neutral gray)
        set .fogDay[0] = 1000.0
        set .fogDay[1] = 8000.0
        set .fogDay[2] = 75.0
        set .fogDay[3] = 75.0
        set .fogDay[4] = 75.0
        set .fogNight[0] = 3000.0
        set .fogNight[1] = 15000.0
        set .fogNight[2] = 15.0
        set .fogNight[3] = 15.0
        set .fogNight[4] = 50.0
        set .fogWeatherLight[0] = 2000.0
        set .fogWeatherLight[1] = 12000.0
        set .fogWeatherLight[2] = 60.0
        set .fogWeatherLight[3] = 60.0
        set .fogWeatherLight[4] = 70.0
        set .fogWeatherMedium[0] = 1200.0
        set .fogWeatherMedium[1] = 9000.0
        set .fogWeatherMedium[2] = 40.0
        set .fogWeatherMedium[3] = 40.0
        set .fogWeatherMedium[4] = 60.0
        set .fogWeatherHeavy[0] = 600.0
        set .fogWeatherHeavy[1] = 5000.0
        set .fogWeatherHeavy[2] = 20.0
        set .fogWeatherHeavy[3] = 20.0
        set .fogWeatherHeavy[4] = 40.0
        set .ambientDaySound = ""
        set .ambientNightSound = ""
        set .ambientRegion = ""
        set .playSoundOnEnter = true
        set .hasSpecialCamera = false
        set .setSkyClear = false
        set .hasLeaveHandler = false
        set .questTitle = "Zone: " + zoneName
        set .questDescription = ""
        set .questLevelReq = "|cFFFFCC00Level:|r |cFFFFFFFF??|r" // Placeholder, set per zone
        set .factions = "Unknown"
        set .notableEntities = "Unknown"
        set .notableCharacters = "Unknown"
        set .iconPath = "ReplaceableTextures\\CommandButtons\\BTNSunderingBlades.blp"
        set .isDungeon = false
        return this
    endmethod
endstruct

// Helper: Boolean to Integer
function B2I takes boolean b returns integer
    if b then
        return 1
    endif
    return 0
endfunction

//===========================================================================
// Zone Registration & Storage
//===========================================================================

private function RegisterZone takes ZoneData z returns nothing
    set zoneDatabase[z.zoneId] = z
    set zoneEnabled[z.zoneId] = true  // Zones enabled by default
    if DEBUG then
        call BJDebugMsg("[Zones] Registered Zone " + I2S(z.zoneId) + ": " + z.name)
    endif
endfunction



private function GetZoneData takes integer zoneId returns ZoneData
    return zoneDatabase[zoneId]
endfunction



//===========================================================================
// ZONE CONFIGURATION HELPER - EXAMPLE USAGE
/*

// Just copy this template in ConfigureZones()
set z = ZoneData.create(999, "New Zone Name")
set z.musicTrack = 42
set z.fogRDay = 75.0
// ... set other properties
call RegisterZone(z)

*/  
//===========================================================================

//===========================================================================
// ZONE CONFIGURATION - EDIT THIS SECTION TO ADD/MODIFY ZONES
//===========================================================================

private function ConfigureZones takes nothing returns nothing
    local ZoneData z
    
    // Zone 01: Twilight Grove
    set z = ZoneData.create(1, "Twilight Grove")
    set z.musicTrack = 18
    set z.dncName = "Outdoors"
    set z.weatherZoneName = "TwilightGrove"
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
    call RegisterZone(z)
    
    // Zone 02: Sereneglade
    set z = ZoneData.create(2, "Sereneglade")
    set z.musicTrack = 9
    set z.dncName = "Outdoors"
    set z.weatherZoneName = "Serenaglade"
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
    call RegisterZone(z)
    
    // Zone 03: Emberpeak Highlands
    set z = ZoneData.create(3, "Emberpeak Highlands")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Dirty"
    set z.weatherZoneName = "EmperpeakHighlands"
    set z.environmentType = "Mountainous"
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
    call RegisterZone(z)
    
    // Zone 04: Dragonfire Peaks
    set z = ZoneData.create(4, "Dragonfire Peaks")
    set z.musicTrack = 14
    set z.dncName = "Outdoors Red"
    set z.weatherZoneName = "DragonfirePeaks"
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
    call RegisterZone(z)
    
    // Zone 06: Thornwoods
    set z = ZoneData.create(6, "Thornwoods")
    set z.musicTrack = 5
    set z.weatherZoneName = "Thornwoods"
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
    call RegisterZone(z)
    
    // Zone 07: Havenwoods
    set z = ZoneData.create(7, "Havenwoods")
    set z.musicTrack = 81
    set z.weatherZoneName = "Havenwoods"
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
    call RegisterZone(z)
    
    // Zone 09: Vanguard Vale
    set z = ZoneData.create(9, "Vanguard Vale")
    set z.musicTrack = 78
    set z.weatherZoneName = "VanguardVale"
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
    call RegisterZone(z)
    
    // Zone 10: Riverbane
    set z = ZoneData.create(10, "Riverbane")
    set z.musicTrack = 2
    set z.weatherZoneName = "Riverbane"
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
    call RegisterZone(z)
    
    // Zone 11: Deadwoods
    set z = ZoneData.create(11, "Deadwoods")
    set z.musicTrack = 21
    set z.dncName = "DarkPlace"
    set z.weatherZoneName = "Deadwoods"
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
    call RegisterZone(z)
    
    // Zone 13: Stormhaven
    set z = ZoneData.create(13, "Stormhaven")
    set z.musicTrack = 51
    set z.weatherZoneName = "Stormhaven"
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
    call RegisterZone(z)
    
    // Zone 14: Sirensong
    set z = ZoneData.create(14, "Sirensong")
    set z.musicTrack = 7
    set z.weatherZoneName = "Sirensong"
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
    call RegisterZone(z)
    
    // Zone 17: Verdant Plains
    set z = ZoneData.create(17, "Verdant Plains")
    set z.musicTrack = 11
    set z.weatherZoneName = "VerdantPlains"
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
    call RegisterZone(z)
    
    //=======================================================================
    // DUNGEONS
    //=======================================================================
    
    // Dungeon 01: Gnoll Hideout
    set z = ZoneData.create(101, "Gnoll Hideout")
    set z.musicTrack = 4
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
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
    set z.ambientRegion = "Dungeon01Area"
    set z.questDescription = "A dark hideout infested with gnolls and other... beings."
    set z.questLevelReq = "5-12"
    set z.factions = "-"
    set z.notableEntities = "Gnoll, Undead"
    set z.notableCharacters = "Impaler, Deathlord Fel'Dok"
    set z.iconPath = "zones\\zone06_thornwoods.blp"   
    call RegisterZone(z)

    // Dungeon 02: Crypt
    set z = ZoneData.create(102, "The Crypt")
    set z.musicTrack = 20
    set z.dncName = "DarkerPlace"
    set z.environmentType = "Underground"
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
    call RegisterZone(z)

    // Dungeon 03: Wyrmhold Sanctum
    set z = ZoneData.create(103, "Wyrmhold Sanctum")
    set z.musicTrack = 25
    set z.isDungeon = true
    set z.environmentType = "Underground"
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 6000.0
    set z.fogDay[2] = 25.0
    set z.fogDay[3] = 25.0
    set z.fogDay[4] = 25.0
    set z.fogNight[0] = 1000.0
    set z.fogNight[1] = 6000.0
    set z.fogNight[2] = 25.0
    set z.fogNight[3] = 25.0
    set z.fogNight[4] = 25.0
    set z.ambientDaySound = "gg_snd_Ambient_DungeonDragon"
    set z.ambientNightSound = "gg_snd_Ambient_DungeonDragon"
    set z.ambientRegion = "05WyrmholdSanctum"
    set z.questDescription = "Deep within this cavern, the dragon mother slumbers."
    set z.questLevelReq = "20-25"
    set z.factions = "-"
    set z.notableEntities = "Dragon"
    set z.notableCharacters = "Dragonmother XXX"
    set z.iconPath = "zones\\zone_wyrmholdsanctum.blp" 
    call RegisterZone(z)

    // Dungeon 04: Boom Mine
    set z = ZoneData.create(104, "Boom Mine")
    set z.musicTrack = 23
    set z.isDungeon = true
    set z.dncName = "Underground"
    set z.environmentType = "Underground"
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
    call RegisterZone(z)

    // Dungeon 05: Firelands
    set z = ZoneData.create(105, "Firelands")
    set z.musicTrack = 22
    set z.isDungeon = true
    set z.dncName = "Firelands"
    set z.environmentType = "Elemental Place"
    set z.hasLeaveHandler = true  // Cleanup VolcanoLoop sound on leave
    set z.fogDay[0] = 1000.0
    set z.fogDay[1] = 8000.0
    set z.fogDay[2] = 80.0
    set z.fogDay[3] = 15.0
    set z.fogDay[4] = 15.0
    set z.fogNight[0] = 1000.0
    set z.fogNight[1] = 8000.0
    set z.fogNight[2] = 80.0
    set z.fogNight[3] = 15.0
    set z.fogNight[4] = 15.0
    set z.ambientDaySound = "gg_snd_Ambient_VolcanicDay"
    set z.ambientNightSound = "gg_snd_Ambient_VolcanicDay"
    set z.ambientRegion = "016Firelands"
    set z.questDescription = "One of the areas of elemental fire, eternally burning."
    set z.questLevelReq = "20-30"
    set z.factions = "-"
    set z.notableEntities = "Fire Elemental, Earth Elemental"
    set z.notableCharacters = "Ragnaros, Core Hound"
    set z.iconPath = "zones\\zone_firelands.blp"   
    call RegisterZone(z)
endfunction

//===========================================================================
// Helper Functions
//===========================================================================
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
        call BJDebugMsg("[Zones] Adding ambient: " + soundName)
    endif
endfunction

private function ApplyFog takes ZoneData z, boolean isDay, player p returns nothing
    local string weather = ""
    local real array fog
    local integer i

    if z.weatherZoneName != "" then
        set weather = WeatherSystem_GetZoneWeather(z.weatherZoneName)
    endif
    if weather == "rain_heavy" or weather == "snow_heavy" or weather == "storm" then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Zones: Fog - Applying HEAVY weather fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherHeavy[i]
            set i = i + 1
        endloop
    elseif weather == "rain_medium" or weather == "snow_medium" then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Zones: Fog - Applying MEDIUM weather fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherMedium[i]
            set i = i + 1
        endloop
    elseif weather == "rain_light" or weather == "snow_light" or weather == "wind" then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Zones: Fog - Applying LIGHT weather fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogWeatherLight[i]
            set i = i + 1
        endloop
    elseif isDay then
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Zones: Fog - Applying DAY fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogDay[i]
            set i = i + 1
        endloop
    else
        if DEBUG then
            call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Zones: Fog - Applying NIGHT fog")
        endif
        set i = 0
        loop
            exitwhen i > 4
            set fog[i] = z.fogNight[i]
            set i = i + 1
        endloop
    endif

    if DEBUG then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "AddFogForPlayer debug: fog[0]=" + R2S(fog[0]) + ", fog[1]=" + R2S(fog[1]) + ", fog[2]=" + R2S(fog[2]) + ", fog[3]=" + R2S(fog[3]) + ", fog[4]=" + R2S(fog[4]))
    endif

    // Apply fog to player
    call AddFogForPlayer(fog[0], fog[1], fog[2], fog[3], fog[4], p)

endfunction

/* LEFTOVER CODE - WEATHER FOG HANDLING - check if needed later
private function ApplyWeatherFog takes ZoneData z, player p returns nothing
    local string weather = ""
    local real fogStart
    local real fogEnd
    
    if z.weatherZoneName != "" then
        // Get weather from WeatherSystem
        // Note: This assumes WeatherSystem_GetZoneWeather exists
        // set weather = WeatherSystem_GetZoneWeather(z.weatherZoneName)
        
        if weather != "" and weather != "none" then
            // Adjust fog intensity based on weather type
            // Heavy fog only for rain_heavy and snow_heavy
            // Medium fog for rain_medium and snow_medium
            // Light fog for rain_light, snow_light, and other types
            
            if weather == "rain_heavy" or weather == "snow_heavy" then
                // Heavy fog - use full fog settings
                set fogStart = z.weatherFogStart
                set fogEnd = z.weatherFogEnd
            elseif weather == "rain_medium" or weather == "snow_medium" then
                // Medium fog - reduce fog intensity (push fog further back)
                set fogStart = z.weatherFogStart * 1.5
                set fogEnd = z.weatherFogEnd * 1.3
            elseif weather == "rain_light" or weather == "snow_light" then
                // Light fog - minimal fog (push fog much further back)
                set fogStart = z.weatherFogStart * 2.0
                set fogEnd = z.weatherFogEnd * 1.6
            elseif weather == "storm" then
                // Storm - use heavy fog (storm always has rain_heavy or rain_medium now)
                set fogStart = z.weatherFogStart * 0.8  // Even closer for storm
                set fogEnd = z.weatherFogEnd
            else
                // Other weather types (wind, etc.) - light fog
                set fogStart = z.weatherFogStart * 2.0
                set fogEnd = z.weatherFogEnd * 1.6
            endif
            
            call AddFogForPlayer(fogStart, fogEnd, z.weatherFogR, z.weatherFogG, z.weatherFogB, p)
        endif
    endif
endfunction
*/ 

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
    elseif dncName == "Firelands" then
        call DNC_Firelands()
    endif
    if DEBUG then
        call BJDebugMsg("[Zones] Running DNC: " + dncName)
    endif
endfunction

private function HandleSpecialEffects takes ZoneData z, unit triggeringUnit returns nothing
    // Handle special zone effects (camera, sky, etc.)
    
    if z.setSkyClear then
        call SetSkyModel(null)
    endif
    
    if z.hasSpecialCamera and z.zoneId == 4 then
        // Boom Mine special camera
        // This is a placeholder for camera handling
        if DEBUG then
            call BJDebugMsg("[Zones] Applying special camera for Boom Mine")
        endif
    endif
    
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
            call BJDebugMsg("[Zones] Created zone quest: " + z.name)
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

//===========================================================================
// Zone Leave Cleanup Handler
//===========================================================================
private function HandleZoneLeaveCleanup takes integer zoneId, unit triggeringUnit returns nothing
    local ZoneData z = GetZoneData(zoneId)
    if z == 0 or not z.hasLeaveHandler then
        return  // No cleanup needed
    endif
    if DEBUG then
        call BJDebugMsg("[Zones] Leaving: " + z.name + " (ID: " + I2S(zoneId) + ") - Running cleanup")
    endif
    // Zone-specific cleanup actions
    // Add cleanup logic for specific zones here
    if zoneId == 5 then
        // Firelands - Remove VolcanoLoop sound
        if DEBUG then
            call BJDebugMsg("[Zones] Firelands cleanup: Removing VolcanoLoop sound")
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
        call BJDebugMsg("Music track: " + I2S(z.musicTrack))
        call BJDebugMsg("udg_ExMusicInteger: " + I2S(udg_ExMusicInteger))
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
    local integer pid
    local integer discoverKey

    if DEBUG then   
        call BJDebugMsg("[Zones] HandleZoneEnter called")
    endif 
    if not systemEnabled then
        if DEBUG then   
            call BJDebugMsg("[Zones] System not enabled! (return)")
        endif
        return
    endif
    if not zoneEnabled[newZoneId] then
        if DEBUG then   
            call BJDebugMsg("[Zones] ERROR: Zone " + I2S(newZoneId) + " not enabled! (return)")
        endif
        return  // Zone disabled
    endif
    if newZoneId == currentZone then
        if DEBUG then
            call BJDebugMsg("[Zones] Already in this zone - " + I2S(newZoneId) + " (return)")
        endif
        return  // Already in this zone
    endif
    set z = GetZoneData(newZoneId)
    set currentZone = newZoneId
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
            call BJDebugMsg("[Zones] ERROR: Zone " + I2S(newZoneId) + " not found! (return)")
        endif
        return
    endif
    if DEBUG then
        call BJDebugMsg("[Zones] Entering: " + z.name + " (ID: " + I2S(newZoneId) + ")")
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
    set fog_Player[0] = triggerPlayer
    if DEBUG then
        call BJDebugMsg("[Zones] ApplyFog: udg_DNE_IsDaytime=" + I2S(B2I(udg_DNE_IsDaytime)) + ", isDay=" + I2S(B2I(isDay)))
    endif
    call ApplyFog(z, isDay, triggerPlayer)

    // Zone Special stuff
    call HandleSpecialEffects(z, triggeringUnit)

    if not zoneDayNightEvent then
        call CreateQuestLog(z)
        if DEBUG then
            call BJDebugMsg("[Zones] Entered: " + z.name)
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
    if DEBUG then
        call BJDebugMsg("[Zones] OnUnitEnterRegion triggered")
    endif

    if not IsPlayerInForce(trigPlayer, udg_PlayerGroup) then
        if DEBUG then
            call BJDebugMsg("[Zones] Early exit: Player not in udg_PlayerGroup")
        endif
        return
    endif
    if not IsUnitType(trigUnit, UNIT_TYPE_HERO) then
        if DEBUG then
            call BJDebugMsg("[Zones] Early exit: Unit is not a hero")
        endif
        return
    endif
    if IsUnitTypeExcluded(unitType) then
        if DEBUG then
            call BJDebugMsg("[Zones] Early exit: Unit type is excluded")
        endif
        return
    endif
    if udg_NazgrekMorphing or udg_ZulkisMorphing then
        if DEBUG then
            call BJDebugMsg("[Zones] Early exit: Morphing detected")
        endif
        return
    endif
    set zoneId = triggerToZoneId.get(trig)
    if zoneId == 0 then
        if DEBUG then
            call BJDebugMsg("[Zones] Could not find zoneId for this trigger")
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
function Zones_ApplyCurrentZoneEffects takes nothing returns nothing
    local ZoneData z
    local player triggerPlayer = GetLocalPlayer()
    local boolean isDay = udg_DNE_IsDaytime

    if currentZone == 0 then
        return
    endif
    set z = GetZoneData(currentZone)
    if z == 0 then
        return
    endif

    // Music
    set udg_ExMusicInteger = z.musicTrack
    call ExMusic_PlayTrack(udg_ExMusicInteger)

    // DNC
    call RunDNC(z.dncName)

    // Fog
    set fog_Player[0] = triggerPlayer
    if DEBUG then
        call BJDebugMsg("[Zones] ApplyFog: udg_DNE_IsDaytime=" + I2S(B2I(udg_DNE_IsDaytime)) + ", isDay=" + I2S(B2I(isDay)))
    endif
    call ApplyFog(z, isDay, triggerPlayer)

    // Ambient
    // Clear existing ambient sounds first
    call ClearAmbientSounds()
    if isDay and z.ambientDaySound != "" then
        call AddAmbientSound(z.ambientDaySound, null)
    elseif not isDay and z.ambientNightSound != "" then
        call AddAmbientSound(z.ambientNightSound, null)
    endif

    // Zone Special stuff
    call HandleSpecialEffects(z, null)

endfunction

function Zones_GetCurrentZone takes nothing returns integer
    return currentZone
endfunction


function Zones_ForceUpdate takes unit whichUnit returns nothing
    // Force zone update for a specific unit
    // This can be called by day/night events or manually
    set zoneDayNightEvent = true
    // Re-enter current zone to update fog/ambient
    if currentZone > 0 then
        call HandleZoneEnter(currentZone, whichUnit)
    endif
    set zoneDayNightEvent = false
endfunction

function Zones_Enable takes boolean enable returns nothing
    set systemEnabled = enable
    if DEBUG then
        if enable then
            call BJDebugMsg("[Zones] System enabled")
        else
            call BJDebugMsg("[Zones] System disabled")
        endif
    endif
endfunction

function Zones_EnableZone takes integer zoneId, boolean enable returns nothing
    set zoneEnabled[zoneId] = enable
    
    // Also enable/disable the trigger if it exists
    if zoneTriggers[zoneId] != null then
        if enable then
            call EnableTrigger(zoneTriggers[zoneId])
        else
            call DisableTrigger(zoneTriggers[zoneId])
        endif
    endif
    
    if DEBUG then
        if enable then
            call BJDebugMsg("[Zones] Zone " + I2S(zoneId) + " enabled")
        else
            call BJDebugMsg("[Zones] Zone " + I2S(zoneId) + " disabled")
        endif
    endif
endfunction



function Zones_IsZoneEnabled takes integer zoneId returns boolean
    return zoneEnabled[zoneId]
endfunction



function Zones_GetZoneName takes integer zoneId returns string
    local ZoneData z = GetZoneData(zoneId)
    if z != 0 then
        return z.name
    endif
    return "Unknown Zone"
endfunction



function Zones_EnterZone takes integer zoneId, unit whichUnit returns nothing
    // Manually trigger zone entry (useful for teleportation, testing, etc.)
    call Zones_EnableZone(zoneId, true)
    call HandleZoneEnter(zoneId, whichUnit) 
endfunction



function Zones_SetZoneSilent takes integer zoneId returns nothing
    // Set current zone without triggering any effects (useful for teleportation)
    set currentZone = zoneId
    if DEBUG then
        call BJDebugMsg("[Zones] Current zone set to: " + I2S(zoneId) + " (silent)")
    endif
endfunction

function Zones_ResetZone takes nothing returns nothing
    // Clear current zone (for scenarios where player is teleporting out of all zones)
    set currentZone = 0
    if DEBUG then
        call BJDebugMsg("[Zones] Current zone cleared")
    endif
endfunction

function Zones_TriggerLeaveCleanup takes integer zoneId, unit whichUnit returns nothing
    // Manually trigger zone leave cleanup (useful when teleporting out)
    call HandleZoneLeaveCleanup(zoneId, whichUnit)
endfunction

function Zones_EnableLeaveHandler takes integer zoneId, boolean enable returns nothing
    // Enable/disable leave trigger for a specific zone
    if zoneLeaveTriggers[zoneId] != null then
        if enable then
            call EnableTrigger(zoneLeaveTriggers[zoneId])
        else
            call DisableTrigger(zoneLeaveTriggers[zoneId])
        endif
        
        if DEBUG then
            if enable then
                call BJDebugMsg("[Zones] Leave handler for zone " + I2S(zoneId) + " enabled")
            else
                call BJDebugMsg("[Zones] Leave handler for zone " + I2S(zoneId) + " disabled")
            endif
        endif
    endif
endfunction

//===========================================================================
// Day/Night Event System
//===========================================================================

// Timer callback to update zone effects after day/night change
private function DayNight_UpdateZone takes nothing returns nothing
    call PauseTimer(dayNightUpdateTimer)

    if currentZone > 0 then
        call Zones_ApplyCurrentZoneEffects()
    endif
endfunction

// Timer callback to reset day/night event flag
private function DayNight_ResetFlag takes nothing returns nothing
    call PauseTimer(dayNightResetTimer)
    set zoneDayNightEvent = false

    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night event completed")
    endif
endfunction

private function OnDayNightEvent takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night event triggered")
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
// Initialization - Register all zone regions here
//===========================================================================
private function RegisterZoneRegions takes nothing returns nothing
    local trigger t
    //=======================================================================
    // ZONE ENTER TRIGGERS
    //=======================================================================
    
    // Zone 01: Twilight Grove
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_001TwilightGrove)
    call TriggerRegisterEnterRectSimple(t, gg_rct_001TwilightGroveFull)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1] = t
    call triggerToZoneId.store(t, 1)

    // Zone 02: Sereneglade
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_02SereneGlade)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[2] = t
    call triggerToZoneId.store(t, 2)

    // Zone 03: Emberpeak Highlands
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_03EmberpeakHighlands)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[3] = t
    call triggerToZoneId.store(t, 3)
    
    // Zone 04: Dragonfire Peaks
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_04DragonfirePeaks)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[4] = t
    call triggerToZoneId.store(t, 4)
    
    // Zone 06: Thornwoods
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_06Thornwoods)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[6] = t
    call triggerToZoneId.store(t, 6)
     
    // Zone 0601: Stonetooth Camp
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_StonetoothCamp)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[601] = t
    call triggerToZoneId.store(t, 601)
    
    // Zone 0602: Bloodtusk Tribe
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_BloodtuskTribe)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[602] = t
    call triggerToZoneId.store(t, 602)
    
    // Zone 07: Havenwoods
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_07Havenwoods)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[7] = t
    call triggerToZoneId.store(t, 7)

    // Zone 08: Bonecrush Stronghold
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_008BonecrushStrongHold)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[8] = t
    call triggerToZoneId.store(t, 8)
    
    // Zone 09: Vanguard Vale
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_009VanguardVale)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[9] = t
    call triggerToZoneId.store(t, 9)
    
    // Zone 10: Riverbane
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_010RiverBane)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[10] = t
    call triggerToZoneId.store(t, 10)
    
    // Zone 11: Deadwoods
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_011Deadwoods)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[11] = t
    call triggerToZoneId.store(t, 11)
    
    // Zone 12: Felfire Bastion
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_012FelfireBastion)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[12] = t
    call triggerToZoneId.store(t, 12)
    
    // Zone 1201: Felfire Citadel
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_012FelfireBastion)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1201] = t
    call triggerToZoneId.store(t, 1201)
    
    // Zone 13: Stormhaven
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_013Stormhaven)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[13] = t
    call triggerToZoneId.store(t, 13)
    
    // Zone 14: Sirensong
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Sirensong)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[14] = t
    call triggerToZoneId.store(t, 14)
    
    // Zone 1401: Moknatha
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Moknatha)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1401] = t
    call triggerToZoneId.store(t, 1401)

    // Zone 1402: Zulgarok
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Zulgarok)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1402] = t
    call triggerToZoneId.store(t, 1402)
    
    // Zone 1403: Urgmar
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Urgmar)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1403] = t
    call triggerToZoneId.store(t, 1403)
    
    // Zone 1404: Serpentshore
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Serpentshore)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1404] = t
    call triggerToZoneId.store(t, 1404)
    
    // Zone 15: Zul'Gurak (4 regions)
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak1)
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak2)
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak3)
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak4)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[15] = t
    call triggerToZoneId.store(t, 15)
    
    // Zone 17: Verdant Plains
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017VerdantPlains)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[17] = t
    call triggerToZoneId.store(t, 17)
    
    // Zone 1701: Chimairos Roost
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017Chimaira)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1701] = t
    call triggerToZoneId.store(t, 1701)
    
    // Zone 1702: Weeping Hollow
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017WeepingHollow)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1702] = t
    call triggerToZoneId.store(t, 1702)
    
    // Zone 1703: Redwind Pass
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017RedwindPass)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1703] = t
    call triggerToZoneId.store(t, 1703)
    
    // Zone 1704: xxxSettlement
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017xxxSettlement)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1704] = t
    call triggerToZoneId.store(t, 1704)
    
    // Zone 1705: VaelAnorath
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017VaelAnorath)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1705] = t
    call triggerToZoneId.store(t, 1705)
    
    // Zone 18: Coliseum of Ages
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_018ColiseumOfAges)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[18] = t
    call triggerToZoneId.store(t, 18)
    
    // Zone 19: Ghostwalk Ridge
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_019GhostwalkRidge)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[19] = t
    call triggerToZoneId.store(t, 19)
    
    // Zone 1901: Ironspine Post
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_IronspinePost)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1901] = t
    call triggerToZoneId.store(t, 1901)
    
    // Zone 20: Dawnhold
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_Dawnhold)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[20] = t
    call triggerToZoneId.store(t, 20)
    
    // Zone 8810: Horde Scout Base
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_HordeScoutBase)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[8810] = t
    call triggerToZoneId.store(t, 8810)

    /* 
        // Create more zone triggers here as needed
    */
    
    //=======================================================================
    // DUNGEON ENTER TRIGGERS
    //=======================================================================
    
    
    // Dungeon 01: Gnoll Hideout
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_Dungeon01Area)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[101] = t
    call triggerToZoneId.store(t, 101)
    
    // Dungeon 02: Crypt (3 regions)
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_DungeonCrypt01A)
    call TriggerRegisterEnterRectSimple(t, gg_rct_DungeonCrypt01B)
    call TriggerRegisterEnterRectSimple(t, gg_rct_DungeonCrypt01C)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[102] = t
    call triggerToZoneId.store(t, 102)
    
    // Dungeon 03: Wyrmhold Sanctum
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_05WyrmholdSanctum)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[103] = t
    call triggerToZoneId.store(t, 103)
    
    // Dungeon 04: Boom Mine
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_BoomBrothersMine)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[104] = t
    call triggerToZoneId.store(t, 104)
    
    // Dungeon 05: Firelands
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_016Firelands)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[105] = t
    call triggerToZoneId.store(t, 105)

    // Create more zone (DUNGEONS) triggers here as needed

    //=======================================================================
    // ZONE LEAVE TRIGGERS (for zones with cleanup)
    //=======================================================================
    
    // Dungeon 05: Firelands - Leave trigger for cleanup
    set t = CreateTrigger()
    call TriggerRegisterLeaveRectSimple(t, gg_rct_016Firelands)
    call TriggerAddCondition(t, Condition(function OnUnitLeaveRegion))
    set zoneLeaveTriggers[105] = t
    call triggerToZoneId.store(t, 105)

    /* 
        // Create more zone leave triggers here as needed
    */

endfunction

private function InitVariables takes nothing returns nothing
    // Initialize variables to global variables for Day/Night updates
    set UPDATE_UNIT = udg_Nazgrek

    // Initialize sound variables to null
    set ZONE_DISCOVER_SOUND = gg_snd_Interface_ZoneDiscovered
    set ZONE_ENTER_SOUND = gg_snd_ZoneEnter
    set DUNGEON_DISCOVER_SOUND = gg_snd_Interface_DungeonEnter
    set DUNGEON_ENTER_SOUND = gg_snd_Interface_DungeonEnter

endfunction

private function Init takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("[Zones] Initializing zone system...")
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

    // Configure all zones
    call ConfigureZones()
    
    // Register zone regions (triggers)
    call RegisterZoneRegions()
    
    // Set up Day/Night event trigger
    set dayNightEventTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(dayNightEventTrigger, "udg_DNE_DayNightEvent", EQUAL, 1.00)
    call TriggerRegisterVariableEvent(dayNightEventTrigger, "udg_DNE_DayNightEvent", EQUAL, 2.00)
    call TriggerAddAction(dayNightEventTrigger, function OnDayNightEvent)

    // Initialize variables (WE created global variables)
    call InitVariables()

    if DEBUG then
        call BJDebugMsg("[Zones] Zone system initialized!")
        call BJDebugMsg("[Zones] Day/Night event system active")
    endif
endfunction

endlibrary
