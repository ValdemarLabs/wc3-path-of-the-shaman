/**
    VendorQuests

    Author: Valdemar
    Version: 1.0.0

    Description:
    Bridges Shop vendors into QuestMaster without registering a second unit
    selection handler. Quest-content libraries register templates by vendor
    unit type; VendorDialogs instantiates them and adds contextual buttons.

    Credits:

    How to install:
    Import after QuestGiver, QuestMaster, DialogSystem, HeroItemCheck,
    VendorLines, and Table. VendorDialogs may require this library and call
    RegisterUnit for each discovered vendor.

    API:
    - VendorQuests_RegisterFetchQuest(...) registers an item quest template.
    - VendorQuests_RegisterKillQuest(...) registers a kill quest template.
    - VendorQuests_RegisterSupplyQuest(...) registers a cross-vendor pickup.
    - VendorQuests_SetFactionReward(definitionId, faction, amount, linked)
      assigns faction metadata and reputation rewards.
    - VendorQuests_RegisterUnit(vendor) instantiates matching templates.
    - VendorQuests_AddDialogButtons(dialog, vendor, handler) adds quest choices.
    - VendorQuests_BeginAction(actionId, vendor, hero) creates quest dialogue.
    - VendorQuests_FinishPendingAction() commits its accept/complete event.
    - VendorQuests_CancelPendingAction() cancels an interrupted quest dialogue.
    - VendorQuests_HandleAction(actionId, vendor, hero) resolves a choice.
    - VendorQuests_OnVendorSelected(vendor, hero) resolves supply pickups.

**/
library VendorQuests initializer Init requires QuestGiver, QuestMaster, DialogSystem, DialogInteraction, HeroItemCheck, VendorLines, VoicelinesVendorQuests, Shop, Table
    globals
        private constant integer VQ_MAX_DEFINITIONS = 64
        private constant integer VQ_MAX_QUESTS = 256
        private constant integer VQ_ACTION_BASE = 10000
        private constant integer VQ_OBJECTIVE_FETCH = 1
        private constant integer VQ_OBJECTIVE_KILL = 2
        private constant integer VQ_OBJECTIVE_SUPPLY = 3
        private constant integer VQ_PENDING_ACCEPT = 1
        private constant integer VQ_PENDING_COMPLETE = 2

        private integer VQ_DefinitionCount = 0
        private integer array VQ_VendorUnitType
        private string array VQ_QuestName
        private string array VQ_QuestType
        private integer array VQ_QuestLevel
        private string array VQ_Title
        private string array VQ_IconPath
        private string array VQ_Description
        private integer array VQ_ObjectiveType
        private integer array VQ_TargetType
        private integer array VQ_TargetAmount
        private integer array VQ_TargetVendorUnitType
        private string array VQ_TargetVendorName
        private integer array VQ_GoldBonus
        private string array VQ_FactionName
        private integer array VQ_ReputationBonus
        private boolean array VQ_ReputationLinked
        private string array VQ_VoiceType
        private integer array VQ_VoiceIndex
        private string array VQ_IntroText
        private string array VQ_CompleteText

        private integer VQ_QuestCount = 0
        private integer array VQ_QuestIds
        private Table VQ_DefinitionByQuest = 0
        private Table VQ_InstantiatedByUnit = 0
        private Table VQ_SupplyClaimed = 0
        private integer VQ_PendingQuestId = 0
        private integer VQ_PendingDefinitionId = 0
        private integer VQ_PendingAction = 0
        private unit VQ_PendingVendor = null
    endglobals

    private function VQ_FormatSoundKey takes string voiceType, integer lineIndex returns string
        if voiceType == null or voiceType == "" or lineIndex <= 0 then
            return ""
        endif
        if lineIndex < 10 then
            return voiceType + "000" + I2S(lineIndex)
        elseif lineIndex < 100 then
            return voiceType + "00" + I2S(lineIndex)
        elseif lineIndex < 1000 then
            return voiceType + "0" + I2S(lineIndex)
        endif
        return voiceType + I2S(lineIndex)
    endfunction

    private function VQ_RegisterDefinition takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer objectiveType, integer targetType, integer targetAmount, integer targetVendorUnitType, string targetVendorName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        local integer definitionId

        if vendorUnitTypeId == 0 or questName == "" or title == "" or VQ_DefinitionCount >= VQ_MAX_DEFINITIONS then
            return 0
        endif
        if questType != "daily" and questType != "normal" and questType != "repeatable" then
            set questType = "normal"
        endif
        if questLevel < 1 then
            set questLevel = 1
        endif
        if targetAmount < 1 then
            set targetAmount = 1
        endif

        set VQ_DefinitionCount = VQ_DefinitionCount + 1
        set definitionId = VQ_DefinitionCount
        set VQ_VendorUnitType[definitionId] = vendorUnitTypeId
        set VQ_QuestName[definitionId] = questName
        set VQ_QuestType[definitionId] = questType
        set VQ_QuestLevel[definitionId] = questLevel
        set VQ_Title[definitionId] = title
        set VQ_IconPath[definitionId] = iconPath
        set VQ_Description[definitionId] = description
        set VQ_ObjectiveType[definitionId] = objectiveType
        set VQ_TargetType[definitionId] = targetType
        set VQ_TargetAmount[definitionId] = targetAmount
        set VQ_TargetVendorUnitType[definitionId] = targetVendorUnitType
        set VQ_TargetVendorName[definitionId] = targetVendorName
        set VQ_GoldBonus[definitionId] = goldBonus
        set VQ_VoiceType[definitionId] = voiceType
        set VQ_VoiceIndex[definitionId] = voiceIndex
        set VQ_IntroText[definitionId] = introText
        set VQ_CompleteText[definitionId] = completeText
        return definitionId
    endfunction

    public function RegisterFetchQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer itemTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return VQ_RegisterDefinition(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, VQ_OBJECTIVE_FETCH, itemTypeId, amount, 0, "", goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterKillQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer unitTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return VQ_RegisterDefinition(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, VQ_OBJECTIVE_KILL, unitTypeId, amount, 0, "", goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterSupplyQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer targetVendorUnitTypeId, string targetVendorName, integer supplyItemTypeId, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return VQ_RegisterDefinition(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, VQ_OBJECTIVE_SUPPLY, supplyItemTypeId, 1, targetVendorUnitTypeId, targetVendorName, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function SetFactionReward takes integer definitionId, string factionName, integer reputationBonus, boolean linked returns nothing
        if definitionId <= 0 or definitionId > VQ_DefinitionCount or factionName == null or factionName == "" then
            return
        endif
        set VQ_FactionName[definitionId] = factionName
        set VQ_ReputationBonus[definitionId] = reputationBonus
        set VQ_ReputationLinked[definitionId] = linked
    endfunction

    private function VQ_CreateQuest takes integer definitionId, unit vendor returns nothing
        local QuestData q
        local string infoText
        local string info2Text
        local string giverName
        local string targetVendorName

        if definitionId <= 0 or definitionId > VQ_DefinitionCount or vendor == null or VQ_QuestCount >= VQ_MAX_QUESTS then
            set vendor = null
            return
        endif

        set giverName = VendorLines_GetVendorSpeakerName(vendor)
        if VQ_QuestType[definitionId] == "daily" then
            set infoText = "|cff80a0ffDaily quest|r\n\n"
        else
            set infoText = "|cffffcc00Vendor quest|r\n\n"
        endif
        set info2Text = "|cffffcc00Recommended level:|r " + I2S(VQ_QuestLevel[definitionId]) + "\n\n"
        set q = QuestGiver_CreateConfiguredQuest(VQ_QuestName[definitionId], vendor, VQ_QuestType[definitionId], VQ_QuestLevel[definitionId], null, VQ_Title[definitionId], VQ_IconPath[definitionId], VQ_Description[definitionId] + "\n\n", infoText, info2Text, VQ_QuestLevel[definitionId], true, true, true, VQ_FactionName[definitionId], giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, VQ_GoldBonus[definitionId], false, 0, VQ_ReputationBonus[definitionId] != 0, VQ_ReputationBonus[definitionId], VQ_ReputationLinked[definitionId])

        if VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_FETCH then
            call QuestGiver_RegisterItemRequirement(q.id, vendor, 1, VQ_TargetType[definitionId], VQ_TargetAmount[definitionId])
        elseif VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_KILL then
            call QuestGiver_RegisterUnitKillRequirement(q.id, vendor, 1, VQ_TargetType[definitionId], VQ_TargetAmount[definitionId])
        elseif VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_SUPPLY then
            set targetVendorName = Shop_GetVendorUnitTypeName(VQ_TargetVendorUnitType[definitionId])
            if targetVendorName == null or targetVendorName == "" then
                set targetVendorName = VQ_TargetVendorName[definitionId]
            endif
            call QuestGiver_RegisterTalkToRequirement(q.id, vendor, 1, null, targetVendorName)
        endif

        set VQ_QuestCount = VQ_QuestCount + 1
        set VQ_QuestIds[VQ_QuestCount] = q.id
        set VQ_DefinitionByQuest.integer[q.id] = definitionId
        call QuestMaster_RefreshAvailabilityForGiver(vendor)
        set vendor = null
    endfunction

    public function RegisterUnit takes unit vendor returns nothing
        local integer definitionId = 1
        local integer handleId
        local Table instantiated

        if vendor == null or GetUnitTypeId(vendor) == 0 then
            set vendor = null
            return
        endif
        set handleId = GetHandleId(vendor)
        set instantiated = VQ_InstantiatedByUnit.link(handleId)

        loop
            exitwhen definitionId > VQ_DefinitionCount
            if VQ_VendorUnitType[definitionId] == GetUnitTypeId(vendor) and not instantiated.boolean[definitionId] then
                set instantiated.boolean[definitionId] = true
                call VQ_CreateQuest(definitionId, vendor)
            endif
            set definitionId = definitionId + 1
        endloop
        set vendor = null
    endfunction

    private function VQ_GetButtonLabel takes QuestData q returns string
        if q.state == QUEST_STATE_AVAILABLE then
            return "|cff00ff00[!]|r " + q.title
        elseif q.state == QUEST_STATE_READY_TURNIN then
            return "|cffffff00[?]|r " + q.title
        elseif q.state == QUEST_STATE_IN_PROGRESS then
            return "|cffaaaaaa[-]|r " + q.title
        endif
        return ""
    endfunction

    public function AddDialogButtons takes dialog d, unit vendor, code actionFunc returns integer
        local integer count
        local integer index = 1
        local integer added = 0
        local integer questId
        local string label
        local QuestData q
        local button b

        if d == null or vendor == null or actionFunc == null then
            set d = null
            set vendor = null
            set b = null
            return 0
        endif

        set count = QuestMaster_GetGiverQuestCount(vendor)
        loop
            exitwhen index > count
            set questId = QuestMaster_GetGiverQuestIdByIndex(vendor, index)
            if VQ_DefinitionByQuest.integer.has(questId) then
                set q = QuestMaster_GetById(questId)
                set label = VQ_GetButtonLabel(q)
                if label != "" then
                    set b = DialogSystem_AddButton(d, label, VQ_ACTION_BASE + questId)
                    call DialogSystem_BindButtonCode(b, actionFunc)
                    set added = added + 1
                endif
            endif
            set index = index + 1
        endloop

        set d = null
        set vendor = null
        set b = null
        return added
    endfunction

    public function IsQuestAction takes integer actionId returns boolean
        return actionId > VQ_ACTION_BASE and VQ_DefinitionByQuest.integer.has(actionId - VQ_ACTION_BASE)
    endfunction

    private function VQ_HasTurnInItems takes integer definitionId returns boolean
        if VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_FETCH or VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_SUPPLY then
            return HeroItemCheckBoth(VQ_TargetType[definitionId], VQ_TargetAmount[definitionId])
        endif
        return true
    endfunction

    private function VQ_RemoveTurnInItems takes integer definitionId returns nothing
        if VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_FETCH or VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_SUPPLY then
            call HeroItemCheckBothAndRemove(VQ_TargetType[definitionId], VQ_TargetAmount[definitionId])
        endif
    endfunction

    private function VQ_ClearPendingAction takes nothing returns nothing
        set VQ_PendingQuestId = 0
        set VQ_PendingDefinitionId = 0
        set VQ_PendingAction = 0
        set VQ_PendingVendor = null
    endfunction

    public function CancelPendingAction takes nothing returns nothing
        call VQ_ClearPendingAction()
    endfunction

    private function VQ_GetHeroActionText takes integer definitionId, integer pendingAction returns string
        if pendingAction == VQ_PENDING_ACCEPT then
            return VL_VENDORQUEST_HERO_ACCEPT
        elseif VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_KILL then
            return VL_VENDORQUEST_HERO_COMPLETE_KILL
        elseif VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_SUPPLY then
            return VL_VENDORQUEST_HERO_COMPLETE_SUPPLY
        endif
        return VL_VENDORQUEST_HERO_COMPLETE_FETCH
    endfunction

    private function VQ_CreateActionSequence takes unit vendor, unit hero, integer definitionId, QuestData q, integer pendingAction returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string speakerName = VendorLines_GetVendorSpeakerName(vendor)
        local string vendorText
        local string soundKey

        call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, speakerName)
        call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)
        if pendingAction == VQ_PENDING_ACCEPT then
            set vendorText = VQ_IntroText[definitionId]
            set soundKey = VQ_FormatSoundKey(VQ_VoiceType[definitionId], VQ_VoiceIndex[definitionId])
            call DialogSystem_AddLine(seq, vendor, speakerName, vendorText, soundKey, true)
            call DialogInteraction_AddHeroLookAtLine(seq, hero, vendor, VQ_GetHeroActionText(definitionId, pendingAction), "")
        elseif pendingAction == VQ_PENDING_COMPLETE then
            call DialogInteraction_AddHeroLookAtLine(seq, hero, vendor, VQ_GetHeroActionText(definitionId, pendingAction), "")
            set vendorText = VQ_CompleteText[definitionId]
            set soundKey = VQ_FormatSoundKey(VQ_VoiceType[definitionId], VQ_VoiceIndex[definitionId] + 1)
            call DialogSystem_AddLine(seq, vendor, speakerName, vendorText, soundKey, true)
        else
            call DialogInteraction_AddHeroLookAtLine(seq, hero, vendor, VL_VENDORQUEST_HERO_PROGRESS, "")
            call DialogSystem_AddLine(seq, vendor, speakerName, VL_VENDORQUEST_VENDOR_PROGRESS + q.title + ". " + q.requirement1, "", true)
        endif

        set vendor = null
        set hero = null
        return seq
    endfunction

    public function BeginAction takes integer actionId, unit vendor, unit hero returns integer
        local integer questId = actionId - VQ_ACTION_BASE
        local integer definitionId = VQ_DefinitionByQuest.integer[questId]
        local QuestData q = QuestMaster_GetById(questId)
        local integer pendingAction = 0
        local integer seq

        call VQ_ClearPendingAction()
        if definitionId <= 0 or q == 0 or vendor == null or hero == null or q.giver != vendor then
            set vendor = null
            set hero = null
            return 0
        endif

        if q.state == QUEST_STATE_AVAILABLE then
            set pendingAction = VQ_PENDING_ACCEPT
            set VQ_SupplyClaimed.boolean[questId] = false
        elseif q.state == QUEST_STATE_READY_TURNIN then
            if not VQ_HasTurnInItems(definitionId) then
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8040You no longer have the required " + GetObjectName(VQ_TargetType[definitionId]) + ".|r")
                set vendor = null
                set hero = null
                return 0
            endif
            set pendingAction = VQ_PENDING_COMPLETE
        elseif q.state != QUEST_STATE_IN_PROGRESS then
            set vendor = null
            set hero = null
            return 0
        endif

        if pendingAction != 0 then
            set VQ_PendingQuestId = questId
            set VQ_PendingDefinitionId = definitionId
            set VQ_PendingAction = pendingAction
            set VQ_PendingVendor = vendor
        endif
        set seq = VQ_CreateActionSequence(vendor, hero, definitionId, q, pendingAction)
        set vendor = null
        set hero = null
        return seq
    endfunction

    private function VQ_FinishPendingAction takes nothing returns nothing
        local integer questId = VQ_PendingQuestId
        local integer definitionId = VQ_PendingDefinitionId
        local integer pendingAction = VQ_PendingAction
        local QuestData q = QuestMaster_GetById(questId)

        if q != 0 and q.giver == VQ_PendingVendor then
            if pendingAction == VQ_PENDING_ACCEPT and q.state == QUEST_STATE_AVAILABLE then
                call QuestGiver_AcceptQuest(questId)
            elseif pendingAction == VQ_PENDING_COMPLETE and q.state == QUEST_STATE_READY_TURNIN and VQ_HasTurnInItems(definitionId) then
                call VQ_RemoveTurnInItems(definitionId)
                call QuestGiver_CompleteQuest(questId)
            endif
        endif
        call VQ_ClearPendingAction()
    endfunction

    public function FinishPendingAction takes nothing returns nothing
        call VQ_FinishPendingAction()
    endfunction

    public function HandleAction takes integer actionId, unit vendor, unit hero returns boolean
        local integer seq = VendorQuests_BeginAction(actionId, vendor, hero)

        if seq <= 0 then
            set vendor = null
            set hero = null
            return false
        endif
        call DialogInteraction_BeginDialogSequence()
        call DialogSystem_SetSequenceCallbacks(seq, null, function VQ_FinishPendingAction)
        call DialogSystem_PlaySequence(seq, Player(0), vendor)
        set vendor = null
        set hero = null
        return true
    endfunction

    public function OnVendorSelected takes unit vendor, unit hero returns nothing
        local integer index = 1
        local integer questId
        local integer definitionId
        local QuestData q

        if vendor == null or hero == null then
            set vendor = null
            set hero = null
            return
        endif

        loop
            exitwhen index > VQ_QuestCount
            set questId = VQ_QuestIds[index]
            set definitionId = VQ_DefinitionByQuest.integer[questId]
            if VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_SUPPLY and VQ_TargetVendorUnitType[definitionId] == GetUnitTypeId(vendor) then
                set q = QuestMaster_GetById(questId)
                if q != 0 and q.active and not q.completed then
                    if not VQ_SupplyClaimed.boolean[questId] then
                        call QuestGiver_GiveQuestItemToHero(hero, VQ_TargetType[definitionId], 0, GetObjectName(VQ_TargetType[definitionId]))
                        set VQ_SupplyClaimed.boolean[questId] = true
                        call QuestGiver_CompleteTalkToRequirement(questId, 1)
                        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cff80ff80Received " + GetObjectName(VQ_TargetType[definitionId]) + " for " + q.title + ".|r")
                    elseif q.state == QUEST_STATE_READY_TURNIN and not HeroItemCheckBoth(VQ_TargetType[definitionId], 1) then
                        call QuestGiver_GiveQuestItemToHero(hero, VQ_TargetType[definitionId], 0, GetObjectName(VQ_TargetType[definitionId]))
                    endif
                endif
            endif
            set index = index + 1
        endloop

        set vendor = null
        set hero = null
    endfunction

    private function VQ_OnDailyReset takes nothing returns nothing
        if VQ_DefinitionByQuest.integer.has(QuestMaster_EventQuestId) then
            set VQ_SupplyClaimed.boolean[QuestMaster_EventQuestId] = false
        endif
    endfunction

    private function Init takes nothing returns nothing
        set VQ_DefinitionByQuest = Table.create()
        set VQ_InstantiatedByUnit = Table.create()
        set VQ_SupplyClaimed = Table.create()
        call QuestMaster_AddDailyResetAction(function VQ_OnDailyReset)
    endfunction
endlibrary
