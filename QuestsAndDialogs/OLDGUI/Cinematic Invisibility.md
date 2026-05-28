Cinematic Invisibility
    Events
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                InCinematic Equal to True
            Then - Actions
                Custom script:   set bj_wantDestroyGroup = true
                Unit Group - Pick every unit in (Units in (Playable map area)) and do (Actions)
                    Loop - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Level of Ghost Wolf (Passive) for (Picked unit)) Equal to 5
                                Or - Any (Conditions) are true
                                    Conditions
                                        (Unit-type of (Picked unit)) Equal to Nazgrek (Ghost Wolf - Level 1)
                                        (Unit-type of (Picked unit)) Equal to Zul'kis (melee Ghost Wolf - Level 1)
                            Then - Actions
                                Unit - Remove Permanent Invisibility from (Picked unit)
                            Else - Actions
            Else - Actions
                Custom script:   set bj_wantDestroyGroup = true
                Unit Group - Pick every unit in (Units in (Playable map area)) and do (Actions)
                    Loop - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Level of Ghost Wolf (Passive) for (Picked unit)) Equal to 5
                                Or - Any (Conditions) are true
                                    Conditions
                                        (Unit-type of (Picked unit)) Equal to Nazgrek (Ghost Wolf - Level 1)
                                        (Unit-type of (Picked unit)) Equal to Zul'kis (melee Ghost Wolf - Level 1)
                            Then - Actions
                                Unit - Add Permanent Invisibility to (Picked unit)
                            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                InCinematic Equal to True
            Then - Actions
                Custom script:   set bj_wantDestroyGroup = true
                Unit Group - Pick every unit in (Units in (Playable map area)) and do (Actions)
                    Loop - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ((Picked unit) has buff Stealth ) Equal to True
                            Then - Actions
                                Unit - Order (Picked unit) to Orc Blademaster - Wind Walk.
                            Else - Actions
            Else - Actions
