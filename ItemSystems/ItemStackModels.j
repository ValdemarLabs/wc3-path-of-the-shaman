/**
    ItemStackModels

    Author: Valdemar
    Version: 1.0

    Description:
    Applies configured ground models to stackable items according to their
    current charge count. Items without registered ranges take the fast path
    and never query or change their model field.

    Credits:
    - Blizzard Entertainment for the item instance field natives

    How to install:
    Import this library before the WC3ItemManager-generated item definitions.
    Requires Warcraft III 1.31 or newer for BlzGetItemStringField and
    BlzSetItemStringField.

    API:
    - ISM_DefineItemType(integer itemTypeId, string defaultModelPath)
    - ISM_DefineStackModel(integer itemTypeId, integer minStack, integer maxStack, string modelPath)
    - ISM_RefreshItem(item whichItem) returns boolean

**/
library ItemStackModels initializer Init

globals
    // Configuration
    private constant real ISM_SCAN_INTERVAL = 0.50

    private constant integer ISM_KEY_RANGE_COUNT = 0
    private constant integer ISM_KEY_DEFAULT_MODEL = 1
    private constant integer ISM_RANGE_KEY_BASE = 10
    private constant integer ISM_RANGE_FIELD_COUNT = 3
    private constant integer ISM_RANGE_FIELD_MIN = 0
    private constant integer ISM_RANGE_FIELD_MAX = 1
    private constant integer ISM_RANGE_FIELD_MODEL = 2

    private hashtable ISM_Data = InitHashtable()
    private trigger ISM_ScanTrigger = null
endglobals

private function ISM_GetRangeKey takes integer rangeIndex, integer fieldOffset returns integer
    return ISM_RANGE_KEY_BASE + rangeIndex * ISM_RANGE_FIELD_COUNT + fieldOffset
endfunction

private function ISM_GetDesiredModel takes integer itemTypeId, integer stackSize returns string
    local integer rangeCount = LoadInteger(ISM_Data, itemTypeId, ISM_KEY_RANGE_COUNT)
    local integer rangeIndex = 0
    local integer minStack
    local integer maxStack

    loop
        exitwhen rangeIndex >= rangeCount
        set minStack = LoadInteger(ISM_Data, itemTypeId, ISM_GetRangeKey(rangeIndex, ISM_RANGE_FIELD_MIN))
        set maxStack = LoadInteger(ISM_Data, itemTypeId, ISM_GetRangeKey(rangeIndex, ISM_RANGE_FIELD_MAX))
        if stackSize >= minStack and stackSize <= maxStack then
            return LoadStr(ISM_Data, itemTypeId, ISM_GetRangeKey(rangeIndex, ISM_RANGE_FIELD_MODEL))
        endif
        set rangeIndex = rangeIndex + 1
    endloop

    return LoadStr(ISM_Data, itemTypeId, ISM_KEY_DEFAULT_MODEL)
endfunction

function ISM_DefineItemType takes integer itemTypeId, string defaultModelPath returns nothing
    if itemTypeId == 0 or defaultModelPath == null or defaultModelPath == "" then
        return
    endif

    call SaveStr(ISM_Data, itemTypeId, ISM_KEY_DEFAULT_MODEL, defaultModelPath)
    call SaveInteger(ISM_Data, itemTypeId, ISM_KEY_RANGE_COUNT, 0)
endfunction

function ISM_DefineStackModel takes integer itemTypeId, integer minStack, integer maxStack, string modelPath returns nothing
    local integer rangeCount

    if itemTypeId == 0 or minStack < 1 or maxStack < minStack or modelPath == null or modelPath == "" then
        return
    endif
    if not HaveSavedString(ISM_Data, itemTypeId, ISM_KEY_DEFAULT_MODEL) then
        return
    endif

    set rangeCount = LoadInteger(ISM_Data, itemTypeId, ISM_KEY_RANGE_COUNT)
    call SaveInteger(ISM_Data, itemTypeId, ISM_GetRangeKey(rangeCount, ISM_RANGE_FIELD_MIN), minStack)
    call SaveInteger(ISM_Data, itemTypeId, ISM_GetRangeKey(rangeCount, ISM_RANGE_FIELD_MAX), maxStack)
    call SaveStr(ISM_Data, itemTypeId, ISM_GetRangeKey(rangeCount, ISM_RANGE_FIELD_MODEL), modelPath)
    call SaveInteger(ISM_Data, itemTypeId, ISM_KEY_RANGE_COUNT, rangeCount + 1)
endfunction

function ISM_RefreshItem takes item whichItem returns boolean
    local integer itemTypeId
    local integer rangeCount
    local string desiredModel

    if whichItem == null then
        return false
    endif

    set itemTypeId = GetItemTypeId(whichItem)
    if not HaveSavedInteger(ISM_Data, itemTypeId, ISM_KEY_RANGE_COUNT) then
        return false
    endif

    set rangeCount = LoadInteger(ISM_Data, itemTypeId, ISM_KEY_RANGE_COUNT)
    if rangeCount <= 0 then
        return false
    endif

    set desiredModel = ISM_GetDesiredModel(itemTypeId, GetItemCharges(whichItem))
    if desiredModel != null and desiredModel != "" and BlzGetItemStringField(whichItem, ITEM_SF_MODEL_USED) != desiredModel then
        return BlzSetItemStringField(whichItem, ITEM_SF_MODEL_USED, desiredModel)
    endif

    return false
endfunction

private function ISM_RefreshEnumItem takes nothing returns nothing
    local item whichItem = GetEnumItem()

    if whichItem != null and IsItemVisible(whichItem) and GetWidgetLife(whichItem) > 0.405 then
        call ISM_RefreshItem(whichItem)
    endif

    set whichItem = null
endfunction

private function ISM_ScanGroundItems takes nothing returns nothing
    call EnumItemsInRect(GetPlayableMapRect(), null, function ISM_RefreshEnumItem)
endfunction

private function Init takes nothing returns nothing
    set ISM_ScanTrigger = CreateTrigger()
    call TriggerRegisterTimerEventPeriodic(ISM_ScanTrigger, ISM_SCAN_INTERVAL)
    call TriggerAddAction(ISM_ScanTrigger, function ISM_ScanGroundItems)
endfunction

endlibrary
