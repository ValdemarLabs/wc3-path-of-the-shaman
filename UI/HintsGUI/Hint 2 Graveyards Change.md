Hint 2 Graveyards Change
    Events
        Unit - A unit enters GraveyardDiscovered <gen>
    Conditions
        HintPublished[2] Not equal to True
        (Triggering unit) Equal to Nazgrek
    Actions
        Trigger - Turn off (This trigger)
        Wait Campaign hint delay seconds
        Quest - Display to Player Group - Player 1 (Red) the Secret message: |cff32CD32Hint|r - ...
        Set VariableSet HintPublished[2] = True
