/**
    AI_Rogue

    Author: Valdemar
    Version:

    Description:
    Rogue AI profile registration. Detailed Rogue ability rotation will be
    layered into this library after the master AI registry is verified.

    Credits:
    - Old GUI HeroRogue triggers

    How to install:
    Requires `AI.j`.

    API:
    call AIRogue_Register(unit whichUnit)

**/
library AIRogue initializer Init requires AI

globals
    constant integer AI_ROGUE_UNIT_HORDE = 'O631'
    constant integer AI_ROGUE_ABILITY_EVASION = 'A6FI'
    constant integer AI_ROGUE_ABILITY_GARROTE = 'A6FF'
    constant integer AI_ROGUE_ABILITY_SHADOWSTEP = 'A6FG'
    constant integer AI_ROGUE_ABILITY_SINISTER_STRIKE = 'A6FE'
    constant integer AI_ROGUE_ABILITY_SLICE_AND_DICE = 'A6E8'
    constant integer AI_ROGUE_ABILITY_SURPRISE_ATTACK = 'A6FJ'
    constant integer AI_ROGUE_ABILITY_TOXIC_VENOM = 'A6FD'
    integer AI_Rogue_ClassId = 0
    integer AI_Rogue_ProfileId = 0
endglobals

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, "What do ya need?", "HeroRogue_Greet1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, "I'm all ears.", "HeroRogue_Greet2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, "Heh, found any good trouble yet?", "HeroRogue_Greet3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_GREET, "Let's get this over with.", "HeroRogue_Greet4")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, "Catch ya later, chief.", "HeroRogue_Farewell1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, "Stay outta trouble... or don't.", "HeroRogue_Farewell2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, "Off to skulk elsewhere.", "HeroRogue_Farewell3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_FAREWELL, "Keep your eyes sharp.", "HeroRogue_Farewell4")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_PASSIVE, "Following your lead, boss.", "HeroRogue_Passive1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_PASSIVE, "I'll keep close, no worries.", "HeroRogue_Passive2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_NORMAL, "Ready for anything.", "HeroRogue_Normal1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_NORMAL, "Let's get to work.", "HeroRogue_Normal2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_AGGRESSIVE, "Time to cause some chaos!", "HeroRogue_Aggressive1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_AGGRESSIVE, "Heh, blood and gold-my favorites.", "HeroRogue_Aggressive2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_AGGRESSIVE, "No mercy, eh? Fine by me!", "HeroRogue_Aggressive3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_HOLD, "Fine, I'll sit tight.", "HeroRogue_HoldPositions1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_HOLD, "You sure this is a good spot?", "HeroRogue_HoldPositions2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_DROP_ITEMS, "Not like I needed those anyway.", "HeroRogue_DropItems1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_DROP_ITEMS, "Guess it's your turn to carry.", "HeroRogue_DropItems2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_DROP_ITEMS, "Here, don't lose them.", "HeroRogue_DropItems3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_IDLE, "If you don't move, I might find something shiny.", "HeroRogue_Idle1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_IDLE, "You planning or sleeping?", "HeroRogue_Idle2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_MOVING, "Hope you know where we're goin'.", "HeroRogue_Moving1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_MOVING, "I swear, if we hit another dead end...", "HeroRogue_Moving2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_MOVING, "Nice weather here... not.", "HeroRogue_Moving3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_CASTING, "Let's see how they handle this trick.", "HeroRogue_Casting1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_CASTING, "I'll make this quick-real quick.", "HeroRogue_Casting2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_CASTING, "They won't feel a thing.", "HeroRogue_Casting3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ATTACKING, "You picked the wrong fight!", "HeroRogue_Attacking1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ATTACKING, "Heh, you're already dead.", "HeroRogue_Attacking2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ATTACKING, "For the Horde-and my pockets!", "HeroRogue_Attacking3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KILLING, "One less fool to worry about.", "HeroRogue_Killing1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KILLING, "They weren't worth the effort.", "HeroRogue_Killing2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KILLING, "Dead and gone.", "HeroRogue_Killing3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KICKED, "You don't need me? Fine!", "HeroRogue_Kicked1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KICKED, "Was I too good for ya?", "HeroRogue_Kicked2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_KICKED, "Your loss, chief.", "HeroRogue_Kicked3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_COMPANION_DIES, "Another one bites the dust.", "HeroRogue_UnitDies1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_COMPANION_DIES, "We'll mourn later-fight now!", "HeroRogue_UnitDies2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_COMPANION_DIES, "Didn't see that coming.", "HeroRogue_UnitDies3")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ITEM_GIVEN, "Oh, shiny! I like it.", "HeroRogue_Item1")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ITEM_GIVEN, "What's this for?", "HeroRogue_Item2")
    call AI_RegisterBarkLine(AI_Rogue_ProfileId, AI_BARK_ITEM_GIVEN, "Guess I'll hold onto it.", "HeroRogue_Item3")
