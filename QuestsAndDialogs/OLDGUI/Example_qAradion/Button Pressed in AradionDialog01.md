Button Pressed in AradionDialog01
    Events
        Dialog - A dialog button is clicked for AradionDialog01
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Info
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- BACKSTORY --------
                Set VariableSet AradionFarewellBoolean = True
                Trigger - Turn on AradionDialog01 Info Over <gen>
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I see the truth in your eyes. You do not come as foe, but as seeker. Then hear me, shaman, and know the ruin of my people.
                Custom script:   call ExSound_Play("Aradion_0003", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = This was once our home — Elarindor. Jewel of Vanguard Vale. A city that shone like a beacon from the light of the arcane energies.
                Custom script:   call ExSound_Play("Aradion_0004", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Then she came… A magister called Lady Serenthia. Cloaked in grace and wisdom, she whispered promises of eternal prosperity. Many of my people heeded her call…
                Custom script:   call ExSound_Play("Aradion_0005", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = But all she was — was a lie. Her beauty and voice, the elven form were mere illusion. In truth, she was the witch Zerathis.
                Custom script:   call ExSound_Play("Aradion_0006", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = My beloved Valeria and I begged our kin to turn away… but what are two voices against the choir of greed?
                Custom script:   call ExSound_Play("Aradion_0007", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = You said… a witch deceived you?
                Custom script:   call ExSound_Play("Nazgrek_0332", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Why did your kin trust this witch? 
                Custom script:   call ExSound_Play("Nazgrek_0333", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Her words promised glory — strength to rival Quel’Thalas itself. Her lies were sweet… and my people were starving for more.
                Custom script:   call ExSound_Play("Aradion_0008", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = But every promise was poison. Each draught of her ‘gift’ deepened the hunger, until the hunger itself consumed them.
                Custom script:   call ExSound_Play("Aradion_0009", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Now my people are twisted, their flesh withering, their souls bleeding into wraiths. Soon… nothing of them will remain.
                Custom script:   call ExSound_Play("Aradion_0010", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The wraiths I see… they were once elves?
                Custom script:   call ExSound_Play("Nazgrek_0334", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Yes. Once mothers, fathers, children. Now only hollow echoes bound to the Void by the magic that devoured them.
                Custom script:   call ExSound_Play("Aradion_0011", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The wretched who remain will share the same fate — it is only a matter of time before they too dissolve into wraiths.
                Custom script:   call ExSound_Play("Aradion_0012", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = And you? How did you resist where others fell?
                Custom script:   call ExSound_Play("Nazgrek_0336", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I resisted… because I feared. And because Valeria feared with me. Together we begged them to turn away. None listened.
                Custom script:   call ExSound_Play("Aradion_0013", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The witch saw no worth in those who refused her. So she left us alive — to watch the slow death of our kin.
                Custom script:   call ExSound_Play("Aradion_0014", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I have searched, shaman… searched for a cure, an answer, any salvation. But all I have found is despair.
                Custom script:   call ExSound_Play("Aradion_0015", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Yet perhaps the spirits you serve have sent you here, to answer the question I cannot solve alone.
                Custom script:   call ExSound_Play("Aradion_0016", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Info_Over)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[1]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- RANGER MISSING - ACCEPT --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Accept_Quest_1)
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = In the chaos, when the wraiths struck, my beloved Valeria was torn from my side.
                Custom script:   call ExSound_Play("Aradion_0035", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I have searched, but the shadows grow thick. If she still lives and you find her, bring her to me, shaman… before they claim her as well.
                Custom script:   call ExSound_Play("Aradion_0036", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I’ll see if I come across her.
                Custom script:   call ExSound_Play("Nazgrek_0337", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Accept_Quest_1)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestFailed[1]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- RANGER MISSING - FAILED --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Failed_Quest_1)
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Valeria was stubborn and left me no choice. I had to kill him in combat...
                Custom script:   call ExSound_Play("Nazgrek_0XXX", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = You did what?!
                Custom script:   call ExSound_Play("Aradion_00XX", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I should have known that you are as evil and vile as the rest of your kind!
                Custom script:   call ExSound_Play("Aradion_00XX", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = And now... you must pay with blood!
                Custom script:   call ExSound_Play("Aradion_00XX", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Failed_Quest_1)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[1]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- RANGER MISSING - COMPLETED --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Complete_Quest_1)
                -------- VALERIA --------
                Custom script:   call TriggerExecute(gg_trg_Valeria_Remove_Companion)
                Unit - Remove Wander (Neutral) from Valeria
                Unit - Order Valeria to Stop.
                Set VariableSet VarPoint = (Position of Aradion)
                Set VariableSet Variable = (VarPoint offset by 200.00 towards (Facing of Aradion) degrees.)
                Unit - Order Valeria to Move To Point
                Custom script:   call RemoveLocation(udg_VarPoint)
                Custom script:   call RemoveLocation(udg_ValeriaPoint)
                -------- =========== --------
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Aradion face Valeria over 0.75 seconds
                Set VariableSet ExSoundString = Aradion… It is you! I thought I’d never see you again.
                Custom script:   call ExSound_Play("Valeria_0023", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Aradion over 0.75 seconds
                Set VariableSet ExSoundString = Valeria? By the stars… you yet live!
                Custom script:   call ExSound_Play("Aradion_0031", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Aradion over 0.75 seconds
                Set VariableSet ExSoundString = I feared that I had lost you… forgive me for losing hope.
                Custom script:   call ExSound_Play("Aradion_0032", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Nazgrek over 0.75 seconds
                Wait 1.00 seconds
                Set VariableSet ExSoundString = This orc… he spoke your name, my love. It is the only reason I followed him.
                Custom script:   call ExSound_Play("Valeria_0024", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Aradion over 0.75 seconds
                Unit - Make Aradion face Nazgrek over 0.75 seconds
                Wait 2.00 seconds
                Set VariableSet ExSoundString = Then I was right. You Nazgrek are no foe, but a seeker.
                Custom script:   call ExSound_Play("Aradion_0033", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Aradion face Valeria over 0.75 seconds
                Set VariableSet ExSoundString = You have given me back my heart, shaman. For this… I owe you more than I can say.
                Custom script:   call ExSound_Play("Aradion_0034", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Nazgrek over 0.75 seconds
                Set VariableSet ExSoundString = …Do not think this earns my trust fully, orc. But… for Aradion’s sake, I’m giving you a chance.
                Custom script:   call ExSound_Play("Valeria_0025", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                Unit - Make Aradion face Nazgrek over 0.75 seconds
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Complete_Quest_1)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[2]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- CRYSTALS HOPE - ACCEPT --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Accept_Quest_2)
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = In the ruins of Elarindor, there are crystals… pulsing, alive with energy.
                Custom script:   call ExSound_Play("Aradion_0041", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I have walked near them. Their song is some what… twisted, yet beautiful.
                Custom script:   call ExSound_Play("Nazgrek_0366", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I believe they are remnants of our ancient magical pools, fractured when our people consumed too much magical energies.
                Custom script:   call ExSound_Play("Aradion_0042", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = If their power can be harnessed, perhaps… perhaps they may quiet the hunger, even if only for a time.
                Custom script:   call ExSound_Play("Aradion_0043", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Bring me shards of these crystals, shaman. Let us not forsake even the faintest hope.
                Custom script:   call ExSound_Play("Aradion_0044", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Accept_Quest_2)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[2]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- CRYSTALS HOPE - COMPLETED --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Complete_Quest_2)
                -------- =========== --------
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Yes… these shards still resonate with power, I can feel it... It is almost... mesmerizing.
                Custom script:   call ExSound_Play("Aradion_0047", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = If we can bend the crystals energy to our control, it might reverse the damage of the wretched elves decay… Or only soothe for a fleeting moment.…
                Custom script:   call ExSound_Play("Aradion_0048", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Yet the pulse of these crystals seems odd... As if the crystals themselves cry out in pain.
                Custom script:   call ExSound_Play("Aradion_0049", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I can hear the spirits whisper caution. These crystals may feed hunger, not heal it.
                Custom script:   call ExSound_Play("Nazgrek_0367", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I must study these shards you brought me… very carefully
                Custom script:   call ExSound_Play("Aradion_0050", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Complete_Quest_2)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[3]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- FADING SPARKS - ACCEPT --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Accept_Quest_3)
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The mana wraiths are what remain when the hunger wins.
                Custom script:   call ExSound_Play("Aradion_0053", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Yet even in their twisted forms, I sense a faint light — echoes of the elves they once were.
                Custom script:   call ExSound_Play("Aradion_0054", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = If we can gather those sparks, perhaps they hold some secret… some key we have overlooked.
                Custom script:   call ExSound_Play("Aradion_0055", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Bring me their essences, shaman. Let us see if even wraiths may whisper truth.
                Custom script:   call ExSound_Play("Aradion_0056", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I will do this Aradion, but I see little hope in the shadows.
                Custom script:   call ExSound_Play("Nazgrek_0371", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = I’ll give you the rod of Tel’anor which can be used to safely extract the essence of mana wraith when it is weakened enough.
                Custom script:   call ExSound_Play("Aradion_0063", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Accept_Quest_3)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[3]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- FADING SPARKS - COMPLETED --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Complete_Quest_3)
                -------- =========== --------
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = So fragile… yet for a moment, I can feel all the memories.... everything they once were…
                Custom script:   call ExSound_Play("Aradion_0060", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = But it all slips away, fading faster than breath. They are too far gone.
                Custom script:   call ExSound_Play("Aradion_0061", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = …If even wraiths leave behind only ashes of the soul, then perhaps our people’s fate is truly sealed... 
                Custom script:   call ExSound_Play("Aradion_0062", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Do not surrender to despair, Aradion. There may yet be an answer to all of it.
                Custom script:   call ExSound_Play("Nazgrek_0372", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Complete_Quest_3)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestAccept[4]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- Move Valeria --------
                -------- PAUSE PATROL --------
                Custom script:   call TriggerExecute(gg_trg_Valeria_Movement_Pause)
                Set VariableSet VarPoint = (Position of Aradion)
                Set VariableSet ValeriaPoint = (VarPoint offset by 1200.00 towards (Facing of Aradion) degrees.)
                Unit - Move Valeria instantly to ValeriaPoint, facing 192.00 degrees
                Custom script:   call RemoveLocation(udg_ValeriaPoint)
                Custom script:   call RemoveLocation(udg_VarPoint)
                Set VariableSet ValeriaPoint = (Center of ValeriaNewPos <gen>)
                Unit - Order Valeria to Move To ValeriaPoint
                Custom script:   call RemoveLocation(udg_ValeriaPoint)
                -------- RIFTS CORRUPTION - ACCEPT --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Accept_Quest_4)
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The ancient pools of magic around the Vanguard Vale and Elarindor once flowed pure, binding our people to life and light.
                Custom script:   call ExSound_Play("Aradion_0065", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Now they are transformed.... distorted by implosion of the mana hunger.... And in those rift-like pools, the wraiths are born anew.
                Custom script:   call ExSound_Play("Aradion_0066", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Aradion over 0.75 seconds
                Set VariableSet ExSoundString = Valeria and I will attempt to seal these rifts. It is perilous work, and we don’t truly know what we are dealing with. I’ve begin to think that I should do this alone…
                Custom script:   call ExSound_Play("Aradion_0067", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Aradion face Valeria over 0.75 seconds
                Set VariableSet ExSoundString = We have planned this forever… I can handle it, my love. 
                Custom script:   call ExSound_Play("Valeria_0060", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Valeria named Valeria: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Unit - Make Valeria face Nazgrek over 0.75 seconds
                Unit - Make Aradion face Nazgrek over 0.75 seconds
                Set VariableSet ExSoundString = The spirits whisper of broken currents here. I will see Valeria through this.
                Custom script:   call ExSound_Play("Nazgrek_0377", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Stand with us, Nazgrek. Guard me while I close the rifts — and strike down whatever nightmares the rifts unleash. 
                Custom script:   call ExSound_Play("Aradion_0068", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Accept_Quest_4)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_QuestComplete[4]
            Then - Actions
                -------- SKIPPED - restore state --------
                Set VariableSet DialogSkipped = False
                -------- RIFTS CORRUPTION - COMPLETED --------
                Set VariableSet AradionFarewellBoolean = True
                Custom script:   call EnableTrigger(gg_trg_AradionDialog01_Complete_Quest_4)
                -------- =========== --------
                Cinematic - Disable user control for (All players).
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The wound in the land is remedied… for now.
                Custom script:   call ExSound_Play("Nazgrek_0378", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Nazgrek named Nazgrek: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = The rifts… are sealed. For the first time in years, the air feels lighter in the Vale.
                Custom script:   call ExSound_Play("Aradion_0071", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = You stood unbroken, my dear friend. Hope stirs again — faint, but alive.
                Custom script:   call ExSound_Play("Aradion_0072", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- ===================================== --------
                Set VariableSet ExSoundString = Thank you, shaman. You have given us more than victory — you have given us belief.
                Custom script:   call ExSound_Play("Aradion_0073", udg_ExSoundString)
                Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                -------- ===================================== --------
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                Wait 3.00 seconds
                If (DialogSkipped Equal to True) then do (Skip remaining actions) else do (Do nothing)
                -------- OVER --------
                Custom script:   call TriggerExecute(gg_trg_AradionDialog01_Complete_Quest_4)
                Skip remaining actions
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Farewell
            Then - Actions
                Set VariableSet AradionFarewellBoolean = True
                Cinematic - Disable user control for (All players).
                -------- ===================================== --------
                Custom script:   call TriggerExecute(gg_trg_Nazgrek_Farewell)
                Wait ExSoundDuration seconds
                -------- ===================================== --------
                Set VariableSet AradionRandomGreet = (Random integer number between 1 and 3)
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 1
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = Go then, shaman. May the spirits shield you.
                        Custom script:   call ExSound_Play("Aradion_0017", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 2
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = May your path carry more hope than mine.
                        Custom script:   call ExSound_Play("Aradion_0018", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        AradionRandomGreet Equal to 3
                    Then - Actions
                        -------- ===================================== --------
                        Set VariableSet ExSoundString = I hope our paths cross again.
                        Custom script:   call ExSound_Play("Aradion_0019", udg_ExSoundString)
                        Cinematic - Send transmission to (All players) from Aradion named Aradion the Farseer: Play No sound and display ExSoundString.  Modify duration: Set to ExSoundDuration seconds and Wait
                        -------- ===================================== --------
                    Else - Actions
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
