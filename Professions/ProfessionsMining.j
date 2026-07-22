/**
    ProfessionsMining

    Author: Valdemar
    Version: 1.0

    Description: Registers forge smelting recipes for Mining without changing the gather-node mining systems.

    Credits:

    How to install:
    Import this library after Professions. Select a Forge unit ('n62S') near a tracked hero to open CraftingUI.

    API:
    call ProfessionsMining_Init()

**/

library ProfessionsMining initializer AutoInit requires Professions, GatherNodeSkills, Interface

globals
    // Runtime guard.
    private boolean PM_Initialized = false

    // Workstation configuration. Mining gather nodes remain owned by GatherNodeUnits.
    private constant integer PM_STATION_FORGE = 'n62S'
    private constant boolean PM_AI_CHEAT_CRAFTING = true
    private constant string PM_CRAFTER_ANIMATION_PRIMARY = "stand work"
    private constant string PM_CRAFTER_ANIMATION_FALLBACK = "attack"

    // Sound labels. Professions plays Start once, Loop until done, and Finish once.
    private constant string PM_SOUND_START = "Smelting"
    private constant string PM_SOUND_LOOP = "Smelting"
    private constant string PM_SOUND_FINISH = "Smelting"

    // Smelting input ore raw codes.
    private constant integer PM_ITEM_COPPER_ORE = 'I67E'
    private constant integer PM_ITEM_TIN_ORE = 'I67F'
    private constant integer PM_ITEM_SILVER_ORE = 'I67G'
    private constant integer PM_ITEM_IRON_ORE = 'I67H'
    private constant integer PM_ITEM_GOLD_ORE = 'I67I'
    private constant integer PM_ITEM_MITHRIL_ORE = 'I67J'
    private constant integer PM_ITEM_ARCANITE_ORE = 'I67K'
    private constant integer PM_ITEM_THORIUM_ORE = 'I67L'
    private constant integer PM_ITEM_COAL = 'I689'

    // Smelting output bar raw codes.
    private constant integer PM_ITEM_COPPER_BAR = 'I67M'
    private constant integer PM_ITEM_TIN_BAR = 'I67N'
    private constant integer PM_ITEM_SILVER_BAR = 'I67O'
    private constant integer PM_ITEM_BRONZE_BAR = 'I67P'
    private constant integer PM_ITEM_IRON_BAR = 'I67Q'
    private constant integer PM_ITEM_STEEL_BAR = 'I67R'
    private constant integer PM_ITEM_GOLD_BAR = 'I67S'
    private constant integer PM_ITEM_MITHRIL_BAR = 'I67T'
    private constant integer PM_ITEM_ARCANITE_BAR = 'I67U'
    private constant integer PM_ITEM_THORIUM_BAR = 'I67V'

    // Recipe icon paths.
    private constant string PM_ICON_COPPER = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_02.TGA"
    private constant string PM_ICON_TIN = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_02.TGA"
    private constant string PM_ICON_SILVER = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_03.TGA"
    private constant string PM_ICON_BRONZE = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Bronze.TGA"
    private constant string PM_ICON_IRON = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Iron.TGA"
    private constant string PM_ICON_STEEL = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Steel.TGA"
    private constant string PM_ICON_GOLD = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_03.TGA"
    private constant string PM_ICON_MITHRIL = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Mithril.TGA"
    private constant string PM_ICON_ARCANITE = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_03.TGA"
    private constant string PM_ICON_THORIUM = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Thorium.TGA"
endglobals

private function PM_RegisterSmelt takes string barName, integer oreCode, string oreName, integer barCode, string iconPath, integer requiredSkill returns nothing
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_MINING, PM_STATION_FORGE, "Smelt " + barName, "Smelts ore into a usable metal bar.", iconPath, barCode, 1, requiredSkill, 3.00, 0.00)

    call Professions_AddRecipeMaterial(recipeId, oreCode, 1, oreName)
    call Professions_SetRecipeSkillGain(recipeId, 1)
endfunction

private function PM_RegisterAlloy takes string barName, integer firstCode, string firstName, integer secondCode, string secondName, integer barCode, string iconPath, integer requiredSkill returns nothing
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_MINING, PM_STATION_FORGE, "Smelt " + barName, "Smelts metal materials into a usable alloy bar.", iconPath, barCode, 1, requiredSkill, 3.00, 0.00)

    call Professions_AddRecipeMaterial(recipeId, firstCode, 1, firstName)
    call Professions_AddRecipeMaterial(recipeId, secondCode, 1, secondName)
    call Professions_SetRecipeSkillGain(recipeId, 1)
endfunction

private function PM_RegisterRecipes takes nothing returns nothing
    call PM_RegisterSmelt("Copper Bar", PM_ITEM_COPPER_ORE, "Copper Ore", PM_ITEM_COPPER_BAR, PM_ICON_COPPER, 0)
    call PM_RegisterSmelt("Tin Bar", PM_ITEM_TIN_ORE, "Tin Ore", PM_ITEM_TIN_BAR, PM_ICON_TIN, 10)
    call PM_RegisterSmelt("Silver Bar", PM_ITEM_SILVER_ORE, "Silver Ore", PM_ITEM_SILVER_BAR, PM_ICON_SILVER, 15)
    call PM_RegisterAlloy("Bronze Bar", PM_ITEM_COPPER_BAR, "Copper Bar", PM_ITEM_TIN_BAR, "Tin Bar", PM_ITEM_BRONZE_BAR, PM_ICON_BRONZE, 15)
    call PM_RegisterSmelt("Iron Bar", PM_ITEM_IRON_ORE, "Iron Ore", PM_ITEM_IRON_BAR, PM_ICON_IRON, 20)
    call PM_RegisterAlloy("Steel Bar", PM_ITEM_IRON_BAR, "Iron Bar", PM_ITEM_COAL, "Coal", PM_ITEM_STEEL_BAR, PM_ICON_STEEL, 30)
    call PM_RegisterSmelt("Gold Bar", PM_ITEM_GOLD_ORE, "Gold Ore", PM_ITEM_GOLD_BAR, PM_ICON_GOLD, 30)
    call PM_RegisterSmelt("Mithril Bar", PM_ITEM_MITHRIL_ORE, "Mithril Ore", PM_ITEM_MITHRIL_BAR, PM_ICON_MITHRIL, 50)
    call PM_RegisterSmelt("Arcanite Bar", PM_ITEM_ARCANITE_ORE, "Arcanite Ore", PM_ITEM_ARCANITE_BAR, PM_ICON_ARCANITE, 65)
    call PM_RegisterSmelt("Thorium Bar", PM_ITEM_THORIUM_ORE, "Thorium Ore", PM_ITEM_THORIUM_BAR, PM_ICON_THORIUM, 70)
endfunction

public function Init takes nothing returns nothing
    if PM_Initialized then
        return
    endif
    set PM_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_MINING, PM_STATION_FORGE, "Forge")
    call Professions_SetProfessionSoundLabels(GNS_PROF_MINING, PM_SOUND_START, PM_SOUND_LOOP, PM_SOUND_FINISH)
    call Professions_SetProfessionSoundHandles(GNS_PROF_MINING, Interface_Profession_Mining_Start, Interface_Profession_Mining_Loop, Interface_Profession_Mining_End)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_MINING, PM_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_MINING, PM_CRAFTER_ANIMATION_PRIMARY, PM_CRAFTER_ANIMATION_FALLBACK)
    call PM_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
