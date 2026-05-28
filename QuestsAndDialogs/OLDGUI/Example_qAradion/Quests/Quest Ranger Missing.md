Quest Ranger Missing
    Events
    Conditions
    Actions
        -------- RESET Quest, if previously done --------
        Quest - Mark QuestRangerMissing as Incomplete
        Quest - Mark QuestRangerMissingReq1 as Incomplete
        Wait Campaign quest delay game-time seconds
        Custom script:   call TriggerExecute(gg_trg_Quest_Ranger_Missing_Discover)
        Custom script:   call EnableTrigger(gg_trg_Quest_Ranger_Missing_Update)
        Unit - Remove Ghost from Valeria
        Trigger - Remove (This trigger) from the trigger queue