endfunction

private function RegisterAbilities takes nothing returns nothing
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_EVASION)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_GARROTE)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SINISTER_STRIKE)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SLICE_AND_DICE)
    call AI_AddProfileStartingAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_TOXIC_VENOM)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_EVASION)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_GARROTE)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SHADOWSTEP)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SINISTER_STRIKE)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SLICE_AND_DICE)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_SURPRISE_ATTACK)
    call AI_AddProfileAbility(AI_Rogue_ProfileId, AI_ROGUE_ABILITY_TOXIC_VENOM)
endfunction

private function Think takes nothing returns nothing
    local unit rogue = AI_EventUnit
    local unit target = AI_EventTarget
    local integer enemyCount
    local integer roll
    local real lifePercent
    local real targetLife
    if rogue == null or target == null then
        set rogue = null
        set target = null
        return
    endif
    set enemyCount = AI_CountNearbyEnemies(rogue, 600.00)
    set roll = GetRandomInt(1, 100)
    set lifePercent = AI_GetUnitLifePercent(rogue)
    set targetLife = AI_GetUnitLifePercent(target)
    if enemyCount <= 0 then
        call IssueTargetOrder(rogue, "attack", target)
    elseif (lifePercent <= 45.00 or enemyCount >= 3) and roll <= 45 and AI_TryCastImmediate(rogue, AI_ROGUE_ABILITY_EVASION, "roar", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif roll <= 25 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_GARROTE, "parasite", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif enemyCount >= 2 and roll <= 42 and AI_TemporaryAbilitySwap(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE, AI_ROGUE_ABILITY_SHADOWSTEP, GetUnitAbilityLevel(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE), 3.00) and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_SHADOWSTEP, "stormbolt", 4.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif targetLife <= 40.00 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_SINISTER_STRIKE, "stormbolt", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif roll <= 58 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_SINISTER_STRIKE, "stormbolt", 2.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif roll <= 70 and AI_TryCastImmediate(rogue, AI_ROGUE_ABILITY_SLICE_AND_DICE, "roar", 5.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    elseif enemyCount <= 2 and lifePercent >= 45.00 and roll <= 80 and AI_TemporaryAbilitySwap(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE, AI_ROGUE_ABILITY_SURPRISE_ATTACK, GetUnitAbilityLevel(rogue, AI_ROGUE_ABILITY_SINISTER_STRIKE), 5.00) and AI_TryCastImmediate(rogue, AI_ROGUE_ABILITY_SURPRISE_ATTACK, "windwalk", 6.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
        call IssueTargetOrder(rogue, "attack", target)
    elseif enemyCount >= 2 and roll <= 92 and AI_TryCastTarget(rogue, target, AI_ROGUE_ABILITY_TOXIC_VENOM, "acidbomb", 5.00) then
        call AI_RequestBark(rogue, AI_BARK_CASTING)
    else
        call IssueTargetOrder(rogue, "attack", target)
    endif
    set rogue = null
    set target = null
endfunction

public function Register takes unit whichUnit returns integer
    return AI_RegisterUnit(whichUnit, AI_Rogue_ProfileId, 0)
endfunction

private function Init takes nothing returns nothing
    set AI_Rogue_ClassId = AI_RegisterClass("Rogue")
    set AI_Rogue_ProfileId = AI_RegisterProfile(AI_Rogue_ClassId, AI_ROGUE_UNIT_HORDE, "Horde Rogue")
    call AI_SetProfileSpawnOwner(AI_Rogue_ProfileId, Player(1))
    call AI_SetProfileThinkCallback(AI_Rogue_ProfileId, function Think)
    call AI_AddProfileProfession(AI_Rogue_ProfileId, AI_PROFESSION_SKINNING)
    call RegisterAbilities()
    call AI_AddDefaultShopItems(AI_Rogue_ProfileId)
    call AI_AddRandomSpawnProfile(AI_Rogue_ProfileId)
    call RegisterBarks()
endfunction

endlibrary
