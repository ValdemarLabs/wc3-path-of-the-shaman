Quest Crystals Hope
    Events
    Conditions
    Actions
        -------- RESET Quest, if previously done --------
        Quest - Mark QuestCrystalsHope as Incomplete
        Quest - Mark QuestCrystalsHopeReq1 as Incomplete
        Quest - Mark QuestCrystalsHopeReq2 as Incomplete
        Wait Campaign quest delay game-time seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Crystals_Hope_Discover)
        Custom script:   call EnableTrigger(gg_trg_Quest_Crystals_Hope_Update)
        Trigger - Remove (This trigger) from the trigger queue
