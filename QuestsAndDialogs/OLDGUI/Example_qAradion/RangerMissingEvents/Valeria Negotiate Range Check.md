Valeria Negotiate Range Check
    Events
        Time - Every 2.00 seconds of game time
    Conditions
    Actions
        Set VariableSet DistanceCheckPoint1 = (Position of Nazgrek)
        Set VariableSet DistanceCheckPoint2 = (Position of Valeria)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Distance between DistanceCheckPoint1 and DistanceCheckPoint2) Greater than 1750.00
            Then - Actions
                Trigger - Turn off (This trigger)
                Set VariableSet ValeriaEncounterReset = True
                Unit - Order Valeria to Stop.
                Unit - Set Valeria movement speed to 420.00
                Unit - Set Unit: Valeria's Real Field: Hit Points Regeneration Rate ('uhpr') to Value: 2.00
                Unit - Set life of Valeria to 100.00%
                Unit - Change ownership of Valeria to Neutral Passive and Retain color
                -------- ======= Hint --------
                Game - Display to (All players) the text: |cffd45e19You've lo...
                Set VariableSet ValeriaPoint = (Center of ValeriaAmbushPos <gen>)
                Unit - Order Valeria to Move To ValeriaPoint
                Custom script:   call RemoveLocation(udg_ValeriaPoint)
                -------- ==================== --------
                Custom script:   call EnableTrigger(gg_trg_Valeria_First_Encounter)
                Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_ValeriaDialog02)
                Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Random_Movement)
                Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Dies)
            Else - Actions
        Custom script:   call RemoveLocation(udg_DistanceCheckPoint1)
        Custom script:   call RemoveLocation(udg_DistanceCheckPoint2)
