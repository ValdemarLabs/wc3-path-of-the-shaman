library Zones initializer Init requires ExMusic, WeatherSystem
//===========================================================================
/*
    Zones System - Dynamic Zone & Dungeon Management
    
    Author: [Valdemar]
    Version: 1.0
    
    Handles all zone and dungeon transitions including:
    - Music changes (ExMusic integration)
    - Day/Night cycle triggers (DNC)
    - Fog settings (day/night variants)
    - Ambient sounds (day/night variants)
    - Weather system integration
    - Quest log discovery system
    - Multiple regions per zone
    - Special fog effects (multi-layer)
    
    API:
        Zones_GetCurrentZone() - Get current zone ID
        Zones_GetCurrentDungeon() - Get current dungeon ID
        Zones_ForceUpdate(unit) - Manually trigger zone update for a unit
        Zones_Enable(enable) - Enable/disable entire zone system
        Zones_IsDungeon(zoneId) - Check if zone ID is a dungeon
        
        Zones_EnableZone(zoneId, enable) - Enable/disable specific zone trigger
        Zones_EnableDungeon(dungeonId, enable) - Enable/disable specific dungeon trigger
        Zones_IsZoneEnabled(zoneId) - Check if zone is enabled
        Zones_IsDungeonEnabled(dungeonId) - Check if dungeon is enabled
        Zones_GetZoneName(zoneId) - Get zone name by ID
        Zones_GetDungeonName(dungeonId) - Get dungeon name by ID
        Zones_EnterZone(zoneId, unit) - Manually trigger zone entry for a unit
        Zones_EnterDungeon(dungeonId, unit) - Manually trigger dungeon entry for a unit
        Zones_SetZoneSilent(zoneId, isDungeon) - Set current zone without triggering effects
        Zones_ResetZone() - Clear current zone/dungeon (for teleport scenarios)
        Zones_TriggerLeaveCleanup(zoneId, isDungeon, unit) - Manually trigger zone leave cleanup
        Zones_EnableLeaveHandler(zoneId, enable) - Enable/disable leave trigger for a zone
        Zones_SetTrackedHero(unit) - Set which hero to use for Day/Night event updates

    API Usage examples; 
        // Disable Zone 11 (Deadwoods) entry events
        call Zones_EnableZone(11, false)

        // Re-enable it later
        call Zones_EnableZone(11, true)

        // Check if a zone is enabled before teleporting
        if Zones_IsZoneEnabled(18) then
            call Zones_EnterZone(18, udg_PlayerHero)
        endif

        // Teleport player to dungeon without triggering effects
        call Zones_SetZoneSilent(3, true)  // Set to Wyrmhold Sanctum silently
        call SetUnitPosition(hero, x, y)
        call Zones_EnterDungeon(3, hero)  // Now trigger the full entry effects

        // Get zone name for display
        call BJDebugMsg("Current zone: " + Zones_GetZoneName(Zones_GetCurrentZone()))
        
        // Manually trigger leave cleanup when teleporting out of a zone
        if Zones_GetCurrentDungeon() == 5 then  // Firelands
            call Zones_TriggerLeaveCleanup(5, true, hero)  // Clean up before teleport
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
    //===========================================================================
    // CONFIGURATION
    //===========================================================================
    private constant boolean DEBUG = false
    private constant integer MAX_ZONES = 10000  // Support up to zone ID 10000
    private constant integer MAX_AMBIENT_SOUNDS = 10  // Max ambient sounds per zone
    
    // Unit types to exclude from zone detection (easy to extend - just add more!)
    private constant integer MAX_EXCLUDED_UNIT_TYPES = 10
    private integer array excludedUnitTypes
    private integer excludedUnitTypeCount = 0
    
    //
    // SYSTEM VARIABLES (DO NOT MODIFY)
    //===========================================================================
    private integer currentZone = 0
    private integer currentDungeon = 0
    private boolean systemEnabled = true
    private boolean zoneDayNightEvent = false  // Set to true when triggered by day/night cycle
    private sound array zoneAmbient[MAX_AMBIENT_SOUNDS]  // Ambient sound handles
    private integer zoneAmbientCount = 0
    private trigger array zoneTriggers  // Trigger handles for each zone
    private trigger array zoneLeaveTriggers  // Trigger handles for zone leave events
    private boolean array zoneEnabled  // Enable/disable specific zones
    private boolean array dungeonEnabled  // Enable/disable specific dungeons
    private trigger dayNightEventTrigger = null  // Trigger for day/night transitions
    private unit trackedHeroUnit = null  // Hero unit to update on day/night change
    
    // Player group check (assumes udg_PlayerGroup from GUI)
    // Note: You may need to adjust this based on your actual player group variable
    
    // Morph detection (assumes these exist from GUI)
    // Note: Adjust if variable names differ
    
    // External variables (GUI)
    private player array fog_Player
    private boolean dayTime = false
    private integer exMusicInteger = 0
    private string tempString = ""
    private unit z_EnteringUnit = null
    private boolean inDungeon_GnollHideout = false
    private boolean cheat_Camlock = false
    
    // Quest arrays (GUI)
    private quest array zones  // Quest handles for zones
    private quest array dungeons  // Quest handles for dungeons
    
    // Zone data storage (declared here, populated after struct definition)
    private integer array zoneDatabase
    private integer array dungeonDatabase
endglobals

//===========================================================================
// Zone Data Structure
//===========================================================================
struct ZoneData
    // Basic info
    integer zoneId
    string name
    boolean isDungeon
    
    // Music & atmosphere
    integer musicTrack
    string dncTriggerName  // DNC trigger to run ("Outdoors", "Underground", "DarkPlace", etc.)
    string weatherZoneName  // Weather system zone name (empty string = no weather)
    
    // Fog settings - Day
    real fogStartDay
    real fogEndDay
    real fogRDay
    real fogGDay
    real fogBDay
    
    // Fog settings - Night
    real fogStartNight
    real fogEndNight
    real fogRNight
    real fogGNight
    real fogBNight
    
    // Special fog (for zones like Deadwoods with multiple fog layers)
    boolean hasSecondaryFog
    real fogStart2
    real fogEnd2
    real fogR2
    real fogG2
    real fogB2
    
    // Weather fog overlay
    real weatherFogStart
    real weatherFogEnd
    real weatherFogR
    real weatherFogG
    real weatherFogB
    
    // Ambient sounds (region names to add ambient to)
    string ambientDaySound  // Ambient sound name for day (empty = none)
    string ambientNightSound  // Ambient sound name for night (empty = none)
    string ambientRegion  // Region name to add ambient across
    
    // Special flags
    boolean playSoundOnEnter  // Play dungeon enter sound
    boolean hasSpecialCamera  // Has special camera setup (like Boom Mine)
    boolean setSkyClear  // Set sky to None/Clear
    boolean hasLeaveHandler  // Has leave event handler (for cleanup)
    
    // Quest log
    string questTitle
    string questDescription
    string questLevelReq
    
    static method create takes integer id, string zoneName returns thistype
        local thistype this = thistype.allocate()
        set .zoneId = id
        set .name = zoneName
        set .isDungeon = false
        
        // Default values
        set .musicTrack = 0
        set .dncTriggerName = "Outdoors"
        set .weatherZoneName = ""
        
        // Default fog (neutral gray)
        set .fogStartDay = 1000.0
        set .fogEndDay = 8000.0
        set .fogRDay = 75.0
        set .fogGDay = 75.0
        set .fogBDay = 75.0
        
        set .fogStartNight = 3000.0
        set .fogEndNight = 15000.0
        set .fogRNight = 15.0
        set .fogGNight = 15.0
        set .fogBNight = 50.0
        
        set .hasSecondaryFog = false
        set .fogStart2 = 0
        set .fogEnd2 = 0
        set .fogR2 = 0
        set .fogG2 = 0
        set .fogB2 = 0
        
        set .weatherFogStart = 500.0
        set .weatherFogEnd = 2000.0
        set .weatherFogR = 10.0
        set .weatherFogG = 10.0
        set .weatherFogB = 30.0
        
        set .ambientDaySound = ""
        set .ambientNightSound = ""
        set .ambientRegion = ""
        
        set .playSoundOnEnter = false
        set .hasSpecialCamera = false
        set .setSkyClear = false
        set .hasLeaveHandler = false
        
        set .questTitle = "Zone: " + zoneName
        set .questDescription = ""
        set .questLevelReq = "|cFFFFCC00Level:|r |cFFFFFFFF??|r"
        
        return this
    endmethod
endstruct

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

private function RegisterDungeon takes ZoneData z returns nothing
    set dungeonDatabase[z.zoneId] = z
    set dungeonEnabled[z.zoneId] = true  // Dungeons enabled by default
    if DEBUG then
        call BJDebugMsg("[Zones] Registered Dungeon " + I2S(z.zoneId) + ": " + z.name)
    endif
endfunction

private function GetZoneData takes integer zoneId returns ZoneData
    return zoneDatabase[zoneId]
endfunction

private function GetDungeonData takes integer dungeonId returns ZoneData
    return dungeonDatabase[dungeonId]
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
    set z.dncTriggerName = "Outdoors"
    set z.weatherZoneName = "TwilightGrove"
    set z.fogRDay = 50.0
    set z.fogGDay = 75.0
    set z.fogBDay = 50.0
    set z.ambientDaySound = "Ambient_EnchantedForestDay"
    set z.ambientNightSound = "Ambient_ForestNight"
    set z.ambientRegion = "001TwilightGroveFull"
    set z.questDescription = "This eerie forest is dominated by a colossal dead tree, its twisted branches reaching out like skeletal fingers to the sky. Shadows dance among the gnarled roots, hinting at ancient secrets buried deep within the forest's heart."
    call RegisterZone(z)
    
    // Zone 02: Sereneglade
    set z = ZoneData.create(2, "Sereneglade")
    set z.musicTrack = 9
    set z.weatherZoneName = "Serenaglade"
    set z.ambientDaySound = "Ambient_ForestDay"
    set z.ambientNightSound = "Ambient_ForestNight"
    set z.ambientRegion = "02SereneGlade"
    set z.questDescription = "A tranquil forest expanse with a pristine lake at its heart, where nature thrives in harmony and the air is filled with a sense of peace and tranquility."
    call RegisterZone(z)
    
    // Zone 03: Emberpeak Highlands
    set z = ZoneData.create(3, "Emberpeak Highlands")
    set z.musicTrack = 14
    set z.dncTriggerName = "Outdoors Dirty"
    set z.weatherZoneName = "EmperpeakHighlands"
    set z.fogRDay = 50.0
    set z.fogGDay = 15.0
    set z.fogBDay = 15.0
    set z.fogRNight = 35.0
    set z.questDescription = "Towering crags of ashen stone pierce the heavens, home to enigmatic stone golems and the fiery guardians of earth, their presence casting an ominous shadow over the desolate landscape."
    call RegisterZone(z)
    
    // Zone 04: Dragonfire Peaks
    set z = ZoneData.create(4, "Dragonfire Peaks")
    set z.musicTrack = 14
    set z.dncTriggerName = "Outdoors Red"
    set z.weatherZoneName = "DragonfirePeaks"
    set z.fogRDay = 85.0
    set z.fogGDay = 5.0
    set z.fogBDay = 5.0
    set z.fogRNight = 66.0
    set z.fogGNight = 6.0
    set z.questDescription = "A treacherous mountainous terrain where fierce dragons reign supreme, their fiery breaths lighting up the sky as they clash with fire and earth elementals amidst the rocky crags."   
    call RegisterZone(z)
    
    // Zone 06: Thornwoods
    set z = ZoneData.create(6, "Thornwoods")
    set z.musicTrack = 5
    set z.weatherZoneName = "Thornwoods"
    set z.questDescription = "A peaceful forest teeming with life, yet fraught with danger as forest trolls, gnolls, and murlocs lurk among the verdant foliage, each vying for dominance over their domain."
    call RegisterZone(z)
    
    // Zone 0601: Stonetooth Camp
    set z = ZoneData.create(601, "Stonetooth Camp")
    set z.musicTrack = 72
    set z.questDescription = "A gnoll encampment in the Thornwoods."
    call RegisterZone(z)
    
    // Zone 0602: Bloodtusk Tribe
    set z = ZoneData.create(602, "Bloodtusk Tribe")
    set z.musicTrack = 70
    set z.fogRDay = 15.0
    set z.fogGDay = 80.0
    set z.fogBDay = 15.0
    set z.questDescription = "The village of Bloodtusk Tribe trolls"
    call RegisterZone(z)
    
    // Zone 07: Havenwoods
    set z = ZoneData.create(7, "Havenwoods")
    set z.musicTrack = 81
    set z.weatherZoneName = "Havenwoods"
    set z.questDescription = "A tranquil forest retreat where humans and murlocs coexist in surprising harmony, their simple settlements nestled amidst the towering trees, a beacon of peace in a troubled world."
    call RegisterZone(z)
    
    // Zone 08: Bonecrush Stronghold
    set z = ZoneData.create(8, "Bonecrush Stronghold")
    set z.musicTrack = 94
    set z.fogRDay = 50.0
    set z.fogGDay = 50.0
    set z.fogBDay = 50.0
    set z.questDescription = "A formidable fortress carved into the rugged mountainside, where ogres reign supreme. Massive gates loom ominously over the surrounding landscape, daring any who would challenge the might of the ogre warlords to enter their domain."
    call RegisterZone(z)
    
    // Zone 09: Vanguard Vale
    set z = ZoneData.create(9, "Vanguard Vale")
    set z.musicTrack = 78
    set z.weatherZoneName = "VanguardVale"
    set z.questDescription = "In this once elven-dominated territory, the air hums with the presence of wraiths and arcane magic, ever vigilant against the encroaching dangers that lurk beyond the borders of their domain."
    call RegisterZone(z)
    
    // Zone 10: Riverbane
    set z = ZoneData.create(10, "Riverbane")
    set z.musicTrack = 2
    set z.weatherZoneName = "Riverbane"
    set z.questDescription = "Along the winding river, scattered settlements offer respite to weary travelers, but danger lurks in the shadows as bandits prowl the dense undergrowth."
    call RegisterZone(z)
    
    // Zone 11: Deadwoods (SPECIAL - double fog)
    set z = ZoneData.create(11, "Deadwoods")
    set z.musicTrack = 21
    set z.dncTriggerName = "DarkPlace"
    set z.weatherZoneName = "Deadwoods"
    set z.fogStartDay = 500.0
    set z.fogEndDay = 5000.0
    set z.fogRDay = 0.0
    set z.fogGDay = 0.0
    set z.fogBDay = 30.0
    set z.fogStartNight = 1000.0
    set z.fogEndNight = 8000.0
    set z.fogRNight = 0.0
    set z.fogGNight = 0.0
    set z.fogBNight = 30.0
    set z.hasSecondaryFog = true
    set z.fogStart2 = 500.0
    set z.fogEnd2 = 5000.0
    set z.fogR2 = 0.0
    set z.fogG2 = 0.0
    set z.fogB2 = 30.0
    set z.questDescription = "A haunting forest where ethereal specters roam amidst the twisted trees, their mournful wails echoing through the mist-shrouded glades, alongside the resilient spirit of a small human settlement."
    call RegisterZone(z)
    
    // Zone 12: Felfire Bastion
    set z = ZoneData.create(12, "Felfire Bastion")
    set z.musicTrack = 93
    set z.fogRDay = 15.0
    set z.fogGDay = 75.0
    set z.fogBDay = 15.0
    set z.questDescription = "A dark forest tainted by the presence of fel orcs, their savage war cries echoing through the trees as they lay siege to any who dare to oppose them. At the heart of the stronghold, a towering fortress rises ominously against the blood-red sky, a beacon of despair in a land consumed by darkness."
    call RegisterZone(z)
    
    // Zone 1201: Felfire Citadel
    set z = ZoneData.create(1201, "Felfire Citadel")
    set z.musicTrack = 44
    set z.fogRDay = 15.0
    set z.fogGDay = 75.0
    set z.fogBDay = 15.0
    set z.questDescription = "The heart of fel corruption."
    call RegisterZone(z)
    
    // Zone 13: Stormhaven
    set z = ZoneData.create(13, "Stormhaven")
    set z.musicTrack = 51
    set z.weatherZoneName = "Stormhaven"
    set z.questDescription = "A human town, where the human denizens thrive amidst the comforting embrace of their quaint town, shielded from the chaos that lurks beyond its borders."
    call RegisterZone(z)
    
    // Zone 14: Sirensong
    set z = ZoneData.create(14, "Sirensong")
    set z.musicTrack = 7
    set z.weatherZoneName = "Sirensong"
    set z.fogRDay = 55.0
    set z.fogGDay = 65.0
    set z.fogBDay = 55.0
    set z.questDescription = "Enveloped by the lush foliage of the jungle and the vast expanse of the ocean's embrace, this zone invites contemplation and exploration. Among the foliage, trolls and ogres carve out their territories with blood."
    call RegisterZone(z)
    
    // Zone 1401: Moknatha
    set z = ZoneData.create(1401, "Mok'natha")
    set z.musicTrack = 71
    set z.fogRDay = 55.0
    set z.fogGDay = 65.0
    set z.fogBDay = 55.0
    set z.questDescription = "Near the mighty ocean shoreline lies orc settlement of Mok'natha."
    call RegisterZone(z)
    
    // Zone 1402: Zulgarok
    set z = ZoneData.create(1402, "Ruins of Zul'Garok")
    set z.musicTrack = 70
    set z.fogRDay = 55.0
    set z.fogGDay = 65.0
    set z.fogBDay = 55.0
    set z.questDescription = "Zul'Garok was a small temple settlement of the Sirensong trolls, destroyed by the mighty hydra demigod Jinvorrak, whom the trolls worship. The settlement is still occupied by the trolls to this day, as they desperately try to summon the hydra again."
    call RegisterZone(z)
    
    // Zone 1403: Urgmar
    set z = ZoneData.create(1403, "Urgmar")
    set z.musicTrack = 94
    set z.fogRDay = 55.0
    set z.fogGDay = 65.0
    set z.fogBDay = 55.0
    set z.questDescription = "Ogre settlement by the river in Sirensong."
    call RegisterZone(z)
    
    // Zone 1404: Serpentshore
    set z = ZoneData.create(1404, "Serpentshore")
    set z.musicTrack = 7
    set z.fogRDay = 55.0
    set z.fogGDay = 65.0
    set z.fogBDay = 55.0
    set z.questDescription = "Naga serpent worshippers by the Sirensong sea shore."
    call RegisterZone(z)
    
    // Zone 15: Zul'Gurak
    set z = ZoneData.create(15, "Zul'Gurak")
    set z.musicTrack = 3
    set z.questDescription = "Amidst the dense jungle foliage, ancient Gurak'jin Tribe trolls gather in worship of their primal gods, their rituals echoing through the verdant canopy as they pay homage to powers older than time itself."
    call RegisterZone(z)
    
    // Zone 17: Verdant Plains
    set z = ZoneData.create(17, "Verdant Plains")
    set z.musicTrack = 11
    set z.weatherZoneName = "VerdantPlains"
    set z.fogRDay = 85.0
    set z.fogGDay = 85.0
    set z.fogBDay = 55.0
    set z.questDescription = "XXX An expansive landscape of open fields and lush forests, dotted with small human settlements that thrive amidst the natural beauty of their surroundings."
    call RegisterZone(z)
    
    // Zone 1701: Chimairos Roost
    set z = ZoneData.create(1701, "Chimairo's Roost")
    set z.musicTrack = 11
    set z.fogRDay = 85.0
    set z.fogGDay = 85.0
    set z.fogBDay = 55.0
    set z.questDescription = "Roost of the mighty chimera."
    call RegisterZone(z)
    
    // Zone 1702: Weeping Hollow
    set z = ZoneData.create(1702, "The Weeping Hollow")
    set z.musicTrack = 46
    set z.fogRDay = 85.0
    set z.fogGDay = 85.0
    set z.fogBDay = 55.0
    set z.questDescription = "Satyr encampment deep in the swamp of the Verdant Plains.Named after the constant dripping and crying of lost spirits or tormented flora."
    call RegisterZone(z)
    
    // Zone 1703: Redwind Pass
    set z = ZoneData.create(1703, "Redwind Pass")
    set z.musicTrack = 74
    set z.fogRDay = 85.0
    set z.fogGDay = 75.0
    set z.fogBDay = 50.0
    set z.questDescription = "Mysterious, but beautiful high mountain pass to travel between the Verdan Plains and the Havenwoods."
    call RegisterZone(z)
    
    // Zone 1704: xxxSettlement
    set z = ZoneData.create(1704, "xxxSettlement")
    set z.musicTrack = 74
    set z.fogRDay = 85.0
    set z.fogGDay = 75.0
    set z.fogBDay = 50.0
    set z.questDescription = "A mysterious settlement."
    call RegisterZone(z)
    
    // Zone 1705: VaelAnorath
    set z = ZoneData.create(1705, "Vael'Anorath")
    set z.musicTrack = 74
    set z.fogRDay = 85.0
    set z.fogGDay = 75.0
    set z.fogBDay = 50.0
    set z.questDescription = "A quiet elven refuge populated by the elven remnants of Elarindor."
    call RegisterZone(z)
    
    // Zone 18: Coliseum of Ages
    set z = ZoneData.create(18, "Coliseum of Ages")
    set z.musicTrack = 10
    set z.questDescription = "Within the crumbling ruins of this ancient arena, warriors clash in epic battles for glory and honor, their deeds echoing through the annals of history."
    call RegisterZone(z)
    
    // Zone 19: Ghostwalk Ridge
    set z = ZoneData.create(19, "Ghostwalk Ridge")
    set z.musicTrack = 62
    set z.fogRDay = 60.0
    set z.fogGDay = 80.0
    set z.fogBDay = 70.0
    set z.questDescription = "Along the borderlands of the haunted Deadwoods, this treacherous realm harbors a coveted gold mine, where orcs maintain a tenuous outpost amidst the lingering spectres of the past."
    call RegisterZone(z)
    
    // Zone 1901: Ironspine Post
    set z = ZoneData.create(1901, "Ironspine Post")
    set z.musicTrack = 68
    set z.questDescription = "A fortified orcish outpost in hostile territory."
    call RegisterZone(z)
    
    // Zone 20: Dawnhold
    set z = ZoneData.create(20, "Dawnhold")
    set z.musicTrack = 47
    set z.fogRDay = 0.0
    set z.fogGDay = 0.0
    set z.fogBDay = 30.0
    set z.questDescription = "Dawnhold, once mighty city of humans, destroyed by the fel orcs and left in ruins. Only a small harbour was left intact. Eerie sounds echo within the city's walls; is it desolace after all?"
    call RegisterZone(z)
    
    // Zone 8810: Horde Scout Base
    set z = ZoneData.create(8810, "Horde Scout Base")
    set z.musicTrack = 0
    set z.questDescription = "Horde scout base on the frontier."
    call RegisterZone(z)
    
    //=======================================================================
    // DUNGEONS
    //=======================================================================
    
    // Dungeon 01: Gnoll Hideout
    set z = ZoneData.create(1, "Gnoll Hideout")
    set z.isDungeon = true
    set z.musicTrack = 4
    set z.dncTriggerName = "Underground"
    set z.playSoundOnEnter = true
    set z.fogStartDay = 1000.0
    set z.fogEndDay = 6000.0
    set z.fogRDay = 0.0
    set z.fogGDay = 0.0
    set z.fogBDay = 60.0
    set z.fogStartNight = 1000.0
    set z.fogEndNight = 6000.0
    set z.fogRNight = 0.0
    set z.fogGNight = 0.0
    set z.fogBNight = 60.0
    set z.ambientDaySound = "Ambient_DungeonNormal"
    set z.ambientRegion = "Dungeon01Area"
    set z.questDescription = "A dark hideout infested with gnolls and other... beings."
    call RegisterDungeon(z)
    
    // Dungeon 02: Crypt
    set z = ZoneData.create(2, "The Crypt")
    set z.isDungeon = true
    set z.musicTrack = 20
    set z.dncTriggerName = "DarkerPlace"
    set z.playSoundOnEnter = true
    set z.setSkyClear = true
    set z.fogStartDay = 1000.0
    set z.fogEndDay = 8000.0
    set z.fogRDay = 0.0
    set z.fogGDay = 60.0
    set z.fogBDay = 20.0
    set z.fogStartNight = 1000.0
    set z.fogEndNight = 8000.0
    set z.fogRNight = 0.0
    set z.fogGNight = 60.0
    set z.fogBNight = 20.0
    set z.ambientDaySound = "Ambient_DungeonCrypt3"
    set z.ambientRegion = "DungeonCrypt"
    set z.questDescription = "An ancient crypt filled with undead."
    call RegisterDungeon(z)
    
    // Dungeon 03: Wyrmhold Sanctum
    set z = ZoneData.create(3, "Wyrmhold Sanctum")
    set z.isDungeon = true
    set z.musicTrack = 25
    set z.playSoundOnEnter = true
    set z.fogStartDay = 1000.0
    set z.fogEndDay = 8000.0
    set z.fogRDay = 25.0
    set z.fogGDay = 25.0
    set z.fogBDay = 25.0
    set z.fogRNight = 35.0
    set z.ambientDaySound = "Ambient_DungeonDragon"
    set z.ambientRegion = "05WyrmholdSanctum"
    set z.questDescription = "Deep within this cavern, the dragon mother slumbers."
    call RegisterDungeon(z)
    
    // Dungeon 04: Boom Mine
    set z = ZoneData.create(4, "Boom Mine")
    set z.isDungeon = true
    set z.musicTrack = 23
    set z.dncTriggerName = "Underground"
    set z.playSoundOnEnter = true
    set z.hasSpecialCamera = true
    set z.fogStartDay = 500.0
    set z.fogEndDay = 2000.0
    set z.fogRDay = 10.0
    set z.fogGDay = 10.0
    set z.fogBDay = 30.0
    set z.fogStartNight = 500.0
    set z.fogEndNight = 2000.0
    set z.fogRNight = 10.0
    set z.fogGNight = 10.0
    set z.fogBNight = 30.0
    set z.ambientDaySound = "Ambient_DungeonNormal"
    set z.ambientRegion = "BoomBrothersMine"
    set z.questDescription = "XXX"
    call RegisterDungeon(z)
    
    // Dungeon 05: Firelands
    set z = ZoneData.create(5, "Firelands")
    set z.isDungeon = true
    set z.musicTrack = 22
    set z.dncTriggerName = "Firelands"
    set z.playSoundOnEnter = true
    set z.hasLeaveHandler = true  // Cleanup VolcanoLoop sound on leave
    set z.fogStartDay = 1000.0
    set z.fogEndDay = 8000.0
    set z.fogRDay = 80.0
    set z.fogGDay = 15.0
    set z.fogBDay = 15.0
    set z.fogStartNight = 1000.0
    set z.fogEndNight = 8000.0
    set z.fogRNight = 80.0
    set z.fogGNight = 15.0
    set z.fogBNight = 15.0
    set z.ambientDaySound = "Ambient_VolcanicDay"
    set z.ambientRegion = "016Firelands"
    set z.questDescription = "One of the areas of elemental fire, eternally burning."
    call RegisterDungeon(z)
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
    // This is a placeholder - you'll need to integrate with your ambient sound system
    // For now, we'll just track that a sound was added
    set zoneAmbientCount = zoneAmbientCount + 1
    if DEBUG then
        call BJDebugMsg("[Zones] Adding ambient: " + soundName)
    endif
endfunction

private function ApplyFog takes ZoneData z, boolean isDay, player p returns nothing
    local real start
    local real endDistance
    local real r
    local real g
    local real b
    
    if isDay then
        set start = z.fogStartDay
        set endDistance = z.fogEndDay
        set r = z.fogRDay
        set g = z.fogGDay
        set b = z.fogBDay
    else
        set start = z.fogStartNight
        set endDistance = z.fogEndNight
        set r = z.fogRNight
        set g = z.fogGNight
        set b = z.fogBNight
    endif
    
    // Apply primary fog
    if GetLocalPlayer() == p then
        call SetTerrainFogEx(0, start, endDistance, 0.0, r/100.0, g/100.0, b/100.0)
    endif
    
    // Apply secondary fog if exists (like Deadwoods)
    if z.hasSecondaryFog then
        if GetLocalPlayer() == p then
            call SetTerrainFogEx(0, z.fogStart2, z.fogEnd2, 0.0, z.fogR2/100.0, z.fogG2/100.0, z.fogB2/100.0)
        endif
    endif
endfunction

private function ApplyWeatherFog takes ZoneData z, player p returns nothing
    local string weather = ""
    local real fogStart
    local real fogEnd
    
    if z.weatherZoneName != "" then
        // Get weather from WeatherSystem
        // Note: This assumes WeatherSystem_GetZoneWeather exists
        set weather = WeatherSystem_GetZoneWeather(z.weatherZoneName)
        
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
            
            if GetLocalPlayer() == p then
                call SetTerrainFogEx(0, fogStart, fogEnd, 0.0, z.weatherFogR/100.0, z.weatherFogG/100.0, z.weatherFogB/100.0)
            endif
        endif
    endif
endfunction

private function RunDNCTrigger takes string dncName returns nothing
    // This is a placeholder for running DNC triggers
    // You'll need to adapt this to your actual DNC system
    
    if dncName == "Outdoors" then
        // Run DNC Outdoors trigger
    elseif dncName == "Underground" then
        // Run DNC Underground trigger
    elseif dncName == "DarkPlace" then
        // Run DNC DarkPlace trigger
    elseif dncName == "DarkerPlace" then
        // Run DNC DarkerPlace trigger
    elseif dncName == "Outdoors Red" then
        // Run DNC Outdoors Red trigger
    elseif dncName == "Outdoors Dirty" then
        // Run DNC Outdoors Dirty trigger
    elseif dncName == "Firelands" then
        // Run DNC Firelands trigger
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
    
    if z.hasSpecialCamera and z.zoneId == 4 and z.isDungeon then
        // Boom Mine special camera
        // This is a placeholder for camera handling
        if DEBUG then
            call BJDebugMsg("[Zones] Applying special camera for Boom Mine")
        endif
    endif
    
    if z.isDungeon and z.zoneId == 1 then
        // Gnoll Hideout - set special flag
        set inDungeon_GnollHideout = true
    endif
endfunction

private function CreateQuestLog takes ZoneData z returns nothing
    local quest q
    local boolean isDungeon = z.isDungeon
    local integer id = z.zoneId
    
    if isDungeon then
        if dungeons[id] == null or not IsQuestEnabled(dungeons[id]) then
            // Create dungeon quest
            set q = CreateQuest()
            call QuestSetTitle(q, "Dungeon: " + z.name)
            call QuestSetDescription(q, z.questDescription)
            call QuestSetIconPath(q, "UI\\Minimap\\MiniMap-Entrance.blp")
            call QuestSetRequired(q, false)
            call QuestSetEnabled(q, true)
            set dungeons[id] = q
            
            if DEBUG then
                call BJDebugMsg("[Zones] Created dungeon quest: " + z.name)
            endif
        endif
    else
        if zones[id] == null or not IsQuestEnabled(zones[id]) then
            // Create zone quest
            set q = CreateQuest()
            call QuestSetTitle(q, "Zone: " + z.name)
            call QuestSetDescription(q, z.questDescription)
            call QuestSetIconPath(q, "UI\\Minimap\\MiniMap-Entrance.blp")
            call QuestSetRequired(q, false)
            call QuestSetEnabled(q, true)
            set zones[id] = q
            
            if DEBUG then
                call BJDebugMsg("[Zones] Created zone quest: " + z.name)
            endif
        endif
    endif
endfunction

//===========================================================================
// Zone Leave Cleanup Handler
//===========================================================================
private function HandleZoneLeaveCleanup takes integer zoneId, boolean isDungeon, unit triggeringUnit returns nothing
    local ZoneData z
    
    // Get zone data
    if isDungeon then
        set z = GetDungeonData(zoneId)
    else
        set z = GetZoneData(zoneId)
    endif
    
    if z == 0 or not z.hasLeaveHandler then
        return  // No cleanup needed
    endif
    
    if DEBUG then
        call BJDebugMsg("[Zones] Leaving: " + z.name + " (ID: " + I2S(zoneId) + ") - Running cleanup")
    endif
    
    // Zone-specific cleanup actions
    // Add cleanup logic for specific zones here
    
    if isDungeon and zoneId == 5 then
        // Dungeon 05: Firelands - Remove VolcanoLoop sound
        // Note: Assumes VolcanoLoop is a named sound in sound editor
        // You may need to adjust this based on your actual sound system
        if DEBUG then
            call BJDebugMsg("[Zones] Firelands cleanup: Removing VolcanoLoop sound")
        endif
        // Placeholder: call RemoveSound(gg_snd_VolcanoLoop, gg_rct_016Firelands)
    endif
    
    // Add more zone-specific cleanup here as needed
    // Example:
    // if not isDungeon and zoneId == 11 then
    //     // Deadwoods cleanup
    // endif
endfunction

//===========================================================================
// Zone Transition Handler
//===========================================================================
private function HandleZoneEnter takes integer newZoneId, boolean isDungeon, unit triggeringUnit returns nothing
    local ZoneData z
    local player triggerPlayer = GetOwningPlayer(triggeringUnit)
    local boolean isDay = dayTime
    
    if not systemEnabled then
        return
    endif
    
    // Get zone data
    if isDungeon then
        if not dungeonEnabled[newZoneId] then
            return  // Dungeon disabled
        endif
        if newZoneId == currentDungeon then
            return  // Already in this dungeon
        endif
        set z = GetDungeonData(newZoneId)
        set currentDungeon = newZoneId
    else
        if not zoneEnabled[newZoneId] then
            return  // Zone disabled
        endif
        if newZoneId == currentZone then
            return  // Already in this zone
        endif
        set z = GetZoneData(newZoneId)
        set currentZone = newZoneId
    endif
    
    if z == 0 then
        if DEBUG then
            call BJDebugMsg("[Zones] ERROR: Zone/Dungeon " + I2S(newZoneId) + " not found!")
        endif
        return
    endif
    
    if DEBUG then
        call BJDebugMsg("[Zones] Entering: " + z.name + " (ID: " + I2S(newZoneId) + ")")
    endif
    
    // Play dungeon enter sound
    if z.playSoundOnEnter then
        // Play Interface_DungeonEnter sound
        if DEBUG then
            call BJDebugMsg("[Zones] Playing dungeon enter sound")
        endif
    endif
    
    // Clear previous ambient sounds
    call ClearAmbientSounds()
    
    // Set music
    set exMusicInteger = z.musicTrack
    call ExMusic_PlayTrack(exMusicInteger)
    
    // Run DNC trigger
    call RunDNCTrigger(z.dncTriggerName)
    
    // Apply fog
    set fog_Player[0] = triggerPlayer
    call ApplyFog(z, isDay, triggerPlayer)
    
    // Apply weather fog if applicable
    call ApplyWeatherFog(z, triggerPlayer)
    
    // Add ambient sound
    if isDay and z.ambientDaySound != "" then
        // Add day ambient
        call AddAmbientSound(z.ambientDaySound, null)  // Region handling needed
    elseif not isDay and z.ambientNightSound != "" then
        // Add night ambient
        call AddAmbientSound(z.ambientNightSound, null)  // Region handling needed
    endif
    
    // Handle special effects
    call HandleSpecialEffects(z, triggeringUnit)
    
    // Create quest log if not triggered by day/night event
    if not zoneDayNightEvent then
        call CreateQuestLog(z)
        // Display "Entered" message
        if DEBUG then
            call BJDebugMsg("[Zones] Entered: " + z.name)
        endif
    endif
    
    // Store triggering unit
    set z_EnteringUnit = triggeringUnit
endfunction

//===========================================================================
// Region Enter Event Handler
//===========================================================================
private function OnUnitEnterRegion takes nothing returns nothing
    local unit trigUnit = GetTriggerUnit()
    local player trigPlayer = GetOwningPlayer(trigUnit)
    local integer unitType = GetUnitTypeId(trigUnit)
    
    // Check conditions
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
    
    // Zone transition is handled by individual zone triggers
    // This is a template function
endfunction

//===========================================================================
// Region Leave Event Handler
//===========================================================================
private function OnUnitLeaveRegion takes nothing returns nothing
    local unit trigUnit = GetTriggerUnit()
    local player trigPlayer = GetOwningPlayer(trigUnit)
    local integer unitType = GetUnitTypeId(trigUnit)
    
    // Check conditions (same as enter)
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
    
    // Zone leave cleanup is handled by individual zone triggers
    // This is a template function
endfunction

//===========================================================================
// Public API
//===========================================================================
function Zones_GetCurrentZone takes nothing returns integer
    return currentZone
endfunction

function Zones_GetCurrentDungeon takes nothing returns integer
    return currentDungeon
endfunction

function Zones_ForceUpdate takes unit whichUnit returns nothing
    // Force zone update for a specific unit
    // This can be called by day/night events or manually
    set zoneDayNightEvent = true
    
    // Re-enter current zone to update fog/ambient
    if currentZone > 0 then
        call HandleZoneEnter(currentZone, false, whichUnit)
    elseif currentDungeon > 0 then
        call HandleZoneEnter(currentDungeon, true, whichUnit)
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

function Zones_IsDungeon takes integer zoneId returns boolean
    local ZoneData z = GetDungeonData(zoneId)
    return z != 0
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

function Zones_EnableDungeon takes integer dungeonId, boolean enable returns nothing
    set dungeonEnabled[dungeonId] = enable
    
    // Also enable/disable the trigger if it exists (dungeons use same trigger array)
    if zoneTriggers[dungeonId] != null then
        if enable then
            call EnableTrigger(zoneTriggers[dungeonId])
        else
            call DisableTrigger(zoneTriggers[dungeonId])
        endif
    endif
    
    if DEBUG then
        if enable then
            call BJDebugMsg("[Zones] Dungeon " + I2S(dungeonId) + " enabled")
        else
            call BJDebugMsg("[Zones] Dungeon " + I2S(dungeonId) + " disabled")
        endif
    endif
endfunction

function Zones_IsZoneEnabled takes integer zoneId returns boolean
    return zoneEnabled[zoneId]
endfunction

function Zones_IsDungeonEnabled takes integer dungeonId returns boolean
    return dungeonEnabled[dungeonId]
endfunction

function Zones_GetZoneName takes integer zoneId returns string
    local ZoneData z = GetZoneData(zoneId)
    if z != 0 then
        return z.name
    endif
    return "Unknown Zone"
endfunction

function Zones_GetDungeonName takes integer dungeonId returns string
    local ZoneData z = GetDungeonData(dungeonId)
    if z != 0 then
        return z.name
    endif
    return "Unknown Dungeon"
endfunction

function Zones_EnterZone takes integer zoneId, unit whichUnit returns nothing
    // Manually trigger zone entry (useful for teleportation, testing, etc.)
    call HandleZoneEnter(zoneId, false, whichUnit)
endfunction

function Zones_EnterDungeon takes integer dungeonId, unit whichUnit returns nothing
    // Manually trigger dungeon entry (useful for teleportation, testing, etc.)
    call HandleZoneEnter(dungeonId, true, whichUnit)
endfunction

function Zones_SetZoneSilent takes integer zoneId, boolean isDungeon returns nothing
    // Set current zone without triggering any effects (useful for teleportation)
    if isDungeon then
        set currentDungeon = zoneId
        set currentZone = 0
    else
        set currentZone = zoneId
        set currentDungeon = 0
    endif
    
    if DEBUG then
        if isDungeon then
            call BJDebugMsg("[Zones] Current dungeon set to: " + I2S(zoneId) + " (silent)")
        else
            call BJDebugMsg("[Zones] Current zone set to: " + I2S(zoneId) + " (silent)")
        endif
    endif
endfunction

function Zones_ResetZone takes nothing returns nothing
    // Clear current zone/dungeon (for scenarios where player is teleporting out of all zones)
    set currentZone = 0
    set currentDungeon = 0
    
    if DEBUG then
        call BJDebugMsg("[Zones] Current zone/dungeon cleared")
    endif
endfunction

function Zones_TriggerLeaveCleanup takes integer zoneId, boolean isDungeon, unit whichUnit returns nothing
    // Manually trigger zone leave cleanup (useful when teleporting out)
    call HandleZoneLeaveCleanup(zoneId, isDungeon, whichUnit)
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

function Zones_SetTrackedHero takes unit whichUnit returns nothing
    // Set which unit to use for Day/Night event zone updates
    set trackedHeroUnit = whichUnit
    
    if DEBUG then
        if whichUnit != null then
            call BJDebugMsg("[Zones] Tracked hero set: " + GetUnitName(whichUnit))
        else
            call BJDebugMsg("[Zones] Tracked hero cleared")
        endif
    endif
endfunction

//===========================================================================
// Day/Night Event System
//===========================================================================
private function OnDayNightEventDelayed takes nothing returns nothing
    // Set flag to prevent quest log spam
    set zoneDayNightEvent = true
    
    // Wait 3 seconds before resetting flag
    call TriggerSleepAction(3.0)
    set zoneDayNightEvent = false
    
    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night event completed")
    endif
endfunction

private function OnDayNightEvent takes nothing returns nothing
    local unit updateUnit
    
    if DEBUG then
        call BJDebugMsg("[Zones] Day/Night event triggered")
    endif
    
    // Wait 0.5 seconds for DNE_IsDaytime to update properly
    call TriggerSleepAction(0.5)
    
    // Get unit to update (prefer tracked hero, fallback to player 1's selection)
    if trackedHeroUnit != null and GetUnitTypeId(trackedHeroUnit) != 0 then
        set updateUnit = trackedHeroUnit
    else
        // Try to get Player 1's main hero or first selected unit
        set updateUnit = GroupPickRandomUnit(GetUnitsSelectedAll(Player(0)))
        if updateUnit == null then
            // Fallback: try to find any hero owned by player group
            // This is a placeholder - you may need to adapt based on your hero tracking
            if DEBUG then
                call BJDebugMsg("[Zones] Warning: No unit found for Day/Night update")
            endif
            return
        endif
    endif
    
    // Update current zone/dungeon with new day/night settings
    if currentZone > 0 then
        call HandleZoneEnter(currentZone, false, updateUnit)
    elseif currentDungeon > 0 then
        call HandleZoneEnter(currentDungeon, true, updateUnit)
    endif
    
    // Start delayed flag reset
    call TriggerExecute(CreateTrigger())  // Create temp trigger for delayed action
    call ExecuteFunc("OnDayNightEventDelayed")
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
    
    // Zone 02: Sereneglade
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_02SereneGlade)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[2] = t
    
    // Zone 03: Emberpeak Highlands
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_03EmberpeakHighlands)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[3] = t
    
    // Zone 04: Dragonfire Peaks
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_04DragonfirePeaks)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[4] = t
    
    // Zone 06: Thornwoods
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_06Thornwoods)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[6] = t
    
    // Zone 0601: Stonetooth Camp
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_StonetoothCamp)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[601] = t
    
    // Zone 0602: Bloodtusk Tribe
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_BloodtuskTribe)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[602] = t
    
    // Zone 07: Havenwoods
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_07Havenwoods)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[7] = t
    
    // Zone 08: Bonecrush Stronghold
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_008BonecrushStrongHold)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[8] = t
    
    // Zone 09: Vanguard Vale
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_009VanguardVale)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[9] = t
    
    // Zone 10: Riverbane
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_010RiverBane)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[10] = t
    
    // Zone 11: Deadwoods
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_011Deadwoods)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[11] = t
    
    // Zone 12: Felfire Bastion
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_012FelfireBastion)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[12] = t
    
    // Zone 1201: Felfire Citadel
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_012FelfireBastion)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1201] = t
    
    // Zone 13: Stormhaven
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_013Stormhaven)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[13] = t
    
    // Zone 14: Sirensong
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Sirensong)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[14] = t
    
    // Zone 1401: Moknatha
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Moknatha)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1401] = t
    
    // Zone 1402: Zulgarok
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Zulgarok)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1402] = t
    
    // Zone 1403: Urgmar
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Urgmar)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1403] = t
    
    // Zone 1404: Serpentshore
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_014Serpentshore)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1404] = t
    
    // Zone 15: Zul'Gurak (4 regions)
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak1)
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak2)
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak3)
    call TriggerRegisterEnterRectSimple(t, gg_rct_015ZulGurak4)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[15] = t
    
    // Zone 17: Verdant Plains
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017VerdantPlains)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[17] = t
    
    // Zone 1701: Chimairos Roost
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017Chimaira)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1701] = t
    
    // Zone 1702: Weeping Hollow
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017WeepingHollow)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1702] = t
    
    // Zone 1703: Redwind Pass
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017RedwindPass)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1703] = t
    
    // Zone 1704: xxxSettlement
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017xxxSettlement)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1704] = t
    
    // Zone 1705: VaelAnorath
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_017VaelAnorath)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1705] = t
    
    // Zone 18: Coliseum of Ages
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_018ColiseumOfAges)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[18] = t
    
    // Zone 19: Ghostwalk Ridge
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_019GhostwalkRidge)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[19] = t
    
    // Zone 1901: Ironspine Post
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_IronspinePost)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1901] = t
    
    // Zone 20: Dawnhold
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_Dawnhold)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[20] = t
    
    // Zone 8810: Horde Scout Base
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_HordeScoutBase)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[8810] = t
    
    //=======================================================================
    // DUNGEON ENTER TRIGGERS
    //=======================================================================
    
    // Dungeon 01: Gnoll Hideout
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_Dungeon01Area)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[1] = t
    
    // Dungeon 02: Crypt (3 regions)
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_DungeonCrypt01A)
    call TriggerRegisterEnterRectSimple(t, gg_rct_DungeonCrypt01B)
    call TriggerRegisterEnterRectSimple(t, gg_rct_DungeonCrypt01C)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[2] = t
    
    // Dungeon 03: Wyrmhold Sanctum
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_05WyrmholdSanctum)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[3] = t
    
    // Dungeon 04: Boom Mine
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_BoomBrothersMine)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[4] = t
    
    // Dungeon 05: Firelands
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_016Firelands)
    call TriggerAddCondition(t, Condition(function OnUnitEnterRegion))
    set zoneTriggers[5] = t
    
    //=======================================================================
    // ZONE LEAVE TRIGGERS (for zones with cleanup)
    //=======================================================================
    
    // Dungeon 05: Firelands - Leave trigger for cleanup
    set t = CreateTrigger()
    call TriggerRegisterLeaveRectSimple(t, gg_rct_016Firelands)
    call TriggerAddCondition(t, Condition(function OnUnitLeaveRegion))
    set zoneLeaveTriggers[5] = t
endfunction

private function Init takes nothing returns nothing
    if DEBUG then
        call BJDebugMsg("[Zones] Initializing zone system...")
    endif
    
    // Initialize excluded unit types list (EASY TO EXTEND - just add more lines!)
    set excludedUnitTypes[0] = 'H60H'  // Bag
    set excludedUnitTypes[1] = 'O61E'  // Companions
    set excludedUnitTypes[2] = 'O005'  // Reputations
    set excludedUnitTypes[3] = 'O006'  // Stats
    set excludedUnitTypeCount = 4
    // To add more excluded types, simply:
    // set excludedUnitTypes[2] = 'xxxx'  // Your unit type
    // set excludedUnitTypeCount = 3
    
    // Configure all zones
    call ConfigureZones()
    
    // Register zone regions (triggers)
    call RegisterZoneRegions()
    
    // Set up Day/Night event trigger
    set dayNightEventTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(dayNightEventTrigger, "udg_DNE_DayNightEvent", EQUAL, 1.00)
    call TriggerRegisterVariableEvent(dayNightEventTrigger, "udg_DNE_DayNightEvent", EQUAL, 2.00)
    call TriggerAddAction(dayNightEventTrigger, function OnDayNightEvent)
    
    if DEBUG then
        call BJDebugMsg("[Zones] Zone system initialized!")
        call BJDebugMsg("[Zones] Day/Night event system active")
    endif
endfunction

endlibrary
