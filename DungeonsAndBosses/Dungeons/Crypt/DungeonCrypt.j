/**
    DungeonCrypt

    Author: Valdemar
    Version: 1.0.0

    Description:
    Registers The Crypt with Dungeon and replaces its recoverable floor-spike
    trap. The three ZonesCore entry rects are used to collect dungeon creeps.

    Credits:
    - DungeonsAndBosses/Dungeons/Crypt/_oldGUI/Events

    How to install:
    Import after Dungeon and Table. Keep CryptTrap1 and the spike doodad
    placement; disable the legacy Crypt trap triggers.

    API:
    - DungeonCrypt_GetDungeonId() returns integer

**/
library DungeonCrypt initializer Init requires Dungeon, ZoneEvent, Table
    globals
        private constant integer ZONE_ID = 102
        private constant integer UNIT_DUMMY_DAMAGE = 'n014'
        private constant integer DOODAD_SPIKE = 'D6B9'
        private constant real TRAP_DELAY = 1.00
        private constant real TRAP_DAMAGE = 65000.00

        private integer DungeonId = 0
        private Table TrapTargets = 0
        private trigger TrapTrigger = null
        private group RegisterGroup = null
    endglobals

    private function IsTrapTarget takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetUnitAbilityLevel(whichUnit, 'Aloc') == 0
    endfunction

    private function RestoreSpikes takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()

        call SetDoodadAnimationRect(gg_rct_CryptTrap1, DOODAD_SPIKE, "stand", false)
        call DestroyTimer(whichTimer)
        set whichTimer = null
    endfunction

    private function DamageTrapTarget takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()
        local integer timerId = GetHandleId(whichTimer)
        local unit target = TrapTargets.unit[timerId]
        local unit dummy = null
        local timer restoreTimer = null

        if IsTrapTarget(target) then
            set dummy = CreateUnit(Player(11), UNIT_DUMMY_DAMAGE, GetUnitX(target), GetUnitY(target), 0.00)
            if dummy != null then
                call UnitApplyTimedLife(dummy, 'BTLF', 1.00)
                call UnitDamageTarget(dummy, target, TRAP_DAMAGE, true, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
            endif
            call SetDoodadAnimationRect(gg_rct_CryptTrap1, DOODAD_SPIKE, "spell", false)
            set restoreTimer = CreateTimer()
            call TimerStart(restoreTimer, 2.00, false, function RestoreSpikes)
        endif
        call TrapTargets.unit.remove(timerId)
        call DestroyTimer(whichTimer)
        set dummy = null
        set target = null
        set restoreTimer = null
        set whichTimer = null
    endfunction

    private function OnTrapEnter takes nothing returns nothing
        local unit entering = GetTriggerUnit()
        local timer delayTimer

        if IsTrapTarget(entering) then
            set delayTimer = CreateTimer()
            set TrapTargets.unit[GetHandleId(delayTimer)] = entering
            call TimerStart(delayTimer, TRAP_DELAY, false, function DamageTrapTarget)
            set delayTimer = null
        endif
        set entering = null
    endfunction

    private function RegisterCryptCreep takes nothing returns nothing
        local unit picked = GetEnumUnit()
        if picked != null and not Boss_IsRegistered(picked) and GetWidgetLife(picked) > 0.405 and IsUnitEnemy(picked, Player(0)) and not IsUnitType(picked, UNIT_TYPE_STRUCTURE) and GetUnitAbilityLevel(picked, 'Aloc') == 0 then
            if GetRandomReal(0.00, 100.00) <= 35.00 then
                call Dungeon_RegisterUnit(DungeonId, picked, DUNGEON_RESPAWN_RANDOM, 120.00, 320.00)
            else
                call Dungeon_RegisterUnit(DungeonId, picked, DUNGEON_RESPAWN_FULL, 120.00, 320.00)
            endif
        endif
        set picked = null
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()

        set DungeonId = Dungeon_Register(ZONE_ID, gg_rct_DungeonCrypt01B, gg_rct_Dungeon02StartingPoint, 300.00)
        call Dungeon_AddArea(DungeonId, gg_rct_DungeonCrypt)
        call ZoneEvent_RegisterEntranceTransition(ZONE_ID, gg_rct_DungeonCrypt01A, gg_rct_Dungeon02StartingPoint, 90.00)
        call ZoneEvent_RegisterEntranceTransition(ZONE_ID, gg_rct_DungeonCrypt01B, gg_rct_Dungeon02StartingPoint, 90.00)
        call ZoneEvent_RegisterEntranceTransition(ZONE_ID, gg_rct_DungeonCrypt01C, gg_rct_Dungeon02StartingPoint, 90.00)
        call ZoneEvent_RegisterExitTransition(ZONE_ID, gg_rct_LeavingDungeon2, gg_rct_DungeonCryptOut, 290.00)
        call ZoneEvent_SetFastPanOnEnter(ZONE_ID, true)
        call GroupEnumUnitsInRect(RegisterGroup, gg_rct_DungeonCrypt, null)
        call ForGroup(RegisterGroup, function RegisterCryptCreep)
        call GroupClear(RegisterGroup)
        call DestroyTimer(whichTimer)
        set whichTimer = null
    endfunction

    public function GetDungeonId takes nothing returns integer
        return DungeonId
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set TrapTargets = Table.create()
        set RegisterGroup = CreateGroup()
        set TrapTrigger = CreateTrigger()
        call TriggerRegisterEnterRectSimple(TrapTrigger, gg_rct_CryptTrap1)
        call TriggerAddAction(TrapTrigger, function OnTrapEnter)
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
