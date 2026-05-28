Valeria Remove Companion
    Events
    Conditions
    Actions
        Set VariableSet CompanionUnitKicked = Valeria
        Unit - Order CompanionUnitKicked to Stop.
        Game - Display to (All players) the text: (Debug Kick:  + (Kicked from Companion_Group:  + (Proper name of CompanionUnitKicked)))
        Unit Group - Remove CompanionUnitKicked from Companion_Group.
        Unit Group - Remove CompanionUnitKicked from CompanionFocusNazgrek.
        Unit Group - Remove CompanionUnitKicked from CompanionFocusZulkis.
        Trigger - Run MultiboardUpdate Remove Companion <gen> (checking conditions)
