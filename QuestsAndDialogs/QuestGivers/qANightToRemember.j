/**
    qANightToRemember

    Author: Valdemar
    Version: 1.0.0

    Description:
    Creates a repeatable, self-completing hangover quest. Each run asks the
    affected hero to question the other player hero when available and three
    randomly selected placed Horde vendors about the previous night.

    Credits:
    - QuestGiver, QuestMaster, DialogInteraction, and DialogSystem

    How to install:
    Import after Drunk, QuestGiver, VoicelinesDrunk, and VoicelinesQuests.
    Eligible vendor qXXX libraries call RegisterVendorType during Init.
    VendorDialogs may optionally expose this library's contextual button.

    API:
    call qANightToRemember_RegisterVendorType(unitTypeId, voiceType, firstIndex)
    call qANightToRemember_AddVendorDialogButton(d, vendor, hero, actionFunc)
    call qANightToRemember_BeginVendorTalk(vendor, hero) returns integer
    call qANightToRemember_FinishVendorTalk()

**/
library qANightToRemember initializer Init requires Drunk, QuestGiver, QuestMaster, DialogInteraction, DialogSystem, VendorLines, VoicelinesDrunk, VoicelinesQuests

globals
    private constant string NTR_QUEST_NAME = "A Night To Remember"
    private constant string NTR_ICON = "ReplaceableTextures\\CommandButtons\\BTNPotionOfOmniscience.blp"
    private constant integer NTR_MAX_VENDOR_TYPES = 15
    private constant integer NTR_MAX_WORLD_VENDORS = 64
    private constant integer NTR_VENDOR_TARGET_COUNT = 3
    private constant integer NTR_VENDOR_ACTION = 31001

    private integer NTR_VendorTypeCount = 0
    private integer array NTR_VendorUnitType
    private string array NTR_VendorVoiceType
    private integer array NTR_VendorFirstIndex

    private unit array NTR_WorldVendor
    private integer NTR_WorldVendorCount = 0
    private unit array NTR_TargetUnit
    private string array NTR_TargetVoiceType
    private integer array NTR_TargetFirstIndex
    private boolean array NTR_TargetCompleted
    private unit NTR_HangoverHero = null
    private unit NTR_OtherHero = null
    private boolean NTR_HasOtherHeroRequirement = false
    private integer NTR_RequirementCount = 0
    private integer NTR_CompletedCount = 0
    private boolean array NTR_RequirementCompleted
    private integer NTR_PendingRequirement = 0
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

private function NTR_SelectVendorTargets takes nothing returns boolean
    local integer targetIndex = 1
    local integer selected
    local integer typeIndex
    local unit swapUnit

    call NTR_CollectWorldVendors()
    if NTR_WorldVendorCount < NTR_VENDOR_TARGET_COUNT then
        set swapUnit = null
        return false
    endif
    loop
        exitwhen targetIndex > NTR_VENDOR_TARGET_COUNT
        set selected = GetRandomInt(targetIndex, NTR_WorldVendorCount)
        set swapUnit = NTR_WorldVendor[targetIndex]
        set NTR_WorldVendor[targetIndex] = NTR_WorldVendor[selected]
        set NTR_WorldVendor[selected] = swapUnit
        set NTR_TargetUnit[targetIndex] = NTR_WorldVendor[targetIndex]
        set typeIndex = NTR_GetVendorTypeIndex(GetUnitTypeId(NTR_TargetUnit[targetIndex]))
        set NTR_TargetVoiceType[targetIndex] = NTR_VendorVoiceType[typeIndex]
        set NTR_TargetFirstIndex[targetIndex] = NTR_VendorFirstIndex[typeIndex]
        set NTR_TargetCompleted[targetIndex] = false
        set targetIndex = targetIndex + 1
    endloop
    set swapUnit = null
    return true
endfunction

private function NTR_ResetQuest takes nothing returns nothing
    if NTR_Quest == 0 or not NTR_Quest.completed then
        return
    endif
    set NTR_Quest.req1Completed = false
    set NTR_Quest.req2Completed = false
    set NTR_Quest.req3Completed = false
    set NTR_Quest.req4Completed = false
    set NTR_Quest.req5Completed = false
    set NTR_Quest.req6Completed = false
    set NTR_Quest.req7Completed = false
    set NTR_Quest.req8Completed = false
    call NTR_Quest.markRequirementCompleted(1, false)
    call NTR_Quest.markRequirementCompleted(2, false)
    call NTR_Quest.markRequirementCompleted(3, false)
    call NTR_Quest.markRequirementCompleted(4, false)
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
    endif
    call NTR_Quest.setState(QUEST_STATE_UNAVAILABLE)
endfunction

private function NTR_EnsureQuest takes nothing returns nothing
    if NTR_Quest == 0 then
        set NTR_Quest = QuestGiver_CreateConfiguredQuest(NTR_QUEST_NAME, null, "repeatable", 1, null, NTR_QUEST_NAME, NTR_ICON, "Piece together the mess left behind during last night's drunken antics.\n\n", "Question everyone who may remember what happened.", "", 1, false, true, true, "", "")
        call NTR_Quest.setAutoComplete(true)
    else
        call NTR_ResetQuest()
    endif
endfunction

