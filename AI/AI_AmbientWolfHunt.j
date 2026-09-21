/**
    AI_AmbientWolfHunt

    Author: Valdemar
    Version: 1.0.0

    Description:
    Lightweight ambient wolf hunting for Havenwoods, Thornwoods, Sereneglade,
    and Twilight Grove. A rare scheduler attempt selects one visible idle stag
    or boar near a player or registered AI hero, then forms a one-to-four wolf
    pack from the closest eligible wild wolves. A hunt may occasionally create
    missing pack members inside the selected zone. The controller issues one
    native attack order per wolf and keeps no AI profile or per-wolf timer.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AI_AmbientEvents.j`, `AI.j`, `AI_Register.j`, `Table`,
    `Events`, `PetDefinitions.j`, `CreepRespawn.j`, and `FallenHeroState`. Keep
    `gg_rct_001TwilightGroveFull`, `gg_rct_02SereneGlade`,
    `gg_rct_06Thornwoods`, and `gg_rct_07Havenwoods`. Future ambient controllers
    should register with `AIAmbientEvents` instead of adding another permanent
    scheduler.

    API:
    call AIAmbientWolfHunt_SetEnabled(enabled)
    call AIAmbientWolfHunt_AttemptNow() returns boolean
    call AIAmbientWolfHunt_IsActive() returns boolean
    call AIAmbientWolfHunt_GetWolfCount() returns integer

**/
library AIAmbientWolfHunt initializer Init requires AIAmbientEvents, AI, AIRegister, Table, Events, PetDefinitions, CreepRespawn, FallenHeroState

globals
    private constant integer ZONE_COUNT = 4
    private constant integer MAX_PACK_SIZE = 4
    private constant integer UNIT_TIMBER_WOLF = 'nwlt'
    private constant integer UNIT_GIANT_WOLF = 'nwlg'
    private constant integer UNIT_DIRE_WOLF = 'nwld'
    private constant integer BUFF_TIMED_LIFE = 'BTLF'

    private constant real HERO_EVENT_RANGE = 10000.00
    private constant real PACK_SEARCH_RANGE = 3000.00
    private constant real SPAWN_MIN_RANGE = 650.00
    private constant real SPAWN_MAX_RANGE = 1200.00
    private constant real SPAWN_LIFETIME = 150.00
    private constant integer SPAWN_CHANCE_PERCENT = 35
    private constant integer SPAWN_POINT_ATTEMPTS = 8

    private constant real MONITOR_INTERVAL = 5.00
    private constant integer MAX_MONITOR_TICKS = 18
    private constant real RETRY_MIN = 120.00
    private constant real RETRY_MAX = 240.00
    private constant real COOLDOWN_MIN = 480.00
    private constant real COOLDOWN_MAX = 780.00

    private integer AmbientEventId = 0
    private integer ActiveWolfCount = 0
    private integer MonitorTicks = 0
    private integer PreyCandidateCount = 0
    private integer DesiredPackSize = 0
    private integer SelectedPackSize = 0
    private integer AttackOrderId = 0

    private real NearestWolfDistanceSq = 0.00
    private real WolfSearchX = 0.00
    private real WolfSearchY = 0.00

    private unit ActivePrey = null
    private unit SelectedPrey = null
    private unit NearestWolf = null
    private rect ActiveZone = null
    private rect array ZoneRect

    private group ScanGroup = null
    private group CandidateWolves = null
    private group PreparedWolves = null
    private group HuntWolves = null
    private group SpawnedWolves = null
    private group InvalidWolves = null
    private Table ActuallySummoned = 0
    private timer MonitorTimer = null
    private trigger UnitDeindexTrigger = null

    private boolean ReleaseStopOrders = false
endglobals

private function IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and FallenHeroState_IsAlive(whichUnit)
endfunction

private function IsWildWolfType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_TIMBER_WOLF or unitTypeId == UNIT_GIANT_WOLF or unitTypeId == UNIT_DIRE_WOLF
endfunction

