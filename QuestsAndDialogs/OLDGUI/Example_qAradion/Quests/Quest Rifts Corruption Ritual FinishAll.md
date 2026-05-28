Quest Rifts Corruption Ritual FinishAll
    Events
    Conditions
    Actions
        -------- Disable --------
        Custom script:   call DisableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Prepare)
        -------- =============== ALL RIFT CLOSED --------
        -------- ===================================== --------
        Set VariableSet ExSoundString = I think this was last of them. All rifts should now be closed.
        Custom script:   call ExSound_Play("Aradion_0084", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet ExSoundString = So, is it… over now? Is this the answer to our people’s curse?
        Custom script:   call ExSound_Play("Valeria_0070", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet ExSoundString = In time, we will see… It’s time to head back to our place. 
        Custom script:   call ExSound_Play("Aradion_0085", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet ExSoundString = Gladly.
        Custom script:   call ExSound_Play("Valeria_0071", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        -------- QUEST UPDATE --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_UpdateLast)
        -------- QUEST ENABLE COMPLETION --------
        Custom script:   call EnableTrigger(gg_trg_Quest_Rifts_Corruption_Completion)
