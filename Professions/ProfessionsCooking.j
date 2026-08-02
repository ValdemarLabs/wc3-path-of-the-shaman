/**
    ProfessionsCooking

    Author: Valdemar
    Version: 1.5

    Description:
    Registers Cooking workstation data, campfire recipes, timed food and
    beverage effects, and item-use handling for cooked consumables.

    Credits:
    - Recipe progression is inspired by Classic WoW cooking, using PotS item ids.

    How to install:
    Import this library after Professions, Events, UnitDeathEvent, TimerUtils,
    Table, Drunk, and UnitStats. Cooking recipes are currently registered only
    against the Camp Fire unit ('n61C'). Later fire-source units should be added
    as extra station registrations here, not by loosening the crafting distance
    check. The shared Professions executor rejects dead campfires before and
    during crafting. Active recipe aura abilities are hidden from the unit
    command card; their associated buff icons remain available in the status bar.

    Food and drink buff notes:
    Cooking owns timed stat add/remove directly. One food buff and one drink
    buff may be active on a unit at the same time. Applying a new food replaces
    only the previous food stats/aura; applying a new drink replaces only the
    previous drink stats/aura. Only drinks with configured drunk amount above
    0.00 call Drunk_Add; non-alcohol drinks are still normal drink buffs.
    Cooked item object data should grant only Eat/Drink ('A0F5') to consume a
    charge. Recipe aura abilities belong on the unit at runtime and must not be
    added to the food or beverage item itself.

    Aura ability rawcodes are defined in PC_RegisterAuraRawcodes. Keep one aura
    ability per recipe when the buff text/icon must be recipe-specific. Warcraft
    runtime tooltip setters are object-code global, so one shared food aura and
    one shared drink aura would not give per-unit tooltip text when multiple
    units have different food or drink buffs active. Cooking adds the mapped
    aura while the timed effect is active and removes it on replacement,
    expiration, or unit death. The JASS stat definitions below remain the
    primary stat source unless the aura ability intentionally adds extra
    object-data bonuses.

    API:
    call ProfessionsCooking_Init()
    set abilityId = ProfessionsCooking_GetCookingAuraAbility(itemCode)
    set abilityId = ProfessionsCooking_GetFoodAuraAbility(itemCode)
    set abilityId = ProfessionsCooking_GetDrinkAuraAbility(itemCode)
    set effectText = ProfessionsCooking_GetCookingEffectText(itemCode)
    set effectText = ProfessionsCooking_GetFoodEffectText(itemCode)
    set effectText = ProfessionsCooking_GetDrinkEffectText(itemCode)
    set isCookingConsumable = ProfessionsCooking_IsCookingConsumable(itemCode)
    set isCookingFood = ProfessionsCooking_IsCookingFood(itemCode)
    set isCookingDrink = ProfessionsCooking_IsCookingDrink(itemCode)
    set isIntoxicatingDrink = ProfessionsCooking_IsCookingIntoxicatingDrink(itemCode)
    set activeAbilityId = ProfessionsCooking_GetActiveFoodAuraAbility(whichUnit)
    set activeAbilityId = ProfessionsCooking_GetActiveDrinkAuraAbility(whichUnit)
    set activeEffectText = ProfessionsCooking_GetActiveFoodEffectText(whichUnit)
    set activeEffectText = ProfessionsCooking_GetActiveDrinkEffectText(whichUnit)

**/

library ProfessionsCooking initializer AutoInit requires Professions, GatherNodeSkills, Interface, TimerUtils, Table, Events, UnitDeathEvent, Drunk, optional UnitStats