private function IsControlledBeast takes unit whichUnit returns boolean
    return (udg_TamedUnits != null and IsUnitInGroup(whichUnit, udg_TamedUnits)) or (udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group))
endfunction

private function IsInCombat takes unit whichUnit returns boolean
    local integer unitId
    if whichUnit == null then
        return false
    endif
    set unitId = GetUnitUserData(whichUnit)
    return unitId > 0 and udg_GCSM_UnitInCombat[unitId]
endfunction

private function IsInsideRect takes rect whichRect, real x, real y returns boolean
    return whichRect != null and x >= GetRectMinX(whichRect) and x <= GetRectMaxX(whichRect) and y >= GetRectMinY(whichRect) and y <= GetRectMaxY(whichRect)
endfunction

private function IsActivePreyValid takes unit whichUnit returns boolean
    local integer unitTypeId
    if not IsAlive(whichUnit) or IsUnitHidden(whichUnit) or GetOwningPlayer(whichUnit) != Player(PLAYER_NEUTRAL_PASSIVE) then
        return false
    endif
    if not IsInsideRect(ActiveZone, GetUnitX(whichUnit), GetUnitY(whichUnit)) then
        return false
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    if not PetDefinitions_IsStagType(unitTypeId) and not PetDefinitions_IsBoarType(unitTypeId) then
        return false
    endif
    if GetUnitAbilityLevel(whichUnit, 'Aloc') > 0 or ActuallySummoned.boolean[GetHandleId(whichUnit)] or IsControlledBeast(whichUnit) or AIRegister_IsUnitExcluded(whichUnit) then
        return false
    endif
    return IsUnitEnemy(whichUnit, Player(PLAYER_NEUTRAL_AGGRESSIVE))
endfunction

private function IsEligiblePrey takes unit whichUnit returns boolean
    if not IsActivePreyValid(whichUnit) then
        return false
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) or IsUnitType(whichUnit, UNIT_TYPE_STRUCTURE) then
        return false
    endif
    if AI_GetInstance(whichUnit) > 0 or AIRegister_IsUnitExcluded(whichUnit) or IsInCombat(whichUnit) or GetUnitCurrentOrder(whichUnit) != 0 then
        return false
    endif
    return IsUnitEnemy(whichUnit, Player(PLAYER_NEUTRAL_AGGRESSIVE)) and AI_HasHeroNearPoint(GetUnitX(whichUnit), GetUnitY(whichUnit), HERO_EVENT_RANGE)
endfunction

private function ConsiderPrey takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    if IsEligiblePrey(whichUnit) then
        set PreyCandidateCount = PreyCandidateCount + 1
        if GetRandomInt(1, PreyCandidateCount) == 1 then
            set SelectedPrey = whichUnit
        endif
    endif
    set whichUnit = null
endfunction

private function IsEligibleWolf takes unit whichUnit returns boolean
    if not IsAlive(whichUnit) or IsUnitHidden(whichUnit) or not IsWildWolfType(GetUnitTypeId(whichUnit)) then
        return false
    endif
    if not IsInsideRect(ActiveZone, GetUnitX(whichUnit), GetUnitY(whichUnit)) then
        return false
    endif
    if GetOwningPlayer(whichUnit) != Player(PLAYER_NEUTRAL_AGGRESSIVE) or IsUnitType(whichUnit, UNIT_TYPE_HERO) or IsUnitType(whichUnit, UNIT_TYPE_STRUCTURE) or GetUnitAbilityLevel(whichUnit, 'Aloc') > 0 then
        return false
    endif
    if ActuallySummoned.boolean[GetHandleId(whichUnit)] or IsControlledBeast(whichUnit) then
        return false
    endif
    if AI_GetInstance(whichUnit) > 0 or AIRegister_IsUnitExcluded(whichUnit) or IsInCombat(whichUnit) or GetUnitCurrentOrder(whichUnit) != 0 then
        return false
    endif
    return ActivePrey != null and IsUnitEnemy(ActivePrey, GetOwningPlayer(whichUnit))
endfunction

