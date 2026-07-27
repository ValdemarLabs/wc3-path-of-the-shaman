/**
    QuestItemSpawner

    Author: Valdemar
    Version:

    Description:
    Reusable quest/event helper for spawning and cleaning up temporary item
    sets at configured rects, points, or locations. Spawn points are picked
    randomly per item, and DespawnRandom / RotateRandom remove random tracked
    items before any replacement spawn.

    Credits:

    How to install:
    Import this library before quest/event libraries that require
    `QuestItemSpawner`.

    API:
    call QuestItemSpawner_Create(integer maxItems) returns integer
    call QuestItemSpawner_SetMaxItems(integer spawnerId, integer maxItems)
    call QuestItemSpawner_AddRect(integer spawnerId, rect spawnRect)
    call QuestItemSpawner_AddPoint(integer spawnerId, real x, real y, real radius)
    call QuestItemSpawner_AddLocation(integer spawnerId, location loc, real radius)
    call QuestItemSpawner_Spawn(integer spawnerId, integer itemTypeId, integer fallbackItemTypeId, integer amount) returns integer
    call QuestItemSpawner_SpawnSimple(integer spawnerId, integer itemTypeId, integer amount) returns integer
    call QuestItemSpawner_DespawnRandom(integer spawnerId, integer amount) returns integer
    call QuestItemSpawner_DespawnAll(integer spawnerId) returns integer
    call QuestItemSpawner_RotateRandom(integer spawnerId, integer itemTypeId, integer fallbackItemTypeId, integer amount) returns integer
    call QuestItemSpawner_GetActiveCount(integer spawnerId) returns integer

**/
library QuestItemSpawner

globals
    private constant boolean DEBUG = false

    // Configuration
    private constant integer QUEST_ITEM_SPAWNER_MAX_SPAWNERS = 64
    private constant integer QUEST_ITEM_SPAWNER_MAX_POINTS = 512
    private constant integer QUEST_ITEM_SPAWNER_MAX_ITEMS = 1024
    private constant real QUEST_ITEM_SPAWNER_TAU = 6.283185307

    // Runtime state
    private integer QuestItemSpawner_NextSpawnerId = 0
    private integer QuestItemSpawner_NextPointId = 0
    private integer QuestItemSpawner_NextItemSlot = 0
    private integer QuestItemSpawner_FreeItemSlot = 0

    private integer array QuestItemSpawner_MaxItems
    private integer array QuestItemSpawner_FirstPoint
    private integer array QuestItemSpawner_PointCount
    private integer array QuestItemSpawner_FirstItem
    private integer array QuestItemSpawner_ItemCount

    private integer array QuestItemSpawner_PointNext
    private boolean array QuestItemSpawner_PointUsesRect
    private rect array QuestItemSpawner_PointRect
    private real array QuestItemSpawner_PointX
    private real array QuestItemSpawner_PointY
    private real array QuestItemSpawner_PointRadius

    private integer array QuestItemSpawner_ItemNext
    private item array QuestItemSpawner_ItemHandle

    private real QuestItemSpawner_PickedX = 0.00
    private real QuestItemSpawner_PickedY = 0.00
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[QuestItemSpawner]|r " + msg)
    endif
endfunction

private function IsValidSpawner takes integer spawnerId returns boolean
    return spawnerId > 0 and spawnerId <= QuestItemSpawner_NextSpawnerId
endfunction

private function NormalizeMaxItems takes integer maxItems returns integer
    if maxItems < 0 then
        return 0
    endif
    return maxItems
endfunction

private function IsLiveTrackedItem takes item trackedItem returns boolean
    local boolean result = false

    if trackedItem != null then
        if GetItemTypeId(trackedItem) != 0 then
            set result = true
        endif
    endif

    set trackedItem = null
    return result
endfunction

private function CreateItemWithFallback takes integer itemTypeId, integer fallbackItemTypeId, real x, real y returns item
    local item createdItem = null

    if itemTypeId != 0 then
        set createdItem = CreateItem(itemTypeId, x, y)
    endif
    if createdItem == null and fallbackItemTypeId != 0 and fallbackItemTypeId != itemTypeId then
        set createdItem = CreateItem(fallbackItemTypeId, x, y)
    endif

    return createdItem
endfunction

