//===========================================================================
// TEST FUNCTION: Simple rain_light test for zone1 via chat command
//===========================================================================
function Test_RainLight_Zone1 takes nothing returns nothing
    //call WeatherSystem_SetZoneWeatherById(1, "rain_light", 60.0)
    call WeatherSystem_SetZoneWeather("Twilight Grove", "rain_light", 60.0)
    call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[Test] rain_light started for 60s") 
endfunction

// Example chat trigger (add to your map triggers):
// call TriggerRegisterPlayerChatEvent(gg_trg_TestRainLight, Player(0), "-rain1", true)
// call TriggerAddAction(gg_trg_TestRainLight, function Test_RainLight_Zone1)
//===========================================================================