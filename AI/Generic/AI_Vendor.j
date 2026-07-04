/**
    AI_Vendor

    Author: Valdemar
    Version:

    Description:
    Generic vendor AI profile factory for shopkeepers and service NPCs that
    should register in the AI system without autonomous combat behavior.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`.

    API:
    call AI_Vendor_RegisterProfile(unitTypeId, profileName)
    call AI_Vendor_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIVendor initializer Init requires AI

globals
    integer AI_Vendor_ClassId = 0
endglobals

private function Think takes nothing returns nothing
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName returns integer
    local integer profileId
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_Vendor_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, false)
    call AI_SetProfileThinkCallback(profileId, function Think)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    set AI_Vendor_ClassId = AI_RegisterClass("Vendor")
endfunction

endlibrary
