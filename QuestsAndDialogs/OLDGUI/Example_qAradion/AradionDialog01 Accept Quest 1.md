AradionDialog01 Accept Quest 1
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
        -------- Reset Camera --------
        Camera - Reset camera smoothing factor
        Camera - Reset camera for Player 1 (Red) to standard game-view over 0.00 seconds
        Wait 0.50 seconds
        -------- Fade In --------
        Cinematic - Fade in over 0.50 seconds using texture White Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        Wait 0.50 seconds
        -------- ======== CINEMATIC ENDS ======== --------
        -------- DEFAULT CAMERA --------
        -------- ================================ --------
        -------- DIALOG CAMERA == RESET --------
        -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
        Custom script:   call DialogCameraReset(Player(0), 2.0)
        -------- ======== CINEMATIC ENDS ======== --------
        Trigger - Run Cinematic OFF <gen> (checking conditions)
        Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Ranger_Missing)
