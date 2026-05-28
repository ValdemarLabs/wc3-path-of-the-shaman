Mining Tin Vein
    Events
        Game - DamageModifierEvent becomes Equal to 1.00
    Conditions
    Actions
        -------- Check unit type --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                And - All (Conditions) are true
                    Conditions
                        (Unit-type of DamageEventTarget) Equal to Tin Vein 2
                        (DamageEventSource has an item of type Mining Pick) Equal to True
            Then - Actions
                -------- TEMP --------
                Set VariableSet Temp_Ore = (Custom value of DamageEventTarget)
                -------- Mining chance --------
                Set VariableSet MiningChance = (Random integer number between 1 and 2)
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        OreAmountTotalSet[Temp_Ore] Equal to False
                    Then - Actions
                        -------- Initialize OreAmountTotalArray --------
                        Set VariableSet OreAmountTotalArray[Temp_Ore] = (Random integer number between 2 and 6)
                        Set VariableSet OreAmountTotalSet[Temp_Ore] = True
                    Else - Actions
                --------  Check ore amount for this unit --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        And - All (Conditions) are true
                            Conditions
                                MiningChance Equal to 1
                                OreAmountArray[Temp_Ore] Less than OreAmountTotalArray[Temp_Ore]
                                OreAmountTotalSet[Temp_Ore] Equal to True
                    Then - Actions
                        -------- debug 1 --------
                        Hero - Create Tin Ore and give it to DamageEventSource
                        Set VariableSet OreAmountArray[Temp_Ore] = (OreAmountArray[Temp_Ore] + 1)
                        -------- Gemstone chance --------
                        Set VariableSet MiningGemstoneChance = (Random integer number between 1 and 10)
                        -------- Gemstones --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                And - All (Conditions) are true
                                    Conditions
                                        MiningGemstoneChance Equal to 1
                                        OreAmountArray[Temp_Ore] Less than OreAmountTotalArray[Temp_Ore]
                                        OreAmountTotalSet[Temp_Ore] Equal to True
                            Then - Actions
                                -------- debug 1 --------
                                Hero - Create Moss Agate and give it to DamageEventSource
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                And - All (Conditions) are true
                                    Conditions
                                        MiningGemstoneChance Equal to 2
                                        OreAmountArray[Temp_Ore] Less than OreAmountTotalArray[Temp_Ore]
                                        OreAmountTotalSet[Temp_Ore] Equal to True
                            Then - Actions
                                -------- debug 1 --------
                                Hero - Create Moonstone and give it to DamageEventSource
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                And - All (Conditions) are true
                                    Conditions
                                        MiningGemstoneChance Equal to 3
                                        OreAmountArray[Temp_Ore] Less than OreAmountTotalArray[Temp_Ore]
                                        OreAmountTotalSet[Temp_Ore] Equal to True
                            Then - Actions
                                -------- debug 1 --------
                                Hero - Create Shadowgem and give it to DamageEventSource
                            Else - Actions
                    Else - Actions
                -------- Ore gathered --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        And - All (Conditions) are true
                            Conditions
                                OreAmountArray[Temp_Ore] Greater than or equal to OreAmountTotalArray[Temp_Ore]
                                OreAmountTotalSet[Temp_Ore] Equal to True
                    Then - Actions
                        -------- debug 2 --------
                        Set VariableSet OreAmountArray[Temp_Ore] = 0
                        Unit - Kill DamageEventTarget
                        Set VariableSet OreAmountTotalSet[Temp_Ore] = False
                    Else - Actions
            Else - Actions
