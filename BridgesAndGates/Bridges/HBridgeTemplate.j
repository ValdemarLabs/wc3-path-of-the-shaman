library Bridge_HBridgeTemplate initializer Init requires BridgeSystem
/*
    Bridge sublibrary template

    How to use:
        1. Copy this file.
        2. Rename the library and file to your bridge name.
        3. Replace TEMPLATE_BRIDGE with your own prefix.
        4. Replace gg_rct_* placeholders with your map rect globals.
        5. Add/remove entry blocker points as needed.
        6. Keep BridgeSystem_FinalizeSetup as the last setup call.

    Recommended setup flow:
        - one bridge rect that contains the bridge pathing/platform destructibles
        - one or more PBR rects for entry blocker spawn points
        - C/D rects for the top-of-bridge lane
        - A/B rects for the under-bridge lane

    Notes:
        - Slot order matters:
          * activate slot 1 = C, slot 2 = D
          * deactivate slot 1 = A, slot 2 = B
        - Entering C/D forces movement to the opposite top-lane rect and controls
          the bridge open/closed state.
        - A/B is only bridge-managed while top-lane C/D traffic is active.
        - If top-lane traffic starts while units are already inside the bridge rect,
          those under-lane units are pushed through with the A/B pass-through logic.
        - Top-lane units get bridge-state GUI updates and optional ghost collision.
        - Ghost collision can be configured separately for top C/D and under A/B.
        - Optional approach rects can redirect move orders into the correct
          entry rect center before the bridge pathing has opened.
        - Under-lane approach rects only matter while top-lane traffic is active.
        - Conditions are optional. Remove them if not needed.
        - Custom actions are optional. Use them if this bridge needs extra logic.
        - BridgeSystem automatically updates udg_IsUnitOnBridge[GetUnitUserData(unit)].
*/

globals
    private integer TEMPLATE_BRIDGE_Id = 0
endglobals

// Optional activate condition.
// Example:
// return GetOwningPlayer(GetTriggerUnit()) == Player(0)
private function TEMPLATE_BRIDGE_CanActivate takes nothing returns boolean
    return true
endfunction

// Optional deactivate condition.
// Example:
// return IsUnitType(GetTriggerUnit(), UNIT_TYPE_HERO)
private function TEMPLATE_BRIDGE_CanDeactivate takes nothing returns boolean
    return true
endfunction

// Optional custom activate callback.
// Runs after the bridge-top C/D activation logic.
private function TEMPLATE_BRIDGE_OnActivate takes nothing returns nothing
    // Add bridge-specific activate logic here if needed.
endfunction

// Optional custom deactivate callback.
// Runs after under-lane A/B activation logic when that flow is used.
private function TEMPLATE_BRIDGE_OnDeactivate takes nothing returns nothing
    // Add bridge-specific deactivate logic here if needed.
endfunction

// Optional public wrappers if you want to trigger this bridge manually from elsewhere.
// BridgeSystem_Activate = top-lane C/D flow, BridgeSystem_Deactivate = under-lane A/B flow.
function TEMPLATE_BRIDGE_Activate takes unit whichUnit returns nothing
    call BridgeSystem_Activate(TEMPLATE_BRIDGE_Id, whichUnit)
endfunction

function TEMPLATE_BRIDGE_Deactivate takes unit whichUnit returns nothing
    call BridgeSystem_Deactivate(TEMPLATE_BRIDGE_Id, whichUnit)
endfunction

private function Init takes nothing returns nothing
    local integer bridgeId

    // Main bridge rect: should contain the pathing/platform destructibles managed by the system.
    set bridgeId = BridgeSystem_Create("TEMPLATE_BRIDGE", gg_rct_TEMPLATE_BRIDGE)
    set TEMPLATE_BRIDGE_Id = bridgeId

    // Default bridge-related destructible ids.
    call BridgeSystem_RegisterDefaultControlledTypes(bridgeId)

    // If this bridge uses extra object ids, register them here.
    // call BridgeSystem_AddControlledType(bridgeId, 'XXXX')

    // Entry blocker spawn points. Add/remove as needed.
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_TEMPLATE_BRIDGEPBR1)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_TEMPLATE_BRIDGEPBR2)

    // Top-lane rects:
    // Slot 1 must be C and slot 2 must be D.
    // These are the rects that activate the bridge-top crossing flow.
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_TEMPLATE_BRIDGEC)
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_TEMPLATE_BRIDGED)

    // Under-lane rects:
    // Slot 1 must be A and slot 2 must be B.
    // These are only bridge-managed while top-lane C/D traffic is active.
    call BridgeSystem_AddDeactivateRect(bridgeId, gg_rct_TEMPLATE_BRIDGEA)
    call BridgeSystem_AddDeactivateRect(bridgeId, gg_rct_TEMPLATE_BRIDGEB)

    // Optional approach rects for pathing assistance.
    // Top lane: slot 1 = C area, slot 2 = D area.
    // call BridgeSystem_SetTopApproach(bridgeId, 1, gg_rct_TEMPLATE_BRIDGECarea)
    // call BridgeSystem_SetTopApproach(bridgeId, 2, gg_rct_TEMPLATE_BRIDGEDarea)
    // Under lane: slot 1 = A area, slot 2 = B area.
    // Under-lane approach redirects are only used while top-lane traffic is active.
    // call BridgeSystem_SetUnderApproach(bridgeId, 1, gg_rct_TEMPLATE_BRIDGEAarea)
    // call BridgeSystem_SetUnderApproach(bridgeId, 2, gg_rct_TEMPLATE_BRIDGEBarea)

    // Optional conditions.
    call BridgeSystem_SetActivateCondition(bridgeId, Condition(function TEMPLATE_BRIDGE_CanActivate))
    call BridgeSystem_SetDeactivateCondition(bridgeId, Condition(function TEMPLATE_BRIDGE_CanDeactivate))

    // Optional lane ghost collision overrides.
    // Defaults are true for both lanes.
    // Top-lane entry centering defaults to true and makes C/D units move to the
    // activation rect center before the forced crossing starts.
    // call BridgeSystem_SetTopLaneEntryCentering(bridgeId, false)
    // call BridgeSystem_SetTopLaneGhostCollision(bridgeId, false)
    // call BridgeSystem_SetUnderLaneGhostCollision(bridgeId, false)

    // Optional callbacks.
    call BridgeSystem_AddActivateAction(bridgeId, function TEMPLATE_BRIDGE_OnActivate)
    call BridgeSystem_AddDeactivateAction(bridgeId, function TEMPLATE_BRIDGE_OnDeactivate)

    // Must be called last.
    call BridgeSystem_FinalizeSetup(bridgeId)
endfunction

endlibrary
