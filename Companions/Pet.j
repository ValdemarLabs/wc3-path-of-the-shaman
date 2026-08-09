/**
    Pet

    Author: Valdemar
    Version:

    Description:
    Pet and tame-beast logic. Pets use the companion control layer for follow
    modes, but keep separate ownership, tame, roster, fatigue, revival, food,
    rename, and Shadowclaw rules.

    Credits:
    - Old GUI pet/taming triggers, converted and consolidated into JASS.

    How to install:
    Import after the required libraries and disable the legacy GUI pet triggers.

    API:
    Pet_CanRename, Pet_ShowRenamePrompt, Pet_IsPetUnit, Pet_IsDead,
    Pet_Revive(unit pet, real lifePercent, real manaPercent, boolean showEffects),
    Pet_GetClassInfoText, Pet_GetTypeInfoText, and Pet_GetAbilityInfoText.

**/
library Pet initializer Init requires Table, Companions, UnitExperience, DamageEngine, FloatingTextSimple, PetDefinitions, Events, FallenHeroState

globals
    private constant boolean DEBUG = false
    private constant integer CONTROL_PLAYER_INDEX = 0
    private constant integer PET_OWNER_INDEX = 18
    private constant real TAME_DURATION = 10.00
    private constant real PET_REVIVE_DURATION = 20.00
    private constant real TAME_DAMAGE_MULTIPLIER = 1.75
    private constant real SHADOWCLAW_INIT_RETRY_DELAY = 0.50
    private constant real PET_HOME_TELEPORT_DELAY = 120.00
    private constant real PET_HOME_ARRIVE_DISTANCE = 300.00
    // Maximum ordinary pets in the roster; Shadowclaw does not use a slot.
    private constant integer MAX_NON_SHADOWCLAW_PETS = 2

    private constant integer ABIL_INVITE = 'A622'
    private constant integer ABIL_KICK = 'A621'
    private constant integer ABIL_TAME_I = 'A623'
    private constant integer ABIL_TAME_II = 'A625'
    private constant integer ABIL_TAME_III = 'A627'
    private constant integer ABIL_INVENTORY_HERO = 'AInv'
    private constant integer ABIL_WANDER_NEUTRAL = 'Awan'

    private Table TameTarget = 0
    private Table TameTimer = 0
    private Table TameTimerCaster = 0
    private Table TameReady = 0
    private Table FreezeTimerUnit = 0
    private Table PetHomeTimer = 0
    private Table HomeTimerPet = 0

    private group PetEnumGroup = null
    private group PetRoster = null
    private unit FoundShadowclaw = null
    private player SelectedPetPlayer = null
    private unit SelectedPetTarget = null
    private integer SelectedPetCount = 0
    private trigger PetDamageTrigger = null
    private dialog DismissPetDialog = null
    private trigger DismissPetTrigger = null
    private button DismissPetButtonOne = null
    private button DismissPetButtonTwo = null
    private unit DismissPetOne = null
    private unit DismissPetTwo = null
    private integer TamedRosterCount = 0
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("[Pet] " + msg)
    endif
endfunction

private function EnsureState takes nothing returns nothing
    if TameTarget == 0 then
        set TameTarget = Table.create()
        set TameTimer = Table.create()
        set TameTimerCaster = Table.create()
        set TameReady = Table.create()
        set FreezeTimerUnit = Table.create()
        set PetHomeTimer = Table.create()
        set HomeTimerPet = Table.create()
    endif
    if PetEnumGroup == null then
        set PetEnumGroup = CreateGroup()
    endif
    if PetRoster == null then
        set PetRoster = CreateGroup()
    endif
endfunction

private function IsAliveUnit takes unit u returns boolean
    return FallenHeroState_IsAlive(u)
endfunction

private function GetPetCount takes nothing returns integer
    if udg_TamedUnits == null then
        return 0
    endif
    return CountUnitsInGroup(udg_TamedUnits)
endfunction

private function EnsurePetGroup takes nothing returns nothing
    if udg_TamedUnits == null then
        set udg_TamedUnits = CreateGroup()
    endif
endfunction

private function IsRosterPet takes unit pet returns boolean
    return pet != null and PetRoster != null and IsUnitInGroup(pet, PetRoster)
endfunction

private function GetPreferredLeader takes unit caster returns unit
    if IsAliveUnit(caster) and (caster == udg_Nazgrek or caster == udg_Zulkis) then
        return caster
    endif
    if IsAliveUnit(udg_Nazgrek) then
        return udg_Nazgrek
    endif
    if IsAliveUnit(udg_Zulkis) then
        return udg_Zulkis
    endif
    return null
endfunction

private function SetPetFocus takes unit pet, unit leader returns nothing
    if pet == null then
        return
    endif
    if udg_CompanionFocusNazgrek != null then
        call GroupRemoveUnit(udg_CompanionFocusNazgrek, pet)
    endif
    if udg_CompanionFocusZulkis != null then
        call GroupRemoveUnit(udg_CompanionFocusZulkis, pet)
    endif
    if leader == udg_Zulkis and udg_CompanionFocusZulkis != null then
        call GroupAddUnit(udg_CompanionFocusZulkis, pet)
    elseif udg_CompanionFocusNazgrek != null then
        call GroupAddUnit(udg_CompanionFocusNazgrek, pet)
    endif
