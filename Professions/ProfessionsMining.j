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

library ProfessionsMining initializer AutoInit requires Professions, GatherNodeSkills

globals
    private boolean PM_Initialized = false

    private constant integer PM_STATION_FORGE = 'n62S'

    private constant integer PM_ITEM_COPPER_ORE = 'I67E'
    private constant integer PM_ITEM_TIN_ORE = 'I67F'
    private constant integer PM_ITEM_SILVER_ORE = 'I67G'
    private constant integer PM_ITEM_IRON_ORE = 'I67H'
    private constant integer PM_ITEM_GOLD_ORE = 'I67I'
    private constant integer PM_ITEM_MITHRIL_ORE = 'I67J'
    private constant integer PM_ITEM_THORIUM_ORE = 'I67L'

    private constant integer PM_ITEM_COPPER_BAR = 'I67M'
    private constant integer PM_ITEM_TIN_BAR = 'I67N'
    private constant integer PM_ITEM_SILVER_BAR = 'I67O'
    private constant integer PM_ITEM_IRON_BAR = 'I67Q'
    private constant integer PM_ITEM_GOLD_BAR = 'I67S'
    private constant integer PM_ITEM_MITHRIL_BAR = 'I67T'
    private constant integer PM_ITEM_THORIUM_BAR = 'I67V'

    private constant string PM_ICON_COPPER = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_02.TGA"
    private constant string PM_ICON_TIN = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_02.TGA"
    private constant string PM_ICON_SILVER = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_03.TGA"
    private constant string PM_ICON_IRON = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Iron.TGA"
    private constant string PM_ICON_GOLD = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_03.TGA"
    private constant string PM_ICON_MITHRIL = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Mithril.TGA"
    private constant string PM_ICON_THORIUM = "ReplaceableTextures\\CommandButtons\\BTNINV_Ingot_Thorium.TGA"
endglobals

private function PM_RegisterSmelt takes string barName, integer oreCode, string oreName, integer barCode, string iconPath, integer requiredSkill returns nothing
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_MINING, PM_STATION_FORGE, "Smelt " + barName, "Smelts ore into a usable metal bar.", iconPath, barCode, 1, requiredSkill, 3.00, 0.00)

    call Professions_AddRecipeMaterial(recipeId, oreCode, 1, oreName)
    call Professions_SetRecipeSkillGain(recipeId, 1)
endfunction

private function PM_RegisterRecipes takes nothing returns nothing
    call PM_RegisterSmelt("Copper Bar", PM_ITEM_COPPER_ORE, "Copper Ore", PM_ITEM_COPPER_BAR, PM_ICON_COPPER, 0)
    call PM_RegisterSmelt("Tin Bar", PM_ITEM_TIN_ORE, "Tin Ore", PM_ITEM_TIN_BAR, PM_ICON_TIN, 10)
    call PM_RegisterSmelt("Silver Bar", PM_ITEM_SILVER_ORE, "Silver Ore", PM_ITEM_SILVER_BAR, PM_ICON_SILVER, 15)
    call PM_RegisterSmelt("Iron Bar", PM_ITEM_IRON_ORE, "Iron Ore", PM_ITEM_IRON_BAR, PM_ICON_IRON, 20)
    call PM_RegisterSmelt("Gold Bar", PM_ITEM_GOLD_ORE, "Gold Ore", PM_ITEM_GOLD_BAR, PM_ICON_GOLD, 30)
    call PM_RegisterSmelt("Mithril Bar", PM_ITEM_MITHRIL_ORE, "Mithril Ore", PM_ITEM_MITHRIL_BAR, PM_ICON_MITHRIL, 50)
    call PM_RegisterSmelt("Thorium Bar", PM_ITEM_THORIUM_ORE, "Thorium Ore", PM_ITEM_THORIUM_BAR, PM_ICON_THORIUM, 70)
endfunction

public function Init takes nothing returns nothing
    if PM_Initialized then
        return
    endif
    set PM_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_MINING, PM_STATION_FORGE, "Forge")
    call Professions_SetProfessionSoundLabels(GNS_PROF_MINING, "Tradeskill_MiningHitA", "Tradeskill_MiningHitB", "Tradeskill_MiningHitC")
    call PM_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