globals
    // Runtime guard.
    private boolean PC_Initialized = false

    // Workstation configuration.
    private constant integer PC_STATION_CAMP_FIRE = 'n61C'
    private constant boolean PC_AI_CHEAT_CRAFTING = true
    private constant string PC_CRAFTER_ANIMATION_PRIMARY = "stand"
    private constant string PC_CRAFTER_ANIMATION_FALLBACK = "spell"

    // Sound labels. Professions plays Start once, Loop until done, and Finish once.
    private constant string PC_SOUND_START = "CookingPrepareA"
    private constant string PC_SOUND_LOOP = "CookingPrepareA"
    private constant string PC_SOUND_FINISH = "CookingPrepareA"

    // Recipe category path for campfire cooking. Camp Fire is the only enabled fire source for now.
    // Keep the subcategory layer simple: each skill tier contains Food and Beverages.
    private constant string PC_CATEGORY_APPRENTICE = "Apprentice Cooking"
    private constant string PC_CATEGORY_JOURNEYMAN = "Journeyman Cooking"
    private constant string PC_CATEGORY_EXPERT = "Expert Cooking"
    private constant string PC_CATEGORY_ARTISAN = "Artisan Cooking"
    private constant string PC_SUBCATEGORY_FOOD = "Food"
    private constant string PC_SUBCATEGORY_BEVERAGES = "Beverages"

    // Recipe icon paths.
    private constant string PC_ICON_MEAT = "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp"
    private constant string PC_ICON_ROAST = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Food_15.blp"
    private constant string PC_ICON_STEW = "ReplaceableTextures\\CommandButtons\\BTNPotionGreenSmall.blp"
    private constant string PC_ICON_FISH = "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp"
    private constant string PC_ICON_DRINK = "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp"
    private constant string PC_ICON_ODDITY = "ReplaceableTextures\\CommandButtons\\BTNOrbOfCorruption.blp"

    // Reagent item raw codes from PotS exports.
    private constant integer PC_ITEM_RAW_WOLF_MEAT = 'I61O'
    private constant integer PC_ITEM_RAW_STAG_MEAT = 'I61P'
    private constant integer PC_ITEM_RAW_BEAR_MEAT = 'I61Q'
    private constant integer PC_ITEM_RAW_LIZARD_MEAT = 'I61R'
    private constant integer PC_ITEM_RAW_HAWK_MEAT = 'I61S'
    private constant integer PC_ITEM_RAW_MURLOC_MEAT = 'I61T'
    private constant integer PC_ITEM_RAW_TURTLE_MEAT = 'I61U'
    private constant integer PC_ITEM_RAW_TIGER_MEAT = 'I61V'
    private constant integer PC_ITEM_RAW_PANTHER_MEAT = 'I61W'
    private constant integer PC_ITEM_RAW_RAPTOR_MEAT = 'I61X'
    private constant integer PC_ITEM_RAW_SNAKE_MEAT = 'I61Y'
    private constant integer PC_ITEM_RAW_MAKRURA_MEAT = 'I61Z'
    private constant integer PC_ITEM_RAW_BOAR_MEAT = 'I620'
    private constant integer PC_ITEM_RAW_CRAWLER_MEAT = 'I621'
    private constant integer PC_ITEM_RAW_RABBIT_MEAT = 'I622'
    private constant integer PC_ITEM_RAW_COW_MEAT = 'I623'

    private constant integer PC_ITEM_RAW_SMALLFISH = 'I6CU'
    private constant integer PC_ITEM_RAW_MACKEREL = 'I6CV'
    private constant integer PC_ITEM_SICKLY_FISH = 'I6CW'
    private constant integer PC_ITEM_OILY_BLACKMOUTH = 'I6CX'
    private constant integer PC_ITEM_RAW_MUD_SNAPPER = 'I6CY'
    private constant integer PC_ITEM_RAW_ALBACORE = 'I6CZ'
    private constant integer PC_ITEM_RAW_CATFISH = 'I6D0'
    private constant integer PC_ITEM_RAW_LOCH_FRENZY = 'I6D1'
    private constant integer PC_ITEM_FIREFIN_SNAPPER = 'I6D2'
    private constant integer PC_ITEM_DEVIATE_FISH = 'I6D3'
    private constant integer PC_ITEM_RAW_SAGEFISH = 'I6D4'
    private constant integer PC_ITEM_RAW_ROCKSCALE_COD = 'I6D6'
    private constant integer PC_ITEM_RAW_MITHRIL_TROUT = 'I6D7'
    private constant integer PC_ITEM_RAW_SPOTTED_YELLOWTAIL = 'I6D8'
    private constant integer PC_ITEM_RAW_GLOSSY_MIGHTFISH = 'I6D9'
    private constant integer PC_ITEM_RAW_REDGILL = 'I6DA'
    private constant integer PC_ITEM_NIGHTFIN_SNAPPER = 'I6DB'
    private constant integer PC_ITEM_SUNSCALE_SALMON = 'I6DC'
    private constant integer PC_ITEM_RAW_STONESCALE_EEL = 'I6DD'
    private constant integer PC_ITEM_RAW_WHITESCALE_SALMON = 'I6DE'
    private constant integer PC_ITEM_DARKCLAW_LOBSTER = 'I6DF'
    private constant integer PC_ITEM_RAW_WINTER_SQUID = 'I6DG'
    private constant integer PC_ITEM_RAW_SUMMER_BASS = 'I6DH'
    private constant integer PC_ITEM_RAW_TIGERSEYE_EEL = 'I6DI'

    private constant integer PC_ITEM_SPRING_WATER = 'I60Z'
    private constant integer PC_ITEM_AGAVE = 'I60W'
    private constant integer PC_ITEM_CRYSTAL_WATER = 'I6BA'
    private constant integer PC_ITEM_PURIFIED_WATER = 'I6BB'
    private constant integer PC_ITEM_SALT = 'I66K'
    private constant integer PC_ITEM_PEACEBLOOM = 'I66X'
    private constant integer PC_ITEM_BLINDWEED = 'I66S'
    private constant integer PC_ITEM_BRUISEWEED = 'I66T'
    private constant integer PC_ITEM_GROMSBLOOD = 'I66U'
    private constant integer PC_ITEM_LIFEROOT = 'I66V'
    private constant integer PC_ITEM_MOUNTAIN_SILVERSAGE = 'I66W'
    private constant integer PC_ITEM_PLAGUEBLOOM = 'I66Y'
    private constant integer PC_ITEM_SEA_SALT_GLAND = 'j0b5'

    // New Cooking material rawcodes seeded by WC3ItemManager/CookingItemsSeeder.cs.
    private constant integer PC_ITEM_COARSE_FLOUR = 'j4a0'
    private constant integer PC_ITEM_HONEY = 'j4a1'
    private constant integer PC_ITEM_COOKING_PEPPERCORN = 'j4a2'
    private constant integer PC_ITEM_BAKER_YEAST = 'j4a3'
    private constant integer PC_ITEM_BITTER_HOPS = 'j4a4'
    private constant integer PC_ITEM_CACTUS_PULP = 'j4a5'
    private constant integer PC_ITEM_SOUR_BERRIES = 'j4a6'
    private constant integer PC_ITEM_GLOWCAP = 'j4a7'
    private constant integer PC_ITEM_ICECAP_SHAVINGS = 'j4a8'
    private constant integer PC_ITEM_EMPTY_BOTTLE = 'j4a9'

    // Existing crafted food item raw codes.
    private constant integer PC_ITEM_SMOKED_WOLF_JERKY = 'j0c6'
    private constant integer PC_ITEM_ROASTED_STAG_HAUNCH = 'j0c7'
    private constant integer PC_ITEM_BEAR_FAT_BISCUIT = 'j0c8'
    private constant integer PC_ITEM_BOILED_MAKRURA_CLAW = 'j0c9'
    private constant integer PC_ITEM_SPICED_SNAKE_STRIPS = 'j0d0'
    private constant integer PC_ITEM_FRIED_CRAWLER_CAKE = 'j0d1'

    // New crafted food rawcodes seeded by WC3ItemManager/CookingItemsSeeder.cs.
    private constant integer PC_ITEM_BRILLIANT_SMALLFISH = 'j2b0'
    private constant integer PC_ITEM_SLITHERSKIN_MACKEREL = 'j2b1'
    private constant integer PC_ITEM_CHARRED_BOAR_RIBS = 'j2a0'
    private constant integer PC_ITEM_MUD_SNAPPER_CAKE = 'j2b2'
    private constant integer PC_ITEM_RABBIT_BROTH = 'j2a1'
    private constant integer PC_ITEM_HAWK_SKEWER = 'j2a2'
    private constant integer PC_ITEM_RAINBOW_ALBACORE = 'j2b3'
    private constant integer PC_ITEM_TURTLE_STEW = 'j2a3'
    private constant integer PC_ITEM_CATFISH_CHOWDER = 'j2b4'
    private constant integer PC_ITEM_MURLOC_FIN_SOUP = 'j2a4'
    private constant integer PC_ITEM_LOCH_FRENZY_DELIGHT = 'j2b5'
    private constant integer PC_ITEM_LIZARD_PEPPER_ROAST = 'j2a5'
    private constant integer PC_ITEM_FIREFIN_CHILI = 'j2b6'
    private constant integer PC_ITEM_TIGER_STEAK = 'j2a6'
    private constant integer PC_ITEM_SAGEFISH_SOUP = 'j2b7'
    private constant integer PC_ITEM_PANTHER_FILLET = 'j2a7'
    private constant integer PC_ITEM_ROCKSCALE_COD = 'j2b9'
    private constant integer PC_ITEM_RAPTOR_CHILI = 'j2a8'
    private constant integer PC_ITEM_MITHRIL_TROUT = 'j2c0'
    private constant integer PC_ITEM_COW_RUMP_ROAST = 'j2a9'
    private constant integer PC_ITEM_SPOTTED_YELLOWTAIL = 'j2c1'
    private constant integer PC_ITEM_DEVIATE_DELIGHT = 'j2d2'
    private constant integer PC_ITEM_GLOSSY_MIGHTFISH_STEAK = 'j2c2'
    private constant integer PC_ITEM_REDGILL_SKILLET = 'j2c3'
    private constant integer PC_ITEM_NIGHTFIN_SOUP = 'j2c4'
    private constant integer PC_ITEM_SUNSCALE_FILLET = 'j2c5'
    private constant integer PC_ITEM_COOKED_STONESCALE_EEL = 'j2c6'
    private constant integer PC_ITEM_WHITESCALE_SALMON = 'j2c7'
    private constant integer PC_ITEM_DARKCLAW_BISQUE = 'j2c8'
    private constant integer PC_ITEM_COOKED_WINTER_SQUID = 'j2c9'
    private constant integer PC_ITEM_SUMMER_BASS = 'j2d0'
    private constant integer PC_ITEM_TIGERSEYE_EEL = 'j2d1'
    private constant integer PC_ITEM_EMBER_WHELP_ROAST = 'j2d3'
    private constant integer PC_ITEM_PLAGUEBLOOM_DUMPLING = 'j2d4'

    // New beverage rawcodes seeded by WC3ItemManager/CookingItemsSeeder.cs.
    private constant integer PC_ITEM_SPRINGWATER_TEA = 'j3a0'
    private constant integer PC_ITEM_HONEYED_MILK = 'j3a1'
    private constant integer PC_ITEM_CACTUS_ALE = 'j3a2'
    private constant integer PC_ITEM_STOUT_MEAD = 'j3a3'
    private constant integer PC_ITEM_SALTED_MAKRURA_BROTH = 'j3a4'
    private constant integer PC_ITEM_BLACKMOUTH_GROG = 'j3a5'
    private constant integer PC_ITEM_FIREFIN_WHISKEY = 'j3a6'
    private constant integer PC_ITEM_SAGEFISH_TONIC = 'j3a7'
    private constant integer PC_ITEM_DEVIATE_RUM = 'j3a8'
    private constant integer PC_ITEM_NIGHTFIN_WINE = 'j3a9'
    private constant integer PC_ITEM_STONESCALE_PORTER = 'j3b0'
    private constant integer PC_ITEM_LOBSTER_CUP = 'j3b1'
    private constant integer PC_ITEM_DRAGONFIRE_PUNCH = 'j3b2'
    private constant integer PC_ITEM_WINTER_ABSINTHE = 'j3b3'
    private constant integer PC_ITEM_BAD_IDEAS_BREW = 'j3b4'

    // Timed effect configuration.
    private constant integer PC_MAX_EFFECT_STATS = 8
    private constant real PC_DEFAULT_FOOD_DURATION = 900.00
    private constant real PC_DEFAULT_BEVERAGE_DURATION = 600.00
    private constant real PC_UNITSTATS_REAPPLY_DELAY = 0.04

    // Stat ids mirror the DEqStatNames ordering where practical, with direct Cooking-only support.
    private constant integer PC_STAT_STRENGTH = 1
    private constant integer PC_STAT_AGILITY = 2
    private constant integer PC_STAT_INTELLIGENCE = 3
    private constant integer PC_STAT_HITPOINTS = 4
    private constant integer PC_STAT_HITPOINT_REGEN = 5
    private constant integer PC_STAT_MANA = 8
    private constant integer PC_STAT_MANA_REGEN = 9
    private constant integer PC_STAT_CRIT = 10
    private constant integer PC_STAT_DAMAGE = 12
    private constant integer PC_STAT_ARMOR = 25
    private constant integer PC_STAT_DODGE = 27
    private constant integer PC_STAT_MOVEMENT_SPEED = 31
    private constant integer PC_STAT_BLOCK = 35
    private constant integer PC_STAT_HIT = 36
    private constant integer PC_STAT_SPELL_POWER_PCT = 37
    private constant integer PC_STAT_SPELL_POWER_FLAT = 38
    private constant integer PC_STAT_SIGHT_RANGE = 133

    // Long-buff aura ability rawcodes, wired per recipe in PC_RegisterAuraRawcodes.
    private integer array PC_EffectAuraAbility

    private Table PC_ItemEffect = 0
    private Table PC_ReapplyTimerGeneration = 0
    private integer PC_EffectCount = 0
    private integer array PC_EffectStatCount
    private integer array PC_EffectStatType
    private real array PC_EffectStatAmount
    private real array PC_EffectDuration
    private real array PC_EffectDrunkAmount
    private boolean array PC_EffectIsBeverage
    private string array PC_EffectName
    private string array PC_EffectText

    // Timed buff slots. Food and drink are separate so each unit can keep one of each active.
    private integer array PC_ActiveFoodEffect
    private timer array PC_ActiveFoodTimer
    private unit array PC_ActiveFoodUnit
    private integer array PC_ActiveBeverageEffect
    private timer array PC_ActiveBeverageTimer
    private unit array PC_ActiveBeverageUnit
    private integer array PC_ReapplyGeneration
    private unit array PC_ReapplyUnit
endglobals

private function PC_RegisterRecipe takes string categoryName, string subcategoryName, string recipeName, string description, string iconPath, integer outputItemCode, integer requiredSkill, real craftTime returns integer
    local integer recipeId = Professions_RegisterRecipe(GNS_PROF_COOKING, PC_STATION_CAMP_FIRE, recipeName, description, iconPath, outputItemCode, 1, requiredSkill, craftTime, 0.00)

    call Professions_SetRecipeCategoryPath(recipeId, categoryName, subcategoryName)
    call Professions_SetRecipeSkillGain(recipeId, 1)
    return recipeId
endfunction

private function PC_Add takes integer recipeId, integer itemCode, integer amount, string materialName returns nothing
    call Professions_AddRecipeMaterial(recipeId, itemCode, amount, materialName)
endfunction

private function PC_Round takes real value returns integer
    if value >= 0.00 then
        return R2I(value + 0.50)
    endif
    return R2I(value - 0.50)
endfunction

private function PC_GetUnitId takes unit whichUnit returns integer
    if whichUnit == null then
        return 0
    endif
    return GetUnitUserData(whichUnit)
endfunction

private function PC_IsArrayBackedStat takes integer statType returns boolean
    return statType == PC_STAT_CRIT or statType == PC_STAT_DODGE or statType == PC_STAT_BLOCK or statType == PC_STAT_HIT or statType == PC_STAT_SPELL_POWER_PCT or statType == PC_STAT_SPELL_POWER_FLAT
endfunction

private function PC_ClampMoveSpeed takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > 522.00 then
        return 522.00
    endif
    return value
endfunction

