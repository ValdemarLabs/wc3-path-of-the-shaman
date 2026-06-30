Valeria Negotiate Button Pressed
    Events
        Dialog - A dialog button is clicked for ValeriaDialog02
    Conditions
    Actions
        Set VariableSet CV = (Custom value of Valeria)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[CV] Not equal to True
            Then - Actions
                -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                Skip remaining actions
                -------- ======== ======== --------
            Else - Actions
        For each (Integer ValeriaLineLoopInt) from 1 to DialogBTN_Count, do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Clicked dialog button) Equal to DialogBTN_Button[ValeriaLineLoopInt]
                    Then - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 1
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = You are outmatched. Stand aside, or fall.
                                Custom script:   call ExSound_Play("Nazgrek_0344", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Then I shall fall but so will you!
                                Custom script:   call ExSound_Play("Valeria_0005", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 2
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = You have no right to stand in my way.
                                Custom script:   call ExSound_Play("Nazgrek_0345", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = This is my land — not yours! 
                                Custom script:   call ExSound_Play("Valeria_0006", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 3
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Enough! I’ll make you listen by force.
                                Custom script:   call ExSound_Play("Nazgrek_0346", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Try it, beast! My bow will show you force!
                                Custom script:   call ExSound_Play("Valeria_0007", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 4
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I’m not like the other orcs.
                                Custom script:   call ExSound_Play("Nazgrek_0347", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Orc tongues are venom — I won’t be deceived!
                                Custom script:   call ExSound_Play("Valeria_0008", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 5
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = You’re wasting both our time. Stand down.
                                Custom script:   call ExSound_Play("Nazgrek_0348", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Never! Not while I still draw breath!
                                Custom script:   call ExSound_Play("Valeria_0009", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 6
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I’m just passing by.
                                Custom script:   call ExSound_Play("Nazgrek_0349", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Then allow me to pass you to the shadowlands!
                                Custom script:   call ExSound_Play("Valeria_0010", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 7
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I’ll show you the power of the Earth mother!
                                Custom script:   call ExSound_Play("Nazgrek_0350", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Warmonger!
                                Custom script:   call ExSound_Play("Valeria_0011", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 8
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I am not your enemy!
                                Custom script:   call ExSound_Play("Nazgrek_0351", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Silence you bloodthirsty beast!
                                Custom script:   call ExSound_Play("Valeria_0012", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 9
                            Then - Actions
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I will not harm you.
                                Custom script:   call ExSound_Play("Nazgrek_0352", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = Lies! All lies!
                                Custom script:   call ExSound_Play("Valeria_0013", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Add Cold Arrows (Valeria) to Valeria
                                Unit - Order Valeria to Special Sylvanas Windrunner - Activate Cold Arrows.
                                Countdown Timer - Start ValeriaArrowTimer as a One-shot timer that will expire in 5.00 seconds
                                -------- ===================================== --------
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ValeriaLineArray[ValeriaLineLoopInt] Equal to 10
                            Then - Actions
                                Set VariableSet CV = (Custom value of Valeria)
                                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                                    If - Conditions
                                        IsUnitAlive[CV] Not equal to True
                                    Then - Actions
                                        -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                                        Skip remaining actions
                                        -------- ======== ======== --------
                                    Else - Actions
                                -------- ===================================== --------
                                -------- CORRECT --------
                                Set VariableSet ValeriaEncounterReset = True
                                -------- ===================================== --------
                                -------- RUN / ENABLE / DISABLE TRIGGERS --------
                                Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Random_Movement)
                                Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Range_Check)
                                Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Dies)
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = I’ve spoken with Aradion. He told me to find you.
                                Custom script:   call ExSound_Play("Nazgrek_0353", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Order Valeria to Stop.
                                Unit - Set Unit: Valeria's Real Field: Hit Points Regeneration Rate ('uhpr') to Value: 2.00
                                Unit - Set life of Valeria to 100.00%
                                Unit - Change ownership of Valeria to Player 19 (Mint) and Retain color
                                Wait 1.00 seconds
                                -------- ======== CINEMATIC STARTS ======== --------
                                Trigger - Run Cinematic ON <gen> (checking conditions)
                                Cinematic - Turn cinematic mode On for (All players)
                                Cinematic - Fade out and back in over 1.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
                                Wait 0.25 seconds
                                Unit - Make Valeria face Nazgrek over 0.75 seconds
                                Unit - Make Nazgrek face Valeria over 0.75 seconds
                                Wait 1.00 seconds
                                -------- Issue Valeria to run in front of Nazgrek --------
                                Set VariableSet VarPoint = (Position of Nazgrek)
                                Set VariableSet ValeriaPoint = (VarPoint offset by 400.00 towards (Facing of Nazgrek) degrees.)
                                Unit - Order Valeria to Move To ValeriaPoint
                                Custom script:   call RemoveLocation(udg_VarPoint)
                                Custom script:   call RemoveLocation(udg_ValeriaPoint)
                                -------- DIALOG CAMERA == START --------
                                Set VariableSet DialogNPC = Valeria
                                -------- USAGE: call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck) --------
                                -------- Typical values (no blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1200.0, 0.0, 0.0, 0.0, 10000.0, 75.0, 0.0, false) --------
                                -------- Typical values (blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, true) --------
                                Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 750.0, 50.0, 355.0, 45.0, 10000.0, 60.0, 0.0, true)
                                -------- ================================ --------
                                Wait 1.00 seconds
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = …Aradion? He… lives?
                                Custom script:   call ExSound_Play("Valeria_0014", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = If he trusts you, then… then perhaps I must as well. For his word has never failed me.
                                Custom script:   call ExSound_Play("Valeria_0015", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Set VariableSet ExSoundString = If you speak the truth — then take me to him. Now.
                                Custom script:   call ExSound_Play("Valeria_0019", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                Unit - Make Valeria face Nazgrek over 0.75 seconds
                                Set VariableSet ExSoundString = But know this, orc — I’ll be watching you.
                                Custom script:   call ExSound_Play("Valeria_0020", udg_ExSoundString)
                                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                                -------- ===================================== --------
                                -------- RUN / ENABLE / DISABLE TRIGGERS --------
                                Custom script:   call TriggerExecute(gg_trg_Quest_Ranger_Missing_Update)
                                -------- Set Valeria to follow Nazgrek --------
                                Custom script:   call TriggerExecute(gg_trg_Valeria_Add_Companion)
                                -------- ===================================== --------
                                -------- DEFAULT CAMERA --------
                                -------- ================================ --------
                                -------- DIALOG CAMERA == RESET --------
                                -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
                                Custom script:   call DialogCameraReset(Player(0), 2.0)
                                -------- ======== CINEMATIC ENDS ======== --------
                                Trigger - Run Cinematic OFF <gen> (checking conditions)
                                Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
                                -------- ===================================== --------
                                Skip remaining actions
                            Else - Actions
                    Else - Actions
        Custom script:   call EnableTrigger(gg_trg_Valeria_Negotiate_ValeriaDialog02)
