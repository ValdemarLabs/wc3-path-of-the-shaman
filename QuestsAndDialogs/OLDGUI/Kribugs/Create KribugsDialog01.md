Create KribugsDialog01
    Events
    Conditions
    Actions
        Cinematic - Enable user control for (All players).
        Dialog - Clear KribugsDialog01
        Dialog - Change the title of KribugsDialog01 to Kribugs
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreSandwich is discovered) Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Ogre Lost His Sandw...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 1
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreSandwich is discovered) Equal to True
                (QuestOgreSandwich is completed) Equal to False
                Or - Any (Conditions) are true
                    Conditions
                        (Nazgrek has an item of type Old Sandwich) Equal to True
                        (Zulkis has an item of type Old Sandwich) Equal to True
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Ogre Lost His Sandw...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 1
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreSandwich is completed) Equal to True
                (QuestKribugsSatchel is discovered) Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Kribug Lost His Sat...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 2
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreSandwich is completed) Equal to True
                (QuestKribugsSatchel is discovered) Equal to True
                (QuestKribugsSatchel is completed) Equal to False
                Or - Any (Conditions) are true
                    Conditions
                        (Nazgrek has an item of type Kribug's Satchel) Equal to True
                        (Zulkis has an item of type Kribug's Satchel) Equal to True
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Kribugs Lost His Sa...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 2
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreSandwich is completed) Equal to True
                (QuestKribugsSatchel is completed) Equal to True
                (QuestOgreThirsty is discovered) Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Ogre Is Very Thirst...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 3
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreSandwich is completed) Equal to True
                (QuestKribugsSatchel is completed) Equal to True
                (QuestOgreThirsty is discovered) Equal to True
                (QuestOgreThirsty is completed) Equal to False
                Or - Any (Conditions) are true
                    Conditions
                        (Nazgrek has an item of type Crystal Water) Equal to True
                        (Zulkis has an item of type Crystal Water) Equal to True
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Ogre Is Very Thirst...
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
                                (QuestMeatForOgre is discovered) Equal to False
                                (QuestMeatForOgre is completed) Equal to False
                        And - All (Conditions) are true
                            Conditions
                                (QuestMeatForOgre is completed) Equal to True
                KribugsOgreFull Equal to False
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Meat for the Ogre (...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 4
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestMeatForOgre is discovered) Equal to True
                (QuestMeatForOgre is completed) Equal to False
                KribugsOgreFull Equal to False
                Or - Any (Conditions) are true
                    Conditions
                        Or - Any (Conditions) are true
                            Conditions
                                (Nazgrek has an item of type Raw Bear Meat) Equal to True
                                (Nazgrek has an item of type Raw Boar Meat) Equal to True
                                (Nazgrek has an item of type Raw Cow Meat) Equal to True
                                (Nazgrek has an item of type Raw Crawler Meat) Equal to True
                                (Nazgrek has an item of type Raw Hawk Meat) Equal to True
                                (Nazgrek has an item of type Raw Lizard Meat) Equal to True
                                (Nazgrek has an item of type Raw Makrura Meat) Equal to True
                                (Nazgrek has an item of type Raw Murloc Meat) Equal to True
                                (Nazgrek has an item of type Raw Panther Meat) Equal to True
                                (Nazgrek has an item of type Raw Rabbit Meat) Equal to True
                                (Nazgrek has an item of type Raw Raptor Meat) Equal to True
                                (Nazgrek has an item of type Raw Snake Meat) Equal to True
                                (Nazgrek has an item of type Raw Stag Meat) Equal to True
                                (Nazgrek has an item of type Raw Tiger Meat) Equal to True
                                (Nazgrek has an item of type Raw Turtle Meat) Equal to True
                                (Nazgrek has an item of type Raw Wolf Meat) Equal to True
                        Or - Any (Conditions) are true
                            Conditions
                                (Zulkis has an item of type Raw Bear Meat) Equal to True
                                (Zulkis has an item of type Raw Boar Meat) Equal to True
                                (Zulkis has an item of type Raw Cow Meat) Equal to True
                                (Zulkis has an item of type Raw Crawler Meat) Equal to True
                                (Zulkis has an item of type Raw Hawk Meat) Equal to True
                                (Zulkis has an item of type Raw Lizard Meat) Equal to True
                                (Zulkis has an item of type Raw Makrura Meat) Equal to True
                                (Zulkis has an item of type Raw Murloc Meat) Equal to True
                                (Zulkis has an item of type Raw Panther Meat) Equal to True
                                (Zulkis has an item of type Raw Rabbit Meat) Equal to True
                                (Zulkis has an item of type Raw Raptor Meat) Equal to True
                                (Zulkis has an item of type Raw Snake Meat) Equal to True
                                (Zulkis has an item of type Raw Stag Meat) Equal to True
                                (Zulkis has an item of type Raw Tiger Meat) Equal to True
                                (Zulkis has an item of type Raw Turtle Meat) Equal to True
                                (Zulkis has an item of type Raw Wolf Meat) Equal to True
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Meat for the Ogre (...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 4
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                KribugsOgreFull Equal to True
                Or - Any (Conditions) are true
                    Conditions
                        And - All (Conditions) are true
                            Conditions
                                (QuestOgreAteMuch is discovered) Equal to False
                                (QuestOgreAteMuch is completed) Equal to False
                        And - All (Conditions) are true
                            Conditions
                                (QuestOgreAteMuch is completed) Equal to True
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for KribugsDialog01 labelled The Ogre Ate Too Mu...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 5
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreAteMuch is discovered) Equal to True
                (QuestOgreAteMuch is completed) Equal to False
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for KribugsDialog01 labelled The Ogre Ate Too Mu...
                Cinematic - Enable user control for (All players).
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 5
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestAngryCustomers is discovered) Equal to False
                (QuestOgreSandwich is completed) Equal to True
                (QuestKribugsSatchel is completed) Equal to True
            Then - Actions
                -------- Quest - Accept --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Angry Customers (Qu...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 6
                Set VariableSet DialogBTN_QuestAccept[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (QuestOgreAteMuch is discovered) Equal to True
                (QuestOgreAteMuch is completed) Equal to False
                QuestAngryCustmersCount Greater than or equal to 10
            Then - Actions
                -------- Quest  - Completion --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Angry Customers (Co...
                -------- BTN variable --------
                Set VariableSet DialogBTN_QuestInt = 6
                Set VariableSet DialogBTN_QuestComplete[DialogBTN_QuestInt] = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Special Deal --------
                Dialog - Create a dialog button for KribugsDialog01 labelled "Special Deal"
                -------- BTN variable --------
                Set VariableSet DialogBTN_Special = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Trade --------
                Dialog - Create a dialog button for KribugsDialog01 labelled Trade
                -------- BTN variable --------
                Set VariableSet DialogBTN_Trade = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Exit dialog --------
                Dialog - Create a dialog button for KribugsDialog01 labelled - Farewell
                -------- BTN variable --------
                Set VariableSet DialogBTN_Farewell = (Last created dialog Button)
            Else - Actions
        -------- ======= SHOW DIALOG --------
        Dialog - Show KribugsDialog01 for Player 1 (Red)
