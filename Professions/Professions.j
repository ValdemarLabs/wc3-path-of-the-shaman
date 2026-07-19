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
    call Professions_StartRecipe(whichCrafter, whichStation, recipeId)
    call Professions_GetProfessionSummary(whichCrafter, GNS_PROF_ALCHEMY)

**/

library Professions initializer AutoInit requires GatherNodeSkills, TimerUtils, Table, optional SharedDInvLib, optional ItemHook

globals
    public constant integer RESULT_OK = 0
    public constant integer RESULT_INVALID = 1
    public constant integer RESULT_NOT_READY = 2
    public constant integer RESULT_MISSING_MATERIALS = 3

    public constant integer MAX_MATERIALS = 6

    private constant integer P_MAX_RECIPES = 256
    private constant integer P_MAX_PROFESSION_ID = GNS_PROF_COOKING
    private constant integer P_ALCHEMY_LIGHT_ABILITY = 'A6DJ'
    private constant real P_STATION_USE_RANGE = 375.00
    private constant real P_SOUND_CUTOFF = 1300.00
    private constant real P_ALCHEMY_DECAY_DELAY = 10.00

    private boolean P_Initialized = false
    private integer P_RecipeCount = 0
    private integer P_RecipeRevision = 0
    private integer P_JobCount = 0
    private string P_LastErrorText = ""

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

    private integer array P_MaterialItemCode
    private integer array P_MaterialAmount
    private string array P_MaterialName

    private unit array P_JobCrafter
    private unit array P_JobStation
    private integer array P_JobRecipe
    private sound array P_JobLoopSound

    private string array P_ProfessionStartSoundLabel
    private string array P_ProfessionLoopSoundLabel
    private string array P_ProfessionFinishSoundLabel

    private Table P_StationProfession = 0
    private Table P_StationName = 0
    private Table P_CrafterActiveJob = 0
    private Table P_StationActiveJob = 0
    private Table P_CooldownUntil = 0
    private Table P_StationByHandle = 0
    private timer P_ClockTimer = null
endglobals

private function P_GetMaterialKey takes integer recipeId, integer slot returns integer
    return recipeId * MAX_MATERIALS + slot
endfunction

private function P_NoOp takes nothing returns nothing
endfunction

private function P_GetCooldownKey takes unit crafter, integer recipeId returns integer
    return StringHash(I2S(GetHandleId(crafter)) + ":" + I2S(recipeId))
endfunction

private function P_IsProfessionValid takes integer professionId returns boolean
    return professionId > GNS_PROF_NONE and professionId <= P_MAX_PROFESSION_ID
endfunction

private function P_IsRecipeValid takes integer recipeId returns boolean
    return recipeId > 0 and recipeId <= P_RecipeCount
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

private function P_GetStationDisplayName takes integer unitTypeId returns string
    if unitTypeId != 0 and P_StationName.has(unitTypeId) then
        return P_StationName.string[unitTypeId]
    endif
    if unitTypeId != 0 then
        return GetObjectName(unitTypeId)
    endif
    return "Workstation"
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
    local real dx
    local real dy

    if crafter == null or station == null then
        return false
    endif

    set dx = GetUnitX(crafter) - GetUnitX(station)
    set dy = GetUnitY(crafter) - GetUnitY(station)
    return dx * dx + dy * dy <= P_STATION_USE_RANGE * P_STATION_USE_RANGE
endfunction

private function P_PlaySoundLabelOnUnit takes string soundLabel, unit whichUnit, boolean looping returns sound
    local sound s

    if soundLabel == null or soundLabel == "" or whichUnit == null then
        return null
    endif

    set s = CreateSoundFromLabel(soundLabel, looping, true, true, 12700, 12700)
    if s == null then
        return null
    endif

    call SetSoundDistances(s, 0.00, P_SOUND_CUTOFF)
    call SetSoundDistanceCutoff(s, P_SOUND_CUTOFF)
    call AttachSoundToUnit(s, whichUnit)
    call SetSoundVolume(s, 127)
    call StartSound(s)
    if not looping then
        call KillSoundWhenDone(s)
    endif

    return s
endfunction

