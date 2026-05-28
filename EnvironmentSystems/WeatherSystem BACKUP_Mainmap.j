library WeatherSystem initializer Init requires ZonesCore, ZoneEvent, Storm, CloudsSystem, SteamBreathSystem, SnowSystem
//===========================================================================
/*
    WeatherSystem 2.1 - Zone-Based Master Weather Control System

    Author: [Valdemar]

    Description:
    A comprehensive zone-based weather system that manages weather by master zones and subzones:
    
*/ 
//===========================================================================


//===========================================================================
// CONFIGURATION CONSTANTS
//===========================================================================
globals
    // Debug Mode
    private constant boolean DEBUG_MODE         = true
    
    // Weather Types
    private constant string WEATHER_NONE        = "none"
    private constant string WEATHER_RAIN_LIGHT  = "rain_light"
    private constant string WEATHER_RAIN_MEDIUM = "rain_medium"
    private constant string WEATHER_RAIN_HEAVY  = "rain_heavy"
    private constant string WEATHER_SNOW_LIGHT  = "snow_light"
    private constant string WEATHER_SNOW_MEDIUM = "snow_medium"
    private constant string WEATHER_SNOW_HEAVY  = "snow_heavy"
    private constant string WEATHER_STORM       = "storm"
    private constant string WEATHER_WIND        = "wind"
    
    // Weather effect resource rawcodes (configurable)
    private constant integer WEATHER_EFFECT_RAIN_LIGHT   = 'RLlr'
    private constant integer WEATHER_EFFECT_RAIN_MEDIUM  = 'RLhr'
    private constant integer WEATHER_EFFECT_RAIN_HEAVY   = 'RAhr'
    private constant integer WEATHER_EFFECT_SNOW_LIGHT   = 'SNls'
    private constant integer WEATHER_EFFECT_SNOW_MEDIUM  = 'SNhs'
    private constant integer WEATHER_EFFECT_SNOW_HEAVY   = 'SNbs'
    private constant integer WEATHER_EFFECT_WIND         = 'WOlw'

    // Seasons
    private constant string SEASON_SPRING       = "spring"
    private constant string SEASON_SUMMER       = "summer"
    private constant string SEASON_AUTUMN       = "autumn"
    private constant string SEASON_WINTER       = "winter"
    
    // Season Day Ranges (configurable)
    private constant integer SPRING_START       = 0
    private constant integer SPRING_END         = 89
    private constant integer SUMMER_START       = 90
    private constant integer SUMMER_END         = 179
    private constant integer AUTUMN_START       = 180
    private constant integer AUTUMN_END         = 269
    private constant integer WINTER_START       = 270
    private constant integer WINTER_END         = 359
    
    // Weather Duration Ranges (in seconds)
    private constant real RAIN_MIN_DURATION     = 180.0
    private constant real RAIN_MAX_DURATION     = 600.0
    private constant real SNOW_LIGHT_MIN_DURATION = 120.0
    private constant real SNOW_LIGHT_MAX_DURATION = 240.0
    private constant real SNOW_MEDIUM_MIN_DURATION = 180.0
    private constant real SNOW_MEDIUM_MAX_DURATION = 420.0
    private constant real SNOW_HEAVY_MIN_DURATION = 90.0
    private constant real SNOW_HEAVY_MAX_DURATION = 240.0
    private constant real STORM_MIN_DURATION    = 60.0
    private constant real STORM_MAX_DURATION    = 120.0
    private constant real WIND_MIN_DURATION     = 180.0
    private constant real WIND_MAX_DURATION     = 400.0
    
    // Weather Check Intervals (in seconds)
    private constant real WEATHER_CHECK_INTERVAL = 250.0
    private constant real SEASON_CHECK_INTERVAL  = 60.0
    
    // Zone System Settings
    private constant integer MAX_MASTER_ZONES   = 20
    private constant integer MAX_SUBZONES       = 50
    private constant integer MAX_REGIONS        = 100
    
    // Snow System Integration
    private constant real SNOW_WAVE_INTERVAL    = 15.0   // Seconds between waves
    // Snow intensity configuration
    private constant integer SNOW_LIGHT_WAVES    = 5     // Waves for light snow
    private constant integer SNOW_LIGHT_UNITS    = 5     // Units per wave for light snow
    private constant integer SNOW_MEDIUM_WAVES   = 10     // Waves for medium snow
    private constant integer SNOW_MEDIUM_UNITS   = 10    // Units per wave for medium snow
    private constant integer SNOW_HEAVY_WAVES    = 15     // Waves for heavy snow
    private constant integer SNOW_HEAVY_UNITS    = 20    // Units per wave for heavy snow
    
    // Ripple Doodad Configuration
    private constant integer DOODAD_RIPPLES     = 'D023' // Change to your ripple doodad ID
    private constant integer RIPPLES_LIGHT      = 3      // Ripples for rain_light
    private constant integer RIPPLES_MEDIUM     = 6      // Ripples for rain_medium
    private constant integer RIPPLES_HEAVY      = 10     // Ripples for rain_heavy
    private constant real RIPPLE_CHECK_SIZE     = 128.0  // Area size for ripple placement checks
    
    // Ambient Sound Configuration
    // NOTE: Configure these sounds in World Editor by importing sounds and creating variables
    // Or replace with CreateSound() calls in Init function if you want to load sounds at runtime
    private constant integer AMBIENT_SOUND_VOLUME = 127  // Sound volume (0-127)

    /* Sound constants removed - using gg_snd_* variables directly to avoid duplicate definitions
    private sound SOUND_RAIN_LIGHT     = null
    private sound SOUND_RAIN_MEDIUM    = null
    private sound SOUND_RAIN_HEAVY     = null
    private sound SOUND_SNOW_LIGHT     = null
    private sound SOUND_SNOW_MEDIUM    = null
    private sound SOUND_SNOW_HEAVY     = null
    private sound SOUND_WIND           = null
    
    // Reference - WE sound variables used directly in code:
    // gg_snd_Ambient_RainLight
    // gg_snd_Ambient_RainMedium
    // gg_snd_Ambient_RainHeavy
    // gg_snd_Ambient_SnowLight
    // gg_snd_Ambient_SnowMedium
    // gg_snd_Ambient_SnowHeavy
    // gg_snd_WindHeavy
    */
    
    // FPS Optimization Settings
    private boolean FPS_OptimizationEnabled     = false  // Master FPS optimization toggle
    private boolean FPS_CloudsDisabled          = false  // Disable clouds for FPS
    private boolean FPS_RipplesDisabled         = false  // Disable ripples for FPS
    private boolean FPS_ThunderDisabled         = false  // Disable thunder for FPS
    private boolean FPS_SteamDisabled           = false  // Disable steam breath for FPS
    private integer FPS_CloudCountOverride      = 0      // Override cloud count (0 = use default)
endglobals

