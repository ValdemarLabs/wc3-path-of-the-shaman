Quest System Create
    Events
    Conditions
    Actions
        -------- DONT MODIFY --------
        -------- ======= ================================= ========================== --------
        -------- ======= QUEST ID Creation --------
        -------- ======= Define level of quest and level of the quest giver --------
        Set VariableSet QuestLevel[QuestID] = QuestLevelTemp
        Set VariableSet QuestGiverLevel[QuestID] = QuestGiverLevelTemp
        Set VariableSet QuestGiverUnit[QuestID] = QuestGiverUnitTemp
        -------- ======= FACTION --------
        Set VariableSet QuestFaction[QuestID] = QuestFactionTemp
        -------- ======= REWARDS - XP --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardXPActive Equal to True
            Then - Actions
                Set VariableSet QuestRewardXP_Multiplier[QuestID] = QuestRewardXP_MultiplierDef
                Set VariableSet QuestRewardXP_Adjust[QuestID] = QuestRewardXP_AdjustTemp
                Set VariableSet QuestRewardXP[QuestID] = ((QuestLevel[QuestID] x (Integer(QuestRewardXP_Multiplier[QuestID]))) + QuestRewardXP_Adjust[QuestID])
                Set VariableSet QuestRewardXP_Text[QuestID] = (|cff8080ffXP: |r + (String(QuestRewardXP[QuestID])))
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardXP[QuestID] Less than 0
                    Then - Actions
                        -------- ======= check and prevent negative value --------
                        Set VariableSet QuestRewardXP[QuestID] = 0
                    Else - Actions
            Else - Actions
                -------- ======= REWARD NOT ACTIVE --------
                Set VariableSet QuestRewardXP[QuestID] = 0
                Set VariableSet QuestRewardXP_Text[QuestID] = <Empty String>
        -------- ======= REWARDS - GOLD --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardGoldActive Equal to True
            Then - Actions
                Set VariableSet QuestRewardGold_Multiplier[QuestID] = QuestRewardGold_MultiplierDef
                Set VariableSet QuestRewardGold_Adjust[QuestID] = QuestRewardGold_AdjustTemp
                Set VariableSet QuestRewardGold[QuestID] = ((QuestLevel[QuestID] x (Integer(QuestRewardGold_Multiplier[QuestID]))) + QuestRewardGold_Adjust[QuestID])
                Set VariableSet QuestRewardGold_Text[QuestID] = (|cffffff00Gold: |r + (String(QuestRewardGold[QuestID])))
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardGold[QuestID] Less than 0
                    Then - Actions
                        -------- ======= check and prevent negative value --------
                        Set VariableSet QuestRewardGold[QuestID] = 0
                    Else - Actions
            Else - Actions
                -------- ======= REWARD NOT ACTIVE --------
                Set VariableSet QuestRewardGold[QuestID] = 0
                Set VariableSet QuestRewardGold_Text[QuestID] = <Empty String>
        -------- ======= REWARDS - ARENA MARKS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardArenaActive Equal to True
            Then - Actions
                Set VariableSet QuestRewardArena_Multiplier[QuestID] = QuestRewardArena_MultiplierDef
                Set VariableSet QuestRewardArena_Adjust[QuestID] = QuestRewardArena_AdjustTemp
                Set VariableSet QuestRewardArena[QuestID] = ((QuestLevel[QuestID] x (Integer(QuestRewardArena_Multiplier[QuestID]))) + QuestRewardArena_Adjust[QuestID])
                Set VariableSet QuestRewardArena_Text[QuestID] = (|cffff0000Arena Marks: |r + (String(QuestRewardArena[QuestID])))
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardArena[QuestID] Less than 0
                    Then - Actions
                        -------- ======= check and prevent negative value --------
                        Set VariableSet QuestRewardArena[QuestID] = 0
                    Else - Actions
            Else - Actions
                -------- ======= REWARD NOT ACTIVE --------
                Set VariableSet QuestRewardArena[QuestID] = 0
                Set VariableSet QuestRewardArena_Text[QuestID] = <Empty String>
        -------- ======= REWARDS - REPUTATION --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardRepActive Equal to True
            Then - Actions
                Set VariableSet QuestRewardRep_Multiplier[QuestID] = QuestRewardRep_MultiplierDef
                Set VariableSet QuestRewardRep_Adjust[QuestID] = QuestRewardRep_AdjustTemp
                Set VariableSet QuestRewardRepLinked[QuestID] = QuestRewardRepLinkedTemp
                Set VariableSet QuestRewardReputation[QuestID] = ((Integer(QuestRewardRep_Multiplier[QuestID])) x QuestRewardRep_Adjust[QuestID])
                Set VariableSet QuestRewardReputation_Text[QuestID] = (|cff8080ffReputation: |r + (String(QuestRewardReputation[QuestID])))
                Set VariableSet QuestRewardReputation_Text[QuestID] = (|cff8080ffReputation: |r + ((String(QuestRewardReputation[QuestID])) + ( [ + (QuestFaction[QuestID] + ]))))
            Else - Actions
                -------- ======= REWARD NOT ACTIVE --------
                Set VariableSet QuestRewardReputation[QuestID] = 0
                Set VariableSet QuestRewardReputation_Text[QuestID] = <Empty String>
        -------- ======= REWARDS - ITEM --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRewardItemActive Equal to True
            Then - Actions
                Set VariableSet QuestRewardItem[QuestID] = QuestRewardItemTemp
                -------- Create temp item to get the name of QuestRewadItem type --------
                Set VariableSet QuestRewardItemLoc = (Center of (Playable map area))
                Item - Create QuestRewardItem[QuestID] at QuestRewardItemLoc
                Set VariableSet QuestRewardItem_TextTemp = (Name of (Last created item))
                Item - Remove (Last created item)
                Custom script:   call RemoveLocation(udg_QuestRewardItemLoc)
                -------- Set the name of the Quest reward item --------
                Set VariableSet QuestRewardItem_Text[QuestID] = (|cff00ffffItem: |r + QuestRewardItem_TextTemp)
            Else - Actions
                -------- ======= REWARD NOT ACTIVE --------
                Set VariableSet QuestRewardItem[QuestID] = (Item-type of No item)
                Set VariableSet QuestRewardItem_Text[QuestID] = <Empty String>
        -------- ======= KILLS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestKillsActive Equal to True
            Then - Actions
                Set VariableSet QuestKillsReq[QuestID] = QuestKillsReqTemp
                Set VariableSet QuestKillsType[QuestID] = QuestKillsTypeTemp
            Else - Actions
                -------- ======= NOT ACTIVE --------
        -------- ======= GATHER --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestItemsActive Equal to True
            Then - Actions
                Set VariableSet QuestItemsReq[QuestID] = QuestItemsReqTemp
                Set VariableSet QuestItemsType[QuestID] = QuestItemsTypeTemp
                -------- Create temp item to get the name of Item type --------
                Set VariableSet QuestRewardItemLoc = (Center of (Playable map area))
                Item - Create QuestItemsType[QuestID] at QuestRewardItemLoc
                Set VariableSet QuestRewardItem_TextTemp = (Name of (Last created item))
                Item - Remove (Last created item)
                Custom script:   call RemoveLocation(udg_QuestRewardItemLoc)
                -------- Set the name of the item type --------
                Set VariableSet QuestItemsTypeText[QuestID] = QuestRewardItem_TextTemp
            Else - Actions
                -------- ======= NOT ACTIVE --------
        -------- ======= TEXTS --------
        Set VariableSet QuestTitle[QuestID] = QuestTitleTemp
        Set VariableSet QuestIconPath[QuestID] = QuestIconPathTemp
        Set VariableSet QuestDescription[QuestID] = QuestDescriptionTemp
        Set VariableSet QuestInfo[QuestID] = QuestInfoTemp
        Set VariableSet QuestInfo2[QuestID] = QuestInfo2Temp
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        QuestRewardXPActive Equal to True
                        QuestRewardGoldActive Equal to True
                        QuestRewardArenaActive Equal to True
                        QuestRewardRepActive Equal to True
                        QuestRewardItemActive Equal to True
            Then - Actions
                Set VariableSet QuestRewardsTextHeading[QuestID] = QuestRewardsTextHeadingTemp
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardXPActive Equal to True
                    Then - Actions
                        Custom script:   set udg_QuestTempString = udg_QuestRewardXP_Text[udg_QuestID] + "\n"
                        Set VariableSet QuestRewards1[QuestID] = QuestTempString
                    Else - Actions
                        Set VariableSet QuestRewards1[QuestID] = <Empty String>
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardGoldActive Equal to True
                    Then - Actions
                        Custom script:   set udg_QuestTempString = udg_QuestRewardGold_Text[udg_QuestID] + "\n"
                        Set VariableSet QuestRewards2[QuestID] = QuestTempString
                    Else - Actions
                        Set VariableSet QuestRewards2[QuestID] = <Empty String>
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardArenaActive Equal to True
                    Then - Actions
                        Custom script:   set udg_QuestTempString = udg_QuestRewardArena_Text[udg_QuestID] + "\n"
                        Set VariableSet QuestRewards3[QuestID] = QuestTempString
                    Else - Actions
                        Set VariableSet QuestRewards3[QuestID] = <Empty String>
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardRepActive Equal to True
                    Then - Actions
                        Custom script:   set udg_QuestTempString = udg_QuestRewardReputation_Text[udg_QuestID] + "\n"
                        Set VariableSet QuestRewards4[QuestID] = QuestTempString
                    Else - Actions
                        Set VariableSet QuestRewards4[QuestID] = <Empty String>
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        QuestRewardItemActive Equal to True
                    Then - Actions
                        Custom script:   set udg_QuestTempString = "\n" + udg_QuestRewardItem_Text[udg_QuestID] + "\n"
                        Set VariableSet QuestRewards5[QuestID] = QuestTempString
                    Else - Actions
                        Set VariableSet QuestRewards5[QuestID] = <Empty String>
            Else - Actions
                -------- = No rewards --------
                Set VariableSet QuestRewardsTextHeading[QuestID] = <Empty String>
                Set VariableSet QuestRewardsText[QuestID] = <Empty String>
        -------- ======= Requirements --------
        Set VariableSet QuestRequirementHeading[QuestID] = QuestRequirementHeadingTemp
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestKillsActive Equal to True
                QuestItemsActive Equal to False
            Then - Actions
                -------- ======= Only KILL active --------
                Set VariableSet QuestRequirement1[QuestID] = (Kill  + ((String(QuestKillsReq[QuestID])) + (  + (String(QuestKillsType[QuestID])))))
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestItemsActive Equal to True
                QuestKillsActive Equal to False
            Then - Actions
                -------- ======= Only GATHER active --------
                Set VariableSet QuestRequirement1[QuestID] = (Gather  + ((String(QuestItemsReq[QuestID])) + (  + QuestItemsTypeText[QuestID])))
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestItemsActive Equal to True
                QuestKillsActive Equal to True
            Then - Actions
                -------- ======= Both KILL and GATHER active --------
                Set VariableSet QuestRequirement1[QuestID] = (Kill  + ((String(QuestKillsReq[QuestID])) + (  + (String(QuestKillsType[QuestID])))))
                Set VariableSet QuestRequirement2[QuestID] = (Gather  + ((String(QuestItemsReq[QuestID])) + (  + QuestItemsTypeText[QuestID])))
            Else - Actions
        -------- ======= Requirements otherwise --------
        Set VariableSet QuestRequirement1[QuestID] = QuestRequirement1Temp
        Set VariableSet QuestRequirement2[QuestID] = QuestRequirement2Temp
        Set VariableSet QuestRequirement3[QuestID] = QuestRequirement3Temp
        Set VariableSet QuestRequirement4[QuestID] = QuestRequirement4Temp
        Set VariableSet QuestRequirement5[QuestID] = QuestRequirement5Temp
        Set VariableSet QuestRequirement6[QuestID] = QuestRequirement6Temp
        Set VariableSet QuestRequirement7[QuestID] = QuestRequirement7Temp
        Set VariableSet QuestRequirement8[QuestID] = QuestRequirement8Temp
        Set VariableSet QuestRewardsText[QuestID] = (QuestRewards1[QuestID] + (QuestRewards2[QuestID] + (QuestRewards3[QuestID] + (QuestRewards4[QuestID] + QuestRewards5[QuestID]))))
        -------- ======= ================================= ========================== --------
        -------- ======= QUEST TYPE: normal, daily, repeatable, dungeon  --------
        Set VariableSet QuestType[QuestID] = QuestTypeTemp
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Set VariableSet QuestState[QuestID] = QuestStateTemp
        -------- ======= QUEST ICON STATUS --------
        Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID], udg_QuestID, udg_QuestType[udg_QuestID], udg_QuestState[udg_QuestID] )
