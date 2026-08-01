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
    - VendorQuests_RegisterUnit(vendor) instantiates matching templates.
    - VendorQuests_AddDialogButtons(dialog, vendor, handler) adds quest choices.
    - VendorQuests_HandleAction(actionId, vendor, hero) resolves a choice.
    - VendorQuests_OnVendorSelected(vendor, hero) resolves supply pickups.

**/
library VendorQuests initializer Init requires QuestGiver, QuestMaster, DialogSystem, HeroItemCheck, VendorLines, Table
    globals
        private constant integer VQ_MAX_DEFINITIONS = 64
        private constant integer VQ_MAX_QUESTS = 256
        private constant integer VQ_ACTION_BASE = 10000
        private constant integer VQ_OBJECTIVE_FETCH = 1
        private constant integer VQ_OBJECTIVE_KILL = 2
        private constant integer VQ_OBJECTIVE_SUPPLY = 3

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
        private string array VQ_VoiceType
        private integer array VQ_VoiceIndex
        private string array VQ_IntroText
        private string array VQ_CompleteText

        private integer VQ_QuestCount = 0
        private integer array VQ_QuestIds
        private Table VQ_DefinitionByQuest = 0
        private Table VQ_InstantiatedByUnit = 0
        private Table VQ_SupplyClaimed = 0
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

    private function VQ_CreateQuest takes integer definitionId, unit vendor returns nothing
        local QuestData q
        local string infoText
        local string info2Text
        local string giverName

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
        set q = QuestGiver_CreateConfiguredQuest(VQ_QuestName[definitionId], vendor, VQ_QuestType[definitionId], VQ_QuestLevel[definitionId], null, VQ_Title[definitionId], VQ_IconPath[definitionId], VQ_Description[definitionId] + "\n\n", infoText, info2Text, VQ_QuestLevel[definitionId], true, true, true, "", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, VQ_GoldBonus[definitionId], false, 0, false, 0, false)

        if VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_FETCH then
            call QuestGiver_RegisterItemRequirement(q.id, vendor, 1, VQ_TargetType[definitionId], VQ_TargetAmount[definitionId])
        elseif VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_KILL then
            call QuestGiver_RegisterUnitKillRequirement(q.id, vendor, 1, VQ_TargetType[definitionId], VQ_TargetAmount[definitionId])
        elseif VQ_ObjectiveType[definitionId] == VQ_OBJECTIVE_SUPPLY then
            call QuestGiver_RegisterTalkToRequirement(q.id, vendor, 1, null, VQ_TargetVendorName[definitionId])
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

    private function VQ_PlayLine takes unit vendor, integer definitionId, boolean completion returns nothing
        local string text
        local integer lineIndex = VQ_VoiceIndex[definitionId]

        if completion then
            set text = VQ_CompleteText[definitionId]
            set lineIndex = lineIndex + 1
        else
            set text = VQ_IntroText[definitionId]
        endif
        call DialogSystem_PlayLine(vendor, VendorLines_GetVendorSpeakerName(vendor), text, VQ_FormatSoundKey(VQ_VoiceType[definitionId], lineIndex), true)
        set vendor = null
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

    public function HandleAction takes integer actionId, unit vendor, unit hero returns boolean
        local integer questId = actionId - VQ_ACTION_BASE
        local integer definitionId = VQ_DefinitionByQuest.integer[questId]
        local QuestData q = QuestMaster_GetById(questId)

        if definitionId <= 0 or q == 0 or vendor == null or q.giver != vendor then
            set vendor = null
            set hero = null
            return false
        endif

        if q.state == QUEST_STATE_AVAILABLE then
            set VQ_SupplyClaimed.boolean[questId] = false
            call QuestGiver_AcceptQuest(questId)
            call VQ_PlayLine(vendor, definitionId, false)
        elseif q.state == QUEST_STATE_READY_TURNIN then
            if not VQ_HasTurnInItems(definitionId) then
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8040You no longer have the required " + GetObjectName(VQ_TargetType[definitionId]) + ".|r")
                set vendor = null
                set hero = null
                return true
            endif
            call VQ_RemoveTurnInItems(definitionId)
            call QuestGiver_CompleteQuest(questId)
            call VQ_PlayLine(vendor, definitionId, true)
        elseif q.state == QUEST_STATE_IN_PROGRESS then
            call DialogSystem_PlayLine(vendor, VendorLines_GetVendorSpeakerName(vendor), "I am still waiting on " + q.title + ". " + q.requirement1, "", true)
        endif

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
