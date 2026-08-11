/**
    DungeonBoomBrothersMine

    Author: Valdemar
    Version: 1.0.0

    Description:
    Migrates Boom Mine's recoverable patrol waves, explosive-barrel rock
    events, and Mad Blix's sole exported combat ability. Empty legacy Mad Blix
    phase/chat files contain no recoverable mechanics and are deliberately not
    invented here.

    Credits:
    - DungeonsAndBosses/Dungeons/Boom Brothers Mine/_oldGUI

    How to install:
    Import after Dungeon, Boss, Events, and UnitDeathEvent. Keep all named
    editor rects, Barrel of Explosives item/unit objects, and disable legacy
    Boom Mine GUI triggers.

    API:
    - DungeonBoomBrothersMine_GetDungeonId() returns integer

**/
library DungeonBoomBrothersMine initializer Init requires Dungeon, ZoneEvent, Boss, Events, UnitDeathEvent, CreepRespawn
    globals
        private constant integer ZONE_ID = 104
        private constant integer UNIT_GOBLIN_MINER = 'n019'
        private constant integer UNIT_ITEM_DROP_LOCATION = 'n01L'
        private constant integer UNIT_BARREL = 'n01M'
        private constant integer ITEM_BARREL = 'I00F'
        private constant integer UNIT_DUMMY_DAMAGE = 'n014'

        private integer DungeonId = 0
        private integer MadBlixId = 0
        private group WaveOneGroup = null
        private group WaveSixGroup = null
        private group WorkGroup = null
        private timer WaveOneTimer = null
        private timer WaveSixTimer = null
        private timer RockTimer = null
        private timer CountdownTimer = null
        private timer MadBlixTimer = null
        private unit ActiveBarrel = null
        private integer ActiveRock = 0
        private real RockAttackX = 0.00
        private real RockAttackY = 0.00
        private trigger RockPickupTrigger = null
    endglobals

    private function IsPlayerHeroOwner takes unit whichUnit returns boolean
        local player owner = null
        local boolean isPlayerOwner = false

        if whichUnit == null then
            set owner = null
            return false
        endif
        set owner = GetOwningPlayer(whichUnit)
        set isPlayerOwner = owner == Player(0) or owner == Player(1)
        set owner = null
        return isPlayerOwner
    endfunction

    private function IsMineCreep takes unit whichUnit returns boolean
        if whichUnit == null then
            return false
        endif
        return GetUnitName(whichUnit) == "Goblin Miner (Level 10)" or GetUnitName(whichUnit) == "Goblin Miner (Level 10 - No Wander)" or GetUnitName(whichUnit) == "Turret (Level 10)" or GetUnitName(whichUnit) == "Shredder (Level 14)"
    endfunction

    private function OrderGroupToPoint takes group whichGroup, real x, real y returns nothing
        local unit picked = null
        local group orderGroup = CreateGroup()
        call BlzGroupAddGroupFast(whichGroup, orderGroup)
        loop
            set picked = FirstOfGroup(orderGroup)
            exitwhen picked == null
            call GroupRemoveUnit(orderGroup, picked)
            call IssuePointOrder(picked, "attack", x, y)
        endloop
        call DestroyGroup(orderGroup)
        set picked = null
        set orderGroup = null
    endfunction

    private function HasLivingUnits takes group whichGroup returns boolean
        local group copyGroup = CreateGroup()
        local unit picked = null
        local boolean found = false

        call BlzGroupAddGroupFast(whichGroup, copyGroup)
        call GroupClear(whichGroup)
        loop
            set picked = FirstOfGroup(copyGroup)
            exitwhen picked == null
            call GroupRemoveUnit(copyGroup, picked)
            if GetWidgetLife(picked) > 0.405 and GetUnitTypeId(picked) != 0 then
                call GroupAddUnit(whichGroup, picked)
                set found = true
            endif
        endloop
        call DestroyGroup(copyGroup)
        set copyGroup = null
        set picked = null
        return found
    endfunction

    private function CooldownExpired takes nothing returns nothing
    endfunction

    private function SpawnWaveOne takes nothing returns nothing
        local integer index = 0
        local unit spawned = null
        local real x = GetRectCenterX(gg_rct_BoomMineR2)
        local real y = GetRectCenterY(gg_rct_BoomMineR2)
        loop
            exitwhen index >= 5
            set spawned = CreateUnit(Player(11), UNIT_GOBLIN_MINER, x, y, 0.00)
            if spawned != null then
                call CreepRespawn_DiscardUnit(spawned)
                call GroupAddUnit(WaveOneGroup, spawned)
                call IssuePointOrder(spawned, "attack", GetRectCenterX(gg_rct_BoomBrothersMineIn), GetRectCenterY(gg_rct_BoomBrothersMineIn))
            endif
            set spawned = null
            set index = index + 1
        endloop
        call TimerStart(WaveOneTimer, 240.00, false, function CooldownExpired)
    endfunction

    private function SpawnWaveSix takes nothing returns nothing
        local integer index = 0
        local unit spawned = null
        local real x = GetRectCenterX(gg_rct_BoomMineR8)
        local real y = GetRectCenterY(gg_rct_BoomMineR8)
        loop
            exitwhen index >= 5
            set spawned = CreateUnit(Player(11), UNIT_GOBLIN_MINER, x, y, 0.00)
            if spawned != null then
                call CreepRespawn_DiscardUnit(spawned)
                call GroupAddUnit(WaveSixGroup, spawned)
                call IssuePointOrder(spawned, "attack", GetRectCenterX(gg_rct_BoomMineR18), GetRectCenterY(gg_rct_BoomMineR18))
            endif
            set spawned = null
            set index = index + 1
        endloop
        call TimerStart(WaveSixTimer, 240.00, false, function CooldownExpired)
    endfunction

    private function OnWaveOneEnter takes nothing returns nothing
        local unit entering = GetTriggerUnit()
        if IsPlayerHeroOwner(entering) and TimerGetRemaining(WaveOneTimer) <= 0.00 then
            if not HasLivingUnits(WaveOneGroup) then
                call SpawnWaveOne()
            else
                call OrderGroupToPoint(WaveOneGroup, GetRectCenterX(gg_rct_BoomBrothersMineIn), GetRectCenterY(gg_rct_BoomBrothersMineIn))
            endif
        endif
        set entering = null
    endfunction

    private function OnWaveSixEnter takes nothing returns nothing
        local unit entering = GetTriggerUnit()
        if IsPlayerHeroOwner(entering) and TimerGetRemaining(WaveSixTimer) <= 0.00 then
            if not HasLivingUnits(WaveSixGroup) then
                call SpawnWaveSix()
            else
                call OrderGroupToPoint(WaveSixGroup, GetRectCenterX(gg_rct_BoomMineR18), GetRectCenterY(gg_rct_BoomMineR18))
            endif
        endif
        set entering = null
    endfunction

    private function SetCreepHostileEnum takes nothing returns nothing
        local unit picked = GetEnumUnit()
        if IsMineCreep(picked) then
            call SetUnitOwner(picked, Player(11), true)
        endif
        set picked = null
    endfunction

    private function SetCreepPassiveEnum takes nothing returns nothing
        local unit picked = GetEnumUnit()
        if IsMineCreep(picked) then
            call SetUnitOwner(picked, Player(PLAYER_NEUTRAL_PASSIVE), true)
            call IssuePointOrder(picked, "move", GetRectCenterX(gg_rct_BoomMineR5), GetRectCenterY(gg_rct_BoomMineR5))
        endif
        set picked = null
    endfunction

    private function OnR7Enter takes nothing returns nothing
        local unit entering = GetTriggerUnit()
        if IsPlayerHeroOwner(entering) then
            call GroupEnumUnitsInRect(WorkGroup, gg_rct_BoomMineR21, null)
            call ForGroup(WorkGroup, function SetCreepHostileEnum)
            call GroupClear(WorkGroup)
        endif
        set entering = null
    endfunction

    private function OnR10Enter takes nothing returns nothing
        local unit entering = GetTriggerUnit()
        if IsPlayerHeroOwner(entering) then
            call GroupEnumUnitsInRect(WorkGroup, gg_rct_BoomMineR20, null)
            call ForGroup(WorkGroup, function SetCreepHostileEnum)
            call GroupClear(WorkGroup)
        endif
        set entering = null
    endfunction

    private function OnR7Leave takes nothing returns nothing
        local unit leaving = GetTriggerUnit()
        if IsPlayerHeroOwner(leaving) then
            call GroupEnumUnitsInRect(WorkGroup, gg_rct_BoomMineR21, null)
            call ForGroup(WorkGroup, function SetCreepPassiveEnum)
            call GroupClear(WorkGroup)
        endif
        set leaving = null
    endfunction

    private function OnR10Leave takes nothing returns nothing
        local unit leaving = GetTriggerUnit()
        if IsPlayerHeroOwner(leaving) then
            call GroupEnumUnitsInRect(WorkGroup, gg_rct_BoomMineR20, null)
            call ForGroup(WorkGroup, function SetCreepPassiveEnum)
            call GroupClear(WorkGroup)
        endif
        set leaving = null
    endfunction

    private function KillPickedDestructable takes nothing returns nothing
        call KillDestructable(GetEnumDestructable())
    endfunction

    private function DamageNearbyUnits takes unit source, real damage returns nothing
        local unit picked = null
        call GroupEnumUnitsInRange(WorkGroup, GetUnitX(source), GetUnitY(source), 500.00, null)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if picked != source and IsUnitEnemy(picked, GetOwningPlayer(source)) then
                call UnitDamageTarget(source, picked, damage, true, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_FIRE, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop
        set picked = null
    endfunction

    private function MobilizeRockCreep takes nothing returns nothing
        local unit picked = GetEnumUnit()
        if IsMineCreep(picked) then
            call SetUnitOwner(picked, Player(11), true)
            call IssuePointOrder(picked, "attack", RockAttackX, RockAttackY)
        endif
        set picked = null
    endfunction

    private function DetonateRock takes integer rockId returns nothing
        local rect rockRect
        if ActiveBarrel == null then
            set rockRect = null
            return
        endif
        if rockId == 1 then
            set rockRect = gg_rct_BoomMineRocks1
        else
            set rockRect = gg_rct_BoomMineRocks2
        endif
        call EnumDestructablesInRectAll(rockRect, function KillPickedDestructable)
        call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Human\\HCancelDeath\\HCancelDeath.mdl", ActiveBarrel, "chest"))
        call DamageNearbyUnits(ActiveBarrel, 1000.00)
        if rockId == 1 then
            set RockAttackX = GetRectCenterX(gg_rct_BoomMineR19)
            set RockAttackY = GetRectCenterY(gg_rct_BoomMineR19)
            call GroupEnumUnitsInRect(WorkGroup, gg_rct_BoomMineR18, null)
        else
            set RockAttackX = GetRectCenterX(gg_rct_BoomMineR21)
            set RockAttackY = GetRectCenterY(gg_rct_BoomMineR21)
            call GroupEnumUnitsInRect(WorkGroup, gg_rct_BoomMineR22, null)
        endif
        call ForGroup(WorkGroup, function MobilizeRockCreep)
        call GroupClear(WorkGroup)
        call KillUnit(ActiveBarrel)
        call PauseTimer(CountdownTimer)
        set udg_BoomMineBarrel = null
        set udg_BoomMineCountdown = 0
        set ActiveBarrel = null
        set ActiveRock = 0
        set rockRect = null
    endfunction

    private function OnRockTimer takes nothing returns nothing
        call DetonateRock(ActiveRock)
    endfunction

    private function OnCountdownTick takes nothing returns nothing
        local texttag countdownText = null

        if ActiveBarrel == null or GetUnitTypeId(ActiveBarrel) == 0 or udg_BoomMineCountdown <= 0 then
            call PauseTimer(CountdownTimer)
            set countdownText = null
            return
        endif
        set countdownText = CreateTextTagUnitBJ(I2S(udg_BoomMineCountdown), ActiveBarrel, 75.00, 10.00, 100.00, 20.00, 20.00, 0.00)
        call SetTextTagPermanent(countdownText, false)
        call SetTextTagLifespan(countdownText, 1.00)
        call SetTextTagFadepoint(countdownText, 0.20)
        set udg_BoomMineCountdown = udg_BoomMineCountdown - 1
        set countdownText = null
    endfunction

    private function OnRockPickup takes nothing returns nothing
        local unit picker = GetTriggerUnit()
        local item pickedItem = GetManipulatedItem()
        local integer rockId = 0
        if GetUnitTypeId(picker) == UNIT_ITEM_DROP_LOCATION and GetItemTypeId(pickedItem) == ITEM_BARREL then
            if RectContainsCoords(gg_rct_BoomMineRocks1, GetUnitX(picker), GetUnitY(picker)) then
                set rockId = 1
            elseif RectContainsCoords(gg_rct_BoomMineRocks2, GetUnitX(picker), GetUnitY(picker)) then
                set rockId = 2
            endif
            if rockId > 0 and ActiveBarrel == null then
                call RemoveItem(pickedItem)
                set ActiveBarrel = CreateUnit(Player(0), UNIT_BARREL, GetUnitX(picker), GetUnitY(picker), 0.00)
                set udg_BoomMineBarrel = ActiveBarrel
                set udg_BoomMineCountdown = 15
                set ActiveRock = rockId
                call TimerStart(RockTimer, 15.00, false, function OnRockTimer)
                call TimerStart(CountdownTimer, 1.00, true, function OnCountdownTick)
            endif
        endif
        set pickedItem = null
        set picker = null
    endfunction

    private function OnUnitDeath takes nothing returns nothing
        local unit dying = UnitDeathEvent_GetDyingUnit()
        if dying == ActiveBarrel then
            call PauseTimer(RockTimer)
            call PauseTimer(CountdownTimer)
            call DamageNearbyUnits(dying, 600.00)
            set udg_BoomMineBarrel = null
            set udg_BoomMineCountdown = 0
            set ActiveBarrel = null
            set ActiveRock = 0
        endif
        set dying = null
    endfunction

    private function MadBlixCharge takes nothing returns nothing
        local unit boss = Boss_GetUnit(MadBlixId)
        local unit target = null
        if Boss_IsActive(MadBlixId) and boss != null then
            call GroupEnumUnitsInRange(WorkGroup, GetUnitX(boss), GetUnitY(boss), 700.00, null)
            loop
                set target = FirstOfGroup(WorkGroup)
                exitwhen target == null or IsUnitEnemy(target, GetOwningPlayer(boss))
                call GroupRemoveUnit(WorkGroup, target)
            endloop
            if target != null and IsUnitEnemy(target, GetOwningPlayer(boss)) then
                call IssueTargetOrder(boss, "absorbmana", target)
            endif
            call GroupClear(WorkGroup)
        endif
        if Boss_IsActive(MadBlixId) then
            call TimerStart(MadBlixTimer, GetRandomReal(15.00, 30.00), false, function MadBlixCharge)
        endif
        set target = null
        set boss = null
    endfunction

    private function StartMadBlixFight takes nothing returns nothing
        if Boss_EventBossId == MadBlixId then
            call TimerStart(MadBlixTimer, GetRandomReal(15.00, 30.00), false, function MadBlixCharge)
        endif
    endfunction

    private function StopMadBlixFight takes nothing returns nothing
        if Boss_EventBossId == MadBlixId then
            call PauseTimer(MadBlixTimer)
        endif
    endfunction

    private function OnMadBlixRespawn takes nothing returns nothing
        set udg_BossMadBlix = Boss_GetUnit(MadBlixId)
    endfunction

    private function RegisterTrigger takes rect whichRect, integer eventId, code callback returns nothing
        local trigger whichTrigger = CreateTrigger()
        if eventId == 0 then
            call TriggerRegisterEnterRectSimple(whichTrigger, whichRect)
        elseif eventId == 1 then
            call TriggerRegisterLeaveRectSimple(whichTrigger, whichRect)
        endif
        call TriggerAddAction(whichTrigger, callback)
        set whichTrigger = null
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()
        local unit boss = null
        local integer playerId = 0

        set DungeonId = Dungeon_Register(ZONE_ID, gg_rct_BoomBrothersMineEnter, gg_rct_BoomBrothersMineIn, 300.00)
        call ZoneEvent_RegisterEntranceTransition(ZONE_ID, gg_rct_BoomBrothersMineEnter, gg_rct_BoomBrothersMineIn, 215.00)
        call ZoneEvent_RegisterExitTransition(ZONE_ID, gg_rct_BoomBrothersMineLeave, gg_rct_BoomBrothersMineOut, 295.00)
        call ZoneEvent_SetZoneCameraMode(ZONE_ID, CameraControl_CAMERA_SPECIAL_MODE_BOOMMINE)
        call ZoneEvent_SetFastPanOnEnter(ZONE_ID, true)
        set boss = Boss_FindUnitByName("Mad Blix", gg_rct_BoomBrothersMine)
        if boss != null then
            set udg_BossMadBlix = boss
            set MadBlixId = Boss_Register(boss, "Mad Blix")
            call Boss_SetArena(MadBlixId, gg_rct_BoomBrothersMine, Player(0), true)
            call Boss_SetAutoStartOnAttack(MadBlixId, true)
            call Boss_SetDescription(MadBlixId, "A goblin overseer whose only recoverable exported mechanic is mana absorption.", "The legacy phase files are empty, so no phase transition is reconstructed.", "Every 15-30 seconds he targets a nearby enemy with Absorb Mana.", "Keep mana available for key responses and interrupt or pressure him when he begins the drain.")
            call Boss_SetEventCallback(MadBlixId, BOSS_EVENT_START, function StartMadBlixFight)
            call Boss_SetEventCallback(MadBlixId, BOSS_EVENT_RESET, function StopMadBlixFight)
            call Boss_SetEventCallback(MadBlixId, BOSS_EVENT_DEATH, function StopMadBlixFight)
            call Boss_SetEventCallback(MadBlixId, BOSS_EVENT_RESPAWN, function OnMadBlixRespawn)
            call Dungeon_RegisterBoss(DungeonId, MadBlixId)
        endif
        call Dungeon_RegisterZoneCreeps(DungeonId, 35.00, 120.00, 320.00)
        call RegisterTrigger(gg_rct_BoomMineR1, 0, function OnWaveOneEnter)
        call RegisterTrigger(gg_rct_BoomMineR6, 0, function OnWaveSixEnter)
        call RegisterTrigger(gg_rct_BoomMineR7, 0, function OnR7Enter)
        call RegisterTrigger(gg_rct_BoomMineR10, 0, function OnR10Enter)
        call RegisterTrigger(gg_rct_BoomMineR21, 1, function OnR7Leave)
        call RegisterTrigger(gg_rct_BoomMineR20, 1, function OnR10Leave)
        loop
            exitwhen playerId > 23
            call TriggerRegisterPlayerUnitEvent(RockPickupTrigger, Player(playerId), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
            set playerId = playerId + 1
        endloop
        call DestroyTimer(whichTimer)
        set boss = null
        set whichTimer = null
    endfunction

    public function GetDungeonId takes nothing returns integer
        return DungeonId
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set WaveOneGroup = CreateGroup()
        set WaveSixGroup = CreateGroup()
        set WorkGroup = CreateGroup()
        set WaveOneTimer = CreateTimer()
        set WaveSixTimer = CreateTimer()
        set RockTimer = CreateTimer()
        set CountdownTimer = CreateTimer()
        set MadBlixTimer = CreateTimer()
        set RockPickupTrigger = CreateTrigger()
        call TriggerAddAction(RockPickupTrigger, function OnRockPickup)
        call UnitDeathEvent_Register(function OnUnitDeath)
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
