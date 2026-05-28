Quest Rifts Corruption Create
    Events
    Conditions
        ((This trigger) is on) Equal to True
    Actions
        Trigger - Turn off (This trigger)
        -------- ======= ================================= ========================== --------
        -------- ======= DONT MODIFY: QUEST ID Creation --------
        Set VariableSet QuestID = (QuestID + 1)
        -------- ======= ADJUST THESE VALUES: Define level of quest and level of the quest giver --------
        Set VariableSet QuestLevelTemp = 18
        Set VariableSet QuestGiverLevelTemp = (Level of (Triggering unit))
        Set VariableSet QuestGiverUnitTemp = Aradion
        -------- ======= ADJUST THESE VALUES: QUEST TYPE: normal, daily, repeatable, dungeon  --------
        Set VariableSet QuestTypeTemp = normal
        -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
        Set VariableSet QuestStateTemp = 3
        -------- ======= FACTION --------
        Set VariableSet QuestFactionTemp = Elarindor
        -------- ======= REWARDS - XP --------
        Set VariableSet QuestRewardXP_AdjustTemp = 0
        -------- ======= REWARDS - GOLD --------
        Set VariableSet QuestRewardGold_AdjustTemp = 0
        -------- ======= REWARDS - ARENA MARKS --------
        Set VariableSet QuestRewardArena_AdjustTemp = 0
        -------- ======= REWARDS - REPUTATION --------
        Set VariableSet QuestRewardRep_AdjustTemp = 200
        Set VariableSet QuestRewardRepLinkedTemp = False
        -------- ======= REWARDS - ITEM --------
        Set VariableSet QuestRewardItemTemp = |c0090EE90Steel Blade|r
        -------- ======= OVERRIDE REWARDS (TRUE = Reward / FALSE = No reward --------
        Set VariableSet QuestRewardXPActive = True
        Set VariableSet QuestRewardGoldActive = True
        Set VariableSet QuestRewardArenaActive = False
        Set VariableSet QuestRewardRepActive = True
        Set VariableSet QuestRewardItemActive = False
        -------- ======= GENERIC TASKS --------
        -------- ======= KILLS - only 1 type units --------
        Set VariableSet QuestKillsReqTemp = 10
        Set VariableSet QuestKillsTypeTemp = Peasant
        -------- ======= ITEM GATHER - only 1 type items --------
        Set VariableSet QuestItemsReqTemp = 10
        Set VariableSet QuestItemsTypeTemp = |c0090EE90Reinforced Leather Gloves|r
        -------- ======= OVERRIDE GENERIC TASKS (TRUE = Reward / FALSE = No reward --------
        Set VariableSet QuestKillsActive = False
        Set VariableSet QuestItemsActive = False
        -------- ======= ADJUST THESE VALUES: Define description texts --------
        Set VariableSet QuestTitleTemp = (Rifts of Corruption + <Empty String>)
        Set VariableSet QuestIconPathTemp = ReplaceableTextures\CommandButtons\BTNDizzy.blp
        Set VariableSet QuestDescriptionTemp = (Find all rifts scattered around the Vanguard Vale and escort Valeria and Aradion to them. Guard Aradion while he will close the rifts. Both Aradion and Valeria must stay alive. + |n|n)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestGiverUnitTemp is A Hero) Equal to True
            Then - Actions
                Set VariableSet QuestInfoTemp = (|cffffcc00Quest giver:|r  + ((Proper name of QuestGiverUnitTemp) + |n))
            Else - Actions
                Set VariableSet QuestInfoTemp = (|cffffcc00Quest giver:|r  + ((Name of QuestGiverUnitTemp) + |n))
        Set VariableSet QuestInfo2Temp = ((|cffffcc00Recommended level:|r  + (String(QuestLevelTemp))) + |n|n)
        Custom script:   set udg_QuestTempString = "|cffffcc00Rewards:|r\n"
        Set VariableSet QuestRewardsTextHeadingTemp = QuestTempString
        Set VariableSet QuestRequirementHeadingTemp = (<Empty String> + <Empty String>)
        Set VariableSet QuestRequirement1Temp = (Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed  + (0 +  / 3)))
        Set VariableSet QuestRequirement2Temp = (Guard Aradion while he closes the rifts + <Empty String>)
        Set VariableSet QuestRequirement3Temp = (Both Aradion and Valeria must stay alive + <Empty String>)
        Set VariableSet QuestRequirement4Temp = (<Empty String> + <Empty String>)
        Set VariableSet QuestRequirement5Temp = (<Empty String> + <Empty String>)
        Set VariableSet QuestRequirement6Temp = (<Empty String> + <Empty String>)
        Set VariableSet QuestRequirement7Temp = (<Empty String> + <Empty String>)
        Set VariableSet QuestRequirement8Temp = (<Empty String> + <Empty String>)
        -------- ======= ========================== --------
        Trigger - Run Quest System Create <gen> (ignoring conditions)
        -------- Adjust quest icon - Removing manually created "9999" Quest ID --------
        Set VariableSet QuestGiverUnitTemp = Aradion
        Custom script:   call RemoveDummyQuestIcon(udg_QuestGiverUnitTemp)
        -------- ======= ========================== --------
        -------- Create the quest objects --------
        Quest - Create a Required, undiscovered quest titled QuestTitle[QuestID] with the description (QuestDescription[QuestID] + (QuestInfo[QuestID] + (QuestInfo2[QuestID] + (QuestRewardsTextHeading[QuestID] + QuestRewardsText[QuestID])))), using icon path QuestIconPath[QuestID]
        Set VariableSet QuestRiftsCorruption = (Last created quest)
        Quest - Create a quest requirement for QuestRiftsCorruption with the description QuestRequirement1[QuestID]
        Set VariableSet QuestRiftsCorruptionReq1 = (Last created quest requirement)
        Quest - Create a quest requirement for QuestRiftsCorruption with the description QuestRequirement2[QuestID]
        Set VariableSet QuestRiftsCorruptionReq2 = (Last created quest requirement)
        Quest - Create a quest requirement for QuestRiftsCorruption with the description QuestRequirement3[QuestID]
        Set VariableSet QuestRiftsCorruptionReq3 = (Last created quest requirement)
        -------- ======= ========================== --------
        -------- DONT MODIFY: SAVE HASHTABLE --------
        Trigger - Run Quest System Save Hashtable <gen> (ignoring conditions)
        -------- ======= ================================= ========================== --------
