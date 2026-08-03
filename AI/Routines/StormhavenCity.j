/**
    StormhavenCity

    Author: Valdemar
    Version:

    Description:
    Ambient AIRoutines setup for Stormhaven citizens. AIRoutines creates and
    manages thirty Player(8) city units in zone 13, using a weighted random
    unit-type pool and several non-harvest city routines for street walking,
    market idling, social movement, and nearby-player ambient chat.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AIRoutines.j`, `Reputation.j`, and `Table`. The map must
    provide `gg_rct_013Stormhaven`.

    API:
    call StormhavenCity_Refresh()
    set started = StormhavenCity_DebugForceChat()

**/
library StormhavenCity initializer Init requires AIRoutines, Reputation, Table, FallenHeroState

globals
    // Configuration
    private constant integer SHC_OWNER_PLAYER_ID = 8
    private constant integer SHC_ROUTINE_ZONE_ID = 13
    private constant integer SHC_STREET_COUNT = 25
    private constant integer SHC_MARKET_COUNT = 15
    private constant integer SHC_SOCIAL_COUNT = 12
    private constant real SHC_RESPAWN_DELAY = 45.00
    private constant real SHC_RANDOM_FACING = -1.00
    private constant real SHC_TURNOVER_MIN = 240.00
    private constant real SHC_TURNOVER_MAX = 620.00
    private constant real SHC_TURNOVER_REMOVE_DELAY = 12.00
    private constant real SHC_TURNOVER_PLAYER_GUARD_RANGE = 1250.00
    private constant string SHC_FACTION_NAME = "Stormhaven"
    private constant integer SHC_CLASS_MALE = 1
    private constant integer SHC_CLASS_FEMALE = 2
    private constant integer SHC_CLASS_CHILD = 3
    private constant integer SHC_CHAT_VARIATION_COUNT = 10
    private constant integer SHC_STREET_CHAT_CHANCE = 18
    private constant integer SHC_MARKET_CHAT_CHANCE = 18
    private constant integer SHC_SOCIAL_CHAT_CHANCE = 28
    private constant integer SHC_DEBUG_CHAT_CHANCE = 100
    private constant real SHC_CHAT_PLAYER_RANGE = 3000.00
    private constant real SHC_CHAT_PARTNER_RANGE = 420.00
    private constant real SHC_CHAT_REPLY_DELAY = 2.70
    private constant real SHC_CHAT_LOCK_DURATION = 9.00
    private constant real SHC_CHAT_LINE_LIFESPAN = 2.35
    private constant real SHC_CHAT_LINE_FADEPOINT = 1.60
    private constant real SHC_CHAT_TEXT_SIZE = 0.018
    private constant real SHC_CHAT_Z_OFFSET = 85.00

    private integer SHC_StreetRoutineId = 0
    private integer SHC_MarketRoutineId = 0
    private integer SHC_SocialRoutineId = 0
    private integer SHC_StreetGroupId = 0
    private integer SHC_MarketGroupId = 0
    private integer SHC_SocialGroupId = 0
    private boolean SHC_ChatActive = false
    private group SHC_ChatEnumGroup = null
    private timer SHC_ChatReplyTimer = null
    private timer SHC_ChatResetTimer = null
    private unit SHC_ChatSpeaker = null
    private unit SHC_ChatResponder = null
    private unit SHC_ChatPickResult = null
    private string SHC_ChatReplyText = ""
    private Table SHC_CitizenClass = 0
endglobals

private function IsAliveUnit takes unit whichUnit returns boolean
    return FallenHeroState_IsAlive(whichUnit)
endfunction

private function GetCitizenClass takes integer unitTypeId returns integer
    if SHC_CitizenClass == 0 then
        return 0
    endif
    return SHC_CitizenClass[unitTypeId]
endfunction

private function IsStormhavenCitizen takes unit whichUnit returns boolean
    return IsAliveUnit(whichUnit) and GetOwningPlayer(whichUnit) == Player(SHC_OWNER_PLAYER_ID) and GetCitizenClass(GetUnitTypeId(whichUnit)) > 0
endfunction

