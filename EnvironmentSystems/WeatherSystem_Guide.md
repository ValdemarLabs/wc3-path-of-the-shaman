# WeatherSystem - Master Weather Control Library

## Overview

The **WeatherSystem** is a comprehensive master library that controls all weather effects in your map. It provides both global and regional weather control, seasonal weather changes based on day progression, and integrates multiple weather subsystems.

## Features

- ✅ **Global Weather Control** - Set weather effects across the entire map
- ✅ **Regional Weather Control** - Set weather in specific regions independently
- ✅ **Seasonal Weather** - Automatic weather changes based on `udg_DaysPassed`
- ✅ **Multiple Weather Types** - Rain (light/heavy), Snow, Thunderstorms
- ✅ **Integrated Effects** - Thunder, Clouds, Steam Breath, Wind, Ripples
- ✅ **Configurable Probabilities** - Control weather frequency per season
- ✅ **Duration Control** - Set how long weather lasts

## Requirements

### Required Libraries (must be in map)
1. `Snow.j` - Snow unit spawning system
2. `FrostbiteSystem.j` - Cold exposure effects
3. `Storm.j` - Thunder and lightning effects
4. `Clouds_create.j` - Cloud visual effects
5. `Clouds_destroy.j` - Cloud cleanup
6. `SteamBreath.j` - Steam breath on units

### Required Global Variables

Create these in the **Variable Editor** (F4):

```
Integer Variables:
- udg_DaysPassed (initial value: 0)
- udg_SnowIndex (initial value: 0)
- udg_SnowWaveCount (initial value: 0)
- udg_SnowDestructionZone (initial value: 0)
- udg_SnowAmounts (array, size 20)

Rect Variables:
- udg_SnowRegions (array, size 20)

Weather Effect Variables:
- udg_SnowWeather (array, size 20)

Timer Variables:
- udg_SnowTimer (array, size 20)
- udg_SnowDestroyTimer
```

## Installation

1. **Copy all required library files** to your map's trigger editor
2. **Create all required global variables** (see above)
3. **Copy WeatherSystem.j** to your map
4. **Ensure WeatherSystem loads AFTER** all dependent libraries
5. **Call initialization** in your map init trigger

## API Reference

### Global Weather Control

#### `WeatherSystem_SetGlobalWeather(weatherType)`
Sets global weather across the entire map.

**Parameters:**
- `weatherType` (string): Weather type to set
  - `"none"` - Clear weather
  - `"rain_light"` - Light rain
  - `"rain_heavy"` - Heavy rain
  - `"snow"` - Snow
  - `"storm"` - Thunderstorm

**Example:**
```jass
// Start light rain globally
call WeatherSystem_SetGlobalWeather("rain_light")

// Start heavy snow globally
call WeatherSystem_SetGlobalWeather("snow")

// Clear all weather
call WeatherSystem_SetGlobalWeather("none")
```

**GUI Example:**
```
Custom script:   call WeatherSystem_SetGlobalWeather("rain_heavy")
```

---

#### `WeatherSystem_StopGlobalWeather()`
Stops all global weather effects immediately.

**Example:**
```jass
call WeatherSystem_StopGlobalWeather()
```

**GUI Example:**
```
Custom script:   call WeatherSystem_StopGlobalWeather()
```

---

### Regional Weather Control

#### `WeatherSystem_StartRegionalWeatherAPI(region, weatherType, duration)`
Starts weather in a specific region.

**Parameters:**
- `region` (rect): Region where weather will occur
- `weatherType` (string): Type of weather (see global weather types)
- `duration` (real): How long weather lasts in seconds (0 = permanent)

**Example:**
```jass
// Start rain in a region for 120 seconds
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_ForestArea, "rain_light", 120.0)

// Start permanent snow in mountain region
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Mountains, "snow", 0.0)
```

**GUI Example:**
```
Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_ForestArea, "rain_light", 120.0)
```

---

#### `WeatherSystem_StopRegionalWeatherAPI(region)`
Stops weather in a specific region.

**Parameters:**
- `region` (rect): Region to stop weather in

**Example:**
```jass
call WeatherSystem_StopRegionalWeatherAPI(gg_rct_ForestArea)
```

