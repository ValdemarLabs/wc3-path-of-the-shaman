/**
    qANightToRemember

    Author: Valdemar
    Version: 2.1.0

    Description:
    Creates a repeatable, self-completing hangover quest. Each run asks the
    affected hero to question the other player hero when available and three
    random witnesses drawn from the active AI company and placed Horde vendors.
    One or two witnesses may require a small amends task before forgiving the
    hero.

    Credits:
    - QuestGiver, QuestMaster, DialogInteraction, and DialogSystem

    How to install:
    Import after Drunk, QuestGiver, Companions, AI, HeroItemCheck,
    UnitDeathEvent, VoicelinesDrunk, and VoicelinesQuests. Eligible vendor
    qXXX libraries call RegisterVendorType during Init. VendorDialogs exposes
    this library's contextual buttons.

    API:
    call qANightToRemember_RegisterVendorType(unitTypeId, voiceType, firstIndex)
    call qANightToRemember_AddVendorDialogButton(d, vendor, hero, actionFunc)
    call qANightToRemember_BeginVendorTalk(vendor, hero) returns integer
    call qANightToRemember_FinishVendorTalk()
    call qANightToRemember_CancelVendorTalk()

**/
library qANightToRemember initializer Init requires Drunk, QuestGiver, QuestMaster, DialogInteraction, DialogSystem, VendorLines, VoicelinesDrunk, VoicelinesQuests, Companions, AI, HeroItemCheck, UnitDeathEvent

globals
    private constant string NTR_QUEST_NAME = "A Night To Remember"
    private constant string NTR_ICON = "ReplaceableTextures\\CommandButtons\\BTNPotionOfOmniscience.blp"
    private constant integer NTR_MAX_VENDOR_TYPES = 15
    private constant integer NTR_MAX_WORLD_VENDORS = 64
    private constant integer NTR_MAX_COMPANY_HEROES = 8
    private constant integer NTR_TARGET_COUNT = 3
    private constant integer NTR_VENDOR_ACTION = 31001
    private constant real NTR_TALK_RANGE = 900.00

    private constant integer NTR_STAGE_TALK = 0
    private constant integer NTR_STAGE_TASK = 1
    private constant integer NTR_STAGE_RETURN = 2
    private constant integer NTR_STAGE_COMPLETE = 3

    private constant integer NTR_TASK_NONE = 0
    private constant integer NTR_TASK_KILL = 1
    private constant integer NTR_TASK_FETCH = 2
    private constant integer NTR_TASK_TALK = 3

    private constant integer NTR_PENDING_NONE = 0
    private constant integer NTR_PENDING_COMPLETE = 1
    private constant integer NTR_PENDING_START_TASK = 2
    private constant integer NTR_PENDING_FINISH_TASK = 3
    private constant integer NTR_PENDING_TASK_TALK = 4

    private integer NTR_VendorTypeCount = 0
    private integer array NTR_VendorUnitType
    private string array NTR_VendorVoiceType
    private integer array NTR_VendorFirstIndex

    private unit array NTR_WorldVendor
    private integer NTR_WorldVendorCount = 0
    private unit array NTR_CompanyHero
    private integer NTR_CompanyHeroCount = 0

    private unit array NTR_TargetUnit
    private boolean array NTR_TargetIsAI
    private string array NTR_TargetVoiceType
    private integer array NTR_TargetFirstIndex
    private integer array NTR_TargetStage
    private integer array NTR_TargetTaskType
    private integer array NTR_TaskTargetType
    private integer array NTR_TaskAmount
    private integer array NTR_TaskCurrent
    private unit array NTR_TaskTalkTarget

    private unit NTR_HangoverHero = null
    private unit NTR_OtherHero = null
    private boolean NTR_HasOtherHeroRequirement = false
    private integer NTR_RequirementCount = 0
    private integer NTR_CompletedCount = 0
    private boolean array NTR_RequirementCompleted
    private integer NTR_PendingAction = 0
    private integer NTR_PendingTarget = 0
    private QuestData NTR_Quest = 0
endglobals

private function NTR_GetVendorTypeIndex takes integer unitTypeId returns integer
    local integer index = 1
    loop
        exitwhen index > NTR_VendorTypeCount
        if NTR_VendorUnitType[index] == unitTypeId then
            return index
        endif
        set index = index + 1
    endloop
    return 0
endfunction

private function NTR_GetOtherHero takes unit hero returns unit
    if hero == udg_Nazgrek and udg_Zulkis != null and GetOwningPlayer(udg_Zulkis) == Player(0) and DialogInteraction_IsUnitAlive(udg_Zulkis) then
        return udg_Zulkis
    elseif hero == udg_Zulkis and udg_Nazgrek != null and GetOwningPlayer(udg_Nazgrek) == Player(0) and DialogInteraction_IsUnitAlive(udg_Nazgrek) then
        return udg_Nazgrek
    endif
    return null
