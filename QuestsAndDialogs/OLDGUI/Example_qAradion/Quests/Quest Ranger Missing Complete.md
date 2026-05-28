Quest Ranger Missing Complete
    Events
    Conditions
    Actions
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestRangerMissing
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- ======= REWARDS --------
        Trigger - Run Quest System Complete Rewards <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- Ensure that the quest exists --------
        Custom script:   call ConditionalTriggerExecute(gg_trg_Quest_Ranger_Missing_Create)
        -------- Update the quest --------
        Quest - Mark QuestRangerMissing as Discovered
        Quest - Mark QuestRangerMissingReq1 as Completed
        Quest - Mark QuestRangerMissingReq2 as Completed
        Quest - Mark QuestRangerMissing as Completed
        -------- Display a quest message. --------
        Trigger - Run Quest System Complete <gen> (ignoring conditions)
        -------- REFRESH QUEST ICON --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = 4
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], udg_QuestID_Temp, udg_QuestType[udg_QuestID_Temp], udg_QuestState[udg_QuestID_Temp] )
        Wait 2.00 seconds
        -------- ======= QUEST ICON STATUS --------
        -------- ======= QUEST TYPE: normal, daily, repeatable, dungeon  --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Set VariableSet QuestGiverUnitTemp = Aradion
        Custom script:   call CreateDummyQuestIcon(udg_QuestGiverUnitTemp, "normal", 2)
        -------- ======= ================================= ========================== --------
        -------- ======= QUEST ICON STATUS --------
        -------- ======= QUEST TYPE: normal, daily, repeatable, dungeon  --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Set VariableSet QuestGiverUnitTemp = Valeria
        Custom script:   call CreateDummyQuestIcon(udg_QuestGiverUnitTemp, "normal", 2)
        -------- ======= ================================= ========================== --------
