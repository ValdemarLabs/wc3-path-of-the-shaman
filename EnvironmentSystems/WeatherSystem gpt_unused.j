library WeatherSystem initializer Init requires Zones, Table

//===========================================================================
// WEATHER TYPES (ENUMS)
//===========================================================================

globals
    constant integer WEATHER_NONE         = 0
    constant integer WEATHER_RAIN_LIGHT   = 1
    constant integer WEATHER_RAIN_MEDIUM  = 2
    constant integer WEATHER_RAIN_HEAVY   = 3
    constant integer WEATHER_SNOW_LIGHT   = 4
    constant integer WEATHER_SNOW_MEDIUM  = 5
    constant integer WEATHER_SNOW_HEAVY   = 6
    constant integer WEATHER_STORM        = 7
    constant integer WEATHER_WIND         = 8
endglobals

//===========================================================================
// WEATHER PROFILES PER ZONE
//===========================================================================

struct ZoneWeatherProfile
    integer zoneId
    boolean seasonalEnabled
    integer currentWeather
    real rainChance
    real snowChance
    real stormChance
    real windChance
endstruct

globals
    private Table ZoneProfiles
    private integer CurrentSeason = 0 // 0=spring,1=summer,2=autumn,3=winter
endglobals

//===========================================================================
// UTILS
//===========================================================================

private function RandomWeatherRoll takes real chance returns boolean
    return GetRandomReal(0.0, 1.0) <= chance
endfunction

//===========================================================================
// WEATHER MANAGEMENT
//===========================================================================

public function RegisterZoneProfile takes integer zoneId returns nothing
    local ZoneWeatherProfile z = ZoneWeatherProfile.create()
    set z.zoneId = zoneId
    set z.seasonalEnabled = true
    set z.currentWeather = WEATHER_NONE
    set z.rainChance = 0.3
    set z.snowChance = 0.2
    set z.stormChance = 0.1
    set z.windChance = 0.1

    set ZoneProfiles[zoneId] = z
endfunction

public function SetZoneWeatherChance takes integer zoneId, integer weatherType, real chance returns nothing
    local ZoneWeatherProfile z = ZoneProfiles[zoneId]
    if z == 0 then
        return
    endif

    if weatherType == WEATHER_RAIN_LIGHT or weatherType == WEATHER_RAIN_MEDIUM or weatherType == WEATHER_RAIN_HEAVY then
        set z.rainChance = chance
    elseif weatherType == WEATHER_SNOW_LIGHT or weatherType == WEATHER_SNOW_MEDIUM or weatherType == WEATHER_SNOW_HEAVY then
        set z.snowChance = chance
    elseif weatherType == WEATHER_STORM then
        set z.stormChance = chance
    elseif weatherType == WEATHER_WIND then
        set z.windChance = chance
    endif
endfunction

public function SetZoneSeasonalEnabled takes integer zoneId, boolean enabled returns nothing
    local ZoneWeatherProfile z = ZoneProfiles[zoneId]
    if z != 0 then
        set z.seasonalEnabled = enabled
    endif
endfunction

//===========================================================================
// WEATHER ROLL
//===========================================================================

public function RollWeatherForZone takes integer zoneId returns nothing
    local ZoneWeatherProfile z = ZoneProfiles[zoneId]
    local integer newWeather = WEATHER_NONE

    if z == 0 then
        return
    endif

    if not z.seasonalEnabled then
        set newWeather = WEATHER_NONE
    else
        if RandomWeatherRoll(z.stormChance) then
            set newWeather = WEATHER_STORM
        elseif RandomWeatherRoll(z.snowChance) then
            set newWeather = WEATHER_SNOW_MEDIUM
        elseif RandomWeatherRoll(z.rainChance) then
            set newWeather = WEATHER_RAIN_MEDIUM
        elseif RandomWeatherRoll(z.windChance) then
            set newWeather = WEATHER_WIND
        else
            set newWeather = WEATHER_NONE
        endif
    endif

    set z.currentWeather = newWeather

    // PUSH TO ZONES
    call Zones_SetZoneWeatherState(zoneId, MapWeatherToZoneWeather(newWeather))
endfunction

private function MapWeatherToZoneWeather takes integer weather returns integer
    if weather == WEATHER_RAIN_LIGHT or weather == WEATHER_RAIN_MEDIUM or weather == WEATHER_RAIN_HEAVY then
        return ZONE_WEATHER_MEDIUM
    elseif weather == WEATHER_SNOW_LIGHT or weather == WEATHER_SNOW_MEDIUM or weather == WEATHER_SNOW_HEAVY then
        return ZONE_WEATHER_MEDIUM
    elseif weather == WEATHER_STORM then
        return ZONE_WEATHER_HEAVY
    elseif weather == WEATHER_WIND then
        return ZONE_WEATHER_LIGHT
    endif
    return ZONE_WEATHER_NONE
endfunction

//===========================================================================
// SEASON MANAGEMENT
//===========================================================================

public function SetSeason takes integer season returns nothing
    if season < 0 or season > 3 then
        return
    endif
    set CurrentSeason = season
endfunction

public function GetCurrentSeason takes nothing returns integer
    return CurrentSeason
endfunction

//===========================================================================
// PERIODIC WEATHER UPDATE
//===========================================================================

public function UpdateAllZonesWeather takes nothing returns nothing
    local integer zoneId = 0
    loop
        exitwhen zoneId >= Table.getLength(ZoneProfiles)
        call RollWeatherForZone(zoneId)
        set zoneId = zoneId + 1
    endloop
endfunction

//===========================================================================
// LEGACY / MANUAL WEATHER SET
//===========================================================================

public function SetZoneWeatherManual takes integer zoneId, integer weather returns nothing
    local ZoneWeatherProfile z = ZoneProfiles[zoneId]
    if z == 0 then return endif

    set z.currentWeather = weather
    call Zones_SetZoneWeatherState(zoneId, MapWeatherToZoneWeather(weather))
endfunction

//===========================================================================
// INIT
//===========================================================================

private function Init takes nothing returns nothing
    set ZoneProfiles = Table.create()
    set CurrentSeason = 0
endfunction

endlibrary
