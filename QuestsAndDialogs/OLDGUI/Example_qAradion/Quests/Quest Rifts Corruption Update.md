Quest Rifts Corruption Update
    Events
    Conditions
    Actions
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestRiftsCorruption
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        Set VariableSet QuestRiftsCorruptionCounter = (QuestRiftsCorruptionCounter + 1)
        Quest - Change the description of QuestRiftsCorruptionReq1 to (Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed  + ((String(QuestRiftsCorruptionCounter)) +  / 3)))
        Quest - Display to (All players) the Quest Update message: |cffffcc00QUEST UPD...
        Quest - Display to (All players) the Quest Update message: (- Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed  + ((String(QuestRiftsCorruptionCounter)) +  / 3)))
        Quest - Flash the quest dialog button
        -------- ======= ================================= ========================== --------
        -------- REFRESH QUEST ICON --------
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = 3
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], udg_QuestID_Temp, udg_QuestType[udg_QuestID_Temp], udg_QuestState[udg_QuestID_Temp] )
        -------- ================================ --------
