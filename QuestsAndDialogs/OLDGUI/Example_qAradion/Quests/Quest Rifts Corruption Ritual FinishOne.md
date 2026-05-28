Quest Rifts Corruption Ritual FinishOne
    Events
        Time - QuestRiftsCorruptionTimerClose expires
    Conditions
    Actions
        -------- =============== Kill Wave units --------
        Custom script:   local integer i = 1
        Custom script:   loop
        Custom script:   exitwhen i > udg_QuestRiftsCorruptionWaveIndex
        Custom script:   call Wave(udg_QuestRiftsCorruptionWaves[i]).killAllUnits()
        Custom script:   call Wave(udg_QuestRiftsCorruptionWaves[i]).destroy()
        Custom script:   set i = i + 1
        Custom script:   endloop
        Set VariableSet QuestRiftsCorruptionWaveIndex = 0
        -------- =============== Disable triggers --------
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_TimerText)
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Waves)
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Combat)
        -------- =============== Stop Aradion channeling --------
        Unit - Remove ClosePortal2 (Aradion) from Aradion
        Unit - Order Aradion to Stop.
        -------- =============== Effect --------
        Set VariableSet VarPoint = (Position of QuestRiftCurrent)
        Sound - Play RfitDeath <gen> at 100.00% volume, attached to QuestRiftCurrent
        Special Effect - Create a special effect at VarPoint using Objects\Spawnmodels\NightElf\NECancelDeath\NECancelDeath.mdl
        Special Effect - Destroy (Last created special effect)
        Custom script:   call RemoveLocation(udg_VarPoint)
        -------- =============== Kill Mana Rift unit --------
        Unit - Kill QuestRiftCurrent
        -------- =============== RIFT CLOSED --------
        Custom script:   call TriggerExecute(gg_trg_Aradion_Add_Companion)
        -------- ARADION CHAT --------
        Set VariableSet CV = (Custom value of Aradion)
        Set VariableSet AradionRandomGreet = (Random integer number between 1 and 2)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[CV] Equal to True
                AradionRandomGreet Equal to 1
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = It is done. This rift is sealed.
                Custom script:   call ExSound_Play("Aradion_0080", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionRandomGreet Equal to 2
                IsUnitAlive[CV] Equal to True
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = I managed to close this rift.
                Custom script:   call ExSound_Play("Aradion_0082", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        -------- VALERIA CHAT --------
        Set VariableSet CV = (Custom value of Valeria)
        Set VariableSet ValeriaRandomGreet = (Random integer number between 1 and 2)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 1
                IsUnitAlive[CV] Equal to True
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = Great job, my love!
                Custom script:   call ExSound_Play("Valeria_0066", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ValeriaRandomGreet Equal to 2
                IsUnitAlive[CV] Equal to True
            Then - Actions
                -------- ===================================== --------
                Set VariableSet ExSoundString = You never cease to amaze me, my love.
                Custom script:   call ExSound_Play("Valeria_0068", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
            Else - Actions
        -------- QUEST UPDATE --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_Update)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRiftsCorruptionCounter Greater than or equal to 3
            Then - Actions
                -------- ALL RIFTS CLOSED --------
                Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_Ritual_FinishAll)
                Skip remaining actions
            Else - Actions
        -------- AFTER CHAT --------
        Set VariableSet CV = (Custom value of Aradion)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[CV] Equal to False
            Then - Actions
                -------- ======== Cinematic / dialogue cannot be started because of the conditions ======== --------
                Skip remaining actions
                -------- ======== ======== --------
            Else - Actions
        -------- ===================================== --------
        Set VariableSet ExSoundString = Let’s head to the next one. Be on your guard.
        Custom script:   call ExSound_Play("Aradion_0083", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet ExSoundString = Don’t worry my love, we will be.
        Custom script:   call ExSound_Play("Valeria_0069", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Custom script:   call EnableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Prepare)
