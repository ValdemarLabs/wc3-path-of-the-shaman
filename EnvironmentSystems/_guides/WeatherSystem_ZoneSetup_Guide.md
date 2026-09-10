# WeatherSystem 2.0 - Zone-Based Quick Setup Guide

## What Changed?

WeatherSystem 2.0 is now **zone-based** instead of global. Instead of setting weather for the entire map, you:

1. **Create master zones** (e.g., "Mountains", "Forest", "Desert")
2. **Add regions to zones** (each zone can contain multiple regions)
3. **Control weather per zone** (all regions in a zone get the same weather)

## Quick Setup (3 Steps)

### Step 1: Create Global Variables (Variable Editor - F4)

**Required:**
```
udg_DaysPassed (Integer)
udg_SnowIndex (Integer)
udg_SnowWaveCount (Integer)
udg_SnowDestructionZone (Integer)
udg_SnowDestroyTimer (Timer)
```

**Remove (no longer needed):**
- ~~udg_SnowRegions array~~
- ~~udg_SnowAmounts array~~
- ~~udg_SnowWeather array~~
- ~~udg_SnowTimer array~~

### Step 2: Create Zones and Add Regions (Map Init Trigger)

```
Trigger Name: Weather System Init

Events:
    Map initialization

Actions:
    -------- Create Master Zones --------
    Custom script:   call WeatherSystem_CreateMasterZone("Mountains", "snow", "auto")
    Custom script:   call WeatherSystem_CreateMasterZone("Forest", "none", "auto")
    Custom script:   call WeatherSystem_CreateMasterZone("Desert", "none", "auto")
    
    -------- Add Your Regions to Zones --------
    Custom script:   call WeatherSystem_AddRegionToZone("Mountains", gg_rct_NorthPeak)
    Custom script:   call WeatherSystem_AddRegionToZone("Mountains", gg_rct_SouthPeak)
    Custom script:   call WeatherSystem_AddRegionToZone("Mountains", gg_rct_MountainPass)
    
    Custom script:   call WeatherSystem_AddRegionToZone("Forest", gg_rct_DarkWoods)
    Custom script:   call WeatherSystem_AddRegionToZone("Forest", gg_rct_ElvenForest)
    
    Custom script:   call WeatherSystem_AddRegionToZone("Desert", gg_rct_SandDunes)
    
    -------- Enable Seasonal Weather --------
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

### Step 3: Update Days (for seasonal progression)

```
Trigger Name: Day Night Cycle

Events:
    Time - Every 24.00 seconds of game time

Actions:
    Set udg_DaysPassed = (udg_DaysPassed + 1)
    -------- Season updates automatically! --------
```

**Done!** Weather now operates per zone with automatic seasonal changes.

---

## Key Concepts

### Master Zones

Think of zones as geographic areas (Mountains, Forest, Desert, Ocean, etc.). Each zone:
- Has its own weather settings
- Can contain multiple regions
- Controls weather for all its regions simultaneously
- Has independent seasonal behavior

### Regions

Regions are the actual World Editor rectangles (rects) that you assign to zones. A region:
- Belongs to one zone
- Inherits that zone's weather
- Can have weather overridden individually if needed

### Example Structure

```
Mountains Zone
├── gg_rct_NorthPeak       ← Region 1
├── gg_rct_SouthPeak       ← Region 2
└── gg_rct_MountainPass    ← Region 3

Forest Zone
├── gg_rct_DarkWoods       ← Region 1
└── gg_rct_ElvenForest     ← Region 2

Desert Zone
└── gg_rct_SandDunes       ← Region 1
```

When you set weather for "Mountains", all three mountain regions get that weather.

---

## Common Usage Patterns

### Pattern 1: Set Zone Weather

```jass
// Make it rain in all forest regions for 2 minutes
call WeatherSystem_SetZoneWeather("Forest", "rain_heavy", 120.0)

// Make it snow permanently in mountains
call WeatherSystem_SetZoneWeather("Mountains", "snow", 0.0)

// Clear weather in desert
call WeatherSystem_StopZoneWeather("Desert")
```

### Pattern 2: Configure Zone Probabilities

```jass
// Mountains: 90% chance of snow
call WeatherSystem_SetZoneWeatherChance("Mountains", "snow", 0.9)

