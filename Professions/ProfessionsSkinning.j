/**
    ProfessionsSkinning

    Author: Valdemar
    Version: 1.1

    Description: Runtime Skinning profession flow. Units cast the Skinning Knife ability on top of a skinnable dead beast to create the configured skin item.

    Credits:

    How to install:
    Import this library after Professions, GatherNodeSkills, Events, UnitDeathEvent, Table, and Interface.

    API:
    call ProfessionsSkinning_Init()
    call ProfessionsSkinning_RegisterSkinningUnit('unit', 'item', "Display Name", requiredSkill)

**/

library ProfessionsSkinning initializer AutoInit requires Professions, GatherNodeSkills, Events, UnitDeathEvent, Table, Interface, optional SharedDInvLib

globals
    // Runtime guard.
    private boolean PS_Initialized = false
    private constant boolean PS_AI_CHEAT_CRAFTING = true
    private constant string PS_CRAFTER_ANIMATION_PRIMARY = "stand work"
    private constant string PS_CRAFTER_ANIMATION_FALLBACK = "attack"

    // Skinning action.
    private constant integer PS_ABILITY_SKIN = 'A0F3'
    private constant integer PS_ITEM_SKINNING_KNIFE = 'I66M'
    private constant integer PS_ITEM_SKINNING_KNIFE_ALT = 'i66m'
    private constant integer PS_DEQUIPMENT_SLOT_MAIN_HAND = 19
    private constant real PS_SKIN_DURATION = 1.50
    private constant real PS_SKIN_RANGE = 128.00
    private constant real PS_SKIN_RANGE_SQ = 16384.00
    private constant real PS_ORDER_GRACE_DURATION = 0.10
    private constant integer PS_SKIN_SKILL_GAIN = 1

    // Skin items.
    private constant integer PS_ITEM_BEAR_SKIN = 'I61B'
    private constant integer PS_ITEM_BOAR_SKIN = 'I61C'
    private constant integer PS_ITEM_FROG_SKIN = 'I61D'
    private constant integer PS_ITEM_TURTLE_SKIN = 'I61E'
    private constant integer PS_ITEM_WOLF_SKIN = 'I61F'
    private constant integer PS_ITEM_THUNDER_LIZARD_SKIN = 'I61G'
    private constant integer PS_ITEM_VIZIER_SKIN = 'I61N'

    private constant string PS_SOUND_START = "Tradeskill_LeatherworkingPick"
    private constant string PS_SOUND_LOOP = "Tradeskill_LeatherworkingPick"
    private constant string PS_SOUND_FINISH = "Tradeskill_LeatherworkingPick"

    private constant string PS_NEED_KNIFE_TEXT = "Requires a Skinning Knife."
    private constant string PS_NO_CORPSE_TEXT = "No skinnable beast corpse nearby."
    private constant string PS_ALREADY_SKINNING_TEXT = "Already skinning."
    private constant string PS_BUSY_TEXT = "Unit is busy."
    private constant string PS_INTERRUPTED_TEXT = "Skinning interrupted."

    private Table PS_SkinItemByUnitType = 0
    private Table PS_SkinRequiredSkillByUnitType = 0
    private Table PS_SkinNameByUnitType = 0
    private Table PS_CorpseSkinned = 0
    private Table PS_CorpseReserved = 0
    private Table PS_ActiveJobByCaster = 0
    private Table PS_TimerJob = 0

    private group PS_SearchGroup = null
    private timer PS_ClockTimer = null

    private integer PS_JobCount = 0
    private integer PS_FreeJobCount = 0
    private integer array PS_FreeJobStack
    private unit array PS_JobSkinner
    private unit array PS_JobCorpse
    private timer array PS_JobTimer
    private real array PS_JobIgnoreOrdersUntil
    private boolean array PS_JobCompleting

    private unit PS_SearchBestUnit = null
    private real PS_SearchBestDistanceSq = 0.00
endglobals

