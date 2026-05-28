Quest Ranger Missing Update
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
        Quest - Mark QuestRangerMissingReq1 as Completed
        Quest - Create a quest requirement for QuestRangerMissing with the description Escort Valeria to A...
        Set VariableSet QuestRangerMissingReq2 = (Last created quest requirement)
        Quest - Display to (All players) the Quest Update message: |cffffcc00QUEST UPD...
        Quest - Display to (All players) the Quest Update message: - Escort Valeria to...
        Quest - Flash the quest dialog button
        -------- ======= ================================= ========================== --------
        -------- REFRESH QUEST ICON --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = 5
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], udg_QuestID_Temp, udg_QuestType[udg_QuestID_Temp], udg_QuestState[udg_QuestID_Temp] )
