library WeatherSystem initializer Init requires ZonesCore
// Lightweight WeatherSystem v4
// Uses ZonesCore to fetch ZoneData weather rects and exposes basic API

globals
    private constant string WEATHER_NONE        = "none"
    private constant string WEATHER_RAIN_LIGHT  = "rain_light"
    private constant string WEATHER_RAIN_MEDIUM = "rain_medium"
    private constant string WEATHER_RAIN_HEAVY  = "rain_heavy"
    private constant string WEATHER_SNOW_LIGHT  = "snow_light"
    private constant string WEATHER_SNOW_MEDIUM = "snow_medium"
    private constant string WEATHER_SNOW_HEAVY  = "snow_heavy"
    private constant string WEATHER_STORM       = "storm"
    private constant string WEATHER_WIND        = "wind"

    // Region storage (simple, indexed list of registered rects)
    private rect array RegionRect
    private integer array RegionZoneIndex
    private integer array RegionSubZoneIndex
    private string array RegionWeatherType
    private weathereffect array RegionWeatherEffect
    private integer RegionCount = 0
endglobals

// Debug helper (silent by default)
private function Debug takes string msg returns nothing
    // Toggle by changing this literal if you want debug output during development
    if false then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[WeatherSystemv4] " + msg)
    endif
endfunction

// Find region index by rect (returns -1 if not found)
private function FindRegionIndex takes rect whichRect returns integer
    local integer i = 0
    if whichRect == null then
        return -1
    endif
    loop
        exitwhen i >= RegionCount
        if RegionRect[i] == whichRect then
            return i
        endif
        set i = i + 1
    endloop
    return -1
endfunction

// Register a single rect (if not already present)
private function RegisterRegionRectInternal takes rect r, integer zoneIndex, integer subZoneIndex returns nothing
    local integer idx
    if r == null then
        return
    endif
    set idx = FindRegionIndex(r)
    if idx != -1 then
        return
    endif
    set RegionRect[RegionCount] = r
    set RegionZoneIndex[RegionCount] = zoneIndex
    set RegionSubZoneIndex[RegionCount] = subZoneIndex
    set RegionWeatherType[RegionCount] = WEATHER_NONE
    set RegionWeatherEffect[RegionCount] = null
    set RegionCount = RegionCount + 1
    call Debug("Registered regionIndex=" + I2S(RegionCount - 1) + " for zone=" + I2S(zoneIndex))
endfunction

// Iterate ZonesCore and register all weather rects found in each ZoneData
private function RegisterAllZoneRects takes nothing returns nothing
    local integer zoneId = 1
    local ZoneData z
    local integer i
    // Upper bound: iterate a large range; ZonesCore_GetZoneData returns 0 if none
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
    call Debug("WeatherSystemv4: Registered " + I2S(RegionCount) + " region rects from ZoneData")
endfunction

// Basic start/stop region weather: maps a few weather types to weather effect IDs
private function StartRegionWeatherInternal takes integer regionIndex, string weatherType returns nothing
    local rect r
    if regionIndex < 0 or regionIndex >= RegionCount then
        return
    endif
    set r = RegionRect[regionIndex]
    if r == null then
        return
    endif

    // Remove existing effect if present
    if RegionWeatherEffect[regionIndex] != null then
        call RemoveWeatherEffect(RegionWeatherEffect[regionIndex])
        set RegionWeatherEffect[regionIndex] = null
    endif

    if weatherType == WEATHER_RAIN_LIGHT then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RLlr')
    elseif weatherType == WEATHER_RAIN_MEDIUM then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RLhr')
    elseif weatherType == WEATHER_RAIN_HEAVY then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'RAhr')
    elseif weatherType == WEATHER_SNOW_LIGHT then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'SNls')
    elseif weatherType == WEATHER_SNOW_MEDIUM then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'SNhs')
    elseif weatherType == WEATHER_SNOW_HEAVY then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'SNbs')
    elseif weatherType == WEATHER_WIND then
        set RegionWeatherEffect[regionIndex] = AddWeatherEffect(r, 'WOlw')
    else
        // unknown or WEATHER_NONE: nothing to add
        set RegionWeatherEffect[regionIndex] = null
    endif

    if RegionWeatherEffect[regionIndex] != null then
        call EnableWeatherEffect(RegionWeatherEffect[regionIndex], true)
        set RegionWeatherType[regionIndex] = weatherType
        call Debug("Started weather '" + weatherType + "' in regionIndex=" + I2S(regionIndex))
    else
        // ensure type set to none
        set RegionWeatherType[regionIndex] = WEATHER_NONE
        call Debug("No weather effect created for '" + weatherType + "' in regionIndex=" + I2S(regionIndex))
    endif
