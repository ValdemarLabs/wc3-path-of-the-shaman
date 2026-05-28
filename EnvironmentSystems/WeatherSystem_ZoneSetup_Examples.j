//===========================================================================
// WeatherSystem 2.0 - Zone-Based Setup Examples
// Copy these triggers into your World Editor
//===========================================================================

//===========================================================================
// EXAMPLE 1: Basic Zone Setup (Map Initialization)
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Zones Init

Events:
    Map initialization

Actions:
    -------- Create Master Zones --------
    Custom script:   call WeatherSystem_CreateMasterZone("Mountains", "snow", "auto")
    Custom script:   call WeatherSystem_CreateMasterZone("Forest", "none", "auto")
    Custom script:   call WeatherSystem_CreateMasterZone("Desert", "none", "auto")
    Custom script:   call WeatherSystem_CreateMasterZone("Ocean", "rain_light", "auto")
    Custom script:   call WeatherSystem_CreateMasterZone("Tundra", "snow", "winter")
    
    -------- Add Regions to Zones --------
    Custom script:   call WeatherSystem_AddRegionToZone("Mountains", gg_rct_NorthPeak)
    Custom script:   call WeatherSystem_AddRegionToZone("Mountains", gg_rct_SouthPeak)
    Custom script:   call WeatherSystem_AddRegionToZone("Mountains", gg_rct_MountainPass)
    
    Custom script:   call WeatherSystem_AddRegionToZone("Forest", gg_rct_DarkForest)
    Custom script:   call WeatherSystem_AddRegionToZone("Forest", gg_rct_ElvenWoods)
    
    Custom script:   call WeatherSystem_AddRegionToZone("Desert", gg_rct_SandDunes)
    Custom script:   call WeatherSystem_AddRegionToZone("Desert", gg_rct_Oasis)
    
    Custom script:   call WeatherSystem_AddRegionToZone("Ocean", gg_rct_CoastalWaters)
    Custom script:   call WeatherSystem_AddRegionToZone("Ocean", gg_rct_DeepSea)
    
    Custom script:   call WeatherSystem_AddRegionToZone("Tundra", gg_rct_FrozenWastes)
    
    -------- Enable Seasonal Weather --------
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
    
    Game - Display to (All players) the text: Weather zones initialized
*/

//===========================================================================
// EXAMPLE 2: Zone-Specific Configuration
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Configure Zone Weather

Events:
    Map initialization

Actions:
    -------- Mountains: Permanent snow with high snow chance --------
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Mountains", "snow", 0.9)
    Custom script:   call WeatherSystem_EnableZoneThunder("Mountains", false)
    Custom script:   call WeatherSystem_EnableZoneClouds("Mountains", true)
    Custom script:   call WeatherSystem_EnableZoneSteamBreath("Mountains", true)
    
    -------- Forest: Seasonal rain, no thunder --------
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Forest", "rain_light", 0.6)
    Custom script:   call WeatherSystem_EnableZoneThunder("Forest", false)
    Custom script:   call WeatherSystem_EnableZoneClouds("Forest", true)
    
    -------- Desert: Minimal weather, occasional storms --------
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Desert", "rain_light", 0.05)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Desert", "storm", 0.15)
    Custom script:   call WeatherSystem_EnableZoneClouds("Desert", false)
    Custom script:   call WeatherSystem_EnableZoneSteamBreath("Desert", false)
    
    -------- Ocean: High rain and storms --------
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Ocean", "rain_heavy", 0.7)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Ocean", "storm", 0.5)
    Custom script:   call WeatherSystem_EnableZoneThunder("Ocean", true)
    
    -------- Tundra: Locked to winter season with permanent snow --------
    Custom script:   call WeatherSystem_SetZoneSeason("Tundra", "winter")
    Custom script:   call WeatherSystem_SetZoneSeasonalBehavior("Tundra", false)
    Custom script:   call WeatherSystem_SetZoneWeather("Tundra", "snow", 0.0)
*/

