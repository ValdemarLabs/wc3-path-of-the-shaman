Quest Ranger Missing Failed
    Events
    Conditions
    Actions
        Trigger - Turn off (This trigger)
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestRangerMissing
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        Quest - Mark QuestRangerMissingReq1 as Incomplete
        Quest - Mark QuestRangerMissing as Failed
        Quest - Flash the quest dialog button
        Quest - Display to (All players) the Quest Failed message: |cffffcc00QUEST FAI...
        Quest - Display to (All players) the Quest Update message: - Valeria has died.
        -------- ======= ================================= ========================== --------
        -------- REFRESH QUEST ICON --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = 3
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], udg_QuestID_Temp, udg_QuestType[udg_QuestID_Temp], udg_QuestState[udg_QuestID_Temp] )
