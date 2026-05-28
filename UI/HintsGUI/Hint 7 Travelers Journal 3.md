Hint 7 Travelers Journal 3
    Events
    Conditions
        HintPublished[7] Not equal to True
    Actions
        Wait Campaign hint delay seconds
        Quest - Display to Player Group - Player 1 (Red) the Secret message: |cFF32CD32Hint|r|cF...
        Quest - Create a quest requirement for HintsQLog with the description |cFF32CD32Hint|r|cF...
        Set VariableSet HintPublished[7] = True
        Wait Campaign hint delay seconds
        Trigger - Remove (This trigger) from the trigger queue
