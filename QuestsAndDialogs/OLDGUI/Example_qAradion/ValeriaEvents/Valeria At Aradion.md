Valeria At Aradion
    Events
        Unit - A unit enters ValeriaAtAradion <gen>
    Conditions
        (Triggering unit) Equal to Valeria
    Actions
        Wait 3.00 seconds
        -------- ======== Initial check of the selected unit ======== --------
        Set VariableSet CV = (Custom value of Valeria)
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
        -------- Make Valeria face other than building... --------
        Unit - Make Valeria face 257.00 over 0.50 seconds
