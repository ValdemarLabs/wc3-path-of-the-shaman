library WeatherSystem initializer Init requires Storm, CloudsSystem, SteamBreathSystem, SnowSystem
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
    private constant boolean DEBUG_MODE         = false
    
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
    private constant integer SNOW_LIGHT_WAVES    = 3     // Waves for light snow
    private constant integer SNOW_LIGHT_UNITS    = 30    // Units per wave for light snow
    private constant integer SNOW_MEDIUM_WAVES   = 6     // Waves for medium snow
    private constant integer SNOW_MEDIUM_UNITS   = 60    // Units per wave for medium snow
    private constant integer SNOW_HEAVY_WAVES    = 8     // Waves for heavy snow
    private constant integer SNOW_HEAVY_UNITS    = 90    // Units per wave for heavy snow
    
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
    // Master Zone Data
    private string array MasterZoneName         // Zone names
    private integer array MasterZoneID         // Zone ID (udg_ZoneCurrent value, 0 if not set)
    private string array MasterZoneWeather      // Current weather in zone
    private string array MasterZoneSeason       // Season for zone ("auto" or specific)
    private boolean array MasterZoneSeasonalEnabled  // Seasonal weather toggle
    private boolean array MasterZoneThunderEnabled   // Thunder toggle per zone
    private boolean array MasterZoneCloudsEnabled    // Clouds toggle per zone
    private boolean array MasterZoneSteamEnabled     // Steam breath toggle per zone
    private real array MasterZoneRainChance     // Rain probability per zone
    private real array MasterZoneSnowChance     // Snow probability per zone
    private real array MasterZoneStormChance    // Storm probability per zone
    private real array MasterZoneWindChance     // Wind probability per zone
    // Allowed Weather Types per Zone
    private boolean array ZoneAllowsRain        // Zone can have rain weather
    private boolean array ZoneAllowsSnow        // Zone can have snow weather (visual)
    private boolean array ZoneAllowsStorm       // Zone can have storm weather
    private boolean array ZoneAllowsWind        // Zone can have wind weather
    private integer MasterZoneCount             = 0
    
    // SubZone Data
    private string array SubZoneName            // Subzone names
    private integer array SubZoneMasterIndex    // Parent master zone index
    private string array SubZoneWeather         // Weather type in subzone
    private integer SubZoneCount                = 0
    
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
private function GetZoneWeatherChance takes integer zoneIndex, string season, string weatherType returns real
    local real baseChance
    local real zoneChance
    
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
        
        // Apply zone-specific chance if set, otherwise use base
        if MasterZoneRainChance[zoneIndex] > 0.0 then
            return MasterZoneRainChance[zoneIndex]
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
        
        // Apply zone-specific chance only if season allows snow
        if MasterZoneSnowChance[zoneIndex] > 0.0 then
            return MasterZoneSnowChance[zoneIndex]
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
        
        // Apply zone-specific chance if set, otherwise use base
        if MasterZoneStormChance[zoneIndex] > 0.0 then
            return MasterZoneStormChance[zoneIndex]
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
        
        // Apply zone-specific chance if set, otherwise use base
        if MasterZoneWindChance[zoneIndex] > 0.0 then
            return MasterZoneWindChance[zoneIndex]
        endif
        return baseChance
    endif
    
    return 0.0
endfunction

//===========================================================================
// ZONE FINDER FUNCTIONS
//===========================================================================

// Find master zone index by name
private function FindMasterZoneIndex takes string zoneName returns integer
    local integer i = 0
    
    loop
        exitwhen i >= MasterZoneCount
        if StringEquals(MasterZoneName[i], zoneName) then
            return i
        endif
        set i = i + 1
    endloop
    
    return -1
endfunction

// Find subzone index by name
private function FindSubZoneIndex takes string subZoneName returns integer
    local integer i = 0
    
    loop
        exitwhen i >= SubZoneCount
        if StringEquals(SubZoneName[i], subZoneName) then
            return i
        endif
        set i = i + 1
    endloop
    
    return -1
endfunction

// Find region index by rect handle
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

// Get master zone index for a region
private function GetRegionMasterZone takes rect whichRect returns integer
    local integer index = FindRegionIndex(whichRect)
    
    if index != -1 then
        return RegionZoneIndex[index]
    endif
    
    return -1
endfunction

// Get effective season for a zone
private function GetZoneSeason takes integer zoneIndex returns string
    if StringEquals(MasterZoneSeason[zoneIndex], "auto") then
        return CurrentSeason
    else
        return MasterZoneSeason[zoneIndex]
    endif
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
    endif
endfunction

private function DisableCloudsInRegion takes integer regionIndex returns nothing
    if RegionHasClouds[regionIndex] then
        call RemoveCloudsInRegion(regionIndex)
        set RegionHasClouds[regionIndex] = false
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
    endif
endfunction

