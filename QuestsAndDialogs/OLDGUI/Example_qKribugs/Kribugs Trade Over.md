Kribugs Trade Over
    Events
        Time - KribugsTradeTimer expires
    Conditions
    Actions
        Set VariableSet KribugsTrade = False
        Trigger - Turn off Kribugs Floating Text Trade <gen>
        Trigger - Turn off Kribugs Trade Random Talk <gen>
        -------- == PATROL == --------
        Trigger - Run Kribugs Movement Continue <gen> (checking conditions)
