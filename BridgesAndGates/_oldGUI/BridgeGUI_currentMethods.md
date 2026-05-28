Init 02 Environment
    Events
    Conditions
    Actions
        -------- Bridges, Gates, etc. --------
        -------- ============== HBRIDGE001 --------
        Destructible - Pick every destructible in HBridge001 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Destructible-type of (Picked destructible)) Equal to Invisible Platform
                    Then - Actions
                        Destructible - Kill (Picked destructible)
                    Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Destructible-type of (Picked destructible)) Equal to Pathing Blocker (Ground)
                            Then - Actions
                                Destructible - Kill (Picked destructible)
                            Else - Actions
        -------- ============== HBRIDGE001 Bridge enter A&B Pathing blockers --------
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR1 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[1] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR2 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[2] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR3 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[3] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR4 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[4] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR5 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[5] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR6 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[6] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR7 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[7] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR8 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[8] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR9 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[9] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR10 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[10] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR11 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[11] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge001PBR12 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge001_PBR1[12] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        -------- ============== HBRIDGE008 Bridge enter A&B Pathing blockers --------
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR1 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[1] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR2 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[2] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR3 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[3] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR4 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[4] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR5 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[5] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR6 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[6] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR7 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[7] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR8 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[8] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR9 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[9] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)
        Set VariableSet HBridgeTempPoint = (Center of HBridge008PBR10 <gen>)
        Destructible - Create a Pathing Blocker (Ground) at HBridgeTempPoint facing (Random angle) with scale 1.00 and variation 0
        Set VariableSet HBridge008_PBR[10] = (Last created destructible)
        Custom script:   call RemoveLocation(udg_HBridgeTempPoint)

=======================
HBridge001 Activate
    Events
        Unit - A unit enters HBridge001A <gen>
        Unit - A unit enters HBridge001B <gen>
    Conditions
        (Owner of (Triggering unit)) Equal to Player 1 (Red)
    Actions
        Trigger - Turn off (This trigger)
        Trigger - Turn on HBridge001 Deactivate <gen>
        -------- ========================================= --------
        -------- Temporal Neutrality for Player --------
        Unit - Make (Triggering unit) Invulnerable
        -------- Passivate under units --------
        -------- ############## PLACEHOLDER - THINK THIS - a) either pause under units OR b) make crossing units invulnerable / not controllable by player etc. --------
        -------- Kill Pathing Blockers on the Bridge A & B entering sides --------
        For each (Integer A) from 1 to 12, do (Actions)
            Loop - Actions
                Destructible - Kill HBridge001_PBR1[(Integer A)]
        -------- Resurrect Invisible Platform(s) for the Bridge --------
        Destructible - Pick every destructible in HBridge001 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Destructible-type of (Picked destructible)) Equal to Invisible Platform
                    Then - Actions
                        Destructible - Resurrect (Picked destructible) with (Max life of (Picked destructible)) life and Hide birth animation
                    Else - Actions
        -------- Resurrect bridge side Pathing Blockers - Do not pick A&B entering blockers --------
        Destructible - Pick every destructible in HBridge001 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Destructible-type of (Picked destructible)) Equal to Pathing Blocker (Ground)
                        And - All (Conditions) are true
                            Conditions
                                (Picked destructible) Not equal to HBridge001_PBR1[1]
                                (Picked destructible) Not equal to HBridge001_PBR1[2]
                                (Picked destructible) Not equal to HBridge001_PBR1[3]
                                (Picked destructible) Not equal to HBridge001_PBR1[4]
                                (Picked destructible) Not equal to HBridge001_PBR1[5]
                                (Picked destructible) Not equal to HBridge001_PBR1[6]
                                (Picked destructible) Not equal to HBridge001_PBR1[7]
                                (Picked destructible) Not equal to HBridge001_PBR1[8]
                                (Picked destructible) Not equal to HBridge001_PBR1[9]
                                (Picked destructible) Not equal to HBridge001_PBR1[10]
                                (Picked destructible) Not equal to HBridge001_PBR1[11]
                                (Picked destructible) Not equal to HBridge001_PBR1[12]
                    Then - Actions
                        Destructible - Resurrect (Picked destructible) with (Max life of (Picked destructible)) life and Hide birth animation
                    Else - Actions
