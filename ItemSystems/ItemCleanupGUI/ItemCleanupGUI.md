Item Remove
    Events
        Time - Every 120.00 seconds of game time
    Conditions
    Actions
        Set VariableSet VarEntireMap = (Entire map)
        Item - Pick every item in VarEntireMap and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Custom value of (Picked item)) Greater than or equal to 4
                        (Item-class of (Picked item)) Not equal to Campaign
                        ((Picked item) is hidden) Equal to False
                    Then - Actions
                        Item - Remove (Picked item)
                    Else - Actions
                        Item - Set the custom value of (Picked item) to ((Custom value of (Picked item)) + 1)
        Custom script:   call RemoveRect(udg_VarEntireMap)


Item Picked
    Events
        Unit - A unit Acquires an item
    Conditions
    Actions
        Item - Set the custom value of (Item being manipulated) to 0

Item Cleanup
    Events
        Time - Every 15.00 seconds of game time
        Time - ICItemCleanupTimer expires
    Conditions
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ICItemCleanupFlag Equal to True
            Then - Actions
                Set VariableSet ICItemCleanupFlag = False
                --------   --------
                -------- Loop through all dead items and remove them --------
                --------   --------
                For each (Integer ICLoop) from 0 to ICItemsToClean, do (Actions)
                    Loop - Actions
                        Item - Set life of ICCleanedItem[ICLoop] to 1.00
                        Item - Remove ICCleanedItem[ICLoop]
                        Set VariableSet ICCleanedItem[ICLoop] = No item
            Else - Actions
                --------   --------
                -------- Clean up all dead items on the map every 15 seconds --------
                --------   --------
                Set VariableSet ICItemsToClean = -1
                Item - Pick every item in (Playable map area) and do (Actions)
                    Loop - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                ((Picked item) is hidden) Equal to False
                                (Current life of (Picked item)) Equal to 0.00
                            Then - Actions
                                Set VariableSet ICItemsToClean = (ICItemsToClean + 1)
                                Set VariableSet ICCleanedItem[ICItemsToClean] = (Picked item)
                            Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        ICItemsToClean Greater than or equal to 0
                    Then - Actions
                        --------   --------
                        -------- Start a 1.50 second timer to give time for any death animations to play --------
                        --------   --------
                        Countdown Timer - Start ICItemCleanupTimer as a One-shot timer that will expire in 1.50 seconds
                        Set VariableSet ICItemCleanupFlag = True
                    Else - Actions
