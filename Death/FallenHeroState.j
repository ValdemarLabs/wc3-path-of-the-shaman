/**
    FallenHeroState

    Author: Valdemar
    Version:

    Description:
    Stores retained fallen-hero state independently from the high-level Death
    system so low-level consumers can reject fake corpses without requiring
    the full revival system.

    Credits:
    - Path of the Shaman Death system

    How to install:
    Import before Death and systems that query fallen-hero state.

    API:
    call FallenHeroState_SetFallen(whichHero, isFallen)
    call FallenHeroState_IsFallen(whichHero) returns boolean
    call FallenHeroState_IsAlive(whichUnit) returns boolean
    call FallenHeroState_IsDead(whichUnit) returns boolean
    call FallenHeroState_ForEach(callback)

**/
library FallenHeroState initializer Init

globals
    // All hero bodies currently retained by the Death system.
    private group FallenHeroState_Heroes = null
endglobals

public function SetFallen takes unit whichHero, boolean isFallen returns nothing
    if whichHero == null then
        return
    endif
    if isFallen then
        call GroupAddUnit(FallenHeroState_Heroes, whichHero)
    else
        call GroupRemoveUnit(FallenHeroState_Heroes, whichHero)
    endif
endfunction

public function IsFallen takes unit whichHero returns boolean
    return whichHero != null and IsUnitInGroup(whichHero, FallenHeroState_Heroes)
endfunction

public function IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD) and not FallenHeroState_IsFallen(whichUnit)
endfunction

public function IsDead takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and (GetWidgetLife(whichUnit) <= 0.405 or IsUnitType(whichUnit, UNIT_TYPE_DEAD) or FallenHeroState_IsFallen(whichUnit))
endfunction

public function ForEach takes code callback returns nothing
    call ForGroup(FallenHeroState_Heroes, callback)
endfunction

private function Init takes nothing returns nothing
    set FallenHeroState_Heroes = CreateGroup()
endfunction

endlibrary