private function PS_NoOp takes nothing returns nothing
endfunction

private function PS_EnsureTables takes nothing returns nothing
    if PS_SkinItemByUnitType == 0 then
        set PS_SkinItemByUnitType = Table.create()
        set PS_SkinRequiredSkillByUnitType = Table.create()
        set PS_SkinNameByUnitType = Table.create()
        set PS_CorpseSkinned = Table.create()
        set PS_CorpseReserved = Table.create()
        set PS_ActiveJobByCaster = Table.create()
        set PS_TimerJob = Table.create()
    endif
    if PS_SearchGroup == null then
        set PS_SearchGroup = CreateGroup()
    endif
    if PS_ClockTimer == null then
        set PS_ClockTimer = CreateTimer()
        call TimerStart(PS_ClockTimer, 999999.00, false, function PS_NoOp)
    endif
endfunction

private function PS_GetNow takes nothing returns real
    call PS_EnsureTables()
    return TimerGetElapsed(PS_ClockTimer)
endfunction

private function PS_DisplayError takes player whichPlayer, string message returns nothing
    if whichPlayer != null and message != null and message != "" then
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "|cffff8080" + message + "|r")
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, whichPlayer)
    endif
endfunction

private function PS_IsUnitAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
endfunction

private function PS_IsUnitCorpse takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) <= 0.405
endfunction

private function PS_GetDistanceSqBetweenUnits takes unit a, unit b returns real
    local real dx
    local real dy

    if a == null or b == null then
        return 999999999.00
    endif

    set dx = GetUnitX(a) - GetUnitX(b)
    set dy = GetUnitY(a) - GetUnitY(b)
    return dx * dx + dy * dy
endfunction

private function PS_HasVanillaKnifeType takes unit skinner, integer itemTypeId returns boolean
    local integer slot = 0
    local integer slotCount = 0
    local item it = null

    if skinner == null then
        return false
    endif

    set slotCount = UnitInventorySize(skinner)
    loop
        exitwhen slot >= slotCount
        set it = UnitItemInSlot(skinner, slot)
        if it != null and GetItemTypeId(it) == itemTypeId then
            set it = null
            return true
        endif
        set slot = slot + 1
    endloop

    set it = null
    return false
endfunction

private function PS_HasDInventoryKnifeType takes unit skinner, integer itemTypeId returns boolean
    static if LIBRARY_SharedDInvLib then
        if skinner != null and BIDOfUnit(skinner) != -1 and GetDInvItemChargesByType(skinner, itemTypeId) > 0 then
            return true
        endif
    endif
    return false
endfunction

private function PS_HasEquippedMainHandKnifeType takes unit skinner, integer itemTypeId returns boolean
    local integer eqId = 0
    local item mainHand = null

    static if LIBRARY_SharedDInvLib then
        if skinner != null then
            set eqId = EQIDOfUnit(skinner)
            if eqId > 0 then
                set mainHand = EQIDDB[eqId][4].item[PS_DEQUIPMENT_SLOT_MAIN_HAND]
                if mainHand != null and GetItemTypeId(mainHand) == itemTypeId then
                    set mainHand = null
                    return true
                endif
            endif
        endif
    endif

    set mainHand = null
    return false
endfunction

private function PS_HasSkinningKnifeType takes unit skinner, integer itemTypeId returns boolean
    return PS_HasDInventoryKnifeType(skinner, itemTypeId) or PS_HasVanillaKnifeType(skinner, itemTypeId) or PS_HasEquippedMainHandKnifeType(skinner, itemTypeId)
endfunction

private function PS_HasSkinningKnife takes unit skinner returns boolean
    return PS_HasSkinningKnifeType(skinner, PS_ITEM_SKINNING_KNIFE) or PS_HasSkinningKnifeType(skinner, PS_ITEM_SKINNING_KNIFE_ALT)
endfunction

