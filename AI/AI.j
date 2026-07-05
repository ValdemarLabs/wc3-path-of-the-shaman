/**
    AI

    Author: Valdemar
    Version:

    Description:
    Master JASS AI registry and shared behavior engine for PotS AI heroes and
    AI units. This library owns AI instance identity, class/profile caps,
    shared state transitions, travel, boss-cast evade, revive handling, common
    helpers, and ExSound/DialogSystem chatter dispatch. Class-specific logic
    belongs in small sublibraries that register profiles and callbacks.

    Credits:
    - Old GUI triggers under `AI/_OldGUI_triggers/`
    - Table v6 by Bribe

    How to install:
    Import this library before AI sublibraries and after the required shared
    systems: Table, Companions, UnitDeathEvent, DamageEngine, DialogSystem, and
    ExSound. File names may use underscores, but vJASS library identifiers and
    generated public function prefixes must not.

    API:
    call AI_RegisterClass(className)
    call AI_RegisterProfile(classId, unitTypeId, profileName)
    call AI_RegisterUnit(whichUnit, profileId, uniqueId)
    call AI_UnregisterUnit(whichUnit)
    call AI_SpawnProfile(profileId, owner, x, y, facing, uniqueId)
    call AI_SetClassCap(classId, cap)
    call AI_SetProfileCap(profileId, cap)
    call AI_SetUnitTypeCap(unitTypeId, cap)
    call AI_SetProfileAutonomous(profileId, enabled)
    call AI_SetProfileSpawnOwner(profileId, owner)
    call AI_SetProfileThinkCallback(profileId, callback)
    call AI_AddProfileSpawnRect(profileId, whichRect)
    call AI_AddProfileRetreatRect(profileId, whichRect)
    call AI_AddProfileShopUnit(profileId, shopUnit)
    call AI_AddRandomSpawnProfile(profileId)
    call AI_SetRandomSpawnHardCap(cap)
    call AI_SetRandomSpawnActiveCap(cap)
    call AI_SetRandomSpawnOwner(owner)
    call AI_SpawnRandomHero(showMessage)
    call AI_AddProfileStartingAbility(profileId, abilityId)
    call AI_AddProfileAbility(profileId, abilityId)
    call AI_AddDefaultShopItems(profileId)
    call AI_RegisterBarkSequence(profileId, barkType, text, soundPrefix, first, last)
    call AI_RegisterBarkReply(primarySoundKey, responderProfileId, text, replySoundKey)
    call AI_RegisterBarkReplySequenceSuffix(primarySoundPrefix, first, last, responderProfileId, text, replySoundPrefix, replySoundSuffix)
    call AI_BeginBuy(whichUnit)
    call AI_BeginSell(whichUnit)
    call AI_BeginCamp(whichUnit, duration)
    call AI_StartTravel(whichUnit, duration, returnX, returnY)
    call AI_RegisterBossCastAbility(abilityId, evadeRadius, evadeDistance)
    call AI_HandleBossCast(caster, abilityId, targetX, targetY)
    call AI_RequestBark(speaker, barkType)
    call AI_SetDebugMode(enabled)

**/
library AI initializer Init requires Table, Companions, UnitDeathEvent, DamageEngine, DialogSystem, ExSound

globals
    constant integer AI_STATE_INACTIVE = 0
    constant integer AI_STATE_IDLE = 1
    constant integer AI_STATE_WANDER = 2
    constant integer AI_STATE_COMBAT = 3
    constant integer AI_STATE_RETREAT_COMBAT = 4
    constant integer AI_STATE_RETREAT_BASE = 5
    constant integer AI_STATE_BUY = 6
    constant integer AI_STATE_SELL = 7
    constant integer AI_STATE_CAMP = 8
    constant integer AI_STATE_TRAVEL = 9
    constant integer AI_STATE_DEAD = 10
    constant integer AI_STATE_COMPANION_CONTROLLED = 11
    constant integer AI_STATE_BOSS_EVADE = 12

    constant integer AI_BARK_GREET = 1
    constant integer AI_BARK_PASSIVE = 2
    constant integer AI_BARK_NORMAL = 3
    constant integer AI_BARK_AGGRESSIVE = 4
    constant integer AI_BARK_HOLD = 5
    constant integer AI_BARK_DROP_ITEMS = 6
    constant integer AI_BARK_KICKED = 7
    constant integer AI_BARK_ITEM_GIVEN = 8
    constant integer AI_BARK_ATTACKING = 9
    constant integer AI_BARK_CASTING = 10
    constant integer AI_BARK_KILLING = 11
    constant integer AI_BARK_COMPANION_DIES = 12
    constant integer AI_BARK_IDLE = 13
    constant integer AI_BARK_MOVING = 14
    constant integer AI_BARK_FAREWELL = 15

    integer AI_EventInstance = 0
    unit AI_EventUnit = null
    integer AI_EventProfileId = 0
    integer AI_EventClassId = 0
    integer AI_EventState = AI_STATE_INACTIVE
    integer AI_EventBarkType = 0
    unit AI_EventTarget = null
    integer AI_EventAbilityId = 0

    private constant boolean DEBUG_DEFAULT = false
    private constant integer MAX_PLAYER_INDEX = 27
    private constant integer MAX_AI_INSTANCES = 512
    private constant integer MAX_BOSS_CASTS = 64
    private constant integer MAX_PROFILE_POINTS = 64
    private constant integer MAX_PROFILE_ITEMS = 64
    private constant integer MAX_BARK_LINES = 192
    private constant integer MAX_RANDOM_SPAWN_PROFILES = 64
    private constant integer MAX_PLAYER_COLOR_INDEX = 23
    private constant integer AI_RANDOM_DEFAULT_OWNER_INDEX = 1
    private constant real AI_THINK_INTERVAL = 0.50
    private constant real AI_DEFAULT_THINK_MIN = 0.80
    private constant real AI_DEFAULT_THINK_MAX = 1.20
    private constant real AI_DEFAULT_REVIVE_DELAY = 60.00
    private constant real AI_DEFAULT_ABILITY_GAP = 2.00
    private constant real AI_ABILITY_ORDER_JITTER = 0.35
    private constant real AI_RETREAT_COMBAT_TIME = 5.00
    private constant real AI_RETREAT_BASE_TIME = 30.00
    private constant real AI_BOSS_EVADE_TIME = 2.25
    private constant real AI_DIALOG_UNLOCK_PAD = 0.15
    private constant real AI_BARK_AUDIBLE_RANGE = 2600.00
    private constant real AI_BARK_GLOBAL_GAP = 0.75
    private constant real AI_SHIELD_BLOCK_CHANCE = 33.34
    private constant real AI_RANDOM_SPAWN_MIN = 50.00
    private constant real AI_RANDOM_SPAWN_MAX = 150.00
    private constant real AI_RANDOM_TRAVEL_MIN = 120.00
    private constant real AI_RANDOM_TRAVEL_MAX = 260.00
    private constant real AI_RANDOM_TRAVEL_DURATION_MIN = 60.00
    private constant real AI_RANDOM_TRAVEL_DURATION_MAX = 180.00

    private constant integer ITEM_MINOR_MANA_POTION = 'I6BS'
    private constant integer ITEM_MANA_POTION = 'pman'
    private constant integer ITEM_MAJOR_MANA_POTION = 'I6BT'
    private constant integer ITEM_MINOR_HEALING_POTION = 'I6BD'
    private constant integer ITEM_HEALING_POTION = 'phea'
    private constant integer ITEM_MAJOR_HEALING_POTION = 'I6BE'
    private constant integer ITEM_SPRING_WATER = 'I60Z'
    private constant integer ITEM_HEALING_SALVE = 'hslv'
    private constant integer ITEM_GREATER_HEALING_SALVE = 'I6BC'

    private Table UnitInstance = 0
    private Table UniqueInstance = 0
    private Table ClassByName = 0
    private Table ProfileByName = 0

    private Table ClassName = 0
    private Table ClassCap = 0
    private Table ClassActiveCount = 0

    private Table ProfileName = 0
    private Table ProfileClass = 0
    private Table ProfileUnitType = 0
    private Table ProfileCap = 0
    private Table ProfileActiveCount = 0
    private Table ProfileReviveDelay = 0
    private Table ProfileNoManaRestore = 0
    private Table ProfileAllowCompanionTravel = 0
    private Table ProfileAutonomousDisabled = 0
    private Table ProfileSpawnOwnerSlot = 0
    private Table ProfileThinkTrigger = 0
    private Table ProfileDeathTrigger = 0
    private Table ProfileReviveTrigger = 0

    private Table UnitTypeCap = 0
    private Table UnitTypeActiveCount = 0

    private Table InstanceUnit = 0
    private Table InstanceClass = 0
    private Table InstanceProfile = 0
    private Table InstanceUnique = 0
    private Table InstanceUnitType = 0
    private Table InstanceState = 0
    private Table InstancePreviousState = 0
    private Table InstanceActiveSlot = 0
    private Table InstanceAlive = 0
    private Table InstanceTraveling = 0
    private Table InstanceRandomManaged = 0
    private Table InstanceHiddenByCap = 0
    private Table InstanceCompanionControlled = 0
    private Table InstanceNextThink = 0
    private Table InstanceNextAbility = 0
    private Table InstanceNextItem = 0
    private Table InstanceNextChat = 0
    private Table InstanceNextBark = 0
    private Table InstanceRetreatUntil = 0
    private Table InstanceTravelReturnAt = 0
    private Table InstanceTravelReturnX = 0
    private Table InstanceTravelReturnY = 0
    private Table InstanceHomeX = 0
    private Table InstanceHomeY = 0
    private Table InstanceActionX = 0
    private Table InstanceActionY = 0
    private Table InstanceReviveTimer = 0
    private Table ReviveTimerInstance = 0

    private Table ProfileSpawnCount = 0
    private Table ProfileSpawnX = 0
    private Table ProfileSpawnY = 0
    private Table ProfileRetreatCount = 0
    private Table ProfileRetreatX = 0
    private Table ProfileRetreatY = 0
    private Table ProfileShopCount = 0
    private Table ProfileShopX = 0
    private Table ProfileShopY = 0
    private Table ProfileShopItemCount = 0
    private Table ProfileShopItemType = 0
    private Table ProfileStartingAbilityCount = 0
    private Table ProfileStartingAbilityId = 0
    private Table ProfileAbilityCount = 0
    private Table ProfileAbilityId = 0

    private Table BarkLineCount = 0
    private Table BarkLineText = 0
    private Table BarkLineSound = 0
    private Table ReplyLineCount = 0
    private Table ReplyLineResponderProfile = 0
    private Table ReplyLineText = 0
    private Table ReplyLineSound = 0
    private Table ReplyTimerSpeaker = 0
    private Table ReplyTimerResponder = 0
    private Table ReplyTimerText = 0
    private Table ReplyTimerSound = 0

    private Table TempAbilityUnit = 0
    private Table TempAbilityRemove = 0
    private Table TempAbilityRestore = 0

    private integer ActiveCount = 0
    private integer array ActiveInstances
    private integer NextInstanceId = 1
    private integer NextClassId = 1
    private integer NextProfileId = 1
    private integer RandomSpawnProfileCount = 0
    private integer array RandomSpawnProfiles
    private integer RandomSpawnManagedCount = 0
    private integer RandomSpawnHardCap = 12
    private integer RandomSpawnActiveCap = 4
    private integer RandomSpawnOwnerIndex = AI_RANDOM_DEFAULT_OWNER_INDEX

    private timer ClockTimer = null
    private timer ThinkTimer = null
    private timer RandomSpawnTimer = null
    private timer RandomTravelTimer = null
    private timer DialogUnlockTimer = null
    private trigger AttackTrigger = null
    private trigger SpellEffectTrigger = null
    private trigger LevelTrigger = null
    private trigger ItemTrigger = null
    private trigger DebugSpawnTrigger = null
    private trigger DebugModeTrigger = null
    private group TempGroup = null
    private boolean DebugMode = DEBUG_DEFAULT
    private boolean RandomSpawnEnabled = true
    private boolean RandomTravelEnabled = true
    private real NextGlobalBark = 0.00
    private real RandomPointX = 0.00
    private real RandomPointY = 0.00

    private boolean BossFightActive = false
    private integer BossCastCount = 0
    private integer array BossCastAbility
    private real array BossCastRadius
    private real array BossCastDistance

    private unit SearchSource = null
    private unit SearchBestUnit = null
    private real SearchBestDistance = 0.00
    private unit AllySearchSource = null
    private unit AllySearchBestUnit = null
    private real AllySearchBestLife = 0.00
    private boolean AllySearchIncludeSelf = false
    private unit CountSource = null
    private integer CountResult = 0
