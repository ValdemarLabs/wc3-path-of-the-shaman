Command Camera Mode Developer
    Events
        Player - Player 1 (Red) types a chat message containing /cam dev as An exact match
    Conditions
    Actions
        -------- //// = Normal camera view --------
        -------- Add additional boolean condition for DeveloperEnabled = TRUE --------
        Set VariableSet CameraPlayer = (Triggering player)
        -------- DISABLE - Isometric locked camera --------
        Custom script:   call FCL_Release(udg_CameraPlayer)
        -------- DISABLE - Keyboard rotate / angle from arrows --------
        Set VariableSet Camera_KeyboardActions = False
        -------- DISABLE - 1st person camera --------
        Trigger - Run Disable 1st Person Camera <gen> (checking conditions)
        Custom script:   call ReleaseMovementUnit(udg_CameraPlayer)
        Sound - Play IAMCHEAT <gen>
        -------- ============ SET THE MODE --------
        Set VariableSet CameraModeNormal = False
        Set VariableSet CameraModeAdvanced = False
        Set VariableSet CameraModeDeveloper = True