private function CollectEligibleWolf takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    if IsEligibleWolf(whichUnit) then
        call GroupAddUnit(CandidateWolves, whichUnit)
    endif
    set whichUnit = null
endfunction

private function FindNearestWolf takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    local real dx = GetUnitX(whichUnit) - WolfSearchX
    local real dy = GetUnitY(whichUnit) - WolfSearchY
    local real distanceSq = dx * dx + dy * dy
    if NearestWolf == null or distanceSq < NearestWolfDistanceSq then
        set NearestWolf = whichUnit
        set NearestWolfDistanceSq = distanceSq
    endif
    set whichUnit = null
endfunction

private function PrepareClosestWolf takes nothing returns boolean
    set NearestWolf = null
    set NearestWolfDistanceSq = 0.00
    call ForGroup(CandidateWolves, function FindNearestWolf)
    if NearestWolf == null then
        return false
    endif
    call GroupRemoveUnit(CandidateWolves, NearestWolf)
    call GroupAddUnit(PreparedWolves, NearestWolf)
    set WolfSearchX = GetUnitX(NearestWolf)
    set WolfSearchY = GetUnitY(NearestWolf)
    set SelectedPackSize = SelectedPackSize + 1
    set NearestWolf = null
    return true
endfunction

private function GetSpawnUnitType takes nothing returns integer
    local integer roll = GetRandomInt(1, 100)
    if roll <= 65 then
        return UNIT_TIMBER_WOLF
    elseif roll <= 90 then
        return UNIT_GIANT_WOLF
    endif
    return UNIT_DIRE_WOLF
endfunction

private function CreateHuntingWolf takes nothing returns unit
    local unit whichUnit = null
    local real angle
    local real distance
    local real x
    local real y
    local integer attempt = 1
    loop
        exitwhen attempt > SPAWN_POINT_ATTEMPTS
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
        set distance = GetRandomReal(SPAWN_MIN_RANGE, SPAWN_MAX_RANGE)
        set x = GetUnitX(ActivePrey) + distance * Cos(angle)
        set y = GetUnitY(ActivePrey) + distance * Sin(angle)
        if IsInsideRect(ActiveZone, x, y) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            set whichUnit = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), GetSpawnUnitType(), x, y, angle * bj_RADTODEG)
            if whichUnit != null then
                call CreepRespawn_DiscardUnit(whichUnit)
                call AIRegister_ExcludeUnit(whichUnit)
                call UnitApplyTimedLife(whichUnit, BUFF_TIMED_LIFE, SPAWN_LIFETIME)
                call GroupAddUnit(SpawnedWolves, whichUnit)
                return whichUnit
            endif
        endif
        set attempt = attempt + 1
    endloop
    return null
endfunction

private function PrepareSpawnedWolves takes nothing returns nothing
    local unit whichUnit
    if SelectedPackSize >= DesiredPackSize or GetRandomInt(1, 100) > SPAWN_CHANCE_PERCENT then
        return
    endif
    loop
        exitwhen SelectedPackSize >= DesiredPackSize
        set whichUnit = CreateHuntingWolf()
        exitwhen whichUnit == null
        call GroupAddUnit(PreparedWolves, whichUnit)
        set SelectedPackSize = SelectedPackSize + 1
    endloop
    set whichUnit = null
endfunction

private function ClearFailedPreparation takes nothing returns nothing
    local unit whichUnit
    loop
        set whichUnit = FirstOfGroup(PreparedWolves)
        exitwhen whichUnit == null
        call GroupRemoveUnit(PreparedWolves, whichUnit)
    endloop
    call GroupClear(CandidateWolves)
    set ActivePrey = null
    set ActiveZone = null
    set whichUnit = null
endfunction

