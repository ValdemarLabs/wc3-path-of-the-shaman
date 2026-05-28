Command Camera Mode Normal
    Events
        Player - Player 1 (Red) types a chat message containing /cam norm as An exact match
    Conditions
    Actions
        Set VariableSet CameraPlayer = (Triggering player)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Nazgrek is selected by (Triggering player).) Equal to True
            Then - Actions
                Set VariableSet CameraUnit = Nazgrek
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Zulkis is selected by (Triggering player).) Equal to True
            Then - Actions
                Set VariableSet CameraUnit = Zulkis
            Else - Actions
                Set VariableSet CameraUnit = Nazgrek
        -------- ENABLE - Isometric locked camera --------
        Custom script:   call FCL_Lock(udg_CameraUnit, udg_CameraPlayer)
        -------- ENABLE - Keyboard rotate / angle from arrows --------
        Set VariableSet Camera_KeyboardActions = True
        -------- DISABLE - 1st person camera --------
        Trigger - Run Disable 1st Person Camera <gen> (checking conditions)
        Custom script:   call ReleaseMovementUnit(udg_CameraPlayer)
        -------- ============ SET THE MODE --------
        Set VariableSet CameraModeNormal = True
        Set VariableSet CameraModeAdvanced = False
        Set VariableSet CameraModeDeveloper = False
        Wait 0.10 seconds
        Selection - Select CameraUnit for CameraPlayer
        Sound - Play IAMCHEAT <gen>
