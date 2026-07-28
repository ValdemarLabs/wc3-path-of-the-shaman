/**
    ProfessionsFishing

    Author: Valdemar
    Version: 1.0

    Description: Fishing pool minigame for the Fishing profession. Players select a fish pool with a tracked hero carrying a registered fishing pole, wait for the bite window, and press Reel before the fish escapes.

    Credits:

    How to install:
    Import this library after Professions, GatherNodeSkills, ZonesCore, GatherNodes, GatherNodeUnits, Table, and Interface. Register fish pools through GatherNodeUnits with GNS_PROF_FISHING, zone rewards through GNU_RegisterZoneDrop, and additional poles or bait here.
    For the intended thin fishing-line look with LEAS, import lariatCaught.blp as ReplaceableTextures\Weather\lariatCaught.blp so it replaces the Aerial Shackles lightning texture.

    API:
    call ProfessionsFishing_RegisterPoleItem('I6CJ')
    call ProfessionsFishing_RegisterPoleItemWithBonus(itemCode, skillBonus)
    call ProfessionsFishing_RegisterBaitItem(itemCode, skillBonus, duration, displayName)
    call ProfessionsFishing_RegisterBaitItemEx(itemCode, skillBonus, duration, displayName, requiredFishingSkill)
    set ProfessionsFishing_BobberModelPath = "war3mapImported\\FishingBobber.mdx"
    set ProfessionsFishing_BobberCinematicAnimationTypeId = 11
    set ProfessionsFishing_BobberCinematicSubAnimationAId = 0
    set ProfessionsFishing_BobberCinematicSubAnimationBId = 44
    set ProfessionsFishing_BobberStandAnimationTypeId = 4
    set ProfessionsFishing_BobberStandSubAnimationAId = 44
    set ProfessionsFishing_BobberStandSubAnimationBId = -1
    set ProfessionsFishing_FishingLineLightningType = "LEAS"
    set ProfessionsFishing_FishingLineUseCustomColor = true
    set ProfessionsFishing_LineHandAttachmentPoint = "hand,right"
    set ProfessionsFishing_LineHandForwardOffset = 0.00
    set ProfessionsFishing_LineHandRightOffset = 0.00
    set ProfessionsFishing_LineHandHeight = 0.00
    set ProfessionsFishing_LineHandZOffset = 0.00
    set started = ProfessionsFishing_Start(whichPlayer, fisher, pool)
    set stopped = ProfessionsFishing_StopForUnit(fisher)
    call ProfessionsFishing_Init()

**/

library ProfessionsFishing initializer AutoInit requires Professions, GatherNodeSkills, ZonesCore, GatherNodes, GatherNodeUnits, Table, Interface, optional GatherNodeDefinitions, optional SharedDInvLib

globals
    private constant integer PF_MAX_POLE_ITEMS = 16
    private constant integer PF_MAX_BAIT_TYPES = 16
    private constant integer PF_ITEM_JINZUN_FISHING_POLE = 'I6CJ'
    private constant integer PF_ITEM_BASIC_FISHING_POLE = 'I6CQ'
    private constant integer PF_ITEM_STRONG_FISHING_POLE = 'I6CR'
    private constant integer PF_ITEM_BIG_IRON_FISHING_POLE = 'I6CS'
    private constant integer PF_ITEM_PROMASTER_FISHING_POLE = 'I6CT'
    private constant integer PF_ITEM_SHINY_BAUBLE = 'I6CM'
    private constant integer PF_ITEM_NIGHTCRAWLERS = 'I6CN'
    private constant integer PF_ITEM_BRIGHT_BAUBLES = 'I6CO'
    private constant integer PF_ITEM_AQUADYNAMIC_FISH = 'I6CP'
    private constant integer PF_UNIT_DEFAULT_FISH_POOL = 'n02N'
    private constant integer PF_CATEGORY_FISH_POOLS = 9
    private constant integer PF_DEFAULT_FISH_POOL_ZONE = 0
    private constant integer PF_FISHING_POLE_EQUIPMENT_SLOT = 19

    private constant real PF_START_RANGE = 750.00
    private constant real PF_READY_RANGE = 650.00
    private constant real PF_CANCEL_RANGE = 850.00
    private constant real PF_APPROACH_OFFSET = 625.00
    private constant real PF_MOVE_TIMEOUT = 10.00
    private constant real PF_CAST_DURATION = 10.00
    private constant real PF_TICK_INTERVAL = 0.05
    private constant real PF_REEL_WINDOW_DURATION = 1.15
    private constant real PF_REEL_WINDOW_MIN_START = 2.00
    private constant real PF_DEFAULT_BAIT_DURATION = 600.00
    private constant real PF_ANIMATION_LOOP_PERIOD = 1.35
    private constant real PF_SOUND_CUTOFF = 1500.00
    private constant real PF_BOBBER_POOL_RANDOM_RADIUS = 100.00
    private constant real PF_BOBBER_HEIGHT_OFFSET = 8.00
    private constant real PF_BOBBER_SCALE = 1.00
    private constant real PF_BOBBER_STAND_DELAY = 0.35
    private constant real PF_BOBBER_END_DESTROY_DELAY = 0.45
    private constant real PF_LINE_WOBBLE_DURATION = 0.55
    private constant real PF_LINE_WOBBLE_STRENGTH = 18.00
    private constant real PF_LINE_WOBBLE_END_STRENGTH = 26.00
    private constant real PF_LINE_WOBBLE_SPEED = 37.00
    private constant real PF_LINE_COLOR_RED = 1.00
    private constant real PF_LINE_COLOR_GREEN = 1.00
    private constant real PF_LINE_COLOR_BLUE = 1.00
    private constant real PF_LINE_COLOR_ALPHA = 0.36
    private constant string PF_DEFAULT_LINE_LIGHTNING_TYPE = "LEAS"
    private constant string PF_DEFAULT_LINE_HAND_ATTACHMENT_POINT = "hand,right"
    private constant string PF_LINE_HAND_MARKER_MODEL = "Abilities\\Weapons\\WispMissile\\WispMissile.mdl"

    private constant integer PF_MISSING_SKILL_MIN_FAIL_CHANCE = 5
    private constant integer PF_MISSING_SKILL_FAIL_PER_LEVEL = 4
    private constant integer PF_MISSING_SKILL_MAX_FAIL_CHANCE = 90

    private constant boolean PF_AI_CHEAT_CRAFTING = true
    private constant string PF_CRAFTER_ANIMATION_PRIMARY = "stand work"
    private constant string PF_CRAFTER_ANIMATION_FALLBACK = "spell"
    private constant string PF_SOUND_START = "Tradeskill_FishingStart"
    private constant string PF_SOUND_LOOP = ""
    private constant string PF_SOUND_FINISH = "Tradeskill_FishingEnd"
    private constant string PF_SOUND_FAIL = "Tradeskill_Fishing"
    private constant string PF_DEFAULT_FISH_POOL_NAME = "Fish"

    public string TitleText = "|cffffe4a3Fishing|r"
    public string ReelButtonText = "Reel"
    public string BaitButtonText = "Bait"
    public string CancelButtonText = "Cancel"
    public string PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    public string ProgressBarTexture = "UI\\Widgets\\Console\\Human\\human-tooltip-background.blp"
    public string BobberModelPath = "world_goober_g_fishingbobber.mdx"
    public integer BobberCinematicAnimationTypeId = 11
    public integer BobberCinematicSubAnimationAId = 0
    public integer BobberCinematicSubAnimationBId = 44
    public integer BobberStandAnimationTypeId = 4
    public integer BobberStandSubAnimationAId = 44
    public integer BobberStandSubAnimationBId = -1
    public string FishingLineLightningType = "LEAS"
    public string LineHandAttachmentPoint = "hand,right"
    public real LineHandForwardOffset = 0.00
    public real LineHandRightOffset = 0.00
    public real LineHandHeight = 0.00
    public real LineHandZOffset = 0.00
    public boolean FishingLineUseCustomColor = true
    public string FishWentAwayText = "Fish went away"
    public string NoTrackedFisherText = "No tracked fisher"
    public string NeedFishingPoleText = "Requires a fishing pole."
    public string NotFishingPoolText = "Select a fish pool."
    public string TooFarText = "Move closer to the fish pool."
    public string PoolBusyText = "Fish pool is already being fished."
    public string UnitBusyText = "Fisher is already busy."
    public string MovingText = "Moving to fish pool..."
    public string FishingText = "Fishing..."
    public string BiteText = "|cff80ff80Bite! Reel now.|r"
    public string WaitForBiteText = "|cffbfbfbfWait for a bite.|r"
    public string FishingInterruptedText = "Fishing interrupted."
    public string NothingCaughtText = "You caught nothing."
    public string CaughtSomethingText = "You caught something."
    public string NoBaitText = "No bait available."
    public string NoBaitConfiguredText = "No bait configured."
    public string NoActiveBaitText = "No bait active"

    private boolean PF_Initialized = false
    private integer PF_ActiveJobCount = 0

    private integer PF_PoleItemCount = 0
    private integer array PF_PoleItemType
    private integer array PF_PoleBonus

    private integer PF_BaitTypeCount = 0
    private integer array PF_BaitItemType
    private integer array PF_BaitBonus
    private integer array PF_BaitRequiredSkill
    private real array PF_BaitDuration
    private string array PF_BaitName

    private boolean array PF_JobActive
    private boolean array PF_JobStarted
    private boolean array PF_JobMoving
    private unit array PF_Fisher
    private unit array PF_Pool
    private real array PF_Elapsed
    private real array PF_MoveElapsed
    private real array PF_WindowStart
    private real array PF_WindowEnd
    private real array PF_AnimationElapsed
    private real array PF_LineEndBaseX
    private real array PF_LineEndBaseY
    private real array PF_LineEndBaseZ
    private real array PF_LineEndX
    private real array PF_LineEndY
    private real array PF_LineEndZ
    private real array PF_LineWobbleElapsed
    private real array PF_LineWobbleDuration
    private real array PF_LineWobbleStrength
    private real array PF_LineWobblePhase
    private real array PF_BobberStandDelay
    private boolean array PF_BiteSoundPlayed
    private lightning array PF_FishingLine
    private effect array PF_LineHandMarker
    private effect array PF_BobberEffect

    private Table PF_UnitJob = 0
    private Table PF_PoolJob = 0
    private Table PF_BaitBonusByUnit = 0
    private Table PF_BaitExpiresByUnit = 0
    private Table PF_BaitNameByUnit = 0
    private Table PF_BobberDestroyTimerEffect = 0

    private timer PF_ClockTimer = null
    private timer PF_TickTimer = null
    private location PF_TerrainSample = null
    private trigger PF_SelectTrigger = null
    private trigger PF_ReelTrigger = null
    private trigger PF_BaitTrigger = null
    private trigger PF_CancelTrigger = null
    private trigger PF_ClearFocusTrigger = null
    private trigger PF_AttackedTrigger = null

    private framehandle PF_UIParent = null
    private framehandle PF_UITitle = null
    private framehandle PF_UIPoolText = null
    private framehandle PF_UISkillText = null
    private framehandle PF_UIBaitText = null
    private framehandle PF_UIStatusText = null
    private framehandle PF_UIBarBackdrop = null
    private framehandle PF_UIBar = null
    private framehandle PF_UIWindow = null
    private framehandle PF_UIBarLabel = null
    private framehandle PF_UIReelButton = null
    private framehandle PF_UIBaitButton = null
    private framehandle PF_UICancelButton = null
