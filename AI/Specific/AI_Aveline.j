/**
    AI_Aveline

    Author: Valdemar
    Version:

    Description:
    Unique Riverbane Warrior profile for Aveline. This profile reuses the
    shared Warrior ability setup while keeping Aveline's identity, owner,
    caps, barks, random spawning, and legacy `udg_Aveline` mapping separate
    from Horde Warrior instances.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j` and `AI_Warrior.j`. The generated map globals must include
    `udg_Aveline`.

    API:
    call AIAveline_Register(unit whichUnit)
    call AIAveline_SpawnAt(x, y, facing)

**/
library AIAveline initializer Init requires AI, AIWarrior

globals
    constant integer AI_AVELINE_UNIT_RIVERBANE = 'O009'
    constant integer AI_AVELINE_UNIQUE_ID = 'AVLN'
    integer AI_Aveline_ProfileId = 0
endglobals

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_GREET, "Aveline of Riverbane. Keep your blade ready.", "Aveline_Greet1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_GREET, "If you stand against raiders, you stand with me.", "Aveline_Greet2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_FAREWELL, "Riverbane roads are never quiet for long.", "Aveline_Farewell1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_PASSIVE, "I will watch the road and spare my strength.", "Aveline_Passive1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_NORMAL, "Steady pace. Eyes open.", "Aveline_Normal1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_AGGRESSIVE, "No mercy for bandits and raiders!", "Aveline_Aggressive1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_HOLD, "I will hold this line.", "Aveline_HoldPositions1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_DROP_ITEMS, "Take what you need.", "Aveline_DropItems1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Riverbane still has people worth defending.", "Aveline_Idle1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "I am checking the road ahead.", "Aveline_Moving1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Now!", "Aveline_Casting1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "Face me!", "Aveline_Attack1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "One less threat to Riverbane.", "Aveline_UnitDies1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "Then I return to my own patrol.", "Aveline_Kicked1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "Hold the line. We still have work to do.", "Aveline_CompanionDies1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "Useful. I will put it to work.", "Aveline_GiveItem1")
endfunction

private function OnRegister takes nothing returns nothing
    set udg_Aveline = AI_EventUnit
endfunction

public function Register takes unit whichUnit returns integer
    local integer instanceId = AI_RegisterUnit(whichUnit, AI_Aveline_ProfileId, AI_AVELINE_UNIQUE_ID)
    if instanceId > 0 then
        set udg_Aveline = whichUnit
    endif
    return instanceId
endfunction

public function SpawnAt takes real x, real y, real facing returns unit
    return AI_SpawnProfile(AI_Aveline_ProfileId, Player(14), x, y, facing, AI_AVELINE_UNIQUE_ID)
endfunction

private function Init takes nothing returns nothing
    set AI_Aveline_ProfileId = AI_RegisterProfile(AI_Warrior_ClassId, AI_AVELINE_UNIT_RIVERBANE, "Aveline")
    call AIWarrior_ConfigureProfile(AI_Aveline_ProfileId)
    call AI_SetProfileSpawnOwner(AI_Aveline_ProfileId, Player(14))
    call AI_SetProfileCap(AI_Aveline_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_AVELINE_UNIT_RIVERBANE, 1)
    call AI_SetProfileRandomUniqueId(AI_Aveline_ProfileId, AI_AVELINE_UNIQUE_ID)
    call AI_SetUnitTypeDefaultProfile(AI_AVELINE_UNIT_RIVERBANE, AI_Aveline_ProfileId)
    call AI_SetProfileRegisterCallback(AI_Aveline_ProfileId, function OnRegister)
    call AI_AddRandomSpawnProfile(AI_Aveline_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
