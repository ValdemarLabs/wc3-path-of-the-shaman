# WeatherSystem Configuration Reference

## Quick Setup Checklist

### 1. Required Files
- [ ] `WeatherSystem.j` - Main library
- [ ] `Snow.j` - Snow spawning system
- [ ] `FrostbiteSystem.j` - Cold exposure effects
- [ ] `Storm.j` - Thunder/lightning effects
- [ ] `Clouds_create.j` - Cloud spawning
- [ ] `Clouds_destroy.j` - Cloud cleanup
- [ ] `SteamBreath.j` - Steam breath effects

### 2. Required Global Variables

Create these in Variable Editor (F4):

```
Name: udg_DaysPassed
Type: Integer
Initial Value: 0

Name: udg_SnowIndex
Type: Integer
Initial Value: 0

Name: udg_SnowWaveCount
Type: Integer
Initial Value: 0

Name: udg_SnowDestructionZone
Type: Integer
Initial Value: 0

Name: udg_SnowAmounts
Type: Integer Array
Array Size: 20

Name: udg_SnowRegions
Type: Region (rect) Array
Array Size: 20

Name: udg_SnowWeather
Type: Weather Effect Array
Array Size: 20

Name: udg_SnowTimer
Type: Timer Array
Array Size: 20

Name: udg_SnowDestroyTimer
Type: Timer
```

### 3. Initialization Trigger

Create this trigger in your map:

```
Trigger Name: Weather System Init

Events:
    Map initialization

Actions:
    Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

---

## Configuration Constants in WeatherSystem.j

### Season Day Ranges

Controls which days correspond to each season:

```jass
SPRING_START       = 0      // Spring begins
SPRING_END         = 89     // Spring ends (90 days)
SUMMER_START       = 90     // Summer begins
SUMMER_END         = 179    // Summer ends (90 days)
AUTUMN_START       = 180    // Autumn begins
AUTUMN_END         = 269    // Autumn ends (90 days)
WINTER_START       = 270    // Winter begins
WINTER_END         = 359    // Winter ends (90 days)
```

**Customization Example:**
```jass
// Shorter seasons (60 days each)
SPRING_START       = 0
SPRING_END         = 59
SUMMER_START       = 60
SUMMER_END         = 119
AUTUMN_START       = 120
AUTUMN_END         = 179
WINTER_START       = 180
WINTER_END         = 239
```

### Weather Duration Ranges

Controls how long weather effects last (in seconds):

```jass
RAIN_MIN_DURATION     = 60.0    // Minimum rain duration
RAIN_MAX_DURATION     = 360.0   // Maximum rain duration
SNOW_MIN_DURATION     = 120.0   // Minimum snow duration
SNOW_MAX_DURATION     = 600.0   // Maximum snow duration
STORM_MIN_DURATION    = 30.0    // Minimum storm duration
STORM_MAX_DURATION    = 120.0   // Maximum storm duration
```

**Customization Example:**
```jass
// Longer, more dramatic weather
RAIN_MIN_DURATION     = 180.0   // 3 minutes minimum
RAIN_MAX_DURATION     = 900.0   // 15 minutes maximum
SNOW_MIN_DURATION     = 300.0   // 5 minutes minimum
SNOW_MAX_DURATION     = 1800.0  // 30 minutes maximum
```

### System Intervals

Controls how often the system checks for changes:

```jass
WEATHER_CHECK_INTERVAL = 250.0  // Check for new weather (seconds)
SEASON_CHECK_INTERVAL  = 60.0   // Update season (seconds)
```

**Customization Example:**
```jass
// More frequent weather changes
WEATHER_CHECK_INTERVAL = 120.0  // Check every 2 minutes

// Less frequent season updates (performance)
SEASON_CHECK_INTERVAL  = 300.0  // Check every 5 minutes
```

### Regional Settings

```jass
MAX_WEATHER_REGIONS = 20  // Maximum independent weather regions
```

**Customization Example:**
```jass
// More regions (requires more array space)
MAX_WEATHER_REGIONS = 50
```

### Doodad Configuration

```jass
DOODAD_RIPPLES = 'FXri'  // Ripple doodad ID for rain effects
```

**How to find your doodad ID:**
1. Open Object Editor (F6)
2. Find your ripple doodad
3. Copy the 4-character code
4. Update the constant

---

## Seasonal Weather Probability Tables

The system automatically adjusts weather based on season. These are calculated in `GetSeasonalWeatherChance()`:

### Spring
| Weather Type | Probability |
|-------------|-------------|
| Rain (Light/Heavy) | 50% |
| Snow | 0% |
| Storm | 20% |

### Summer
| Weather Type | Probability |
|-------------|-------------|
| Rain (Light/Heavy) | 20% |
| Snow | 0% |
| Storm | 30% |

### Autumn
| Weather Type | Probability |
|-------------|-------------|
| Rain (Light/Heavy) | 40% |
| Snow | 20% |
| Storm | 10% |

### Winter
| Weather Type | Probability |
|-------------|-------------|
| Rain (Light/Heavy) | 10% |
| Snow | 70% |
| Storm | 10% |

**Customization Example:**

To modify probabilities, edit the `GetSeasonalWeatherChance()` function:

```jass
// More snow in winter
if season == SEASON_WINTER then
    return 0.9  // 90% snow chance instead of 70%
