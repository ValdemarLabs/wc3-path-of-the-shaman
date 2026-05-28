# Reputation System - Master Alliance Controller

## Overview

The Reputation system has been upgraded to be the **MASTER ALLIANCE CONTROLLER** for the entire game. It now controls not only Player 0's alliances with factions, but also the alliances between all computer-controlled factions.

## What Changed?

### 1. New Configuration Constant

```jass
private constant boolean ENABLE_INTER_FACTION_ALLIANCES = true
```

- **When `true`**: Reputation system controls alliances between ALL players (Player 0 + all computer factions)
- **When `false`**: Only controls Player 0's alliances (classic behavior)

### 2. Alliance Mapping from Reputation

The system automatically maps reputation levels to alliance states:

| Reputation Tier | Rep Range | Alliance State | Behavior |
|----------------|-----------|----------------|----------|
| **Enemy** | < -12000 | Unallied with Vision | Will attack on sight, can see each other |
| **Hostile** | -12000 to -3000 | Unallied | Will attack on sight |
| **Unfriendly** | -3000 to 0 | Neutral | Won't attack unless provoked |
| **Neutral** | 0 to 3000 | Neutral with Vision | Won't attack, can see each other |
| **Friendly** | 3000 to 6000 | Allied | Will help each other |
| **Covenant** | 6000 to 12000 | Allied with Vision | Full alliance with vision |
| **Exalted** | 12000+ | Allied with Vision | Full alliance with vision |

### 3. New Functions

#### `GetAllianceStateFromRep(integer rep) -> integer`
Converts a reputation value to an alliance state code (1-7).

#### `ApplyAllianceState(player p1, player p2, integer allianceState)`
Applies the alliance state between two players bidirectionally.

#### `UpdateInterFactionAlliances()`
Updates alliances between all computer-controlled factions based on their mutual reputations.

## How It Works

### Player 0 Alliances (Always Active)
1. Every 5 seconds, the system checks Player 0's reputation with each faction
2. Determines the appropriate alliance state from reputation
3. If the state changed, applies new alliance and displays a message to Player 0

### Inter-Faction Alliances (Optional)
When `ENABLE_INTER_FACTION_ALLIANCES = true`:

1. Every 5 seconds, checks all faction pairs (e.g., Horde vs Alliance)
2. Gets mutual reputation (Horde's rep with Alliance AND Alliance's rep with Horde)
3. Uses the **worse** of the two reputations to determine alliance
4. Applies the alliance state between those two factions
5. Tracks changes and logs them to debug

**Example:**
- Horde has -15000 rep with Alliance
- Alliance has -18000 rep with Horde
- System uses -18000 (worse) = Enemy status
- Both factions become unallied with vision (will attack each other)

## Configuration Examples

### Example 1: Dynamic Faction Politics
```jass
// In InitFactions(), set up faction relationships
call Reputation.setRep(Player(1), Faction.get("Alliance"), -15000)  // Horde hates Alliance
call Reputation.setRep(Player(2), Faction.get("Horde"), -15000)     // Alliance hates Horde
call Reputation.setRep(Player(3), Faction.get("Horde"), 8000)       // Goblins allied with Horde
call Reputation.setRep(Player(1), Faction.get("Goblins"), 8000)     // Horde allied with Goblins
```

Result:
- Horde and Alliance will be enemies (attack on sight)
- Horde and Goblins will be allied (help each other)
- Alliance and Goblins' relationship depends on their mutual reputation

### Example 2: Shifting Alliances
When Player 0 gains reputation with Horde:
```jass
call Reputation.addRaw(Player(0), Faction.get("Horde"), 5000)
```

This changes:
1. Player 0's alliance with Horde (from Hostile to Friendly)
2. If linked factions exist, their reputation may also change
3. Inter-faction alliances remain unchanged (only involves Player 0)

When one faction gains reputation with another:
```jass
call Reputation.addRaw(Player(1), Faction.get("FelOrcs"), 10000)  // Horde becomes friendly with Fel Orcs
```

This changes:
1. Horde's alliance with Fel Orcs (becomes allied)
2. Affects the entire political landscape
3. May cause cascading effects if factions are linked

## Benefits

### 1. **Centralized Alliance Control**
- All alliances controlled by one system
- No need to manually call SetPlayerAlliance in multiple places
- Consistent and predictable behavior

### 2. **Dynamic World**
- Faction relationships can change based on player actions
- Reputation changes ripple through the entire world
- Creates a living, reactive political system

### 3. **Automatic Management**
- Alliances update automatically every 5 seconds
- No manual intervention needed
- Change detection prevents unnecessary updates

### 4. **Configurable**
- Toggle inter-faction alliances on/off with one constant
- Easy to extend with new reputation tiers
- Debug messages for troubleshooting

## Use Cases

### Scenario 1: War and Peace
**Setup:**
- Horde and Alliance start as enemies (-15000 rep)
- Player completes peace quest
- Quest gives +30000 rep to both factions with each other

**Result:**
- Horde and Alliance become allied
- Their units stop fighting
- They will defend each other against common enemies

### Scenario 2: Betrayal
**Setup:**
- Player is allied with Goblins (+10000 rep)
- Player accidentally kills Goblin merchant
- Loses -5000 rep with Goblins

**Result:**
- Player drops from Exalted to Friendly
- Alliance state changes from Allied Vision to Allied
- Slight gameplay difference (less vision sharing)

### Scenario 3: Faction Merger
**Setup:**
- Two neutral factions (Tribe A and Tribe B)
- Player completes unification quest
- Both tribes gain +15000 rep with each other

**Result:**
- Tribes become allied with vision
- They share vision and resources
- Act as a unified force

## Technical Notes

### Performance
- Updates only every 5 seconds (configurable via RELATION_UPDATE_INTERVAL)
- Change detection prevents unnecessary alliance updates
- O(n²) complexity for inter-faction updates, but n is typically small (<15 factions)

### State Tracking
- Uses `prevStates` table to track previous alliance states
- Unique keys for Player 0 alliances: `factionId`
- Unique keys for inter-faction alliances: `faction1Id * 1000 + faction2Id`
- Only updates alliances when state actually changes

### Mutual Reputation Logic
For inter-faction alliances, the system uses the **worse** reputation:
```jass
if rep1to2 < rep2to1 then
    set finalRep = rep1to2
else
    set finalRep = rep2to1
endif
```

This ensures that if one faction hates another, they won't be allied even if the feeling isn't mutual.

## Debugging

Enable debug messages to see alliance updates:
```jass
call BJDebugMsg("[Reputation] Inter-faction alliance updated: Horde <-> Alliance = Enemy")
```

These messages show:
- Which factions' alliance changed
- The new alliance state
- Helps troubleshoot unexpected alliance behavior

## Migration from Old System

If you have manual `SetPlayerAlliance` calls:

**Before:**
```jass
call SetPlayerAllianceStateBJ(Player(1), Player(2), bj_ALLIANCE_UNALLIED)
```

**After:**
```jass
// Set reputation instead - alliance updates automatically
call Reputation.setRep(Player(1), Faction.get("Alliance"), -15000)
```

## Summary

The Reputation system is now the **single source of truth** for all alliances in the game. By setting up faction reputations properly in `InitFactions()`, you create a dynamic, reactive world where alliances shift based on player actions and faction relationships.

**Key Principle:** Don't set alliances manually. Set reputation instead, and let the master system handle the rest!
