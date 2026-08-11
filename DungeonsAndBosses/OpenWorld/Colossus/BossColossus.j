/**
    BossColossus
    Author: Valdemar
    Version: 1.0.0
    Description:
    Replaces the Emberpeak Colossus encounter, including its slam sequence,
    boulders, healing-golem intermission, dragonfire reversal, damage rules,
    reset presentation, and respawn.
    Credits:
    - Legacy Colossus GUI exports.
    How to install:
    Import after Boss, EmberpeakDragonfire, DamageEngine, CreepRespawn, and the
    map rect and sound globals. Disable the legacy Colossus GUI triggers.
    API:
    - BossColossus_GetId()
*/
library BossColossus initializer Init requires Boss, EmberpeakDragonfire, DamageEngine, CreepRespawn
    globals
        private constant integer UNIT_GOLEM = 'n64E'
        private constant integer ABILITY_SLAM = 'A6D2'
        private constant integer ABILITY_BOULDER = 'A6CY'
        private constant integer ABILITY_CLEAVE = 'A6DA'
        private constant integer BUFF_FLAME_STRIKE = 'BHfs'
        private integer BossId = 0
        private timer PhaseTimer = null
        private timer BoulderTimer = null
        private timer SlamTimer = null
        private timer GolemTimer = null
        private timer GolemBirthTimer = null
        private timer CleaveTimer = null
        private timer StartTimer = null
        private timer RespawnTimer = null
        private group GolemGroup = null
        private group WorkGroup = null
        private integer SlamPulseCount = 0
        private integer GolemCooldown = 0
        private integer CleaveMissingTime = 0
        private boolean BoulderActive = false
        private boolean GolemActive = false
        private boolean GolemBirthPending = false
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function ClearGolems takes nothing returns nothing
        local unit picked = null
        loop
            set picked = FirstOfGroup(GolemGroup)
            exitwhen picked == null
            call GroupRemoveUnit(GolemGroup, picked)
            if GetUnitTypeId(picked) != 0 then
                call KillUnit(picked)
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function CountAndOrderGolems takes nothing returns integer
        local group swapGroup = null
        local unit picked = null
        local unit boss = Boss_GetUnit(BossId)
        local integer count = 0

        call GroupClear(WorkGroup)
        loop
            set picked = FirstOfGroup(GolemGroup)
            exitwhen picked == null
            call GroupRemoveUnit(GolemGroup, picked)
            if IsAlive(picked) then
                call GroupAddUnit(WorkGroup, picked)
                call IssueTargetOrder(picked, "attack", boss)
                set count = count + 1
            endif
        endloop
        set swapGroup = GolemGroup
        set GolemGroup = WorkGroup
        set WorkGroup = swapGroup
        set udg_BossColossus_Golems = GolemGroup
        set swapGroup = null
        set picked = null
        set boss = null
        return count
    endfunction

    private function CreateGolem takes real x, real y, unit boss returns nothing
        local unit golem = CreateUnit(Player(11), UNIT_GOLEM, x, y, Atan2(GetUnitY(boss) - y, GetUnitX(boss) - x) * bj_RADTODEG)
        if golem != null then
            call CreepRespawn_DiscardUnit(golem)
            call GroupAddUnit(GolemGroup, golem)
            call SetUnitInvulnerable(golem, true)
            call PauseUnit(golem, true)
            call SetUnitAnimation(golem, "birth")
        endif
        set golem = null
    endfunction

    private function ActivateGolems takes nothing returns nothing
        local group copyGroup = CreateGroup()
        local unit picked = null
        local unit boss = Boss_GetUnit(BossId)

        set GolemBirthPending = false
        call BlzGroupAddGroupFast(GolemGroup, copyGroup)
        loop
            set picked = FirstOfGroup(copyGroup)
            exitwhen picked == null
            call GroupRemoveUnit(copyGroup, picked)
            if IsAlive(picked) then
                call SetUnitInvulnerable(picked, false)
                call PauseUnit(picked, false)
                call QueueUnitAnimation(picked, "stand")
                call IssueTargetOrder(picked, "attack", boss)
            endif
        endloop
        call DestroyGroup(copyGroup)
        set boss = null
        set picked = null
        set copyGroup = null
    endfunction

    private function GolemTick takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        if not Boss_IsActive(BossId) then
            call PauseTimer(GolemTimer)
        elseif Boss_GetPhase(BossId) < 2 then
            set GolemCooldown = 50
        elseif GolemBirthPending then
            set boss = null
            return
        elseif GolemActive and CountAndOrderGolems() == 0 then
            set GolemActive = false
            set GolemCooldown = 50
            call SetUnitInvulnerable(boss, false)
            call SetUnitMoveSpeed(boss, GetUnitDefaultMoveSpeed(boss))
            call PlaySoundOnUnitBJ(gg_snd_ColossusReady, 100.00, boss)
        elseif not GolemActive then
            set GolemCooldown = GolemCooldown - 1
            if GolemCooldown <= 0 and not BoulderActive then
                call SetUnitInvulnerable(boss, true)
                call SetUnitPosition(boss, GetRectCenterX(gg_rct_ColossusSpot), GetRectCenterY(gg_rct_ColossusSpot))
                call SetUnitMoveSpeed(boss, GetUnitDefaultMoveSpeed(boss) * 0.25)
                call SetUnitAnimation(boss, "spell slam")
                call CreateGolem(GetUnitX(boss) + 750.00, GetUnitY(boss), boss)
                call CreateGolem(GetUnitX(boss), GetUnitY(boss) + 750.00, boss)
                call CreateGolem(GetUnitX(boss) - 750.00, GetUnitY(boss), boss)
                call CreateGolem(GetUnitX(boss), GetUnitY(boss) - 750.00, boss)
                set GolemActive = true
                set GolemBirthPending = true
                call SetUnitInvulnerable(boss, false)
                call TimerStart(GolemBirthTimer, 2.00, false, function ActivateGolems)
            endif
        endif
        set boss = null
    endfunction

    private function OnDamage takes nothing returns nothing
        local unit target = udg_DamageEventTarget
        local unit source = udg_DamageEventSource
        if (target == Boss_GetUnit(BossId) or GetUnitTypeId(target) == UNIT_GOLEM) and GetUnitAbilityLevel(target, BUFF_FLAME_STRIKE) > 0 then
            set udg_DamageEventAmount = 0.00
        elseif BossId > 0 and target == Boss_GetUnit(BossId) and GetUnitTypeId(source) == UNIT_GOLEM then
            set udg_DamageEventAmount = -50.00
            set udg_DamageEventType = udg_DamageTypeHeal
            call UnitDamageTarget(target, source, 50.00, true, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
            call PlaySoundOnUnitBJ(gg_snd_ColossusHeal, 100.00, target)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Demon\\DemonBoltImpact\\DemonBoltImpact.mdl", target, "chest"))
        endif
        set source = null
        set target = null
    endfunction

    private function CastBoulder takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)
        local real delay

        if Boss_IsActive(BossId) and whichUnit != null and not GolemActive then
            if BoulderActive then
                call UnitRemoveAbility(whichUnit, ABILITY_BOULDER)
                set BoulderActive = false
                if Boss_GetPhase(BossId) == 1 then
                    set delay = GetRandomReal(10.00, 20.00)
                else
                    set delay = 30.00
                endif
                call TimerStart(BoulderTimer, delay, false, function CastBoulder)
                set whichUnit = null
                return
            endif
            call UnitAddAbility(whichUnit, ABILITY_BOULDER)
            set BoulderActive = true
            if Boss_GetPhase(BossId) == 1 then
                call IssuePointOrder(whichUnit, "breathoffire", GetUnitX(whichUnit) + 300.00 * Cos(GetUnitFacing(whichUnit) * bj_DEGTORAD), GetUnitY(whichUnit) + 300.00 * Sin(GetUnitFacing(whichUnit) * bj_DEGTORAD))
                call PlaySoundOnUnitBJ(gg_snd_Colossus04, 100.00, whichUnit)
                call TimerStart(BoulderTimer, 1.00, false, function CastBoulder)
            else
                call IssuePointOrder(whichUnit, "stampede", GetUnitX(whichUnit), GetUnitY(whichUnit))
                call PlaySoundOnUnitBJ(gg_snd_Colossus03, 100.00, whichUnit)
                call TimerStart(BoulderTimer, 10.00, false, function CastBoulder)
            endif
        endif
        set whichUnit = null
    endfunction

    private function CastSlam takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)

        if not Boss_IsActive(BossId) or Boss_GetPhase(BossId) != 1 or whichUnit == null then
            set SlamPulseCount = 0
            set whichUnit = null
            return
        endif
        if SlamPulseCount == 0 then
            call UnitAddAbility(whichUnit, ABILITY_SLAM)
            call SetUnitMoveSpeed(whichUnit, GetUnitDefaultMoveSpeed(whichUnit) * 0.25)
            call PlaySoundOnUnitBJ(gg_snd_Colossus01, 100.00, whichUnit)
            set SlamPulseCount = 1
            call TimerStart(SlamTimer, 1.00, false, function CastSlam)
        else
            call IssueImmediateOrderById(whichUnit, 852097)
            if SlamPulseCount == 5 then
                call PlaySoundOnUnitBJ(gg_snd_Colossus02, 100.00, whichUnit)
            endif
            if SlamPulseCount >= 10 then
                call UnitRemoveAbility(whichUnit, ABILITY_SLAM)
                call SetUnitMoveSpeed(whichUnit, GetUnitDefaultMoveSpeed(whichUnit))
                set SlamPulseCount = 0
                call TimerStart(SlamTimer, 40.00, false, function CastSlam)
            else
                set SlamPulseCount = SlamPulseCount + 1
                call TimerStart(SlamTimer, 1.00, false, function CastSlam)
            endif
        endif
        set whichUnit = null
    endfunction

    private function UpdateCleave takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)

        if Boss_IsActive(BossId) and whichUnit != null then
            if GetUnitAbilityLevel(whichUnit, BUFF_FLAME_STRIKE) > 0 then
                call UnitAddAbility(whichUnit, ABILITY_CLEAVE)
                set CleaveMissingTime = 0
            elseif GetUnitAbilityLevel(whichUnit, ABILITY_CLEAVE) > 0 then
                set CleaveMissingTime = CleaveMissingTime + 1
                if CleaveMissingTime >= 5 then
                    call UnitRemoveAbility(whichUnit, ABILITY_CLEAVE)
                    set CleaveMissingTime = 0
                endif
            else
                set CleaveMissingTime = 0
            endif
        endif
        set whichUnit = null
    endfunction
    private function CheckPhase takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)
        if Boss_IsActive(BossId) and whichUnit != null then
            if Boss_GetPhase(BossId) < 3 and GetUnitState(whichUnit, UNIT_STATE_LIFE) <= GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE) * 0.25 then
                call Boss_SetPhase(BossId, 3)
            elseif Boss_GetPhase(BossId) == 1 and GetUnitState(whichUnit, UNIT_STATE_LIFE) <= GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE) * 0.50 then
                call Boss_SetPhase(BossId, 2)
            endif
        endif
        set whichUnit = null
    endfunction
    private function ActivateFight takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if not Boss_IsActive(BossId) or boss == null then
            set boss = null
            return
        endif
        call PauseUnit(boss, false)
        call SetUnitOwner(boss, Player(11), true)
        call SetUnitInvulnerable(boss, false)
        call SetUnitTimeScale(boss, 1.00)
        call SetUnitAnimation(boss, "attack spell")
        call QueueUnitAnimation(boss, "stand")
        call EmberpeakDragonfire_SetMode(EMBERPEAK_DRAGONFIRE_PLAYERS)
        call TimerStart(PhaseTimer, 1.00, true, function CheckPhase)
        call TimerStart(CleaveTimer, 1.00, true, function UpdateCleave)
        call TimerStart(SlamTimer, 40.00, false, function CastSlam)
        call TimerStart(BoulderTimer, GetRandomReal(10.00, 20.00), false, function CastBoulder)
        call TimerStart(GolemTimer, 1.00, true, function GolemTick)
        set boss = null
    endfunction

    private function OnStart takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call SetUnitTimeScale(boss, 0.30)
        call SetUnitAnimation(boss, "birth")
        call PlaySoundOnUnitBJ(gg_snd_ColossusReady, 100.00, boss)
        call TimerStart(StartTimer, 6.00, false, function ActivateFight)
        set boss = null
    endfunction
    private function OnPhase takes nothing returns nothing
        if Boss_EventBossId == BossId and Boss_EventPhase == 2 then
            call PauseTimer(SlamTimer)
            set SlamPulseCount = 0
            set GolemCooldown = 50
        elseif Boss_EventBossId == BossId and Boss_EventPhase == 3 then
            call EmberpeakDragonfire_SetMode(EMBERPEAK_DRAGONFIRE_COLOSSUS)
        endif
    endfunction
    private function OnEnd takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call PauseTimer(PhaseTimer)
        call PauseTimer(SlamTimer)
        call PauseTimer(BoulderTimer)
        call PauseTimer(GolemTimer)
        call PauseTimer(GolemBirthTimer)
        call PauseTimer(CleaveTimer)
        call PauseTimer(StartTimer)
        call ClearGolems()
        set SlamPulseCount = 0
        set GolemCooldown = 0
        set CleaveMissingTime = 0
        set BoulderActive = false
        set GolemActive = false
        set GolemBirthPending = false
        call EmberpeakDragonfire_SetMode(EMBERPEAK_DRAGONFIRE_IDLE)
        if boss != null then
            call UnitRemoveAbility(boss, ABILITY_SLAM)
            call UnitRemoveAbility(boss, ABILITY_BOULDER)
            call UnitRemoveAbility(boss, ABILITY_CLEAVE)
            call SetUnitMoveSpeed(boss, GetUnitDefaultMoveSpeed(boss))
            call SetUnitTimeScale(boss, 1.00)
            call SetUnitAnimation(boss, "sleep")
            call PauseUnit(boss, true)
        endif
        set boss = null
    endfunction
    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossColossus = boss
            call SetUnitAnimation(boss, "sleep")
            call PauseUnit(boss, true)
            call EmberpeakDragonfire_SetBoss(boss)
            call EmberpeakDragonfire_SetMode(EMBERPEAK_DRAGONFIRE_IDLE)
        endif
        set boss = null
    endfunction
    private function OnDeath takes nothing returns nothing
        call OnEnd()
        call TimerStart(RespawnTimer, GetRandomReal(240.00, 500.00), false, function Respawn)
    endfunction
    public function GetId takes nothing returns integer
        return BossId
    endfunction
    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = Boss_FindUnitByName("Colossus (Level 15)", gg_rct_DragonFireSpam01)
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Colossus", gg_rct_DragonFireSpam01)
        endif
        if whichUnit != null then
            set udg_BossColossus = whichUnit
            set BossId = Boss_Register(whichUnit, "Colossus")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetArena(BossId, gg_rct_DragonFireSpam01, Player(0), true)
            call Boss_SetPhaseCount(BossId, 3)
            call Boss_SetDescription(BossId, "An Emberpeak giant empowered by the surrounding dragonfire.", "Slam phase; boulder and golem phase below 50%; dragonfire phase below 25%.", "Thunder Clap, splitting boulders, fire immunity, cleave, and healing golem spawns.", "Kill golems before they reach him, avoid forward boulders, and keep moving through dragonfire.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_PHASE, function OnPhase)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
            call RegisterDamageEngine(function OnDamage, "Modifier", 1.00)
            call EmberpeakDragonfire_SetBoss(whichUnit)
            call EmberpeakDragonfire_SetMode(EMBERPEAK_DRAGONFIRE_IDLE)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction
    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set PhaseTimer = CreateTimer()
        set BoulderTimer = CreateTimer()
        set SlamTimer = CreateTimer()
        set GolemTimer = CreateTimer()
        set GolemBirthTimer = CreateTimer()
        set CleaveTimer = CreateTimer()
        set StartTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        if udg_BossColossus_Golems == null then
            set udg_BossColossus_Golems = CreateGroup()
        endif
        set GolemGroup = udg_BossColossus_Golems
        set WorkGroup = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
