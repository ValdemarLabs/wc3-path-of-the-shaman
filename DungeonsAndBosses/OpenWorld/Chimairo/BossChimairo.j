/**
    BossChimairo
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers Chimairo and replaces its recoverable venom and frenzy triggers.
    Credits:
    - Legacy Chimairo GUI exports.
    How to install:
    Import after Boss and DamageEngine. Disable the matching legacy GUI triggers.
    API:
    - BossChimairo_GetId()
*/
library BossChimairo initializer Init requires Boss, DamageEngine
    globals
        private integer BossId = 0
        private constant integer BUFF_VENOMOUS_BREATH = 'B029'
        private constant integer BUFF_CORROSIVE_VENOM = 'B028'
        private constant integer UNIT_VENOM_DUMMY = 'n02A'
        private constant integer ABILITY_PREDATORS_FRENZY = 'A057'
        private timer RespawnTimer = null
    endglobals

    private function OnSpellDamage takes nothing returns nothing
        local unit source = udg_DamageEventSource
        local unit target = udg_DamageEventTarget
        local unit dummy = null

        if BossId > 0 and target == Boss_GetUnit(BossId) and Boss_IsActive(BossId) and Boss_GetPhase(BossId) < 4 and GetWidgetLife(target) <= GetUnitState(target, UNIT_STATE_MAX_LIFE) * 0.35 then
            call Boss_SetPhase(BossId, 4)
            call UnitAddAbility(target, ABILITY_PREDATORS_FRENZY)
            call IssueImmediateOrder(target, "berserk")
        endif

        if BossId > 0 and source == Boss_GetUnit(BossId) and target != null and udg_IsDamageSpell and GetUnitAbilityLevel(target, BUFF_VENOMOUS_BREATH) > 0 and GetUnitAbilityLevel(target, BUFF_CORROSIVE_VENOM) == 0 then
            set dummy = CreateUnit(Player(11), UNIT_VENOM_DUMMY, GetUnitX(target), GetUnitY(target), 0.00)
            call UnitApplyTimedLife(dummy, 'BTLF', 2.00)
            call IssueTargetOrder(dummy, "shadowstrike", target)
        endif
        set dummy = null
        set source = null
        set target = null
    endfunction

    private function OnReset takes nothing returns nothing
        call UnitRemoveAbility(Boss_GetUnit(BossId), ABILITY_PREDATORS_FRENZY)
    endfunction

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossChimairo = boss
        endif
        set boss = null
    endfunction

    private function OnDeath takes nothing returns nothing
        call TimerStart(RespawnTimer, GetRandomReal(120.00, 320.00), false, function Respawn)
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = Boss_FindUnitByName("Chimairo (Level 20)", null)
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Chimairo", null)
        endif
        if whichUnit != null then
            set udg_BossChimairo = whichUnit
            set BossId = Boss_Register(whichUnit, "Chimairo")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetPhaseCount(BossId, 4)
            call Boss_SetDescription(BossId, "A venomous chimera whose breath leaves victims open to Corrosive Venom.", "The first three legacy phase triggers are empty; below 35% health Chimairo enters Predator's Frenzy.", "Spell damage applies Corrosive Venom to targets already marked by Venomous Breath, while the final phase adds Berserk.", "Cleanse the breath mark before another spell lands, then save control and defensive cooldowns for the frenzy.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnReset)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
            call RegisterDamageEngine(function OnSpellDamage, "Modifier", 1.00)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction
    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
