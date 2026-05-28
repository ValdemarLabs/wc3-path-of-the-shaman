Camera Restore Parameters
    Events
    Conditions
    Actions
        For each (Integer CameraPlayerNumber) from 1 to 20, do (Actions)
            Loop - Actions
                -------- Restore Camera settings --------
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Angle of attack to Camera_AngleOfAttack[CameraPlayerNumber] over 0.10 seconds
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Rotation to Camera_Rotation[CameraPlayerNumber] over 0.10 seconds
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Far Z to CameraParameterFarZ[(Player number of (Triggering player))] over 0.00 seconds
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Distance to target to CameraParameterDistance[(Player number of (Triggering player))] over 0.00 seconds
                Camera - Set CameraPlayers[CameraPlayerNumber]'s camera Field of view to CameraParameterFov[(Player number of (Triggering player))] over 0.00 seconds