private function DisableSteamBreathInRegion takes integer regionIndex returns nothing
    if RegionHasSteam[regionIndex] then
        call RemoveSteamEffectsInRegion(regionIndex) // From SteamBreath.j
        set RegionHasSteam[regionIndex] = false
    endif
endfunction

//===========================================================================
// THUNDER MANAGEMENT (ZONE-BASED)
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
                call CreateRandomSnow(RegionSnowZoneIndex[i])
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

private function ZoneThunderCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    local integer chance = 0
    local integer zoneId = 0
    
    // Find which zone this timer belongs to
    loop
        exitwhen i >= MasterZoneCount
        if ZoneThunderTimer[i] == t then
            set ZoneThunderCounter[i] = ZoneThunderCounter[i] + 1
            
            if ZoneThunderCounter[i] >= 3 then
                set chance = GetRandomInt(1, 3)
                set ZoneThunderCounter[i] = 0
                
                if chance == 1 or chance == 2 then
                    // Get zone ID for this zone (0 if not set = global)
                    set zoneId = MasterZoneID[i]
                    
                    // Storm effects now only visible to players in the zone
                    call Storm_ImitateRandomZone(GetRandomInt(1, Storm_VAR_COUNT), zoneId)
                    
                    if zoneId > 0 then
                        call Debug("Thunder triggered by zone: " + MasterZoneName[i] + " (zone ID: " + I2S(zoneId) + ", visible only in zone)")
                    else
                        call Debug("Thunder triggered by zone: " + MasterZoneName[i] + " (global, no zone ID set)")
                    endif
                endif
            endif
            
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    set t = null
endfunction

private function EnableThunderInZone takes integer zoneIndex returns nothing
    // Skip if FPS optimization disables thunder
    if FPS_ThunderDisabled or FPS_OptimizationEnabled then
        return
    endif
    
    if MasterZoneThunderEnabled[zoneIndex] and ZoneThunderTimer[zoneIndex] == null then
        set ZoneThunderTimer[zoneIndex] = CreateTimer()
        call TimerStart(ZoneThunderTimer[zoneIndex], 15.0, true, function ZoneThunderCallback)
        set ZoneThunderCounter[zoneIndex] = 0
    endif
endfunction

private function DisableThunderInZone takes integer zoneIndex returns nothing
    if ZoneThunderTimer[zoneIndex] != null then
        call PauseTimer(ZoneThunderTimer[zoneIndex])
        call DestroyTimer(ZoneThunderTimer[zoneIndex])
        set ZoneThunderTimer[zoneIndex] = null
        set ZoneThunderCounter[zoneIndex] = 0
    endif
endfunction

//===========================================================================
// SNOW MANAGEMENT (SnowSystem Integration)
//===========================================================================

private function StartSnowInRegion takes integer regionIndex, string weatherType returns nothing
    local integer snowZone
    local integer maxWaves
    local integer unitsPerWave
    
    if regionIndex == -1 then
        return
    endif
    
    // Only spawn snow units if region is configured for snow spawning
    if not RegionSpawnsSnow[regionIndex] then
        return
    endif
    
    // Configure snow intensity based on weather type
    if weatherType == WEATHER_SNOW_LIGHT then
        set maxWaves = SNOW_LIGHT_WAVES
        set unitsPerWave = SNOW_LIGHT_UNITS
    elseif weatherType == WEATHER_SNOW_MEDIUM then
        set maxWaves = SNOW_MEDIUM_WAVES
        set unitsPerWave = SNOW_MEDIUM_UNITS
    elseif weatherType == WEATHER_SNOW_HEAVY then
        set maxWaves = SNOW_HEAVY_WAVES
        set unitsPerWave = SNOW_HEAVY_UNITS
    else
        // Default to medium if invalid
        set maxWaves = SNOW_MEDIUM_WAVES
        set unitsPerWave = SNOW_MEDIUM_UNITS
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
    
    // Create first wave immediately
    call CreateRandomSnow(snowZone)
    set RegionSnowWaveCount[regionIndex] = 1
endfunction