//===========================================================================
// ZONE DATA STRUCTURES
//===========================================================================
globals
    
    // SubZone Data
    private string array SubZoneName            // Subzone names
    private integer array SubZoneMasterIndex    // Parent master zone index
    private string array SubZoneWeather         // Weather type in subzone
    private integer SubZoneCount                = 0

    // Master Zone Data
    private string array MasterZoneName            // Master zone names
    private string array MasterZoneSeason          // Season for each master zone
    private boolean array MasterZoneThunderEnabled // Thunder enabled per zone
    private boolean array MasterZoneCloudsEnabled  // Clouds enabled per zone
    private boolean array MasterZoneSteamEnabled   // Steam enabled per zone
    private string array MasterZoneWeather         // Current weather type per zone
    private integer array MasterZoneID             // Zone ID for each master zone
    private boolean array MasterZoneSeasonalEnabled // Seasonal weather enabled per zone
    private integer MasterZoneCount                = 0
    
    // Region Data
    private rect array RegionRect               // Region handles
    private integer array RegionZoneIndex       // Master zone index for region
    private integer array RegionSubZoneIndex    // Subzone index (-1 if none)
    private string array RegionWeatherType      // Current weather type
    private weathereffect array RegionWeatherEffect  // Weather effect handle
    private timer array RegionWeatherTimer      // Duration timer
    private sound array RegionRainSound         // Rain sound per region
    private sound array RegionAmbientSound      // Ambient weather sound per region
    private boolean array RegionHasClouds       // Cloud effects active
    private boolean array RegionHasSteam        // Steam breath active
    private boolean array RegionHasThunder      // Thunder active
    private boolean array RegionSpawnsSnow      // Region spawns snow units (manual config)
    private integer array RegionSnowZoneIndex   // SnowSystem zone index (-1 if none)
    private timer array RegionSnowWaveTimer     // Timer for snow wave spawning
    private integer array RegionSnowWaveCount   // Current snow wave count
    private integer array RegionSnowMaxWaves    // Max waves for this region based on intensity
    private integer array RegionSnowUnitsPerWave // Units per wave based on intensity
    private destructable array RegionRipples    // Array of ripple destructables (2D: [regionIndex * 20 + rippleIndex])
    private integer array RegionRippleCount     // Number of ripples in region
    private integer RegionCount                 = 0
    
    // Seasonal State
    private string CurrentSeason                = SEASON_SPRING
    private boolean SeasonalWeatherEnabled      = false
    
    // System Timers
    private timer WeatherCheckTimer             = CreateTimer()
    private timer SeasonCheckTimer              = CreateTimer()
    
    // Zone Thunder Timers
    private timer array ZoneThunderTimer        // Thunder timer per zone
    private integer array ZoneThunderCounter    // Thunder counter per zone
endglobals

//===========================================================================
// UTILITY FUNCTIONS
//===========================================================================

// Debug output
private function Debug takes string msg returns nothing
    if DEBUG_MODE then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[WeatherSystem] " + msg)
    endif
endfunction

// String comparison helper
private function StringEquals takes string s1, string s2 returns boolean
    return s1 == s2
endfunction

//===========================================================================
// REGION RECT TO INDEX LOOKUP
//===========================================================================
// Returns the index of the region whose RegionRect matches the given rect, or -1 if not found
private function FindRegionIndex takes rect whichRect returns integer
    local integer i = 0
    loop
        exitwhen i >= RegionCount
        if RegionRect[i] == whichRect then
            return i
        endif
        set i = i + 1
    endloop
    return -1
endfunction

// Get season based on days passed
private function GetSeasonFromDays takes integer days returns string
    local integer dayOfYear = ModuloInteger(days, 360)
    
    if dayOfYear >= WINTER_START or dayOfYear < SPRING_START then
        return SEASON_WINTER
    elseif dayOfYear >= AUTUMN_START and dayOfYear <= AUTUMN_END then
        return SEASON_AUTUMN
    elseif dayOfYear >= SUMMER_START and dayOfYear <= SUMMER_END then
        return SEASON_SUMMER
    else
        return SEASON_SPRING
    endif
endfunction

// Get weather probabilities based on season and zone
public function GetZoneWeatherChance takes integer zoneIndex, string season, string weatherType returns real
    local real baseChance
    local real zoneChance
    local integer idx = -1
    local integer j = 0
    local ZoneData z = ZonesCore_GetZoneData(zoneIndex)

    // Get seasonal base chance first to determine if weather is appropriate for this season
    if weatherType == WEATHER_RAIN_LIGHT or weatherType == WEATHER_RAIN_MEDIUM or weatherType == WEATHER_RAIN_HEAVY then
        if season == SEASON_SPRING then
            set baseChance = 0.5
        elseif season == SEASON_AUTUMN then
            set baseChance = 0.4
        elseif season == SEASON_SUMMER then
            set baseChance = 0.2
        else
            set baseChance = 0.1
        endif
        
        // Use zone-specific chance if set, otherwise use base
        // Find index of weatherType in z.weatherTypes
        loop
            exitwhen j >= z.weatherTypeCount
            if z.weatherTypes[j] == weatherType then
                set idx = j
                exitwhen true
            endif
            set j = j + 1
        endloop
        if idx != -1 and z.weatherTypeChance[idx] != 0.0 then
            return z.weatherTypeChance[idx]
        endif
        return baseChance
    elseif weatherType == WEATHER_SNOW_LIGHT or weatherType == WEATHER_SNOW_MEDIUM or weatherType == WEATHER_SNOW_HEAVY then
        // Snow is only appropriate in winter and late autumn
        if season == SEASON_WINTER then
            set baseChance = 0.7
        elseif season == SEASON_AUTUMN then
            set baseChance = 0.2
        else
            // No snow in spring/summer - return 0 even if zone has specific chance
            return 0.0
        endif
        // Use zone-specific chance if set, otherwise use base
        // Find index of weatherType in z.weatherTypes
        set idx = -1
        set j = 0
        loop
            exitwhen j >= z.weatherTypeCount
            if z.weatherTypes[j] == weatherType then
                set idx = j
                exitwhen true
            endif
            set j = j + 1
        endloop
        if idx != -1 and z.weatherTypeChance[idx] != 0.0 then
            return z.weatherTypeChance[idx]
        endif
        return baseChance
    elseif weatherType == WEATHER_STORM then
        if season == SEASON_SUMMER then
            set baseChance = 0.3
        elseif season == SEASON_SPRING then
            set baseChance = 0.2
        else
            set baseChance = 0.1
        endif
        // Use zone-specific chance if set, otherwise use base
        // Find index of weatherType in z.weatherTypes
        set idx = -1
        set j = 0
        loop
            exitwhen j >= z.weatherTypeCount
            if z.weatherTypes[j] == weatherType then
                set idx = j
                exitwhen true
            endif
            set j = j + 1
        endloop
        if idx != -1 and z.weatherTypeChance[idx] != 0.0 then
            return z.weatherTypeChance[idx]
        endif
        return baseChance
    elseif weatherType == WEATHER_WIND then
        // Wind is more common in spring and autumn
        if season == SEASON_SPRING then
            set baseChance = 0.4
        elseif season == SEASON_AUTUMN then
            set baseChance = 0.3
        elseif season == SEASON_WINTER then
            set baseChance = 0.2
        else
            set baseChance = 0.15
        endif
        // Use zone-specific chance if set, otherwise use base
        // Find index of weatherType in z.weatherTypes
        set idx = -1
        set j = 0
        loop
            exitwhen j >= z.weatherTypeCount
            if z.weatherTypes[j] == weatherType then
                set idx = j
                exitwhen true
            endif
            set j = j + 1
        endloop
        if idx != -1 and z.weatherTypeChance[idx] != 0.0 then
            return z.weatherTypeChance[idx]
        endif
        return baseChance
    endif
    return 0.0
endfunction



//===========================================================================
// RIPPLE MANAGEMENT (for rain effects)
//===========================================================================

// Check if a point has water terrain type
private function IsPointWaterTerrain takes real x, real y returns boolean
    local integer terrainType = GetTerrainType(x, y)
    // Water terrain types (may vary by tileset):
    // 'Wdro' = Deep Water (Lordaeron), 'Wshw' = Shallow Water
    // Add more terrain types specific to your map's tileset
    return terrainType == 'Wdro' or terrainType == 'Wshw' or terrainType == 'Wdrt' or terrainType == 'Wwtr'
endfunction

// Stop ripples in a region
private function StopRipplesInRegion takes rect whichRect, integer regionIndex returns nothing
    local integer i = 0
    local integer baseIndex
    local destructable ripple
    
    if regionIndex == -1 then
        return
    endif
    
    set baseIndex = regionIndex * 20
    
    // Remove all ripples for this region
    loop
        exitwhen i >= RegionRippleCount[regionIndex]
        set ripple = RegionRipples[baseIndex + i]
        if ripple != null then
            call RemoveDestructable(ripple)
            set RegionRipples[baseIndex + i] = null
        endif
        set i = i + 1
    endloop
    
    if RegionRippleCount[regionIndex] > 0 then
        call Debug("Removed " + I2S(RegionRippleCount[regionIndex]) + " ripples from region")
    endif
    
    set RegionRippleCount[regionIndex] = 0