endglobals

private function DebugMsg takes string msg returns nothing
    if DebugMode then
        call BJDebugMsg("[AI] " + msg)
    endif
endfunction

private function EnsureState takes nothing returns nothing
    if UnitInstance == 0 then
        set UnitInstance = Table.create()
        set UniqueInstance = Table.create()
        set ClassByName = Table.create()
        set ProfileByName = Table.create()
        set ClassName = Table.create()
        set ClassCap = Table.create()
        set ClassActiveCount = Table.create()
        set ProfileName = Table.create()
        set ProfileClass = Table.create()
        set ProfileUnitType = Table.create()
        set ProfileCap = Table.create()
        set ProfileActiveCount = Table.create()
        set ProfileReviveDelay = Table.create()
        set ProfileNoManaRestore = Table.create()
        set ProfileAllowCompanionTravel = Table.create()
        set ProfileAutonomousDisabled = Table.create()
        set ProfileSpawnOwnerSlot = Table.create()
        set ProfileThinkTrigger = Table.create()
        set ProfileDeathTrigger = Table.create()
        set ProfileReviveTrigger = Table.create()
        set UnitTypeCap = Table.create()
        set UnitTypeActiveCount = Table.create()
        set InstanceUnit = Table.create()
        set InstanceClass = Table.create()
        set InstanceProfile = Table.create()
        set InstanceUnique = Table.create()
        set InstanceUnitType = Table.create()
        set InstanceState = Table.create()
        set InstancePreviousState = Table.create()
        set InstanceActiveSlot = Table.create()
        set InstanceAlive = Table.create()
        set InstanceTraveling = Table.create()
        set InstanceRandomManaged = Table.create()
        set InstanceHiddenByCap = Table.create()
        set InstanceCompanionControlled = Table.create()
        set InstanceNextThink = Table.create()
        set InstanceNextAbility = Table.create()
        set InstanceNextItem = Table.create()
        set InstanceNextChat = Table.create()
        set InstanceNextBark = Table.create()
        set InstanceRetreatUntil = Table.create()
        set InstanceTravelReturnAt = Table.create()
        set InstanceTravelReturnX = Table.create()
        set InstanceTravelReturnY = Table.create()
        set InstanceHomeX = Table.create()
        set InstanceHomeY = Table.create()
        set InstanceActionX = Table.create()
        set InstanceActionY = Table.create()
        set InstanceReviveTimer = Table.create()
        set ReviveTimerInstance = Table.create()
        set ProfileSpawnCount = Table.create()
        set ProfileSpawnX = Table.create()
        set ProfileSpawnY = Table.create()
        set ProfileRetreatCount = Table.create()
        set ProfileRetreatX = Table.create()
        set ProfileRetreatY = Table.create()
        set ProfileShopCount = Table.create()
        set ProfileShopX = Table.create()
        set ProfileShopY = Table.create()
        set ProfileShopItemCount = Table.create()
        set ProfileShopItemType = Table.create()
        set ProfileStartingAbilityCount = Table.create()
        set ProfileStartingAbilityId = Table.create()
        set ProfileAbilityCount = Table.create()
        set ProfileAbilityId = Table.create()
        set BarkLineCount = Table.create()
        set BarkLineText = Table.create()
        set BarkLineSound = Table.create()
        set ReplyLineCount = Table.create()
        set ReplyLineResponderProfile = Table.create()
        set ReplyLineText = Table.create()
        set ReplyLineSound = Table.create()
        set ReplyTimerSpeaker = Table.create()
        set ReplyTimerResponder = Table.create()
        set ReplyTimerText = Table.create()
        set ReplyTimerSound = Table.create()
        set TempAbilityUnit = Table.create()
        set TempAbilityRemove = Table.create()
        set TempAbilityRestore = Table.create()
    endif
    if TempGroup == null then
        set TempGroup = CreateGroup()
    endif
    if ClockTimer == null then
        set ClockTimer = CreateTimer()
        call TimerStart(ClockTimer, 1000000.00, false, null)
    endif
endfunction

private function GetNow takes nothing returns real
    call EnsureState()
    return TimerGetElapsed(ClockTimer)
endfunction

private function IsAliveUnit takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
endfunction

private function IsCompanionControlled takes unit whichUnit returns boolean
    if whichUnit == null then
        return false
    endif
    return udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group)
endfunction

private function GetLifePercent takes unit whichUnit returns real
    local real maxLife
    if whichUnit == null then
        return 0.00
    endif
    set maxLife = GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE)
    if maxLife <= 0.00 then
        return 0.00
    endif
    return GetWidgetLife(whichUnit) * 100.00 / maxLife
endfunction

private function GetManaPercent takes unit whichUnit returns real
    local real maxMana
    if whichUnit == null then
        return 0.00
    endif
    set maxMana = GetUnitState(whichUnit, UNIT_STATE_MAX_MANA)
    if maxMana <= 0.00 then
        return 100.00
    endif
    return GetUnitState(whichUnit, UNIT_STATE_MANA) * 100.00 / maxMana
endfunction

private function GetPointKey takes integer profileId, integer index returns integer
    return profileId * 100 + index
endfunction

private function GetBarkKey takes integer profileId, integer barkType returns integer
    return profileId * 100 + barkType
endfunction

private function GetBarkLineKey takes integer barkKey, integer index returns integer
    return barkKey * 100 + index
endfunction

private function GetInstanceBarkKey takes integer instanceId, integer barkType returns integer
    return instanceId * 100 + barkType
endfunction

private function GetReplyIndexKey takes integer replyKey, integer index returns integer
    return StringHash(I2S(replyKey) + ":" + I2S(index))
endfunction

private function ClearInstanceBarkCooldowns takes integer instanceId returns nothing
    local integer barkType = 1
    loop
        exitwhen barkType > AI_BARK_FAREWELL
        call InstanceNextBark.remove(GetInstanceBarkKey(instanceId, barkType))
        set barkType = barkType + 1
    endloop
endfunction

private function IsBarkNearPlayerHero takes unit speaker returns boolean
    if speaker == null then
        return false
    endif
    if udg_Nazgrek != null and IsAliveUnit(udg_Nazgrek) and IsUnitInRange(speaker, udg_Nazgrek, AI_BARK_AUDIBLE_RANGE) then
        return true
    endif
    if udg_Zulkis != null and IsAliveUnit(udg_Zulkis) and IsUnitInRange(speaker, udg_Zulkis, AI_BARK_AUDIBLE_RANGE) then
        return true
    endif
    return false
endfunction

private function IsCompanionOnlyBark takes integer barkType returns boolean
    if barkType == AI_BARK_GREET or barkType == AI_BARK_PASSIVE or barkType == AI_BARK_NORMAL then
        return true
    endif
    if barkType == AI_BARK_AGGRESSIVE or barkType == AI_BARK_HOLD or barkType == AI_BARK_DROP_ITEMS then
        return true
    endif
    if barkType == AI_BARK_KICKED or barkType == AI_BARK_ITEM_GIVEN or barkType == AI_BARK_COMPANION_DIES then
        return true
    endif
    return barkType == AI_BARK_IDLE or barkType == AI_BARK_MOVING or barkType == AI_BARK_FAREWELL
endfunction

private function IsDialogBlockingBark takes nothing returns boolean
    return udg_InCinematic or DialogSystem_IsSequenceActive()
endfunction

private function IsBarkContextAllowed takes unit speaker, integer barkType returns boolean
    if IsDialogBlockingBark() then
        return false
    endif
    if not IsBarkNearPlayerHero(speaker) then
        return false
    endif
    if IsCompanionOnlyBark(barkType) and not IsCompanionControlled(speaker) then
        return false
    endif
    return true
endfunction

private function GetBarkCooldown takes integer barkType returns real
    if barkType == AI_BARK_IDLE or barkType == AI_BARK_MOVING then
        return GetRandomReal(60.00, 120.00)
    elseif barkType == AI_BARK_ATTACKING or barkType == AI_BARK_CASTING or barkType == AI_BARK_KILLING then
        return GetRandomReal(12.00, 28.00)
    elseif barkType == AI_BARK_COMPANION_DIES then
        return GetRandomReal(25.00, 60.00)
    elseif IsCompanionOnlyBark(barkType) then
        return GetRandomReal(3.00, 8.00)
    endif
    return GetRandomReal(10.00, 20.00)
endfunction

private function IsCapAvailable takes integer cap, integer active returns boolean
    if cap <= 0 then
        return true
    endif
    return active < cap
endfunction

private function RegisterPlayerUnitEventAll takes trigger whichTrigger, playerunitevent whichEvent returns nothing
    local integer playerIndex = 0
    loop
        call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > MAX_PLAYER_INDEX
    endloop
endfunction

private function ClearEventContext takes nothing returns nothing
    set AI_EventInstance = 0
    set AI_EventUnit = null
    set AI_EventProfileId = 0
    set AI_EventClassId = 0
    set AI_EventState = AI_STATE_INACTIVE
    set AI_EventBarkType = 0
    set AI_EventTarget = null
    set AI_EventAbilityId = 0
endfunction

private function SetEventContext takes integer instanceId, unit whichUnit, integer barkType returns nothing
    set AI_EventInstance = instanceId
    set AI_EventUnit = whichUnit
    set AI_EventProfileId = InstanceProfile[instanceId]
    set AI_EventClassId = InstanceClass[instanceId]
    set AI_EventState = InstanceState[instanceId]
    set AI_EventBarkType = barkType
endfunction

private function RunProfileTrigger takes Table triggerTable, integer instanceId, unit whichUnit returns nothing
    local trigger profileTrigger
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set profileTrigger = triggerTable.trigger[profileId]
    if profileTrigger != null then
        call SetEventContext(instanceId, whichUnit, AI_EventBarkType)
        call TriggerExecute(profileTrigger)
        call ClearEventContext()
    endif
    set profileTrigger = null
endfunction

private function SetInstanceState takes integer instanceId, integer newState returns nothing
    if instanceId <= 0 then
        return
    endif
    if InstanceState[instanceId] != newState then
        set InstancePreviousState[instanceId] = InstanceState[instanceId]
        set InstanceState[instanceId] = newState
    endif
endfunction

private function AddActiveInstance takes integer instanceId returns nothing
    if instanceId <= 0 then
        return
    endif
    set ActiveCount = ActiveCount + 1
    set ActiveInstances[ActiveCount] = instanceId
    set InstanceActiveSlot[instanceId] = ActiveCount
endfunction

private function RemoveActiveInstance takes integer instanceId returns nothing
    local integer slot
    local integer moved
    if instanceId <= 0 then
        return
    endif
    set slot = InstanceActiveSlot[instanceId]
    if slot <= 0 or slot > ActiveCount then
        return
    endif
    set moved = ActiveInstances[ActiveCount]
    set ActiveInstances[slot] = moved
    set InstanceActiveSlot[moved] = slot
    set ActiveInstances[ActiveCount] = 0
    set ActiveCount = ActiveCount - 1
    call InstanceActiveSlot.remove(instanceId)
endfunction

