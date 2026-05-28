Valeria Negotiate Random Movement
    Events
        Time - Every 10.00 seconds of game time
    Conditions
        ValeriaEncounterReset Equal to False
    Actions
        Unit - Set Valeria movement speed to 420.00
        Set VariableSet ValeriaPoint = (Position of Valeria)
        Set VariableSet ValeriaPoint2 = (ValeriaPoint offset by (Random real number between 300.00 and 700.00) towards (Random angle) degrees.)
        Unit - Order Valeria to Move To ValeriaPoint2
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
        Custom script:   call RemoveLocation(udg_ValeriaPoint2)
        Special Effect - Create a special effect attached to the overhead of Valeria using Abilities\Spells\Items\AIsp\SpeedTarget.mdl
        Special Effect - Destroy (Last created special effect)
        Wait 3.00 seconds
        Unit - Set Valeria movement speed to (Default movement speed of Valeria)
