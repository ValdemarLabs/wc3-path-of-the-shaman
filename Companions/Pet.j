/**
    Pet

    Author: Valdemar
    Credits:
    - Old GUI pet/taming triggers, converted and consolidated into JASS.
    Version:

    Description:
    Pet and tame-beast logic. Pets use the companion control layer for follow
    modes, but keep separate ownership, tame, fatigue, revival, food, rename,
    and Shadowclaw rules.

**/
library Pet initializer Init requires Table, Companions, UnitExperience, DamageEngine, FloatingTextSimple

globals
    private constant boolean DEBUG = false
    private constant integer MAX_PLAYER_INDEX = 27
    private constant integer PET_OWNER_INDEX = 18
    private constant real TAME_DURATION = 10.00
    private constant real PET_REVIVE_DURATION = 20.00
    private constant real TAME_DAMAGE_MULTIPLIER = 1.75

    private constant integer ABIL_INVITE = 'A622'
    private constant integer ABIL_KICK = 'A621'
    private constant integer ABIL_TAME_I = 'A623'
    private constant integer ABIL_TAME_II = 'A625'
    private constant integer ABIL_TAME_III = 'A627'
    private constant integer ABIL_INVENTORY_HERO = 'AInv'
    private constant integer ABIL_WANDER_NEUTRAL = 'Awan'

    private constant integer UNIT_SHADOWCLAW = 'n655'
    private constant integer UNIT_PIG_5 = 'n63C'
    private constant integer UNIT_PIG_10 = 'n63U'
    private constant integer UNIT_TIMBER_WOLF = 'nwlt'
    private constant integer UNIT_GIANT_WOLF = 'nwlg'
    private constant integer UNIT_DIRE_WOLF = 'nwld'
    private constant integer UNIT_STAG_1 = 'nder'
    private constant integer UNIT_STAG_5 = 'n63A'
    private constant integer UNIT_STAG_10 = 'n63B'
    private constant integer UNIT_BEAR_CUB = 'ngz1'
    private constant integer UNIT_BEAR = 'ngz2'
    private constant integer UNIT_MOTHER_BEAR = 'ngz4'
    private constant integer UNIT_FEROCIOUS_BEAR = 'ngza'
    private constant integer UNIT_PANTHER_CUB = 'n61O'
    private constant integer UNIT_PANTHER_10 = 'n016'
    private constant integer UNIT_PANTHER_15 = 'n015'
    private constant integer UNIT_TIGER_2 = 'n61P'
    private constant integer UNIT_TIGER_10 = 'n017'
    private constant integer UNIT_TIGER_15 = 'n018'
    private constant integer UNIT_SEA_TURTLE_10 = 'n01F'
    private constant integer UNIT_GIANT_SEA_TURTLE_15 = 'n01G'
    private constant integer UNIT_GIANT_MOTH_12 = 'n00V'
    private constant integer UNIT_LYNX_5 = 'n63M'

    private constant integer ITEM_RAW_WOLF = 'I61O'
    private constant integer ITEM_RAW_STAG = 'I61P'
    private constant integer ITEM_RAW_BEAR = 'I61Q'
    private constant integer ITEM_RAW_LIZARD = 'I61R'
    private constant integer ITEM_RAW_HAWK = 'I61S'
    private constant integer ITEM_RAW_MURLOC = 'I61T'
    private constant integer ITEM_RAW_TURTLE = 'I61U'
    private constant integer ITEM_RAW_TIGER = 'I61V'
    private constant integer ITEM_RAW_PANTHER = 'I61W'
    private constant integer ITEM_RAW_RAPTOR = 'I61X'
    private constant integer ITEM_RAW_SNAKE = 'I61Y'
    private constant integer ITEM_RAW_MAKRURA = 'I61Z'
    private constant integer ITEM_RAW_BOAR = 'I620'
    private constant integer ITEM_RAW_CRAWLER = 'I621'
    private constant integer ITEM_RAW_RABBIT = 'I622'
    private constant integer ITEM_RAW_COW = 'I623'

    private Table TameTarget = 0
    private Table TameTimer = 0
    private Table TameTimerCaster = 0
    private Table TameReady = 0
    private Table TameAbility = 0
    private Table FreezeTimerUnit = 0

    private group PetEnumGroup = null
    private unit FoundShadowclaw = null
    private trigger PetDamageTrigger = null
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
        set TameAbility = Table.create()
        set FreezeTimerUnit = Table.create()
    endif
    if PetEnumGroup == null then
        set PetEnumGroup = CreateGroup()
    endif
endfunction

private function IsAliveUnit takes unit u returns boolean
    return u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD)
endfunction