private function NTR_SetRequirements takes nothing returns nothing
    local string requirement1 = ""
    local string requirement2
    local string requirement3
    local string requirement4
    local integer vendorOffset = 0

    if NTR_OtherHero != null then
        set requirement1 = "Talk to " + DialogInteraction_GetHeroName(NTR_OtherHero) + " about last night"
        set vendorOffset = 1
    endif
    set requirement2 = "Talk to " + VendorLines_GetVendorSpeakerName(NTR_TargetUnit[1]) + " about last night"
    set requirement3 = "Talk to " + VendorLines_GetVendorSpeakerName(NTR_TargetUnit[2]) + " about last night"
    set requirement4 = "Talk to " + VendorLines_GetVendorSpeakerName(NTR_TargetUnit[3]) + " about last night"
    if vendorOffset == 0 then
        call QuestGiver_SetRequirements(NTR_Quest.id, "Find out what happened:", requirement2, requirement3, requirement4, "", "", "", "", "")
        set NTR_RequirementCount = 3
    else
        call QuestGiver_SetRequirements(NTR_Quest.id, "Find out what happened:", requirement1, requirement2, requirement3, requirement4, "", "", "", "")
        set NTR_RequirementCount = 4
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

private function NTR_OnAnySelected takes nothing returns nothing
    local unit selected = DialogInteraction_GetSelectedUnit()
    local integer seq

    if NTR_Quest == 0 or not NTR_Quest.active or NTR_OtherHero == null or selected != NTR_OtherHero or not DialogInteraction_IsUnitAlive(NTR_HangoverHero) or not IsUnitInRange(selected, NTR_HangoverHero, 900.00) or DialogSystem_IsSequenceActive() then
        set selected = null
        return
    endif
    call VoicelinesDrunk_PickHeroNightReply(NTR_OtherHero)
    set seq = DialogSystem_CreateSequence()
    call DialogSystem_SetSequenceDefaultSpeaker(seq, NTR_OtherHero, DialogInteraction_GetHeroName(NTR_OtherHero))
    call DialogSystem_AddLine(seq, NTR_OtherHero, DialogInteraction_GetHeroName(NTR_OtherHero), VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
    call DialogSystem_PlaySequence(seq, Player(0), NTR_OtherHero)
    call NTR_CompleteRequirement(1)
    set NTR_OtherHero = null
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
    if not NTR_SelectVendorTargets() then
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00A Night To Remember needs at least three placed registered Horde vendors.|r")
        set hero = null
        return
    endif
    set NTR_HangoverHero = hero
    set NTR_OtherHero = NTR_GetOtherHero(hero)
    set NTR_HasOtherHeroRequirement = NTR_OtherHero != null
    set NTR_CompletedCount = 0
    loop
        exitwhen index > 4
        set NTR_RequirementCompleted[index] = false
        set index = index + 1
    endloop
    call NTR_EnsureQuest()
    call NTR_SetRequirements()
    call NTR_Quest.accept()
    set hero = null
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
    local integer index = 1
    local button b

    if NTR_Quest == 0 or not NTR_Quest.active or hero != NTR_HangoverHero then
        set d = null
        set vendor = null
        set hero = null
        set b = null
        return false
    endif
    loop
        exitwhen index > NTR_VENDOR_TARGET_COUNT
        if NTR_TargetUnit[index] == vendor and not NTR_TargetCompleted[index] then
            set b = DialogSystem_AddButton(d, "|cff80ff80[Quest]|r Ask about last night", NTR_VENDOR_ACTION)
            call DialogSystem_BindButtonCode(b, actionFunc)
            set d = null
            set vendor = null
            set hero = null
            set b = null
            return true
        endif
        set index = index + 1
    endloop
    set d = null
    set vendor = null
    set hero = null
    set b = null
    return false
endfunction

public function IsVendorTalkAction takes integer actionId returns boolean
    return actionId == NTR_VENDOR_ACTION
endfunction

public function BeginVendorTalk takes unit vendor, unit hero returns integer
    local integer index = 1
    local integer seq
    local integer requirementIndex
    local string vendorName

    set NTR_PendingRequirement = 0
    set NTR_PendingTarget = 0
    if NTR_Quest == 0 or not NTR_Quest.active or hero != NTR_HangoverHero then
        set vendor = null
        set hero = null
        return 0
    endif
    loop
        exitwhen index > NTR_VENDOR_TARGET_COUNT
        if NTR_TargetUnit[index] == vendor and not NTR_TargetCompleted[index] then
            set requirementIndex = index
            if NTR_HasOtherHeroRequirement then
                set requirementIndex = requirementIndex + 1
            endif
            set NTR_PendingRequirement = requirementIndex
            set NTR_PendingTarget = index
            set vendorName = VendorLines_GetVendorSpeakerName(vendor)
            call VoicelinesDrunk_PickVendorLine(NTR_TargetVoiceType[index], NTR_TargetFirstIndex[index])
            set seq = DialogSystem_CreateSequence()
            call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, vendorName)
            call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)
            call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), "What happened last night?", "", true)
            call DialogSystem_AddLine(seq, vendor, vendorName, VoicelinesDrunk_PickedText, VoicelinesDrunk_PickedKey, true)
            set vendor = null
            set hero = null
            return seq
        endif
        set index = index + 1
    endloop
    set vendor = null
    set hero = null
    return 0
endfunction

public function FinishVendorTalk takes nothing returns nothing
    if NTR_PendingRequirement > 0 then
        set NTR_TargetCompleted[NTR_PendingTarget] = true
        call NTR_CompleteRequirement(NTR_PendingRequirement)
    endif
    set NTR_PendingRequirement = 0
    set NTR_PendingTarget = 0
endfunction

public function CancelVendorTalk takes nothing returns nothing
    set NTR_PendingRequirement = 0
    set NTR_PendingTarget = 0
endfunction

private function Init takes nothing returns nothing
    call Drunk_RegisterWakeHandler(function NTR_OnHangoverWake)
    call DialogInteraction_RegisterAnySelectionHandler(function NTR_OnAnySelected)
endfunction

endlibrary
