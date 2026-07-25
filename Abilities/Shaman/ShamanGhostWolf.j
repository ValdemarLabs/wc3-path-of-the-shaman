/**
    ShamanGhostWolf

    Author: Valdemar
    Version:

    Description:
    Ghost Wolf morph, return morph, Bite burst, and item handoff converted
    from GUI. Keeps the existing Nazgrek/Zulkis active-hero globals updated
    while storing the hidden original hero in the old GUI morph globals.

    Credits:
    - Old GUI "Ghost Wolf Morph", "Ghost Wolf Normal", "Ghost Wolf Bite",
      and "Ghost Wolf ItemTransfer" triggers

    How to install:
    Requires `Table`, `Events`, and `ShamanCommon`.
    Optionally integrates with `Companions` so focused companions and pets keep
    following the active hero form through the morph transition.
    Optionally integrates with `TerrainDamage` so the active wolf form is tracked
    instead of the hidden original hero.

**/
library ShamanGhostWolf initializer Init requires Table, Events, ShamanCommon, optional Companions, optional TerrainDamage

globals
    private constant real MORPH_DELAY = 1.00
    private constant real MORPHING_CLEAR_DELAY = 0.10
    private constant real BITE_DUMMY_OFFSET = 50.00
    private constant real BITE_DUMMY_LIFETIME = 0.50

    private Table TimerUnitByHandle = 0
    private Table TimerSlotByHandle = 0
    private Table TimerRankByHandle = 0
    private Table WolfCritByHandle = 0
    private Table WolfDodgeByHandle = 0
    private group RetargetFocusGroup = null
    private unit RetargetNewLeader = null
endglobals

private function EnsureState takes nothing returns nothing
    if TimerUnitByHandle == 0 then
        set TimerUnitByHandle = Table.create()
        set TimerSlotByHandle = Table.create()
        set TimerRankByHandle = Table.create()
        set WolfCritByHandle = Table.create()
        set WolfDodgeByHandle = Table.create()
    endif
endfunction

private function RetargetFocusedControlledUnit takes unit controlledUnit returns nothing
    if controlledUnit == null then
        return
    endif
    if RetargetNewLeader == null or RetargetFocusGroup == null then
        return
    endif
    if GetUnitTypeId(controlledUnit) == 0 then
        return
    endif
    if IsUnitInGroup(controlledUnit, RetargetFocusGroup) then
        static if LIBRARY_Companions then
            call Companions_SetLeader(controlledUnit, RetargetNewLeader)
        endif
    endif
endfunction

private function RetargetFocusedControlledEnum takes nothing returns nothing
    call RetargetFocusedControlledUnit(GetEnumUnit())
endfunction

private function RetargetFocusedFollowers takes integer heroSlot, unit newLeader returns nothing
    local integer displayIndex = 1
    local integer displayCount = 0

    static if LIBRARY_Companions then
        if newLeader == null then
            return
        endif

        set displayCount = Companions_GetControlledDisplayCount()
        if heroSlot == ShamanCommon_HERO_SLOT_ZULKIS then
            set RetargetFocusGroup = udg_CompanionFocusZulkis
        else
            set RetargetFocusGroup = udg_CompanionFocusNazgrek
        endif

        if RetargetFocusGroup == null then
            return
        endif

        set RetargetNewLeader = newLeader
        if udg_Companion_Group != null then
            call ForGroup(udg_Companion_Group, function RetargetFocusedControlledEnum)
        endif
        if udg_TamedUnits != null then
            call ForGroup(udg_TamedUnits, function RetargetFocusedControlledEnum)
        endif
        loop
            exitwhen displayIndex > displayCount
            call RetargetFocusedControlledUnit(Companions_GetControlledDisplayUnit(displayIndex))
            set displayIndex = displayIndex + 1
        endloop
        set RetargetNewLeader = null
        set RetargetFocusGroup = null
    endif
endfunction

private function IsGhostWolfType takes integer unitTypeId returns boolean
    return unitTypeId == ShamanCommon_UNIT_NAZGREK_GHOST_WOLF or unitTypeId == ShamanCommon_UNIT_ZULKIS_GHOST_WOLF or unitTypeId == ShamanCommon_UNIT_ZULKIS_RANGED_GHOST_WOLF
endfunction

private function GetBiteDamageAbility takes integer rank returns integer
    if rank == 1 then
        return ShamanCommon_ABILITY_BITE_DAMAGE_1
    elseif rank == 2 then
        return ShamanCommon_ABILITY_BITE_DAMAGE_2
    elseif rank == 3 then
        return ShamanCommon_ABILITY_BITE_DAMAGE_3
    elseif rank == 4 then
        return ShamanCommon_ABILITY_BITE_DAMAGE_4
    endif
    return ShamanCommon_ABILITY_BITE_DAMAGE_5