endfunction

// Start ripples in a region with specified intensity
private function StartRipplesInRegion takes rect whichRect, integer regionIndex, integer rippleCount returns nothing
    local real minX
    local real minY
    local real maxX
    local real maxY
    local real x
    local real y
    local integer attempts = 0
    local integer spawned = 0
    local integer maxAttempts = rippleCount * 10
    local destructable ripple
    local integer rippleIndex
    
    // Skip if FPS optimization disables ripples
    if FPS_RipplesDisabled or FPS_OptimizationEnabled then
        return
    endif
    
    if regionIndex == -1 or whichRect == null then
        return
    endif
    
    // Clear existing ripples first
    call StopRipplesInRegion(whichRect, regionIndex)
    
    set minX = GetRectMinX(whichRect)
    set minY = GetRectMinY(whichRect)
    set maxX = GetRectMaxX(whichRect)
    set maxY = GetRectMaxY(whichRect)
    
    // Spawn ripples only on water terrain
    loop
        exitwhen spawned >= rippleCount or attempts >= maxAttempts
        
        // Generate random position in region
        set x = GetRandomReal(minX + RIPPLE_CHECK_SIZE, maxX - RIPPLE_CHECK_SIZE)
        set y = GetRandomReal(minY + RIPPLE_CHECK_SIZE, maxY - RIPPLE_CHECK_SIZE)
        
        // Check if point has water terrain
        if IsPointWaterTerrain(x, y) then
            // Create ripple destructable
            set ripple = CreateDestructable(DOODAD_RIPPLES, x, y, GetRandomReal(0, 360), 1.0, 0)
            
            if ripple != null then
                // Store in array (use regionIndex * 20 as base offset, max 20 ripples per region)
                set rippleIndex = regionIndex * 20 + spawned
                set RegionRipples[rippleIndex] = ripple
                set spawned = spawned + 1
            endif
        endif
        
        set attempts = attempts + 1
    endloop
    
    set RegionRippleCount[regionIndex] = spawned
    
    if spawned > 0 then
        call Debug("Spawned " + I2S(spawned) + " ripples on water terrain")
    endif
endfunction

//===========================================================================
//===========================================================================

private function EnableCloudsInRegion takes integer regionIndex returns nothing
    // Skip if FPS optimization disables clouds
    if FPS_CloudsDisabled or FPS_OptimizationEnabled then
        return
    endif
    
    if not RegionHasClouds[regionIndex] then
        call SpawnCloudsInRegion(RegionRect[regionIndex], regionIndex)
        set RegionHasClouds[regionIndex] = true
        call Debug("EnableCloudsInRegion: Enabled clouds in regionIndex=" + I2S(regionIndex))
    endif
endfunction

private function DisableCloudsInRegion takes integer regionIndex returns nothing
    if RegionHasClouds[regionIndex] then
        call RemoveCloudsInRegion(regionIndex)
        set RegionHasClouds[regionIndex] = false
        call Debug("DisableCloudsInRegion: Disabled clouds in regionIndex=" + I2S(regionIndex))
    endif
endfunction

//===========================================================================
// STEAM BREATH MANAGEMENT
//===========================================================================

private function EnableSteamBreathInRegion takes integer regionIndex returns nothing
    // Skip if FPS optimization disables steam breath
    if FPS_SteamDisabled or FPS_OptimizationEnabled then
        return
    endif
    
    if not RegionHasSteam[regionIndex] then
        call AttachSteamEffectsInRegion(RegionRect[regionIndex], regionIndex) // From SteamBreath.j
        set RegionHasSteam[regionIndex] = true
        call Debug("EnableSteamBreathInRegion: Enabled steam breath in regionIndex=" + I2S(regionIndex))
    endif
endfunction

private function DisableSteamBreathInRegion takes integer regionIndex returns nothing
    if RegionHasSteam[regionIndex] then
        call RemoveSteamEffectsInRegion(regionIndex) // From SteamBreath.j
        set RegionHasSteam[regionIndex] = false
        call Debug("DisableSteamBreathInRegion: Disabled steam breath in regionIndex=" + I2S(regionIndex))
    endif
endfunction

//===========================================================================
// THUNDER MANAGEMENT (ZONE-BASED)
//===========================================================================

private function ZoneThunderCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer zoneId = 1
    local integer variant = 0
    local integer chance = 0
    local ZoneData z
    local integer currentZone = 0
    // Assume max 100 zones; adjust as needed for your map
    loop
        exitwhen zoneId > 100
        set z = ZonesCore_GetZoneData(zoneId)
        if z != 0 and ZoneThunderTimer[zoneId] == t then
            set ZoneThunderCounter[zoneId] = ZoneThunderCounter[zoneId] + 1
            if ZoneThunderCounter[zoneId] >= 3 then
                
                set ZoneThunderCounter[zoneId] = 0
                // Record current active zone from ZonesCore
                set currentZone = ZonesCore_GetCurrentZone()
                // Only trigger storm imitation if the current zone matches this zone
                if currentZone == zoneId then
                    set chance = GetRandomInt(0, 1)
                    if chance == 1 then
                        set variant = GetRandomInt(1, 3)
                        call Storm_ImitateRandom(variant)
                        call Debug("Thunder triggered by zone: " + z.name + " (zone ID: " + I2S(zoneId) + ", visible only in zone)")
                    endif
                else
                    call Debug("Thunder suppressed for zone: " + z.name + " (zone ID: " + I2S(zoneId) + "), currentZone=" + I2S(currentZone))
                endif
            endif
            exitwhen true
        endif
        set zoneId = zoneId + 1
    endloop
    set t = null
endfunction

private function EnableThunderInZone takes integer zoneId returns nothing
    local ZoneData z = ZonesCore_GetZoneData(zoneId)
    // Skip if FPS optimization disables thunder
    if FPS_ThunderDisabled or FPS_OptimizationEnabled then
        return
    endif
    if z != 0 and z.weatherEnableThunder and ZoneThunderTimer[zoneId] == null then
        set ZoneThunderTimer[zoneId] = CreateTimer()
        call TimerStart(ZoneThunderTimer[zoneId], 2.0, true, function ZoneThunderCallback)
        set ZoneThunderCounter[zoneId] = 0
        call Debug("EnableThunderInZone: Enabled thunder for zone=" + I2S(zoneId) + ", name='" + z.name + "'")
    endif
endfunction

private function DisableThunderInZone takes integer zoneId returns nothing
    if ZoneThunderTimer[zoneId] != null then
        call PauseTimer(ZoneThunderTimer[zoneId])
        call DestroyTimer(ZoneThunderTimer[zoneId])
        set ZoneThunderTimer[zoneId] = null
        set ZoneThunderCounter[zoneId] = 0
        call Debug("DisableThunderInZone: Disabled thunder for zone=" + I2S(zoneId))
    endif
endfunction

//===========================================================================
// SNOW MANAGEMENT (SnowSystem Integration)
//===========================================================================
private function SnowWaveCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    
    // Find which region this timer belongs to
    loop
        exitwhen i >= RegionCount
        if RegionSnowWaveTimer[i] == t then
            set RegionSnowWaveCount[i] = RegionSnowWaveCount[i] + 1
            
            // Create snow wave
            if RegionSnowZoneIndex[i] != -1 then
                call Debug("SnowWaveCallback: Creating snow wave for regionIndex=" + I2S(i) + ", snowZone=" + I2S(RegionSnowZoneIndex[i]) + ", waveCount=" + I2S(RegionSnowWaveCount[i]))
                call CreateRandomSnow(RegionSnowZoneIndex[i])
            else
                call Debug("SnowWaveCallback: No snowZone assigned for regionIndex=" + I2S(i) + ", skipping")
            endif
            
            // Stop after max waves (region-specific)
            if RegionSnowWaveCount[i] >= RegionSnowMaxWaves[i] then
                call PauseTimer(t)
                call DestroyTimer(t)
                set RegionSnowWaveTimer[i] = null
            endif
            
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    set t = null
endfunction


