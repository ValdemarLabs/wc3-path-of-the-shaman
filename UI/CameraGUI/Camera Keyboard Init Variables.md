Camera Keyboard Init Variables
    Events
        Time - Elapsed game time is 0.50 seconds
    Conditions
    Actions
        -------- Rotational Speeds --------
        Set VariableSet Camera_SpeedHorizontal = 1.50
        Set VariableSet Camera_SpeedVertical = 1.50
        -------- Angle of Attack --------
        Set VariableSet Camera_AngleMin = 270.00
        Set VariableSet Camera_AngleMax = 350.00
        -------- init values --------
        -------- init players --------
        Player Group - Pick every player in (All players controlled by a User player) and do (Actions)
            Loop - Actions
                Set VariableSet CameraPlayers[(Player number of (Picked player))] = (Picked player)
        For each (Integer CameraPlayerNumber) from 1 to 20, do (Actions)
            Loop - Actions
                -------- ==================== --------
                -------- Set the camera parameters to DEFAULT --------
                -------- -- Command parameters via chat --------
                Set VariableSet CameraParameterFarZ[CameraPlayerNumber] = 30000.00
                Set VariableSet CameraParameterDistance[CameraPlayerNumber] = 1650.00
                Set VariableSet CameraParameterAngle[CameraPlayerNumber] = 304.00
                Set VariableSet CameraParameterRotation[CameraPlayerNumber] = 90.00
                Set VariableSet CameraParameterFov[CameraPlayerNumber] = 70.00
                -------- -- Command parameters via keyboard --------
                Set VariableSet Camera_AngleOfAttack[CameraPlayerNumber] = 304.00
                Set VariableSet Camera_Rotation[CameraPlayerNumber] = 90.00
                -------- ==================== --------
