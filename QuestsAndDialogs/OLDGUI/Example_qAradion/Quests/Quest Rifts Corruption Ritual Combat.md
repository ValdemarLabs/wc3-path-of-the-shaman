Quest Rifts Corruption Ritual Combat
    Events
        Time - Every 40.00 seconds of game time
    Conditions
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
        -------- COMBAT --------
        Set VariableSet AradionRandomGreet = (Random integer number between 1 and 3)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionRandomGreet Equal to 1
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = Hold them back! Just a little longer!
                Custom script:   call ExSound_Play("Aradion_0076", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionRandomGreet Equal to 2
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = The rift is still open — I need more time!
                Custom script:   call ExSound_Play("Aradion_0077", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionRandomGreet Equal to 3
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = Try to keep them away from me! 
                Custom script:   call ExSound_Play("Aradion_0078", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
