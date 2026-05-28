# Quest System Integration Summary

## System Overview

The complete quest system consists of two complementary libraries:

### 1. **QuestIconSystem** (Display Layer)
- Handles visual quest icons (exclamation marks, question marks)
- Manages overhead effects and minimap pings
- Displays appropriate icon based on quest state and type
- **Manual control** - you tell it what to display

### 2. **QuestEvaluationSystem** (Logic Layer) ⭐ NEW
- Automatically evaluates quest availability every 5 seconds
- Checks level requirements, reputation, events, custom conditions
- Updates icons dynamically as conditions change
- **Automatic control** - it decides what should be displayed

## How They Work Together

```
┌─────────────────────────────────────────────────────────────────┐
│                    QUEST EVALUATION SYSTEM                      │
│  Runs every 5 seconds - checks requirements for all NPCs       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Calls QuestIcon API
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                     QUEST ICON SYSTEM                           │
│  Displays the appropriate icon based on state/type             │
└─────────────────────────────────────────────────────────────────┘
                         │
                         │ Visual Output
                         ↓
                    [Quest Giver NPC]
                         🔸 ← Icon
```

## State Management Flow

### Before Player Accepts Quest

**Managed by: QuestEvaluationSystem**

```
Requirements NOT Met → State 1 (Unavailable) → Gray Exclamation
Requirements Met     → State 2 (Available)   → Yellow/Blue Exclamation
```

The evaluation system automatically transitions between states 1 and 2 based on:
- Hero level changes
- Reputation changes
- Event flags
- Custom conditions

### After Player Accepts Quest

**Managed by: Your Quest Triggers**

```
Quest Accepted    → Call QuestEval_MarkQuestActive(questID)
                  → Evaluation system stops showing availability icon
                  → Your trigger shows State 3 icon (in progress)

Quest Objectives  → Your trigger updates to State 5 (ready to turn in)
Complete          → Shows colored question mark

Quest Turned In   → Call QuestEval_MarkQuestInactive(questID)
                  → Evaluation system resumes checking availability
                  → Quest may appear again (for dailies/repeatables)
```

## Complete Quest Lifecycle Example

Let's follow Quest ID 100: "Horde Training" from start to finish:

### 1. Configuration (Setup)
```jass
// In QuestEvaluationSystem.j:
private function ConfigureQuestGivers takes nothing returns nothing
    call QuestEval_RegisterGiver(udg_Thrall) // Register Thrall as quest giver
endfunction

private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.get("Horde")
    // Quest 100: Requires level 5 and Horde Neutral reputation
    call AddQuestRequirement(100, udg_Thrall, 5, horde, 0, "normal")
endfunction
```

### 2. Hero Level 1-4 (Requirements Not Met)
```
Hero Level: 3
Reputation: Horde Unfriendly (-1000)

Every 5 seconds, QuestEvaluationSystem checks:
✗ Level 3 < 5 (Required) → FAIL

Result: Gray Exclamation Mark displayed on Thrall
        "Quest available but you don't meet requirements"
```

### 3. Hero Reaches Level 5 (Requirements Met)
```
Hero Level: 5
Reputation: Horde Neutral (500)

Every 5 seconds, QuestEvaluationSystem checks:
✓ Level 5 >= 5 (Required) → PASS
✓ Reputation 500 >= 0 (Required) → PASS

Result: Yellow Exclamation Mark displayed on Thrall
        "Quest available - talk to Thrall to accept!"
```

### 4. Player Talks to Thrall and Accepts Quest
```jass
function QuestDialog_Accept_Actions takes nothing returns nothing
    local integer questID = 100
    local unit npc = udg_Thrall
    
    // Tell evaluation system: stop showing availability icon
    call QuestEval_MarkQuestActive(questID)
    
    // Tell icon system: show "in progress" icon
    call QuestIcon_RegisterQuest(npc, questID, "normal", 3)
    call QuestIcon_UpdateForNPC(npc)
    
    // Your quest setup code...
    set udg_Quest100_Active = true
    set udg_Quest100_Objectives = 0
endfunction
```
```
Result: Gray Question Mark displayed on Thrall
        "Quest in progress"
        
Evaluation system no longer checks this quest (QuestIsActive = true)
```

