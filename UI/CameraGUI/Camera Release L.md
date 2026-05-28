Camera Release L
    Events
        Player - Player 1 (Red) Releases the Left Arrow key
        Player - Player 20 (Lavender) Releases the Left Arrow key
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Camera_KeyboardActions Equal to True
            Then - Actions
                Set VariableSet CameraPlayerNumber = (Player number of (Triggering player))
                Set VariableSet Camera_PressingL[CameraPlayerNumber] = False
                Set VariableSet Camera_MoveL[CameraPlayerNumber] = False
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Camera_PressingR[CameraPlayerNumber] Equal to True
                    Then - Actions
                        Set VariableSet Camera_MoveR[CameraPlayerNumber] = True
                    Else - Actions
                -------- ========================= --------
                -------- Check if ANY player is still pressing a movement key --------
                Set VariableSet Camera_AnyKeyPressed = False
                For each (Integer Camera_CheckInteger) from 1 to 20, do (Actions)
                    Loop - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                Or - Any (Conditions) are true
                                    Conditions
                                        Camera_PressingD[Camera_CheckInteger] Equal to True
                                        Camera_PressingL[Camera_CheckInteger] Equal to True
                                        Camera_PressingR[Camera_CheckInteger] Equal to True
                                        Camera_PressingU[Camera_CheckInteger] Equal to True
                            Then - Actions
                                Set VariableSet Camera_AnyKeyPressed = True
                            Else - Actions
                -------- If no keys are pressed, disable Camera Update loop --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Camera_AnyKeyPressed Equal to False
                    Then - Actions
                        Set VariableSet Camera_UpdateLoop = False
                        Trigger - Turn off Camera Update <gen>
                    Else - Actions
            Else - Actions