private function StopSnowInRegion takes integer regionIndex returns nothing
    if regionIndex == -1 then
        return
    endif
    
    // Stop wave timer
    if RegionSnowWaveTimer[regionIndex] != null then
        call PauseTimer(RegionSnowWaveTimer[regionIndex])
        call DestroyTimer(RegionSnowWaveTimer[regionIndex])
        set RegionSnowWaveTimer[regionIndex] = null
    endif
    
    // Gradually destroy snow units
    if RegionSnowZoneIndex[regionIndex] != -1 then
        set udg_SnowDestructionZone = RegionSnowZoneIndex[regionIndex]
        call StartGradualDestroy(RegionSnowZoneIndex[regionIndex])
        set RegionSnowZoneIndex[regionIndex] = -1
    endif
    
    set RegionSnowWaveCount[regionIndex] = 0
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
    
    if regionIndex == -1 then
        return
    endif
    
    // Stop existing weather
    call StopRegionWeatherInternal(regionIndex)
    
    set r = RegionRect[regionIndex]
    set zoneIndex = RegionZoneIndex[regionIndex]
    
    // Create weather effect and ambient sounds
    if weatherType == WEATHER_RAIN_LIGHT then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RLlr')
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainLight  // was: SOUND_RAIN_LIGHT
        call StartRipplesInRegion(r, regionIndex, RIPPLES_LIGHT)
        // No clouds for rain_light
    elseif weatherType == WEATHER_RAIN_MEDIUM then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RLhr')
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainMedium  // was: SOUND_RAIN_MEDIUM
        call StartRipplesInRegion(r, regionIndex, RIPPLES_MEDIUM)
        // Enable clouds for rain_medium
        if MasterZoneCloudsEnabled[zoneIndex] then
            call EnableCloudsInRegion(regionIndex)
        endif
    elseif weatherType == WEATHER_RAIN_HEAVY then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RAhr')
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainHeavy  // was: SOUND_RAIN_HEAVY
        call StartRipplesInRegion(r, regionIndex, RIPPLES_HEAVY)
        // Enable clouds for rain_heavy
        if MasterZoneCloudsEnabled[zoneIndex] then
            call EnableCloudsInRegion(regionIndex)
        endif
        if MasterZoneThunderEnabled[zoneIndex] then
            call EnableThunderInZone(zoneIndex)
        endif
    elseif weatherType == WEATHER_SNOW_LIGHT then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'SNls')
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_SnowLight  // was: SOUND_SNOW_LIGHT
        call StartSnowInRegion(regionIndex, weatherType)
        // No clouds for snow_light
        if MasterZoneSteamEnabled[zoneIndex] then
            call EnableSteamBreathInRegion(regionIndex)
        endif
    elseif weatherType == WEATHER_SNOW_MEDIUM then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'SNhs')
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_SnowMedium  // was: SOUND_SNOW_MEDIUM
        call StartSnowInRegion(regionIndex, weatherType)
        // Enable clouds for snow_medium
        if MasterZoneCloudsEnabled[zoneIndex] then
            call EnableCloudsInRegion(regionIndex)
        endif
        if MasterZoneSteamEnabled[zoneIndex] then
            call EnableSteamBreathInRegion(regionIndex)
        endif
    elseif weatherType == WEATHER_SNOW_HEAVY then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'SNbs')
        set RegionAmbientSound[regionIndex] = gg_snd_Ambient_SnowHeavy  // was: SOUND_SNOW_HEAVY
        call StartSnowInRegion(regionIndex, weatherType)
        // Enable clouds for snow_heavy
        if MasterZoneCloudsEnabled[zoneIndex] then
            call EnableCloudsInRegion(regionIndex)
        endif
        if MasterZoneSteamEnabled[zoneIndex] then
            call EnableSteamBreathInRegion(regionIndex)
        endif
    elseif weatherType == WEATHER_STORM then
        // Storm now always includes rain (heavy or medium)
        // Randomly choose rain intensity for storm
        if GetRandomInt(1, 100) <= 70 then
            // 70% chance: rain_heavy with storm
            set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RAhr')
            set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainHeavy
            call StartRipplesInRegion(r, regionIndex, RIPPLES_HEAVY)
        else
            // 30% chance: rain_medium with storm
            set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RLhr')
            set RegionAmbientSound[regionIndex] = gg_snd_Ambient_RainMedium
            call StartRipplesInRegion(r, regionIndex, RIPPLES_MEDIUM)
        endif
        // Enable clouds for storm
        if MasterZoneCloudsEnabled[zoneIndex] then
            call EnableCloudsInRegion(regionIndex)
        endif
        // Storm has no snow units, only thunder and rain visuals
        if MasterZoneThunderEnabled[zoneIndex] then
            call EnableThunderInZone(zoneIndex)
        endif
    elseif weatherType == WEATHER_WIND then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'WOlw')
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
    endif
endfunction

//===========================================================================
// ZONE WEATHER CONTROL
//===========================================================================

// Set weather for all regions in a zone
private function SetZoneWeatherInternal takes integer zoneIndex, string weatherType, real duration returns nothing
    local integer i = 0
    
    if zoneIndex == -1 then
        return
    endif
    
    set MasterZoneWeather[zoneIndex] = weatherType
    
    // Apply weather to all regions in this zone
    loop
        exitwhen i >= RegionCount
        if RegionZoneIndex[i] == zoneIndex then
            call StartRegionWeatherInternal(i, weatherType, duration)
        endif
        set i = i + 1
    endloop
    
    call Debug("Zone '" + MasterZoneName[zoneIndex] + "' weather set to: " + weatherType)
endfunction