endfunction

private function NTR_GetTargetName takes integer targetIndex returns string
    if NTR_TargetIsAI[targetIndex] then
        return GetUnitName(NTR_TargetUnit[targetIndex])
    endif
    return VendorLines_GetVendorSpeakerName(NTR_TargetUnit[targetIndex])
endfunction

private function NTR_GetRequirementIndex takes integer targetIndex returns integer
    if NTR_HasOtherHeroRequirement then
        return targetIndex + 1
    endif
    return targetIndex
endfunction

private function NTR_FindWitness takes unit whichUnit returns integer
    local integer index = 1
    loop
        exitwhen index > NTR_TARGET_COUNT
        if NTR_TargetUnit[index] == whichUnit then
            return index
        endif
        set index = index + 1
    endloop
    return 0
endfunction

private function NTR_FindTalkTaskByTarget takes unit whichUnit returns integer
    local integer index = 1
    loop
        exitwhen index > NTR_TARGET_COUNT
        if NTR_TargetStage[index] == NTR_STAGE_TASK and NTR_TargetTaskType[index] == NTR_TASK_TALK and NTR_TaskTalkTarget[index] == whichUnit then
            return index
        endif
        set index = index + 1
    endloop
    return 0
endfunction

private function NTR_IsSelectedInteractionValid takes unit selected returns boolean
    if selected == null or NTR_HangoverHero == null or not DialogInteraction_IsUnitAlive(selected) or not DialogInteraction_IsUnitAlive(NTR_HangoverHero) then
        return false
    endif
    if IsUnitEnemy(selected, Player(0)) or not IsUnitInRange(selected, NTR_HangoverHero, NTR_TALK_RANGE) then
        return false
    endif
    return not DialogSystem_IsSequenceActive()
endfunction

private function NTR_CollectWorldVendors takes nothing returns nothing
    local group worldUnits = CreateGroup()
    local rect worldBounds = GetWorldBounds()
    local unit vendor

    set NTR_WorldVendorCount = 0
    call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
    loop
        set vendor = FirstOfGroup(worldUnits)
        exitwhen vendor == null
        call GroupRemoveUnit(worldUnits, vendor)
        if NTR_WorldVendorCount < NTR_MAX_WORLD_VENDORS and DialogInteraction_IsUnitAlive(vendor) and NTR_GetVendorTypeIndex(GetUnitTypeId(vendor)) > 0 then
            set NTR_WorldVendorCount = NTR_WorldVendorCount + 1
            set NTR_WorldVendor[NTR_WorldVendorCount] = vendor
        endif
    endloop

    call DestroyGroup(worldUnits)
    call RemoveRect(worldBounds)
    set worldUnits = null
    set worldBounds = null
    set vendor = null
endfunction

private function NTR_CollectCompanyHeroes takes unit hangoverHero returns nothing
    local integer index = 1
    local integer count = Companions_GetControlledDisplayCount()
    local unit candidate

    set NTR_CompanyHeroCount = 0
    loop
        exitwhen index > count
        set candidate = Companions_GetControlledDisplayUnit(index)
        if NTR_CompanyHeroCount < NTR_MAX_COMPANY_HEROES and candidate != null and candidate != hangoverHero and DialogInteraction_IsUnitAlive(candidate) and IsUnitType(candidate, UNIT_TYPE_HERO) and AI_GetInstance(candidate) > 0 and udg_Companion_Group != null and IsUnitInGroup(candidate, udg_Companion_Group) then
            set NTR_CompanyHeroCount = NTR_CompanyHeroCount + 1
            set NTR_CompanyHero[NTR_CompanyHeroCount] = candidate
        endif
        set index = index + 1
    endloop
    set candidate = null
    set hangoverHero = null
endfunction

private function NTR_ClearTarget takes integer targetIndex returns nothing
    set NTR_TargetUnit[targetIndex] = null
    set NTR_TargetIsAI[targetIndex] = false
    set NTR_TargetVoiceType[targetIndex] = ""
    set NTR_TargetFirstIndex[targetIndex] = 0
    set NTR_TargetStage[targetIndex] = NTR_STAGE_TALK
    set NTR_TargetTaskType[targetIndex] = NTR_TASK_NONE
    set NTR_TaskTargetType[targetIndex] = 0
    set NTR_TaskAmount[targetIndex] = 0
    set NTR_TaskCurrent[targetIndex] = 0
    set NTR_TaskTalkTarget[targetIndex] = null
endfunction

private function NTR_SelectRandomCompanyHero takes integer targetIndex, integer firstCandidate returns nothing
    local integer selected = GetRandomInt(firstCandidate, NTR_CompanyHeroCount)
    local unit swapUnit = NTR_CompanyHero[firstCandidate]

    set NTR_CompanyHero[firstCandidate] = NTR_CompanyHero[selected]
    set NTR_CompanyHero[selected] = swapUnit
    set NTR_TargetUnit[targetIndex] = NTR_CompanyHero[firstCandidate]
    set NTR_TargetIsAI[targetIndex] = true
    set swapUnit = null