endfunction

private function RemovePetFocus takes unit pet returns nothing
    if pet == null then
        return
    endif
    if udg_CompanionFocusNazgrek != null then
        call GroupRemoveUnit(udg_CompanionFocusNazgrek, pet)
    endif
    if udg_CompanionFocusZulkis != null then
        call GroupRemoveUnit(udg_CompanionFocusZulkis, pet)
    endif
endfunction

private function RemovePetWander takes unit pet returns nothing
    if pet != null and GetUnitAbilityLevel(pet, ABIL_WANDER_NEUTRAL) > 0 then
        call UnitRemoveAbility(pet, ABIL_WANDER_NEUTRAL)
    endif
endfunction

private function IsTameAbility takes integer abilityId returns boolean
    return abilityId == ABIL_TAME_I or abilityId == ABIL_TAME_II or abilityId == ABIL_TAME_III
endfunction

private function GetTameMaxLevel takes integer abilityId returns integer
    if abilityId == ABIL_TAME_III then
        return 30
    elseif abilityId == ABIL_TAME_II then
        return 20
    endif
    return 10
endfunction

private function IsTameableType takes integer unitTypeId returns boolean
    return PetDefinitions_IsTameableType(unitTypeId)
endfunction

private function IsRawMeat takes integer itemTypeId returns boolean
    return PetDefinitions_IsRawMeat(itemTypeId)
endfunction

private function GetPetClassInfoTextInternal takes unit pet returns string
    local integer unitTypeId

    if pet == null or GetUnitTypeId(pet) == 0 then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(pet)
    return PetDefinitions_GetClassText(unitTypeId)
endfunction

private function GetPetTypeInfoTextInternal takes unit pet returns string
    local integer unitTypeId

    if pet == null or GetUnitTypeId(pet) == 0 then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(pet)
    return PetDefinitions_GetRoleText(unitTypeId)
endfunction

private function GetPetAbilityInfoTextInternal takes unit pet returns string
    local integer unitTypeId

    if pet == null or GetUnitTypeId(pet) == 0 then
        return "-"
    endif

    set unitTypeId = GetUnitTypeId(pet)
    return PetDefinitions_GetAbilityInfoText(unitTypeId)
endfunction

private function HealPetByPercent takes unit pet, real percent returns nothing
    local real maxLife
    local real newLife

    if pet == null then
        return
    endif

    set maxLife = GetUnitState(pet, UNIT_STATE_MAX_LIFE)
    set newLife = GetWidgetLife(pet) + maxLife * percent * 0.01
    if newLife > maxLife then
        set newLife = maxLife
    endif
    call SetWidgetLife(pet, newLife)
endfunction

private function ClearTameState takes integer casterKey, boolean clearReady returns nothing
    local timer t
    local integer timerId

    if casterKey <= 0 then
        return
    endif

    set t = TameTimer.timer[casterKey]
    if t != null then
        set timerId = GetHandleId(t)
        call PauseTimer(t)
        call DestroyTimer(t)
        call TameTimerCaster.remove(timerId)
    endif

    set TameTimer.timer[casterKey] = null
    call TameTarget.remove(casterKey)
    if clearReady then
        call TameReady.remove(casterKey)
        set udg_TM_TimerFinished = false
    endif
    set udg_Pet_TamerChanneling[casterKey] = false
    set udg_Pet_Tamer[casterKey] = null
    set udg_UDexUnits[casterKey] = null
    set t = null
endfunction

private function OnTameTimer takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local integer casterKey = TameTimerCaster[timerId]

    if casterKey > 0 then
        set TameReady[casterKey] = 1
        set udg_TM_Value = casterKey
        set udg_TM_TimerFinished = true
        set udg_Pet_TamerChanneling[casterKey] = false
        set TameTimer.timer[casterKey] = null
        call TameTimerCaster.remove(timerId)
    endif

    call DestroyTimer(expired)
    set expired = null
endfunction

private function StartTame takes unit caster, unit target, integer abilityId returns nothing
    local integer casterKey
    local integer targetLevel
    local timer t

    if caster == null or target == null then
        return
    endif

    set casterKey = GetUnitUserData(caster)
    if casterKey <= 0 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Tame Beast: caster is not indexed.")
        return
    endif

    if udg_Pet_Dead then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "Your current pet must recover before you tame another beast.")
        return
    endif

    if IsRosterPet(target) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " is already one of your pets.")
        return
    endif

    if not IsTameableType(GetUnitTypeId(target)) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " cannot be tamed.")
        return
    endif

    set targetLevel = GetUnitLevel(target)
    if targetLevel > GetHeroLevel(caster) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " is too high level to tame.")
        return
    endif
    if targetLevel > GetTameMaxLevel(abilityId) then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "This rank of Tame Beast cannot tame that beast.")
        return
    endif

    call ClearTameState(casterKey, true)
    set udg_TM_Value = casterKey
    set udg_TM_TimerFinished = false
    set udg_Pet_Tamer[casterKey] = caster
    set udg_Pet_TamerChanneling[casterKey] = true
    set udg_UDexUnits[casterKey] = target
    set TameTarget.unit[casterKey] = target
    set TameReady[casterKey] = 0

    call IssuePointOrder(target, "attack", GetUnitX(caster), GetUnitY(caster))

    set t = CreateTimer()
    set TameTimer.timer[casterKey] = t
    set TameTimerCaster[GetHandleId(t)] = casterKey
    set udg_TM_Timer = t
    call TimerStart(t, TAME_DURATION, false, function OnTameTimer)
    set t = null