private function PC_ApplyStatDelta takes unit whichUnit, integer statType, real amount returns nothing
    local integer unitId = PC_GetUnitId(whichUnit)
    local integer intAmount = PC_Round(amount)
    local integer newValue
    local real newReal

    if whichUnit == null or amount == 0.00 then
        return
    endif

    if statType == PC_STAT_STRENGTH then
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) and intAmount != 0 then
            call SetHeroStr(whichUnit, GetHeroStr(whichUnit, false) + intAmount, true)
        endif
    elseif statType == PC_STAT_AGILITY then
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) and intAmount != 0 then
            call SetHeroAgi(whichUnit, GetHeroAgi(whichUnit, false) + intAmount, true)
        endif
    elseif statType == PC_STAT_INTELLIGENCE then
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) and intAmount != 0 then
            call SetHeroInt(whichUnit, GetHeroInt(whichUnit, false) + intAmount, true)
        endif
    elseif statType == PC_STAT_HITPOINTS then
        set newValue = BlzGetUnitMaxHP(whichUnit) + intAmount
        if newValue < 1 then
            set newValue = 1
        endif
        call BlzSetUnitMaxHP(whichUnit, newValue)
        if GetUnitState(whichUnit, UNIT_STATE_LIFE) > I2R(newValue) then
            call SetUnitState(whichUnit, UNIT_STATE_LIFE, I2R(newValue))
        endif
    elseif statType == PC_STAT_MANA then
        set newValue = BlzGetUnitMaxMana(whichUnit) + intAmount
        if newValue < 0 then
            set newValue = 0
        endif
        call BlzSetUnitMaxMana(whichUnit, newValue)
        if GetUnitState(whichUnit, UNIT_STATE_MANA) > I2R(newValue) then
            call SetUnitState(whichUnit, UNIT_STATE_MANA, I2R(newValue))
        endif
    elseif statType == PC_STAT_HITPOINT_REGEN then
        set newReal = BlzGetUnitRealField(whichUnit, UNIT_RF_HIT_POINTS_REGENERATION_RATE) + amount
        if newReal < 0.00 then
            set newReal = 0.00
        endif
        call BlzSetUnitRealField(whichUnit, UNIT_RF_HIT_POINTS_REGENERATION_RATE, newReal)
    elseif statType == PC_STAT_MANA_REGEN then
        set newReal = BlzGetUnitRealField(whichUnit, UNIT_RF_MANA_REGENERATION) + amount
        if newReal < 0.00 then
            set newReal = 0.00
        endif
        call BlzSetUnitRealField(whichUnit, UNIT_RF_MANA_REGENERATION, newReal)
    elseif statType == PC_STAT_DAMAGE then
        call BlzSetUnitBaseDamage(whichUnit, BlzGetUnitBaseDamage(whichUnit, 0) + intAmount, 0)
        call BlzSetUnitBaseDamage(whichUnit, BlzGetUnitBaseDamage(whichUnit, 1) + intAmount, 1)
    elseif statType == PC_STAT_ARMOR then
        call BlzSetUnitArmor(whichUnit, BlzGetUnitArmor(whichUnit) + amount)
    elseif statType == PC_STAT_MOVEMENT_SPEED then
        call SetUnitMoveSpeed(whichUnit, PC_ClampMoveSpeed(GetUnitMoveSpeed(whichUnit) + amount))
    elseif statType == PC_STAT_SIGHT_RANGE then
        set newReal = BlzGetUnitRealField(whichUnit, ConvertUnitRealField('usir')) + amount
        if newReal < 0.00 then
            set newReal = 0.00
        endif
        call BlzSetUnitRealField(whichUnit, ConvertUnitRealField('usir'), newReal)
    elseif unitId > 0 and intAmount != 0 then
        if statType == PC_STAT_CRIT then
            set udg_Stats_Crit[unitId] = udg_Stats_Crit[unitId] + intAmount
        elseif statType == PC_STAT_DODGE then
            set udg_Stats_Dodge[unitId] = udg_Stats_Dodge[unitId] + intAmount
        elseif statType == PC_STAT_BLOCK then
            set udg_Stats_Block[unitId] = udg_Stats_Block[unitId] + intAmount
        elseif statType == PC_STAT_HIT then
            set udg_Stats_Hit[unitId] = udg_Stats_Hit[unitId] + intAmount
        elseif statType == PC_STAT_SPELL_POWER_PCT then
            set udg_Stats_SpellPowerPct[unitId] = udg_Stats_SpellPowerPct[unitId] + intAmount
        elseif statType == PC_STAT_SPELL_POWER_FLAT then
            set udg_Stats_SpellPowerFlat[unitId] = udg_Stats_SpellPowerFlat[unitId] + intAmount
        endif
    endif
endfunction

private function PC_ApplyEffectStats takes unit whichUnit, integer effectId, integer sign, boolean arrayOnly returns nothing
    local integer slot = 1
    local integer key
    local integer statType

    loop
        exitwhen slot > PC_EffectStatCount[effectId]
        set key = effectId * PC_MAX_EFFECT_STATS + slot
        set statType = PC_EffectStatType[key]
        if not arrayOnly or PC_IsArrayBackedStat(statType) then
            call PC_ApplyStatDelta(whichUnit, statType, PC_EffectStatAmount[key] * I2R(sign))
        endif
        set slot = slot + 1
    endloop
endfunction

private function PC_RegisterConsumable takes integer itemCode, string effectName, string effectText, real duration, boolean isBeverage, real drunkAmount returns integer
    set PC_EffectCount = PC_EffectCount + 1
    set PC_EffectName[PC_EffectCount] = effectName
    set PC_EffectText[PC_EffectCount] = effectText
    set PC_EffectDuration[PC_EffectCount] = duration
    set PC_EffectIsBeverage[PC_EffectCount] = isBeverage
    set PC_EffectDrunkAmount[PC_EffectCount] = drunkAmount
    set PC_EffectAuraAbility[PC_EffectCount] = 0
    set PC_ItemEffect.integer[itemCode] = PC_EffectCount
    return PC_EffectCount
endfunction

private function PC_SetAuraByItem takes integer itemCode, integer auraAbilityId returns nothing
    local integer effectId = PC_ItemEffect.integer[itemCode]

    if effectId > 0 then
        set PC_EffectAuraAbility[effectId] = auraAbilityId
    endif
endfunction

private function PC_AddEffectStat takes integer effectId, integer statType, real amount returns nothing
    local integer slot
    local integer key

    if effectId <= 0 or amount == 0.00 then
        return
    endif

    set slot = PC_EffectStatCount[effectId] + 1
    if slot > PC_MAX_EFFECT_STATS then
        return
    endif

    set PC_EffectStatCount[effectId] = slot
    set key = effectId * PC_MAX_EFFECT_STATS + slot
    set PC_EffectStatType[key] = statType
    set PC_EffectStatAmount[key] = amount
endfunction

private function PC_ShowEffectApplied takes unit whichUnit, integer effectId returns nothing
    if whichUnit != null and effectId > 0 then
        call DisplayTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, "|cffffcc66" + PC_EffectName[effectId] + "|r: " + PC_EffectText[effectId])
    endif
endfunction

private function PC_AddEffectAura takes unit whichUnit, integer effectId returns nothing
    local integer auraAbilityId

    if whichUnit == null or effectId <= 0 then
        return
    endif

    set auraAbilityId = PC_EffectAuraAbility[effectId]
    if auraAbilityId != 0 then
        call UnitAddAbility(whichUnit, auraAbilityId)
        call BlzUnitHideAbility(whichUnit, auraAbilityId, true)
    endif
endfunction

private function PC_RemoveEffectAura takes unit whichUnit, integer effectId returns nothing
    local integer auraAbilityId

    if whichUnit == null or effectId <= 0 then
        return
    endif

    set auraAbilityId = PC_EffectAuraAbility[effectId]
    if auraAbilityId != 0 then
        call UnitRemoveAbility(whichUnit, auraAbilityId)
    endif
endfunction

private function PC_ReleaseFoodTimer takes integer unitId returns nothing
    if PC_ActiveFoodTimer[unitId] != null then
        call PauseTimer(PC_ActiveFoodTimer[unitId])
        call ReleaseTimer(PC_ActiveFoodTimer[unitId])
        set PC_ActiveFoodTimer[unitId] = null
    endif
endfunction

private function PC_ReleaseBeverageTimer takes integer unitId returns nothing
    if PC_ActiveBeverageTimer[unitId] != null then
        call PauseTimer(PC_ActiveBeverageTimer[unitId])
        call ReleaseTimer(PC_ActiveBeverageTimer[unitId])
        set PC_ActiveBeverageTimer[unitId] = null
    endif
endfunction

private function PC_RemoveFood takes integer unitId returns nothing
    if PC_ActiveFoodEffect[unitId] > 0 and PC_ActiveFoodUnit[unitId] != null then
        call PC_RemoveEffectAura(PC_ActiveFoodUnit[unitId], PC_ActiveFoodEffect[unitId])
        call PC_ApplyEffectStats(PC_ActiveFoodUnit[unitId], PC_ActiveFoodEffect[unitId], -1, false)
    endif
    call PC_ReleaseFoodTimer(unitId)
    set PC_ActiveFoodEffect[unitId] = 0
    set PC_ActiveFoodUnit[unitId] = null
endfunction

private function PC_RemoveBeverage takes integer unitId returns nothing
    if PC_ActiveBeverageEffect[unitId] > 0 and PC_ActiveBeverageUnit[unitId] != null then
        call PC_RemoveEffectAura(PC_ActiveBeverageUnit[unitId], PC_ActiveBeverageEffect[unitId])
        call PC_ApplyEffectStats(PC_ActiveBeverageUnit[unitId], PC_ActiveBeverageEffect[unitId], -1, false)
    endif
    call PC_ReleaseBeverageTimer(unitId)
    set PC_ActiveBeverageEffect[unitId] = 0
    set PC_ActiveBeverageUnit[unitId] = null
endfunction

