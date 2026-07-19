/**
    ProfessionsLeatherworking

    Author: Valdemar
    Version: 1.0

    Description: Registers Leatherworking workstation data and first-pass Reinforced Leather recipes for the shared Professions crafting engine.

    Credits:

    How to install:
    Import this library after Professions. Select a Tannery unit ('n625') near a tracked hero to open CraftingUI.

    API:
    call ProfessionsLeatherworking_Init()

**/

library ProfessionsLeatherworking initializer AutoInit requires Professions, GatherNodeSkills

globals
    private boolean PL_Initialized = false

    private constant integer PL_STATION_TANNERY = 'n625'

    private constant integer PL_ITEM_REINFORCED_LEATHER_GLOVES = 'I65X'
    private constant integer PL_ITEM_REINFORCED_LEATHER_BOOTS = 'I65Y'
    private constant integer PL_ITEM_REINFORCED_LEATHER_HELMET = 'I65Z'
    private constant integer PL_ITEM_REINFORCED_LEATHER_CHESTPIECE = 'I660'
    private constant integer PL_ITEM_REINFORCED_LEATHER_BELT = 'I661'
    private constant integer PL_ITEM_REINFORCED_LEATHER_SHOULDERPADS = 'I662'

    private constant string PL_ICON_LEATHER = "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp"
endglobals

private function PL_RegisterReinforcedLeather takes string recipeName, string description, integer outputItemCode returns nothing
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_LEATHERWORKING, PL_STATION_TANNERY, recipeName, description, PL_ICON_LEATHER, outputItemCode, 1, 0, 5.00, 0.00)

    call Professions_SetRecipeSkillGain(recipeId, 1)
endfunction

private function PL_RegisterRecipes takes nothing returns nothing
    call PL_RegisterReinforcedLeather("Reinforced Leather Belt", "Crafts a reinforced leather belt.", PL_ITEM_REINFORCED_LEATHER_BELT)
    call PL_RegisterReinforcedLeather("Reinforced Leather Boots", "Crafts reinforced leather boots.", PL_ITEM_REINFORCED_LEATHER_BOOTS)
    call PL_RegisterReinforcedLeather("Reinforced Leather Chestpiece", "Crafts a reinforced leather chestpiece.", PL_ITEM_REINFORCED_LEATHER_CHESTPIECE)
    call PL_RegisterReinforcedLeather("Reinforced Leather Gloves", "Crafts reinforced leather gloves.", PL_ITEM_REINFORCED_LEATHER_GLOVES)
    call PL_RegisterReinforcedLeather("Reinforced Leather Helmet", "Crafts a reinforced leather helmet.", PL_ITEM_REINFORCED_LEATHER_HELMET)
    call PL_RegisterReinforcedLeather("Reinforced Leather Shoulderpads", "Crafts reinforced leather shoulderpads.", PL_ITEM_REINFORCED_LEATHER_SHOULDERPADS)
endfunction

public function Init takes nothing returns nothing
    if PL_Initialized then
        return
    endif
    set PL_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_LEATHERWORKING, PL_STATION_TANNERY, "Tannery")
    call Professions_SetProfessionSoundLabels(GNS_PROF_LEATHERWORKING, "Tannery", "Tannery", "Tannery")
    call PL_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