**GUI Example:**
```
Custom script:   call WeatherSystem_StopRegionalWeatherAPI(gg_rct_ForestArea)
```

---

### Seasonal Weather System

#### `WeatherSystem_EnableSeasonalWeather(enable)`
Enables or disables automatic seasonal weather changes.

**Parameters:**
- `enable` (boolean): true to enable, false to disable

**Example:**
```jass
// Enable seasonal weather
call WeatherSystem_EnableSeasonalWeather(true)

// Disable seasonal weather
call WeatherSystem_EnableSeasonalWeather(false)
```

**GUI Example:**
```
Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

**How it works:**
- System checks `udg_DaysPassed` variable
- Automatically determines season based on day ranges:
  - **Spring**: Days 0-89
  - **Summer**: Days 90-179
  - **Autumn**: Days 180-269
  - **Winter**: Days 270-359
- Each season has different weather probabilities
- Weather changes occur automatically based on configured intervals

---

#### `WeatherSystem_SetSeason(season)`
Manually sets the current season.

**Parameters:**
- `season` (string): Season to set
  - `"spring"` - Spring season
  - `"summer"` - Summer season
  - `"autumn"` - Autumn season
  - `"winter"` - Winter season

**Example:**
```jass
call WeatherSystem_SetSeason("winter")
```

**GUI Example:**
```
Custom script:   call WeatherSystem_SetSeason("winter")
```

---

#### `WeatherSystem_UpdateSeason()`
Updates the season based on current `udg_DaysPassed` value.

**Example:**
```jass
call WeatherSystem_UpdateSeason()
```

**GUI Example:**
```
Custom script:   call WeatherSystem_UpdateSeason()
```

---

### Weather Effects Control

#### `WeatherSystem_EnableThunderEffect(enable)`
Enables or disables thunder/lightning effects.

**Parameters:**
- `enable` (boolean): true to enable, false to disable

**Example:**
```jass
call WeatherSystem_EnableThunderEffect(true)
```

---

#### `WeatherSystem_EnableCloudsEffect(enable)`
Enables or disables cloud visual effects.

**Parameters:**
- `enable` (boolean): true to enable, false to disable

**Example:**
```jass
call WeatherSystem_EnableCloudsEffect(true)
```

---

#### `WeatherSystem_EnableSteamBreathEffect(enable)`
Enables or disables steam breath effects on units.

**Parameters:**
- `enable` (boolean): true to enable, false to disable

**Example:**
```jass
call WeatherSystem_EnableSteamBreathEffect(true)
```

---

#### `WeatherSystem_EnableWindEffect(enable)`
Enables or disables wind effects (placeholder for future implementation).

**Parameters:**
- `enable` (boolean): true to enable, false to disable

**Example:**
```jass
call WeatherSystem_EnableWindEffect(true)
```

---

### Configuration Functions

#### `WeatherSystem_SetRainChance(chance)`
Sets the probability of rain occurring.

**Parameters:**
- `chance` (real): Probability from 0.0 to 1.0

**Example:**
```jass
call WeatherSystem_SetRainChance(0.5) // 50% chance
```

---

#### `WeatherSystem_SetSnowChance(chance)`
Sets the probability of snow occurring.

**Parameters:**
- `chance` (real): Probability from 0.0 to 1.0

**Example:**
```jass
call WeatherSystem_SetSnowChance(0.3) // 30% chance
```

---

#### `WeatherSystem_SetStormChance(chance)`
Sets the probability of storms occurring.

**Parameters:**
- `chance` (real): Probability from 0.0 to 1.0

**Example:**
```jass
call WeatherSystem_SetStormChance(0.2) // 20% chance
```

---

### Query Functions

#### `WeatherSystem_GetCurrentWeather()` → string
Returns the current global weather type.

**Returns:** String representing current weather ("none", "rain_light", "rain_heavy", "snow", "storm")

**Example:**
```jass
local string weather = WeatherSystem_GetCurrentWeather()
if weather == "snow" then
    // Do something during snow