private function PC_FoodExpires takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer unitId = GetTimerData(t)

    set PC_ActiveFoodTimer[unitId] = null
    if PC_ActiveFoodEffect[unitId] > 0 and PC_ActiveFoodUnit[unitId] != null then
        call PC_RemoveEffectAura(PC_ActiveFoodUnit[unitId], PC_ActiveFoodEffect[unitId])
        call PC_ApplyEffectStats(PC_ActiveFoodUnit[unitId], PC_ActiveFoodEffect[unitId], -1, false)
    endif
    set PC_ActiveFoodEffect[unitId] = 0
    set PC_ActiveFoodUnit[unitId] = null

    call ReleaseTimer(t)
    set t = null
endfunction

private function PC_BeverageExpires takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer unitId = GetTimerData(t)

    set PC_ActiveBeverageTimer[unitId] = null
    if PC_ActiveBeverageEffect[unitId] > 0 and PC_ActiveBeverageUnit[unitId] != null then
        call PC_RemoveEffectAura(PC_ActiveBeverageUnit[unitId], PC_ActiveBeverageEffect[unitId])
        call PC_ApplyEffectStats(PC_ActiveBeverageUnit[unitId], PC_ActiveBeverageEffect[unitId], -1, false)
    endif
    set PC_ActiveBeverageEffect[unitId] = 0
    set PC_ActiveBeverageUnit[unitId] = null

    call ReleaseTimer(t)
    set t = null
endfunction

private function PC_StartFoodTimer takes unit whichUnit, integer unitId, integer effectId returns nothing
    local timer t = NewTimer()
    set PC_ActiveFoodUnit[unitId] = whichUnit
    set PC_ActiveFoodEffect[unitId] = effectId
    set PC_ActiveFoodTimer[unitId] = t
    call SetTimerData(t, unitId)
    call TimerStart(t, PC_EffectDuration[effectId], false, function PC_FoodExpires)
    set t = null
endfunction

private function PC_StartBeverageTimer takes unit whichUnit, integer unitId, integer effectId returns nothing
    local timer t = NewTimer()
    set PC_ActiveBeverageUnit[unitId] = whichUnit
    set PC_ActiveBeverageEffect[unitId] = effectId
    set PC_ActiveBeverageTimer[unitId] = t
    call SetTimerData(t, unitId)
    call TimerStart(t, PC_EffectDuration[effectId], false, function PC_BeverageExpires)
    set t = null
endfunction

private function PC_ApplyFoodBuff takes unit whichUnit, integer unitId, integer effectId returns nothing
    call PC_RemoveFood(unitId)
    call PC_ApplyEffectStats(whichUnit, effectId, 1, false)
    call PC_AddEffectAura(whichUnit, effectId)
    call PC_StartFoodTimer(whichUnit, unitId, effectId)
endfunction

private function PC_ApplyDrinkBuff takes unit whichUnit, integer unitId, integer effectId returns nothing
    call PC_RemoveBeverage(unitId)
    call PC_ApplyEffectStats(whichUnit, effectId, 1, false)
    call PC_AddEffectAura(whichUnit, effectId)
    call PC_StartBeverageTimer(whichUnit, unitId, effectId)
endfunction

private function PC_ApplyConsumable takes unit whichUnit, integer effectId returns nothing
    local integer unitId = PC_GetUnitId(whichUnit)

    if whichUnit == null or effectId <= 0 or unitId <= 0 then
        return
    endif

    if PC_EffectIsBeverage[effectId] then
        call PC_ApplyDrinkBuff(whichUnit, unitId, effectId)
        if PC_EffectDrunkAmount[effectId] > 0.00 then
            call Drunk_Add(whichUnit, PC_EffectDrunkAmount[effectId], PC_EffectDuration[effectId])
        endif
    else
        call PC_ApplyFoodBuff(whichUnit, unitId, effectId)
    endif

    call PC_ShowEffectApplied(whichUnit, effectId)
endfunction

private function PC_HasActiveArrayStats takes unit whichUnit returns boolean
    local integer unitId = PC_GetUnitId(whichUnit)
    local integer effectId
    local integer slot
    local integer key

    if unitId <= 0 then
        return false
    endif

    set effectId = PC_ActiveFoodEffect[unitId]
    set slot = 1
    loop
        exitwhen effectId <= 0 or slot > PC_EffectStatCount[effectId]
        set key = effectId * PC_MAX_EFFECT_STATS + slot
        if PC_IsArrayBackedStat(PC_EffectStatType[key]) then
            return true
        endif
        set slot = slot + 1
    endloop

    set effectId = PC_ActiveBeverageEffect[unitId]
    set slot = 1
    loop
        exitwhen effectId <= 0 or slot > PC_EffectStatCount[effectId]
        set key = effectId * PC_MAX_EFFECT_STATS + slot
        if PC_IsArrayBackedStat(PC_EffectStatType[key]) then
            return true
        endif
        set slot = slot + 1
    endloop

    return false
endfunction

private function PC_ReapplyTimedArrayStats takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId = GetHandleId(t)
    local integer unitId = GetTimerData(t)
    local integer generation = PC_ReapplyTimerGeneration.integer[timerId]
    local unit whichUnit = PC_ReapplyUnit[unitId]

    call PC_ReapplyTimerGeneration.integer.remove(timerId)
    if generation == PC_ReapplyGeneration[unitId] and whichUnit != null then
        if PC_ActiveFoodEffect[unitId] > 0 then
            call PC_ApplyEffectStats(whichUnit, PC_ActiveFoodEffect[unitId], 1, true)
        endif
        if PC_ActiveBeverageEffect[unitId] > 0 then
            call PC_ApplyEffectStats(whichUnit, PC_ActiveBeverageEffect[unitId], 1, true)
        endif
        set PC_ReapplyUnit[unitId] = null
    endif

    call ReleaseTimer(t)
    set t = null
    set whichUnit = null
endfunction

private function PC_ScheduleTimedArrayReapply takes unit whichUnit returns nothing
    local integer unitId = PC_GetUnitId(whichUnit)
    local timer t

    if unitId <= 0 or not PC_HasActiveArrayStats(whichUnit) then
        return
    endif

    set PC_ReapplyGeneration[unitId] = PC_ReapplyGeneration[unitId] + 1
    set PC_ReapplyUnit[unitId] = whichUnit
    set t = NewTimer()
    call SetTimerData(t, unitId)
    set PC_ReapplyTimerGeneration.integer[GetHandleId(t)] = PC_ReapplyGeneration[unitId]
    call TimerStart(t, PC_UNITSTATS_REAPPLY_DELAY, false, function PC_ReapplyTimedArrayStats)
    set t = null
endfunction

private function PC_OnItemUse takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local item usedItem = GetManipulatedItem()
    local integer effectId = 0

    if usedItem != null then
        set effectId = PC_ItemEffect.integer[GetItemTypeId(usedItem)]
        if effectId > 0 then
            call PC_ApplyConsumable(whichUnit, effectId)
        endif
    endif

    set whichUnit = null
    set usedItem = null
endfunction

private function PC_OnItemDrop takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()

    static if LIBRARY_UnitStats then
        if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
            call PC_ScheduleTimedArrayReapply(whichUnit)
        endif
    endif

    set whichUnit = null
endfunction

private function PC_OnUnitDeath takes nothing returns nothing
    local unit dyingUnit = UnitDeathEvent_GetDyingUnit()
    local integer unitId = PC_GetUnitId(dyingUnit)

    if unitId > 0 then
        call PC_RemoveFood(unitId)
        call PC_RemoveBeverage(unitId)
        call Drunk_Clear(dyingUnit)
    endif

    set dyingUnit = null
endfunction

