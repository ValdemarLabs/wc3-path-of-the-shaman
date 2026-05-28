Camera Switch
    Events
        Player - Player 1 (Red) Selects a unit
        Player - Player 20 (Lavender) Selects a unit
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Triggering unit) Equal to Nazgrek
                (Triggering unit) Equal to Zulkis
    Actions
        Set VariableSet CameraPlayer = (Triggering player)
        Set VariableSet CameraUnit = (Triggering unit)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraModeNormal Equal to True
            Then - Actions
                Custom script:   call FCL_Lock(udg_CameraUnit, udg_CameraPlayer)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                CameraModeAdvanced Equal to True
            Then - Actions
                Custom script:   call SetCameraUnit(udg_CameraUnit, udg_CameraPlayer)
                Custom script:   call SetMovementUnit(udg_CameraUnit,udg_CameraPlayer,5)
                Camera - Set CameraPlayer's camera Far Z to 20000.00 over 0.00 seconds
            Else - Actions