private function ClaimPreparedWolves takes nothing returns nothing
    local unit whichUnit
    local boolean spawned
    set ActiveWolfCount = 0
    loop
        set whichUnit = FirstOfGroup(PreparedWolves)
        exitwhen whichUnit == null
        call GroupRemoveUnit(PreparedWolves, whichUnit)
        set spawned = IsUnitInGroup(whichUnit, SpawnedWolves)
        if IsAlive(whichUnit) and not IsUnitHidden(whichUnit) and AI_GetInstance(whichUnit) <= 0 and not IsControlledBeast(whichUnit) and IsUnitEnemy(ActivePrey, GetOwningPlayer(whichUnit)) then
            if not spawned then
                call AIRegister_ExcludeUnit(whichUnit)
            endif
            if IssueTargetOrderById(whichUnit, AttackOrderId, ActivePrey) then
                call GroupAddUnit(HuntWolves, whichUnit)
                set ActiveWolfCount = ActiveWolfCount + 1
            else
                if not spawned then
                    call AIRegister_AllowUnit(whichUnit)
                endif
            endif
        endif
    endloop
    set whichUnit = null
endfunction

private function ReleaseWolf takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    local boolean spawned = IsUnitInGroup(whichUnit, SpawnedWolves)
    local boolean externalControl = IsControlledBeast(whichUnit) or GetOwningPlayer(whichUnit) != Player(PLAYER_NEUTRAL_AGGRESSIVE)
    if externalControl then
        if IsAlive(whichUnit) and GetUnitCurrentOrder(whichUnit) == AttackOrderId then
            call IssueImmediateOrder(whichUnit, "stop")
        endif
        if spawned then
            call BlzUnitCancelTimedLife(whichUnit)
            call GroupRemoveUnit(SpawnedWolves, whichUnit)
        endif
        call AIRegister_AllowUnit(whichUnit)
    elseif ReleaseStopOrders and IsAlive(whichUnit) and GetUnitCurrentOrder(whichUnit) == AttackOrderId then
        call IssueImmediateOrder(whichUnit, "stop")
    endif
    if not externalControl and not spawned then
        call AIRegister_AllowUnit(whichUnit)
    endif
    set whichUnit = null
endfunction

private function EndHunt takes boolean stopOrders returns nothing
    if not AIAmbientEvents_IsActive(AmbientEventId) then
        return
    endif
    call PauseTimer(MonitorTimer)
    set ReleaseStopOrders = stopOrders
    call ForGroup(HuntWolves, function ReleaseWolf)
    call GroupClear(HuntWolves)
    call GroupClear(CandidateWolves)
    call GroupClear(PreparedWolves)
    call GroupClear(InvalidWolves)
    set ActiveWolfCount = 0
    set MonitorTicks = 0
    set ActivePrey = null
    set ActiveZone = null
    call AIAmbientEvents_Finish(AmbientEventId)
endfunction

private function CountActiveWolf takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    if IsAlive(whichUnit) and not IsUnitHidden(whichUnit) and GetOwningPlayer(whichUnit) == Player(PLAYER_NEUTRAL_AGGRESSIVE) and not IsControlledBeast(whichUnit) then
        set ActiveWolfCount = ActiveWolfCount + 1
    else
        call GroupAddUnit(InvalidWolves, whichUnit)
    endif
    set whichUnit = null
endfunction

private function ReleaseInvalidWolves takes nothing returns nothing
    local unit whichUnit
    local boolean externalControl
    loop
        set whichUnit = FirstOfGroup(InvalidWolves)
        exitwhen whichUnit == null
        call GroupRemoveUnit(InvalidWolves, whichUnit)
        call GroupRemoveUnit(HuntWolves, whichUnit)
        if IsAlive(whichUnit) and GetUnitCurrentOrder(whichUnit) == AttackOrderId then
            call IssueImmediateOrder(whichUnit, "stop")
        endif
        set externalControl = IsControlledBeast(whichUnit) or GetOwningPlayer(whichUnit) != Player(PLAYER_NEUTRAL_AGGRESSIVE)
        if externalControl then
            if IsUnitInGroup(whichUnit, SpawnedWolves) then
                call BlzUnitCancelTimedLife(whichUnit)
            endif
            call GroupRemoveUnit(SpawnedWolves, whichUnit)
            call AIRegister_AllowUnit(whichUnit)
        elseif not IsUnitInGroup(whichUnit, SpawnedWolves) then
            call AIRegister_AllowUnit(whichUnit)
        endif
    endloop
    set whichUnit = null
