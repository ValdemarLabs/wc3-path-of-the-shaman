Quest Rifts Corruption Ritual CombatIncoming
    Events
    Conditions
    Actions
        Set VariableSet CV = (Custom value of Valeria)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[CV] Equal to False
            Then - Actions
                -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                Skip remaining actions
                -------- ======== ======== --------
            Else - Actions
        -------- WRATHS INCOMING --------
        Set VariableSet ValeriaRandomGreet = (Random integer number between 1 and 3)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 1
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = Hold your ground! Don’t let them reach Aradion!
                Custom script:   call ExSound_Play("Valeria_0061", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 2
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = The rift is pulling every wrath towards it — brace yourself!
                Custom script:   call ExSound_Play("Valeria_0062", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 3
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = They are too many! Drive them back!
                Custom script:   call ExSound_Play("Valeria_0065", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
