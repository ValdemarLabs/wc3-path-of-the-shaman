Command Camera Fov
    Events
        Player - Player 1 (Red) types a chat message containing /cam fov  as A substring
    Conditions
    Actions
        -------- ======== Extract value from the chat message --------
        Set VariableSet CameraParameterFov[(Player number of (Triggering player))] = (Real((Substring((Entered chat string), 10, (Length of (Entered chat string))))))
        -------- ======== Apply min/max failsafe values --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraParameterFov[(Player number of (Triggering player))] Less than 0.00
            Then - Actions
                Set VariableSet CameraParameterFov[(Player number of (Triggering player))] = 20.00
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraParameterFov[(Player number of (Triggering player))] Greater than 120.00
            Then - Actions
                Set VariableSet CameraParameterFov[(Player number of (Triggering player))] = 120.00
            Else - Actions
        -------- ======== Adjust the player's camera --------
        Camera - Set (Triggering player)'s camera Field of view to CameraParameterFov[(Player number of (Triggering player))] over 0.00 seconds
        Sound - Play IAMCHEAT <gen>