private function IsPlayerNearUnit takes unit whichUnit returns boolean
    local unit enumUnit
    local boolean found = false
    if whichUnit == null or SHC_ChatEnumGroup == null then
        return false
    endif

    call GroupEnumUnitsInRange(SHC_ChatEnumGroup, GetUnitX(whichUnit), GetUnitY(whichUnit), SHC_CHAT_PLAYER_RANGE, null)
    loop
        set enumUnit = FirstOfGroup(SHC_ChatEnumGroup)
        exitwhen enumUnit == null or found
        call GroupRemoveUnit(SHC_ChatEnumGroup, enumUnit)
        if GetOwningPlayer(enumUnit) == Player(0) and IsAliveUnit(enumUnit) and not IsUnitHidden(enumUnit) then
            set found = true
        endif
    endloop
    call GroupClear(SHC_ChatEnumGroup)

    set enumUnit = null
    return found
endfunction

private function GetOpeningLine takes integer speakerClass, integer responderClass, integer lineIndex returns string
    if speakerClass == SHC_CLASS_CHILD then
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "Race you to the well!"
            elseif lineIndex == 2 then
                return "I saw a guard trip today."
            elseif lineIndex == 3 then
                return "Let us hide behind the crates."
            elseif lineIndex == 4 then
                return "The baker gave me a burnt roll."
            elseif lineIndex == 5 then
                return "I found a copper pin by the chapel."
            elseif lineIndex == 6 then
                return "Bet you cannot skip three stones."
            elseif lineIndex == 7 then
                return "My boots are still wet."
            elseif lineIndex == 8 then
                return "I heard bells after midnight."
            elseif lineIndex == 9 then
                return "There is a loose brick by the wall."
            endif
            return "I drew a map of the alleys."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "Can I help at the bakery?"
            elseif lineIndex == 2 then
                return "The fountain looks silver today."
            elseif lineIndex == 3 then
                return "I found a button near the gate."
            elseif lineIndex == 4 then
                return "May I polish the shrine bell?"
            elseif lineIndex == 5 then
                return "Why do grownups whisper so much?"
            elseif lineIndex == 6 then
                return "I swept the step twice already."
            elseif lineIndex == 7 then
                return "Do you need more thread?"
            elseif lineIndex == 8 then
                return "The apples smelled sweet today."
            elseif lineIndex == 9 then
                return "Can I visit the market alone?"
            endif
            return "A soldier smiled at me."
        else
            if lineIndex == 1 then
                return "Did you ever face a bandit?"
            elseif lineIndex == 2 then
                return "Can I carry a real sword someday?"
            elseif lineIndex == 3 then
                return "Why do guards stare at the road?"
            elseif lineIndex == 4 then
                return "Is the gate taller than a tower?"
            elseif lineIndex == 5 then
                return "Can I ring the warning bell?"
            elseif lineIndex == 6 then
                return "Did you build that cart?"
            elseif lineIndex == 7 then
                return "Why is your hammer so heavy?"
            elseif lineIndex == 8 then
                return "Are there ships beyond the river?"
            elseif lineIndex == 9 then
                return "Did you see the king once?"
            endif
            return "Can you teach me to whistle loud?"
        endif
    elseif speakerClass == SHC_CLASS_FEMALE then
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "Stay where the lamps can see you."
            elseif lineIndex == 2 then
                return "Did you finish your letters?"
            elseif lineIndex == 3 then
                return "Take this bread before it cools."
            elseif lineIndex == 4 then
                return "Your scarf is dragging again."
            elseif lineIndex == 5 then
                return "Wash your hands before supper."
            elseif lineIndex == 6 then
                return "Tell your brother to come home."
            elseif lineIndex == 7 then
                return "Do not chase carts in the square."
            elseif lineIndex == 8 then
                return "Mind the puddle by the pump."
            elseif lineIndex == 9 then
                return "Keep away from the south steps."
            endif
            return "Carry this note to Mira."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "The market is thin on onions."
            elseif lineIndex == 2 then
                return "My wash will never dry in this fog."
            elseif lineIndex == 3 then
                return "The north gate was closed at dawn."
            elseif lineIndex == 4 then
                return "I sold the last candle before noon."
            elseif lineIndex == 5 then
                return "The priest asked for fresh linen."
            elseif lineIndex == 6 then
                return "My neighbor argues with barrels."
            elseif lineIndex == 7 then
                return "The well water tasted of iron."
            elseif lineIndex == 8 then
                return "I heard singing near the barracks."
            elseif lineIndex == 9 then
                return "Your daughter grows taller daily."
            endif
            return "I saved you a bolt of blue cloth."
        else
            if lineIndex == 1 then
                return "The cobbles near the well need fixing."
            elseif lineIndex == 2 then
                return "Your stall sign is crooked again."
            elseif lineIndex == 3 then
                return "Keep your voice down by the shrine."
            elseif lineIndex == 4 then
                return "The flour sacks arrived torn."
            elseif lineIndex == 5 then
                return "The east awning leaks badly."
            elseif lineIndex == 6 then
                return "Are you guarding or gossiping?"
            elseif lineIndex == 7 then
                return "The bell rope is fraying."
            elseif lineIndex == 8 then
                return "Your ledger looks worried."
            elseif lineIndex == 9 then
                return "Bring more coal before evening."
            endif
            return "The children found your chalk marks."
        endif
    else
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "Mind the cart wheels, little one."
            elseif lineIndex == 2 then
                return "No climbing the fountain today."
            elseif lineIndex == 3 then
                return "Your mother is looking for you."
            elseif lineIndex == 4 then
                return "Keep your hands off the tool rack."
            elseif lineIndex == 5 then
                return "That gate chain can pinch fingers."
            elseif lineIndex == 6 then
                return "Run along before the bell sounds."
            elseif lineIndex == 7 then
                return "Did you lose your cap again?"
            elseif lineIndex == 8 then
                return "Stay clear of the grain carts."
            elseif lineIndex == 9 then
                return "Take this nail to the smith."
            endif
            return "Count the steps to the chapel."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "The watch doubled at the western gate."
            elseif lineIndex == 2 then
                return "Fresh nails for your shutters are ready."
            elseif lineIndex == 3 then
                return "Did the baker save rye loaves?"
            elseif lineIndex == 4 then
                return "Your roof tile came loose again."
            elseif lineIndex == 5 then
                return "I brought the spice crate you asked for."
            elseif lineIndex == 6 then
                return "The tailor wants payment by dusk."
            elseif lineIndex == 7 then
                return "I heard the bridge toll may rise."
            elseif lineIndex == 8 then
                return "Your lantern glass is cracked."
            elseif lineIndex == 9 then
                return "The council clerk looked pale today."
            endif
            return "The well chain sounds rough."
        else
            if lineIndex == 1 then
                return "Patrol came back muddy again."
            elseif lineIndex == 2 then
                return "Stone prices climbed this week."
            elseif lineIndex == 3 then
                return "The tavern watered the ale."
            elseif lineIndex == 4 then
                return "The west wall still sweats after rain."
            elseif lineIndex == 5 then
                return "I lost two hours in the permit line."
            elseif lineIndex == 6 then
                return "Smith says iron is short."
            elseif lineIndex == 7 then
                return "Gate captain wants extra lanterns."
            elseif lineIndex == 8 then
                return "The bridge planks creak worse now."
            elseif lineIndex == 9 then
                return "Did you hear drums last night?"
            endif
            return "The tax man counted my barrels."
        endif
    endif
