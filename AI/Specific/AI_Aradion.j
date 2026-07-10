/**
    AI_Aradion

    Author: Valdemar
    Version:

    Description:
    Optional Aradion AI profile. This registers Aradion for shared AI state and
    defensive combat reactions while leaving qAradion and later qValeria-style
    quest scripts in charge of movement and ritual orders.

    Credits:
    - qAradion / Aradion quest flow

    How to install:
    Requires `AI.j`.

    API:
    call AIAradion_Enable(unit whichUnit)
    call AIAradion_Disable(unit whichUnit)
    call AIAradion_SetCombatOrders(boolean enabled)

**/
library AIAradion initializer Init requires AI

globals
    constant integer AI_ARADION_UNIT = 'h00A'
    constant integer AI_ARADION_UNIQUE_ID = 'ARAD'
    private constant real AUTO_ENABLE_INTERVAL = 5.00
    integer AI_Aradion_ClassId = 0
    integer AI_Aradion_ProfileId = 0
    private timer AutoEnableTimer = null
    private boolean AutoEnableAllowed = true
    private boolean CombatOrdersEnabled = false
endglobals

private function MoveAwayFromTarget takes unit whichUnit, unit target, real distance returns nothing
    local real dx
    local real dy
    local real angle
    if whichUnit == null or target == null then
        return
    endif
    set dx = GetUnitX(whichUnit) - GetUnitX(target)
    set dy = GetUnitY(whichUnit) - GetUnitY(target)
    if dx == 0.00 and dy == 0.00 then
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif
    call IssuePointOrder(whichUnit, "move", GetUnitX(whichUnit) + distance * Cos(angle), GetUnitY(whichUnit) + distance * Sin(angle))
endfunction

private function Think takes nothing returns nothing
    local unit aradion = AI_EventUnit
    local unit target = AI_EventTarget
    if aradion != null and target != null then
        if AI_GetUnitLifePercent(aradion) <= 35.00 then
            call MoveAwayFromTarget(aradion, target, 500.00)
        elseif CombatOrdersEnabled then
            call IssueTargetOrder(aradion, "attack", target)
        endif
    endif
    set aradion = null
    set target = null
endfunction

public function SetCombatOrders takes boolean enabled returns nothing
    set CombatOrdersEnabled = enabled
endfunction

public function Enable takes unit whichUnit returns integer
    local unit existing = AI_GetUnitByUniqueId(AI_ARADION_UNIQUE_ID)
    if whichUnit == null then
        set existing = null
        return 0
    endif
    set AutoEnableAllowed = true
    if existing != null and existing != whichUnit then
        call AI_UnregisterUnit(existing)
    endif
    set existing = null
    return AI_RegisterUnit(whichUnit, AI_Aradion_ProfileId, AI_ARADION_UNIQUE_ID)
endfunction

public function Disable takes unit whichUnit returns nothing
    set AutoEnableAllowed = false
    call AI_UnregisterUnit(whichUnit)
endfunction

private function TryAutoEnable takes nothing returns nothing
    if AutoEnableAllowed and udg_Aradion != null and AI_GetInstance(udg_Aradion) <= 0 then
        call AIAradion_Enable(udg_Aradion)
    endif
endfunction

private function RegisterChat takes string soundKey, string text returns nothing
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_IDLE, text, soundKey)
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_MOVING, text, soundKey)
endfunction

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_GREET, "Aradion. Once a magister, now a man counting what remains.", "Aradion_0201")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_GREET, "Speak softly. The ruins have learned to listen.", "Aradion_0202")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_FAREWELL, "May your path find kinder answers than mine.", "Aradion_0203")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_FAREWELL, "Go carefully. Hope is fragile here.", "Aradion_0204")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_PASSIVE, "I will conserve what strength I have left.", "Aradion_0205")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_NORMAL, "There is still work before despair earns its rest.", "Aradion_0206")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_AGGRESSIVE, "If battle is forced on us, then let it be brief.", "Aradion_0207")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_HOLD, "I can hold this warded ground.", "Aradion_0208")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_DROP_ITEMS, "Take this. It may serve you better than my shelves.", "Aradion_0209")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_KICKED, "Then I return to my studies, and to Valeria.", "Aradion_0210")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_ITEM_GIVEN, "Curious. I will examine it carefully.", "Aradion_0211")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_ATTACKING, "Back, shade.", "Aradion_0212")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_ATTACKING, "I remember enough magic for this.", "Aradion_0213")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_CASTING, "By the old currents, answer me.", "Aradion_0214")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_CASTING, "Steady... do not break now.", "Aradion_0215")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_KILLING, "Another echo put to rest.", "Aradion_0216")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_COMPANION_DIES, "No. I will not lose another soul to this ruin.", "Aradion_0217")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_IDLE, "Wisdom came too late to save Elarindor. I keep it anyway.", "Aradion_0218")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_IDLE, "The arcane still hums beneath the stones, wounded but not silent.", "Aradion_0219")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_MOVING, "The old paths twist where memory refuses to fade.", "Aradion_0220")
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, AI_BARK_MOVING, "Careful. Disturbed magic does not sleep deeply.", "Aradion_0221")
    call RegisterChat("Aradion_0222", "A failed magister can still read the shape of a disaster.")
    call RegisterChat("Aradion_0223", "I mistook caution for cowardice once. The cost taught me otherwise.")
    call RegisterChat("Aradion_0224", "Valeria kept her aim steady when my faith broke.")
    call RegisterChat("Aradion_0225", "If the Vale heals, it will be because someone kinder than me refused to abandon it.")
endfunction

private function Init takes nothing returns nothing
    set AI_Aradion_ClassId = AI_RegisterClass("Magister")
    set AI_Aradion_ProfileId = AI_RegisterProfile(AI_Aradion_ClassId, AI_ARADION_UNIT, "Aradion")
    call AI_SetProfileCap(AI_Aradion_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_ARADION_UNIT, 1)
    call AI_SetProfileAutonomous(AI_Aradion_ProfileId, false)
    call AI_SetProfileThinkCallback(AI_Aradion_ProfileId, function Think)
    call RegisterBarks()

    set AutoEnableTimer = CreateTimer()
    call TimerStart(AutoEnableTimer, AUTO_ENABLE_INTERVAL, true, function TryAutoEnable)
endfunction

endlibrary