private function AcquireItemSlot takes nothing returns integer
    local integer slot

    if QuestItemSpawner_FreeItemSlot != 0 then
        set slot = QuestItemSpawner_FreeItemSlot
        set QuestItemSpawner_FreeItemSlot = QuestItemSpawner_ItemNext[slot]
        set QuestItemSpawner_ItemNext[slot] = 0
        return slot
    endif

    if QuestItemSpawner_NextItemSlot >= QUEST_ITEM_SPAWNER_MAX_ITEMS then
        call DebugMsg("Max tracked item slots reached.")
        return 0
    endif

    set QuestItemSpawner_NextItemSlot = QuestItemSpawner_NextItemSlot + 1
    return QuestItemSpawner_NextItemSlot
endfunction

private function ReleaseItemSlot takes integer slot returns nothing
    set QuestItemSpawner_ItemHandle[slot] = null
    set QuestItemSpawner_ItemNext[slot] = QuestItemSpawner_FreeItemSlot
    set QuestItemSpawner_FreeItemSlot = slot
endfunction

private function TrackItem takes integer spawnerId, item trackedItem returns boolean
    local integer slot

    if not IsValidSpawner(spawnerId) or trackedItem == null then
        set trackedItem = null
        return false
    endif

    set slot = AcquireItemSlot()
    if slot == 0 then
        set trackedItem = null
        return false
    endif

    set QuestItemSpawner_ItemHandle[slot] = trackedItem
    set QuestItemSpawner_ItemNext[slot] = QuestItemSpawner_FirstItem[spawnerId]
    set QuestItemSpawner_FirstItem[spawnerId] = slot
    set QuestItemSpawner_ItemCount[spawnerId] = QuestItemSpawner_ItemCount[spawnerId] + 1

    set trackedItem = null
    return true
endfunction

private function RemoveTrackedItemSlot takes integer spawnerId, integer slot, boolean removeItem returns nothing
    local integer previous = 0
    local integer current
    local integer nextSlot
    local item trackedItem = null

    if not IsValidSpawner(spawnerId) or slot <= 0 then
        return
    endif

    set current = QuestItemSpawner_FirstItem[spawnerId]
    loop
        exitwhen current == 0
        set nextSlot = QuestItemSpawner_ItemNext[current]
        if current == slot then
            if previous == 0 then
                set QuestItemSpawner_FirstItem[spawnerId] = nextSlot
            else
                set QuestItemSpawner_ItemNext[previous] = nextSlot
            endif

            if removeItem then
                set trackedItem = QuestItemSpawner_ItemHandle[current]
                if IsLiveTrackedItem(trackedItem) then
                    call RemoveItem(trackedItem)
                endif
                set trackedItem = null
            endif

            if QuestItemSpawner_ItemCount[spawnerId] > 0 then
                set QuestItemSpawner_ItemCount[spawnerId] = QuestItemSpawner_ItemCount[spawnerId] - 1
            endif
            call ReleaseItemSlot(current)
            return
        endif
        set previous = current
        set current = nextSlot
    endloop

    set trackedItem = null
endfunction

private function CompactSpawnerItems takes integer spawnerId returns integer
    local integer current
    local integer nextSlot
    local integer activeCount = 0
    local item trackedItem = null

    if not IsValidSpawner(spawnerId) then
        return 0
    endif

    set current = QuestItemSpawner_FirstItem[spawnerId]
    loop
        exitwhen current == 0
        set nextSlot = QuestItemSpawner_ItemNext[current]
        set trackedItem = QuestItemSpawner_ItemHandle[current]
        if IsLiveTrackedItem(trackedItem) then
            set activeCount = activeCount + 1
        else
            call RemoveTrackedItemSlot(spawnerId, current, false)
        endif
        set current = nextSlot
    endloop

    set QuestItemSpawner_ItemCount[spawnerId] = activeCount
    set trackedItem = null
    return activeCount
endfunction

private function GetPointSlotByIndex takes integer spawnerId, integer pointIndex returns integer
    local integer current
    local integer index = 1

    if not IsValidSpawner(spawnerId) or pointIndex <= 0 then
        return 0
    endif

    set current = QuestItemSpawner_FirstPoint[spawnerId]
    loop
        exitwhen current == 0
        if index == pointIndex then
            return current
        endif
        set index = index + 1
        set current = QuestItemSpawner_PointNext[current]
    endloop

    return 0
endfunction

