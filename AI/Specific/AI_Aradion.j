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
    Requires `AI.j`, `Reputation.j`, and `Voicelines_Aradion.j`.

    API:
    call AIAradion_Enable(unit whichUnit)
    call AIAradion_Disable(unit whichUnit)
    call AIAradion_SetCombatOrders(boolean enabled)

**/
library AIAradion initializer Init requires AI, Reputation, VoicelinesAradion

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
    call RegisterNeutralBark(AI_BARK_GREET, VL_ARADION_0181_TEXT, VL_ARADION_0181_KEY)
    call RegisterNeutralBark(AI_BARK_GREET, VL_ARADION_0182_TEXT, VL_ARADION_0182_KEY)
    call RegisterNeutralBark(AI_BARK_GREET, VL_ARADION_0183_TEXT, VL_ARADION_0183_KEY)
    call RegisterFriendlyBark(AI_BARK_GREET, VL_ARADION_0184_TEXT, VL_ARADION_0184_KEY)
    call RegisterFriendlyBark(AI_BARK_GREET, VL_ARADION_0185_TEXT, VL_ARADION_0185_KEY)
    call RegisterFriendlyBark(AI_BARK_GREET, VL_ARADION_0186_TEXT, VL_ARADION_0186_KEY)
    call RegisterCovenantBark(AI_BARK_GREET, VL_ARADION_0187_TEXT, VL_ARADION_0187_KEY)
    call RegisterCovenantBark(AI_BARK_GREET, VL_ARADION_0188_TEXT, VL_ARADION_0188_KEY)
    call RegisterCovenantBark(AI_BARK_GREET, VL_ARADION_0189_TEXT, VL_ARADION_0189_KEY)
    call RegisterExaltedBark(AI_BARK_GREET, VL_ARADION_0190_TEXT, VL_ARADION_0190_KEY)
    call RegisterExaltedBark(AI_BARK_GREET, VL_ARADION_0191_TEXT, VL_ARADION_0191_KEY)
    call RegisterExaltedBark(AI_BARK_GREET, VL_ARADION_0192_TEXT, VL_ARADION_0192_KEY)
    call RegisterNeutralBark(AI_BARK_FAREWELL, VL_ARADION_0193_TEXT, VL_ARADION_0193_KEY)
    call RegisterNeutralBark(AI_BARK_FAREWELL, VL_ARADION_0194_TEXT, VL_ARADION_0194_KEY)
    call RegisterNeutralBark(AI_BARK_FAREWELL, VL_ARADION_0195_TEXT, VL_ARADION_0195_KEY)
    call RegisterFriendlyBark(AI_BARK_FAREWELL, VL_ARADION_0196_TEXT, VL_ARADION_0196_KEY)
    call RegisterFriendlyBark(AI_BARK_FAREWELL, VL_ARADION_0197_TEXT, VL_ARADION_0197_KEY)
    call RegisterFriendlyBark(AI_BARK_FAREWELL, VL_ARADION_0198_TEXT, VL_ARADION_0198_KEY)
    call RegisterCovenantBark(AI_BARK_FAREWELL, VL_ARADION_0199_TEXT, VL_ARADION_0199_KEY)
    call RegisterCovenantBark(AI_BARK_FAREWELL, VL_ARADION_0200_TEXT, VL_ARADION_0200_KEY)
    call RegisterCovenantBark(AI_BARK_FAREWELL, VL_ARADION_0201_TEXT, VL_ARADION_0201_KEY)
    call RegisterExaltedBark(AI_BARK_FAREWELL, VL_ARADION_0202_TEXT, VL_ARADION_0202_KEY)
    call RegisterExaltedBark(AI_BARK_FAREWELL, VL_ARADION_0203_TEXT, VL_ARADION_0203_KEY)
    call RegisterExaltedBark(AI_BARK_FAREWELL, VL_ARADION_0204_TEXT, VL_ARADION_0204_KEY)
    call RegisterNeutralBark(AI_BARK_PASSIVE, VL_ARADION_0205_TEXT, VL_ARADION_0205_KEY)
    call RegisterNeutralBark(AI_BARK_PASSIVE, VL_ARADION_0206_TEXT, VL_ARADION_0206_KEY)
    call RegisterNeutralBark(AI_BARK_PASSIVE, VL_ARADION_0207_TEXT, VL_ARADION_0207_KEY)
    call RegisterFriendlyBark(AI_BARK_PASSIVE, VL_ARADION_0208_TEXT, VL_ARADION_0208_KEY)
    call RegisterFriendlyBark(AI_BARK_PASSIVE, VL_ARADION_0209_TEXT, VL_ARADION_0209_KEY)
    call RegisterFriendlyBark(AI_BARK_PASSIVE, VL_ARADION_0210_TEXT, VL_ARADION_0210_KEY)
    call RegisterCovenantBark(AI_BARK_PASSIVE, VL_ARADION_0211_TEXT, VL_ARADION_0211_KEY)
    call RegisterCovenantBark(AI_BARK_PASSIVE, VL_ARADION_0212_TEXT, VL_ARADION_0212_KEY)
    call RegisterCovenantBark(AI_BARK_PASSIVE, VL_ARADION_0213_TEXT, VL_ARADION_0213_KEY)
    call RegisterExaltedBark(AI_BARK_PASSIVE, VL_ARADION_0214_TEXT, VL_ARADION_0214_KEY)
    call RegisterExaltedBark(AI_BARK_PASSIVE, VL_ARADION_0215_TEXT, VL_ARADION_0215_KEY)
    call RegisterExaltedBark(AI_BARK_PASSIVE, VL_ARADION_0216_TEXT, VL_ARADION_0216_KEY)
    call RegisterNeutralBark(AI_BARK_NORMAL, VL_ARADION_0217_TEXT, VL_ARADION_0217_KEY)
    call RegisterNeutralBark(AI_BARK_NORMAL, VL_ARADION_0218_TEXT, VL_ARADION_0218_KEY)
    call RegisterNeutralBark(AI_BARK_NORMAL, VL_ARADION_0219_TEXT, VL_ARADION_0219_KEY)
    call RegisterFriendlyBark(AI_BARK_NORMAL, VL_ARADION_0220_TEXT, VL_ARADION_0220_KEY)
    call RegisterFriendlyBark(AI_BARK_NORMAL, VL_ARADION_0221_TEXT, VL_ARADION_0221_KEY)
    call RegisterFriendlyBark(AI_BARK_NORMAL, VL_ARADION_0222_TEXT, VL_ARADION_0222_KEY)
    call RegisterCovenantBark(AI_BARK_NORMAL, VL_ARADION_0223_TEXT, VL_ARADION_0223_KEY)
    call RegisterCovenantBark(AI_BARK_NORMAL, VL_ARADION_0224_TEXT, VL_ARADION_0224_KEY)
    call RegisterCovenantBark(AI_BARK_NORMAL, VL_ARADION_0225_TEXT, VL_ARADION_0225_KEY)
    call RegisterExaltedBark(AI_BARK_NORMAL, VL_ARADION_0226_TEXT, VL_ARADION_0226_KEY)
    call RegisterExaltedBark(AI_BARK_NORMAL, VL_ARADION_0227_TEXT, VL_ARADION_0227_KEY)
    call RegisterExaltedBark(AI_BARK_NORMAL, VL_ARADION_0228_TEXT, VL_ARADION_0228_KEY)
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, VL_ARADION_0229_TEXT, VL_ARADION_0229_KEY)
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, VL_ARADION_0230_TEXT, VL_ARADION_0230_KEY)
    call RegisterNeutralBark(AI_BARK_AGGRESSIVE, VL_ARADION_0231_TEXT, VL_ARADION_0231_KEY)
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, VL_ARADION_0232_TEXT, VL_ARADION_0232_KEY)
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, VL_ARADION_0233_TEXT, VL_ARADION_0233_KEY)
    call RegisterFriendlyBark(AI_BARK_AGGRESSIVE, VL_ARADION_0234_TEXT, VL_ARADION_0234_KEY)
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, VL_ARADION_0235_TEXT, VL_ARADION_0235_KEY)
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, VL_ARADION_0236_TEXT, VL_ARADION_0236_KEY)
    call RegisterCovenantBark(AI_BARK_AGGRESSIVE, VL_ARADION_0237_TEXT, VL_ARADION_0237_KEY)
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, VL_ARADION_0238_TEXT, VL_ARADION_0238_KEY)
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, VL_ARADION_0239_TEXT, VL_ARADION_0239_KEY)
    call RegisterExaltedBark(AI_BARK_AGGRESSIVE, VL_ARADION_0240_TEXT, VL_ARADION_0240_KEY)
    call RegisterNeutralBark(AI_BARK_HOLD, VL_ARADION_0241_TEXT, VL_ARADION_0241_KEY)
    call RegisterNeutralBark(AI_BARK_HOLD, VL_ARADION_0242_TEXT, VL_ARADION_0242_KEY)
    call RegisterNeutralBark(AI_BARK_HOLD, VL_ARADION_0243_TEXT, VL_ARADION_0243_KEY)
    call RegisterFriendlyBark(AI_BARK_HOLD, VL_ARADION_0244_TEXT, VL_ARADION_0244_KEY)
    call RegisterFriendlyBark(AI_BARK_HOLD, VL_ARADION_0245_TEXT, VL_ARADION_0245_KEY)
    call RegisterFriendlyBark(AI_BARK_HOLD, VL_ARADION_0246_TEXT, VL_ARADION_0246_KEY)
    call RegisterCovenantBark(AI_BARK_HOLD, VL_ARADION_0247_TEXT, VL_ARADION_0247_KEY)
    call RegisterCovenantBark(AI_BARK_HOLD, VL_ARADION_0248_TEXT, VL_ARADION_0248_KEY)
    call RegisterCovenantBark(AI_BARK_HOLD, VL_ARADION_0249_TEXT, VL_ARADION_0249_KEY)
    call RegisterExaltedBark(AI_BARK_HOLD, VL_ARADION_0250_TEXT, VL_ARADION_0250_KEY)
    call RegisterExaltedBark(AI_BARK_HOLD, VL_ARADION_0251_TEXT, VL_ARADION_0251_KEY)
    call RegisterExaltedBark(AI_BARK_HOLD, VL_ARADION_0252_TEXT, VL_ARADION_0252_KEY)
    call RegisterNeutralBark(AI_BARK_KICKED, VL_ARADION_0253_TEXT, VL_ARADION_0253_KEY)
    call RegisterNeutralBark(AI_BARK_KICKED, VL_ARADION_0254_TEXT, VL_ARADION_0254_KEY)
    call RegisterNeutralBark(AI_BARK_KICKED, VL_ARADION_0255_TEXT, VL_ARADION_0255_KEY)
    call RegisterFriendlyBark(AI_BARK_KICKED, VL_ARADION_0256_TEXT, VL_ARADION_0256_KEY)
    call RegisterFriendlyBark(AI_BARK_KICKED, VL_ARADION_0257_TEXT, VL_ARADION_0257_KEY)
    call RegisterFriendlyBark(AI_BARK_KICKED, VL_ARADION_0258_TEXT, VL_ARADION_0258_KEY)
    call RegisterCovenantBark(AI_BARK_KICKED, VL_ARADION_0259_TEXT, VL_ARADION_0259_KEY)
    call RegisterCovenantBark(AI_BARK_KICKED, VL_ARADION_0260_TEXT, VL_ARADION_0260_KEY)
    call RegisterCovenantBark(AI_BARK_KICKED, VL_ARADION_0261_TEXT, VL_ARADION_0261_KEY)
    call RegisterExaltedBark(AI_BARK_KICKED, VL_ARADION_0262_TEXT, VL_ARADION_0262_KEY)
    call RegisterExaltedBark(AI_BARK_KICKED, VL_ARADION_0263_TEXT, VL_ARADION_0263_KEY)
    call RegisterExaltedBark(AI_BARK_KICKED, VL_ARADION_0264_TEXT, VL_ARADION_0264_KEY)
    call RegisterNeutralBark(AI_BARK_IDLE, VL_ARADION_0265_TEXT, VL_ARADION_0265_KEY)
    call RegisterNeutralBark(AI_BARK_IDLE, VL_ARADION_0266_TEXT, VL_ARADION_0266_KEY)
    call RegisterNeutralBark(AI_BARK_IDLE, VL_ARADION_0267_TEXT, VL_ARADION_0267_KEY)
    call RegisterFriendlyBark(AI_BARK_IDLE, VL_ARADION_0268_TEXT, VL_ARADION_0268_KEY)
    call RegisterFriendlyBark(AI_BARK_IDLE, VL_ARADION_0269_TEXT, VL_ARADION_0269_KEY)
    call RegisterFriendlyBark(AI_BARK_IDLE, VL_ARADION_0270_TEXT, VL_ARADION_0270_KEY)
    call RegisterCovenantBark(AI_BARK_IDLE, VL_ARADION_0271_TEXT, VL_ARADION_0271_KEY)
    call RegisterCovenantBark(AI_BARK_IDLE, VL_ARADION_0272_TEXT, VL_ARADION_0272_KEY)
    call RegisterCovenantBark(AI_BARK_IDLE, VL_ARADION_0273_TEXT, VL_ARADION_0273_KEY)
    call RegisterExaltedBark(AI_BARK_IDLE, VL_ARADION_0274_TEXT, VL_ARADION_0274_KEY)
    call RegisterExaltedBark(AI_BARK_IDLE, VL_ARADION_0275_TEXT, VL_ARADION_0275_KEY)
    call RegisterExaltedBark(AI_BARK_IDLE, VL_ARADION_0276_TEXT, VL_ARADION_0276_KEY)
    call RegisterNeutralBark(AI_BARK_MOVING, VL_ARADION_0277_TEXT, VL_ARADION_0277_KEY)
    call RegisterNeutralBark(AI_BARK_MOVING, VL_ARADION_0278_TEXT, VL_ARADION_0278_KEY)
    call RegisterNeutralBark(AI_BARK_MOVING, VL_ARADION_0279_TEXT, VL_ARADION_0279_KEY)
    call RegisterFriendlyBark(AI_BARK_MOVING, VL_ARADION_0280_TEXT, VL_ARADION_0280_KEY)
    call RegisterFriendlyBark(AI_BARK_MOVING, VL_ARADION_0281_TEXT, VL_ARADION_0281_KEY)
    call RegisterFriendlyBark(AI_BARK_MOVING, VL_ARADION_0282_TEXT, VL_ARADION_0282_KEY)
    call RegisterCovenantBark(AI_BARK_MOVING, VL_ARADION_0283_TEXT, VL_ARADION_0283_KEY)
    call RegisterCovenantBark(AI_BARK_MOVING, VL_ARADION_0284_TEXT, VL_ARADION_0284_KEY)
    call RegisterCovenantBark(AI_BARK_MOVING, VL_ARADION_0285_TEXT, VL_ARADION_0285_KEY)
    call RegisterExaltedBark(AI_BARK_MOVING, VL_ARADION_0286_TEXT, VL_ARADION_0286_KEY)
    call RegisterExaltedBark(AI_BARK_MOVING, VL_ARADION_0287_TEXT, VL_ARADION_0287_KEY)
    call RegisterExaltedBark(AI_BARK_MOVING, VL_ARADION_0288_TEXT, VL_ARADION_0288_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_ARADION_0289_TEXT, VL_ARADION_0289_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_ARADION_0290_TEXT, VL_ARADION_0290_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_ARADION_0291_TEXT, VL_ARADION_0291_KEY)
    call RegisterCommonBark(AI_BARK_DROP_ITEMS, VL_ARADION_0292_TEXT, VL_ARADION_0292_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_ARADION_0293_TEXT, VL_ARADION_0293_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_ARADION_0294_TEXT, VL_ARADION_0294_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_ARADION_0295_TEXT, VL_ARADION_0295_KEY)
    call RegisterCommonBark(AI_BARK_ITEM_GIVEN, VL_ARADION_0296_TEXT, VL_ARADION_0296_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_ARADION_0297_TEXT, VL_ARADION_0297_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_ARADION_0298_TEXT, VL_ARADION_0298_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_ARADION_0299_TEXT, VL_ARADION_0299_KEY)
    call RegisterCommonBark(AI_BARK_ATTACKING, VL_ARADION_0300_TEXT, VL_ARADION_0300_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_ARADION_0301_TEXT, VL_ARADION_0301_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_ARADION_0302_TEXT, VL_ARADION_0302_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_ARADION_0303_TEXT, VL_ARADION_0303_KEY)
    call RegisterCommonBark(AI_BARK_CASTING, VL_ARADION_0304_TEXT, VL_ARADION_0304_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_ARADION_0305_TEXT, VL_ARADION_0305_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_ARADION_0306_TEXT, VL_ARADION_0306_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_ARADION_0307_TEXT, VL_ARADION_0307_KEY)
    call RegisterCommonBark(AI_BARK_KILLING, VL_ARADION_0308_TEXT, VL_ARADION_0308_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_ARADION_0309_TEXT, VL_ARADION_0309_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_ARADION_0310_TEXT, VL_ARADION_0310_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_ARADION_0311_TEXT, VL_ARADION_0311_KEY)
    call RegisterCommonBark(AI_BARK_COMPANION_DIES, VL_ARADION_0312_TEXT, VL_ARADION_0312_KEY)
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
