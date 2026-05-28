Quest Fading Sparks GatherReady
    Events
        Unit - A unit Finishes casting an ability
    Conditions
        And - All (Conditions) are true
            Conditions
                (Ability being cast) Equal to Drain Essence 
                QuestFadingSparksFinished Equal to True
    Actions
        Set VariableSet VarPoint = (Position of QuestFadingSparksTarget)
        Unit - Cause QuestFadingSparksCaster to damage QuestFadingSparksTarget, dealing 6000.00 damage of attack type Spells and damage type Normal
        Item - Create Wraith Essence at VarPoint
        Custom script:   call RemoveLocation(udg_VarPoint)