endfunction

private function SetMorphing takes integer heroSlot, boolean morphing returns nothing
    if heroSlot == ShamanCommon_HERO_SLOT_NAZGREK then
        set udg_NazgrekMorphing = morphing
    elseif heroSlot == ShamanCommon_HERO_SLOT_ZULKIS then
        set udg_ZulkisMorphing = morphing
    endif
endfunction

private function ClearMorphingTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local integer heroSlot = TimerSlotByHandle.integer[timerId]
    call SetMorphing(heroSlot, false)
    call TimerSlotByHandle.integer.remove(timerId)
    call DestroyTimer(expiredTimer)
    set expiredTimer = null
endfunction

private function StartMorphingClear takes integer heroSlot returns nothing
    local timer clearTimer
    call EnsureState()
    set clearTimer = CreateTimer()
    set TimerSlotByHandle.integer[GetHandleId(clearTimer)] = heroSlot
    call TimerStart(clearTimer, MORPHING_CLEAR_DELAY, false, function ClearMorphingTimer)
    set clearTimer = null
endfunction

private function GetMorphOriginal takes integer heroSlot returns unit
    if heroSlot == ShamanCommon_HERO_SLOT_NAZGREK then
        return udg_NazgrekMorph
    elseif heroSlot == ShamanCommon_HERO_SLOT_ZULKIS then
        return udg_ZulkisMorph
    endif
    return null
endfunction

private function SetMorphOriginal takes integer heroSlot, unit original returns nothing
    if heroSlot == ShamanCommon_HERO_SLOT_NAZGREK then
        set udg_NazgrekMorph = original
    elseif heroSlot == ShamanCommon_HERO_SLOT_ZULKIS then
        set udg_ZulkisMorph = original
    endif
endfunction

private function GetWolfType takes integer heroSlot returns integer
    if heroSlot == ShamanCommon_HERO_SLOT_NAZGREK then
        return ShamanCommon_UNIT_NAZGREK_GHOST_WOLF
    elseif heroSlot == ShamanCommon_HERO_SLOT_ZULKIS then
        return ShamanCommon_UNIT_ZULKIS_GHOST_WOLF
    endif
    return 0
endfunction

private function GetWolfCritBonus takes integer rank returns integer
    if rank <= 1 then
        return 0
    elseif rank == 2 then
        return 5
    elseif rank == 3 then
        return 10
    elseif rank == 4 then
        return 15
    endif
    return 20
endfunction

private function GetWolfDodgeBonus takes integer rank returns integer
    return rank * 5
endfunction

private function ApplyWolfAbilityLevels takes unit wolf, integer rank returns nothing
    call UnitAddAbility(wolf, ShamanCommon_ABILITY_GHOST_WOLF_BITE)
    call UnitAddAbility(wolf, ShamanCommon_ABILITY_GHOST_WOLF_FURIOUS_HOWL)
    call UnitAddAbility(wolf, ShamanCommon_ABILITY_GHOST_WOLF_PASSIVE)
    call UnitAddAbility(wolf, ShamanCommon_ABILITY_GHOST_WOLF_NORMAL)
    call SetUnitAbilityLevel(wolf, ShamanCommon_ABILITY_GHOST_WOLF_BITE, rank)
    call SetUnitAbilityLevel(wolf, ShamanCommon_ABILITY_GHOST_WOLF_FURIOUS_HOWL, rank)
    call SetUnitAbilityLevel(wolf, ShamanCommon_ABILITY_GHOST_WOLF_PASSIVE, rank)
    call SetUnitAbilityLevel(wolf, ShamanCommon_ABILITY_GHOST_WOLF_NORMAL, rank)
    call UnitRemoveAbility(wolf, ShamanCommon_ABILITY_ENHANCEMENT_CATEGORY)
endfunction

private function ApplyWolfBonuses takes unit original, unit wolf, integer rank returns nothing
    local integer handleId = GetHandleId(wolf)
    local integer customValue = GetUnitUserData(wolf)
    local integer crit = GetWolfCritBonus(rank)
    local integer dodge = GetWolfDodgeBonus(rank)
    local real armorMultiplier = 1.40 + I2R(rank) * 0.10
    local real damageMultiplier = 1.00 + I2R(rank) * 0.20

    if customValue > 0 then
        set udg_Stats_Crit[customValue] = udg_Stats_Crit[customValue] + crit
        set udg_Stats_Dodge[customValue] = udg_Stats_Dodge[customValue] + dodge
        set WolfCritByHandle.integer[handleId] = crit
        set WolfDodgeByHandle.integer[handleId] = dodge
    endif

    call BlzSetUnitArmor(wolf, BlzGetUnitArmor(original) * armorMultiplier)
    call BlzSetUnitBaseDamage(wolf, R2I(I2R(BlzGetUnitBaseDamage(original, 0)) * damageMultiplier), 0)
    call ApplyWolfAbilityLevels(wolf, rank)
