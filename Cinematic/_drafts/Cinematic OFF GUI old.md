Cinematic OFF
    Events
    Conditions
    Actions
        Set VariableSet InCinematic = False
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IntroCinematic Equal to False
            Then - Actions
                -------- ====================UNIT LOCATIONS - RESTORE --------
                Custom script:   call CinematicMover_ReturnUnitsFromCinematic(udg_CinematicTriggerUnit)
            Else - Actions
        -------- ==== Return gaming mode START ==== --------
        Cinematic - Enable user control for (All players).
        Cinematic - Turn cinematic mode Off for (All players)
        Set VariableSet VarPoint = (Position of Nazgrek)
        Camera - Pan camera for Player 1 (Red) to VarPoint over 0.00 seconds
        Custom script:   call RemoveLocation(udg_VarPoint)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AlwaysFALSE Equal to True
            Then - Actions
                -------- ================== CAM --------
                Set VariableSet CameraPlayer = (Triggering player)
                -------- ENABLE - Isometric locked camera --------
                Set VariableSet CameraUnit = Nazgrek
                Custom script:   call FCL_Lock(udg_CameraUnit, udg_CameraPlayer)
                -------- ENABLE - Keyboard rotate / angle from arrows --------
                Set VariableSet Camera_KeyboardActions = True
                -------- DISABLE - 1st person camera --------
                Trigger - Run Disable 1st Person Camera <gen> (checking conditions)
                Custom script:   call ReleaseMovementUnit(udg_CameraPlayer)
                -------- ============ SET THE MODE --------
                Set VariableSet CameraModeNormal = True
                Set VariableSet CameraModeAdvanced = False
                Set VariableSet CameraModeDeveloper = False
                Wait 0.10 seconds
                -------- ================== CAM --------
            Else - Actions
        Selection - Select Nazgrek
        -------- Restore units --------
        Unit Group - Pick every unit in PlayerCinemaGroup and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Or - Any (Conditions) are true
                            Conditions
                                (Picked unit) Equal to Nazgrek
                                (Picked unit) Equal to Zulkis
                    Then - Actions
                        Unit - Change ownership of (Picked unit) to Player 1 (Red) and Retain color
                        Hero - Enable experience gain for (Picked unit).
                    Else - Actions
        -------- ==== Return gaming mode END ==== --------
        Unit Group - Pick every unit in CinematicPauseGroup and do (Actions)
            Loop - Actions
                Unit - Unpause (Picked unit)
        -------- Remove all units from CinematicHideGroup --------
        Unit Group - Remove all units from CinematicPauseGroup.
        Unit Group - Remove all units from CinematicUnpauseGroup.
        Unit Group - Remove all units from PlayerCinemaGroup.
        -------- ============= OTHER --------
        -------- Ability related --------
        Trigger - Run Cinematic Invisibility <gen> (checking conditions)
        -------- FLOATING TEXTs --------
        Trigger - Turn on Damage Tag <gen>
        Custom script:   call EnableTrigger(gg_trg_Floating_Texts_Spell_Event)
        Custom script:   call EnableTrigger(gg_trg_HealingDisplay)
        Custom script:   call EnableTrigger(gg_trg_RegenerationDisplay)
        Custom script:   call EnableTrigger(gg_trg_RegenerationDisplay)
        -------- =============  --------
        -------- Cinematic Panels --------
        Custom script:   call EnableCinematicMode(false)
        Cinematic - Turn off letterbox mode (show interface) for (All players): fade in over 2.00 seconds
        -------- CAMERA Z --------
        Camera - Set Player 1 (Red)'s camera Far Z to 20000.00 over 0.00 seconds
        -------- RESTORE CAMERA view and settings --------
        Trigger - Run Camera Restore Parameters <gen> (checking conditions)
        -------- ====================UNIT HIDER --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IntroCinematic Equal to False
            Then - Actions
                Custom script:   call UnitHider_SetSystemEnabled(true)
            Else - Actions
        -------- ====================---------------- --------
        -------- DynamicMinimap --------
        Custom script:   call DynamicMinimap_SetFullMapMode(false)
        -------- TasQuestBox --------
        Custom script:   call TasQuestBox_Unhide()
        -------- DynamicMinimap --------
        Trigger - Remove (This trigger) from the trigger queue