private function StartSnowInRegion takes integer regionIndex, string weatherType returns nothing
    local integer snowZone
    local integer maxWaves
    local integer unitsPerWave
    local integer zoneIndex
    local ZoneData z
    local integer i
    local real totalArea = 0.0
    local real rectArea
    local rect r
    local integer baseUnits
    local integer baseWaves
    local real scale
    local integer totalUnits

    if regionIndex == -1 then
        call Debug("StartSnowInRegion: invalid regionIndex=-1")
        return
    endif

    // Get the zone index for this region
    set zoneIndex = RegionZoneIndex[regionIndex]
    set z = ZonesCore_GetZoneData(zoneIndex)
    if z == 0 then
        call Debug("StartSnowInRegion: could not get ZoneData for regionIndex=" + I2S(regionIndex))
        return
    endif

    // Base values for intensity
    if weatherType == WEATHER_SNOW_LIGHT then
        set baseUnits = SNOW_LIGHT_UNITS
        set baseWaves = SNOW_LIGHT_WAVES
    elseif weatherType == WEATHER_SNOW_MEDIUM then
        set baseUnits = SNOW_MEDIUM_UNITS
        set baseWaves = SNOW_MEDIUM_WAVES
    elseif weatherType == WEATHER_SNOW_HEAVY then
        set baseUnits = SNOW_HEAVY_UNITS
        set baseWaves = SNOW_HEAVY_WAVES
    else
        set baseUnits = SNOW_MEDIUM_UNITS
        set baseWaves = SNOW_MEDIUM_WAVES
    endif

    // Calculate total area of all snowRects in the zone
    set i = 0
    set totalArea = 0.0
    loop
        exitwhen i >= z.weatherSnowRectCount
        set r = z.getWeatherSnowRect(i)
        if r != null then
            set rectArea = (GetRectMaxX(r) - GetRectMinX(r)) * (GetRectMaxY(r) - GetRectMinY(r))
            set totalArea = totalArea + rectArea
        endif
        set i = i + 1
    endloop

    // Use a reference area for scaling (e.g., 32000.0 is a typical region size)
    // You can adjust this value for your map's scale
    set scale = totalArea / 32000.0
    if scale < 0.5 then
        set scale = 0.5 // minimum scaling
    endif

    // Calculate total units and waves
    set totalUnits = R2I(baseUnits * scale)
    set maxWaves = R2I(baseWaves * scale)
    if maxWaves < 1 then
        set maxWaves = 1
    endif
    if totalUnits < 1 then
        set totalUnits = 1
    endif
    set unitsPerWave = totalUnits / maxWaves
    if unitsPerWave < 1 then
        set unitsPerWave = 1
    endif

    // Set up SnowSystem integration
    set snowZone = regionIndex  // Use region index as snow zone index
    set RegionSnowZoneIndex[regionIndex] = snowZone
    set RegionSnowWaveCount[regionIndex] = 0
    set RegionSnowMaxWaves[regionIndex] = maxWaves
    set RegionSnowUnitsPerWave[regionIndex] = unitsPerWave

    // Configure SnowSystem globals
    set udg_SnowIndex = snowZone
    set udg_SnowRegions[snowZone] = RegionRect[regionIndex]
    set udg_SnowAmounts[snowZone] = unitsPerWave

    // Start snow wave timer
    set RegionSnowWaveTimer[regionIndex] = CreateTimer()
    call TimerStart(RegionSnowWaveTimer[regionIndex], SNOW_WAVE_INTERVAL, true, function SnowWaveCallback)
    call Debug("StartSnowInRegion: Started snow in regionIndex=" + I2S(regionIndex) + ", snowZone=" + I2S(snowZone) + ", maxWaves=" + I2S(maxWaves) + ", unitsPerWave=" + I2S(unitsPerWave) + ", totalArea=" + R2S(totalArea))

    // Do not create any snow immediately; let SnowWaveCallback handle gradual spawning
    set RegionSnowWaveCount[regionIndex] = 0
endfunction

private function StopSnowInRegion takes integer regionIndex returns nothing
    local real destroyInterval
    local integer destroyAmount
    local string snowType = RegionWeatherType[regionIndex]

    if regionIndex == -1 then
        return
    endif
    
    // Stop wave timer
    if RegionSnowWaveTimer[regionIndex] != null then
        call PauseTimer(RegionSnowWaveTimer[regionIndex])
        call DestroyTimer(RegionSnowWaveTimer[regionIndex])
        set RegionSnowWaveTimer[regionIndex] = null
        call Debug("StopSnowInRegion: Stopped snow timer for regionIndex=" + I2S(regionIndex))
    endif
    
    // Gradually destroy snow units
    if RegionSnowZoneIndex[regionIndex] != -1 then
        // Choose interval and amount based on snow type
        if snowType == WEATHER_SNOW_LIGHT then
            set destroyInterval = 6.0
            set destroyAmount = 2
        elseif snowType == WEATHER_SNOW_MEDIUM then
            set destroyInterval = 4.0
            set destroyAmount = 5
        elseif snowType == WEATHER_SNOW_HEAVY then
            set destroyInterval = 4.0
            set destroyAmount = 5
        else
            set destroyInterval = 5.0
            set destroyAmount = 5
        endif
        set udg_SnowDestructionZone = RegionSnowZoneIndex[regionIndex]
        call StartGradualDestroyEx(RegionSnowZoneIndex[regionIndex], destroyInterval, destroyAmount)
        set RegionSnowZoneIndex[regionIndex] = -1
    endif
    
    set RegionSnowWaveCount[regionIndex] = 0
    call Debug("StopSnowInRegion: Cleared snow data for regionIndex=" + I2S(regionIndex))
endfunction

//===========================================================================
// REGION WEATHER CONTROL
//===========================================================================

// Stop weather in a specific region
private function StopRegionWeatherInternal takes integer regionIndex returns nothing
    local string oldWeather
    
    if regionIndex == -1 then
        return
    endif
    
    // Store old weather for debug message
    set oldWeather = RegionWeatherType[regionIndex]
    
    // Remove weather effect
    if RegionWeatherEffect[regionIndex] != null then
        call RemoveWeatherEffect(RegionWeatherEffect[regionIndex])
        set RegionWeatherEffect[regionIndex] = null
    endif
    
    // Remove rain sound
    if RegionRainSound[regionIndex] != null then
        call StopSound(RegionRainSound[regionIndex], true, true)
        call KillSoundWhenDone(RegionRainSound[regionIndex])
        set RegionRainSound[regionIndex] = null
    endif
    
    // Remove ambient sound
    if RegionAmbientSound[regionIndex] != null then
        call StopSound(RegionAmbientSound[regionIndex], true, true)
        call KillSoundWhenDone(RegionAmbientSound[regionIndex])
        set RegionAmbientSound[regionIndex] = null
    endif
    
    // Destroy timer
    if RegionWeatherTimer[regionIndex] != null then
        call DestroyTimer(RegionWeatherTimer[regionIndex])
        set RegionWeatherTimer[regionIndex] = null
    endif
    
    // Disable effects
    call DisableCloudsInRegion(regionIndex)
    call DisableSteamBreathInRegion(regionIndex)
    call StopRipplesInRegion(RegionRect[regionIndex], regionIndex)
    
    // Stop snow if active
    if RegionWeatherType[regionIndex] == WEATHER_SNOW_LIGHT or RegionWeatherType[regionIndex] == WEATHER_SNOW_MEDIUM or RegionWeatherType[regionIndex] == WEATHER_SNOW_HEAVY then
        call StopSnowInRegion(regionIndex)
    endif
    
    set RegionWeatherType[regionIndex] = WEATHER_NONE
    
    // Debug message
    if oldWeather != WEATHER_NONE then
        call Debug("Region weather stopped: " + oldWeather)
    endif

    // If the old weather was a storm, also stop thunder for the zone
    if oldWeather == WEATHER_STORM or oldWeather == WEATHER_RAIN_HEAVY then
        // Find the zone index for this region
        if regionIndex >= 0 and regionIndex < RegionCount then
            call DisableThunderInZone(RegionZoneIndex[regionIndex])
        endif
    endif

    // Re-apply current zone effects
    call ZoneEvent_ApplyCurrentZoneEffects()
