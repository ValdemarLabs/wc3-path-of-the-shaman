Quest Rifts Corruption Ritual Aradion Dies
    Events
        Unit - A unit Takes damage
    Conditions
        (Damage Target) Equal to Aradion
        (Damage taken) Greater than or equal to ((Life of Aradion) - 0.41)
    Actions
        Event Response - Set Damage of Unit Damaged Event to ((Life of Aradion) - 1.00)
        Unit - Make Aradion Invulnerable
        Unit - Change ownership of Aradion to Neutral Passive and Retain color
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
        Set VariableSet ExSoundString = The current was… too strong… I…
        Custom script:   call ExSound_Play("Aradion_0086", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Don't wait
        -------- ===================================== --------
        Wait ExSoundDuration seconds
        Unit - Kill Aradion
        -------- ===================================== --------
        -------- Make Valeria run to Aradion --------
        Unit - Make Valeria Invulnerable
        Set VariableSet ValeriaPoint = (Position of Aradion)
        Unit - Order Valeria to Move To ValeriaPoint
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        -------- ===================================== --------
        Set VariableSet ExSoundString = Aradion…? No!!!
        Custom script:   call ExSound_Play("Valeria_0063", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Don't wait
        -------- ===================================== --------
        -------- Start timer for Valeria to walk back to init location --------
        Countdown Timer - Start ValeriaTimer as a One-shot timer that will expire in 10.00 seconds
        -------- Set Aradion to respawn at Valeria --------
        -------- ===================================== --------
        -------- Run triggers --------
        Custom script:   call TriggerExecute(gg_trg_Aradion_Remove_Companion)
        Custom script:   call TriggerExecute(gg_trg_Valeria_Remove_Companion)
        -------- FAIL QUEST --------
        Quest - Mark QuestRiftsCorruption as Failed
        Quest - Display to (All players) the Quest Failed message: |cffffcc00QUEST|r  ...
        Quest - Display to (All players) the Quest Update message: Aradion has died
