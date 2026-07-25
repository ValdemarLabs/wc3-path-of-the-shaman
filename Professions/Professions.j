/**
    Professions

    Author: Valdemar
    Version: 1.0

    Description: Central registry and executor for profession crafting recipes, workstation definitions, materials, sounds, and completion feedback.

    Credits:

    How to install:
    Import this library after GatherNodeSkills, TimerUtils, and Table. Profession sublibraries register stations and recipes through this API.

    API:
    call Professions_RegisterStationType(GNS_PROF_ALCHEMY, 'n61D', "Cauldron")
    set recipeId = Professions_RegisterRecipe(GNS_PROF_ALCHEMY, 'n61D', "Spring Water", "Creates spring water.", "ReplaceableTextures\\CommandButtons\\BTNPotionGreenSmall.blp", 'I60Z', 1, 0, 5.00, 0.00)
    call Professions_AddRecipeMaterial(recipeId, 'I60W', 1, "Agave")
    call Professions_SetRecipeSkillGain(recipeId, 1)
    call Professions_SetProfessionSoundLabels(GNS_PROF_ALCHEMY, "Alchemy start", "Alchemy loop", "Alchemy loop")
    call Professions_SetProfessionSoundHandles(GNS_PROF_ALCHEMY, Interface_Profession_Alchemy_Start, Interface_Profession_Alchemy_Loop, Interface_Profession_Alchemy_End)
    call Professions_SetProfessionSoundPaths(GNS_PROF_ALCHEMY, Interface_Profession_Alchemy_StartPath, Interface_Profession_Alchemy_LoopPath, Interface_Profession_Alchemy_EndPath)
    call Professions_SetProfessionAiCheatCrafting(GNS_PROF_ALCHEMY, true)
    call Professions_SetProfessionCrafterAnimations(GNS_PROF_ALCHEMY, "stand work", "spell")
    call Professions_SetProfessionCrafterAnimationsForUnitType(GNS_PROF_ALCHEMY, 'H000', "spell", "stand")
    call Professions_SetRecipeCategory(recipeId, "Basic Alchemy")
    call Professions_SetRecipeCategoryPath(recipeId, "Apprentice Blacksmithing", "Copper Armor")
    call Professions_StartRecipe(whichCrafter, whichStation, recipeId)
    call Professions_StartRecipeForAi(whichCrafter, whichStation, recipeId)
    set wasCancelled = Professions_CancelUnitCraft(whichCrafter)
    set isAiCrafting = Professions_IsUnitAiCrafting(whichCrafter)
    set bonus = Professions_GetProfessionItemBonus(whichCrafter, GNS_PROF_ALCHEMY)
    set effectiveSkill = Professions_GetEffectiveSkill(whichCrafter, GNS_PROF_ALCHEMY)
    call Professions_ConsumeItem(whichCrafter, 'I60W', 1)
    call Professions_GetProfessionSummary(whichCrafter, GNS_PROF_ALCHEMY)

**/

library Professions initializer AutoInit requires GatherNodeSkills, TimerUtils, Table, DialogCamera, CinematicMover, Interface, optional SharedDInvLib, optional ItemHook, optional MasterUI

globals
    // Public result codes for callers that need richer failure handling later.
    public constant integer RESULT_OK = 0
    public constant integer RESULT_INVALID = 1
    public constant integer RESULT_NOT_READY = 2
    public constant integer RESULT_MISSING_MATERIALS = 3

    // Recipe/material limits and shared workstation feedback settings.
    public constant integer MAX_MATERIALS = 6

    private constant integer P_MAX_RECIPES = 256
    private constant integer P_MAX_PROFESSION_ID = GNS_PROF_COOKING
    private constant string P_DEFAULT_CATEGORY = "Recipes"
    private constant integer P_ALCHEMY_LIGHT_ABILITY = 'A6DJ'
    private constant integer P_CRAFT_FAKE_CAST_ABILITY = 'A6DY'
    private constant string P_CRAFT_FAKE_CAST_ORDER = "innerfire"
    private constant string P_CRAFT_FADE_TEXTURE = "ReplaceableTextures\\CameraMasks\\Black_mask.blp"
    private constant real P_STATION_USE_RANGE = 375.00
    private constant real P_CRAFT_FADE_TIME = 0.50
    private constant real P_CRAFT_STATION_OFFSET = 96.00
    private constant real P_CRAFT_AI_READY_RANGE = 145.00
    private constant real P_CRAFT_AI_MOVE_POLL = 0.25
    private constant real P_CRAFT_AI_MOVE_TIMEOUT = 60.00
    private constant real P_CRAFT_ANIMATION_LOOP_PERIOD = 1.50
    private constant real P_SOUND_CUTOFF = 3000.00
    private constant integer P_ALCHEMY_STAGE_DEATH = 1
    private constant integer P_ALCHEMY_STAGE_DECAY = 2
    private constant real P_ALCHEMY_STAND_ANIMATION_DELAY = 60.00
    private constant real P_ALCHEMY_DEATH_ANIMATION_DELAY = 120.00
    private constant real P_CRAFT_CAMERA_DISTANCE = 950.00
    private constant real P_CRAFT_CAMERA_ZOFFSET = 40.00
    private constant real P_CRAFT_CAMERA_ANGLE = 328.00
    private constant real P_CRAFT_CAMERA_ROTATION = 180.00
    private constant real P_CRAFT_CAMERA_FARZ = 10000.00
    private constant real P_CRAFT_CAMERA_FOV = 60.00
    private constant real P_CRAFT_CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean P_CRAFT_CAMERA_BLOCK_CHECK = true
    private constant real P_CRAFT_CAMERA_RESET_TIME = 0.75

    // Registry/runtime state.
    private boolean P_Initialized = false
    private integer P_RecipeCount = 0
    private integer P_RecipeRevision = 0
    private integer P_JobCount = 0
    private string P_LastErrorText = ""

    // Recipe definitions registered by ProfessionsXXX sublibraries.
    private integer array P_RecipeProfessionId
    private integer array P_RecipeStationTypeId
    private integer array P_RecipeOutputItemCode
    private integer array P_RecipeOutputCount
    private integer array P_RecipeRequiredSkill
    private integer array P_RecipeSkillGain
    private integer array P_RecipeMaterialCount
    private real array P_RecipeCraftTime
    private real array P_RecipeCooldown
    private string array P_RecipeName
    private string array P_RecipeDescription
    private string array P_RecipeIcon
    private string array P_RecipeCategory
    private string array P_RecipeSubcategory

    // Material slots are stored by recipeId * MAX_MATERIALS + slot.
    private integer array P_MaterialItemCode
    private integer array P_MaterialAmount
    private string array P_MaterialName

    // Active crafting jobs.
    private unit array P_JobCrafter
    private unit array P_JobStation
    private player array P_JobOwner
    private integer array P_JobRecipe
    private sound array P_JobLoopSound
    private boolean array P_JobLoopSoundTransient
    private boolean array P_JobCinematicActive
    private boolean array P_JobAiControlled
    private boolean array P_JobIgnoreMaterials
    private boolean array P_JobFakeCastAdded
    private boolean array P_JobStartedCrafting
    private real array P_JobPrepareElapsed
    private timer array P_JobAnimationTimer

    // Per-profession sound labels: start once, loop during craft, finish once.
    private string array P_ProfessionStartSoundLabel
    private string array P_ProfessionLoopSoundLabel
    private string array P_ProfessionFinishSoundLabel
    private sound array P_ProfessionStartSound
    private sound array P_ProfessionLoopSound
    private sound array P_ProfessionFinishSound
    private string array P_ProfessionStartSoundPath
    private string array P_ProfessionLoopSoundPath
    private string array P_ProfessionFinishSoundPath

    // Per-profession crafter behavior registered by ProfessionsXXX sublibraries.
    private boolean array P_ProfessionAiCheatCrafting
    private string array P_ProfessionCrafterAnimPrimary
    private string array P_ProfessionCrafterAnimFallback

    // Cinematic mode is global, so overlapping profession jobs keep it enabled until the last job finishes.
    private integer P_CinematicDepth = 0

    // Lookup/state tables keyed by unit type, handle id, recipe id, or cooldown key.
    private Table P_StationProfession = 0
    private Table P_StationName = 0
    private Table P_CrafterActiveJob = 0
    private Table P_StationActiveJob = 0
    private Table P_CooldownUntil = 0
    private Table P_StationByHandle = 0
    private Table P_AlchemyGeneration = 0
    private Table P_AlchemyPostCraft = 0
    private Table P_AlchemyTimerStation = 0
    private Table P_AlchemyTimerStage = 0
    private Table P_AlchemyTimerGeneration = 0
    private Table P_CrafterAnimPrimaryByType = 0
    private Table P_CrafterAnimFallbackByType = 0
    private timer P_ClockTimer = null
    private trigger P_AttackedTrigger = null
endglobals

private function P_GetMaterialKey takes integer recipeId, integer slot returns integer
    return recipeId * MAX_MATERIALS + slot
endfunction

private function P_NoOp takes nothing returns nothing
endfunction

private function P_GetCooldownKey takes unit crafter, integer recipeId returns integer
    return StringHash(I2S(GetHandleId(crafter)) + ":" + I2S(recipeId))
endfunction

private function P_GetCrafterAnimationKey takes integer professionId, integer unitTypeId returns integer
    return StringHash(I2S(professionId) + ":" + I2S(unitTypeId))
endfunction

private function P_GetCrafterPrimaryAnimation takes integer professionId, integer unitTypeId returns string
    local integer key

    if P_CrafterAnimPrimaryByType != 0 and unitTypeId != 0 then
        set key = P_GetCrafterAnimationKey(professionId, unitTypeId)
        if P_CrafterAnimPrimaryByType.string.has(key) then
            return P_CrafterAnimPrimaryByType.string[key]
        endif
    endif

    return P_ProfessionCrafterAnimPrimary[professionId]
endfunction

private function P_GetCrafterFallbackAnimation takes integer professionId, integer unitTypeId returns string
    local integer key

    if P_CrafterAnimFallbackByType != 0 and unitTypeId != 0 then
        set key = P_GetCrafterAnimationKey(professionId, unitTypeId)
        if P_CrafterAnimFallbackByType.string.has(key) then
            return P_CrafterAnimFallbackByType.string[key]
        endif
    endif

    return P_ProfessionCrafterAnimFallback[professionId]