endfunction

private function GetReplyLine takes integer speakerClass, integer responderClass, integer lineIndex returns string
    if speakerClass == SHC_CLASS_CHILD then
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "Only if you do not cheat again."
            elseif lineIndex == 2 then
                return "Was it the tall one by the gate?"
            elseif lineIndex == 3 then
                return "Not too long, they check there."
            elseif lineIndex == 4 then
                return "Lucky. I only got crumbs."
            elseif lineIndex == 5 then
                return "Does it have a mark on it?"
            elseif lineIndex == 6 then
                return "I can skip four if no one watches."
            elseif lineIndex == 7 then
                return "Then stop jumping in gutters."
            elseif lineIndex == 8 then
                return "That was the watch changing posts."
            elseif lineIndex == 9 then
                return "Show me before someone fixes it."
            endif
            return "Does it include secret shortcuts?"
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "You may carry the small basket."
            elseif lineIndex == 2 then
                return "That means clouds are coming."
            elseif lineIndex == 3 then
                return "Give it to the watch desk."
            elseif lineIndex == 4 then
                return "Only after your chores are done."
            elseif lineIndex == 5 then
                return "Because Stormhaven has sharp ears."
            elseif lineIndex == 6 then
                return "Then sweep once for pride."
            elseif lineIndex == 7 then
                return "Blue, if the trader still has any."
            elseif lineIndex == 8 then
                return "Sweet ones cost more than sense."
            elseif lineIndex == 9 then
                return "Not past the statue, and not alone."
            endif
            return "Then you gave him hope today."
        else
            if lineIndex == 1 then
                return "Once, and I chose the wiser road."
            elseif lineIndex == 2 then
                return "Start with carrying your chores."
            elseif lineIndex == 3 then
                return "Roads bring both coin and trouble."
            elseif lineIndex == 4 then
                return "Tall enough to keep stories outside."
            elseif lineIndex == 5 then
                return "Only if danger is real."
            elseif lineIndex == 6 then
                return "I fixed it after someone crashed it."
            elseif lineIndex == 7 then
                return "So stubborn nails learn manners."
            elseif lineIndex == 8 then
                return "Ships, storms, and sailors' lies."
            elseif lineIndex == 9 then
                return "From far away, and briefly."
            endif
            return "After you learn to listen first."
        endif
    elseif speakerClass == SHC_CLASS_FEMALE then
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "I know, I know, no alleys."
            elseif lineIndex == 2 then
                return "Almost. The long words are mean."
            elseif lineIndex == 3 then
                return "For me? I will share it."
            elseif lineIndex == 4 then
                return "It makes me look important."
            elseif lineIndex == 5 then
                return "But the dirt is from exploring."
            elseif lineIndex == 6 then
                return "He owes me two buttons first."
            elseif lineIndex == 7 then
                return "I was racing their shadows."
            elseif lineIndex == 8 then
                return "That puddle knows my name."
            elseif lineIndex == 9 then
                return "Are they cursed or just broken?"
            endif
            return "Can I read the seal first?"
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "The caravans are late again."
            elseif lineIndex == 2 then
                return "Hang it by the smithy wall."
            elseif lineIndex == 3 then
                return "Then the patrol saw something."
            elseif lineIndex == 4 then
                return "Storm clouds make good customers."
            elseif lineIndex == 5 then
                return "He always asks after rain."
            elseif lineIndex == 6 then
                return "At least barrels listen better."
            elseif lineIndex == 7 then
                return "The old pipes need mercy."
            elseif lineIndex == 8 then
                return "Then the recruits found payday."
            elseif lineIndex == 9 then
                return "And sharper with every question."
            endif
            return "Bless you, I need color today."
        else
            if lineIndex == 1 then
                return "I will tell the stoneworker."
            elseif lineIndex == 2 then
                return "Wind did it, or my hammer did."
            elseif lineIndex == 3 then
                return "Fair enough, the old priest hears all."
            elseif lineIndex == 4 then
                return "I will speak to the cart driver."
            elseif lineIndex == 5 then
                return "I patched it twice already."
            elseif lineIndex == 6 then
                return "A good guard can do both."
            elseif lineIndex == 7 then
                return "I will replace it before dusk."
            elseif lineIndex == 8 then
                return "Numbers know when coin is missing."
            elseif lineIndex == 9 then
                return "The forge is already hungry."
            endif
            return "Then my plans are public now."
        endif
    else
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "I am faster than carts."
            elseif lineIndex == 2 then
                return "But yesterday was allowed."
            elseif lineIndex == 3 then
                return "Then I was never here."
            elseif lineIndex == 4 then
                return "I only touched the shiny one."
            elseif lineIndex == 5 then
                return "My fingers are careful."
            elseif lineIndex == 6 then
                return "I can run after it sounds too."
            elseif lineIndex == 7 then
                return "It ran away in the wind."
            elseif lineIndex == 8 then
                return "I know which drivers shout."
            elseif lineIndex == 9 then
                return "Is it a brave nail?"
            endif
            return "I already counted twice."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "Then the city expects bad news."
            elseif lineIndex == 2 then
                return "Good, the wind keeps testing them."
            elseif lineIndex == 3 then
                return "Two, if no guard bought them."
            elseif lineIndex == 4 then
                return "Then Stormhaven wants me busy."
            elseif lineIndex == 5 then
                return "Put it under the dry awning."
            elseif lineIndex == 6 then
                return "He can want until morning."
            elseif lineIndex == 7 then
                return "Then fewer shoppers will cross."
            elseif lineIndex == 8 then
                return "Leave it, I have a spare."
            elseif lineIndex == 9 then
                return "Paperwork can wound a person."
            endif
            return "Grease it before it snaps."
        else
            if lineIndex == 1 then
                return "Muddy boots mean quiet roads."
            elseif lineIndex == 2 then
                return "Everything climbs except wages."
            elseif lineIndex == 3 then
                return "Again? Then I will drink slowly."
            elseif lineIndex == 4 then
                return "Old stone remembers every storm."
            elseif lineIndex == 5 then
                return "Bureaucracy is Stormhaven's moat."
            elseif lineIndex == 6 then
                return "Then nails will cost like silver."
            elseif lineIndex == 7 then
                return "He can pay for extra oil."
            elseif lineIndex == 8 then
                return "They complain less than my knees."
            elseif lineIndex == 9 then
                return "Only thunder, I hope."
            endif
            return "Hide the empty ones next time."
        endif
    endif