// Forest: 60% chance of rain
call WeatherSystem_SetZoneWeatherChance("Forest", "rain_light", 0.6)

// Desert: 5% rain, 15% storms
call WeatherSystem_SetZoneWeatherChance("Desert", "rain_light", 0.05)
call WeatherSystem_SetZoneWeatherChance("Desert", "storm", 0.15)
```

### Pattern 3: Lock Zone to Specific Season

```jass
// Tundra is always winter
call WeatherSystem_SetZoneSeason("Tundra", "winter")
call WeatherSystem_SetZoneSeasonalBehavior("Tundra", false)

// Most zones follow global season
call WeatherSystem_SetZoneSeason("Forest", "auto")
call WeatherSystem_SetZoneSeasonalBehavior("Forest", true)
```

### Pattern 4: Control Zone Effects

```jass
// Enable thunder in mountains
call WeatherSystem_EnableZoneThunder("Mountains", true)

// Enable steam breath in cold zones
call WeatherSystem_EnableZoneSteamBreath("Tundra", true)

// Disable clouds in desert
call WeatherSystem_EnableZoneClouds("Desert", false)
```

### Pattern 5: Override Individual Region

```jass
// Stop weather in just one region (rest of zone continues)
call WeatherSystem_StopRegionWeather(gg_rct_SafeCave)

// Set weather for single region
call WeatherSystem_SetRegionWeather(gg_rct_BossArena, "storm", 300.0)
```

---

## Complete API Reference

### Zone Management

```jass
// Create a master zone
WeatherSystem_CreateMasterZone(zoneName, defaultWeather, season)
  // zoneName: string ("Mountains", "Forest", etc.)
  // defaultWeather: "none", "rain_light", "rain_heavy", "snow", "storm"
  // season: "auto", "spring", "summer", "autumn", "winter"

// Add region to zone
WeatherSystem_AddRegionToZone(zoneName, region)
  // zoneName: your zone name
  // region: gg_rct_YourRegion
```

### Zone Weather Control

```jass
// Set zone weather
WeatherSystem_SetZoneWeather(zoneName, weatherType, duration)
  // duration: seconds (0 = permanent)

// Stop zone weather
WeatherSystem_StopZoneWeather(zoneName)

// Set zone seasonal behavior
WeatherSystem_SetZoneSeasonalBehavior(zoneName, enabled)

// Lock zone to specific season
WeatherSystem_SetZoneSeason(zoneName, season)
```

### Region Weather Control

```jass
// Set region weather (overrides zone)
WeatherSystem_SetRegionWeather(region, weatherType, duration)

// Stop region weather
WeatherSystem_StopRegionWeather(region)
```

### Zone Configuration

```jass
// Set weather probability for zone
WeatherSystem_SetZoneWeatherChance(zoneName, weatherType, chance)
  // chance: 0.0 to 1.0

// Enable/disable effects
WeatherSystem_EnableZoneThunder(zoneName, enable)
WeatherSystem_EnableZoneClouds(zoneName, enable)
WeatherSystem_EnableZoneSteamBreath(zoneName, enable)
```

### Seasonal System

```jass
// Enable automatic seasonal weather
WeatherSystem_EnableSeasonalWeather(enable)

// Set global season manually
WeatherSystem_SetSeason(season)

// Update season from udg_DaysPassed
WeatherSystem_UpdateSeason()
```

### Query Functions

```jass
// Get zone weather
local string weather = WeatherSystem_GetZoneWeather(zoneName)

// Get region weather
local string weather = WeatherSystem_GetRegionWeather(region)

// Get which zone a region belongs to
local string zone = WeatherSystem_GetRegionZone(region)

// Get current season
local string season = WeatherSystem_GetCurrentSeason()
```

---

## Migration from Old System

### Old Way (Global)

```jass
// Old: Set weather globally
call WeatherSystem_SetGlobalWeather("rain_heavy")

