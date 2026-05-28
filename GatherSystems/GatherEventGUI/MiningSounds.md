Mining Sound Effects
    Events
        Game - DamageModifierEvent becomes Equal to 1.00
    Conditions
        (DamageEventSource has an item of type Mining Pick) Equal to True
        Or - Any (Conditions) are true
            Conditions
                (Unit-type of DamageEventTarget) Equal to Copper Vein 2
                (Unit-type of DamageEventTarget) Equal to Tin Vein 2
                (Unit-type of DamageEventTarget) Equal to Silver Vein 2
                (Unit-type of DamageEventTarget) Equal to Gold Vein 2
                (Unit-type of DamageEventTarget) Equal to Iron Vein 2
                (Unit-type of DamageEventTarget) Equal to Mithril Vein 2
                (Unit-type of DamageEventTarget) Equal to Thorium Vein 2
                (Unit-type of DamageEventTarget) Equal to Blue Crystal
                (Unit-type of DamageEventTarget) Equal to Rich Blue Crystal
                (Unit-type of DamageEventTarget) Equal to Red Crystal
                (Unit-type of DamageEventTarget) Equal to Rich Red Crystal
                (Unit-type of DamageEventTarget) Equal to Green Crystal
                (Unit-type of DamageEventTarget) Equal to Rich Green Crystal
                (Unit-type of DamageEventTarget) Equal to Yellow Crystal
                (Unit-type of DamageEventTarget) Equal to Rich Yellow Crystal
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Random integer number between 1 and 5) Equal to 1
            Then - Actions
                Sound - Play Tradeskill_MiningHitA <gen> at 100.00% volume, attached to DamageEventTarget
            Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Random integer number between 1 and 4) Equal to 1
                    Then - Actions
                        Sound - Play Tradeskill_MiningHitB <gen> at 100.00% volume, attached to DamageEventTarget
                    Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 3) Equal to 1
                            Then - Actions
                                Sound - Play Tradeskill_MiningHitC <gen> at 100.00% volume, attached to DamageEventTarget
                            Else - Actions
                                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                                    If - Conditions
                                        (Random integer number between 1 and 2) Equal to 1
                                    Then - Actions
                                        Sound - Play Tradeskill_MiningHitD <gen> at 100.00% volume, attached to DamageEventTarget
                                    Else - Actions
                                        Sound - Play Tradeskill_MiningHitE <gen> at 100.00% volume, attached to DamageEventTarget
