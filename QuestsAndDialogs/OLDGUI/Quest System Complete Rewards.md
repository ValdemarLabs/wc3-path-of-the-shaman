Quest System Complete Rewards
    Events
    Conditions
    Actions
        -------- DONT MODIFY --------
        -------- ======= ================================= ========================== --------
        -------- ======= REWARDS - XP --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardXP[QuestID_Temp] Greater than 0
            Then - Actions
                Custom script:   set bj_wantDestroyGroup = true
                Unit Group - Pick every unit in (Units owned by Player 1 (Red) matching (((Matching unit) is A Hero) Equal to True).) and do (Actions)
                    Loop - Actions
                        Hero - Add QuestRewardXP[QuestID_Temp] experience to (Picked unit), Show level-up graphics
                Unit Group - Pick every unit in Companion_Group and do (Actions)
                    Loop - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ((Picked unit) is A Hero) Equal to True
                            Then - Actions
                                Hero - Add QuestRewardXP[QuestID_Temp] experience to (Picked unit), Show level-up graphics
                            Else - Actions
            Else - Actions
        -------- ======= REWARDS - GOLD --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardGold[QuestID_Temp] Greater than 0
            Then - Actions
                Player - Add QuestRewardGold[QuestID_Temp] to Player 1 (Red).Current gold
            Else - Actions
        -------- ======= ================================= ========================== --------
        -------- ======= REWARDS - ARENA MARKS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardArena[QuestID_Temp] Greater than 0
            Then - Actions
                Player - Add QuestRewardArena[QuestID_Temp] to Player 1 (Red).Current lumber
            Else - Actions
        -------- ======= REWARDS - REPUTATION --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestFaction[QuestID_Temp] Not equal to <Empty String>
            Then - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardRepLinked[QuestID_Temp] Equal to True
                    Then - Actions
                        Custom script:   call AddReputationLinked(Player(0), udg_QuestFaction[udg_QuestID_Temp], udg_QuestRewardReputation[udg_QuestID_Temp])
                    Else - Actions
                        Custom script:   call AddReputation(Player(0), udg_QuestFaction[udg_QuestID_Temp], udg_QuestRewardReputation[udg_QuestID_Temp])
            Else - Actions
        -------- ======= REWARDS - ITEM --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                Hero - Create QuestRewardItem[QuestID_Temp] and give it to Nazgrek
            Else - Actions
        -------- ======= ================================= ========================== --------