endfunction

private function FreezePetAnimation takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit pet = FreezeTimerUnit.unit[timerId]

    if pet != null and udg_Pet_Dead then
        call PauseUnit(pet, true)
        call SetUnitTimeScale(pet, 0.00)
    endif

    call FreezeTimerUnit.remove(timerId)
    call DestroyTimer(expired)
    set pet = null
    set expired = null
endfunction

private function StartFreezeTimer takes unit pet returns nothing
    local timer t
    local real freezeDelay

    if pet == null then
        return
    endif

    set t = CreateTimer()
    set freezeDelay = BlzGetUnitRealField(pet, UNIT_RF_DEATH_TIME)
    if freezeDelay < 0.10 then
        set freezeDelay = 0.10
    endif
    set FreezeTimerUnit.unit[GetHandleId(t)] = pet
    call TimerStart(t, freezeDelay, false, function FreezePetAnimation)
    set t = null
endfunction

private function RestoreFatiguedPet takes unit pet, real lifePercent, real manaPercent, boolean restoreMana, string effectPath returns boolean
    if pet == null or pet != udg_TamedUnit or not udg_Pet_Dead then
        return false
    endif

    if udg_ReviveTimerPet != null then
        call PauseTimer(udg_ReviveTimerPet)
    endif
    call SetUnitPathing(pet, true)
    call PauseUnit(pet, false)
    call SetUnitTimeScale(pet, 1.00)
    call ResetUnitAnimation(pet)
    call SetUnitAnimation(pet, "stand")
    if effectPath != "" then
        call DestroyEffect(AddSpecialEffectTarget(effectPath, pet, "origin"))
    endif

    set udg_Pet_Dead = false
    call SetWidgetLife(pet, GetUnitState(pet, UNIT_STATE_MAX_LIFE) * lifePercent * 0.01)
    if restoreMana then
        call SetUnitState(pet, UNIT_STATE_MANA, GetUnitState(pet, UNIT_STATE_MAX_MANA) * manaPercent * 0.01)
    endif
    call SetUnitInvulnerable(pet, false)
    call SetUnitOwner(pet, Player(PET_OWNER_INDEX), true)
    call Companions_Resume(pet)

    if udg_Pet_DeathPoint != null then
        call RemoveLocation(udg_Pet_DeathPoint)
        set udg_Pet_DeathPoint = null
    endif
    return true
endfunction

private function OnReviveTimer takes nothing returns nothing
    local unit pet = udg_TamedUnit

    if pet == null or GetUnitTypeId(pet) == 0 then
        set pet = null
        return
    endif

    call RestoreFatiguedPet(pet, 25.00, 0.00, false, "Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl")

    set pet = null
endfunction

private function FatiguePet takes unit pet returns nothing
    local player textPlayer

    if pet == null or udg_Pet_Dead then
        return
    endif

    set udg_Pet_Dead = true
    set udg_TamedUnitDeathCount = udg_TamedUnitDeathCount + 1
    call Companions_Suspend(pet)
    call IssueImmediateOrder(pet, "stop")
    call SetUnitInvulnerable(pet, true)
    call SetUnitOwner(pet, Player(PLAYER_NEUTRAL_PASSIVE), true)
    call SetUnitTimeScale(pet, 1.00)
    call SetUnitAnimation(pet, "death")
    call PauseUnit(pet, true)
    call SetUnitPathing(pet, false)

    if udg_Pet_DeathPoint != null then
        call RemoveLocation(udg_Pet_DeathPoint)
    endif
    set udg_Pet_DeathPoint = Location(GetUnitX(pet), GetUnitY(pet))

    set textPlayer = Player(0)
    call FloatingTextTag.create(GetUnitName(pet) + " is fatigued!", pet, PET_REVIVE_DURATION, 1.20, textPlayer, 1.00, 0.05, 0.10, false, true)
    call StartFreezeTimer(pet)

    if udg_ReviveTimerPet == null then
        set udg_ReviveTimerPet = CreateTimer()
    endif
    call TimerStart(udg_ReviveTimerPet, PET_REVIVE_DURATION, false, function OnReviveTimer)
    set textPlayer = null
endfunction