endif

// More rain in spring
if season == SEASON_SPRING then
    return 0.7  // 70% rain chance instead of 50%
endif
```

---

## Weather Effect IDs (Warcraft 3)

These are the weather effect codes used by the system:

| Weather Type | Effect ID | Name |
|-------------|-----------|------|
| Light Rain | `'RAlr'` | Lordaeron Light Rain |
| Heavy Rain | `'RAhr'` | Lordaeron Heavy Rain |
| Heavy Snow | `'SNhs'` | Northrend Heavy Snow |
| Light Snow | `'SNls'` | Northrend Light Snow |
| Wind | `'WNcw'` | Windmill Wind |

**To change weather effects:**

In `WeatherSystem.j`, find the weather creation functions:

```jass
// Light Rain
set GlobalWeatherEffect = AddWeatherEffect(bj_mapInitialPlayableArea, 'RAlr')

// Change to different tileset rain:
set GlobalWeatherEffect = AddWeatherEffect(bj_mapInitialPlayableArea, 'RAir')  // Icecrown Rain
```

### Available Weather Effects by Tileset

#### Ashenvale
- Rain Light: `'RAir'`
- Rain Heavy: `'RAhr'`

#### Barrens
- Rain Light: `'RBlr'`
- Rain Heavy: `'RBhr'`

#### Lordaeron
- Rain Light: `'RAlr'`
- Rain Heavy: `'RAhr'`
- Snow Light: `'SNls'`
- Snow Heavy: `'SNhs'`

#### Northrend
- Snow Light: `'SNls'`
- Snow Heavy: `'SNhs'`
- Blizzard: `'SNbs'`

#### Outland
- Rain Light: `'WOlr'`
- Wind Light: `'WNcw'`

---

## Thunder Configuration (Storm.j Integration)

The thunder system uses the Storm library by OVOgenez. Configuration in `Storm.j`:

```jass
globals
    constant integer VAR_COUNT = 3  // Number of storm variations
    
    // Fog parameters
    boolean TF          = true      // Enable fog during lightning
    integer TF_style    = 0         // Fog style
    real    TF_zstart   = 1000.0    // Fog start height
    real    TF_zend     = 3000.0    // Fog end height
    real    TF_density  = 0.0       // Fog density
    real    TF_red      = 0.0       // Fog red color
    real    TF_green    = 0.0       // Fog green color
    real    TF_blue     = 0.0       // Fog blue color
endglobals
```

**Thunder Frequency:**

In `WeatherSystem.j`, thunder checks occur every 15 seconds:

```jass
call TimerStart(ThunderTimer, 15.0, true, function ThunderCallback)
```

**To change frequency:**
```jass
call TimerStart(ThunderTimer, 30.0, true, function ThunderCallback)  // Every 30 seconds
```

**Thunder Probability:**

In `ThunderCallback()`:
```jass
if ThunderCounter >= 3 then  // Thunder every 3 checks (45 seconds)
    local integer chance = GetRandomInt(1, 3)  // 66% chance
```

**To make more frequent:**
```jass
if ThunderCounter >= 2 then  // Thunder every 2 checks (30 seconds)
    local integer chance = GetRandomInt(1, 2)  // 100% chance
```

---

## Cloud Configuration (Clouds_create.j)

```jass
globals
    integer CLOUD_COUNT = 20  // Number of cloud effects
endglobals

function SpawnClouds takes nothing returns nothing
    // ...
    set z = GetRandomReal(200.0, 1000.0)  // Cloud height range
    call BlzSetSpecialEffectScale(cloudEffect, 455.0)  // Cloud scale
    // ...
endfunction
```

**Customization:**

```jass
// More clouds
integer CLOUD_COUNT = 40

// Higher clouds
set z = GetRandomReal(500.0, 1500.0)

// Larger clouds
call BlzSetSpecialEffectScale(cloudEffect, 600.0)

// Smaller clouds
call BlzSetSpecialEffectScale(cloudEffect, 300.0)
```

---

## Steam Breath Configuration (SteamBreath.j)

```jass
globals
    integer MAX_UNITS = 1000  // Max units with steam breath
endglobals

function Filter_IsSteamTarget takes nothing returns boolean
    return IsUnitAliveBJ(u) and 
           not IsUnitType(u, UNIT_TYPE_MECHANICAL) and 
           not IsUnitType(u, UNIT_TYPE_STRUCTURE) and 
           not IsUnitType(u, UNIT_TYPE_SUMMONED)
endfunction
```

**Customization:**

```jass
// More units supported
integer MAX_UNITS = 2000

// Include mechanical units
function Filter_IsSteamTarget takes nothing returns boolean
    return IsUnitAliveBJ(u) and 
           not IsUnitType(u, UNIT_TYPE_STRUCTURE)