endglobals

private function PF_NoOp takes nothing returns nothing
endfunction

private function PF_GetNow takes nothing returns real
    if PF_ClockTimer == null then
        return 0.00
    endif
    return TimerGetElapsed(PF_ClockTimer)
endfunction

private function PF_IsUnitAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
endfunction

private function PF_RegisterExistingDefaultFishPools takes integer defId returns nothing
    local group scanGroup = CreateGroup()
    local unit scannedUnit = null
    local integer zoneId

    if defId < 0 then
        call DestroyGroup(scanGroup)
        set scanGroup = null
        return
    endif

    call GroupEnumUnitsInRect(scanGroup, bj_mapInitialPlayableArea, null)
    loop
        set scannedUnit = FirstOfGroup(scanGroup)
        exitwhen scannedUnit == null
        call GroupRemoveUnit(scanGroup, scannedUnit)
        if GetUnitTypeId(scannedUnit) == PF_UNIT_DEFAULT_FISH_POOL and PF_IsUnitAlive(scannedUnit) then
            set zoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(scannedUnit), GetUnitY(scannedUnit))
            if zoneId <= 0 then
                set zoneId = PF_DEFAULT_FISH_POOL_ZONE
            endif
            call GNU_RegisterExistingUnitNode(scannedUnit, defId, zoneId)
        endif
    endloop

    call DestroyGroup(scanGroup)
    set scannedUnit = null
    set scanGroup = null
endfunction

private function PF_RegisterDefaultFishPoolUnit takes nothing returns nothing
    local integer defId = GNU_GetDefinitionIdByUnitCode(PF_UNIT_DEFAULT_FISH_POOL)

    if defId < 0 then
        set defId = GNU_RegisterDefinition(PF_UNIT_DEFAULT_FISH_POOL, PF_DEFAULT_FISH_POOL_NAME, PF_CATEGORY_FISH_POOLS, 100, 180.00, 400.00, 5, 0, GNS_PROF_FISHING, 1, 1, 100, 100, 0, 0, 0, 23, false, false, 40, 150, 255, 200, 1.20, 0.00, false)
    endif

    call PF_RegisterExistingDefaultFishPools(defId)
endfunction

private function PF_GetPoolName takes unit pool returns string
    if pool == null then
        return NotFishingPoolText
    endif
    return GN_GetGatherUnitName(pool)
endfunction

private function PF_GetDistanceSq takes unit a, unit b returns real
    local real dx
    local real dy

    if a == null or b == null then
        return 999999999.00
    endif

    set dx = GetUnitX(a) - GetUnitX(b)
    set dy = GetUnitY(a) - GetUnitY(b)
    return dx * dx + dy * dy
endfunction

private function PF_IsNearPool takes unit fisher, unit pool, real range returns boolean
    return PF_GetDistanceSq(fisher, pool) <= range * range
endfunction

private function PF_FacePool takes unit fisher, unit pool returns nothing
    local real dx
    local real dy

    if fisher == null or pool == null then
        return
    endif

    set dx = GetUnitX(pool) - GetUnitX(fisher)
    set dy = GetUnitY(pool) - GetUnitY(fisher)
    call SetUnitFacing(fisher, Atan2(dy, dx) * bj_RADTODEG)
endfunction

private function PF_GetApproachPointX takes unit fisher, unit pool returns real
    local real angle
    local real dx
    local real dy

    if fisher == null or pool == null then
        return 0.00
    endif

    set dx = GetUnitX(fisher) - GetUnitX(pool)
    set dy = GetUnitY(fisher) - GetUnitY(pool)
    if dx * dx + dy * dy < 1.00 then
        set angle = GetUnitFacing(pool) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif

    return GetUnitX(pool) + PF_APPROACH_OFFSET * Cos(angle)
endfunction

private function PF_GetApproachPointY takes unit fisher, unit pool returns real
    local real angle
    local real dx
    local real dy

    if fisher == null or pool == null then
        return 0.00
    endif

    set dx = GetUnitX(fisher) - GetUnitX(pool)
    set dy = GetUnitY(fisher) - GetUnitY(pool)
    if dx * dx + dy * dy < 1.00 then
        set angle = GetUnitFacing(pool) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif

    return GetUnitY(pool) + PF_APPROACH_OFFSET * Sin(angle)
endfunction

private function PF_IsFishingPool takes unit pool returns boolean
    return pool != null and GN_IsGatherUnit(pool) and GN_GetGatherUnitProfessionId(pool) == GNS_PROF_FISHING
endfunction

private function PF_IsTrackedFisherCandidate takes player whichPlayer, unit whichUnit returns boolean
    if whichPlayer == null or not PF_IsUnitAlive(whichUnit) then
        return false
    endif
    return GetOwningPlayer(whichUnit) == whichPlayer and IsUnitType(whichUnit, UNIT_TYPE_HERO) and GNS_IsTrackedGatherer(whichUnit)
endfunction

private function PF_GetCloserFisher takes player whichPlayer, unit pool, unit current, unit candidate returns unit
    if pool == null or not PF_IsTrackedFisherCandidate(whichPlayer, candidate) then
        return current
    endif
    if current == null or PF_GetDistanceSq(candidate, pool) < PF_GetDistanceSq(current, pool) then
        return candidate
    endif
    return current
endfunction

private function PF_GetNearestTrackedFisher takes player whichPlayer, unit pool returns unit
    local unit best = null

    set best = PF_GetCloserFisher(whichPlayer, pool, best, udg_Nazgrek)
    set best = PF_GetCloserFisher(whichPlayer, pool, best, udg_Zulkis)
    set best = PF_GetCloserFisher(whichPlayer, pool, best, GNS_GetUITargetUnit())

    return best
endfunction

private function PF_CountAvailableItem takes unit fisher, integer itemCode returns integer
    return Professions_CountItem(fisher, itemCode)
endfunction

private function PF_ConsumeAvailableItem takes unit fisher, integer itemCode, integer amount returns nothing
    call Professions_ConsumeItem(fisher, itemCode, amount)
endfunction

private function PF_IsRegisteredPoleItem takes integer itemCode returns boolean
    local integer index = 1

    loop
        exitwhen index > PF_PoleItemCount
        if PF_PoleItemType[index] == itemCode then
            return true
        endif
        set index = index + 1
    endloop

    return false
endfunction

private function PF_GetRegisteredPoleBonus takes integer itemCode returns integer
    local integer index = 1

    loop
        exitwhen index > PF_PoleItemCount
        if PF_PoleItemType[index] == itemCode then
            return PF_PoleBonus[index]
        endif
        set index = index + 1
    endloop

    return 0
endfunction

private function PF_CountEquippedItem takes unit fisher, integer itemCode returns integer
    local integer count = 0
    local integer eqId = 0
    local integer slot = 1
    local integer charges
    local item equippedItem = null

    if fisher == null or itemCode == 0 then
        return 0
    endif

    static if LIBRARY_SharedDInvLib then
        set eqId = EQIDOfUnit(fisher)
        if eqId > 0 then
            loop
                exitwhen slot > HighestSlotNumber
                set equippedItem = EQIDDB[eqId][4].item[slot]
                if equippedItem != null and GetItemTypeId(equippedItem) == itemCode then
                    set charges = GetItemCharges(equippedItem)
                    if charges <= 0 then
                        set count = count + 1
                    else
                        set count = count + charges
                    endif
                endif
                set slot = slot + 1
            endloop
        endif
    endif

    set equippedItem = null
    return count
endfunction

private function PF_RegisterPoleInternal takes integer itemCode, integer skillBonus returns boolean
    local integer index = 1

    if itemCode == 0 then
        return false
    endif

    loop
        exitwhen index > PF_PoleItemCount
        if PF_PoleItemType[index] == itemCode then
            set PF_PoleBonus[index] = skillBonus
            return true
        endif
        set index = index + 1
    endloop

    if PF_PoleItemCount >= PF_MAX_POLE_ITEMS then
        return false
    endif

    set PF_PoleItemCount = PF_PoleItemCount + 1
    set PF_PoleItemType[PF_PoleItemCount] = itemCode
    set PF_PoleBonus[PF_PoleItemCount] = skillBonus
    return true
endfunction

public function RegisterPoleItem takes integer itemCode returns boolean
    return PF_RegisterPoleInternal(itemCode, 0)
endfunction

public function RegisterPoleItemWithBonus takes integer itemCode, integer skillBonus returns boolean
    return PF_RegisterPoleInternal(itemCode, skillBonus)
endfunction

public function RegisterBaitItemEx takes integer itemCode, integer skillBonus, real duration, string displayName, integer requiredFishingSkill returns boolean
    local integer index = 1

    if itemCode == 0 or skillBonus <= 0 then
        return false
    endif

    if requiredFishingSkill < 0 then
        set requiredFishingSkill = 0
    endif

    loop
        exitwhen index > PF_BaitTypeCount
        if PF_BaitItemType[index] == itemCode then
            set PF_BaitBonus[index] = skillBonus
            set PF_BaitRequiredSkill[index] = requiredFishingSkill
            set PF_BaitDuration[index] = duration
            set PF_BaitName[index] = displayName
            return true
        endif
        set index = index + 1
    endloop

    if PF_BaitTypeCount >= PF_MAX_BAIT_TYPES then
        return false
    endif

    set PF_BaitTypeCount = PF_BaitTypeCount + 1
    set PF_BaitItemType[PF_BaitTypeCount] = itemCode
    set PF_BaitBonus[PF_BaitTypeCount] = skillBonus
    set PF_BaitRequiredSkill[PF_BaitTypeCount] = requiredFishingSkill
    set PF_BaitDuration[PF_BaitTypeCount] = duration
    set PF_BaitName[PF_BaitTypeCount] = displayName
    return true