private function OnPetDamaged takes nothing returns nothing
    local unit pet = GetTriggerUnit()
    local real damage = GetEventDamage()
    local real life

    if pet == null or pet != udg_TamedUnit or udg_Pet_Dead or damage <= 0.00 then
        set pet = null
        return
    endif

    set life = GetWidgetLife(pet)
    if damage >= life - 0.41 then
        if life > 1.00 then
            call BlzSetEventDamage(life - 1.00)
        else
            call BlzSetEventDamage(0.00)
        endif
        call FatiguePet(pet)
    endif

    set pet = null
endfunction

private function RefreshPetDamageTrigger takes unit pet returns nothing
    if PetDamageTrigger != null then
        call DestroyTrigger(PetDamageTrigger)
        set PetDamageTrigger = null
    endif
    if pet != null and GetUnitTypeId(pet) != 0 then
        set PetDamageTrigger = CreateTrigger()
        call TriggerRegisterUnitEvent(PetDamageTrigger, pet, EVENT_UNIT_DAMAGED)
        call TriggerAddAction(PetDamageTrigger, function OnPetDamaged)
    endif
endfunction

private function StopPetHomeFallback takes unit pet returns nothing
    local integer petId
    local timer homeTimer

    if pet == null then
        return
    endif

    set petId = GetHandleId(pet)
    set homeTimer = PetHomeTimer.timer[petId]
    if homeTimer != null then
        call HomeTimerPet.remove(GetHandleId(homeTimer))
        call PauseTimer(homeTimer)
        call DestroyTimer(homeTimer)
        set PetHomeTimer.timer[petId] = null
    endif
    set homeTimer = null
endfunction

private function IsPetAtHome takes unit pet returns boolean
    local real dx
    local real dy

    if pet == null or gg_rct_NazgrekIntroPoint == null then
        return true
    endif

    set dx = GetUnitX(pet) - GetRectCenterX(gg_rct_NazgrekIntroPoint)
    set dy = GetUnitY(pet) - GetRectCenterY(gg_rct_NazgrekIntroPoint)
    return dx * dx + dy * dy <= PET_HOME_ARRIVE_DISTANCE * PET_HOME_ARRIVE_DISTANCE
endfunction

private function TeleportPetHomeFallback takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit pet = HomeTimerPet.unit[timerId]

    if pet != null and GetUnitTypeId(pet) != 0 and gg_rct_NazgrekIntroPoint != null and not IsPetAtHome(pet) then
        call SetUnitX(pet, GetRectCenterX(gg_rct_NazgrekIntroPoint))
        call SetUnitY(pet, GetRectCenterY(gg_rct_NazgrekIntroPoint))
        call IssueImmediateOrder(pet, "stop")
    endif

    if pet != null then
        set PetHomeTimer.timer[GetHandleId(pet)] = null
    endif
    call HomeTimerPet.remove(timerId)
    call DestroyTimer(expired)
    set pet = null
    set expired = null
endfunction

private function StartPetHomeFallback takes unit pet returns nothing
    local timer homeTimer

    if pet == null or gg_rct_NazgrekIntroPoint == null then
        return
    endif

    call StopPetHomeFallback(pet)
    set homeTimer = CreateTimer()
    set PetHomeTimer.timer[GetHandleId(pet)] = homeTimer
    set HomeTimerPet.unit[GetHandleId(homeTimer)] = pet
    call TimerStart(homeTimer, PET_HOME_TELEPORT_DELAY, false, function TeleportPetHomeFallback)
    set homeTimer = null
endfunction

private function SendPetHome takes unit pet returns nothing
    if pet == null then
        return
    endif

    call SetUnitInvulnerable(pet, true)
    call SetUnitOwner(pet, Player(PET_OWNER_INDEX), true)
    call RemovePetWander(pet)
    if gg_rct_NazgrekIntroPoint != null then
        call IssuePointOrder(pet, "move", GetRectCenterX(gg_rct_NazgrekIntroPoint), GetRectCenterY(gg_rct_NazgrekIntroPoint))
        call StartPetHomeFallback(pet)
    endif
endfunction

private function StoreActivePet takes unit pet, boolean playSound, boolean announce returns boolean
    if pet == null or udg_TamedUnits == null or not IsUnitInGroup(pet, udg_TamedUnits) then
        return false
    endif
    if pet == udg_TamedUnit and udg_Pet_Dead then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(pet) + " must recover before returning home.")
        return false
    endif

    set udg_CompanionUnitKicked = pet
    if playSound and gg_snd_UpkeepRing != null then
        call StartSound(gg_snd_UpkeepRing)
    endif

    call UnitExperience_DisableXP(pet, true)
    call Companions_UnregisterControlled(pet)
    call GroupRemoveUnit(udg_TamedUnits, pet)
    call RemovePetFocus(pet)
    call IssueImmediateOrder(pet, "stop")
    call SetUnitPathing(pet, true)
    call PauseUnit(pet, false)
    call SetUnitTimeScale(pet, 1.00)
    call RefreshPetDamageTrigger(null)

    if pet == udg_TamedUnit then
        set udg_TamedUnit = null
    endif
    set udg_Pet_Dead = false
    call SendPetHome(pet)

    if announce then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(pet) + " is waiting at home.")
    endif
    return true
