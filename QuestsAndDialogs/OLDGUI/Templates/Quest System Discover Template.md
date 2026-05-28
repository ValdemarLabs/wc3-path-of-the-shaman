Quest System Discover Template
    Events
    Conditions
    Actions
        -------- Ensure that the quest exists --------
        Trigger - Run Quest Explosive Crisis Create <gen> (checking conditions)
        -------- Update the quest --------
        Quest - Mark QuestExplosiveCrisis as Discovered
        -------- ======= ================================= ========================== --------
        -------- ======= ADJUST WHICH QUEST --------
        Set VariableSet QuestTemp = QuestExplosiveCrisis
        -------- ======= DONT MODIFY: LOAD HASHTABLE --------
        Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
        -------- Display a quest message. --------
        Trigger - Run Quest System Discover <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