// Old: Regional weather
call WeatherSystem_StartRegionalWeatherAPI(gg_rct_Forest, "rain_light", 120.0)
```

### New Way (Zone-Based)

```jass
// New: Create zone first
call WeatherSystem_CreateMasterZone("Forest", "none", "auto")
call WeatherSystem_AddRegionToZone("Forest", gg_rct_Forest)

// New: Set zone weather
call WeatherSystem_SetZoneWeather("Forest", "rain_heavy", 0.0)

// New: Or individual region (still works)
call WeatherSystem_SetRegionWeather(gg_rct_Forest, "rain_light", 120.0)
```

**Note:** Old global functions still work but apply to ALL zones - not recommended!

---

## Example Maps

### Small Map (3 Zones)

```jass
// Mountains (permanent snow)
call WeatherSystem_CreateMasterZone("Mountains", "snow", "winter")
call WeatherSystem_AddRegionToZone("Mountains", gg_rct_Peak)
call WeatherSystem_SetZoneSeasonalBehavior("Mountains", false)
call WeatherSystem_SetZoneWeather("Mountains", "snow", 0.0)

// Village (seasonal rain)
call WeatherSystem_CreateMasterZone("Village", "none", "auto")
call WeatherSystem_AddRegionToZone("Village", gg_rct_VillageCenter)
call WeatherSystem_AddRegionToZone("Village", gg_rct_VillageFarms)
call WeatherSystem_SetZoneWeatherChance("Village", "rain_light", 0.3)

// Forest (frequent rain)
call WeatherSystem_CreateMasterZone("Forest", "rain_light", "auto")
call WeatherSystem_AddRegionToZone("Forest", gg_rct_DarkForest)
call WeatherSystem_SetZoneWeatherChance("Forest", "rain_heavy", 0.6)

call WeatherSystem_EnableSeasonalWeather(true)
```

### Large RPG Map (10+ Zones)

See `WeatherSystem_ZoneSetup_Examples.j` - Example 8 or 12

---

## Debugging

### Show Zone Info

```jass
local string weather = WeatherSystem_GetZoneWeather("Mountains")
call BJDebugMsg("Mountains weather: " + weather)

local string season = WeatherSystem_GetCurrentSeason()
call BJDebugMsg("Current season: " + season)
```

### Check Region Assignment

```jass
local string zone = WeatherSystem_GetRegionZone(gg_rct_MyRegion)
call BJDebugMsg("Region belongs to zone: " + zone)
```

### Test Commands

Create a trigger with these chat commands:
- `-weather Mountains rain` → Rain in Mountains zone
- `-weather Mountains snow` → Snow in Mountains zone
- `-weather Mountains clear` → Clear Mountains zone
- `-weather info` → Show all zone weather

---

## Troubleshooting

**Q: Weather not appearing?**
- Check you created the zone with `CreateMasterZone()`
- Verify you added regions with `AddRegionToZone()`
- Ensure seasonal weather is enabled

**Q: Region has no weather?**
- Check the region is added to a zone with `GetRegionZone()`
- Verify the zone has weather set with `GetZoneWeather()`

**Q: All zones have same weather?**
- Don't use old `SetGlobalWeather()` - it affects all zones
- Use `SetZoneWeather()` for individual zones

**Q: Season not updating?**
- Ensure `udg_DaysPassed` is incrementing
- Enable seasonal weather with `EnableSeasonalWeather(true)`
- Manually call `UpdateSeason()` if needed

---

## Performance Notes

- **Max zones**: 20 master zones (configurable via MAX_MASTER_ZONES)
- **Max regions**: 100 total regions across all zones (configurable via MAX_REGIONS)
- Weather checks occur every 250 seconds (configurable via WEATHER_CHECK_INTERVAL)
- Season checks occur every 60 seconds (configurable via SEASON_CHECK_INTERVAL)

---

## Files

- **WeatherSystem.j** - Main library (replaces old version)
- **WeatherSystem_ZoneSetup_Examples.j** - 15 example triggers
- **WeatherSystem_ZoneSetup_Guide.md** - This file

---

## Support

For more examples, see `WeatherSystem_ZoneSetup_Examples.j`

The zone-based system provides much better control and organization for maps with varied terrain and weather needs!