endfunction

private function NTR_SelectRandomVendor takes integer targetIndex, integer firstCandidate returns nothing
    local integer selected = GetRandomInt(firstCandidate, NTR_WorldVendorCount)
    local integer typeIndex
    local unit swapUnit = NTR_WorldVendor[firstCandidate]

    set NTR_WorldVendor[firstCandidate] = NTR_WorldVendor[selected]
    set NTR_WorldVendor[selected] = swapUnit
    set NTR_TargetUnit[targetIndex] = NTR_WorldVendor[firstCandidate]
    set typeIndex = NTR_GetVendorTypeIndex(GetUnitTypeId(NTR_TargetUnit[targetIndex]))
    set NTR_TargetVoiceType[targetIndex] = NTR_VendorVoiceType[typeIndex]
    set NTR_TargetFirstIndex[targetIndex] = NTR_VendorFirstIndex[typeIndex]
    set swapUnit = null
endfunction

private function NTR_SelectTargets takes unit hangoverHero returns boolean
    local integer aiTargetCount = 0
    local integer vendorTargetCount
    local integer targetIndex = 1
    local integer vendorCandidate = 1

    call NTR_CollectCompanyHeroes(hangoverHero)
    call NTR_CollectWorldVendors()
    if NTR_CompanyHeroCount == 1 then
        set aiTargetCount = 1
    elseif NTR_CompanyHeroCount > 1 then
        set aiTargetCount = GetRandomInt(1, 2)
    endif
    set vendorTargetCount = NTR_TARGET_COUNT - aiTargetCount
    if NTR_WorldVendorCount < vendorTargetCount then
        set hangoverHero = null
        return false
    endif

    loop
        exitwhen targetIndex > NTR_TARGET_COUNT
        call NTR_ClearTarget(targetIndex)
        if targetIndex <= aiTargetCount then
            call NTR_SelectRandomCompanyHero(targetIndex, targetIndex)
        else
            call NTR_SelectRandomVendor(targetIndex, vendorCandidate)
            set vendorCandidate = vendorCandidate + 1
        endif
        set targetIndex = targetIndex + 1
    endloop
    set hangoverHero = null
    return true
endfunction

private function NTR_IsCurrentTargetUnit takes unit candidate returns boolean
    return candidate == NTR_TargetUnit[1] or candidate == NTR_TargetUnit[2] or candidate == NTR_TargetUnit[3]
endfunction

private function NTR_IsTaskTalkTargetUsed takes unit candidate returns boolean
    return candidate == NTR_TaskTalkTarget[1] or candidate == NTR_TaskTalkTarget[2] or candidate == NTR_TaskTalkTarget[3]
endfunction

private function NTR_SelectTaskTalkTarget takes integer targetIndex returns unit
    local integer index = 1
    local integer seen = 0
    local unit candidate
    local unit selected = null

    loop
        exitwhen index > NTR_WorldVendorCount
        set candidate = NTR_WorldVendor[index]
        if candidate != null and candidate != NTR_TargetUnit[targetIndex] and not NTR_IsCurrentTargetUnit(candidate) and not NTR_IsTaskTalkTargetUsed(candidate) and DialogInteraction_IsUnitAlive(candidate) then
            set seen = seen + 1
            if GetRandomInt(1, seen) == 1 then
                set selected = candidate
            endif
        endif
        set index = index + 1
    endloop
    set candidate = null
    return selected
endfunction

private function NTR_ConfigureKillTask takes integer targetIndex returns nothing
    local integer roll = GetRandomInt(1, 4)
    set NTR_TargetTaskType[targetIndex] = NTR_TASK_KILL
    set NTR_TaskAmount[targetIndex] = GetRandomInt(3, 5)
    if roll == 1 then
        set NTR_TaskTargetType[targetIndex] = 'ngno'
    elseif roll == 2 then
        set NTR_TaskTargetType[targetIndex] = 'nsat'
    elseif roll == 3 then
        set NTR_TaskTargetType[targetIndex] = 'nsty'
    else
        set NTR_TaskTargetType[targetIndex] = 'ndqt'
    endif
endfunction

private function NTR_ConfigureFetchTask takes integer targetIndex returns nothing
    local integer roll = GetRandomInt(1, 4)
    set NTR_TargetTaskType[targetIndex] = NTR_TASK_FETCH
    set NTR_TaskAmount[targetIndex] = GetRandomInt(2, 4)
    if roll == 1 then
        set NTR_TaskTargetType[targetIndex] = 'I67E'
    elseif roll == 2 then
        set NTR_TaskTargetType[targetIndex] = 'I689'
    elseif roll == 3 then
        set NTR_TaskTargetType[targetIndex] = 'I620'
    else
        set NTR_TaskTargetType[targetIndex] = 'I60Y'
    endif
