# WeatherSystem - Quick Reference Card

## Most Common Commands (Copy & Paste)

### Starting Weather

```jass
// Light Rain
call WeatherSystem_SetGlobalWeather("rain_light")

// Heavy Rain
call WeatherSystem_SetGlobalWeather("rain_heavy")

// Snow
call WeatherSystem_SetGlobalWeather("snow")

// Thunderstorm
call WeatherSystem_SetGlobalWeather("storm")

// Clear Weather
call WeatherSystem_SetGlobalWeather("none")
// OR
call WeatherSystem_StopGlobalWeather()
```

### Regional Weather

```jass
// Start rain in a region for 2 minutes
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_YourRegion, "rain_light", 120.0)

// Start permanent snow in mountains
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Mountains, "snow", 0.0)

// Stop weather in region
call WeatherSystem_StopRegionalWeatherAPI(gg_rct_YourRegion)
```

### Seasonal System

```jass
// Enable automatic seasonal weather
call WeatherSystem_EnableSeasonalWeather(true)

// Disable automatic seasonal weather
call WeatherSystem_EnableSeasonalWeather(false)

// Force a specific season
call WeatherSystem_SetSeason("winter")
call WeatherSystem_SetSeason("spring")
call WeatherSystem_SetSeason("summer")
call WeatherSystem_SetSeason("autumn")

// Update season from udg_DaysPassed
call WeatherSystem_UpdateSeason()
```

### Effects Control

```jass
// Enable/Disable Thunder
call WeatherSystem_EnableThunderEffect(true)
call WeatherSystem_EnableThunderEffect(false)

// Enable/Disable Clouds
call WeatherSystem_EnableCloudsEffect(true)
call WeatherSystem_EnableCloudsEffect(false)

// Enable/Disable Steam Breath
call WeatherSystem_EnableSteamBreathEffect(true)
call WeatherSystem_EnableSteamBreathEffect(false)

// Enable/Disable Wind
call WeatherSystem_EnableWindEffect(true)
call WeatherSystem_EnableWindEffect(false)
```

### Query Functions

```jass
// Get current weather
local string weather = WeatherSystem_GetCurrentWeather()

// Get weather in region
local string weather = WeatherSystem_GetRegionalWeather(gg_rct_YourRegion)

// Get current season
local string season = WeatherSystem_GetCurrentSeason()
```

### Configuration

```jass
// Set weather chances (0.0 to 1.0)
call WeatherSystem_SetRainChance(0.5)
call WeatherSystem_SetSnowChance(0.3)
call WeatherSystem_SetStormChance(0.2)
```

---

## GUI Trigger Examples

### Map Init - Basic Setup
```
Events:
    Map initialization
Actions:
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

### Debug Command - Manual Weather
```
Events:
    Player - Player 1 (Red) types a chat message containing rain as An exact match
Actions:
    Custom script:   call WeatherSystem_SetGlobalWeather("rain_heavy")
```

### Day/Night Cycle - Season Update
```
Events:
    Time - Every 24.00 seconds of game time
Actions:
    Set udg_DaysPassed = (udg_DaysPassed + 1)
    Custom script:   call WeatherSystem_UpdateSeason()
```

### Regional Weather on Unit Enter
```
Events:
    Unit - A unit enters YourRegion <gen>
Actions:
    Custom script:   call WeatherSystem_StartRegionalWeatherAPI(gg_rct_YourRegion, "snow", 0.0)
```

---

## Weather Types

| Type | String | Description |
|------|--------|-------------|
| None | `"none"` | Clear weather |
| Light Rain | `"rain_light"` | Light rain with ripples |
| Heavy Rain | `"rain_heavy"` | Heavy rain with thunder |
| Snow | `"snow"` | Snow with steam breath |
| Storm | `"storm"` | Heavy rain with thunder/lightning |

---

## Seasons

| Season | String | Days | Typical Weather |
|--------|--------|------|-----------------|
| Spring | `"spring"` | 0-89 | High rain |
| Summer | `"summer"` | 90-179 | Low rain, high storms |
| Autumn | `"autumn"` | 180-269 | Moderate rain, some snow |
| Winter | `"winter"` | 270-359 | High snow |

---

## Required Global Variables (Variable Editor - F4)

```
udg_DaysPassed (Integer)
udg_SnowIndex (Integer)
udg_SnowWaveCount (Integer)
udg_SnowDestructionZone (Integer)
udg_SnowAmounts[20] (Integer Array)
udg_SnowRegions[20] (Rect Array)
udg_SnowWeather[20] (Weather Effect Array)
udg_SnowTimer[20] (Timer Array)
udg_SnowDestroyTimer (Timer)
```

---

## Common Patterns

### Pattern 1: Timed Weather Event
```jass
// Start rain for 3 minutes then stop
call WeatherSystem_SetGlobalWeather("rain_heavy")
call TriggerSleepAction(180.0)
call WeatherSystem_StopGlobalWeather()
```

### Pattern 2: Permanent Regional Weather
```jass
// Mountain always has snow
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Mountains, "snow", 0.0)