endfunction

private function ShowChatLine takes unit whichUnit, string line returns nothing
    local texttag tag
    if line == "" or not IsAliveUnit(whichUnit) or not IsPlayerNearUnit(whichUnit) then
        return
    endif

    set tag = CreateTextTag()
    call SetTextTagText(tag, line, SHC_CHAT_TEXT_SIZE)
    call SetTextTagPosUnit(tag, whichUnit, SHC_CHAT_Z_OFFSET)
    call SetTextTagColor(tag, 235, 230, 205, 255)
    call SetTextTagVelocity(tag, 0.00, 0.025)
    call SetTextTagPermanent(tag, false)
    call SetTextTagLifespan(tag, SHC_CHAT_LINE_LIFESPAN)
    call SetTextTagFadepoint(tag, SHC_CHAT_LINE_FADEPOINT)
    call SetTextTagVisibility(tag, GetLocalPlayer() == Player(0))
    set tag = null
endfunction

private function EndChat takes nothing returns nothing
    set SHC_ChatActive = false
    set SHC_ChatSpeaker = null
    set SHC_ChatResponder = null
    set SHC_ChatPickResult = null
    set SHC_ChatReplyText = ""
endfunction

private function PlayChatReply takes nothing returns nothing
    if IsAliveUnit(SHC_ChatResponder) and IsPlayerNearUnit(SHC_ChatResponder) then
        call IssueImmediateOrder(SHC_ChatResponder, "stop")
        call SetUnitAnimation(SHC_ChatResponder, "stand")
        call ShowChatLine(SHC_ChatResponder, SHC_ChatReplyText)
    endif
