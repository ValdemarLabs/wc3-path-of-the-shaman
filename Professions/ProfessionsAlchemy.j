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

    // Sound labels. Professions plays Start once, Loop until done, and Finish once.
    private constant string PA_SOUND_START = "Alchemy start"
    private constant string PA_SOUND_LOOP = "Alchemy loop"
    private constant string PA_SOUND_FINISH = "Alchemy loop"

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

private function PA_Register takes string recipeName, string description, string iconPath, integer outputItemCode, integer requiredSkill, real craftTime returns integer
    return Professions_RegisterRecipe(GNS_PROF_ALCHEMY, PA_STATION_CAULDRON, recipeName, description, iconPath, outputItemCode, 1, requiredSkill, craftTime, 0.00)
endfunction

private function PA_Add takes integer recipeId, integer itemCode, integer amount, string materialName returns nothing
    call Professions_AddRecipeMaterial(recipeId, itemCode, amount, materialName)
endfunction

private function PA_RegisterRecipes takes nothing returns nothing
    local integer recipeId

    set recipeId = PA_Register("Spring Water", "Boils Agave into a simple restorative water.", PA_ICON_WATER, PA_ITEM_SPRING_WATER, 0, 5.00)
    call PA_Add(recipeId, PA_ITEM_AGAVE, 1, "Agave")

    set recipeId = PA_Register("Crystal Water", "Refines Liferoot into clear restorative water.", PA_ICON_WATER, PA_ITEM_CRYSTAL_WATER, 5, 5.00)
    call PA_Add(recipeId, PA_ITEM_LIFEROOT, 1, "Liferoot")

    set recipeId = PA_Register("Healing Salve", "Creates a basic salve for field treatment.", PA_ICON_SALVE, PA_ITEM_HEALING_SALVE, 0, 5.00)
    call PA_Add(recipeId, PA_ITEM_PEACEBLOOM, 1, "Peacebloom")

    set recipeId = PA_Register("Greater Healing Salve", "Creates a stronger salve from Peacebloom.", PA_ICON_SALVE, PA_ITEM_GREATER_HEALING_SALVE, 10, 5.00)
    call PA_Add(recipeId, PA_ITEM_PEACEBLOOM, 3, "Peacebloom")

    set recipeId = PA_Register("Minor Healing Potion", "Brews a small healing potion.", PA_ICON_HEALING, PA_ITEM_MINOR_HEALING_POTION, 0, 5.00)
    call PA_Add(recipeId, PA_ITEM_PEACEBLOOM, 1, "Peacebloom")
    call PA_Add(recipeId, PA_ITEM_AGAVE, 1, "Agave")

    set recipeId = PA_Register("Nazgrek's Flask", "A long-lasting flask using gathered herbs and creature reagents.", PA_ICON_FLASK, PA_ITEM_NAZGREKS_FLASK, 35, 5.00)
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
    call PA_RegisterRecipes()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