endfunction

private function P_IsProfessionValid takes integer professionId returns boolean
    return professionId > GNS_PROF_NONE and professionId <= P_MAX_PROFESSION_ID
endfunction

private function P_IsRecipeValid takes integer recipeId returns boolean
    return recipeId > 0 and recipeId <= P_RecipeCount
endfunction

private function P_IsUnitAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
endfunction

public function GetProfessionItemBonus takes unit whichUnit, integer professionId returns integer
    return GNS_GetItemSkillBonus(whichUnit, professionId)
endfunction

public function GetEffectiveSkill takes unit whichUnit, integer professionId returns integer
    return GNS_GetEffectiveSkill(whichUnit, professionId)
endfunction

private function P_GetDistanceSqBetweenUnits takes unit a, unit b returns real
    local real dx
    local real dy

    if a == null or b == null then
        return 999999999.00
    endif

    set dx = GetUnitX(a) - GetUnitX(b)
    set dy = GetUnitY(a) - GetUnitY(b)
    return dx * dx + dy * dy
endfunction

private function P_IsAtCraftStartRange takes unit crafter, unit station returns boolean
    return P_GetDistanceSqBetweenUnits(crafter, station) <= P_CRAFT_AI_READY_RANGE * P_CRAFT_AI_READY_RANGE
endfunction

private function P_FaceStation takes unit crafter, unit station returns nothing
    local real dx
    local real dy

    if crafter == null or station == null then
        return
    endif

    set dx = GetUnitX(station) - GetUnitX(crafter)
    set dy = GetUnitY(station) - GetUnitY(crafter)
    call SetUnitFacing(crafter, Atan2(dy, dx) * bj_RADTODEG)
endfunction

private function P_GetCraftPointX takes unit crafter, unit station returns real
    local real angle
    local real dx
    local real dy

    if crafter == null or station == null then
        return 0.00
    endif

    set dx = GetUnitX(crafter) - GetUnitX(station)
    set dy = GetUnitY(crafter) - GetUnitY(station)
    if dx * dx + dy * dy < 1.00 then
        set angle = GetUnitFacing(station) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif
    return GetUnitX(station) + P_CRAFT_STATION_OFFSET * Cos(angle)
endfunction

private function P_GetCraftPointY takes unit crafter, unit station returns real
    local real angle
    local real dx
    local real dy

    if crafter == null or station == null then
        return 0.00
    endif

    set dx = GetUnitX(crafter) - GetUnitX(station)
    set dy = GetUnitY(crafter) - GetUnitY(station)
    if dx * dx + dy * dy < 1.00 then
        set angle = GetUnitFacing(station) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif
    return GetUnitY(station) + P_CRAFT_STATION_OFFSET * Sin(angle)
endfunction

private function P_GetCraftCameraRotationOffset takes unit crafter, unit station returns real
    local real dx
    local real dy

    if crafter == null or station == null then
        return P_CRAFT_CAMERA_ROTATION
    endif

    set dx = GetUnitX(crafter) - GetUnitX(station)
    set dy = GetUnitY(crafter) - GetUnitY(station)
    if dx * dx + dy * dy < 1.00 then
        return P_CRAFT_CAMERA_ROTATION
    endif

    return (Atan2(dy, dx) * bj_RADTODEG + 180.00) - GetUnitFacing(station)
endfunction

private function P_GetNow takes nothing returns real
    if P_ClockTimer == null then
        return 0.00
    endif
    return TimerGetElapsed(P_ClockTimer)
endfunction

private function P_GetSafeItemName takes integer itemCode, string fallbackName returns string
    if fallbackName != null and fallbackName != "" then
        return fallbackName
    endif
    if itemCode == 0 then
        return "Unknown item"
    endif
    return GetObjectName(itemCode)
endfunction

private function P_GetRecipeDisplayName takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return "Unknown recipe"
    endif
    if P_RecipeName[recipeId] == null or P_RecipeName[recipeId] == "" then
        return GetObjectName(P_RecipeOutputItemCode[recipeId])
    endif
    return P_RecipeName[recipeId]
endfunction

private function P_GetNormalizedCategory takes string categoryName returns string
    if categoryName == null or categoryName == "" then
        return P_DEFAULT_CATEGORY
    endif
    return categoryName
endfunction

private function P_GetNormalizedSubcategory takes string subcategoryName returns string
    if subcategoryName == null then
        return ""
    endif
    return subcategoryName
endfunction

private function P_GetRecipeCategoryDisplay takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return P_DEFAULT_CATEGORY
    endif
    return P_GetNormalizedCategory(P_RecipeCategory[recipeId])
endfunction

private function P_GetRecipeSubcategoryDisplay takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return ""
    endif
    return P_GetNormalizedSubcategory(P_RecipeSubcategory[recipeId])
endfunction

private function P_GetStationDisplayName takes integer unitTypeId returns string
    if unitTypeId != 0 and P_StationName.has(unitTypeId) then
        return P_StationName.string[unitTypeId]
    endif
    if unitTypeId != 0 then
        return GetObjectName(unitTypeId)
    endif
    return "Workstation"
endfunction

private function P_RecipeMatchesStation takes integer recipeId, integer professionId, integer stationTypeId returns boolean
    return P_RecipeProfessionId[recipeId] == professionId and (stationTypeId == 0 or P_RecipeStationTypeId[recipeId] == stationTypeId)
endfunction

private function P_RecipeMatchesCategory takes integer recipeId, string categoryName returns boolean
    return P_GetRecipeCategoryDisplay(recipeId) == P_GetNormalizedCategory(categoryName) and P_GetRecipeSubcategoryDisplay(recipeId) == ""
endfunction

private function P_RecipeMatchesSubcategory takes integer recipeId, string categoryName, string subcategoryName returns boolean
    return P_GetRecipeCategoryDisplay(recipeId) == P_GetNormalizedCategory(categoryName) and P_GetRecipeSubcategoryDisplay(recipeId) == P_GetNormalizedSubcategory(subcategoryName)
endfunction

private function P_IsFirstStationCategory takes integer recipeId, integer professionId, integer stationTypeId returns boolean
    local integer previousId = 1
    local string categoryName = P_GetRecipeCategoryDisplay(recipeId)

    loop
        exitwhen previousId >= recipeId
        if P_RecipeMatchesStation(previousId, professionId, stationTypeId) and P_GetRecipeCategoryDisplay(previousId) == categoryName then
            return false
        endif
        set previousId = previousId + 1
    endloop

    return true
endfunction

private function P_IsFirstStationSubcategory takes integer recipeId, integer professionId, integer stationTypeId, string categoryName returns boolean
    local integer previousId = 1
    local string subcategoryName = P_GetRecipeSubcategoryDisplay(recipeId)

    if subcategoryName == "" then
        return false
    endif

    loop
        exitwhen previousId >= recipeId
        if P_RecipeMatchesStation(previousId, professionId, stationTypeId) and P_RecipeMatchesSubcategory(previousId, categoryName, subcategoryName) then
            return false
        endif
        set previousId = previousId + 1
    endloop

    return true
endfunction

private function P_CountVanillaItems takes unit u, integer itemCode returns integer
    local integer slot = 0
    local integer count = 0
    local integer charges
    local item it

    if u == null or itemCode == 0 then
        return 0
    endif

    loop
        exitwhen slot >= UnitInventorySize(u)
        set it = UnitItemInSlot(u, slot)
        if it != null and GetItemTypeId(it) == itemCode then
            set charges = GetItemCharges(it)
            if charges <= 0 then
                set count = count + 1
            else
                set count = count + charges
            endif
        endif
        set slot = slot + 1
    endloop

    set it = null
    return count
endfunction

private function P_ConsumeVanillaItems takes unit u, integer itemCode, integer amount returns nothing
    local integer slot = 0
    local integer remaining = amount
    local integer charges
    local item it

    if u == null or itemCode == 0 or amount <= 0 then
        return
    endif

    loop
        exitwhen slot >= UnitInventorySize(u) or remaining <= 0
        set it = UnitItemInSlot(u, slot)
        if it != null and GetItemTypeId(it) == itemCode then
            set charges = GetItemCharges(it)
            if charges <= 0 then
                set remaining = remaining - 1
                call RemoveItem(it)
            elseif charges > remaining then
                call SetItemCharges(it, charges - remaining)
                set remaining = 0
                set slot = slot + 1
            else
                set remaining = remaining - charges
                call RemoveItem(it)
            endif
        else
            set slot = slot + 1
        endif
    endloop

    set it = null
endfunction

private function P_CountItems takes unit u, integer itemCode returns integer
    if u == null or itemCode == 0 then
        return 0
    endif

    static if LIBRARY_SharedDInvLib then
        if BIDOfUnit(u) != -1 then
            return GetDInvItemChargesByType(u, itemCode)
        endif
        return P_CountVanillaItems(u, itemCode)
    else
        return P_CountVanillaItems(u, itemCode)
    endif
endfunction

private function P_ConsumeItems takes unit u, integer itemCode, integer amount returns nothing
    if u == null or itemCode == 0 or amount <= 0 then
        return
    endif

    static if LIBRARY_SharedDInvLib then
        if BIDOfUnit(u) != -1 then
            call RemoveDInvItemChargesByType(u, itemCode, amount)
        else
            call P_ConsumeVanillaItems(u, itemCode, amount)
        endif
    else
        call P_ConsumeVanillaItems(u, itemCode, amount)
    endif
endfunction

private function P_HasMaterials takes unit crafter, integer recipeId returns boolean
    local integer slot = 1
    local integer key

    loop
        exitwhen slot > P_RecipeMaterialCount[recipeId]
        set key = P_GetMaterialKey(recipeId, slot)
        if P_CountItems(crafter, P_MaterialItemCode[key]) < P_MaterialAmount[key] then
            return false
        endif
        set slot = slot + 1
    endloop

    return true
endfunction

