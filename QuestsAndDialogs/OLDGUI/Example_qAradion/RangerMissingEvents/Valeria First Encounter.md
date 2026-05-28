Valeria First Encounter
    Events
        Game - WithinRangeEvent becomes Equal to 1.00
    Conditions
        WithinRangeUnit Equal to Valeria
        (Owner of WithinRangeEnteringUnit) Equal to Player 1 (Red)
        (QuestRangerMissing is discovered) Equal to True
        (QuestRangerMissing is failed) Equal to False
    Actions
        Trigger - Turn off (This trigger)
        -------- ======== CINEMATIC STARTS ======== --------
        Trigger - Run Cinematic ON <gen> (checking conditions)
        Cinematic - Turn cinematic mode On for (All players)
        Cinematic - Fade out and back in over 1.00 seconds using texture Black Mask and color (0.00%, 0.00%, 0.00%) with 0.00% transparency
        -------- ======== Init values ======== --------
        Unit - Set Valeria movement speed to (Default movement speed of Valeria)
        Wait 0.25 seconds
        Unit - Make Valeria face Nazgrek over 0.75 seconds
        Unit - Make Nazgrek face Valeria over 0.75 seconds
        Wait 1.00 seconds
        -------- DIALOG CAMERA == START --------
        Set VariableSet DialogNPC = Valeria
        -------- USAGE: call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck) --------
        -------- Typical values (no blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1200.0, 0.0, 0.0, 0.0, 10000.0, 75.0, 0.0, false) --------
        -------- Typical values (blocking): call DialogCameraStart(Player(0), udg_DialogNPC, 1000.0, 0.0, 0.0, 0.0, 10000.0, 70.0, 0.0, true) --------
        Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 750.0, 50.0, 355.0, 180.0, 10000.0, 70.0, 0.0, true)
        -------- ================================ --------
        Wait 1.00 seconds
        -------- Start "ambush" by Valeria --------
        -------- ===================================== --------
        Animation - Play Valeria's Stand Ready animation
        -------- ===================================== --------
        Set VariableSet ExSoundString = Hold, intruder! Another step and you bleed where you stand!
        Custom script:   call ExSound_Play("Valeria_0001", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet ExSoundString = You must be Valeria.
        Custom script:   call ExSound_Play("Nazgrek_0340", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet DialogNPC = Nazgrek
        Custom script:   call DialogCameraStart(Player(0), udg_DialogNPC, 750.0, 50.0, 355.0, 45.0, 10000.0, 60.0, 0.0, true)
        -------- ===================================== --------
        Set VariableSet ExSoundString = I am not your enemy…
        Custom script:   call ExSound_Play("Nazgrek_0341", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet VarPoint = (Position of Nazgrek)
        Set VariableSet ValeriaPoint = (VarPoint offset by -400.00 towards (Facing of Nazgrek) degrees.)
        Unit - Order Valeria to Move To ValeriaPoint
        Custom script:   call RemoveLocation(udg_VarPoint)
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        Wait 1.50 seconds
        Unit - Order Valeria to Stop.
        Animation - Play Valeria's Stand Ready animation
        Wait 1.00 seconds
        -------- ===================================== --------
        Set VariableSet ExSoundString = Filthy orc lies! I’ll drop you down where you stand!
        Custom script:   call ExSound_Play("Valeria_0002", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Animation - Reset Valeria's animation
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
        -------- Start fight --------
        Set VariableSet ValeriaEncounterReset = False
        Set VariableSet ValeriaPoint = (Position of Nazgrek)
        Unit - Change ownership of Valeria to Player 12 (Brown) and Retain color
        Unit - Order Valeria to Attack-Move To ValeriaPoint
        Unit - Set Unit: Valeria's Real Field: Hit Points Regeneration Rate ('uhpr') to Value: 200.00
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        -------- ===================================== --------
        -------- Run / enable  necessary triggers --------
        Custom script:   call TriggerExecute(gg_trg_Valeria_Negotiate_Lines_Nazgrek)
        Custom script:   call EnableTrigger(gg_trg_Valeria_Negotiate_ValeriaDialog02)
        Custom script:   call EnableTrigger(gg_trg_Valeria_Negotiate_Random_Movement)
        Custom script:   call EnableTrigger(gg_trg_Valeria_Negotiate_Range_Check)
        Custom script:   call EnableTrigger(gg_trg_Valeria_Negotiate_Dies)
        Wait 2.00 seconds
        -------- ======= Hint --------
        Game - Display to (All players) the text: |cffd45e19Press ESC...
