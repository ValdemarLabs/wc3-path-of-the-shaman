# Temporal Hostility - Quick Configuration Guide

## To Enable/Disable

Find this section in `Reputation.j`:

```jass
// TEMPORAL HOSTILITY SYSTEM
// When true, non-hostile factions become temporarily hostile when attacked/killed by Player(0)
// After the duration expires, the faction returns to its original status
private constant boolean ENABLE_TEMPORAL_HOSTILITY = true

// Duration (in seconds) that a faction remains temporarily hostile
private constant real TEMPORAL_HOSTILITY_DURATION = 30.0
```

## Configuration Options

### 1. Turn System On/Off
```jass
private constant boolean ENABLE_TEMPORAL_HOSTILITY = true   // ON
private constant boolean ENABLE_TEMPORAL_HOSTILITY = false  // OFF
```

### 2. Change Duration
```jass
private constant real TEMPORAL_HOSTILITY_DURATION = 15.0   // 15 seconds
private constant real TEMPORAL_HOSTILITY_DURATION = 30.0   // 30 seconds (default)
private constant real TEMPORAL_HOSTILITY_DURATION = 60.0   // 1 minute
private constant real TEMPORAL_HOSTILITY_DURATION = 120.0  // 2 minutes
```

## How It Works

1. **When Player(0) attacks or kills a faction unit:**
   - If faction is NOT already hostile/enemy → becomes temporarily hostile
   - If faction IS already hostile/enemy → nothing happens (they're already hostile)

2. **During temporary hostility:**
   - Faction attacks Player(0) on sight
   - Alliance state is set to "Unallied"
   - Regular reputation system updates are paused for this faction

3. **After duration expires:**
   - Faction returns to whatever status their reputation indicates
   - Normal reputation-based alliance resumes

## Examples

### Example 1: Short Retaliation (15 seconds)
Good for quick "oops" moments when player accidentally attacks wrong unit.
```jass
private constant real TEMPORAL_HOSTILITY_DURATION = 15.0
```

### Example 2: Standard Duration (30 seconds)
Balanced duration - enough to escape but not too long.
```jass
private constant real TEMPORAL_HOSTILITY_DURATION = 30.0
```

### Example 3: Long Consequence (2 minutes)
For more serious consequences of attacking neutral/friendly factions.
```jass
private constant real TEMPORAL_HOSTILITY_DURATION = 120.0
```

### Example 4: Disable Completely
If you want reputation changes only, no temporary hostility.
```jass
private constant boolean ENABLE_TEMPORAL_HOSTILITY = false
```

## Important Notes

- **Does NOT apply to already hostile factions** (Hostile or Enemy tier)
- **Works with reputation system** - if reputation drops to hostile during temporary hostility, they stay hostile permanently
- **Per-faction basis** - attacking Horde only makes Horde hostile, not their allies
- **No stacking** - attacking same faction multiple times doesn't extend duration
- **Respects visibility** - hidden factions don't show messages but still become hostile

## Messages Shown to Player

When temporal hostility triggers:
> "|cffff4040[Faction Name] has become temporarily hostile!|r"

When hostility expires:
> "|cffff8040[Faction Name] is no longer hostile to you.|r"

## Troubleshooting

**Problem:** Factions become hostile forever
- **Cause:** Reputation dropped too low during temporary hostility
- **Solution:** Check your `REP_KILL_DELTA` values - they might be too harsh

**Problem:** Nothing happens when I attack
- **Cause:** System is disabled or faction is already hostile
- **Solution:** Check `ENABLE_TEMPORAL_HOSTILITY = true` and faction's reputation

**Problem:** Duration too short/long
- **Cause:** `TEMPORAL_HOSTILITY_DURATION` needs adjustment
- **Solution:** Change the value to suit your gameplay
