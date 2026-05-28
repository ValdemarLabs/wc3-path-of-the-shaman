Quest System Complete
    Events
    Conditions
    Actions
        -------- DONT MODIFY --------
        -------- Display a quest message. --------
        Custom script:   set udg_QuestTempString = "|cffffcc00QUEST COMPLETED|r\n" + udg_QuestTitle[udg_QuestID_Temp]
        Quest - Display to (All players) the Quest Completed message: QuestTempString
        Set VariableSet QuestTempString = (QuestRewardsTextHeading[QuestID_Temp] + QuestRewardsText[QuestID_Temp])
        Quest - Display to (All players) the Quest Completed message: QuestTempString
        Quest - Flash the quest dialog button
