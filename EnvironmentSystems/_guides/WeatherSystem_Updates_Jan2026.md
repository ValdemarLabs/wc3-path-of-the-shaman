# WeatherSystem Updates - January 2026

## Issues Fixed

### 1. Snow Units During Storms ❌→✅
**Problem:** Snow units were spawning during both `WEATHER_SNOW` and `WEATHER_STORM`, causing visual confusion.

**Solution:** Modified `StartRegionWeatherInternal()` to only call `StartSnowInRegion()` for `WEATHER_SNOW`. Storms now have only thunder and heavy rain visuals, no snow units.

### 2. Weather Duration Too Long ⏰→⏱️
**Problem:** 
- Rain: 60-360 seconds (up to 6 minutes!)
- Snow: 120-600 seconds (up to 10 minutes!)
- Storm: 30-120 seconds (seemed okay but reduced slightly)

**Solution:** Adjusted durations for better pacing:
```jass
// NEW DURATIONS
Rain:  45-180 seconds (0.75-3 minutes)
Snow:  90-300 seconds (1.5-5 minutes)
Storm: 30-90 seconds  (0.5-1.5 minutes)
```

### 3. Rain Not Appearing 🌧️
**Problem:** Rain was rarely/never appearing because the weather roll system used a single random number and checked weather types sequentially. High snow chances (like Serenaglade's 75%) would always trigger first, preventing rain from ever being checked.

**Solution:** Refactored `ZoneSeasonalWeatherCheck()` to use **probability ranges**:
- Calculates total chance from all weather types (snow + rain + storm)
- Rolls a number from 0 to totalChance
- Divides the range into segments: [0, snow), [snow, snow+rain), [snow+rain, total)
- Each weather type gets its fair share of the probability space

**Example:** Zone with 75% snow, 30% rain, 40% storm:
- Total: 145% (1.45)
- Roll 0.00-0.75: Snow
- Roll 0.75-1.05: Rain
- Roll 1.05-1.45: Storm

### 4. Cloud Height Flickering 🌥️
**Problem:** Clouds spawned at random heights (200-1000 units), causing visible flickering when players zoom the camera.

**Solution:** Changed cloud spawn to **fixed height of 350 units** in `SpawnClouds()` function. All clouds now maintain consistent height regardless of camera zoom.

---

## New Features

### FPS Optimization API 🚀

Added comprehensive performance control system while keeping snow mechanics intact (game mechanic requirement).

#### Master Toggle
```jass
call WeatherSystem_SetFPSOptimization(true)  // Disables ALL optional effects
call WeatherSystem_SetFPSOptimization(false) // Re-enables effects
```

#### Individual Effect Controls
```jass
// Disable/enable clouds
call WeatherSystem_SetCloudsEnabled(false)

// Disable/enable water ripples  
call WeatherSystem_SetRipplesEnabled(false)

// Disable/enable thunder/lightning
call WeatherSystem_SetThunderEnabled(false)

// Disable/enable steam breath effects
call WeatherSystem_SetSteamBreathEnabled(false)

// Override cloud count (lower = better FPS, 0 = use default)
call WeatherSystem_SetCloudCount(10)  // Reduce to 10 clouds instead of 20
```

#### FPS Optimization Flags
New global variables added:
- `FPS_OptimizationEnabled` - Master toggle
- `FPS_CloudsDisabled` - Individual cloud control
- `FPS_RipplesDisabled` - Individual ripple control  
- `FPS_ThunderDisabled` - Individual thunder control
- `FPS_SteamDisabled` - Individual steam control
- `FPS_CloudCountOverride` - Cloud count override (0 = default)

All effect-enabling functions now check these flags:
- `EnableCloudsInRegion()`
- `StartRipplesInRegion()`
- `EnableThunderInZone()`
- `EnableSteamBreathInRegion()`

---

## API Summary

### Complete FPS Optimization Functions

| Function | Description |
|----------|-------------|
| `SetFPSOptimization(bool)` | Master toggle - disables all optional effects |
| `SetCloudsEnabled(bool)` | Control cloud effects |
| `SetRipplesEnabled(bool)` | Control water ripple effects |
| `SetThunderEnabled(bool)` | Control thunder/lightning effects |
| `SetSteamBreathEnabled(bool)` | Control steam breath effects |
| `SetCloudCount(int)` | Override cloud count (0 = default) |

### Usage Example
```jass
function InitOptimizedWeather takes nothing returns nothing
    // For low-end machines
    call WeatherSystem_SetFPSOptimization(true)
    
    // OR for custom control
    call WeatherSystem_SetCloudsEnabled(false)     // Disable clouds
    call WeatherSystem_SetRipplesEnabled(false)    // Disable ripples
    call WeatherSystem_SetCloudCount(8)            // Reduce cloud count
    
    // Thunder and steam can stay enabled (less impact)
    call WeatherSystem_SetThunderEnabled(true)
    call WeatherSystem_SetSteamBreathEnabled(true)
    
    // Enable weather system
    call WeatherSystem_EnableSeasonalWeather(true)
endfunction
```

---

## Technical Details

### Weather Probability System Refactor

**Old System (Broken):**
```jass
roll = random(0, 1)
if roll < snowChance then -> Snow (always triggered if high)
else if roll < rainChance then -> Rain (never reached)
else if roll < stormChance then -> Storm (never reached)
```

**New System (Fixed):**
```jass
total = snowChance + rainChance + stormChance
roll = random(0, total)
accumulated = 0

accumulated += snowChance
if roll < accumulated then -> Snow

accumulated += rainChance  
if roll < accumulated then -> Rain

accumulated += stormChance
if roll < accumulated then -> Storm
```

### Effect Check Flow

All optional effects now follow this pattern:
```jass
function EnableEffect takes ... returns nothing
    // Check FPS optimization flags first
    if FPS_EffectDisabled or FPS_OptimizationEnabled then
        return  // Skip effect
    endif
    
    // Normal effect logic
    ...
endfunction
```

---

## Testing Checklist

- [x] Snow only appears with snow weather (not storms)
- [x] Weather durations feel reasonable
- [x] Rain actually appears in zones
- [x] Clouds don't flicker on camera zoom
- [x] FPS optimization API works
- [x] Snow system still functions (game mechanic)
- [x] Seasonal constraints work (no snow in spring/summer)
- [ ] Test all FPS optimization combinations
- [ ] Verify weather probabilities in all 36 zones
- [ ] Long-term weather pattern observation

---

## Notes

- **Snow System:** Left unchanged as requested (game mechanic)
- **Cloud Count:** Default is 20, can be reduced via API for FPS
- **Cloud Height:** Fixed at 350 units (adjust if needed)
- **Weather Durations:** Can be tweaked in constants if needed
- **Probability System:** Now allows multiple weather types to coexist in configuration

---

## Configuration Example

Zone with balanced weather chances:
```jass
call CreateMasterZoneInternal("BalancedZone", "none", "auto")
call SetZoneWeatherChance("BalancedZone", "rain_light", 0.3)  // 30%
call SetZoneWeatherChance("BalancedZone", "snow", 0.2)        // 20%
call SetZoneWeatherChance("BalancedZone", "storm", 0.15)      // 15%
// Total: 65% weather, 35% clear skies
// Each weather type gets proportional chance
```

---

## Files Modified

1. **WeatherSystem.j**
   - Fixed snow during storm
   - Adjusted weather durations
   - Refactored weather probability system
   - Added FPS optimization flags and API
   - Added FPS checks to effect functions

2. **Clouds_create.j**
   - Fixed cloud height to 350 units (was random 200-1000)

---

## Backward Compatibility

All existing API functions remain unchanged. New FPS optimization functions are optional additions. Default behavior (all effects enabled) is preserved unless explicitly modified.