//===========================================================================
// EXAMPLE 3: Manual Zone Weather Control
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Quest Weather Event

Events:
    Unit - A unit enters QuestStart <gen>

Conditions:
    (Unit-type of (Triggering unit)) Equal to Footman

Actions:
    Game - Display to (All players) the text: A storm approaches th...
    Wait 3.00 seconds
    
    -------- Start heavy rain in Forest zone for 3 minutes --------
    Custom script:   call WeatherSystem_SetZoneWeather("Forest", "rain_heavy", 180.0)
    
    -------- Storm in Ocean zone for 2 minutes --------
    Custom script:   call WeatherSystem_SetZoneWeather("Ocean", "storm", 120.0)
    
    Wait 180.00 seconds
    Game - Display to (All players) the text: The storm passes...
*/

//===========================================================================
// EXAMPLE 4: Regional Weather Override (Zone weather continues elsewhere)
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Cave Weather Control

Events:
    Unit - A unit enters CaveEntrance <gen>

Conditions:

Actions:
    -------- Clear weather in this specific region --------
    Custom script:   call WeatherSystem_StopRegionWeather(gg_rct_CaveEntrance)
    
    Game - Display to (All players) the text: You enter a sheltered...
*/

//===========================================================================
// EXAMPLE 5: Boss Fight Weather
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Boss Weather Start

Events:
    Unit - IceDragon 0001 <gen> enters BossArena <gen>

Conditions:

Actions:
    -------- Lock Mountains zone to eternal winter --------
    Custom script:   call WeatherSystem_SetZoneSeason("Mountains", "winter")
    Custom script:   call WeatherSystem_SetZoneSeasonalBehavior("Mountains", false)
    
    -------- Start permanent blizzard --------
    Custom script:   call WeatherSystem_SetZoneWeather("Mountains", "snow", 0.0)
    Custom script:   call WeatherSystem_EnableZoneThunder("Mountains", true)
    
    Game - Display to (All players) the text: The dragon summons an...


Trigger Name: Boss Weather End

Events:
    Unit - IceDragon 0001 <gen> Dies

Conditions:

Actions:
    -------- Clear weather in zone --------
    Custom script:   call WeatherSystem_StopZoneWeather("Mountains")
    
    -------- Re-enable seasonal weather --------
    Custom script:   call WeatherSystem_SetZoneSeason("Mountains", "auto")
    Custom script:   call WeatherSystem_SetZoneSeasonalBehavior("Mountains", true)
    
    Game - Display to (All players) the text: The eternal winter su...
*/

//===========================================================================
// EXAMPLE 6: Dynamic Zone Creation
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Create Dynamic Weather Zone

Events:
    Player - Player 1 (Red) types a chat message containing -createzone as An exact match

Conditions:

Actions:
    -------- Create new zone on-the-fly --------
    Custom script:   call WeatherSystem_CreateMasterZone("BattleZone", "storm", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("BattleZone", gg_rct_BattleArea01)
    Custom script:   call WeatherSystem_AddRegionToZone("BattleZone", gg_rct_BattleArea02)
    Custom script:   call WeatherSystem_AddRegionToZone("BattleZone", gg_rct_BattleArea03)
    
    -------- Start weather immediately --------
    Custom script:   call WeatherSystem_SetZoneWeather("BattleZone", "storm", 300.0)
    
    Game - Display to (All players) the text: Battle zone created w...
*/

//===========================================================================
// EXAMPLE 7: Seasonal Zone Weather Checking
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Check Zone Weather

Events:
    Time - Every 30.00 seconds of game time

Conditions:

Actions:
    Custom script:   local string weather = WeatherSystem_GetZoneWeather("Forest")
    Custom script:   if weather == "rain_heavy" or weather == "rain_light" then
        -------- Spawn mushrooms during rain in forest --------
        Unit - Create 5 Mushroom for Neutral Passive at (Center of ForestSpawn <gen>) facing Default building facing degrees
        Game - Display to (All players) the text: Mushrooms sprout in ...
    Custom script:   endif
    
    Custom script:   set weather = WeatherSystem_GetZoneWeather("Mountains")
    Custom script:   if weather == "snow" then
        -------- Spawn ice creatures in snowy mountains --------
        Unit - Create 3 Ice Troll for Neutral Hostile at (Center of MountainSpawn <gen>) facing Default building facing degrees
    Custom script:   endif
*/

//===========================================================================
// EXAMPLE 8: Multi-Zone Configuration
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Setup World Zones

Events:
    Map initialization

Actions:
    -------- NORTHERN REGIONS --------
    Custom script:   call WeatherSystem_CreateMasterZone("North", "snow", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("North", gg_rct_NorthVillage)
    Custom script:   call WeatherSystem_AddRegionToZone("North", gg_rct_NorthFields)
    Custom script:   call WeatherSystem_AddRegionToZone("North", gg_rct_NorthRoad)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("North", "snow", 0.8)
    
    -------- CENTRAL REGIONS --------
    Custom script:   call WeatherSystem_CreateMasterZone("Central", "rain_light", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("Central", gg_rct_CentralCity)
    Custom script:   call WeatherSystem_AddRegionToZone("Central", gg_rct_CentralMarket)
    Custom script:   call WeatherSystem_AddRegionToZone("Central", gg_rct_CentralGates)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Central", "rain_light", 0.4)
    
    -------- SOUTHERN REGIONS --------
    Custom script:   call WeatherSystem_CreateMasterZone("South", "none", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("South", gg_rct_SouthDesert)
    Custom script:   call WeatherSystem_AddRegionToZone("South", gg_rct_SouthOasis)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("South", "rain_light", 0.1)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("South", "storm", 0.2)
    
    -------- EASTERN REGIONS --------
    Custom script:   call WeatherSystem_CreateMasterZone("East", "rain_heavy", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("East", gg_rct_EastJungle)
    Custom script:   call WeatherSystem_AddRegionToZone("East", gg_rct_EastSwamp)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("East", "rain_heavy", 0.7)
    
    -------- WESTERN REGIONS --------
    Custom script:   call WeatherSystem_CreateMasterZone("West", "none", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("West", gg_rct_WestCoast)
    Custom script:   call WeatherSystem_AddRegionToZone("West", gg_rct_WestPort)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("West", "storm", 0.4)
    
    Game - Display to (All players) the text: World weather zones c...
*/

//===========================================================================
// EXAMPLE 9: Day/Night Cycle with Seasonal Updates
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Day Night Weather Cycle

Events:
    Time - Every 24.00 seconds of game time

Actions:
    -------- Increment day counter --------
    Set udg_DaysPassed = (udg_DaysPassed + 1)
    
    -------- Season automatically updates via WeatherSystem --------
    -------- Display current day and season --------
    Custom script:   local string season = WeatherSystem_GetCurrentSeason()
    Game - Display to (All players) the text: Day + I2S(udg_DaysPassed) + , Season: + (Local variable season)
*/

//===========================================================================
// EXAMPLE 10: Query Zone Information
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Display Zone Info

Events:
    Player - Player 1 (Red) types a chat message containing -zoneinfo as An exact match

Conditions:

Actions:
    Game - Display to (All players) the text: === ZONE WEATHER INF...
    
    Custom script:   local string weather
    Custom script:   set weather = WeatherSystem_GetZoneWeather("Mountains")
    Game - Display to (All players) the text: Mountains: + (Local variable weather)
    
    Custom script:   set weather = WeatherSystem_GetZoneWeather("Forest")
    Game - Display to (All players) the text: Forest: + (Local variable weather)
    
    Custom script:   set weather = WeatherSystem_GetZoneWeather("Desert")
    Game - Display to (All players) the text: Desert: + (Local variable weather)
    
    Custom script:   set weather = WeatherSystem_GetZoneWeather("Ocean")
    Game - Display to (All players) the text: Ocean: + (Local variable weather)
*/

//===========================================================================
// EXAMPLE 11: Check Which Zone a Region Belongs To
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Unit Enters Region

Events:
    Unit - A unit enters PlayableMapArea <gen>

Conditions:
    (Owner of (Triggering unit)) Equal to Player 1 (Red)

Actions:
    Custom script:   local string zoneName = WeatherSystem_GetRegionZone(GetTriggeringRegion())
    Custom script:   local string weather = WeatherSystem_GetRegionWeather(GetTriggeringRegion())
    
    Game - Display to (All players) the text: Entered zone: + (Local variable zoneName)
    Game - Display to (All players) the text: Current weather: + (Local variable weather)
*/

//===========================================================================
// EXAMPLE 12: Advanced Zone Configuration (RPG Setup)
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: RPG Weather Setup

Events:
    Map initialization

Actions:
    -------- STARTER ZONE: Always clear --------
    Custom script:   call WeatherSystem_CreateMasterZone("StarterZone", "none", "spring")
    Custom script:   call WeatherSystem_AddRegionToZone("StarterZone", gg_rct_Tutorial)
    Custom script:   call WeatherSystem_AddRegionToZone("StarterZone", gg_rct_StartingVillage)
    Custom script:   call WeatherSystem_SetZoneSeasonalBehavior("StarterZone", false)
    
    -------- DARK LANDS: Always stormy --------
    Custom script:   call WeatherSystem_CreateMasterZone("DarkLands", "storm", "winter")
    Custom script:   call WeatherSystem_AddRegionToZone("DarkLands", gg_rct_Shadowlands)
    Custom script:   call WeatherSystem_AddRegionToZone("DarkLands", gg_rct_DeadForest)
    Custom script:   call WeatherSystem_SetZoneSeasonalBehavior("DarkLands", false)
    Custom script:   call WeatherSystem_SetZoneWeather("DarkLands", "storm", 0.0)
    
    -------- PEACEFUL MEADOWS: Light seasonal weather --------
    Custom script:   call WeatherSystem_CreateMasterZone("Meadows", "none", "auto")
    Custom script:   call WeatherSystem_AddRegionToZone("Meadows", gg_rct_GreenFields)
    Custom script:   call WeatherSystem_AddRegionToZone("Meadows", gg_rct_Farm)
    Custom script:   call WeatherSystem_SetZoneWeatherChance("Meadows", "rain_light", 0.3)
    Custom script:   call WeatherSystem_EnableZoneThunder("Meadows", false)
    
    -------- ICE REALM: Eternal winter --------
    Custom script:   call WeatherSystem_CreateMasterZone("IceRealm", "snow", "winter")
    Custom script:   call WeatherSystem_AddRegionToZone("IceRealm", gg_rct_IceCastle)
    Custom script:   call WeatherSystem_AddRegionToZone("IceRealm", gg_rct_FrozenLake)
    Custom script:   call WeatherSystem_SetZoneSeasonalBehavior("IceRealm", false)
    Custom script:   call WeatherSystem_SetZoneWeather("IceRealm", "snow", 0.0)
    Custom script:   call WeatherSystem_EnableZoneSteamBreath("IceRealm", true)
    
    -------- Enable global seasonal system --------
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
    
    Game - Display to (All players) the text: RPG weather zones rea...
*/

//===========================================================================
// EXAMPLE 13: Stop All Weather in Zone (Safe Haven)
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Safe Haven Weather

Events:
    Unit - A unit enters SafeHaven <gen>

Conditions:
    ((Triggering unit) is A Hero) Equal to true

Actions:
    -------- Stop weather in specific region only --------
    Custom script:   call WeatherSystem_StopRegionWeather(gg_rct_SafeHaven)
    
    Special Effect - Create a special effect at (Position of (Triggering unit)) using Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl
    Game - Display to (All players) the text: Protected by ancient ...
*/

//===========================================================================
// EXAMPLE 14: Debug Commands
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Weather Debug Commands

Events:
    Player - Player 1 (Red) types a chat message containing -weather as A substring

Conditions:

Actions:
    -------- Zone rain --------
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to -weather mountains rain
        Then - Actions
            Custom script:   call WeatherSystem_SetZoneWeather("Mountains", "rain_heavy", 120.0)
        Else - Actions
    
    -------- Zone snow --------
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to -weather mountains snow
        Then - Actions
            Custom script:   call WeatherSystem_SetZoneWeather("Mountains", "snow", 0.0)
        Else - Actions
    
    -------- Zone clear --------
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to -weather mountains clear
        Then - Actions
            Custom script:   call WeatherSystem_StopZoneWeather("Mountains")
        Else - Actions
    
    -------- Show info --------
    If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        If - Conditions
            (Entered chat string) Equal to -weather info
        Then - Actions
            Custom script:   local string s = WeatherSystem_GetCurrentSeason()
            Custom script:   local string w1 = WeatherSystem_GetZoneWeather("Mountains")
            Custom script:   local string w2 = WeatherSystem_GetZoneWeather("Forest")
            Game - Display to (All players) the text: Season: + s
            Game - Display to (All players) the text: Mountains: + w1
            Game - Display to (All players) the text: Forest: + w2
        Else - Actions
*/

//===========================================================================
// EXAMPLE 15: Seasonal Shop based on Zone Weather
//===========================================================================
/*
GUI Format:
-----------
Trigger Name: Seasonal Shop Setup

Events:
    Time - Every 60.00 seconds of game time

Conditions:

Actions:
    Custom script:   local string weather = WeatherSystem_GetZoneWeather("Mountains")
    Custom script:   local unit shop = gg_unit_n000_0001
    
    -------- Clear shop inventory --------
    Neutral Building - Remove all items from (Last created unit) of type Campaign
    
    Custom script:   if weather == "snow" then
        -------- Winter gear available --------
        Neutral Building - Add FrostArmor to (Last created unit) with 1 in stock and a max stock of 1
        Neutral Building - Add WinterCloak to (Last created unit) with 1 in stock and a max stock of 1
        Game - Display to (All players) the text: Shop updated: Winter...
    Custom script:   elseif weather == "rain_heavy" or weather == "rain_light" then
        -------- Rain gear available --------
        Neutral Building - Add Umbrella to (Last created unit) with 1 in stock and a max stock of 1
        Neutral Building - Add WaterproofBoots to (Last created unit) with 1 in stock and a max stock of 1
        Game - Display to (All players) the text: Shop updated: Rain ge...
    Custom script:   else
        -------- Normal items --------
        Neutral Building - Add StandardGear to (Last created unit) with 1 in stock and a max stock of 1
    Custom script:   endif
*/

//===========================================================================
// ZONE CONFIGURATION TEMPLATE
//===========================================================================
/*
Copy and modify this template for your map:

Custom script:   call WeatherSystem_CreateMasterZone("ZoneName", "none", "auto")
Custom script:   call WeatherSystem_AddRegionToZone("ZoneName", gg_rct_Region1)
Custom script:   call WeatherSystem_AddRegionToZone("ZoneName", gg_rct_Region2)
Custom script:   call WeatherSystem_SetZoneWeatherChance("ZoneName", "rain_light", 0.4)
Custom script:   call WeatherSystem_SetZoneWeatherChance("ZoneName", "snow", 0.3)
Custom script:   call WeatherSystem_SetZoneWeatherChance("ZoneName", "storm", 0.2)
Custom script:   call WeatherSystem_EnableZoneThunder("ZoneName", true)
Custom script:   call WeatherSystem_EnableZoneClouds("ZoneName", true)
Custom script:   call WeatherSystem_EnableZoneSteamBreath("ZoneName", true)

Weather Types:
- "none"
- "rain_light"
- "rain_heavy"
- "snow"
- "storm"

Season Options:
- "auto" (follows global season based on udg_DaysPassed)
- "spring"
- "summer"
- "autumn"
- "winter"
*/
