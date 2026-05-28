# QuestEvaluationSystem - Visual Flow Diagrams

## System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                         GAME WORLD                                 │
│                                                                    │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐      │
│  │   Hero   │   │   NPC    │   │   NPC    │   │   NPC    │      │
│  │ (Nazgrek)│   │ (Thrall) │   │ (Jaina)  │   │ (Cairne) │      │
│  │  Lv: 5   │   │    🔸    │   │    🔸    │   │    🔸    │      │
│  │ Rep: +500│   │Quest Icon│   │Quest Icon│   │Quest Icon│      │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘      │
│       │              │              │              │             │
└───────┼──────────────┼──────────────┼──────────────┼─────────────┘
        │              │              │              │
        │              └──────────┬───┴──────────────┘
        │                         │
        │                         ↓
┌───────┼─────────────────────────────────────────────────────────┐
│       │            QUEST ICON SYSTEM                            │
│       │    • Displays overhead quest icons                      │
│       │    • Shows minimap pings                                │
│       │    • Updates based on state/type                        │
│       │                                                         │
│       │    call QuestIcon_RegisterQuest(npc, id, type, state)  │
│       │    call QuestIcon_UpdateForNPC(npc)                    │
└───────┼─────────────────────────────────────────────────────────┘
        │                         ↑
        │                         │ QuestIcon API calls
        │                         │
┌───────┼─────────────────────────┴───────────────────────────────┐
│       │       QUEST EVALUATION SYSTEM (Every 5 sec)             │
│       │                                                         │
│       │   ┌─────────────────────────────────────────────┐      │
│       └──→│ Check Hero Level                            │      │
│           │ Check Reputation (Reputation.getRep)        │      │
│           │ Check Event Flags                           │      │
│           │ Check Custom Conditions                     │      │
│           └─────────────────┬───────────────────────────┘      │
│                             │                                   │
│                             ↓                                   │
│           ┌─────────────────────────────────────────┐          │
│           │ Requirements Met?                       │          │
│           └─────┬─────────────────────┬─────────────┘          │
│                 │ YES                 │ NO                     │
│                 ↓                     ↓                        │
│          State 2 (Available)    State 1 (Unavailable)         │
│          Yellow/Blue !          Gray !                        │
└───────────────────────────────────────────────────────────────┘
                                │
                                ↓
                    ┌───────────────────────┐
                    │  REPUTATION SYSTEM    │
                    │  • Faction relations  │
                    │  • Reputation values  │
                    └───────────────────────┘
```

## Quest State Transition Diagram

```
                    ┌─────────────────────────────────────┐
                    │  Quest Configured in System         │
                    │  AddQuestRequirement(...)           │
                    └──────────────┬──────────────────────┘
                                   │
                                   ↓
    ┌──────────────────────────────────────────────────────────┐
    │           EVALUATION SYSTEM MANAGES                      │
    │                                                          │
    │  ┌────────────────┐              ┌─────────────────┐   │
    │  │   STATE 1      │              │    STATE 2      │   │
    │  │  UNAVAILABLE   │◄────────────►│   AVAILABLE     │   │
    │  │   Gray !       │ Requirements │   Yellow/Blue ! │   │
    │  │                │  Met/Not Met │                 │   │
    │  └────────────────┘              └────────┬────────┘   │
    │         ↑                                  │            │
    │         │                                  │            │
    │         │                                  ↓            │
    │         │                    Player Talks to NPC       │
    │         │                    Accepts Quest             │
    │         │                    ↓                         │
    │         │        call QuestEval_MarkQuestActive(id)   │
    └─────────┼──────────────────────────────────────────────┘
              │                    │
              │                    ↓
    ┌─────────┼──────────────────────────────────────────────┐
    │         │       YOUR QUEST TRIGGERS MANAGE             │
    │         │                                              │
    │         │         ┌──────────────────┐                │
    │         │         │    STATE 3       │                │
    │         │         │  IN PROGRESS     │                │
    │         │         │   Gray ?         │                │
    │         │         └────────┬─────────┘                │
    │         │                  │                          │
    │         │                  │ Objectives Complete      │
    │         │                  ↓                          │
    │         │         ┌──────────────────┐                │
    │         │         │    STATE 5       │                │
    │         │         │ READY TO TURN IN │                │
    │         │         │  Yellow/Blue ?   │                │
    │         │         └────────┬─────────┘                │
    │         │                  │                          │
    │         │                  │ Player Turns In          │
    │         │                  ↓                          │
    │         │       call QuestEval_MarkQuestInactive(id)  │
    │         │       call QuestIcon_RemoveQuest(npc, id)   │
    └─────────┼──────────────────────────────────────────────┘
              │                  │
              │                  ↓
              │         ┌────────────────┐
              │         │   STATE 4      │
              │         │   COMPLETE     │
              │         │   No Icon      │
              │         └────────┬───────┘
              │                  │
              │                  │ For Dailies/Repeatables
              └──────────────────┘ After Reset
                   Loop Back
