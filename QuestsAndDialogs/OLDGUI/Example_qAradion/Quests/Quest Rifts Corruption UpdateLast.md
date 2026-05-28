Quest Rifts Corruption UpdateLast
    Events
    Conditions
    Actions
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestRiftsCorruption
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        Quest - Mark QuestRiftsCorruptionReq1 as Completed
        Quest - Mark QuestRiftsCorruptionReq2 as Completed
        Quest - Create a quest requirement for QuestRiftsCorruption with the description Escort both Aradion...
        Set VariableSet QuestRiftsCorruptionReq4 = (Last created quest requirement)
        Quest - Display to (All players) the Quest Update message: |cffffcc00QUEST UPD...
        Quest - Display to (All players) the Quest Update message: - Escort both Aradi...
        Quest - Flash the quest dialog button
        -------- ======= ================================= ========================== --------
        -------- REFRESH QUEST ICON --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = 3
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], udg_QuestID_Temp, udg_QuestType[udg_QuestID_Temp], udg_QuestState[udg_QuestID_Temp] )
        -------- ================================ --------
