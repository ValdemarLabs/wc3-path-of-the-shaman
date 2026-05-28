Hint 3 Travelers Journal 1
    Events
    Conditions
        HintPublished[3] Not equal to True
    Actions
        Wait Campaign hint delay seconds
        Quest - Display to Player Group - Player 1 (Red) the Secret message: |cff32CD32Hint|r - ...
        Quest - Create a quest requirement for HintsQLog with the description |cff32CD32Hint|r - ...
        Set VariableSet HintPublished[3] = True
        Wait Campaign hint delay seconds
        Trigger - Remove (This trigger) from the trigger queue
