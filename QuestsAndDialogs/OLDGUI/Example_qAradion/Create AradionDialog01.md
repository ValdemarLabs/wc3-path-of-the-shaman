Create AradionDialog01
    Events
    Conditions
    Actions
        Cinematic - Enable user control for (All players).
        Dialog - Clear AradionDialog01
        Dialog - Change the title of AradionDialog01 to Aradion the Farseer
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Backstory --------
                Dialog - Create a dialog button for AradionDialog01 labelled Backstory
                -------- BTN variable --------
                Set VariableSet DialogBTN_Info = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionBackstoryBoolean Equal to True
                (QuestRangerMissing is discovered) Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for AradionDialog01 labelled Ranger Missing (Que...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 1
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                AradionBackstoryBoolean Equal to True
                (QuestRangerMissing is discovered) Equal to True
                (QuestRangerMissing is failed) Equal to True
            Then - Actions
                -------- Quest - Failed --------
                Dialog - Create a dialog button for AradionDialog01 labelled Ranger Missing (Fai...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 1
                Set VariableSet DialogBTN_QuestFailed[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRangerMissing is discovered) Equal to True
                (QuestRangerMissing is completed) Equal to False
                (QuestRangerMissingReq1 is completed) Equal to True
            Then - Actions
                -------- VELARIA MUST BE ALIVE and CLOSE TO ARADION to have COMPLETE button available --------
                Set VariableSet CV = (Custom value of Valeria)
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        IsUnitAlive[CV] Equal to True
                        GCSM_UnitInCombat[CV] Equal to False
                    Then - Actions
                        Set VariableSet DistanceCheckPoint1 = (Position of Aradion)
                        Set VariableSet DistanceCheckPoint2 = (Position of Valeria)
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Distance between DistanceCheckPoint1 and DistanceCheckPoint2) Less than or equal to 1000.00
                            Then - Actions
                                -------- Quest  - Completion --------
                                Dialog - Create a dialog button for AradionDialog01 labelled Ranger Missing (Com...
                                -------- BTN variable --------
                                Set VariableSet DialogBTN_QuestInt = 1
                                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
                            Else - Actions
                    Else - Actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRangerMissing is completed) Equal to True
                (QuestCrystalsHope is discovered) Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for AradionDialog01 labelled Crystals of Hope (Q...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 2
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        -------- ================================ --------
        -------- CHECK ITEM --------
        Set VariableSet DInvItemType = Mana Crystal
        Set VariableSet DInvItemAmount = 6
        Custom script:   set udg_DInvItemCarrierHasItems = HeroItemCheckBoth(udg_DInvItemType, udg_DInvItemAmount)
        -------- ================================ --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRangerMissing is completed) Equal to True
                (QuestCrystalsHope is discovered) Equal to True
                (QuestCrystalsHope is completed) Equal to False
                DInvItemCarrierHasItems Equal to True
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for AradionDialog01 labelled Crystals of Hope (C...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 2
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRangerMissing is completed) Equal to True
                (QuestFadingSparks is discovered) Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for AradionDialog01 labelled Fading Sparks (Ques...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 3
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        -------- ================================ --------
        -------- CHECK ITEM --------
        Set VariableSet DInvItemType = Wraith Essence
        Set VariableSet DInvItemAmount = 10
        Custom script:   set udg_DInvItemCarrierHasItems = HeroItemCheckBoth(udg_DInvItemType, udg_DInvItemAmount)
        -------- ================================ --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRangerMissing is completed) Equal to True
                (QuestFadingSparks is discovered) Equal to True
                (QuestFadingSparks is completed) Equal to False
                DInvItemCarrierHasItems Equal to True
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for AradionDialog01 labelled Fading Sparks (Comp...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 3
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        And - All (Conditions) are true
                            Conditions
                                (QuestRangerMissing is completed) Equal to True
                                (QuestCrystalsHope is completed) Equal to True
                                (QuestFadingSparks is completed) Equal to True
                                (QuestRiftsCorruption is discovered) Equal to False
                        And - All (Conditions) are true
                            Conditions
                                (QuestRangerMissing is completed) Equal to True
                                (QuestCrystalsHope is completed) Equal to True
                                (QuestFadingSparks is completed) Equal to True
                                (QuestRiftsCorruption is failed) Equal to True
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for AradionDialog01 labelled Rifts of Corruption...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 4
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestRangerMissing is completed) Equal to True
                (QuestCrystalsHope is completed) Equal to True
                (QuestFadingSparks is completed) Equal to True
                (QuestRiftsCorruption is discovered) Equal to True
                (QuestRiftsCorruption is completed) Equal to False
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for AradionDialog01 labelled Rifts of Corruption...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 4
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Exit dialog --------
                Dialog - Create a dialog button for AradionDialog01 labelled - Farewell
                -------- BTN variable --------
                Set VariableSet DialogBTN_Farewell = (Last created dialog Button)
            Else - Actions
        -------- ======= SHOW DIALOG --------
        Dialog - Show AradionDialog01 for Player 1 (Red)