private function PS_IsCorpseSkinnable takes unit corpse returns boolean
    local integer handleId

    call PS_EnsureTables()
    if not PS_IsUnitCorpse(corpse) then
        return false
    endif
    if not PS_SkinItemByUnitType.has(GetUnitTypeId(corpse)) then
        return false
    endif

    set handleId = GetHandleId(corpse)
    return not PS_CorpseSkinned.boolean[handleId] and not PS_CorpseReserved.has(handleId)
endfunction

private function PS_FindNearestSkinCorpse takes unit skinner returns unit
    local unit enumUnit = null
    local unit bestUnit = null
    local real distanceSq

    call PS_EnsureTables()
    set PS_SearchBestUnit = null
    set PS_SearchBestDistanceSq = PS_SKIN_RANGE_SQ

    if skinner == null then
        return null
    endif

    call GroupClear(PS_SearchGroup)
    call GroupEnumUnitsInRange(PS_SearchGroup, GetUnitX(skinner), GetUnitY(skinner), PS_SKIN_RANGE, null)
    loop
        set enumUnit = FirstOfGroup(PS_SearchGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(PS_SearchGroup, enumUnit)
        if PS_IsCorpseSkinnable(enumUnit) then
            set distanceSq = PS_GetDistanceSqBetweenUnits(skinner, enumUnit)
            if distanceSq <= PS_SearchBestDistanceSq then
                set PS_SearchBestDistanceSq = distanceSq
                set PS_SearchBestUnit = enumUnit
            endif
        endif
    endloop

    set bestUnit = PS_SearchBestUnit
    set PS_SearchBestUnit = null
    set enumUnit = null
    return bestUnit
endfunction

private function PS_AllocateJobId takes nothing returns integer
    if PS_FreeJobCount > 0 then
        set PS_FreeJobCount = PS_FreeJobCount - 1
        return PS_FreeJobStack[PS_FreeJobCount + 1]
    endif

    set PS_JobCount = PS_JobCount + 1
    return PS_JobCount
endfunction

private function PS_FreeJobId takes integer jobId returns nothing
    if jobId <= 0 then
        return
    endif
    set PS_FreeJobCount = PS_FreeJobCount + 1
    set PS_FreeJobStack[PS_FreeJobCount] = jobId
endfunction

private function PS_ClearJob takes integer jobId returns nothing
    local unit skinner = null
    local unit corpse = null
    local timer jobTimer = null
    local integer handleId = 0

    if jobId <= 0 then
        return
    endif

    set skinner = PS_JobSkinner[jobId]
    set corpse = PS_JobCorpse[jobId]
    set jobTimer = PS_JobTimer[jobId]

    if skinner != null then
        call PS_ActiveJobByCaster.remove(GetHandleId(skinner))
    endif
    if corpse != null then
        set handleId = GetHandleId(corpse)
        if PS_CorpseReserved.integer[handleId] == jobId then
            call PS_CorpseReserved.remove(handleId)
        endif
    endif
    if jobTimer != null then
        call PS_TimerJob.remove(GetHandleId(jobTimer))
        call PauseTimer(jobTimer)
        call DestroyTimer(jobTimer)
    endif

    set PS_JobSkinner[jobId] = null
    set PS_JobCorpse[jobId] = null
    set PS_JobTimer[jobId] = null
    set PS_JobIgnoreOrdersUntil[jobId] = 0.00
    set PS_JobCompleting[jobId] = false
    call PS_FreeJobId(jobId)

    set jobTimer = null
    set corpse = null
    set skinner = null
endfunction

private function PS_ResetSkinnerAnimation takes unit skinner returns nothing
    if skinner != null then
        call ResetUnitAnimation(skinner)
        call SetUnitAnimation(skinner, "stand")
    endif
endfunction

private function PS_CancelJob takes integer jobId, boolean showMessage returns nothing
    local unit skinner = null
    local player whichPlayer = null

    if jobId <= 0 then
        return
    endif

    set skinner = PS_JobSkinner[jobId]
    if skinner != null then
        set whichPlayer = GetOwningPlayer(skinner)
        call PS_ResetSkinnerAnimation(skinner)
        if showMessage then
            call PS_DisplayError(whichPlayer, PS_INTERRUPTED_TEXT)
        endif
    endif

    call PS_ClearJob(jobId)

    set whichPlayer = null
    set skinner = null
endfunction

private function PS_IsJobStillValid takes integer jobId returns boolean
    local unit skinner = null
    local unit corpse = null
    local boolean result = false

    if jobId <= 0 then
        return false
    endif

    set skinner = PS_JobSkinner[jobId]
    set corpse = PS_JobCorpse[jobId]
    if not PS_IsUnitAlive(skinner) then
        set corpse = null
        set skinner = null
        return false
    endif
    if not PS_IsUnitCorpse(corpse) then
        set corpse = null
        set skinner = null
        return false
    endif
    if not PS_SkinItemByUnitType.has(GetUnitTypeId(corpse)) then
        set corpse = null
        set skinner = null
        return false
    endif
    if not PS_HasSkinningKnife(skinner) then
        set corpse = null
        set skinner = null
        return false
    endif
    if PS_CorpseSkinned.boolean[GetHandleId(corpse)] then
        set corpse = null
        set skinner = null
        return false
    endif

    set result = PS_GetDistanceSqBetweenUnits(skinner, corpse) <= PS_SKIN_RANGE_SQ

    set corpse = null
    set skinner = null
    return result
endfunction

private function PS_CompleteJob takes integer jobId returns nothing
    local unit skinner = null
    local unit corpse = null
    local player whichPlayer = null
    local item createdSkin = null
    local integer corpseHandleId = 0
    local integer corpseTypeId = 0
    local integer skinItemTypeId = 0
    local integer requiredSkill = 0
    local real x = 0.00
    local real y = 0.00

    if jobId <= 0 then
        return
    endif

    set skinner = PS_JobSkinner[jobId]
    set corpse = PS_JobCorpse[jobId]
    if not PS_IsJobStillValid(jobId) then
        call PS_CancelJob(jobId, true)
        set corpse = null
        set skinner = null
        return
    endif

    set corpseHandleId = GetHandleId(corpse)
    set corpseTypeId = GetUnitTypeId(corpse)
    set skinItemTypeId = PS_SkinItemByUnitType.integer[corpseTypeId]
    set requiredSkill = PS_SkinRequiredSkillByUnitType.integer[corpseTypeId]
    set x = GetUnitX(corpse)
    set y = GetUnitY(corpse)
    set whichPlayer = GetOwningPlayer(skinner)

    set PS_JobCompleting[jobId] = true
    set PS_CorpseSkinned.boolean[corpseHandleId] = true
    set createdSkin = CreateItem(skinItemTypeId, x, y)
    call GNS_AwardGatherSkillForNode(skinner, GNS_PROF_SKINNING, requiredSkill, PS_SKIN_SKILL_GAIN)
    call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, whichPlayer)
    call PS_ResetSkinnerAnimation(skinner)
    call PS_ClearJob(jobId)

    set createdSkin = null
    set whichPlayer = null
    set corpse = null
    set skinner = null
