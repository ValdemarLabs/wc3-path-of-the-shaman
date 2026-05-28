# WeatherSystem Configuration Guide

## Core Design Principles

### 1. **Explicit Weather Type Definition**
Each zone must explicitly define which weather effects are allowed. By default, all weather types are **DISABLED** until enabled.

### 2. **Snow Units vs Snow Weather**
- **Snow Weather Visual**: The snow particle effect (`'SNhs'`) can appear in any region within a zone that allows snow
- **Snow Unit Spawning**: Physical snow units only spawn in regions **explicitly configured** for snow spawning
- This separation allows snow visuals without the performance/gameplay impact of snow unit spawning

### 3. **Manual Snow Region Configuration**
Snow unit spawning is NEVER automatic. You must manually specify which regions will spawn snow units using `SetRegionSnowSpawn()`.

---

## Configuration Workflow

### Step 1: Create Zone
```jass
call CreateMasterZoneInternal("ZoneName", "none", "auto")
```

### Step 2: Add Regions to Zone
```jass
call AddRegionToZoneInternal("ZoneName", gg_rct_RegionName)
```

### Step 3: Define Allowed Weather Types
```jass
// Enable rain weather in this zone
call SetZoneAllowedWeather("ZoneName", "rain", true)

// Enable snow weather (visual) in this zone
call SetZoneAllowedWeather("ZoneName", "snow", true)

// Enable storm weather in this zone
call SetZoneAllowedWeather("ZoneName", "storm", true)
```

**CRITICAL:** If you don't call `SetZoneAllowedWeather()`, the weather type will **NEVER occur** in that zone, even if you set probabilities.

### Step 4: Set Weather Probabilities
```jass
// Set probability for each allowed weather type
call SetZoneWeatherChance("ZoneName", "rain_light", 0.4)  // 40% chance
call SetZoneWeatherChance("ZoneName", "snow", 0.3)        // 30% chance
call SetZoneWeatherChance("ZoneName", "storm", 0.2)       // 20% chance
```

### Step 5: Configure Snow Unit Spawning (If Needed)
```jass
// Only spawn snow units in specific regions
call SetRegionSnowSpawn(gg_rct_SnowyMountaintop, true)
call SetRegionSnowSpawn(gg_rct_FrozenLake, true)

// Other regions in the zone will show snow WEATHER but NOT spawn snow UNITS
```

---

## API Reference

### Zone Configuration

#### `SetZoneAllowedWeather(zoneName, weatherType, allowed)`
Enables or disables a specific weather type for a zone.

**Parameters:**
- `zoneName`: string - Name of the zone
- `weatherType`: string - Weather type identifier
  - `"rain"` - Allows rain_light and rain_heavy
  - `"snow"` - Allows snow weather visual
  - `"storm"` - Allows storm weather
- `allowed`: boolean - true to enable, false to disable

**Example:**
```jass
call SetZoneAllowedWeather("Mountains", "snow", true)
call SetZoneAllowedWeather("Desert", "snow", false)
```

#### `SetRegionSnowSpawn(region, enabled)`
Configures whether a specific region will spawn physical snow units.

**Parameters:**
- `region`: rect - Region handle (e.g., `gg_rct_SnowyArea`)
- `enabled`: boolean - true to spawn snow units, false to disable

**Example:**
```jass
// Snow zone with 3 regions - only 1 spawns snow units
call AddRegionToZoneInternal("SnowyZone", gg_rct_SnowArea1)
call AddRegionToZoneInternal("SnowyZone", gg_rct_SnowArea2)
call AddRegionToZoneInternal("SnowyZone", gg_rct_SnowArea3)

// Only Area2 spawns snow units (maybe it's flat terrain)
call SetRegionSnowSpawn(gg_rct_SnowArea2, true)

// All 3 regions will show snow WEATHER when it snows
// But only Area2 will spawn the physical snow units
```

---

## Complete Configuration Examples

### Example 1: Forest Zone (Rain Only)
```jass
call CreateMasterZoneInternal("PeacefulForest", "none", "auto")
call AddRegionToZoneInternal("PeacefulForest", gg_rct_Forest)

// Only allow rain
call SetZoneAllowedWeather("PeacefulForest", "rain", true)
call SetZoneWeatherChance("PeacefulForest", "rain_light", 0.4)

// Clouds and effects
call EnableZoneClouds("PeacefulForest", true)
call EnableZoneThunder("PeacefulForest", false)  // No thunder in peaceful area
```