// Stop weather in all regions of a zone
private function StopZoneWeatherInternal takes integer zoneIndex returns nothing
    local integer i = 0
    local string oldWeather
    
    if zoneIndex == -1 then
        return
    endif
    
    set oldWeather = MasterZoneWeather[zoneIndex]
    set MasterZoneWeather[zoneIndex] = WEATHER_NONE
    
    // Stop weather in all regions of this zone
    loop
        exitwhen i >= RegionCount
        if RegionZoneIndex[i] == zoneIndex then
            call StopRegionWeatherInternal(i)
        endif
        set i = i + 1
    endloop
    
    // Disable zone thunder
    call DisableThunderInZone(zoneIndex)
    
    // Debug message
    if oldWeather != WEATHER_NONE then
        call Debug("Zone '" + MasterZoneName[zoneIndex] + "' weather stopped: " + oldWeather)
    endif
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
    local real totalChance
    local real accumulated
    local real rainRoll
    local real snowRoll
    
    if not MasterZoneSeasonalEnabled[zoneIndex] then
        return
    endif
    
    // Skip if zone already has weather
    if MasterZoneWeather[zoneIndex] != WEATHER_NONE then
        return
    endif
    
    set season = GetZoneSeason(zoneIndex)
    
    // Get weather chances only for allowed weather types
    set snowChance = 0.0
    set rainChance = 0.0
    set stormChance = 0.0
    set windChance = 0.0
    
    if ZoneAllowsSnow[zoneIndex] then
        set snowChance = GetZoneWeatherChance(zoneIndex, season, WEATHER_SNOW_LIGHT)
    endif
    
    if ZoneAllowsRain[zoneIndex] then
        set rainChance = GetZoneWeatherChance(zoneIndex, season, WEATHER_RAIN_LIGHT)
    endif
    
    if ZoneAllowsStorm[zoneIndex] then
        set stormChance = GetZoneWeatherChance(zoneIndex, season, WEATHER_STORM)
    endif
    
    if ZoneAllowsWind[zoneIndex] then
        set windChance = GetZoneWeatherChance(zoneIndex, season, WEATHER_WIND)
    endif
    
    // Calculate total probability
    set totalChance = snowChance + rainChance + stormChance + windChance
    
    // If no weather configured, return
    if totalChance <= 0.0 then
        return
    endif
    
    // Roll a single value and use probability ranges
    set roll = GetRandomReal(0.0, totalChance)
    set accumulated = 0.0
    
    // Check snow range
    if ZoneAllowsSnow[zoneIndex] then
        set accumulated = accumulated + snowChance
        if roll < accumulated then
            // Pick snow intensity
            set snowRoll = GetRandomReal(0.0, 1.0)
            if snowRoll < 0.5 then
                set duration = GetRandomReal(SNOW_LIGHT_MIN_DURATION, SNOW_LIGHT_MAX_DURATION)
                call SetZoneWeatherInternal(zoneIndex, WEATHER_SNOW_LIGHT, duration)
            elseif snowRoll < 0.85 then
                set duration = GetRandomReal(SNOW_MEDIUM_MIN_DURATION, SNOW_MEDIUM_MAX_DURATION)
                call SetZoneWeatherInternal(zoneIndex, WEATHER_SNOW_MEDIUM, duration)
            else
                set duration = GetRandomReal(SNOW_HEAVY_MIN_DURATION, SNOW_HEAVY_MAX_DURATION)
                call SetZoneWeatherInternal(zoneIndex, WEATHER_SNOW_HEAVY, duration)
            endif
            return
        endif
    endif
    
    // Check rain range
    if ZoneAllowsRain[zoneIndex] then
        set accumulated = accumulated + rainChance
        if roll < accumulated then
            set duration = GetRandomReal(RAIN_MIN_DURATION, RAIN_MAX_DURATION)
            // Pick rain intensity
            set rainRoll = GetRandomReal(0.0, 1.0)
            if rainRoll < 0.5 then
                call SetZoneWeatherInternal(zoneIndex, WEATHER_RAIN_LIGHT, duration)
            elseif rainRoll < 0.85 then
                call SetZoneWeatherInternal(zoneIndex, WEATHER_RAIN_MEDIUM, duration)
            else
                call SetZoneWeatherInternal(zoneIndex, WEATHER_RAIN_HEAVY, duration)
            endif
            return
        endif
    endif
    
    // Check storm range
    if ZoneAllowsStorm[zoneIndex] then
        set accumulated = accumulated + stormChance
        if roll < accumulated then
            set duration = GetRandomReal(STORM_MIN_DURATION, STORM_MAX_DURATION)
            call SetZoneWeatherInternal(zoneIndex, WEATHER_STORM, duration)
            return
        endif
    endif
    
    // Check wind range
    if ZoneAllowsWind[zoneIndex] then
        set accumulated = accumulated + windChance
        if roll < accumulated then
            set duration = GetRandomReal(WIND_MIN_DURATION, WIND_MAX_DURATION)
            call SetZoneWeatherInternal(zoneIndex, WEATHER_WIND, duration)
            return
        endif
    endif