private function P_StartLoopSound takes integer professionId, unit station returns sound
    if not P_IsProfessionValid(professionId) then
        return null
    endif
    return P_PlaySoundLabelOnUnit(P_ProfessionLoopSoundLabel[professionId], station, true)
endfunction

private function P_StopLoopSound takes sound whichSound returns nothing
    if whichSound != null then
        call StopSound(whichSound, false, true)
    endif
endfunction

private function P_PlayStartSound takes integer professionId, unit station returns nothing
    if P_IsProfessionValid(professionId) then
        call P_PlaySoundLabelOnUnit(P_ProfessionStartSoundLabel[professionId], station, false)
    endif
endfunction

private function P_PlayFinishSound takes integer professionId, unit station returns nothing
    if P_IsProfessionValid(professionId) then
        call P_PlaySoundLabelOnUnit(P_ProfessionFinishSoundLabel[professionId], station, false)
    endif
endfunction

private function P_AlchemyDecayAction takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer stationId = GetTimerData(t)
    local unit station = P_StationByHandle.unit[stationId]

    if station != null and GetUnitTypeId(station) != 0 then
        call SetUnitAnimation(station, "decay")
    endif

    call P_StationByHandle.unit.remove(stationId)
    call ReleaseTimer(t)

    set station = null
    set t = null
endfunction

private function P_ScheduleAlchemyDecay takes unit station returns nothing
    local timer t
    local integer stationId

    if station == null or GetUnitTypeId(station) == 0 then
        return
    endif

    set stationId = GetHandleId(station)
    set P_StationByHandle.unit[stationId] = station
    set t = NewTimerEx(stationId)
    call TimerStart(t, P_ALCHEMY_DECAY_DELAY, false, function P_AlchemyDecayAction)

    set t = null
endfunction

private function P_StartStationFeedback takes integer professionId, unit station returns nothing
    if station == null then
        return
    endif

    if professionId == GNS_PROF_ALCHEMY then
        call SetUnitAnimation(station, "stand")
        call UnitAddAbility(station, P_ALCHEMY_LIGHT_ABILITY)
    elseif professionId == GNS_PROF_BLACKSMITHING then
        call SetUnitAnimation(station, "attack")
    elseif professionId == GNS_PROF_MINING then
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
        call UnitRemoveAbility(station, P_ALCHEMY_LIGHT_ABILITY)
        call SetUnitAnimation(station, "death")
        call P_ScheduleAlchemyDecay(station)
    else
        call SetUnitAnimation(station, "stand")
    endif
endfunction

private function P_CreateCraftedItem takes unit crafter, unit station, integer itemCode, integer amount returns item
    local real x = 0.00
    local real y = 0.00
    local item result

    if crafter != null and GetUnitTypeId(crafter) != 0 then
        set x = GetUnitX(crafter)
        set y = GetUnitY(crafter)
    elseif station != null and GetUnitTypeId(station) != 0 then
        set x = GetUnitX(station)
        set y = GetUnitY(station)
    endif

    static if LIBRARY_ItemHook then
        set result = ItemHook_CreateItem(itemCode, x, y)
    else
        set result = CreateItem(itemCode, x, y)
    endif

    if result != null and amount > 1 then
        call SetItemCharges(result, amount)
    endif

    return result
endfunction

private function P_CheckStartRequirements takes unit crafter, unit station, integer recipeId, boolean explain returns boolean
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

    if crafter == null or GetUnitTypeId(crafter) == 0 then
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

    if not P_IsNearStation(crafter, station) then
        if explain then
            set P_LastErrorText = GetUnitName(crafter) + " is too far from the " + P_GetStationDisplayName(GetUnitTypeId(station)) + "."
        endif
        return false
    endif

    if GNS_GetSkill(crafter, professionId) < P_RecipeRequiredSkill[recipeId] then
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
            set P_LastErrorText = "That " + P_GetStationDisplayName(GetUnitTypeId(station)) + " is already in use."
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

    if not P_HasMaterials(crafter, recipeId) then
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

    if P_IsRecipeValid(recipeId) then
        set professionId = P_RecipeProfessionId[recipeId]
        call P_StopLoopSound(P_JobLoopSound[jobId])
        call P_PlayFinishSound(professionId, station)
        call P_FinishStationFeedback(professionId, station)
        set createdItem = P_CreateCraftedItem(crafter, station, P_RecipeOutputItemCode[recipeId], P_RecipeOutputCount[recipeId])
        call GNS_AwardGatherSkillForNode(crafter, professionId, P_RecipeRequiredSkill[recipeId], P_RecipeSkillGain[recipeId])
        if crafter != null then
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

    set P_JobCrafter[jobId] = null
    set P_JobStation[jobId] = null
    set P_JobRecipe[jobId] = 0
    set P_JobLoopSound[jobId] = null

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