private function PC_RegisterEffects takes nothing returns nothing
    local integer effectId

    // Apprentice food: mostly better regeneration with small familiar stat bonuses.
    set effectId = PC_RegisterConsumable(PC_ITEM_SMOKED_WOLF_JERKY, "Smoked Wolf Jerky", "+1 Agility, +1 hit point regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_BRILLIANT_SMALLFISH, "Brilliant Smallfish", "+1 hit point regeneration and +25 maximum hit points for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 25.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_ROASTED_STAG_HAUNCH, "Roasted Stag Haunch", "+1 Strength and +50 maximum hit points for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 50.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SLITHERSKIN_MACKEREL, "Slitherskin Mackerel", "+35 maximum mana and +1 mana regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 35.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SPICED_SNAKE_STRIPS, "Spiced Snake Strips", "+2 Agility and +1 Critical Chance for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_BEAR_FAT_BISCUIT, "Bear Fat Biscuit", "+2 Strength, +100 maximum hit points, and +1 hit point regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 100.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_MUD_SNAPPER_CAKE, "Mud Snapper Cake", "+75 maximum hit points and +1 Dodge for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 75.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_BOILED_MAKRURA_CLAW, "Boiled Makrura Claw", "+2 Intelligence, +60 maximum mana, and +1 mana regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 60.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_FRIED_CRAWLER_CAKE, "Fried Crawler Cake", "+1 Armor, +1 Block, and +1 hit point regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_BLOCK, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_CHARRED_BOAR_RIBS, "Charred Boar Ribs", "+3 Strength and +3 Damage for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 3.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_RABBIT_BROTH, "Rabbit Broth", "+2 hit point regeneration, +1 Dodge, and +40 maximum mana for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 40.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_HAWK_SKEWER, "Hawk Skewer", "+3 Agility, +1 Hit, and +4 Damage for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_RAINBOW_ALBACORE, "Rainbow Albacore", "+2 Agility, +2 Hit, and +1 mana regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_TURTLE_STEW, "Turtle Stew", "+2 Armor, +2 Block, and +150 maximum hit points for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_BLOCK, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 150.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_CATFISH_CHOWDER, "Catfish Chowder", "+125 maximum hit points, +2 hit point regeneration, and +1 Armor for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 125.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_MURLOC_FIN_SOUP, "Murloc Fin Soup", "+3 Intelligence, +90 maximum mana, and +1 Spell Power for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 90.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_LOCH_FRENZY_DELIGHT, "Loch Frenzy Delight", "+2 Critical Chance, +2 Hit, and +4 Damage for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_LIZARD_PEPPER_ROAST, "Lizard Pepper Roast", "+3 Strength, +5 Damage, and +1 Critical Chance for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_FIREFIN_CHILI, "Firefin Chili", "+5 Spell Power, +2 Critical Chance, and -1 Armor for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_TIGER_STEAK, "Tiger Steak", "+5 Agility, +2 Critical Chance, and +7 Damage for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 7.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SAGEFISH_SOUP, "Sagefish Soup", "+4 Intelligence, +2 mana regeneration, and +5 Spell Power for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 5.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_PANTHER_FILLET, "Panther Fillet", "+5 Agility, +2 Dodge, and +12 movement speed for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_MOVEMENT_SPEED, 12.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_ROCKSCALE_COD, "Rockscale Cod", "+3 Armor, +2 Block, and +100 maximum hit points for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_BLOCK, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 100.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_RAPTOR_CHILI, "Raptor Chili", "+5 Strength, +8 Damage, +3 Critical Chance, and -1 Hit for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 8.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_MITHRIL_TROUT, "Mithril Head Trout", "+3 Block, +2 Armor, and +3 Hit for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_BLOCK, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 3.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_COW_RUMP_ROAST, "Cow Rump Roast", "+4 Strength, +250 maximum hit points, and +2 hit point regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 250.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 2.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SPOTTED_YELLOWTAIL, "Spotted Yellowtail", "+4 Agility, +3 Hit, and +10 movement speed for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_MOVEMENT_SPEED, 10.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_DEVIATE_DELIGHT, "Deviate Delight", "+4 Agility, +3 Dodge, -2 Intelligence, and +30 sight range for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -2.00)
    call PC_AddEffectStat(effectId, PC_STAT_SIGHT_RANGE, 30.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_GLOSSY_MIGHTFISH_STEAK, "Glossy Mightfish Steak", "+7 Strength, +12 Damage, and +4 Critical Chance for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 7.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 12.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_REDGILL_SKILLET, "Redgill Skillet", "+4 Critical Chance, +5 Hit, and +6 Damage for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 6.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_NIGHTFIN_SOUP, "Nightfin Soup", "+3 mana regeneration, +10 Spell Power, and +180 maximum mana for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 10.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 180.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SUNSCALE_FILLET, "Sunscale Fillet", "+4 hit point regeneration, +300 maximum hit points, and +2 Armor for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 300.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 2.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_COOKED_STONESCALE_EEL, "Stonescale Eel", "+4 Armor, +5 Block, and -8 movement speed for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_BLOCK, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_MOVEMENT_SPEED, -8.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_WHITESCALE_SALMON, "Whitescale Salmon", "+5% Spell Power, +250 maximum mana, and +4 Hit for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_PCT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 250.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_DARKCLAW_BISQUE, "Darkclaw Bisque", "+8 Strength, +300 maximum hit points, and +4 Armor for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 8.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 300.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_COOKED_WINTER_SQUID, "Winter Squid", "+8 Agility, +5 Critical Chance, and +6 Dodge for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, 8.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 6.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SUMMER_BASS, "Summer Bass", "+20 movement speed, +5 Hit, and +5 Dodge for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_MOVEMENT_SPEED, 20.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 5.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_TIGERSEYE_EEL, "Tigerseye Eel", "+25 Spell Power, +5 Dodge, and +5% Spell Power for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 25.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_PCT, 5.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_EMBER_WHELP_ROAST, "Ember Whelp Roast", "+20 Damage, +5% Spell Power, +5 Critical Chance, and -2 Armor for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 20.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_PCT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -2.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_PLAGUEBLOOM_DUMPLING, "Plaguebloom Dumpling", "+8 Critical Chance, +8 Spell Power, +40 sight range, and -2 hit point regeneration for 15 minutes.", PC_DEFAULT_FOOD_DURATION, false, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 8.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 8.00)
    call PC_AddEffectStat(effectId, PC_STAT_SIGHT_RANGE, 40.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, -2.00)

    // Beverages occupy the drink buff slot; only entries with drunk amount > 0.00 feed Drunk.j.
    set effectId = PC_RegisterConsumable(PC_ITEM_SPRINGWATER_TEA, "Springwater Tea", "+25 maximum mana and +1 mana regeneration for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 25.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_HONEYED_MILK, "Honeyed Milk", "+50 maximum hit points and -1 Intelligence for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 50.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_CACTUS_ALE, "Bitter Cactus Ale", "+1 Strength, -2 Intelligence, and -1 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.20)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -2.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_STOUT_MEAD, "Stout Mead", "+3 Strength, -2 Intelligence, and -1 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.35)
    call PC_AddEffectStat(effectId, PC_STAT_STRENGTH, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -2.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SALTED_MAKRURA_BROTH, "Salted Makrura Broth", "+1 mana regeneration, +60 maximum mana, and -1 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA, 60.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_BLACKMOUTH_GROG, "Blackmouth Grog", "+5 Damage, -2 Hit, and -3 Intelligence for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.45)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, -2.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -3.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_FIREFIN_WHISKEY, "Firefin Whiskey", "+3 Critical Chance, +6 Damage, -4 Intelligence, and -2 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.60)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 3.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 6.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -4.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -2.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_SAGEFISH_TONIC, "Sagefish Tonic", "+4 Intelligence, +1 mana regeneration, and -1 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_MANA_REGEN, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -1.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_DEVIATE_RUM, "Deviate Rum", "+5 Dodge, -5 Hit, +20 sight range, and -4 Intelligence for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.80)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, -5.00)
    call PC_AddEffectStat(effectId, PC_STAT_SIGHT_RANGE, 20.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_NIGHTFIN_WINE, "Nightfin Wine", "+15 Spell Power, -20 movement speed, and -2 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.50)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 15.00)
    call PC_AddEffectStat(effectId, PC_STAT_MOVEMENT_SPEED, -20.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -2.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_STONESCALE_PORTER, "Stonescale Porter", "+4 Armor, +4 Block, and -4 Agility for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.55)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_BLOCK, 4.00)
    call PC_AddEffectStat(effectId, PC_STAT_AGILITY, -4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_LOBSTER_CUP, "Lobster Bisque Cup", "+200 maximum hit points, +2 hit point regeneration, and -3 Intelligence for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINTS, 200.00)
    call PC_AddEffectStat(effectId, PC_STAT_HITPOINT_REGEN, 2.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -3.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_DRAGONFIRE_PUNCH, "Dragonfire Punch", "+20 Damage, +5 Critical Chance, -5 Intelligence, and -4 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 0.90)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 20.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 5.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -5.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -4.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_WINTER_ABSINTHE, "Winter Squid Absinthe", "+10% Spell Power, +10 Spell Power, -5 Hit, and -6 Intelligence for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_PCT, 10.00)
    call PC_AddEffectStat(effectId, PC_STAT_SPELL_POWER_FLAT, 10.00)
    call PC_AddEffectStat(effectId, PC_STAT_HIT, -5.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -6.00)

    set effectId = PC_RegisterConsumable(PC_ITEM_BAD_IDEAS_BREW, "Brew of Bad Ideas", "+10 Critical Chance, +10 Damage, -10 Intelligence, -5 Dodge, and -5 Armor for 10 minutes.", PC_DEFAULT_BEVERAGE_DURATION, true, 1.00)
    call PC_AddEffectStat(effectId, PC_STAT_CRIT, 10.00)
    call PC_AddEffectStat(effectId, PC_STAT_DAMAGE, 10.00)
    call PC_AddEffectStat(effectId, PC_STAT_INTELLIGENCE, -10.00)
    call PC_AddEffectStat(effectId, PC_STAT_DODGE, -5.00)
    call PC_AddEffectStat(effectId, PC_STAT_ARMOR, -5.00)
endfunction

private function PC_RegisterAuraRawcodes takes nothing returns nothing
    // Recipe-specific aura abilities keep Object Editor buff text/icons stable per unit.
    call PC_SetAuraByItem(PC_ITEM_SMOKED_WOLF_JERKY, 'S003')
    call PC_SetAuraByItem(PC_ITEM_BRILLIANT_SMALLFISH, 'S004')
    call PC_SetAuraByItem(PC_ITEM_ROASTED_STAG_HAUNCH, 'S005')
    call PC_SetAuraByItem(PC_ITEM_SLITHERSKIN_MACKEREL, 'S006')
    call PC_SetAuraByItem(PC_ITEM_SPICED_SNAKE_STRIPS, 'S007')
    call PC_SetAuraByItem(PC_ITEM_BEAR_FAT_BISCUIT, 'S008')
    call PC_SetAuraByItem(PC_ITEM_MUD_SNAPPER_CAKE, 'S009')
    call PC_SetAuraByItem(PC_ITEM_BOILED_MAKRURA_CLAW, 'S00A')
    call PC_SetAuraByItem(PC_ITEM_FRIED_CRAWLER_CAKE, 'S00B')
    call PC_SetAuraByItem(PC_ITEM_CHARRED_BOAR_RIBS, 'S00C')
    call PC_SetAuraByItem(PC_ITEM_RABBIT_BROTH, 'S00D')
    call PC_SetAuraByItem(PC_ITEM_HAWK_SKEWER, 'S00E')
    call PC_SetAuraByItem(PC_ITEM_RAINBOW_ALBACORE, 'S00F')
    call PC_SetAuraByItem(PC_ITEM_TURTLE_STEW, 'S00G')
    call PC_SetAuraByItem(PC_ITEM_CATFISH_CHOWDER, 'S00H')
    call PC_SetAuraByItem(PC_ITEM_MURLOC_FIN_SOUP, 'S001')
    call PC_SetAuraByItem(PC_ITEM_LOCH_FRENZY_DELIGHT, 'S00J')
    call PC_SetAuraByItem(PC_ITEM_LIZARD_PEPPER_ROAST, 'S00K')
    call PC_SetAuraByItem(PC_ITEM_FIREFIN_CHILI, 'S00L')
    call PC_SetAuraByItem(PC_ITEM_TIGER_STEAK, 'S00M')
    call PC_SetAuraByItem(PC_ITEM_SAGEFISH_SOUP, 'S00N')
    call PC_SetAuraByItem(PC_ITEM_PANTHER_FILLET, 'S000')
    call PC_SetAuraByItem(PC_ITEM_ROCKSCALE_COD, 'S00P')
    call PC_SetAuraByItem(PC_ITEM_RAPTOR_CHILI, 'S00Q')
    call PC_SetAuraByItem(PC_ITEM_MITHRIL_TROUT, 'S00R')
    call PC_SetAuraByItem(PC_ITEM_COW_RUMP_ROAST, 'S00S')
    call PC_SetAuraByItem(PC_ITEM_SPOTTED_YELLOWTAIL, 'S00T')
    call PC_SetAuraByItem(PC_ITEM_DEVIATE_DELIGHT, 'S00U')
    call PC_SetAuraByItem(PC_ITEM_GLOSSY_MIGHTFISH_STEAK, 'S00V')
    call PC_SetAuraByItem(PC_ITEM_REDGILL_SKILLET, 'S00W')
    call PC_SetAuraByItem(PC_ITEM_NIGHTFIN_SOUP, 'S00X')
    call PC_SetAuraByItem(PC_ITEM_SUNSCALE_FILLET, 'S00Y')
    call PC_SetAuraByItem(PC_ITEM_COOKED_STONESCALE_EEL, 'S00Z')
    call PC_SetAuraByItem(PC_ITEM_WHITESCALE_SALMON, 'S010')
    call PC_SetAuraByItem(PC_ITEM_DARKCLAW_BISQUE, 'S011')
    call PC_SetAuraByItem(PC_ITEM_COOKED_WINTER_SQUID, 'S012')
    call PC_SetAuraByItem(PC_ITEM_SUMMER_BASS, 'S013')
    call PC_SetAuraByItem(PC_ITEM_EMBER_WHELP_ROAST, 'S014')
    call PC_SetAuraByItem(PC_ITEM_PLAGUEBLOOM_DUMPLING, 'S015')
    call PC_SetAuraByItem(PC_ITEM_TIGERSEYE_EEL, 'S016')

    call PC_SetAuraByItem(PC_ITEM_SPRINGWATER_TEA, 'S017')
    call PC_SetAuraByItem(PC_ITEM_HONEYED_MILK, 'S018')
    call PC_SetAuraByItem(PC_ITEM_CACTUS_ALE, 'S019')
    call PC_SetAuraByItem(PC_ITEM_STOUT_MEAD, 'S01A')
    call PC_SetAuraByItem(PC_ITEM_SALTED_MAKRURA_BROTH, 'S01B')
    call PC_SetAuraByItem(PC_ITEM_BLACKMOUTH_GROG, 'S01C')
    call PC_SetAuraByItem(PC_ITEM_FIREFIN_WHISKEY, 'S01D')
    call PC_SetAuraByItem(PC_ITEM_SAGEFISH_TONIC, 'S01E')
    call PC_SetAuraByItem(PC_ITEM_DEVIATE_RUM, 'S01F')
    call PC_SetAuraByItem(PC_ITEM_NIGHTFIN_WINE, 'S01G')
    call PC_SetAuraByItem(PC_ITEM_STONESCALE_PORTER, 'S01H')
    call PC_SetAuraByItem(PC_ITEM_LOBSTER_CUP, 'S01I')
    call PC_SetAuraByItem(PC_ITEM_DRAGONFIRE_PUNCH, 'S01J')
    call PC_SetAuraByItem(PC_ITEM_WINTER_ABSINTHE, 'S01K')
    call PC_SetAuraByItem(PC_ITEM_BAD_IDEAS_BREW, 'S01L')
endfunction

private function PC_RegisterRecipes takes nothing returns nothing
    local integer recipeId

    // Apprentice 0-25.
    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Smoked Wolf Jerky", "Smokes wolf meat into compact trail food.", PC_ICON_MEAT, PC_ITEM_SMOKED_WOLF_JERKY, 0, 4.00)
    call PC_Add(recipeId, PC_ITEM_RAW_WOLF_MEAT, 1, "Raw Wolf Meat")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Brilliant Smallfish", "Pan-fries smallfish with a pinch of salt.", PC_ICON_FISH, PC_ITEM_BRILLIANT_SMALLFISH, 1, 3.00)
    call PC_Add(recipeId, PC_ITEM_RAW_SMALLFISH, 1, "Raw Brilliant Smallfish")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Roasted Stag Haunch", "Roasts stag meat into a hearty haunch.", PC_ICON_ROAST, PC_ITEM_ROASTED_STAG_HAUNCH, 3, 4.00)
    call PC_Add(recipeId, PC_ITEM_RAW_STAG_MEAT, 2, "Raw Stag Meat")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Slitherskin Mackerel", "Cooks mackerel over open flame until the skin crisps.", PC_ICON_FISH, PC_ITEM_SLITHERSKIN_MACKEREL, 5, 3.00)
    call PC_Add(recipeId, PC_ITEM_RAW_MACKEREL, 1, "Raw Slitherskin Mackerel")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Spiced Snake Strips", "Cooks snake meat into salted strips.", PC_ICON_MEAT, PC_ITEM_SPICED_SNAKE_STRIPS, 8, 4.00)
    call PC_Add(recipeId, PC_ITEM_RAW_SNAKE_MEAT, 1, "Raw Snake Meat")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Bear Fat Biscuit", "Bakes bear meat with flour, water, and salt into a filling biscuit.", PC_ICON_ROAST, PC_ITEM_BEAR_FAT_BISCUIT, 13, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_BEAR_MEAT, 1, "Raw Bear Meat")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Mud Snapper Cake", "Binds mud snapper with flour into a simple fish cake.", PC_ICON_FISH, PC_ITEM_MUD_SNAPPER_CAKE, 17, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_MUD_SNAPPER, 1, "Raw Longjaw Mud Snapper")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Boiled Makrura Claw", "Boils makrura meat into a briny campfire meal.", PC_ICON_STEW, PC_ITEM_BOILED_MAKRURA_CLAW, 18, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_MAKRURA_MEAT, 1, "Raw Makrura Meat")
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_FOOD, "Fried Crawler Cake", "Fries crawler meat into a salted shellfish cake.", PC_ICON_FISH, PC_ITEM_FRIED_CRAWLER_CAKE, 22, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_CRAWLER_MEAT, 2, "Raw Crawler Meat")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")

    // Journeyman 25-50.
    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Charred Boar Ribs", "Chars boar ribs with salt and pepper.", PC_ICON_ROAST, PC_ITEM_CHARRED_BOAR_RIBS, 25, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_BOAR_MEAT, 2, "Raw Boar Meat")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Rabbit Broth", "Simmered rabbit broth with a gentle herbal finish.", PC_ICON_STEW, PC_ITEM_RABBIT_BROTH, 27, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_RABBIT_MEAT, 1, "Raw Rabbit Meat")
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")
    call PC_Add(recipeId, PC_ITEM_PEACEBLOOM, 1, "Peacebloom")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Hawk Skewer", "Skewers hawk meat with pepper and honey glaze.", PC_ICON_MEAT, PC_ITEM_HAWK_SKEWER, 30, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_HAWK_MEAT, 2, "Raw Hawk Meat")
    call PC_Add(recipeId, PC_ITEM_HONEY, 1, "Honey")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Rainbow Albacore", "Grills albacore with salt and bright herbs.", PC_ICON_FISH, PC_ITEM_RAINBOW_ALBACORE, 32, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_ALBACORE, 1, "Raw Rainbow Fin Albacore")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")
    call PC_Add(recipeId, PC_ITEM_PEACEBLOOM, 1, "Peacebloom")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Turtle Stew", "A thick stew of turtle meat and salted broth.", PC_ICON_STEW, PC_ITEM_TURTLE_STEW, 33, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_TURTLE_MEAT, 2, "Raw Turtle Meat")
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Catfish Chowder", "A heavy catfish chowder thickened with flour.", PC_ICON_STEW, PC_ITEM_CATFISH_CHOWDER, 37, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_CATFISH, 1, "Raw Bristle Whisker Catfish")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Murloc Fin Soup", "Boils murloc fins in a sharp sea-salt broth.", PC_ICON_STEW, PC_ITEM_MURLOC_FIN_SOUP, 40, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_MURLOC_MEAT, 1, "Raw Murloc Meat")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")
    call PC_Add(recipeId, PC_ITEM_CRYSTAL_WATER, 1, "Crystal Water")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Loch Frenzy Delight", "Pan-fries loch frenzy with peppercorn.", PC_ICON_FISH, PC_ITEM_LOCH_FRENZY_DELIGHT, 42, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_LOCH_FRENZY, 1, "Raw Loch Frenzy")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Lizard Pepper Roast", "Roasts lizard meat with extra pepper.", PC_ICON_ROAST, PC_ITEM_LIZARD_PEPPER_ROAST, 43, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_LIZARD_MEAT, 2, "Raw Lizard Meat")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 2, "Peppercorn")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_FOOD, "Firefin Chili", "A dangerous chili built around Firefin Snapper.", PC_ICON_STEW, PC_ITEM_FIREFIN_CHILI, 47, 6.00)
    call PC_Add(recipeId, PC_ITEM_FIREFIN_SNAPPER, 1, "Firefin Snapper")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 2, "Peppercorn")
    call PC_Add(recipeId, PC_ITEM_CACTUS_PULP, 1, "Cactus Pulp")

    // Expert 50-75.
    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Tiger Steak", "Sears tiger meat hard and fast over the fire.", PC_ICON_ROAST, PC_ITEM_TIGER_STEAK, 50, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_TIGER_MEAT, 2, "Raw Tiger Meat")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")
    call PC_Add(recipeId, PC_ITEM_HONEY, 1, "Honey")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Sagefish Soup", "A clear soup that preserves sagefish oils.", PC_ICON_STEW, PC_ITEM_SAGEFISH_SOUP, 52, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_SAGEFISH, 1, "Raw Sagefish")
    call PC_Add(recipeId, PC_ITEM_PURIFIED_WATER, 1, "Purified Water")
    call PC_Add(recipeId, PC_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Panther Fillet", "Smokes panther fillet until it stays tender.", PC_ICON_MEAT, PC_ITEM_PANTHER_FILLET, 55, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_PANTHER_MEAT, 2, "Raw Panther Meat")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")
    call PC_Add(recipeId, PC_ITEM_SOUR_BERRIES, 1, "Sour Berries")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Rockscale Cod", "Roasts cod until the scales crack into a salty crust.", PC_ICON_FISH, PC_ITEM_ROCKSCALE_COD, 57, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_ROCKSCALE_COD, 1, "Raw Rockscale Cod")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Raptor Chili", "A fast-burning chili with raptor meat and cactus pulp.", PC_ICON_STEW, PC_ITEM_RAPTOR_CHILI, 60, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_RAPTOR_MEAT, 2, "Raw Raptor Meat")
    call PC_Add(recipeId, PC_ITEM_CACTUS_PULP, 1, "Cactus Pulp")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 2, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Mithril Head Trout", "Crisps trout in a salt-heavy pan.", PC_ICON_FISH, PC_ITEM_MITHRIL_TROUT, 63, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_MITHRIL_TROUT, 1, "Raw Mithril Head Trout")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")
    call PC_Add(recipeId, PC_ITEM_BRUISEWEED, 1, "Bruiseweed")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Cow Rump Roast", "A large roast that needs time and a steady fire.", PC_ICON_ROAST, PC_ITEM_COW_RUMP_ROAST, 67, 7.00)
    call PC_Add(recipeId, PC_ITEM_RAW_COW_MEAT, 2, "Raw Cow Meat")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_HONEY, 1, "Honey")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Spotted Yellowtail", "Grills yellowtail with sour berries.", PC_ICON_FISH, PC_ITEM_SPOTTED_YELLOWTAIL, 68, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_SPOTTED_YELLOWTAIL, 1, "Raw Spotted Yellowtail")
    call PC_Add(recipeId, PC_ITEM_SOUR_BERRIES, 1, "Sour Berries")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_FOOD, "Deviate Delight", "Prepares Deviate Fish into an unpredictable meal.", PC_ICON_ODDITY, PC_ITEM_DEVIATE_DELIGHT, 72, 7.00)
    call PC_Add(recipeId, PC_ITEM_DEVIATE_FISH, 1, "Deviate Fish")
    call PC_Add(recipeId, PC_ITEM_GLOWCAP, 1, "Glowcap")
    call PC_Add(recipeId, PC_ITEM_SOUR_BERRIES, 1, "Sour Berries")

    // Artisan 75-100.
    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Glossy Mightfish Steak", "A dense steak from Glossy Mightfish.", PC_ICON_FISH, PC_ITEM_GLOSSY_MIGHTFISH_STEAK, 75, 7.00)
    call PC_Add(recipeId, PC_ITEM_RAW_GLOSSY_MIGHTFISH, 1, "Raw Glossy Mightfish")
    call PC_Add(recipeId, PC_ITEM_HONEY, 1, "Honey")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Redgill Skillet", "Skillet-cooks redgill with pepper and blindweed.", PC_ICON_FISH, PC_ITEM_REDGILL_SKILLET, 77, 7.00)
    call PC_Add(recipeId, PC_ITEM_RAW_REDGILL, 1, "Raw Redgill")
    call PC_Add(recipeId, PC_ITEM_BLINDWEED, 1, "Blindweed")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Nightfin Soup", "A deep nightfin soup for patient casters.", PC_ICON_STEW, PC_ITEM_NIGHTFIN_SOUP, 80, 7.00)
    call PC_Add(recipeId, PC_ITEM_NIGHTFIN_SNAPPER, 1, "Nightfin Snapper")
    call PC_Add(recipeId, PC_ITEM_PURIFIED_WATER, 1, "Purified Water")
    call PC_Add(recipeId, PC_ITEM_LIFEROOT, 1, "Liferoot")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Sunscale Fillet", "A bright salmon fillet cooked with liferoot.", PC_ICON_FISH, PC_ITEM_SUNSCALE_FILLET, 82, 7.00)
    call PC_Add(recipeId, PC_ITEM_SUNSCALE_SALMON, 1, "Sunscale Salmon")
    call PC_Add(recipeId, PC_ITEM_LIFEROOT, 1, "Liferoot")
    call PC_Add(recipeId, PC_ITEM_HONEY, 1, "Honey")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Stonescale Eel", "Charred eel with a mineral-heavy crust.", PC_ICON_FISH, PC_ITEM_COOKED_STONESCALE_EEL, 83, 7.00)
    call PC_Add(recipeId, PC_ITEM_RAW_STONESCALE_EEL, 1, "Stonescale Eel")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")
    call PC_Add(recipeId, PC_ITEM_ICECAP_SHAVINGS, 1, "Icecap Shavings")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Whitescale Salmon", "A refined salmon meal with silversage.", PC_ICON_FISH, PC_ITEM_WHITESCALE_SALMON, 87, 7.00)
    call PC_Add(recipeId, PC_ITEM_RAW_WHITESCALE_SALMON, 1, "Raw Whitescale Salmon")
    call PC_Add(recipeId, PC_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")
    call PC_Add(recipeId, PC_ITEM_PURIFIED_WATER, 1, "Purified Water")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Darkclaw Bisque", "A rich lobster bisque with a bite.", PC_ICON_STEW, PC_ITEM_DARKCLAW_BISQUE, 90, 8.00)
    call PC_Add(recipeId, PC_ITEM_DARKCLAW_LOBSTER, 1, "Darkclaw Lobster")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_PURIFIED_WATER, 1, "Purified Water")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 1, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Winter Squid", "Cold-prepped squid finished over flame.", PC_ICON_FISH, PC_ITEM_COOKED_WINTER_SQUID, 93, 8.00)
    call PC_Add(recipeId, PC_ITEM_RAW_WINTER_SQUID, 1, "Winter Squid")
    call PC_Add(recipeId, PC_ITEM_ICECAP_SHAVINGS, 1, "Icecap Shavings")
    call PC_Add(recipeId, PC_ITEM_SOUR_BERRIES, 1, "Sour Berries")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Summer Bass", "A quick bass dish that keeps the feet light.", PC_ICON_FISH, PC_ITEM_SUMMER_BASS, 97, 8.00)
    call PC_Add(recipeId, PC_ITEM_RAW_SUMMER_BASS, 1, "Raw Summer Bass")
    call PC_Add(recipeId, PC_ITEM_AGAVE, 1, "Agave")
    call PC_Add(recipeId, PC_ITEM_SALT, 1, "Salt")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Ember Whelp Roast", "An illegal-looking roast seasoned like dragonfire.", PC_ICON_ODDITY, PC_ITEM_EMBER_WHELP_ROAST, 95, 8.00)
    call PC_Add(recipeId, PC_ITEM_RAW_RAPTOR_MEAT, 2, "Raw Raptor Meat")
    call PC_Add(recipeId, PC_ITEM_GROMSBLOOD, 1, "Gromsblood")
    call PC_Add(recipeId, PC_ITEM_FIREFIN_SNAPPER, 1, "Firefin Snapper")
    call PC_Add(recipeId, PC_ITEM_COOKING_PEPPERCORN, 2, "Peppercorn")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Plaguebloom Dumpling", "A risky dumpling that should probably be labeled.", PC_ICON_ODDITY, PC_ITEM_PLAGUEBLOOM_DUMPLING, 98, 8.00)
    call PC_Add(recipeId, PC_ITEM_PLAGUEBLOOM, 1, "Plaguebloom")
    call PC_Add(recipeId, PC_ITEM_COARSE_FLOUR, 1, "Coarse Flour")
    call PC_Add(recipeId, PC_ITEM_SICKLY_FISH, 1, "Sickly Looking Fish")
    call PC_Add(recipeId, PC_ITEM_GLOWCAP, 1, "Glowcap")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_FOOD, "Tigerseye Eel", "A strange eel dish that sharpens spell focus.", PC_ICON_ODDITY, PC_ITEM_TIGERSEYE_EEL, 100, 8.00)
    call PC_Add(recipeId, PC_ITEM_RAW_TIGERSEYE_EEL, 1, "Raw Tigerseye Eel")
    call PC_Add(recipeId, PC_ITEM_GLOWCAP, 1, "Glowcap")
    call PC_Add(recipeId, PC_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")

    // Beverages.
    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_BEVERAGES, "Springwater Tea", "Brews spring water with a pinch of peacebloom.", PC_ICON_DRINK, PC_ITEM_SPRINGWATER_TEA, 1, 3.00)
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")
    call PC_Add(recipeId, PC_ITEM_PEACEBLOOM, 1, "Peacebloom")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_BEVERAGES, "Honeyed Milk", "A gentle drink that still dulls the mind a little.", PC_ICON_DRINK, PC_ITEM_HONEYED_MILK, 7, 3.00)
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")
    call PC_Add(recipeId, PC_ITEM_HONEY, 1, "Honey")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_APPRENTICE, PC_SUBCATEGORY_BEVERAGES, "Bitter Cactus Ale", "Ferments cactus pulp into a sharp ale.", PC_ICON_DRINK, PC_ITEM_CACTUS_ALE, 15, 4.00)
    call PC_Add(recipeId, PC_ITEM_CACTUS_PULP, 1, "Cactus Pulp")
    call PC_Add(recipeId, PC_ITEM_BAKER_YEAST, 1, "Baker's Yeast")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_BEVERAGES, "Stout Mead", "Ferments honey into a heavy mead.", PC_ICON_DRINK, PC_ITEM_STOUT_MEAD, 25, 4.00)
    call PC_Add(recipeId, PC_ITEM_HONEY, 2, "Honey")
    call PC_Add(recipeId, PC_ITEM_BAKER_YEAST, 1, "Baker's Yeast")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_BEVERAGES, "Salted Makrura Broth", "A drinkable broth that tastes like the shoreline.", PC_ICON_DRINK, PC_ITEM_SALTED_MAKRURA_BROTH, 30, 4.00)
    call PC_Add(recipeId, PC_ITEM_RAW_MAKRURA_MEAT, 1, "Raw Makrura Meat")
    call PC_Add(recipeId, PC_ITEM_SEA_SALT_GLAND, 1, "Sea-Salt Gland")
    call PC_Add(recipeId, PC_ITEM_SPRING_WATER, 1, "Spring Water")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_JOURNEYMAN, PC_SUBCATEGORY_BEVERAGES, "Blackmouth Grog", "Distills oily blackmouth into murky grog.", PC_ICON_DRINK, PC_ITEM_BLACKMOUTH_GROG, 40, 5.00)
    call PC_Add(recipeId, PC_ITEM_OILY_BLACKMOUTH, 1, "Oily Blackmouth")
    call PC_Add(recipeId, PC_ITEM_BITTER_HOPS, 1, "Bitter Hops")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_BEVERAGES, "Firefin Whiskey", "A reckless whiskey warmed with Firefin oil.", PC_ICON_DRINK, PC_ITEM_FIREFIN_WHISKEY, 50, 5.00)
    call PC_Add(recipeId, PC_ITEM_FIREFIN_SNAPPER, 1, "Firefin Snapper")
    call PC_Add(recipeId, PC_ITEM_BITTER_HOPS, 1, "Bitter Hops")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_BEVERAGES, "Sagefish Tonic", "A clear tonic for focused casters.", PC_ICON_DRINK, PC_ITEM_SAGEFISH_TONIC, 58, 5.00)
    call PC_Add(recipeId, PC_ITEM_RAW_SAGEFISH, 1, "Raw Sagefish")
    call PC_Add(recipeId, PC_ITEM_MOUNTAIN_SILVERSAGE, 1, "Mountain Silversage")
    call PC_Add(recipeId, PC_ITEM_PURIFIED_WATER, 1, "Purified Water")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_EXPERT, PC_SUBCATEGORY_BEVERAGES, "Deviate Rum", "A volatile rum that refuses to behave.", PC_ICON_DRINK, PC_ITEM_DEVIATE_RUM, 67, 5.00)
    call PC_Add(recipeId, PC_ITEM_DEVIATE_FISH, 1, "Deviate Fish")
    call PC_Add(recipeId, PC_ITEM_GLOWCAP, 1, "Glowcap")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_BEVERAGES, "Nightfin Wine", "A dark wine strained through nightfin oil.", PC_ICON_DRINK, PC_ITEM_NIGHTFIN_WINE, 75, 6.00)
    call PC_Add(recipeId, PC_ITEM_NIGHTFIN_SNAPPER, 1, "Nightfin Snapper")
    call PC_Add(recipeId, PC_ITEM_SOUR_BERRIES, 1, "Sour Berries")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_BEVERAGES, "Stonescale Porter", "A heavy porter with mineral bitterness.", PC_ICON_DRINK, PC_ITEM_STONESCALE_PORTER, 83, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_STONESCALE_EEL, 1, "Stonescale Eel")
    call PC_Add(recipeId, PC_ITEM_BITTER_HOPS, 1, "Bitter Hops")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_BEVERAGES, "Lobster Bisque Cup", "Serves darkclaw bisque as a drinkable travel ration.", PC_ICON_DRINK, PC_ITEM_LOBSTER_CUP, 90, 6.00)
    call PC_Add(recipeId, PC_ITEM_DARKCLAW_LOBSTER, 1, "Darkclaw Lobster")
    call PC_Add(recipeId, PC_ITEM_PURIFIED_WATER, 1, "Purified Water")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_BEVERAGES, "Dragonfire Punch", "A hot punch no sensible cook serves twice.", PC_ICON_DRINK, PC_ITEM_DRAGONFIRE_PUNCH, 95, 6.00)
    call PC_Add(recipeId, PC_ITEM_FIREFIN_SNAPPER, 1, "Firefin Snapper")
    call PC_Add(recipeId, PC_ITEM_GROMSBLOOD, 1, "Gromsblood")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_BEVERAGES, "Winter Squid Absinthe", "A bright, cold drink that bends aim and spell focus.", PC_ICON_DRINK, PC_ITEM_WINTER_ABSINTHE, 98, 6.00)
    call PC_Add(recipeId, PC_ITEM_RAW_WINTER_SQUID, 1, "Winter Squid")
    call PC_Add(recipeId, PC_ITEM_ICECAP_SHAVINGS, 1, "Icecap Shavings")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")

    set recipeId = PC_RegisterRecipe(PC_CATEGORY_ARTISAN, PC_SUBCATEGORY_BEVERAGES, "Brew of Bad Ideas", "A deliberately bad drink for very confident cooks.", PC_ICON_DRINK, PC_ITEM_BAD_IDEAS_BREW, 100, 6.00)
    call PC_Add(recipeId, PC_ITEM_PLAGUEBLOOM, 1, "Plaguebloom")
    call PC_Add(recipeId, PC_ITEM_GLOWCAP, 1, "Glowcap")
    call PC_Add(recipeId, PC_ITEM_BITTER_HOPS, 1, "Bitter Hops")
    call PC_Add(recipeId, PC_ITEM_EMPTY_BOTTLE, 1, "Empty Bottle")