endfunction

// Main seasonal weather check for all zones
private function SeasonalWeatherCheck takes nothing returns nothing
    local integer i = 0
    
    if not SeasonalWeatherEnabled then
        return
    endif
    
    // Update season
    call UpdateSeasonInternal()
    
    // Check each zone for weather changes
    loop
        exitwhen i >= MasterZoneCount
        call ZoneSeasonalWeatherCheck(i)
        set i = i + 1
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

// Create a master zone
private function CreateMasterZoneInternal takes string zoneName, string defaultWeather, string season returns integer
    local integer index
    
    if MasterZoneCount >= MAX_MASTER_ZONES then
        call Debug("Cannot create zone '" + zoneName + "' - maximum zones reached")
        return -1
    endif
    
    // Check if zone already exists
    set index = FindMasterZoneIndex(zoneName)
    if index != -1 then
        call Debug("Zone '" + zoneName + "' already exists")
        return index
    endif
    
    set index = MasterZoneCount
    set MasterZoneName[index] = zoneName
    set MasterZoneID[index] = 0  // Default to 0 (global), set via SetZoneID if needed
    set MasterZoneWeather[index] = defaultWeather
    set MasterZoneSeason[index] = season
    set MasterZoneSeasonalEnabled[index] = true
    set MasterZoneThunderEnabled[index] = true
    set MasterZoneCloudsEnabled[index] = true
    set MasterZoneSteamEnabled[index] = true
    set MasterZoneRainChance[index] = 0.0  // 0 = use defaults
    set MasterZoneSnowChance[index] = 0.0
    set MasterZoneStormChance[index] = 0.0
    // Initialize allowed weather types (all disabled by default)
    set ZoneAllowsRain[index] = false
    set ZoneAllowsSnow[index] = false
    set ZoneAllowsStorm[index] = false
    set MasterZoneCount = MasterZoneCount + 1
    
    call Debug("Created master zone: " + zoneName)
    return index
endfunction

// Add a region to a zone
private function AddRegionToZoneInternal takes string zoneName, rect whichRect returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    local integer regionIndex = FindRegionIndex(whichRect)
    local integer newIndex
    
    if zoneIndex == -1 then
        call Debug("Zone '" + zoneName + "' not found")
        return
    endif
    
    // If region already exists, update its zone
    if regionIndex != -1 then
        set RegionZoneIndex[regionIndex] = zoneIndex
        call Debug("Updated region to zone: " + zoneName)
        return
    endif
    
    // Add new region
    if RegionCount >= MAX_REGIONS then
        call Debug("Cannot add region - maximum regions reached")
        return
    endif
    
    set newIndex = RegionCount
    set RegionRect[newIndex] = whichRect
    set RegionZoneIndex[newIndex] = zoneIndex
    set RegionSubZoneIndex[newIndex] = -1
    set RegionWeatherType[newIndex] = WEATHER_NONE
    set RegionWeatherEffect[newIndex] = null
    set RegionAmbientSound[newIndex] = null
    set RegionWeatherTimer[newIndex] = null
    set RegionRainSound[newIndex] = null
    set RegionHasClouds[newIndex] = false
    set RegionHasSteam[newIndex] = false
    set RegionHasThunder[newIndex] = false
    set RegionSpawnsSnow[newIndex] = false  // Default: no snow unit spawning
    set RegionSnowZoneIndex[newIndex] = -1
    set RegionSnowWaveTimer[newIndex] = null
    set RegionSnowWaveCount[newIndex] = 0
    set RegionRippleCount[newIndex] = 0
    set RegionCount = RegionCount + 1
    
    call Debug("Added region to zone: " + zoneName)
endfunction

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
// ZONE MANAGEMENT API
//===========================================================================

// Create a master zone
public function CreateMasterZone takes string zoneName, string defaultWeather, string season returns nothing
    call CreateMasterZoneInternal(zoneName, defaultWeather, season)
endfunction

// Add a region to a zone
public function AddRegionToZone takes string zoneName, rect whichRect returns nothing
    call AddRegionToZoneInternal(zoneName, whichRect)
endfunction

