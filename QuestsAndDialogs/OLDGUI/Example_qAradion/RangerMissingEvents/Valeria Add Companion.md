Valeria Add Companion
    Events
    Conditions
    Actions
        Sound - Play Rescue <gen>
        Unit Group - Add Valeria to Companion_Group
        Unit Group - Add Valeria to CompanionFocusNazgrek
        Game - Display to (All players) the text: ((Name of Valeria) +  has joined the party!)
        Set VariableSet CompanionCount = (CompanionCount + 1)
        Set VariableSet CompanionUnit[CompanionCount] = Valeria
        Set VariableSet CompanionIndex[(Custom value of Valeria)] = CompanionCount
        Set VariableSet CompanionIcon[CompanionCount] = ReplaceableTextures\CommandButtons\BTNHighElvenArcher.blp
        Trigger - Run MultiboardUpdate Add Companion <gen> (checking conditions)