```

## Icon Color Decision Tree

```
Quest Registered
    │
    ├─→ State 1 (Unavailable)
    │       └─→ GRAY EXCLAMATION (!)
    │
    ├─→ State 2 (Available)
    │       │
    │       ├─→ Type: "normal" or "dungeon"
    │       │       └─→ YELLOW EXCLAMATION (!)
    │       │
    │       └─→ Type: "daily" or "repeatable"
    │               └─→ BLUE EXCLAMATION (!)
    │
    ├─→ State 3 (In Progress)
    │       └─→ GRAY QUESTION (?)
    │
    ├─→ State 5 (Ready to Turn In)
    │       │
    │       ├─→ Type: "normal" or "dungeon"
    │       │       └─→ YELLOW QUESTION (?)
    │       │
    │       └─→ Type: "daily" or "repeatable"
    │               └─→ BLUE QUESTION (?)
    │
    └─→ State 4 (Complete)
            └─→ NO ICON
```

## Evaluation Cycle Timeline

```
Time: 0s ──────→ 5s ──────→ 10s ─────→ 15s ─────→ ...
       │         │          │          │
       ↓         ↓          ↓          ↓
    [Evaluate] [Evaluate] [Evaluate] [Evaluate]
       │         │          │          │
       ├─ NPC 1  ├─ NPC 1   ├─ NPC 1   ├─ NPC 1
       │  └Quest 1  └Quest 1  └Quest 1  └Quest 1
       │  └Quest 2  └Quest 2  └Quest 2  └Quest 2
       │                                        
       ├─ NPC 2  ├─ NPC 2   ├─ NPC 2   ├─ NPC 2
       │  └Quest 3  └Quest 3  └Quest 3  └Quest 3
       │                                        
       └─ NPC 3  └─ NPC 3   └─ NPC 3   └─ NPC 3
          └Quest 4  └Quest 4  └Quest 4  └Quest 4

For each quest:
    ✓ Check level requirement
    ✓ Check reputation requirement
    ✓ Check if quest is active (skip if yes)
    ✓ Check custom conditions
    ↓
    Update icon state (1 or 2)
    ↓
    Call QuestIcon_RegisterQuest()
    ↓
    Call QuestIcon_UpdateForNPC()
```

## Level Progression Example

```
Hero Level 1
    │
    ├─→ Quest 1 (Req: Lv 1) → Available ✓ → Yellow !
    ├─→ Quest 2 (Req: Lv 3) → Unavailable ✗ → Gray !
    ├─→ Quest 3 (Req: Lv 5) → Unavailable ✗ → Gray !
    └─→ Quest 4 (Req: Lv 10) → Unavailable ✗ → Gray !

Hero Levels Up to 3
    │
    ├─→ Quest 1 (Req: Lv 1) → Available ✓ → Yellow !
    ├─→ Quest 2 (Req: Lv 3) → Available ✓ → Yellow !
    ├─→ Quest 3 (Req: Lv 5) → Unavailable ✗ → Gray !
    └─→ Quest 4 (Req: Lv 10) → Unavailable ✗ → Gray !

Hero Levels Up to 5
    │
    ├─→ Quest 1 (Req: Lv 1) → Available ✓ → Yellow !
    ├─→ Quest 2 (Req: Lv 3) → Available ✓ → Yellow !
    ├─→ Quest 3 (Req: Lv 5) → Available ✓ → Yellow !
    └─→ Quest 4 (Req: Lv 10) → Unavailable ✗ → Gray !

[System evaluates every 5 seconds and updates icons automatically]
```

## Reputation Progression Example

```
Reputation: -1000 (Unfriendly)
    │
    ├─→ Quest A (Req: Neutral 0)    → Unavailable ✗ → Gray !
    ├─→ Quest B (Req: Friendly 3000) → Unavailable ✗ → Gray !
    └─→ Quest C (Req: Covenant 6000) → Unavailable ✗ → Gray !

Complete quests, gain +2000 rep → Now: +1000 (Neutral)
    │
    ├─→ Quest A (Req: Neutral 0)    → Available ✓ → Yellow !
    ├─→ Quest B (Req: Friendly 3000) → Unavailable ✗ → Gray !
    └─→ Quest C (Req: Covenant 6000) → Unavailable ✗ → Gray !

Complete more quests, gain +3000 rep → Now: +4000 (Friendly)
    │
    ├─→ Quest A (Req: Neutral 0)    → Available ✓ → Yellow !
    ├─→ Quest B (Req: Friendly 3000) → Available ✓ → Yellow !
    └─→ Quest C (Req: Covenant 6000) → Unavailable ✗ → Gray !

[System evaluates every 5 seconds and updates icons automatically]
```

## Multi-NPC Icon Priority Example

```
NPC has 3 quests registered:

Quest 1: State 1 (Unavailable, Gray !)
Quest 2: State 2 (Available, Yellow !)
Quest 3: State 3 (In Progress, Gray ?)

Priority System (highest shown):
    5. State 5 (Ready to turn in)     ← Highest
    4. State 2 (Available)
    3. State 3 (In Progress)
    2. State 1 (Unavailable)
    1. State 4 (Complete/No quests)   ← Lowest

Within same state:
    Normal/Dungeon > Daily/Repeatable