// Enable/disable specific weather types for a zone
public function SetZoneAllowedWeather takes string zoneName, string weatherType, boolean allowed returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex == -1 then
        return
    endif
    
    if weatherType == WEATHER_RAIN_LIGHT or weatherType == WEATHER_RAIN_HEAVY or weatherType == WEATHER_RAIN_MEDIUM or weatherType == "rain" then
        set ZoneAllowsRain[zoneIndex] = allowed
        if allowed then
            call Debug("Zone '" + zoneName + "' rain: enabled")
        else
            call Debug("Zone '" + zoneName + "' rain: disabled")
        endif
    elseif weatherType == WEATHER_SNOW_LIGHT or weatherType == WEATHER_SNOW_MEDIUM or weatherType == WEATHER_SNOW_HEAVY or weatherType == "snow" then
        set ZoneAllowsSnow[zoneIndex] = allowed
        if allowed then
            call Debug("Zone '" + zoneName + "' snow: enabled")
        else
            call Debug("Zone '" + zoneName + "' snow: disabled")
        endif
    elseif weatherType == WEATHER_STORM or weatherType == "storm" then
        set ZoneAllowsStorm[zoneIndex] = allowed
        if allowed then
            call Debug("Zone '" + zoneName + "' storm: enabled")
        else
            call Debug("Zone '" + zoneName + "' storm: disabled")
        endif
    elseif weatherType == WEATHER_WIND or weatherType == "wind" then
        set ZoneAllowsWind[zoneIndex] = allowed
        if allowed then
            call Debug("Zone '" + zoneName + "' wind: enabled")
        else
            call Debug("Zone '" + zoneName + "' wind: disabled")
        endif
    endif
endfunction

// Enable snow unit spawning for a specific region (manual configuration)
public function SetRegionSnowSpawn takes rect whichRect, boolean enabled returns nothing
    local integer regionIndex = FindRegionIndex(whichRect)
    
    if regionIndex != -1 then
        set RegionSpawnsSnow[regionIndex] = enabled
        if enabled then
            call Debug("Region configured for snow unit spawning")
        else
            call Debug("Region snow unit spawning disabled")
        endif
    endif
endfunction

// Set weather for an entire zone
public function SetZoneWeather takes string zoneName, string weatherType, real duration returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    call SetZoneWeatherInternal(zoneIndex, weatherType, duration)
    call Zones_ApplyCurrentZoneEffects()
endfunction

// Stop weather in a zone
public function StopZoneWeather takes string zoneName returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    call StopZoneWeatherInternal(zoneIndex)
    call Zones_ApplyCurrentZoneEffects()
endfunction

// Set weather for a specific region
public function SetRegionWeather takes rect whichRect, string weatherType, real duration returns nothing
    local integer regionIndex = FindRegionIndex(whichRect)
    call StartRegionWeatherInternal(regionIndex, weatherType, duration)
    call Zones_ApplyCurrentZoneEffects()
endfunction

// Stop weather in a specific region
public function StopRegionWeather takes rect whichRect returns nothing
    local integer regionIndex = FindRegionIndex(whichRect)
    call StopRegionWeatherInternal(regionIndex)
    call Zones_ApplyCurrentZoneEffects()
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

// Set zone seasonal behavior
public function SetZoneSeasonalBehavior takes string zoneName, boolean enabled returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        set MasterZoneSeasonalEnabled[zoneIndex] = enabled
    endif
endfunction

// Set season manually
public function SetSeason takes string season returns nothing
    if season == SEASON_SPRING or season == SEASON_SUMMER or season == SEASON_AUTUMN or season == SEASON_WINTER then
        set CurrentSeason = season
        call Debug("Season set to: " + season)
    else
        call Debug("Invalid season: " + season)
    endif
endfunction

// Set zone-specific season
public function SetZoneSeason takes string zoneName, string season returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        set MasterZoneSeason[zoneIndex] = season
        call Debug("Zone '" + zoneName + "' season set to: " + season)
    endif
endfunction

// Update season from days passed
public function UpdateSeason takes nothing returns nothing
    call UpdateSeasonInternal()
endfunction

// Enable/disable thunder in zone
public function EnableZoneThunder takes string zoneName, boolean enable returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        set MasterZoneThunderEnabled[zoneIndex] = enable
        
        if not enable then
            call DisableThunderInZone(zoneIndex)
        endif
    endif
endfunction

// Enable/disable clouds in zone
public function EnableZoneClouds takes string zoneName, boolean enable returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        set MasterZoneCloudsEnabled[zoneIndex] = enable
    endif
endfunction

// Enable/disable steam breath in zone
public function EnableZoneSteamBreath takes string zoneName, boolean enable returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        set MasterZoneSteamEnabled[zoneIndex] = enable
    endif
endfunction

// Set zone ID (udg_ZoneCurrent value) for storm effect targeting
public function SetZoneID takes string zoneName, integer zoneId returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        set MasterZoneID[zoneIndex] = zoneId
        call Debug("Zone '" + zoneName + "' ID set to: " + I2S(zoneId))
    endif
endfunction

