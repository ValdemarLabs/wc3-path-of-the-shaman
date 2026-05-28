# QuestEvaluationSystem 2.0 - Fully Automatic

## 🎯 Zero Setup Required!

This system is **FULLY AUTOMATIC**. You configure your quests once, and the system handles everything.

**NO function calls needed from your quest triggers!**

---

## ⚡ Quick Start (3 Steps)

### 1. Open `QuestEvaluationSystem.j`

### 2. Find `ConfigureQuestRequirements()` function

### 3. Add your quests:

```jass
call AddQuest(1, udg_Thrall, 5, Faction.getFaction("Horde"), 3000, "normal")
```

**That's it!** The system automatically:
- ✅ Evaluates quest requirements every 5 seconds
- ✅ Shows gray ! when requirements not met
- ✅ Shows yellow/blue ! when available
- ✅ Respects QuestIconSystem's active quests (doesn't override states 3 & 5)
- ✅ Updates when hero levels up or reputation changes

---

## 📝 Configuration Format

```jass
call AddQuest(questID, npcUnit, minLevel, faction, minRep, "questType")
```

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `questID` | integer | Unique quest ID | `1` |
| `npcUnit` | unit | NPC variable | `udg_Thrall` |
| `minLevel` | integer | Min hero level (0=none) | `5` |
| `faction` | Faction | Faction or null | `Faction.getFaction("Horde")` |
| `minRep` | integer | Min reputation | `3000` |
| `questType` | string | Quest type | `"normal"` |

---

## 🎨 Quest Types

| Type | Icon Color | Use For |
|------|------------|---------|
| `"normal"` | Yellow | One-time quests |
| `"daily"` | Blue | Daily quests |
| `"repeatable"` | Blue | Repeatable quests |
| `"dungeon"` | Yellow | Dungeon quests |

---

## 📊 Reputation Values

| Tier | Value | Description |
|------|-------|-------------|
| ENEMY | `-20000` | Hated |
| HOSTILE | `-12000` | Attacked on sight |
| UNFRIENDLY | `-3000` | Wary |
| NEUTRAL | `0` | Basic access |
| FRIENDLY | `3000` | Welcomed |
| COVENANT | `6000` | Trusted |
| EXALTED | `12000` | Revered |

---

## 💡 Complete Examples

### Example 1: Simple Level Quest
```jass
// Quest 1: Available at level 1, no other requirements
call AddQuest(1, udg_Thrall, 1, null, 0, "normal")
```

### Example 2: Reputation Quest
```jass
// Quest 2: Level 5 + Horde Friendly required
local Faction horde = Faction.getFaction("Horde")
call AddQuest(2, udg_Thrall, 5, horde, 3000, "normal")
```

### Example 3: Daily Quest
```jass
// Quest 50: Level 10 daily quest
call AddQuest(50, udg_Jaina, 10, null, 0, "daily")
```

### Example 4: High-Level Dungeon
```jass
// Quest 100: Level 15 + Alliance Covenant
local Faction alliance = Faction.getFaction("Alliance")
call AddQuest(100, udg_DungeonNPC, 15, alliance, 6000, "dungeon")
```

### Example 5: Multiple Quests Same NPC
```jass
// Thrall has 3 quests at different levels
call AddQuest(1, udg_Thrall, 1, null, 0, "normal")
call AddQuest(2, udg_Thrall, 5, horde, 0, "normal")
call AddQuest(3, udg_Thrall, 10, horde, 3000, "normal")
```

---

## 🔧 Advanced: Custom Conditions

For complex requirements (e.g., must defeat a boss first):

**Step 1:** Define condition function (above ConfigureQuestRequirements):

```jass
function Quest10_MustDefeatBoss takes nothing returns boolean
    return udg_BossDefeated == true and udg_PlayerHasRelic == true
endfunction
```

**Step 2:** In ConfigureQuestRequirements:

```jass
local trigger customCond = CreateTrigger()
call TriggerAddCondition(customCond, Condition(function Quest10_MustDefeatBoss))
call AddQuest(10, udg_SpecialNPC, 10, horde, 3000, "normal")
call AddQuestCondition(customCond) // Applies to last added quest
```

---

## 🔄 How It Works With QuestIconSystem

### Automatic Cooperation