private function GetPetCount takes nothing returns integer
    if udg_TamedUnits == null then
        return 0
    endif
    return CountUnitsInGroup(udg_TamedUnits)
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
    return unitTypeId == UNIT_PIG_5 or unitTypeId == UNIT_PIG_10 or unitTypeId == UNIT_TIMBER_WOLF or unitTypeId == UNIT_GIANT_WOLF or unitTypeId == UNIT_DIRE_WOLF or unitTypeId == UNIT_STAG_1 or unitTypeId == UNIT_STAG_5 or unitTypeId == UNIT_STAG_10 or unitTypeId == UNIT_BEAR_CUB or unitTypeId == UNIT_BEAR or unitTypeId == UNIT_MOTHER_BEAR or unitTypeId == UNIT_FEROCIOUS_BEAR or unitTypeId == UNIT_PANTHER_CUB or unitTypeId == UNIT_PANTHER_10 or unitTypeId == UNIT_PANTHER_15 or unitTypeId == UNIT_TIGER_2 or unitTypeId == UNIT_TIGER_10 or unitTypeId == UNIT_TIGER_15 or unitTypeId == UNIT_SEA_TURTLE_10 or unitTypeId == UNIT_GIANT_SEA_TURTLE_15 or unitTypeId == UNIT_GIANT_MOTH_12 or unitTypeId == UNIT_LYNX_5
endfunction

private function IsRawMeat takes integer itemTypeId returns boolean
    return itemTypeId == ITEM_RAW_WOLF or itemTypeId == ITEM_RAW_STAG or itemTypeId == ITEM_RAW_BEAR or itemTypeId == ITEM_RAW_LIZARD or itemTypeId == ITEM_RAW_HAWK or itemTypeId == ITEM_RAW_MURLOC or itemTypeId == ITEM_RAW_TURTLE or itemTypeId == ITEM_RAW_TIGER or itemTypeId == ITEM_RAW_PANTHER or itemTypeId == ITEM_RAW_RAPTOR or itemTypeId == ITEM_RAW_SNAKE or itemTypeId == ITEM_RAW_MAKRURA or itemTypeId == ITEM_RAW_BOAR or itemTypeId == ITEM_RAW_CRAWLER or itemTypeId == ITEM_RAW_RABBIT or itemTypeId == ITEM_RAW_COW
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
    call TameAbility.remove(casterKey)
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

    if GetPetCount() >= 1 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "You already have a beast companion.")
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
    set TameAbility[casterKey] = abilityId
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

private function OnReviveTimer takes nothing returns nothing
    local unit pet = udg_TamedUnit

    if pet == null or GetUnitTypeId(pet) == 0 then
        set pet = null
        return
    endif

    call PauseUnit(pet, false)
    call SetUnitTimeScale(pet, 1.00)
    call ResetUnitAnimation(pet)
    call SetUnitAnimation(pet, "stand")
    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl", pet, "origin"))

    set udg_Pet_Dead = false
    call HealPetByPercent(pet, 25.00)
    call SetUnitInvulnerable(pet, false)
    call SetUnitOwner(pet, Player(PET_OWNER_INDEX), true)
    call Companions_Resume(pet)
    call RefreshPetDamageTrigger(pet)

    if udg_Pet_DeathPoint != null then
        call RemoveLocation(udg_Pet_DeathPoint)
        set udg_Pet_DeathPoint = null
    endif

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

private function RegisterPetUnit takes unit pet, unit leader, boolean resetCounters returns nothing
    local integer petKey
    local boolean registered

    if pet == null or GetUnitTypeId(pet) == 0 then
        return
    endif

    set petKey = GetUnitUserData(pet)
    if petKey > 0 then
        set udg_UnitHider_ReferenceUnits[petKey] = pet
    endif

    if udg_TamedUnits != null then
        call GroupAddUnit(udg_TamedUnits, pet)
    endif
    call RemovePetWander(pet)
    call SetPetFocus(pet, leader)
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

    call Companions_RegisterControlled(pet, leader, COMPANION_MODE_DEFEND)
    call RefreshPetDamageTrigger(pet)

    if gg_trg_MultiboardUpdate_Add_Tamed != null then
        call TriggerExecute(gg_trg_MultiboardUpdate_Add_Tamed)
    endif
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
    if FoundShadowclaw == null and GetUnitTypeId(u) == UNIT_SHADOWCLAW then
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
    local unit shadowclaw = udg_Shadowclaw

    if shadowclaw == null or GetUnitTypeId(shadowclaw) == 0 then
        set shadowclaw = FindShadowclaw()
        set udg_Shadowclaw = shadowclaw
    endif

    if shadowclaw != null then
        call ScaleShadowclawStats(shadowclaw)
        call RegisterPetUnit(shadowclaw, udg_Nazgrek, true)
    endif

    set shadowclaw = null
endfunction

