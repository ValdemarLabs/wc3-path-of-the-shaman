Button Pressed in KribugsDialog02
    Events
        Dialog - A dialog button is clicked for KribugsDialog02
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Special
            Then - Actions
                -------- SPECIAL DEAL --------
                Trigger - Turn on KribugsDialog01 Accept Quest 1 <gen>
                Cinematic - Disable user control for (All players).
                -------- CHECK IF PLAYER HAS GOLD --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Player 1 (Red) Current gold) Less than 1000
                    Then - Actions
                        -------- No gold --------
                        Game - Display to (All players) the text: (You don't have enough gold. + <Empty String>)
                        Wait 2.00 seconds
                        -------- ====================== --------
                        -------- Run "Create Dialog" --------
                        Trigger - Run Create KribugsDialog01 <gen> (checking conditions)
                        Trigger - Turn on (This trigger)
                        Skip remaining actions
                    Else - Actions
                        -------- Sound effect --------
                        Wait 0.50 seconds
                        Player - Add -1000 to Player 1 (Red).Current gold
                        Sound - Play Interface_LootCoin <gen>
                        -------- CREATE RANDOM ITEM --------
                        -------- xxx action --------
                        -------- xxx action --------
                        -------- xxx action --------
                        Game - Display to (All players) the text: (Item received:  + XXX)
                        Wait 1.00 seconds
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Random integer number between 1 and 3) Equal to 1
                            Then - Actions
                                Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Heh-heh! You paid, ....  Modify duration: Set to 5.00 seconds and Wait
                            Else - Actions
                                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                                    If - Conditions
                                        (Random integer number between 1 and 2) Equal to 2
                                    Then - Actions
                                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display See? Totally worth ....  Modify duration: Set to 5.00 seconds and Wait
                                    Else - Actions
                                        Cinematic - Send transmission to (All players) from Kribugs named Kribugs: Play No sound and display Lucky you! Or unluc....  Modify duration: Set to 5.00 seconds and Wait
                        -------- OVER --------
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
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Clicked dialog button) Equal to DialogBTN_Previous
            Then - Actions
                -------- ====================== --------
                -------- Run "Create Dialog" --------
                Trigger - Run Create KribugsDialog01 <gen> (checking conditions)
                Trigger - Turn on (This trigger)
                Skip remaining actions
            Else - Actions
