Camera Update
    Events
        Time - Every 0.03 seconds of game time
    Conditions
        Camera_KeyboardActions Equal to True
    Actions
        -------- ==================== --------
        For each (Integer CameraPlayerNumber) from 1 to 20, do (Actions)
            Loop - Actions
                -------- Vertical Movement (Angle of Attack) --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Camera_MoveD[CameraPlayerNumber] Equal to True
                    Then - Actions
                        Set VariableSet Camera_AngleOfAttack[CameraPlayerNumber] = (Camera_AngleOfAttack[CameraPlayerNumber] + Camera_SpeedVertical)
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                Camera_AngleOfAttack[CameraPlayerNumber] Greater than Camera_AngleMax
                            Then - Actions
                                Set VariableSet Camera_AngleOfAttack[CameraPlayerNumber] = Camera_AngleMax
                            Else - Actions
                    Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                Camera_MoveU[CameraPlayerNumber] Equal to True
                            Then - Actions
                                Set VariableSet Camera_AngleOfAttack[CameraPlayerNumber] = (Camera_AngleOfAttack[CameraPlayerNumber] - Camera_SpeedVertical)
                                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                                    If - Conditions
                                        Camera_AngleOfAttack[CameraPlayerNumber] Less than Camera_AngleMin
                                    Then - Actions
                                        Set VariableSet Camera_AngleOfAttack[CameraPlayerNumber] = Camera_AngleMin
                                    Else - Actions
                            Else - Actions
                -------- ==================== --------
                -------- Horizontal Movement (Rotation) --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Camera_MoveR[CameraPlayerNumber] Equal to True
                    Then - Actions
                        Set VariableSet Camera_Rotation[CameraPlayerNumber] = (Camera_Rotation[CameraPlayerNumber] + Camera_SpeedHorizontal)
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                Camera_Rotation[CameraPlayerNumber] Greater than or equal to 360.00
                            Then - Actions
                                Set VariableSet Camera_Rotation[CameraPlayerNumber] = (Camera_Rotation[CameraPlayerNumber] - 360.00)
                            Else - Actions
                    Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                Camera_MoveL[CameraPlayerNumber] Equal to True
                            Then - Actions
                                Set VariableSet Camera_Rotation[CameraPlayerNumber] = (Camera_Rotation[CameraPlayerNumber] - Camera_SpeedHorizontal)
                                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                                    If - Conditions
                                        Camera_Rotation[CameraPlayerNumber] Less than or equal to 0.00
                                    Then - Actions
                                        Set VariableSet Camera_Rotation[CameraPlayerNumber] = (Camera_Rotation[CameraPlayerNumber] + 360.00)
                                    Else - Actions
                            Else - Actions
                -------- ==================== --------
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Angle of attack to Camera_AngleOfAttack[CameraPlayerNumber] over 0.10 seconds
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Rotation to Camera_Rotation[CameraPlayerNumber] over 0.10 seconds
