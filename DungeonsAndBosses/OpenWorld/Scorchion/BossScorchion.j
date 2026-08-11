/**
    BossScorchion

    Author: Valdemar
    Version: 1.0.0

    Description:
    Replaces Scorchion's recoverable Dark Shaman gate, timed fire attacks,
    lava ritual, fire-orb interaction, reset, and respawn triggers.

    Credits:
    - DungeonsAndBosses/OpenWorld/Scorchion/_oldGUI

    How to install:
    Import after Boss, DamageEngine, CreepRespawn, and UnitDeathEvent. Keep the
    named Scorchion and Dark Shaman rects and disable the legacy GUI triggers.

    API:
    - BossScorchion_GetId() returns integer

**/
library BossScorchion initializer Init requires Boss, DamageEngine, CreepRespawn, UnitDeathEvent
    globals
        private constant integer UNIT_DARK_SHAMAN = 'n00I'
        private constant integer UNIT_FIRE_ORB = 'n00F'
        private constant integer ABILITY_BLINK = 'A02B'
        private constant integer ABILITY_TEMPORAL_INSTABILITY = 'A02C'
        private constant integer ABILITY_FIRE_WARD = 'A02E'
        private constant integer ABILITY_INFERNAL_RAIN = 'A02G'
        private constant integer ABILITY_FIRE_ORB = 'A02J'
        private constant integer ABILITY_UNDYING_FLAME = 'A02K'
        private constant integer ABILITY_ETHEREAL = 'Aeth'
        private constant real DEFAULT_SCALE = 2.50

        private integer BossId = 0
        private integer BaseDamage = 0
        private integer EmpowerStacks = 0
        private boolean TemporalActive = false
        private integer RitualStage = 0
        private timer MeteorTimer = null
        private timer BlinkTimer = null
        private timer WardTimer = null
        private timer RitualTimer = null
        private timer OrbTickTimer = null
        private timer TemporalTimer = null
        private timer RespawnTimer = null
        private group ShamanGroup = null
        private group OrbGroup = null
        private group WorkGroup = null
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function ClearGroupUnits takes group whichGroup returns nothing
        local unit picked = null

        loop
            set picked = FirstOfGroup(whichGroup)
            exitwhen picked == null
            call GroupRemoveUnit(whichGroup, picked)
            if GetUnitTypeId(picked) != 0 then
                call KillUnit(picked)
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function CreateShaman takes rect spawnRect, real facing returns nothing
        local unit shaman = CreateUnit(Player(11), UNIT_DARK_SHAMAN, GetRectCenterX(spawnRect), GetRectCenterY(spawnRect), facing)
        if shaman != null then
            call CreepRespawn_DiscardUnit(shaman)
            call GroupAddUnit(ShamanGroup, shaman)
        endif
        set shaman = null
    endfunction

    private function ResetShamans takes nothing returns nothing
        call ClearGroupUnits(ShamanGroup)
        call CreateShaman(gg_rct_DarkShaman01, 47.00)
        call CreateShaman(gg_rct_DarkShaman02, 120.00)
        call CreateShaman(gg_rct_DarkShaman03, 160.00)
        call CreateShaman(gg_rct_DarkShaman04, 195.00)
    endfunction

    private function RegisterExistingShamans takes nothing returns nothing
        local unit picked = null
        call GroupClear(WorkGroup)
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_BossScorchionArea, null)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if GetUnitTypeId(picked) == UNIT_DARK_SHAMAN and IsAlive(picked) then
                call CreepRespawn_DiscardUnit(picked)
                call GroupAddUnit(ShamanGroup, picked)
            endif
        endloop
        set picked = null
    endfunction

    private function CountLivingGroup takes group sourceGroup returns integer
        local group swapGroup = null
        local unit picked = null
        local integer count = 0

        call GroupClear(WorkGroup)
        loop
            set picked = FirstOfGroup(sourceGroup)
            exitwhen picked == null
            call GroupRemoveUnit(sourceGroup, picked)
            if IsAlive(picked) then
                call GroupAddUnit(WorkGroup, picked)
                set count = count + 1
            endif
        endloop
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            call GroupAddUnit(sourceGroup, picked)
        endloop
        set swapGroup = null
        set picked = null
        return count
    endfunction

    private function GetRandomEnemy takes unit boss, real radius returns unit
        local unit picked = null
        local unit target = null

        call GroupClear(WorkGroup)
        call GroupEnumUnitsInRange(WorkGroup, GetUnitX(boss), GetUnitY(boss), radius, null)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) and IsUnitEnemy(picked, GetOwningPlayer(boss)) then
                set target = picked
                exitwhen true
            endif
        endloop
        call GroupClear(WorkGroup)
        set picked = null
        return target
    endfunction

    private function CastMeteors takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        if Boss_IsActive(BossId) and IsAlive(boss) then
            call UnitAddAbility(boss, ABILITY_INFERNAL_RAIN)
            call IssueImmediateOrder(boss, "thunderclap")
        endif
        set boss = null
    endfunction

    private function BlinkTarget takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit target = null
        if Boss_IsActive(BossId) and IsAlive(boss) then
            set target = GetRandomEnemy(boss, 1000.00)
            if target != null then
                call UnitAddAbility(boss, ABILITY_BLINK)
                call IssuePointOrder(boss, "blink", GetUnitX(target), GetUnitY(target))
            endif
        endif
        set target = null
        set boss = null
    endfunction

    private function CastWard takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit target = null
        if Boss_IsActive(BossId) and IsAlive(boss) then
            set target = GetRandomEnemy(boss, 700.00)
            if target != null then
                call UnitAddAbility(boss, ABILITY_FIRE_WARD)
                call IssuePointOrder(boss, "clusterrockets", GetUnitX(target), GetUnitY(target))
            endif
        endif
        set target = null
        set boss = null
    endfunction

    private function StartCombatTimers takes nothing returns nothing
        call TimerStart(MeteorTimer, 8.00, true, function CastMeteors)
        call TimerStart(BlinkTimer, 10.00, true, function BlinkTarget)
        call TimerStart(WardTimer, 15.00, true, function CastWard)
    endfunction

    private function PauseCombatTimers takes nothing returns nothing
        call PauseTimer(MeteorTimer)
        call PauseTimer(BlinkTimer)
        call PauseTimer(WardTimer)
    endfunction

    private function SpawnFireOrbs takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit orb = null
        local integer index = 0
        local integer count = GetRandomInt(2, 4)
        local real angle
        local real distance
        local real x
        local real y

        loop
            exitwhen index >= count
            set angle = GetRandomReal(0.00, 2.00 * bj_PI)
            set distance = GetRandomReal(400.00, 800.00)
            set x = GetUnitX(boss) + distance * Cos(angle)
            set y = GetUnitY(boss) + distance * Sin(angle)
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Doom\\DoomTarget.mdl", x, y))
            set orb = CreateUnit(Player(11), UNIT_FIRE_ORB, x, y, GetRandomReal(0.00, 360.00))
            if orb != null then
                call CreepRespawn_DiscardUnit(orb)
                call SetUnitInvulnerable(orb, true)
                call PauseUnit(orb, true)
                call GroupAddUnit(OrbGroup, orb)
            endif
            set orb = null
            set index = index + 1
        endloop
        set boss = null
    endfunction

    private function ConsumeOrb takes unit boss, unit orb returns nothing
        call GroupRemoveUnit(OrbGroup, orb)
        call KillUnit(orb)
        call RemoveUnit(orb)
        if EmpowerStacks < 5 then
            set EmpowerStacks = EmpowerStacks + 1
            call BlzSetUnitBaseDamage(boss, BaseDamage + 5 * EmpowerStacks, 0)
            call SetUnitScale(boss, DEFAULT_SCALE + 0.25 * EmpowerStacks, DEFAULT_SCALE + 0.25 * EmpowerStacks, DEFAULT_SCALE + 0.25 * EmpowerStacks)
        endif
    endfunction

    private function OrbTick takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit orb = FirstOfGroup(OrbGroup)
        local real dx
        local real dy

        if not Boss_IsActive(BossId) or not IsAlive(boss) then
            call PauseTimer(OrbTickTimer)
        elseif orb != null then
            set dx = GetUnitX(orb) - GetUnitX(boss)
            set dy = GetUnitY(orb) - GetUnitY(boss)
            if dx * dx + dy * dy <= 22500.00 then
                call ConsumeOrb(boss, orb)
            else
                call IssuePointOrder(boss, "move", GetUnitX(orb), GetUnitY(orb))
            endif
        endif
        set orb = null
        set boss = null
    endfunction

    private function EndTemporalInstability takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        set TemporalActive = false
        if boss != null then
            call UnitRemoveAbility(boss, ABILITY_TEMPORAL_INSTABILITY)
        endif
        set boss = null
    endfunction

    private function EndRitual takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit orb = null
        local integer orbCount

        call PauseTimer(OrbTickTimer)
        if not Boss_IsActive(BossId) or not IsAlive(boss) then
            set boss = null
            return
        endif
        call UnitRemoveAbility(boss, ABILITY_ETHEREAL)
        call UnitRemoveAbility(boss, ABILITY_FIRE_ORB)
        call SetUnitInvulnerable(boss, false)
        set orbCount = CountLivingGroup(OrbGroup)
        if orbCount == 0 then
            set TemporalActive = true
            call UnitAddAbility(boss, ABILITY_TEMPORAL_INSTABILITY)
            call TimerStart(TemporalTimer, 15.00, false, function EndTemporalInstability)
        else
            call GroupClear(WorkGroup)
            call BlzGroupAddGroupFast(OrbGroup, WorkGroup)
            loop
                set orb = FirstOfGroup(WorkGroup)
                exitwhen orb == null
                call GroupRemoveUnit(WorkGroup, orb)
                call PauseUnit(orb, false)
                call SetUnitInvulnerable(orb, false)
                call UnitAddAbility(orb, ABILITY_UNDYING_FLAME)
                call UnitApplyTimedLife(orb, 'BTLF', 30.00)
                call IssueTargetOrder(orb, "attack", boss)
            endloop
            call GroupClear(WorkGroup)
        endif
        call Boss_SetPhase(BossId, 1)
        call StartCombatTimers()
        set orb = null
        set boss = null
    endfunction

    private function BeginRitual takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if not Boss_IsActive(BossId) or not IsAlive(boss) then
            set boss = null
            return
        endif
        call Boss_SetPhase(BossId, 2)
        call PauseCombatTimers()
        call UnitAddAbility(boss, ABILITY_ETHEREAL)
        call UnitAddAbility(boss, ABILITY_FIRE_ORB)
        call SetUnitInvulnerable(boss, true)
        call IssuePointOrder(boss, "move", GetRectCenterX(gg_rct_BossScorchionLava), GetRectCenterY(gg_rct_BossScorchionLava))
        call ClearGroupUnits(OrbGroup)
        call SpawnFireOrbs()
        call TimerStart(OrbTickTimer, 1.00, true, function OrbTick)
        set boss = null
    endfunction

    private function RitualTimerExpired takes nothing returns nothing
        if RitualStage == 0 then
            set RitualStage = 1
            call BeginRitual()
            call TimerStart(RitualTimer, 50.00, false, function RitualTimerExpired)
        else
            set RitualStage = 0
            call EndRitual()
            if Boss_IsActive(BossId) then
                call TimerStart(RitualTimer, 60.00, false, function RitualTimerExpired)
            endif
        endif
    endfunction

    private function OnDamage takes nothing returns nothing
        if TemporalActive and udg_DamageEventTarget == Boss_GetUnit(BossId) then
            set udg_DamageEventAmount = udg_DamageEventAmount * 2.50
        endif
    endfunction

    private function OnStart takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call SetUnitOwner(boss, Player(11), true)
        call SetUnitInvulnerable(boss, false)
        call BlzSetUnitRealField(boss, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 0.50)
        call StartCombatTimers()
        set RitualStage = 0
        call TimerStart(RitualTimer, 60.00, false, function RitualTimerExpired)
        set boss = null
    endfunction

    private function StopEncounter takes nothing returns nothing
        call PauseCombatTimers()
        call PauseTimer(RitualTimer)
        call PauseTimer(OrbTickTimer)
        call PauseTimer(TemporalTimer)
        set TemporalActive = false
        set RitualStage = 0
        call ClearGroupUnits(OrbGroup)
    endfunction

    private function OnReset takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call StopEncounter()
        set EmpowerStacks = 0
        if boss != null then
            call UnitRemoveAbility(boss, ABILITY_ETHEREAL)
            call UnitRemoveAbility(boss, ABILITY_FIRE_ORB)
            call UnitRemoveAbility(boss, ABILITY_TEMPORAL_INSTABILITY)
            call UnitRemoveAbility(boss, ABILITY_BLINK)
            call UnitRemoveAbility(boss, ABILITY_INFERNAL_RAIN)
            call UnitRemoveAbility(boss, ABILITY_FIRE_WARD)
            call BlzSetUnitBaseDamage(boss, BaseDamage, 0)
            call SetUnitScale(boss, DEFAULT_SCALE, DEFAULT_SCALE, DEFAULT_SCALE)
            call SetUnitInvulnerable(boss, true)
        endif
        call ResetShamans()
        set boss = null
    endfunction

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossScorchion = boss
            call OnReset()
        endif
        set boss = null
    endfunction

    private function OnDeath takes nothing returns nothing
        call StopEncounter()
        call ClearGroupUnits(ShamanGroup)
        call TimerStart(RespawnTimer, GetRandomReal(240.00, 500.00), false, function Respawn)
    endfunction

    private function OnUnitDeath takes nothing returns nothing
        local unit dying = UnitDeathEvent_GetDyingUnit()
        if BossId > 0 and Boss_GetState(BossId) == BOSS_STATE_IDLE and IsUnitInGroup(dying, ShamanGroup) and CountLivingGroup(ShamanGroup) == 0 then
            call Boss_Start(BossId)
        endif
        set dying = null
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit boss = Boss_FindUnitByName("Scorchion (Level 20)", gg_rct_BossScorchionArea)
        if boss == null then
            set boss = Boss_FindUnitByName("Scorchion", gg_rct_BossScorchionArea)
        endif
        if boss != null then
            set udg_BossScorchion = boss
            set BossId = Boss_Register(boss, "Scorchion")
            set BaseDamage = BlzGetUnitBaseDamage(boss, 0)
            call Boss_SetArena(BossId, gg_rct_BossScorchionArea, Player(0), true)
            call Boss_SetPhaseCount(BossId, 2)
            call Boss_SetDescription(BossId, "A fire lord protected by four Dark Shaman worshippers.", "Kill all four worshippers to begin. After 60 seconds Scorchion enters a 50-second lava-and-orb ritual before returning to the main phase.", "Infernal Rain, Blink, Fire Ward, orb consumption that raises damage and size, Undying Flame backlash, and Temporal Instability when every orb is denied.", "Clear the shamans, keep moving through fire casts, and deny every orb during the ritual to gain the 15-second amplified-damage window.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnReset)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
            call SetUnitInvulnerable(boss, true)
            call RegisterExistingShamans()
            if CountLivingGroup(ShamanGroup) != 4 then
                call ResetShamans()
            endif
            call RegisterDamageEngine(function OnDamage, "Modifier", 1.00)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set boss = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        set MeteorTimer = CreateTimer()
        set BlinkTimer = CreateTimer()
        set WardTimer = CreateTimer()
        set RitualTimer = CreateTimer()
        set OrbTickTimer = CreateTimer()
        set TemporalTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        set ShamanGroup = CreateGroup()
        set OrbGroup = CreateGroup()
        set WorkGroup = CreateGroup()
        call UnitDeathEvent_Register(function OnUnitDeath)
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