endfunction

public function RegisterBaitItem takes integer itemCode, integer skillBonus, real duration, string displayName returns boolean
    return RegisterBaitItemEx(itemCode, skillBonus, duration, displayName, 0)
endfunction

private function PF_HasEquippedFishingPole takes unit fisher returns boolean
    local integer index = 1

    loop
        exitwhen index > PF_PoleItemCount
        if PF_CountEquippedItem(fisher, PF_PoleItemType[index]) > 0 then
            return true
        endif
        set index = index + 1
    endloop

    return false
endfunction

private function PF_GetEquippedPoleBonus takes unit fisher returns integer
    local integer index = 1
    local integer bestBonus = 0

    loop
        exitwhen index > PF_PoleItemCount
        if PF_CountEquippedItem(fisher, PF_PoleItemType[index]) > 0 and PF_PoleBonus[index] > bestBonus then
            set bestBonus = PF_PoleBonus[index]
        endif
        set index = index + 1
    endloop

    return bestBonus
endfunction

private function PF_HasVanillaFishingPole takes unit fisher returns boolean
    local integer slot = 0
    local item whichItem = null

    if fisher == null then
        return false
    endif

    loop
        exitwhen slot >= UnitInventorySize(fisher)
        set whichItem = UnitItemInSlot(fisher, slot)
        if whichItem != null then
            static if LIBRARY_SharedDInvLib then
                if not IsItemStoredInDInv(whichItem) and PF_IsRegisteredPoleItem(GetItemTypeId(whichItem)) then
                    set whichItem = null
                    return true
                endif
            else
                if PF_IsRegisteredPoleItem(GetItemTypeId(whichItem)) then
                    set whichItem = null
                    return true
                endif
            endif
        endif
        set slot = slot + 1
    endloop

    set whichItem = null
    return false
endfunction

private function PF_GetBestVanillaPoleBonus takes unit fisher returns integer
    local integer slot = 0
    local integer bestBonus = 0
    local integer itemBonus
    local item whichItem = null

    if fisher == null then
        return 0
    endif

    loop
        exitwhen slot >= UnitInventorySize(fisher)
        set whichItem = UnitItemInSlot(fisher, slot)
        if whichItem != null then
            static if LIBRARY_SharedDInvLib then
                if not IsItemStoredInDInv(whichItem) and PF_IsRegisteredPoleItem(GetItemTypeId(whichItem)) then
                    set itemBonus = PF_GetRegisteredPoleBonus(GetItemTypeId(whichItem))
                    if itemBonus > bestBonus then
                        set bestBonus = itemBonus
                    endif
                endif
            else
                if PF_IsRegisteredPoleItem(GetItemTypeId(whichItem)) then
                    set itemBonus = PF_GetRegisteredPoleBonus(GetItemTypeId(whichItem))
                    if itemBonus > bestBonus then
                        set bestBonus = itemBonus
                    endif
                endif
            endif
        endif
        set slot = slot + 1
    endloop

    set whichItem = null
    return bestBonus
endfunction

private function PF_GetDInventoryPoleSlot takes unit fisher returns integer
    local integer bid = -1
    local integer maxCapacity = 0
    local integer slot = 0
    local integer bestSlot = -1
    local integer bestBonus = 0
    local integer itemBonus
    local item whichItem = null

    if fisher == null then
        return -1
    endif

    static if LIBRARY_SharedDInvLib then
        set bid = BIDOfUnit(fisher)
        if bid != -1 then
            set maxCapacity = MaxDInvCapacityOfUnit(fisher)
            loop
                exitwhen slot >= maxCapacity
                set whichItem = DInventoryDB[bid].item[slot]
                if whichItem != null and PF_IsRegisteredPoleItem(GetItemTypeId(whichItem)) then
                    set itemBonus = PF_GetRegisteredPoleBonus(GetItemTypeId(whichItem))
                    if bestSlot < 0 or itemBonus > bestBonus then
                        set bestSlot = slot
                        set bestBonus = itemBonus
                    endif
                endif
                set slot = slot + 1
            endloop
        endif
    endif

    set whichItem = null
    return bestSlot
endfunction

private function PF_TryEquipFishingPole takes unit fisher returns boolean
    local integer pid = 0
    local integer bid = -1
    local integer eqId = 0
    local integer poleSlot = -1
    local integer freeSlot = -1
    local item poleItem = null
    local item currentItem = null

    if fisher == null then
        return false
    endif

    static if LIBRARY_SharedDInvLib then
        set bid = BIDOfUnit(fisher)
        set eqId = EQIDOfUnit(fisher)
        set poleSlot = PF_GetDInventoryPoleSlot(fisher)
        if bid != -1 and eqId > 0 then
            set currentItem = EQIDDB[eqId][4].item[PF_FISHING_POLE_EQUIPMENT_SLOT]
            if poleSlot >= 0 then
                set poleItem = DInventoryDB[bid].item[poleSlot]
            endif

            if currentItem != null and PF_IsRegisteredPoleItem(GetItemTypeId(currentItem)) then
                if poleItem == null or PF_GetRegisteredPoleBonus(GetItemTypeId(currentItem)) >= PF_GetRegisteredPoleBonus(GetItemTypeId(poleItem)) then
                    set poleItem = null
                    set currentItem = null
                    return true
                endif
            endif

            if poleItem != null and DEqCanUnitEquipItemInSlot(fisher, poleItem, PF_FISHING_POLE_EQUIPMENT_SLOT) then
                set pid = GetPlayerId(GetOwningPlayer(fisher))
                if currentItem != null then
                    set freeSlot = FirstFreeDInvSlotOfBID(pid, bid)
                    if freeSlot == -1 then
                        if PF_IsRegisteredPoleItem(GetItemTypeId(currentItem)) then
                            set poleItem = null
                            set currentItem = null
                            return true
                        endif
                        set poleItem = null
                        set currentItem = null
                        return false
                    endif
                    if not UnequipDEqItemToDInvSlot(pid, bid, eqId, fisher, GetHandleId(fisher), currentItem, freeSlot, PF_FISHING_POLE_EQUIPMENT_SLOT) then
                        set poleItem = null
                        set currentItem = null
                        return false
                    endif
                endif

                set currentItem = null
                if EquipDInvItemToDEqSlot(pid, bid, eqId, fisher, GetHandleId(fisher), poleItem, poleSlot, PF_FISHING_POLE_EQUIPMENT_SLOT) then
                    set poleItem = null
                    return true
                endif
            endif
        endif
    endif

    if PF_HasEquippedFishingPole(fisher) then
        return true
    endif

    set poleItem = null
    set currentItem = null
    return PF_HasVanillaFishingPole(fisher)
endfunction

private function PF_ClearExpiredBait takes unit fisher returns nothing
    local integer handleId

    if fisher == null then
        return
    endif

    set handleId = GetHandleId(fisher)
    if PF_BaitExpiresByUnit.real.has(handleId) and PF_BaitExpiresByUnit.real[handleId] <= PF_GetNow() then
        call PF_BaitExpiresByUnit.real.remove(handleId)
        call PF_BaitBonusByUnit.remove(handleId)
        call PF_BaitNameByUnit.string.remove(handleId)
    endif
endfunction

private function PF_GetActiveBaitBonus takes unit fisher returns integer
    local integer handleId

    if fisher == null then
        return 0
    endif

    call PF_ClearExpiredBait(fisher)
    set handleId = GetHandleId(fisher)
    if PF_BaitBonusByUnit.has(handleId) then
        return PF_BaitBonusByUnit.integer[handleId]
    endif

    return 0
endfunction

private function PF_GetActiveBaitName takes unit fisher returns string
    local integer handleId

    if fisher == null then
        return NoActiveBaitText
    endif

    call PF_ClearExpiredBait(fisher)
    set handleId = GetHandleId(fisher)
    if PF_BaitNameByUnit.string.has(handleId) then
        return PF_BaitNameByUnit.string[handleId]
    endif

    return NoActiveBaitText
endfunction

private function PF_GetBaitNameByIndex takes integer baitIndex returns string
    if baitIndex <= 0 or baitIndex > PF_BaitTypeCount then
        return ""
    endif

    if PF_BaitName[baitIndex] == null or PF_BaitName[baitIndex] == "" then
        return GetObjectName(PF_BaitItemType[baitIndex])
    endif

    return PF_BaitName[baitIndex]
endfunction

private function PF_GetBaitRemaining takes unit fisher returns integer
    local integer handleId
    local real remaining

    if fisher == null then
        return 0
    endif

    call PF_ClearExpiredBait(fisher)
    set handleId = GetHandleId(fisher)
    if not PF_BaitExpiresByUnit.real.has(handleId) then
        return 0
    endif

    set remaining = PF_BaitExpiresByUnit.real[handleId] - PF_GetNow()
    if remaining <= 0.00 then
        return 0
    endif

    return R2I(remaining + 0.99)
endfunction

private function PF_GetFishingSkillBeforeBait takes unit fisher returns integer
    local integer skill

    if fisher == null then
        return 0
    endif

    set skill = Professions_GetEffectiveSkill(fisher, GNS_PROF_FISHING)
    if Professions_GetProfessionItemBonus(fisher, GNS_PROF_FISHING) <= 0 then
        set skill = skill + PF_GetEquippedPoleBonus(fisher)
    endif

    return skill + PF_GetBestVanillaPoleBonus(fisher)
endfunction

private function PF_GetEffectiveFishingSkill takes unit fisher returns integer
    return PF_GetFishingSkillBeforeBait(fisher) + PF_GetActiveBaitBonus(fisher)
endfunction

private function PF_FindBestAvailableBait takes unit fisher returns integer
    local integer index = 1
    local integer bestIndex = 0
    local integer bestBonus = 0
    local integer skill = PF_GetFishingSkillBeforeBait(fisher)

    loop
        exitwhen index > PF_BaitTypeCount
        if PF_CountAvailableItem(fisher, PF_BaitItemType[index]) > 0 and skill >= PF_BaitRequiredSkill[index] then
            if bestIndex <= 0 or PF_BaitBonus[index] > bestBonus then
                set bestIndex = index
                set bestBonus = PF_BaitBonus[index]
            endif
        endif
        set index = index + 1
    endloop

    return bestIndex
endfunction