endfunction

private function OnMonitorTick takes nothing returns nothing
    if not AIAmbientEvents_IsActive(AmbientEventId) then
        call PauseTimer(MonitorTimer)
        return
    endif
    if udg_InCinematic then
        call EndHunt(true)
        return
    endif
    set MonitorTicks = MonitorTicks + 1
    if not IsAlive(ActivePrey) then
        call EndHunt(false)
        return
    endif
    if not IsActivePreyValid(ActivePrey) then
        call EndHunt(true)
        return
    endif
    if not AI_HasHeroNearPoint(GetUnitX(ActivePrey), GetUnitY(ActivePrey), HERO_EVENT_RANGE) then
        call EndHunt(true)
        return
    endif
    if MonitorTicks >= MAX_MONITOR_TICKS then
        call EndHunt(true)
        return
    endif
    set ActiveWolfCount = 0
    call GroupClear(InvalidWolves)
    call ForGroup(HuntWolves, function CountActiveWolf)
    call ReleaseInvalidWolves()
    if ActiveWolfCount <= 0 then
        call EndHunt(false)
    endif
endfunction

private function ZoneCouldContainNearbyHero takes rect whichRect returns boolean
    local real halfWidth = (GetRectMaxX(whichRect) - GetRectMinX(whichRect)) * 0.50
    local real halfHeight = (GetRectMaxY(whichRect) - GetRectMinY(whichRect)) * 0.50
    local real reach = HERO_EVENT_RANGE + SquareRoot(halfWidth * halfWidth + halfHeight * halfHeight)
    return AI_HasHeroNearPoint(GetRectCenterX(whichRect), GetRectCenterY(whichRect), reach)
endfunction

private function AttemptHunt takes nothing returns nothing
    local integer packIndex
    if udg_InCinematic or AIAmbientEvents_GetCurrentEventId() != AmbientEventId then
        return
    endif
    set ActiveZone = ZoneRect[GetRandomInt(1, ZONE_COUNT)]
    if ActiveZone == null or not ZoneCouldContainNearbyHero(ActiveZone) then
        set ActiveZone = null
        return
    endif

    set ActivePrey = null
    set SelectedPrey = null
    set PreyCandidateCount = 0
    call GroupClear(ScanGroup)
    call GroupEnumUnitsInRect(ScanGroup, ActiveZone, null)
    call ForGroup(ScanGroup, function ConsiderPrey)
    call GroupClear(ScanGroup)
    set ActivePrey = SelectedPrey
    set SelectedPrey = null
    if ActivePrey == null then
        set ActiveZone = null
        return
    endif

    call GroupClear(CandidateWolves)
    call GroupEnumUnitsInRange(ScanGroup, GetUnitX(ActivePrey), GetUnitY(ActivePrey), PACK_SEARCH_RANGE, null)
    call ForGroup(ScanGroup, function CollectEligibleWolf)
    call GroupClear(ScanGroup)

    set DesiredPackSize = GetRandomInt(1, MAX_PACK_SIZE)
    set SelectedPackSize = 0
    set WolfSearchX = GetUnitX(ActivePrey)
    set WolfSearchY = GetUnitY(ActivePrey)
    set packIndex = 1
    loop
        exitwhen packIndex > DesiredPackSize or not PrepareClosestWolf()
        set packIndex = packIndex + 1
    endloop
    call PrepareSpawnedWolves()
    if FirstOfGroup(PreparedWolves) == null then
        call ClearFailedPreparation()
        return
    endif
    if not AIAmbientEvents_MarkStarted(AmbientEventId) then
        call ClearFailedPreparation()
        return
    endif

    call ClaimPreparedWolves()
    call GroupClear(CandidateWolves)
    if ActiveWolfCount <= 0 then
        call EndHunt(false)
        return
    endif
    set MonitorTicks = 0
    call TimerStart(MonitorTimer, MONITOR_INTERVAL, true, function OnMonitorTick)
endfunction

