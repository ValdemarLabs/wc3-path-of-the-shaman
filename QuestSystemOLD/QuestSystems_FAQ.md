// Complete Quest Lifecycle:
// This example demonstrates how a quest evaluation system
// interacts with a custom quest trigger system to manage (QuestIconSystem)
// the lifecycle of a quest.
┌─────────────────────────────────────────────────────────────┐
│ 1. NO QUEST ACCEPTED (Evaluation System Active)            │
├─────────────────────────────────────────────────────────────┤
│ NPC: Thrall                                                 │
│ Quest Slots:                                                │
│   • Dummy Quest ID 900000 (State 1 or 2)  ← QuestEvalSys  │
│                                                             │
│ NPCHasActiveQuests(Thrall) = FALSE                         │
│ Icon Shown: Gray ! or Yellow ! (dummy quest)               │
└─────────────────────────────────────────────────────────────┘
                           ↓
                  Player Accepts Quest
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. QUEST ACCEPTED (Quest Trigger Takes Over)               │
├─────────────────────────────────────────────────────────────┤
│ Your Trigger Actions:                                       │
│   call QuestIcon_RegisterQuest(Thrall, 1, "normal", 3)    │
│                                                             │
│ NPC: Thrall                                                 │
│ Quest Slots:                                                │
│   • Real Quest ID 1 (State 3)  ← Your Quest Trigger       │
│   • Dummy Quest ID 900000 REMOVED  ← QuestEvalSys         │
│                                                             │
│ NPCHasActiveQuests(Thrall) = TRUE (found state 3)          │
│ Icon Shown: Yellow ! (real quest in progress)              │
└─────────────────────────────────────────────────────────────┘
                           ↓
                  Player Completes Objectives
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. QUEST READY TO TURN IN                                  │
├─────────────────────────────────────────────────────────────┤
│ Your Trigger Actions:                                       │
│   call QuestIcon_RegisterQuest(Thrall, 1, "normal", 5)    │
│                                                             │
│ NPC: Thrall                                                 │
│ Quest Slots:                                                │
│   • Real Quest ID 1 (State 5)  ← Your Quest Trigger       │
│   • Dummy Quest ID 900000 still REMOVED                    │
│                                                             │
│ NPCHasActiveQuests(Thrall) = TRUE (found state 5)          │
│ Icon Shown: Yellow ? (ready to turn in)                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
                  Player Turns In Quest
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. QUEST COMPLETED (Evaluation System Resumes)             │
├─────────────────────────────────────────────────────────────┤
│ Your Trigger Actions:                                       │
│   call QuestIcon_RemoveQuest(Thrall, 1)                   │
│                                                             │
│ NPC: Thrall                                                 │
│ Quest Slots:                                                │
│   • Real Quest ID 1 REMOVED                                │
│   • After ~5 seconds: Dummy Quest reappears if configured  │
│                                                             │
│ NPCHasActiveQuests(Thrall) = FALSE                         │
│ Icon: None → then Dummy icon reappears (State 1 or 2)     │
└─────────────────────────────────────────────────────────────┘


Key Protection Mechanism:
// In QuestEvaluationSystem - NPCHasActiveQuests checks REAL quests
private function NPCHasActiveQuests takes unit npc returns boolean
    loop
        set existingState = LoadInteger(QUEST_ICON_TABLE, npcId, i*100 + QUEST_STATE_KEY)
        
        if existingState == 3 or existingState == 5 then
            return true // Found REAL active quest
        endif
    endloop
    return false
endfunction

// If active quests found - REMOVE all dummy quests
if hasActiveQuests then
    call QuestIcon_RemoveQuest(npc, dummyID)  // Remove dummy
endif


-------------
No Conflict Because:
Different Quest IDs:

Dummy: 900000-900499 (QuestEvaluationSystem)
Real: 1-899999 (Your quest triggers)
Automatic Coordination:

When real quest registered (state 3 or 5) → Dummy removed
When real quest removed → Dummy reappears next evaluation cycle
Shared Hashtable, Separate Slots:

Both write to QUEST_ICON_TABLE
Each quest ID gets its own slot in the array
NPC can have multiple quests simultaneously (but only shows highest priority)


Your Quest Trigger Workflow:
// ACCEPT QUEST
function Quest_Accept takes nothing returns nothing
    // Just register the real quest - QuestEvalSys automatically removes dummy
    call QuestIcon_RegisterQuest(udg_Thrall, 1, "normal", 3)
    // No need to manually remove dummy quest!
endfunction

// COMPLETE OBJECTIVES
function Quest_ObjectiveDone takes nothing returns nothing
    call QuestIcon_RegisterQuest(udg_Thrall, 1, "normal", 5)
endfunction

// TURN IN QUEST  
function Quest_TurnIn takes nothing returns nothing
    call QuestIcon_RemoveQuest(udg_Thrall, 1)
    // Dummy quest will reappear in ~5 seconds automatically
endfunction


======== 
They work in harmony - the evaluation system steps back when you register real quests, and automatically resumes showing availability when your quests are complete!