### Example 2: Mountain Zone (Snow + Rain)
```jass
call CreateMasterZoneInternal("Mountains", "none", "auto")
call AddRegionToZoneInternal("Mountains", gg_rct_MountainValley)
call AddRegionToZoneInternal("Mountains", gg_rct_MountainPeak)

// Allow both rain and snow
call SetZoneAllowedWeather("Mountains", "rain", true)
call SetZoneAllowedWeather("Mountains", "snow", true)

// Set probabilities
call SetZoneWeatherChance("Mountains", "rain_light", 0.3)
call SetZoneWeatherChance("Mountains", "snow", 0.5)

// Only the PEAK spawns snow units (valley is too warm)
call SetRegionSnowSpawn(gg_rct_MountainPeak, true)

// Enable effects
call EnableZoneClouds("Mountains", true)
call EnableZoneSteamBreath("Mountains", true)
```

### Example 3: Stormy Coastal Zone
```jass
call CreateMasterZoneInternal("StormCoast", "none", "auto")
call AddRegionToZoneInternal("StormCoast", gg_rct_CoastalArea)

// Allow rain and storm
call SetZoneAllowedWeather("StormCoast", "rain", true)
call SetZoneAllowedWeather("StormCoast", "storm", true)

// High storm probability
call SetZoneWeatherChance("StormCoast", "rain_heavy", 0.4)
call SetZoneWeatherChance("StormCoast", "storm", 0.6)

// Thunder enabled for dramatic effect
call EnableZoneThunder("StormCoast", true)
call EnableZoneClouds("StormCoast", true)
```

### Example 4: Mixed Zone (All Weather Types)
```jass
call CreateMasterZoneInternal("VariedLands", "none", "auto")
call AddRegionToZoneInternal("VariedLands", gg_rct_Lowlands)
call AddRegionToZoneInternal("VariedLands", gg_rct_Highlands)

// Allow all weather types
call SetZoneAllowedWeather("VariedLands", "rain", true)
call SetZoneAllowedWeather("VariedLands", "snow", true)
call SetZoneAllowedWeather("VariedLands", "storm", true)

// Balanced probabilities
call SetZoneWeatherChance("VariedLands", "rain_light", 0.3)
call SetZoneWeatherChance("VariedLands", "snow", 0.2)
call SetZoneWeatherChance("VariedLands", "storm", 0.15)

// Only highlands spawn snow units
call SetRegionSnowSpawn(gg_rct_Highlands, true)

// All effects enabled
call EnableZoneClouds("VariedLands", true)
call EnableZoneThunder("VariedLands", true)
call EnableZoneSteamBreath("VariedLands", true)
```

---

## Weather Behavior Matrix

| Zone Has | Rain Allowed | Snow Allowed | Storm Allowed | Result |
|----------|--------------|--------------|---------------|--------|
| Rain chance 40% | ✅ Yes | ❌ No | ❌ No | Rain will occur |
| Snow chance 70% | ❌ No | ✅ Yes | ❌ No | Snow will occur |
| Both chances set | ✅ Yes | ✅ Yes | ❌ No | Both can occur (probability split) |
| Snow chance 50% | ❌ No | ❌ No | ❌ No | **NO WEATHER** (not allowed) |

---

## Snow Spawning Behavior

### Scenario 1: Zone with Snow Weather, No Spawn Regions
```jass
call SetZoneAllowedWeather("Zone", "snow", true)
call SetZoneWeatherChance("Zone", "snow", 0.5)
// No SetRegionSnowSpawn() calls

// Result: Snow weather visual effects appear, but NO snow units spawn
```

### Scenario 2: Zone with Snow Weather, Multiple Regions
```jass
call AddRegionToZoneInternal("Zone", gg_rct_Region1)
call AddRegionToZoneInternal("Zone", gg_rct_Region2)
call AddRegionToZoneInternal("Zone", gg_rct_Region3)

call SetZoneAllowedWeather("Zone", "snow", true)
call SetRegionSnowSpawn(gg_rct_Region2, true)  // Only Region2

// Result when it snows:
// - All 3 regions show snow weather visual
// - Only Region2 spawns physical snow units
```

### Scenario 3: Region with Snow Spawn, but Zone Doesn't Allow Snow
```jass
call SetRegionSnowSpawn(gg_rct_Region, true)
// But SetZoneAllowedWeather("Zone", "snow", true) NOT called

// Result: Region will NEVER spawn snow units (zone doesn't allow snow weather)
```

---

## Common Configuration Patterns

