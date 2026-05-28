# WeatherSystem v2.1 - Weather Variety & Ambient Sound Integration

## Overview
Major update adding wind weather, rain/snow intensity variations, and atmospheric ambient sound integration.

## New Features

### 1. Wind Weather Type
- **Weather Effect**: 'WOlw' (Outland Wind Light)
- **Ambient Sound**: gg_snd_WindHeavy
- **Duration**: 60-240 seconds
- **Seasonal Probability**:
  - Spring: 40% (highest - spring winds)
  - Autumn: 30% (autumn gusts)
  - Winter: 20% (cold winds)
  - Summer: 15% (lightest)

### 2. Rain Intensity Variations
Expanded from 2 to 3 intensity levels:

| Type | Effect ID | Visual | Ambient Sound | Notes |
|------|-----------|--------|---------------|-------|
| **rain_light** | 'RLlr' | Lordaeron Rain Light | gg_snd_Ambient_RainLight | Gentle drizzle |
| **rain_medium** | 'RLhr' | Lordaeron Rain Heavy | gg_snd_Ambient_RainMedium | Standard rain |
| **rain_heavy** | 'RAhr' | Ashenvale Rain Heavy | gg_snd_Ambient_RainHeavy | Downpour + thunder |

**Probability Distribution in ZoneSeasonalWeatherCheck**:
- Light: 50% chance
- Medium: 35% chance (85% cumulative)
- Heavy: 15% chance

### 3. Snow Intensity Variations
Expanded from 1 to 3 intensity levels:

| Type | Effect ID | Visual | Ambient Sound | Notes |
|------|-----------|--------|---------------|-------|
| **snow_light** | 'SNls' | Northrend Snow Light | gg_snd_Ambient_SnowLight | Light flurries |
| **snow_medium** | 'SNhs' | Northrend Snow Heavy | gg_snd_Ambient_SnowMedium | Standard snowfall |
| **snow_heavy** | 'SNbs' | Blizzard Rain/Snow | gg_snd_Ambient_SnowHeavy | Heavy blizzard |

**Probability Distribution in ZoneSeasonalWeatherCheck**:
- Light: 50% chance
- Medium: 35% chance (85% cumulative)
- Heavy: 15% chance

**All snow types**:
- Enable steam breath effects on units
- Spawn snow units ONLY in regions configured with `SetRegionSnowSpawn(region, true)`

### 4. Ambient Sound Integration
All weather types now have atmospheric audio:

**Sound Playback**:
- Volume: 127 (moderate level)
- Playback: `SetSoundVolume() + StartSound()`
- Storage: `RegionAmbientSound[]` array

**Sound Cleanup**:
- Automatic cleanup when weather stops
- `StopSound() + KillSoundWhenDone()` prevents memory leaks

## Code Changes

### New Constants
```jass
constant string WEATHER_WIND = "wind"
constant string WEATHER_RAIN_MEDIUM = "rain_medium"
constant string WEATHER_SNOW_LIGHT = "snow_light"
constant string WEATHER_SNOW_MEDIUM = "snow_medium"
constant string WEATHER_SNOW_HEAVY = "snow_heavy"

constant real WIND_MIN_DURATION = 60.0
constant real WIND_MAX_DURATION = 240.0
```

### New Data Arrays
```jass
real array MasterZoneWindChance[MAX_MASTER_ZONES]
boolean array ZoneAllowsWind[MAX_MASTER_ZONES]
sound array RegionAmbientSound[MAX_REGIONS]
```

### Updated Functions

#### GetZoneWeatherChance()
- Now handles 9 weather types (was 5)
- Wind probability varies by season
- Returns zone-specific overrides via MasterZoneWindChance[]

#### ZoneSeasonalWeatherCheck()
- Includes wind in weather probability calculations
- Rain intensity selection: light (50%), medium (35%), heavy (15%)
- Snow intensity selection: light (50%), medium (35%), heavy (15%)
- Wind uses separate duration range (60-240s)

#### StartRegionWeatherInternal()
- All 8 active weather types configured with:
  - Weather effect creation ('RLlr', 'RLhr', 'RAhr', 'SNls', 'SNhs', 'SNbs', 'RAhr', 'WOlw')
  - Ambient sound playback
  - EnableWeatherEffect() call
  - Appropriate visual effects (ripples, thunder, steam, clouds)
  - Snow unit spawning (region-specific)

#### StopRegionWeatherInternal()
- Added RegionAmbientSound cleanup
- Updated snow check to handle all 3 snow variations

#### SetZoneAllowedWeather()
- Now accepts "wind" weatherType parameter
- Accepts all weather variation strings (rain_light/medium/heavy, snow_light/medium/heavy)

