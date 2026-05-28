# QuestEvaluationSystem

**Automatic Quest Availability System for Warcraft III**

Version 1.0 | Author: Valdemar | 2025

---

## What is This?

The **QuestEvaluationSystem** is an automatic quest management system that evaluates quest availability based on dynamic conditions and updates quest icons in real-time. It works alongside the **QuestIconSystem** to provide a complete quest display solution.

### Key Features

✨ **Automatic Evaluation** - Checks quest requirements every 5 seconds  
🎯 **Multiple Requirement Types** - Level, reputation, events, custom conditions  
🔄 **Dynamic Updates** - Icons change automatically as conditions change  
🎨 **Visual Feedback** - Shows available, unavailable, and active quest states  
⚡ **Event Integration** - Works with your quest triggers seamlessly  
📊 **Reputation Integration** - Uses your Reputation system for faction requirements  

---

## Quick Start

### 1. Install Files

Add these files to your map:
- `QuestEvaluationSystem.j` (this system)
- `QuestIconSystem.j` (required dependency)
- `Reputation.j` (required dependency)

### 2. Configure Quest Givers

In `QuestEvaluationSystem.j`, find `ConfigureQuestGivers()`:

```jass
private function ConfigureQuestGivers takes nothing returns nothing
    call QuestEval_RegisterGiver(udg_Thrall)
    call QuestEval_RegisterGiver(udg_Jaina)
    // Add more quest givers...
endfunction
```

### 3. Configure Quest Requirements

In `ConfigureQuestRequirements()`:

```jass
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    
    // Quest 1: Level 5, Horde Neutral, Normal quest
    call AddQuestRequirement(1, udg_Thrall, 5, horde, 0, "normal")
    
    // Quest 2: Level 10, No faction requirement, Daily quest
    call AddQuestRequirement(2, udg_Jaina, 10, null, 0, "daily")
    
    // Add more quests...
endfunction
```

### 4. Integrate with Quest Triggers

When player accepts quest:
```jass
call QuestEval_MarkQuestActive(questID)
```

When player completes/abandons quest:
```jass
call QuestEval_MarkQuestInactive(questID)
```

That's it! The system will automatically show quest icons based on your configuration.

---

## How It Works

```
Every 5 seconds → Check all quest requirements
                    ↓
           Requirements Met?
                ↓         ↓
              YES         NO
                ↓         ↓
         Yellow/Blue !  Gray !
         (Available)  (Unavailable)
```

When player accepts quest → Icon changes to Gray ? (In Progress)  
When quest complete → Your triggers change to Yellow/Blue ? (Ready to turn in)  
When turned in → Icon removed, evaluation resumes

---

## Documentation

📖 **[Full Guide](QuestEvaluationSystem_Guide.md)** - Complete documentation with detailed explanations  
🎯 **[Quick Reference](QuestEvaluationSystem_QuickRef.md)** - API reference and quick lookup  
💡 **[Examples](QuestEvaluationSystem_Examples.j)** - Code examples for common scenarios  
🔄 **[Integration Summary](Quest_System_Integration_Summary.md)** - How systems work together  
📊 **[Visual Guide](QuestEvaluationSystem_Visual_Guide.md)** - Diagrams and flow charts  

---

## System Requirements

- **Warcraft III 1.26+** (or Reforged)
- **QuestIconSystem.j** - Quest icon display system
- **Reputation.j** - Faction reputation system
- **JASS/vJASS support** - NewGen Editor or similar

---

## API Quick Reference

### Core Functions

```jass
// Register an NPC as quest giver
call QuestEval_RegisterGiver(unit npc)

// Mark quest as active (when player accepts)
call QuestEval_MarkQuestActive(integer questID)

// Mark quest as inactive (when player completes/abandons)
call QuestEval_MarkQuestInactive(integer questID)

// Force immediate evaluation (don't wait for next cycle)
call QuestEval_ForceUpdate()

// Add custom condition to a quest
call QuestEval_AddCustomCondition(integer questID, trigger conditionTrigger)
```

### Configuration Functions

```jass
// In ConfigureQuestRequirements():
call AddQuestRequirement(
    questID,        // Unique quest ID
    npcUnit,        // NPC that gives this quest
    minLevel,       // Minimum hero level (0 = none)
    faction,        // Faction object (null = none)
    minReputation,  // Minimum reputation (-20000 to 20000)
    questType       // "normal", "daily", "repeatable", "dungeon"
)
```

