/**
    QuestsVendor

    Author: Valdemar
    Version: 1.0.0

    Description:
    Shop-vendor adapter for QuestsGeneric. Generic giver quests are delegated
    to the shared template engine; this library owns only cross-vendor handoff
    and purchase interactions plus vendor display-name integration.

    Credits:

    How to install:
    Import after QuestsGeneric, VoicelinesQuests, Shop, VendorLines, and Table.
    VendorDialogs may require this library and register discovered vendors.

    API:
    - QuestsVendor_RegisterFetchQuest/RegisterKillQuest register generic quests.
    - QuestsVendor_RegisterSupplyQuest registers a target-vendor objective.
    - QuestsVendor_SetSupplyRequiresPurchase overrides stock detection.
    - QuestsVendor_SetFactionReward/SetExtendedDialogue configure definitions.
    - QuestsVendor_RegisterUnit instantiates matching vendor templates.
    - QuestsVendor_AddDialogButtons adds giver and target-vendor choices.
    - QuestsVendor_BeginAction/FinishPendingAction/CancelPendingAction manage
      vendor quest dialogue and target-vendor side effects.

**/
library QuestsVendor initializer Init requires QuestsGeneric, VoicelinesQuests, QuestGiver, QuestMaster, DialogSystem, DialogInteraction, HeroItemCheck, VendorLines, Shop, Table
    globals
        private constant integer QV_MAX_SUPPLY_DEFINITIONS = 32
        private constant integer QV_TARGET_ACTION_BASE = 20000
        private constant integer QV_PENDING_HANDOFF = 1

        private integer QV_SupplyCount = 0
        private integer array QV_SupplyDefinitionId
        private integer array QV_TargetVendorUnitType
        private string array QV_TargetVendorName
        private integer array QV_SupplyItemType
        private boolean array QV_RequiresPurchase
        private boolean array QV_ModeConfigured
        private Table QV_SupplyIndexByDefinition = 0
        private Table QV_SupplyClaimed = 0

        private integer QV_PendingQuestId = 0
        private integer QV_PendingSupplyIndex = 0
        private integer QV_PendingAction = 0
        private unit QV_PendingVendor = null
        private unit QV_PendingHero = null
        private boolean QV_PendingOpenTrade = false
        private boolean QV_OpenTradeRequest = false
    endglobals

    public function RegisterFetchQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer itemTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QuestsGeneric_RegisterFetchQuest(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, itemTypeId, amount, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterKillQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer unitTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QuestsGeneric_RegisterKillQuest(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, unitTypeId, amount, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterSupplyQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer targetVendorUnitTypeId, string targetVendorName, integer supplyItemTypeId, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        local integer definitionId

        if QV_SupplyCount >= QV_MAX_SUPPLY_DEFINITIONS then
            return 0
        endif
        set definitionId = QuestsGeneric_RegisterTalkQuest(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, targetVendorName, goldBonus, voiceType, voiceIndex, introText, completeText)
        if definitionId <= 0 then
            return 0
        endif
        set QV_SupplyCount = QV_SupplyCount + 1
        set QV_SupplyDefinitionId[QV_SupplyCount] = definitionId
        set QV_TargetVendorUnitType[QV_SupplyCount] = targetVendorUnitTypeId
        set QV_TargetVendorName[QV_SupplyCount] = targetVendorName
        set QV_SupplyItemType[QV_SupplyCount] = supplyItemTypeId
        set QV_SupplyIndexByDefinition.integer[definitionId] = QV_SupplyCount
        return definitionId
    endfunction

    public function SetFactionReward takes integer definitionId, string factionName, integer reputationBonus, boolean linked returns nothing
        call QuestsGeneric_SetFactionReward(definitionId, factionName, reputationBonus, linked)
    endfunction

    public function SetExtendedDialogue takes integer definitionId, string acceptText, integer acceptVoiceIndex, string completeText, integer completeVoiceIndex returns nothing
        call QuestsGeneric_SetExtendedDialogue(definitionId, acceptText, acceptVoiceIndex, completeText, completeVoiceIndex)
    endfunction

    public function SetSupplyRequiresPurchase takes integer definitionId, boolean required returns nothing
        local integer supplyIndex = QV_SupplyIndexByDefinition.integer[definitionId]

        if supplyIndex <= 0 then
            return
        endif
        set QV_ModeConfigured[supplyIndex] = true
        set QV_RequiresPurchase[supplyIndex] = required
    endfunction

    private function QV_TargetVendorSellsItem takes integer supplyIndex returns boolean
        local integer vendorId = Shop_GetVendorIdForUnitType(QV_TargetVendorUnitType[supplyIndex])
        local integer position = 1
        local integer stockId
        local integer stockCount

        if vendorId <= 0 or QV_SupplyItemType[supplyIndex] == 0 then
            return false
        endif
        set stockCount = Shop_GetVendorStockCount(vendorId)
        loop
            exitwhen position > stockCount
            set stockId = Shop_GetVendorStockEntry(vendorId, position)
            if Shop_GetStockItemType(stockId) == QV_SupplyItemType[supplyIndex] then
                return true
            endif
            set position = position + 1
        endloop
        return false
    endfunction

    private function QV_ConfigureSupplyObjectives takes nothing returns nothing
        local integer supplyIndex = 1
        local string targetName

        loop
            exitwhen supplyIndex > QV_SupplyCount
            if not QV_ModeConfigured[supplyIndex] then
                set QV_RequiresPurchase[supplyIndex] = QV_TargetVendorSellsItem(supplyIndex)
            endif
            if QV_RequiresPurchase[supplyIndex] then
                call QuestsGeneric_SetObjective(QV_SupplyDefinitionId[supplyIndex], QuestsGeneric_OBJECTIVE_PURCHASE, QV_SupplyItemType[supplyIndex], 1, "")
            else
                set targetName = Shop_GetVendorUnitTypeName(QV_TargetVendorUnitType[supplyIndex])
                if targetName == null or targetName == "" then
                    set targetName = QV_TargetVendorName[supplyIndex]
                endif
                call QuestsGeneric_SetObjective(QV_SupplyDefinitionId[supplyIndex], QuestsGeneric_OBJECTIVE_TALK, QV_SupplyItemType[supplyIndex], 1, targetName)
            endif
            set supplyIndex = supplyIndex + 1
        endloop
    endfunction

    public function RegisterUnit takes unit vendor returns nothing
        if vendor == null then
            set vendor = null
            return
        endif
        call QV_ConfigureSupplyObjectives()
        call QuestsGeneric_RegisterUnit(vendor, VendorLines_GetVendorSpeakerName(vendor))
        set vendor = null
    endfunction

    private function QV_AddTargetButtons takes dialog d, unit vendor, code actionFunc returns integer
        local integer index = 1
        local integer added = 0
        local integer questId
        local integer definitionId
        local integer supplyIndex
        local string label
        local QuestData q
        local button b

        loop
            exitwhen index > QuestsGeneric_GetQuestCount()
            set questId = QuestsGeneric_GetQuestIdByIndex(index)
            set definitionId = QuestsGeneric_GetDefinitionForQuest(questId)
            set supplyIndex = QV_SupplyIndexByDefinition.integer[definitionId]
            if supplyIndex > 0 and QV_TargetVendorUnitType[supplyIndex] == GetUnitTypeId(vendor) then
                set q = QuestMaster_GetById(questId)
                if q != 0 and q.active and not q.completed then
                    if QV_RequiresPurchase[supplyIndex] then
                        set label = "|cff80ff80[Quest]|r Ask about buying " + GetObjectName(QV_SupplyItemType[supplyIndex])
                    else
                        set label = "|cff80ff80[Quest]|r Collect " + GetObjectName(QV_SupplyItemType[supplyIndex])
                    endif
                    set b = DialogSystem_AddButton(d, label, QV_TARGET_ACTION_BASE + questId)
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

    public function AddDialogButtons takes dialog d, unit vendor, code actionFunc returns integer
        local integer added = QuestsGeneric_AddDialogButtons(d, vendor, actionFunc)

        set added = added + QV_AddTargetButtons(d, vendor, actionFunc)
        set d = null
        set vendor = null
        return added
    endfunction

    public function IsQuestAction takes integer actionId returns boolean
        if actionId > QV_TARGET_ACTION_BASE then
            return QV_SupplyIndexByDefinition.integer[QuestsGeneric_GetDefinitionForQuest(actionId - QV_TARGET_ACTION_BASE)] > 0
        endif
        return QuestsGeneric_IsQuestAction(actionId)
    endfunction

    private function QV_ClearPendingAction takes nothing returns nothing
        set QV_PendingQuestId = 0
        set QV_PendingSupplyIndex = 0
        set QV_PendingAction = 0
        set QV_PendingVendor = null
        set QV_PendingHero = null
        set QV_PendingOpenTrade = false
    endfunction

    public function CancelPendingAction takes nothing returns nothing
        call QuestsGeneric_CancelPendingAction()
        call QV_ClearPendingAction()
        set QV_OpenTradeRequest = false
    endfunction

    private function QV_CreateTargetSequence takes unit vendor, unit hero, integer supplyIndex, boolean alreadyHandedOff returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string speakerName = VendorLines_GetVendorSpeakerName(vendor)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, speakerName)
        call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)
        if QV_RequiresPurchase[supplyIndex] then
            call DialogInteraction_AddHeroLookAtLine(seq, hero, vendor, VL_QUEST_HERO_ASK_TO_BUY, "")
            call DialogSystem_AddLine(seq, vendor, speakerName, VL_QUEST_VENDOR_PURCHASE, "", true)
        else
            call DialogInteraction_AddHeroLookAtLine(seq, hero, vendor, VL_QUEST_HERO_REQUEST_SUPPLY, "")
            if alreadyHandedOff then
                call DialogSystem_AddLine(seq, vendor, speakerName, VL_QUEST_VENDOR_ALREADY_HANDED_OFF, "", true)
            else
                call DialogSystem_AddLine(seq, vendor, speakerName, VL_QUEST_VENDOR_HANDOFF, "", true)
            endif
        endif
        set vendor = null
        set hero = null
        return seq
    endfunction

    private function QV_BeginTargetAction takes integer actionId, unit vendor, unit hero returns integer
        local integer questId = actionId - QV_TARGET_ACTION_BASE
        local integer definitionId = QuestsGeneric_GetDefinitionForQuest(questId)
        local integer supplyIndex = QV_SupplyIndexByDefinition.integer[definitionId]
        local QuestData q = QuestMaster_GetById(questId)
        local boolean alreadyHandedOff
        local integer seq

        if supplyIndex <= 0 or q == 0 or vendor == null or hero == null or not q.active or q.completed or QV_TargetVendorUnitType[supplyIndex] != GetUnitTypeId(vendor) then
            set vendor = null
            set hero = null
            return 0
        endif
        set alreadyHandedOff = QV_SupplyClaimed.boolean[questId] and HeroItemCheckBoth(QV_SupplyItemType[supplyIndex], 1)
        if QV_RequiresPurchase[supplyIndex] then
            set QV_PendingOpenTrade = true
        elseif not alreadyHandedOff then
            set QV_PendingQuestId = questId
            set QV_PendingSupplyIndex = supplyIndex
            set QV_PendingAction = QV_PENDING_HANDOFF
            set QV_PendingVendor = vendor
            set QV_PendingHero = hero
        endif
        set seq = QV_CreateTargetSequence(vendor, hero, supplyIndex, alreadyHandedOff)
        set vendor = null
        set hero = null
        return seq
    endfunction

    public function BeginAction takes integer actionId, unit vendor, unit hero returns integer
        local integer seq

        call QV_ClearPendingAction()
        set QV_OpenTradeRequest = false
        if actionId > QV_TARGET_ACTION_BASE then
            call QuestsGeneric_CancelPendingAction()
            set seq = QV_BeginTargetAction(actionId, vendor, hero)
        else
            set seq = QuestsGeneric_BeginAction(actionId, vendor, VendorLines_GetVendorSpeakerName(vendor), hero)
        endif
        set vendor = null
        set hero = null
        return seq
    endfunction

    public function FinishPendingAction takes nothing returns nothing
        local QuestData q = QuestMaster_GetById(QV_PendingQuestId)
        local boolean openTrade = QV_PendingOpenTrade

        call QuestsGeneric_FinishPendingAction()
        if QV_PendingAction == QV_PENDING_HANDOFF and q != 0 and q.active and not q.completed and QV_PendingVendor != null and GetUnitTypeId(QV_PendingVendor) == QV_TargetVendorUnitType[QV_PendingSupplyIndex] then
            if QuestGiver_GiveQuestItemToHero(QV_PendingHero, QV_SupplyItemType[QV_PendingSupplyIndex], 0, GetObjectName(QV_SupplyItemType[QV_PendingSupplyIndex])) then
                set QV_SupplyClaimed.boolean[QV_PendingQuestId] = true
                call QuestGiver_CompleteTalkToRequirement(QV_PendingQuestId, 1)
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cff80ff80Received " + GetObjectName(QV_SupplyItemType[QV_PendingSupplyIndex]) + " for " + q.title + ".|r")
            endif
        endif
        call QV_ClearPendingAction()
        set QV_OpenTradeRequest = openTrade
    endfunction

    public function ConsumeOpenTradeRequest takes nothing returns boolean
        local boolean result = QV_OpenTradeRequest

        set QV_OpenTradeRequest = false
        return result
    endfunction

    private function QV_OnDailyReset takes nothing returns nothing
        if QuestsGeneric_GetDefinitionForQuest(QuestMaster_EventQuestId) > 0 then
            set QV_SupplyClaimed.boolean[QuestMaster_EventQuestId] = false
        endif
    endfunction

    private function Init takes nothing returns nothing
        set QV_SupplyIndexByDefinition = Table.create()
        set QV_SupplyClaimed = Table.create()
        call QuestMaster_AddDailyResetAction(function QV_OnDailyReset)
    endfunction
endlibrary