endfunction

private function NTR_ConfigureTask takes integer targetIndex returns nothing
    local integer taskType = GetRandomInt(NTR_TASK_KILL, NTR_TASK_TALK)
    local unit talkTarget

    if taskType == NTR_TASK_FETCH then
        call NTR_ConfigureFetchTask(targetIndex)
    elseif taskType == NTR_TASK_TALK then
        set talkTarget = NTR_SelectTaskTalkTarget(targetIndex)
        if talkTarget != null then
            set NTR_TargetTaskType[targetIndex] = NTR_TASK_TALK
            set NTR_TaskTalkTarget[targetIndex] = talkTarget
        else
            call NTR_ConfigureKillTask(targetIndex)
        endif
    else
        call NTR_ConfigureKillTask(targetIndex)
    endif
    set talkTarget = null
endfunction

private function NTR_AssignTasks takes nothing returns nothing
    local integer taskCount = GetRandomInt(1, 2)
    local integer assigned = 0
    local integer targetIndex

    loop
        exitwhen assigned >= taskCount
        set targetIndex = GetRandomInt(1, NTR_TARGET_COUNT)
        if NTR_TargetTaskType[targetIndex] == NTR_TASK_NONE then
            call NTR_ConfigureTask(targetIndex)
            set assigned = assigned + 1
        endif
    endloop
endfunction

private function NTR_ResetQuest takes nothing returns nothing
    local integer index = 1
    if NTR_Quest == 0 or not NTR_Quest.completed then
        return
    endif
    loop
        exitwhen index > 8
        call NTR_Quest.markRequirementCompleted(index, false)
        set index = index + 1
    endloop
    set NTR_Quest.req1Completed = false
    set NTR_Quest.req2Completed = false
    set NTR_Quest.req3Completed = false
    set NTR_Quest.req4Completed = false
    set NTR_Quest.req5Completed = false
    set NTR_Quest.req6Completed = false
    set NTR_Quest.req7Completed = false
    set NTR_Quest.req8Completed = false
    set NTR_Quest.returnReqIndex = 0
    set NTR_Quest.hasReturnReq = false
    set NTR_Quest.discovered = false
    set NTR_Quest.active = false
    set NTR_Quest.completed = false
    set NTR_Quest.failed = false
    set NTR_Quest.failReasonText = ""
    if NTR_Quest.wcQuest != null then
        call QuestSetCompleted(NTR_Quest.wcQuest, false)
        call QuestSetDiscovered(NTR_Quest.wcQuest, false)
        call QuestSetFailed(NTR_Quest.wcQuest, false)
        call DestroyQuest(NTR_Quest.wcQuest)
    endif
    set NTR_Quest.wcQuest = null
    set NTR_Quest.req1 = null
    set NTR_Quest.req2 = null
    set NTR_Quest.req3 = null
    set NTR_Quest.req4 = null
    set NTR_Quest.req5 = null
    set NTR_Quest.req6 = null
    set NTR_Quest.req7 = null
    set NTR_Quest.req8 = null
    call NTR_Quest.setState(QUEST_STATE_UNAVAILABLE)
endfunction

private function NTR_EnsureQuest takes nothing returns nothing
    if NTR_Quest == 0 then
        set NTR_Quest = QuestGiver_CreateConfiguredQuest(NTR_QUEST_NAME, null, "repeatable", 1, null, NTR_QUEST_NAME, NTR_ICON, "Piece together the mess left behind during last night's drunken antics. Some witnesses may expect you to make amends before they forgive you.\n\n", "Question everyone who may remember what happened.", "", 1, false, true, true, "", "")
        call NTR_Quest.setAutoComplete(true)
    else
        call NTR_ResetQuest()
    endif
endfunction

private function NTR_ClearRequirementTexts takes nothing returns nothing
    local integer index = 1
    loop
        exitwhen index > 8
        call NTR_Quest.updateRequirementText(index, "")
        set index = index + 1
    endloop
endfunction

private function NTR_SetRequirements takes nothing returns nothing
    local string requirement1 = ""
    local string requirement2
    local string requirement3
    local string requirement4

    if NTR_OtherHero != null then
        set requirement1 = "Talk to " + DialogInteraction_GetHeroName(NTR_OtherHero) + " about last night"
    endif
    set requirement2 = "Talk to " + NTR_GetTargetName(1) + " about last night"
    set requirement3 = "Talk to " + NTR_GetTargetName(2) + " about last night"
    set requirement4 = "Talk to " + NTR_GetTargetName(3) + " about last night"
    call NTR_ClearRequirementTexts()
    if NTR_HasOtherHeroRequirement then
        call QuestGiver_SetRequirements(NTR_Quest.id, "Find out what happened and make amends:", requirement1, requirement2, requirement3, requirement4, "", "", "", "")
        set NTR_RequirementCount = 4
    else
        call QuestGiver_SetRequirements(NTR_Quest.id, "Find out what happened and make amends:", requirement2, requirement3, requirement4, "", "", "", "", "")
        set NTR_RequirementCount = 3
    endif