private function PF_GetUnavailableBaitRequirement takes unit fisher returns integer
    local integer index = 1
    local integer skill = PF_GetFishingSkillBeforeBait(fisher)
    local integer requiredSkill = 100000

    loop
        exitwhen index > PF_BaitTypeCount
        if PF_CountAvailableItem(fisher, PF_BaitItemType[index]) > 0 and skill < PF_BaitRequiredSkill[index] and PF_BaitRequiredSkill[index] < requiredSkill then
            set requiredSkill = PF_BaitRequiredSkill[index]
        endif
        set index = index + 1
    endloop

    if requiredSkill == 100000 then
        return 0
    endif

    return requiredSkill
endfunction

private function PF_GetBaitDisplayText takes unit fisher returns string
    local integer remaining = PF_GetBaitRemaining(fisher)
    local integer baitIndex
    local integer requiredSkill

    if remaining > 0 then
        return "Bait: " + PF_GetActiveBaitName(fisher) + " +" + I2S(PF_GetActiveBaitBonus(fisher)) + " (" + I2S(remaining) + "s)"
    endif

    if PF_BaitTypeCount <= 0 then
        return "Bait: " + NoBaitConfiguredText
    endif

    set baitIndex = PF_FindBestAvailableBait(fisher)
    if baitIndex > 0 then
        return "Bait: " + PF_GetBaitNameByIndex(baitIndex) + " available"
    endif

    set requiredSkill = PF_GetUnavailableBaitRequirement(fisher)
    if requiredSkill > 0 then
        return "Bait: Requires Fishing " + I2S(requiredSkill)
    endif

    return "Bait: " + NoBaitText
endfunction

private function PF_GetSkillFailChance takes integer effectiveSkill, integer requiredSkill returns integer
    local integer chance

    if effectiveSkill >= requiredSkill then
        return 0
    endif

    set chance = PF_MISSING_SKILL_MIN_FAIL_CHANCE + (requiredSkill - effectiveSkill) * PF_MISSING_SKILL_FAIL_PER_LEVEL
    if chance > PF_MISSING_SKILL_MAX_FAIL_CHANCE then
        set chance = PF_MISSING_SKILL_MAX_FAIL_CHANCE
    endif

    return chance
endfunction

private function PF_PlayFishingProfessionSound takes unit fisher, sound whichSound, string soundLabel, string soundPath returns nothing
    local sound fishingSound = null

    call Interface_RefreshDefaultSounds()
    set fishingSound = Interface_PlayProfessionSoundOnUnit(whichSound, soundLabel, fisher, false, PF_SOUND_CUTOFF)

    if fishingSound == null and soundPath != null and soundPath != "" then
        set fishingSound = Interface_PlayProfessionSoundPathOnUnit(soundPath, fisher, false, PF_SOUND_CUTOFF)
    endif

    set fishingSound = null
endfunction

private function PF_PlayFishingStartSound takes unit fisher returns nothing
    call PF_PlayFishingProfessionSound(fisher, Interface_Profession_Fishing_Start, PF_SOUND_START, Interface_Profession_Fishing_StartPath)
endfunction

private function PF_PlayFishingEndSound takes unit fisher returns nothing
    call PF_PlayFishingProfessionSound(fisher, Interface_Profession_Fishing_End, PF_SOUND_FINISH, Interface_Profession_Fishing_EndPath)
endfunction

private function PF_PlayFishingFailSound takes unit fisher returns nothing
    call PF_PlayFishingProfessionSound(fisher, Interface_Profession_Fishing_Fail, PF_SOUND_FAIL, Interface_Profession_Fishing_FailPath)
endfunction

private function PF_PlayFishingBiteSoundIfNeeded takes integer pid, unit fisher returns nothing
    if not PF_BiteSoundPlayed[pid] then
        set PF_BiteSoundPlayed[pid] = true
        call PF_PlayFishingEndSound(fisher)
    endif
endfunction

private function PF_PlayFishingAnimation takes integer pid returns nothing
    local unit fisher = PF_Fisher[pid]

    if fisher == null then
        return
    endif

    call PF_FacePool(fisher, PF_Pool[pid])
    if PF_CRAFTER_ANIMATION_PRIMARY != null and PF_CRAFTER_ANIMATION_PRIMARY != "" then
        call SetUnitAnimation(fisher, PF_CRAFTER_ANIMATION_PRIMARY)
        if PF_CRAFTER_ANIMATION_FALLBACK != null and PF_CRAFTER_ANIMATION_FALLBACK != "" then
            call QueueUnitAnimation(fisher, PF_CRAFTER_ANIMATION_FALLBACK)
        endif
    elseif PF_CRAFTER_ANIMATION_FALLBACK != null and PF_CRAFTER_ANIMATION_FALLBACK != "" then
        call SetUnitAnimation(fisher, PF_CRAFTER_ANIMATION_FALLBACK)
    else
        call SetUnitAnimation(fisher, "stand")
    endif

    set fisher = null
endfunction

private function PF_ResetFisherAnimation takes unit fisher returns nothing
    if fisher != null then
        call SetUnitAnimation(fisher, "stand")
    endif
endfunction

private function PF_GetTerrainZ takes real x, real y returns real
    if PF_TerrainSample == null then
        return 0.00
    endif

    call MoveLocation(PF_TerrainSample, x, y)
    return GetLocationZ(PF_TerrainSample)
endfunction

private function PF_GetFallbackLineStartX takes unit fisher returns real
    local real facing

    if fisher == null then
        return 0.00
    endif

    set facing = GetUnitFacing(fisher) * bj_DEGTORAD
    return GetUnitX(fisher) + LineHandForwardOffset * Cos(facing) + LineHandRightOffset * Cos(facing - bj_PI * 0.50)
endfunction

private function PF_GetFallbackLineStartY takes unit fisher returns real
    local real facing

    if fisher == null then
        return 0.00
    endif

    set facing = GetUnitFacing(fisher) * bj_DEGTORAD
    return GetUnitY(fisher) + LineHandForwardOffset * Sin(facing) + LineHandRightOffset * Sin(facing - bj_PI * 0.50)
endfunction

private function PF_GetFallbackLineStartZ takes unit fisher, real x, real y returns real
    if fisher == null then
        return PF_GetTerrainZ(x, y) + LineHandHeight
    endif

    return PF_GetTerrainZ(x, y) + GetUnitFlyHeight(fisher) + LineHandHeight
endfunction

private function PF_GetFishingLineLightningType takes nothing returns string
    if FishingLineLightningType != null and FishingLineLightningType != "" then
        return FishingLineLightningType
    endif

    return PF_DEFAULT_LINE_LIGHTNING_TYPE
endfunction

private function PF_GetLineHandAttachmentPoint takes nothing returns string
    if LineHandAttachmentPoint != null and LineHandAttachmentPoint != "" then
        return LineHandAttachmentPoint
    endif

    return PF_DEFAULT_LINE_HAND_ATTACHMENT_POINT
endfunction

private function PF_DestroyLineHandMarker takes integer pid returns nothing
    if PF_LineHandMarker[pid] != null then
        call DestroyEffect(PF_LineHandMarker[pid])
        set PF_LineHandMarker[pid] = null
    endif
endfunction

private function PF_CreateLineHandMarker takes integer pid, unit fisher returns nothing
    call PF_DestroyLineHandMarker(pid)

    if fisher != null then
        set PF_LineHandMarker[pid] = AddSpecialEffectTarget(PF_LINE_HAND_MARKER_MODEL, fisher, PF_GetLineHandAttachmentPoint())
        if PF_LineHandMarker[pid] != null then
            call BlzSetSpecialEffectAlpha(PF_LineHandMarker[pid], 0)
            call BlzSetSpecialEffectScale(PF_LineHandMarker[pid], 0.01)
        endif
    endif
endfunction

private function PF_LineHandMarkerIsUsable takes integer pid, unit fisher returns boolean
    local real markerX
    local real markerY
    local real dx
    local real dy

    if fisher == null or PF_LineHandMarker[pid] == null then
        return false
    endif

    set markerX = BlzGetLocalSpecialEffectX(PF_LineHandMarker[pid])
    set markerY = BlzGetLocalSpecialEffectY(PF_LineHandMarker[pid])
    if markerX * markerX + markerY * markerY <= 16.00 then
        return false
    endif

    set dx = markerX - GetUnitX(fisher)
    set dy = markerY - GetUnitY(fisher)
    return dx * dx + dy * dy > 4.00
endfunction

private function PF_GetLineStartX takes integer pid, unit fisher returns real
    if PF_LineHandMarkerIsUsable(pid, fisher) then
        return BlzGetLocalSpecialEffectX(PF_LineHandMarker[pid])
    endif

    return PF_GetFallbackLineStartX(fisher)
endfunction

private function PF_GetLineStartY takes integer pid, unit fisher returns real
    if PF_LineHandMarkerIsUsable(pid, fisher) then
        return BlzGetLocalSpecialEffectY(PF_LineHandMarker[pid])
    endif

    return PF_GetFallbackLineStartY(fisher)
endfunction

private function PF_GetLineStartZ takes integer pid, unit fisher, real x, real y returns real
    if PF_LineHandMarkerIsUsable(pid, fisher) then
        return BlzGetLocalSpecialEffectZ(PF_LineHandMarker[pid]) + LineHandZOffset
    endif

    return PF_GetFallbackLineStartZ(fisher, x, y)
endfunction

private function PF_AddBobberSubAnimationId takes effect bobber, integer subAnimId returns nothing
    if bobber != null and subAnimId >= 0 then
        call BlzSpecialEffectAddSubAnimation(bobber, ConvertSubAnimType(subAnimId))
    endif
endfunction

private function PF_PlayBobberAnimationByIds takes integer pid, integer animTypeId, integer subAnimAId, integer subAnimBId returns nothing
    local effect bobber = PF_BobberEffect[pid]

    if bobber != null then
        call BlzSpecialEffectClearSubAnimations(bobber)
        call PF_AddBobberSubAnimationId(bobber, subAnimAId)
        call PF_AddBobberSubAnimationId(bobber, subAnimBId)
        call BlzSetSpecialEffectTimeScale(bobber, 1.00)
        call BlzSetSpecialEffectTime(bobber, 0.00)
        call BlzPlaySpecialEffectWithTimeScale(bobber, ConvertAnimType(animTypeId), 1.00)
        call BlzSetSpecialEffectTime(bobber, 0.00)
    endif

    set bobber = null
endfunction

private function PF_PlayBobberCinematicCustomOne takes integer pid returns nothing
    call PF_PlayBobberAnimationByIds(pid, BobberCinematicAnimationTypeId, BobberCinematicSubAnimationAId, BobberCinematicSubAnimationBId)
