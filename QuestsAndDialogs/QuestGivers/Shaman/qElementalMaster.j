/**
    qElementalMaster

    Author: Valdemar
    Version:

    Description:
    Adds the four Summon Elemental rank quests to every Elemental Master.
    Each accepted quest remains bound to its exact trainer for turn-in.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/ShamanElemental.

    How to install:
    Import after QuestGiver, AbilityTrainerDialogs, Abilities, and Events.
    Disable the four old Quest Elemental GUI trigger groups.

    API:
    - qElementalMaster_RefreshAvailability()

**/
library qElementalMaster initializer Init requires QuestGiver, QuestMaster, AbilityTrainerDialogs, AbilityTrainerLines, Abilities, AbilitiesPlayer, HeroItemCheck, Events

globals
    private constant boolean DEBUG = false

    public constant string QUEST_ELEMENT_AIR = "Element of Air"
    public constant string QUEST_ELEMENT_EARTH = "Element of Earth"
    public constant string QUEST_ELEMENT_FIRE = "Element of Fire"
    public constant string QUEST_ELEMENT_WATER = "Element of Water"

    private constant integer ABILITY_SUMMON_ELEMENTAL = 'A67Q'
    private constant integer ITEM_ESSENCE_AIR = 'I6C7'
    private constant integer ITEM_ESSENCE_EARTH = 'I6C8'
    private constant integer ITEM_ESSENCE_FIRE = 'I6C5'
    private constant integer ITEM_ESSENCE_WATER = 'I6C6'

    private constant integer MAX_TRAINERS = 24
    private unit array ElementalTrainer
    private integer ElementalTrainerCount = 0
    private trigger array RankCondition
    private boolean RefreshingAvailability = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff69ccf0[qElementalMaster]|r " + msg)
    endif
endfunction

private function GetQuestName takes integer rank returns string
    if rank == 1 then
        return QUEST_ELEMENT_AIR
    elseif rank == 2 then
        return QUEST_ELEMENT_EARTH
    elseif rank == 3 then
        return QUEST_ELEMENT_FIRE
    elseif rank == 4 then
        return QUEST_ELEMENT_WATER
    endif
    return ""
endfunction

private function GetElementName takes integer rank returns string
    if rank == 1 then
        return "Air"
    elseif rank == 2 then
        return "Earth"
    elseif rank == 3 then
        return "Fire"
    elseif rank == 4 then
        return "Water"
    endif
    return ""
endfunction

private function GetEssenceItemType takes integer rank returns integer
    if rank == 1 then
        return ITEM_ESSENCE_AIR
    elseif rank == 2 then
        return ITEM_ESSENCE_EARTH
    elseif rank == 3 then
        return ITEM_ESSENCE_FIRE
    elseif rank == 4 then
        return ITEM_ESSENCE_WATER
    endif
    return 0
endfunction

private function GetQuestIcon takes integer rank returns string
    if rank == 1 then
        return "ReplaceableTextures\\CommandButtons\\BTNTornado.blp"
    elseif rank == 2 then
        return "ReplaceableTextures\\CommandButtons\\BTNRockGolem.blp"
    elseif rank == 3 then
        return "ReplaceableTextures\\CommandButtons\\BTNLavaSpawn.blp"
    elseif rank == 4 then
        return "ReplaceableTextures\\CommandButtons\\BTNSummonWaterElemental.blp"
    endif
    return "ReplaceableTextures\\CommandButtons\\BTNEssenceOfMagic.blp"
endfunction

private function HasElementalSpecialization takes unit hero returns boolean
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(ABILITY_SUMMON_ELEMENTAL)
    local integer requiredAbilityId

    if hero == null or entryIndex == 0 then
        return false
    endif
    set requiredAbilityId = AbilitiesPlayer_GetEntryRequiredAbilityId(entryIndex)
    return requiredAbilityId != 0 and GetUnitAbilityLevel(hero, requiredAbilityId) > 0
endfunction

private function CanHeroStartRank takes unit hero, integer rank returns boolean
    return hero != null and HasElementalSpecialization(hero) and GetUnitAbilityLevel(hero, ABILITY_SUMMON_ELEMENTAL) == rank - 1
endfunction