endfunction

// Timer callback for region weather expiration
private function RegionWeatherExpireCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    
    loop
        exitwhen i >= RegionCount
        if RegionWeatherTimer[i] == t then
            call StopRegionWeatherInternal(i)
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    set t = null
endfunction

// Start weather in a specific region
private function StartRegionWeatherInternal takes integer regionIndex, string weatherType, real duration returns nothing
    local rect r
    local integer zoneIndex
    local ZoneData z
    local string zoneNameStr
    local integer wi
    local integer foundIndex
    local boolean foundIsSnow
    
    if regionIndex == -1 then
        return
    endif
    
    // Stop existing weather
    call StopRegionWeatherInternal(regionIndex)
    
    set r = RegionRect[regionIndex]
    set zoneIndex = RegionZoneIndex[regionIndex]
    set z = ZonesCore_GetZoneData(zoneIndex)

    // Debug: show which rect is actually used for this region and try to map it back to ZoneData
    set zoneNameStr = "null"
    set wi = 0
    set foundIndex = -1
    set foundIsSnow = false
    if z != 0 then
        set zoneNameStr = z.name
    endif
    call Debug("StartRegionWeatherInternal: regionIndex=" + I2S(regionIndex) + ", zoneIndex=" + I2S(zoneIndex) + ", zoneName='" + zoneNameStr + "'")
    if r == null then
        call Debug("StartRegionWeatherInternal: RegionRect is null for regionIndex=" + I2S(regionIndex))
    else
        call Debug("StartRegionWeatherInternal: RegionRect coords: minX=" + R2S(GetRectMinX(r)) + ", minY=" + R2S(GetRectMinY(r)) + ", maxX=" + R2S(GetRectMaxX(r)) + ", maxY=" + R2S(GetRectMaxY(r)))
    endif
    // Attempt to find which ZoneData rect maps to this region rect
    if z != 0 then
        set wi = 0
        loop
            exitwhen wi >= z.weatherRectCount
            if z.getWeatherRect(wi) == r then
                set foundIndex = wi
                set foundIsSnow = false
                exitwhen true
            endif
            set wi = wi + 1
        endloop
        if foundIndex == -1 then
            set wi = 0
            loop
                exitwhen wi >= z.weatherSnowRectCount
                if z.getWeatherSnowRect(wi) == r then
                    set foundIndex = wi
                    set foundIsSnow = true
                    exitwhen true
                endif
                set wi = wi + 1
            endloop
        endif
        if foundIndex != -1 then
            if foundIsSnow then
                call Debug("StartRegionWeatherInternal: matched Zone weatherSnowRect index=" + I2S(foundIndex))
            else
                call Debug("StartRegionWeatherInternal: matched Zone weatherRect index=" + I2S(foundIndex))
            endif
        else
            call Debug("StartRegionWeatherInternal: No matching ZoneData rect found for this region rect")
        endif
    endif
    
    // Create weather effect and ambient sounds
    if weatherType == WEATHER_RAIN_LIGHT then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_RAIN_LIGHT)
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainLight  // was: SOUND_RAIN_LIGHT
        call StartRipplesInRegion(r, regionIndex, RIPPLES_LIGHT)
        // No clouds for rain_light
        call EnableSteamBreathInRegion(regionIndex)
    elseif weatherType == WEATHER_RAIN_MEDIUM then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_RAIN_MEDIUM)
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainMedium  // was: SOUND_RAIN_MEDIUM
        call StartRipplesInRegion(r, regionIndex, RIPPLES_MEDIUM)
        // Enable clouds for rain_medium
        if z != 0 and z.weatherEnableClouds then
            call EnableCloudsInRegion(regionIndex)
        endif
        call EnableSteamBreathInRegion(regionIndex)
    elseif weatherType == WEATHER_RAIN_HEAVY then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_RAIN_HEAVY)
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainHeavy  // was: SOUND_RAIN_HEAVY
        call StartRipplesInRegion(r, regionIndex, RIPPLES_HEAVY)
        // Enable clouds for rain_heavy
        if z != 0 and z.weatherEnableClouds then
            call EnableCloudsInRegion(regionIndex)
        endif
        if z != 0 and z.weatherEnableThunder then
            call EnableThunderInZone(zoneIndex)
        endif
        call EnableSteamBreathInRegion(regionIndex)
    elseif weatherType == WEATHER_SNOW_LIGHT then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_SNOW_LIGHT)
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_SnowLight  // was: SOUND_SNOW_LIGHT
        call StartSnowInRegion(regionIndex, weatherType)
        // No clouds for snow_light
        call EnableSteamBreathInRegion(regionIndex)
    elseif weatherType == WEATHER_SNOW_MEDIUM then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_SNOW_MEDIUM)
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_SnowMedium  // was: SOUND_SNOW_MEDIUM
        call StartSnowInRegion(regionIndex, weatherType)
        // Enable clouds for snow_medium
        if z != 0 and z.weatherEnableClouds then
            call EnableCloudsInRegion(regionIndex)
        endif
        call EnableSteamBreathInRegion(regionIndex)
    elseif weatherType == WEATHER_SNOW_HEAVY then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_SNOW_HEAVY)
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_SnowHeavy  // was: SOUND_SNOW_HEAVY
        call StartSnowInRegion(regionIndex, weatherType)
        // Enable clouds for snow_heavy
        if z != 0 and z.weatherEnableClouds then
            call EnableCloudsInRegion(regionIndex)
        endif
        call EnableSteamBreathInRegion(regionIndex)
    elseif weatherType == WEATHER_STORM then
        // Storm now always includes rain (heavy or medium)
        // Randomly choose rain intensity for storm
        if GetRandomInt(1, 100) <= 70 then
            // 70 perc chance: rain_heavy with storm
            set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_RAIN_HEAVY)
            set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainHeavy
            call StartRipplesInRegion(r, regionIndex, RIPPLES_HEAVY)
        else
        // 30 perc chance: rain_medium with storm
            set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_RAIN_MEDIUM)
            set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainMedium
            call StartRipplesInRegion(r, regionIndex, RIPPLES_MEDIUM)
        endif
        // Enable clouds for storm
        if z != 0 and z.weatherEnableClouds then
            call EnableCloudsInRegion(regionIndex)
        endif
        // Storm has no snow units, only thunder and rain visuals
        if z != 0 and z.weatherEnableThunder then
            call EnableThunderInZone(zoneIndex)
        endif
    elseif weatherType == WEATHER_WIND then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, WEATHER_EFFECT_WIND)
        set RegionAmbientSound[regionIndex] = gg_snd_WindHeavy  // was: SOUND_WIND
        // No clouds for wind
    endif
    
    if RegionWeatherEffect[regionIndex] != null then
        set RegionWeatherType[regionIndex] = weatherType
        
        // Enable weather effect
        call EnableWeatherEffect(RegionWeatherEffect[regionIndex], true)
        
        // Play ambient sound if configured
        if RegionAmbientSound[regionIndex] != null then
            call SetSoundVolume(RegionAmbientSound[regionIndex], AMBIENT_SOUND_VOLUME)
            call StartSound(RegionAmbientSound[regionIndex])
        endif
        
        // Note: Cloud enabling is now handled per weather type above
        
        // Set duration timer
        if duration > 0.0 then
            set RegionWeatherTimer[regionIndex] = CreateTimer()
            call TimerStart(RegionWeatherTimer[regionIndex], duration, false, function RegionWeatherExpireCallback)
        endif
    else
        // Debug: failed to create weather effect for region
        call Debug("StartRegionWeatherInternal: Failed to create weather effect for regionIndex=" + I2S(regionIndex) + ", weatherType='" + weatherType + "'")
    endif
