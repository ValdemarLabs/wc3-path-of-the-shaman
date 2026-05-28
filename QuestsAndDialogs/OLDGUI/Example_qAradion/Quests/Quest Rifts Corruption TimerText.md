Quest Rifts Corruption TimerText
    Events
        Time - Every 1.00 seconds of game time
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                QuestRiftsCorruptionCountdown Greater than 0
            Then - Actions
                Set VariableSet AradionPoint = (Position of Aradion)
                Floating Text - Create floating text that reads ((String(QuestRiftsCorruptionCountdown)) + |cffff0000|r) at AradionPoint with Z offset 75.00, using font size 10.00, color (100.00%, 20.00%, 20.00%), and 0.00% transparency
                Floating Text - Set the velocity of (Last created floating text) to 0.00 towards 90.00 degrees
                Floating Text - Change (Last created floating text): Disable permanence
                Floating Text - Change the lifespan of (Last created floating text) to 1.00 seconds
                Floating Text - Change the fading age of (Last created floating text) to 0.20 seconds
                Custom script:   call RemoveLocation(udg_AradionPoint)
                Set VariableSet QuestRiftsCorruptionCountdown = (QuestRiftsCorruptionCountdown - 1)
            Else - Actions
                Trigger - Turn off (This trigger)