private function IsRankActive takes integer rank returns boolean
    local integer trainerIndex = 1
    local QuestData q

    loop
        exitwhen trainerIndex > ElementalTrainerCount
        set q = QuestGiver_GetByNameAndGiver(GetQuestName(rank), ElementalTrainer[trainerIndex])
        if q != 0 and q.active and not q.completed then
            set q = 0
            return true
        endif
        set trainerIndex = trainerIndex + 1
    endloop

    set q = 0
    return false
endfunction

private function CanAnyHeroStartRank takes integer rank returns boolean
    if IsRankActive(rank) then
        return false
    endif
    return CanHeroStartRank(udg_Nazgrek, rank) or CanHeroStartRank(udg_Zulkis, rank)
endfunction

private function CanStartAir takes nothing returns boolean
    return CanAnyHeroStartRank(1)
endfunction

private function CanStartEarth takes nothing returns boolean
    return CanAnyHeroStartRank(2)
endfunction

private function CanStartFire takes nothing returns boolean
    return CanAnyHeroStartRank(3)
endfunction

private function CanStartWater takes nothing returns boolean
    return CanAnyHeroStartRank(4)
endfunction

private function RefreshAllTrainerAvailability takes nothing returns nothing
    local integer trainerIndex = 1

    if RefreshingAvailability then
        return
    endif
    set RefreshingAvailability = true
    loop
        exitwhen trainerIndex > ElementalTrainerCount
        call QuestGiver_RefreshAvailabilityForGiver(ElementalTrainer[trainerIndex])
        set trainerIndex = trainerIndex + 1
    endloop
    set RefreshingAvailability = false
endfunction

private function CreateRankQuest takes unit trainer, integer rank returns nothing
    local QuestData q
    local string elementName = GetElementName(rank)
    local string questName = GetQuestName(rank)
    local string infoText = "|cffffcc00Quest giver:|r Elemental Master\n|cffffcc00Category:|r Shaman class quest\n"
    local string description

    if trainer == null or questName == "" or QuestGiver_QuestExistsByNameAndGiver(questName, trainer) then
        set trainer = null
        return
    endif

    set description = "Defeat a " + elementName + " Elemental and claim its Essence of " + elementName + ". Elementals are scarce and dangerous; the mightiest among them are the most likely to carry a concentrated essence. Return the essence to this same Elemental Master to form the covenant.\n\n"
    set q = QuestGiver_CreateConfiguredQuest(questName, trainer, "normal", 6, null, questName, GetQuestIcon(rank), description, infoText, "|cffffcc00Reward:|r Summon " + elementName + " Elemental\n\n", 1, true, true, true, "", "Elemental Master")
    call QuestGiver_SetQuestCategory(q, "class")
    call QuestGiver_SetQuestRewards(q, false, 0, false, 0, false, 0, false, 0, false)
    call QuestGiver_SetRequirements(q.id, "", "Bring an Essence of " + elementName + " to this Elemental Master", "", "", "", "", "", "", "")
    call QuestGiver_RegisterItemRequirement(q.id, trainer, 1, GetEssenceItemType(rank), 1)
    call QuestGiver_SetQuestCustomCondition(q, RankCondition[rank])

    set q = 0
    set trainer = null
endfunction

private function RegisterTrainer takes unit trainer returns nothing
    local integer trainerIndex = 1
    local integer rank = 1

    if trainer == null or GetUnitTypeId(trainer) != AbilitiesPlayer_TRAINER_ELEMENTAL then
        set trainer = null
        return
    endif
    loop
        exitwhen trainerIndex > ElementalTrainerCount
        if ElementalTrainer[trainerIndex] == trainer then
            set trainer = null
            return
        endif
        set trainerIndex = trainerIndex + 1
    endloop
    if ElementalTrainerCount >= MAX_TRAINERS then
        call DebugMsg("Maximum Elemental Master count reached.")
        set trainer = null
        return
    endif

    set ElementalTrainerCount = ElementalTrainerCount + 1
    set ElementalTrainer[ElementalTrainerCount] = trainer
    call QuestGiver_Register(trainer)
    loop
        exitwhen rank > 4
        call CreateRankQuest(trainer, rank)
        set rank = rank + 1
    endloop
    call QuestGiver_RefreshAvailabilityForGiver(trainer)
    set trainer = null
endfunction

