WithinRange Register Mana Rift
    Events
    Conditions
    Actions
        -------- RIFT 1 --------
        Set VariableSet WithinRangeRange = 900.00
        Set VariableSet WithinRangeUnit = QuestRifts[1]
        -------- Use Event wanted = 0 to not throw Events. --------
        Set VariableSet WithinRangeWanted_Event = 1.00
        Set VariableSet WithinRangeWanted_Filter = (((Triggering unit) is A structure) Equal to False)
        Trigger - Run WithinRange <gen> (ignoring conditions)
        -------- RIFT 2 --------
        Set VariableSet WithinRangeRange = 900.00
        Set VariableSet WithinRangeUnit = QuestRifts[2]
        -------- Use Event wanted = 0 to not throw Events. --------
        Set VariableSet WithinRangeWanted_Event = 1.00
        Set VariableSet WithinRangeWanted_Filter = (((Triggering unit) is A structure) Equal to False)
        Trigger - Run WithinRange <gen> (ignoring conditions)
        -------- RIFT 3 --------
        Set VariableSet WithinRangeRange = 900.00
        Set VariableSet WithinRangeUnit = QuestRifts[3]
        -------- Use Event wanted = 0 to not throw Events. --------
        Set VariableSet WithinRangeWanted_Event = 1.00
        Set VariableSet WithinRangeWanted_Filter = (((Triggering unit) is A structure) Equal to False)
        Trigger - Run WithinRange <gen> (ignoring conditions)
