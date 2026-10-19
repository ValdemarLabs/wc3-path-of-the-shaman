/**
    ModernAbilityLoadout

    Author: Valdemar
    Version: 0.1.0

    Description:
    Stores twelve synchronized modern action-bar assignments independently for
    Nazgrek and Zul'kis. Assignments reference real learned ability rawcodes;
    spellbook wrapper abilities remain untouched for compatibility during the
    staged migration.

    Credits:
    - Blizzard Entertainment, Warcraft III ability API

    How to install:
    Import after AbilitiesPlayer, ShamanCommon, and ModernAbilityCatalog.
    Call mutating functions only from synchronized game code. A local frame
    click must send and validate sync data before changing this loadout.

    API:
    - set changed = ModernAbilityLoadout_Assign(whichHero, slot, abilityId)
    - set changed = ModernAbilityLoadout_Clear(whichHero, slot)
    - set abilityId = ModernAbilityLoadout_GetAbilityId(whichHero, slot)
    - set slot = ModernAbilityLoadout_FindSlot(whichHero, abilityId)
    - call ModernAbilityLoadout_FillFirstLearned(whichHero)
    - call ModernAbilityLoadout_Reset(whichHero)
    - set count = ModernAbilityLoadout_SLOT_COUNT

**/
library ModernAbilityLoadout requires AbilitiesPlayer, ShamanCommon, ModernAbilityCatalog

globals
    public constant integer SLOT_COUNT = 12

    private integer array MAL_AbilityId
endglobals

private function MAL_GetStorageIndex takes integer heroSlot, integer slot returns integer
    if heroSlot < ShamanCommon_HERO_SLOT_NAZGREK or heroSlot > ShamanCommon_HERO_SLOT_ZULKIS or slot < 1 or slot > SLOT_COUNT then
        return 0
    endif
    return heroSlot * SLOT_COUNT + slot
endfunction

private function MAL_GetCanonicalAbilityId takes integer abilityId returns integer
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return 0
    endif
    return AbilitiesPlayer_GetEntryAbilityId(entryIndex)
endfunction

private function MAL_IsLearnedActiveAbility takes unit whichHero, integer abilityId returns boolean
    local integer entryIndex
    local integer canonicalAbilityId = MAL_GetCanonicalAbilityId(abilityId)

    if whichHero == null or canonicalAbilityId == 0 or not ModernAbilityCatalog_IsAssignable(canonicalAbilityId) then
        return false
    endif

    set entryIndex = AbilitiesPlayer_GetEntryByAbilityId(canonicalAbilityId)
    return AbilitiesPlayer_GetEntryKind(entryIndex) == AbilitiesPlayer_ENTRY_ABILITY and GetUnitAbilityLevel(whichHero, canonicalAbilityId) > 0
endfunction

public function GetAbilityId takes unit whichHero, integer slot returns integer
    local integer storageIndex = MAL_GetStorageIndex(ShamanCommon_GetHeroSlot(whichHero), slot)

    if storageIndex == 0 then
        return 0
    endif
    return MAL_AbilityId[storageIndex]
endfunction

public function FindSlot takes unit whichHero, integer abilityId returns integer
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer canonicalAbilityId = MAL_GetCanonicalAbilityId(abilityId)
    local integer slot = 1
    local integer storageIndex

    if canonicalAbilityId == 0 then
        return 0
    endif

    loop
        exitwhen slot > SLOT_COUNT
        set storageIndex = MAL_GetStorageIndex(heroSlot, slot)
        if storageIndex != 0 and MAL_AbilityId[storageIndex] == canonicalAbilityId then
            return slot
        endif
        set slot = slot + 1
    endloop

    return 0
endfunction

public function Assign takes unit whichHero, integer slot, integer abilityId returns boolean
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer storageIndex = MAL_GetStorageIndex(heroSlot, slot)
    local integer canonicalAbilityId = MAL_GetCanonicalAbilityId(abilityId)
    local integer previousSlot

    if storageIndex == 0 or not MAL_IsLearnedActiveAbility(whichHero, canonicalAbilityId) then
        return false
    endif

    set previousSlot = FindSlot(whichHero, canonicalAbilityId)
    if previousSlot != 0 and previousSlot != slot then
        set MAL_AbilityId[MAL_GetStorageIndex(heroSlot, previousSlot)] = 0
    endif

    set MAL_AbilityId[storageIndex] = canonicalAbilityId
    return true
endfunction

public function Clear takes unit whichHero, integer slot returns boolean
    local integer storageIndex = MAL_GetStorageIndex(ShamanCommon_GetHeroSlot(whichHero), slot)

    if storageIndex == 0 then
        return false
    endif

    set MAL_AbilityId[storageIndex] = 0
    return true
endfunction

public function Reset takes unit whichHero returns nothing
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer slot = 1
    local integer storageIndex

    loop
        exitwhen slot > SLOT_COUNT
        set storageIndex = MAL_GetStorageIndex(heroSlot, slot)
        if storageIndex != 0 then
            set MAL_AbilityId[storageIndex] = 0
        endif
        set slot = slot + 1
    endloop
endfunction

public function FillFirstLearned takes unit whichHero returns nothing
    local integer entryIndex = 1
    local integer entryCount = AbilitiesPlayer_GetEntryCount()
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer abilityId
    local integer slot = 1

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return
    endif

    call Reset(whichHero)
    loop
        exitwhen entryIndex > entryCount or slot > SLOT_COUNT
        set abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if MAL_IsLearnedActiveAbility(whichHero, abilityId) then
            set MAL_AbilityId[MAL_GetStorageIndex(heroSlot, slot)] = abilityId
            set slot = slot + 1
        endif
        set entryIndex = entryIndex + 1
    endloop
endfunction

endlibrary
