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
    Requires `AI.j` and `Reputation.j`.

    API:
    call AIAradion_Enable(unit whichUnit)
    call AIAradion_Disable(unit whichUnit)
    call AIAradion_SetCombatOrders(boolean enabled)

**/
library AIAradion initializer Init requires AI, Reputation

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

private function RegisterElarindorBark takes integer barkType, string text, string soundKey, integer minRep, integer maxRep returns nothing
    call AI_RegisterBarkLineForReputation(AI_Aradion_ProfileId, barkType, text, soundKey, "Elarindor", minRep, maxRep)
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
    call RegisterNeutralBark(AI_BARK_GREET, "Once a magister, now a man asking caution from strangers.", "Aradion_0201")
    call RegisterFriendlyBark(AI_BARK_GREET, "It is good to see a familiar face in Elarindor.", "Aradion_0202")
    call RegisterCovenantBark(AI_BARK_GREET, "Friend, your presence steadies more than my wards.", "Aradion_0203")
    call RegisterExaltedBark(AI_BARK_GREET, "My friend, Elarindor still stands because you refused to abandon it.", "Aradion_0204")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Go carefully. I would not lose another possible ally.", "Aradion_0205")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "May your path find kinder answers than mine.", "Aradion_0206")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Elarindor is safer for every step you take.", "Aradion_0207")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "Return safely. Valeria and I will keep a light for you.", "Aradion_0208")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "I will conserve what strength remains to me.", "Aradion_0209")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "Peace gives old wounds a moment to close.", "Aradion_0210")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "Let restraint be our proof that we are not lost.", "Aradion_0211")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "Peace suits the Vale better than fear.", "Aradion_0212")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Let us proceed carefully. These ruins punish certainty.", "Aradion_0213")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "There is still work before despair earns its rest.", "Aradion_0214")
    call RegisterCovenantBark(AI_BARK_NORMAL, "Together, perhaps we can make these ruins teach instead of mourn.", "Aradion_0215")
    call RegisterExaltedBark(AI_BARK_NORMAL, "Lead on. My counsel and my magic are yours.", "Aradion_0216")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "If battle is forced on us, let it be brief.", "Aradion_0217")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "Stand with me!", "Aradion_0218")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "For the Vale, and for the lives I failed to protect.", "Aradion_0219")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "Let Elarindor remember courage today.", "Aradion_0220")
    call RegisterNeutralBark(AI_BARK_HOLD, "I can hold this warded ground.", "Aradion_0221")
    call RegisterFriendlyBark(AI_BARK_HOLD, "This circle should hold if I do not miscalculate.", "Aradion_0222")
    call RegisterCovenantBark(AI_BARK_HOLD, "I will anchor the ward. Trust the line.", "Aradion_0223")
    call RegisterExaltedBark(AI_BARK_HOLD, "I will hold this ground as if it were the heart of the Vale.", "Aradion_0224")
    call RegisterNeutralBark(AI_BARK_DROP_ITEMS, "Take this. It may serve you better than my shelves.", "Aradion_0225")
    call RegisterFriendlyBark(AI_BARK_DROP_ITEMS, "Please, take it. I have carried enough regrets.", "Aradion_0226")
    call RegisterCovenantBark(AI_BARK_DROP_ITEMS, "This belongs in capable hands. Yours.", "Aradion_0227")
    call RegisterExaltedBark(AI_BARK_DROP_ITEMS, "Take it with my gratitude, not my sorrow.", "Aradion_0228")
    call RegisterNeutralBark(AI_BARK_KICKED, "Then I return to my studies, and to Valeria.", "Aradion_0229")
    call RegisterFriendlyBark(AI_BARK_KICKED, "I will wait with Valeria. She worries better than I do.", "Aradion_0230")
    call RegisterCovenantBark(AI_BARK_KICKED, "Go on. I will keep the research alive.", "Aradion_0231")
    call RegisterExaltedBark(AI_BARK_KICKED, "I understand. Our bond does not need orders.", "Aradion_0232")
    call RegisterNeutralBark(AI_BARK_ITEM_GIVEN, "Curious. I will examine it carefully.", "Aradion_0233")
    call RegisterFriendlyBark(AI_BARK_ITEM_GIVEN, "Thank you. I will put it to careful use.", "Aradion_0234")
    call RegisterCovenantBark(AI_BARK_ITEM_GIVEN, "You remembered what my work requires. That means much.", "Aradion_0235")
    call RegisterExaltedBark(AI_BARK_ITEM_GIVEN, "A gift from a trusted friend. I will treasure it.", "Aradion_0236")
    call RegisterNeutralBark(AI_BARK_ATTACKING, "Back, shade.", "Aradion_0237")
    call RegisterFriendlyBark(AI_BARK_ATTACKING, "I remember enough magic for this.", "Aradion_0238")
    call RegisterCovenantBark(AI_BARK_ATTACKING, "Old power, new purpose.", "Aradion_0239")
    call RegisterExaltedBark(AI_BARK_ATTACKING, "No more stolen futures.", "Aradion_0240")
    call RegisterNeutralBark(AI_BARK_CASTING, "Begone you spawn of void!", "Aradion_0241")
    call RegisterFriendlyBark(AI_BARK_CASTING, "Anar’ethil, selama arcanum!", "Aradion_0242")
    call RegisterCovenantBark(AI_BARK_CASTING, "Felo’melorn, ash’al diel!", "Aradion_0243")
    call RegisterExaltedBark(AI_BARK_CASTING, "Belore, shael en’theran!", "Aradion_0244")
    call RegisterNeutralBark(AI_BARK_KILLING, "Another echo put to rest.", "Aradion_0245")
    call RegisterFriendlyBark(AI_BARK_KILLING, "A small mercy for Elarindor.", "Aradion_0246")
    call RegisterCovenantBark(AI_BARK_KILLING, "May that be the last shadow here.", "Aradion_0247")
    call RegisterExaltedBark(AI_BARK_KILLING, "Rest now.", "Aradion_0248")
    call RegisterNeutralBark(AI_BARK_COMPANION_DIES, "No. I will not lose another soul to this ruin.", "Aradion_0249")
    call RegisterFriendlyBark(AI_BARK_COMPANION_DIES, "No. Stay with us.", "Aradion_0250")
    call RegisterCovenantBark(AI_BARK_COMPANION_DIES, "No. Not you. Not after all this.", "Aradion_0251")
    call RegisterExaltedBark(AI_BARK_COMPANION_DIES, "No! I was meant to protect you.", "Aradion_0252")
    call RegisterNeutralBark(AI_BARK_IDLE, "A failed magister can still read the shape of a disaster.", "Aradion_0253")
    call RegisterFriendlyBark(AI_BARK_IDLE, "Perhaps it's not too late to save the Elarindor.", "Aradion_0254")
    call RegisterCovenantBark(AI_BARK_IDLE, "You have good heart.", "Aradion_0255")
    call RegisterExaltedBark(AI_BARK_IDLE, "For the first time in years, I can imagine tomorrow.", "Aradion_0256")
    call RegisterNeutralBark(AI_BARK_MOVING, "Careful. Unstable arcane energies are flowing everywhere here.", "Aradion_0257")
    call RegisterFriendlyBark(AI_BARK_MOVING, "The old paths twist where memory refuses to fade.", "Aradion_0258")
    call RegisterCovenantBark(AI_BARK_MOVING, "I've walked this path many times. It doesn't have the same beauty as it used to have.", "Aradion_0259")
    call RegisterExaltedBark(AI_BARK_MOVING, "Valeria says I should smile more. Despite the circumstances... she may be right.", "Aradion_0260")
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
