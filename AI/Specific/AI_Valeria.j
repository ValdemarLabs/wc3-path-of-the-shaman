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
    Requires `AI.j` and `Reputation.j`.

    API:
    call AIValeria_Enable(unit whichUnit)
    call AIValeria_Disable(unit whichUnit)

**/
library AIValeria initializer Init requires AI, Reputation

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

private function RegisterElarindorBark takes integer barkType, string text, string soundKey, integer minRep, integer maxRep returns nothing
    call AI_RegisterBarkLineForReputation(AI_Valeria_ProfileId, barkType, text, soundKey, "Elarindor", minRep, maxRep)
endfunction

private function RegisterNeutralBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, AI_REP_NO_MIN, Reputation_REP_NEUTRAL - 1)
endfunction

private function RegisterFriendlyBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, Reputation_REP_NEUTRAL, Reputation_REP_FRIENDLY - 1)
endfunction

private function RegisterCovenantBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, Reputation_REP_FRIENDLY, Reputation_REP_COVENANT - 1)
endfunction

private function RegisterExaltedBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, Reputation_REP_COVENANT, AI_REP_NO_MAX)
endfunction

private function RegisterBarks takes nothing returns nothing
    call RegisterNeutralBark(AI_BARK_GREET, "Keep your hands where I can see them.", "Valeria_0201")
    call RegisterFriendlyBark(AI_BARK_GREET, "You came back. That counts for something.", "Valeria_0202")
    call RegisterCovenantBark(AI_BARK_GREET, "I'm glad that you could make it back here.", "Valeria_0203")
    call RegisterExaltedBark(AI_BARK_GREET, "My bow is yours, friend of the Vale.", "Valeria_0204")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Leave before the trees decide you lingered too long.", "Valeria_0205")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "Safe travels.", "Valeria_0206")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Go with my watch over you.", "Valeria_0207")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "Return safely. Elarindor still needs its champions.", "Valeria_0208")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "I will lower my bow when I have reason.", "Valeria_0209")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "I can hold my shot if you keep your word.", "Valeria_0210")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "No needless blood. We guard what remains.", "Valeria_0211")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "Peace, then. Your judgment has earned that.", "Valeria_0212")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Walk where I can see you.", "Valeria_0213")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "Eyes forward. I will cover the flank.", "Valeria_0214")
    call RegisterCovenantBark(AI_BARK_NORMAL, "Move as one with the trees and they may spare us.", "Valeria_0215")
    call RegisterExaltedBark(AI_BARK_NORMAL, "Lead on. My arrows will clear the path.", "Valeria_0216")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "Finally. Something I am allowed to shoot.", "Valeria_0217")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "If they threaten the Vale, they fall.", "Valeria_0218")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "No mercy for those who hunt Elarindor.", "Valeria_0219")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "Together, we strike before fear takes root.", "Valeria_0220")
    call RegisterNeutralBark(AI_BARK_HOLD, "I will hold this line, not your hand.", "Valeria_0221")
    call RegisterFriendlyBark(AI_BARK_HOLD, "This ground gives me a clean line.", "Valeria_0222")
    call RegisterCovenantBark(AI_BARK_HOLD, "I will keep this pass sealed.", "Valeria_0223")
    call RegisterExaltedBark(AI_BARK_HOLD, "Nothing crosses while I breathe.", "Valeria_0224")
    call RegisterNeutralBark(AI_BARK_DROP_ITEMS, "Take it. I would rather keep my hands free.", "Valeria_0225")
    call RegisterFriendlyBark(AI_BARK_DROP_ITEMS, "Take this. It should serve you better.", "Valeria_0226")
    call RegisterCovenantBark(AI_BARK_DROP_ITEMS, "Use it well. Elarindor has few gifts left.", "Valeria_0227")
    call RegisterExaltedBark(AI_BARK_DROP_ITEMS, "A ranger shares what keeps an ally alive.", "Valeria_0228")
    call RegisterNeutralBark(AI_BARK_KICKED, "Good. I prefer my own company.", "Valeria_0229")
    call RegisterFriendlyBark(AI_BARK_KICKED, "Then I will watch from the trees.", "Valeria_0230")
    call RegisterCovenantBark(AI_BARK_KICKED, "Call when the Vale needs my bow again.", "Valeria_0231")
    call RegisterExaltedBark(AI_BARK_KICKED, "I will be near if you need me.", "Valeria_0232")
    call RegisterNeutralBark(AI_BARK_ITEM_GIVEN, "I will use it if it serves the Vale.", "Valeria_0233")
    call RegisterFriendlyBark(AI_BARK_ITEM_GIVEN, "Useful. I will not waste it.", "Valeria_0234")
    call RegisterCovenantBark(AI_BARK_ITEM_GIVEN, "You know a ranger's needs. Thank you.", "Valeria_0235")
    call RegisterExaltedBark(AI_BARK_ITEM_GIVEN, "A thoughtful gift from a trusted hand. I accept.", "Valeria_0236")
    call RegisterNeutralBark(AI_BARK_ATTACKING, "Wrong step.", "Valeria_0237")
    call RegisterFriendlyBark(AI_BARK_ATTACKING, "I have the shot.", "Valeria_0238")
    call RegisterCovenantBark(AI_BARK_ATTACKING, "For Elarindor.", "Valeria_0239")
    call RegisterExaltedBark(AI_BARK_ATTACKING, "Bal’a dash, malanore!", "Valeria_0240")
    call RegisterNeutralBark(AI_BARK_CASTING, "Hold still.", "Valeria_0241")
    call RegisterFriendlyBark(AI_BARK_CASTING, "This arrow finds its mark.", "Valeria_0242")
    call RegisterCovenantBark(AI_BARK_CASTING, "Let the old shadows bleed.", "Valeria_0243")
    call RegisterExaltedBark(AI_BARK_CASTING, "By leaf and oath, fall.", "Valeria_0244")
    call RegisterNeutralBark(AI_BARK_KILLING, "Stay down.", "Valeria_0245")
    call RegisterFriendlyBark(AI_BARK_KILLING, "Threat ended.", "Valeria_0246")
    call RegisterCovenantBark(AI_BARK_KILLING, "One less scar on the Vale.", "Valeria_0247")
    call RegisterExaltedBark(AI_BARK_KILLING, "Anar’alah belore!", "Valeria_0248")
    call RegisterNeutralBark(AI_BARK_COMPANION_DIES, "No. Do not make this worse.", "Valeria_0249")
    call RegisterFriendlyBark(AI_BARK_COMPANION_DIES, "No. We do not fall here.", "Valeria_0250")
    call RegisterCovenantBark(AI_BARK_COMPANION_DIES, "Hold! I will not lose another ally.", "Valeria_0251")
    call RegisterExaltedBark(AI_BARK_COMPANION_DIES, "No! I swore you would leave this place alive.", "Valeria_0252")
    call RegisterNeutralBark(AI_BARK_IDLE, "Do not mistake silence for trust.", "Valeria_0253")
    call RegisterFriendlyBark(AI_BARK_IDLE, "Atleast the mighty red trees have retained their beauty in this place.", "Valeria_0254")
    call RegisterCovenantBark(AI_BARK_IDLE, "Aradion sees patterns. I see tracks.", "Valeria_0255")
    call RegisterExaltedBark(AI_BARK_IDLE, "For once, the Vale feels almost willing to heal.", "Valeria_0256")
    call RegisterNeutralBark(AI_BARK_MOVING, "Stay ahead of my arrow, not behind it.", "Valeria_0257")
    call RegisterFriendlyBark(AI_BARK_MOVING, "Quiet steps. Loose grip. Breathe.", "Valeria_0258")
    call RegisterCovenantBark(AI_BARK_MOVING, "I know a safer path. Follow close.", "Valeria_0259")
    call RegisterExaltedBark(AI_BARK_MOVING, "With you, even these old paths feel less cursed.", "Valeria_0260")
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