private function IncrementCounts takes integer classId, integer profileId, integer unitTypeId returns nothing
    set ClassActiveCount[classId] = ClassActiveCount[classId] + 1
    set ProfileActiveCount[profileId] = ProfileActiveCount[profileId] + 1
    set UnitTypeActiveCount[unitTypeId] = UnitTypeActiveCount[unitTypeId] + 1
endfunction

private function DecrementCounts takes integer classId, integer profileId, integer unitTypeId returns nothing
    if ClassActiveCount[classId] > 0 then
        set ClassActiveCount[classId] = ClassActiveCount[classId] - 1
    endif
    if ProfileActiveCount[profileId] > 0 then
        set ProfileActiveCount[profileId] = ProfileActiveCount[profileId] - 1
    endif
    if UnitTypeActiveCount[unitTypeId] > 0 then
        set UnitTypeActiveCount[unitTypeId] = UnitTypeActiveCount[unitTypeId] - 1
    endif
endfunction

private function CanRegister takes integer profileId, integer uniqueId returns boolean
    local integer classId
    local integer unitTypeId
    if profileId <= 0 then
        return false
    endif
    set classId = ProfileClass[profileId]
    set unitTypeId = ProfileUnitType[profileId]
    if classId <= 0 or unitTypeId == 0 then
        return false
    endif
    if not IsCapAvailable(ClassCap[classId], ClassActiveCount[classId]) then
        return false
    endif
    if not IsCapAvailable(ProfileCap[profileId], ProfileActiveCount[profileId]) then
        return false
    endif
    if not IsCapAvailable(UnitTypeCap[unitTypeId], UnitTypeActiveCount[unitTypeId]) then
        return false
    endif
    if uniqueId != 0 and UniqueInstance[uniqueId] != 0 then
        return false
    endif
    return true
endfunction

private function GetGraveyardRect takes integer graveyardId returns rect
    if graveyardId == 2 then
        return gg_rct_Graveyard02
    elseif graveyardId == 3 then
        return gg_rct_Graveyard03
    elseif graveyardId == 4 then
        return gg_rct_Graveyard04
    elseif graveyardId == 5 then
        return gg_rct_Graveyard05
    elseif graveyardId == 6 then
        return gg_rct_Graveyard06
    elseif graveyardId == 7 then
        return gg_rct_Graveyard07
    elseif graveyardId == 8 then
        return gg_rct_Graveyard08
    elseif graveyardId == 9 then
        return gg_rct_Graveyard09
    endif
    return gg_rct_Graveyard
endfunction

private function GetReviveGraveyardId takes unit whichUnit returns integer
    if whichUnit != null and IsCompanionControlled(whichUnit) and udg_GraveyardSelect > 0 then
        return udg_GraveyardSelect
    endif
    return GetRandomInt(1, 9)
endfunction

private function GetDisplayName takes unit whichUnit returns string
    if whichUnit == null then
        return ""
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroProperName(whichUnit)
    endif
    return GetUnitName(whichUnit)
endfunction

private function EstimateDialogDuration takes string text returns real
    local real duration = I2R(StringLength(text)) / 13.00
    if duration < 1.25 then
        set duration = 1.25
    endif
    return duration
endfunction

private function UnlockDialog takes nothing returns nothing
    set udg_CompanionDialogueActive = false
endfunction

private function RestoreTemporaryAbility takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit whichUnit = TempAbilityUnit.unit[timerId]
    local integer removeAbilityId = TempAbilityRemove[timerId]
    local integer restoreAbilityId = TempAbilityRestore[timerId]
    if whichUnit != null then
        if removeAbilityId != 0 then
            call UnitRemoveAbility(whichUnit, removeAbilityId)
        endif
        if restoreAbilityId != 0 and GetUnitAbilityLevel(whichUnit, restoreAbilityId) <= 0 then
            call UnitAddAbility(whichUnit, restoreAbilityId)
        endif
    endif
    call TempAbilityUnit.unit.remove(timerId)
    call TempAbilityRemove.remove(timerId)
    call TempAbilityRestore.remove(timerId)
    call DestroyTimer(expired)
    set whichUnit = null
    set expired = null
endfunction

private function ClosestEnemyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    local real dx
    local real dy
    local real distance
    if SearchSource != null and IsAliveUnit(enumUnit) and IsUnitEnemy(enumUnit, GetOwningPlayer(SearchSource)) then
        set dx = GetUnitX(enumUnit) - GetUnitX(SearchSource)
        set dy = GetUnitY(enumUnit) - GetUnitY(SearchSource)
        set distance = dx * dx + dy * dy
        if SearchBestUnit == null or distance < SearchBestDistance then
            set SearchBestUnit = enumUnit
            set SearchBestDistance = distance
        endif
    endif
    set enumUnit = null
endfunction

private function LowestHealthAllyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    local real lifePercent
    if AllySearchSource != null and IsAliveUnit(enumUnit) and IsUnitAlly(enumUnit, GetOwningPlayer(AllySearchSource)) then
        if AllySearchIncludeSelf or enumUnit != AllySearchSource then
            set lifePercent = GetLifePercent(enumUnit)
            if AllySearchBestUnit == null or lifePercent < AllySearchBestLife then
                set AllySearchBestUnit = enumUnit
                set AllySearchBestLife = lifePercent
            endif
        endif
    endif
    set enumUnit = null
endfunction

private function CountEnemyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    if CountSource != null and IsAliveUnit(enumUnit) and IsUnitEnemy(enumUnit, GetOwningPlayer(CountSource)) then
        set CountResult = CountResult + 1
    endif
    set enumUnit = null
endfunction

private function MoveAwayFromPoint takes unit whichUnit, real originX, real originY, real distance returns nothing
    local real dx
    local real dy
    local real angle
    local real x
    local real y
    if whichUnit == null then
        return
    endif
    set dx = GetUnitX(whichUnit) - originX
    set dy = GetUnitY(whichUnit) - originY
    if dx == 0.00 and dy == 0.00 then
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif
    set x = GetUnitX(whichUnit) + distance * Cos(angle)
    set y = GetUnitY(whichUnit) + distance * Sin(angle)
    call IssuePointOrder(whichUnit, "move", x, y)
endfunction

private function BeginWander takes integer instanceId, unit whichUnit returns nothing
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set x = GetRandomReal(GetRectMinX(bj_mapInitialPlayableArea), GetRectMaxX(bj_mapInitialPlayableArea))
    set y = GetRandomReal(GetRectMinY(bj_mapInitialPlayableArea), GetRectMaxY(bj_mapInitialPlayableArea))
    call SetInstanceState(instanceId, AI_STATE_WANDER)
    call IssuePointOrder(whichUnit, "attack", x, y)
endfunction

private function BeginCombatRetreat takes integer instanceId, unit whichUnit returns nothing
    local real angle
    local real distance
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    set distance = GetRandomReal(400.00, 1000.00)
    set x = GetUnitX(whichUnit) + distance * Cos(angle)
    set y = GetUnitY(whichUnit) + distance * Sin(angle)
    call SetInstanceState(instanceId, AI_STATE_RETREAT_COMBAT)
    set InstanceRetreatUntil.real[instanceId] = GetNow() + AI_RETREAT_COMBAT_TIME
    call IssuePointOrder(whichUnit, "move", x, y)
endfunction

private function BeginBaseRetreat takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer count
    local integer index
    local integer key
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileRetreatCount[profileId]
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set x = ProfileRetreatX.real[key]
        set y = ProfileRetreatY.real[key]
    else
        set x = InstanceHomeX.real[instanceId]
        set y = InstanceHomeY.real[instanceId]
    endif
    call SetInstanceState(instanceId, AI_STATE_RETREAT_BASE)
    set InstanceRetreatUntil.real[instanceId] = GetNow() + AI_RETREAT_BASE_TIME
    call IssuePointOrder(whichUnit, "move", x, y)
endfunction

private function IsNearActionPoint takes integer instanceId, unit whichUnit, real range returns boolean
    local real dx
    local real dy
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set dx = GetUnitX(whichUnit) - InstanceActionX.real[instanceId]
    set dy = GetUnitY(whichUnit) - InstanceActionY.real[instanceId]
    return dx * dx + dy * dy <= range * range
endfunction

private function FinishBuyState takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer count
    local integer index
    local integer key
    local item boughtItem
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileShopItemCount[profileId]
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set boughtItem = CreateItem(ProfileShopItemType[key], GetUnitX(whichUnit), GetUnitY(whichUnit))
        if boughtItem != null then
            call UnitAddItem(whichUnit, boughtItem)
        endif
    endif
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    set boughtItem = null
endfunction

private function DropInventoryItem takes unit whichUnit returns boolean
    local integer slot = GetRandomInt(0, bj_MAX_INVENTORY - 1)
    local integer checked = 0
    local item slotItem
    if whichUnit == null then
        return false
    endif
    loop
        exitwhen checked >= bj_MAX_INVENTORY
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null then
            call UnitDropItemPoint(whichUnit, slotItem, GetUnitX(whichUnit), GetUnitY(whichUnit))
            set slotItem = null
            return true
        endif
        set slot = slot + 1
        if slot >= bj_MAX_INVENTORY then
            set slot = 0
        endif
        set checked = checked + 1
    endloop
    set slotItem = null
    return false
endfunction

private function IsRandomManagedVisible takes integer instanceId returns boolean
    local unit whichUnit
    local boolean result = false
    if instanceId <= 0 or not InstanceRandomManaged.boolean[instanceId] or InstanceHiddenByCap.boolean[instanceId] or InstanceTraveling.boolean[instanceId] then
        return false
    endif
    set whichUnit = InstanceUnit.unit[instanceId]
    set result = whichUnit != null and IsAliveUnit(whichUnit) and not IsUnitHidden(whichUnit)
    set whichUnit = null
    return result
endfunction

private function CountRandomManagedVisible takes nothing returns integer
    local integer index = 1
    local integer count = 0
    loop
        exitwhen index > ActiveCount
        if IsRandomManagedVisible(ActiveInstances[index]) then
            set count = count + 1
        endif
        set index = index + 1
    endloop
    return count
endfunction

private function CanShowRandomManaged takes integer instanceId returns boolean
    local integer visible
    if instanceId <= 0 or not InstanceRandomManaged.boolean[instanceId] then
        return true
    endif
    if RandomSpawnActiveCap <= 0 then
        return true
    endif
    set visible = CountRandomManagedVisible()
    if IsRandomManagedVisible(instanceId) then
        return visible <= RandomSpawnActiveCap
    endif
    return visible < RandomSpawnActiveCap
endfunction

private function HideRandomManagedByCap takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null or not InstanceRandomManaged.boolean[instanceId] then
        return
    endif
    set InstanceHiddenByCap.boolean[instanceId] = true
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call IssueImmediateOrder(whichUnit, "stop")
    call PauseUnit(whichUnit, true)
    call ShowUnit(whichUnit, false)
endfunction

private function ShowRandomManagedFromCap takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null or not InstanceRandomManaged.boolean[instanceId] then
        return
    endif
    set InstanceHiddenByCap.boolean[instanceId] = false
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call ShowUnit(whichUnit, true)
    call PauseUnit(whichUnit, false)
endfunction

private function BeginBuyState takes integer instanceId, unit whichUnit returns boolean
    local integer profileId
    local integer count
    local integer index
    local integer key
    if instanceId <= 0 or whichUnit == null or IsCompanionControlled(whichUnit) then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileShopCount[profileId]
    if count <= 0 then
        return false
    endif
    set index = GetRandomInt(1, count)
    set key = GetPointKey(profileId, index)
    set InstanceActionX.real[instanceId] = ProfileShopX.real[key]
    set InstanceActionY.real[instanceId] = ProfileShopY.real[key]
    call SetInstanceState(instanceId, AI_STATE_BUY)
    call IssuePointOrder(whichUnit, "move", InstanceActionX.real[instanceId], InstanceActionY.real[instanceId])
    return true
endfunction