private function RegisterExistingTrainers takes nothing returns nothing
    local group worldUnits = CreateGroup()
    local rect worldBounds = GetWorldBounds()
    local unit enumUnit

    call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
    loop
        set enumUnit = FirstOfGroup(worldUnits)
        exitwhen enumUnit == null
        call GroupRemoveUnit(worldUnits, enumUnit)
        call RegisterTrainer(enumUnit)
    endloop

    call DestroyGroup(worldUnits)
    call RemoveRect(worldBounds)
    set worldUnits = null
    set worldBounds = null
    set enumUnit = null
endfunction

private function ReportUnable takes unit trainer, string text returns nothing
    call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080" + text + "|r")
    call AbilityTrainerLines_PlayUnableLine(trainer)
    set trainer = null
endfunction

private function AcceptRank takes integer rank returns nothing
    local unit trainer = AbilityTrainerDialogs_GetSelectedTrainer()
    local unit hero = AbilityTrainerDialogs_GetSelectedHero()

    if trainer == null or GetUnitTypeId(trainer) != AbilitiesPlayer_TRAINER_ELEMENTAL or not CanHeroStartRank(hero, rank) or IsRankActive(rank) then
        call ReportUnable(trainer, "This elemental covenant is not available.")
    else
        call QuestGiver_AcceptQuestByNameAndGiver(GetQuestName(rank), trainer)
        call RefreshAllTrainerAvailability()
    endif
    call AbilityTrainerDialogs_RefreshDialog()

    set trainer = null
    set hero = null
endfunction

private function CompleteRank takes integer rank returns nothing
    local unit trainer = AbilityTrainerDialogs_GetSelectedTrainer()
    local unit hero = AbilityTrainerDialogs_GetSelectedHero()
    local integer itemTypeId = GetEssenceItemType(rank)
    local QuestData q

    if trainer == null or GetUnitTypeId(trainer) != AbilitiesPlayer_TRAINER_ELEMENTAL then
        call ReportUnable(trainer, "Return to the Elemental Master who began this covenant.")
        set trainer = null
        set hero = null
        return
    endif
    set q = QuestGiver_GetByNameAndGiver(GetQuestName(rank), trainer)
    if q == 0 or not q.active or q.completed or q.state != QUEST_STATE_READY_TURNIN then
        call ReportUnable(trainer, "Return to the Elemental Master who began this covenant.")
    elseif not CanHeroStartRank(hero, rank) then
        call ReportUnable(trainer, "The Elemental specialization and each earlier covenant are required.")
    elseif not HeroItemCheckBothAndRemove(itemTypeId, 1) then
        call ReportUnable(trainer, "The required elemental essence is missing.")
    elseif Abilities_GrantQuestAbilityRank(hero, ABILITY_SUMMON_ELEMENTAL, rank) then
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(GetQuestName(rank), trainer)
        call AbilityTrainerLines_PlayLearnedLine(trainer)
        call RefreshAllTrainerAvailability()
    endif
    call AbilityTrainerDialogs_RefreshDialog()

    set q = 0
    set trainer = null
    set hero = null
endfunction

private function AcceptAir takes nothing returns nothing
    call AcceptRank(1)
endfunction

private function AcceptEarth takes nothing returns nothing
    call AcceptRank(2)
endfunction

private function AcceptFire takes nothing returns nothing
    call AcceptRank(3)
endfunction

private function AcceptWater takes nothing returns nothing
    call AcceptRank(4)
endfunction

private function CompleteAir takes nothing returns nothing
    call CompleteRank(1)
endfunction

private function CompleteEarth takes nothing returns nothing
    call CompleteRank(2)
endfunction

private function CompleteFire takes nothing returns nothing
    call CompleteRank(3)
endfunction

private function CompleteWater takes nothing returns nothing
    call CompleteRank(4)
endfunction

