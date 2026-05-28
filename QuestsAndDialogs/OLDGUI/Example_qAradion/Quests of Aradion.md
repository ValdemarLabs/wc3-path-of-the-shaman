Quests of Aradion
    Events
        Player - Player 1 (Red) Selects a unit
    Conditions
        (Triggering unit) Equal to Aradion
        (Distance between (Position of Aradion) and (Position of Nazgrek)) Less than or equal to 500.00
        (Remaining time for DialogOverTimer) Equal to 0.00
    Actions
        -------- ======== Initial check of the selected unit ======== --------
        Set VariableSet CV = (Custom value of (Triggering unit))
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        UnitIsCasting[CV] Equal to True
                        GCSM_UnitInCombat[CV] Equal to True
            Then - Actions
                -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                Skip remaining actions
                -------- ======== ======== --------
            Else - Actions
        -------- ======== START ======== --------
        Trigger - Turn off (This trigger)
        -------- ======== CINEMATIC STARTS ======== --------
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
        Wait 0.25 seconds
        Unit - Make Aradion face Nazgrek over 0.75 seconds
        Unit - Make Nazgrek face Aradion over 0.75 seconds
        Wait 1.00 seconds
        -------- DIALOG CAMERA == START --------
        Set VariableSet DialogNPC = Aradion
        -------- USAGE: call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck) --------
        -------- Typical values (no blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1200.0, 0.0, 0.0, 0.0, 10000.0, 75.0, 0.0, false) --------
        -------- Typical values (blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, true) --------
        Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 1050.0, 20.0, 350.0, 180.0, 10000.0, 60.0, 0.0, true)
        -------- ================================ --------
        Wait 1.00 seconds
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- FIRST DIALOG --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionFarewellBoolean Equal to False
                    Then - Actions
                        -------- If the Player has previosly not declined the quest --------
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = An… orc? Here? If you came for blood, take mine swiftly. I will not flee…
                        Custom script:   call ExSound_Play("Aradion_0001", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = Your blood is not what I seek, elf. I walk the spirit path, not the path of slaughter.
                        Custom script:   call ExSound_Play("Nazgrek_0331", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = …No. Orcs do not speak so. You… are different.
                        Custom script:   call ExSound_Play("Aradion_0002", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                        -------- ====================== --------
                        -------- Run "Create Dialog" --------
                        Trigger - Run Create AradionDialog01 <gen> (checking conditions)
                        Trigger - Turn on (This trigger)
                        Skip remaining actions
                    Else - Actions
                -------- DIALOG (QUEST(s) UNFINISHED --------
                Custom script:   call TriggerExecute(gg_trg_Nazgrek_Greet)
                Wait ExSoundDuration seconds
                -------- ======================== --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Valeria is in Companion_Group.) Equal to False
                        (QuestRangerMissing is discovered) Equal to True
                        (QuestRangerMissing is completed) Equal to False
                    Then - Actions
                        -------- RANGER MISSING UNFINISHED --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 2) Equal to 1
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Valeria is still missing... Tell me you have found her?
                                Custom script:   call ExSound_Play("Aradion_0037", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                            Else - Actions
                                Set VariableSet ExSoundString = More and more wraiths are circling around Elarindor… please, do not let her be lost to them.
                                Custom script:   call ExSound_Play("Aradion_0038", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 2) Equal to 1
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I’ll see if I come across her.
                                Custom script:   call ExSound_Play("Nazgrek_0337", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                            Else - Actions
                                -------- ===================================== --------
                        -------- ====================== --------
                        -------- Run "Create Dialog" --------
                        Trigger - Run Create AradionDialog01 <gen> (checking conditions)
                        Trigger - Turn on (This trigger)
                        Skip remaining actions
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (QuestRangerMissing is completed) Equal to True
                        (QuestCrystalsHope is discovered) Equal to True
                        (QuestCrystalsHope is completed) Equal to False
                    Then - Actions
                        -------- CRYSTALS HOPE UNFINISHED --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 2) Equal to 1
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Have you managed to obtain any crystal shards?
                                Custom script:   call ExSound_Play("Aradion_0045", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                            Else - Actions
                                Set VariableSet ExSoundString = Without those shards, the hope slips further from our grasp.
                                Custom script:   call ExSound_Play("Aradion_0046", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                        -------- ====================== --------
                        -------- Run "Create Dialog" --------
                        Trigger - Run Create AradionDialog01 <gen> (checking conditions)
                        Trigger - Turn on (This trigger)
                        Skip remaining actions
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (QuestRangerMissing is completed) Equal to True
                        (QuestFadingSparks is discovered) Equal to True
                        (QuestFadingSparks is completed) Equal to False
                    Then - Actions
                        -------- FADING SPARKS UNFINISHED --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 2) Equal to 1
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Our people's shades still drift through the Vale. You must claim their sparks…
                                Custom script:   call ExSound_Play("Aradion_0057", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                            Else - Actions
                                Set VariableSet ExSoundString = Do not let their torment go to waste. Bring me what little endures.
                                Custom script:   call ExSound_Play("Aradion_0058", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                        -------- ====================== --------
                        -------- Run "Create Dialog" --------
                        Trigger - Run Create AradionDialog01 <gen> (checking conditions)
                        Trigger - Turn on (This trigger)
                        Skip remaining actions
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (QuestRangerMissing is completed) Equal to True
                        (QuestCrystalsHope is completed) Equal to True
                        (QuestFadingSparks is completed) Equal to True
                        (QuestRiftsCorruption is discovered) Equal to True
                        (QuestRiftsCorruption is completed) Equal to False
                        (QuestRiftsCorruption is failed) Equal to False
                    Then - Actions
                        -------- RIFTS CORRUPTION UNFINISHED --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 2) Equal to 1
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = The rifts are still open. If they are not sealed, the Vale will never heal.
                                Custom script:   call ExSound_Play("Aradion_0069", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                            Else - Actions
                                Set VariableSet ExSoundString = Hold the line! Protect Valeria — protect us both, shaman!
                                Custom script:   call ExSound_Play("Aradion_0070", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                        -------- ====================== --------
                        -------- Run "Create Dialog" --------
                        Trigger - Run Create AradionDialog01 <gen> (checking conditions)
                        Trigger - Turn on (This trigger)
                        Skip remaining actions
                    Else - Actions
                -------- NORMAL DIALOG - NEUTRAL --------
                Set VariableSet AradionRandomGreet = (Random integer number between 1 and 4)
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 1
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = I did not expect company in these ruins.
                        Custom script:   call ExSound_Play("Aradion_0020", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 2
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = Yes, shaman?
                        Custom script:   call ExSound_Play("Aradion_0021", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 3
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = Hm? Ah, it’s you.
                        Custom script:   call ExSound_Play("Aradion_0022", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 4
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = Have you seen Valeria?
                        Custom script:   call ExSound_Play("Aradion_0023", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        Set VariableSet ExSoundString = She is always on the run…
                        Custom script:   call ExSound_Play("Aradion_0024", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
                -------- ====================== --------
                -------- Run "Create Dialog" --------
                Trigger - Run Create AradionDialog01 <gen> (checking conditions)
                Trigger - Turn on (This trigger)
                Skip remaining actions
            Else - Actions
