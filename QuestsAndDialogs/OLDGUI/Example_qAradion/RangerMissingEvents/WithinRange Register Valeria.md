WithinRange Register Valeria
    Events
        Time - Elapsed game time is 5.00 seconds
    Conditions
    Actions
        -------- Autoregister on start --------
        Set VariableSet WithinRangeRange = 900.00
        Set VariableSet WithinRangeUnit = Valeria
        -------- Use Event wanted = 0 to not throw Events. --------
        Set VariableSet WithinRangeWanted_Event = 1.00
        Set VariableSet WithinRangeWanted_Filter = (((Triggering unit) is A structure) Equal to False)
        Trigger - Run WithinRange <gen> (ignoring conditions)
