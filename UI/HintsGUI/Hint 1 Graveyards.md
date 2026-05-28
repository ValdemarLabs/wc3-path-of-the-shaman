Hint 1 Graveyards
    Events
        Unit - A unit owned by Player 1 (Red) Dies
    Conditions
        HintPublished[1] Not equal to True
        Or - Any (Conditions) are true
            Conditions
                (Triggering unit) Equal to Nazgrek
                (Triggering unit) Equal to Zulkis
    Actions
        Trigger - Turn off (This trigger)
        Set VariableSet HintPublished[1] = True
        Wait Campaign hint delay seconds
        Quest - Display to Player Group - Player 1 (Red) the Secret message: (|cFF32CD32Hint|r|cFFFFFFFF |r + (|cFFFFCC00 + ((Proper name of (Triggering unit)) + (|r  +  |cFFFFFFFFhas died, but will be resurrected at the graveyard. |r))))
        Wait Campaign hint delay seconds
        Quest - Display to Player Group - Player 1 (Red) the Secret message: (|cFF32CD32Hint|r|cFFFFFFFF |r + (Graveyards can be found in multiple locations. Graveyard is selected by walking over it. + (<Empty String> + <Empty String>)))
        Trigger - Remove (This trigger) from the trigger queue