// Set zone weather probabilities
public function SetZoneWeatherChance takes string zoneName, string weatherType, real chance returns nothing
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        if weatherType == WEATHER_RAIN_LIGHT or weatherType == WEATHER_RAIN_MEDIUM or weatherType == WEATHER_RAIN_HEAVY or weatherType == "rain" then
            set MasterZoneRainChance[zoneIndex] = chance
        elseif weatherType == WEATHER_SNOW_LIGHT or weatherType == WEATHER_SNOW_MEDIUM or weatherType == WEATHER_SNOW_HEAVY or weatherType == "snow" then
            set MasterZoneSnowChance[zoneIndex] = chance
        elseif weatherType == WEATHER_STORM or weatherType == "storm" then
            set MasterZoneStormChance[zoneIndex] = chance
        elseif weatherType == WEATHER_WIND or weatherType == "wind" then
            set MasterZoneWindChance[zoneIndex] = chance
        endif
    endif
endfunction

// Query: Get zone weather
public function GetZoneWeather takes string zoneName returns string
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    
    if zoneIndex != -1 then
        return MasterZoneWeather[zoneIndex]
    endif
    
    return WEATHER_NONE
endfunction

// Query: Get region weather
public function GetRegionWeather takes rect whichRect returns string
    local integer regionIndex = FindRegionIndex(whichRect)
    
    if regionIndex != -1 then
        return RegionWeatherType[regionIndex]
    endif
    
    return WEATHER_NONE
endfunction

// Query: Get region's zone name
public function GetRegionZone takes rect whichRect returns string
    local integer regionIndex = FindRegionIndex(whichRect)
    local integer zoneIndex
    
    if regionIndex != -1 then
        set zoneIndex = RegionZoneIndex[regionIndex]
        if zoneIndex != -1 then
            return MasterZoneName[zoneIndex]
        endif
    endif
    
    return ""
endfunction

// Query: Get current season
public function GetCurrentSeason takes nothing returns string
    return CurrentSeason
endfunction

// Query: Check if current weather matches a pattern
// Supports patterns: "rain_any" (any rain), "snow" (any snow), "Sirensong" (zone name), specific weather type
public function IsWeatherActive takes string pattern returns boolean
    local integer i = 0
    local string weather
    local string zoneName
    
    // Check for zone name pattern (e.g., "Sirensong")
    set i = 0
    loop
        exitwhen i >= MasterZoneCount
        if StringEquals(MasterZoneName[i], pattern) then
            // Found matching zone, check if it has any active weather
            return MasterZoneWeather[i] != WEATHER_NONE
        endif
        set i = i + 1
    endloop
    
    // Check for weather type patterns
    set i = 0
    loop
        exitwhen i >= RegionCount
        set weather = RegionWeatherType[i]
        
        // Pattern matching
        if pattern == "rain_any" or pattern == "rain" then
            if weather == WEATHER_RAIN_LIGHT or weather == WEATHER_RAIN_MEDIUM or weather == WEATHER_RAIN_HEAVY then
                return true
            endif
        elseif pattern == "snow" then
            if weather == WEATHER_SNOW_LIGHT or weather == WEATHER_SNOW_MEDIUM or weather == WEATHER_SNOW_HEAVY then
                return true
            endif
        elseif pattern == "storm" then
            if weather == WEATHER_STORM then
                return true
            endif
        elseif pattern == "wind" then
            if weather == WEATHER_WIND then
                return true
            endif
        elseif StringEquals(weather, pattern) then
            // Exact match (e.g., "rain_light", "snow_heavy")
            return true
        endif
        
        set i = i + 1
    endloop
    
    return false
endfunction

// Query: Get weather in specific zone with pattern matching
// Returns the specific weather type if pattern matches, or "" if no match
public function GetWeatherInZone takes string zoneName, string pattern returns string
    local integer zoneIndex = FindMasterZoneIndex(zoneName)
    local string weather
    
    if zoneIndex == -1 then
        return ""
    endif
    
    set weather = MasterZoneWeather[zoneIndex]
    
    // Return empty if no weather
    if weather == WEATHER_NONE then
        return ""
    endif
    
    // Pattern matching
    if pattern == "rain_any" or pattern == "rain" then
        if weather == WEATHER_RAIN_LIGHT or weather == WEATHER_RAIN_MEDIUM or weather == WEATHER_RAIN_HEAVY then
            return weather
        endif
    elseif pattern == "snow" then
        if weather == WEATHER_SNOW_LIGHT or weather == WEATHER_SNOW_MEDIUM or weather == WEATHER_SNOW_HEAVY then
            return weather
        endif
    elseif pattern == "storm" then
        if weather == WEATHER_STORM then
            return weather
        endif
    elseif pattern == "wind" then
        if weather == WEATHER_WIND then
            return weather
        endif
    elseif pattern == "any" then
        // Return any active weather
        return weather
    elseif StringEquals(weather, pattern) then
        // Exact match
        return weather
    endif
    
    return ""
endfunction