endfunction

private function PF_PlayBobberStand takes integer pid returns nothing
    call PF_PlayBobberAnimationByIds(pid, BobberStandAnimationTypeId, BobberStandSubAnimationAId, BobberStandSubAnimationBId)
endfunction

private function PF_BobberDestroyTimerAction takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local effect bobber = null

    if PF_BobberDestroyTimerEffect != 0 and PF_BobberDestroyTimerEffect.effect.has(timerId) then
        set bobber = PF_BobberDestroyTimerEffect.effect[timerId]
        call PF_BobberDestroyTimerEffect.effect.remove(timerId)
    endif

    if bobber != null then
        call DestroyEffect(bobber)
    endif

    call DestroyTimer(expiredTimer)
    set bobber = null
    set expiredTimer = null
endfunction

private function PF_QueueBobberDestroy takes integer pid returns nothing
    local timer destroyTimer
    local integer timerId
    local effect bobber = PF_BobberEffect[pid]

    if bobber == null then
        set bobber = null
        return
    endif

    call PF_PlayBobberCinematicCustomOne(pid)
    set PF_BobberEffect[pid] = null
    set PF_BobberStandDelay[pid] = 0.00

    if PF_BobberDestroyTimerEffect == 0 or PF_BOBBER_END_DESTROY_DELAY <= 0.00 then
        call DestroyEffect(bobber)
        set bobber = null
        return
    endif

    set destroyTimer = CreateTimer()
    set timerId = GetHandleId(destroyTimer)
    set PF_BobberDestroyTimerEffect.effect[timerId] = bobber
    call TimerStart(destroyTimer, PF_BOBBER_END_DESTROY_DELAY, false, function PF_BobberDestroyTimerAction)

    set destroyTimer = null
    set bobber = null
endfunction

private function PF_StartLineWobble takes integer pid, real duration, real strength returns nothing
    if duration <= 0.00 or strength <= 0.00 then
        return
    endif

    set PF_LineWobbleElapsed[pid] = 0.00
    set PF_LineWobbleDuration[pid] = duration
    set PF_LineWobbleStrength[pid] = strength
    set PF_LineWobblePhase[pid] = GetRandomReal(0.00, bj_PI * 2.00)
endfunction

private function PF_UpdateLineWobble takes integer pid returns nothing
    local real scale
    local real phase

    if PF_LineWobbleDuration[pid] <= 0.00 then
        set PF_LineEndX[pid] = PF_LineEndBaseX[pid]
        set PF_LineEndY[pid] = PF_LineEndBaseY[pid]
        set PF_LineEndZ[pid] = PF_LineEndBaseZ[pid]
        return
    endif

    set PF_LineWobbleElapsed[pid] = PF_LineWobbleElapsed[pid] + PF_TICK_INTERVAL
    if PF_LineWobbleElapsed[pid] >= PF_LineWobbleDuration[pid] then
        set PF_LineWobbleElapsed[pid] = 0.00
        set PF_LineWobbleDuration[pid] = 0.00
        set PF_LineWobbleStrength[pid] = 0.00
        set PF_LineEndX[pid] = PF_LineEndBaseX[pid]
        set PF_LineEndY[pid] = PF_LineEndBaseY[pid]
        set PF_LineEndZ[pid] = PF_LineEndBaseZ[pid]
        return
    endif

    set scale = PF_LineWobbleStrength[pid] * (1.00 - PF_LineWobbleElapsed[pid] / PF_LineWobbleDuration[pid])
    set phase = PF_LineWobblePhase[pid] + PF_LineWobbleElapsed[pid] * PF_LINE_WOBBLE_SPEED
    set PF_LineEndX[pid] = PF_LineEndBaseX[pid] + Cos(phase) * scale
    set PF_LineEndY[pid] = PF_LineEndBaseY[pid] + Sin(phase * 1.21) * scale
    set PF_LineEndZ[pid] = PF_LineEndBaseZ[pid] + Sin(phase * 0.77) * scale * 0.35
endfunction

private function PF_UpdateFishingVisuals takes integer pid returns nothing
    local unit fisher = PF_Fisher[pid]
    local real startX
    local real startY
    local real startZ

    if fisher == null then
        set fisher = null
        return
    endif

    call PF_UpdateLineWobble(pid)

    set startX = PF_GetLineStartX(pid, fisher)
    set startY = PF_GetLineStartY(pid, fisher)
    set startZ = PF_GetLineStartZ(pid, fisher, startX, startY)

    if PF_FishingLine[pid] != null then
        call MoveLightningEx(PF_FishingLine[pid], true, startX, startY, startZ, PF_LineEndX[pid], PF_LineEndY[pid], PF_LineEndZ[pid])
    endif

    if PF_BobberEffect[pid] != null then
        call BlzSetSpecialEffectPosition(PF_BobberEffect[pid], PF_LineEndX[pid], PF_LineEndY[pid], PF_LineEndZ[pid])
        if PF_BobberStandDelay[pid] > 0.00 then
            set PF_BobberStandDelay[pid] = PF_BobberStandDelay[pid] - PF_TICK_INTERVAL
            if PF_BobberStandDelay[pid] <= 0.00 then
                call PF_PlayBobberStand(pid)
            endif
        endif
    endif

    set fisher = null
endfunction

private function PF_DestroyFishingVisuals takes integer pid returns nothing
    if PF_FishingLine[pid] != null or PF_BobberEffect[pid] != null then
        call PF_StartLineWobble(pid, 0.15, PF_LINE_WOBBLE_END_STRENGTH)
        call PF_UpdateFishingVisuals(pid)
    endif

    if PF_FishingLine[pid] != null then
        call DestroyLightning(PF_FishingLine[pid])
        set PF_FishingLine[pid] = null
    endif

    if PF_BobberEffect[pid] != null then
        call PF_QueueBobberDestroy(pid)
    endif

    call PF_DestroyLineHandMarker(pid)
    set PF_LineEndBaseX[pid] = 0.00
    set PF_LineEndBaseY[pid] = 0.00
    set PF_LineEndBaseZ[pid] = 0.00
    set PF_LineEndX[pid] = 0.00
    set PF_LineEndY[pid] = 0.00
    set PF_LineEndZ[pid] = 0.00
    set PF_LineWobbleElapsed[pid] = 0.00
    set PF_LineWobbleDuration[pid] = 0.00
    set PF_LineWobbleStrength[pid] = 0.00
    set PF_LineWobblePhase[pid] = 0.00
    set PF_BobberStandDelay[pid] = 0.00
endfunction

private function PF_CreateFishingVisuals takes integer pid returns nothing
    local unit fisher = PF_Fisher[pid]
    local unit pool = PF_Pool[pid]
    local real startX
    local real startY
    local real startZ
    local real endAngle
    local real endDistance

    call PF_DestroyFishingVisuals(pid)

    if fisher == null or pool == null then
        set fisher = null
        set pool = null
        return
    endif

    call PF_CreateLineHandMarker(pid, fisher)

    set startX = PF_GetLineStartX(pid, fisher)
    set startY = PF_GetLineStartY(pid, fisher)
    set startZ = PF_GetLineStartZ(pid, fisher, startX, startY)
    set endAngle = GetRandomReal(0.00, bj_PI * 2.00)
    set endDistance = GetRandomReal(0.00, PF_BOBBER_POOL_RANDOM_RADIUS)
    set PF_LineEndBaseX[pid] = GetUnitX(pool) + endDistance * Cos(endAngle)
    set PF_LineEndBaseY[pid] = GetUnitY(pool) + endDistance * Sin(endAngle)
    set PF_LineEndBaseZ[pid] = PF_GetTerrainZ(PF_LineEndBaseX[pid], PF_LineEndBaseY[pid]) + PF_BOBBER_HEIGHT_OFFSET
    set PF_LineEndX[pid] = PF_LineEndBaseX[pid]
    set PF_LineEndY[pid] = PF_LineEndBaseY[pid]
    set PF_LineEndZ[pid] = PF_LineEndBaseZ[pid]
    set PF_FishingLine[pid] = AddLightningEx(PF_GetFishingLineLightningType(), true, startX, startY, startZ, PF_LineEndX[pid], PF_LineEndY[pid], PF_LineEndZ[pid])
    if PF_FishingLine[pid] != null and FishingLineUseCustomColor then
        call SetLightningColor(PF_FishingLine[pid], PF_LINE_COLOR_RED, PF_LINE_COLOR_GREEN, PF_LINE_COLOR_BLUE, PF_LINE_COLOR_ALPHA)
    endif

    if BobberModelPath != null and BobberModelPath != "" then
        set PF_BobberEffect[pid] = AddSpecialEffect(BobberModelPath, PF_LineEndX[pid], PF_LineEndY[pid])
        if PF_BobberEffect[pid] != null then
            call BlzSetSpecialEffectPosition(PF_BobberEffect[pid], PF_LineEndX[pid], PF_LineEndY[pid], PF_LineEndZ[pid])
            call BlzSetSpecialEffectScale(PF_BobberEffect[pid], PF_BOBBER_SCALE)
            call PF_PlayBobberCinematicCustomOne(pid)
            set PF_BobberStandDelay[pid] = PF_BOBBER_STAND_DELAY
        endif
    endif

    call PF_StartLineWobble(pid, PF_LINE_WOBBLE_DURATION, PF_LINE_WOBBLE_STRENGTH)
    call PF_UpdateFishingVisuals(pid)

    set fisher = null
    set pool = null
endfunction

private function PF_DisplayError takes player whichPlayer, string message returns nothing
    if whichPlayer != null and message != null and message != "" then
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "|cffff8080" + message + "|r")
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, whichPlayer)
    endif
endfunction

private function PF_DisplayMessage takes player whichPlayer, string message returns nothing
    if whichPlayer != null and message != null and message != "" then
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, message)
    endif
endfunction

private function PF_UI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function PF_UI_HideForPlayer takes player whichPlayer returns nothing
    if PF_UIParent != null and GetLocalPlayer() == whichPlayer then
        if BlzFrameIsVisible(PF_UIParent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, whichPlayer)
        endif
        call BlzFrameSetVisible(PF_UIParent, false)
    endif
endfunction