---

## Quest States

| State | Description | Managed By | Icon |
|-------|-------------|------------|------|
| 1 | Unavailable | QuestEvaluationSystem | Gray ! |
| 2 | Available | QuestEvaluationSystem | Yellow/Blue ! |
| 3 | In Progress | Your Quest Triggers | Gray ? |
| 5 | Ready to Turn In | Your Quest Triggers | Yellow/Blue ? |
| 4 | Complete | Your Quest Triggers | None |

---

## Quest Types

| Type | Color | Use Case |
|------|-------|----------|
| `"normal"` | Yellow | Standard one-time quests |
| `"daily"` | Blue | Quests that reset daily |
| `"repeatable"` | Blue | Quests that can be repeated |
| `"dungeon"` | Yellow | Special dungeon/raid quests |

---

## Example Configuration

```jass
private function ConfigureQuestGivers takes nothing returns nothing
    call QuestEval_RegisterGiver(udg_Thrall)
    call QuestEval_RegisterGiver(udg_Jaina)
    call QuestEval_RegisterGiver(udg_Cairne)
endfunction

private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.get("Horde")
    local Faction alliance = Faction.get("Alliance")
    
    // Quest 1: First quest from Thrall (level 1, no faction requirement)
    call AddQuestRequirement(1, udg_Thrall, 1, null, 0, "normal")
    
    // Quest 2: Horde quest requiring Friendly reputation
    call AddQuestRequirement(2, udg_Thrall, 5, horde, 3000, "normal")
    
    // Quest 3: Alliance daily quest
    call AddQuestRequirement(3, udg_Jaina, 7, alliance, 0, "daily")
    
    // Quest 4: High-level dungeon quest
    call AddQuestRequirement(4, udg_Cairne, 15, horde, 6000, "dungeon")
endfunction
```

---

## Example Quest Trigger

```jass
//===========================================================================
// Quest 1 - Acceptance Trigger
//===========================================================================
function Quest001_Accept takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    
    // Mark as active in evaluation system (removes availability icon)
    call QuestEval_MarkQuestActive(questID)
    
    // Show in-progress icon
    call QuestIcon_RegisterQuest(npc, questID, "normal", 3)
    call QuestIcon_UpdateForNPC(npc)
    
    // Display message
    call DisplayTimedTextToPlayer(Player(0), 0, 0, 10.0, 
        "|cffffcc00Quest Accepted:|r Call of the Shaman")
    
    // Your quest setup code...
endfunction

//===========================================================================
// Quest 1 - Turn In Trigger
//===========================================================================
function Quest001_TurnIn takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    
    // Give rewards
    call AddHeroXP(udg_Nazgrek, 100, true)
    call Reputation.addRaw(Player(0), Faction.getFaction("Horde"), 250)
    
    // Mark as inactive (allows next quest to appear)
    call QuestEval_MarkQuestInactive(questID)
    
    // Remove icon
    call QuestIcon_RemoveQuest(npc, questID)
    call QuestIcon_UpdateForNPC(npc)
    
    // Display message
    call DisplayTimedTextToPlayer(Player(0), 0, 0, 10.0,
        "|cff00ff00Quest Completed:|r Call of the Shaman")
endfunction
```

---

## Reputation Tier Reference

| Tier | Range | Min Value for Quest |
|------|-------|---------------------|
| ENEMY | -20000 to -12000 | -20000 |
| HOSTILE | -12000 to -6000 | -12000 |
| UNFRIENDLY | -3000 to 0 | -3000 |
| NEUTRAL | 0 to 3000 | 0 |
| FRIENDLY | 3000 to 6000 | 3000 |
| COVENANT | 6000 to 12000 | 6000 |
| EXALTED | 12000 to 20000 | 12000 |

---

## Common Use Cases

### Level-Based Quest Chain
```jass
call AddQuestRequirement(1, npc, 1, null, 0, "normal")  // Quest 1: Level 1
call AddQuestRequirement(2, npc, 5, null, 0, "normal")  // Quest 2: Level 5
call AddQuestRequirement(3, npc, 10, null, 0, "normal") // Quest 3: Level 10
```

