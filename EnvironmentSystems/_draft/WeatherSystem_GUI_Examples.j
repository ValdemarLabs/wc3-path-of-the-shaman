//===========================================================================
// WeatherSystem - Example GUI Triggers
// These can be copied into your trigger editor (convert to GUI format)
//===========================================================================

//===========================================================================
// EXAMPLE 1: Map Initialization - Enable Seasonal Weather
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather System Init

Events:
    Map initialization

Actions:
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
    Custom script:   call WeatherSystem_EnableThunderEffect(true)
    Custom script:   call WeatherSystem_EnableCloudsEffect(true)
    Custom script:   call WeatherSystem_EnableSteamBreathEffect(true)
    Game - Display to (All players) the text: Weather System Activ...
*/

//===========================================================================
// EXAMPLE 2: Day/Night Cycle with Season Updates
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Day Night Cycle

Events:
    Time - Every 24.00 seconds of game time

Actions:
    Set udg_DaysPassed = (udg_DaysPassed + 1)
    Custom script:   call WeatherSystem_UpdateSeason()
    Game - Display to (All players) the text: Day + I2S(udg_DaysPassed) + , Season: + WeatherSystem_GetCurrentSeason()
*/

//===========================================================================
// EXAMPLE 3: Manual Weather Control (Debug Commands)
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Debug Commands

Events:
    Player - Player 1 (Red) types a chat message containing rain light as An exact match
    Player - Player 1 (Red) types a chat message containing rain heavy as An exact match
    Player - Player 1 (Red) types a chat message containing snow as An exact match
    Player - Player 1 (Red) types a chat message containing storm as An exact match
    Player - Player 1 (Red) types a chat message containing clear as An exact match

Conditions:

Actions:
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to rain light
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("rain_light")
            Game - Display to (All players) the text: Light rain started
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to rain heavy
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("rain_heavy")
            Game - Display to (All players) the text: Heavy rain started
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to snow
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("snow")
            Game - Display to (All players) the text: Snow started
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to storm
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("storm")
            Game - Display to (All players) the text: Storm started
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to clear
        Then - Actions
            Custom script:   call WeatherSystem_StopGlobalWeather()
            Game - Display to (All players) the text: Weather cleared
        Else - Actions
*/

//===========================================================================
// EXAMPLE 4: Regional Weather - Permanent Snow Zones
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Setup Snow Zones

Events:
    Map initialization

Actions:
    -------- Northern Mountains - Permanent Snow --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_NorthMountains, "snow", 0.0)
    -------- Eastern Peaks - Permanent Snow --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_EastPeaks, "snow", 0.0)
    -------- Frozen Wastes - Permanent Snow --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_FrozenWastes, "snow", 0.0)
    Game - Display to (All players) the text: Snow zones establishe...
*/

//===========================================================================
// EXAMPLE 5: Regional Weather - Temporary Rain Event
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Forest Rain Event

Events:
    Unit - A unit enters ForestRegion <gen>

Conditions:
    (Unit-type of (Triggering unit)) Equal to Peasant

Actions:
    Game - Display to (All players) the text: A storm approaches the...
    Wait 3.00 seconds
    -------- Start heavy rain in forest for 180 seconds --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_ForestRegion, "rain_heavy", 180.0)
    -------- Optional: Show message when rain stops --------
    Wait 180.00 seconds
    Game - Display to (All players) the text: The storm has passed
*/

//===========================================================================
// EXAMPLE 6: Seasonal Quest System
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Check Season for Quest

Events:
    Time - Every 60.00 seconds of game time

Conditions:

Actions:
    Custom script:   local string season = WeatherSystem_GetCurrentSeason()
    Custom script:   if season == "winter" then
        -------- Enable winter quests --------
        Trigger - Turn on Winter Quest 01 <gen>
        Trigger - Turn on Winter Quest 02 <gen>
        Quest - Display to (All players) the Quest Update message: Winter Quests Available
    Custom script:   elseif season == "summer" then
        -------- Enable summer quests --------
        Trigger - Turn on Summer Quest 01 <gen>
        Trigger - Turn on Summer Quest 02 <gen>
        Quest - Display to (All players) the Quest Update message: Summer Quests Availab...
    Custom script:   endif
*/