private function PF_UI_UpdateWindow takes integer pid, boolean biteActive returns nothing
    local real windowWidth
    local real windowOffset

    if PF_UIWindow == null then
        return
    endif

    set windowWidth = 0.240 * ((PF_WindowEnd[pid] - PF_WindowStart[pid]) / PF_CAST_DURATION)
    if windowWidth < 0.010 then
        set windowWidth = 0.010
    endif
    set windowOffset = 0.240 * (PF_WindowStart[pid] / PF_CAST_DURATION)
    if windowOffset < 0.00 then
        set windowOffset = 0.00
    elseif windowOffset > 0.230 then
        set windowOffset = 0.230
    endif

    call BlzFrameClearAllPoints(PF_UIWindow)
    call BlzFrameSetPoint(PF_UIWindow, FRAMEPOINT_LEFT, PF_UIBarBackdrop, FRAMEPOINT_LEFT, windowOffset, 0.00)
    call BlzFrameSetSize(PF_UIWindow, windowWidth, 0.018)
    call BlzFrameSetVisible(PF_UIWindow, biteActive)
endfunction

private function PF_UI_UpdateForPlayer takes player whichPlayer returns nothing
    local integer pid
    local unit fisher
    local unit pool
    local integer baseSkill = 0
    local integer effectiveSkill = 0
    local integer requiredSkill = 0
    local integer failChance = 0
    local real remaining
    local boolean biteActive
    local boolean started
    local boolean hasBait
    local string poolText
    local string baitText

    if whichPlayer == null then
        return
    endif

    set pid = GetPlayerId(whichPlayer)
    set fisher = PF_Fisher[pid]
    set pool = PF_Pool[pid]
    set started = PF_JobActive[pid] and PF_JobStarted[pid]
    set remaining = PF_CAST_DURATION - PF_Elapsed[pid]
    if remaining < 0.00 then
        set remaining = 0.00
    elseif remaining > PF_CAST_DURATION then
        set remaining = PF_CAST_DURATION
    endif
    set biteActive = started and PF_Elapsed[pid] >= PF_WindowStart[pid] and PF_Elapsed[pid] <= PF_WindowEnd[pid]
    set baseSkill = GNS_GetSkill(fisher, GNS_PROF_FISHING)
    set effectiveSkill = PF_GetEffectiveFishingSkill(fisher)
    set requiredSkill = GN_GetGatherUnitSkillRequired(pool)
    set failChance = PF_GetSkillFailChance(effectiveSkill, requiredSkill)
    set poolText = PF_GetPoolName(pool)
    set baitText = PF_GetBaitDisplayText(fisher)
    set hasBait = PF_BaitTypeCount > 0 and PF_FindBestAvailableBait(fisher) > 0

    if GetLocalPlayer() == whichPlayer then
        call BlzFrameSetText(PF_UITitle, TitleText)
        call BlzFrameSetText(PF_UIPoolText, "Pool: " + poolText)
        if effectiveSkill > baseSkill then
            call BlzFrameSetText(PF_UISkillText, "Skill: " + I2S(effectiveSkill) + " (" + I2S(baseSkill) + " +" + I2S(effectiveSkill - baseSkill) + ") / " + I2S(requiredSkill) + " | Fail " + I2S(failChance) + "%")
        else
            call BlzFrameSetText(PF_UISkillText, "Skill: " + I2S(baseSkill) + " / " + I2S(requiredSkill) + " | Fail " + I2S(failChance) + "%")
        endif
        call BlzFrameSetText(PF_UIBaitText, baitText)
        if PF_JobMoving[pid] then
            call BlzFrameSetText(PF_UIStatusText, MovingText)
        elseif biteActive then
            call BlzFrameSetText(PF_UIStatusText, BiteText)
        elseif PF_JobStarted[pid] then
            call BlzFrameSetText(PF_UIStatusText, WaitForBiteText)
        else
            call BlzFrameSetText(PF_UIStatusText, FishingText)
        endif
        call BlzFrameSetValue(PF_UIBar, remaining)
        call BlzFrameSetText(PF_UIBarLabel, R2SW(remaining, 1, 1) + "s")
        call BlzFrameSetEnable(PF_UIReelButton, biteActive)
        call BlzFrameSetEnable(PF_UIBaitButton, hasBait)
        call PF_UI_UpdateWindow(pid, biteActive)
    endif

    set fisher = null
    set pool = null
endfunction

private function PF_UI_ShowForPlayer takes player whichPlayer returns nothing
    if PF_UIParent != null and GetLocalPlayer() == whichPlayer then
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, whichPlayer)
        call BlzFrameSetVisible(PF_UIParent, true)
    endif
    call PF_UI_UpdateForPlayer(whichPlayer)
endfunction

private function PF_DisplayErrorText takes player whichPlayer, string message returns nothing
    if whichPlayer != null and message != null and message != "" then
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, "|cffff8080" + message + "|r")
    endif
endfunction

private function PF_ClearJobState takes integer pid returns nothing
    call PF_DestroyFishingVisuals(pid)

    if PF_Fisher[pid] != null and PF_UnitJob.has(GetHandleId(PF_Fisher[pid])) then
        call PF_UnitJob.remove(GetHandleId(PF_Fisher[pid]))
    endif
    if PF_Pool[pid] != null and PF_PoolJob.has(GetHandleId(PF_Pool[pid])) then
        call PF_PoolJob.remove(GetHandleId(PF_Pool[pid]))
    endif

    set PF_JobActive[pid] = false
    set PF_JobStarted[pid] = false
    set PF_JobMoving[pid] = false
    set PF_Fisher[pid] = null
    set PF_Pool[pid] = null
    set PF_Elapsed[pid] = 0.00
    set PF_MoveElapsed[pid] = 0.00
    set PF_WindowStart[pid] = 0.00
    set PF_WindowEnd[pid] = 0.00
    set PF_AnimationElapsed[pid] = 0.00
    set PF_BiteSoundPlayed[pid] = false
endfunction

private function PF_StopJob takes integer pid, string message, boolean showMessage, boolean errorSound returns nothing
    local player whichPlayer = Player(pid)
    local unit fisher = PF_Fisher[pid]
    local boolean fishingFailed = message == FishWentAwayText or message == NothingCaughtText

    if not PF_JobActive[pid] then
        set fisher = null
        set whichPlayer = null
        return
    endif

    if fisher != null then
        call IssueImmediateOrder(fisher, "stop")
        call PF_ResetFisherAnimation(fisher)
    endif

    call PF_ClearJobState(pid)
    if PF_ActiveJobCount > 0 then
        set PF_ActiveJobCount = PF_ActiveJobCount - 1
    endif
    if PF_ActiveJobCount <= 0 and PF_TickTimer != null then
        call PauseTimer(PF_TickTimer)
    endif

    if fishingFailed then
        call PF_PlayFishingFailSound(fisher)
    endif

    if showMessage then
        if errorSound then
            if fishingFailed then
                call PF_DisplayErrorText(whichPlayer, message)
            else
                call PF_DisplayError(whichPlayer, message)
            endif
        else
            call PF_DisplayMessage(whichPlayer, message)
        endif
    endif

    call PF_UI_HideForPlayer(whichPlayer)

    set fisher = null
    set whichPlayer = null
endfunction

private function PF_BeginCast takes integer pid returns nothing
    local real latestWindowStart = PF_CAST_DURATION - PF_REEL_WINDOW_DURATION

    if latestWindowStart < PF_REEL_WINDOW_MIN_START then
        set latestWindowStart = PF_REEL_WINDOW_MIN_START
    endif

    set PF_JobMoving[pid] = false
    set PF_JobStarted[pid] = true
    set PF_Elapsed[pid] = 0.00
    set PF_AnimationElapsed[pid] = 0.00
    set PF_WindowStart[pid] = GetRandomReal(PF_REEL_WINDOW_MIN_START, latestWindowStart)
    set PF_WindowEnd[pid] = PF_WindowStart[pid] + PF_REEL_WINDOW_DURATION
    set PF_BiteSoundPlayed[pid] = false
    if PF_WindowEnd[pid] > PF_CAST_DURATION then
        set PF_WindowEnd[pid] = PF_CAST_DURATION
    endif

    call IssueImmediateOrder(PF_Fisher[pid], "stop")
    call PF_PlayFishingAnimation(pid)
    call PF_CreateFishingVisuals(pid)
    call PF_PlayFishingStartSound(PF_Fisher[pid])
    call PF_UI_UpdateForPlayer(Player(pid))
endfunction

private function PF_CompleteJob takes integer pid returns nothing
    local unit fisher = PF_Fisher[pid]
    local unit pool = PF_Pool[pid]
    local player whichPlayer = Player(pid)
    local integer requiredSkill
    local integer effectiveSkill
    local integer failChance
    local integer awarded

    if not PF_JobActive[pid] or fisher == null or pool == null then
        set fisher = null
        set pool = null
        set whichPlayer = null
        return
    endif

    set requiredSkill = GN_GetGatherUnitSkillRequired(pool)
    set effectiveSkill = PF_GetEffectiveFishingSkill(fisher)
    set failChance = PF_GetSkillFailChance(effectiveSkill, requiredSkill)
    call PF_PlayFishingBiteSoundIfNeeded(pid, fisher)
    if failChance > 0 and GetRandomInt(1, 100) <= failChance then
        call PF_StopJob(pid, FishWentAwayText, true, true)
        set fisher = null
        set pool = null
        set whichPlayer = null
        return
    endif

    set awarded = GNU_RollGatherUnitRewards(fisher, pool)
    if awarded > 0 then
        call GNS_AwardGatherSkillForNode(fisher, GNS_PROF_FISHING, requiredSkill, 1)
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, whichPlayer)
        call PF_StopJob(pid, CaughtSomethingText, true, false)
    else
        call PF_StopJob(pid, NothingCaughtText, true, false)
    endif

    set fisher = null
    set pool = null
    set whichPlayer = null
endfunction