// Jungle always has light rain
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Jungle, "rain_light", 0.0)
```

### Pattern 3: Seasonal Check
```jass
local string season = WeatherSystem_GetCurrentSeason()
if season == "winter" then
    // Enable winter content
endif
```

### Pattern 4: Weather-Based Spawning
```jass
local string weather = WeatherSystem_GetCurrentWeather()
if weather == "snow" then
    // Spawn ice creatures
elseif weather == "storm" then
    // Spawn lightning elementals
endif
```

---

## Error Checking

### Check if weather is active
```jass
if WeatherSystem_GetCurrentWeather() != "none" then
    call BJDebugMsg("Weather is active")
endif
```

### Check if regional weather exists
```jass
if WeatherSystem_GetRegionalWeather(gg_rct_MyRegion) != "none" then
    call BJDebugMsg("Region has weather")
endif
```

---

## Performance Tips

### Low Performance Map
```jass
// Reduce effects
call WeatherSystem_EnableCloudsEffect(false)
call WeatherSystem_EnableSteamBreathEffect(false)

// Increase check intervals (in WeatherSystem.j)
WEATHER_CHECK_INTERVAL = 500.0
CLOUD_COUNT = 10
MAX_UNITS = 500
```

### High Quality Map
```jass
// Enable all effects
call WeatherSystem_EnableThunderEffect(true)
call WeatherSystem_EnableCloudsEffect(true)
call WeatherSystem_EnableSteamBreathEffect(true)

// More frequent updates (in WeatherSystem.j)
WEATHER_CHECK_INTERVAL = 120.0
CLOUD_COUNT = 40
MAX_UNITS = 2000
```

---

## Debugging

### Show current weather
```jass
call BJDebugMsg("Weather: " + WeatherSystem_GetCurrentWeather())
call BJDebugMsg("Season: " + WeatherSystem_GetCurrentSeason())
call BJDebugMsg("Days: " + I2S(udg_DaysPassed))
```

### Test all weather types
```jass
// In chat command trigger
if GetEventPlayerChatString() == "test rain" then
    call WeatherSystem_SetGlobalWeather("rain_light")
elseif GetEventPlayerChatString() == "test snow" then
    call WeatherSystem_SetGlobalWeather("snow")
elseif GetEventPlayerChatString() == "test storm" then
    call WeatherSystem_SetGlobalWeather("storm")
elseif GetEventPlayerChatString() == "test clear" then
    call WeatherSystem_StopGlobalWeather()
endif
```

---

## Integration Notes

### With Frostbite System
- Snow weather automatically works with cold auras
- Steam breath shows during cold weather
- Frostbite debuff activates in cold regions

### With Reputation System
```jass
// Give reputation bonus for rescuing in storm
if WeatherSystem_GetCurrentWeather() == "storm" then
    call Reputation_ModifyReputation(rescuedUnit, rescuer, 20)
endif
```

### With Quest System
```jass
// Seasonal quest activation
if WeatherSystem_GetCurrentSeason() == "winter" then
    call QuestSystem_ActivateQuest(winterQuestId)
endif
```

---

## File Dependencies

Load order in Trigger Editor:
1. Storm.j
2. Snow.j
3. FrostbiteSystem.j
4. Clouds_create.j
5. Clouds_destroy.j
6. SteamBreath.j
7. **WeatherSystem.j** ← Must load last

---

## Quick Setup (3 Steps)

### Step 1: Create Variables
Open Variable Editor (F4), create all variables from list above

### Step 2: Import Files
Copy all 7 JASS files to your map's triggers

### Step 3: Initialize
Create map init trigger:
```
Events:
    Map initialization
Actions:
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

**Done!** Weather system is now active.

---

## Support

**Documentation Files:**
- `WeatherSystem_Guide.md` - Complete API reference
- `WeatherSystem_Configuration.md` - Detailed configuration
- `WeatherSystem_GUI_Examples.j` - 15 example triggers
- `WeatherSystem_QuickReference.md` - This file

**Test Commands:**
Create a trigger with these chat commands for testing:
- `-rain` → Start rain
- `-snow` → Start snow
- `-storm` → Start storm
- `-clear` → Clear weather
- `-season winter` → Set winter
- `-season summer` → Set summer

---

## Credits

- WeatherSystem, Snow, Frostbite, Clouds, SteamBreath: Valdemar
- Storm (Thunder/Lightning): OVOgenez

---

*Last Updated: 2025*
*Version: 1.0*