endfunction

private function NTR_CompleteRequirement takes integer requirementIndex returns nothing
    if NTR_Quest == 0 or not NTR_Quest.active or requirementIndex <= 0 or requirementIndex > NTR_RequirementCount or NTR_RequirementCompleted[requirementIndex] then
        return
    endif
    set NTR_RequirementCompleted[requirementIndex] = true
    call QuestGiver_SetRequirementCompleted(NTR_Quest.id, requirementIndex, true)
    set NTR_CompletedCount = NTR_CompletedCount + 1
    if NTR_CompletedCount >= NTR_RequirementCount then
        call QuestGiver_CompleteQuestByNameAndGiver(NTR_QUEST_NAME, null)
    endif
endfunction

private function NTR_UpdateTaskRequirement takes integer targetIndex returns nothing
    local string witnessName = NTR_GetTargetName(targetIndex)
    local string text

    if NTR_TargetStage[targetIndex] == NTR_STAGE_RETURN then
        set text = "Return to " + witnessName + " for forgiveness"
    elseif NTR_TargetTaskType[targetIndex] == NTR_TASK_KILL then
        set text = "Make amends with " + witnessName + ": defeat " + I2S(NTR_TaskAmount[targetIndex]) + " " + GetObjectName(NTR_TaskTargetType[targetIndex]) + " (" + I2S(NTR_TaskCurrent[targetIndex]) + "/" + I2S(NTR_TaskAmount[targetIndex]) + ")"
    elseif NTR_TargetTaskType[targetIndex] == NTR_TASK_FETCH then
        set text = "Replace " + witnessName + "'s supplies: bring " + I2S(NTR_TaskAmount[targetIndex]) + " " + GetObjectName(NTR_TaskTargetType[targetIndex])
    else
        set text = "Make amends with " + witnessName + ": apologize to " + VendorLines_GetVendorSpeakerName(NTR_TaskTalkTarget[targetIndex])
    endif
    call QuestGiver_UpdateRequirementText(NTR_Quest.id, NTR_GetRequirementIndex(targetIndex), text)
endfunction

private function NTR_StartTask takes integer targetIndex returns nothing
    set NTR_TargetStage[targetIndex] = NTR_STAGE_TASK
    call NTR_UpdateTaskRequirement(targetIndex)
endfunction

private function NTR_MarkTaskReady takes integer targetIndex returns nothing
    if NTR_TargetStage[targetIndex] != NTR_STAGE_TASK then
        return
    endif
    set NTR_TargetStage[targetIndex] = NTR_STAGE_RETURN
    call NTR_UpdateTaskRequirement(targetIndex)
endfunction

private function NTR_IsTaskReady takes integer targetIndex returns boolean
    if NTR_TargetStage[targetIndex] == NTR_STAGE_RETURN then
        return true
    endif
    if NTR_TargetStage[targetIndex] != NTR_STAGE_TASK then
        return false
    endif
    if NTR_TargetTaskType[targetIndex] == NTR_TASK_FETCH then
        return HeroItemCheckBoth(NTR_TaskTargetType[targetIndex], NTR_TaskAmount[targetIndex])
    elseif NTR_TargetTaskType[targetIndex] == NTR_TASK_KILL then
        return NTR_TaskCurrent[targetIndex] >= NTR_TaskAmount[targetIndex]
    endif
    return false
endfunction

private function NTR_CompleteTarget takes integer targetIndex returns nothing
    if NTR_TargetStage[targetIndex] == NTR_STAGE_COMPLETE then
        return
    endif
    set NTR_TargetStage[targetIndex] = NTR_STAGE_COMPLETE
    call NTR_CompleteRequirement(NTR_GetRequirementIndex(targetIndex))
endfunction

private function NTR_ClearPending takes nothing returns nothing
    set NTR_PendingAction = NTR_PENDING_NONE
    set NTR_PendingTarget = 0
endfunction

private function NTR_FinishPendingTalk takes nothing returns nothing
    local integer targetIndex = NTR_PendingTarget

    if targetIndex <= 0 or NTR_Quest == 0 or not NTR_Quest.active then
        call NTR_ClearPending()
        return
    endif
    if NTR_PendingAction == NTR_PENDING_COMPLETE then
        call NTR_CompleteTarget(targetIndex)
    elseif NTR_PendingAction == NTR_PENDING_START_TASK then
        call NTR_StartTask(targetIndex)
    elseif NTR_PendingAction == NTR_PENDING_TASK_TALK then
        call NTR_MarkTaskReady(targetIndex)
    elseif NTR_PendingAction == NTR_PENDING_FINISH_TASK then
        if NTR_TargetTaskType[targetIndex] != NTR_TASK_FETCH or HeroItemCheckBothAndRemove(NTR_TaskTargetType[targetIndex], NTR_TaskAmount[targetIndex]) then
            call NTR_CompleteTarget(targetIndex)
        else
            set NTR_TargetStage[targetIndex] = NTR_STAGE_TASK
            call NTR_UpdateTaskRequirement(targetIndex)
        endif
    endif
    call NTR_ClearPending()
