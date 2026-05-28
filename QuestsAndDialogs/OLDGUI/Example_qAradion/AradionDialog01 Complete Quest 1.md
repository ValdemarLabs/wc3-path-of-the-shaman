AradionDialog01 Complete Quest 1
    Events
        Player - Player 1 (Red) skips a cinematic sequence
    Conditions
    Actions
        Trigger - Turn off (This trigger)
        -------- SKIPPED --------
        Set VariableSet DialogSkipped = True
        -------- SKIPPED --------
        -------- Give Item --------
        -------- Fade Out --------
        Cinematic - Fade out over 0.50 seconds using texture White Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        Wait 0.50 seconds
        -------- Remove OLD Valeria + Create New Valeria to change respawn point --------
        Unit - Remove Valeria from the game
        Set VariableSet ValeriaPoint = (Center of ValeriaNewPos <gen>)
        Unit - Create 1 Valeria for Player 16 (Violet) at ValeriaPoint facing 252.00 degrees
        Set VariableSet Valeria = (Last created unit)
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        -------- START Patrol for Valeria --------
        Custom script:   call ValeriaMovementStart()
        -------- Add abilities to Valeria --------
        Unit - Add Dash (Valeria) to Valeria
        Unit - Add Cold Arrows (Valeria) to Valeria
        Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
        -------- Reset Camera --------
        Camera - Reset camera smoothing factor
        Camera - Reset camera for Player 1 (Red) to standard game-view over 0.00 seconds
        Wait 0.50 seconds
        -------- Fade In --------
        Cinematic - Fade in over 0.50 seconds using texture White Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        Wait 0.50 seconds
        -------- Remove quest items --------
        -------- ======== CINEMATIC ENDS ======== --------
        -------- DEFAULT CAMERA --------
        -------- ================================ --------
        -------- DIALOG CAMERA == RESET --------
        -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
        Custom script:   call DialogCameraReset(Player(0), 2.0)
        -------- ======== CINEMATIC ENDS ======== --------
        Trigger - Run Cinematic OFF <gen> (checking conditions)
        Wait Campaign quest delay seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Ranger_Missing_Complete)
        Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
