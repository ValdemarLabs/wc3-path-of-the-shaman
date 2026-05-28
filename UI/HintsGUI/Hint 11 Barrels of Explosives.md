Hint 11 Barrels of Explosives
    Events
    Conditions
        HintPublished[11] Not equal to True
    Actions
        Set VariableSet HintPublished[11] = True
        Wait 5.00 seconds
        Quest - Display to Player Group - Player 1 (Red) the Warning message: |cFFFF0000Warning|r...
        Quest - Create a quest requirement for HintsQLog with the description |cFFFF0000Warning|r...
        Wait Campaign hint delay seconds
        Trigger - Remove (This trigger) from the trigger queue