endfunction

private function NTR_AddWitnessNightExchange takes integer seq, integer targetIndex, unit hero returns nothing
    local unit witness = NTR_TargetUnit[targetIndex]
    local string witnessName = NTR_GetTargetName(targetIndex)
    local integer storyIndex
    if NTR_TargetIsAI[targetIndex] then
        call VoicelinesDrunk_PickAINightReply(witness)
    else
        call VoicelinesDrunk_PickVendorLine(NTR_TargetVoiceType[targetIndex], NTR_TargetFirstIndex[targetIndex])
    endif
    set storyIndex = VoicelinesDrunk_PickedNightIndex
    call DialogSystem_AddLine(seq, witness, witnessName, VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
    call VoicelinesDrunk_PickNightHeroResponse(hero, storyIndex)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
    set witness = null
    set hero = null
endfunction

private function NTR_AddTaskRequestLine takes integer seq, integer targetIndex returns nothing
    local unit witness = NTR_TargetUnit[targetIndex]
    local string witnessName = NTR_GetTargetName(targetIndex)
    if NTR_TargetIsAI[targetIndex] then
        call VoicelinesDrunk_PickAITaskRequest(witness)
    else
        call VoicelinesDrunk_PickVendorTaskRequest(NTR_TargetVoiceType[targetIndex], NTR_TargetFirstIndex[targetIndex])
    endif
    call DialogSystem_AddLine(seq, witness, witnessName, VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
    set witness = null
endfunction

private function NTR_AddForgivenessLine takes integer seq, integer targetIndex returns nothing
    local unit witness = NTR_TargetUnit[targetIndex]
    local string witnessName = NTR_GetTargetName(targetIndex)
    if NTR_TargetIsAI[targetIndex] then
        call VoicelinesDrunk_PickAIForgiveness(witness)
    else
        call VoicelinesDrunk_PickVendorForgiveness(NTR_TargetVoiceType[targetIndex], NTR_TargetFirstIndex[targetIndex])
    endif
    call DialogSystem_AddLine(seq, witness, witnessName, VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
    set witness = null
endfunction

private function NTR_CreateWitnessSequence takes integer targetIndex, unit hero returns integer
    local unit witness = NTR_TargetUnit[targetIndex]
    local string witnessName = NTR_GetTargetName(targetIndex)
    local integer seq = DialogSystem_CreateSequence()

    call NTR_ClearPending()
    call DialogSystem_SetSequenceDefaultSpeaker(seq, witness, witnessName)
    call DialogSystem_AddMakeFaceEachOther(seq, witness, hero, 0.45, 0.00)
    if NTR_TargetStage[targetIndex] == NTR_STAGE_TALK then
        call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), "What happened last night?", "", true)
        call NTR_AddWitnessNightExchange(seq, targetIndex, hero)
        if NTR_TargetTaskType[targetIndex] == NTR_TASK_NONE then
            set NTR_PendingAction = NTR_PENDING_COMPLETE
        else
            call NTR_AddTaskRequestLine(seq, targetIndex)
            set NTR_PendingAction = NTR_PENDING_START_TASK
        endif
    else
        if NTR_IsTaskReady(targetIndex) then
            call NTR_MarkTaskReady(targetIndex)
        endif
        if NTR_TargetStage[targetIndex] == NTR_STAGE_RETURN then
            call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), "I fixed the mess. Are we even?", "", true)
            call NTR_AddForgivenessLine(seq, targetIndex)
            set NTR_PendingAction = NTR_PENDING_FINISH_TASK
        else
            call NTR_AddTaskRequestLine(seq, targetIndex)
        endif
    endif
    set NTR_PendingTarget = targetIndex
    set witness = null
    set hero = null
    return seq
endfunction