endfunction

private function CountTamedRosterPetEnum takes nothing returns nothing
    local unit pet = GetEnumUnit()
    if pet != null and pet != udg_Shadowclaw then
        set TamedRosterCount = TamedRosterCount + 1
    endif
    set pet = null
endfunction

private function GetTamedRosterCount takes nothing returns integer
    set TamedRosterCount = 0
    if PetRoster != null then
        call ForGroup(PetRoster, function CountTamedRosterPetEnum)
    endif
    return TamedRosterCount
endfunction

private function FindDismissPetEnum takes nothing returns nothing
    local unit pet = GetEnumUnit()
    if pet != null and pet != udg_Shadowclaw and pet != udg_TamedUnit then
        if DismissPetOne == null then
            set DismissPetOne = pet
        elseif DismissPetTwo == null then
            set DismissPetTwo = pet
        endif
    endif
    set pet = null
endfunction

private function DropPetItems takes unit pet returns nothing
    local integer slot = 0
    local integer maxSlots = UnitInventorySize(pet)
    local item droppedItem
    local real angle
    local real x = GetUnitX(pet)
    local real y = GetUnitY(pet)

    if maxSlots > 6 then
        set maxSlots = 6
    endif

    loop
        exitwhen slot >= maxSlots
        set droppedItem = UnitItemInSlot(pet, slot)
        if droppedItem != null then
            call UnitRemoveItem(pet, droppedItem)
            set angle = 6.2831853 * I2R(slot) / 6.00
            call SetItemPosition(droppedItem, x + 90.00 * Cos(angle), y + 90.00 * Sin(angle))
        endif
        set slot = slot + 1
    endloop

    set droppedItem = null
endfunction

private function DismissRosterPet takes unit pet returns nothing
    if pet == null or not IsRosterPet(pet) or pet == udg_Shadowclaw or pet == udg_TamedUnit then
        return
    endif

    call StopPetHomeFallback(pet)
    if gg_rct_NazgrekIntroPoint != null then
        call SetUnitX(pet, GetRectCenterX(gg_rct_NazgrekIntroPoint))
        call SetUnitY(pet, GetRectCenterY(gg_rct_NazgrekIntroPoint))
        call IssueImmediateOrder(pet, "stop")
    endif
    call DropPetItems(pet)
    call GroupRemoveUnit(PetRoster, pet)
    call UnitExperience_DisableXP(pet, true)
    call Companions_UnregisterControlled(pet)
    call RemovePetFocus(pet)
    call SetUnitInvulnerable(pet, false)
    call SetUnitOwner(pet, Player(PLAYER_NEUTRAL_PASSIVE), true)
    if GetUnitAbilityLevel(pet, ABIL_WANDER_NEUTRAL) == 0 then
        call UnitAddAbility(pet, ABIL_WANDER_NEUTRAL)
    endif
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(pet) + " has been dismissed.")
endfunction

private function OnDismissPet takes nothing returns nothing
    local button clicked = GetClickedButton()

    call DialogDisplay(Player(CONTROL_PLAYER_INDEX), DismissPetDialog, false)
    if clicked == DismissPetButtonOne then
        call DismissRosterPet(DismissPetOne)
    elseif clicked == DismissPetButtonTwo then
        call DismissRosterPet(DismissPetTwo)
    endif

    set DismissPetButtonOne = null
    set DismissPetButtonTwo = null
    set DismissPetOne = null
    set DismissPetTwo = null
    set clicked = null
endfunction

private function ShowDismissPetDialog takes nothing returns nothing
    if GetTamedRosterCount() <= MAX_NON_SHADOWCLAW_PETS then
        return
    endif

    set DismissPetOne = null
    set DismissPetTwo = null
    call ForGroup(PetRoster, function FindDismissPetEnum)
    if DismissPetOne == null or DismissPetTwo == null then
        return
    endif

    if DismissPetDialog == null then
        set DismissPetDialog = DialogCreate()
        set DismissPetTrigger = CreateTrigger()
        call TriggerRegisterDialogEvent(DismissPetTrigger, DismissPetDialog)
        call TriggerAddAction(DismissPetTrigger, function OnDismissPet)
    endif

    call DialogClear(DismissPetDialog)
    call DialogSetMessage(DismissPetDialog, "Choose a pet to dismiss")
    set DismissPetButtonOne = DialogAddButton(DismissPetDialog, GetUnitName(DismissPetOne), 0)
    set DismissPetButtonTwo = DialogAddButton(DismissPetDialog, GetUnitName(DismissPetTwo), 0)
    call DialogDisplay(Player(CONTROL_PLAYER_INDEX), DismissPetDialog, true)
endfunction

