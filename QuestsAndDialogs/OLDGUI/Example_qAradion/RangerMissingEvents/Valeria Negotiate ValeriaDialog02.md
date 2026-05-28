Valeria Negotiate ValeriaDialog02
    Events
        Player - Player 1 (Red) skips a cinematic sequence
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Distance between (Position of Valeria) and (Position of Nazgrek)) Less than or equal to 1000.00
            Then - Actions
                Trigger - Turn off (This trigger)
                Cinematic - Enable user control for (All players).
                Dialog - Clear ValeriaDialog02
                Dialog - Change the title of ValeriaDialog02 to Persuade Valeria
                -------- -------- Shuffle indices 1–10 --------
                For each (Integer ValeriaLineLoopInt) from 1 to 10, do (Actions)
                    Loop - Actions
                        Set VariableSet ValeriaLineArray[ValeriaLineLoopInt] = ValeriaLineLoopInt
                For each (Integer ValeriaLineLoopInt) from 1 to 10, do (Actions)
                    Loop - Actions
                        Set VariableSet ValeriaTempInt = (Random integer number between ValeriaLineLoopInt and 10)
                        Set VariableSet ValeriaTempInt2 = ValeriaLineArray[ValeriaLineLoopInt]
                        Set VariableSet ValeriaLineArray[ValeriaLineLoopInt] = ValeriaLineArray[ValeriaTempInt]
                        Set VariableSet ValeriaLineArray[ValeriaTempInt] = ValeriaTempInt2
                -------- -------- Create up to 5 buttons -------- --------
                Set VariableSet DialogBTN_Count = 0
                For each (Integer ValeriaLineLoopInt) from 1 to 5, do (Actions)
                    Loop - Actions
                        Set VariableSet DialogBTN_Count = (DialogBTN_Count + 1)
                        Dialog - Create a dialog button for ValeriaDialog02 labelled ValeriaLines[ValeriaLineArray[ValeriaLineLoopInt]]
                        Set VariableSet DialogBTN_Button[DialogBTN_Count] = (Last created dialog Button)
                -------- ======= SHOW DIALOG --------
                Dialog - Show ValeriaDialog02 for Player 1 (Red)
            Else - Actions
                -------- ======= TOO FAR --------
                Game - Display to (All players) the text: |cffd45e19You must ...