private function NTR_CreateTaskTalkSequence takes integer targetIndex, unit talkTarget, unit hero returns integer
    local integer typeIndex = NTR_GetVendorTypeIndex(GetUnitTypeId(talkTarget))
    local string targetName = VendorLines_GetVendorSpeakerName(talkTarget)
    local integer seq = DialogSystem_CreateSequence()

    call NTR_ClearPending()
    call DialogSystem_SetSequenceDefaultSpeaker(seq, talkTarget, targetName)
    call DialogSystem_AddMakeFaceEachOther(seq, talkTarget, hero, 0.45, 0.00)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), "I owe you an apology for last night.", "", true)
    call VoicelinesDrunk_PickVendorForgiveness(NTR_VendorVoiceType[typeIndex], NTR_VendorFirstIndex[typeIndex])
    call DialogSystem_AddLine(seq, talkTarget, targetName, VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
    set NTR_PendingAction = NTR_PENDING_TASK_TALK
    set NTR_PendingTarget = targetIndex
    set talkTarget = null
    set hero = null
    return seq
endfunction

private function NTR_OnAISequenceEnd takes nothing returns nothing
    call NTR_FinishPendingTalk()
endfunction

private function NTR_OnOtherHeroSequenceEnd takes nothing returns nothing
    call NTR_CompleteRequirement(1)
    set NTR_OtherHero = null
endfunction

private function NTR_PlayDirectWitnessSequence takes integer targetIndex returns nothing
    local integer seq = NTR_CreateWitnessSequence(targetIndex, NTR_HangoverHero)
    call DialogSystem_SetSequenceCallbacks(seq, null, function NTR_OnAISequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), NTR_TargetUnit[targetIndex])
endfunction