private function BeginSellState takes integer instanceId, unit whichUnit returns boolean
    if instanceId <= 0 or whichUnit == null or IsCompanionControlled(whichUnit) then
        return false
    endif
    call SetInstanceState(instanceId, AI_STATE_SELL)
    return true
endfunction

private function BeginCampState takes integer instanceId, unit whichUnit, real duration returns boolean
    if instanceId <= 0 or whichUnit == null or duration <= 0.00 or IsCompanionControlled(whichUnit) then
        return false
    endif
    call SetInstanceState(instanceId, AI_STATE_CAMP)
    set InstanceRetreatUntil.real[instanceId] = GetNow() + duration
    call IssueImmediateOrder(whichUnit, "stop")
    return true
endfunction

private function ApplyStartingAbilities takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer count
    local integer index = 1
    local integer abilityId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileStartingAbilityCount[profileId]
    loop
        exitwhen index > count
        set abilityId = ProfileStartingAbilityId[GetPointKey(profileId, index)]
        if abilityId != 0 and GetUnitAbilityLevel(whichUnit, abilityId) <= 0 then
            call UnitAddAbility(whichUnit, abilityId)
        endif
        set index = index + 1
    endloop
endfunction

private function LearnRandomProfileAbility takes unit whichUnit, integer profileId returns nothing
    local integer count
    local integer abilityId
    if whichUnit == null or profileId <= 0 then
        return
    endif
    set count = ProfileAbilityCount[profileId]
    if count <= 0 then
        return
    endif
    set abilityId = ProfileAbilityId[GetPointKey(profileId, GetRandomInt(1, count))]
    if abilityId == 0 then
        return
    endif
    if GetUnitAbilityLevel(whichUnit, abilityId) <= 0 then
        call UnitAddAbility(whichUnit, abilityId)
    else
        call IncUnitAbilityLevel(whichUnit, abilityId)
    endif
endfunction

private function ReviveExpired takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local integer instanceId = ReviveTimerInstance[timerId]
    local unit whichUnit = InstanceUnit.unit[instanceId]
    local rect graveyardRect
    local integer graveyardId
    local real x
    local real y
    local integer profileId
    if instanceId > 0 and whichUnit != null and GetUnitTypeId(whichUnit) != 0 then
        set profileId = InstanceProfile[instanceId]
        set graveyardId = GetReviveGraveyardId(whichUnit)
        set graveyardRect = GetGraveyardRect(graveyardId)
        set x = GetRectCenterX(graveyardRect)
        set y = GetRectCenterY(graveyardRect)
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
            call ReviveHero(whichUnit, x, y, true)
        else
            call SetUnitPosition(whichUnit, x, y)
            call ShowUnit(whichUnit, true)
            call PauseUnit(whichUnit, false)
        endif
        call SetWidgetLife(whichUnit, GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE) * 0.50)
        if not ProfileNoManaRestore.boolean[profileId] then
            call SetUnitState(whichUnit, UNIT_STATE_MANA, GetUnitState(whichUnit, UNIT_STATE_MAX_MANA) * 0.50)
        else
            call SetUnitState(whichUnit, UNIT_STATE_MANA, 0.00)
        endif
        set InstanceAlive.boolean[instanceId] = true
        call SetInstanceState(instanceId, AI_STATE_IDLE)
        if InstanceRandomManaged.boolean[instanceId] then
            if CanShowRandomManaged(instanceId) then
                call ShowRandomManagedFromCap(instanceId, whichUnit)
            else
                call HideRandomManagedByCap(instanceId, whichUnit)
            endif
        endif
        if IsCompanionControlled(whichUnit) and not udg_InCinematic then
            call PingMinimapEx(x, y, 1.00, 255, 0, 0, true)
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 5.00, "|cffffff00|r" + GetDisplayName(whichUnit) + " |cffffffffis |r|cff00ff00revived.|r")
        endif
        call RunProfileTrigger(ProfileReviveTrigger, instanceId, whichUnit)
    endif
    call ReviveTimerInstance.remove(timerId)
    call InstanceReviveTimer.timer.remove(instanceId)
    call DestroyTimer(expired)
    set whichUnit = null
    set graveyardRect = null
    set expired = null
endfunction

private function StartReviveTimer takes integer instanceId, unit whichUnit returns nothing
    local timer reviveTimer
    local real reviveDelay
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set reviveDelay = ProfileReviveDelay.real[profileId]
    if reviveDelay <= 0.00 then
        set reviveDelay = AI_DEFAULT_REVIVE_DELAY
    endif
    set reviveTimer = CreateTimer()
    set InstanceReviveTimer.timer[instanceId] = reviveTimer
    set ReviveTimerInstance[GetHandleId(reviveTimer)] = instanceId
    call TimerStart(reviveTimer, reviveDelay, false, function ReviveExpired)
    set reviveTimer = null
endfunction

private function CompleteTravel takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    call SetUnitPosition(whichUnit, InstanceTravelReturnX.real[instanceId], InstanceTravelReturnY.real[instanceId])
    set InstanceTraveling.boolean[instanceId] = false
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    if CanShowRandomManaged(instanceId) then
        if InstanceRandomManaged.boolean[instanceId] then
            call ShowRandomManagedFromCap(instanceId, whichUnit)
        else
            call PauseUnit(whichUnit, false)
            call ShowUnit(whichUnit, true)
        endif
    else
        call HideRandomManagedByCap(instanceId, whichUnit)
    endif
endfunction

public function RegisterClass takes string className returns integer
    local integer key
    local integer classId
    call EnsureState()
    if className == "" then
        return 0
    endif
    set key = StringHash(className)
    set classId = ClassByName[key]
    if classId > 0 then
        return classId
    endif
    set classId = NextClassId
    set NextClassId = NextClassId + 1
    set ClassByName[key] = classId
    set ClassName.string[classId] = className
    return classId
endfunction

public function RegisterProfile takes integer classId, integer unitTypeId, string profileName returns integer
    local integer key
    local integer profileId
    call EnsureState()
    if classId <= 0 or unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set key = StringHash(profileName)
    set profileId = ProfileByName[key]
    if profileId > 0 then
        return profileId
    endif
    set profileId = NextProfileId
    set NextProfileId = NextProfileId + 1
    set ProfileByName[key] = profileId
    set ProfileClass[profileId] = classId
    set ProfileUnitType[profileId] = unitTypeId
    set ProfileName.string[profileId] = profileName
    set ProfileReviveDelay.real[profileId] = AI_DEFAULT_REVIVE_DELAY
    return profileId
endfunction

public function SetClassCap takes integer classId, integer cap returns nothing
    call EnsureState()
    set ClassCap[classId] = cap
endfunction

public function SetProfileCap takes integer profileId, integer cap returns nothing
    call EnsureState()
    set ProfileCap[profileId] = cap
endfunction

public function SetUnitTypeCap takes integer unitTypeId, integer cap returns nothing
    call EnsureState()
    set UnitTypeCap[unitTypeId] = cap
endfunction

public function SetProfileReviveDelay takes integer profileId, real delay returns nothing
    call EnsureState()
    set ProfileReviveDelay.real[profileId] = delay
endfunction

public function SetProfileNoManaRestore takes integer profileId, boolean noMana returns nothing
    call EnsureState()
    set ProfileNoManaRestore.boolean[profileId] = noMana
endfunction

public function SetProfileAllowCompanionTravel takes integer profileId, boolean allowed returns nothing
    call EnsureState()
    set ProfileAllowCompanionTravel.boolean[profileId] = allowed
endfunction

public function SetProfileAutonomous takes integer profileId, boolean enabled returns nothing
    call EnsureState()
    set ProfileAutonomousDisabled.boolean[profileId] = not enabled
endfunction

public function SetProfileSpawnOwner takes integer profileId, player owner returns nothing
    call EnsureState()
    if profileId <= 0 or owner == null then
        return
    endif
    set ProfileSpawnOwnerSlot[profileId] = GetPlayerId(owner) + 1
endfunction

public function SetRandomSpawnOwner takes player owner returns nothing
    call EnsureState()
    if owner == null then
        return
    endif
    set RandomSpawnOwnerIndex = GetPlayerId(owner)
endfunction

public function SetRandomSpawnHardCap takes integer cap returns nothing
    call EnsureState()
    set RandomSpawnHardCap = cap
endfunction

public function SetRandomSpawnActiveCap takes integer cap returns nothing
    call EnsureState()
    set RandomSpawnActiveCap = cap
endfunction

public function AddRandomSpawnProfile takes integer profileId returns nothing
    local integer index = 1
    call EnsureState()
    if profileId <= 0 or ProfileUnitType[profileId] == 0 then
        return
    endif
    loop
        exitwhen index > RandomSpawnProfileCount
        if RandomSpawnProfiles[index] == profileId then
            return
        endif
        set index = index + 1
    endloop
    if RandomSpawnProfileCount >= MAX_RANDOM_SPAWN_PROFILES then
        call BJDebugMsg("[AI] ERROR: MAX_RANDOM_SPAWN_PROFILES reached.")
        return
    endif
    set RandomSpawnProfileCount = RandomSpawnProfileCount + 1
    set RandomSpawnProfiles[RandomSpawnProfileCount] = profileId
endfunction

public function SetProfileThinkCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileThinkTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileThinkTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function SetProfileDeathCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileDeathTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileDeathTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function SetProfileReviveCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileReviveTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileReviveTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function AddProfileSpawnPoint takes integer profileId, real x, real y returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set count = ProfileSpawnCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileSpawnCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileSpawnX.real[key] = x
    set ProfileSpawnY.real[key] = y
endfunction

public function AddProfileSpawnRect takes integer profileId, rect whichRect returns nothing
    if whichRect == null then
        return
    endif
    call AI_AddProfileSpawnPoint(profileId, GetRectCenterX(whichRect), GetRectCenterY(whichRect))
endfunction

public function AddProfileRetreatPoint takes integer profileId, real x, real y returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set count = ProfileRetreatCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileRetreatCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileRetreatX.real[key] = x
    set ProfileRetreatY.real[key] = y
endfunction

public function AddProfileRetreatRect takes integer profileId, rect whichRect returns nothing
    if whichRect == null then
        return
    endif
    call AI_AddProfileRetreatPoint(profileId, GetRectCenterX(whichRect), GetRectCenterY(whichRect))
endfunction

public function AddProfileShopPoint takes integer profileId, real x, real y returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set count = ProfileShopCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileShopCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileShopX.real[key] = x
    set ProfileShopY.real[key] = y
endfunction

public function AddProfileShopUnit takes integer profileId, unit shopUnit returns nothing
    if shopUnit == null then
        return
    endif
    call AI_AddProfileShopPoint(profileId, GetUnitX(shopUnit), GetUnitY(shopUnit))
endfunction

public function AddProfileShopItem takes integer profileId, integer itemTypeId returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 or itemTypeId == 0 then
        return
    endif
    set count = ProfileShopItemCount[profileId]
    if count >= MAX_PROFILE_ITEMS then
        return
    endif
    set count = count + 1
    set ProfileShopItemCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileShopItemType[key] = itemTypeId
endfunction

public function AddDefaultShopItems takes integer profileId returns nothing
    call AI_AddProfileShopItem(profileId, ITEM_MINOR_MANA_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_MANA_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_MAJOR_MANA_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_MINOR_HEALING_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_HEALING_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_MAJOR_HEALING_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_SPRING_WATER)
    call AI_AddProfileShopItem(profileId, ITEM_HEALING_SALVE)
    call AI_AddProfileShopItem(profileId, ITEM_GREATER_HEALING_SALVE)
endfunction

public function AddProfileStartingAbility takes integer profileId, integer abilityId returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 or abilityId == 0 then
        return
    endif
    set count = ProfileStartingAbilityCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileStartingAbilityCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileStartingAbilityId[key] = abilityId
endfunction