//===========================================================================
// EXAMPLE 7: Weather-Based Unit Spawning
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Spawn System

Events:
    Time - Every 30.00 seconds of game time

Conditions:

Actions:
    Custom script:   local string weather = WeatherSystem_GetCurrentWeather()
    Custom script:   if weather == "snow" then
        -------- Spawn ice creatures during snow --------
        Unit - Create 3 Ice Troll for Neutral Hostile at (Center of SpawnZone <gen>) facing Default building facing degrees
        Game - Display to (All players) the text: Ice creatures emerge...
    Custom script:   elseif weather == "storm" then
        -------- Spawn lightning elementals during storms --------
        Unit - Create 2 Lightning Revenant for Neutral Hostile at (Center of SpawnZone <gen>) facing Default building facing degrees
        Game - Display to (All players) the text: Storm creatures appe...
    Custom script:   endif
*/

//===========================================================================
// EXAMPLE 8: Region Entry Weather Effect
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Mountain Region Weather

Events:
    Unit - A unit enters MountainPass <gen>

Conditions:
    (Owner of (Triggering unit)) Equal to Player 1 (Red)

Actions:
    -------- Start snow when entering mountains --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_MountainPass, "snow", 0.0)
    Special Effect - Create a special effect at (Position of (Triggering unit)) using Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl
    Game - Display to (All players) the text: The mountain pass is ...
*/

//===========================================================================
// EXAMPLE 9: Advanced - Multi-Region Weather Zones
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Setup Weather Zones

Events:
    Map initialization

Actions:
    -------- Desert - No weather --------
    Custom script:   call WeatherSystem_StopRegionalWeatherAPI(gg_rct_Desert)
    -------- Jungle - Frequent rain --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Jungle, "rain_light", 0.0)
    -------- Mountains - Snow --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Mountains, "snow", 0.0)
    -------- Ocean - Storms --------
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Ocean, "storm", 0.0)
    -------- Temperate - Seasonal (no fixed weather) --------
    Game - Display to (All players) the text: Weather zones configured
*/

//===========================================================================
// EXAMPLE 10: Boss Fight Weather Effect
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Boss Weather Effect

Events:
    Unit - A unit Dies

Conditions:
    (Unit-type of (Triggering unit)) Equal to Ice Dragon

Actions:
    -------- Clear snow when boss is defeated --------
    Custom script:   call WeatherSystem_StopRegionalWeatherAPI(gg_rct_BossArena)
    Wait 2.00 seconds
    -------- Victory weather effect --------
    Custom script:   call WeatherSystem_SetGlobalWeather("none")
    Game - Display to (All players) the text: The eternal winter ...
    Special Effect - Create a special effect at (Position of (Triggering unit)) using Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl
*/

//===========================================================================
// EXAMPLE 11: Random Weather Events (Non-Seasonal)
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Random Weather Events

Events:
    Time - Every (Random real number between 200.00 and 500.00) seconds of game time

Conditions:

Actions:
    Set TempInt = (Random integer number between 1 and 5)
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            TempInt Equal to 1
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("rain_light")
            Wait (Random real number between 60.00 and 180.00) seconds
            Custom script:   call WeatherSystem_StopGlobalWeather()
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            TempInt Equal to 2
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("rain_heavy")
            Wait (Random real number between 45.00 and 120.00) seconds
            Custom script:   call WeatherSystem_StopGlobalWeather()
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            TempInt Equal to 3
        Then - Actions
            Custom script:   call WeatherSystem_SetGlobalWeather("storm")
            Wait (Random real number between 30.00 and 90.00) seconds
            Custom script:   call WeatherSystem_StopGlobalWeather()
        Else - Actions
*/

//===========================================================================
// EXAMPLE 12: Weather Configuration Menu
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Config Menu

Events:
    Player - Player 1 (Red) types a chat message containing -weather config as An exact match

Conditions:

Actions:
    Dialog - Clear Weather_Dialog
    Dialog - Change the title of Weather_Dialog to Weather Configuration
    Dialog - Create a dialog button for Weather_Dialog labelled Enable Seasonal
    Set Weather_Button[1] = (Last created dialog Button)
    Dialog - Create a dialog button for Weather_Dialog labelled Disable Seasonal
    Set Weather_Button[2] = (Last created dialog Button)
    Dialog - Create a dialog button for Weather_Dialog labelled Toggle Thunder
    Set Weather_Button[3] = (Last created dialog Button)
    Dialog - Create a dialog button for Weather_Dialog labelled Toggle Clouds
    Set Weather_Button[4] = (Last created dialog Button)
    Dialog - Create a dialog button for Weather_Dialog labelled Toggle Steam Breath
    Set Weather_Button[5] = (Last created dialog Button)
    Dialog - Show Weather_Dialog for (Triggering player)

-------- Separate trigger for button clicks --------
Trigger Name: Weather Config Clicks

Events:
    Dialog - A dialog button is clicked for Weather_Dialog

Conditions:

Actions:
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Clicked dialog button) Equal to Weather_Button[1]
        Then - Actions
            Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
            Game - Display to (All players) the text: Seasonal weather ena...
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Clicked dialog button) Equal to Weather_Button[2]
        Then - Actions
            Custom script:   call WeatherSystem_EnableSeasonalWeather(false)
            Game - Display to (All players) the text: Seasonal weather dis...
        Else - Actions
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Clicked dialog button) Equal to Weather_Button[3]
        Then - Actions
            Set Thunder_Enabled = (not Thunder_Enabled)
            Custom script:   call WeatherSystem_EnableThunderEffect(udg_Thunder_Enabled)
        Else - Actions
    -------- Similar for other buttons --------
*/

//===========================================================================
// EXAMPLE 13: Weather Damage System
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Damage

Events:
    Time - Every 5.00 seconds of game time

Conditions:

Actions:
    Custom script:   local string weather = WeatherSystem_GetCurrentWeather()
    Custom script:   if weather == "storm" then
        -------- Damage units outside during storm --------
        Unit Group - Pick every unit in (Units in (Playable map area)) and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        ((Picked unit) is in Building_Group) Equal to false
                        ((Picked unit) is alive) Equal to true
                    Then - Actions
                        Unit - Cause Neutral Hostile to damage (Picked unit), dealing 5.00 damage of attack type Spells and damage type Normal
                        Special Effect - Create a special effect attached to the overhead of (Picked unit) using Abilities\\Spells\\Other\\Drain\\ManaDrainCaster.mdl
                    Else - Actions
    Custom script:   endif
*/

//===========================================================================
// EXAMPLE 14: Season Change Event
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Season Change Events

Events:
    Time - Every 60.00 seconds of game time

Conditions:

Actions:
    Set Last_Season = Current_Season
    Custom script:   set udg_Current_Season = WeatherSystem_GetCurrentSeason()
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            Current_Season Not equal to Last_Season
        Then - Actions
            -------- Season changed! --------
            Game - Display to (All players) the text: Season changed to + Current_Season
            If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                If - Conditions
                    Current_Season Equal to winter
                Then - Actions
                    -------- Winter effects --------
                    Environment - Set sky to LordaeronWinterSky
                    Cinematic - Fade out over 1.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
                    Wait 1.00 seconds
                    Cinematic - Fade in over 2.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
                Else - Actions
        Else - Actions
*/

//===========================================================================
// EXAMPLE 15: Advanced - Weather Forecast System
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Forecast

Events:
    Player - Player 1 (Red) types a chat message containing -forecast as An exact match

Conditions:

Actions:
    Set Forecast_Days = 3
    Set Current_Day = udg_DaysPassed
    Game - Display to (All players) the text: === Weather Forecast =...
    Custom script:   local string season
    For each (Integer A) from 1 to Forecast_Days, do (Actions)
        Loop - Actions
            Set Current_Day = (Current_Day + 1)
            Custom script:   set season = GetSeasonFromDays(udg_Current_Day)
            Game - Display to (All players) the text: Day + I2S(udg_Current_Day) + : Season + season
*/

//===========================================================================
// Notes for Implementation:
// 
// 1. Copy the GUI format sections into your trigger editor
// 2. Create any referenced variables (udg_DaysPassed, etc.)
// 3. Create regions in World Editor (gg_rct_ForestRegion, etc.)
// 4. Adjust timing and values to match your gameplay
// 5. Test each trigger individually before combining
//
// Remember: Custom script lines must be exact!
//===========================================================================
