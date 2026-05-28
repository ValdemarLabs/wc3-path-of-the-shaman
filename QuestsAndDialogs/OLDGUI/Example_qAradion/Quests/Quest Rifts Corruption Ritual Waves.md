Quest Rifts Corruption Ritual Waves
    Events
        Time - Every 30.00 seconds of game time
    Conditions
    Actions
        -------- Create waves of Mana Wraith incoming to Aradion --------
        Set VariableSet VarPoint = (Position of QuestRiftCurrent)
        Set VariableSet QuestRiftsCorruptionWaveIndex = (QuestRiftsCorruptionWaveIndex + 1)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRiftsCorruptionWaveN Equal to 1
            Then - Actions
                Custom script:   set udg_QuestRiftsCorruptionWaves[udg_QuestRiftsCorruptionWaveIndex] = WavesRiftWraits_Wave1(Player(11), udg_VarPoint)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRiftsCorruptionWaveN Equal to 2
            Then - Actions
                Custom script:   set udg_QuestRiftsCorruptionWaves[udg_QuestRiftsCorruptionWaveIndex] = WavesRiftWraits_Wave2(Player(11), udg_VarPoint)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRiftsCorruptionWaveN Equal to 3
            Then - Actions
                Custom script:   set udg_QuestRiftsCorruptionWaves[udg_QuestRiftsCorruptionWaveIndex] = WavesRiftWraits_Wave3(Player(11), udg_VarPoint)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRiftsCorruptionWaveN Equal to 4
            Then - Actions
                Custom script:   set udg_QuestRiftsCorruptionWaves[udg_QuestRiftsCorruptionWaveIndex] = WavesRiftWraits_Wave4(Player(11), udg_VarPoint)
            Else - Actions
        Custom script:   call RemoveLocation(udg_VarPoint)
        -------- Set next wave be random --------
        Set VariableSet QuestRiftsCorruptionWaveN = (Random integer number between 1 and 4)
        Wait 1.00 seconds
        -------- Run Chat CombatIncoming --------
        Custom script:   call TriggerExecute(gg_trg_Quest_Rifts_Corruption_Ritual_CombatIncoming)
