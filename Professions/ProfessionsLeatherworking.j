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

library ProfessionsLeatherworking initializer AutoInit requires Professions, GatherNodeSkills, Interface

globals
    // Runtime guard.
    private boolean PL_Initialized = false

    // Workstation configuration.
    private constant integer PL_STATION_TANNERY = 'n625'
    private constant boolean PL_AI_CHEAT_CRAFTING = true
    private constant string PL_CRAFTER_ANIMATION_PRIMARY = "stand work"
    private constant string PL_CRAFTER_ANIMATION_FALLBACK = "attack"

    // Sound labels. Professions plays Start once, Loop until done, and Finish once.
    private constant string PL_SOUND_START = "Tannery"
    private constant string PL_SOUND_LOOP = "Tannery"
    private constant string PL_SOUND_FINISH = "Tannery"

    // Recipe category path for the current first-pass reinforced leather set.
    private constant string PL_CATEGORY_APPRENTICE = "Apprentice Leatherworking"
    private constant string PL_SUBCATEGORY_REINFORCED = "Reinforced Leather"

    // Crafted output raw codes.
    private constant integer PL_ITEM_REINFORCED_LEATHER_GLOVES = 'I65X'
    private constant integer PL_ITEM_REINFORCED_LEATHER_BOOTS = 'I65Y'
    private constant integer PL_ITEM_REINFORCED_LEATHER_HELMET = 'I65Z'
    private constant integer PL_ITEM_REINFORCED_LEATHER_CHESTPIECE = 'I660'
    private constant integer PL_ITEM_REINFORCED_LEATHER_BELT = 'I661'
    private constant integer PL_ITEM_REINFORCED_LEATHER_SHOULDERPADS = 'I662'

    // Recipe icon paths.
    private constant string PL_ICON_LEATHER = "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp"
endglobals

private function PL_RegisterReinforcedLeather takes string recipeName, string description, integer outputItemCode returns nothing
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_LEATHERWORKING, PL_STATION_TANNERY, recipeName, description, PL_ICON_LEATHER, outputItemCode, 1, 0, 5.00, 0.00)

    call Professions_SetRecipeCategoryPath(recipeId, PL_CATEGORY_APPRENTICE, PL_SUBCATEGORY_REINFORCED)
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
    call Professions_SetProfessionSoundLabels(GNS_PROF_LEATHERWORKING, PL_SOUND_START, PL_SOUND_LOOP, PL_SOUND_FINISH)
    call Professions_SetProfessionSoundHandles(GNS_PROF_LEATHERWORKING, Interface_Profession_Leatherworking_Start, Interface_Profession_Leatherworking_Loop, Interface_Profession_Leatherworking_End)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_LEATHERWORKING, PL_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_LEATHERWORKING, PL_CRAFTER_ANIMATION_PRIMARY, PL_CRAFTER_ANIMATION_FALLBACK)
    call PL_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