private function RegisterPetUnit takes unit pet, unit leader, boolean resetCounters, boolean startSuspended returns nothing
    local integer petKey
    local boolean registered
    local unit focusLeader = leader

    if pet == null or GetUnitTypeId(pet) == 0 then
        set focusLeader = null
        return
    endif

    if pet == udg_Shadowclaw then
        if udg_Nazgrek != null then
            set focusLeader = udg_Nazgrek
        endif
    endif
    call StopPetHomeFallback(pet)

    set petKey = GetUnitUserData(pet)
    if petKey > 0 then
        set udg_UnitHider_ReferenceUnits[petKey] = pet
    endif

    call EnsurePetGroup()
    call GroupAddUnit(udg_TamedUnits, pet)
    call GroupAddUnit(PetRoster, pet)
    call RemovePetWander(pet)
    call SetPetFocus(pet, focusLeader)
    call SetUnitPathing(pet, true)
    call PauseUnit(pet, false)
    call SetUnitTimeScale(pet, 1.00)
    call SetUnitOwner(pet, Player(PET_OWNER_INDEX), true)
    call SetUnitInvulnerable(pet, false)
    if UnitInventorySize(pet) == 0 then
        call UnitAddAbility(pet, ABIL_INVENTORY_HERO)
    endif

    set udg_TamedUnit = pet
    set udg_Pet_Dead = false
    if resetCounters then
        set udg_TamedUnitKillCount = 0
        set udg_TamedUnitDeathCount = 0
    endif

    set registered = UnitExperience_IsUnitRegistered(pet)
    if registered then
        call UnitExperience_DisableXP(pet, false)
    else
        call UnitExperience_RegisterUnit(pet)
    endif

    call Companions_RegisterControlled(pet, focusLeader, COMPANION_MODE_DEFEND)
    if pet == udg_Shadowclaw then
        call Companions_SetLeader(pet, focusLeader)
    endif
    if startSuspended then
        call Companions_Halt(pet)
    endif
    call RefreshPetDamageTrigger(pet)

    set focusLeader = null
endfunction

private function ScaleShadowclawStats takes unit pet returns nothing
    if pet == null or udg_Nazgrek == null then
        return
    endif

    set udg_Shadowclaw_hp_base = R2I(GetUnitState(pet, UNIT_STATE_MAX_LIFE))
    set udg_Shadowclaw_armor_base = BlzGetUnitArmor(pet)
    set udg_Shadowclaw_dmg_base = BlzGetUnitBaseDamage(pet, 0)

    set udg_Shadowclaw_hp = udg_Shadowclaw_hp_base + R2I(GetUnitState(udg_Nazgrek, UNIT_STATE_MAX_LIFE) * 0.75)
    set udg_Shadowclaw_armor = udg_Shadowclaw_armor_base + BlzGetUnitArmor(udg_Nazgrek) * 0.80
    set udg_Shadowclaw_dmg = udg_Shadowclaw_dmg_base + R2I(I2R(BlzGetUnitBaseDamage(udg_Nazgrek, 0)) * 0.75)

    call BlzSetUnitMaxHP(pet, udg_Shadowclaw_hp)
    call SetUnitState(pet, UNIT_STATE_LIFE, I2R(udg_Shadowclaw_hp))
    call BlzSetUnitArmor(pet, udg_Shadowclaw_armor)
    call BlzSetUnitBaseDamage(pet, udg_Shadowclaw_dmg, 0)
endfunction

private function FindShadowclawEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    if FoundShadowclaw == null and PetDefinitions_IsShadowclawType(GetUnitTypeId(u)) then
        set FoundShadowclaw = u
    endif
    set u = null
endfunction

private function FindShadowclaw takes nothing returns unit
    set FoundShadowclaw = null
    call GroupClear(PetEnumGroup)
    call GroupEnumUnitsInRect(PetEnumGroup, bj_mapInitialPlayableArea, null)
    call ForGroup(PetEnumGroup, function FindShadowclawEnum)
    call GroupClear(PetEnumGroup)
    return FoundShadowclaw
endfunction

private function OnShadowclawInitTimer takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local unit shadowclaw = udg_Shadowclaw

    if shadowclaw == null or GetUnitTypeId(shadowclaw) == 0 then
        set shadowclaw = FindShadowclaw()
        set udg_Shadowclaw = shadowclaw
    endif

    if shadowclaw == null or udg_Nazgrek == null then
        if expired != null then
            call TimerStart(expired, SHADOWCLAW_INIT_RETRY_DELAY, false, function OnShadowclawInitTimer)
        endif
        set shadowclaw = null
        set expired = null
        return
    endif

    if shadowclaw != null then
        call ScaleShadowclawStats(shadowclaw)
        call RegisterPetUnit(shadowclaw, udg_Nazgrek, true, udg_InCinematic)
    endif

    if expired != null then
        call DestroyTimer(expired)
    endif
    set shadowclaw = null
    set expired = null
endfunction

private function CompleteTame takes unit caster, unit target returns nothing
    local unit leader
    local unit currentPet = udg_TamedUnit

    if caster == null or target == null or GetUnitTypeId(target) == 0 then
        set currentPet = null
        return
    endif

    if currentPet != null and currentPet != target then
        if not StoreActivePet(currentPet, false, true) then
            set currentPet = null
            return
        endif
    endif

    set leader = GetPreferredLeader(caster)
    call RegisterPetUnit(target, leader, true, false)

    if gg_snd_Rescue != null then
        call StartSound(gg_snd_Rescue)
    endif
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " has been tamed.")
    call ShowDismissPetDialog()

    set leader = null
    set currentPet = null