endfunction

private function PC_GetEffectIdByItem takes integer itemCode returns integer
    if PC_ItemEffect == 0 then
        return 0
    endif
    return PC_ItemEffect.integer[itemCode]
endfunction

private function PC_GetAuraAbilityByItem takes integer itemCode returns integer
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    if effectId > 0 then
        return PC_EffectAuraAbility[effectId]
    endif
    return 0
endfunction

private function PC_GetEffectTextByItem takes integer itemCode returns string
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    if effectId > 0 then
        return PC_EffectText[effectId]
    endif
    return ""
endfunction

public function IsCookingConsumable takes integer itemCode returns boolean
    return PC_GetEffectIdByItem(itemCode) > 0
endfunction

public function IsCookingFood takes integer itemCode returns boolean
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    return effectId > 0 and not PC_EffectIsBeverage[effectId]
endfunction

public function IsCookingDrink takes integer itemCode returns boolean
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    return effectId > 0 and PC_EffectIsBeverage[effectId]
endfunction

public function IsCookingIntoxicatingDrink takes integer itemCode returns boolean
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    return effectId > 0 and PC_EffectIsBeverage[effectId] and PC_EffectDrunkAmount[effectId] > 0.00
endfunction

public function GetCookingAuraAbility takes integer itemCode returns integer
    return PC_GetAuraAbilityByItem(itemCode)
