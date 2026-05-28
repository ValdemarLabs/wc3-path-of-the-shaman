AradionDialog01 Complete Quest 4
    Events
        Player - Player 1 (Red) skips a cinematic sequence
    Conditions
    Actions
        Trigger - Turn off (This trigger)
        -------- SKIPPED --------
        Set VariableSet DialogSkipped = True
        -------- SKIPPED --------
        -------- Disable FAIL Conditions --------
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Valeria_Dies)
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Aradion_Dies)
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
        Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_Complete)
        Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
        -------- CONTINUE PATROL --------
        Custom script:   call TriggerExecute(gg_trg_Valeria_Movement_Continue)
