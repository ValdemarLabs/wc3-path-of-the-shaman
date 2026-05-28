Quest Crystals Hope Discover
    Events
    Conditions
    Actions
        -------- Ensure that the quest exists --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Crystals_Hope_Create)
        -------- Update the quest --------
        Quest - Mark QuestCrystalsHope as Discovered
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestCrystalsHope
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- Display a quest message. --------
        Trigger - Run Quest System Discover <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
