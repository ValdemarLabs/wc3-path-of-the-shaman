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
    Requires `AI.j`, `Reputation.j`, and `Voicelines_Valeria.j`.

    API:
    call AIValeria_Enable(unit whichUnit)
    call AIValeria_Disable(unit whichUnit)

**/
library AIValeria initializer Init requires AI, Reputation, VoicelinesValeria

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
    call RegisterNeutralBark(AI_BARK_GREET, VL_VALERIA_0181_TEXT, VL_VALERIA_0181_KEY)
    call RegisterNeutralBark(AI_BARK_GREET, VL_VALERIA_0182_TEXT, VL_VALERIA_0182_KEY)
    call RegisterNeutralBark(AI_BARK_GREET, VL_VALERIA_0183_TEXT, VL_VALERIA_0183_KEY)
    call RegisterFriendlyBark(AI_BARK_GREET, VL_VALERIA_0184_TEXT, VL_VALERIA_0184_KEY)
    call RegisterFriendlyBark(AI_BARK_GREET, VL_VALERIA_0185_TEXT, VL_VALERIA_0185_KEY)
    call RegisterFriendlyBark(AI_BARK_GREET, VL_VALERIA_0186_TEXT, VL_VALERIA_0186_KEY)
    call RegisterCovenantBark(AI_BARK_GREET, VL_VALERIA_0187_TEXT, VL_VALERIA_0187_KEY)
    call RegisterCovenantBark(AI_BARK_GREET, VL_VALERIA_0188_TEXT, VL_VALERIA_0188_KEY)
    call RegisterCovenantBark(AI_BARK_GREET, VL_VALERIA_0189_TEXT, VL_VALERIA_0189_KEY)
    call RegisterExaltedBark(AI_BARK_GREET, VL_VALERIA_0190_TEXT, VL_VALERIA_0190_KEY)
    call RegisterExaltedBark(AI_BARK_GREET, VL_VALERIA_0191_TEXT, VL_VALERIA_0191_KEY)
    call RegisterExaltedBark(AI_BARK_GREET, VL_VALERIA_0192_TEXT, VL_VALERIA_0192_KEY)
    call RegisterNeutralBark(AI_BARK_FAREWELL, VL_VALERIA_0193_TEXT, VL_VALERIA_0193_KEY)
    call RegisterNeutralBark(AI_BARK_FAREWELL, VL_VALERIA_0194_TEXT, VL_VALERIA_0194_KEY)
    call RegisterNeutralBark(AI_BARK_FAREWELL, VL_VALERIA_0195_TEXT, VL_VALERIA_0195_KEY)
    call RegisterFriendlyBark(AI_BARK_FAREWELL, VL_VALERIA_0196_TEXT, VL_VALERIA_0196_KEY)
    call RegisterFriendlyBark(AI_BARK_FAREWELL, VL_VALERIA_0197_TEXT, VL_VALERIA_0197_KEY)
    call RegisterFriendlyBark(AI_BARK_FAREWELL, VL_VALERIA_0198_TEXT, VL_VALERIA_0198_KEY)
    call RegisterCovenantBark(AI_BARK_FAREWELL, VL_VALERIA_0199_TEXT, VL_VALERIA_0199_KEY)
    call RegisterCovenantBark(AI_BARK_FAREWELL, VL_VALERIA_0200_TEXT, VL_VALERIA_0200_KEY)
    call RegisterCovenantBark(AI_BARK_FAREWELL, VL_VALERIA_0201_TEXT, VL_VALERIA_0201_KEY)
    call RegisterExaltedBark(AI_BARK_FAREWELL, VL_VALERIA_0202_TEXT, VL_VALERIA_0202_KEY)
    call RegisterExaltedBark(AI_BARK_FAREWELL, VL_VALERIA_0203_TEXT, VL_VALERIA_0203_KEY)
    call RegisterExaltedBark(AI_BARK_FAREWELL, VL_VALERIA_0204_TEXT, VL_VALERIA_0204_KEY)
    call RegisterNeutralBark(AI_BARK_PASSIVE, VL_VALERIA_0205_TEXT, VL_VALERIA_0205_KEY)
    call RegisterNeutralBark(AI_BARK_PASSIVE, VL_VALERIA_0206_TEXT, VL_VALERIA_0206_KEY)
    call RegisterNeutralBark(AI_BARK_PASSIVE, VL_VALERIA_0207_TEXT, VL_VALERIA_0207_KEY)
    call RegisterFriendlyBark(AI_BARK_PASSIVE, VL_VALERIA_0208_TEXT, VL_VALERIA_0208_KEY)
    call RegisterFriendlyBark(AI_BARK_PASSIVE, VL_VALERIA_0209_TEXT, VL_VALERIA_0209_KEY)
    call RegisterFriendlyBark(AI_BARK_PASSIVE, VL_VALERIA_0210_TEXT, VL_VALERIA_0210_KEY)
    call RegisterCovenantBark(AI_BARK_PASSIVE, VL_VALERIA_0211_TEXT, VL_VALERIA_0211_KEY)
    call RegisterCovenantBark(AI_BARK_PASSIVE, VL_VALERIA_0212_TEXT, VL_VALERIA_0212_KEY)
    call RegisterCovenantBark(AI_BARK_PASSIVE, VL_VALERIA_0213_TEXT, VL_VALERIA_0213_KEY)
    call RegisterExaltedBark(AI_BARK_PASSIVE, VL_VALERIA_0214_TEXT, VL_VALERIA_0214_KEY)
    call RegisterExaltedBark(AI_BARK_PASSIVE, VL_VALERIA_0215_TEXT, VL_VALERIA_0215_KEY)
    call RegisterExaltedBark(AI_BARK_PASSIVE, VL_VALERIA_0216_TEXT, VL_VALERIA_0216_KEY)
    call RegisterNeutralBark(AI_BARK_NORMAL, VL_VALERIA_0217_TEXT, VL_VALERIA_0217_KEY)
    call RegisterNeutralBark(AI_BARK_NORMAL, VL_VALERIA_0218_TEXT, VL_VALERIA_0218_KEY)
    call RegisterNeutralBark(AI_BARK_NORMAL, VL_VALERIA_0219_TEXT, VL_VALERIA_0219_KEY)
    call RegisterFriendlyBark(AI_BARK_NORMAL, VL_VALERIA_0220_TEXT, VL_VALERIA_0220_KEY)
    call RegisterFriendlyBark(AI_BARK_NORMAL, VL_VALERIA_0221_TEXT, VL_VALERIA_0221_KEY)
    call RegisterFriendlyBark(AI_BARK_NORMAL, VL_VALERIA_0222_TEXT, VL_VALERIA_0222_KEY)
    call RegisterCovenantBark(AI_BARK_NORMAL, VL_VALERIA_0223_TEXT, VL_VALERIA_0223_KEY)
    call RegisterCovenantBark(AI_BARK_NORMAL, VL_VALERIA_0224_TEXT, VL_VALERIA_0224_KEY)
    call RegisterCovenantBark(AI_BARK_NORMAL, VL_VALERIA_0225_TEXT, VL_VALERIA_0225_KEY)
    call RegisterExaltedBark(AI_BARK_NORMAL, VL_VALERIA_0226_TEXT, VL_VALERIA_0226_KEY)
    call RegisterExaltedBark(AI_BARK_NORMAL, VL_VALERIA_0227_TEXT, VL_VALERIA_0227_KEY)
    call RegisterExaltedBark(AI_BARK_NORMAL, VL_VALERIA_0228_TEXT, VL_VALERIA_0228_KEY)
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0229_TEXT, VL_VALERIA_0229_KEY)
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0230_TEXT, VL_VALERIA_0230_KEY)
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0231_TEXT, VL_VALERIA_0231_KEY)
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0232_TEXT, VL_VALERIA_0232_KEY)
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0233_TEXT, VL_VALERIA_0233_KEY)
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0234_TEXT, VL_VALERIA_0234_KEY)
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0235_TEXT, VL_VALERIA_0235_KEY)
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0236_TEXT, VL_VALERIA_0236_KEY)
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0237_TEXT, VL_VALERIA_0237_KEY)
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0238_TEXT, VL_VALERIA_0238_KEY)
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0239_TEXT, VL_VALERIA_0239_KEY)
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, VL_VALERIA_0240_TEXT, VL_VALERIA_0240_KEY)
    call RegisterNeutralBark(AI_BARK_HOLD, VL_VALERIA_0241_TEXT, VL_VALERIA_0241_KEY)
    call RegisterNeutralBark(AI_BARK_HOLD, VL_VALERIA_0242_TEXT, VL_VALERIA_0242_KEY)
    call RegisterNeutralBark(AI_BARK_HOLD, VL_VALERIA_0243_TEXT, VL_VALERIA_0243_KEY)
    call RegisterFriendlyBark(AI_BARK_HOLD, VL_VALERIA_0244_TEXT, VL_VALERIA_0244_KEY)
    call RegisterFriendlyBark(AI_BARK_HOLD, VL_VALERIA_0245_TEXT, VL_VALERIA_0245_KEY)
    call RegisterFriendlyBark(AI_BARK_HOLD, VL_VALERIA_0246_TEXT, VL_VALERIA_0246_KEY)
    call RegisterCovenantBark(AI_BARK_HOLD, VL_VALERIA_0247_TEXT, VL_VALERIA_0247_KEY)
    call RegisterCovenantBark(AI_BARK_HOLD, VL_VALERIA_0248_TEXT, VL_VALERIA_0248_KEY)
    call RegisterCovenantBark(AI_BARK_HOLD, VL_VALERIA_0249_TEXT, VL_VALERIA_0249_KEY)
    call RegisterExaltedBark(AI_BARK_HOLD, VL_VALERIA_0250_TEXT, VL_VALERIA_0250_KEY)
    call RegisterExaltedBark(AI_BARK_HOLD, VL_VALERIA_0251_TEXT, VL_VALERIA_0251_KEY)
    call RegisterExaltedBark(AI_BARK_HOLD, VL_VALERIA_0252_TEXT, VL_VALERIA_0252_KEY)
    call RegisterNeutralBark(AI_BARK_KICKED, VL_VALERIA_0253_TEXT, VL_VALERIA_0253_KEY)
    call RegisterNeutralBark(AI_BARK_KICKED, VL_VALERIA_0254_TEXT, VL_VALERIA_0254_KEY)
    call RegisterNeutralBark(AI_BARK_KICKED, VL_VALERIA_0255_TEXT, VL_VALERIA_0255_KEY)
    call RegisterFriendlyBark(AI_BARK_KICKED, VL_VALERIA_0256_TEXT, VL_VALERIA_0256_KEY)
    call RegisterFriendlyBark(AI_BARK_KICKED, VL_VALERIA_0257_TEXT, VL_VALERIA_0257_KEY)
    call RegisterFriendlyBark(AI_BARK_KICKED, VL_VALERIA_0258_TEXT, VL_VALERIA_0258_KEY)
    call RegisterCovenantBark(AI_BARK_KICKED, VL_VALERIA_0259_TEXT, VL_VALERIA_0259_KEY)
    call RegisterCovenantBark(AI_BARK_KICKED, VL_VALERIA_0260_TEXT, VL_VALERIA_0260_KEY)
    call RegisterCovenantBark(AI_BARK_KICKED, VL_VALERIA_0261_TEXT, VL_VALERIA_0261_KEY)
    call RegisterExaltedBark(AI_BARK_KICKED, VL_VALERIA_0262_TEXT, VL_VALERIA_0262_KEY)
    call RegisterExaltedBark(AI_BARK_KICKED, VL_VALERIA_0263_TEXT, VL_VALERIA_0263_KEY)
    call RegisterExaltedBark(AI_BARK_KICKED, VL_VALERIA_0264_TEXT, VL_VALERIA_0264_KEY)
    call RegisterNeutralBark(AI_BARK_IDLE, VL_VALERIA_0265_TEXT, VL_VALERIA_0265_KEY)
    call RegisterNeutralBark(AI_BARK_IDLE, VL_VALERIA_0266_TEXT, VL_VALERIA_0266_KEY)
    call RegisterNeutralBark(AI_BARK_IDLE, VL_VALERIA_0267_TEXT, VL_VALERIA_0267_KEY)
    call RegisterFriendlyBark(AI_BARK_IDLE, VL_VALERIA_0268_TEXT, VL_VALERIA_0268_KEY)
    call RegisterFriendlyBark(AI_BARK_IDLE, VL_VALERIA_0269_TEXT, VL_VALERIA_0269_KEY)
    call RegisterFriendlyBark(AI_BARK_IDLE, VL_VALERIA_0270_TEXT, VL_VALERIA_0270_KEY)
    call RegisterCovenantBark(AI_BARK_IDLE, VL_VALERIA_0271_TEXT, VL_VALERIA_0271_KEY)
    call RegisterCovenantBark(AI_BARK_IDLE, VL_VALERIA_0272_TEXT, VL_VALERIA_0272_KEY)
    call RegisterCovenantBark(AI_BARK_IDLE, VL_VALERIA_0273_TEXT, VL_VALERIA_0273_KEY)
    call RegisterExaltedBark(AI_BARK_IDLE, VL_VALERIA_0274_TEXT, VL_VALERIA_0274_KEY)
    call RegisterExaltedBark(AI_BARK_IDLE, VL_VALERIA_0275_TEXT, VL_VALERIA_0275_KEY)
    call RegisterExaltedBark(AI_BARK_IDLE, VL_VALERIA_0276_TEXT, VL_VALERIA_0276_KEY)
    call RegisterNeutralBark(AI_BARK_MOVING, VL_VALERIA_0277_TEXT, VL_VALERIA_0277_KEY)
    call RegisterNeutralBark(AI_BARK_MOVING, VL_VALERIA_0278_TEXT, VL_VALERIA_0278_KEY)
    call RegisterNeutralBark(AI_BARK_MOVING, VL_VALERIA_0279_TEXT, VL_VALERIA_0279_KEY)
    call RegisterFriendlyBark(AI_BARK_MOVING, VL_VALERIA_0280_TEXT, VL_VALERIA_0280_KEY)
    call RegisterFriendlyBark(AI_BARK_MOVING, VL_VALERIA_0281_TEXT, VL_VALERIA_0281_KEY)
    call RegisterFriendlyBark(AI_BARK_MOVING, VL_VALERIA_0282_TEXT, VL_VALERIA_0282_KEY)
    call RegisterCovenantBark(AI_BARK_MOVING, VL_VALERIA_0283_TEXT, VL_VALERIA_0283_KEY)
    call RegisterCovenantBark(AI_BARK_MOVING, VL_VALERIA_0284_TEXT, VL_VALERIA_0284_KEY)
    call RegisterCovenantBark(AI_BARK_MOVING, VL_VALERIA_0285_TEXT, VL_VALERIA_0285_KEY)
    call RegisterExaltedBark(AI_BARK_MOVING, VL_VALERIA_0286_TEXT, VL_VALERIA_0286_KEY)
    call RegisterExaltedBark(AI_BARK_MOVING, VL_VALERIA_0287_TEXT, VL_VALERIA_0287_KEY)
    call RegisterExaltedBark(AI_BARK_MOVING, VL_VALERIA_0288_TEXT, VL_VALERIA_0288_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_VALERIA_0289_TEXT, VL_VALERIA_0289_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_VALERIA_0290_TEXT, VL_VALERIA_0290_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_VALERIA_0291_TEXT, VL_VALERIA_0291_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_VALERIA_0292_TEXT, VL_VALERIA_0292_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_VALERIA_0293_TEXT, VL_VALERIA_0293_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_VALERIA_0294_TEXT, VL_VALERIA_0294_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_VALERIA_0295_TEXT, VL_VALERIA_0295_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_VALERIA_0296_TEXT, VL_VALERIA_0296_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_VALERIA_0297_TEXT, VL_VALERIA_0297_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_VALERIA_0298_TEXT, VL_VALERIA_0298_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_VALERIA_0299_TEXT, VL_VALERIA_0299_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_VALERIA_0300_TEXT, VL_VALERIA_0300_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_VALERIA_0301_TEXT, VL_VALERIA_0301_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_VALERIA_0302_TEXT, VL_VALERIA_0302_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_VALERIA_0303_TEXT, VL_VALERIA_0303_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_VALERIA_0304_TEXT, VL_VALERIA_0304_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_VALERIA_0305_TEXT, VL_VALERIA_0305_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_VALERIA_0306_TEXT, VL_VALERIA_0306_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_VALERIA_0307_TEXT, VL_VALERIA_0307_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_VALERIA_0308_TEXT, VL_VALERIA_0308_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_VALERIA_0309_TEXT, VL_VALERIA_0309_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_VALERIA_0310_TEXT, VL_VALERIA_0310_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_VALERIA_0311_TEXT, VL_VALERIA_0311_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_VALERIA_0312_TEXT, VL_VALERIA_0312_KEY)
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
