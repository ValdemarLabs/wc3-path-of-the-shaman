/**
    BossJinvorrak
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers the Jinvorrak statue catalog entry.
    Credits:
    - Legacy Jinvorrak Statue GUI export.
    How to install:
    Import after Boss.
    API:
    - BossJinvorrak_GetId()
*/
library BossJinvorrak initializer Init requires Boss
    globals
        private integer BossId = 0
    endglobals

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = Boss_FindUnitByName("Jinvorrak (Statue)", null)
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Jinvorrak", null)
        endif

        if whichUnit != null then
            set BossId = Boss_Register(whichUnit, "Jinvorrak")
            call Boss_SetDescription(BossId, "A silent Jinvorrak statue.", "No combat phase is defined in the recovered map triggers.", "The statue is frozen in place.", "This is currently a world landmark, not an active encounter.")
            call SetUnitAnimationByIndex(whichUnit, 0)
            call SetUnitTimeScale(whichUnit, 0.00)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
