Valeria WalkHome
    Events
        Time - ValeriaTimer expires
    Conditions
    Actions
        Unit - Make Valeria Vulnerable
        Set VariableSet ValeriaPoint = (Center of ValeriaNewPos <gen>)
        Unit - Order Valeria to Move To ValeriaPoint
        Custom script:   call RemoveLocation(udg_ValeriaPoint)