endfunction
```

---

## Snow Configuration (Snow.j)

Snow spawning is controlled by the global variable:

```jass
udg_SnowAmounts[zone]  // Number of snow units to spawn per wave
```

**In GUI:**
```
Set udg_SnowAmounts[1] = 90   // 90 snow units
Set udg_SnowAmounts[2] = 150  // 150 snow units (heavier)
```

**Snow Unit ID:**
```jass
set snow = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h006', x, y, 0)
```

Change `'h006'` to your snow unit's ID.

---

## Performance Tuning

### High Performance Settings
```jass
CLOUD_COUNT = 10               // Fewer clouds
MAX_UNITS = 500                // Fewer steam breath units
WEATHER_CHECK_INTERVAL = 500.0 // Less frequent checks
```

### High Quality Settings
```jass
CLOUD_COUNT = 40               // More clouds
MAX_UNITS = 2000               // More steam breath units
WEATHER_CHECK_INTERVAL = 120.0 // More frequent checks
```

### Balanced Settings (Default)
```jass
CLOUD_COUNT = 20
MAX_UNITS = 1000
WEATHER_CHECK_INTERVAL = 250.0
```

---

## Debug Mode

To enable debug messages, in GUI:

```
Custom script:   call BJDebugMsg("[WeatherSystem] Current Weather: " + WeatherSystem_GetCurrentWeather())
Custom script:   call BJDebugMsg("[WeatherSystem] Current Season: " + WeatherSystem_GetCurrentSeason())
```

---

## Common Issues and Solutions

### Issue: Weather doesn't change
**Solution:** Enable seasonal weather:
```
Custom script:   call WeatherSystem_EnableSeasonalWeather(true)
```

### Issue: Thunder doesn't work
**Solution:** 
1. Check Storm.j is imported
2. Verify Ldummy unit exists
3. Import lightning models/sounds

### Issue: Steam breath on mechanical units
**Solution:** Modify filter in SteamBreath.j (see Steam Breath Configuration)

### Issue: Too much/little weather
**Solution:** Adjust probabilities in `GetSeasonalWeatherChance()`

### Issue: Regional weather overlaps
**Solution:** This is by design - regions can have independent weather

---

## Advanced Configuration Examples

### Example 1: Perpetual Winter Map
```jass
// In Init function
call WeatherSystem_SetSeason("winter")
call WeatherSystem_EnableSeasonalWeather(false)
call WeatherSystem_SetSnowChance(1.0)
```

### Example 2: Desert Map (Minimal Weather)
```jass
call WeatherSystem_SetRainChance(0.05)
call WeatherSystem_SetSnowChance(0.0)
call WeatherSystem_SetStormChance(0.1)
call WeatherSystem_EnableCloudsEffect(false)
call WeatherSystem_EnableSteamBreathEffect(false)
```

### Example 3: Tropical Map (Heavy Rain)
```jass
call WeatherSystem_SetRainChance(0.7)
call WeatherSystem_SetSnowChance(0.0)
call WeatherSystem_SetStormChance(0.4)
```

### Example 4: Fast Seasons (Testing)
```jass
// Change season every 60 days instead of 90
SPRING_END         = 59
SUMMER_START       = 60
SUMMER_END         = 119
AUTUMN_START       = 120
AUTUMN_END         = 179
WINTER_START       = 180
WINTER_END         = 239
```

---

## Variable Summary Table

| Variable | Type | Array | Size | Purpose |
|----------|------|-------|------|---------|
| udg_DaysPassed | Integer | No | - | Tracks game days for seasons |
| udg_SnowIndex | Integer | No | - | Current snow zone index |
| udg_SnowWaveCount | Integer | No | - | Snow wave counter |
| udg_SnowDestructionZone | Integer | No | - | Zone being destroyed |
| udg_SnowAmounts | Integer | Yes | 20 | Snow units per zone |
| udg_SnowRegions | Rect | Yes | 20 | Snow regions |
| udg_SnowWeather | Weather Effect | Yes | 20 | Weather effects per region |
| udg_SnowTimer | Timer | Yes | 20 | Timers per region |
| udg_SnowDestroyTimer | Timer | No | - | Destruction timer |

---

## Final Checklist

Before releasing your map, verify:

- [ ] All required libraries imported
- [ ] All global variables created
- [ ] Initialization trigger created
- [ ] udg_DaysPassed increments properly
- [ ] Regions created in World Editor
- [ ] Weather effects tested in each season
- [ ] Regional weather tested
- [ ] Thunder effects work
- [ ] Cloud effects appear
- [ ] Steam breath on units works
- [ ] Performance is acceptable

---

## Support Files Location

All configuration happens in these files:

1. `WeatherSystem.j` - Main configuration constants
2. `Storm.j` - Thunder/lightning configuration
3. `Clouds_create.j` - Cloud count and appearance
4. `SteamBreath.j` - Steam breath filters
5. `Snow.j` - Snow unit spawning

Make a backup before modifying!
