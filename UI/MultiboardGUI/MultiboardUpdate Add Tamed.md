MultiboardUpdate Add Tamed
    Events
    Conditions
    Actions
        Set VariableSet Multiboard_RowVar = 5
        -------- Hero/Unit icon --------
        Multiboard - Set the display style for Multiboard item in column 1, row Multiboard_RowVar to Show text and Show icons
        -------- stats --------
        Multiboard - Set the display style for Multiboard item in column 2, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 3, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 4, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 5, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 6, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 7, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 8, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 9, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 10, row Multiboard_RowVar to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 11, row Multiboard_RowVar to Show text and Hide icons
        -------- ======================================== --------
        -------- (Row 5) --------
        Multiboard - Set the text for Multiboard item in column 2, row 5 to (Name of TamedUnit)
        --------  // KILLS --------
        Multiboard - Set the text for Multiboard item in column 12, row 5 to (0 + <Empty String>)
        --------  // DEATHS --------
        Multiboard - Set the text for Multiboard item in column 13, row 5 to (0 + <Empty String>)
        -------- ======================================== --------
        -------- ======================================== --------
        -------- WOLF ICON --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        (Unit-type of TamedUnit) Equal to Shadowclaw
                        (Unit-type of TamedUnit) Equal to Timber Wolf (Level 2)
                        (Unit-type of TamedUnit) Equal to Giant Wolf (Level 4)
                        (Unit-type of TamedUnit) Equal to Dire Wolf (Level 5)
            Then - Actions
                Multiboard - Set the icon for Multiboard item in column 1, row 5 to ReplaceableTextures\CommandButtons\BTNDireWolf.blp
            Else - Actions
        -------- ======================================== --------
        -------- BEAR ICON --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        (Unit-type of TamedUnit) Equal to Bear Cub
                        (Unit-type of TamedUnit) Equal to Bear
                        (Unit-type of TamedUnit) Equal to Ferocious Bear
            Then - Actions
                Multiboard - Set the icon for Multiboard item in column 1, row 5 to ReplaceableTextures\CommandButtons\BTNGrizzlyBear.blp
            Else - Actions
        -------- ======================================== --------
        -------- EAGLE ICON --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Or - Any (Conditions) are true
                    Conditions
                        (Unit-type of TamedUnit) Equal to Hawk (Level 5)
            Then - Actions
                Multiboard - Set the icon for Multiboard item in column 1, row 5 to ReplaceableTextures\CommandButtons\BTNWarEagle.blp
            Else - Actions
        -------- ======================================== --------
        -------- RAVEN ICON --------
        -------- ======================================== --------
        -------- TURTLE ICON --------
        -------- ======================================== --------
        -------- PANTHER ICON --------
        -------- ======================================== --------
        -------- TIGER ICON --------
        -------- ======================================== --------
        -------- RAPTOR ICON --------
        -------- ======================================== --------
        -------- LYNX ICON --------
        -------- ======================================== --------
        -------- FAERIE DRAGON ICON --------
        -------- ======================================== --------
        -------- TamedUnit level and stats --------
        -------- Tamed Unit Level --------
        Multiboard - Set the text for Multiboard item in column 4, row Multiboard_RowVar to (|c007EBFF1 + ((String((Level of TamedUnit))) + |r))
        -------- STATS --------
        --------  // HIT --------
        Multiboard - Set the text for Multiboard item in column 7, row Multiboard_RowVar to ((String(Stats_Hit[(Custom value of TamedUnit)])) + %)
        --------  // CRIT --------
        Multiboard - Set the text for Multiboard item in column 8, row Multiboard_RowVar to ((String(Stats_Crit[(Custom value of TamedUnit)])) + %)
        --------  // DODGE --------
        Multiboard - Set the text for Multiboard item in column 9, row Multiboard_RowVar to ((String(Stats_Dodge[(Custom value of TamedUnit)])) + %)
        --------  // BLOCK --------
        Multiboard - Set the text for Multiboard item in column 10, row Multiboard_RowVar to ((String(Stats_Block[(Custom value of TamedUnit)])) + %)
        --------  // SPELL BONUS --------
        Multiboard - Set the text for Multiboard item in column 11, row Multiboard_RowVar to ((String(Stats_SpellPowerPct[(Custom value of TamedUnit)])) + %)