endfunction

private function PickChatPartner takes unit speaker returns unit
    local unit enumUnit
    local integer seen = 0
    set SHC_ChatPickResult = null
    if speaker == null or SHC_ChatEnumGroup == null then
        return null
    endif

    call GroupEnumUnitsInRange(SHC_ChatEnumGroup, GetUnitX(speaker), GetUnitY(speaker), SHC_CHAT_PARTNER_RANGE, null)
    loop
        set enumUnit = FirstOfGroup(SHC_ChatEnumGroup)
        exitwhen enumUnit == null
        call GroupRemoveUnit(SHC_ChatEnumGroup, enumUnit)
        if enumUnit != speaker and IsStormhavenCitizen(enumUnit) then
            set seen = seen + 1
            if GetRandomInt(1, seen) == 1 then
                set SHC_ChatPickResult = enumUnit
            endif
        endif
    endloop
    call GroupClear(SHC_ChatEnumGroup)

    set enumUnit = null
    return SHC_ChatPickResult
endfunction

private function TryStartChat takes unit speaker, integer chance returns boolean
    local unit partner
    local integer speakerClass
    local integer partnerClass
    local integer lineIndex
    local string opening

    if SHC_ChatActive or chance <= 0 or GetRandomInt(1, 100) > chance then
        return false
    endif
    if not IsStormhavenCitizen(speaker) or not IsPlayerNearUnit(speaker) then
        return false
    endif

    set partner = PickChatPartner(speaker)
    if partner == null then
        set partner = null
        return false
    endif

    set speakerClass = GetCitizenClass(GetUnitTypeId(speaker))
    set partnerClass = GetCitizenClass(GetUnitTypeId(partner))
    set lineIndex = GetRandomInt(1, SHC_CHAT_VARIATION_COUNT)
    set opening = GetOpeningLine(speakerClass, partnerClass, lineIndex)
    set SHC_ChatReplyText = GetReplyLine(speakerClass, partnerClass, lineIndex)
    if opening == "" or SHC_ChatReplyText == "" then
        set SHC_ChatReplyText = ""
        set SHC_ChatPickResult = null
        set partner = null
        return false
    endif

    set SHC_ChatActive = true
    set SHC_ChatSpeaker = speaker
    set SHC_ChatResponder = partner
    set SHC_ChatPickResult = null

    call IssueImmediateOrder(speaker, "stop")
    call IssueImmediateOrder(partner, "stop")
    call SetUnitAnimation(speaker, "stand")
    call SetUnitAnimation(partner, "stand")
    call SetUnitFacingToFaceUnitTimed(speaker, partner, 0.20)
    call SetUnitFacingToFaceUnitTimed(partner, speaker, 0.20)
    call ShowChatLine(speaker, opening)
    call TimerStart(SHC_ChatReplyTimer, SHC_CHAT_REPLY_DELAY, false, function PlayChatReply)
    call TimerStart(SHC_ChatResetTimer, SHC_CHAT_LOCK_DURATION, false, function EndChat)

    set partner = null
    return true
