Quest Fading Sparks Update
    Events
        Unit - A unit Acquires an item
    Conditions
        (QuestFadingSparks is discovered) Equal to True
        (QuestFadingSparks is completed) Equal to False
        (Owner of (Triggering unit)) Equal to Player 1 (Red)
        (Item-type of (Item being manipulated)) Equal to Wraith Essence
    Actions
        -------- ================================ --------
        -------- CHECK ITEM --------
        Set VariableSet DInvItemType = Wraith Essence
        Set VariableSet DInvItemAmount = 10
        Custom script:   set udg_DInvItemCarrierHasItems = HeroItemCheckBoth(udg_DInvItemType, udg_DInvItemAmount)
        -------- ================================ --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                DInvItemCarrierHasItems Equal to True
            Then - Actions
                Trigger - Turn off (This trigger)
                -------- ======= ================================= ========================== --------
                -------- ======= ADJUST WHICH QUEST --------
                Set VariableSet QuestTemp = QuestFadingSparks
                -------- ======= DONT MODIFY: LOAD HASHTABLE --------
                Trigger - Run Quest System Load Hashtable <gen> (ignoring conditions)
                -------- ======= ================================= ========================== --------
                Quest - Mark QuestFadingSparksReq1 as Completed
                Quest - Create a quest requirement for QuestFadingSparks with the description Bring the wraith es...
                Set VariableSet QuestFadingSparksReq2 = (Last created quest requirement)
                Quest - Display to (All players) the Quest Update message: |cffffcc00QUEST UPD...
                Quest - Display to (All players) the Quest Update message: - Bring the wraith ...
                Quest - Flash the quest dialog button
                -------- ======= ================================= ========================== --------
                -------- REFRESH QUEST ICON --------
                -------- ======= QUEST State 1-5: (unavailable, available, in progress, complete, ready to turn in) --------
                Custom script:   set udg_QuestState[udg_QuestID_Temp] = 5
                Custom script:   call QuestIcon_RegisterQuest(udg_QuestGiverUnit[udg_QuestID_Temp], udg_QuestID_Temp, udg_QuestType[udg_QuestID_Temp], udg_QuestState[udg_QuestID_Temp] )
            Else - Actions