### Faction Reputation Chain
```jass
call AddQuestRequirement(10, npc, 1, horde, 0, "normal")     // Neutral
call AddQuestRequirement(11, npc, 5, horde, 3000, "normal")  // Friendly
call AddQuestRequirement(12, npc, 10, horde, 6000, "normal") // Covenant
```

### Daily Quest Hub
```jass
call AddQuestRequirement(50, npc, 5, null, 0, "daily")  // Daily 1
call AddQuestRequirement(51, npc, 5, null, 0, "daily")  // Daily 2
call AddQuestRequirement(52, npc, 5, null, 0, "daily")  // Daily 3
```

---

## Performance

- **Evaluation Frequency**: Every 5 seconds (configurable)
- **Maximum Quest Givers**: 100 (configurable)
- **Maximum Quests**: 500 (configurable)
- **CPU Impact**: Minimal - only evaluates non-active quests
- **Memory Usage**: Low - array-based storage

---

## Troubleshooting

### Quest icons not appearing?
- ✅ Verify NPC registered in `ConfigureQuestGivers()`
- ✅ Verify quest added in `ConfigureQuestRequirements()`
- ✅ Check requirements are actually met (level, reputation)
- ✅ Ensure `PlayerHero` is set correctly in Init function

### Duplicate icons showing?
- ✅ Make sure to call `QuestEval_MarkQuestActive()` when player accepts quest
- ✅ Don't register same quest in both systems simultaneously

### Icons not updating?
- ✅ Wait 5 seconds for next evaluation cycle
- ✅ Or call `QuestEval_ForceUpdate()` for immediate update
- ✅ Check hero reference is valid

---

## Advanced Features

### Custom Conditions

Add complex requirements beyond level and reputation:

```jass
// Define condition function
function Quest10_Condition takes nothing returns boolean
    return udg_BossDefeated and udg_HasSpecialItem
endfunction

// In ConfigureQuestRequirements:
local trigger customTrigger = CreateTrigger()
call TriggerAddCondition(customTrigger, Condition(function Quest10_Condition))
call AddQuestRequirement(10, npc, 10, faction, 3000, "normal")
call QuestEval_AddCustomCondition(10, customTrigger)
```

### Dynamic Quest Giver Management

```jass
// Spawn and register new quest giver at runtime
function SpawnQuestGiver takes nothing returns nothing
    local unit newNPC = CreateUnit(...)
    call QuestEval_RegisterGiver(newNPC)
    call QuestEval_ForceUpdate()
endfunction

// Remove quest giver
function RemoveQuestGiver takes unit npc returns nothing
    call QuestEval_UnregisterGiver(npc)
    call RemoveUnit(npc)
endfunction
```

### Integration with Level-Up Events

```jass
function OnHeroLevelUp takes nothing returns nothing
    // Your level-up code...
    
    // Check for newly available quests
    call QuestEval_ForceUpdate()
endfunction
```

---

## Support & Credits

**System Author**: Valdemar  
**Version**: 1.0  
**Date**: 2025  

**Dependencies**:
- QuestIconSystem by Valdemar
- Reputation System by Valdemar

**Special Thanks**:
- TheHelper.net community
- Hive Workshop community

---

## License

Free to use and modify for your Warcraft III maps.  
Credit appreciated but not required.

---

## Changelog

### Version 1.0 (2025)
- Initial release
- Automatic quest evaluation every 5 seconds
- Support for level, reputation, event, and custom conditions
- Integration with QuestIconSystem and Reputation system
- Support for normal, daily, repeatable, and dungeon quests
- Comprehensive documentation and examples

---

## Links

- **Full Documentation**: [QuestEvaluationSystem_Guide.md](QuestEvaluationSystem_Guide.md)
- **Quick Reference**: [QuestEvaluationSystem_QuickRef.md](QuestEvaluationSystem_QuickRef.md)
- **Code Examples**: [QuestEvaluationSystem_Examples.j](QuestEvaluationSystem_Examples.j)
- **Visual Guide**: [QuestEvaluationSystem_Visual_Guide.md](QuestEvaluationSystem_Visual_Guide.md)
- **Integration Guide**: [Quest_System_Integration_Summary.md](Quest_System_Integration_Summary.md)

---

**Ready to get started? Edit `QuestEvaluationSystem.j` and configure your quests!** 🎮✨