public function GetRecipeCountForStation takes integer professionId, integer stationTypeId returns integer
    local integer recipeId = 1
    local integer count = 0

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeProfessionId[recipeId] == professionId and (stationTypeId == 0 or P_RecipeStationTypeId[recipeId] == stationTypeId) then
            set count = count + 1
        endif
        set recipeId = recipeId + 1
    endloop

    return count
endfunction

public function GetRecipeIdForStationIndex takes integer professionId, integer stationTypeId, integer listIndex returns integer
    local integer recipeId = 1
    local integer count = 0

    if listIndex <= 0 then
        return 0
    endif

    loop
        exitwhen recipeId > P_RecipeCount
        if P_RecipeProfessionId[recipeId] == professionId and (stationTypeId == 0 or P_RecipeStationTypeId[recipeId] == stationTypeId) then
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

public function CanStartRecipe takes unit crafter, unit station, integer recipeId returns boolean
    return P_CheckStartRequirements(crafter, station, recipeId, false)
endfunction

public function GetLastErrorText takes nothing returns string
    return P_LastErrorText
endfunction

public function StartRecipe takes unit crafter, unit station, integer recipeId returns boolean
    local timer t
    local integer jobId
    local integer professionId
    local integer cooldownKey
    local player owner

    if not P_CheckStartRequirements(crafter, station, recipeId, true) then
        if crafter != null then
            set owner = GetOwningPlayer(crafter)
            if owner != null and P_LastErrorText != "" then
                call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffff8080" + P_LastErrorText + "|r")
            endif
        endif
        set owner = null
        return false
    endif

    set professionId = P_RecipeProfessionId[recipeId]
    call P_ConsumeRecipeMaterials(crafter, recipeId)

    if P_RecipeCooldown[recipeId] > 0.00 then
        set cooldownKey = P_GetCooldownKey(crafter, recipeId)
        set P_CooldownUntil.real[cooldownKey] = P_GetNow() + P_RecipeCooldown[recipeId]
    endif

    if P_JobCount >= 8000 then
        set P_JobCount = 0
    endif
    set P_JobCount = P_JobCount + 1
    set jobId = P_JobCount
    set P_JobCrafter[jobId] = crafter
    set P_JobStation[jobId] = station
    set P_JobRecipe[jobId] = recipeId
    set P_CrafterActiveJob.integer[GetHandleId(crafter)] = jobId
    set P_StationActiveJob.integer[GetHandleId(station)] = jobId

    call P_PlayStartSound(professionId, station)
    set P_JobLoopSound[jobId] = P_StartLoopSound(professionId, station)
    call P_StartStationFeedback(professionId, station)

    set owner = GetOwningPlayer(crafter)
    if owner != null then
        call DisplayTextToPlayer(owner, 0.00, 0.00, "|cffffcc00Crafting:|r " + P_GetRecipeDisplayName(recipeId))
    endif

    set t = NewTimerEx(jobId)
    call TimerStart(t, P_RecipeCraftTime[recipeId], false, function P_FinishJobAction)

    set owner = null
    set t = null
    return true
endfunction

public function GetProfessionSummary takes unit viewer, integer professionId returns string
    local integer recipeId = 1
    local integer total = 0
    local integer skillReady = 0
    local integer materialReady = 0
    local integer currentSkill = GNS_GetSkill(viewer, professionId)
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
    set P_ClockTimer = CreateTimer()
    call TimerStart(P_ClockTimer, 999999.00, false, function P_NoOp)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
