Valeria Movement Stop
    Events
    Conditions
    Actions
        -------- Fully stops the patrol system for the selected unit --------
        Set VariableSet TempUnit = Valeria
        Custom script:   call PatrolSystem_Stop(udg_TempUnit)
