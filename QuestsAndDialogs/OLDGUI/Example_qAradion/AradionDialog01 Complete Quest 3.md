AradionDialog01 Complete Quest 3
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
        -------- Remove quest items --------
        -------- CHECK AND REMOVE ITEMs (Will remove which unit first will have the charges) --------
        Set VariableSet DInvItemType = Wraith Essence
        Set VariableSet DInvItemAmount = 10
        Custom script:   set udg_DInvItemCarrierHasItems = HeroItemCheckBothAndRemove(udg_DInvItemType, udg_DInvItemAmount)
        -------- CHECK AND REMOVE ITEMs (Will remove which unit first will have the charges) --------
        Set VariableSet DInvItemType = |cffffff00Tel’anor Rod|r
        Set VariableSet DInvItemAmount = 1
        Custom script:   set udg_DInvItemCarrierHasItems = HeroItemCheckBothAndRemove(udg_DInvItemType, udg_DInvItemAmount)
        -------- ======================= --------
        -------- ======== CINEMATIC ENDS ======== --------
        -------- DEFAULT CAMERA --------
        -------- ================================ --------
        -------- DIALOG CAMERA == RESET --------
        -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
        Custom script:   call DialogCameraReset(Player(0), 2.0)
        -------- ======== CINEMATIC ENDS ======== --------
        Trigger - Run Cinematic OFF <gen> (checking conditions)
        Wait Campaign quest delay seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Fading_Sparks_Complete)
        Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