### Pattern 1: Pure Rain Zone
```jass
call SetZoneAllowedWeather("Zone", "rain", true)
call SetZoneWeatherChance("Zone", "rain_light", 0.4)
// Rain only, no snow units to manage
```

### Pattern 2: Visual Snow, No Game Mechanics
```jass
call SetZoneAllowedWeather("Zone", "snow", true)
call SetZoneWeatherChance("Zone", "snow", 0.6)
// Don't call SetRegionSnowSpawn()
// Result: Snow effects for atmosphere, but no units
```

### Pattern 3: Selective Snow Spawning
```jass
// Mountain with 5 regions
call AddRegionToZoneInternal("Mountain", gg_rct_Peak)
call AddRegionToZoneInternal("Mountain", gg_rct_UpperSlope)
call AddRegionToZoneInternal("Mountain", gg_rct_MidSlope)
call AddRegionToZoneInternal("Mountain", gg_rct_LowerSlope)
call AddRegionToZoneInternal("Mountain", gg_rct_Valley)

call SetZoneAllowedWeather("Mountain", "snow", true)

// Only peak and upper slope spawn snow (steep terrain)
call SetRegionSnowSpawn(gg_rct_Peak, true)
call SetRegionSnowSpawn(gg_rct_UpperSlope, true)

// All 5 regions show snow weather
// Only 2 spawn snow units
```

---

## Seasonal Behavior with Allowed Weather

The seasonal system respects allowed weather types:

```jass
// Winter season: snow chance is 70% by default
// But if zone doesn't allow snow:
call SetZoneAllowedWeather("Desert", "snow", false)

// Result: Even in winter, this zone will NEVER have snow
// System will fall back to rain/storm if those are allowed
```

**Season Priority:**
1. Check if season allows weather type (e.g., no snow in summer)
2. Check if zone allows weather type
3. Both must be true for weather to occur

---

## Migration from Old System

### Old Configuration (Automatic)
```jass
call SetZoneWeatherChance("Zone", "snow", 0.5)
// Snow would automatically spawn everywhere
```

### New Configuration (Explicit)
```jass
// Step 1: Allow snow weather in zone
call SetZoneAllowedWeather("Zone", "snow", true)

// Step 2: Set probability
call SetZoneWeatherChance("Zone", "snow", 0.5)

// Step 3: Explicitly enable snow unit spawning per region
call SetRegionSnowSpawn(gg_rct_SpecificRegion, true)
```

---

## Troubleshooting

### "Weather never occurs in my zone"
**Check:**
1. Did you call `SetZoneAllowedWeather()` for that weather type?
2. Did you set a probability with `SetZoneWeatherChance()`?
3. Is seasonal weather enabled? `EnableSeasonalWeather(true)`
4. Does the season allow that weather? (e.g., no snow in summer)

### "Snow weather appears but no snow units spawn"
**Check:**
1. Did you call `SetRegionSnowSpawn(region, true)` for at least one region?
2. Is the region actually part of the zone?
3. Check debug messages for snow spawn attempts

### "Snow units spawn in wrong regions"
**Check:**
1. Which regions have `SetRegionSnowSpawn(region, true)` called?
2. Verify region handles match the intended regions
3. Only configured regions should spawn units

---

## Best Practices

1. **Always use `SetZoneAllowedWeather()` first** before setting probabilities
2. **Be selective with snow spawning** - only enable in suitable terrain
3. **Test each zone independently** to verify weather behavior
4. **Use descriptive comments** in configuration for maintenance
5. **Group related regions** when spawning snow units
6. **Consider performance** - fewer snow spawn regions = better FPS

---

## Quick Reference

```jass
// Basic zone setup
call CreateMasterZoneInternal("Name", "none", "auto")
call AddRegionToZoneInternal("Name", gg_rct_Region)

// Enable weather types
call SetZoneAllowedWeather("Name", "rain", true)
call SetZoneAllowedWeather("Name", "snow", true)
call SetZoneAllowedWeather("Name", "storm", true)

// Set probabilities
call SetZoneWeatherChance("Name", "rain_light", 0.4)
call SetZoneWeatherChance("Name", "snow", 0.3)
call SetZoneWeatherChance("Name", "storm", 0.2)

// Configure snow spawning
call SetRegionSnowSpawn(gg_rct_Region, true)

// Optional effects
call EnableZoneClouds("Name", true)
call EnableZoneThunder("Name", true)
call EnableZoneSteamBreath("Name", true)
```
