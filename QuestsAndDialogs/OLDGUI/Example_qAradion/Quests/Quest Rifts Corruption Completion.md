Quest Rifts Corruption Completion
    Events
        Unit - A unit enters AradionPlace <gen>
    Conditions
        (Owner of (Entering unit)) Equal to Player 1 (Red)
    Actions
        Set VariableSet CV = (Custom value of Aradion)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[CV] Equal to False
            Then - Actions
                -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                Skip remaining actions
                -------- ======== ======== --------
            Else - Actions
        Set VariableSet CV = (Custom value of Valeria)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[CV] Equal to False
            Then - Actions
                -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                Skip remaining actions
                -------- ======== ======== --------
            Else - Actions
        Trigger - Turn off (This trigger)
        -------- Run triggers --------
        Custom script:   call TriggerExecute(gg_trg_Valeria_Remove_Companion)
        Custom script:   call TriggerExecute(gg_trg_Aradion_Remove_Companion)
        -------- ================ MOVE VALERIA --------
        Set VariableSet ValeriaPoint = (Center of ValeriaNewPos <gen>)
        Unit - Move Valeria instantly to ValeriaPoint, facing 192.00 degrees
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        -------- ================ MOVE ARADION --------
        Set VariableSet AradionPoint = (Center of AradionPos <gen>)
        Unit - Move Aradion instantly to AradionPoint, facing 184.00 degrees
        Custom script:   call RemoveLocation(udg_AradionPoint)
        -------- ======== CINEMATIC MOVE ======== --------
        Set VariableSet CinematicTriggerUnit = Nazgrek
        Set VariableSet CinematicMoveMode = 1
        Set VariableSet CinematicMovePoint[1] = ((Position of Aradion) offset by 256.00 towards 210.00 degrees.)
        Set VariableSet CinematicMovePoint[2] = ((Position of Aradion) offset by 256.00 towards 210.00 degrees.)
        Trigger - Run Cinematic ON <gen> (checking conditions)
        Custom script:   call RemoveLocation(udg_CinematicMovePoint[1])
        Custom script:   call RemoveLocation(udg_CinematicMovePoint[2])
        -------- ================================ --------
        Cinematic - Turn cinematic mode On for (All players)
        Cinematic - Fade out and back in over 1.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        Wait 1.00 seconds
        -------- DIALOG CAMERA == START --------
        Set VariableSet DialogNPC = Aradion
        -------- USAGE: call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck) --------
        -------- Typical values (no blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1200.0, 0.0, 0.0, 0.0, 10000.0, 75.0, 0.0, false) --------
        -------- Typical values (blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, true) --------
        Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 1050.0, 20.0, 350.0, 180.0, 10000.0, 60.0, 0.0, true)
        -------- ================================ --------
        -------- SKIPPED - restore state --------
        Set VariableSet DialogSkipped = False
        -------- RIFTS CORRUPTION - COMPLETED --------
        Set VariableSet AradionFarewellBoolean = True
        Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Complete_Quest_4)
        -------- =========== --------
        Cinematic - Disable user control for (All players).
        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
        -------- ===================================== --------
        Set VariableSet ExSoundString = The wound in the land is remedied… for now.
        Custom script:   call ExSound_Play("Nazgrek_0378", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
        -------- ===================================== --------
        Set VariableSet ExSoundString = The rifts… are sealed. For the first time in years, the air feels lighter in the Vale.
        Custom script:   call ExSound_Play("Aradion_0071", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
        -------- ===================================== --------
        Set VariableSet ExSoundString = You stood unbroken, my dear friend. Hope stirs again — faint, but alive.
        Custom script:   call ExSound_Play("Aradion_0072", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
        -------- ===================================== --------
        Set VariableSet ExSoundString = Thank you, shaman. You have given us more than victory — you have given us belief.
        Custom script:   call ExSound_Play("Aradion_0073", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
        -------- OVER --------
        Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Complete_Quest_4)
        Skip remaining actions