private function NTR_OnPreSelected takes nothing returns nothing
    local unit selected = DialogInteraction_GetSelectedUnit()
    local integer targetIndex
    local integer storyIndex
    local integer seq

    if NTR_Quest == 0 or not NTR_Quest.active or not NTR_IsSelectedInteractionValid(selected) then
        set selected = null
        return
    endif
    if NTR_OtherHero != null and selected == NTR_OtherHero then
        call DialogInteraction_ConsumeSelection()
        set seq = DialogSystem_CreateSequence()
        call DialogSystem_SetSequenceDefaultSpeaker(seq, NTR_OtherHero, DialogInteraction_GetHeroName(NTR_OtherHero))
        call DialogSystem_AddMakeFaceEachOther(seq, NTR_OtherHero, NTR_HangoverHero, 0.45, 0.00)
        call DialogSystem_AddLine(seq, NTR_HangoverHero, DialogInteraction_GetHeroName(NTR_HangoverHero), "What happened last night?", "", true)
        call VoicelinesDrunk_PickHeroNightReply(NTR_OtherHero)
        set storyIndex = VoicelinesDrunk_PickedNightIndex
        call DialogSystem_AddLine(seq, NTR_OtherHero, DialogInteraction_GetHeroName(NTR_OtherHero), VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
        call VoicelinesDrunk_PickNightHeroResponse(NTR_HangoverHero, storyIndex)
        call DialogSystem_AddLine(seq, NTR_HangoverHero, DialogInteraction_GetHeroName(NTR_HangoverHero), VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
        call DialogSystem_SetSequenceCallbacks(seq, null, function NTR_OnOtherHeroSequenceEnd)
        call DialogSystem_PlaySequence(seq, Player(0), NTR_OtherHero)
        set selected = null
        return
    endif

    set targetIndex = NTR_FindWitness(selected)
    if targetIndex > 0 and NTR_TargetIsAI[targetIndex] and NTR_TargetStage[targetIndex] != NTR_STAGE_COMPLETE then
        call DialogInteraction_ConsumeSelection()
        call NTR_PlayDirectWitnessSequence(targetIndex)
    endif
    set selected = null
endfunction

private function NTR_OnHangoverWake takes nothing returns nothing
    local unit hero = Drunk_GetWakeUnit()
    local integer index = 1

    if hero == null or GetOwningPlayer(hero) != Player(0) or (hero != udg_Nazgrek and hero != udg_Zulkis) then
        set hero = null
        return
    endif
    if NTR_Quest != 0 and NTR_Quest.active then
        set hero = null
        return
    endif
    if not NTR_SelectTargets(hero) then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00A Night To Remember could not find enough eligible AI heroes and placed Horde vendors.|r")
        set hero = null
        return
    endif

    set NTR_HangoverHero = hero
    set NTR_OtherHero = NTR_GetOtherHero(hero)
    set NTR_HasOtherHeroRequirement = NTR_OtherHero != null
    set NTR_CompletedCount = 0
    call NTR_ClearPending()
    loop
        exitwhen index > 4
        set NTR_RequirementCompleted[index] = false
        set index = index + 1
    endloop
    call NTR_AssignTasks()
    call NTR_EnsureQuest()
    call NTR_SetRequirements()
    call NTR_Quest.accept()
    set hero = null
endfunction

private function NTR_IsValidKillCredit takes unit killer returns boolean
    if killer == null then
        return false
    endif
    if GetOwningPlayer(killer) == Player(0) then
        return true
    endif
    return udg_Companion_Group != null and IsUnitInGroup(killer, udg_Companion_Group)
endfunction

private function NTR_OnAnyUnitDeath takes nothing returns nothing
    local unit dying = UnitDeathEvent_GetDyingUnit()
    local unit killer = UnitDeathEvent_GetKillingUnit()
    local integer index = 1

    if NTR_Quest != 0 and NTR_Quest.active and dying != null and NTR_IsValidKillCredit(killer) then
        loop
            exitwhen index > NTR_TARGET_COUNT
            if NTR_TargetStage[index] == NTR_STAGE_TASK and NTR_TargetTaskType[index] == NTR_TASK_KILL and GetUnitTypeId(dying) == NTR_TaskTargetType[index] then
                set NTR_TaskCurrent[index] = NTR_TaskCurrent[index] + 1
                if NTR_TaskCurrent[index] >= NTR_TaskAmount[index] then
                    call NTR_MarkTaskReady(index)
                else
                    call NTR_UpdateTaskRequirement(index)
                endif
            endif
            set index = index + 1
        endloop
    endif
    set dying = null
    set killer = null
endfunction

public function RegisterVendorType takes integer unitTypeId, string voiceType, integer firstIndex returns nothing
    if unitTypeId == 0 or voiceType == "" or firstIndex <= 0 or NTR_VendorTypeCount >= NTR_MAX_VENDOR_TYPES or NTR_GetVendorTypeIndex(unitTypeId) > 0 then
        return
    endif
    set NTR_VendorTypeCount = NTR_VendorTypeCount + 1
    set NTR_VendorUnitType[NTR_VendorTypeCount] = unitTypeId
    set NTR_VendorVoiceType[NTR_VendorTypeCount] = voiceType
    set NTR_VendorFirstIndex[NTR_VendorTypeCount] = firstIndex
endfunction

public function AddVendorDialogButton takes dialog d, unit vendor, unit hero, code actionFunc returns boolean
    local integer targetIndex
    local button b

    if NTR_Quest == 0 or not NTR_Quest.active or hero != NTR_HangoverHero then
        set d = null
        set vendor = null
        set hero = null
        set b = null
        return false
    endif
    set targetIndex = NTR_FindTalkTaskByTarget(vendor)
    if targetIndex > 0 then
        set b = DialogSystem_AddButton(d, "|cff80ff80[Quest]|r Apologize for last night", NTR_VENDOR_ACTION)
    else
        set targetIndex = NTR_FindWitness(vendor)
        if targetIndex <= 0 or NTR_TargetIsAI[targetIndex] or NTR_TargetStage[targetIndex] == NTR_STAGE_COMPLETE then
            set d = null
            set vendor = null
            set hero = null
            set b = null
            return false
        endif
        if NTR_TargetStage[targetIndex] == NTR_STAGE_TALK then
            set b = DialogSystem_AddButton(d, "|cff80ff80[Quest]|r Ask about last night", NTR_VENDOR_ACTION)
        elseif NTR_IsTaskReady(targetIndex) then
            set b = DialogSystem_AddButton(d, "|cff80ff80[Quest]|r Ask forgiveness", NTR_VENDOR_ACTION)
        else
            set b = DialogSystem_AddButton(d, "|cff80ff80[Quest]|r Discuss making amends", NTR_VENDOR_ACTION)
        endif
    endif
    call DialogSystem_BindButtonCode(b, actionFunc)
    set d = null
    set vendor = null
    set hero = null
    set b = null
    return true
endfunction

public function IsVendorTalkAction takes integer actionId returns boolean
    return actionId == NTR_VENDOR_ACTION
endfunction

public function BeginVendorTalk takes unit vendor, unit hero returns integer
    local integer targetIndex
    local integer seq

    if NTR_Quest == 0 or not NTR_Quest.active or hero != NTR_HangoverHero then
        set vendor = null
        set hero = null
        return 0
    endif
    set targetIndex = NTR_FindTalkTaskByTarget(vendor)
    if targetIndex > 0 then
        set seq = NTR_CreateTaskTalkSequence(targetIndex, vendor, hero)
        set vendor = null
        set hero = null
        return seq
    endif
    set targetIndex = NTR_FindWitness(vendor)
    if targetIndex > 0 and not NTR_TargetIsAI[targetIndex] and NTR_TargetStage[targetIndex] != NTR_STAGE_COMPLETE then
        set seq = NTR_CreateWitnessSequence(targetIndex, hero)
        set vendor = null
        set hero = null
        return seq
    endif
    set vendor = null
    set hero = null
    return 0
endfunction

public function FinishVendorTalk takes nothing returns nothing
    call NTR_FinishPendingTalk()
endfunction

public function CancelVendorTalk takes nothing returns nothing
    call NTR_ClearPending()
endfunction

private function Init takes nothing returns nothing
    call Drunk_RegisterWakeHandler(function NTR_OnHangoverWake)
    call DialogInteraction_RegisterPreSelectionHandler(function NTR_OnPreSelected)
    call UnitDeathEvent_Register(function NTR_OnAnyUnitDeath)
endfunction

endlibrary