endfunction

// Register a rect into the WeatherSystem Region arrays if not already present
private function RegisterRegionRectInternal takes rect r, integer zoneIndex, integer subZoneIndex returns nothing
    local integer idx
    if r == null then
        return
    endif
    // Skip if already registered
    set idx = FindRegionIndex(r)
    if idx != -1 then
        return
    endif
    // Register new region
    set RegionRect[RegionCount] = r
    set RegionZoneIndex[RegionCount] = zoneIndex
    set RegionSubZoneIndex[RegionCount] = subZoneIndex
    set RegionWeatherType[RegionCount] = WEATHER_NONE
    set RegionWeatherEffect[RegionCount] = null
    set RegionWeatherTimer[RegionCount] = null
    set RegionRainSound[RegionCount] = null
    set RegionAmbientSound[RegionCount] = null
    set RegionHasClouds[RegionCount] = false
    set RegionHasSteam[RegionCount] = false
    set RegionHasThunder[RegionCount] = false
    set RegionSnowZoneIndex[RegionCount] = -1
    set RegionSnowWaveTimer[RegionCount] = null
    set RegionSnowWaveCount[RegionCount] = 0
    set RegionSnowMaxWaves[RegionCount] = 0
    set RegionSnowUnitsPerWave[RegionCount] = 0
    set RegionRippleCount[RegionCount] = 0
    // Debug: report new region registration
    call Debug("RegisterRegionRectInternal: Registered regionIndex=" + I2S(RegionCount) + ", zoneIndex=" + I2S(zoneIndex) + ", subZoneIndex=" + I2S(subZoneIndex) + ", rect=" + R2S(GetRectMinX(r)) + "," + R2S(GetRectMinY(r)) + " - " + R2S(GetRectMaxX(r)) + "," + R2S(GetRectMaxY(r)))
    set RegionCount = RegionCount + 1
endfunction

// Scan ZonesCore and register all weather rects into RegionRect[] so weather can be applied
private function RegisterAllZoneRects takes nothing returns nothing
    local integer zoneId = 1
    local ZoneData z
    local integer i
    // Scan an upper bound of possible zone IDs (adjust if you have more)
    loop
        exitwhen zoneId > 2000
        set z = ZonesCore_GetZoneData(zoneId)
        if z != 0 then
            // register normal weather rects
            set i = 0
            loop
                exitwhen i >= z.weatherRectCount
                call RegisterRegionRectInternal(z.getWeatherRect(i), zoneId, -1)
                set i = i + 1
            endloop
            // register snow rects
            set i = 0
            loop
                exitwhen i >= z.weatherSnowRectCount
                call RegisterRegionRectInternal(z.getWeatherSnowRect(i), zoneId, -1)
                set i = i + 1
            endloop
        endif
        set zoneId = zoneId + 1
    endloop
    call Debug("WeatherSystem: Registered " + I2S(RegionCount) + " region rects from ZoneData")
endfunction

//===========================================================================
// ZONE WEATHER CONTROL
//===========================================================================

// Set weather for all regions in a zone

private function SetZoneWeatherInternal takes integer zoneIndex, string weatherType, real duration returns nothing
    local ZoneData z
    local integer i
    local rect r
    local integer regionIndex = -1
    local boolean isSnow
    local integer j
    local string equalsStr
    // Validate zone id and ZoneData
    if zoneIndex <= 0 then
        return
    endif
    set z = ZonesCore_GetZoneData(zoneIndex)
    if z == 0 then
        return
    endif
    set isSnow = (weatherType == WEATHER_SNOW_LIGHT or weatherType == WEATHER_SNOW_MEDIUM or weatherType == WEATHER_SNOW_HEAVY)
    // Apply weather to correct rects only, using FindRegionIndex for each rect
    if isSnow then
        // Only apply to weatherSnowRect
        set i = 0
        loop
            exitwhen i >= z.weatherSnowRectCount
            set r = z.getWeatherSnowRect(i)
            // Debug: show each snow rect and mapping to regionIndex
            if r == null then
                call Debug("SetZoneWeatherInternal: zone=" + I2S(zoneIndex) + ", snowRect index=" + I2S(i) + " is null")
            else
                set regionIndex = FindRegionIndex(r)
                call Debug("SetZoneWeatherInternal: zone=" + I2S(zoneIndex) + ", snowRect index=" + I2S(i) + ", regionIndex=" + I2S(regionIndex))
            endif
            if r != null then
                if regionIndex == -1 then
                    set regionIndex = FindRegionIndex(r)
                endif
                if regionIndex != -1 then
                    call StartRegionWeatherInternal(regionIndex, weatherType, duration)
                endif
            endif
            set i = i + 1
        endloop
    else
        // Apply to all weatherRects
        set i = 0
        loop
            exitwhen i >= z.weatherRectCount
            set r = z.getWeatherRect(i)
            // Debug: show each rect and mapping to regionIndex
            if r == null then
                call Debug("SetZoneWeatherInternal: zone=" + I2S(zoneIndex) + ", rect index=" + I2S(i) + " is null")
            else
                set regionIndex = FindRegionIndex(r)
                call Debug("SetZoneWeatherInternal: zone=" + I2S(zoneIndex) + ", rect index=" + I2S(i) + ", regionIndex=" + I2S(regionIndex))
                            if regionIndex == -1 then
                                // Show the rect coords we attempted to map
                                call Debug("SetZoneWeatherInternal: rect coords minX=" + R2S(GetRectMinX(r)) + ", minY=" + R2S(GetRectMinY(r)) + ", maxX=" + R2S(GetRectMaxX(r)) + ", maxY=" + R2S(GetRectMaxY(r)))
                                // Show registered RegionRect list to diagnose mismatch
                                call Debug("SetZoneWeatherInternal: Registered RegionCount=" + I2S(RegionCount))
                                set j = 0
                                loop
                                    exitwhen j >= RegionCount
                                    if RegionRect[j] == null then
                                        call Debug("  RegionRect[" + I2S(j) + "] = null")
                                    else
                                        set equalsStr = "false"
                                        if RegionRect[j] == r then
                                            set equalsStr = "true"
                                        endif
                                        call Debug("  RegionRect[" + I2S(j) + "] coords minX=" + R2S(GetRectMinX(RegionRect[j])) + ", minY=" + R2S(GetRectMinY(RegionRect[j])) + ", maxX=" + R2S(GetRectMaxX(RegionRect[j])) + ", maxY=" + R2S(GetRectMaxY(RegionRect[j])) + ", equalsTarget=" + equalsStr)
                                    endif
                                    set j = j + 1
                                endloop
                            endif
                            if regionIndex == -1 then
                                call Debug("SetZoneWeatherInternal: snowRect coords minX=" + R2S(GetRectMinX(r)) + ", minY=" + R2S(GetRectMinY(r)) + ", maxX=" + R2S(GetRectMaxX(r)) + ", maxY=" + R2S(GetRectMaxY(r)))
                                call Debug("SetZoneWeatherInternal: Registered RegionCount=" + I2S(RegionCount))
                                set j = 0
                                loop
                                    exitwhen j >= RegionCount
                                    if RegionRect[j] == null then
                                        call Debug("  RegionRect[" + I2S(j) + "] = null")
                                    else
                                        set equalsStr = "false"
                                        if RegionRect[j] == r then
                                            set equalsStr = "true"
                                        endif
                                        call Debug("  RegionRect[" + I2S(j) + "] coords minX=" + R2S(GetRectMinX(RegionRect[j])) + ", minY=" + R2S(GetRectMinY(RegionRect[j])) + ", maxX=" + R2S(GetRectMaxX(RegionRect[j])) + ", maxY=" + R2S(GetRectMaxY(RegionRect[j])) + ", equalsTarget=" + equalsStr)
                                    endif
                                    set j = j + 1
                                endloop
                            endif
            endif
            if r != null then
                if regionIndex == -1 then
                    set regionIndex = FindRegionIndex(r)
                endif
                if regionIndex != -1 then
                    call StartRegionWeatherInternal(regionIndex, weatherType, duration)
                endif
            endif
            set i = i + 1
        endloop
    endif
    call Debug("Zone '" + z.name + "' weather set to: " + weatherType)

    // Set the current weather state in ZoneData
    if z != 0 then
        call z.SetWeatherState(weatherType)
    endif