endfunction

private function PS_FinishJobAction takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer jobId = 0

    if expiredTimer != null and PS_TimerJob != 0 and PS_TimerJob.has(GetHandleId(expiredTimer)) then
        set jobId = PS_TimerJob.integer[GetHandleId(expiredTimer)]
        call PS_CompleteJob(jobId)
    endif

    set expiredTimer = null
endfunction

private function PS_StartSkinning takes unit skinner returns boolean
    local player whichPlayer = null
    local unit corpse = null
    local timer jobTimer = null
    local integer jobId = 0
    local integer skinnerHandleId = 0
    local integer corpseHandleId = 0

    call PS_EnsureTables()
    if skinner == null then
        return false
    endif

    set whichPlayer = GetOwningPlayer(skinner)
    set skinnerHandleId = GetHandleId(skinner)

    if PS_ActiveJobByCaster.has(skinnerHandleId) then
        call PS_DisplayError(whichPlayer, PS_ALREADY_SKINNING_TEXT)
        set whichPlayer = null
        return false
    endif
    if Professions_IsUnitReserved(skinner) then
        call PS_DisplayError(whichPlayer, PS_BUSY_TEXT)
        set whichPlayer = null
        return false
    endif
    if not PS_HasSkinningKnife(skinner) then
        call PS_DisplayError(whichPlayer, PS_NEED_KNIFE_TEXT)
        set whichPlayer = null
        return false
    endif

    set corpse = PS_FindNearestSkinCorpse(skinner)
    if corpse == null then
        call PS_DisplayError(whichPlayer, PS_NO_CORPSE_TEXT)
        set whichPlayer = null
        return false
    endif

    set corpseHandleId = GetHandleId(corpse)
    set jobId = PS_AllocateJobId()
    set jobTimer = CreateTimer()
    set PS_JobSkinner[jobId] = skinner
    set PS_JobCorpse[jobId] = corpse
    set PS_JobTimer[jobId] = jobTimer
    set PS_JobIgnoreOrdersUntil[jobId] = PS_GetNow() + PS_ORDER_GRACE_DURATION
    set PS_JobCompleting[jobId] = false
    set PS_ActiveJobByCaster.integer[skinnerHandleId] = jobId
    set PS_CorpseReserved.integer[corpseHandleId] = jobId
    set PS_TimerJob.integer[GetHandleId(jobTimer)] = jobId

    call SetUnitFacing(skinner, Atan2(GetUnitY(corpse) - GetUnitY(skinner), GetUnitX(corpse) - GetUnitX(skinner)) * bj_RADTODEG)
    call SetUnitAnimation(skinner, PS_CRAFTER_ANIMATION_PRIMARY)
    call TimerStart(jobTimer, PS_SKIN_DURATION, false, function PS_FinishJobAction)

    set jobTimer = null
    set corpse = null
    set whichPlayer = null
    return true