endfunction

private function ClearWolfBonuses takes unit wolf returns nothing
    local integer handleId = GetHandleId(wolf)
    local integer customValue = GetUnitUserData(wolf)
    if customValue > 0 then
        set udg_Stats_Crit[customValue] = udg_Stats_Crit[customValue] - WolfCritByHandle.integer[handleId]
        set udg_Stats_Dodge[customValue] = udg_Stats_Dodge[customValue] - WolfDodgeByHandle.integer[handleId]
    endif
    call WolfCritByHandle.integer.remove(handleId)
    call WolfDodgeByHandle.integer.remove(handleId)
endfunction

private function FinishMorphToWolf takes unit original, integer heroSlot, integer rank returns nothing
    local player owner
    local real x
    local real y
    local unit wolf

    if not ShamanCommon_IsAlive(original) or heroSlot == ShamanCommon_HERO_SLOT_NONE then
        set original = null
        return
    endif

    call SetMorphing(heroSlot, true)
    call SetMorphOriginal(heroSlot, original)
    call UnitRemoveBuffs(original, true, true)
    call SetUnitPathing(original, false)

    set owner = GetOwningPlayer(original)
    set x = GetUnitX(original)
    set y = GetUnitY(original)
    set wolf = CreateUnit(owner, GetWolfType(heroSlot), x, y, GetUnitFacing(original))
    call ShamanCommon_SetHeroBySlot(heroSlot, wolf)
    call RetargetFocusedFollowers(heroSlot, wolf)
    call QueueUnitAnimation(wolf, "attack")
    call QueueUnitAnimation(wolf, "stand")
    call ShamanCommon_TransferHeroState(original, wolf)
    static if LIBRARY_TerrainDamage then
        call TerrainDamage_RemoveUnit(original)
        call TerrainDamage_AddUnit(wolf)
    endif
    call ShowUnit(original, false)
    call PauseUnit(original, true)
    call ApplyWolfBonuses(original, wolf, rank)
    call ShamanCommon_PlaySound(gg_snd_GhostWolfBegin)
    call ShamanCommon_SelectForOwner(wolf)
    call StartMorphingClear(heroSlot)

    set wolf = null
    set owner = null
    set original = null
endfunction

private function FinishReturnToHero takes unit wolf, integer heroSlot returns nothing
    local unit original = GetMorphOriginal(heroSlot)
    if not ShamanCommon_IsAlive(wolf) or original == null then
        set original = null
        set wolf = null
        return
    endif

    call SetMorphing(heroSlot, true)
    call SetUnitX(original, GetUnitX(wolf))
    call SetUnitY(original, GetUnitY(wolf))
    call BlzSetUnitFacingEx(original, GetUnitFacing(wolf))
    call ShamanCommon_TransferHeroState(wolf, original)
    call ClearWolfBonuses(wolf)
    static if LIBRARY_TerrainDamage then
        call TerrainDamage_RemoveUnit(wolf)
        call TerrainDamage_AddUnit(original)
    endif
    call RemoveUnit(wolf)
    call ShowUnit(original, true)
    call PauseUnit(original, false)
    call SetUnitPathing(original, true)
    call ShamanCommon_SetHeroBySlot(heroSlot, original)
    call RetargetFocusedFollowers(heroSlot, original)
    call SetMorphOriginal(heroSlot, null)
    call QueueUnitAnimation(original, "spell slam")
    call QueueUnitAnimation(original, "stand")
    call ShamanCommon_PlaySound(gg_snd_GhostWolfMorph)
    call ShamanCommon_SelectForOwner(original)
    call StartMorphingClear(heroSlot)

    set original = null
    set wolf = null
endfunction

private function MorphTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local unit original = TimerUnitByHandle.unit[timerId]
    local integer heroSlot = TimerSlotByHandle.integer[timerId]
    local integer rank = TimerRankByHandle.integer[timerId]
    call TimerUnitByHandle.unit.remove(timerId)
    call TimerSlotByHandle.integer.remove(timerId)
    call TimerRankByHandle.integer.remove(timerId)
    call DestroyTimer(expiredTimer)
    call FinishMorphToWolf(original, heroSlot, rank)
    set original = null
    set expiredTimer = null
endfunction

