# QuestEvaluationSystem Guide

## Overview

The **QuestEvaluationSystem** is an automated quest availability checker that works with the **QuestIconSystem**. It periodically (every 5 seconds) evaluates all configured quest givers to determine which quests should be displayed as available, unavailable, or hidden based on dynamic conditions.

## Features

- **Automatic Quest Icon Updates**: Evaluates quests every 5 seconds and updates icons
- **Multiple Requirement Types**:
  - Hero level requirements
  - Faction reputation requirements
  - Event-based requirements (using boolean flags)
  - Custom condition functions
- **Integration with Event-Based Quests**: Prevents duplicate icons when quests are accepted
- **Support for All Quest Types**: normal, daily, repeatable, dungeon
- **Dynamic State Management**: Automatically transitions between unavailable (gray !) and available (colored !)

## How It Works

### Quest States

The system manages these quest states automatically:

1. **State 1 (Unavailable)** - Requirements not met → Gray Exclamation Mark
2. **State 2 (Available)** - Requirements met → Yellow/Blue Exclamation Mark
3. **Active Quest** - Player accepted quest → Icon removed from this system (handled by quest triggers)
4. **States 3, 5** - Quest progress/completion → Handled by your quest triggers using QuestIconSystem directly

### Evaluation Cycle

Every 5 seconds, the system:
1. Loops through all registered quest givers
2. For each quest giver, checks all their quests
3. Evaluates requirements (level, reputation, events, custom conditions)
4. Updates the quest state (unavailable vs available)
5. Calls `QuestIcon_RegisterQuest()` to update the icon
6. Calls `QuestIcon_UpdateForNPC()` to refresh the display

## Configuration

### Step 1: Register Quest Givers

In the `ConfigureQuestGivers()` function, register all NPCs that give quests:

```jass
private function ConfigureQuestGivers takes nothing returns nothing
    call QuestEval_RegisterGiver(udg_Thrall)
    call QuestEval_RegisterGiver(udg_Jaina)
    call QuestEval_RegisterGiver(udg_Cairne)
    call QuestEval_RegisterGiver(udg_VendorOrc)
endfunction
```

### Step 2: Define Quest Requirements

In the `ConfigureQuestRequirements()` function, define each quest:

```jass
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    local Faction alliance = Faction.getFaction("Alliance")
    
    // Quest 1: Level 1 normal quest from Thrall, no other requirements
    call AddQuestRequirement(1, udg_Thrall, 1, null, 0, "normal")
    
    // Quest 2: Level 5 quest requiring Horde Friendly (3000 rep)
    call AddQuestRequirement(2, udg_Thrall, 5, horde, 3000, "normal")
    
    // Quest 3: Daily quest from Jaina, level 10, Alliance Neutral
    call AddQuestRequirement(3, udg_Jaina, 10, alliance, 0, "daily")
    
    // Quest 4: Dungeon quest, level 15, Horde Covenant
    call AddQuestRequirement(4, udg_Cairne, 15, horde, 6000, "dungeon")
    
    // Quest 5: Repeatable quest, no requirements
    call AddQuestRequirement(5, udg_VendorOrc, 1, null, 0, "repeatable")
endfunction
```

### AddQuestRequirement Parameters

```jass
call AddQuestRequirement(questID, npcUnit, minLevel, faction, minReputation, questType)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `questID` | integer | Unique ID for this quest (use same ID in your quest triggers) |
| `npcUnit` | unit | The unit variable that gives this quest |
| `minLevel` | integer | Minimum hero level required (0 = no requirement) |
| `faction` | Faction | Faction object from Reputation system (null = no faction requirement) |
| `minReputation` | integer | Minimum reputation value (-20000 to 20000) |
| `questType` | string | "normal", "daily", "repeatable", or "dungeon" |

### Reputation Tiers Reference

| Tier | Range | Value for minReputation |
|------|-------|------------------------|
| ENEMY | -20000 to -12000 | -20000 |
| HOSTILE | -12000 to -6000 | -12000 |
| UNFRIENDLY | -3000 to 0 | -3000 |
| NEUTRAL | 0 to 3000 | 0 |
| FRIENDLY | 3000 to 6000 | 3000 |
| COVENANT | 6000 to 12000 | 6000 |
| EXALTED | 12000 to 20000 | 12000 |

## Integration with Quest Triggers

### When Player Accepts Quest

When a player accepts a quest from dialogue/interaction, your quest trigger should call:

```jass
call QuestEval_MarkQuestActive(questID)
```

This prevents the evaluation system from showing the availability icon while the quest is active.

**Example Quest Acceptance Trigger:**

```jass
function AcceptQuest_Actions takes nothing returns nothing
    local integer questID = 1
    
    // Mark as active in evaluation system (removes availability icon)
    call QuestEval_MarkQuestActive(questID)
    
    // Register as in-progress in QuestIconSystem
    call QuestIcon_RegisterQuest(udg_Thrall, questID, "normal", 3)
    
    // Your quest setup code...
    // Create quest objectives, etc.
