/**
    Dungeon

    Author: Valdemar
    Version: 1.0.0

    Description:
    Connects explicitly registered dungeons to ZonesCore, owns their grouped
    and random creature respawns, and routes revived AI companions back to the
    entrance of the dungeon occupied by their focused player hero. A routed AI
    is teleported just inside the entrance after 120 seconds if pathing never
    brings it into the dungeon.

    Registered dungeon bosses and full-respawn creeps return together on the
    dungeon timer. Random-respawn slots use independent delays and never accept
    a registered boss. Dungeon-owned units are excluded from CreepRespawn so
    only one system can recreate them.

    Credits:
    - Legacy NPC Revival Move Dungeon GUI trigger
    - ZonesCore and ZoneEvent
    - CreepRespawn

    How to install:
    Import after Boss, ZonesCore, ZoneEvent, CreepRespawn, UnitDeathEvent, AI,
    Companions, and Death. Register only gameplay dungeons; ZonesCore also marks
    some ordinary interiors as dungeons. Entrance rects are borrowed map refs.

    API:
    - set dungeonId = Dungeon_Register(zoneId, approachRect, insideRect, delay)
    - call Dungeon_AddArea(dungeonId, containmentRect)
    - set slotId = Dungeon_RegisterUnit(dungeonId, whichUnit, respawnMode, minDelay, maxDelay)
    - set slotId = Dungeon_RegisterBoss(dungeonId, bossId)
    - call Dungeon_RegisterZoneCreeps(dungeonId, randomRespawnPercent, minDelay, maxDelay)
    - call Dungeon_SetFullRespawnCallback(dungeonId, callback)
    - call Dungeon_ScheduleFullRespawn(dungeonId)
    - call Dungeon_RespawnNow(dungeonId)
    - set dungeonId = Dungeon_GetIdByZone(zoneId)
    - set zoneId = Dungeon_GetZoneId(dungeonId)
    - set dungeonId = Dungeon_GetIdForUnit(whichUnit)
    - set flag = Dungeon_IsUnitInside(dungeonId, whichUnit)
    - set x = Dungeon_GetEntranceX(dungeonId)
    - set y = Dungeon_GetEntranceY(dungeonId)
    - set flag = Dungeon_StartAIRoute(whichUnit)
    - call Dungeon_CancelAIRoute(whichUnit, true)

    Full-respawn callbacks read Dungeon_EventDungeonId.

**/
library Dungeon initializer Init requires Boss, ZonesCore, ZoneEvent, CreepRespawn, UnitDeathEvent, AI, Companions, Death, Table
    globals
        constant integer DUNGEON_RESPAWN_FULL = 1
        constant integer DUNGEON_RESPAWN_RANDOM = 2

        integer Dungeon_EventDungeonId = 0

        private constant integer DUNGEON_MAX_COUNT = 64
        private constant integer DUNGEON_MAX_AREAS = 16
        private constant integer DUNGEON_MAX_SLOTS = 4096
        private constant real DUNGEON_DEFAULT_FULL_RESPAWN_DELAY = 300.00
        private constant real DUNGEON_DEFAULT_RANDOM_RESPAWN_MIN = 120.00
        private constant real DUNGEON_DEFAULT_RANDOM_RESPAWN_MAX = 320.00
        private constant real DUNGEON_AI_ROUTE_INTERVAL = 1.00
        private constant real DUNGEON_AI_ROUTE_REISSUE = 4.00
        private constant real DUNGEON_AI_TELEPORT_DELAY = 120.00
        private constant string DUNGEON_TELEPORT_EFFECT = "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl"

        private integer Dungeon_Count = 0
        private integer array Dungeon_ZoneId
        private rect array Dungeon_ApproachRect
        private rect array Dungeon_InsideRect
        private rect array Dungeon_AreaRect
        private integer array Dungeon_AreaCount
        private real array Dungeon_FullRespawnDelay
        private integer array Dungeon_FirstSlot
        private timer array Dungeon_FullRespawnTimer
        private trigger array Dungeon_FullRespawnCallback

        private integer Dungeon_SlotCount = 0
        private integer array Dungeon_SlotDungeon
        private integer array Dungeon_SlotNext
        private unit array Dungeon_SlotUnit
        private integer array Dungeon_SlotUnitTypeId
        private player array Dungeon_SlotOwner
        private real array Dungeon_SlotX
        private real array Dungeon_SlotY
        private real array Dungeon_SlotFacing
        private integer array Dungeon_SlotRespawnMode
        private real array Dungeon_SlotRandomMin
        private real array Dungeon_SlotRandomMax
        private integer array Dungeon_SlotBossId
        private timer array Dungeon_SlotTimer

        private Table Dungeon_ZoneToId = 0
        private Table Dungeon_UnitToSlot = 0
        private Table Dungeon_TimerToDungeon = 0
        private Table Dungeon_TimerToSlot = 0
        private Table Dungeon_RouteDungeon = 0
        private Table Dungeon_RouteRemaining = 0
        private Table Dungeon_RouteReissue = 0

        private group Dungeon_RegisterGroup = null
        private group Dungeon_AIRouteGroup = null
        private timer Dungeon_AIRouteTimer = null
        private integer Dungeon_RegisterContextId = 0
        private real Dungeon_RegisterRandomPercent = 0.00
        private real Dungeon_RegisterRandomMin = 0.00
        private real Dungeon_RegisterRandomMax = 0.00
        private boolean Dungeon_DebugEnabled = false
    endglobals

    private function Dungeon_Debug takes string message returns nothing
        if Dungeon_DebugEnabled then
            call BJDebugMsg("|cffcc66ff[Dungeon]|r " + message)
        endif
    endfunction

    private function Dungeon_Error takes string message returns nothing
        call BJDebugMsg("|cffff8080[Dungeon] ERROR:|r " + message)
    endfunction

    private function Dungeon_IsValidId takes integer dungeonId returns boolean
        return dungeonId > 0 and dungeonId <= Dungeon_Count and Dungeon_ZoneId[dungeonId] > 0
    endfunction

    private function Dungeon_IsValidSlot takes integer slotId returns boolean
        return slotId > 0 and slotId <= Dungeon_SlotCount and Dungeon_SlotDungeon[slotId] > 0 and Dungeon_SlotUnitTypeId[slotId] != 0
    endfunction

    private function Dungeon_IsUnitAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function Dungeon_GetIdForZoneInternal takes integer zoneId returns integer
        local integer dungeonId

        if zoneId <= 0 then
            return 0
        endif
        set dungeonId = Dungeon_ZoneToId[zoneId]
        if dungeonId > 0 then
            return dungeonId
        endif

        set dungeonId = 1
        loop
            exitwhen dungeonId > Dungeon_Count
            if ZonesCore_IsChildZoneOf(zoneId, Dungeon_ZoneId[dungeonId]) then
                return dungeonId
            endif
            set dungeonId = dungeonId + 1
        endloop
        return 0
    endfunction

    public function SetDebugEnabled takes boolean enabled returns nothing
        set Dungeon_DebugEnabled = enabled
    endfunction

    public function GetIdByZone takes integer zoneId returns integer
        return Dungeon_GetIdForZoneInternal(zoneId)
    endfunction

    public function GetZoneId takes integer dungeonId returns integer
        if not Dungeon_IsValidId(dungeonId) then
            return 0
        endif
        return Dungeon_ZoneId[dungeonId]
    endfunction

    private function Dungeon_IsZoneDataPointInside takes ZoneData zoneData, real x, real y returns boolean
        local integer rectIndex = 0
        local rect whichRect = null

        if zoneData == 0 then
            return false
        endif
        loop
            exitwhen rectIndex >= zoneData.enterRegionCount
            set whichRect = zoneData.enterRegions[rectIndex]
            if whichRect != null and RectContainsCoords(whichRect, x, y) then
                set whichRect = null
                return true
            endif
            set rectIndex = rectIndex + 1
        endloop
        set whichRect = null
        return false
    endfunction

    private function Dungeon_IsPointInside takes integer dungeonId, real x, real y returns boolean
        local integer areaIndex = 0
        local rect whichRect = null

        if not Dungeon_IsValidId(dungeonId) then
            return false
        endif
        if Dungeon_AreaCount[dungeonId] > 0 then
            loop
                exitwhen areaIndex >= Dungeon_AreaCount[dungeonId]
                set whichRect = Dungeon_AreaRect[dungeonId * DUNGEON_MAX_AREAS + areaIndex]
                if whichRect != null and RectContainsCoords(whichRect, x, y) then
                    set whichRect = null
                    return true
                endif
                set areaIndex = areaIndex + 1
            endloop
            set whichRect = null
            return false
        endif
        return Dungeon_IsZoneDataPointInside(ZonesCore_GetZoneData(Dungeon_ZoneId[dungeonId]), x, y)
    endfunction

    public function GetIdForUnit takes unit whichUnit returns integer
        local integer dungeonId = 1
        local integer zoneId

        if whichUnit == null then
            return 0
        endif
        loop
            exitwhen dungeonId > Dungeon_Count
            if Dungeon_IsPointInside(dungeonId, GetUnitX(whichUnit), GetUnitY(whichUnit)) then
                return dungeonId
            endif
            set dungeonId = dungeonId + 1
        endloop
        set zoneId = ZoneEvent_GetUnitZoneId(whichUnit)
        return Dungeon_GetIdForZoneInternal(zoneId)
    endfunction

    public function IsUnitInside takes integer dungeonId, unit whichUnit returns boolean
        return Dungeon_IsValidId(dungeonId) and whichUnit != null and Dungeon_IsPointInside(dungeonId, GetUnitX(whichUnit), GetUnitY(whichUnit))
    endfunction

    public function GetEntranceX takes integer dungeonId returns real
        if not Dungeon_IsValidId(dungeonId) or Dungeon_ApproachRect[dungeonId] == null then
            return 0.00
        endif
        return GetRectCenterX(Dungeon_ApproachRect[dungeonId])
    endfunction

    public function GetEntranceY takes integer dungeonId returns real
        if not Dungeon_IsValidId(dungeonId) or Dungeon_ApproachRect[dungeonId] == null then
            return 0.00
        endif
        return GetRectCenterY(Dungeon_ApproachRect[dungeonId])
    endfunction

    public function Register takes integer zoneId, rect approachRect, rect insideRect, real fullRespawnDelay returns integer
        local integer dungeonId
        local ZoneData zoneData

        if zoneId <= 0 or insideRect == null then
            call Dungeon_Error("A dungeon needs a valid zone id and inside-entrance rect.")
            return 0
        endif
        set zoneData = ZonesCore_GetZoneData(zoneId)
        if zoneData == 0 or not zoneData.isDungeon then
            call Dungeon_Error("Zone " + I2S(zoneId) + " is not a registered dungeon in ZonesCore.")
            return 0
        endif
        set dungeonId = Dungeon_ZoneToId[zoneId]
        if dungeonId == 0 then
            if Dungeon_Count >= DUNGEON_MAX_COUNT then
                call Dungeon_Error("Maximum dungeon count reached (" + I2S(DUNGEON_MAX_COUNT) + ").")
                return 0
            endif
            set Dungeon_Count = Dungeon_Count + 1
            set dungeonId = Dungeon_Count
            set Dungeon_ZoneId[dungeonId] = zoneId
            set Dungeon_ZoneToId[zoneId] = dungeonId
            set Dungeon_FullRespawnTimer[dungeonId] = CreateTimer()
            set Dungeon_TimerToDungeon[GetHandleId(Dungeon_FullRespawnTimer[dungeonId])] = dungeonId
        endif

        if approachRect == null then
            set approachRect = insideRect
        endif
        if fullRespawnDelay <= 0.00 then
            set fullRespawnDelay = DUNGEON_DEFAULT_FULL_RESPAWN_DELAY
        endif
        set Dungeon_ApproachRect[dungeonId] = approachRect
        set Dungeon_InsideRect[dungeonId] = insideRect
        set Dungeon_FullRespawnDelay[dungeonId] = fullRespawnDelay
        call Dungeon_Debug("Registered zone " + I2S(zoneId) + " as dungeon " + I2S(dungeonId) + ".")
        return dungeonId
    endfunction

    public function AddArea takes integer dungeonId, rect containmentRect returns boolean
        local integer areaIndex

        if not Dungeon_IsValidId(dungeonId) or containmentRect == null then
            return false
        endif
        set areaIndex = Dungeon_AreaCount[dungeonId]
        if areaIndex >= DUNGEON_MAX_AREAS then
            call Dungeon_Error("Maximum containment-area count reached for dungeon " + I2S(dungeonId) + ".")
            return false
        endif
        set Dungeon_AreaRect[dungeonId * DUNGEON_MAX_AREAS + areaIndex] = containmentRect
        set Dungeon_AreaCount[dungeonId] = areaIndex + 1
        return true
    endfunction

    public function RegisterUnit takes integer dungeonId, unit whichUnit, integer respawnMode, real randomMin, real randomMax returns integer
        local integer slotId
        local integer bossId

        if not Dungeon_IsValidId(dungeonId) or whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
            return 0
        endif
        set slotId = Dungeon_UnitToSlot[GetHandleId(whichUnit)]
        if slotId > 0 then
            return slotId
        endif
        if Dungeon_SlotCount >= DUNGEON_MAX_SLOTS then
            call Dungeon_Error("Maximum dungeon unit-slot count reached (" + I2S(DUNGEON_MAX_SLOTS) + ").")
            return 0
        endif

        set bossId = Boss_GetId(whichUnit)
        if bossId > 0 then
            set respawnMode = DUNGEON_RESPAWN_FULL
        elseif respawnMode != DUNGEON_RESPAWN_RANDOM then
            set respawnMode = DUNGEON_RESPAWN_FULL
        endif
        if randomMin <= 0.00 then
            set randomMin = DUNGEON_DEFAULT_RANDOM_RESPAWN_MIN
        endif
        if randomMax < randomMin then
            set randomMax = randomMin
        endif

        set Dungeon_SlotCount = Dungeon_SlotCount + 1
        set slotId = Dungeon_SlotCount
        set Dungeon_SlotDungeon[slotId] = dungeonId
        set Dungeon_SlotNext[slotId] = Dungeon_FirstSlot[dungeonId]
        set Dungeon_FirstSlot[dungeonId] = slotId
        set Dungeon_SlotUnit[slotId] = whichUnit
        set Dungeon_SlotUnitTypeId[slotId] = GetUnitTypeId(whichUnit)
        set Dungeon_SlotOwner[slotId] = GetOwningPlayer(whichUnit)
        set Dungeon_SlotX[slotId] = GetUnitX(whichUnit)
        set Dungeon_SlotY[slotId] = GetUnitY(whichUnit)
        set Dungeon_SlotFacing[slotId] = GetUnitFacing(whichUnit)
        set Dungeon_SlotRespawnMode[slotId] = respawnMode
        set Dungeon_SlotRandomMin[slotId] = randomMin
        set Dungeon_SlotRandomMax[slotId] = randomMax
        set Dungeon_SlotBossId[slotId] = bossId
        set Dungeon_UnitToSlot[GetHandleId(whichUnit)] = slotId
        call CreepRespawn_DiscardUnit(whichUnit)
        if bossId > 0 then
            call Boss_SetDungeonId(bossId, dungeonId)
        endif
        return slotId
    endfunction

    public function RegisterBoss takes integer dungeonId, integer bossId returns integer
        local unit bossUnit = Boss_GetUnit(bossId)
        local integer slotId

        if bossUnit == null then
            return 0
        endif
        set slotId = RegisterUnit(dungeonId, bossUnit, DUNGEON_RESPAWN_FULL, 0.00, 0.00)
        if slotId > 0 then
            set Dungeon_SlotBossId[slotId] = bossId
            set Dungeon_SlotRespawnMode[slotId] = DUNGEON_RESPAWN_FULL
            call Boss_SetDungeonId(bossId, dungeonId)
        endif
        set bossUnit = null
        return slotId
    endfunction

    private function Dungeon_RegisterPickedCreep takes nothing returns nothing
        local unit pickedUnit = GetEnumUnit()
        local integer respawnMode = DUNGEON_RESPAWN_FULL

        if Dungeon_IsUnitAlive(pickedUnit) and not Boss_IsRegistered(pickedUnit) and not IsUnitType(pickedUnit, UNIT_TYPE_STRUCTURE) and GetUnitAbilityLevel(pickedUnit, 'Aloc') == 0 and GetUnitAbilityLevel(pickedUnit, 'BTLF') == 0 and IsUnitEnemy(pickedUnit, Player(0)) then
            if Dungeon_RegisterRandomPercent > 0.00 and GetRandomReal(0.00, 100.00) <= Dungeon_RegisterRandomPercent then
                set respawnMode = DUNGEON_RESPAWN_RANDOM
            endif
            call RegisterUnit(Dungeon_RegisterContextId, pickedUnit, respawnMode, Dungeon_RegisterRandomMin, Dungeon_RegisterRandomMax)
        endif
        set pickedUnit = null
    endfunction

    public function RegisterZoneCreeps takes integer dungeonId, real randomRespawnPercent, real randomMin, real randomMax returns nothing
        local ZoneData zoneData
        local integer rectIndex = 0
        local rect whichRect = null

        if not Dungeon_IsValidId(dungeonId) then
            return
        endif
        if randomRespawnPercent < 0.00 then
            set randomRespawnPercent = 0.00
        elseif randomRespawnPercent > 100.00 then
            set randomRespawnPercent = 100.00
        endif
        set zoneData = ZonesCore_GetZoneData(Dungeon_ZoneId[dungeonId])
        if zoneData == 0 then
            return
        endif

        set Dungeon_RegisterContextId = dungeonId
        set Dungeon_RegisterRandomPercent = randomRespawnPercent
        set Dungeon_RegisterRandomMin = randomMin
        set Dungeon_RegisterRandomMax = randomMax
        loop
            exitwhen rectIndex >= zoneData.enterRegionCount
            set whichRect = zoneData.enterRegions[rectIndex]
            if whichRect != null then
                call GroupClear(Dungeon_RegisterGroup)
                call GroupEnumUnitsInRect(Dungeon_RegisterGroup, whichRect, null)
                call ForGroup(Dungeon_RegisterGroup, function Dungeon_RegisterPickedCreep)
            endif
            set rectIndex = rectIndex + 1
        endloop
        call GroupClear(Dungeon_RegisterGroup)
        set Dungeon_RegisterContextId = 0
        set Dungeon_RegisterRandomPercent = 0.00
        set Dungeon_RegisterRandomMin = 0.00
        set Dungeon_RegisterRandomMax = 0.00
        set whichRect = null
    endfunction

    private function Dungeon_RespawnSlot takes integer slotId returns unit
        local unit oldUnit = null
        local unit newUnit = null
        local integer bossId

        if not Dungeon_IsValidSlot(slotId) then
            return null
        endif
        set oldUnit = Dungeon_SlotUnit[slotId]
        if Dungeon_IsUnitAlive(oldUnit) then
            set oldUnit = null
            return null
        endif

        set bossId = Dungeon_SlotBossId[slotId]
        if bossId > 0 then
            set newUnit = Boss_Respawn(bossId)
        else
            if oldUnit != null and GetUnitTypeId(oldUnit) != 0 then
                call Dungeon_UnitToSlot.remove(GetHandleId(oldUnit))
                call RemoveUnit(oldUnit)
            endif
            set newUnit = CreateUnit(Dungeon_SlotOwner[slotId], Dungeon_SlotUnitTypeId[slotId], Dungeon_SlotX[slotId], Dungeon_SlotY[slotId], Dungeon_SlotFacing[slotId])
        endif
        if newUnit == null then
            call Dungeon_Error("Failed to respawn dungeon slot " + I2S(slotId) + ".")
            set oldUnit = null
            return null
        endif

        if oldUnit != null then
            call Dungeon_UnitToSlot.remove(GetHandleId(oldUnit))
        endif
        set Dungeon_SlotUnit[slotId] = newUnit
        set Dungeon_UnitToSlot[GetHandleId(newUnit)] = slotId
        call CreepRespawn_DiscardUnit(newUnit)
        set oldUnit = null
        return newUnit
    endfunction

    private function Dungeon_RunFullRespawnCallback takes integer dungeonId returns nothing
        local integer previousDungeonId = Dungeon_EventDungeonId

        if Dungeon_FullRespawnCallback[dungeonId] != null then
            set Dungeon_EventDungeonId = dungeonId
            call TriggerExecute(Dungeon_FullRespawnCallback[dungeonId])
            set Dungeon_EventDungeonId = previousDungeonId
        endif
    endfunction

    private function Dungeon_RespawnFullSlots takes integer dungeonId returns nothing
        local integer slotId
        local unit respawnedUnit = null

        if not Dungeon_IsValidId(dungeonId) then
            return
        endif
        set slotId = Dungeon_FirstSlot[dungeonId]
        loop
            exitwhen slotId == 0
            if Dungeon_SlotRespawnMode[slotId] == DUNGEON_RESPAWN_FULL and not Dungeon_IsUnitAlive(Dungeon_SlotUnit[slotId]) then
                set respawnedUnit = Dungeon_RespawnSlot(slotId)
            endif
            set slotId = Dungeon_SlotNext[slotId]
        endloop
        call Dungeon_RunFullRespawnCallback(dungeonId)
        call Dungeon_Debug("Completed full respawn for dungeon " + I2S(dungeonId) + ".")
        set respawnedUnit = null
    endfunction

    private function Dungeon_OnFullRespawnExpired takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()
        local integer dungeonId = Dungeon_TimerToDungeon[GetHandleId(expiredTimer)]

        call Dungeon_RespawnFullSlots(dungeonId)
        set expiredTimer = null
    endfunction

    private function Dungeon_OnRandomRespawnExpired takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()
        local integer slotId = Dungeon_TimerToSlot[GetHandleId(expiredTimer)]
        local unit respawnedUnit = Dungeon_RespawnSlot(slotId)

        set respawnedUnit = null
        set expiredTimer = null
    endfunction

    public function SetFullRespawnCallback takes integer dungeonId, code callback returns nothing
        if not Dungeon_IsValidId(dungeonId) then
            return
        endif
        if Dungeon_FullRespawnCallback[dungeonId] != null then
            call DestroyTrigger(Dungeon_FullRespawnCallback[dungeonId])
            set Dungeon_FullRespawnCallback[dungeonId] = null
        endif
        if callback != null then
            set Dungeon_FullRespawnCallback[dungeonId] = CreateTrigger()
            call TriggerAddAction(Dungeon_FullRespawnCallback[dungeonId], callback)
        endif
    endfunction

    public function ScheduleFullRespawn takes integer dungeonId returns nothing
        if not Dungeon_IsValidId(dungeonId) or TimerGetRemaining(Dungeon_FullRespawnTimer[dungeonId]) > 0.00 then
            return
        endif
        call TimerStart(Dungeon_FullRespawnTimer[dungeonId], Dungeon_FullRespawnDelay[dungeonId], false, function Dungeon_OnFullRespawnExpired)
        call Dungeon_Debug("Scheduled full respawn for dungeon " + I2S(dungeonId) + ".")
    endfunction

    public function RespawnNow takes integer dungeonId returns nothing
        if not Dungeon_IsValidId(dungeonId) then
            return
        endif
        call PauseTimer(Dungeon_FullRespawnTimer[dungeonId])
        call Dungeon_RespawnFullSlots(dungeonId)
    endfunction

    private function Dungeon_ScheduleRandomRespawn takes integer slotId returns nothing
        local real delay

        if not Dungeon_IsValidSlot(slotId) then
            return
        endif
        if Dungeon_SlotTimer[slotId] == null then
            set Dungeon_SlotTimer[slotId] = CreateTimer()
            set Dungeon_TimerToSlot[GetHandleId(Dungeon_SlotTimer[slotId])] = slotId
        endif
        set delay = GetRandomReal(Dungeon_SlotRandomMin[slotId], Dungeon_SlotRandomMax[slotId])
        call TimerStart(Dungeon_SlotTimer[slotId], delay, false, function Dungeon_OnRandomRespawnExpired)
    endfunction

    private function Dungeon_IsFocusedPlayerHero takes unit leader returns boolean
        return Dungeon_IsUnitAlive(leader) and IsUnitType(leader, UNIT_TYPE_HERO) and IsPlayerInForce(GetOwningPlayer(leader), udg_PlayerGroup)
    endfunction

    private function Dungeon_CancelAIRouteInternal takes unit whichUnit, boolean restoreOrders returns nothing
        local integer unitKey

        if whichUnit == null or Dungeon_RouteDungeon == 0 then
            return
        endif
        set unitKey = GetHandleId(whichUnit)
        if Dungeon_RouteDungeon[unitKey] == 0 then
            return
        endif

        call GroupRemoveUnit(Dungeon_AIRouteGroup, whichUnit)
        call Dungeon_RouteDungeon.remove(unitKey)
        call Dungeon_RouteRemaining.real.remove(unitKey)
        call Dungeon_RouteReissue.real.remove(unitKey)
        if Companions_IsControlled(whichUnit) then
            call Companions_SetExternalOrderOverride(whichUnit, false)
        endif
        if restoreOrders and Dungeon_IsUnitAlive(whichUnit) and not Companions_IsSuspended(whichUnit) and Companions_IsControlled(whichUnit) then
            call Companions_RefreshOrders(whichUnit)
        endif
    endfunction

    public function CancelAIRoute takes unit whichUnit, boolean restoreOrders returns nothing
        call Dungeon_CancelAIRouteInternal(whichUnit, restoreOrders)
    endfunction

    private function Dungeon_IssueAIRouteOrder takes unit whichUnit, integer dungeonId returns nothing
        if whichUnit == null or not Dungeon_IsValidId(dungeonId) or Dungeon_ApproachRect[dungeonId] == null then
            return
        endif
        call IssuePointOrder(whichUnit, "move", GetRectCenterX(Dungeon_ApproachRect[dungeonId]), GetRectCenterY(Dungeon_ApproachRect[dungeonId]))
    endfunction

    public function StartAIRoute takes unit whichUnit returns boolean
        local unit leader = null
        local integer dungeonId
        local integer unitKey

        if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) or AI_GetInstance(whichUnit) <= 0 or not Companions_IsControlled(whichUnit) or Companions_IsSuspended(whichUnit) then
            return false
        endif
        set leader = Companions_GetLeader(whichUnit)
        if not Dungeon_IsFocusedPlayerHero(leader) then
            set leader = null
            return false
        endif
        set dungeonId = Dungeon_GetIdForUnit(leader)
        if dungeonId == 0 or Dungeon_IsUnitInside(dungeonId, whichUnit) then
            set leader = null
            return false
        endif

        set unitKey = GetHandleId(whichUnit)
        if Dungeon_RouteDungeon[unitKey] > 0 then
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
        endif
        set Dungeon_RouteDungeon[unitKey] = dungeonId
        set Dungeon_RouteRemaining.real[unitKey] = DUNGEON_AI_TELEPORT_DELAY
        set Dungeon_RouteReissue.real[unitKey] = DUNGEON_AI_ROUTE_REISSUE
        call GroupAddUnit(Dungeon_AIRouteGroup, whichUnit)
        call Companions_SetExternalOrderOverride(whichUnit, true)
        call Dungeon_IssueAIRouteOrder(whichUnit, dungeonId)
        call Dungeon_Debug("Routing " + GetUnitName(whichUnit) + " to dungeon " + I2S(dungeonId) + ".")
        set leader = null
        return true
    endfunction

    private function Dungeon_TeleportAIRouteUnit takes unit whichUnit, integer dungeonId returns nothing
        if whichUnit == null or not Dungeon_IsValidId(dungeonId) or Dungeon_InsideRect[dungeonId] == null then
            return
        endif
        call DestroyEffect(AddSpecialEffectTarget(DUNGEON_TELEPORT_EFFECT, whichUnit, "origin"))
        call SetUnitPosition(whichUnit, GetRectCenterX(Dungeon_InsideRect[dungeonId]), GetRectCenterY(Dungeon_InsideRect[dungeonId]))
        call DestroyEffect(AddSpecialEffectTarget(DUNGEON_TELEPORT_EFFECT, whichUnit, "origin"))
        if Dungeon_IsUnitInside(dungeonId, whichUnit) then
            call Dungeon_Debug("Teleported " + GetUnitName(whichUnit) + " inside dungeon " + I2S(dungeonId) + ".")
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
        else
            set Dungeon_RouteRemaining.real[GetHandleId(whichUnit)] = DUNGEON_AI_ROUTE_REISSUE
            call Dungeon_Error("Teleport destination did not place " + GetUnitName(whichUnit) + " inside dungeon " + I2S(dungeonId) + "; retrying.")
        endif
    endfunction

    private function Dungeon_UpdateAIRouteUnit takes unit whichUnit returns nothing
        local integer unitKey
        local integer dungeonId
        local integer focusedDungeonId
        local unit leader = null
        local real remaining
        local real reissue

        if whichUnit == null then
            return
        endif
        set unitKey = GetHandleId(whichUnit)
        set dungeonId = Dungeon_RouteDungeon[unitKey]
        if dungeonId == 0 then
            return
        endif
        if not Dungeon_IsUnitAlive(whichUnit) then
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
            return
        endif

        set leader = Companions_GetLeader(whichUnit)
        if not Dungeon_IsFocusedPlayerHero(leader) then
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
            set leader = null
            return
        endif
        set focusedDungeonId = Dungeon_GetIdForUnit(leader)
        if focusedDungeonId == 0 then
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
            set leader = null
            return
        elseif focusedDungeonId != dungeonId then
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
            call StartAIRoute(whichUnit)
            set leader = null
            return
        endif
        if Dungeon_IsUnitInside(dungeonId, whichUnit) then
            call Dungeon_CancelAIRouteInternal(whichUnit, true)
            set leader = null
            return
        endif

        set remaining = Dungeon_RouteRemaining.real[unitKey] - DUNGEON_AI_ROUTE_INTERVAL
        set Dungeon_RouteRemaining.real[unitKey] = remaining
        if remaining <= 0.00 then
            call Dungeon_TeleportAIRouteUnit(whichUnit, dungeonId)
            set leader = null
            return
        endif

        set reissue = Dungeon_RouteReissue.real[unitKey] - DUNGEON_AI_ROUTE_INTERVAL
        if reissue <= 0.00 then
            call Dungeon_IssueAIRouteOrder(whichUnit, dungeonId)
            set reissue = DUNGEON_AI_ROUTE_REISSUE
        endif
        set Dungeon_RouteReissue.real[unitKey] = reissue
        set leader = null
    endfunction

    private function Dungeon_UpdateAIRouteEnum takes nothing returns nothing
        call Dungeon_UpdateAIRouteUnit(GetEnumUnit())
    endfunction

    private function Dungeon_OnAIRouteTick takes nothing returns nothing
        call ForGroup(Dungeon_AIRouteGroup, function Dungeon_UpdateAIRouteEnum)
    endfunction

    private function Dungeon_OnCompanionLeaderChanged takes nothing returns nothing
        local unit whichUnit = Companions_EventUnit

        if whichUnit != null and Dungeon_RouteDungeon[GetHandleId(whichUnit)] > 0 then
            call Dungeon_UpdateAIRouteUnit(whichUnit)
        endif
        set whichUnit = null
    endfunction

    private function Dungeon_OnAIRevived takes nothing returns nothing
        call StartAIRoute(AI_EventUnit)
    endfunction

    private function Dungeon_OnHeroRevived takes nothing returns nothing
        call StartAIRoute(Death_EventHero)
    endfunction

    private function Dungeon_OnZoneEnter takes nothing returns nothing
        local unit enteringUnit = ZoneEvent_EventUnit
        local integer unitKey

        if enteringUnit != null then
            set unitKey = GetHandleId(enteringUnit)
            if Dungeon_RouteDungeon[unitKey] > 0 and Dungeon_GetIdForZoneInternal(ZoneEvent_EventZoneId) == Dungeon_RouteDungeon[unitKey] and Dungeon_IsUnitInside(Dungeon_RouteDungeon[unitKey], enteringUnit) then
                call Dungeon_CancelAIRouteInternal(enteringUnit, true)
            endif
        endif
        set enteringUnit = null
    endfunction

    private function Dungeon_OnUnitDeath takes nothing returns nothing
        local unit dyingUnit = UnitDeathEvent_GetDyingUnit()
        local integer unitKey
        local integer slotId
        local integer dungeonId

        if dyingUnit == null then
            return
        endif
        set unitKey = GetHandleId(dyingUnit)
        if Dungeon_RouteDungeon[unitKey] > 0 then
            call Dungeon_CancelAIRouteInternal(dyingUnit, true)
        endif

        set slotId = Dungeon_UnitToSlot[unitKey]
        if Dungeon_IsValidSlot(slotId) then
            set dungeonId = Dungeon_SlotDungeon[slotId]
            if Dungeon_SlotRespawnMode[slotId] == DUNGEON_RESPAWN_RANDOM and Dungeon_SlotBossId[slotId] == 0 then
                call Dungeon_ScheduleRandomRespawn(slotId)
            else
                call ScheduleFullRespawn(dungeonId)
            endif
        endif
        set dyingUnit = null
    endfunction

    private function Init takes nothing returns nothing
        set Dungeon_ZoneToId = Table.create()
        set Dungeon_UnitToSlot = Table.create()
        set Dungeon_TimerToDungeon = Table.create()
        set Dungeon_TimerToSlot = Table.create()
        set Dungeon_RouteDungeon = Table.create()
        set Dungeon_RouteRemaining = Table.create()
        set Dungeon_RouteReissue = Table.create()
        set Dungeon_RegisterGroup = CreateGroup()
        set Dungeon_AIRouteGroup = CreateGroup()
        set Dungeon_AIRouteTimer = CreateTimer()
        call TimerStart(Dungeon_AIRouteTimer, DUNGEON_AI_ROUTE_INTERVAL, true, function Dungeon_OnAIRouteTick)
        call UnitDeathEvent_Register(function Dungeon_OnUnitDeath)
        call AI_RegisterAutomaticReviveCallback(function Dungeon_OnAIRevived)
        call Death_RegisterReviveCallback(function Dungeon_OnHeroRevived)
        call ZoneEvent_RegisterEnterAction(function Dungeon_OnZoneEnter)
        call Companions_RegisterLeaderChangeCallback(function Dungeon_OnCompanionLeaderChanged)
    endfunction
endlibrary
