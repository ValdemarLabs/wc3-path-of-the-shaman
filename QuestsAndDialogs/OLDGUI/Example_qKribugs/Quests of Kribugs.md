Quests of Kribugs
    Events
        Player - Player 1 (Red) Selects a unit
    Conditions
        (Triggering unit) Equal to Kribugs
        KribugsTrade Equal to False
        (Distance between (Position of Kribugs) and (Position of Nazgrek)) Less than or equal to 500.00
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
        Trigger - Run Cinematic ON <gen> (checking conditions)
        Cinematic - Turn cinematic mode On for (All players)
        Cinematic - Fade out and back in over 1.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        -------- == PATROL == --------
        Trigger - Run Kribugs Movement Pause <gen> (checking conditions)
        Wait 0.25 seconds
        Unit - Make Kribugs face Nazgrek over 0.75 seconds
        Unit - Make Nazgrek face Kribugs over 0.75 seconds
        Wait 1.00 seconds
        -------- DIALOG CAMERA == START --------
        Set VariableSet DialogNPC = Kribugs
        -------- USAGE: call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck) --------
        -------- Typical values (no blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, false) --------
        -------- Typical values (blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, true) --------
        Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 850.0, 20.0, 345.0, 180.0, 10000.0, 75.0, 0.0, true)
        -------- ================================ --------
        Wait 1.00 seconds
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- NORMAL DIALOG --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsFarewellBoolean Equal to False
                        (QuestOgreSandwich is discovered) Equal to False
                    Then - Actions
                        -------- If the Player has previosly not declined the quest --------
                        Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play Nazgrek_Greet1 <gen> and display Hello..  Modify duration: Set to 1.00 seconds and Wait
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Welcome, welcome! K....  Modify duration: Set to 5.00 seconds and Wait
                        Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                        Wait 1.00 seconds
                    Else - Actions
                Set VariableSet KribugsRandomGreet = (Random integer number between 1 and 3)
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsRandomGreet Equal to 1
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Step right up! Don....  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsRandomGreet Equal to 2
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Shiny coin for shin....  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsRandomGreet Equal to 3
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display You want to trade?.  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                -------- ====================== --------
                -------- Run "Create Dialog" --------
                Trigger - Run Create KribugsDialog01 <gen> (checking conditions)
                Trigger - Turn on (This trigger)
                Skip remaining actions
            Else - Actions
