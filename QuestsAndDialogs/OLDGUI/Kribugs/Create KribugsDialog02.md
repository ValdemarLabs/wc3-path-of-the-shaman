Create KribugsDialog02
    Events
    Conditions
    Actions
        Cinematic - Enable user control for (All players).
        Dialog - Clear KribugsDialog02
        Dialog - Change the title of KribugsDialog02 to "Special Deal"
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Special Deal --------
                Dialog - Create a dialog button for KribugsDialog02 labelled Buy (1000 Gold)
                -------- BTN variable --------
                Set VariableSet DialogBTN_Special = (Last created dialog Button)
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
            Then - Actions
                -------- Exit dialog --------
                Dialog - Create a dialog button for KribugsDialog02 labelled - Previous
                -------- BTN variable --------
                Set VariableSet DialogBTN_Previous = (Last created dialog Button)
            Else - Actions
        -------- ======= SHOW DIALOG --------
        Dialog - Show KribugsDialog02 for Player 1 (Red)
