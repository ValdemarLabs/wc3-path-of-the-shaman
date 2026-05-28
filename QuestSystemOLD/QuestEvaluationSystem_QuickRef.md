# QuestEvaluationSystem - Quick Reference

## Setup Checklist

- [ ] Add `QuestEvaluationSystem.j` to your map
- [ ] Ensure `QuestIconSystem` is loaded
- [ ] Ensure `Reputation` system is loaded
- [ ] Set `PlayerHero = udg_Nazgrek` (or your hero variable)
- [ ] Configure quest givers in `ConfigureQuestGivers()`
- [ ] Configure quest requirements in `ConfigureQuestRequirements()`

## Essential Code Snippets

### Register Quest Givers
```jass
call QuestEval_RegisterGiver(udg_YourNPC)
```

### Add Quest with Requirements
```jass
// AddQuestRequirement(questID, npc, minLevel, faction, minRep, questType)
call AddQuestRequirement(1, udg_Thrall, 5, Faction.getFaction("Horde"), 3000, "normal")
```

### When Player Accepts Quest
```jass
call QuestEval_MarkQuestActive(questID)
call QuestIcon_RegisterQuest(npc, questID, "normal", 3) // State 3 = in progress
```

### When Quest is Complete (ready to turn in)
```jass
call QuestIcon_RegisterQuest(npc, questID, "normal", 5) // State 5 = ready
call QuestIcon_UpdateForNPC(npc)
```

### When Player Turns In Quest
```jass
call QuestEval_MarkQuestInactive(questID)
call QuestIcon_RemoveQuest(npc, questID)
call QuestIcon_UpdateForNPC(npc)
```

### Force Immediate Update
```jass
call QuestEval_ForceUpdate() // After level-up or reputation change
```

### Add Custom Condition to Quest
```jass
local trigger customTrig = CreateTrigger()
call TriggerAddCondition(customTrig, Condition(function YourConditionFunc))
call QuestEval_AddCustomCondition(questID, customTrig)
```

## Quest Types

| Type | String Value | Icon Color |
|------|--------------|------------|
| Normal Quest | `"normal"` | Yellow |
| Daily Quest | `"daily"` | Blue |
| Repeatable | `"repeatable"` | Blue |
| Dungeon Quest | `"dungeon"` | Yellow |

## Quest States

| State | Meaning | Managed By |
|-------|---------|------------|
| 1 | Unavailable (gray !) | QuestEvaluationSystem |
| 2 | Available (colored !) | QuestEvaluationSystem |
| 3 | In Progress (gray ?) | Your Quest Triggers |
| 5 | Ready to Turn In (colored ?) | Your Quest Triggers |
| 4 | Complete (no icon) | Your Quest Triggers |

## Reputation Tiers

| Tier | Min Value | Use Case |
|------|-----------|----------|
| ENEMY | -20000 | Heavily hostile quests |
| HOSTILE | -12000 | Hostile faction quests |
| UNFRIENDLY | -3000 | Wary faction quests |
| NEUTRAL | 0 | Basic access |
| FRIENDLY | 3000 | Standard quests |
| COVENANT | 6000 | Advanced quests |
| EXALTED | 12000 | Exclusive quests |

## Common Patterns

### Level-Based Quest
```jass
call AddQuestRequirement(1, npc, 5, null, 0, "normal") // Level 5 required
```

### Reputation Quest
```jass
local Faction horde = Faction.getFaction("Horde")
call AddQuestRequirement(2, npc, 5, horde, 3000, "normal") // Horde Friendly
```

### High-Level Dungeon
```jass
call AddQuestRequirement(100, npc, 15, faction, 6000, "dungeon") // Level 15, Covenant
```

### Daily Quest
```jass
call AddQuestRequirement(50, npc, 5, null, 0, "daily") // Level 5 daily
```

### No Requirements
```jass
call AddQuestRequirement(1, npc, 1, null, 0, "normal") // Level 1, no faction
```

## Integration Points

### In Hero Level-Up Trigger
```jass
call QuestEval_ForceUpdate() // Check for newly available quests
```

### After Reputation Change
```jass
call QuestEval_ForceUpdate() // Check for faction quests
```

### Quest Acceptance Dialog
```jass
call QuestEval_MarkQuestActive(questID) // Hide availability icon
call QuestIcon_RegisterQuest(npc, questID, type, 3) // Show progress icon
```

### Quest Completion Dialog
```jass
call QuestIcon_RegisterQuest(npc, questID, type, 5) // Show turn-in icon
```

### Quest Turn-In Dialog
```jass
call QuestEval_MarkQuestInactive(questID) // Allow quest to reset
call QuestIcon_RemoveQuest(npc, questID) // Remove icon
```

## Debugging

### Check Quest Count
Initialization message shows: "X quests configured for Y quest givers"

### Verify Quest Registration
```jass
call BJDebugMsg("Quest " + I2S(questID) + " requirements met: " + B2S(CheckQuestRequirements(index)))
```

### Test Level Requirements
```jass
call SetHeroLevel(udg_Nazgrek, 10, false)
call QuestEval_ForceUpdate()
```

### Test Reputation Requirements
```jass
call Reputation.addRaw(Player(0), Faction.getFaction("Horde"), 3000)
call QuestEval_ForceUpdate()
```

## Common Issues

### Icons not appearing?
- Check NPC is registered with `QuestEval_RegisterGiver()`
- Verify quest configured with `AddQuestRequirement()`
- Ensure requirements are met (level, reputation)
- Check `PlayerHero` is set correctly

### Duplicate icons?
- Make sure you call `QuestEval_MarkQuestActive()` when player accepts quest
- Don't register quest in both systems simultaneously

### Icons not updating?
- System updates every 5 seconds automatically
- Use `QuestEval_ForceUpdate()` for immediate update
- Check hero reference is correct

## Files

| File | Purpose |
|------|---------|
| `QuestEvaluationSystem.j` | Main system (configure here) |
| `QuestEvaluationSystem_Guide.md` | Full documentation |
| `QuestEvaluationSystem_Examples.j` | Code examples |
| `QuestEvaluationSystem_QuickRef.md` | This file |
| `QuestIconSystem.j` | Icon display system (dependency) |
| `Reputation.j` | Reputation system (dependency) |

## System Flow

```
Every 5 seconds:
  ↓
For each Quest Giver:
  ↓
For each Quest:
  ↓
Check Requirements (level, reputation, events, custom)
  ↓
If Active → Skip (handled by quest triggers)
If Requirements Met → State 2 (Available) → Yellow/Blue !
If Requirements Not Met → State 1 (Unavailable) → Gray !
  ↓
Update Quest Icon
  ↓
Display Best Icon for NPC
```

## Configuration Template

```jass
// In ConfigureQuestGivers():
call QuestEval_RegisterGiver(udg_NPC_Name)

// In ConfigureQuestRequirements():
local Faction myFaction = Faction.getFaction("FactionName")
call AddQuestRequirement(
    questID,        // Unique ID
    udg_NPC_Name,   // Quest giver
    minLevel,       // Minimum hero level (1+)
    myFaction,      // Faction or null
    minRep,         // Reputation value or 0
    "questType"     // "normal", "daily", "repeatable", "dungeon"
)
```

## Version Info

**QuestEvaluationSystem 1.0**
- Requires: QuestIconSystem, Reputation system
- Update Interval: 5 seconds (configurable)
- Max Quest Givers: 100
- Max Quests: 500
