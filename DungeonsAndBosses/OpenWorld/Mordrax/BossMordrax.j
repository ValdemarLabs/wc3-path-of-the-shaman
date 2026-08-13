/**
    BossMordrax
    Author: Valdemar
    Version: 1.0.0
    Description:
    Replaces Mordrax's patrol, combat, fire-orb, loot, dialogue, death-flight,
    and respawn flow.
    Credits:
    - Legacy Mordrax GUI exports.
    How to install:
    Import after Boss, BossMordraxDialogue, PatrolSystem, and CreepRespawn.
    API:
    - BossMordrax_GetId()
*/
library BossMordrax initializer Init requires Boss, BossMordraxDialogue, PatrolSystem, CreepRespawn
    globals
        private integer BossId = 0
        private timer OrbTimer = null
        private timer ResetTimer = null
        private timer FlightTimer = null
        private timer RespawnTimer = null
        private group TargetGroup = null
    endglobals

    private function StartPatrol takes unit whichUnit returns nothing
        call PatrolSystem_Begin(whichUnit)
        call PatrolSystem_SetPoint(whichUnit, 0, GetRectCenterX(gg_rct_MordraxWP01), GetRectCenterY(gg_rct_MordraxWP01), 15.00)
        call PatrolSystem_SetPoint(whichUnit, 1, GetRectCenterX(gg_rct_MordraxWP02), GetRectCenterY(gg_rct_MordraxWP02), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 2, GetRectCenterX(gg_rct_MordraxWP03), GetRectCenterY(gg_rct_MordraxWP03), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 3, GetRectCenterX(gg_rct_MordraxWP04), GetRectCenterY(gg_rct_MordraxWP04), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 4, GetRectCenterX(gg_rct_MordraxWP05), GetRectCenterY(gg_rct_MordraxWP05), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 5, GetRectCenterX(gg_rct_MordraxWP06), GetRectCenterY(gg_rct_MordraxWP06), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 6, GetRectCenterX(gg_rct_MordraxWP07), GetRectCenterY(gg_rct_MordraxWP07), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 7, GetRectCenterX(gg_rct_MordraxWP08), GetRectCenterY(gg_rct_MordraxWP08), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 8, GetRectCenterX(gg_rct_MordraxWP09), GetRectCenterY(gg_rct_MordraxWP09), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 9, GetRectCenterX(gg_rct_MordraxWP10), GetRectCenterY(gg_rct_MordraxWP10), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 10, GetRectCenterX(gg_rct_MordraxWP11), GetRectCenterY(gg_rct_MordraxWP11), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 11, GetRectCenterX(gg_rct_MordraxWP12), GetRectCenterY(gg_rct_MordraxWP12), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 12, GetRectCenterX(gg_rct_MordraxWP13), GetRectCenterY(gg_rct_MordraxWP13), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 13, GetRectCenterX(gg_rct_MordraxWP14), GetRectCenterY(gg_rct_MordraxWP14), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 14, GetRectCenterX(gg_rct_MordraxWP15), GetRectCenterY(gg_rct_MordraxWP15), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 15, GetRectCenterX(gg_rct_MordraxWP16), GetRectCenterY(gg_rct_MordraxWP16), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 16, GetRectCenterX(gg_rct_MordraxWP17), GetRectCenterY(gg_rct_MordraxWP17), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 17, GetRectCenterX(gg_rct_MordraxWP18), GetRectCenterY(gg_rct_MordraxWP18), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 18, GetRectCenterX(gg_rct_MordraxWP19), GetRectCenterY(gg_rct_MordraxWP19), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 19, GetRectCenterX(gg_rct_MordraxWP20), GetRectCenterY(gg_rct_MordraxWP20), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 20, GetRectCenterX(gg_rct_MordraxWP21), GetRectCenterY(gg_rct_MordraxWP21), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 21, GetRectCenterX(gg_rct_MordraxWP22), GetRectCenterY(gg_rct_MordraxWP22), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 22, GetRectCenterX(gg_rct_MordraxWP23), GetRectCenterY(gg_rct_MordraxWP23), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 23, GetRectCenterX(gg_rct_MordraxWP24), GetRectCenterY(gg_rct_MordraxWP24), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 24, GetRectCenterX(gg_rct_MordraxWP25), GetRectCenterY(gg_rct_MordraxWP25), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 25, GetRectCenterX(gg_rct_MordraxWP26), GetRectCenterY(gg_rct_MordraxWP26), 0.00)
        call PatrolSystem_StartConfigured(whichUnit, 26, 30.00, PATROL_STYLE_LOOP, true, "attack", 120.00)
    endfunction

    private function CastFireOrbs takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)
        local unit picked = null
        local unit target = null
        local integer candidates = 0
        local real angle
        if Boss_IsActive(BossId) and whichUnit != null then
            call GroupEnumUnitsInRange(TargetGroup, GetUnitX(whichUnit), GetUnitY(whichUnit), 1000.00, null)
            loop
                set picked = FirstOfGroup(TargetGroup)
                exitwhen picked == null
                call GroupRemoveUnit(TargetGroup, picked)
                if GetWidgetLife(picked) > 0.405 and IsUnitEnemy(picked, GetOwningPlayer(whichUnit)) and GetUnitTypeId(picked) != udg_Totem then
                    set candidates = candidates + 1
                    if GetRandomInt(1, candidates) == 1 then
                        set target = picked
                    endif
                endif
            endloop
            if target != null then
                set angle = Atan2(GetUnitY(target) - GetUnitY(whichUnit), GetUnitX(target) - GetUnitX(whichUnit))
                call IssuePointOrder(whichUnit, "darksummoning", GetUnitX(whichUnit) + 150.00 * Cos(angle), GetUnitY(whichUnit) + 150.00 * Sin(angle))
            endif
        endif
        call GroupClear(TargetGroup)
        set target = null
        set picked = null
        set whichUnit = null
    endfunction
    private function CheckReset takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit picked = null
        local boolean enemyFound = false
        if Boss_IsActive(BossId) and boss != null then
            call GroupEnumUnitsInRange(TargetGroup, GetUnitX(boss), GetUnitY(boss), 1000.00, null)
            loop
                set picked = FirstOfGroup(TargetGroup)
                exitwhen picked == null
                call GroupRemoveUnit(TargetGroup, picked)
                if GetWidgetLife(picked) > 0.405 and IsUnitEnemy(picked, GetOwningPlayer(boss)) then
                    set enemyFound = true
                    exitwhen true
                endif
            endloop
            call GroupClear(TargetGroup)
            if not enemyFound then
                call Boss_Reset(BossId)
            endif
        endif
        set picked = null
        set boss = null
    endfunction
    private function OnStart takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call PatrolSystem_Pause(boss)
        call SetUnitFlyHeight(boss, 100.00, 2.00)
        call UnitRemoveAbility(boss, 'Amrf')
        call TimerStart(OrbTimer, 10.00, true, function CastFireOrbs)
        call TimerStart(ResetTimer, 10.00, true, function CheckReset)
        call BossMordraxDialogue_SetEnabled(true)
        call BossMordraxDialogue_PlayStart()
        set boss = null
    endfunction
    private function OnReset takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)
        call PauseTimer(OrbTimer)
        call PauseTimer(ResetTimer)
        call BossMordraxDialogue_SetEnabled(false)
        if whichUnit != null then
            call UnitAddAbility(whichUnit, 'Amrf')
            call SetUnitFlyHeight(whichUnit, 600.00, 5.00)
            call SetUnitMoveSpeed(whichUnit, 120.00)
            call PatrolSystem_Continue(whichUnit)
        endif
        set whichUnit = null
    endfunction
    private function FinishDeathFlight takes nothing returns nothing
        call Boss_FinishScriptedDefeat(BossId)
    endfunction
    private function OnDefeat takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit lootDummy = null
        local real angle = GetRandomReal(0.00, 2.00 * bj_PI)
        call PauseTimer(OrbTimer)
        call PauseTimer(ResetTimer)
        set lootDummy = CreateUnit(Player(11), 'n022', GetUnitX(boss), GetUnitY(boss), 0.00)
        if lootDummy != null then
            call CreepRespawn_DiscardUnit(lootDummy)
            call KillUnit(lootDummy)
        endif
        call PlaySoundOnUnitBJ(gg_snd_BloodSplat, 100.00, boss)
        call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Other\\HumanBloodCinematicEffect\\HumanBloodCinematicEffect.mdl", boss, "chest"))
        call BossMordraxDialogue_PlayDeath()
        call BossMordraxDialogue_SetEnabled(false)
        call SetUnitOwner(boss, Player(PLAYER_NEUTRAL_PASSIVE), false)
        call PauseUnit(boss, false)
        call UnitAddAbility(boss, 'Amrf')
        call SetUnitMoveSpeed(boss, 150.00)
        call SetUnitFlyHeight(boss, 2000.00, 50.00)
        call IssuePointOrder(boss, "move", GetUnitX(boss) + 5000.00 * Cos(angle), GetUnitY(boss) + 5000.00 * Sin(angle))
        call TimerStart(FlightTimer, 5.00, false, function FinishDeathFlight)
        set lootDummy = null
        set boss = null
    endfunction
    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossMordrax = boss
            call UnitAddAbility(boss, 'Amrf')
            call SetUnitMoveSpeed(boss, 120.00)
            call SetUnitFlyHeight(boss, 600.00, 5.00)
            call StartPatrol(boss)
            call BossMordraxDialogue_Bind(boss)
            call BossMordraxDialogue_SetEnabled(false)
        endif
        set boss = null
    endfunction
    private function OnDeath takes nothing returns nothing
        call PauseTimer(OrbTimer)
        call PauseTimer(ResetTimer)
        call TimerStart(RespawnTimer, GetRandomReal(240.00, 500.00), false, function Respawn)
    endfunction
    public function GetId takes nothing returns integer
        return BossId
    endfunction
    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = udg_BossMordrax
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Mordrax", null)
        endif
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Mordrax the Desolator (Level 15)", null)
        endif
        if whichUnit != null then
            set udg_BossMordrax = whichUnit
            set BossId = Boss_Register(whichUnit, "Mordrax")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetDefeatMode(BossId, BOSS_DEFEAT_MODE_SCRIPTED)
            call Boss_SetHome(BossId, GetRectCenterX(gg_rct_MordraxWP01), GetRectCenterY(gg_rct_MordraxWP01), GetUnitFacing(whichUnit))
            call Boss_SetDescription(BossId, "A flying desolator that leaves his patrol when combat begins.", "One recovered combat phase; he resumes patrol after a reset and flies away on scripted defeat.", "Every ten seconds he aims a Dark Summoning-style fire-orb cast near a random target.", "Fight him away from his patrol route and avoid the targeted orb impact.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnReset)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEFEAT, function OnDefeat)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
            call BossMordraxDialogue_Bind(whichUnit)
            call BossMordraxDialogue_SetEnabled(false)
            call StartPatrol(whichUnit)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction
    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set OrbTimer = CreateTimer()
        set ResetTimer = CreateTimer()
        set FlightTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        set TargetGroup = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