endfunction

private function PS_SpellAction takes nothing returns nothing
    local unit skinner = GetTriggerUnit()

    if GetSpellAbilityId() == PS_ABILITY_SKIN and skinner != null then
        if PS_ActiveJobByCaster == 0 then
            call PS_StartSkinning(skinner)
        elseif not PS_ActiveJobByCaster.has(GetHandleId(skinner)) then
            call PS_StartSkinning(skinner)
        endif
    endif

    set skinner = null
endfunction

private function PS_OrderAction takes nothing returns nothing
    local unit skinner = GetTriggerUnit()
    local integer jobId = 0

    if skinner != null and PS_ActiveJobByCaster != 0 and PS_ActiveJobByCaster.has(GetHandleId(skinner)) then
        set jobId = PS_ActiveJobByCaster.integer[GetHandleId(skinner)]
        if jobId > 0 and not PS_JobCompleting[jobId] and PS_GetNow() >= PS_JobIgnoreOrdersUntil[jobId] then
            call PS_CancelJob(jobId, true)
        endif
    endif

    set skinner = null
endfunction

private function PS_AttackedAction takes nothing returns nothing
    local unit attackedUnit = GetTriggerUnit()
    local integer jobId = 0

    if attackedUnit != null and PS_ActiveJobByCaster != 0 and PS_ActiveJobByCaster.has(GetHandleId(attackedUnit)) then
        set jobId = PS_ActiveJobByCaster.integer[GetHandleId(attackedUnit)]
        if jobId > 0 then
            call PS_CancelJob(jobId, true)
        endif
    endif

    set attackedUnit = null
endfunction

