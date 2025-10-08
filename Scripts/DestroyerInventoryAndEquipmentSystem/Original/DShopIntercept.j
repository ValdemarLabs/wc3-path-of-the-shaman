function Trig_DShopIntercept_Actions takes nothing returns nothing
local integer pid = GetPlayerId(GetTriggerPlayer())
local item it = GetSoldItem()
local integer g = GetItemGoldCost(it)
local texttag tt = CreateTextTag()
local unit u = GetTriggerUnit()
local integer chg = GetItemCharges(it)

set g = R2I(g * ShopResaleValueX)

if chg > 1 then
set g = g * chg
endif

if g == 0 then
else
call SetPlayerState(Player(pid), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(Player(pid), PLAYER_STATE_RESOURCE_GOLD) + g)

call SetTextTagText(tt, I2S(g), 0.023)
call SetTextTagPos(tt, GetUnitX(u)+GetRandomReal(-45,45), GetUnitY(u)+GetRandomReal(-45,45), 10.0)
call SetTextTagColor(tt, 255, 255, 0, 255)
call SetTextTagPermanent(tt, false)
call SetTextTagLifespan(tt, 3.3)
endif

set u = null
set it = null
set tt = null
endfunction

//===========================================================================
function InitTrig_DShopIntercept takes nothing returns nothing
    set gg_trg_DShopIntercept = CreateTrigger(  )
    call TriggerRegisterAnyUnitEventBJ( gg_trg_DShopIntercept, EVENT_PLAYER_UNIT_PAWN_ITEM )
    call TriggerAddAction( gg_trg_DShopIntercept, function Trig_DShopIntercept_Actions )
endfunction