endfunction

private function RandomCityPointOrder takes unit whichUnit, string order returns nothing
    local real x
    local real y
    if whichUnit == null then
        return
    endif

    set x = GetRandomReal(GetRectMinX(gg_rct_013Stormhaven), GetRectMaxX(gg_rct_013Stormhaven))
    set y = GetRandomReal(GetRectMinY(gg_rct_013Stormhaven), GetRectMaxY(gg_rct_013Stormhaven))
    call IssuePointOrder(whichUnit, order, x, y)
endfunction

private function PlayCityIdle takes unit whichUnit, string animationName returns nothing
    if whichUnit == null then
        return
    endif
    if animationName == null or animationName == "" then
        set animationName = "stand"
    endif

    call IssueImmediateOrder(whichUnit, "stop")
    call SetUnitAnimation(whichUnit, animationName)
endfunction

private function PlayMarketIdle takes unit whichUnit returns nothing
    if GetCitizenClass(GetUnitTypeId(whichUnit)) == SHC_CLASS_CHILD then
        call PlayCityIdle(whichUnit, "stand")
    else
        call PlayCityIdle(whichUnit, "stand work")
    endif
endfunction

private function StreetAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    if TryStartChat(whichUnit, SHC_STREET_CHAT_CHANCE) then
        set whichUnit = null
        return
    endif

    set action = GetRandomInt(1, 5)
    if action <= 2 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, "stand")
    endif

    set whichUnit = null
endfunction

private function MarketAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    if TryStartChat(whichUnit, SHC_MARKET_CHAT_CHANCE) then
        set whichUnit = null
        return
    endif

    set action = GetRandomInt(1, 5)
    if action <= 3 then
        call PlayMarketIdle(whichUnit)
    elseif action == 4 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, "stand")
    endif

    set whichUnit = null
endfunction

private function SocialAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    if TryStartChat(whichUnit, SHC_SOCIAL_CHAT_CHANCE) then
        set whichUnit = null
        return
    endif

    set action = GetRandomInt(1, 5)
    if action <= 2 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, "stand")
    endif

    set whichUnit = null
endfunction

private function CreateStreetRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Stormhaven Streets")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 7.00, 15.00)
    call AIRoutines_AddCallbackStep(routineId, 4.00, 9.00, function StreetAction)
    call AIRoutines_AddWaitStep(routineId, 2.00, 5.00)
    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 8.00, 18.00)
    call AIRoutines_AddStandStep(routineId, "stand", 3.00, 8.00)
    return routineId
endfunction

private function CreateMarketRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Stormhaven Market Citizens")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 5.00, 12.00)
    call AIRoutines_AddCallbackStep(routineId, 8.00, 18.00, function MarketAction)
    call AIRoutines_AddWaitStep(routineId, 3.00, 7.00)
    call AIRoutines_AddCallbackStep(routineId, 5.00, 12.00, function StreetAction)
    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 6.00, 14.00)
    return routineId
endfunction

private function CreateSocialRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Stormhaven Social Citizens")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 6.00, 14.00)
    call AIRoutines_AddCallbackStep(routineId, 6.00, 16.00, function SocialAction)
    call AIRoutines_AddWaitStep(routineId, 3.00, 8.00)
    call AIRoutines_AddCallbackStep(routineId, 4.00, 10.00, function MarketAction)
    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 5.00, 12.00)
    return routineId
endfunction