private function CompleteTame takes unit caster, unit target returns nothing
    local unit leader

    if caster == null or target == null or GetUnitTypeId(target) == 0 then
        return
    endif

    if GetPetCount() >= 1 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "You already have a beast companion.")
        return
    endif

    set leader = GetPreferredLeader(caster)
    call RegisterPetUnit(target, leader, true)

    if gg_snd_Rescue != null then
        call StartSound(gg_snd_Rescue)
    endif
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " has been tamed.")

    set leader = null
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

private function InviteShadowclaw takes unit caster, unit target returns nothing
    if target == null or target != udg_Shadowclaw then
        return
    endif

    if GetPetCount() >= 1 then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "You already have a beast companion.")
        return
    endif

    call ScaleShadowclawStats(target)
    call RegisterPetUnit(target, GetPreferredLeader(caster), true)
    if gg_snd_Rescue != null then
        call StartSound(gg_snd_Rescue)
    endif
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(target) + " has joined you again.")
endfunction

private function KickPet takes unit pet returns nothing
    if pet == null or udg_TamedUnits == null or not IsUnitInGroup(pet, udg_TamedUnits) then
        return
    endif

    set udg_CompanionUnitKicked = pet
    if gg_snd_UpkeepRing != null then
        call StartSound(gg_snd_UpkeepRing)
    endif

    call UnitExperience_DisableXP(pet, true)
    call Companions_UnregisterControlled(pet)
    call GroupRemoveUnit(udg_TamedUnits, pet)
    call RemovePetFocus(pet)
    call IssueImmediateOrder(pet, "stop")
    call RefreshPetDamageTrigger(null)

    if gg_trg_MultiboardUpdate_Remove_Tamed != null then
        call TriggerExecute(gg_trg_MultiboardUpdate_Remove_Tamed)
    endif

    set udg_TamedUnit = null
    set udg_Pet_Dead = false

    if pet == udg_Shadowclaw then
        call SetUnitInvulnerable(pet, true)
        call SetUnitOwner(pet, Player(PET_OWNER_INDEX), true)
        call RemovePetWander(pet)
        if gg_rct_NazgrekIntroPoint != null then
            call SetUnitX(pet, GetRectCenterX(gg_rct_NazgrekIntroPoint))
            call SetUnitY(pet, GetRectCenterY(gg_rct_NazgrekIntroPoint))
        endif
    else
        call SetUnitOwner(pet, Player(PLAYER_NEUTRAL_PASSIVE), true)
        if GetUnitAbilityLevel(pet, ABIL_WANDER_NEUTRAL) == 0 then
            call UnitAddAbility(pet, ABIL_WANDER_NEUTRAL)
        endif
    endif

    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(pet) + " is no longer your pet.")
endfunction

private function OnSpellEffect takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()

    if IsTameAbility(abilityId) then
        call StartTame(caster, target, abilityId)
    elseif abilityId == ABIL_INVITE then
        call InviteShadowclaw(caster, target)
    elseif abilityId == ABIL_KICK then
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

    if damaged == null then
        return
    endif

    set damagedKey = GetUnitUserData(damaged)
    if damagedKey > 0 and udg_Pet_TamerChanneling[damagedKey] then
        set udg_DamageEventAmount = udg_DamageEventAmount * TAME_DAMAGE_MULTIPLIER
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
    if gg_trg_MultiboardUpdate_Add_Tamed != null then
        call TriggerExecute(gg_trg_MultiboardUpdate_Add_Tamed)
    endif
    call DisplayTextToPlayer(Player(0), 0.00, 0.00, "Pet renamed to " + newName + ".")

    set pet = null
endfunction

private function RegisterPlayerUnitEventAll takes trigger whichTrigger, playerunitevent whichEvent returns nothing
    local integer playerIndex = 0
    loop
        call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
        set playerIndex = playerIndex + 1
        exitwhen playerIndex > MAX_PLAYER_INDEX
    endloop
endfunction

private function Init takes nothing returns nothing
    local trigger t
    local timer shadowclawTimer

    call EnsureState()

    set t = CreateTrigger()
    call RegisterPlayerUnitEventAll(t, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerAddAction(t, function OnSpellEffect)

    set t = CreateTrigger()
    call RegisterPlayerUnitEventAll(t, EVENT_PLAYER_UNIT_SPELL_FINISH)
    call TriggerAddAction(t, function OnSpellFinish)

    set t = CreateTrigger()
    call RegisterPlayerUnitEventAll(t, EVENT_PLAYER_UNIT_SPELL_ENDCAST)
    call TriggerAddAction(t, function OnSpellEndcast)

    set t = CreateTrigger()
    call RegisterPlayerUnitEventAll(t, EVENT_PLAYER_UNIT_PICKUP_ITEM)
    call TriggerAddAction(t, function OnPetPickupItem)

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
