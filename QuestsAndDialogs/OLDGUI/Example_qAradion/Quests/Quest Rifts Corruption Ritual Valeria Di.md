Quest Rifts Corruption Ritual Valeria Dies
    Events
        Unit - A unit Takes damage
    Conditions
        (Damage Target) Equal to Valeria
        (Damage taken) Greater than or equal to ((Life of Valeria) - 0.41)
    Actions
        Event Response - Set Damage of Unit Damaged Event to ((Life of Valeria) - 1.00)
        Unit - Make Valeria Invulnerable
        Unit - Change ownership of Valeria to Neutral Passive and Retain color
        Trigger - Turn off (This trigger)
        -------- Stop Timer(s) --------
        Countdown Timer - Pause QuestRiftsCorruptionTimerClose
        -------- Disable triggers --------
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_TimerText)
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Waves)
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Combat)
        -------- Run triggers --------
        -------- Chat --------
        -------- ===================================== --------
        Set VariableSet ExSoundString = Forgive me… my love... I… have failed… 
        Custom script:   call ExSound_Play("Valeria_0064", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Wait ExSoundDuration seconds
        Unit - Kill Valeria
        -------- ===================================== --------
        -------- Make Aradion run to Valeria --------
        Unit - Make Aradion Invulnerable
        Set VariableSet AradionPoint = (Position of Valeria)
        Unit - Order Aradion to Move To AradionPoint
        Custom script:   call RemoveLocation(udg_AradionPoint)
        -------- ===================================== --------
        Set VariableSet ExSoundString = Valeria!
        Custom script:   call ExSound_Play("Aradion_0079", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        -------- Start timer for Aradion to walk back to init location --------
        Countdown Timer - Start AradionTimer as a One-shot timer that will expire in 10.00 seconds
        -------- Set Valeria to respawn at Aradion --------
        -------- ===================================== --------
        -------- Run triggers --------
        Custom script:   call TriggerExecute(gg_trg_Valeria_Remove_Companion)
        Custom script:   call TriggerExecute(gg_trg_Aradion_Remove_Companion)
        -------- FAIL QUEST --------
        Quest - Mark QuestRiftsCorruption as Failed
        Quest - Display to (All players) the Quest Failed message: |cffffcc00QUEST|r  ...
        Quest - Display to (All players) the Quest Update message: Valeria has died
        Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_Fail)