Result: Shows Quest 2 icon (Yellow !)
```

## Player Journey Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. QUEST APPEARS                                                │
│    Hero reaches level/reputation requirement                   │
│    System detects in next evaluation cycle (within 5 sec)      │
│    Icon changes: Gray ! → Yellow/Blue !                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. PLAYER INTERACTION                                           │
│    Player clicks NPC, dialogue opens                            │
│    Player selects "Accept Quest"                                │
│    Trigger executes: QuestEval_MarkQuestActive(questID)        │
│    Trigger executes: QuestIcon_RegisterQuest(..., state 3)     │
│    Icon changes: Yellow/Blue ! → Gray ?                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. QUEST PROGRESS                                               │
│    Player completes objectives                                  │
│    Trigger detects completion                                   │
│    Trigger executes: QuestIcon_RegisterQuest(..., state 5)     │
│    Icon changes: Gray ? → Yellow/Blue ?                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. QUEST COMPLETION                                             │
│    Player returns to NPC, turns in quest                        │
│    Trigger gives rewards                                        │
│    Trigger executes: QuestEval_MarkQuestInactive(questID)      │
│    Trigger executes: QuestIcon_RemoveQuest(npc, questID)       │
│    Icon changes: Yellow/Blue ? → (removed)                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. NEXT QUEST CHECK                                             │
│    System evaluates NPC again in next cycle                     │
│    If more quests available → Shows new icon                    │
│    If no quests available → No icon                             │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
ConfigureQuestRequirements()
    │
    ├─→ AddQuestRequirement(id=1, npc=Thrall, level=5, ...)
    ├─→ AddQuestRequirement(id=2, npc=Thrall, level=10, ...)
    └─→ AddQuestRequirement(id=3, npc=Jaina, level=7, ...)
            │
            ↓
    [Quest Data Stored in Arrays]
        QuestIDs[]
        QuestNPC[]
        QuestMinLevel[]
        QuestRequiredFaction[]
        QuestMinReputation[]
        QuestType[]
        QuestIsActive[]
            │
            ↓
    [Timer Triggers Every 5 Seconds]
            │
            ↓
    For each quest:
        GetQuestIndex(questID)
        CheckQuestRequirements(index)
            │
            ├─→ Get Hero Level
            ├─→ Get Reputation (via Reputation.getRep)
            ├─→ Check Event Flags
            └─→ Evaluate Custom Conditions
                │
                ↓
        Requirements Met? → State 2 (Available)
        Requirements Not Met? → State 1 (Unavailable)
                │
                ↓
        QuestIcon_RegisterQuest(npc, id, type, state)
                │
                ↓
        QuestIcon_UpdateForNPC(npc)
                │
                ↓
        [Icon Displayed on NPC]
```

## Error Prevention Flow

```
Common Mistake: Duplicate Icons
    │
    ├─→ Problem: Quest shows two icons (! and ?)
    │
    └─→ Cause: Both systems trying to manage same quest
            │
            └─→ Solution:
                ├─→ EvaluationSystem manages States 1 & 2
                ├─→ Quest Triggers manage States 3 & 5
                └─→ Call QuestEval_MarkQuestActive() on accept

Common Mistake: Icon Not Updating
    │
    ├─→ Problem: Icon stuck as gray ! when should be yellow !
    │
    └─→ Causes:
            ├─→ PlayerHero not set correctly
            ├─→ Requirements not actually met
            └─→ Waiting for next 5-second cycle
                    │
                    └─→ Solution: call QuestEval_ForceUpdate()

Common Mistake: Quest Never Appears
    │
    ├─→ Problem: No icon shows up at all
    │
    └─→ Checklist:
            ├─→ [ ] NPC registered with QuestEval_RegisterGiver()?
            ├─→ [ ] Quest configured with AddQuestRequirement()?
            ├─→ [ ] Quest models exist in map?
            └─→ [ ] Check initialization debug message
```

## System Integration Map

```
┌──────────────────────────────────────────────────────────────┐
│                    YOUR MAP TRIGGERS                         │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │Quest Accept│  │Quest Update│  │Quest TurnIn│           │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘           │
└────────┼───────────────┼───────────────┼───────────────────┘
         │               │               │
         │               │               │
    MarkActive()    UpdateIcon()    MarkInactive()
         │               │               │
         ↓               ↓               ↓
┌──────────────────────────────────────────────────────────────┐
│              QUEST EVALUATION SYSTEM                         │
│  • Checks requirements every 5 seconds                       │
│  • Manages quest availability (States 1 & 2)                 │
│  • Interfaces with Reputation system                         │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ↓ QuestIcon API
┌──────────────────────────────────────────────────────────────┐
│              QUEST ICON SYSTEM                               │
│  • Displays overhead effects                                │
│  • Shows minimap pings                                       │
│  • Manages icon priority                                     │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ↓
┌──────────────────────────────────────────────────────────────┐
│              REPUTATION SYSTEM                               │
│  • Tracks faction relationships                             │
│  • Provides reputation values                               │
│  • Updates based on player actions                          │
└──────────────────────────────────────────────────────────────┘
```