endfunction

private function FinishTame takes unit caster, integer abilityId returns nothing
    local integer casterKey
    local unit target

    if caster == null or not IsTameAbility(abilityId) then
        return
    endif

    set casterKey = GetUnitUserData(caster)
    if casterKey <= 0 then
        return
    endif

    set target = TameTarget.unit[casterKey]
    if TameReady[casterKey] == 1 and target != null then
        call CompleteTame(caster, target)
    endif

    call ClearTameState(casterKey, true)
    set target = null
endfunction

private function CancelTame takes unit caster, integer abilityId returns nothing
    local integer casterKey

    if caster == null or not IsTameAbility(abilityId) then
        return
    endif

    set casterKey = GetUnitUserData(caster)
    if casterKey <= 0 then
        return
    endif

    if TameTarget.unit[casterKey] != null then
        call ClearTameState(casterKey, true)
    endif
endfunction

private function InvitePet takes unit caster, unit target returns nothing
    local unit currentPet = udg_TamedUnit

    if target == null or not IsRosterPet(target) or target == currentPet then
        set currentPet = null
        return
    endif

    if currentPet != null then
        if not StoreActivePet(currentPet, false, true) then
            set currentPet = null
            return
        endif
    endif

    if target == udg_Shadowclaw then
        call ScaleShadowclawStats(target)
    endif
    call RegisterPetUnit(target, GetPreferredLeader(caster), true, false)
    if gg_snd_Rescue != null then
        call StartSound(gg_snd_Rescue)
    endif
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " has joined you again.")
    set currentPet = null
endfunction

private function KickPet takes unit pet returns nothing
    call StoreActivePet(pet, true, true)
endfunction

private function GetCommandPlayer takes unit caster returns player
    if caster == null then
        return Player(CONTROL_PLAYER_INDEX)
    endif
    if GetOwningPlayer(caster) == Player(PET_OWNER_INDEX) then
        return Player(CONTROL_PLAYER_INDEX)
    endif
    return GetOwningPlayer(caster)
endfunction

private function FindSelectedPetTarget takes nothing returns nothing
    local unit pet = GetEnumUnit()

    if pet != null and IsUnitSelected(pet, SelectedPetPlayer) then
        set SelectedPetCount = SelectedPetCount + 1
        if SelectedPetTarget == null then
            set SelectedPetTarget = pet
        endif
    endif

    set pet = null
endfunction

private function GetSelectedPetTarget takes player commandPlayer returns unit
    local unit selectedTarget

    if udg_TamedUnits == null then
        return null
    endif

    set SelectedPetPlayer = commandPlayer
    set SelectedPetTarget = null
    set SelectedPetCount = 0
    call ForGroup(udg_TamedUnits, function FindSelectedPetTarget)

    if SelectedPetCount == 1 then
        set selectedTarget = SelectedPetTarget
    else
        set selectedTarget = null
    endif

    set SelectedPetPlayer = null
    set SelectedPetTarget = null
    set SelectedPetCount = 0
    return selectedTarget
endfunction

private function ResolvePetCommandTarget takes unit caster, unit target returns unit
    if target != null then
        return target
    endif
    if caster != null and udg_TamedUnits != null and IsUnitInGroup(caster, udg_TamedUnits) then
        return caster
    endif
    return GetSelectedPetTarget(GetCommandPlayer(caster))
endfunction

private function OnSpellEffect takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()

    if IsTameAbility(abilityId) then
        call StartTame(caster, target, abilityId)
    elseif abilityId == ABIL_INVITE then
        call InvitePet(caster, target)
    elseif abilityId == ABIL_KICK then
        set target = ResolvePetCommandTarget(caster, target)
        call KickPet(target)
    endif

    set caster = null
    set target = null
endfunction

private function OnSpellFinish takes nothing returns nothing
    call FinishTame(GetTriggerUnit(), GetSpellAbilityId())
endfunction

private function OnSpellEndcast takes nothing returns nothing
    call CancelTame(GetTriggerUnit(), GetSpellAbilityId())
endfunction

private function OnDamageModifier takes nothing returns nothing
    local unit damaged = udg_DamageEventTarget
    local integer damagedKey
    local real life

    if damaged == null then
        return
    endif

    set damagedKey = GetUnitUserData(damaged)
    if damagedKey > 0 and udg_Pet_TamerChanneling[damagedKey] then
        set udg_DamageEventAmount = udg_DamageEventAmount * TAME_DAMAGE_MULTIPLIER
    endif

    if damaged == udg_TamedUnit and not udg_Pet_Dead and udg_DamageEventAmount > 0.00 then
        set life = GetWidgetLife(damaged)
        if udg_DamageEventAmount >= life - 0.41 then
            if life > 1.00 then
                set udg_DamageEventAmount = life - 1.00
            else
                set udg_DamageEventAmount = 0.00
            endif
            call FatiguePet(damaged)
        endif
    endif

    set damaged = null
