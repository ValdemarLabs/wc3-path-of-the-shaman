Quest Fading Sparks Start
    Events
        Unit - A unit Starts the effect of an ability
    Conditions
        (Ability being cast) Equal to Drain Essence 
        Or - Any (Conditions) are true
            Conditions
                (Unit-type of (Target unit of ability being cast)) Equal to Mana Wraith (Level 16)
    Actions
        Set VariableSet VarPoint = (Position of (Triggering unit))
        Unit - Order (Target unit of ability being cast) to Attack-Move To VarPoint
        Custom script:   call RemoveLocation(udg_VarPoint)
        -------- CASTER --------
        Set VariableSet QuestFadingSparksCaster = (Triggering unit)
        -------- TARGET --------
        Set VariableSet CV = (Custom value of (Target unit of ability being cast))
        Set VariableSet QuestFadingSparksTarget = (Target unit of ability being cast)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Percentage life of QuestFadingSparksTarget) Greater than 50.00
            Then - Actions
                -------- ======= Hint --------
                Game - Display to (All players) the text: |cffd45e19The targe...
                Skip remaining actions
            Else - Actions
        -------- start timer --------
        Countdown Timer - Start QuestFadingSparksTimer as a One-shot timer that will expire in 2.00 seconds