endfunction

// Stop weather in all regions of a zone

private function StopZoneWeatherInternal takes integer zoneIndex returns nothing
    local ZoneData z
    local integer i
    local rect r
    if zoneIndex <= 0 then
        return
    endif
    set z = ZonesCore_GetZoneData(zoneIndex)
    if z == 0 then
        return
    endif
    // Stop in all snow rects
    set i = 0
    loop
        exitwhen i >= z.weatherSnowRectCount
        set r = z.getWeatherSnowRect(i)
        if r != null then
            call StopRegionWeatherInternal(FindRegionIndex(r))
        endif
        set i = i + 1
    endloop
    // Stop in all regular weather rects
    set i = 0
    loop
        exitwhen i >= z.weatherRectCount
        set r = z.getWeatherRect(i)
        if r != null then
            call StopRegionWeatherInternal(FindRegionIndex(r))
        endif
        set i = i + 1
    endloop
    // Disable zone thunder
    call DisableThunderInZone(zoneIndex)
    // Debug message
    call Debug("Zone '" + z.name + "' weather stopped")

    // Set the current weather state in ZoneData to "none"
    if z != 0 then
        call z.SetWeatherState(WEATHER_NONE)
    endif

    // Re-apply zone effects to clear any residual effects
    call ZoneEvent_ApplyCurrentZoneEffects()
endfunction

//===========================================================================
// SEASONAL WEATHER SYSTEM
//===========================================================================

// Update season based on days passed
private function UpdateSeasonInternal takes nothing returns nothing
    local string newSeason = GetSeasonFromDays(udg_DaysPassed)
    
    if newSeason != CurrentSeason then
        set CurrentSeason = newSeason
        call Debug("Season changed to: " + newSeason)
    endif
endfunction

// Check and trigger weather changes for a zone based on season
private function ZoneSeasonalWeatherCheck takes integer zoneIndex returns nothing
    local real roll
    local string season
    local string weatherType
    local real duration
    local real snowChance
    local real rainChance
    local real stormChance
    local real windChance
    local real totalChance = 0.0
    local real accumulated = 0.0
    local real rainRoll
    local real snowRoll
    local integer i
    local string wtype
    local real array chances
    local integer chosen = -1
    local ZoneData z
    // Validate zone
    if zoneIndex <= 0 then
        return
    endif
    set z = ZonesCore_GetZoneData(zoneIndex)
    if z == 0 then
        return
    endif

    // Respect weatherAllowed flag
    if not z.weatherAllowed then
        return
    endif

    // Use zone's custom season if set, otherwise use global
    if z.weatherSeason != "" and z.weatherSeason != "auto" then
        set season = z.weatherSeason
    else
        set season = GetSeasonFromDays(udg_DaysPassed)
    endif

    // Skip if zone already has weather
    // Optionally: track current weather in z if needed
    // if z.currentWeather != WEATHER_NONE then
    //     return
    // endif

    // Gather allowed weather types and their chances
    set i = 0
    loop
        exitwhen i >= z.weatherTypeCount
        set wtype = z.getWeatherType(i)
        set chances[i] = GetZoneWeatherChance(zoneIndex, season, wtype)
        set totalChance = totalChance + chances[i]
        set i = i + 1
    endloop
    if totalChance <= 0.0 then
        return
    endif
    set roll = GetRandomReal(0.0, totalChance)
    set accumulated = 0.0
    set i = 0
    loop
        exitwhen i >= z.weatherTypeCount
        set accumulated = accumulated + chances[i]
        if roll < accumulated then
            set chosen = i
            exitwhen true
        endif
        set i = i + 1
    endloop
    if chosen == -1 then
        return
    endif
    set wtype = z.getWeatherType(chosen)
    // Set duration based on type
    if wtype == WEATHER_RAIN_LIGHT then
        set duration = GetRandomReal(RAIN_MIN_DURATION, RAIN_MAX_DURATION)
    elseif wtype == WEATHER_RAIN_MEDIUM then
        set duration = GetRandomReal(RAIN_MIN_DURATION, RAIN_MAX_DURATION)
    elseif wtype == WEATHER_RAIN_HEAVY then
        set duration = GetRandomReal(RAIN_MIN_DURATION, RAIN_MAX_DURATION)
    elseif wtype == WEATHER_SNOW_LIGHT then
        set duration = GetRandomReal(SNOW_LIGHT_MIN_DURATION, SNOW_LIGHT_MAX_DURATION)
    elseif wtype == WEATHER_SNOW_MEDIUM then
        set duration = GetRandomReal(SNOW_MEDIUM_MIN_DURATION, SNOW_MEDIUM_MAX_DURATION)
    elseif wtype == WEATHER_SNOW_HEAVY then
        set duration = GetRandomReal(SNOW_HEAVY_MIN_DURATION, SNOW_HEAVY_MAX_DURATION)
    elseif wtype == WEATHER_STORM then
        set duration = GetRandomReal(STORM_MIN_DURATION, STORM_MAX_DURATION)
    elseif wtype == WEATHER_WIND then
        set duration = GetRandomReal(WIND_MIN_DURATION, WIND_MAX_DURATION)
    else
        set duration = 0.0
    endif
    call SetZoneWeatherInternal(zoneIndex, wtype, duration)
endfunction

// Main seasonal weather check for all zones

private function SeasonalWeatherCheck takes nothing returns nothing
    local integer zoneId = 1
    local ZoneData z
    if not SeasonalWeatherEnabled then
        return
    endif
    // Update season
    call UpdateSeasonInternal()
    // Check each valid zone for weather changes (assume max 100 zones, adjust as needed)
    loop
        exitwhen zoneId > 100
        set z = ZonesCore_GetZoneData(zoneId)
        if z != 0 then
            call ZoneSeasonalWeatherCheck(zoneId)
        endif
        set zoneId = zoneId + 1
    endloop
endfunction

private function SeasonCheckCallback takes nothing returns nothing
    call UpdateSeasonInternal()
endfunction

private function WeatherCheckCallback takes nothing returns nothing
    call SeasonalWeatherCheck()
endfunction

//===========================================================================
// ZONE MANAGEMENT FUNCTIONS
//===========================================================================


//===========================================================================
// PUBLIC API FUNCTIONS
//===========================================================================

//===========================================================================
// FPS OPTIMIZATION API
//===========================================================================

// Enable/disable FPS optimization mode (disables all optional effects)
public function SetFPSOptimization takes boolean enable returns nothing
    set FPS_OptimizationEnabled = enable
    
    if enable then
        call Debug("FPS Optimization: Enabled (all optional effects disabled)")
    else
        call Debug("FPS Optimization: Disabled")
    endif
endfunction

// Disable/enable clouds for FPS (individual control)
public function SetCloudsEnabled takes boolean enable returns nothing
    local integer i = 0
    
    set FPS_CloudsDisabled = not enable
    
    if not enable then
        // Remove all existing clouds from all regions
        loop
            exitwhen i >= RegionCount
            if RegionHasClouds[i] then
                call RemoveCloudsInRegion(i)
                set RegionHasClouds[i] = false
            endif
            set i = i + 1
        endloop
        call Debug("Clouds: Disabled for FPS")
    else
        call Debug("Clouds: Enabled")
    endif
endfunction

// Disable/enable ripples for FPS
public function SetRipplesEnabled takes boolean enable returns nothing
    set FPS_RipplesDisabled = not enable
    
    if enable then
        call Debug("Ripples: Enabled")
    else
        call Debug("Ripples: Disabled for FPS")
    endif