private function PickSpawnPoint takes integer spawnerId returns boolean
    local integer pointSlot
    local real angle
    local real radius

    if not IsValidSpawner(spawnerId) or QuestItemSpawner_PointCount[spawnerId] <= 0 then
        return false
    endif

    set pointSlot = GetPointSlotByIndex(spawnerId, GetRandomInt(1, QuestItemSpawner_PointCount[spawnerId]))
    if pointSlot == 0 then
        return false
    endif

    if QuestItemSpawner_PointUsesRect[pointSlot] then
        if QuestItemSpawner_PointRect[pointSlot] == null then
            return false
        endif
        set QuestItemSpawner_PickedX = GetRandomReal(GetRectMinX(QuestItemSpawner_PointRect[pointSlot]), GetRectMaxX(QuestItemSpawner_PointRect[pointSlot]))
        set QuestItemSpawner_PickedY = GetRandomReal(GetRectMinY(QuestItemSpawner_PointRect[pointSlot]), GetRectMaxY(QuestItemSpawner_PointRect[pointSlot]))
    else
        set radius = QuestItemSpawner_PointRadius[pointSlot]
        if radius > 0.00 then
            set angle = GetRandomReal(0.00, QUEST_ITEM_SPAWNER_TAU)
            set radius = GetRandomReal(0.00, radius)
            set QuestItemSpawner_PickedX = QuestItemSpawner_PointX[pointSlot] + radius * Cos(angle)
            set QuestItemSpawner_PickedY = QuestItemSpawner_PointY[pointSlot] + radius * Sin(angle)
        else
            set QuestItemSpawner_PickedX = QuestItemSpawner_PointX[pointSlot]
            set QuestItemSpawner_PickedY = QuestItemSpawner_PointY[pointSlot]
        endif
    endif

    return true
endfunction

private function AddPointInternal takes integer spawnerId, boolean useRect, rect spawnRect, real x, real y, real radius returns nothing
    local integer pointId

    if not IsValidSpawner(spawnerId) then
        set spawnRect = null
        return
    endif

    if QuestItemSpawner_NextPointId >= QUEST_ITEM_SPAWNER_MAX_POINTS then
        call DebugMsg("Max spawn points reached.")
        set spawnRect = null
        return
    endif

    if useRect and spawnRect == null then
        set spawnRect = null
        return
    endif

    set QuestItemSpawner_NextPointId = QuestItemSpawner_NextPointId + 1
    set pointId = QuestItemSpawner_NextPointId
    set QuestItemSpawner_PointUsesRect[pointId] = useRect
    set QuestItemSpawner_PointRect[pointId] = spawnRect
    set QuestItemSpawner_PointX[pointId] = x
    set QuestItemSpawner_PointY[pointId] = y
    set QuestItemSpawner_PointRadius[pointId] = radius
    set QuestItemSpawner_PointNext[pointId] = QuestItemSpawner_FirstPoint[spawnerId]
    set QuestItemSpawner_FirstPoint[spawnerId] = pointId
    set QuestItemSpawner_PointCount[spawnerId] = QuestItemSpawner_PointCount[spawnerId] + 1

    set spawnRect = null
endfunction

private function GetItemSlotByIndex takes integer spawnerId, integer itemIndex returns integer
    local integer current
    local integer index = 1

    if not IsValidSpawner(spawnerId) or itemIndex <= 0 then
        return 0
    endif

    set current = QuestItemSpawner_FirstItem[spawnerId]
    loop
        exitwhen current == 0
        if index == itemIndex then
            return current
        endif
        set index = index + 1
        set current = QuestItemSpawner_ItemNext[current]
    endloop

    return 0
endfunction

public function Create takes integer maxItems returns integer
    if QuestItemSpawner_NextSpawnerId >= QUEST_ITEM_SPAWNER_MAX_SPAWNERS then
        call DebugMsg("Max spawners reached.")
        return 0
    endif

    set QuestItemSpawner_NextSpawnerId = QuestItemSpawner_NextSpawnerId + 1
    set QuestItemSpawner_MaxItems[QuestItemSpawner_NextSpawnerId] = NormalizeMaxItems(maxItems)
    set QuestItemSpawner_FirstPoint[QuestItemSpawner_NextSpawnerId] = 0
    set QuestItemSpawner_PointCount[QuestItemSpawner_NextSpawnerId] = 0
    set QuestItemSpawner_FirstItem[QuestItemSpawner_NextSpawnerId] = 0
    set QuestItemSpawner_ItemCount[QuestItemSpawner_NextSpawnerId] = 0
    return QuestItemSpawner_NextSpawnerId