private function PS_DeathAction takes nothing returns nothing
    local unit dyingUnit = GetDyingUnit()
    local integer handleId = 0
    local integer jobId = 0

    if dyingUnit != null then
        set handleId = GetHandleId(dyingUnit)
        if PS_CorpseSkinned != 0 then
            call PS_CorpseSkinned.remove(handleId)
        endif
        if PS_CorpseReserved != 0 and PS_CorpseReserved.has(handleId) then
            call PS_CorpseReserved.remove(handleId)
        endif
        if PS_ActiveJobByCaster != 0 and PS_ActiveJobByCaster.has(handleId) then
            set jobId = PS_ActiveJobByCaster.integer[handleId]
            if jobId > 0 then
                call PS_CancelJob(jobId, true)
            endif
        endif
    endif

    set dyingUnit = null
endfunction

private function PS_RegisterSkinningUnitInternal takes integer unitTypeId, integer skinItemTypeId, string displayName, integer requiredSkill returns nothing
    call PS_EnsureTables()
    if unitTypeId == 0 or skinItemTypeId == 0 then
        return
    endif

    set PS_SkinItemByUnitType.integer[unitTypeId] = skinItemTypeId
    set PS_SkinRequiredSkillByUnitType.integer[unitTypeId] = requiredSkill
    set PS_SkinNameByUnitType.string[unitTypeId] = displayName
endfunction

private function PS_RegisterDefaultSkinningUnits takes nothing returns nothing
    // Boars
    call PS_RegisterSkinningUnitInternal('npig', PS_ITEM_BOAR_SKIN, "Boar", 0)
    call PS_RegisterSkinningUnitInternal('n63C', PS_ITEM_BOAR_SKIN, "Boar", 0)
    call PS_RegisterSkinningUnitInternal('n63U', PS_ITEM_BOAR_SKIN, "Boar", 0)
    call PS_RegisterSkinningUnitInternal('n65J', PS_ITEM_BOAR_SKIN, "Fel Boar", 0)
    call PS_RegisterSkinningUnitInternal('n65K', PS_ITEM_BOAR_SKIN, "Fel Boar", 0)
    call PS_RegisterSkinningUnitInternal('n65L', PS_ITEM_BOAR_SKIN, "Fel Boar", 0)

    // Bears
    call PS_RegisterSkinningUnitInternal('ngz1', PS_ITEM_BEAR_SKIN, "Bear Cub", 0)
    call PS_RegisterSkinningUnitInternal('ngz2', PS_ITEM_BEAR_SKIN, "Bear", 0)
    call PS_RegisterSkinningUnitInternal('ngz4', PS_ITEM_BEAR_SKIN, "Mother Bear", 0)
    call PS_RegisterSkinningUnitInternal('ngza', PS_ITEM_BEAR_SKIN, "Ferocious Bear", 0)
    call PS_RegisterSkinningUnitInternal('n02C', PS_ITEM_BEAR_SKIN, "Ursa", 0)

    // Frogs
    call PS_RegisterSkinningUnitInternal('nfro', PS_ITEM_FROG_SKIN, "Frog", 0)

    // Turtles
    call PS_RegisterSkinningUnitInternal('ntrh', PS_ITEM_TURTLE_SKIN, "Sea Turtle", 0)
    call PS_RegisterSkinningUnitInternal('ntrs', PS_ITEM_TURTLE_SKIN, "Sea Turtle", 0)
    call PS_RegisterSkinningUnitInternal('ntrt', PS_ITEM_TURTLE_SKIN, "Sea Turtle", 0)
    call PS_RegisterSkinningUnitInternal('ntrg', PS_ITEM_TURTLE_SKIN, "Sea Turtle", 0)
    call PS_RegisterSkinningUnitInternal('n01F', PS_ITEM_TURTLE_SKIN, "Giant Sea Turtle", 0)
    call PS_RegisterSkinningUnitInternal('n01G', PS_ITEM_TURTLE_SKIN, "Giant Sea Turtle", 0)

    // Wolves
    call PS_RegisterSkinningUnitInternal('o600', PS_ITEM_WOLF_SKIN, "Wolf", 0)
    call PS_RegisterSkinningUnitInternal('o601', PS_ITEM_WOLF_SKIN, "Wolf", 0)
    call PS_RegisterSkinningUnitInternal('o602', PS_ITEM_WOLF_SKIN, "Wolf", 0)
    call PS_RegisterSkinningUnitInternal('n648', PS_ITEM_WOLF_SKIN, "Wolf Mother", 0)
    call PS_RegisterSkinningUnitInternal('n64B', PS_ITEM_WOLF_SKIN, "Alpha Wolf", 0)

    // Thunder lizards and salamanders
    call PS_RegisterSkinningUnitInternal('nthl', PS_ITEM_THUNDER_LIZARD_SKIN, "Thunder Lizard", 0)
    call PS_RegisterSkinningUnitInternal('nltl', PS_ITEM_THUNDER_LIZARD_SKIN, "Lightning Lizard", 0)
    call PS_RegisterSkinningUnitInternal('n01U', PS_ITEM_THUNDER_LIZARD_SKIN, "Ember Salamander", 0)
    call PS_RegisterSkinningUnitInternal('n01V', PS_ITEM_THUNDER_LIZARD_SKIN, "Ember Salamander", 0)
    call PS_RegisterSkinningUnitInternal('n02K', PS_ITEM_THUNDER_LIZARD_SKIN, "Salamander Hazzling", 0)

    // Vizier skin currently has no confirmed unit rawcode in the local unit export.
