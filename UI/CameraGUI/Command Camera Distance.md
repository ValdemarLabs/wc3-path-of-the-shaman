Command Camera Distance
    Events
        Player - Player 1 (Red) types a chat message containing /cam dist  as A substring
    Conditions
    Actions
        -------- ======== Extract value from the chat message --------
        Set VariableSet CameraParameterDistance[(Player number of (Triggering player))] = (Real((Substring((Entered chat string), 11, (Length of (Entered chat string))))))
        -------- ======== Apply min/max failsafe values --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraParameterDistance[(Player number of (Triggering player))] Less than 500.00
            Then - Actions
                Set VariableSet CameraParameterDistance[(Player number of (Triggering player))] = 500.00
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraParameterDistance[(Player number of (Triggering player))] Greater than 4000.00
            Then - Actions
                Set VariableSet CameraParameterDistance[(Player number of (Triggering player))] = 4000.00
            Else - Actions
        -------- ======== Adjust the player's camera --------
        Camera - Set (Triggering player)'s camera Distance to target to CameraParameterDistance[(Player number of (Triggering player))] over 0.00 seconds
        Sound - Play IAMCHEAT <gen>
