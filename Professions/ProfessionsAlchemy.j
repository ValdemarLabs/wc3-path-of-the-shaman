/**
    ProfessionsAlchemy

    Author: Valdemar
    Version: 1.0

    Description: Registers Alchemy workstation data, sounds, and cauldron recipes for the shared Professions crafting engine.

    Credits:

    How to install:
    Import this library after Professions. Select a Cauldron unit ('n61D') near a tracked hero to open CraftingUI.

    API:
    call ProfessionsAlchemy_Init()

**/

library ProfessionsAlchemy initializer AutoInit requires Professions, GatherNodeSkills

globals
    // Runtime guard.
    private boolean PA_Initialized = false

    // Workstation configuration.
    private constant integer PA_STATION_CAULDRON = 'n61D'
    private constant boolean PA_AI_CHEAT_CRAFTING = true
    private constant string PA_CRAFTER_ANIMATION_PRIMARY = "stand work"
    private constant string PA_CRAFTER_ANIMATION_FALLBACK = "spell"

    // Sound labels. Professions plays Start once, Loop until done, and Finish once.
    private constant string PA_SOUND_START = "Alchemy start"
    private constant string PA_SOUND_LOOP = "Alchemy loop"
    private constant string PA_SOUND_FINISH = "Alchemy loop"

    // Recipe categories mirror the workbook spellbook groups.
    private constant string PA_CATEGORY_BASIC_ALCHEMY = "Basic Alchemy"
    private constant string PA_CATEGORY_BASIC_POTIONS = "Basic Potions"
    private constant string PA_CATEGORY_UTILITY_POTIONS = "Utility Potions"
    private constant string PA_CATEGORY_FLASKS = "Flasks"

    // Reagent item raw codes used by current and future Alchemy recipes.
    private constant integer PA_ITEM_AGAVE = 'I60W'
    private constant integer PA_ITEM_EARTH_ROOTS = 'I60X'
    private constant integer PA_ITEM_FOREST_FLOWER = 'I60Y'
    private constant integer PA_ITEM_SPRING_WATER = 'I60Z'
    private constant integer PA_ITEM_STAG_HAIR = 'I614'
    private constant integer PA_ITEM_FROG_SLIME = 'I615'
    private constant integer PA_ITEM_EMPTY_FLASK = 'I61M'
    private constant integer PA_ITEM_NAZGREKS_FLASK = 'I61L'
    private constant integer PA_ITEM_PEACEBLOOM = 'I66X'
    private constant integer PA_ITEM_BRUISEWEED = 'I66T'
    private constant integer PA_ITEM_MOUNTAIN_SILVERSAGE = 'I66W'
    private constant integer PA_ITEM_LIFEROOT = 'I66V'
    private constant integer PA_ITEM_BLINDWEED = 'I66S'
    private constant integer PA_ITEM_GROMSBLOOD = 'I66U'
    private constant integer PA_ITEM_PLAGUEBLOOM = 'I66Y'

    // Crafted output raw codes.
    private constant integer PA_ITEM_CRYSTAL_WATER = 'I6BA'
    private constant integer PA_ITEM_HEALING_SALVE = 'hslv'
    private constant integer PA_ITEM_GREATER_HEALING_SALVE = 'I6BC'
    private constant integer PA_ITEM_MINOR_HEALING_POTION = 'I6BD'
    private constant integer PA_ITEM_HEALING_POTION = 'phea'
    private constant integer PA_ITEM_GREATER_HEALING_POTION = 'pghe'
    private constant integer PA_ITEM_MAJOR_HEALING_POTION = 'I6BE'
    private constant integer PA_ITEM_MINOR_MANA_POTION = 'I6BS'
    private constant integer PA_ITEM_MANA_POTION = 'pman'
    private constant integer PA_ITEM_GREATER_MANA_POTION = 'pgma'
    private constant integer PA_ITEM_MAJOR_MANA_POTION = 'I6BT'
    private constant integer PA_ITEM_MINOR_REPLENISHMENT = 'I6BG'
    private constant integer PA_ITEM_REPLENISHMENT = 'rej3'
    private constant integer PA_ITEM_GREATER_REPLENISHMENT = 'I6BH'
    private constant integer PA_ITEM_RESTORATION = 'pres'
    private constant integer PA_ITEM_GREATER_RESTORATION = 'I6BF'
    private constant integer PA_ITEM_INVISIBILITY = 'pinv'
    private constant integer PA_ITEM_SPEED = 'pspd'
    private constant integer PA_ITEM_LESSER_INVULNERABILITY = 'pnvl'
    private constant integer PA_ITEM_DIVINITY = 'pdiv'
    private constant integer PA_ITEM_ANTI_MAGIC = 'pams'

    // Recipe icon paths.
    private constant string PA_ICON_WATER = "ReplaceableTextures\\CommandButtons\\BTNINV_SpringWater.blp"
    private constant string PA_ICON_SALVE = "ReplaceableTextures\\CommandButtons\\BTNHealingSalve.blp"
    private constant string PA_ICON_HEALING = "ReplaceableTextures\\CommandButtons\\BTNPotionGreenSmall.blp"
    private constant string PA_ICON_HEALING_BIG = "ReplaceableTextures\\CommandButtons\\BTNPotionGreen.blp"
    private constant string PA_ICON_MANA = "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp"
    private constant string PA_ICON_MANA_BIG = "ReplaceableTextures\\CommandButtons\\BTNPotionBlueBig.blp"
    private constant string PA_ICON_REPLENISH = "ReplaceableTextures\\CommandButtons\\BTNMinorRejuvPotion.blp"
    private constant string PA_ICON_PURPLE = "ReplaceableTextures\\CommandButtons\\BTNPotionOfVampirism.blp"
    private constant string PA_ICON_FLASK = "ReplaceableTextures\\CommandButtons\\BTNVialFull.blp"