endfunction

public function SetMaxItems takes integer spawnerId, integer maxItems returns nothing
    if IsValidSpawner(spawnerId) then
        set QuestItemSpawner_MaxItems[spawnerId] = NormalizeMaxItems(maxItems)
    endif
endfunction

public function AddRect takes integer spawnerId, rect spawnRect returns nothing
    call AddPointInternal(spawnerId, true, spawnRect, 0.00, 0.00, 0.00)
    set spawnRect = null
endfunction

public function AddPoint takes integer spawnerId, real x, real y, real radius returns nothing
    if radius < 0.00 then
        set radius = 0.00
    endif
    call AddPointInternal(spawnerId, false, null, x, y, radius)
endfunction

public function AddLocation takes integer spawnerId, location loc, real radius returns nothing
    if loc != null then
        call AddPoint(spawnerId, GetLocationX(loc), GetLocationY(loc), radius)
    endif
    set loc = null
endfunction

public function Spawn takes integer spawnerId, integer itemTypeId, integer fallbackItemTypeId, integer amount returns integer
    local integer activeCount
    local integer allowed
    local integer attempts = 0
    local integer created = 0
    local item createdItem = null

    if not IsValidSpawner(spawnerId) or amount <= 0 or (itemTypeId == 0 and fallbackItemTypeId == 0) then
        set createdItem = null
        return 0
    endif

    if QuestItemSpawner_PointCount[spawnerId] <= 0 then
        set createdItem = null
        return 0
    endif

    set activeCount = CompactSpawnerItems(spawnerId)
    set allowed = QuestItemSpawner_MaxItems[spawnerId] - activeCount
    if allowed <= 0 then
        set createdItem = null
        return 0
    endif
    if amount > allowed then
        set amount = allowed
    endif

    loop
        exitwhen created >= amount or attempts >= amount
        set attempts = attempts + 1
        if not PickSpawnPoint(spawnerId) then
            set createdItem = null
            return created
        endif
        set createdItem = CreateItemWithFallback(itemTypeId, fallbackItemTypeId, QuestItemSpawner_PickedX, QuestItemSpawner_PickedY)
        if createdItem != null then
            if TrackItem(spawnerId, createdItem) then
                set created = created + 1
            else
                call RemoveItem(createdItem)
            endif
        endif
    endloop

    set createdItem = null
    return created
endfunction

public function SpawnSimple takes integer spawnerId, integer itemTypeId, integer amount returns integer
    return Spawn(spawnerId, itemTypeId, 0, amount)
endfunction

public function GetActiveCount takes integer spawnerId returns integer
    return CompactSpawnerItems(spawnerId)
endfunction

public function DespawnRandom takes integer spawnerId, integer amount returns integer
    local integer activeCount
    local integer removed = 0
    local integer slot

    if not IsValidSpawner(spawnerId) or amount <= 0 then
        return 0
    endif

    set activeCount = CompactSpawnerItems(spawnerId)
    loop
        exitwhen removed >= amount or activeCount <= 0
        set slot = GetItemSlotByIndex(spawnerId, GetRandomInt(1, activeCount))
        if slot == 0 then
            return removed
        endif
        call RemoveTrackedItemSlot(spawnerId, slot, true)
        set removed = removed + 1
        set activeCount = activeCount - 1
    endloop

    return removed
endfunction

public function DespawnAll takes integer spawnerId returns integer
    local integer current
    local integer nextSlot
    local integer removed = 0

    if not IsValidSpawner(spawnerId) then
        return 0
    endif

    set current = QuestItemSpawner_FirstItem[spawnerId]
    loop
        exitwhen current == 0
        set nextSlot = QuestItemSpawner_ItemNext[current]
        call RemoveTrackedItemSlot(spawnerId, current, true)
        set removed = removed + 1
        set current = nextSlot
    endloop

    set QuestItemSpawner_FirstItem[spawnerId] = 0
    set QuestItemSpawner_ItemCount[spawnerId] = 0
    return removed
endfunction

public function RotateRandom takes integer spawnerId, integer itemTypeId, integer fallbackItemTypeId, integer amount returns integer
    local integer removed = DespawnRandom(spawnerId, amount)
    return Spawn(spawnerId, itemTypeId, fallbackItemTypeId, removed)
endfunction

endlibrary