endfunction

private function OnPetPickupItem takes nothing returns nothing
    local unit pet = GetManipulatingUnit()
    local item pickedItem = GetManipulatedItem()

    if pet == null or pickedItem == null or udg_TamedUnits == null or not IsUnitInGroup(pet, udg_TamedUnits) then
        set pet = null
        set pickedItem = null
        return
    endif

    if IsRawMeat(GetItemTypeId(pickedItem)) then
        call RemoveItem(pickedItem)
        call HealPetByPercent(pet, 25.00)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", pet, "origin"))
        if gg_snd_Devour != null then
            call StartSound(gg_snd_Devour)
        endif
    else
        call UnitRemoveItem(pet, pickedItem)
        call SetItemPosition(pickedItem, GetUnitX(pet) + 60.00, GetUnitY(pet))
    endif

    set pet = null
    set pickedItem = null
endfunction

private function OnRenameChat takes nothing returns nothing
    local string chatText = GetEventPlayerChatString()
    local string newName
    local unit pet = udg_TamedUnit
    local integer petKey

    if pet == null or GetPetCount() <= 0 then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "You do not have a pet to rename.")
        set pet = null
        return
    endif

    if pet == udg_Shadowclaw then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "Shadowclaw cannot be renamed.")
        set pet = null
        return
    endif

    set newName = SubString(chatText, 12, StringLength(chatText))
    if newName == "" then
        set pet = null
        return
    endif

    set petKey = GetUnitUserData(pet)
    if petKey > 0 and udg_Pet_Renamed[petKey] then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "This pet has already been renamed.")
        set pet = null
        return
    endif

    call BlzSetUnitName(pet, newName)
    call BlzSetUnitStringField(pet, UNIT_SF_NAME, newName)
    if petKey > 0 then
        set udg_Pet_Renamed[petKey] = true
    endif
    call DisplayTextToPlayer(Player(0), 0.00, 0.00, "Pet renamed to " + newName + ".")

    set pet = null
endfunction

public function CanRename takes unit pet returns boolean
    local integer petKey

    if pet == null or pet != udg_TamedUnit or GetPetCount() <= 0 then
        return false
    endif

    if pet == udg_Shadowclaw then
        return false
    endif

    set petKey = GetUnitUserData(pet)
    if petKey > 0 and udg_Pet_Renamed[petKey] then
        return false
    endif

    return true
endfunction

public function ShowRenamePrompt takes unit pet returns nothing
    local integer petKey

    if pet == null or pet != udg_TamedUnit or GetPetCount() <= 0 then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "You do not have a pet to rename.")
        return
    endif

    if pet == udg_Shadowclaw then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "Shadowclaw cannot be renamed.")
        return
    endif

    set petKey = GetUnitUserData(pet)
    if petKey > 0 and udg_Pet_Renamed[petKey] then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "This pet has already been renamed.")
        return
    endif

    call DisplayTextToPlayer(Player(0), 0.00, 0.00, "Type |cff66ccff/pet rename <name>|r to rename your pet.")
endfunction

public function IsPetUnit takes unit pet returns boolean
    return IsRosterPet(pet)
endfunction

public function IsDead takes unit pet returns boolean
    return pet != null and pet == udg_TamedUnit and udg_Pet_Dead
endfunction

public function Revive takes unit pet, real lifePercent, real manaPercent, boolean showEffects returns boolean
    if showEffects then
        return RestoreFatiguedPet(pet, lifePercent, manaPercent, true, "Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl")
    endif
    return RestoreFatiguedPet(pet, lifePercent, manaPercent, true, "")
endfunction

public function GetClassInfoText takes unit pet returns string
    return GetPetClassInfoTextInternal(pet)
endfunction

public function GetTypeInfoText takes unit pet returns string
    return GetPetTypeInfoTextInternal(pet)
endfunction

public function GetAbilityInfoText takes unit pet returns string
    return GetPetAbilityInfoTextInternal(pet)
endfunction

private function Init takes nothing returns nothing
    local trigger t
    local timer shadowclawTimer

    call EnsureState()

    call Events_RegisterPlayerUnitEvent(function OnSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitEvent(function OnSpellFinish, EVENT_PLAYER_UNIT_SPELL_FINISH)
    call Events_RegisterPlayerUnitEvent(function OnSpellEndcast, EVENT_PLAYER_UNIT_SPELL_ENDCAST)
    call Events_RegisterPlayerUnitEvent(function OnPetPickupItem, EVENT_PLAYER_UNIT_PICKUP_ITEM)

    set t = CreateTrigger()
    call TriggerRegisterVariableEvent(t, "udg_DamageModifierEvent", EQUAL, 1.00)
    call TriggerAddAction(t, function OnDamageModifier)

    set t = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(t, Player(0), "/pet rename ", false)
    call TriggerAddAction(t, function OnRenameChat)

    set shadowclawTimer = CreateTimer()
    call TimerStart(shadowclawTimer, 2.00, false, function OnShadowclawInitTimer)

    set t = null
    set shadowclawTimer = null
endfunction

endlibrary
