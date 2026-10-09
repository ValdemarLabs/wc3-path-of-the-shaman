Cinematic ON
    Events
    Conditions
    Actions
        -------- DynamicMinimap --------
        Custom script:   call DynamicMinimap_SetFullMapMode(true)
        -------- DynamicMinimap --------
        -------- TasQuestBox --------
        Custom script:   call TasQuestBox_Hide()
        -------- TasQuestBox --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AlwaysFALSE Equal to True
            Then - Actions
                -------- ================== CAM --------
                -------- //// = Normal camera view --------
                -------- Add additional boolean condition for DeveloperEnabled = TRUE --------
                Set VariableSet CameraPlayer = Player 1 (Red)
                -------- DISABLE - Isometric locked camera --------
                Custom script:   call FCL_Release(udg_CameraPlayer)
                -------- DISABLE - Keyboard rotate / angle from arrows --------
                Set VariableSet Camera_KeyboardActions = False
                -------- DISABLE - 1st person camera --------
                Trigger - Run Disable 1st Person Camera <gen> (checking conditions)
                Custom script:   call ReleaseMovementUnit(udg_CameraPlayer)
                -------- ============ SET THE MODE --------
                Set VariableSet CameraModeNormal = False
                Set VariableSet CameraModeAdvanced = False
                Set VariableSet CameraModeDeveloper = True
                -------- ================== CAM --------
            Else - Actions
        -------- ===================== --------
        Set VariableSet InCinematic = True
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IntroCinematic Equal to False
            Then - Actions
                -------- ====================UNIT LOCATIONS - STORE --------
                Custom script:   call CinematicMover_MoveUnitsToCinematic(udg_CinematicTriggerUnit, udg_CinematicMoveMode)
            Else - Actions
        -------- ====================UNIT HIDER --------
        -------- RUN THIS before Cinematic / etc. --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IntroCinematic Equal to False
            Then - Actions
                Custom script:   call UnitHider_SetSystemEnabled(false)
            Else - Actions
        -------- Pick player units --------
        Set VariableSet PlayerCinemaGroup = (Units owned by Player 1 (Red).)
        Unit Group - Pick every unit in PlayerCinemaGroup and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Unit-type of (Picked unit)) Not equal to Stash
                        (Unit-type of (Picked unit)) Not equal to Bag
                        (Unit-type of (Picked unit)) Not equal to Companions
                        (Unit-type of (Picked unit)) Not equal to Stats
                        (Unit-type of (Picked unit)) Not equal to Reputations
                    Then - Actions
                        Unit - Change ownership of (Picked unit) to Player 22 (Snow) and Retain color
                    Else - Actions
        -------- Pick all units within range of Nazgrek that WILL NOT BE PAUSED --------
        Set VariableSet VarPoint = (Position of Nazgrek)
        Unit Group - Pick every unit in (Units within 5000.00 of VarPoint.) and do (Actions)
            Loop - Actions
                Unit Group - Add (Picked unit) to CinematicUnpauseGroup
        Custom script:   call RemoveLocation(udg_VarPoint)
        -------- Pick all units that WILL BE PAUSED --------
        -------- Pause all CinematicGroup units --------
        Unit Group - Pick every unit in (Units in (Playable map area)) and do (Actions)
            Loop - Actions
                Unit - Pause (Picked unit)
                Unit Group - Add (Picked unit) to CinematicPauseGroup
        Unit Group - Pick every unit in CinematicUnpauseGroup and do (Actions)
            Loop - Actions
                Unit - Unpause (Picked unit)
        Unit Group - Pick every unit in PlayerCinemaGroup and do (Actions)
            Loop - Actions
                Unit - Unpause (Picked unit)
                Hero - Disable experience gain for (Picked unit).
        -------- ============= OTHER --------
        -------- Ability related --------
        Trigger - Run Cinematic Invisibility <gen> (checking conditions)
        -------- FLOATING TEXTs --------
        Trigger - Turn off Damage Tag <gen>
        Custom script:   call DisableTrigger(gg_trg_Floating_Texts_Spell_Event)
        Custom script:   call DisableTrigger(gg_trg_HealingDisplay)
        Custom script:   call DisableTrigger(gg_trg_RegenerationDisplay)
        Custom script:   call DisableTrigger(gg_trg_RegenerationDisplay)
        -------- =============  --------
        -------- CAMERA Z --------
        Camera - Set Player 1 (Red)'s camera Far Z to 20000.00 over 0.00 seconds
        -------- Cinematic Panels --------
        Custom script:   call EnableCinematicMode(true)
        Cinematic - Turn on letterbox mode (hide interface) for (All players): fade out over 2.00 seconds
        -------- ====================---------------- --------
        Trigger - Remove (This trigger) from the trigger queue