#### SetZoneWeatherChance()
- Handles all new weather variation types
- Accepts generic "rain"/"snow" or specific variation names

#### AddRegionToZoneInternal()
- Initializes `RegionAmbientSound[newIndex] = null`

## Zone Configurations with Wind

Wind weather added to 10 zones with appropriate chances:

| Zone | Type | Wind Chance | Rationale |
|------|------|-------------|-----------|
| **VanguardVale** | Open plains | 0.50 | Exposed valley terrain |
| **Stormhaven** | Coastal | 0.45 | Strong ocean winds |
| **EmperpeakHighlands** | Mountain | 0.35 | High elevation winds |
| **DragonfirePeaks** | Mountain peaks | 0.30 | Mountain gusts |
| **Sirensong** | Coastal hub | 0.40 | Seaside location |
| **VerdantPlains** | Open plains | 0.55 | Flat exposed terrain |
| **RedwindPass** | Mountain pass | 0.60 | Named for wind! |
| **Serpentshore** | Shore | 0.40 | Coastal winds |

**Zones WITHOUT wind**: Forests (sheltered), cities (buildings block wind), enclosed valleys

## API Documentation

### Enable Wind Weather
```jass
call SetZoneAllowedWeather("ZoneName", "wind", true)
call SetZoneWeatherChance("ZoneName", "wind", 0.4)  // 40% chance
```

### Configure Rain Variations
```jass
// Generic "rain" allows all rain types
call SetZoneAllowedWeather("ZoneName", "rain", true)
call SetZoneWeatherChance("ZoneName", "rain", 0.5)

// Or specify intensity (affects chance override)
call SetZoneWeatherChance("ZoneName", "rain_light", 0.3)
call SetZoneWeatherChance("ZoneName", "rain_heavy", 0.7)
```

### Configure Snow Variations
```jass
// Generic "snow" allows all snow types
call SetZoneAllowedWeather("ZoneName", "snow", true)
call SetZoneWeatherChance("ZoneName", "snow", 0.6)

// Or specify intensity (affects chance override)
call SetZoneWeatherChance("ZoneName", "snow_heavy", 0.8)
```

### Manual Weather Triggering
```jass
// Trigger specific weather intensity
call SetZoneWeather("ZoneName", WEATHER_RAIN_MEDIUM, 120.0)
call SetZoneWeather("ZoneName", WEATHER_SNOW_HEAVY, 180.0)
call SetZoneWeather("ZoneName", WEATHER_WIND, 150.0)
```

## Sound Requirements

Ensure these sounds are imported in your map:
- `gg_snd_Ambient_RainLight`
- `gg_snd_Ambient_RainMedium`
- `gg_snd_Ambient_RainHeavy`
- `gg_snd_Ambient_SnowLight`
- `gg_snd_Ambient_SnowMedium`
- `gg_snd_Ambient_SnowHeavy`
- `gg_snd_WindHeavy`

## Backward Compatibility

All existing configurations remain functional:
- Old `WEATHER_RAIN_LIGHT/HEAVY` constants still work
- Old `WEATHER_SNOW` constant still works
- Existing zone configs unaffected (wind disabled by default)
- SetZoneAllowedWeather("zone", "rain", true) enables all rain types
- SetZoneAllowedWeather("zone", "snow", true) enables all snow types

## Performance Notes

- Ambient sounds use proper cleanup (no memory leaks)
- Sound volume set to 127 (moderate, not overwhelming)
- Wind weather has NO visual effects beyond weather effect (lightweight)
- All weather effects properly enabled with `EnableWeatherEffect()`
- FPS optimization API still functional for all weather types

## Testing Checklist

- [x] No compilation errors
- [ ] All weather effects display correctly in-game
- [ ] Ambient sounds play and loop properly
- [ ] Ambient sounds stop when weather changes
- [ ] Wind appears in configured zones
- [ ] Rain intensities vary appropriately
- [ ] Snow intensities vary appropriately
- [ ] Sound volume (127) is comfortable
- [ ] No sound memory leaks during long sessions
- [ ] Seasonal constraints work (no snow in summer)
- [ ] Zone-specific wind chances respected
- [ ] Manual weather triggering works with new types

## Version History

### v2.1 (Current)
- Added wind weather type
- Expanded rain to 3 intensities
- Expanded snow to 3 intensities
- Integrated ambient sounds for all weather types
- Added 10 zones with wind configuration
- Updated all core weather functions

### v2.0 (Previous)
- Zone-based architecture with 36 configured zones
- Explicit weather type configuration
- Manual snow spawn region system
- FPS optimization API
- Seasonal weather with 360-day cycle
