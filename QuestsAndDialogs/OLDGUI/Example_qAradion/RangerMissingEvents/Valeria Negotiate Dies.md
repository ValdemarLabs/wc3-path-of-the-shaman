Valeria Negotiate Dies
    Events
        Unit - A unit Dies
    Conditions
        (Triggering unit) Equal to Valeria
    Actions
        Unit - Change ownership of (Triggering unit) to Neutral Passive and Retain color
        -------- ==================== --------
        Set VariableSet ValeriaEncounterReset = True
        -------- RUN / ENABLE / DISABLE TRIGGERS --------
        Custom script:   call EnableTrigger(gg_trg_Valeria_First_Encounter)
        Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_ValeriaDialog02)
        Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Random_Movement)
        Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Dies)
        Custom script:   call DisableTrigger(gg_trg_Valeria_Negotiate_Range_Check)
        -------- Fail the quest --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Ranger_Missing_Failed)