endfunction

public function GetFoodAuraAbility takes integer itemCode returns integer
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    if effectId > 0 and not PC_EffectIsBeverage[effectId] then
        return PC_EffectAuraAbility[effectId]
    endif
    return 0
endfunction

public function GetDrinkAuraAbility takes integer itemCode returns integer
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    if effectId > 0 and PC_EffectIsBeverage[effectId] then
        return PC_EffectAuraAbility[effectId]
    endif
    return 0
endfunction

public function GetCookingEffectText takes integer itemCode returns string
    return PC_GetEffectTextByItem(itemCode)
endfunction

public function GetFoodEffectText takes integer itemCode returns string
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    if effectId > 0 and not PC_EffectIsBeverage[effectId] then
        return PC_EffectText[effectId]
    endif
    return ""
endfunction

public function GetDrinkEffectText takes integer itemCode returns string
    local integer effectId = PC_GetEffectIdByItem(itemCode)

    if effectId > 0 and PC_EffectIsBeverage[effectId] then
        return PC_EffectText[effectId]
    endif
    return ""
endfunction

public function GetActiveFoodAuraAbility takes unit whichUnit returns integer
    local integer unitId = PC_GetUnitId(whichUnit)

    if unitId > 0 and PC_ActiveFoodEffect[unitId] > 0 then
        return PC_EffectAuraAbility[PC_ActiveFoodEffect[unitId]]
    endif
    return 0
