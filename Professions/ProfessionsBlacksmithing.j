/**
    ProfessionsBlacksmithing

    Author: Valdemar
    Version: 1.0

    Description: Registers Blacksmithing workstation data and first-pass copper armor recipes for the shared Professions crafting engine.

    Credits:

    How to install:
    Import this library after Professions. Select an Anvil unit ('n62R') near a tracked hero to open CraftingUI.

    API:
    call ProfessionsBlacksmithing_Init()

**/

library ProfessionsBlacksmithing initializer AutoInit requires Professions, GatherNodeSkills

globals
    // Runtime guard.
    private boolean PB_Initialized = false

    // Workstation and material configuration.
    private constant integer PB_STATION_ANVIL = 'n62R'
    private constant integer PB_ITEM_COPPER_BAR = 'I67M'

    // Sound labels. Professions plays Start once, Loop until done, and Finish once.
    private constant string PB_SOUND_START = "Blacksmithing"
    private constant string PB_SOUND_LOOP = "Blacksmithing"
    private constant string PB_SOUND_FINISH = "Blacksmithing"

    // Recipe category path for the current first-pass copper armor set.
    private constant string PB_CATEGORY_APPRENTICE = "Apprentice Blacksmithing"
    private constant string PB_SUBCATEGORY_COPPER_ARMOR = "Copper Armor"

    // Crafted output raw codes.
    private constant integer PB_ITEM_COPPER_CHAIN_HELMET = 'I68F'
    private constant integer PB_ITEM_COPPER_CHAIN_LEGGINGS = 'I68G'
    private constant integer PB_ITEM_COPPER_CHAIN_VEST = 'I68H'
    private constant integer PB_ITEM_COPPER_CHAIN_BRACERS = 'I68I'
    private constant integer PB_ITEM_COPPER_CHAIN_GAUNTLETS = 'I68J'
    private constant integer PB_ITEM_COPPER_CHAIN_BELT = 'I68K'
    private constant integer PB_ITEM_COPPER_CHAIN_SHOULDERS = 'I68L'
    private constant integer PB_ITEM_COPPER_CHAIN_BOOTS = 'I68M'

    // Recipe icon paths.
    private constant string PB_ICON_ARMOR = "ReplaceableTextures\\CommandButtons\\BTNThoriumArmor.blp"
    private constant string PB_ICON_CHEST = "war3campImported\\BTNINV_Chest_Chain_10.blp"
endglobals

private function PB_RegisterCopperArmor takes string recipeName, string description, string iconPath, integer outputItemCode, integer requiredSkill, integer copperBars returns nothing
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_BLACKSMITHING, PB_STATION_ANVIL, recipeName, description, iconPath, outputItemCode, 1, requiredSkill, 5.00, 0.00)

    call Professions_AddRecipeMaterial(recipeId, PB_ITEM_COPPER_BAR, copperBars, "Copper Bar")
    call Professions_SetRecipeCategoryPath(recipeId, PB_CATEGORY_APPRENTICE, PB_SUBCATEGORY_COPPER_ARMOR)
    call Professions_SetRecipeSkillGain(recipeId, 1)
endfunction

private function PB_RegisterRecipes takes nothing returns nothing
    call PB_RegisterCopperArmor("Copper Chain Belt", "Forges a copper chain belt.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_BELT, 0, 4)
    call PB_RegisterCopperArmor("Copper Chain Boots", "Forges copper chain boots.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_BOOTS, 5, 6)
    call PB_RegisterCopperArmor("Copper Chain Bracers", "Forges copper chain bracers.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_BRACERS, 5, 4)
    call PB_RegisterCopperArmor("Copper Chain Gauntlets", "Forges copper chain gauntlets.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_GAUNTLETS, 10, 5)
    call PB_RegisterCopperArmor("Copper Chain Helmet", "Forges a copper chain helmet.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_HELMET, 15, 7)
    call PB_RegisterCopperArmor("Copper Chain Shoulders", "Forges copper chain shoulders.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_SHOULDERS, 20, 7)
    call PB_RegisterCopperArmor("Copper Chain Leggings", "Forges copper chain leggings.", PB_ICON_ARMOR, PB_ITEM_COPPER_CHAIN_LEGGINGS, 20, 8)
    call PB_RegisterCopperArmor("Copper Chain Vest", "Forges a copper chain vest.", PB_ICON_CHEST, PB_ITEM_COPPER_CHAIN_VEST, 25, 10)
endfunction

public function Init takes nothing returns nothing
    if PB_Initialized then
        return
    endif
    set PB_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_BLACKSMITHING, PB_STATION_ANVIL, "Anvil")
    call Professions_SetProfessionSoundLabels(GNS_PROF_BLACKSMITHING, PB_SOUND_START, PB_SOUND_LOOP, PB_SOUND_FINISH)
    call Professions_SetProfessionSoundHandles(GNS_PROF_BLACKSMITHING, gg_snd_Blacksmithing, gg_snd_Blacksmithing, gg_snd_Blacksmithing)
    call PB_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