### 5. Player Completes Quest Objectives
```jass
function Quest100_KillCount_Actions takes nothing returns nothing
    set udg_Quest100_Objectives = udg_Quest100_Objectives + 1
    
    if udg_Quest100_Objectives >= 10 then
        // Quest complete - ready to turn in
        call QuestIcon_RegisterQuest(udg_Thrall, 100, "normal", 5)
        call QuestIcon_UpdateForNPC(udg_Thrall)
        
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 8.0, 
            "|cff00ff00Quest Complete!|r Return to Thrall")
    endif
endfunction
```
```
Result: Yellow Question Mark displayed on Thrall
        "Quest ready to turn in!"
```

### 6. Player Turns In Quest
```jass
function Quest100_TurnIn_Actions takes nothing returns nothing
    local integer questID = 100
    
    // Give rewards
    call AddHeroXP(udg_Nazgrek, 500, true)
    call Reputation.addRaw(Player(0), Faction.getFaction("Horde"), 250)
    
    // Tell evaluation system: quest is complete, check availability again
    call QuestEval_MarkQuestInactive(questID)
    
    // Remove icon
    call QuestIcon_RemoveQuest(udg_Thrall, questID)
    call QuestIcon_UpdateForNPC(udg_Thrall)
    
    // Clean up
    set udg_Quest100_Active = false
    set udg_Quest100_Objectives = 0
endfunction
```
```
Result: No icon on Thrall (quest complete)

Evaluation system resumes checking:
- For normal quests: won't show again (one-time quest)
- For daily/repeatable: would show again after reset
```

## Integration Checklist

### Initial Setup
- [x] QuestIconSystem.j added to map
- [x] QuestEvaluationSystem.j added to map
- [x] Reputation.j configured
- [ ] Set PlayerHero variable in QuestEvaluationSystem Init
- [ ] Configure quest givers in ConfigureQuestGivers()
- [ ] Configure quest requirements in ConfigureQuestRequirements()

### For Each Quest
- [ ] Add quest to ConfigureQuestRequirements()
- [ ] Create quest acceptance trigger
  - [ ] Call `QuestEval_MarkQuestActive(questID)`
  - [ ] Call `QuestIcon_RegisterQuest(npc, questID, type, 3)`
- [ ] Create quest update trigger (for objectives)
  - [ ] Update icon to state 5 when ready to turn in
- [ ] Create quest turn-in trigger
  - [ ] Call `QuestEval_MarkQuestInactive(questID)`
  - [ ] Call `QuestIcon_RemoveQuest(npc, questID)`
- [ ] Test with different hero levels and reputation values

### Optional Enhancements
- [ ] Add custom conditions for complex quests
- [ ] Hook QuestEval_ForceUpdate() into level-up events
- [ ] Hook QuestEval_ForceUpdate() into reputation changes
- [ ] Implement quest event flags system

## Code Integration Points

### Your Map Initialization
```jass
// QuestEvaluationSystem initializes automatically
// Just make sure it's loaded after QuestIconSystem and Reputation
```

### Hero Level-Up Event
```jass
function LevelUpEvent takes nothing returns nothing
    // Existing level-up code...
    
    // Check for newly available quests
    call QuestEval_ForceUpdate()
endfunction
```

### Reputation Change Events
```jass
// In Reputation.j addRaw method, or manually after changes:
function AfterReputationChange takes nothing returns nothing
    call QuestEval_ForceUpdate()
endfunction
```

## File Organization

```
Your Map/
├── QuestIconSystem.j                    (Icon display system)
├── QuestEvaluationSystem.j              (Quest availability checker)
├── QuestEvaluationSystem_Guide.md       (Full documentation)
├── QuestEvaluationSystem_Examples.j     (Code examples)
├── QuestEvaluationSystem_QuickRef.md    (Quick reference)
├── Reputation.j                         (Required dependency)
└── Your Quest Triggers/
    ├── Quest_001_Accept.j
    ├── Quest_001_Update.j
    ├── Quest_001_TurnIn.j
    ├── Quest_002_Accept.j
    └── ... etc
```