endif
```

---

#### `WeatherSystem_GetRegionalWeather(region)` → string
Returns the weather type for a specific region.

**Parameters:**
- `region` (rect): Region to check

**Returns:** String representing weather in that region

**Example:**
```jass
local string weather = WeatherSystem_GetRegionalWeather(gg_rct_Forest)
```

---

#### `WeatherSystem_GetCurrentSeason()` → string
Returns the current season.

**Returns:** String representing current season ("spring", "summer", "autumn", "winter")

**Example:**
```jass
local string season = WeatherSystem_GetCurrentSeason()
if season == "winter" then
    // Do something in winter
endif
```

---

## Configuration Constants

You can modify these constants in `WeatherSystem.j` to customize the system:

### Season Day Ranges
```jass
SPRING_START       = 0
SPRING_END         = 89
SUMMER_START       = 90
SUMMER_END         = 179
AUTUMN_START       = 180
AUTUMN_END         = 269
WINTER_START       = 270
WINTER_END         = 359
```

### Weather Duration Ranges (seconds)
```jass
RAIN_MIN_DURATION     = 60.0
RAIN_MAX_DURATION     = 360.0
SNOW_MIN_DURATION     = 120.0
SNOW_MAX_DURATION     = 600.0
STORM_MIN_DURATION    = 30.0
STORM_MAX_DURATION    = 120.0
```

### Check Intervals (seconds)
```jass
WEATHER_CHECK_INTERVAL = 250.0  // How often to check for weather changes
SEASON_CHECK_INTERVAL  = 60.0   // How often to update season
```

### Regional Settings
```jass
MAX_WEATHER_REGIONS = 20  // Maximum number of regions with independent weather
```

---

## Seasonal Weather Probabilities

The system automatically adjusts weather probabilities based on the season:

### Spring
- Rain: 50% (high)
- Snow: 0%
- Storm: 20%

### Summer
- Rain: 20%
- Snow: 0%
- Storm: 30% (high)

### Autumn
- Rain: 40% (moderate)
- Snow: 20% (light)
- Storm: 10%

### Winter
- Rain: 10%
- Snow: 70% (high)
- Storm: 10%

---

## GUI Trigger Examples

### Example 1: Enable Seasonal Weather on Map Init
```
Map Initialization
    Events
        Map initialization
    Conditions
    Actions
        Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

### Example 2: Manual Rain in Region
```
Start Rain in Forest
    Events
        Player - Player 1 (Red) types a chat message containing rain forest as An exact match
    Conditions
    Actions
        Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Forest, "rain_heavy", 120.0)
```

### Example 3: Stop All Weather
```
Clear Weather
    Events
        Player - Player 1 (Red) types a chat message containing clear weather as An exact match
    Conditions
    Actions
        Custom script:   call WeatherSystem_StopGlobalWeather()
```

### Example 4: Winter Event with Snow
```
Winter Quest Start
    Events
        Unit - A unit enters WinterQuest <gen>
    Conditions
    Actions
        Custom script:   call WeatherSystem_SetSeason("winter")
        Custom script:   call WeatherSystem_SetGlobalWeather("snow")
        Custom script:   call WeatherSystem_EnableThunderEffect(false)
        Custom script:   call WeatherSystem_EnableCloudsEffect(true)
        Custom script:   call WeatherSystem_EnableSteamBreathEffect(true)
```

### Example 5: Day/Night Cycle with Season Update
```
Day Night Cycle
    Events
        Time - Every 24.00 seconds of game time
    Conditions
    Actions
        Set VariableSet udg_DaysPassed = (udg_DaysPassed + 1)
        Custom script:   call WeatherSystem_UpdateSeason()
```

### Example 6: Random Weather Event
```
Random Weather Event
    Events
        Time - Every 300.00 seconds of game time
    Conditions
    Actions
        Set VariableSet WeatherRoll = (Random integer number between 1 and 4)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                WeatherRoll Equal to 1
            Then - Actions
                Custom script:   call WeatherSystem_SetGlobalWeather("rain_light")
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                WeatherRoll Equal to 2
            Then - Actions
                Custom script:   call WeatherSystem_SetGlobalWeather("snow")
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                WeatherRoll Equal to 3
            Then - Actions
                Custom script:   call WeatherSystem_SetGlobalWeather("storm")
            Else - Actions
                Custom script:   call WeatherSystem_SetGlobalWeather("none")
```