public function AddProfileAbility takes integer profileId, integer abilityId returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 or abilityId == 0 then
        return
    endif
    set count = ProfileAbilityCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileAbilityCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileAbilityId[key] = abilityId
endfunction

public function RegisterBarkLine takes integer profileId, integer barkType, string text, string soundKey returns nothing
    local integer barkKey
    local integer count
    local integer index
    local integer lineKey
    call EnsureState()
    if profileId <= 0 or barkType <= 0 or text == "" then
        return
    endif
    set barkKey = GetBarkKey(profileId, barkType)
    set count = BarkLineCount[barkKey]
    set index = 1
    loop
        exitwhen index > count
        set lineKey = GetBarkLineKey(barkKey, index)
        if soundKey != "" and BarkLineSound.string[lineKey] == soundKey then
            set BarkLineText.string[lineKey] = text
            return
        endif
        set index = index + 1
    endloop
    if count >= MAX_BARK_LINES then
        return
    endif
    set count = count + 1
    set BarkLineCount[barkKey] = count
    set lineKey = GetBarkLineKey(barkKey, count)
    set BarkLineText.string[lineKey] = text
    set BarkLineSound.string[lineKey] = soundKey
endfunction

public function RegisterBarkSequence takes integer profileId, integer barkType, string text, string soundPrefix, integer first, integer last returns nothing
    local integer index = first
    loop
        exitwhen index > last
        call AI_RegisterBarkLine(profileId, barkType, text, soundPrefix + I2S(index))
        set index = index + 1
    endloop
endfunction

public function RegisterBarkReply takes string primarySoundKey, integer responderProfileId, string text, string replySoundKey returns nothing
    local integer replyKey
    local integer count
    local integer index
    local integer lineKey
    call EnsureState()
    if primarySoundKey == "" or responderProfileId <= 0 or text == "" or replySoundKey == "" then
        return
    endif
    set replyKey = StringHash(primarySoundKey)
    set count = ReplyLineCount[replyKey]
    set index = 1
    loop
        exitwhen index > count
        set lineKey = GetReplyIndexKey(replyKey, index)
        if ReplyLineResponderProfile[lineKey] == responderProfileId and ReplyLineSound.string[lineKey] == replySoundKey then
            set ReplyLineText.string[lineKey] = text
            return
        endif
        set index = index + 1
    endloop
    if count >= MAX_BARK_LINES then
        return
    endif
    set count = count + 1
    set ReplyLineCount[replyKey] = count
    set lineKey = GetReplyIndexKey(replyKey, count)
    set ReplyLineResponderProfile[lineKey] = responderProfileId
    set ReplyLineText.string[lineKey] = text
    set ReplyLineSound.string[lineKey] = replySoundKey
endfunction

public function RegisterBarkReplySequence takes string primarySoundPrefix, integer first, integer last, integer responderProfileId, string text, string replySoundPrefix returns nothing
    local integer index = first
    loop
        exitwhen index > last
        call AI_RegisterBarkReply(primarySoundPrefix + I2S(index), responderProfileId, text, replySoundPrefix + I2S(index))
        set index = index + 1
    endloop
endfunction

public function RegisterBarkReplySequenceSuffix takes string primarySoundPrefix, integer first, integer last, integer responderProfileId, string text, string replySoundPrefix, string replySoundSuffix returns nothing
    local integer index = first
    loop
        exitwhen index > last
        call AI_RegisterBarkReply(primarySoundPrefix + I2S(index), responderProfileId, text, replySoundPrefix + I2S(index) + replySoundSuffix)
        set index = index + 1
    endloop
endfunction

private function StartDialogUnlock takes real delay returns nothing
    if delay < 0.01 then
        set delay = 0.01
    endif
    if DialogUnlockTimer == null then
        set DialogUnlockTimer = CreateTimer()
    endif
    call TimerStart(DialogUnlockTimer, delay, false, function UnlockDialog)
endfunction

private function FindCompanionResponder takes integer profileId, unit speaker returns unit
    local integer i = 1
    local integer instanceId
    local unit responder
    loop
        exitwhen i > ActiveCount
        set instanceId = ActiveInstances[i]
        set responder = InstanceUnit.unit[instanceId]
        if responder != null and responder != speaker and InstanceProfile[instanceId] == profileId then
            if IsAliveUnit(responder) and IsCompanionControlled(responder) and IsBarkNearPlayerHero(responder) then
                return responder
            endif
        endif
        set i = i + 1
    endloop
    set responder = null
    return null
endfunction

private function PlayBarkReply takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit speaker = ReplyTimerSpeaker.unit[timerId]
    local unit responder = ReplyTimerResponder.unit[timerId]
    local string text = ReplyTimerText.string[timerId]
    local string soundKey = ReplyTimerSound.string[timerId]
    local integer responderInstance
    local real now = GetNow()
    local real duration
    if responder != null and IsAliveUnit(responder) and IsCompanionControlled(responder) and IsBarkNearPlayerHero(responder) and not IsDialogBlockingBark() then
        if speaker != null and IsAliveUnit(speaker) then
            call DialogSystem_MakeFaceEachOther(speaker, responder, 0.50)
        endif
        call DialogSystem_PlayLine(responder, "", text, soundKey, true)
        set duration = udg_ExSoundDuration
        if duration <= 0.00 then
            set duration = EstimateDialogDuration(text)
        endif
        set responderInstance = UnitInstance[GetHandleId(responder)]
        if responderInstance > 0 then
            set InstanceNextChat.real[responderInstance] = now + duration + AI_DIALOG_UNLOCK_PAD
        endif
        set NextGlobalBark = now + duration + AI_BARK_GLOBAL_GAP
        call StartDialogUnlock(duration + AI_DIALOG_UNLOCK_PAD)
    else
        call StartDialogUnlock(AI_DIALOG_UNLOCK_PAD)
    endif
    call ReplyTimerSpeaker.remove(timerId)
    call ReplyTimerResponder.remove(timerId)
    call ReplyTimerText.remove(timerId)
    call ReplyTimerSound.remove(timerId)
    call DestroyTimer(expired)
    set expired = null
    set speaker = null
    set responder = null
endfunction

private function ScheduleBarkReply takes unit speaker, string primarySoundKey, real delay returns boolean
    local integer replyKey
    local integer count
    local integer attempts
    local integer index
    local integer lineKey
    local integer responderProfileId
    local unit responder
    local timer replyTimer
    local integer timerId
    if primarySoundKey == "" then
        return false
    endif
    set replyKey = StringHash(primarySoundKey)
    set count = ReplyLineCount[replyKey]
    if count <= 0 then
        return false
    endif
    set attempts = count
    set index = GetRandomInt(1, count)
    loop
        exitwhen attempts <= 0
        set lineKey = GetReplyIndexKey(replyKey, index)
        set responderProfileId = ReplyLineResponderProfile[lineKey]
        set responder = FindCompanionResponder(responderProfileId, speaker)
        if responder != null then
            set replyTimer = CreateTimer()
            set timerId = GetHandleId(replyTimer)
            set ReplyTimerSpeaker.unit[timerId] = speaker
            set ReplyTimerResponder.unit[timerId] = responder
            set ReplyTimerText.string[timerId] = ReplyLineText.string[lineKey]
            set ReplyTimerSound.string[timerId] = ReplyLineSound.string[lineKey]
            call TimerStart(replyTimer, delay, false, function PlayBarkReply)
            set replyTimer = null
            set responder = null
            return true
        endif
        set index = index + 1
        if index > count then
            set index = 1
        endif
        set attempts = attempts - 1
    endloop
    set responder = null
    return false
endfunction

public function GetInstance takes unit whichUnit returns integer
    call EnsureState()
    if whichUnit == null then
        return 0
    endif
    return UnitInstance[GetHandleId(whichUnit)]
endfunction

public function GetUnitByInstance takes integer instanceId returns unit
    call EnsureState()
    return InstanceUnit.unit[instanceId]
endfunction

public function GetUnitByUniqueId takes integer uniqueId returns unit
    local integer instanceId
    call EnsureState()
    if uniqueId == 0 then
        return null
    endif
    set instanceId = UniqueInstance[uniqueId]
    if instanceId <= 0 then
        return null
    endif
    return InstanceUnit.unit[instanceId]
endfunction

public function GetProfileId takes unit whichUnit returns integer
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return 0
    endif
    return InstanceProfile[instanceId]
endfunction

public function GetClassId takes unit whichUnit returns integer
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return 0
    endif
    return InstanceClass[instanceId]
endfunction

public function GetState takes unit whichUnit returns integer
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return AI_STATE_INACTIVE
    endif
    return InstanceState[instanceId]
endfunction

public function BeginBuy takes unit whichUnit returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return false
    endif
    return BeginBuyState(instanceId, whichUnit)
endfunction

public function BeginSell takes unit whichUnit returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return false
    endif
    return BeginSellState(instanceId, whichUnit)
endfunction

public function BeginCamp takes unit whichUnit, real duration returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return false
    endif
    return BeginCampState(instanceId, whichUnit, duration)
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    local integer existing
    local integer instanceId
    local integer classId
    local integer unitTypeId
    local integer customValue
    call EnsureState()
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or profileId <= 0 then
        return 0
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    if ProfileUnitType[profileId] != unitTypeId then
        call DebugMsg("Registration rejected because unit type does not match profile " + I2S(profileId))
        return 0
    endif
    set existing = UnitInstance[GetHandleId(whichUnit)]
    if existing > 0 then
        return existing
    endif
    if not CanRegister(profileId, uniqueId) then
        call DebugMsg("Cap prevented registration for profile " + I2S(profileId))
        return 0
    endif
    if NextInstanceId > MAX_AI_INSTANCES then
        call BJDebugMsg("[AI] ERROR: MAX_AI_INSTANCES reached.")
        return 0
    endif
    set classId = ProfileClass[profileId]
    set instanceId = NextInstanceId
    set NextInstanceId = NextInstanceId + 1
    set UnitInstance[GetHandleId(whichUnit)] = instanceId
    set InstanceUnit.unit[instanceId] = whichUnit
    set InstanceClass[instanceId] = classId
    set InstanceProfile[instanceId] = profileId
    set InstanceUnique[instanceId] = uniqueId
    set InstanceUnitType[instanceId] = unitTypeId
    set InstanceAlive.boolean[instanceId] = IsAliveUnit(whichUnit)
    set InstanceRandomManaged.boolean[instanceId] = false
    set InstanceHiddenByCap.boolean[instanceId] = false
    set InstanceHomeX.real[instanceId] = GetUnitX(whichUnit)
    set InstanceHomeY.real[instanceId] = GetUnitY(whichUnit)
    set InstanceNextThink.real[instanceId] = GetNow() + GetRandomReal(0.00, AI_DEFAULT_THINK_MAX)
    set InstanceNextAbility.real[instanceId] = GetNow() + GetRandomReal(0.00, AI_DEFAULT_ABILITY_GAP)
    set InstanceNextItem.real[instanceId] = GetNow() + GetRandomReal(1.00, 3.00)
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call AddActiveInstance(instanceId)
    call IncrementCounts(classId, profileId, unitTypeId)
    if uniqueId != 0 then
        set UniqueInstance[uniqueId] = instanceId
    endif
    call ApplyStartingAbilities(instanceId, whichUnit)
    set customValue = GetUnitUserData(whichUnit)
    if customValue > 0 then
        set udg_UnitHider_ReferenceUnits[customValue] = whichUnit
    endif
    return instanceId
endfunction

