/**
    BossImpaler

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements Impaler's escalating Gnoll Hideout encounter.

    Credits:
    - DungeonsAndBosses/Dungeons/Gnoll Hideout/_oldGUI/Boss Impaler

    How to install:
    Import after Boss and DungeonGnollHideout. Keep the Impaler unit name and
    BossImpalerArea rect. Disable the legacy Impaler GUI triggers.

    API:
    - BossImpaler_GetId() returns integer

**/
library BossImpaler initializer Init requires Boss, DungeonGnollHideout
    globals
        private integer BossId = 0
        private timer FightTimer = null
        private real BaseArmor = 0.00
        private integer BaseDamage = 0
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function Fight takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local effect fx = null

        if not Boss_IsActive(BossId) or not IsAlive(boss) then
            call PauseTimer(FightTimer)
        else
            call BlzSetUnitArmor(boss, BlzGetUnitArmor(boss) + 1.00)
            call BlzSetUnitBaseDamage(boss, BlzGetUnitBaseDamage(boss, 0) + 3, 0)
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 1.00, "Impaler: Me strong!")
            set fx = AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\FaerieDragonInvis\\FaerieDragon_Invis.mdl", boss, "overhead")
            call DestroyEffect(fx)
        endif
        set fx = null
        set boss = null
    endfunction

    private function OnStart takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call TimerStart(FightTimer, 15.00, true, function Fight)
        endif
    endfunction

    private function OnEnd takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if Boss_EventBossId == BossId then
            call PauseTimer(FightTimer)
            if Boss_EventType == BOSS_EVENT_RESET and boss != null then
                call BlzSetUnitArmor(boss, BaseArmor)
                call BlzSetUnitBaseDamage(boss, BaseDamage, 0)
            endif
        endif
        set boss = null
    endfunction

    private function OnRespawn takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        set udg_BossImpaler = boss
        if boss != null then
            set BaseArmor = BlzGetUnitArmor(boss)
            set BaseDamage = BlzGetUnitBaseDamage(boss, 0)
        endif
        set boss = null
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit boss = Boss_FindUnitByName("Impaler", gg_rct_BossImpalerArea)

        if boss != null then
            set udg_BossImpaler = boss
            set BossId = Boss_Register(boss, "Impaler")
            set BaseArmor = BlzGetUnitArmor(boss)
            set BaseDamage = BlzGetUnitBaseDamage(boss, 0)
            call Boss_SetArena(BossId, gg_rct_BossImpalerArea, Player(0), true)
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetDescription(BossId, "A brutal gnoll champion who steadily hardens during a prolonged fight.", "One escalating phase.", "Every 15 seconds he gains armor and base damage.", "Finish the fight quickly; his scaling makes long engagements increasingly dangerous.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESPAWN, function OnRespawn)
            call Dungeon_RegisterBoss(DungeonGnollHideout_GetDungeonId(), BossId)
        endif
        call DestroyTimer(initTimer)
        set boss = null
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set FightTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
