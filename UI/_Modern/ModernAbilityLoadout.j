/**
    ModernAbilityLoadout

    Author: Valdemar
    Version: 0.6.0

    Description:
    Stores twenty-four synchronized modern action-bar assignments independently for
    Nazgrek and Zul'kis. Assignments reference real learned ability rawcodes;
    spellbook wrapper abilities remain untouched for compatibility during the
    staged migration. The derived default layout is materialized once per hero
    instead of rescanning the complete ability catalog for every slot lookup.

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
    - set abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(whichHero, slot)
    - set slot = ModernAbilityLoadout_FindSlot(whichHero, abilityId)
    - call ModernAbilityLoadout_FillFirstLearned(whichHero)
    - call ModernAbilityLoadout_RefreshDefaults(whichHero)
    - set changed = ModernAbilityLoadout_AppendNewLearned(whichHero)
    - set changed = ModernAbilityLoadout_Swap(whichHero, firstSlot, secondSlot)
    - set revision = ModernAbilityLoadout_GetRevision(whichHero)
    - call ModernAbilityLoadout_Reset(whichHero)
    - set count = ModernAbilityLoadout_SLOT_COUNT

**/
library ModernAbilityLoadout requires AbilitiesPlayer, ShamanCommon, ModernAbilityCatalog

globals
    public constant integer SLOT_COUNT = 24

    private integer array MAL_AbilityId
    private boolean array MAL_Explicit
    private boolean array MAL_DefaultsMaterialized
    private integer array MAL_Revision
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

private function MAL_MaterializeDefaults takes unit whichHero, integer heroSlot returns nothing
    local integer entryIndex = 1
    local integer entryCount = AbilitiesPlayer_GetEntryCount()
    local integer abilityId
    local integer slot = 1

    if heroSlot == ShamanCommon_HERO_SLOT_NONE or MAL_Explicit[heroSlot] or MAL_DefaultsMaterialized[heroSlot] then
        return
    endif

    loop
        exitwhen entryIndex > entryCount or slot > SLOT_COUNT
        set abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if MAL_IsLearnedActiveAbility(whichHero, abilityId) then
            set MAL_AbilityId[MAL_GetStorageIndex(heroSlot, slot)] = abilityId
            set slot = slot + 1
        endif
        set entryIndex = entryIndex + 1
    endloop
    set MAL_DefaultsMaterialized[heroSlot] = true
    set MAL_Revision[heroSlot] = MAL_Revision[heroSlot] + 1
endfunction

public function GetRevision takes unit whichHero returns integer
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return 0
    endif
    return MAL_Revision[heroSlot]
endfunction

public function GetEffectiveAbilityId takes unit whichHero, integer slot returns integer
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer storageIndex = MAL_GetStorageIndex(heroSlot, slot)

    if storageIndex == 0 then
        return 0
    endif
    call MAL_MaterializeDefaults(whichHero, heroSlot)
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
        if storageIndex != 0 and GetEffectiveAbilityId(whichHero, slot) == canonicalAbilityId then
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

    call MAL_MaterializeDefaults(whichHero, heroSlot)
    set previousSlot = FindSlot(whichHero, canonicalAbilityId)
    if previousSlot != 0 and previousSlot != slot then
        set MAL_AbilityId[MAL_GetStorageIndex(heroSlot, previousSlot)] = 0
    endif

    set MAL_AbilityId[storageIndex] = canonicalAbilityId
    set MAL_Explicit[heroSlot] = true
    set MAL_Revision[heroSlot] = MAL_Revision[heroSlot] + 1
    return true
endfunction

public function Clear takes unit whichHero, integer slot returns boolean
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer storageIndex = MAL_GetStorageIndex(heroSlot, slot)

    if storageIndex == 0 then
        return false
    endif

    call MAL_MaterializeDefaults(whichHero, heroSlot)
    set MAL_AbilityId[storageIndex] = 0
    set MAL_Explicit[heroSlot] = true
    set MAL_Revision[heroSlot] = MAL_Revision[heroSlot] + 1
    return true
endfunction

public function Swap takes unit whichHero, integer firstSlot, integer secondSlot returns boolean
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer firstIndex = MAL_GetStorageIndex(heroSlot, firstSlot)
    local integer secondIndex = MAL_GetStorageIndex(heroSlot, secondSlot)
    local integer firstAbilityId

    if firstIndex == 0 or secondIndex == 0 or firstSlot == secondSlot then
        return false
    endif

    call MAL_MaterializeDefaults(whichHero, heroSlot)
    set firstAbilityId = MAL_AbilityId[firstIndex]
    set MAL_AbilityId[firstIndex] = MAL_AbilityId[secondIndex]
    set MAL_AbilityId[secondIndex] = firstAbilityId
    set MAL_Explicit[heroSlot] = true
    set MAL_Revision[heroSlot] = MAL_Revision[heroSlot] + 1
    return true
endfunction

public function AppendNewLearned takes unit whichHero returns boolean
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer entryIndex = 1
    local integer entryCount = AbilitiesPlayer_GetEntryCount()
    local integer abilityId
    local integer slot
    local boolean changed = false

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return false
    endif

    call MAL_MaterializeDefaults(whichHero, heroSlot)
    loop
        exitwhen entryIndex > entryCount
        set abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if MAL_IsLearnedActiveAbility(whichHero, abilityId) and FindSlot(whichHero, abilityId) == 0 then
            set slot = 1
            loop
                exitwhen slot > SLOT_COUNT or MAL_AbilityId[MAL_GetStorageIndex(heroSlot, slot)] == 0
                set slot = slot + 1
            endloop
            if slot <= SLOT_COUNT then
                set MAL_AbilityId[MAL_GetStorageIndex(heroSlot, slot)] = abilityId
                set changed = true
            endif
        endif
        set entryIndex = entryIndex + 1
    endloop

    if changed then
        set MAL_Explicit[heroSlot] = true
        set MAL_Revision[heroSlot] = MAL_Revision[heroSlot] + 1
    endif
    return changed
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
    if heroSlot != ShamanCommon_HERO_SLOT_NONE then
        set MAL_Explicit[heroSlot] = false
        set MAL_DefaultsMaterialized[heroSlot] = false
        set MAL_Revision[heroSlot] = MAL_Revision[heroSlot] + 1
    endif
endfunction

public function RefreshDefaults takes unit whichHero returns nothing
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    local integer slot = 1

    if heroSlot == ShamanCommon_HERO_SLOT_NONE or MAL_Explicit[heroSlot] then
        return
    endif

    loop
        exitwhen slot > SLOT_COUNT
        set MAL_AbilityId[MAL_GetStorageIndex(heroSlot, slot)] = 0
        set slot = slot + 1
    endloop
    set MAL_DefaultsMaterialized[heroSlot] = false
    call MAL_MaterializeDefaults(whichHero, heroSlot)
endfunction

public function FillFirstLearned takes unit whichHero returns nothing
    local integer heroSlot = ShamanCommon_GetHeroSlot(whichHero)

    if heroSlot == ShamanCommon_HERO_SLOT_NONE then
        return
    endif

    call Reset(whichHero)
    call MAL_MaterializeDefaults(whichHero, heroSlot)
endfunction

endlibrary