public function UnregisterUnit takes unit whichUnit returns nothing
    local integer instanceId
    local integer classId
    local integer profileId
    local integer unitTypeId
    local integer uniqueId
    local timer reviveTimer
    if whichUnit == null then
        return
    endif
    call EnsureState()
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 then
        return
    endif
    set classId = InstanceClass[instanceId]
    set profileId = InstanceProfile[instanceId]
    set unitTypeId = InstanceUnitType[instanceId]
    set uniqueId = InstanceUnique[instanceId]
    set reviveTimer = InstanceReviveTimer.timer[instanceId]
    if InstanceRandomManaged.boolean[instanceId] and RandomSpawnManagedCount > 0 then
        set RandomSpawnManagedCount = RandomSpawnManagedCount - 1
    endif
    if reviveTimer != null then
        call ReviveTimerInstance.remove(GetHandleId(reviveTimer))
        call PauseTimer(reviveTimer)
        call DestroyTimer(reviveTimer)
        call InstanceReviveTimer.timer.remove(instanceId)
    endif
    call RemoveActiveInstance(instanceId)
    call DecrementCounts(classId, profileId, unitTypeId)
    if uniqueId != 0 and UniqueInstance[uniqueId] == instanceId then
        call UniqueInstance.remove(uniqueId)
    endif
    call UnitInstance.remove(GetHandleId(whichUnit))
    call InstanceUnit.unit.remove(instanceId)
    call InstanceClass.remove(instanceId)
    call InstanceProfile.remove(instanceId)
    call InstanceUnique.remove(instanceId)
    call InstanceUnitType.remove(instanceId)
    call InstanceState.remove(instanceId)
    call InstancePreviousState.remove(instanceId)
    call InstanceAlive.remove(instanceId)
    call InstanceTraveling.remove(instanceId)
    call InstanceRandomManaged.remove(instanceId)
    call InstanceHiddenByCap.remove(instanceId)
    call InstanceCompanionControlled.remove(instanceId)
    call InstanceNextThink.remove(instanceId)
    call InstanceNextAbility.remove(instanceId)
    call InstanceNextItem.remove(instanceId)
    call InstanceNextChat.remove(instanceId)
    call ClearInstanceBarkCooldowns(instanceId)
    call InstanceRetreatUntil.remove(instanceId)
    call InstanceTravelReturnAt.remove(instanceId)
    call InstanceTravelReturnX.remove(instanceId)
    call InstanceTravelReturnY.remove(instanceId)
    call InstanceHomeX.remove(instanceId)
    call InstanceHomeY.remove(instanceId)
    call InstanceActionX.remove(instanceId)
    call InstanceActionY.remove(instanceId)
    set reviveTimer = null
endfunction

public function SpawnProfile takes integer profileId, player owner, real x, real y, real facing, integer uniqueId returns unit
    local unit created
    local integer unitTypeId
    call EnsureState()
    if profileId <= 0 or owner == null or not CanRegister(profileId, uniqueId) then
        return null
    endif
    set unitTypeId = ProfileUnitType[profileId]
    if unitTypeId == 0 then
        return null
    endif
    set created = CreateUnit(owner, unitTypeId, x, y, facing)
    if created != null then
        call AI_RegisterUnit(created, profileId, uniqueId)
    endif
    return created
endfunction

public function SpawnProfileAtRandomPoint takes integer profileId, player owner, real facing, integer uniqueId returns unit
    local integer count
    local integer index
    local integer key
    call EnsureState()
    set count = ProfileSpawnCount[profileId]
    if count <= 0 then
        return null
    endif
    set index = GetRandomInt(1, count)
    set key = GetPointKey(profileId, index)
    return AI_SpawnProfile(profileId, owner, ProfileSpawnX.real[key], ProfileSpawnY.real[key], facing, uniqueId)
endfunction

public function FindClosestEnemy takes unit source, real range returns unit
    call EnsureState()
    if source == null or range <= 0.00 then
        return null
    endif
    call GroupClear(TempGroup)
    set SearchSource = source
    set SearchBestUnit = null
    set SearchBestDistance = range * range
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function ClosestEnemyEnum)
    call GroupClear(TempGroup)
    set SearchSource = null
    return SearchBestUnit
endfunction

public function FindLowestHealthAlly takes unit source, real range, boolean includeSelf returns unit
    call EnsureState()
    if source == null or range <= 0.00 then
        return null
    endif
    call GroupClear(TempGroup)
    set AllySearchSource = source
    set AllySearchBestUnit = null
    set AllySearchBestLife = 101.00
    set AllySearchIncludeSelf = includeSelf
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function LowestHealthAllyEnum)
    call GroupClear(TempGroup)
    set AllySearchSource = null
    set AllySearchIncludeSelf = false
    return AllySearchBestUnit
endfunction

public function CountNearbyEnemies takes unit source, real range returns integer
    local integer result
    call EnsureState()
    if source == null or range <= 0.00 then
        return 0
    endif
    call GroupClear(TempGroup)
    set CountSource = source
    set CountResult = 0
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function CountEnemyEnum)
    call GroupClear(TempGroup)
    set result = CountResult
    set CountSource = null
    set CountResult = 0
    return result
endfunction

private function CanCreateRandomHero takes nothing returns boolean
    if not RandomSpawnEnabled or RandomSpawnProfileCount <= 0 then
        return false
    endif
    if RandomSpawnHardCap > 0 and RandomSpawnManagedCount >= RandomSpawnHardCap then
        return false
    endif
    if RandomSpawnActiveCap > 0 and CountRandomManagedVisible() >= RandomSpawnActiveCap then
        return false
    endif
    return true
endfunction

private function GetRandomSpawnProfile takes nothing returns integer
    local integer start
    local integer index
    local integer checked = 0
    local integer profileId
    if RandomSpawnProfileCount <= 0 then
        return 0
    endif
    set start = GetRandomInt(1, RandomSpawnProfileCount)
    set index = start
    loop
        exitwhen checked >= RandomSpawnProfileCount
        set profileId = RandomSpawnProfiles[index]
        if CanRegister(profileId, 0) then
            return profileId
        endif
        set checked = checked + 1
        set index = index + 1
        if index > RandomSpawnProfileCount then
            set index = 1
        endif
    endloop
    return 0
endfunction

private function PickProfileSpawnPoint takes integer profileId returns boolean
    local integer count
    local integer index
    local integer key
    if profileId <= 0 then
        return false
    endif
    set count = ProfileSpawnCount[profileId]
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set RandomPointX = ProfileSpawnX.real[key]
        set RandomPointY = ProfileSpawnY.real[key]
    else
        set RandomPointX = GetRandomReal(GetRectMinX(bj_mapInitialPlayableArea), GetRectMaxX(bj_mapInitialPlayableArea))
        set RandomPointY = GetRandomReal(GetRectMinY(bj_mapInitialPlayableArea), GetRectMaxY(bj_mapInitialPlayableArea))
    endif
    return true
endfunction

private function GetSpawnOwnerForProfile takes integer profileId returns player
    local integer slot = ProfileSpawnOwnerSlot[profileId]
    if slot > 0 then
        return Player(slot - 1)
    endif
    return Player(RandomSpawnOwnerIndex)
endfunction

private function MarkRandomManaged takes integer instanceId returns nothing
    if instanceId <= 0 then
        return
    endif
    if not InstanceRandomManaged.boolean[instanceId] then
        set RandomSpawnManagedCount = RandomSpawnManagedCount + 1
    endif
    set InstanceRandomManaged.boolean[instanceId] = true
    set InstanceHiddenByCap.boolean[instanceId] = false
endfunction

private function ApplyRandomSpawnPresentation takes unit whichUnit returns nothing
    local integer newLevel
    if whichUnit == null then
        return
    endif
    call SetUnitColor(whichUnit, ConvertPlayerColor(GetRandomInt(0, MAX_PLAYER_COLOR_INDEX)))
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        set newLevel = GetHeroLevel(whichUnit) + GetRandomInt(1, 15)
        call SetHeroLevel(whichUnit, newLevel, false)
    endif
endfunction

private function AnnounceRandomSpawn takes unit whichUnit, integer profileId returns nothing
    if whichUnit == null then
        return
    endif
    call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 6.00, "|cff808000AI Heroes: |r" + ProfileName.string[profileId] + " entered the world...")
endfunction

public function SpawnRandomHero takes boolean showMessage returns unit
    local integer profileId
    local integer instanceId
    local player owner
    local unit created = null
    call EnsureState()
    if not CanCreateRandomHero() then
        if showMessage then
            call BJDebugMsg("[AI] Random spawn skipped: hard cap, active cap, or random profile pool is blocking it.")
        endif
        return null
    endif
    set profileId = GetRandomSpawnProfile()
    if profileId <= 0 then
        if showMessage then
            call BJDebugMsg("[AI] Random spawn skipped: all random profiles are currently capped.")
        endif
        return null
    endif
    set owner = GetSpawnOwnerForProfile(profileId)
    if PickProfileSpawnPoint(profileId) then
        set created = AI_SpawnProfile(profileId, owner, RandomPointX, RandomPointY, GetRandomReal(0.00, 360.00), 0)
    endif
    if created == null then
        if showMessage then
            call BJDebugMsg("[AI] Random spawn failed for profile " + I2S(profileId) + ".")
        endif
        set owner = null
        return null
    endif
    set instanceId = AI_GetInstance(created)
    if instanceId > 0 then
        call MarkRandomManaged(instanceId)
        call ApplyRandomSpawnPresentation(created)
        if RandomSpawnActiveCap > 0 and CountRandomManagedVisible() > RandomSpawnActiveCap then
            call HideRandomManagedByCap(instanceId, created)
        endif
    endif
    call AnnounceRandomSpawn(created, profileId)
    set owner = null
    return created
endfunction

private function TryUnhideRandomManaged takes boolean showMessage returns boolean
    local integer index = 1
    local integer instanceId
    local integer selected = 0
    local integer seen = 0
    local unit whichUnit
    if RandomSpawnActiveCap > 0 and CountRandomManagedVisible() >= RandomSpawnActiveCap then
        return false
    endif
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        if InstanceRandomManaged.boolean[instanceId] and InstanceHiddenByCap.boolean[instanceId] and not InstanceTraveling.boolean[instanceId] then
            set whichUnit = InstanceUnit.unit[instanceId]
            if whichUnit != null and IsAliveUnit(whichUnit) and not IsCompanionControlled(whichUnit) then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set selected = instanceId
                endif
            endif
        endif
        set index = index + 1
    endloop
    if selected > 0 then
        set whichUnit = InstanceUnit.unit[selected]
        if CanShowRandomManaged(selected) then
            call ShowRandomManagedFromCap(selected, whichUnit)
            if showMessage then
                call BJDebugMsg("[AI] Random hero returned: " + GetDisplayName(whichUnit))
            endif
            set whichUnit = null
            return true
        endif
    endif
    set whichUnit = null
    return false
endfunction

private function GetRandomTravelInstance takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer selected = 0
    local integer seen = 0
    local integer state
    local unit whichUnit
    local unit enemy
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set state = InstanceState[instanceId]
        if IsRandomManagedVisible(instanceId) and not IsCompanionControlled(InstanceUnit.unit[instanceId]) and (state == AI_STATE_IDLE or state == AI_STATE_WANDER) then
            set whichUnit = InstanceUnit.unit[instanceId]
            set enemy = AI_FindClosestEnemy(whichUnit, 900.00)
            if enemy == null then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set selected = instanceId
                endif
            endif
            set enemy = null
        endif
        set index = index + 1
    endloop
    set whichUnit = null
    set enemy = null
    return selected
endfunction

public function GetUnitLifePercent takes unit whichUnit returns real
    return GetLifePercent(whichUnit)
endfunction

public function GetUnitManaPercent takes unit whichUnit returns real
    return GetManaPercent(whichUnit)
endfunction

public function TryUseConsumable takes unit whichUnit returns boolean
    local integer slot = 0
    local item slotItem
    if whichUnit == null then
        return false
    endif
    if GetLifePercent(whichUnit) > 50.00 and GetManaPercent(whichUnit) > 50.00 then
        return false
    endif
    loop
        exitwhen slot >= bj_MAX_INVENTORY
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null and GetItemType(slotItem) == ITEM_TYPE_CHARGED then
            call UnitUseItem(whichUnit, slotItem)
            set slotItem = null
            return true
        endif
        set slot = slot + 1
    endloop
    set slotItem = null
    return false
