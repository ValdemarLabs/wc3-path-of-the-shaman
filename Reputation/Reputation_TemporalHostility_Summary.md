# Temporal Hostility System - Implementation Summary

## Overview
The Reputation system now includes a **Temporal Hostility** feature that makes factions temporarily hostile when attacked or killed by Player(0). After a configurable duration, the faction returns to its original status based on reputation.

## Configuration

### Global Constants (in `globals` section)

```jass
// TEMPORAL HOSTILITY SYSTEM
// When true, non-hostile factions become temporarily hostile when attacked/killed by Player(0)
// After the duration expires, the faction returns to its original status
private constant boolean ENABLE_TEMPORAL_HOSTILITY = true

// Duration (in seconds) that a faction remains temporarily hostile
private constant real TEMPORAL_HOSTILITY_DURATION = 30.0
```

### How to Configure:
1. **Enable/Disable**: Set `ENABLE_TEMPORAL_HOSTILITY` to `true` or `false`
2. **Duration**: Change `TEMPORAL_HOSTILITY_DURATION` to desired seconds (e.g., 60.0 for 1 minute)

## Key Features

### 1. Smart Hostility Triggering
- Only triggers for factions that are **NOT already hostile or enemy**
- Skips factions with reputation in Enemy or Hostile tiers
- Works for both:
  - **Unit kills** by Player(0)
  - **Unit attacks** by Player(0)

### 2. Status Preservation
- Stores the faction's original alliance state before making them hostile
- Restores exact previous state after duration expires
- Does not interfere with reputation-based alliance updates during hostility

### 3. Visual Feedback
- Shows message when faction becomes temporarily hostile (if faction is visible)
- Shows message when faction returns to original status (if faction is visible)
- Messages respect the faction's `isVisible` setting

### 4. Debug Information
- Logs when temporal hostility is triggered
- Logs when faction is already hostile (skip case)
- Logs when faction status is restored

## Technical Implementation

### New Data Structures

1. **temporalHostilityActive** (Table)
   - Tracks which factions (by ID) are currently temporarily hostile
   - Used to prevent re-triggering and to skip reputation updates

2. **temporalHostilityOriginalStatus** (Table)
   - Stores the original alliance state code before temporal hostility
   - Used to restore exact state when timer expires

3. **temporalHostilityHash** (hashtable)
   - Private hashtable for timer callbacks
   - Maps timer handle IDs to TemporalHostility struct instances

### TemporalHostility Struct

**Methods:**
- `trigger(Faction f)` - Triggers temporary hostility for a faction
- `restore()` - Restores faction to original status
- `onExpire()` - Timer callback to restore status

### Integration Points

1. **OnUnitDeathHandler**
   - When Player(0) kills a unit, triggers temporal hostility for victim's faction

2. **OnUnitAttacked**
   - When Player(0) attacks a unit, triggers temporal hostility for target's faction
   - Registered globally for all units via `EVENT_PLAYER_UNIT_ATTACKED`

3. **UpdateFactionAlliances**
   - Skips alliance updates for temporarily hostile factions
   - Prevents reputation changes from overriding temporary hostility

## Example Scenarios

### Scenario 1: Attacking Neutral Faction
- Initial state: Player(0) is Neutral with Horde (rep: 2000)
- Action: Player(0) attacks a Horde unit
- Result:
  - Horde becomes temporarily hostile for 30 seconds
  - Message: "|cffff4040Horde has become temporarily hostile!|r"
  - After 30 seconds: Horde returns to Neutral
  - Message: "|cffff8040Horde is no longer hostile to you.|r"

### Scenario 2: Attacking Already Hostile Faction
- Initial state: Player(0) is Hostile with Alliance (rep: -7000)
- Action: Player(0) kills an Alliance unit
- Result:
  - Temporal hostility is NOT triggered (already hostile)
  - Only reputation change occurs (if configured)

### Scenario 3: Killing Friendly Faction Unit
- Initial state: Player(0) is Friendly with Goblins (rep: 4000)
- Action: Player(0) kills a Goblin unit
- Result:
  - Goblins become temporarily hostile for 30 seconds
  - Reputation decreases by configured amount
  - After 30 seconds: Returns to Friendly (or whatever tier reputation is now in)

## Alliance State Codes

| Code | Status | Description |
|------|--------|-------------|
| 1 | Enemy | Unallied with vision (hunt player) |
| 2 | Hostile | Unallied (attack on sight) |
| 3 | Unfriendly | Neutral |
| 4 | Neutral | Neutral with vision |
| 5 | Friendly | Allied |
| 6 | Covenant | Allied with vision |
| 7 | Exalted | Allied with vision |

## Notes

- Temporal hostility always applies alliance state 2 (Hostile/Unallied)
- The system respects faction visibility settings for messages
- Multiple attacks within the duration do not restart the timer
- The system integrates seamlessly with existing reputation mechanics
- Does not affect inter-faction alliances (only Player(0) relationships)

## Debugging

Enable debug messages to see:
- When temporal hostility triggers
- Original alliance state before hostility
- When status is restored
- Skip reasons (already hostile, already triggered, etc.)

All debug messages are prefixed with `[TemporalHostility]` for easy filtering.