endglobals

private function PA_Register takes string categoryName, string recipeName, string description, string iconPath, integer outputItemCode, integer requiredSkill, real craftTime returns integer
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_ALCHEMY, PA_STATION_CAULDRON, recipeName, description, iconPath, outputItemCode, 1, requiredSkill, craftTime, 0.00)

    call Professions_SetRecipeCategory(recipeId, categoryName)
    return recipeId
endfunction

private function PA_Add takes integer recipeId, integer itemCode, integer amount, string materialName returns nothing
    call Professions_AddRecipeMaterial(recipeId, itemCode, amount, materialName)
endfunction

private function PA_RegisterRecipes takes nothing returns nothing
    local integer recipeId

    // Material-less or unresolved workbook rows are unregistered for now:
    // Purified Water, Vampiric Potion, Elixir of Might, Elixir of Shadows, and non-Nazgrek flask ideas.

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Spring Water", "Boils Agave into a simple restorative water.", PA_ICON_WATER, PA_ITEM_SPRING_WATER, 0, 5.00)
    call PA_Add(recipeId, PA_ITEM_AGAVE, 1, "Agave")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Crystal Water", "Refines Spring Water with Mountain Silversage.", PA_ICON_WATER, PA_ITEM_CRYSTAL_WATER, 5, 5.00)
    call PA_Add(recipeId, PA_ITEM_SPRING_WATER, 3, "Spring Water")
    call PA_Add(recipeId, PA_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Healing Salve", "Creates a basic salve for field treatment.", PA_ICON_SALVE, PA_ITEM_HEALING_SALVE, 0, 5.00)
    call PA_Add(recipeId, PA_ITEM_PEACEBLOOM, 2, "Peacebloom")
    call PA_Add(recipeId, PA_ITEM_EARTH_ROOTS, 1, "Earth Roots")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Greater Healing Salve", "Creates a stronger salve from prepared salves and Liferoot.", PA_ICON_SALVE, PA_ITEM_GREATER_HEALING_SALVE, 10, 5.00)
    call PA_Add(recipeId, PA_ITEM_HEALING_SALVE, 3, "Healing Salve")
    call PA_Add(recipeId, PA_ITEM_LIFEROOT, 2, "Liferoot")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Minor Replenishment Potion", "Brews a basic replenishment potion.", PA_ICON_REPLENISH, PA_ITEM_MINOR_REPLENISHMENT, 10, 5.00)
    call PA_Add(recipeId, PA_ITEM_PEACEBLOOM, 1, "Peacebloom")
    call PA_Add(recipeId, PA_ITEM_LIFEROOT, 2, "Liferoot")
    call PA_Add(recipeId, PA_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Replenishment Potion", "Brews a stronger replenishment potion.", PA_ICON_REPLENISH, PA_ITEM_REPLENISHMENT, 20, 5.00)
    call PA_Add(recipeId, PA_ITEM_CRYSTAL_WATER, 2, "Crystal Water")
    call PA_Add(recipeId, PA_ITEM_EARTH_ROOTS, 2, "Earth Roots")
    call PA_Add(recipeId, PA_ITEM_BLINDWEED, 1, "Blindweed")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_ALCHEMY, "Greater Replenishment Potion", "Brews a high-grade replenishment potion.", PA_ICON_REPLENISH, PA_ITEM_GREATER_REPLENISHMENT, 35, 5.00)
    call PA_Add(recipeId, PA_ITEM_REPLENISHMENT, 3, "Replenishment Potion")
    call PA_Add(recipeId, PA_ITEM_GROMSBLOOD, 2, "Gromsblood")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Minor Healing Potion", "Brews a small healing potion.", PA_ICON_HEALING, PA_ITEM_MINOR_HEALING_POTION, 0, 5.00)
    call PA_Add(recipeId, PA_ITEM_PEACEBLOOM, 1, "Peacebloom")
    call PA_Add(recipeId, PA_ITEM_AGAVE, 1, "Agave")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Healing Potion", "Brews a standard healing potion.", PA_ICON_HEALING, PA_ITEM_HEALING_POTION, 10, 5.00)
    call PA_Add(recipeId, PA_ITEM_MINOR_HEALING_POTION, 2, "Minor Healing Potion")
    call PA_Add(recipeId, PA_ITEM_LIFEROOT, 1, "Liferoot")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Greater Healing Potion", "Brews a greater healing potion.", PA_ICON_HEALING_BIG, PA_ITEM_GREATER_HEALING_POTION, 20, 5.00)
    call PA_Add(recipeId, PA_ITEM_HEALING_POTION, 3, "Healing Potion")
    call PA_Add(recipeId, PA_ITEM_BRUISEWEED, 2, "Bruiseweed")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Major Healing Potion", "Brews a major healing potion.", PA_ICON_HEALING_BIG, PA_ITEM_MAJOR_HEALING_POTION, 35, 5.00)
    call PA_Add(recipeId, PA_ITEM_GREATER_HEALING_POTION, 3, "Greater Healing Potion")
    call PA_Add(recipeId, PA_ITEM_PLAGUEBLOOM, 2, "Plaguebloom")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Minor Mana Potion", "Brews a small mana potion.", PA_ICON_MANA, PA_ITEM_MINOR_MANA_POTION, 5, 5.00)
    call PA_Add(recipeId, PA_ITEM_AGAVE, 1, "Agave")
    call PA_Add(recipeId, PA_ITEM_EARTH_ROOTS, 1, "Earth Roots")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Mana Potion", "Brews a standard mana potion.", PA_ICON_MANA, PA_ITEM_MANA_POTION, 15, 5.00)
    call PA_Add(recipeId, PA_ITEM_MINOR_MANA_POTION, 2, "Minor Mana Potion")
    call PA_Add(recipeId, PA_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Greater Mana Potion", "Brews a greater mana potion.", PA_ICON_MANA_BIG, PA_ITEM_GREATER_MANA_POTION, 30, 5.00)
    call PA_Add(recipeId, PA_ITEM_MANA_POTION, 3, "Mana Potion")
    call PA_Add(recipeId, PA_ITEM_BLINDWEED, 2, "Blindweed")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Major Mana Potion", "Brews a major mana potion.", PA_ICON_MANA_BIG, PA_ITEM_MAJOR_MANA_POTION, 45, 5.00)
    call PA_Add(recipeId, PA_ITEM_GREATER_MANA_POTION, 3, "Greater Mana Potion")
    call PA_Add(recipeId, PA_ITEM_GROMSBLOOD, 2, "Gromsblood")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Restoration Potion", "Brews a potion that restores life and mana.", PA_ICON_REPLENISH, PA_ITEM_RESTORATION, 25, 5.00)
    call PA_Add(recipeId, PA_ITEM_CRYSTAL_WATER, 2, "Crystal Water")
    call PA_Add(recipeId, PA_ITEM_LIFEROOT, 2, "Liferoot")
    call PA_Add(recipeId, PA_ITEM_EARTH_ROOTS, 1, "Earth Roots")

    set recipeId = PA_Register(PA_CATEGORY_BASIC_POTIONS, "Greater Restoration Potion", "Brews a stronger restoration potion.", PA_ICON_REPLENISH, PA_ITEM_GREATER_RESTORATION, 40, 5.00)
    call PA_Add(recipeId, PA_ITEM_RESTORATION, 3, "Restoration Potion")
    call PA_Add(recipeId, PA_ITEM_PLAGUEBLOOM, 2, "Plaguebloom")

    set recipeId = PA_Register(PA_CATEGORY_UTILITY_POTIONS, "Potion of Invisibility", "Brews a potion that briefly hides the drinker.", PA_ICON_PURPLE, PA_ITEM_INVISIBILITY, 20, 5.00)
    call PA_Add(recipeId, PA_ITEM_BLINDWEED, 2, "Blindweed")
    call PA_Add(recipeId, PA_ITEM_AGAVE, 1, "Agave")

    set recipeId = PA_Register(PA_CATEGORY_UTILITY_POTIONS, "Potion of Speed", "Brews a potion that greatly increases movement speed.", PA_ICON_HEALING, PA_ITEM_SPEED, 15, 5.00)
    call PA_Add(recipeId, PA_ITEM_EARTH_ROOTS, 2, "Earth Roots")
    call PA_Add(recipeId, PA_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")

    set recipeId = PA_Register(PA_CATEGORY_UTILITY_POTIONS, "Potion of Lesser Invulnerability", "Brews a short defensive potion.", PA_ICON_PURPLE, PA_ITEM_LESSER_INVULNERABILITY, 25, 5.00)
    call PA_Add(recipeId, PA_ITEM_BRUISEWEED, 2, "Bruiseweed")
    call PA_Add(recipeId, PA_ITEM_LIFEROOT, 1, "Liferoot")

    set recipeId = PA_Register(PA_CATEGORY_UTILITY_POTIONS, "Potion of Divinity", "Brews a rare defensive potion.", PA_ICON_PURPLE, PA_ITEM_DIVINITY, 45, 5.00)
    call PA_Add(recipeId, PA_ITEM_CRYSTAL_WATER, 3, "Crystal Water")
    call PA_Add(recipeId, PA_ITEM_PLAGUEBLOOM, 2, "Plaguebloom")

    set recipeId = PA_Register(PA_CATEGORY_UTILITY_POTIONS, "Anti-Magic Potion", "Brews a potion that helps resist harmful magic.", PA_ICON_PURPLE, PA_ITEM_ANTI_MAGIC, 35, 5.00)
    call PA_Add(recipeId, PA_ITEM_BLINDWEED, 2, "Blindweed")
    call PA_Add(recipeId, PA_ITEM_GROMSBLOOD, 1, "Gromsblood")

    set recipeId = PA_Register(PA_CATEGORY_FLASKS, "Nazgrek's Flask", "A long-lasting flask using gathered herbs and creature reagents.", PA_ICON_FLASK, PA_ITEM_NAZGREKS_FLASK, 35, 5.00)
    call PA_Add(recipeId, PA_ITEM_FOREST_FLOWER, 6, "Forest Flower")
    call PA_Add(recipeId, PA_ITEM_AGAVE, 3, "Agave")
    call PA_Add(recipeId, PA_ITEM_EARTH_ROOTS, 2, "Earth Roots")
    call PA_Add(recipeId, PA_ITEM_STAG_HAIR, 6, "Stag Hair")
    call PA_Add(recipeId, PA_ITEM_FROG_SLIME, 2, "Frog Slime")
    call PA_Add(recipeId, PA_ITEM_EMPTY_FLASK, 1, "Empty Flask")
endfunction

public function Init takes nothing returns nothing
    if PA_Initialized then
        return
    endif
    set PA_Initialized = true

    call Professions_RegisterStationType(GNS_PROF_ALCHEMY, PA_STATION_CAULDRON, "Cauldron")
    call Professions_SetProfessionSoundLabels(GNS_PROF_ALCHEMY, PA_SOUND_START, PA_SOUND_LOOP, PA_SOUND_FINISH)
    call Professions_SetProfessionSoundHandles(GNS_PROF_ALCHEMY, gg_snd_CauldronSound, gg_snd_CauldronSound, gg_snd_CauldronSound)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_ALCHEMY, PA_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_ALCHEMY, PA_CRAFTER_ANIMATION_PRIMARY, PA_CRAFTER_ANIMATION_FALLBACK)
    call PA_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
