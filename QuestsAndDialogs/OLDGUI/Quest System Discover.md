Quest System Discover
    Events
    Conditions
    Actions
        -------- DONT MODIFY --------
        -------- Adjust requirements texts in Quest Dicovered Message (will not be if specific requirement is empty) --------
        Custom script:   set udg_QuestTempString = "|cffffcc00QUEST|r\n" + udg_QuestTitle[udg_QuestID_Temp] + "\n\n"
        -------- REQUIREMENT 1 --------
        Custom script:   if udg_QuestRequirement1[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement1[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 2 --------
        Custom script:   if udg_QuestRequirement2[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement2[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 3 --------
        Custom script:   if udg_QuestRequirement3[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement3[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 4 --------
        Custom script:   if udg_QuestRequirement4[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement4[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 5 --------
        Custom script:   if udg_QuestRequirement5[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement5[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 6 --------
        Custom script:   if udg_QuestRequirement6[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement6[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 7 --------
        Custom script:   if udg_QuestRequirement7[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement7[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- REQUIREMENT 8 --------
        Custom script:   if udg_QuestRequirement8[udg_QuestID_Temp] != "" then
        Custom script:   set udg_QuestTempString = udg_QuestTempString + "- " + udg_QuestRequirement8[udg_QuestID_Temp] + "\n"
        Custom script:   endif
        -------- Display a quest message. --------
        Quest - Display to (All players) the Quest Discovered message: QuestTempString
        Quest - Flash the quest dialog button