endfunction

public function RegisterSkinningUnit takes integer unitTypeId, integer skinItemTypeId, string displayName, integer requiredSkill returns nothing
    call PS_RegisterSkinningUnitInternal(unitTypeId, skinItemTypeId, displayName, requiredSkill)
endfunction

public function IsUnitTypeSkinnable takes integer unitTypeId returns boolean
    call PS_EnsureTables()
    return PS_SkinItemByUnitType.has(unitTypeId)
endfunction

public function GetSkinItemForUnitType takes integer unitTypeId returns integer
    call PS_EnsureTables()
    if not PS_SkinItemByUnitType.has(unitTypeId) then
        return 0
    endif
    return PS_SkinItemByUnitType.integer[unitTypeId]
endfunction

public function IsUnitSkinned takes unit corpse returns boolean
    if corpse == null or PS_CorpseSkinned == 0 then
        return false
    endif
    return PS_CorpseSkinned.boolean[GetHandleId(corpse)]
endfunction

public function ClearSkinnedState takes unit corpse returns nothing
    if corpse != null and PS_CorpseSkinned != 0 then
        call PS_CorpseSkinned.remove(GetHandleId(corpse))
    endif
endfunction

public function Init takes nothing returns nothing
    if PS_Initialized then
        return
    endif
    set PS_Initialized = true

    call PS_EnsureTables()
    call PS_RegisterDefaultSkinningUnits()

    call Events_RegisterSpellChannel(function PS_SpellAction)
    call Events_RegisterSpellEffect(function PS_SpellAction)
    call Events_RegisterPlayerUnitEvent(function PS_OrderAction, EVENT_PLAYER_UNIT_ISSUED_ORDER)
    call Events_RegisterPlayerUnitEvent(function PS_OrderAction, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
    call Events_RegisterPlayerUnitEvent(function PS_OrderAction, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call Events_RegisterUnitAttacked(function PS_AttackedAction)
    call UnitDeathEvent_Register(function PS_DeathAction)

    call Professions_SetProfessionSoundLabels(GNS_PROF_SKINNING, PS_SOUND_START, PS_SOUND_LOOP, PS_SOUND_FINISH)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_SKINNING, PS_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_SKINNING, PS_CRAFTER_ANIMATION_PRIMARY, PS_CRAFTER_ANIMATION_FALLBACK)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
