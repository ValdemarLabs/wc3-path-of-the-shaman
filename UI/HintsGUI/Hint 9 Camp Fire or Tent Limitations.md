Hint 9 Camp Fire or Tent Limitations
    Events
    Conditions
        HintPublished[9] Not equal to True
    Actions
        Set VariableSet HintPublished[9] = True
        Wait 5.00 seconds
        Quest - Display to Player Group - Player 1 (Red) the Hint message: |cff32CD32HINT|r - ...
        Quest - Create a quest requirement for HintsQLog with the description |cff32CD32HINT|r - ...
        Wait Campaign hint delay seconds
        Trigger - Remove (This trigger) from the trigger queue