private function AddCitizenTypeEx takes integer unitTypeId, integer weight, integer citizenClass returns nothing
    set SHC_CitizenClass[unitTypeId] = citizenClass
    if SHC_StreetGroupId > 0 then
        call AIRoutines_AddManagedUnitGroupType(SHC_StreetGroupId, unitTypeId, weight)
    endif
    if SHC_MarketGroupId > 0 then
        call AIRoutines_AddManagedUnitGroupType(SHC_MarketGroupId, unitTypeId, weight)
    endif
    if SHC_SocialGroupId > 0 then
        call AIRoutines_AddManagedUnitGroupType(SHC_SocialGroupId, unitTypeId, weight)
    endif
    call Reputation_RegisterUnitTypeFaction(unitTypeId, SHC_FACTION_NAME)
endfunction

private function AddCitizenType takes integer unitTypeId, integer weight returns nothing
    call AddCitizenTypeEx(unitTypeId, weight, SHC_CLASS_MALE)
endfunction

private function RegisterCitizenTypes takes nothing returns nothing
    call AddCitizenType('n65M', 4)
    call AddCitizenType('n65N', 4)
    call AddCitizenType('n65O', 4)
    call AddCitizenType('n65P', 4)
    call AddCitizenType('n65Q', 4)
    call AddCitizenType('n65R', 3)
    call AddCitizenTypeEx('nvlw', 4, SHC_CLASS_FEMALE)
    call AddCitizenTypeEx('nvlk', 2, SHC_CLASS_CHILD)
    call AddCitizenTypeEx('nvk2', 2, SHC_CLASS_CHILD)
endfunction

private function CreateCitizenGroup takes integer routineId, integer count returns integer
    local integer spawnGroupId
    if routineId <= 0 then
        return 0
    endif

    set spawnGroupId = AIRoutines_CreateManagedRandomUnitGroupInZone(Player(SHC_OWNER_PLAYER_ID), gg_rct_013Stormhaven, routineId, count, SHC_RESPAWN_DELAY, SHC_RANDOM_FACING, SHC_ROUTINE_ZONE_ID)
    if spawnGroupId > 0 then
        call AIRoutines_SetManagedUnitGroupTurnover(spawnGroupId, SHC_TURNOVER_MIN, SHC_TURNOVER_MAX, gg_rct_013Stormhaven, SHC_TURNOVER_REMOVE_DELAY)
        call AIRoutines_SetManagedUnitGroupRemovalPlayerGuardRange(spawnGroupId, SHC_TURNOVER_PLAYER_GUARD_RANGE)
    endif
    return spawnGroupId
endfunction

public function Refresh takes nothing returns nothing
    call AIRoutines_RefillManagedUnitGroup(SHC_StreetGroupId)
    call AIRoutines_RefillManagedUnitGroup(SHC_MarketGroupId)
    call AIRoutines_RefillManagedUnitGroup(SHC_SocialGroupId)
endfunction

public function DebugForceChat takes nothing returns boolean
    local group enumGroup = CreateGroup()
    local unit enumUnit
    local boolean started = false
    call GroupEnumUnitsInRect(enumGroup, gg_rct_013Stormhaven, null)
    loop
        set enumUnit = FirstOfGroup(enumGroup)
        exitwhen enumUnit == null or started
        call GroupRemoveUnit(enumGroup, enumUnit)
        if IsStormhavenCitizen(enumUnit) and IsPlayerNearUnit(enumUnit) then
            set started = TryStartChat(enumUnit, SHC_DEBUG_CHAT_CHANCE)
        endif
    endloop

    call DestroyGroup(enumGroup)
    set enumUnit = null
    set enumGroup = null
    return started
endfunction

private function Init takes nothing returns nothing
    set SHC_CitizenClass = Table.create()
    set SHC_ChatEnumGroup = CreateGroup()
    set SHC_ChatReplyTimer = CreateTimer()
    set SHC_ChatResetTimer = CreateTimer()

    set SHC_StreetRoutineId = CreateStreetRoutine()
    set SHC_MarketRoutineId = CreateMarketRoutine()
    set SHC_SocialRoutineId = CreateSocialRoutine()

    set SHC_StreetGroupId = CreateCitizenGroup(SHC_StreetRoutineId, SHC_STREET_COUNT)
    set SHC_MarketGroupId = CreateCitizenGroup(SHC_MarketRoutineId, SHC_MARKET_COUNT)
    set SHC_SocialGroupId = CreateCitizenGroup(SHC_SocialRoutineId, SHC_SOCIAL_COUNT)

    call RegisterCitizenTypes()
    call Refresh()
endfunction

endlibrary