### Example 7: Regional Snow Zones (Multiple)
```
Setup Snow Zones
    Events
        Map initialization
    Conditions
    Actions
        Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_NorthMountains, "snow", 0.0)
        Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_IcePeaks, "snow", 0.0)
        Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_FrozenWastes, "snow", 0.0)
```

### Example 8: Weather-Based Quest Trigger
```
Check if Raining
    Events
        Time - Every 5.00 seconds of game time
    Conditions
    Actions
        Custom script:   local string w = WeatherSystem_GetCurrentWeather()
        Custom script:   if w == "rain_heavy" or w == "rain_light" then
        Quest - Display to (All players) the Quest Update message: Rain Quest Available!
        Custom script:   endif
```

---

## Integration with Existing Systems

### Frostbite System
The WeatherSystem automatically works with FrostbiteSystem:
- Snow weather should be paired with cold aura zones
- Steam breath effects are enabled during cold weather
- Use frostbite events to trigger additional weather effects

### Storm System
Thunder and lightning effects use the Storm.j library:
- Thunder occurs during heavy rain and storms
- Frequency controlled by `ThunderTimer` (every 15 seconds)
- Random lightning strikes during storms

### Snow System
Regional snow integrates with Snow.j:
- Snow units spawn in waves
- Gradual destruction when weather clears
- Configurable snow amounts per region

---

## Advanced Usage

### Creating Weather Zones
```jass
// Create a permanent rain zone
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_RainForest, "rain_light", 0.0)

// Create a temporary storm
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Battlefield, "storm", 180.0)

// Stack with global weather
call WeatherSystem_SetGlobalWeather("rain_light")
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Mountains, "snow", 0.0)
```

### Dynamic Season Changes
```jass
// Progress through seasons faster
set udg_DaysPassed = 90  // Jump to summer
call WeatherSystem_UpdateSeason()

// Lock to specific season
call WeatherSystem_SetSeason("winter")
call WeatherSystem_EnableSeasonalWeather(false) // Prevent auto-change
```

### Weather-Based Gameplay
```jass
// Check weather for quest conditions
if WeatherSystem_GetCurrentWeather() == "snow" then
    call EnableTrigger(gg_trg_SnowQuest)
endif

// Seasonal shop items
if WeatherSystem_GetCurrentSeason() == "winter" then
    call AddItemToStock(u, 'I000', 1, 1) // Winter gear
endif
```

---

## Troubleshooting

### Weather Not Appearing
1. Check that all required libraries are imported
2. Verify global variables are created
3. Ensure WeatherSystem loads AFTER dependencies
4. Check that seasonal weather is enabled if using automatic mode

### Thunder/Lightning Not Working
1. Verify Storm.j is properly imported
2. Check that Ldummy unit ('h000') exists
3. Import lightning models (L1.mdx, L2.mdx, L3.mdx)
4. Import thunder sounds (T1.wav, T2.wav, T3.wav)

### Regional Weather Not Working
1. Ensure regions are created in World Editor
2. Check region variable names match (gg_rct_RegionName)
3. Verify MAX_WEATHER_REGIONS hasn't been exceeded

### Steam Breath Not Showing
1. Check that SteamBreath.j is imported
2. Verify steam breath model exists in map
3. Ensure units aren't mechanical/structure/summoned

---

## Performance Considerations

- Regional weather has a maximum of 20 active regions
- Seasonal weather checks occur every 250 seconds by default
- Thunder effects check every 15 seconds when active
- Cloud effects spawn 20 clouds maximum
- Steam breath supports up to 1000 units

To optimize performance:
- Reduce `CLOUD_COUNT` if needed
- Increase `WEATHER_CHECK_INTERVAL` for less frequent changes
- Limit active regional weather zones
- Disable unused effects (wind, clouds, etc.)

---

## Version History

### Version 1.0
- Initial release
- Global and regional weather control
- Seasonal weather system
- Integration with existing weather libraries
- Thunder, clouds, steam breath effects
- Configurable weather probabilities

---

## Credits

- **WeatherSystem**: Valdemar
- **Snow System**: Valdemar
- **Frostbite System**: Valdemar
- **Storm System**: OVOgenez
- **Cloud Effects**: Valdemar
- **Steam Breath**: Valdemar

---

## Support

For issues, questions, or suggestions, please refer to your map's documentation or trigger comments in the World Editor.