endfunction
```

### When Quest is Turned In or Abandoned

```jass
function CompleteQuest_Actions takes nothing returns nothing
    local integer questID = 1
    
    // Mark as inactive in evaluation system
    call QuestEval_MarkQuestInactive(questID)
    
    // Remove icon from QuestIconSystem
    call QuestIcon_RemoveQuest(udg_Thrall, questID)
    
    // Your quest completion code...
endfunction
```

### Updating Quest Progress

For quests that are event-based (player in progress):

```jass
function UpdateQuestProgress takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    
    // Check if quest objectives are complete
    if QuestObjectivesComplete() then
        // Ready to turn in
        call QuestIcon_RegisterQuest(npc, questID, "normal", 5)
    else
        // Still in progress
        call QuestIcon_RegisterQuest(npc, questID, "normal", 3)
    endif
    
    call QuestIcon_UpdateForNPC(npc)
endfunction
```

## API Reference

### QuestEval_RegisterGiver
```jass
call QuestEval_RegisterGiver(unit npc)
```
Registers an NPC as a quest giver. The system will evaluate their quests every 5 seconds.

### QuestEval_UnregisterGiver
```jass
call QuestEval_UnregisterGiver(unit npc)
```
Removes an NPC from the evaluation system (e.g., if they die or are removed).

### QuestEval_MarkQuestActive
```jass
call QuestEval_MarkQuestActive(integer questID)
```
Call this when a player accepts a quest. Removes the availability icon from evaluation system.

### QuestEval_MarkQuestInactive
```jass
call QuestEval_MarkQuestInactive(integer questID)
```
Call this when a quest is completed or abandoned. Allows the quest to be evaluated again.

### QuestEval_ForceUpdate
```jass
call QuestEval_ForceUpdate()
```
Forces an immediate evaluation of all quest givers (instead of waiting for next 5-second cycle).

### QuestEval_AddCustomCondition
```jass
call QuestEval_AddCustomCondition(integer questID, boolexpr condition)
```
Adds a custom condition function to a quest for advanced requirements.

## Advanced: Custom Conditions

For complex requirements beyond level and reputation, use custom conditions:

```jass
// Create a condition function
function Quest10_CustomCondition takes nothing returns boolean
    // Example: Requires player to have defeated a specific boss
    return udg_BossDefeated == true and udg_PlayerHasItem == true
endfunction

// In ConfigureQuestRequirements:
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    local trigger customTrigger = CreateTrigger()
    
    // Setup custom condition trigger
    call TriggerAddCondition(customTrigger, Condition(function Quest10_CustomCondition))
    
    // Add the quest
    call AddQuestRequirement(10, udg_SpecialNPC, 10, horde, 3000, "normal")
    
    // Add custom condition trigger
    call QuestEval_AddCustomCondition(10, customTrigger)
endfunction
```

## Advanced: Event-Based Quests

For quests that require specific world events to occur:

Currently, the system has placeholders for event-based requirements. You can extend this by:

1. Creating a boolean array for quest events (e.g., `udg_QuestEvents`)
2. Setting flags when events occur
3. Modifying the `CheckQuestRequirements` function to check your event array

**Example Extension:**

```jass
// In your globals:
globals
    boolean array udg_QuestEvents // Index = event ID
endglobals