private function PF_UpdateJob takes integer pid returns nothing
    local unit fisher = PF_Fisher[pid]
    local unit pool = PF_Pool[pid]

    if not PF_JobActive[pid] then
        set fisher = null
        set pool = null
        return
    endif

    if not PF_IsUnitAlive(fisher) or not PF_IsFishingPool(pool) then
        call PF_StopJob(pid, FishingInterruptedText, true, true)
        set fisher = null
        set pool = null
        return
    endif

    if PF_JobMoving[pid] then
        set PF_MoveElapsed[pid] = PF_MoveElapsed[pid] + PF_TICK_INTERVAL
        if PF_IsNearPool(fisher, pool, PF_READY_RANGE) then
            call PF_BeginCast(pid)
        elseif PF_MoveElapsed[pid] >= PF_MOVE_TIMEOUT then
            call PF_StopJob(pid, TooFarText, true, true)
        endif
        set fisher = null
        set pool = null
        return
    endif

    if PF_JobStarted[pid] then
        if not PF_IsNearPool(fisher, pool, PF_CANCEL_RANGE) then
            call PF_StopJob(pid, FishingInterruptedText, true, true)
            set fisher = null
            set pool = null
            return
        endif

        call PF_UpdateFishingVisuals(pid)
        set PF_Elapsed[pid] = PF_Elapsed[pid] + PF_TICK_INTERVAL
        set PF_AnimationElapsed[pid] = PF_AnimationElapsed[pid] + PF_TICK_INTERVAL
        if PF_AnimationElapsed[pid] >= PF_ANIMATION_LOOP_PERIOD then
            set PF_AnimationElapsed[pid] = 0.00
            call PF_PlayFishingAnimation(pid)
        endif
        if PF_Elapsed[pid] >= PF_WindowStart[pid] and PF_Elapsed[pid] <= PF_WindowEnd[pid] then
            call PF_PlayFishingBiteSoundIfNeeded(pid, fisher)
        endif
        if PF_Elapsed[pid] > PF_WindowEnd[pid] then
            call PF_StopJob(pid, FishWentAwayText, true, true)
        else
            call PF_UI_UpdateForPlayer(Player(pid))
        endif
    endif

    set fisher = null
    set pool = null
endfunction

private function PF_Tick takes nothing returns nothing
    local integer pid = 0

    loop
        exitwhen pid >= bj_MAX_PLAYERS
        call PF_UpdateJob(pid)
        set pid = pid + 1
    endloop
endfunction

private function PF_ReserveJob takes integer pid, unit fisher, unit pool returns nothing
    set PF_JobActive[pid] = true
    set PF_JobStarted[pid] = false
    set PF_JobMoving[pid] = false
    set PF_Fisher[pid] = fisher
    set PF_Pool[pid] = pool
    set PF_Elapsed[pid] = 0.00
    set PF_MoveElapsed[pid] = 0.00
    set PF_WindowStart[pid] = 0.00
    set PF_WindowEnd[pid] = 0.00
    set PF_AnimationElapsed[pid] = 0.00
    set PF_BiteSoundPlayed[pid] = false
    set PF_UnitJob.integer[GetHandleId(fisher)] = pid + 1
    set PF_PoolJob.integer[GetHandleId(pool)] = pid + 1
    set PF_ActiveJobCount = PF_ActiveJobCount + 1

    if PF_ActiveJobCount == 1 then
        call TimerStart(PF_TickTimer, PF_TICK_INTERVAL, true, function PF_Tick)
    endif
endfunction

private function PF_StartJob takes player whichPlayer, unit fisher, unit pool returns boolean
    local integer pid
    local real x
    local real y

    if whichPlayer == null or fisher == null or pool == null then
        return false
    endif

    set pid = GetPlayerId(whichPlayer)
    if not PF_IsFishingPool(pool) then
        call PF_DisplayError(whichPlayer, NotFishingPoolText)
        return false
    endif
    if not PF_IsTrackedFisherCandidate(whichPlayer, fisher) then
        call PF_DisplayError(whichPlayer, NoTrackedFisherText)
        return false
    endif
    if not PF_IsNearPool(fisher, pool, PF_START_RANGE) then
        call PF_DisplayError(whichPlayer, TooFarText)
        return false
    endif
    if not PF_TryEquipFishingPole(fisher) then
        call PF_DisplayError(whichPlayer, NeedFishingPoleText)
        return false
    endif
    if Professions_IsUnitReserved(fisher) then
        call PF_DisplayError(whichPlayer, UnitBusyText)
        return false
    endif

    if PF_JobActive[pid] then
        call PF_StopJob(pid, "", false, false)
    endif

    if PF_UnitJob.has(GetHandleId(fisher)) then
        call PF_DisplayError(whichPlayer, UnitBusyText)
        return false
    endif
    if PF_PoolJob.has(GetHandleId(pool)) then
        call PF_DisplayError(whichPlayer, PoolBusyText)
        return false
    endif

    call PF_ReserveJob(pid, fisher, pool)
    if PF_IsNearPool(fisher, pool, PF_READY_RANGE) then
        call PF_BeginCast(pid)
    else
        set PF_JobMoving[pid] = true
        set x = PF_GetApproachPointX(fisher, pool)
        set y = PF_GetApproachPointY(fisher, pool)
        call IssuePointOrder(fisher, "move", x, y)
    endif

    call PF_UI_ShowForPlayer(whichPlayer)
    return true
endfunction

public function Start takes player whichPlayer, unit fisher, unit pool returns boolean
    return PF_StartJob(whichPlayer, fisher, pool)
endfunction

public function StopForUnit takes unit fisher returns boolean
    local integer jobSlot

    if fisher == null or PF_UnitJob == 0 or not PF_UnitJob.has(GetHandleId(fisher)) then
        return false
    endif

    set jobSlot = PF_UnitJob.integer[GetHandleId(fisher)]
    if jobSlot <= 0 then
        return false
    endif

    call PF_StopJob(jobSlot - 1, FishingInterruptedText, true, true)
    return true
endfunction

private function PF_SelectAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local unit selectedUnit = GetTriggerUnit()
    local unit fisher

    if not PF_IsFishingPool(selectedUnit) then
        set selectedUnit = null
        set whichPlayer = null
        return
    endif

    set fisher = PF_GetNearestTrackedFisher(whichPlayer, selectedUnit)
    if fisher == null then
        call PF_DisplayError(whichPlayer, NoTrackedFisherText)
    else
        call PF_StartJob(whichPlayer, fisher, selectedUnit)
    endif

    set fisher = null
    set selectedUnit = null
    set whichPlayer = null
endfunction

private function PF_ReelAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid = GetPlayerId(whichPlayer)

    if PF_JobActive[pid] and PF_JobStarted[pid] then
        call PF_StartLineWobble(pid, PF_LINE_WOBBLE_DURATION, PF_LINE_WOBBLE_STRENGTH)
        call PF_UpdateFishingVisuals(pid)
    endif

    if not PF_JobActive[pid] or not PF_JobStarted[pid] then
        call PF_DisplayError(whichPlayer, WaitForBiteText)
    elseif PF_Elapsed[pid] >= PF_WindowStart[pid] and PF_Elapsed[pid] <= PF_WindowEnd[pid] then
        call PF_CompleteJob(pid)
    elseif PF_Elapsed[pid] > PF_WindowEnd[pid] then
        call PF_StopJob(pid, FishWentAwayText, true, true)
    else
        call PF_DisplayError(whichPlayer, WaitForBiteText)
    endif

    set whichPlayer = null
endfunction

private function PF_BaitAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid = GetPlayerId(whichPlayer)
    local unit fisher = PF_Fisher[pid]
    local integer baitIndex
    local integer handleId
    local real duration
    local integer requiredSkill
    local string baitName

    if not PF_JobActive[pid] or fisher == null then
        call PF_DisplayError(whichPlayer, NoTrackedFisherText)
        set fisher = null
        set whichPlayer = null
        return
    endif

    set baitIndex = PF_FindBestAvailableBait(fisher)
    if baitIndex <= 0 then
        set requiredSkill = PF_GetUnavailableBaitRequirement(fisher)
        if requiredSkill > 0 then
            call PF_DisplayError(whichPlayer, "Requires Fishing " + I2S(requiredSkill) + ".")
        else
            call PF_DisplayError(whichPlayer, NoBaitText)
        endif
        set fisher = null
        set whichPlayer = null
        return
    endif

    set duration = PF_BaitDuration[baitIndex]
    if duration <= 0.00 then
        set duration = 60.00
    endif
    set baitName = PF_GetBaitNameByIndex(baitIndex)

    call PF_ConsumeAvailableItem(fisher, PF_BaitItemType[baitIndex], 1)
    set handleId = GetHandleId(fisher)
    set PF_BaitBonusByUnit.integer[handleId] = PF_BaitBonus[baitIndex]
    set PF_BaitExpiresByUnit.real[handleId] = PF_GetNow() + duration
    set PF_BaitNameByUnit.string[handleId] = baitName

    if PF_JobStarted[pid] then
        call PF_StartLineWobble(pid, PF_LINE_WOBBLE_DURATION, PF_LINE_WOBBLE_STRENGTH)
        call PF_UpdateFishingVisuals(pid)
    endif

    call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, whichPlayer)
    call PF_UI_UpdateForPlayer(whichPlayer)

    set fisher = null
    set whichPlayer = null
endfunction

private function PF_CancelAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid = GetPlayerId(whichPlayer)

    if PF_JobActive[pid] then
        call PF_StopJob(pid, FishingInterruptedText, true, true)
    else
        call PF_UI_HideForPlayer(whichPlayer)
    endif

    set whichPlayer = null
endfunction

private function PF_AttackedAction takes nothing returns nothing
    local unit attackedUnit = GetTriggerUnit()
    local integer jobSlot

    if attackedUnit != null and PF_UnitJob != 0 and PF_UnitJob.has(GetHandleId(attackedUnit)) then
        set jobSlot = PF_UnitJob.integer[GetHandleId(attackedUnit)]
        if jobSlot > 0 then
            call PF_StopJob(jobSlot - 1, FishingInterruptedText, true, true)
        endif
    endif

    set attackedUnit = null
endfunction

