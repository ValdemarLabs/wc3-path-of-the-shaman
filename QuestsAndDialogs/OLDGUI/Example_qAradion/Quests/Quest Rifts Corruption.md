Quest Rifts Corruption
    Events
    Conditions
    Actions
        -------- Register rifts --------
        Set VariableSet QuestRifts[1] = Mana Rift 0971 <gen>
        Set VariableSet QuestRifts[2] = Mana Rift 1093 <gen>
        Set VariableSet QuestRifts[3] = Mana Rift 1092 <gen>
        Custom script:   call TriggerExecute(gg_trg_WithinRange_Register_Mana_Rift)
        -------- RESET Quest, if previously done --------
        Quest - Mark QuestRiftsCorruption as Incomplete
        Quest - Mark QuestRiftsCorruptionReq1 as Incomplete
        Quest - Mark QuestRiftsCorruptionReq2 as Incomplete
        Quest - Mark QuestRiftsCorruptionReq3 as Incomplete
        Wait Campaign quest delay game-time seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_Discover)
        -------- Enable FAIL Conditions --------
        Custom script:   call EnableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Valeria_Dies)
        Custom script:   call EnableTrigger(gg_trg_Quest_Rifts_Corruption_Ritual_Aradion_Dies)
        -------- Set Valeria to follow Nazgrek --------
        Custom script:   call TriggerExecute(gg_trg_Valeria_Add_Companion)
        -------- Set Aradion to follow Nazgrek --------
        Custom script:   call TriggerExecute(gg_trg_Aradion_Add_Companion)
        -------- ===================================== --------
        Set VariableSet ExSoundString = Let’s go and search one of those rifts.
        Custom script:   call ExSound_Play("Aradion_0081", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Set VariableSet ExSoundString = Beware the wraiths we may encounter… they can be damaged only by magic and spells.
        Custom script:   call ExSound_Play("Valeria_0067", udg_ExSoundString)
        Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
        -------- ===================================== --------
        Trigger - Remove (This trigger) from the trigger queue
