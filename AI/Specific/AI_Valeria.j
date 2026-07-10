/**
    AI_Valeria

    Author: Valdemar
    Version:

    Description:
    Optional Valeria AI profile. This library registers the profile for combat
    assistance while leaving patrol and quest movement in external systems.

    Credits:
    - qAradion / Valeria encounter flow

    How to install:
    Requires `AI.j`.

    API:
    call AIValeria_Enable(unit whichUnit)
    call AIValeria_Disable(unit whichUnit)

**/
library AIValeria initializer Init requires AI

globals
    constant integer AI_VALERIA_UNIT = 'n01W'
    constant integer AI_VALERIA_UNIQUE_ID = 'VALR'
    private constant real AUTO_ENABLE_INTERVAL = 5.00
    integer AI_Valeria_ClassId = 0
    integer AI_Valeria_ProfileId = 0
    private timer AutoEnableTimer = null
    private boolean AutoEnableAllowed = true
endglobals

private function Think takes nothing returns nothing
    local unit valeria = AI_EventUnit
    local unit target = AI_EventTarget
    local real dx
    local real dy
    local real distance
    local real angle
    local real lifePercent
    if valeria != null and target != null then
        set dx = GetUnitX(valeria) - GetUnitX(target)
        set dy = GetUnitY(valeria) - GetUnitY(target)
        set distance = dx * dx + dy * dy
        set lifePercent = AI_GetUnitLifePercent(valeria)
        if dx != 0.00 or dy != 0.00 then
            set angle = Atan2(dy, dx)
        else
            set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
        endif
        if lifePercent <= 35.00 then
            call IssuePointOrder(valeria, "move", GetUnitX(valeria) + 500.00 * Cos(angle), GetUnitY(valeria) + 500.00 * Sin(angle))
        elseif distance <= 350.00 * 350.00 and GetRandomInt(1, 100) <= 55 then
            call IssuePointOrder(valeria, "move", GetUnitX(valeria) + 300.00 * Cos(angle), GetUnitY(valeria) + 300.00 * Sin(angle))
        else
            call IssueTargetOrder(valeria, "attack", target)
        endif
    endif
    set valeria = null
    set target = null
endfunction

public function Enable takes unit whichUnit returns integer
    local unit existing = AI_GetUnitByUniqueId(AI_VALERIA_UNIQUE_ID)
    if whichUnit == null then
        set existing = null
        return 0
    endif
    set AutoEnableAllowed = true
    if existing != null and existing != whichUnit then
        call AI_UnregisterUnit(existing)
    endif
    set existing = null
    return AI_RegisterUnit(whichUnit, AI_Valeria_ProfileId, AI_VALERIA_UNIQUE_ID)
endfunction

public function Disable takes unit whichUnit returns nothing
    set AutoEnableAllowed = false
    call AI_UnregisterUnit(whichUnit)
endfunction

private function TryAutoEnable takes nothing returns nothing
    if AutoEnableAllowed and udg_Valeria != null and AI_GetInstance(udg_Valeria) <= 0 then
        call AIValeria_Enable(udg_Valeria)
    endif
endfunction

private function RegisterChat takes string soundKey, string text returns nothing
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_IDLE, text, soundKey)
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_MOVING, text, soundKey)
endfunction

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_GREET, "Valeria. Keep your hands where I can see them.", "Valeria_0201")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_GREET, "If Aradion trusts you, I will listen. Once.", "Valeria_0202")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_FAREWELL, "Stay clear of the old paths after dark.", "Valeria_0203")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_FAREWELL, "I will keep watch from the trees.", "Valeria_0204")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_PASSIVE, "I will hold my shot until it matters.", "Valeria_0205")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_NORMAL, "Eyes forward. The Vale hides teeth.", "Valeria_0206")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_AGGRESSIVE, "Good. Let them learn why rangers keep distance.", "Valeria_0207")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_HOLD, "This ground gives me a clean line.", "Valeria_0208")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_DROP_ITEMS, "Take it. I travel lighter with a bow in hand.", "Valeria_0209")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_KICKED, "Then I return to Aradion.", "Valeria_0210")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_ITEM_GIVEN, "Useful. I will not waste it.", "Valeria_0211")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_ATTACKING, "You stepped into my range.", "Valeria_0212")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_ATTACKING, "I have the shot.", "Valeria_0213")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_CASTING, "Hold still.", "Valeria_0214")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_CASTING, "This arrow finds its mark.", "Valeria_0215")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_KILLING, "Threat ended.", "Valeria_0216")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_COMPANION_DIES, "No. We do not fall here.", "Valeria_0217")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_IDLE, "The trees remember where the wraiths passed.", "Valeria_0218")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_IDLE, "Aradion sees patterns. I see tracks.", "Valeria_0219")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_MOVING, "Quiet steps. Loose grip. Breathe.", "Valeria_0220")
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, AI_BARK_MOVING, "Stay behind my line of fire.", "Valeria_0221")
    call RegisterChat("Valeria_0222", "Every path through Elarindor carries a memory I would rather forget.")
    call RegisterChat("Valeria_0223", "I was a ranger before the Vale broke. I remain one after.")
    call RegisterChat("Valeria_0224", "Aradion blames himself for too much. That does not make him wrong.")
    call RegisterChat("Valeria_0225", "I have watched him chase hope through ruins. Someone has to guard his back.")
endfunction

private function Init takes nothing returns nothing
    set AI_Valeria_ClassId = AI_RegisterClass("Ranger")
    set AI_Valeria_ProfileId = AI_RegisterProfile(AI_Valeria_ClassId, AI_VALERIA_UNIT, "Valeria")
    call AI_SetProfileCap(AI_Valeria_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_VALERIA_UNIT, 1)
    call AI_SetProfileAutonomous(AI_Valeria_ProfileId, false)
    call AI_SetProfileThinkCallback(AI_Valeria_ProfileId, function Think)
    call RegisterBarks()

    set AutoEnableTimer = CreateTimer()
    call TimerStart(AutoEnableTimer, AUTO_ENABLE_INTERVAL, true, function TryAutoEnable)
endfunction

endlibrary