endfunction

private function IsCastingLocked takes unit whichUnit returns boolean
    local integer customValue
    if whichUnit == null then
        return false
    endif
    set customValue = GetUnitUserData(whichUnit)
    return customValue > 0 and udg_UnitIsCasting[customValue]
endfunction

private function CanStartAbilityOrder takes unit caster, integer instanceId returns boolean
    if instanceId > 0 then
        if GetNow() < InstanceNextAbility.real[instanceId] then
            return false
        endif
        if IsCastingLocked(caster) then
            return false
        endif
    endif
    return true
endfunction

private function SetAbilityOrderCooldown takes integer instanceId, real cooldown returns nothing
    if instanceId <= 0 then
        return
    endif
    if cooldown <= 0.00 then
        set cooldown = AI_DEFAULT_ABILITY_GAP
    endif
    set InstanceNextAbility.real[instanceId] = GetNow() + cooldown + GetRandomReal(0.00, AI_ABILITY_ORDER_JITTER)
endfunction

public function IsUnitCastingLocked takes unit whichUnit returns boolean
    return IsCastingLocked(whichUnit)
endfunction

public function TryCastTarget takes unit caster, unit target, integer abilityId, string order, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or target == null or order == "" then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssueTargetOrder(caster, order, target) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function TryCastPoint takes unit caster, real x, real y, integer abilityId, string order, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or order == "" then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssuePointOrder(caster, order, x, y) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function TryCastImmediate takes unit caster, integer abilityId, string order, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or order == "" then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssueImmediateOrder(caster, order) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function TryCastImmediateById takes unit caster, integer abilityId, integer orderId, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or orderId == 0 then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssueImmediateOrderById(caster, orderId) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function DefaultAttackThink takes nothing returns nothing
    local unit caster = AI_EventUnit
    local unit target = AI_EventTarget
    if caster != null and target != null and IsAliveUnit(target) then
        call IssueTargetOrder(caster, "attack", target)
    endif
    set caster = null
    set target = null
endfunction

public function TemporaryAbilitySwap takes unit whichUnit, integer removeAbilityId, integer addAbilityId, integer addLevel, real duration returns boolean
    local timer restoreTimer
    local integer timerId
    local boolean addWasPresent
    if whichUnit == null or addAbilityId == 0 or duration <= 0.00 then
        return false
    endif
    set addWasPresent = GetUnitAbilityLevel(whichUnit, addAbilityId) > 0
    if removeAbilityId != 0 then
        call UnitRemoveAbility(whichUnit, removeAbilityId)
    endif
    call UnitAddAbility(whichUnit, addAbilityId)
    if addLevel > 0 then
        call SetUnitAbilityLevel(whichUnit, addAbilityId, addLevel)
    endif
    set restoreTimer = CreateTimer()
    set timerId = GetHandleId(restoreTimer)
    set TempAbilityUnit.unit[timerId] = whichUnit
    if addWasPresent then
        set TempAbilityRemove[timerId] = 0
    else
        set TempAbilityRemove[timerId] = addAbilityId
    endif
    set TempAbilityRestore[timerId] = removeAbilityId
    call TimerStart(restoreTimer, duration, false, function RestoreTemporaryAbility)
    set restoreTimer = null
    return true
endfunction

public function RequestBark takes unit speaker, integer barkType returns boolean
    local integer instanceId = AI_GetInstance(speaker)
    local integer profileId
    local integer barkKey
    local integer cooldownKey
    local integer count
    local integer index
    local integer lineKey
    local string text
    local string soundKey
    local real now = GetNow()
    local real duration
    local boolean replyScheduled
    if instanceId <= 0 or speaker == null or barkType <= 0 then
        return false
    endif
    if not IsAliveUnit(speaker) or udg_CompanionDialogueActive then
        return false
    endif
    if IsDialogBlockingBark() or not IsBarkContextAllowed(speaker, barkType) then
        return false
    endif
    set cooldownKey = GetInstanceBarkKey(instanceId, barkType)
    if now < NextGlobalBark or now < InstanceNextChat.real[instanceId] or now < InstanceNextBark.real[cooldownKey] then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    set barkKey = GetBarkKey(profileId, barkType)
    set count = BarkLineCount[barkKey]
    if count <= 0 then
        return false
    endif
    set index = GetRandomInt(1, count)
    set lineKey = GetBarkLineKey(barkKey, index)
    set text = BarkLineText.string[lineKey]
    set soundKey = BarkLineSound.string[lineKey]
    set udg_CompanionDialogueActive = true
    call DialogSystem_PlayLine(speaker, "", text, soundKey, true)
    set duration = udg_ExSoundDuration
    if duration <= 0.00 then
        set duration = EstimateDialogDuration(text)
    endif
    set InstanceNextChat.real[instanceId] = now + duration + AI_DIALOG_UNLOCK_PAD
    set InstanceNextBark.real[cooldownKey] = now + GetBarkCooldown(barkType)
    set NextGlobalBark = now + duration + AI_BARK_GLOBAL_GAP
    set replyScheduled = ScheduleBarkReply(speaker, soundKey, duration)
    if not replyScheduled then
        call StartDialogUnlock(duration + AI_DIALOG_UNLOCK_PAD)
    endif
    return true
endfunction

public function SetDebugMode takes boolean enabled returns nothing
    set DebugMode = enabled
endfunction

public function IsDebugMode takes nothing returns boolean
    return DebugMode
endfunction

public function SetBossFightActive takes boolean active returns nothing
    set BossFightActive = active
endfunction

public function IsBossFightActive takes nothing returns boolean
    return BossFightActive
endfunction

public function RegisterBossCastAbility takes integer abilityId, real evadeRadius, real evadeDistance returns nothing
    if abilityId == 0 or BossCastCount >= MAX_BOSS_CASTS then
        return
    endif
    set BossCastCount = BossCastCount + 1
    set BossCastAbility[BossCastCount] = abilityId
    set BossCastRadius[BossCastCount] = evadeRadius
    set BossCastDistance[BossCastCount] = evadeDistance
endfunction

public function HandleBossCast takes unit caster, integer abilityId, real targetX, real targetY returns nothing
    local integer castIndex = 1
    local integer activeIndex
    local integer instanceId
    local unit whichUnit
    local real originX
    local real originY
    local real dx
    local real dy
    if abilityId == 0 then
        return
    endif
    loop
        exitwhen castIndex > BossCastCount
        if BossCastAbility[castIndex] == abilityId then
            if targetX == 0.00 and targetY == 0.00 and caster != null then
                set originX = GetUnitX(caster)
                set originY = GetUnitY(caster)
            else
                set originX = targetX
                set originY = targetY
            endif
            set activeIndex = 1
            loop
                exitwhen activeIndex > ActiveCount
                set instanceId = ActiveInstances[activeIndex]
                set whichUnit = InstanceUnit.unit[instanceId]
                if whichUnit != null and IsAliveUnit(whichUnit) and not InstanceTraveling.boolean[instanceId] then
                    set dx = GetUnitX(whichUnit) - originX
                    set dy = GetUnitY(whichUnit) - originY
                    if dx * dx + dy * dy <= BossCastRadius[castIndex] * BossCastRadius[castIndex] then
                        call SetInstanceState(instanceId, AI_STATE_BOSS_EVADE)
                        set InstanceRetreatUntil.real[instanceId] = GetNow() + AI_BOSS_EVADE_TIME
                        call MoveAwayFromPoint(whichUnit, originX, originY, BossCastDistance[castIndex])
                    endif
                endif
                set activeIndex = activeIndex + 1
            endloop
            set whichUnit = null
            return
        endif
        set castIndex = castIndex + 1
    endloop
    set whichUnit = null
endfunction

public function StartTravel takes unit whichUnit, real duration, real returnX, real returnY returns nothing
    local integer instanceId = AI_GetInstance(whichUnit)
    local integer profileId
    if instanceId <= 0 or whichUnit == null or duration <= 0.00 or InstanceHiddenByCap.boolean[instanceId] then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    if IsCompanionControlled(whichUnit) and not ProfileAllowCompanionTravel.boolean[profileId] then
        return
    endif
    set InstanceTraveling.boolean[instanceId] = true
    set InstanceTravelReturnAt.real[instanceId] = GetNow() + duration
    set InstanceTravelReturnX.real[instanceId] = returnX
    set InstanceTravelReturnY.real[instanceId] = returnY
    call SetInstanceState(instanceId, AI_STATE_TRAVEL)
    call IssueImmediateOrder(whichUnit, "stop")
    call PauseUnit(whichUnit, true)
    call ShowUnit(whichUnit, false)
endfunction

public function ReturnFromTravel takes unit whichUnit returns nothing
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    call CompleteTravel(instanceId, whichUnit)
endfunction

private function PickRandomTravelReturnPoint takes integer instanceId returns nothing
    local integer profileId = InstanceProfile[instanceId]
    local integer count = ProfileSpawnCount[profileId]
    local integer index
    local integer key
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set RandomPointX = ProfileSpawnX.real[key]
        set RandomPointY = ProfileSpawnY.real[key]
    else
        set RandomPointX = InstanceHomeX.real[instanceId]
        set RandomPointY = InstanceHomeY.real[instanceId]
    endif
endfunction

private function StartRandomManagedTravel takes integer instanceId returns boolean
    local unit whichUnit
    if instanceId <= 0 or InstanceTraveling.boolean[instanceId] or InstanceHiddenByCap.boolean[instanceId] then
        return false
    endif
    set whichUnit = InstanceUnit.unit[instanceId]
    if whichUnit == null or not IsAliveUnit(whichUnit) or IsCompanionControlled(whichUnit) then
        set whichUnit = null
        return false
    endif
    call PickRandomTravelReturnPoint(instanceId)
    call AI_StartTravel(whichUnit, GetRandomReal(AI_RANDOM_TRAVEL_DURATION_MIN, AI_RANDOM_TRAVEL_DURATION_MAX), RandomPointX, RandomPointY)
    set whichUnit = null
    return InstanceTraveling.boolean[instanceId]
endfunction

private function RandomSpawnTimerAction takes nothing returns nothing
    local unit spawned = null
    if RandomSpawnEnabled then
        set spawned = AI_SpawnRandomHero(false)
    endif
    set spawned = null
    call TimerStart(RandomSpawnTimer, GetRandomReal(AI_RANDOM_SPAWN_MIN, AI_RANDOM_SPAWN_MAX), false, function RandomSpawnTimerAction)
endfunction

private function RandomTravelTimerAction takes nothing returns nothing
    local integer instanceId
    local boolean started = false
    if RandomTravelEnabled then
        set started = TryUnhideRandomManaged(false)
        if GetRandomInt(1, 2) == 1 then
            set instanceId = GetRandomTravelInstance()
            if instanceId > 0 then
                set started = StartRandomManagedTravel(instanceId)
            endif
        endif
    endif
    call TimerStart(RandomTravelTimer, GetRandomReal(AI_RANDOM_TRAVEL_MIN, AI_RANDOM_TRAVEL_MAX), false, function RandomTravelTimerAction)
endfunction

private function DebugSpawnAction takes nothing returns nothing
    local unit spawned = AI_SpawnRandomHero(true)
    set spawned = null
endfunction

private function DebugModeAction takes nothing returns nothing
    set DebugMode = not DebugMode
    if DebugMode then
        call BJDebugMsg("[AI] Debug mode enabled.")
    else
        call BJDebugMsg("[AI] Debug mode disabled.")
    endif
endfunction

private function RunProfileThink takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set AI_EventTarget = AI_FindClosestEnemy(whichUnit, 700.00)
    call RunProfileTrigger(ProfileThinkTrigger, instanceId, whichUnit)
    set AI_EventTarget = null
endfunction