===========================
HBridge001 Deactivate
    Events
        Unit - A unit enters HBridge001C <gen>
        Unit - A unit enters HBridge001D <gen>
    Conditions
        (Owner of (Triggering unit)) Equal to Player 1 (Red)
    Actions
        Trigger - Turn off (This trigger)
        Trigger - Turn on HBridge001 Activate <gen>
        -------- ========================================= --------
        -------- Temporal Neutrality for Player --------
        Unit - Make (Triggering unit) Vulnerable
        -------- Passivate under units --------
        -------- ############## PLACEHOLDER - THINK THIS - a) either pause under units OR b) make crossing units invulnerable / not controllable by player etc. --------
        -------- ========================================= --------
        -------- Kill Pathing Blockers on the Bridge side --------
        -------- Kill Invisible Platforms --------
        Destructible - Pick every destructible in HBridge001 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Or - Any (Conditions) are true
                            Conditions
                                (Destructible-type of (Picked destructible)) Equal to Invisible Platform
                                (Destructible-type of (Picked destructible)) Equal to Pathing Blocker (Ground)
                    Then - Actions
                        Destructible - Kill (Picked destructible)
                    Else - Actions
        -------- Resurrect Pathing Blockers on the Bridge A & B entering sides --------
        For each (Integer A) from 1 to 12, do (Actions)
            Loop - Actions
                Destructible - Resurrect HBridge001_PBR1[(Integer A)] with (Max life of (Last created destructible)) life and Hide birth animation
===========================
HBridge008 Activate
    Events
        Unit - A unit enters HBridge008A <gen>
        Unit - A unit enters HBridge008B <gen>
    Conditions
    Actions
        Trigger - Turn off (This trigger)
        Trigger - Turn on HBridge008 Deactivate <gen>
        -------- ========================================= --------
        -------- Temporal Neutrality for Player --------
        Unit - Make (Triggering unit) Invulnerable
        -------- Passivate under units --------
        -------- ############## PLACEHOLDER - THINK THIS - a) either pause under units OR b) make crossing units invulnerable / not controllable by player etc. --------
        -------- Kill Pathing Blockers on the Bridge A & B entering sides --------
        For each (Integer A) from 1 to 10, do (Actions)
            Loop - Actions
                Destructible - Kill HBridge008_PBR[(Integer A)]
        -------- Resurrect Invisible Platform(s) for the Bridge --------
        Destructible - Pick every destructible in HBridge008 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Destructible-type of (Picked destructible)) Equal to Invisible Platform
                    Then - Actions
                        Destructible - Resurrect (Picked destructible) with (Max life of (Picked destructible)) life and Hide birth animation
                    Else - Actions
        -------- Resurrect bridge side Pathing Blockers - Do not pick A&B entering blockers --------
        Destructible - Pick every destructible in HBridge008 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Destructible-type of (Picked destructible)) Equal to Pathing Blocker (Ground)
                        And - All (Conditions) are true
                            Conditions
                                (Picked destructible) Not equal to HBridge008_PBR[1]
                                (Picked destructible) Not equal to HBridge008_PBR[2]
                                (Picked destructible) Not equal to HBridge008_PBR[3]
                                (Picked destructible) Not equal to HBridge008_PBR[4]
                                (Picked destructible) Not equal to HBridge008_PBR[5]
                                (Picked destructible) Not equal to HBridge008_PBR[6]
                                (Picked destructible) Not equal to HBridge008_PBR[7]
                                (Picked destructible) Not equal to HBridge008_PBR[8]
                                (Picked destructible) Not equal to HBridge008_PBR[9]
                                (Picked destructible) Not equal to HBridge008_PBR[10]
                    Then - Actions
                        Destructible - Resurrect (Picked destructible) with (Max life of (Picked destructible)) life and Hide birth animation
                    Else - Actions
===========================
HBridge008 Deactivate
    Events
        Unit - A unit enters HBridge008C <gen>
        Unit - A unit enters HBridge008D <gen>
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Unit-type of (Triggering unit)) Equal to Transport Ship
                (Unit-type of (Triggering unit)) Equal to Orc Frigate
                (Unit-type of (Triggering unit)) Equal to Orc Transport Ship
                (Unit-type of (Triggering unit)) Equal to Orc Juggernaught
    Actions
        Trigger - Turn off (This trigger)
        Trigger - Turn on HBridge008 Activate <gen>
        -------- ========================================= --------
        -------- Temporal Neutrality for Player --------
        Unit - Make (Triggering unit) Vulnerable
        -------- Passivate under units --------
        -------- ############## PLACEHOLDER - THINK THIS - a) either pause under units OR b) make crossing units invulnerable / not controllable by player etc. --------
        -------- ========================================= --------
        -------- Kill Pathing Blockers on the Bridge side --------
        -------- Kill Invisible Platforms --------
        Destructible - Pick every destructible in HBridge008 <gen> and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Or - Any (Conditions) are true
                            Conditions
                                (Destructible-type of (Picked destructible)) Equal to Invisible Platform
                                (Destructible-type of (Picked destructible)) Equal to Pathing Blocker (Ground)
                    Then - Actions
                        Destructible - Kill (Picked destructible)
                    Else - Actions
        -------- Resurrect Pathing Blockers on the Bridge A & B entering sides --------
        For each (Integer A) from 1 to 10, do (Actions)
            Loop - Actions
                Destructible - Resurrect HBridge008_PBR[(Integer A)] with (Max life of (Last created destructible)) life and Hide birth animation