private function OnUnitSummoned takes nothing returns nothing
    local unit summoned = GetSummonedUnit()
    if summoned != null then
        set ActuallySummoned.boolean[GetHandleId(summoned)] = true
    endif
    set summoned = null
endfunction

private function OnUnitDeindexed takes nothing returns nothing
    local unit deindexedUnit = udg_UDexUnits[udg_UDex]
    if deindexedUnit != null then
        call ActuallySummoned.boolean.remove(GetHandleId(deindexedUnit))
        call GroupRemoveUnit(SpawnedWolves, deindexedUnit)
        call GroupRemoveUnit(HuntWolves, deindexedUnit)
        call GroupRemoveUnit(PreparedWolves, deindexedUnit)
        call GroupRemoveUnit(CandidateWolves, deindexedUnit)
    endif
    set deindexedUnit = null
endfunction

private function OnClaimedWolfOwnerChanged takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local boolean spawned = whichUnit != null and IsUnitInGroup(whichUnit, SpawnedWolves)
    local boolean claimed = whichUnit != null and (spawned or IsUnitInGroup(whichUnit, HuntWolves) or IsUnitInGroup(whichUnit, PreparedWolves))
    if claimed and (GetOwningPlayer(whichUnit) != Player(PLAYER_NEUTRAL_AGGRESSIVE) or IsControlledBeast(whichUnit)) then
        if IsAlive(whichUnit) and GetUnitCurrentOrder(whichUnit) == AttackOrderId then
            call IssueImmediateOrder(whichUnit, "stop")
        endif
        if spawned then
            call BlzUnitCancelTimedLife(whichUnit)
        endif
        call GroupRemoveUnit(SpawnedWolves, whichUnit)
        call GroupRemoveUnit(HuntWolves, whichUnit)
        call GroupRemoveUnit(PreparedWolves, whichUnit)
        call GroupRemoveUnit(CandidateWolves, whichUnit)
        call AIRegister_AllowUnit(whichUnit)
    endif
    set whichUnit = null
endfunction

public function SetEnabled takes boolean enabled returns nothing
    if not enabled and AIAmbientEvents_IsActive(AmbientEventId) then
        call EndHunt(true)
    endif
    call AIAmbientEvents_SetEnabled(AmbientEventId, enabled)
endfunction

public function AttemptNow takes nothing returns boolean
    return AIAmbientEvents_AttemptEvent(AmbientEventId)
endfunction

public function IsActive takes nothing returns boolean
    return AIAmbientEvents_IsActive(AmbientEventId)
endfunction

public function GetWolfCount takes nothing returns integer
    return ActiveWolfCount
endfunction

private function Init takes nothing returns nothing
    set ZoneRect[1] = gg_rct_001TwilightGroveFull
    set ZoneRect[2] = gg_rct_02SereneGlade
    set ZoneRect[3] = gg_rct_06Thornwoods
    set ZoneRect[4] = gg_rct_07Havenwoods
    set ScanGroup = CreateGroup()
    set CandidateWolves = CreateGroup()
    set PreparedWolves = CreateGroup()
    set HuntWolves = CreateGroup()
    set SpawnedWolves = CreateGroup()
    set InvalidWolves = CreateGroup()
    set ActuallySummoned = Table.create()
    set MonitorTimer = CreateTimer()
    set UnitDeindexTrigger = CreateTrigger()
    set AttackOrderId = OrderId("attack")
    call TriggerRegisterVariableEvent(UnitDeindexTrigger, "udg_UnitIndexEvent", EQUAL, 2.00)
    call TriggerAddAction(UnitDeindexTrigger, function OnUnitDeindexed)
    call Events_RegisterUnitSummon(function OnUnitSummoned)
    call Events_RegisterPlayerUnitEvent(function OnClaimedWolfOwnerChanged, EVENT_PLAYER_UNIT_CHANGE_OWNER)
    set AmbientEventId = AIAmbientEvents_Register("Wolf Hunt", RETRY_MIN, RETRY_MAX, COOLDOWN_MIN, COOLDOWN_MAX, function AttemptHunt)
endfunction

endlibrary
