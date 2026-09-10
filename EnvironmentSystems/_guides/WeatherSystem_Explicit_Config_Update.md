# WeatherSystem - Explicit Configuration Update

## Changes Summary

### Core Philosophy Change

**OLD SYSTEM:** Weather types were implicitly enabled by setting probabilities. Setting `SetZoneWeatherChance("Zone", "snow", 0.5)` would automatically enable snow weather in that zone.

**NEW SYSTEM:** Weather types must be **explicitly enabled** before they can occur. You must call `SetZoneAllowedWeather()` to permit each weather type, then set probabilities.

---

## New Requirements

### 1. Explicit Weather Type Declaration

Every zone must explicitly declare which weather types are allowed:

```jass
// Before setting probabilities, declare allowed types:
call SetZoneAllowedWeather("ZoneName", "rain", true)   // Enable rain
call SetZoneAllowedWeather("ZoneName", "snow", true)   // Enable snow  
call SetZoneAllowedWeather("ZoneName", "storm", true)  // Enable storm

// THEN set probabilities:
call SetZoneWeatherChance("ZoneName", "rain_light", 0.4)
call SetZoneWeatherChance("ZoneName", "snow", 0.3)
call SetZoneWeatherChance("ZoneName", "storm", 0.2)
```

**If you skip `SetZoneAllowedWeather()`, the weather type will NEVER occur, even with probabilities set.**

### 2. Manual Snow Unit Spawn Configuration

Snow weather visual and snow unit spawning are now separated:

```jass
// Enable snow weather (visual effects)
call SetZoneAllowedWeather("Mountains", "snow", true)
call SetZoneWeatherChance("Mountains", "snow", 0.5)

// Manually specify which regions spawn snow units
call SetRegionSnowSpawn(gg_rct_MountainPeak, true)
call SetRegionSnowSpawn(gg_rct_SnowyValley, true)

// Other regions in zone will show snow weather but NOT spawn units
```

---

## API Changes

### New Functions

#### `SetZoneAllowedWeather(zoneName, weatherType, allowed)`

Declares which weather types can occur in a zone.

**Parameters:**
- `zoneName` - Zone identifier string
- `weatherType` - `"rain"`, `"snow"`, or `"storm"`
- `allowed` - `true` to enable, `false` to disable

**Example:**
```jass
call SetZoneAllowedWeather("Forest", "rain", true)
call SetZoneAllowedWeather("Forest", "snow", false)  // Never snows in forest
call SetZoneAllowedWeather("Forest", "storm", true)
```

#### `SetRegionSnowSpawn(region, enabled)`

Configures snow unit spawning for specific regions.

**Parameters:**
- `region` - Region handle (e.g., `gg_rct_RegionName`)
- `enabled` - `true` to spawn snow units, `false` to disable

**Example:**
```jass
// Zone with 3 regions - only 1 spawns snow units
call AddRegionToZoneInternal("SnowZone", gg_rct_Area1)
call AddRegionToZoneInternal("SnowZone", gg_rct_Area2)
call AddRegionToZoneInternal("SnowZone", gg_rct_Area3)

call SetRegionSnowSpawn(gg_rct_Area2, true)  // Only Area2 spawns units

// Result: All 3 areas show snow weather visual
//         Only Area2 spawns physical snow units
```

---

## Migration Guide

### Old Configuration Style
```jass
call CreateMasterZoneInternal("Zone", "none", "auto")
call AddRegionToZoneInternal("Zone", gg_rct_Region)
call SetZoneWeatherChance("Zone", "rain_light", 0.4)
call SetZoneWeatherChance("Zone", "snow", 0.5)

// Snow units automatically spawned in all regions
```

### New Configuration Style
```jass
call CreateMasterZoneInternal("Zone", "none", "auto")
call AddRegionToZoneInternal("Zone", gg_rct_Region)

// STEP 1: Explicitly enable weather types
call SetZoneAllowedWeather("Zone", "rain", true)
call SetZoneAllowedWeather("Zone", "snow", true)

// STEP 2: Set probabilities
call SetZoneWeatherChance("Zone", "rain_light", 0.4)
call SetZoneWeatherChance("Zone", "snow", 0.5)

// STEP 3: Manually enable snow spawning if needed
call SetRegionSnowSpawn(gg_rct_Region, true)
```

---

## Why This Change?

### 1. **Performance Control**
Snow unit spawning has significant performance impact. By requiring explicit configuration, you have fine-grained control over which regions spawn units vs. just showing visual effects.

### 2. **Terrain Suitability**
Not all terrain can support snow units (steep slopes, water, etc.). Explicit configuration prevents automatic spawning in unsuitable areas.

### 3. **Clear Intent**
Configuration explicitly states: "This zone can have rain and snow" vs. implicit behavior where setting a probability automatically enabled the weather.

### 4. **Prevents Accidents**
Old system: Setting a probability accidentally enabled weather everywhere
New system: Must explicitly enable weather, then configure regions for snow units

---

## Configuration Examples

