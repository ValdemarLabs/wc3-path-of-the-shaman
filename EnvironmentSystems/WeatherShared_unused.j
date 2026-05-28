//===========================================================================
// WeatherShared - Shared API for WeatherSystem and Zones
//===========================================================================
// Place all functions and globals that must be accessed by both WeatherSystem and Zones here.
// Both libraries should require WeatherShared instead of each other.
//
library WeatherShared initializer Init

// Shared API: GetZoneWeather
// This will be set by WeatherSystem at map init
globals
    trigger WeatherShared_GetZoneWeatherPtr = null
    string WeatherShared_ZoneWeatherParam = ""
    string WeatherShared_ZoneWeatherResult = ""
endglobals

function WeatherShared_GetZoneWeather takes string zoneName returns string
    if WeatherShared_GetZoneWeatherPtr != null then
        set WeatherShared_ZoneWeatherParam = zoneName
        call TriggerEvaluate(WeatherShared_GetZoneWeatherPtr)
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[WeatherShared] Result for '" + zoneName + "': " + WeatherShared_ZoneWeatherResult)
        return WeatherShared_ZoneWeatherResult
    endif
    return ""
endfunction

// You can add more shared API functions, variables, or interfaces here.

private function Init takes nothing returns nothing
    // Initialization code for shared API, if needed.
endfunction

endlibrary
