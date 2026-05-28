Command Camera AngleAttack
    Events
        Player - Player 1 (Red) types a chat message containing /cam angle  as A substring
    Conditions
    Actions
        -------- ======== Extract value from the chat message --------
        Set VariableSet CameraParameterAngle[(Player number of (Triggering player))] = (Real((Substring((Entered chat string), 12, (Length of (Entered chat string))))))
        -------- ======== Apply min/max failsafe values --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraParameterAngle[(Player number of (Triggering player))] Less than 0.00
            Then - Actions
                Set VariableSet CameraParameterAngle[(Player number of (Triggering player))] = 0.00
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraParameterAngle[(Player number of (Triggering player))] Greater than 360.00
            Then - Actions
                Set VariableSet CameraParameterAngle[(Player number of (Triggering player))] = 360.00
            Else - Actions
        -------- ======== Adjust the player's camera --------
        Camera - Set (Triggering player)'s camera Angle of attack to CameraParameterAngle[(Player number of (Triggering player))] over 0.00 seconds
        Sound - Play IAMCHEAT <gen>
