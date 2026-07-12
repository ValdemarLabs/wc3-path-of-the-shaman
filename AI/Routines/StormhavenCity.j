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

**/
library StormhavenCity initializer Init requires AIRoutines, Reputation, Table

globals
    // Configuration
    private constant integer SHC_OWNER_PLAYER_ID = 8
    private constant integer SHC_ROUTINE_ZONE_ID = 13
    private constant integer SHC_STREET_COUNT = 12
    private constant integer SHC_MARKET_COUNT = 10
    private constant integer SHC_SOCIAL_COUNT = 8
    private constant real SHC_RESPAWN_DELAY = 45.00
    private constant real SHC_RANDOM_FACING = -1.00
    private constant real SHC_TURNOVER_MIN = 240.00
    private constant real SHC_TURNOVER_MAX = 620.00
    private constant real SHC_TURNOVER_REMOVE_DELAY = 12.00
    private constant string SHC_FACTION_NAME = "Stormhaven"
    private constant integer SHC_CLASS_MALE = 1
    private constant integer SHC_CLASS_FEMALE = 2
    private constant integer SHC_CLASS_CHILD = 3
    private constant real SHC_CHAT_PLAYER_RANGE = 500.00
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
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD) and GetWidgetLife(whichUnit) > 0.405
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
            endif
            return "Let us hide behind the crates."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "Can I help at the bakery?"
            elseif lineIndex == 2 then
                return "The fountain looks silver today."
            endif
            return "I found a button near the gate."
        else
            if lineIndex == 1 then
                return "Did you ever fight a wolf?"
            elseif lineIndex == 2 then
                return "Can I carry a real sword someday?"
            endif
            return "Why do guards stare at the road?"
        endif
    elseif speakerClass == SHC_CLASS_FEMALE then
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "Stay where the lamps can see you."
            elseif lineIndex == 2 then
                return "Did you finish your letters?"
            endif
            return "Take this bread before it cools."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "The market is thin on onions."
            elseif lineIndex == 2 then
                return "My wash will never dry in this fog."
            endif
            return "The north gate was closed at dawn."
        else
            if lineIndex == 1 then
                return "The cobbles near the well need fixing."
            elseif lineIndex == 2 then
                return "Your stall sign is crooked again."
            endif
            return "Keep your voice down by the shrine."
        endif
    else
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "Mind the cart wheels, little one."
            elseif lineIndex == 2 then
                return "No climbing the fountain today."
            endif
            return "Your mother is looking for you."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "The watch doubled at the western gate."
            elseif lineIndex == 2 then
                return "Fresh nails for your shutters are ready."
            endif
            return "Did the baker save rye loaves?"
        else
            if lineIndex == 1 then
                return "Patrol came back muddy again."
            elseif lineIndex == 2 then
                return "Stone prices climbed this week."
            endif
            return "The tavern watered the ale."
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
            endif
            return "Not too long, they check there."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "You may carry the small basket."
            elseif lineIndex == 2 then
                return "That means clouds are coming."
            endif
            return "Give it to the watch desk."
        else
            if lineIndex == 1 then
                return "A hungry one, and I ran fast."
            elseif lineIndex == 2 then
                return "Start with carrying your chores."
            endif
            return "Roads bring both coin and trouble."
        endif
    elseif speakerClass == SHC_CLASS_FEMALE then
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "I know, I know, no alleys."
            elseif lineIndex == 2 then
                return "Almost. The long words are mean."
            endif
            return "For me? I will share it."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "The caravans are late again."
            elseif lineIndex == 2 then
                return "Hang it by the smithy wall."
            endif
            return "Then the patrol saw something."
        else
            if lineIndex == 1 then
                return "I will tell the stoneworker."
            elseif lineIndex == 2 then
                return "Wind did it, or my hammer did."
            endif
            return "Fair enough, the old priest hears all."
        endif
    else
        if responderClass == SHC_CLASS_CHILD then
            if lineIndex == 1 then
                return "I am faster than carts."
            elseif lineIndex == 2 then
                return "But yesterday was allowed."
            endif
            return "Then I was never here."
        elseif responderClass == SHC_CLASS_FEMALE then
            if lineIndex == 1 then
                return "Then the city expects bad news."
            elseif lineIndex == 2 then
                return "Good, the wind keeps testing them."
            endif
            return "Two, if no guard bought them."
        else
            if lineIndex == 1 then
                return "Muddy boots mean quiet roads."
            elseif lineIndex == 2 then
                return "Everything climbs except wages."
            endif
            return "Again? Then I will drink slowly."
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
    set lineIndex = GetRandomInt(1, 3)
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

private function PlayCityIdle takes unit whichUnit, integer action returns nothing
    if whichUnit == null then
        return
    endif

    call IssueImmediateOrder(whichUnit, "stop")
    if action == 1 then
        call SetUnitAnimation(whichUnit, "stand")
    elseif action == 2 then
        call SetUnitAnimation(whichUnit, "stand work")
    elseif action == 3 then
        call SetUnitAnimation(whichUnit, "stand ready")
    elseif action == 4 then
        call SetUnitAnimation(whichUnit, "spell")
    elseif action == 5 then
        call SetUnitAnimation(whichUnit, "stand victory")
    else
        call SetUnitAnimation(whichUnit, "attack")
    endif
endfunction

private function StreetAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    if TryStartChat(whichUnit, 12) then
        set whichUnit = null
        return
    endif

    set action = GetRandomInt(1, 7)
    if action <= 4 then
        call PlayCityIdle(whichUnit, action)
    elseif action == 5 then
        call RandomCityPointOrder(whichUnit, "move")
    elseif action == 6 then
        call IssueImmediateOrder(whichUnit, "holdposition")
        call SetUnitAnimation(whichUnit, "stand")
    else
        call PlayCityIdle(whichUnit, 6)
    endif

    set whichUnit = null
endfunction

private function MarketAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    if TryStartChat(whichUnit, 18) then
        set whichUnit = null
        return
    endif

    set action = GetRandomInt(1, 6)
    if action <= 3 then
        call PlayCityIdle(whichUnit, 2)
    elseif action == 4 then
        call PlayCityIdle(whichUnit, 4)
    elseif action == 5 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, 1)
    endif

    set whichUnit = null
endfunction

private function SocialAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    if TryStartChat(whichUnit, 28) then
        set whichUnit = null
        return
    endif

    set action = GetRandomInt(1, 6)
    if action == 1 then
        call PlayCityIdle(whichUnit, 5)
    elseif action == 2 then
        call PlayCityIdle(whichUnit, 3)
    elseif action == 3 then
        call PlayCityIdle(whichUnit, 4)
    elseif action == 4 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, 1)
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
    call AddCitizenType('N65R', 3)
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
    endif
    return spawnGroupId
endfunction

public function Refresh takes nothing returns nothing
    call AIRoutines_RefillManagedUnitGroup(SHC_StreetGroupId)
    call AIRoutines_RefillManagedUnitGroup(SHC_MarketGroupId)
    call AIRoutines_RefillManagedUnitGroup(SHC_SocialGroupId)
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
