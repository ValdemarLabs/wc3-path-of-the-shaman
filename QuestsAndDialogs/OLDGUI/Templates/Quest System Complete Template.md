Quest System Complete Template
    Events
    Conditions
    Actions
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestExplosiveCrisis
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- ======= REWARDS --------
        Trigger - Run Quest System Complete Rewards <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- Ensure that the quest exists --------
        Trigger - Run Quest Explosive Crisis Create <gen> (checking conditions)
        -------- Update the quest --------
        Quest - Mark QuestExplosiveCrisis as Discovered
        Quest - Mark QuestExplosiveCrisisReq1 as Completed
        Quest - Mark QuestExplosiveCrisis as Completed
        -------- Display a quest message. --------
        Trigger - Run Quest System Complete <gen> (ignoring conditions)
        -------- REFRESH QUEST ICON --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = 2
        Trigger - Run gg_trg_Quest_System_Icon_Refresh (ignoring conditions)
        -------- NEW QUEST AVAILABLE --------
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], 9999, "normal", udg_QuestState[udg_QuestID_Temp])
        -------- ======= ================================= ========================== --------
