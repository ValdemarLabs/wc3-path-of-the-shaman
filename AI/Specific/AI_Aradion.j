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
    call RegisterElarindorBark(barkType, text, soundKey, AI_REP_NO_MIN, Reputation_REP_FRIENDLY - 1)
endfunction

private function RegisterFriendlyBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, Reputation_REP_FRIENDLY, Reputation_REP_COVENANT - 1)
endfunction

private function RegisterCovenantBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, Reputation_REP_COVENANT, Reputation_REP_EXALTED - 1)
endfunction

private function RegisterExaltedBark takes integer barkType, string text, string soundKey returns nothing
    call RegisterElarindorBark(barkType, text, soundKey, Reputation_REP_EXALTED, AI_REP_NO_MAX)
endfunction

private function RegisterCommonBark takes integer barkType, string text, string soundKey returns nothing
    call AI_RegisterBarkLine(AI_Aradion_ProfileId, barkType, text, soundKey)
endfunction

private function RegisterBarks takes nothing returns nothing
    call RegisterNeutralBark(AI_BARK_GREET, "Greetings! I am magister Aradion, but they also call me as the Farseer.", "Aradion_0181")
    call RegisterNeutralBark(AI_BARK_GREET, "Welcome, traveler. Please forgive the tension in this place.", "Aradion_0182")
    call RegisterNeutralBark(AI_BARK_GREET, "Come gently. Nowadays, the Elarindor startles one easily.", "Aradion_0183")
    call RegisterFriendlyBark(AI_BARK_GREET, "It is good to see a familiar face in Elarindor.", "Aradion_0184")
    call RegisterFriendlyBark(AI_BARK_GREET, "Ah, you return.", "Aradion_0185")
    call RegisterFriendlyBark(AI_BARK_GREET, "You are most welcome here.", "Aradion_0186")
    call RegisterCovenantBark(AI_BARK_GREET, "Friend, your presence steadies more than my wards.", "Aradion_0187")
    call RegisterCovenantBark(AI_BARK_GREET, "Elarindor knows you now, and so do I.", "Aradion_0188")
    call RegisterCovenantBark(AI_BARK_GREET, "Valeria trusts you more than she likes to admit.", "Aradion_0189")
    call RegisterExaltedBark(AI_BARK_GREET, "My friend, Elarindor still stands because you refused to abandon it.", "Aradion_0190")
    call RegisterExaltedBark(AI_BARK_GREET, "You bring hope with you. I had almost forgotten the feeling of it...", "Aradion_0191")
    call RegisterExaltedBark(AI_BARK_GREET, "Come, dear friend. The Vale feels lighter when you are near.", "Aradion_0192")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Go carefully. I don't want to lose possible ally.", "Aradion_0193")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "May your path avoid the hungrier shadows.", "Aradion_0194")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Leave with caution. The void can temp you.", "Aradion_0195")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "May your path find kinder answers than mine.", "Aradion_0196")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "Travel safely. Hope is fragile here.", "Aradion_0197")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "I hope our paths cross again.", "Aradion_0198")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Elarindor is safer for every step you take.", "Aradion_0199")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Go with my gratitude, and Valeria's watch.", "Aradion_0200")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Return when you can. We will be here.", "Aradion_0201")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "Return safely. Valeria and I will keep a light for you.", "Aradion_0202")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "May the Vale itself guard your road.", "Aradion_0203")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "Farewell, my friend. Come back to visit us soon.", "Aradion_0204")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "I will conserve what strength remains to me.", "Aradion_0205")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "Let us avoid waste. Elarindor has endured enough.", "Aradion_0206")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "I prefer not to stir more ghosts.", "Aradion_0207")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "Peace gives old wounds a moment to close.", "Aradion_0208")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "Restraint may serve us better than fire.", "Aradion_0209")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "I can hold my spell, if you can hold the line.", "Aradion_0210")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "Let restraint be our proof that we are not lost.", "Aradion_0211")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "Good. We protect what remains.", "Aradion_0212")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "Mercy is harder than magic, and more needed.", "Aradion_0213")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "Peace suits the Vale better than fear.", "Aradion_0214")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "If you choose mercy, I will stand by it.", "Aradion_0215")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "The old wards rest easier when blades stay low.", "Aradion_0216")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Let us proceed carefully. These ruins punish certainty.", "Aradion_0217")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Step softly. Broken magic loves careless feet.", "Aradion_0218")
    call RegisterNeutralBark(AI_BARK_NORMAL, "I will follow your command.", "Aradion_0219")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "There is still work before despair earns its rest.", "Aradion_0220")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "Keep steady. Panic feeds this place.", "Aradion_0221")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "I can guide us past the worst of the old currents.", "Aradion_0222")
    call RegisterCovenantBark(AI_BARK_NORMAL, "Together, perhaps we can solve these problems.", "Aradion_0223")
    call RegisterCovenantBark(AI_BARK_NORMAL, "Your courage gives shape to my plans.", "Aradion_0224")
    call RegisterCovenantBark(AI_BARK_NORMAL, "Let us move before doubt finds me again.", "Aradion_0225")
    call RegisterExaltedBark(AI_BARK_NORMAL, "Lead on. My counsel and my magic are yours.", "Aradion_0226")
    call RegisterExaltedBark(AI_BARK_NORMAL, "With you ahead, even failure feels less certain.", "Aradion_0227")
    call RegisterExaltedBark(AI_BARK_NORMAL, "The Vale has waited long enough. Let us continue.", "Aradion_0228")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "If battle is forced on us, so shall it be.", "Aradion_0229")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "I will help, though I wish we had more time.", "Aradion_0230")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "Very well.", "Aradion_0231")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "Stand with me!", "Aradion_0232")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "My magic may falter, but not my intent.", "Aradion_0233")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "Let us end this before fear spreads.", "Aradion_0234")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "For the Vale, and for the lives I failed to protect.", "Aradion_0235")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "Old power, answer a better purpose.", "Aradion_0236")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "We fight so Elarindor may breathe again.", "Aradion_0237")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "Let Elarindor remember courage today.", "Aradion_0238")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "No more stolen futures.", "Aradion_0239")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "For every soul the Void has claimed!", "Aradion_0240")
    call RegisterNeutralBark(AI_BARK_HOLD, "I can hold this warded ground.", "Aradion_0241")
    call RegisterNeutralBark(AI_BARK_HOLD, "If my calculations hold, so will this place.", "Aradion_0242")
    call RegisterNeutralBark(AI_BARK_HOLD, "I will keep the ward steady. Mostly steady.", "Aradion_0243")
    call RegisterFriendlyBark(AI_BARK_HOLD, "This circle should hold if I do not miscalculate.", "Aradion_0244")
    call RegisterFriendlyBark(AI_BARK_HOLD, "I will anchor here. Try not to make me improvise.", "Aradion_0245")
    call RegisterFriendlyBark(AI_BARK_HOLD, "This ground remembers old protections.", "Aradion_0246")
    call RegisterCovenantBark(AI_BARK_HOLD, "I will anchor the ward. Trust the line.", "Aradion_0247")
    call RegisterCovenantBark(AI_BARK_HOLD, "Go. I can hold this point.", "Aradion_0248")
    call RegisterCovenantBark(AI_BARK_HOLD, "My wards are stronger with allies nearby.", "Aradion_0249")
    call RegisterExaltedBark(AI_BARK_HOLD, "I will hold this ground as if it were the heart of the Vale.", "Aradion_0250")
    call RegisterExaltedBark(AI_BARK_HOLD, "Nothing breaks this circle while I draw breath.", "Aradion_0251")
    call RegisterExaltedBark(AI_BARK_HOLD, "Trust me here. I will not fail you.", "Aradion_0252")
    call RegisterNeutralBark(AI_BARK_KICKED, "Then I return to my studies.", "Aradion_0253")
    call RegisterNeutralBark(AI_BARK_KICKED, "Very well. I have notes enough to keep me occupied.", "Aradion_0254")
    call RegisterNeutralBark(AI_BARK_KICKED, "Perhaps distance is wise for now.", "Aradion_0255")
    call RegisterFriendlyBark(AI_BARK_KICKED, "I will wait with Valeria. She worries better than I do.", "Aradion_0256")
    call RegisterFriendlyBark(AI_BARK_KICKED, "Call if you need counsel, or a flawed spell.", "Aradion_0257")
    call RegisterFriendlyBark(AI_BARK_KICKED, "Go carefully. I will remain near the wards.", "Aradion_0258")
    call RegisterCovenantBark(AI_BARK_KICKED, "Go on. I will keep the researching.", "Aradion_0259")
    call RegisterCovenantBark(AI_BARK_KICKED, "You know where to find us.", "Aradion_0260")
    call RegisterCovenantBark(AI_BARK_KICKED, "I will be ready when you needs us again, my friend.", "Aradion_0261")
    call RegisterExaltedBark(AI_BARK_KICKED, "I understand. Our bond does not need orders.", "Aradion_0262")
    call RegisterExaltedBark(AI_BARK_KICKED, "Take care, my friend. Valeria and I will be here.", "Aradion_0263")
    call RegisterExaltedBark(AI_BARK_KICKED, "Send word, and I will come as quickly as I can.", "Aradion_0264")
    call RegisterNeutralBark(AI_BARK_IDLE, "A failed magister can still read the shape of a disaster.", "Aradion_0265")
    call RegisterNeutralBark(AI_BARK_IDLE, "The arcane energies hum everywhere around this corner of the world.", "Aradion_0266")
    call RegisterNeutralBark(AI_BARK_IDLE, "I mistook caution for cowardice once. The cost taught me otherwise.", "Aradion_0267")
    call RegisterFriendlyBark(AI_BARK_IDLE, "Perhaps it's not too late to save the Elarindor.", "Aradion_0268")
    call RegisterFriendlyBark(AI_BARK_IDLE, "Wisdom came too late to save Elarindor. I keep it anyway.", "Aradion_0269")
    call RegisterFriendlyBark(AI_BARK_IDLE, "Valeria kept her aim steady when my faith broke.", "Aradion_0270")
    call RegisterCovenantBark(AI_BARK_IDLE, "You have good heart.", "Aradion_0271")
    call RegisterCovenantBark(AI_BARK_IDLE, "Valeria says I apologize to stones. She is not entirely wrong.", "Aradion_0272")
    call RegisterCovenantBark(AI_BARK_IDLE, "If the Vale heals, it will be because someone refused to abandon it.", "Aradion_0273")
    call RegisterExaltedBark(AI_BARK_IDLE, "For the first time in years, I can imagine tomorrow.", "Aradion_0274")
    call RegisterExaltedBark(AI_BARK_IDLE, "Hope feels strange after so long. I am learning it again.", "Aradion_0275")
    call RegisterExaltedBark(AI_BARK_IDLE, "Valeria smiles more when you are near. I pretend not to notice.", "Aradion_0276")
    call RegisterNeutralBark(AI_BARK_MOVING, "Careful. Unstable arcane energies are flowing everywhere here.", "Aradion_0277")
    call RegisterNeutralBark(AI_BARK_MOVING, "The old paths twist where memory refuses to fade.", "Aradion_0278")
    call RegisterNeutralBark(AI_BARK_MOVING, "Most of our kin is consumed by the Void.", "Aradion_0279")
    call RegisterFriendlyBark(AI_BARK_MOVING, "Careful. Disturbed magic does not sleep deeply.", "Aradion_0280")
    call RegisterFriendlyBark(AI_BARK_MOVING, "I know enough of this road to fear it properly.", "Aradion_0281")
    call RegisterFriendlyBark(AI_BARK_MOVING, "The old paths twist where memory refuses to fade.", "Aradion_0282")
    call RegisterCovenantBark(AI_BARK_MOVING, "I've walked this path many times. It doesn't have the same beauty as it used to have.", "Aradion_0283")
    call RegisterCovenantBark(AI_BARK_MOVING, "I know this route. I wish I had known it sooner.", "Aradion_0284")
    call RegisterCovenantBark(AI_BARK_MOVING, "The currents pull left here. Trust me on that.", "Aradion_0285")
    call RegisterExaltedBark(AI_BARK_MOVING, "Valeria says I should smile more. Despite the circumstances... maybe she is right.", "Aradion_0286")
    call RegisterExaltedBark(AI_BARK_MOVING, "With friends beside me, these ruins feel less final.", "Aradion_0287")
    call RegisterExaltedBark(AI_BARK_MOVING, "Come. There is still a path worth walking.", "Aradion_0288")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "Take this. It may serve you better than my shelves.", "Aradion_0289")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "Please, take it. I have carried enough regrets.", "Aradion_0290")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "This belongs in capable hands. Yours.", "Aradion_0291")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "Take it with my gratitude, not my sorrow.", "Aradion_0292")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "Curious. I will examine it carefully.", "Aradion_0293")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "Thank you. I will put it to careful use.", "Aradion_0294")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "You remembered what my work requires. That means much.", "Aradion_0295")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "A gift from a trusted friend. I will treasure it.", "Aradion_0296")
    call RegisterCommonBark(AI_BARK_ATTACKING, "Back, shade.", "Aradion_0297")
    call RegisterCommonBark(AI_BARK_ATTACKING, "Arcane magic is needed for this one!", "Aradion_0298")
    call RegisterCommonBark(AI_BARK_ATTACKING, "You can't defeat me!", "Aradion_0299")
    call RegisterCommonBark(AI_BARK_ATTACKING, "This ends now!", "Aradion_0300")
    call RegisterCommonBark(AI_BARK_CASTING, "Begone you spawn of Void!", "Aradion_0301")
    call RegisterCommonBark(AI_BARK_CASTING, "Anar'ethil, selama arcanum!", "Aradion_0302")
    call RegisterCommonBark(AI_BARK_CASTING, "Felo'melorn, ash'al diel!", "Aradion_0303")
    call RegisterCommonBark(AI_BARK_CASTING, "Belore, shael en'theran!", "Aradion_0304")
    call RegisterCommonBark(AI_BARK_KILLING, "Another echo put to rest.", "Aradion_0305")
    call RegisterCommonBark(AI_BARK_KILLING, "A small mercy for Elarindor.", "Aradion_0306")
    call RegisterCommonBark(AI_BARK_KILLING, "May that be the last shadow here.", "Aradion_0307")
    call RegisterCommonBark(AI_BARK_KILLING, "Rest now.", "Aradion_0308")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No. I will not lose another soul to this ruin.", "Aradion_0309")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No. Stay with us.", "Aradion_0310")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No. Not you. Not after all this.", "Aradion_0311")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No! I was meant to protect you.", "Aradion_0312")
endfunction

private function Init takes nothing returns nothing
    set AI_Aradion_ClassId = AI_RegisterClass("Magister")
    set AI_Aradion_ProfileId = AI_RegisterProfile(AI_Aradion_ClassId, AI_ARADION_UNIT, "Aradion")
    call AI_SetProfileFaction(AI_Aradion_ProfileId, "Elarindor")
    call AI_SetProfileCap(AI_Aradion_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_ARADION_UNIT, 1)
    call AI_SetProfileAutonomous(AI_Aradion_ProfileId, false)
    call AI_SetProfileThinkCallback(AI_Aradion_ProfileId, function Think)
    call RegisterBarks()

    set AutoEnableTimer = CreateTimer()
    call TimerStart(AutoEnableTimer, AUTO_ENABLE_INTERVAL, true, function TryAutoEnable)
endfunction

endlibrary
