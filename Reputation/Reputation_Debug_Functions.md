# Reputation System - Debug Functions

## Overview
Three new public debug functions have been added to help test and debug the reputation system.

---

## 1. SetFactionReputation
**Set a faction's reputation to a specific value (bypasses normal gain/loss system)**

### Syntax
```jass
call SetFactionReputation(player whichPlayer, string factionName, integer repValue)
```

### Parameters
- `whichPlayer` - The player whose reputation you want to change (usually `Player(0)`)
- `factionName` - The name of the faction (e.g., "Horde", "Alliance", "Satyr")
- `repValue` - The exact reputation value to set (-20000 to 20000)

### Reputation Tiers
- **-20000 to -12000**: Enemy (Dark Red)
- **-12000 to -3000**: Hostile (Red)
- **-3000 to 0**: Unfriendly (Orange)
- **0 to 3000**: Neutral (White)
- **3000 to 6000**: Friendly (Green)
- **6000 to 12000**: Covenant (Bright Green)
- **12000 to 20000**: Exalted (Gold)

### Examples
```jass
// Set Horde reputation to Friendly (5000)
call SetFactionReputation(Player(0), "Horde", 5000)

// Set Alliance reputation to Enemy (-15000)
call SetFactionReputation(Player(0), "Alliance", -15000)

// Set Satyr to Neutral (1000)
call SetFactionReputation(Player(0), "Satyr", 1000)

// Reset Goblins to exactly 0 (Unfriendly/Neutral threshold)
call SetFactionReputation(Player(0), "Goblins", 0)

// Max out Elarindor reputation (Exalted)
call SetFactionReputation(Player(0), "Elarindor", 20000)
```

### Notes
- This function immediately sets the reputation value
- It triggers alliance state updates on the next tick
- Debug message is printed to console
- Player receives an in-game notification
- Useful for testing specific reputation thresholds

---

## 2. TriggerFactionTemporalHostility
**Manually activate temporal hostility for a faction**

### Syntax
```jass
call TriggerFactionTemporalHostility(string factionName)
```

### Parameters
- `factionName` - The name of the faction to make temporarily hostile

### Examples
```jass
// Make Horde temporarily hostile (even if you're friendly)
call TriggerFactionTemporalHostility("Horde")

// Make Alliance temporarily hostile
call TriggerFactionTemporalHostility("Alliance")

// Make Goblins temporarily hostile
call TriggerFactionTemporalHostility("Goblins")
```

### Behavior
- Only triggers if faction is NOT already Enemy or Hostile by reputation
- Lasts for 120 seconds (configurable via `TEMPORAL_HOSTILITY_DURATION`)
- Affects all players mapped to that faction
- After expiration, faction returns to original reputation-based state
- Shows "X has become temporarily hostile!" message
- Shows remaining time in reputation multiboard

### Notes
- Useful for testing temporal hostility system
- Won't trigger if faction is already Enemy or Hostile
- Debug message is printed to console
- If already temporarily hostile, won't restart the timer

---

## 3. SetReputationMultiplier
**Toggle 10x reputation gains and losses**

### Syntax
```jass
call SetReputationMultiplier(boolean enable)
```

### Parameters
- `enable` - `true` to enable 10x multiplier, `false` to disable (normal gains/losses)

### Examples
```jass
// Enable 10x reputation gains/losses
call SetReputationMultiplier(true)

// Disable multiplier (return to normal)
call SetReputationMultiplier(false)
```

### Behavior
- When enabled, ALL reputation changes are multiplied by 10x
- Affects:
  - Kill reputation (e.g., -50 becomes -500)
  - Quest rewards
  - Manual reputation changes
  - Linked faction reputation
- Does NOT affect reputation set via `SetFactionReputation()`
- Shows debug message in console and on-screen notification

### Use Cases
- **Fast testing**: Quickly reach different reputation tiers
- **Speed runs**: Rapidly gain/lose reputation during testing
- **Threshold testing**: Test what happens at tier boundaries

### Examples in Practice
```jass
// Enable multiplier for fast testing
call SetReputationMultiplier(true)

// Kill a few Horde units (normally -50 each = -500 each with multiplier)
// Player will quickly reach Hostile status

// Disable when done testing
call SetReputationMultiplier(false)
```

---

## Complete Testing Workflow Example

```jass
// Test temporal hostility with Horde
// 1. Set yourself to Friendly with Horde
call SetFactionReputation(Player(0), "Horde", 5000)

// 2. Wait a moment for alliance to update, then trigger temporal hostility
call TriggerFactionTemporalHostility("Horde")

// 3. Horde should now be hostile for 120 seconds
// 4. After 120 seconds, they should return to Friendly

// Test rapid reputation changes
// 1. Enable 10x multiplier
call SetReputationMultiplier(true)

// 2. Kill some Alliance units (-50 each becomes -500 each)
// 3. Watch reputation drop rapidly

// 4. Reset Alliance to neutral
call SetFactionReputation(Player(0), "Alliance", 1000)

// 5. Disable multiplier
call SetReputationMultiplier(false)
```

---

## Available Faction Names

Use these exact strings (case-sensitive) with the debug functions:

- `"Horde"`
- `"Alliance"`
- `"Satyr"`
- `"Riverbane"`
- `"Fel Orcs"`
- `"Undead"`
- `"Goblins"`
- `"Elarindor"`
- `"Bonecrusher Clan"`
- `"The True Horde"`
- `"Human Citizen"`
- `"Gnolls"`
- `"Jungle trolls"`
- `"Forest trolls"`
- `"Kobolds"`

---

## Triggering from GUI

You can call these functions from World Editor GUI triggers:

### Custom Script Action
1. Create a new trigger
2. Add action: **Custom Script**
3. Enter the function call

Example:
```
Custom script: call SetFactionReputation(Player(0), "Horde", 8000)
Custom script: call TriggerFactionTemporalHostility("Alliance")
Custom script: call SetReputationMultiplier(true)
```

### With ESC Key Detection
```
Events
    Player - Player 1 (Red) presses the Escape key

Actions
    Custom script: call SetReputationMultiplier(GetBooleanOr(REPUTATION_MULTIPLIER_ENABLED, false) == false)
    Game - Display to (All players) the text: Toggled reputation multiplier
```

---

## Debugging Tips

1. **Enable RE_DEBUG**: Set `RE_DEBUG = true` in the code to see detailed console output
2. **Watch Multiboard**: Open reputation board to see real-time changes
3. **Check Alliance States**: Observe unit behavior changes when toggling temporal hostility
4. **Test Mapped Players**: Remember Player(1) is mapped to Horde, so changes affect them too

---

## Safety Notes

- These are DEBUG functions - remove or disable in production
- Reputation multiplier affects ALL reputation changes globally
- Setting reputation directly bypasses linked faction effects
- Temporal hostility only works if `ENABLE_TEMPORAL_HOSTILITY = true`
