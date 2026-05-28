Quest Rifts Corruption Ritual Prepare
    Events
        Game - WithinRangeEvent becomes Equal to 1.00
    Conditions
        Or - Any (Conditions) are true
            Conditions
                WithinRangeUnit Equal to QuestRifts[1]
                WithinRangeUnit Equal to QuestRifts[2]
                WithinRangeUnit Equal to QuestRifts[3]
        (Owner of WithinRangeEnteringUnit) Equal to Player 1 (Red)
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
        Trigger - Turn off (This trigger)
        -------- ================ Set RIFT unit --------
        Set VariableSet QuestRiftCurrent = WithinRangeUnit
        Set VariableSet QuestRiftsCorruptionWaveN = 1
        -------- ================ ARADION BEGINS RITUAL --------
        -------- ======== CINEMATIC MOVE ======== --------
        Set VariableSet CinematicTriggerUnit = Nazgrek
        Set VariableSet CinematicMoveMode = 9
        Set VariableSet CinematicMovePoint[1] = ((Position of Aradion) offset by 256.00 towards 210.00 degrees.)
        Set VariableSet CinematicMovePoint[2] = ((Position of Aradion) offset by 256.00 towards 210.00 degrees.)
        Trigger - Run Cinematic ON <gen> (checking conditions)
        Custom script:   call RemoveLocation(udg_CinematicMovePoint[1])
        Custom script:   call RemoveLocation(udg_CinematicMovePoint[2])
        -------- ================================ --------
        Cinematic - Turn cinematic mode On for (All players)
        Cinematic - Fade out and back in over 1.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        Wait 0.50 seconds
        Custom script:   call TriggerExecute(gg_trg_Aradion_Remove_Companion)
        Unit - Remove Wander (Neutral) from Aradion
        Unit - Order Aradion to Stop.
        -------- ================ MOVE ARADION --------
        Set VariableSet VarPoint = (Position of QuestRiftCurrent)
        Set VariableSet AradionPoint = (VarPoint offset by 500.00 towards (Facing of Aradion) degrees.)
        Unit - Move Aradion instantly to AradionPoint
        Custom script:   call RemoveLocation(udg_VarPoint)
        Custom script:   call RemoveLocation(udg_AradionPoint)
        -------- ================ MOVE VALERIA --------
        Set VariableSet VarPoint = (Position of Aradion)
        Set VariableSet ValeriaPoint = (VarPoint offset by 200.00 towards (Facing of Aradion) degrees.)
        Unit - Move Valeria instantly to ValeriaPoint
        Custom script:   call RemoveLocation(udg_VarPoint)
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        Wait 0.50 seconds
        -------- DIALOG CAMERA == START --------
        Set VariableSet DialogNPC = Aradion
        -------- USAGE: call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck) --------
        -------- Typical values (no blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1200.0, 0.0, 0.0, 0.0, 10000.0, 75.0, 0.0, false) --------
        -------- Typical values (blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, true) --------
        Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 2350.0, 20.0, 333.0, 180.0, 10000.0, 70.0, 0.0, true)
        -------- ================================ --------
        Wait 1.00 seconds
        Set VariableSet VarPoint = (Position of QuestRiftCurrent)
        Set VariableSet AradionPoint = (Position of Aradion)
        Set VariableSet AradionAngle = (Angle from VarPoint to AradionPoint)
        Custom script:   call RemoveLocation(udg_AradionPoint)
        Set VariableSet AradionPoint = (VarPoint offset by 500.00 towards AradionAngle degrees.)
        Unit - Order Aradion to Move To AradionPoint
        Custom script:   call RemoveLocation(udg_VarPoint)
        Custom script:   call RemoveLocation(udg_AradionPoint)
        -------- CHAT --------
        Set VariableSet AradionRandomGreet = (Random integer number between 1 and 2)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionRandomGreet Equal to 1
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = Stand ready, Nazgrek. Once I begin, this place can start to crawl with wraiths.
                Custom script:   call ExSound_Play("Aradion_0074", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionRandomGreet Equal to 2
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = I will attempt to close this rift. But I cannot fight and focus at once… you must protect me!
                Custom script:   call ExSound_Play("Aradion_0075", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        Set VariableSet ValeriaRandomGreet = (Random integer number between 1 and 2)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 1
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = We will handle them, just keep your focus on the rift!
                Custom script:   call ExSound_Play("Valeria_0072", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Don't wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 2
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = We stand ready to defend you!
                Custom script:   call ExSound_Play("Valeria_0073", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Don't wait
                -------- ===================================== --------
            Else - Actions
        -------- ===================================== --------
        Wait 2.00 seconds
        -------- ===================================== --------
        -------- EFFECTS AND FORCE "CASTING" --------
        Set VariableSet AradionPoint = (Position of QuestRiftCurrent)
        Unit - Add ClosePortal2 (Aradion) to Aradion
        Unit - Order Aradion to Human Archmage - Blizzard AradionPoint
        Custom script:   call RemoveLocation(udg_AradionPoint)
        -------- DEFAULT CAMERA --------
        -------- ================================ --------
        -------- DIALOG CAMERA == RESET --------
        -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
        Custom script:   call DialogCameraReset(Player(0), 2.0)
        -------- ======== CINEMATIC ENDS ======== --------
        Trigger - Run Cinematic OFF <gen> (checking conditions)
        -------- START TIMER --------
        Countdown Timer - Start QuestRiftsCorruptionTimerClose as a One-shot timer that will expire in 120.00 seconds
        Set VariableSet QuestRiftsCorruptionCountdown = 120
        Trigger - Turn on Quest Rifts Corruption TimerText <gen>
        -------- START ATTACK WAVES --------
        Custom script:   call EnableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Waves)
        Custom script:   call EnableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Combat)