private function NormalTimer takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local unit wolf = TimerUnitByHandle.unit[timerId]
    local integer heroSlot = TimerSlotByHandle.integer[timerId]
    call TimerUnitByHandle.unit.remove(timerId)
    call TimerSlotByHandle.integer.remove(timerId)
    call DestroyTimer(expiredTimer)
    call FinishReturnToHero(wolf, heroSlot)
    set wolf = null
    set expiredTimer = null
endfunction

private function ScheduleMorph takes unit original returns nothing
    local timer morphTimer
    local integer heroSlot = ShamanCommon_GetHeroSlot(original)
    local integer rank = ShamanCommon_GetAbilityRank(original, ShamanCommon_ABILITY_GHOST_WOLF_MORPH)

    if heroSlot == ShamanCommon_HERO_SLOT_NONE or not ShamanCommon_IsAlive(original) then
        return
    endif

    call EnsureState()
    call QueueUnitAnimation(original, "spell slam")
    set morphTimer = CreateTimer()
    set TimerUnitByHandle.unit[GetHandleId(morphTimer)] = original
    set TimerSlotByHandle.integer[GetHandleId(morphTimer)] = heroSlot
    set TimerRankByHandle.integer[GetHandleId(morphTimer)] = rank
    call TimerStart(morphTimer, MORPH_DELAY, false, function MorphTimer)
    set morphTimer = null
endfunction

private function ScheduleReturn takes unit wolf returns nothing
    local timer normalTimer
    local integer heroSlot = ShamanCommon_GetHeroSlot(wolf)

    if heroSlot == ShamanCommon_HERO_SLOT_NONE or not IsGhostWolfType(GetUnitTypeId(wolf)) then
        return
    endif

    call EnsureState()
    call QueueUnitAnimation(wolf, "attack slam")
    set normalTimer = CreateTimer()
    set TimerUnitByHandle.unit[GetHandleId(normalTimer)] = wolf
    set TimerSlotByHandle.integer[GetHandleId(normalTimer)] = heroSlot
    call TimerStart(normalTimer, MORPH_DELAY, false, function NormalTimer)
    set normalTimer = null
endfunction

private function CastBiteBurst takes unit caster returns nothing
    local integer rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_GHOST_WOLF_BITE)
    local integer damageAbility = GetBiteDamageAbility(rank)
    local real amount = ShamanCommon_GetHybridDamageAmount(caster, ShamanCommon_ABILITY_GHOST_WOLF_BITE, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_STRENGTH, 1.10, ShamanCommon_STAT_AGILITY, 0.65)
    local real x = ShamanCommon_PolarX(GetUnitX(caster), BITE_DUMMY_OFFSET, GetUnitFacing(caster))
    local real y = ShamanCommon_PolarY(GetUnitY(caster), BITE_DUMMY_OFFSET, GetUnitFacing(caster))
    local unit dummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_BITE, x, y, bj_UNIT_FACING, BITE_DUMMY_LIFETIME)
    local ability dummyAbility

    call ShamanCommon_PlaySound(gg_snd_Bite)
    call UnitAddAbility(dummy, damageAbility)
    set dummyAbility = BlzGetUnitAbility(dummy, damageAbility)
    if dummyAbility != null then
        call BlzSetAbilityRealLevelField(dummyAbility, ABILITY_RLF_DAMAGE_PER_TARGET_EFK1, 0, amount)
    endif
    call IssueImmediateOrder(dummy, "fanofknives")

    set dummyAbility = null
    set dummy = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local unit caster = GetTriggerUnit()

    if abilityId == ShamanCommon_ABILITY_GHOST_WOLF_MORPH then
        call ScheduleMorph(caster)
    elseif abilityId == ShamanCommon_ABILITY_GHOST_WOLF_NORMAL then
        call ScheduleReturn(caster)
    elseif abilityId == ShamanCommon_ABILITY_GHOST_WOLF_BITE then
        call CastBiteBurst(caster)
    endif

    set caster = null
endfunction

private function HandleItemPickup takes nothing returns nothing
    local unit wolf = GetManipulatingUnit()
    local item pickedItem = GetManipulatedItem()
    local unit original

    if wolf == null or pickedItem == null or not IsGhostWolfType(GetUnitTypeId(wolf)) then
        set wolf = null
        set pickedItem = null
        return
    endif

    set original = GetMorphOriginal(ShamanCommon_GetHeroSlot(wolf))
    if original != null then
        call UnitRemoveItem(wolf, pickedItem)
        call UnitAddItem(original, pickedItem)
    endif

    set original = null
    set wolf = null
    set pickedItem = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    call Events_RegisterSpellEffect(function HandleSpellEffect)
    call Events_RegisterUnitPickupItem(function HandleItemPickup)
endfunction

endlibrary
