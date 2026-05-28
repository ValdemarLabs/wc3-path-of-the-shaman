Quest Fading Sparks Stop
    Events
        Unit - A unit Stops casting an ability
    Conditions
        (Ability being cast) Equal to Drain Essence 
    Actions
        Set VariableSet QuestFadingSparksFinished = False
        Countdown Timer - Pause QuestFadingSparksTimer