private function ProcessInstance takes integer instanceId, real now returns nothing
    local unit whichUnit = InstanceUnit.unit[instanceId]
    local boolean companionControlled
    local integer state
    if instanceId <= 0 or whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        set whichUnit = null
        return
    endif
    set state = InstanceState[instanceId]
    if state == AI_STATE_TRAVEL then
        if now >= InstanceTravelReturnAt.real[instanceId] then
            call CompleteTravel(instanceId, whichUnit)
        endif
        set whichUnit = null
        return
    endif
    if InstanceHiddenByCap.boolean[instanceId] then
        set whichUnit = null
        return
    endif
    if state == AI_STATE_DEAD or not IsAliveUnit(whichUnit) or IsUnitHidden(whichUnit) then
        set whichUnit = null
        return
    endif
    if now < InstanceNextThink.real[instanceId] then
        set whichUnit = null
        return
    endif
    set InstanceNextThink.real[instanceId] = now + GetRandomReal(AI_DEFAULT_THINK_MIN, AI_DEFAULT_THINK_MAX)
    set companionControlled = IsCompanionControlled(whichUnit)
    set InstanceCompanionControlled.boolean[instanceId] = companionControlled

    if companionControlled then
        call SetInstanceState(instanceId, AI_STATE_COMPANION_CONTROLLED)
        if now >= InstanceNextAbility.real[instanceId] then
            call RunProfileThink(instanceId, whichUnit)
        endif
        set whichUnit = null
        return
    endif

    if state == AI_STATE_RETREAT_COMBAT or state == AI_STATE_RETREAT_BASE or state == AI_STATE_BOSS_EVADE then
        if now < InstanceRetreatUntil.real[instanceId] then
            set whichUnit = null
            return
        endif
        call SetInstanceState(instanceId, AI_STATE_IDLE)
    elseif state == AI_STATE_BUY then
        if IsNearActionPoint(instanceId, whichUnit, 250.00) then
            call FinishBuyState(instanceId, whichUnit)
        endif
        set whichUnit = null
        return
    elseif state == AI_STATE_SELL then
        call DropInventoryItem(whichUnit)
        call SetInstanceState(instanceId, AI_STATE_IDLE)
        set whichUnit = null
        return
    elseif state == AI_STATE_CAMP then
        if now >= InstanceRetreatUntil.real[instanceId] then
            call SetInstanceState(instanceId, AI_STATE_IDLE)
        endif
        set whichUnit = null
        return
    endif

    if ProfileAutonomousDisabled.boolean[InstanceProfile[instanceId]] then
        if now >= InstanceNextAbility.real[instanceId] then
            call RunProfileThink(instanceId, whichUnit)
        endif
        set whichUnit = null
        return
    endif

    if not BossFightActive then
        if GetLifePercent(whichUnit) <= 10.00 then
            call BeginBaseRetreat(instanceId, whichUnit)
            set whichUnit = null
            return
        elseif GetLifePercent(whichUnit) <= GetRandomReal(10.00, 25.00) then
            call BeginCombatRetreat(instanceId, whichUnit)
            set whichUnit = null
            return
        endif
    endif

    if now >= InstanceNextItem.real[instanceId] then
        if AI_TryUseConsumable(whichUnit) then
            set InstanceNextItem.real[instanceId] = now + 5.00 + GetRandomReal(0.50, 1.50)
        else
            set InstanceNextItem.real[instanceId] = now + 2.00 + GetRandomReal(0.10, 0.80)
        endif
    endif

    if now >= InstanceNextAbility.real[instanceId] then
        call RunProfileThink(instanceId, whichUnit)
    endif

    if GetUnitCurrentOrder(whichUnit) == 0 and GetLifePercent(whichUnit) >= GetRandomReal(25.00, 30.00) and GetRandomInt(1, 10) == 1 then
        call BeginWander(instanceId, whichUnit)
    endif
    set whichUnit = null
endfunction

private function Think takes nothing returns nothing
    local integer i = 1
    local real now = GetNow()
    loop
        exitwhen i > ActiveCount
        call ProcessInstance(ActiveInstances[i], now)
        set i = i + 1
    endloop
endfunction

private function RequestCompanionDeathBark takes unit victim returns nothing
    local integer i = 1
    local integer instanceId
    local unit speaker
    loop
        exitwhen i > ActiveCount
        set instanceId = ActiveInstances[i]
        set speaker = InstanceUnit.unit[instanceId]
        if speaker != null and speaker != victim and IsCompanionControlled(speaker) and IsAliveUnit(speaker) and GetRandomInt(1, 2) == 1 then
            set AI_EventTarget = victim
            call AI_RequestBark(speaker, AI_BARK_COMPANION_DIES)
            set AI_EventTarget = null
            set speaker = null
            return
        endif
        set i = i + 1
    endloop
    set speaker = null
endfunction

private function HandleDeath takes nothing returns nothing
    local unit victim = GetDyingUnit()
    local unit killer = GetKillingUnit()
    local integer instanceId = UnitInstance[GetHandleId(victim)]
    if instanceId > 0 then
        set InstanceAlive.boolean[instanceId] = false
        set InstanceTraveling.boolean[instanceId] = false
        call SetInstanceState(instanceId, AI_STATE_DEAD)
        if IsCompanionControlled(victim) and not udg_InCinematic then
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 5.00, "|cffff4040" + GetDisplayName(victim) + " has fallen.|r")
            call RequestCompanionDeathBark(victim)
        endif
        call RunProfileTrigger(ProfileDeathTrigger, instanceId, victim)
        call StartReviveTimer(instanceId, victim)
    endif
    if killer != null then
        set instanceId = UnitInstance[GetHandleId(killer)]
        if instanceId > 0 then
            set AI_EventTarget = victim
            call AI_RequestBark(killer, AI_BARK_KILLING)
            set AI_EventTarget = null
        endif
    endif
    set victim = null
    set killer = null
endfunction

private function HandleAttack takes nothing returns nothing
    local unit attacker = GetAttacker()
    local unit attacked = GetTriggerUnit()
    local integer instanceId = UnitInstance[GetHandleId(attacker)]
    if instanceId > 0 and IsCompanionControlled(attacker) and GetRandomInt(1, 10) == 1 then
        set AI_EventTarget = attacked
        call AI_RequestBark(attacker, AI_BARK_ATTACKING)
        set AI_EventTarget = null
    endif
    set instanceId = UnitInstance[GetHandleId(attacked)]
    if instanceId > 0 and GetRandomReal(0.00, 100.00) <= AI_SHIELD_BLOCK_CHANCE then
        call IssueImmediateOrder(attacked, "berserk")
    endif
    set attacker = null
    set attacked = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer instanceId = UnitInstance[GetHandleId(caster)]
    if instanceId > 0 and IsCompanionControlled(caster) and GetRandomInt(1, 5) == 1 then
        set AI_EventAbilityId = abilityId
        call AI_RequestBark(caster, AI_BARK_CASTING)
        set AI_EventAbilityId = 0
    endif
    call AI_HandleBossCast(caster, abilityId, GetSpellTargetX(), GetSpellTargetY())
    set caster = null
endfunction

private function HandleLevel takes nothing returns nothing
    local unit whichUnit = GetLevelingUnit()
    local integer instanceId = UnitInstance[GetHandleId(whichUnit)]
    local integer profileId
    if instanceId > 0 then
        set profileId = InstanceProfile[instanceId]
        call SetWidgetLife(whichUnit, GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE))
        if ProfileNoManaRestore.boolean[profileId] then
            call SetUnitState(whichUnit, UNIT_STATE_MANA, 0.00)
        else
            call SetUnitState(whichUnit, UNIT_STATE_MANA, GetUnitState(whichUnit, UNIT_STATE_MAX_MANA))
        endif
        call LearnRandomProfileAbility(whichUnit, profileId)
    endif
    set whichUnit = null
endfunction

private function HandleItem takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local item manipulatedItem = GetManipulatedItem()
    local integer instanceId = UnitInstance[GetHandleId(whichUnit)]
    if GetTriggerEventId() == EVENT_PLAYER_UNIT_DROP_ITEM then
        if GetOwningPlayer(whichUnit) == Player(0) then
            set udg_LastDroppedItem = manipulatedItem
        endif
    elseif instanceId > 0 and manipulatedItem == udg_LastDroppedItem then
        call AI_RequestBark(whichUnit, AI_BARK_ITEM_GIVEN)
    endif
    set whichUnit = null
    set manipulatedItem = null
endfunction

private function HandleCompanionCommand takes nothing returns nothing
    local unit whichUnit = Companions_EventUnit
    local integer commandId = Companions_EventCommand
    local integer mode = Companions_EventMode
    local integer barkType = 0

    if whichUnit == null or UnitInstance[GetHandleId(whichUnit)] <= 0 then
        set whichUnit = null
        return
    endif

    if commandId == Companions_COMMAND_INVITE then
        set barkType = AI_BARK_GREET
    elseif commandId == Companions_COMMAND_KICK then
        if GetRandomInt(1, 2) == 1 then
            set barkType = AI_BARK_KICKED
        else
            set barkType = AI_BARK_FAREWELL
        endif
    elseif commandId == Companions_COMMAND_DROP_ITEMS then
        set barkType = AI_BARK_DROP_ITEMS
    elseif commandId == Companions_COMMAND_MODE then
        if mode == COMPANION_MODE_PASSIVE then
            set barkType = AI_BARK_PASSIVE
        elseif mode == COMPANION_MODE_HOLD then
            set barkType = AI_BARK_HOLD
        elseif mode == COMPANION_MODE_AGGRESSIVE then
            set barkType = AI_BARK_AGGRESSIVE
        else
            set barkType = AI_BARK_NORMAL
        endif
    endif

    if barkType > 0 then
        call AI_RequestBark(whichUnit, barkType)
    endif

    set whichUnit = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    set ThinkTimer = CreateTimer()
    call TimerStart(ThinkTimer, AI_THINK_INTERVAL, true, function Think)

    set RandomSpawnTimer = CreateTimer()
    call TimerStart(RandomSpawnTimer, GetRandomReal(AI_RANDOM_SPAWN_MIN, AI_RANDOM_SPAWN_MAX), false, function RandomSpawnTimerAction)

    set RandomTravelTimer = CreateTimer()
    call TimerStart(RandomTravelTimer, GetRandomReal(AI_RANDOM_TRAVEL_MIN, AI_RANDOM_TRAVEL_MAX), false, function RandomTravelTimerAction)

    set DebugSpawnTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugSpawnTrigger, Player(0), "/debug aispawn", true)
    call TriggerRegisterPlayerChatEvent(DebugSpawnTrigger, Player(0), "aispawn", true)
    call TriggerAddAction(DebugSpawnTrigger, function DebugSpawnAction)

    set DebugModeTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugModeTrigger, Player(0), "/debug ai", true)
    call TriggerRegisterPlayerChatEvent(DebugModeTrigger, Player(0), "/debug aidebug", true)
    call TriggerAddAction(DebugModeTrigger, function DebugModeAction)

    set AttackTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(AttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerAddAction(AttackTrigger, function HandleAttack)

    set SpellEffectTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(SpellEffectTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerAddAction(SpellEffectTrigger, function HandleSpellEffect)

    set LevelTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(LevelTrigger, EVENT_PLAYER_HERO_LEVEL)
    call TriggerAddAction(LevelTrigger, function HandleLevel)

    set ItemTrigger = CreateTrigger()
    call RegisterPlayerUnitEventAll(ItemTrigger, EVENT_PLAYER_UNIT_DROP_ITEM)
    call RegisterPlayerUnitEventAll(ItemTrigger, EVENT_PLAYER_UNIT_PICKUP_ITEM)
    call TriggerAddAction(ItemTrigger, function HandleItem)

    call UnitDeathEvent_Register(function HandleDeath)
    call Companions_RegisterCommandEvent(function HandleCompanionCommand)
endfunction

endlibrary