endfunction

public function GetActiveDrinkAuraAbility takes unit whichUnit returns integer
    local integer unitId = PC_GetUnitId(whichUnit)

    if unitId > 0 and PC_ActiveBeverageEffect[unitId] > 0 then
        return PC_EffectAuraAbility[PC_ActiveBeverageEffect[unitId]]
    endif
    return 0
endfunction

public function GetActiveFoodEffectText takes unit whichUnit returns string
    local integer unitId = PC_GetUnitId(whichUnit)

    if unitId > 0 and PC_ActiveFoodEffect[unitId] > 0 then
        return PC_EffectText[PC_ActiveFoodEffect[unitId]]
    endif
    return ""
endfunction

public function GetActiveDrinkEffectText takes unit whichUnit returns string
    local integer unitId = PC_GetUnitId(whichUnit)

    if unitId > 0 and PC_ActiveBeverageEffect[unitId] > 0 then
        return PC_EffectText[PC_ActiveBeverageEffect[unitId]]
    endif
    return ""
endfunction

public function Init takes nothing returns nothing
    if PC_Initialized then
        return
    endif
    set PC_Initialized = true

    set PC_ItemEffect = Table.create()
    set PC_ReapplyTimerGeneration = Table.create()

    call Professions_RegisterStationType(GNS_PROF_COOKING, PC_STATION_CAMP_FIRE, "Camp Fire")
    call Professions_SetProfessionSoundLabels(GNS_PROF_COOKING, PC_SOUND_START, PC_SOUND_LOOP, PC_SOUND_FINISH)
    call Professions_SetProfessionSoundHandles(GNS_PROF_COOKING, Interface_Profession_Cooking_Start, Interface_Profession_Cooking_Loop, Interface_Profession_Cooking_End)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_COOKING, PC_AI_CHEAT_CRAFTING)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_COOKING, PC_CRAFTER_ANIMATION_PRIMARY, PC_CRAFTER_ANIMATION_FALLBACK)

    call PC_RegisterEffects()
    call PC_RegisterAuraRawcodes()
    call PC_RegisterRecipes()
    call Events_RegisterPlayerUnitEvent(function PC_OnItemUse, EVENT_PLAYER_UNIT_USE_ITEM)
    call Events_RegisterPlayerUnitEvent(function PC_OnItemDrop, EVENT_PLAYER_UNIT_DROP_ITEM)
    call UnitDeathEvent_Register(function PC_OnUnitDeath)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
