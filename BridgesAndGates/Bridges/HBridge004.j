library HBridge004 initializer Init requires BridgeSystem

globals
    private integer HBridge004_Id = 0
endglobals

function HBridge004_Activate takes unit whichUnit returns nothing
    call BridgeSystem_Activate(HBridge004_Id, whichUnit)
endfunction

private function Init takes nothing returns nothing
    local integer bridgeId = BridgeSystem_Create("HBridge004", gg_rct_HBridge004)

    set HBridge004_Id = bridgeId

    call BridgeSystem_RegisterDefaultControlledTypes(bridgeId)
    call BridgeSystem_SetTopLanePersistentOpen(bridgeId, true)

    // C/D are the only bridge-managed entry rects for this variant.
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_HBridge004C)
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_HBridge004D)

    // Optional top-lane approach redirect rects.
    call BridgeSystem_SetTopApproach(bridgeId, 1, gg_rct_HBridge004Carea)
    call BridgeSystem_SetTopApproach(bridgeId, 2, gg_rct_HBridge004Darea)

    // Optional lane ghost collision overrides.
    // Defaults are true for both lanes.
    //call BridgeSystem_SetTopLaneGhostCollision(bridgeId, false)

    call BridgeSystem_FinalizeSetup(bridgeId)
endfunction

endlibrary