endfunction

private function StopRegionWeatherInternal takes integer regionIndex returns nothing
    if regionIndex < 0 or regionIndex >= RegionCount then
        return
    endif
    if RegionWeatherEffect[regionIndex] != null then
        call RemoveWeatherEffect(RegionWeatherEffect[regionIndex])
        set RegionWeatherEffect[regionIndex] = null
    endif
    set RegionWeatherType[regionIndex] = WEATHER_NONE
    call Debug("Stopped weather in regionIndex=" + I2S(regionIndex))
endfunction

// Set weather for all rects in a zone by zoneId
private function SetZoneWeatherInternal takes integer zoneIndex, string weatherType returns nothing
    local ZoneData z
    local integer i
    local rect r
    local integer regionIdx
    if zoneIndex <= 0 then
        return
    endif
    set z = ZonesCore_GetZoneData(zoneIndex)
    if z == 0 then
        return
    endif

    // Normal weather rects
    set i = 0
    loop
        exitwhen i >= z.weatherRectCount
        set r = z.getWeatherRect(i)
        if r != null then
            set regionIdx = FindRegionIndex(r)
            if regionIdx != -1 then
                call StartRegionWeatherInternal(regionIdx, weatherType)
            endif
        endif
        set i = i + 1
    endloop

    // Snow rects
    set i = 0
    loop
        exitwhen i >= z.weatherSnowRectCount
        set r = z.getWeatherSnowRect(i)
        if r != null then
            set regionIdx = FindRegionIndex(r)
            if regionIdx != -1 then
                call StartRegionWeatherInternal(regionIdx, weatherType)
            endif
        endif
        set i = i + 1
    endloop

    call Debug("SetZoneWeatherInternal: zone=" + I2S(zoneIndex) + " -> " + weatherType)
endfunction

// Public API: set zone weather by zoneId
public function SetZoneWeatherById takes integer zoneId, string weatherType returns nothing
    call SetZoneWeatherInternal(zoneId, weatherType)
endfunction

// Public API: stop zone weather by zoneId
public function StopZoneWeatherById takes integer zoneId returns nothing
    local ZoneData z
    local integer i
    local rect r
    local integer regionIdx
    if zoneId <= 0 then
        return
    endif
    set z = ZonesCore_GetZoneData(zoneId)
    if z == 0 then
        return
    endif
    set i = 0
    loop
        exitwhen i >= z.weatherRectCount
        set r = z.getWeatherRect(i)
        if r != null then
            set regionIdx = FindRegionIndex(r)
            if regionIdx != -1 then
                call StopRegionWeatherInternal(regionIdx)
            endif
        endif
        set i = i + 1
    endloop
    set i = 0
    loop
        exitwhen i >= z.weatherSnowRectCount
        set r = z.getWeatherSnowRect(i)
        if r != null then
            set regionIdx = FindRegionIndex(r)
            if regionIdx != -1 then
                call StopRegionWeatherInternal(regionIdx)
            endif
        endif
        set i = i + 1
    endloop
    call Debug("StopZoneWeatherById: zone=" + I2S(zoneId))
endfunction

// Public API: set region weather by registered region index
public function SetRegionWeatherByIndex takes integer regionIndex, string weatherType returns nothing
    call StartRegionWeatherInternal(regionIndex, weatherType)
endfunction

// Public API: stop region weather by registered region index
public function StopRegionWeatherByIndex takes integer regionIndex returns nothing
    call StopRegionWeatherInternal(regionIndex)
endfunction

// Query region weather
public function GetRegionWeatherByIndex takes integer regionIndex returns string
    if regionIndex >= 0 and regionIndex < RegionCount then
        return RegionWeatherType[regionIndex]
    endif
    return WEATHER_NONE
endfunction

// Simple test helper: start light rain in zone named "Twilight Grove"
public function Test_StartTwilightGroveRain takes nothing returns nothing
    local integer zoneId
    set zoneId = ZonesCore_GetZoneIdByName("Twilight Grove")
    if zoneId != 0 then
        call SetZoneWeatherById(zoneId, WEATHER_RAIN_LIGHT)
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "WeatherSystemv4: Started rain_light in zone 'Twilight Grove' (id=" + I2S(zoneId) + ")")
    else
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "WeatherSystemv4: Zone not found: Twilight Grove")
    endif
endfunction

// Initialization
private function Init takes nothing returns nothing
    call RegisterAllZoneRects()
    //call Debug("Init complete. Regions registered: " + I2S(RegionCount))
    call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "WeatherSystemv4: Initialized.") 
endfunction

endlibrary