// Query: Get all zones with active weather matching pattern
// Returns count of matching zones (stores results in a callback or global)
public function CountZonesWithWeather takes string pattern returns integer
    local integer i = 0
    local integer count = 0
    local string weather
    
    loop
        exitwhen i >= MasterZoneCount
        set weather = MasterZoneWeather[i]
        
        if weather != WEATHER_NONE then
            // Pattern matching
            if pattern == "rain_any" or pattern == "rain" then
                if weather == WEATHER_RAIN_LIGHT or weather == WEATHER_RAIN_MEDIUM or weather == WEATHER_RAIN_HEAVY then
                    set count = count + 1
                endif
            elseif pattern == "snow" then
                if weather == WEATHER_SNOW_LIGHT or weather == WEATHER_SNOW_MEDIUM or weather == WEATHER_SNOW_HEAVY then
                    set count = count + 1
                endif
            elseif pattern == "any" then
                set count = count + 1
            elseif StringEquals(weather, pattern) then
                set count = count + 1
            endif
        endif
        
        set i = i + 1
    endloop
    
    return count
endfunction

//===========================================================================
// LEGACY COMPATIBILITY FUNCTIONS (for old global weather API)
//===========================================================================

// Deprecated: Use zone-based system instead
public function SetGlobalWeather takes string weatherType returns nothing
    local integer i = 0
    
    call Debug("SetGlobalWeather is deprecated - use zone-based weather instead")
    
    // Apply to all zones
    loop
        exitwhen i >= MasterZoneCount
        call SetZoneWeatherInternal(i, weatherType, 0.0)
        set i = i + 1
    endloop
endfunction

// Deprecated: Use zone-based system instead
public function StopGlobalWeather takes nothing returns nothing
    local integer i = 0
    
    call Debug("StopGlobalWeather is deprecated - use zone-based weather instead")
    
    // Stop in all zones
    loop
        exitwhen i >= MasterZoneCount
        call StopZoneWeatherInternal(i)
        set i = i + 1
    endloop
endfunction

// Alias for compatibility
public function StartRegionalWeatherAPI takes rect whichRect, string weatherType, real duration returns nothing
    call SetRegionWeather(whichRect, weatherType, duration)
endfunction

// Alias for compatibility
public function StopRegionalWeatherAPI takes rect whichRect returns nothing
    call StopRegionWeather(whichRect)
endfunction

//===========================================================================
// ZONE CONFIGURATION - DEFINE YOUR ZONES HERE
//===========================================================================

private function ConfigureZones takes nothing returns nothing
    //===========================================================================
    // MAP ZONE CONFIGURATION
    // Adjust weather types, probabilities, and effects below
    //===========================================================================
    
    // === Zone01: Twilight Grove (Forest) ===
    call CreateMasterZoneInternal("TwilightGrove", "none", "auto")
    call SetZoneID("TwilightGrove", 1)  // udg_ZoneCurrent = 1
    call AddRegionToZoneInternal("TwilightGrove", gg_rct_001TwilightGroveFull)
    call SetZoneAllowedWeather("TwilightGrove", "rain", true)
    call SetZoneAllowedWeather("TwilightGrove", "snow", true)
    call SetZoneWeatherChance("TwilightGrove", "rain_light", 0.4)
    call SetZoneWeatherChance("TwilightGrove", "snow", 0.55)
    call EnableZoneClouds("TwilightGrove", true)
    call EnableZoneSteamBreath("TwilightGrove", true)
    call SetRegionSnowSpawn(gg_rct_001TwilightGroveFull, true)
    // Snowy section included in zone - ONLY this region spawns snow units
    call AddRegionToZoneInternal("Serenaglade", gg_rct_SnowTest2)
    call SetRegionSnowSpawn(gg_rct_SnowTest2, true)
    
    //===========================================================================
    // SPECIAL CONFIGURATION EXAMPLES:
    //===========================================================================
    
    // To make the snowy section in Serenaglade have permanent snow:
    // call SetRegionWeather(gg_rct_SnowTest2, "snow", 0.0)
    
    // To lock a zone to eternal winter:
    // call SetZoneSeason("EmperpeakHighlands", "winter")
    // call SetZoneSeasonalBehavior("EmperpeakHighlands", false)
    
    // To create dramatic weather for boss areas:
    // call SetZoneWeather("FelfireBastion", "storm", 0.0)
    
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================

private function Init takes nothing returns nothing
    // Initialize season
    call UpdateSeasonInternal()
    
    // Configure zones (edit ConfigureZones function above)
    call ConfigureZones()
    
    // Display status
    if MasterZoneCount > 0 then
        call Debug("Weather System initialized with " + I2S(MasterZoneCount) + " zones")
    else
        call Debug("Zone-Based Weather System 2.0 initialized")
        call Debug("No zones configured. Define zones in ConfigureZones() or create via triggers:")
        call Debug("  WeatherSystem_CreateMasterZone(name, weather, season)")
        call Debug("  WeatherSystem_AddRegionToZone(zoneName, region)")
    endif
endfunction

endlibrary
