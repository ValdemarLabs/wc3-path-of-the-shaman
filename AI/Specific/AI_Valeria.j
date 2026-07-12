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
    call AI_RegisterBarkLine(AI_Valeria_ProfileId, barkType, text, soundKey)
endfunction

private function RegisterBarks takes nothing returns nothing
    call RegisterNeutralBark(AI_BARK_GREET, "Keep your hands where I can see them.", "Valeria_0181")
    call RegisterNeutralBark(AI_BARK_GREET, "Do not test my patience, outsider.", "Valeria_0182")
    call RegisterNeutralBark(AI_BARK_GREET, "Aradion may listen. I am not so naive.", "Valeria_0183")
    call RegisterFriendlyBark(AI_BARK_GREET, "You came back. That counts for something.", "Valeria_0184")
    call RegisterFriendlyBark(AI_BARK_GREET, "Is this event important to you?", "Valeria_0185")
    call RegisterFriendlyBark(AI_BARK_GREET, "If you came to help, then speak.", "Valeria_0186")
    call RegisterCovenantBark(AI_BARK_GREET, "I'm glad that you could make it back here.", "Valeria_0187")
    call RegisterCovenantBark(AI_BARK_GREET, "Elarindor knows your steps now. So do I.", "Valeria_0188")
    call RegisterCovenantBark(AI_BARK_GREET, "A trusted bow is waiting for you.", "Valeria_0189")
    call RegisterExaltedBark(AI_BARK_GREET, "My bow is yours, friend of the Vale.", "Valeria_0190")
    call RegisterExaltedBark(AI_BARK_GREET, "You are welcome beneath these trees.", "Valeria_0191")
    call RegisterExaltedBark(AI_BARK_GREET, "Elarindor is safer when you return.", "Valeria_0192")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Leave before the trees decide you lingered too long.", "Valeria_0193")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Go. I have watched strangers enough for one day.", "Valeria_0194")
    call RegisterNeutralBark(AI_BARK_FAREWELL, "Keep away from Aradion unless your word stays true.", "Valeria_0195")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "Safe travels.", "Valeria_0196")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "Stay clear of the old paths after dark.", "Valeria_0197")
    call RegisterFriendlyBark(AI_BARK_FAREWELL, "Return with quiet steps, not trouble.", "Valeria_0198")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Go with my watch over you.", "Valeria_0199")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "May the red leaves hide your trail.", "Valeria_0200")
    call RegisterCovenantBark(AI_BARK_FAREWELL, "Call if the Vale darkens again.", "Valeria_0201")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "Return safely. Elarindor still needs its champions.", "Valeria_0202")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "Walk with my trust, and come back alive.", "Valeria_0203")
    call RegisterExaltedBark(AI_BARK_FAREWELL, "The Vale will keep a path open for you.", "Valeria_0204")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "I will lower my bow when I have reason.", "Valeria_0205")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "I can wait. My arrow cannot.", "Valeria_0206")
    call RegisterNeutralBark(AI_BARK_PASSIVE, "Do not mistake restraint for trust.", "Valeria_0207")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "I can hold my shot if you keep your word.", "Valeria_0208")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "No needless blood today.", "Valeria_0209")
    call RegisterFriendlyBark(AI_BARK_PASSIVE, "I will watch and let you lead.", "Valeria_0210")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "No needless blood. We guard what remains.", "Valeria_0211")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "I trust your caution here.", "Valeria_0212")
    call RegisterCovenantBark(AI_BARK_PASSIVE, "The Vale has suffered enough.", "Valeria_0213")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "Peace, then. Your judgment has earned that.", "Valeria_0214")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "If you call for restraint, I will honor it.", "Valeria_0215")
    call RegisterExaltedBark(AI_BARK_PASSIVE, "My bow rests while your word holds.", "Valeria_0216")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Walk where I can see you.", "Valeria_0217")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Stay ahead of my arrow, not behind it.", "Valeria_0218")
    call RegisterNeutralBark(AI_BARK_NORMAL, "Eyes open.", "Valeria_0219")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "Eyes forward. I will cover the flank.", "Valeria_0220")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "Keep close and keep quiet.", "Valeria_0221")
    call RegisterFriendlyBark(AI_BARK_NORMAL, "I will take the high line.", "Valeria_0222")
    call RegisterCovenantBark(AI_BARK_NORMAL, "Let's do this.", "Valeria_0223")
    call RegisterCovenantBark(AI_BARK_NORMAL, "I know a safer trail. Follow my marks.", "Valeria_0224")
    call RegisterCovenantBark(AI_BARK_NORMAL, "We move together, or not at all.", "Valeria_0225")
    call RegisterExaltedBark(AI_BARK_NORMAL, "Lead on. My arrows will clear the path.", "Valeria_0226")
    call RegisterExaltedBark(AI_BARK_NORMAL, "Your path is my path today.", "Valeria_0227")
    call RegisterExaltedBark(AI_BARK_NORMAL, "The Vale bends kinder around trusted steps.", "Valeria_0228")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "Finally. Something I am allowed to shoot.", "Valeria_0229")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "Point me at the threat and stay out of my line.", "Valeria_0230")
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, "If they move against us, they fall.", "Valeria_0231")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "If they threaten the Vale, they fall.", "Valeria_0232")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "Good. Let them learn why rangers keep distance.", "Valeria_0233")
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, "I have been waiting for a clean target.", "Valeria_0234")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "No mercy for those who ruin Elarindor.", "Valeria_0235")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "For the Vale. Make every strike count.", "Valeria_0236")
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, "The trees will hide us; my arrows will not.", "Valeria_0237")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "Together, we strike before fear takes root.", "Valeria_0238")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "For Elarindor, and for the friend who stood by it.", "Valeria_0239")
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, "Let them learn what the Vale still protects.", "Valeria_0240")
    call RegisterNeutralBark(AI_BARK_HOLD, "I will hold this line, not your hand.", "Valeria_0241")
    call RegisterNeutralBark(AI_BARK_HOLD, "I can guard this ground. Do not make me regret it.", "Valeria_0242")
    call RegisterNeutralBark(AI_BARK_HOLD, "Nothing passes unless I choose.", "Valeria_0243")
    call RegisterFriendlyBark(AI_BARK_HOLD, "This ground gives me a clean line.", "Valeria_0244")
    call RegisterFriendlyBark(AI_BARK_HOLD, "I will hold here. Keep moving.", "Valeria_0245")
    call RegisterFriendlyBark(AI_BARK_HOLD, "Leave this approach to me.", "Valeria_0246")
    call RegisterCovenantBark(AI_BARK_HOLD, "I will keep this pass sealed.", "Valeria_0247")
    call RegisterCovenantBark(AI_BARK_HOLD, "Trust the line. I will not let it break.", "Valeria_0248")
    call RegisterCovenantBark(AI_BARK_HOLD, "This is ranger ground now.", "Valeria_0249")
    call RegisterExaltedBark(AI_BARK_HOLD, "Nothing crosses while I breathe.", "Valeria_0250")
    call RegisterExaltedBark(AI_BARK_HOLD, "I will hold until you return.", "Valeria_0251")
    call RegisterExaltedBark(AI_BARK_HOLD, "I'll remain here with my bow, you go ahead!", "Valeria_0252")
    call RegisterNeutralBark(AI_BARK_KICKED, "Good. I prefer my own company.", "Valeria_0253")
    call RegisterNeutralBark(AI_BARK_KICKED, "Then I go back to my Aradion.", "Valeria_0254")
    call RegisterNeutralBark(AI_BARK_KICKED, "Fine. I was done watching your back.", "Valeria_0255")
    call RegisterFriendlyBark(AI_BARK_KICKED, "Then I will watch from the trees.", "Valeria_0256")
    call RegisterFriendlyBark(AI_BARK_KICKED, "Call if trouble finds you.", "Valeria_0257")
    call RegisterFriendlyBark(AI_BARK_KICKED, "Go carefully. I will not be far.", "Valeria_0258")
    call RegisterCovenantBark(AI_BARK_KICKED, "Call when the Vale needs my bow again.", "Valeria_0259")
    call RegisterCovenantBark(AI_BARK_KICKED, "I will return to Aradion, but my watch remains.", "Valeria_0260")
    call RegisterCovenantBark(AI_BARK_KICKED, "You know where to find me.", "Valeria_0261")
    call RegisterExaltedBark(AI_BARK_KICKED, "I will be near if you need me.", "Valeria_0262")
    call RegisterExaltedBark(AI_BARK_KICKED, "Our paths part, not our trust.", "Valeria_0263")
    call RegisterExaltedBark(AI_BARK_KICKED, "Send word and I will come.", "Valeria_0264")
    call RegisterNeutralBark(AI_BARK_IDLE, "Do not mistake silence for trust.", "Valeria_0265")
    call RegisterNeutralBark(AI_BARK_IDLE, "Every path through Elarindor carries a memory I would rather forget.", "Valeria_0266")
    call RegisterNeutralBark(AI_BARK_IDLE, "It is not wise to stay still in Vanguard Vale...", "Valeria_0267")
    call RegisterFriendlyBark(AI_BARK_IDLE, "Atleast the mighty red trees have retained their beauty in this place.", "Valeria_0268")
    call RegisterFriendlyBark(AI_BARK_IDLE, "The trees remember where the wraiths passed.", "Valeria_0269")
    call RegisterFriendlyBark(AI_BARK_IDLE, "I was a ranger before the Vale broke. I remain one after.", "Valeria_0270")
    call RegisterCovenantBark(AI_BARK_IDLE, "Aradion tries his best to end our people's suffering.", "Valeria_0271")
    call RegisterCovenantBark(AI_BARK_IDLE, "I could use a real bath, but that lake can do.", "Valeria_0272")
    call RegisterCovenantBark(AI_BARK_IDLE, "Aradion blames himself for the events that lead to our people's demise too much.", "Valeria_0273")
    call RegisterExaltedBark(AI_BARK_IDLE, "For once, the Vale feels almost willing to heal.", "Valeria_0274")
    call RegisterExaltedBark(AI_BARK_IDLE, "I have watched my brother turn into a monster... and now he is gone.", "Valeria_0275")
    call RegisterExaltedBark(AI_BARK_IDLE, "Some mornings here almost feel like home again.", "Valeria_0276")
    call RegisterNeutralBark(AI_BARK_MOVING, "Stay ahead of my arrow, not behind it.", "Valeria_0277")
    call RegisterNeutralBark(AI_BARK_MOVING, "Do not wander into my line of fire.", "Valeria_0278")
    call RegisterNeutralBark(AI_BARK_MOVING, "Quiet. I heard something in the brush.", "Valeria_0279")
    call RegisterFriendlyBark(AI_BARK_MOVING, "Quiet steps. Loose grip. Breathe.", "Valeria_0280")
    call RegisterFriendlyBark(AI_BARK_MOVING, "Keep on moving!", "Valeria_0281")
    call RegisterFriendlyBark(AI_BARK_MOVING, "I will mark the safer path.", "Valeria_0282")
    call RegisterCovenantBark(AI_BARK_MOVING, "I know a safer path. Follow close.", "Valeria_0283")
    call RegisterCovenantBark(AI_BARK_MOVING, "I had a pet faerie dragon once. She was so beautiful.", "Valeria_0284")
    call RegisterCovenantBark(AI_BARK_MOVING, "Your steps have grown quieter.", "Valeria_0285")
    call RegisterExaltedBark(AI_BARK_MOVING, "With you, even these old paths feel less cursed.", "Valeria_0286")
    call RegisterExaltedBark(AI_BARK_MOVING, "Walk with me. I know where the Vale still breathes.", "Valeria_0287")
    call RegisterExaltedBark(AI_BARK_MOVING, "Where is this adventure going this time?", "Valeria_0288")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "Take it. I would rather keep my hands free.", "Valeria_0289")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "Take this. It should serve you better.", "Valeria_0290")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "Use it well. Elarindor has few gifts left.", "Valeria_0291")
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, "A ranger shares what keeps an ally alive.", "Valeria_0292")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "I will use it if it serves the Vale.", "Valeria_0293")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "Useful. I will not waste it.", "Valeria_0294")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "You know a ranger's needs. Thank you.", "Valeria_0295")
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, "A thoughtful gift from a trusted hand. I accept.", "Valeria_0296")
    call RegisterCommonBark(AI_BARK_ATTACKING, "Wrong step.", "Valeria_0297")
    call RegisterCommonBark(AI_BARK_ATTACKING, "I have the shot.", "Valeria_0298")
    call RegisterCommonBark(AI_BARK_ATTACKING, "For Elarindor.", "Valeria_0299")
    call RegisterCommonBark(AI_BARK_ATTACKING, "Bal'a dash, malanore!", "Valeria_0300")
    call RegisterCommonBark(AI_BARK_CASTING, "Hold still.", "Valeria_0301")
    call RegisterCommonBark(AI_BARK_CASTING, "This arrow finds its mark.", "Valeria_0302")
    call RegisterCommonBark(AI_BARK_CASTING, "Let the old shadows bleed.", "Valeria_0303")
    call RegisterCommonBark(AI_BARK_CASTING, "By leaf and oath, fall.", "Valeria_0304")
    call RegisterCommonBark(AI_BARK_KILLING, "Stay down.", "Valeria_0305")
    call RegisterCommonBark(AI_BARK_KILLING, "Threat ended.", "Valeria_0306")
    call RegisterCommonBark(AI_BARK_KILLING, "One less scar on the Vale.", "Valeria_0307")
    call RegisterCommonBark(AI_BARK_KILLING, "Anar'alah belore!", "Valeria_0308")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No. Do not make this worse.", "Valeria_0309")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No. We do not fall here.", "Valeria_0310")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "Hold! I will not lose another ally.", "Valeria_0311")
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, "No! I swore you would leave this place alive.", "Valeria_0312")
endfunction

private function Init takes nothing returns nothing
    set AI_Valeria_ClassId = AI_RegisterClass("Ranger")
    set AI_Valeria_ProfileId = AI_RegisterProfile(AI_Valeria_ClassId, AI_VALERIA_UNIT, "Valeria")
    call AI_SetProfileFaction(AI_Valeria_ProfileId, "Elarindor")
    call AI_SetProfileCap(AI_Valeria_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_VALERIA_UNIT, 1)
    call AI_SetProfileAutonomous(AI_Valeria_ProfileId, false)
    call AI_SetProfileThinkCallback(AI_Valeria_ProfileId, function Think)
    call RegisterBarks()

    set AutoEnableTimer = CreateTimer()
    call TimerStart(AutoEnableTimer, AUTO_ENABLE_INTERVAL, true, function TryAutoEnable)
endfunction

endlibrary