### Example 1: Rain-Only Forest
```jass
call CreateMasterZoneInternal("PeacefulForest", "none", "auto")
call AddRegionToZoneInternal("PeacefulForest", gg_rct_Forest)

call SetZoneAllowedWeather("PeacefulForest", "rain", true)  // Only rain
call SetZoneWeatherChance("PeacefulForest", "rain_light", 0.4)

call EnableZoneClouds("PeacefulForest", true)
```

### Example 2: Mountain with Selective Snow Spawning
```jass
call CreateMasterZoneInternal("Mountains", "none", "auto")
call AddRegionToZoneInternal("Mountains", gg_rct_MountainBase)
call AddRegionToZoneInternal("Mountains", gg_rct_MountainPeak)

call SetZoneAllowedWeather("Mountains", "rain", true)
call SetZoneAllowedWeather("Mountains", "snow", true)

call SetZoneWeatherChance("Mountains", "rain_light", 0.3)
call SetZoneWeatherChance("Mountains", "snow", 0.5)

// Only peak spawns snow units (base is too low elevation)
call SetRegionSnowSpawn(gg_rct_MountainPeak, true)

call EnableZoneSteamBreath("Mountains", true)
```

### Example 3: Snow Weather Without Units
```jass
call CreateMasterZoneInternal("VisualSnowZone", "none", "auto")
call AddRegionToZoneInternal("VisualSnowZone", gg_rct_Area)

call SetZoneAllowedWeather("VisualSnowZone", "snow", true)
call SetZoneWeatherChance("VisualSnowZone", "snow", 0.6)

// Don't call SetRegionSnowSpawn() - no units, just visuals
// Result: Snow weather appears, but no performance impact from units
```

### Example 4: Storm-Heavy Coastal Zone
```jass
call CreateMasterZoneInternal("StormyCoast", "none", "auto")
call AddRegionToZoneInternal("StormyCoast", gg_rct_Coast)

call SetZoneAllowedWeather("StormyCoast", "rain", true)
call SetZoneAllowedWeather("StormyCoast", "storm", true)

call SetZoneWeatherChance("StormyCoast", "rain_heavy", 0.4)
call SetZoneWeatherChance("StormyCoast", "storm", 0.6)

call EnableZoneThunder("StormyCoast", true)
```

---

## Updated Zone Configuration

All 36 zones in the map have been updated with explicit weather type declarations:

### Snow Zones (with unit spawning)
- **Serenaglade**: gg_rct_SnowTest2 spawns snow units
- **EmperpeakHighlands**: gg_rct_03EmberpeakHighlands spawns snow units
- **DragonfirePeaks**: gg_rct_04DragonfirePeaks spawns snow units

### Rain Zones
- TwilightGrove, Thornwoods, Havenwoods, VanguardVale, Riverbane, and 20+ others

### Storm Zones
- BonecrushStronghold, Deadwoods, FelfireBastion, Stormhaven, ChimairosRoost

### Mixed Weather Zones
- Serenaglade (rain + snow)
- EmperpeakHighlands (rain + snow)
- DragonfirePeaks (snow + storm)
- Stormhaven (rain + storm)
- Sirensong (rain + storm)
- Serpentshore (rain + storm)

---

## Behavior Changes

### Before
```jass
call SetZoneWeatherChance("Zone", "snow", 0.5)
// Result: Snow occurs automatically, spawns units in ALL regions
```

### After
```jass
call SetZoneAllowedWeather("Zone", "snow", true)
call SetZoneWeatherChance("Zone", "snow", 0.5)
// Result: Snow CAN occur (if allowed)

call SetRegionSnowSpawn(gg_rct_SpecificRegion, true)
// Result: Snow units spawn ONLY in SpecificRegion
```

---

## Testing Checklist

- [ ] Each zone has `SetZoneAllowedWeather()` calls for intended weather types
- [ ] Weather probabilities only set for allowed types
- [ ] Snow unit spawning explicitly configured with `SetRegionSnowSpawn()`
- [ ] Seasonal constraints still work (no snow in summer, even if allowed)
- [ ] Zones without snow spawning show visual effects only
- [ ] Performance is improved (fewer snow spawn regions)

---

## Quick Reference

```jass
// ALWAYS follow this order:

// 1. Create zone and add regions
call CreateMasterZoneInternal("Name", "none", "auto")
call AddRegionToZoneInternal("Name", gg_rct_Region)

// 2. Enable allowed weather types
call SetZoneAllowedWeather("Name", "rain", true)
call SetZoneAllowedWeather("Name", "snow", true)

// 3. Set probabilities
call SetZoneWeatherChance("Name", "rain_light", 0.4)
call SetZoneWeatherChance("Name", "snow", 0.3)

// 4. Configure snow spawning (if snow is allowed)
call SetRegionSnowSpawn(gg_rct_Region, true)

// 5. Configure effects
call EnableZoneClouds("Name", true)
call EnableZoneThunder("Name", true)
call EnableZoneSteamBreath("Name", true)
```

---

## Documentation Files

- **WeatherSystem_Configuration_Guide.md** - Complete configuration guide
- **WeatherSystem_Updates_Jan2026.md** - Previous update (FPS optimization)
- **WeatherSystem.j** - Main system file with all zones configured
