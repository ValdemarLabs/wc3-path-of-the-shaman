Command Camera Lock
    Events
        Player - Player 1 (Red) types a chat message containing /cam lock as An exact match
    Conditions
    Actions
        Sound - Play IAMCHEAT <gen>
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Command_CameraLock Equal to True
            Then - Actions
                Set VariableSet Command_CameraLock = False
                Trigger - Turn on Camera Switch <gen>
            Else - Actions
                Set VariableSet Command_CameraLock = True
                Trigger - Turn off Camera Switch <gen>