| State | Managed By | Icon | Description |
|-------|------------|------|-------------|
| **1** | QuestEvaluationSystem | Gray ! | Requirements not met |
| **2** | QuestEvaluationSystem | Yellow/Blue ! | Available |
| **3** | **QuestIconSystem** | Gray ? | In progress (system skips) |
| **5** | **QuestIconSystem** | Yellow/Blue ? | Ready to turn in (system skips) |
| **4** | Either | None | Complete |

**The systems work together automatically!**

When you register a quest with QuestIconSystem in state 3 or 5, the evaluation system **respects it** and doesn't override.

---

## 📋 Full Configuration Template

```jass
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    local Faction alliance = Faction.getFaction("Alliance")
    
    // ===== HORDE QUEST LINE =====
    call AddQuest(1, udg_Thrall, 1, null, 0, "normal")
    call AddQuest(2, udg_Thrall, 3, horde, 0, "normal")
    call AddQuest(3, udg_Thrall, 5, horde, 3000, "normal")
    call AddQuest(4, udg_Cairne, 10, horde, 6000, "normal")
    
    // ===== ALLIANCE QUEST LINE =====
    call AddQuest(10, udg_Jaina, 1, null, 0, "normal")
    call AddQuest(11, udg_Jaina, 5, alliance, 0, "normal")
    call AddQuest(12, udg_Jaina, 10, alliance, 3000, "normal")
    
    // ===== DAILY QUESTS =====
    call AddQuest(50, udg_Vendor, 5, null, 0, "daily")
    call AddQuest(51, udg_InnKeeper, 7, null, 0, "daily")
    
    // ===== DUNGEON QUESTS =====
    call AddQuest(100, udg_DungeonEntrance, 15, horde, 6000, "dungeon")
    call AddQuest(101, udg_DungeonEntrance, 20, horde, 12000, "dungeon")
    
endfunction
```

---

## ❓ FAQ

### Do I need to call any functions from my quest triggers?
**No!** The system is fully automatic.

### What happens when player accepts a quest?
Your quest trigger registers it with QuestIconSystem in state 3 (in progress). The evaluation system automatically detects this and stops showing availability icons for that quest.

### What about when quest is complete?
Your quest trigger updates it to state 5 (ready to turn in) using QuestIconSystem. The evaluation system continues to respect this.

### What about after turning in?
Your quest trigger removes it from QuestIconSystem. The evaluation system will automatically check if requirements are still met (for dailies/repeatables) and show it again if appropriate.

### Can quests appear/disappear as hero levels up?
**Yes!** The system automatically checks every 5 seconds. When hero reaches required level, gray ! changes to yellow/blue ! automatically.

### What about reputation changes?
**Yes!** Same thing - when reputation increases, unavailable quests become available automatically.

### Do I need to register NPCs?
**No!** NPCs are automatically registered when you add quests for them.

### Can multiple NPCs have the same quest?
**No**, each quest ID can only be assigned to one NPC. Create separate quest IDs for different NPCs.

### Can one NPC have multiple quests?
**Yes!** Add multiple `AddQuest()` calls with the same NPC but different quest IDs.

---

## 🎮 In-Game Behavior

### Player Level 1
- Quest 1 (Level 1): Yellow ! (available)
- Quest 2 (Level 5): Gray ! (unavailable)
- Quest 3 (Level 10): Gray ! (unavailable)

### Player Levels to 5
- Quest 1: Still available (or completed)
- Quest 2 (Level 5): Automatically changes to Yellow ! (available)
- Quest 3 (Level 10): Still gray ! (unavailable)

### Player Gains Reputation
- Quests requiring reputation automatically unlock
- Icon automatically changes from Gray ! to Yellow/Blue !

### No Code Changes Needed!
Everything happens automatically ✨

---

## ⚠️ Important Notes

1. **Quest IDs must be unique** across your entire map
2. **Use same quest ID** in both this system and your quest triggers
3. **Hero variable** is `udg_Nazgrek` by default (change in Init function if needed)
4. **Evaluation runs every 5 seconds** (change `EVALUATION_INTERVAL` if needed)
5. **System respects QuestIconSystem** - won't override active quests
6. **Faction names must match** your Reputation system exactly

---

## 🚀 You're Done!

Configure your quests in `ConfigureQuestRequirements()`, save your map, and play!

The system handles everything automatically. No function calls, no manual updates, no hassle.

**Just configure once and forget about it!** 🎉