private function P_ConsumeRecipeMaterials takes unit crafter, integer recipeId returns nothing
    local integer slot = 1
    local integer key

    loop
        exitwhen slot > P_RecipeMaterialCount[recipeId]
        set key = P_GetMaterialKey(recipeId, slot)
        call P_ConsumeItems(crafter, P_MaterialItemCode[key], P_MaterialAmount[key])
        set slot = slot + 1
    endloop
endfunction

private function P_IsNearStation takes unit crafter, unit station returns boolean
    return P_GetDistanceSqBetweenUnits(crafter, station) <= P_STATION_USE_RANGE * P_STATION_USE_RANGE
endfunction

private function P_PlaySoundPathForJob takes integer jobId, string soundPath, unit station, boolean looping returns sound
    if soundPath == null or soundPath == "" then
        return null
    endif

    if P_JobCinematicActive[jobId] and not P_JobAiControlled[jobId] then
        return Interface_PlayProfessionSoundPath(soundPath, looping)
    endif

    if station != null then
        return Interface_PlayProfessionSoundPathOnUnit(soundPath, station, looping, P_SOUND_CUTOFF)
    endif

    return null
endfunction

private function P_PlaySoundLabelForJob takes integer jobId, string soundLabel, unit station, boolean looping returns sound
    if P_JobCinematicActive[jobId] and not P_JobAiControlled[jobId] then
        return Interface_PlayProfessionSound(null, soundLabel, looping)
    endif

    if station != null then
        return Interface_PlayProfessionSoundOnUnit(null, soundLabel, station, looping, P_SOUND_CUTOFF)
    endif

    return null
endfunction

private function P_PlaySoundHandleForJob takes integer jobId, sound whichSound, unit station, boolean looping returns sound
    if P_JobCinematicActive[jobId] and not P_JobAiControlled[jobId] then
        return Interface_PlayProfessionSound(whichSound, "", looping)
    endif

    if station != null then
        return Interface_PlayProfessionSoundOnUnit(whichSound, "", station, looping, P_SOUND_CUTOFF)
    endif

    return null
endfunction

private function P_ShouldPreferSoundLabel takes integer jobId returns boolean
    return P_JobAiControlled[jobId]
endfunction

private function P_ShouldPreferSoundPath takes integer jobId returns boolean
    return P_JobCinematicActive[jobId] and not P_JobAiControlled[jobId]
endfunction

private function P_IsBlankString takes string value returns boolean
    return value == null or value == ""
endfunction

private function P_RefreshProfessionSoundHandles takes integer professionId returns nothing
    call Interface_RefreshDefaultSounds()

    if professionId == GNS_PROF_ALCHEMY then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Alchemy_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Alchemy_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Alchemy_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Alchemy_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Alchemy_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Alchemy_EndPath
        endif
    elseif professionId == GNS_PROF_BLACKSMITHING then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Blacksmithing_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Blacksmithing_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Blacksmithing_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Blacksmithing_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Blacksmithing_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Blacksmithing_EndPath
        endif
    elseif professionId == GNS_PROF_MINING then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Mining_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Mining_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Mining_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Mining_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Mining_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Mining_EndPath
        endif
    elseif professionId == GNS_PROF_LEATHERWORKING then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Leatherworking_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Leatherworking_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Leatherworking_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Leatherworking_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Leatherworking_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Leatherworking_EndPath
        endif
    elseif professionId == GNS_PROF_COOKING then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Cooking_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Cooking_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Cooking_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Cooking_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Cooking_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Cooking_EndPath
        endif
    elseif professionId == GNS_PROF_FISHING then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Fishing_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Fishing_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Fishing_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Fishing_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Fishing_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Fishing_EndPath
        endif
    elseif professionId == GNS_PROF_SKINNING then
        if P_ProfessionStartSound[professionId] == null then
            set P_ProfessionStartSound[professionId] = Interface_Profession_Skinning_Start
        endif
        if P_ProfessionLoopSound[professionId] == null then
            set P_ProfessionLoopSound[professionId] = Interface_Profession_Skinning_Loop
        endif
        if P_ProfessionFinishSound[professionId] == null then
            set P_ProfessionFinishSound[professionId] = Interface_Profession_Skinning_End
        endif
        if P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set P_ProfessionStartSoundPath[professionId] = Interface_Profession_Skinning_StartPath
        endif
        if P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
            set P_ProfessionLoopSoundPath[professionId] = Interface_Profession_Skinning_LoopPath
        endif
        if P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set P_ProfessionFinishSoundPath[professionId] = Interface_Profession_Skinning_EndPath
        endif
    endif
endfunction

private function P_StartLoopSound takes integer jobId, integer professionId, unit station returns sound
    local sound loopSound

    set P_JobLoopSoundTransient[jobId] = false
    if not P_IsProfessionValid(professionId) then
        return null
    endif
    call P_RefreshProfessionSoundHandles(professionId)

    if P_ShouldPreferSoundPath(jobId) and not P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
        set loopSound = P_PlaySoundPathForJob(jobId, P_ProfessionLoopSoundPath[professionId], station, true)
        if loopSound != null then
            set P_JobLoopSoundTransient[jobId] = true
            return loopSound
        endif
    endif

    if P_ShouldPreferSoundLabel(jobId) and P_ProfessionLoopSoundLabel[professionId] != null and P_ProfessionLoopSoundLabel[professionId] != "" then
        set loopSound = P_PlaySoundLabelForJob(jobId, P_ProfessionLoopSoundLabel[professionId], station, true)
        if loopSound != null then
            set P_JobLoopSoundTransient[jobId] = true
            return loopSound
        endif
    endif

    if P_ProfessionLoopSound[professionId] != null then
        set loopSound = P_PlaySoundHandleForJob(jobId, P_ProfessionLoopSound[professionId], station, true)
        if loopSound != null then
            return loopSound
        endif
    endif

    if not P_ShouldPreferSoundLabel(jobId) and P_ProfessionLoopSoundLabel[professionId] != null and P_ProfessionLoopSoundLabel[professionId] != "" then
        set loopSound = P_PlaySoundLabelForJob(jobId, P_ProfessionLoopSoundLabel[professionId], station, true)
        if loopSound != null then
            set P_JobLoopSoundTransient[jobId] = true
            return loopSound
        endif
    endif

    if not P_ShouldPreferSoundPath(jobId) and not P_IsBlankString(P_ProfessionLoopSoundPath[professionId]) then
        set loopSound = P_PlaySoundPathForJob(jobId, P_ProfessionLoopSoundPath[professionId], station, true)
        if loopSound != null then
            set P_JobLoopSoundTransient[jobId] = true
            return loopSound
        endif
    endif

    return null
endfunction

private function P_StopLoopSound takes integer jobId returns nothing
    local sound whichSound = P_JobLoopSound[jobId]

    if whichSound != null then
        if P_JobLoopSoundTransient[jobId] then
            call StopSound(whichSound, true, true)
        else
            call StopSound(whichSound, false, true)
        endif
    endif
    set P_JobLoopSound[jobId] = null
    set P_JobLoopSoundTransient[jobId] = false

    set whichSound = null
endfunction

