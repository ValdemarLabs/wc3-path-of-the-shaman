Command Camera Default Init
    Events
        Time - Elapsed game time is 0.10 seconds
    Conditions
    Actions
        -------- Set the camera parameters to DEFAULT --------
        Set VariableSet CameraParameterFarZ[(Player number of (Triggering player))] = 30000.00
        Set VariableSet CameraParameterDistance[(Player number of (Triggering player))] = 1650.00
        Set VariableSet CameraParameterAngle[(Player number of (Triggering player))] = 304.00
        Set VariableSet CameraParameterRotation[(Player number of (Triggering player))] = 90.00
        Set VariableSet CameraParameterFov[(Player number of (Triggering player))] = 70.00
        -------- Set the camera to DEFAULT --------
        Camera - Set (Triggering player)'s camera Far Z to CameraParameterFarZ[(Player number of (Triggering player))] over 0.00 seconds
        Camera - Set (Triggering player)'s camera Distance to target to CameraParameterDistance[(Player number of (Triggering player))] over 0.00 seconds
        Camera - Set (Triggering player)'s camera Angle of attack to CameraParameterAngle[(Player number of (Triggering player))] over 0.00 seconds
        Camera - Set (Triggering player)'s camera Rotation to CameraParameterRotation[(Player number of (Triggering player))] over 0.00 seconds
        Camera - Set (Triggering player)'s camera Field of view to CameraParameterFov[(Player number of (Triggering player))] over 0.00 seconds