## Best Practices

### DO:
✅ Use QuestEvaluationSystem for states 1 (unavailable) and 2 (available)
✅ Call `QuestEval_MarkQuestActive()` when player accepts quest
✅ Use your quest triggers for states 3 (in progress) and 5 (ready to turn in)
✅ Call `QuestEval_MarkQuestInactive()` when quest is turned in
✅ Use `QuestEval_ForceUpdate()` after level-ups or reputation changes
✅ Configure all requirements in one place (ConfigureQuestRequirements)

### DON'T:
❌ Manually register state 2 quests with QuestIconSystem (evaluation handles this)
❌ Forget to mark quest as active when player accepts it
❌ Register the same quest in both systems simultaneously
❌ Modify quest requirements at runtime (configure at initialization)
❌ Use evaluation system for quest progress tracking (that's your triggers' job)

## Debugging Tips

### Quest Not Showing?
1. Check debug message at initialization: "X quests configured for Y quest givers"
2. Verify NPC is registered: `QuestEval_RegisterGiver(npc)`
3. Verify quest requirements: `AddQuestRequirement(...)`
4. Check hero level: `call BJDebugMsg("Level: " + I2S(GetHeroLevel(udg_Nazgrek)))`
5. Check reputation: `call BJDebugMsg("Rep: " + I2S(Reputation.getRep(Player(0), faction)))`

### Duplicate Icons?
- Quest is registered in both systems - make sure to call `QuestEval_MarkQuestActive()`

### Icon Stuck?
- Quest is still marked as active - call `QuestEval_MarkQuestInactive()`
- Force update: `call QuestEval_ForceUpdate()`

### Wrong Icon Color?
- Check quest type parameter: "normal" (yellow), "daily" (blue), "repeatable" (blue), "dungeon" (yellow)

## Performance Considerations

- **Evaluation Interval**: 5 seconds (configurable)
- **Quest Limit**: 500 quests max (configurable)
- **Quest Giver Limit**: 100 NPCs max (configurable)
- **CPU Impact**: Minimal - simple checks every 5 seconds
- **Optimization**: System skips active quests (reduces checks)

## Future Extension Ideas

1. **Time-based quests**: Only available at certain times of day
2. **Class restrictions**: Different quests for different hero types
3. **Completed quest tracking**: Quest chains requiring previous completion
4. **Party size requirements**: Multiplayer quest requirements
5. **Item requirements**: Must have specific item to unlock quest
6. **Zone-based availability**: Quests appear only in certain regions

## Quick API Summary

| Function | When to Use |
|----------|-------------|
| `QuestEval_RegisterGiver(unit)` | Setup - register quest giver NPCs |
| `QuestEval_MarkQuestActive(id)` | When player accepts quest |
| `QuestEval_MarkQuestInactive(id)` | When quest is turned in/abandoned |
| `QuestEval_ForceUpdate()` | After level-up or reputation change |
| `QuestIcon_RegisterQuest(...)` | Update quest icon state manually |
| `QuestIcon_RemoveQuest(...)` | Remove icon from NPC |
| `QuestIcon_UpdateForNPC(unit)` | Refresh NPC's displayed icon |

## Support & Help

For detailed information:
- **Full Guide**: `QuestEvaluationSystem_Guide.md`
- **Code Examples**: `QuestEvaluationSystem_Examples.j`
- **Quick Reference**: `QuestEvaluationSystem_QuickRef.md`
- **This Document**: `Quest_System_Integration_Summary.md`

For QuestIconSystem documentation:
- See header comments in `QuestIconSystem.j`

---

**System Version**: QuestEvaluationSystem 1.0 + QuestIconSystem 1.1
**Author**: Valdemar
**Date**: 2025