private function P_PlayStartSound takes integer jobId, integer professionId, unit station returns nothing
    local sound playedSound

    if P_IsProfessionValid(professionId) then
        call P_RefreshProfessionSoundHandles(professionId)
        if P_ShouldPreferSoundPath(jobId) and not P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set playedSound = P_PlaySoundPathForJob(jobId, P_ProfessionStartSoundPath[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if P_ShouldPreferSoundLabel(jobId) and P_ProfessionStartSoundLabel[professionId] != null and P_ProfessionStartSoundLabel[professionId] != "" then
            set playedSound = P_PlaySoundLabelForJob(jobId, P_ProfessionStartSoundLabel[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if P_ProfessionStartSound[professionId] != null then
            set playedSound = P_PlaySoundHandleForJob(jobId, P_ProfessionStartSound[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if not P_ShouldPreferSoundLabel(jobId) and P_ProfessionStartSoundLabel[professionId] != null and P_ProfessionStartSoundLabel[professionId] != "" then
            set playedSound = P_PlaySoundLabelForJob(jobId, P_ProfessionStartSoundLabel[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if not P_ShouldPreferSoundPath(jobId) and not P_IsBlankString(P_ProfessionStartSoundPath[professionId]) then
            set playedSound = P_PlaySoundPathForJob(jobId, P_ProfessionStartSoundPath[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
    endif

    set playedSound = null
endfunction

private function P_PlayFinishSound takes integer jobId, integer professionId, unit station returns nothing
    local sound playedSound

    if P_IsProfessionValid(professionId) then
        call P_RefreshProfessionSoundHandles(professionId)
        if P_ShouldPreferSoundPath(jobId) and not P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set playedSound = P_PlaySoundPathForJob(jobId, P_ProfessionFinishSoundPath[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if P_ShouldPreferSoundLabel(jobId) and P_ProfessionFinishSoundLabel[professionId] != null and P_ProfessionFinishSoundLabel[professionId] != "" then
            set playedSound = P_PlaySoundLabelForJob(jobId, P_ProfessionFinishSoundLabel[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if P_ProfessionFinishSound[professionId] != null then
            set playedSound = P_PlaySoundHandleForJob(jobId, P_ProfessionFinishSound[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if not P_ShouldPreferSoundLabel(jobId) and P_ProfessionFinishSoundLabel[professionId] != null and P_ProfessionFinishSoundLabel[professionId] != "" then
            set playedSound = P_PlaySoundLabelForJob(jobId, P_ProfessionFinishSoundLabel[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
        if not P_ShouldPreferSoundPath(jobId) and not P_IsBlankString(P_ProfessionFinishSoundPath[professionId]) then
            set playedSound = P_PlaySoundPathForJob(jobId, P_ProfessionFinishSoundPath[professionId], station, false)
            if playedSound != null then
                set playedSound = null
                return
            endif
        endif
    endif

    set playedSound = null
endfunction

private function P_ClearAlchemyTimerData takes timer t returns nothing
    local integer timerId

    if t == null then
        return
    endif

    set timerId = GetHandleId(t)
    call P_AlchemyTimerStation.integer.remove(timerId)
    call P_AlchemyTimerStage.integer.remove(timerId)
    call P_AlchemyTimerGeneration.integer.remove(timerId)
endfunction

private function P_BumpAlchemyGeneration takes unit station returns nothing
    local integer stationId

    if station == null then
        return
    endif

    set stationId = GetHandleId(station)
    set P_AlchemyGeneration.integer[stationId] = P_AlchemyGeneration.integer[stationId] + 1
    set P_StationByHandle.unit[stationId] = station
endfunction

private function P_AlchemyDelayAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId = GetHandleId(t)
    local integer stationId = P_AlchemyTimerStation.integer[timerId]
    local integer stage = P_AlchemyTimerStage.integer[timerId]
    local integer generation = P_AlchemyTimerGeneration.integer[timerId]
    local unit station = P_StationByHandle.unit[stationId]

    if station != null and GetUnitTypeId(station) != 0 and P_AlchemyGeneration.integer[stationId] == generation then
        if stage == P_ALCHEMY_STAGE_DEATH then
            call UnitRemoveAbility(station, P_ALCHEMY_LIGHT_ABILITY)
            call SetUnitAnimation(station, "death")
        elseif stage == P_ALCHEMY_STAGE_DECAY then
            call UnitRemoveAbility(station, P_ALCHEMY_LIGHT_ABILITY)
            call SetUnitAnimation(station, "decay")
            call P_AlchemyPostCraft.boolean.remove(stationId)
            call P_StationByHandle.unit.remove(stationId)
        endif
    endif

    call P_ClearAlchemyTimerData(t)
    call ReleaseTimer(t)

    set station = null
    set t = null
endfunction

private function P_ScheduleAlchemyStage takes unit station, integer stage, real delay returns nothing
    local timer t
    local integer timerId
    local integer stationId

    if station == null or GetUnitTypeId(station) == 0 then
        return
    endif

    set stationId = GetHandleId(station)
    set P_StationByHandle.unit[stationId] = station
    set t = NewTimer()
    set timerId = GetHandleId(t)
    set P_AlchemyTimerStation.integer[timerId] = stationId
    set P_AlchemyTimerStage.integer[timerId] = stage
    set P_AlchemyTimerGeneration.integer[timerId] = P_AlchemyGeneration.integer[stationId]
    call TimerStart(t, delay, false, function P_AlchemyDelayAction)

    set t = null
endfunction

private function P_StartAlchemyStationFeedback takes unit station returns nothing
    local integer stationId
    local boolean keepAnimation

    if station == null then
        return
    endif

    set stationId = GetHandleId(station)
    set keepAnimation = P_AlchemyPostCraft.boolean[stationId]
    call P_BumpAlchemyGeneration(station)
    call P_AlchemyPostCraft.boolean.remove(stationId)
    call UnitAddAbility(station, P_ALCHEMY_LIGHT_ABILITY)
    if not keepAnimation then
        call SetUnitAnimation(station, "stand")
    endif
endfunction

private function P_FinishAlchemyStationFeedback takes unit station returns nothing
    local integer stationId

    if station == null then
        return
    endif

    set stationId = GetHandleId(station)
    call P_BumpAlchemyGeneration(station)
    set P_AlchemyPostCraft.boolean[stationId] = true
    call UnitAddAbility(station, P_ALCHEMY_LIGHT_ABILITY)
    call SetUnitAnimation(station, "stand")
    call P_ScheduleAlchemyStage(station, P_ALCHEMY_STAGE_DEATH, P_ALCHEMY_STAND_ANIMATION_DELAY)
    call P_ScheduleAlchemyStage(station, P_ALCHEMY_STAGE_DECAY, P_ALCHEMY_STAND_ANIMATION_DELAY + P_ALCHEMY_DEATH_ANIMATION_DELAY)
endfunction

private function P_StartStationFeedback takes integer professionId, unit station returns nothing
    if station == null then
        return
    endif

    if professionId == GNS_PROF_ALCHEMY then
        call P_StartAlchemyStationFeedback(station)
    elseif professionId == GNS_PROF_BLACKSMITHING then
        call SetUnitAnimation(station, "attack")
    elseif professionId == GNS_PROF_MINING then
        call SetUnitAnimation(station, "stand work")
    elseif professionId == GNS_PROF_LEATHERWORKING then
        call SetUnitAnimation(station, "stand work")
    else
        call SetUnitAnimation(station, "stand")
    endif
endfunction

private function P_FinishStationFeedback takes integer professionId, unit station returns nothing
    if station == null then
        return
    endif

    if professionId == GNS_PROF_ALCHEMY then
        call P_FinishAlchemyStationFeedback(station)
    else
        call SetUnitAnimation(station, "stand")
    endif
endfunction

private function P_CancelStationFeedback takes integer professionId, unit station returns nothing
    local integer stationId

    if station == null then
        return
    endif

    if professionId == GNS_PROF_ALCHEMY then
        set stationId = GetHandleId(station)
        call P_BumpAlchemyGeneration(station)
        call P_AlchemyPostCraft.boolean.remove(stationId)
        call P_StationByHandle.unit.remove(stationId)
        call UnitRemoveAbility(station, P_ALCHEMY_LIGHT_ABILITY)
        call SetUnitAnimation(station, "decay")
    else
        call SetUnitAnimation(station, "stand")
    endif
endfunction

private function P_StartCrafterFeedback takes integer professionId, unit crafter, unit station returns nothing
    local string primaryAnim
    local string fallbackAnim
    local integer unitTypeId

    if crafter == null then
        return
    endif

    call P_FaceStation(crafter, station)

    if P_IsProfessionValid(professionId) then
        set unitTypeId = GetUnitTypeId(crafter)
        set primaryAnim = P_GetCrafterPrimaryAnimation(professionId, unitTypeId)
        set fallbackAnim = P_GetCrafterFallbackAnimation(professionId, unitTypeId)
        if primaryAnim != null and primaryAnim != "" then
            call SetUnitAnimation(crafter, primaryAnim)
            if fallbackAnim != null and fallbackAnim != "" then
                call QueueUnitAnimation(crafter, fallbackAnim)
            endif
        elseif fallbackAnim != null and fallbackAnim != "" then
            call SetUnitAnimation(crafter, fallbackAnim)
        else
            call SetUnitAnimation(crafter, "stand")
        endif
    else
        call SetUnitAnimation(crafter, "stand")
    endif
endfunction

private function P_FinishCrafterFeedback takes unit crafter returns nothing
    if crafter != null then
        call SetUnitAnimation(crafter, "stand")
    endif
endfunction

private function P_RestartStationCraftAnimation takes integer professionId, unit station returns nothing
    if station == null then
        return
    endif

    if professionId == GNS_PROF_ALCHEMY then
        call UnitAddAbility(station, P_ALCHEMY_LIGHT_ABILITY)
    elseif professionId == GNS_PROF_BLACKSMITHING then
        call SetUnitAnimation(station, "attack")
    elseif professionId == GNS_PROF_MINING then
        call SetUnitAnimation(station, "stand work")
    elseif professionId == GNS_PROF_LEATHERWORKING then
        call SetUnitAnimation(station, "stand work")
    else
        call SetUnitAnimation(station, "stand")
    endif
endfunction

private function P_StopCrafterAnimationLoop takes integer jobId returns nothing
    local timer t = P_JobAnimationTimer[jobId]

    if t != null then
        call PauseTimer(t)
        call ReleaseTimer(t)
        set P_JobAnimationTimer[jobId] = null
    endif

    set t = null
endfunction

private function P_CrafterAnimationLoopAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer jobId = GetTimerData(t)
    local integer recipeId = P_JobRecipe[jobId]
    local integer professionId
    local unit crafter = P_JobCrafter[jobId]
    local unit station = P_JobStation[jobId]

    if P_JobStartedCrafting[jobId] and P_IsRecipeValid(recipeId) and P_IsUnitAlive(crafter) and station != null and GetUnitTypeId(station) != 0 then
        set professionId = P_RecipeProfessionId[recipeId]
        call P_StartCrafterFeedback(professionId, crafter, station)
        call P_RestartStationCraftAnimation(professionId, station)
    endif

    set crafter = null
    set station = null
    set t = null
endfunction

private function P_StartCrafterAnimationLoop takes integer jobId returns nothing
    local timer t

    call P_StopCrafterAnimationLoop(jobId)
    set t = NewTimerEx(jobId)
    set P_JobAnimationTimer[jobId] = t
    call TimerStart(t, P_CRAFT_ANIMATION_LOOP_PERIOD, true, function P_CrafterAnimationLoopAction)

    set t = null
endfunction

private function P_StartFakeCast takes integer jobId, unit crafter returns nothing
    if crafter == null then
        return
    endif

    set P_JobFakeCastAdded[jobId] = UnitAddAbility(crafter, P_CRAFT_FAKE_CAST_ABILITY)
    call IssueTargetOrder(crafter, P_CRAFT_FAKE_CAST_ORDER, crafter)
endfunction

private function P_FinishFakeCast takes integer jobId, unit crafter returns nothing
    if crafter != null and P_JobFakeCastAdded[jobId] then
        call UnitRemoveAbility(crafter, P_CRAFT_FAKE_CAST_ABILITY)
    endif
    set P_JobFakeCastAdded[jobId] = false
endfunction

private function P_StartCraftCinematic takes integer jobId, unit crafter, unit station returns nothing
    local player owner

    if crafter == null or station == null then
        return
    endif

    set owner = GetOwningPlayer(crafter)
    if owner == null then
        set owner = Player(0)
    endif

    set P_JobOwner[jobId] = owner
    set P_JobCinematicActive[jobId] = true
    if P_CinematicDepth <= 0 then
        call CinematicModeBJ(true, GetPlayersAll())
        static if LIBRARY_MasterUI then
            call MasterUI_HideGameButton()
        endif
        set P_CinematicDepth = 0
    endif
    set P_CinematicDepth = P_CinematicDepth + 1
    call Interface_ApplyProfessionCinematicVolumes(owner)

    call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, P_CRAFT_FADE_TIME, P_CRAFT_FADE_TEXTURE, 0.00, 0.00, 0.00, 0.00)

    set owner = null
endfunction

private function P_FinishCraftCinematic takes integer jobId, unit crafter returns nothing
    local player owner = P_JobOwner[jobId]

    if not P_JobCinematicActive[jobId] then
        set owner = null
        return
    endif

    if owner != null then
        call DialogCameraReset(owner, P_CRAFT_CAMERA_RESET_TIME)
    endif
    call CinematicMover_ReturnSingleUnitFromCinematic(crafter)

    set P_CinematicDepth = P_CinematicDepth - 1
    if P_CinematicDepth <= 0 then
        set P_CinematicDepth = 0
        call CinematicModeBJ(false, GetPlayersAll())
        static if LIBRARY_MasterUI then
            call MasterUI_ShowGameButton()
        endif
    endif
    call ExecuteFunc("CraftingUI_ReopenAfterCraft")

    set P_JobCinematicActive[jobId] = false
    set P_JobOwner[jobId] = null
    set owner = null
endfunction

private function P_CreateCraftedItem takes unit crafter, unit station, integer itemCode, integer amount returns item
    local real x = 0.00
    local real y = 0.00
    local item result
    local integer pid
    local integer bid
    local integer eqid
    local integer storedSlot

    if station != null and GetUnitTypeId(station) != 0 then
        set x = GetUnitX(station)
        set y = GetUnitY(station)
    elseif crafter != null and GetUnitTypeId(crafter) != 0 then
        set x = GetUnitX(crafter)
        set y = GetUnitY(crafter)
    endif

    static if LIBRARY_ItemHook then
        set result = ItemHook_CreateItem(itemCode, x, y)
    else
        set result = CreateItem(itemCode, x, y)
    endif

    if result != null and amount > 1 then
        call SetItemCharges(result, amount)
    endif

    static if LIBRARY_SharedDInvLib then
        if result != null and crafter != null and GetUnitTypeId(crafter) != 0 then
            set pid = GetPlayerId(GetOwningPlayer(crafter))
            set bid = BIDOfUnit(crafter)
            set eqid = EQIDOfUnit(crafter)
            if bid > 0 then
                set storedSlot = StoreItemForPIDBID(result, pid, bid, eqid)
                if storedSlot >= 0 then
                    return result
                endif
            endif
        endif
    endif

    if result != null and crafter != null and UnitInventorySize(crafter) > 0 and UnitAddItem(crafter, result) then
        return result
    endif

    if result != null then
        call SetItemPosition(result, x, y)
    endif

    return result
endfunction

private function P_CheckStartRequirements takes unit crafter, unit station, integer recipeId, boolean explain, boolean ignoreMaterials, boolean requireNear returns boolean
    local integer professionId
    local integer stationTypeId
    local integer cooldownKey
    local real cooldownUntil

    if not P_IsRecipeValid(recipeId) then
        if explain then
            set P_LastErrorText = "Invalid recipe."
        endif
        return false
    endif

    set professionId = P_RecipeProfessionId[recipeId]
    set stationTypeId = P_RecipeStationTypeId[recipeId]

    if not P_IsUnitAlive(crafter) then
        if explain then
            set P_LastErrorText = "No crafter selected."
        endif
        return false
    endif

    if not GNS_IsTrackedGatherer(crafter) then
        if explain then
            set P_LastErrorText = GetUnitName(crafter) + " cannot use profession workstations."
        endif
        return false
    endif

    if station == null or GetUnitTypeId(station) == 0 then
        if explain then
            set P_LastErrorText = "No workstation selected."
        endif
        return false
    endif

    if stationTypeId != 0 and GetUnitTypeId(station) != stationTypeId then
        if explain then
            set P_LastErrorText = P_GetRecipeDisplayName(recipeId) + " requires " + P_GetStationDisplayName(stationTypeId) + "."
        endif
        return false
    endif

    if requireNear and not P_IsNearStation(crafter, station) then
        if explain then
            set P_LastErrorText = GetUnitName(crafter) + " is too far from the " + P_GetStationDisplayName(GetUnitTypeId(station)) + "."
        endif
        return false
    endif

    if GetEffectiveSkill(crafter, professionId) < P_RecipeRequiredSkill[recipeId] then
        if explain then
            set P_LastErrorText = "Requires " + GNS_GetProfessionName(professionId) + " " + I2S(P_RecipeRequiredSkill[recipeId]) + "."
        endif
        return false
    endif

    if P_CrafterActiveJob.has(GetHandleId(crafter)) then
        if explain then
            set P_LastErrorText = GetUnitName(crafter) + " is already crafting."
        endif
        return false
    endif

    if P_StationActiveJob.has(GetHandleId(station)) then
        if explain then
            set P_LastErrorText = "That " + P_GetStationDisplayName(GetUnitTypeId(station)) + " is already reserved."
        endif
        return false
    endif

    if P_RecipeCooldown[recipeId] > 0.00 then
        set cooldownKey = P_GetCooldownKey(crafter, recipeId)
        set cooldownUntil = P_CooldownUntil.real[cooldownKey]
        if cooldownUntil > P_GetNow() then
            if explain then
                set P_LastErrorText = P_GetRecipeDisplayName(recipeId) + " is cooling down."
            endif
            return false
        endif
    endif

    if not ignoreMaterials and not P_HasMaterials(crafter, recipeId) then
        if explain then
            set P_LastErrorText = "Missing materials for " + P_GetRecipeDisplayName(recipeId) + "."
        endif
        return false
    endif

    if explain then
        set P_LastErrorText = ""
    endif
    return true
endfunction

private function P_FinishJob takes integer jobId returns nothing
    local unit crafter = P_JobCrafter[jobId]
    local unit station = P_JobStation[jobId]
    local integer recipeId = P_JobRecipe[jobId]
    local integer professionId = 0
    local item createdItem
    local player owner

    call P_StopLoopSound(jobId)
    call P_StopCrafterAnimationLoop(jobId)
    call P_FinishFakeCast(jobId, crafter)

    if P_IsRecipeValid(recipeId) then
        set professionId = P_RecipeProfessionId[recipeId]
        call P_PlayFinishSound(jobId, professionId, station)
        call P_FinishCrafterFeedback(crafter)
        call P_FinishStationFeedback(professionId, station)
        set createdItem = P_CreateCraftedItem(crafter, station, P_RecipeOutputItemCode[recipeId], P_RecipeOutputCount[recipeId])
        call GNS_AwardGatherSkillForNode(crafter, professionId, P_RecipeRequiredSkill[recipeId], P_RecipeSkillGain[recipeId])
        if crafter != null and not P_JobAiControlled[jobId] then
            set owner = GetOwningPlayer(crafter)
            if owner != null then
                call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffffcc00Created:|r " + P_GetRecipeDisplayName(recipeId))
            endif
        endif
    endif

    if crafter != null then
        call P_CrafterActiveJob.remove(GetHandleId(crafter))
    endif
    if station != null then
        call P_StationActiveJob.remove(GetHandleId(station))
    endif

    call P_FinishCraftCinematic(jobId, crafter)

    set P_JobCrafter[jobId] = null
    set P_JobStation[jobId] = null
    set P_JobOwner[jobId] = null
    set P_JobRecipe[jobId] = 0
    set P_JobLoopSound[jobId] = null
    set P_JobLoopSoundTransient[jobId] = false
    set P_JobCinematicActive[jobId] = false
    set P_JobAiControlled[jobId] = false
    set P_JobIgnoreMaterials[jobId] = false
    set P_JobFakeCastAdded[jobId] = false
    set P_JobStartedCrafting[jobId] = false
    set P_JobPrepareElapsed[jobId] = 0.00
    set P_JobAnimationTimer[jobId] = null

    set createdItem = null
    set owner = null
    set crafter = null
    set station = null
endfunction

private function P_FinishJobAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer jobId = GetTimerData(t)

    call P_FinishJob(jobId)
    call ReleaseTimer(t)

    set t = null
endfunction

private function P_ClearJob takes integer jobId returns nothing
    set P_JobCrafter[jobId] = null
    set P_JobStation[jobId] = null
    set P_JobOwner[jobId] = null
    set P_JobRecipe[jobId] = 0
    set P_JobLoopSound[jobId] = null
    set P_JobLoopSoundTransient[jobId] = false
    set P_JobCinematicActive[jobId] = false
    set P_JobAiControlled[jobId] = false
    set P_JobIgnoreMaterials[jobId] = false
    set P_JobFakeCastAdded[jobId] = false
    set P_JobStartedCrafting[jobId] = false
    set P_JobPrepareElapsed[jobId] = 0.00
    set P_JobAnimationTimer[jobId] = null
endfunction

private function P_CancelJob takes integer jobId returns nothing
    local unit crafter = P_JobCrafter[jobId]
    local unit station = P_JobStation[jobId]
    local integer recipeId = P_JobRecipe[jobId]

    call P_StopLoopSound(jobId)
    call P_StopCrafterAnimationLoop(jobId)
    call P_FinishFakeCast(jobId, crafter)
    call P_FinishCrafterFeedback(crafter)
    if P_JobStartedCrafting[jobId] and P_IsRecipeValid(recipeId) then
        call P_CancelStationFeedback(P_RecipeProfessionId[recipeId], station)
    endif
    if crafter != null then
        call IssueImmediateOrder(crafter, "stop")
    endif

    if crafter != null then
        call P_CrafterActiveJob.remove(GetHandleId(crafter))
    endif
    if station != null then
        call P_StationActiveJob.remove(GetHandleId(station))
    endif

    call P_FinishCraftCinematic(jobId, crafter)
    call P_ClearJob(jobId)

    set crafter = null
    set station = null
endfunction

private function P_CrafterAttackedAction takes nothing returns nothing
    local unit crafter = GetTriggerUnit()
    local integer jobId
    local player owner

    if crafter != null and P_CrafterActiveJob.has(GetHandleId(crafter)) then
        set jobId = P_CrafterActiveJob.integer[GetHandleId(crafter)]
        if not P_JobAiControlled[jobId] then
            set owner = GetOwningPlayer(crafter)
            if owner != null then
                call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffff8080Crafting interrupted.|r")
            endif
        endif
        call P_CancelJob(jobId)
    endif

    set owner = null
    set crafter = null
endfunction

private function P_BeginActualCraft takes integer jobId returns boolean
    local unit crafter = P_JobCrafter[jobId]
    local unit station = P_JobStation[jobId]
    local integer recipeId = P_JobRecipe[jobId]
    local integer professionId
    local integer cooldownKey
    local timer t
    local player owner

    if P_JobStartedCrafting[jobId] then
        set crafter = null
        set station = null
        return true
    endif

    if not P_IsRecipeValid(recipeId) or not P_IsUnitAlive(crafter) or station == null or GetUnitTypeId(station) == 0 then
        call P_CancelJob(jobId)
        set crafter = null
        set station = null
        return false
    endif

    set professionId = P_RecipeProfessionId[recipeId]

    if not P_JobIgnoreMaterials[jobId] and not P_HasMaterials(crafter, recipeId) then
        set owner = GetOwningPlayer(crafter)
        if owner != null and not P_JobAiControlled[jobId] then
            call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffff8080Missing materials for " + P_GetRecipeDisplayName(recipeId) + ".|r")
        endif
        call P_CancelJob(jobId)
        set owner = null
        set crafter = null
        set station = null
        return false
    endif

    if not P_JobIgnoreMaterials[jobId] then
        call P_ConsumeRecipeMaterials(crafter, recipeId)
    endif

    if P_RecipeCooldown[recipeId] > 0.00 then
        set cooldownKey = P_GetCooldownKey(crafter, recipeId)
        set P_CooldownUntil.real[cooldownKey] = P_GetNow() + P_RecipeCooldown[recipeId]
    endif

    set P_JobStartedCrafting[jobId] = true

    call P_StartFakeCast(jobId, crafter)
    call P_PlayStartSound(jobId, professionId, station)
    set P_JobLoopSound[jobId] = P_StartLoopSound(jobId, professionId, station)
    call P_StartCrafterFeedback(professionId, crafter, station)
    call P_StartCrafterAnimationLoop(jobId)
    call P_StartStationFeedback(professionId, station)

    if not P_JobAiControlled[jobId] then
        set owner = GetOwningPlayer(crafter)
        if owner != null then
            call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffffcc00Crafting:|r " + P_GetRecipeDisplayName(recipeId))
        endif
    endif

    set t = NewTimerEx(jobId)
    call TimerStart(t, P_RecipeCraftTime[recipeId], false, function P_FinishJobAction)

    set owner = null
    set t = null
    set crafter = null
    set station = null
    return true
endfunction

private function P_PlayerFadeInDoneAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer jobId = GetTimerData(t)

    call P_BeginActualCraft(jobId)
    call ReleaseTimer(t)

    set t = null
endfunction

private function P_PlayerFadeOutDoneAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer jobId = GetTimerData(t)
    local unit crafter = P_JobCrafter[jobId]
    local unit station = P_JobStation[jobId]
    local player owner = P_JobOwner[jobId]
    local real x
    local real y
    local real rotationOffset

    if P_IsUnitAlive(crafter) and station != null and GetUnitTypeId(station) != 0 then
        set x = P_GetCraftPointX(crafter, station)
        set y = P_GetCraftPointY(crafter, station)
        call CinematicMover_MoveSingleUnitToPoint(crafter, x, y)
        call P_FaceStation(crafter, station)
        if owner != null then
            set rotationOffset = P_GetCraftCameraRotationOffset(crafter, station)
            call DialogCameraStart(owner, station, P_CRAFT_CAMERA_DISTANCE, P_CRAFT_CAMERA_ZOFFSET, P_CRAFT_CAMERA_ANGLE, rotationOffset, P_CRAFT_CAMERA_FARZ, P_CRAFT_CAMERA_FOV, P_CRAFT_CAMERA_BLOCK_RADIUS, P_CRAFT_CAMERA_BLOCK_CHECK)
        endif
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, P_CRAFT_FADE_TIME, P_CRAFT_FADE_TEXTURE, 0.00, 0.00, 0.00, 0.00)
        call TimerStart(t, P_CRAFT_FADE_TIME, false, function P_PlayerFadeInDoneAction)
    else
        call P_CancelJob(jobId)
        call ReleaseTimer(t)
    endif

    set crafter = null
    set station = null
    set owner = null
    set t = null
endfunction

private function P_StartPlayerCraftPreparation takes integer jobId returns nothing
    local timer t = NewTimerEx(jobId)

    call P_StartCraftCinematic(jobId, P_JobCrafter[jobId], P_JobStation[jobId])
    call TimerStart(t, P_CRAFT_FADE_TIME, false, function P_PlayerFadeOutDoneAction)

    set t = null
endfunction

private function P_IssueAiMoveToStation takes unit crafter, unit station returns boolean
    if crafter == null or station == null then
        return false
    endif
    if IssueTargetOrder(crafter, "move", station) then
        return true
    endif
    return IssuePointOrder(crafter, "move", GetUnitX(station), GetUnitY(station))
endfunction

private function P_AiPrepareAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer jobId = GetTimerData(t)
    local unit crafter = P_JobCrafter[jobId]
    local unit station = P_JobStation[jobId]
    local integer orderId

    if not P_IsUnitAlive(crafter) or station == null or GetUnitTypeId(station) == 0 then
        call P_CancelJob(jobId)
        call ReleaseTimer(t)
        set crafter = null
        set station = null
        set t = null
        return
    endif

    if P_IsAtCraftStartRange(crafter, station) then
        call IssueImmediateOrder(crafter, "stop")
        call P_BeginActualCraft(jobId)
        call ReleaseTimer(t)
        set crafter = null
        set station = null
        set t = null
        return
    endif

    set P_JobPrepareElapsed[jobId] = P_JobPrepareElapsed[jobId] + P_CRAFT_AI_MOVE_POLL
    if P_JobPrepareElapsed[jobId] >= P_CRAFT_AI_MOVE_TIMEOUT then
        call P_CancelJob(jobId)
        call ReleaseTimer(t)
    else
        set orderId = GetUnitCurrentOrder(crafter)
        if orderId != OrderId("move") then
            call P_IssueAiMoveToStation(crafter, station)
        endif
    endif

    set crafter = null
    set station = null
    set t = null
endfunction

private function P_StartAiCraftPreparation takes integer jobId returns nothing
    local timer t = NewTimerEx(jobId)

    set P_JobPrepareElapsed[jobId] = 0.00
    call P_IssueAiMoveToStation(P_JobCrafter[jobId], P_JobStation[jobId])
    call TimerStart(t, P_CRAFT_AI_MOVE_POLL, true, function P_AiPrepareAction)

    set t = null
endfunction

private function P_CreateReservedJob takes unit crafter, unit station, integer recipeId, boolean aiControlled, boolean ignoreMaterials returns integer
    local integer jobId

    if P_JobCount >= 8000 then
        set P_JobCount = 0
    endif

    set P_JobCount = P_JobCount + 1
    set jobId = P_JobCount
    set P_JobCrafter[jobId] = crafter
    set P_JobStation[jobId] = station
    set P_JobRecipe[jobId] = recipeId
    set P_JobAiControlled[jobId] = aiControlled
    set P_JobIgnoreMaterials[jobId] = ignoreMaterials
    set P_JobAnimationTimer[jobId] = null
    set P_CrafterActiveJob.integer[GetHandleId(crafter)] = jobId
    set P_StationActiveJob.integer[GetHandleId(station)] = jobId

    return jobId
endfunction

public function RegisterStationType takes integer professionId, integer unitTypeId, string stationName returns nothing
    if not P_IsProfessionValid(professionId) or unitTypeId == 0 then
        return
    endif

    set P_StationProfession.integer[unitTypeId] = professionId
    set P_StationName.string[unitTypeId] = stationName
    set P_RecipeRevision = P_RecipeRevision + 1
endfunction

public function SetProfessionSoundLabels takes integer professionId, string startLabel, string loopLabel, string finishLabel returns nothing
    if not P_IsProfessionValid(professionId) then
        return
    endif

    set P_ProfessionStartSoundLabel[professionId] = startLabel
    set P_ProfessionLoopSoundLabel[professionId] = loopLabel
    set P_ProfessionFinishSoundLabel[professionId] = finishLabel
endfunction

public function SetProfessionSoundHandles takes integer professionId, sound startSound, sound loopSound, sound finishSound returns nothing
    if not P_IsProfessionValid(professionId) then
        return
    endif

    set P_ProfessionStartSound[professionId] = startSound
    set P_ProfessionLoopSound[professionId] = loopSound
    set P_ProfessionFinishSound[professionId] = finishSound
endfunction

public function SetProfessionSoundPaths takes integer professionId, string startPath, string loopPath, string finishPath returns nothing
    if not P_IsProfessionValid(professionId) then
        return
    endif

    set P_ProfessionStartSoundPath[professionId] = startPath
    set P_ProfessionLoopSoundPath[professionId] = loopPath
    set P_ProfessionFinishSoundPath[professionId] = finishPath
endfunction

public function SetProfessionAiCheatCrafting takes integer professionId, boolean enabled returns nothing
    if not P_IsProfessionValid(professionId) then
        return
    endif

    set P_ProfessionAiCheatCrafting[professionId] = enabled
endfunction

public function IsProfessionAiCheatCraftingEnabled takes integer professionId returns boolean
    if not P_IsProfessionValid(professionId) then
        return false
    endif

    return P_ProfessionAiCheatCrafting[professionId]
endfunction

public function SetProfessionCrafterAnimations takes integer professionId, string primaryAnimation, string fallbackAnimation returns nothing
    if not P_IsProfessionValid(professionId) then
        return
    endif

    set P_ProfessionCrafterAnimPrimary[professionId] = primaryAnimation
    set P_ProfessionCrafterAnimFallback[professionId] = fallbackAnimation
endfunction

public function SetProfessionCrafterAnimationsForUnitType takes integer professionId, integer unitTypeId, string primaryAnimation, string fallbackAnimation returns nothing
    local integer key

    if not P_IsProfessionValid(professionId) or unitTypeId == 0 then
        return
    endif

    set key = P_GetCrafterAnimationKey(professionId, unitTypeId)
    set P_CrafterAnimPrimaryByType.string[key] = primaryAnimation
    set P_CrafterAnimFallbackByType.string[key] = fallbackAnimation
endfunction

public function RegisterRecipe takes integer professionId, integer stationTypeId, string recipeName, string description, string iconPath, integer outputItemCode, integer outputCount, integer requiredSkill, real craftTime, real cooldown returns integer
    if not P_IsProfessionValid(professionId) or P_RecipeCount >= P_MAX_RECIPES or outputItemCode == 0 then
        return 0
    endif

    if outputCount <= 0 then
        set outputCount = 1
    endif
    if craftTime < 0.00 then
        set craftTime = 0.00
    endif
    if cooldown < 0.00 then
        set cooldown = 0.00
    endif

    set P_RecipeCount = P_RecipeCount + 1
    set P_RecipeProfessionId[P_RecipeCount] = professionId
    set P_RecipeStationTypeId[P_RecipeCount] = stationTypeId
    set P_RecipeName[P_RecipeCount] = recipeName
    set P_RecipeDescription[P_RecipeCount] = description
    set P_RecipeIcon[P_RecipeCount] = iconPath
    set P_RecipeCategory[P_RecipeCount] = P_DEFAULT_CATEGORY
    set P_RecipeSubcategory[P_RecipeCount] = ""
    set P_RecipeOutputItemCode[P_RecipeCount] = outputItemCode
    set P_RecipeOutputCount[P_RecipeCount] = outputCount
    set P_RecipeRequiredSkill[P_RecipeCount] = requiredSkill
    set P_RecipeCraftTime[P_RecipeCount] = craftTime
    set P_RecipeCooldown[P_RecipeCount] = cooldown
    set P_RecipeSkillGain[P_RecipeCount] = 1
    set P_RecipeRevision = P_RecipeRevision + 1

    return P_RecipeCount
endfunction

public function AddRecipeMaterial takes integer recipeId, integer itemCode, integer amount, string materialName returns nothing
    local integer slot
    local integer key

    if not P_IsRecipeValid(recipeId) or itemCode == 0 or amount <= 0 then
        return
    endif
    if P_RecipeMaterialCount[recipeId] >= MAX_MATERIALS then
        return
    endif

    set slot = P_RecipeMaterialCount[recipeId] + 1
    set key = P_GetMaterialKey(recipeId, slot)
    set P_RecipeMaterialCount[recipeId] = slot
    set P_MaterialItemCode[key] = itemCode
    set P_MaterialAmount[key] = amount
    set P_MaterialName[key] = materialName
    set P_RecipeRevision = P_RecipeRevision + 1
endfunction

public function SetRecipeSkillGain takes integer recipeId, integer amount returns nothing
    if not P_IsRecipeValid(recipeId) then
        return
    endif
    if amount < 0 then
        set amount = 0
    endif
    set P_RecipeSkillGain[recipeId] = amount
endfunction

public function SetRecipeCategoryPath takes integer recipeId, string categoryName, string subcategoryName returns nothing
    if not P_IsRecipeValid(recipeId) then
        return
    endif

    set P_RecipeCategory[recipeId] = P_GetNormalizedCategory(categoryName)
    set P_RecipeSubcategory[recipeId] = P_GetNormalizedSubcategory(subcategoryName)
    set P_RecipeRevision = P_RecipeRevision + 1
endfunction

public function SetRecipeCategory takes integer recipeId, string categoryName returns nothing
    call SetRecipeCategoryPath(recipeId, categoryName, "")
endfunction

public function GetRecipeRevision takes nothing returns integer
    return P_RecipeRevision
endfunction

public function GetRecipeCount takes nothing returns integer
    return P_RecipeCount
endfunction

public function IsRecipeValid takes integer recipeId returns boolean
    return P_IsRecipeValid(recipeId)
endfunction

public function GetRecipeProfessionId takes integer recipeId returns integer
    if not P_IsRecipeValid(recipeId) then
        return GNS_PROF_NONE
    endif
    return P_RecipeProfessionId[recipeId]
endfunction

public function GetRecipeStationTypeId takes integer recipeId returns integer
    if not P_IsRecipeValid(recipeId) then
        return 0
    endif
    return P_RecipeStationTypeId[recipeId]
endfunction

public function GetRecipeName takes integer recipeId returns string
    return P_GetRecipeDisplayName(recipeId)
endfunction

public function GetRecipeDescription takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return ""
    endif
    return P_RecipeDescription[recipeId]
endfunction

public function GetRecipeIcon takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    endif
    if P_RecipeIcon[recipeId] == null or P_RecipeIcon[recipeId] == "" then
        return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    endif
    return P_RecipeIcon[recipeId]
endfunction

public function GetRecipeCategory takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return ""
    endif
    return P_GetRecipeCategoryDisplay(recipeId)
endfunction

public function GetRecipeSubcategory takes integer recipeId returns string
    if not P_IsRecipeValid(recipeId) then
        return ""
    endif
    return P_GetRecipeSubcategoryDisplay(recipeId)
endfunction

public function GetRecipeRequiredSkill takes integer recipeId returns integer
    if not P_IsRecipeValid(recipeId) then
        return 0
    endif
    return P_RecipeRequiredSkill[recipeId]
endfunction

public function GetRecipeCraftTime takes integer recipeId returns real
    if not P_IsRecipeValid(recipeId) then
        return 0.00
    endif
    return P_RecipeCraftTime[recipeId]
endfunction

public function GetRecipeCooldown takes integer recipeId returns real
    if not P_IsRecipeValid(recipeId) then
        return 0.00
    endif
    return P_RecipeCooldown[recipeId]
endfunction

public function GetRecipeOutputItemCode takes integer recipeId returns integer
    if not P_IsRecipeValid(recipeId) then
        return 0
    endif
    return P_RecipeOutputItemCode[recipeId]
endfunction

public function GetRecipeOutputCount takes integer recipeId returns integer
    if not P_IsRecipeValid(recipeId) then
        return 0
    endif
    return P_RecipeOutputCount[recipeId]
endfunction

public function GetRecipeMaterialCount takes integer recipeId returns integer
    if not P_IsRecipeValid(recipeId) then
        return 0
    endif
    return P_RecipeMaterialCount[recipeId]
endfunction

public function GetRecipeMaterialItemCode takes integer recipeId, integer slot returns integer
    if not P_IsRecipeValid(recipeId) or slot <= 0 or slot > P_RecipeMaterialCount[recipeId] then
        return 0
    endif
    return P_MaterialItemCode[P_GetMaterialKey(recipeId, slot)]
endfunction

public function GetRecipeMaterialAmount takes integer recipeId, integer slot returns integer
    if not P_IsRecipeValid(recipeId) or slot <= 0 or slot > P_RecipeMaterialCount[recipeId] then
        return 0
    endif
    return P_MaterialAmount[P_GetMaterialKey(recipeId, slot)]
endfunction

public function GetRecipeMaterialName takes integer recipeId, integer slot returns string
    local integer key

    if not P_IsRecipeValid(recipeId) or slot <= 0 or slot > P_RecipeMaterialCount[recipeId] then
        return ""
    endif

    set key = P_GetMaterialKey(recipeId, slot)
    return P_GetSafeItemName(P_MaterialItemCode[key], P_MaterialName[key])
endfunction

public function CountItem takes unit u, integer itemCode returns integer
    return P_CountItems(u, itemCode)
endfunction

public function ConsumeItem takes unit u, integer itemCode, integer amount returns nothing
    call P_ConsumeItems(u, itemCode, amount)
endfunction

public function GetRecipeMaterialLine takes unit crafter, integer recipeId, integer slot returns string
    local integer key
    local integer have
    local integer need
    local string color

    if not P_IsRecipeValid(recipeId) or slot <= 0 or slot > P_RecipeMaterialCount[recipeId] then
        return ""
    endif

    set key = P_GetMaterialKey(recipeId, slot)
    set have = P_CountItems(crafter, P_MaterialItemCode[key])
    set need = P_MaterialAmount[key]
    if have >= need then
        set color = "|cff80ff80"
    else
        set color = "|cffff8080"
    endif

    return color + P_GetSafeItemName(P_MaterialItemCode[key], P_MaterialName[key]) + "|r |cffbfbfbf" + I2S(have) + "/" + I2S(need) + "|r"
endfunction

public function GetMissingRecipeText takes unit crafter, integer recipeId returns string
    local integer slot = 1
    local integer key
    local integer have
    local string result = ""

    if not P_IsRecipeValid(recipeId) then
        return "Invalid recipe."
    endif

    loop
        exitwhen slot > P_RecipeMaterialCount[recipeId]
        set key = P_GetMaterialKey(recipeId, slot)
        set have = P_CountItems(crafter, P_MaterialItemCode[key])
        if have < P_MaterialAmount[key] then
            if result != "" then
                set result = result + "|n"
            endif
            set result = result + P_GetSafeItemName(P_MaterialItemCode[key], P_MaterialName[key]) + " " + I2S(have) + "/" + I2S(P_MaterialAmount[key])
        endif
        set slot = slot + 1
    endloop

    return result
endfunction

public function GetRecipeCategoryCountForStation takes integer professionId, integer stationTypeId returns integer
    local integer recipeId = 1
    local integer count = 0

    if not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_IsFirstStationCategory(recipeId, professionId, stationTypeId) then
            set count = count + 1
        endif
        set recipeId = recipeId + 1
    endloop

    return count
endfunction

public function GetRecipeCategoryForStationIndex takes integer professionId, integer stationTypeId, integer categoryIndex returns string
    local integer recipeId = 1
    local integer count = 0

    if categoryIndex <= 0 or not P_IsProfessionValid(professionId) then
        return ""
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_IsFirstStationCategory(recipeId, professionId, stationTypeId) then
            set count = count + 1
            if count == categoryIndex then
                return P_GetRecipeCategoryDisplay(recipeId)
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    return ""
endfunction

public function GetRecipeSubcategoryCountForStationCategory takes integer professionId, integer stationTypeId, string categoryName returns integer
    local integer recipeId = 1
    local integer count = 0
    local string category = P_GetNormalizedCategory(categoryName)

    if not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_GetRecipeCategoryDisplay(recipeId) == category and P_IsFirstStationSubcategory(recipeId, professionId, stationTypeId, category) then
            set count = count + 1
        endif
        set recipeId = recipeId + 1
    endloop

    return count
endfunction

public function GetRecipeSubcategoryForStationCategoryIndex takes integer professionId, integer stationTypeId, string categoryName, integer subcategoryIndex returns string
    local integer recipeId = 1
    local integer count = 0
    local string category = P_GetNormalizedCategory(categoryName)

    if subcategoryIndex <= 0 or not P_IsProfessionValid(professionId) then
        return ""
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_GetRecipeCategoryDisplay(recipeId) == category and P_IsFirstStationSubcategory(recipeId, professionId, stationTypeId, category) then
            set count = count + 1
            if count == subcategoryIndex then
                return P_GetRecipeSubcategoryDisplay(recipeId)
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    return ""
endfunction

public function GetRecipeCountForStation takes integer professionId, integer stationTypeId returns integer
    local integer recipeId = 1
    local integer count = 0

    if not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) then
            set count = count + 1
        endif
        set recipeId = recipeId + 1
    endloop

    return count
endfunction

public function GetRecipeIdForStationIndex takes integer professionId, integer stationTypeId, integer listIndex returns integer
    local integer recipeId = 1
    local integer count = 0

    if listIndex <= 0 or not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) then
            set count = count + 1
            if count == listIndex then
                return recipeId
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    return 0
endfunction

public function GetRecipeCountForStationCategory takes integer professionId, integer stationTypeId, string categoryName returns integer
    local integer recipeId = 1
    local integer count = 0

    if not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_RecipeMatchesCategory(recipeId, categoryName) then
            set count = count + 1
        endif
        set recipeId = recipeId + 1
    endloop

    return count
endfunction

public function GetRecipeIdForStationCategoryIndex takes integer professionId, integer stationTypeId, string categoryName, integer listIndex returns integer
    local integer recipeId = 1
    local integer count = 0

    if listIndex <= 0 or not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_RecipeMatchesCategory(recipeId, categoryName) then
            set count = count + 1
            if count == listIndex then
                return recipeId
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    return 0
endfunction

public function GetRecipeCountForStationSubcategory takes integer professionId, integer stationTypeId, string categoryName, string subcategoryName returns integer
    local integer recipeId = 1
    local integer count = 0

    if not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_RecipeMatchesSubcategory(recipeId, categoryName, subcategoryName) then
            set count = count + 1
        endif
        set recipeId = recipeId + 1
    endloop

    return count
endfunction

public function GetRecipeIdForStationSubcategoryIndex takes integer professionId, integer stationTypeId, string categoryName, string subcategoryName, integer listIndex returns integer
    local integer recipeId = 1
    local integer count = 0

    if listIndex <= 0 or not P_IsProfessionValid(professionId) then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_RecipeMatchesSubcategory(recipeId, categoryName, subcategoryName) then
            set count = count + 1
            if count == listIndex then
                return recipeId
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    return 0
endfunction

public function GetStationProfessionByUnitType takes integer unitTypeId returns integer
    if unitTypeId != 0 and P_StationProfession.has(unitTypeId) then
        return P_StationProfession.integer[unitTypeId]
    endif
    return GNS_PROF_NONE
endfunction

public function GetStationProfession takes unit station returns integer
    if station == null then
        return GNS_PROF_NONE
    endif
    return GetStationProfessionByUnitType(GetUnitTypeId(station))
endfunction

public function GetStationNameByUnitType takes integer unitTypeId returns string
    return P_GetStationDisplayName(unitTypeId)
endfunction

public function IsStationUnitType takes integer unitTypeId returns boolean
    return GetStationProfessionByUnitType(unitTypeId) != GNS_PROF_NONE
endfunction

public function IsStationUnit takes unit station returns boolean
    return station != null and IsStationUnitType(GetUnitTypeId(station))
endfunction

public function IsCrafterNearStation takes unit crafter, unit station returns boolean
    return P_IsNearStation(crafter, station)
endfunction

public function IsUnitReserved takes unit crafter returns boolean
    return crafter != null and P_CrafterActiveJob.has(GetHandleId(crafter))
endfunction

public function IsStationReserved takes unit station returns boolean
    return station != null and P_StationActiveJob.has(GetHandleId(station))
endfunction

public function IsUnitAiCrafting takes unit crafter returns boolean
    local integer jobId

    if crafter == null then
        return false
    endif
    if not P_CrafterActiveJob.has(GetHandleId(crafter)) then
        return false
    endif

    set jobId = P_CrafterActiveJob.integer[GetHandleId(crafter)]
    return P_JobAiControlled[jobId]
endfunction

public function CancelUnitCraft takes unit crafter returns boolean
    local integer jobId

    if crafter == null then
        return false
    endif
    if not P_CrafterActiveJob.has(GetHandleId(crafter)) then
        return false
    endif

    set jobId = P_CrafterActiveJob.integer[GetHandleId(crafter)]
    call P_CancelJob(jobId)
    return true
endfunction

public function CanStartRecipe takes unit crafter, unit station, integer recipeId returns boolean
    return P_CheckStartRequirements(crafter, station, recipeId, false, false, true)
endfunction

public function CanStartRecipeForAi takes unit crafter, unit station, integer recipeId returns boolean
    local integer professionId

    if not P_IsRecipeValid(recipeId) then
        return false
    endif

    set professionId = P_RecipeProfessionId[recipeId]
    return P_CheckStartRequirements(crafter, station, recipeId, false, P_ProfessionAiCheatCrafting[professionId], false)
endfunction

public function GetAiRecipeForStation takes unit crafter, unit station returns integer
    local integer recipeId = 1
    local integer professionId
    local integer stationTypeId
    local integer selectedRecipe = 0
    local integer seen = 0
    local boolean ignoreMaterials

    if crafter == null or station == null then
        return 0
    endif

    set professionId = GetStationProfession(station)
    set stationTypeId = GetUnitTypeId(station)
    if not P_IsProfessionValid(professionId) then
        return 0
    endif

    set ignoreMaterials = P_ProfessionAiCheatCrafting[professionId]
    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeMatchesStation(recipeId, professionId, stationTypeId) and P_CheckStartRequirements(crafter, station, recipeId, false, ignoreMaterials, false) then
            set seen = seen + 1
            if GetRandomInt(1, seen) == 1 then
                set selectedRecipe = recipeId
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    return selectedRecipe
endfunction

public function GetLastErrorText takes nothing returns string
    return P_LastErrorText
endfunction

private function P_StartRecipeInternal takes unit crafter, unit station, integer recipeId, boolean aiControlled returns boolean
    local integer jobId
    local integer professionId
    local boolean ignoreMaterials
    local player owner

    if not P_IsRecipeValid(recipeId) then
        set professionId = GNS_PROF_NONE
        set ignoreMaterials = false
    else
        set professionId = P_RecipeProfessionId[recipeId]
        set ignoreMaterials = aiControlled and P_ProfessionAiCheatCrafting[professionId]
    endif

    if not P_CheckStartRequirements(crafter, station, recipeId, not aiControlled, ignoreMaterials, not aiControlled) then
        if not aiControlled and crafter != null then
            set owner = GetOwningPlayer(crafter)
            if owner != null and P_LastErrorText != "" then
                call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffff8080" + P_LastErrorText + "|r")
            endif
        endif
        set owner = null
        return false
    endif

    set jobId = P_CreateReservedJob(crafter, station, recipeId, aiControlled, ignoreMaterials)
    if aiControlled then
        call P_StartAiCraftPreparation(jobId)
    else
        call P_StartPlayerCraftPreparation(jobId)
    endif

    set owner = null
    return true
endfunction

public function StartRecipe takes unit crafter, unit station, integer recipeId returns boolean
    return P_StartRecipeInternal(crafter, station, recipeId, false)
endfunction

public function StartRecipeForAi takes unit crafter, unit station, integer recipeId returns boolean
    return P_StartRecipeInternal(crafter, station, recipeId, true)
endfunction

public function GetProfessionSummary takes unit viewer, integer professionId returns string
    local integer recipeId = 1
    local integer total = 0
    local integer skillReady = 0
    local integer materialReady = 0
    local integer currentSkill = GetEffectiveSkill(viewer, professionId)
    local integer nextSkill = 100000
    local integer nextRecipe = 0
    local string result

    if not P_IsProfessionValid(professionId) then
        return ""
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeProfessionId[recipeId] == professionId then
            set total = total + 1
            if currentSkill >= P_RecipeRequiredSkill[recipeId] then
                set skillReady = skillReady + 1
            elseif P_RecipeRequiredSkill[recipeId] < nextSkill then
                set nextSkill = P_RecipeRequiredSkill[recipeId]
                set nextRecipe = recipeId
            endif
            if viewer != null and P_HasMaterials(viewer, recipeId) then
                set materialReady = materialReady + 1
            endif
        endif
        set recipeId = recipeId + 1
    endloop

    if total <= 0 then
        return "Crafting:|n|cffbfbfbfNo recipes configured yet.|r"
    endif

    set result = "Crafting:|n|cff80ff80" + I2S(skillReady) + "|r|cffbfbfbf/" + I2S(total) + " recipes usable by skill|r"
    if viewer != null then
        set result = result + "|n|cff80ff80" + I2S(materialReady) + "|r|cffbfbfbf/" + I2S(total) + " recipes have materials ready|r"
    endif
    if nextRecipe != 0 then
        set result = result + "|n|cffbfbfbfNext recipe: " + P_GetRecipeDisplayName(nextRecipe) + " (" + I2S(nextSkill) + ")|r"
    endif

    return result
endfunction

public function Init takes nothing returns nothing
    if P_Initialized then
        return
    endif
    set P_Initialized = true

    set P_StationProfession = Table.create()
    set P_StationName = Table.create()
    set P_CrafterActiveJob = Table.create()
    set P_StationActiveJob = Table.create()
    set P_CooldownUntil = Table.create()
    set P_StationByHandle = Table.create()
    set P_AlchemyGeneration = Table.create()
    set P_AlchemyPostCraft = Table.create()
    set P_AlchemyTimerStation = Table.create()
    set P_AlchemyTimerStage = Table.create()
    set P_AlchemyTimerGeneration = Table.create()
    set P_CrafterAnimPrimaryByType = Table.create()
    set P_CrafterAnimFallbackByType = Table.create()
    set P_ClockTimer = CreateTimer()
    set P_AttackedTrigger = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(P_AttackedTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerAddAction(P_AttackedTrigger, function P_CrafterAttackedAction)
    call TimerStart(P_ClockTimer, 999999.00, false, function P_NoOp)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