private function PF_CreateFrames takes nothing returns nothing
    set PF_UIParent = BlzCreateFrameByType("BACKDROP", "FishingUIParent", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
    call BlzFrameSetAbsPoint(PF_UIParent, FRAMEPOINT_TOPLEFT, 0.245, 0.320)
    call BlzFrameSetAbsPoint(PF_UIParent, FRAMEPOINT_BOTTOMRIGHT, 0.555, 0.200)
    call BlzFrameSetTexture(PF_UIParent, PanelTexture, 0, true)
    call BlzFrameSetAlpha(PF_UIParent, 235)
    call BlzFrameSetVertexColor(PF_UIParent, BlzConvertColor(235, 12, 12, 12))

    set PF_UITitle = BlzCreateFrameByType("TEXT", "FishingUITitle", PF_UIParent, "", 0)
    call BlzFrameSetPoint(PF_UITitle, FRAMEPOINT_TOPLEFT, PF_UIParent, FRAMEPOINT_TOPLEFT, 0.010, -0.006)
    call BlzFrameSetSize(PF_UITitle, 0.120, 0.016)
    call BlzFrameSetTextAlignment(PF_UITitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(PF_UITitle, false)
    call BlzFrameSetText(PF_UITitle, TitleText)

    set PF_UIPoolText = BlzCreateFrameByType("TEXT", "FishingUIPoolText", PF_UIParent, "", 0)
    call BlzFrameSetPoint(PF_UIPoolText, FRAMEPOINT_TOPLEFT, PF_UITitle, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.003)
    call BlzFrameSetSize(PF_UIPoolText, 0.180, 0.013)
    call BlzFrameSetTextAlignment(PF_UIPoolText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(PF_UIPoolText, 0.92)
    call BlzFrameSetEnable(PF_UIPoolText, false)

    set PF_UISkillText = BlzCreateFrameByType("TEXT", "FishingUISkillText", PF_UIParent, "", 0)
    call BlzFrameSetPoint(PF_UISkillText, FRAMEPOINT_TOPLEFT, PF_UIPoolText, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.002)
    call BlzFrameSetSize(PF_UISkillText, 0.290, 0.013)
    call BlzFrameSetTextAlignment(PF_UISkillText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(PF_UISkillText, 0.90)
    call BlzFrameSetEnable(PF_UISkillText, false)

    set PF_UIBaitText = BlzCreateFrameByType("TEXT", "FishingUIBaitText", PF_UIParent, "", 0)
    call BlzFrameSetPoint(PF_UIBaitText, FRAMEPOINT_TOPLEFT, PF_UISkillText, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.002)
    call BlzFrameSetSize(PF_UIBaitText, 0.180, 0.013)
    call BlzFrameSetTextAlignment(PF_UIBaitText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(PF_UIBaitText, 0.90)
    call BlzFrameSetEnable(PF_UIBaitText, false)

    set PF_UIBarBackdrop = BlzCreateFrameByType("BACKDROP", "FishingUIBarBackdrop", PF_UIParent, "", 0)
    call BlzFrameSetPoint(PF_UIBarBackdrop, FRAMEPOINT_TOPLEFT, PF_UIBaitText, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.010)
    call BlzFrameSetSize(PF_UIBarBackdrop, 0.240, 0.018)
    call BlzFrameSetTexture(PF_UIBarBackdrop, PanelTexture, 0, false)
    call BlzFrameSetAlpha(PF_UIBarBackdrop, 255)
    call BlzFrameSetVertexColor(PF_UIBarBackdrop, BlzConvertColor(255, 18, 18, 18))
    call BlzFrameSetEnable(PF_UIBarBackdrop, false)

    set PF_UIBar = BlzCreateSimpleFrame("SimpleStatusBarTemplate", PF_UIBarBackdrop, 0)
    call BlzFrameSetAllPoints(PF_UIBar, PF_UIBarBackdrop)
    call BlzFrameSetTexture(PF_UIBar, ProgressBarTexture, 0, true)
    call BlzFrameSetMinMaxValue(PF_UIBar, 0.00, PF_CAST_DURATION)
    call BlzFrameSetValue(PF_UIBar, PF_CAST_DURATION)

    set PF_UIWindow = BlzCreateFrameByType("BACKDROP", "FishingUIWindow", PF_UIBarBackdrop, "", 0)
    call BlzFrameSetTexture(PF_UIWindow, PanelTexture, 0, false)
    call BlzFrameSetAlpha(PF_UIWindow, 210)
    call BlzFrameSetVertexColor(PF_UIWindow, BlzConvertColor(210, 80, 255, 80))
    call BlzFrameSetEnable(PF_UIWindow, false)
    call BlzFrameSetVisible(PF_UIWindow, false)

    set PF_UIBarLabel = BlzCreateFrameByType("TEXT", "FishingUIBarLabel", PF_UIBarBackdrop, "", 0)
    call BlzFrameSetAllPoints(PF_UIBarLabel, PF_UIBarBackdrop)
    call BlzFrameSetTextAlignment(PF_UIBarLabel, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(PF_UIBarLabel, 0.90)
    call BlzFrameSetEnable(PF_UIBarLabel, false)

    set PF_UIStatusText = BlzCreateFrameByType("TEXT", "FishingUIStatusText", PF_UIParent, "", 0)
    call BlzFrameSetPoint(PF_UIStatusText, FRAMEPOINT_TOP, PF_UIBarBackdrop, FRAMEPOINT_BOTTOM, 0.000, -0.004)
    call BlzFrameSetSize(PF_UIStatusText, 0.240, 0.014)
    call BlzFrameSetTextAlignment(PF_UIStatusText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(PF_UIStatusText, 0.90)
    call BlzFrameSetEnable(PF_UIStatusText, false)

    set PF_UIReelButton = BlzCreateFrameByType("GLUETEXTBUTTON", "FishingUIReelButton", PF_UIParent, "ScriptDialogButton", 0)
    call BlzFrameSetPoint(PF_UIReelButton, FRAMEPOINT_LEFT, PF_UIBarBackdrop, FRAMEPOINT_RIGHT, 0.010, 0.000)
    call BlzFrameSetSize(PF_UIReelButton, 0.055, 0.026)
    call BlzFrameSetText(PF_UIReelButton, ReelButtonText)
    call BlzFrameSetEnable(PF_UIReelButton, false)

    set PF_UIBaitButton = BlzCreateFrameByType("GLUETEXTBUTTON", "FishingUIBaitButton", PF_UIParent, "ScriptDialogButton", 0)
    call BlzFrameSetPoint(PF_UIBaitButton, FRAMEPOINT_BOTTOM, PF_UIReelButton, FRAMEPOINT_TOP, 0.000, 0.006)
    call BlzFrameSetSize(PF_UIBaitButton, 0.055, 0.024)
    call BlzFrameSetText(PF_UIBaitButton, BaitButtonText)
    call BlzFrameSetEnable(PF_UIBaitButton, false)

    set PF_UICancelButton = BlzCreateFrameByType("GLUETEXTBUTTON", "FishingUICancelButton", PF_UIParent, "ScriptDialogButton", 0)
    call BlzFrameSetPoint(PF_UICancelButton, FRAMEPOINT_BOTTOM, PF_UIBaitButton, FRAMEPOINT_TOP, 0.000, 0.006)
    call BlzFrameSetSize(PF_UICancelButton, 0.060, 0.024)
    call BlzFrameSetText(PF_UICancelButton, CancelButtonText)

    call BlzTriggerRegisterFrameEvent(PF_ReelTrigger, PF_UIReelButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PF_ClearFocusTrigger, PF_UIReelButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PF_BaitTrigger, PF_UIBaitButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PF_ClearFocusTrigger, PF_UIBaitButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PF_CancelTrigger, PF_UICancelButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PF_ClearFocusTrigger, PF_UICancelButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(PF_UIParent, false)
endfunction

public function Init takes nothing returns nothing
    local integer playerIndex = 0

    if PF_Initialized then
        return
    endif
    set PF_Initialized = true

    set PF_UnitJob = Table.create()
    set PF_PoolJob = Table.create()
    set PF_BaitBonusByUnit = Table.create()
    set PF_BaitExpiresByUnit = Table.create()
    set PF_BaitNameByUnit = Table.create()
    set PF_BobberDestroyTimerEffect = Table.create()
    set PF_TerrainSample = Location(0.00, 0.00)

    set PF_ClockTimer = CreateTimer()
    set PF_TickTimer = CreateTimer()
    set PF_SelectTrigger = CreateTrigger()
    set PF_ReelTrigger = CreateTrigger()
    set PF_BaitTrigger = CreateTrigger()
    set PF_CancelTrigger = CreateTrigger()
    set PF_ClearFocusTrigger = CreateTrigger()
    set PF_AttackedTrigger = CreateTrigger()

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(PF_SelectTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_SELECTED, null)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerRegisterAnyUnitEventBJ(PF_AttackedTrigger, EVENT_PLAYER_UNIT_ATTACKED)

    call TriggerAddAction(PF_SelectTrigger, function PF_SelectAction)
    call TriggerAddAction(PF_ReelTrigger, function PF_ReelAction)
    call TriggerAddAction(PF_BaitTrigger, function PF_BaitAction)
    call TriggerAddAction(PF_CancelTrigger, function PF_CancelAction)
    call TriggerAddAction(PF_ClearFocusTrigger, function PF_UI_ClearFocusAction)
    call TriggerAddAction(PF_AttackedTrigger, function PF_AttackedAction)

    call TimerStart(PF_ClockTimer, 999999.00, false, function PF_NoOp)
    call PF_CreateFrames()

    call RegisterPoleItemWithBonus(PF_ITEM_JINZUN_FISHING_POLE, 0)
    call RegisterPoleItemWithBonus(PF_ITEM_BASIC_FISHING_POLE, 0)
    call RegisterPoleItemWithBonus(PF_ITEM_STRONG_FISHING_POLE, 5)
    call RegisterPoleItemWithBonus(PF_ITEM_BIG_IRON_FISHING_POLE, 20)
    call RegisterPoleItemWithBonus(PF_ITEM_PROMASTER_FISHING_POLE, 100)
    call RegisterBaitItemEx(PF_ITEM_SHINY_BAUBLE, 25, PF_DEFAULT_BAIT_DURATION, "Shiny Bauble", 0)
    call RegisterBaitItemEx(PF_ITEM_NIGHTCRAWLERS, 50, PF_DEFAULT_BAIT_DURATION, "Nightcrawlers", 50)
    call RegisterBaitItemEx(PF_ITEM_BRIGHT_BAUBLES, 75, PF_DEFAULT_BAIT_DURATION, "Bright Baubles", 100)
    call RegisterBaitItemEx(PF_ITEM_AQUADYNAMIC_FISH, 100, PF_DEFAULT_BAIT_DURATION, "Aquadynamic Fish", 125)
    call PF_RegisterDefaultFishPoolUnit()
    call Professions_SetProfessionSoundLabels(GNS_PROF_FISHING, PF_SOUND_START, PF_SOUND_LOOP, PF_SOUND_FINISH)
    call Professions_SetProfessionSoundHandles(GNS_PROF_FISHING, Interface_Profession_Fishing_Start, Interface_Profession_Fishing_Loop, Interface_Profession_Fishing_End)
    call Professions_SetProfessionSoundPaths(GNS_PROF_FISHING, Interface_Profession_Fishing_StartPath, Interface_Profession_Fishing_LoopPath, Interface_Profession_Fishing_EndPath)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_FISHING, PF_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_FISHING, PF_CRAFTER_ANIMATION_PRIMARY, PF_CRAFTER_ANIMATION_FALLBACK)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