private function BuildTrainerDialog takes nothing returns nothing
    local dialog d = AbilityTrainerDialogs_GetDialog()
    local unit trainer = AbilityTrainerDialogs_GetSelectedTrainer()
    local unit hero = AbilityTrainerDialogs_GetSelectedHero()

    if d == null or trainer == null or GetUnitTypeId(trainer) != AbilitiesPlayer_TRAINER_ELEMENTAL then
        set d = null
        set trainer = null
        set hero = null
        return
    endif

    call RegisterTrainer(trainer)
    call RefreshAllTrainerAvailability()

    if CanHeroStartRank(hero, 1) and not IsRankActive(1) then
        call QuestGiver_AddAvailableQuestAcceptButton(d, QUEST_ELEMENT_AIR, trainer, 101, function AcceptAir, true, false)
    endif
    if CanHeroStartRank(hero, 2) and not IsRankActive(2) then
        call QuestGiver_AddAvailableQuestAcceptButton(d, QUEST_ELEMENT_EARTH, trainer, 102, function AcceptEarth, true, false)
    endif
    if CanHeroStartRank(hero, 3) and not IsRankActive(3) then
        call QuestGiver_AddAvailableQuestAcceptButton(d, QUEST_ELEMENT_FIRE, trainer, 103, function AcceptFire, true, false)
    endif
    if CanHeroStartRank(hero, 4) and not IsRankActive(4) then
        call QuestGiver_AddAvailableQuestAcceptButton(d, QUEST_ELEMENT_WATER, trainer, 104, function AcceptWater, true, false)
    endif

    call QuestGiver_AddReadyQuestCompleteButton(d, QUEST_ELEMENT_AIR, trainer, 111, function CompleteAir, true)
    call QuestGiver_AddReadyQuestCompleteButton(d, QUEST_ELEMENT_EARTH, trainer, 112, function CompleteEarth, true)
    call QuestGiver_AddReadyQuestCompleteButton(d, QUEST_ELEMENT_FIRE, trainer, 113, function CompleteFire, true)
    call QuestGiver_AddReadyQuestCompleteButton(d, QUEST_ELEMENT_WATER, trainer, 114, function CompleteWater, true)

    set d = null
    set trainer = null
    set hero = null
endfunction

private function IsManagedQuest takes integer questId returns boolean
    local integer trainerIndex = 1
    local integer rank
    local QuestData q

    loop
        exitwhen trainerIndex > ElementalTrainerCount
        set rank = 1
        loop
            exitwhen rank > 4
            set q = QuestGiver_GetByNameAndGiver(GetQuestName(rank), ElementalTrainer[trainerIndex])
            if q != 0 and q.id == questId then
                set q = 0
                return true
            endif
            set rank = rank + 1
        endloop
        set trainerIndex = trainerIndex + 1
    endloop

    set q = 0
    return false
endfunction

private function OnQuestStateChanged takes nothing returns nothing
    local integer questId = QuestGiver_GetEventQuestId()
    local QuestData q

    if not RefreshingAvailability and IsManagedQuest(questId) then
        set q = QuestMaster_GetById(questId)
        if q != 0 and q.state == QUEST_STATE_AVAILABLE and q.discovered and not q.active and not q.completed and not q.failed then
            call q.setDiscovered(false)
        endif
        call RefreshAllTrainerAvailability()
    endif
    set q = 0
endfunction

private function OnUnitEnter takes nothing returns nothing
    call RegisterTrainer(GetTriggerUnit())
endfunction

private function InitDelayed takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()

    call RegisterExistingTrainers()
    call Events_RegisterUnitEnter(function OnUnitEnter)
    call RefreshAllTrainerAvailability()

    call DestroyTimer(expiredTimer)
    set expiredTimer = null
endfunction

private function Init takes nothing returns nothing
    local timer initTimer = CreateTimer()

    set RankCondition[1] = CreateTrigger()
    call TriggerAddCondition(RankCondition[1], Condition(function CanStartAir))
    set RankCondition[2] = CreateTrigger()
    call TriggerAddCondition(RankCondition[2], Condition(function CanStartEarth))
    set RankCondition[3] = CreateTrigger()
    call TriggerAddCondition(RankCondition[3], Condition(function CanStartFire))
    set RankCondition[4] = CreateTrigger()
    call TriggerAddCondition(RankCondition[4], Condition(function CanStartWater))

    call AbilityTrainerDialogs_RegisterDialogBuilder(function BuildTrainerDialog)
    call QuestMaster_AddStateChangedAction(function OnQuestStateChanged)
    call TimerStart(initTimer, 0.00, false, function InitDelayed)
    set initTimer = null
endfunction

public function RefreshAvailability takes nothing returns nothing
    call RefreshAllTrainerAvailability()
endfunction

endlibrary
