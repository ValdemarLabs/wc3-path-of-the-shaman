Quest Fading Sparks Discover
    Events
    Conditions
    Actions
        -------- Ensure that the quest exists --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Fading_Sparks_Create)
        -------- Update the quest --------
        Quest - Mark QuestFadingSparks as Discovered
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestFadingSparks
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- Display a quest message. --------
        Trigger - Run Quest System Discover <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
