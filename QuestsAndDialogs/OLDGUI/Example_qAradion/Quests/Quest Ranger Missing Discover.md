Quest Ranger Missing Discover
    Events
    Conditions
    Actions
        -------- Ensure that the quest exists --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Ranger_Missing_Create)
        -------- Update the quest --------
        Quest - Mark QuestRangerMissing as Discovered
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestRangerMissing
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- Display a quest message. --------
        Trigger - Run Quest System Discover <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
