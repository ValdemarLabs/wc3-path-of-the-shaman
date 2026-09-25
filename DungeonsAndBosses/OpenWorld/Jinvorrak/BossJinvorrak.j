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
        private constant integer UNIT_JINVORRAK_STATUE = 'n01J'
        private integer BossId = 0
    endglobals

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = Boss_FindUnitByType(UNIT_JINVORRAK_STATUE, null)

        if whichUnit != null then
            set BossId = Boss_Register(whichUnit, "Jinvorrak")
            call Boss_SetDescription(BossId, "A silent Jinvorrak statue.", "No combat phase is defined in the recovered map triggers.", "The statue is frozen in place.", "This is currently a world landmark, not an active encounter.")
            call SetUnitAnimationByIndex(whichUnit, 0)
            call SetUnitTimeScale(whichUnit, 0.00)
        else
            call BJDebugMsg("|cffff8080[BossJinvorrak] ERROR:|r Could not find placed Jinvorrak statue unit 'n01J'.")
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
