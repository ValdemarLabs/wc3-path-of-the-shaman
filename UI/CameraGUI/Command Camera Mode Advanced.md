Command Camera Mode Advanced
    Events
        Player - Player 1 (Red) types a chat message containing /cam adv as An exact match
    Conditions
    Actions
        Set VariableSet CameraPlayer = (Triggering player)
        -------- DISABLE - Isometric locked camera --------
        Custom script:   call FCL_Release(udg_CameraPlayer)
        -------- DISABLE - Keyboard rotate / angle from arrows --------
        Set VariableSet Camera_KeyboardActions = False
        -------- ENABLE - 1st person camera --------
        Trigger - Run Enable1st Person Camera <gen> (checking conditions)
        Sound - Play IAMCHEAT <gen>
        Selection - Select CameraUnit for CameraPlayer
        -------- ============ SET THE MODE --------
        Set VariableSet CameraModeNormal = False
        Set VariableSet CameraModeAdvanced = True
        Set VariableSet CameraModeDeveloper = False
