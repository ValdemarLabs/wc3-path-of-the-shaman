Camera Press R
    Events
        Player - Player 1 (Red) Presses the Right Arrow key
        Player - Player 20 (Lavender) Presses the Right Arrow key
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Camera_KeyboardActions Equal to True
            Then - Actions
                Set VariableSet CameraPlayerNumber = (Player number of (Triggering player))
                Set VariableSet Camera_PressingR[CameraPlayerNumber] = True
                Set VariableSet Camera_MoveL[CameraPlayerNumber] = False
                Set VariableSet Camera_MoveR[CameraPlayerNumber] = True
                -------- Start Camera Update Loop if it's not running --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Camera_UpdateLoop Equal to False
                    Then - Actions
                        Set VariableSet Camera_UpdateLoop = True
                        Trigger - Turn on Camera Update <gen>
                    Else - Actions
            Else - Actions