// Modify CheckQuestRequirements to check events:
private function CheckQuestRequirements takes integer questIndex returns boolean
    // ... existing code ...
    
    // Check event flag requirement
    if QuestRequiresEvent[questIndex] then
        set eventMet = udg_QuestEvents[QuestEventFlag[questIndex]]
    endif
    
    // ... rest of function ...
endfunction

// In AddQuestRequirement, add parameters for event checking:
private function AddQuestRequirementWithEvent takes integer questID, unit npc, integer minLevel, Faction faction, integer minRep, string questType, integer eventID returns nothing
    // ... existing code ...
    set QuestRequiresEvent[QuestCount] = true
    set QuestEventFlag[QuestCount] = eventID
    // ... rest of function ...
endfunction
```

## Example: Complete Quest Setup

Here's a complete example of setting up a quest chain:

```jass
//===========================================================================
// Quest Chain: "Help the Horde"
//===========================================================================

// Quest Giver Setup
private function ConfigureQuestGivers takes nothing returns nothing
    call QuestEval_RegisterGiver(udg_ThrallQuestGiver)
    call QuestEval_RegisterGiver(udg_CairneQuestGiver)
endfunction

// Quest Configuration
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    
    // Quest 100: "First Steps" - No requirements
    call AddQuestRequirement(100, udg_ThrallQuestGiver, 1, null, 0, "normal")
    
    // Quest 101: "Proving Yourself" - Requires level 3
    call AddQuestRequirement(101, udg_ThrallQuestGiver, 3, null, 0, "normal")
    
    // Quest 102: "Earning Trust" - Requires level 5 and Horde Neutral
    call AddQuestRequirement(102, udg_ThrallQuestGiver, 5, horde, 0, "normal")
    
    // Quest 103: "Champion of the Horde" - Requires level 10 and Horde Friendly
    call AddQuestRequirement(103, udg_CairneQuestGiver, 10, horde, 3000, "normal")
    
    // Quest 104: "Daily: Horde Supply Run" - Daily quest, level 5
    call AddQuestRequirement(104, udg_ThrallQuestGiver, 5, null, 0, "daily")
endfunction
```

## Troubleshooting

### Quest icons not appearing
1. Verify NPC is registered in `ConfigureQuestGivers()`
2. Check quest is configured in `ConfigureQuestRequirements()`
3. Ensure QuestIconSystem models exist in your map
4. Check debug message on initialization for quest count

### Icons showing when they shouldn't
1. Verify you're calling `QuestEval_MarkQuestActive()` when player accepts quest
2. Check requirement values (level, reputation) are correct
3. Use `call BJDebugMsg()` to debug requirement checking

### Icons not updating
1. System updates every 5 seconds - wait for next cycle or call `QuestEval_ForceUpdate()`
2. Ensure hero reference is set correctly (`PlayerHero = udg_Nazgrek`)
3. Verify Reputation system is working properly

### Duplicate icons
This happens when both the evaluation system AND your quest triggers register the same quest. Solution:
- Let evaluation system handle states 1 (unavailable) and 2 (available)
- Call `QuestEval_MarkQuestActive()` when player accepts
- Your quest triggers handle states 3 (in progress) and 5 (ready to turn in)

## Performance Notes

- The system evaluates quests every 5 seconds (configurable via `EVALUATION_INTERVAL`)
- Maximum 100 quest givers (`MAX_QUEST_GIVERS`)
- Maximum 500 quests total (`MAX_QUESTS`)
- Each evaluation loops through all quests for all quest givers
- For optimal performance, keep quest counts reasonable per NPC

## Future Enhancements

Possible extensions you could add:

1. **Time-based quests**: Quests available only at certain times
2. **Class restrictions**: Quests only for specific hero types
3. **Item requirements**: Need specific items to unlock quests
4. **Completed quest dependencies**: Quest chains requiring previous quest completion
5. **Party size requirements**: Quests requiring multiple players
6. **Zone-based availability**: Quests only available in certain regions

## See Also

- `QuestIconSystem.j` - The visual icon display system
- `Reputation.j` - The faction reputation system
- `QuestEvaluationSystem.j` - This system (source code)