endfunction

// Disable/enable thunder for FPS
public function SetThunderEnabled takes boolean enable returns nothing
    local integer i = 0
    
    set FPS_ThunderDisabled = not enable
    
    if not enable then
        // Disable thunder in all zones
        loop
            exitwhen i >= MasterZoneCount
            call DisableThunderInZone(i)
            set i = i + 1
        endloop
        call Debug("Thunder: Disabled for FPS")
    else
        call Debug("Thunder: Enabled")
    endif
endfunction

// Disable/enable steam breath for FPS
public function SetSteamBreathEnabled takes boolean enable returns nothing
    local integer i = 0

    set FPS_SteamDisabled = not enable
    
    if not enable then
        // Remove steam effects from all regions
        loop
            exitwhen i >= RegionCount
            call DisableSteamBreathInRegion(i)
            set i = i + 1
        endloop
        call Debug("Steam Breath: Disabled for FPS")
    else
        call Debug("Steam Breath: Enabled")
    endif
endfunction

// Override cloud count (0 = use default, lower values = better FPS)
public function SetCloudCount takes integer count returns nothing
    set FPS_CloudCountOverride = count
    
    if count > 0 then
        call Debug("Cloud count override: " + I2S(count))
    else
        call Debug("Cloud count: Using default")
    endif
endfunction


//===========================================================================
// NEW DATA-DRIVEN WEATHER API (ZonesCore/ZoneData only)
//===========================================================================

// Set weather for a zone by zoneId
public function SetZoneWeatherById takes integer zoneId, string weatherType, real duration returns nothing
    call SetZoneWeatherInternal(zoneId, weatherType, duration)
    call ZoneEvent_ApplyCurrentZoneEffects()
endfunction

// Stop weather in a zone by zoneId
public function StopZoneWeatherById takes integer zoneId returns nothing
    call StopZoneWeatherInternal(zoneId)
    call ZoneEvent_ApplyCurrentZoneEffects()
endfunction

// Set weather for a zone by zone name (e.g., "TwilightGrove")
public function SetZoneWeather takes string zoneName, string weatherType, real duration returns nothing
    local integer zoneId = ZonesCore_GetZoneIdByName(zoneName)
    local string resolvedName
    local string allowedStr
    local ZoneData z

    if zoneId != 0 then
        set resolvedName = ZonesCore_Zones_GetZoneName(zoneId)
        set z = ZonesCore_GetZoneData(zoneId)

        if z.weatherAllowed then
            set allowedStr = "true"
        else
            set allowedStr = "false"
        endif
        call Debug("SetZoneWeather: Requested '" + zoneName + "', resolved zoneId=" + I2S(zoneId) + ", resolvedName='" + resolvedName + "', weatherType='" + weatherType + "', duration=" + R2S(duration))
        call Debug("SetZoneWeather: ZoneData: environmentType='" + z.environmentType + "', weatherSeason='" + z.weatherSeason + "', weatherAllowed=" + allowedStr + ", weatherTypeCount=" + I2S(z.weatherTypeCount))
        call SetZoneWeatherById(zoneId, weatherType, duration)
    else
        call Debug("SetZoneWeather: Zone name not found: " + zoneName)
    endif
endfunction

// Set weather for a region by region index
public function SetRegionWeatherByIndex takes integer regionIndex, string weatherType, real duration returns nothing
    call StartRegionWeatherInternal(regionIndex, weatherType, duration)
    call ZoneEvent_ApplyCurrentZoneEffects()
endfunction

// Stop weather in a region by region index
public function StopRegionWeatherByIndex takes integer regionIndex returns nothing
    call StopRegionWeatherInternal(regionIndex)
    call ZoneEvent_ApplyCurrentZoneEffects()
endfunction

// Enable/disable seasonal weather globally
public function EnableSeasonalWeather takes boolean enable returns nothing
    set SeasonalWeatherEnabled = enable
    if enable then
        call TimerStart(WeatherCheckTimer, WEATHER_CHECK_INTERVAL, true, function WeatherCheckCallback)
        call TimerStart(SeasonCheckTimer, SEASON_CHECK_INTERVAL, true, function SeasonCheckCallback)
        call Debug("Seasonal weather enabled")
    else
        call PauseTimer(WeatherCheckTimer)
        call PauseTimer(SeasonCheckTimer)
        call Debug("Seasonal weather disabled")
    endif
endfunction

// Query: Get region weather by region index
public function GetRegionWeatherByIndex takes integer regionIndex returns string
    if regionIndex >= 0 and regionIndex < RegionCount then
        return RegionWeatherType[regionIndex]
    endif
    return WEATHER_NONE
endfunction

// Query: Get current season
public function GetCurrentSeason takes nothing returns string
    return CurrentSeason
endfunction

//========================================
// Testing: Chat command to spawn random
// weather for 60s in a named zone
// Usage (chat): ws <ZoneName>
// Example: ws Sereneglade
//========================================

private function Test_SpawnRandomWeatherInZone takes string zoneName returns nothing
    local integer zoneId = ZonesCore_GetZoneIdByName(zoneName)
    local string weatherType = WEATHER_NONE
    local integer choice = 0

    if zoneId == 0 then
        call Debug("Test_SpawnRandomWeatherInZone: zone not found: " + zoneName)
        return
    endif

    // Pick a random weather type from a simple list
    set choice = GetRandomInt(0, 7)
    if choice == 0 then
        set weatherType = WEATHER_RAIN_LIGHT
    elseif choice == 1 then
        set weatherType = WEATHER_RAIN_MEDIUM
    elseif choice == 2 then
        set weatherType = WEATHER_RAIN_HEAVY
    elseif choice == 3 then
        set weatherType = WEATHER_SNOW_LIGHT
    elseif choice == 4 then
        set weatherType = WEATHER_SNOW_MEDIUM
    elseif choice == 5 then
        set weatherType = WEATHER_SNOW_HEAVY
    elseif choice == 6 then
        set weatherType = WEATHER_STORM
    else
        set weatherType = WEATHER_WIND
    endif

    // Duration: 60 seconds for testing
    call Debug("Test: Setting zone '" + zoneName + "' weather to '" + weatherType + "' for 60s")
    call SetZoneWeather(zoneName, weatherType, 60.0)
endfunction


private function OnPlayerChat_WS takes nothing returns nothing
    local string msg = GetEventPlayerChatString()
    local integer len = StringLength(msg)
    local string zoneName
    local string prefix

    call Debug("OnPlayerChat_WS: player='" + GetPlayerName(GetTriggerPlayer()) + "' msg='" + msg + "'")

    // Expecting: "ws <ZoneName>" (with space) - check prefix (case variations)
    if len < 3 then
        return
    endif

    set prefix = SubString(msg, 0, 3)
    if prefix != "ws " and prefix != "Ws " and prefix != "wS " and prefix != "WS " then
        return
    endif

    // Extract substring after the "ws " prefix (index 3 to end)
    set zoneName = SubString(msg, 3, len)
    call Test_SpawnRandomWeatherInZone(zoneName)
endfunction

// Register chat command listener for all players
private function RegisterWeatherTestChatCommand takes nothing returns nothing
    local trigger t = CreateTrigger()
    local integer i = 0
    
    loop
        exitwhen i >= 16
        // Register for all chat; handler will filter messages starting with 'ws '
        call TriggerRegisterPlayerChatEvent(t, Player(i), "", false)
        set i = i + 1
    endloop
    call TriggerAddAction(t, function OnPlayerChat_WS)
    call Debug("RegisterWeatherTestChatCommand: Registered 'ws' chat command for players 0-15")
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    // Initialize season
    call UpdateSeasonInternal()
    // Register any ZoneData weather rects into the Region list so weather can be applied
    call RegisterAllZoneRects()
    // Register test chat command for weather spawning
    call RegisterWeatherTestChatCommand()
    call Debug("Zone-Based Weather System initialized (data-driven)")
endfunction


endlibrary
