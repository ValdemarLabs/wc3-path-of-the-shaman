Quest Rifts Corruption Fail
    Events
    Conditions
    Actions
        -------- Remove Aradion and Valeria from Companions group --------
        -------- Init locations of Aradion and Valeria --------
        -------- Order survived unit (Aradion or Valeria) to move to their init place before the quest --------
        -------- RESTORE and REGISTER Mana Rifts units --------
        -------- RIFT 1 --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRifts[1] is alive) Equal to False
            Then - Actions
                Set VariableSet VarPoint = (Center of ManaRift1 <gen>)
                Unit - Create 1 Mana Rift for Neutral Passive at VarPoint facing Default building facing degrees
                Set VariableSet QuestRifts[1] = (Last created unit)
                Custom script:   call RemoveLocation(udg_VarPoint)
            Else - Actions
        -------- RIFT 2 --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRifts[2] is alive) Equal to False
            Then - Actions
                Set VariableSet VarPoint = (Center of ManaRift2 <gen>)
                Unit - Create 1 Mana Rift for Neutral Passive at VarPoint facing Default building facing degrees
                Set VariableSet QuestRifts[2] = (Last created unit)
                Custom script:   call RemoveLocation(udg_VarPoint)
            Else - Actions
        -------- RIFT 3 --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRifts[3] is alive) Equal to False
            Then - Actions
                Set VariableSet VarPoint = (Center of ManaRift3 <gen>)
                Unit - Create 1 Mana Rift for Neutral Passive at VarPoint facing Default building facing degrees
                Set VariableSet QuestRifts[3] = (Last created unit)
                Custom script:   call RemoveLocation(udg_VarPoint)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        (QuestRifts[1] is alive) Equal to False
                        (QuestRifts[2] is alive) Equal to False
                        (QuestRifts[3] is alive) Equal to False
            Then - Actions
                Custom script:   call TriggerExecute(gg_trg_WithinRange_Register_Mana_Rift)
            Else - Actions
