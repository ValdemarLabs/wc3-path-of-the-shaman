Quest System Load Hashtable
    Events
    Conditions
    Actions
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Custom script:   set udg_QuestID_Temp = LoadInteger(udg_QuestData, GetHandleId(udg_QuestTemp), 0)
        Custom script:   set udg_QuestType[udg_QuestID_Temp] = LoadStr(udg_QuestData, GetHandleId(udg_QuestTemp), 1)
        Custom script:   set udg_QuestGiverUnit[udg_QuestID_Temp] = LoadUnitHandle(udg_QuestData, GetHandleId(udg_QuestTemp), 2)
        Custom script:   set udg_QuestState[udg_QuestID_Temp] = LoadInteger(udg_QuestData, GetHandleId(udg_QuestTemp), 3)
        -------- ======= ================================= ========================== --------
