Button Pressed in KribugsDialog01
    Events
        Dialog - A dialog button is clicked for KribugsDialog01
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[1]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- SANDWICH - ACCEPT --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Accept Quest 1 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ogre sad… he lost....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display No sandwich, no smi....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display He dropped it somew....  Modify duration: Set to 5.00 seconds and Wait
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Accept Quest 1 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[1]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- SANDWICH - COMPLETED --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Complete Quest 1 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Sandwich! You found....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Look at his face—....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Mmm, smells worse t....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Complete Quest 1 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[2]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- KRIBUGS SATCHEL - ACCEPT --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Accept Quest 2 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display My satchel! My prec....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Satchel’s got shi....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ogre no help—he t....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Accept Quest 2 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[2]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- KRIBUGS SATCHEL - COMPLETED --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Complete Quest 2 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Yes-yes! Kribugs’....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Did gnolls chew on ....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Good work, friend! ....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Complete Quest 2 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[3]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- OGRE THIRSTY - ACCEPT --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Accept Quest 3 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ogre thirsty. Very ....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Need good water! Cr....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Without water, Ogre....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Accept Quest 3 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[3]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- OGRE THIRSTY - COMPLETE --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Complete Quest 3 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ahhh, see? Ogre dri....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display He slurp-sluuuurp....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Good water! Strong ....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Complete Quest 3 <gen> (checking conditions)
                Skip remaining actions
                -------- ============ --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[4]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- MEAT FOR THE OGRE - ACCEPT --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Accept Quest 4 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ogre’s belly rumb....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Sound - Play KribugsOgreHungry <gen> at 100.00% volume, attached to Kribugs
                Wait 3.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Find something tast....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display No meat, no move. O....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Accept Quest 4 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[4]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- MEAT FOR THE OGRE - COMPLETE --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Complete Quest 4 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Yes-yes! Ogre chomp....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Look at him—chewi....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- SET COUNTER --------
                Trigger - Run Kribugs Ogre Full <gen> (checking conditions)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Complete Quest 4 <gen> (checking conditions)
                Skip remaining actions
                -------- ============ --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[5]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- OGRE ATE TOO MUCH - ACCEPT --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Accept Quest 5 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Sound - Play KribugsOgreFart <gen> at 100.00% volume, attached to Kribugs
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ugh… Ogre ate too....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                Wait 1.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display He groans, he moans....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Find herbs, potion,....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Accept Quest 5 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[5]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- OGRE ATE TOO MUCH - COMPLETE --------
                Set VariableSet KribugsFarewellBoolean = True
                Cinematic - Disable user control for (All players).
                -------- 50/50 chance to get --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Random integer number between 1 and 2) Equal to 1
                    Then - Actions
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Trigger - Turn on KribugsDialog01 Complete Quest 5 <gen>
                        Wait 5.00 seconds
                        -------- SET COUNTER --------
                        Set VariableSet KribugsOgreFullCount = 0
                        Set VariableSet KribugsOgreFull = False
                        -------- Full active --------
                        Unit - Remove Fart Cloud (Neutral Hostile no damage) from Kribugs
                        Unit - Set Unit: Kribugs's Integer Field: Tinting Color 1 (Red) ('uclr') to Value: 255
                        Unit - Set Unit: Kribugs's Integer Field: Tinting Color 2 (Green) ('uclg') to Value: 255
                        Unit - Set Unit: Kribugs's Integer Field: Tinting Color 3 (Blue) ('uclb') to Value: 255
                        Trigger - Turn off Kribugs Ogre Full Active <gen>
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Wait 2.00 seconds
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Trigger - Run Kribugs Ogre Random Voice <gen> (checking conditions)
                        Wait 1.00 seconds
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Ahhh, Ogre smiling ....  Modify duration: Set to 5.00 seconds and Wait
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Herbs worked! Ogre ....  Modify duration: Set to 5.00 seconds and Wait
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Thank you, thank yo....  Modify duration: Set to 5.00 seconds and Wait
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        -------- OVER --------
                        Trigger - Run KribugsDialog01 Complete Quest 5 <gen> (checking conditions)
                        Skip remaining actions
                    Else - Actions
                        If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Um… Well that did....  Modify duration: Set to 5.00 seconds and Wait
                        -------- ================================ --------
                        -------- DIALOG CAMERA == RESET --------
                        -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
                        Custom script:   call DialogCameraReset(Player(0), 2.0)
                        -------- ======== CINEMATIC ENDS ======== --------
                        Trigger - Run Cinematic OFF <gen> (checking conditions)
                        Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
                        -------- == PATROL == --------
                        Trigger - Run Kribugs Movement Continue <gen> (checking conditions)
                        Skip remaining actions
                -------- ============ --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[6]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- ANGRY CUSTOMERS - ACCEPT --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Accept Quest 6 <gen>
                Cinematic - Disable user control for (All players).
                -------- =========================== --------
                -------- Create "customers" --------
                Set VariableSet VarPoint2 = (Position of Kribugs)
                -------- --- Gnoll 1 --------
                Set VariableSet VarPoint = ((Position of Kribugs) offset by (250.00, 250.00))
                Unit - Create 1 Gnoll for Neutral Passive at VarPoint facing VarPoint2
                Unit Group - Add (Last created unit) to QuestAngryCustomersGroup
                Unit - Add a 30.00 second Generic expiration timer to (Last created unit)
                Unit - Add Invulnerable (Neutral) to (Last created unit)
                Custom script:   call RemoveLocation(udg_VarPoint)
                -------- --- Gnoll 2 --------
                Set VariableSet VarPoint = ((Position of Kribugs) offset by (200.00, 180.00))
                Unit - Create 1 Gnoll Brute for Neutral Passive at VarPoint facing VarPoint2
                Unit Group - Add (Last created unit) to QuestAngryCustomersGroup
                Unit - Add a 30.00 second Generic expiration timer to (Last created unit)
                Unit - Add Invulnerable (Neutral) to (Last created unit)
                Custom script:   call RemoveLocation(udg_VarPoint)
                -------- --- Gnoll 3 --------
                Set VariableSet VarPoint = ((Position of Kribugs) offset by (175.00, 280.00))
                Unit - Create 1 Gnoll for Neutral Passive at VarPoint facing VarPoint2
                Unit Group - Add (Last created unit) to QuestAngryCustomersGroup
                Unit - Add a 30.00 second Generic expiration timer to (Last created unit)
                Unit - Add Invulnerable (Neutral) to (Last created unit)
                Custom script:   call RemoveLocation(udg_VarPoint)
                -------- remove leaks --------
                Custom script:   call RemoveLocation(udg_VarPoint2)
                -------- Issue Gnolls moving --------
                Set VariableSet VarPoint = (Random point in (Playable map area))
                Unit Group - Pick every unit in QuestAngryCustomersGroup and do (Actions)
                    Loop - Actions
                        Unit - Order (Picked unit) to Move To VarPoint
                Custom script:   call RemoveLocation(udg_VarPoint)
                -------- =========================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Eh-heh… small pro....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display They say ‘bad dea....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Help chase ‘em of....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Accept Quest 6 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[6]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- ANGRY CUSTOMERS - COMPLETE --------
                Set VariableSet KribugsFarewellBoolean = True
                Trigger - Turn on KribugsDialog01 Complete Quest 6 <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Safe again! Custome....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display See? They angry, yo....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Now everyone rememb....  Modify duration: Set to 5.00 seconds and Wait
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Trigger - Run KribugsDialog01 Complete Quest 6 <gen> (checking conditions)
                Skip remaining actions
                -------- ============ --------
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Special
            Then - Actions
                -------- SKIPPED - restore state --------
                -------- SPECIAL DEAL --------
                Set VariableSet KribugsFarewellBoolean = True
                Cinematic - Disable user control for (All players).
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Random integer number between 1 and 2) Equal to 1
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Psst! Special deal,....  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display One-of-a-kind treas....  Modify duration: Set to 5.00 seconds and Wait
                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Pay gold, get surpr....  Modify duration: Set to 5.00 seconds and Wait
                Trigger - Run Create KribugsDialog02 <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Trade
            Then - Actions
                -------- SKIPPED - restore state --------
                -------- TRADE --------
                Set VariableSet KribugsFarewellBoolean = True
                Set VariableSet KribugsTrade = True
                Countdown Timer - Start KribugsTradeTimer as a One-shot timer that will expire in 30.00 seconds
                -------- --- --------
                Set VariableSet KribugsTradeCountdown = 30
                Trigger - Turn on Kribugs Floating Text Trade <gen>
                Trigger - Turn on Kribugs Trade Random Talk <gen>
                -------- DEFAULT CAMERA --------
                -------- ================================ --------
                -------- DIALOG CAMERA == RESET --------
                -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
                Custom script:   call DialogCameraReset(Player(0), 2.0)
                -------- ======== CINEMATIC ENDS ======== --------
                Trigger - Run Cinematic OFF <gen> (checking conditions)
                Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Farewell
            Then - Actions
                Set VariableSet KribugsFarewellBoolean = True
                Cinematic - Disable user control for (All players).
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play Nazgrek_0136 <gen> and display Farewell..  Modify duration: Set to 1.00 seconds and Wait
                Set VariableSet KribugsRandomGreet = (Random integer number between 1 and 3)
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsRandomGreet Equal to 1
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Spend again soon, o....  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsRandomGreet Equal to 2
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Goodbye, come back ....  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        KribugsRandomGreet Equal to 3
                    Then - Actions
                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Safe travels!.  Modify duration: Set to 5.00 seconds and Wait
                    Else - Actions
                -------- DEFAULT CAMERA --------
                -------- ================================ --------
                -------- DIALOG CAMERA == RESET --------
                -------- USAGE: call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds --------
                Custom script:   call DialogCameraReset(Player(0), 2.0)
                -------- ======== CINEMATIC ENDS ======== --------
                Trigger - Run Cinematic OFF <gen> (checking conditions)
                Countdown Timer - Start DialogOverTimer as a One-shot timer that will expire in 6.00 seconds
                -------- == PATROL == --------
                Trigger - Run Kribugs Movement Continue <gen> (checking conditions)
                Skip remaining actions
            Else - Actions
