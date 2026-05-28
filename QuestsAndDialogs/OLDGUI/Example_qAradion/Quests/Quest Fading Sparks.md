Quest Fading Sparks
    Events
    Conditions
    Actions
        -------- RESET Quest, if previously done --------
        Quest - Mark QuestFadingSparks as Incomplete
        Quest - Mark QuestFadingSparksReq1 as Incomplete
        Quest - Mark QuestFadingSparksReq2 as Incomplete
        Wait Campaign quest delay game-time seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Fading_Sparks_Discover)
        Custom script:   call EnableTrigger(gg_trg_Quest_Fading_Sparks_Update)
        Item - Create |cffffff00Tel’anor Rod|r at (Position of Nazgrek)
        Trigger - Remove (This trigger) from the trigger queue
