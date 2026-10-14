/**
    QuestsGeneric

    Author: Valdemar
    Version: 2.0.1

    Description:
    Reusable kill, fetch, find, talk, purchase, and escort quest templates built
    on QuestGiver and QuestMaster. Templates support separate quest receivers
    and up to seven combined objectives. Vendor and non-vendor integrations can
    instantiate the same definitions and run interrupt-safe quest sequences.

    Credits:

    How to install:
    Import after QuestGiver, QuestMaster, DialogSystem, DialogInteraction,
    HeroItemCheck, and Table. Import VoicelinesQuests afterward to configure
    shared dialogue and daily acceptance variants.

    API:
    - QuestsGeneric_RegisterFetchQuest(...) registers an item template.
    - QuestsGeneric_RegisterKillQuest(...) registers a kill template.
    - QuestsGeneric_AddKillTargetCandidate(...) adds a safe random target.
    - QuestsGeneric_SetKillTargetZone(...) limits candidate discovery by zone.
    - QuestsGeneric_GetQuestTargetType(...) returns an instance's chosen target.
    - QuestsGeneric_RegisterTalkQuest(...) registers a manual talk template.
    - QuestsGeneric_RegisterFindQuest(...) registers a proximity-find template.
    - QuestsGeneric_RegisterEscortQuest(...) registers an escort template.
    - QuestsGeneric_AddFetchObjective/AddKillObjective/AddFindObjective(...)
      compose up to seven authored objectives before instantiation.
    - QuestsGeneric_SetReceiverUnit/SetReceiverUnitType(...) routes turn-in to
      an NPC other than the giver, including quests offered by notice boards.
    - QuestsGeneric_SetGiverUnit(...) binds a definition to one placed unit.
    - QuestsGeneric_SetObjective(...) changes an uninstantiated definition.
    - QuestsGeneric_SetQuestCategory(...) assigns story/content grouping.
    - QuestsGeneric_SetFactionReward(...) configures reputation rewards.
    - QuestsGeneric_SetExtendedDialogue(...) adds authored normal-quest lines.
    - QuestsGeneric_ConfigureSharedDialogue(...) sets shared text and hero voices.
    - QuestsGeneric_RegisterHeroVoiceVariant(...) adds a selectable-hero reply.
    - QuestsGeneric_RegisterDefinitionHeroVoiceVariant(...) scopes a reply.
    - Objective-specific accept/progress line types refine reusable hero replies.
    - QuestsGeneric_AddHeroVoiceVariantLine(...) plays a matching random reply.
    - QuestsGeneric_RegisterDailyAcceptanceVariant(...) adds a random line.
    - QuestsGeneric_RegisterProgressVariant(...) adds shared incomplete dialogue.
    - QuestsGeneric_RegisterDefinitionProgressVariant(...) scopes progress text.
    - QuestsGeneric_HasDefinitionForUnitType(...) checks template ownership.
    - QuestsGeneric_RegisterUnit(giver, displayName) instantiates templates.
    - QuestsGeneric_AddDialogButtons(...) adds managed quest choices.
    - QuestsGeneric_GetQuestIdFromAction(...) resolves a quest dialog action.
    - QuestsGeneric_BeginAction/FinishPendingAction/CancelPendingAction manage
      interrupt-safe accept, progress, and completion dialogue.

**/
library QuestsGeneric initializer Init requires QuestGiver, QuestMaster, DialogSystem, DialogInteraction, HeroItemCheck, Table, optional ZonesCore
    globals
        public constant integer OBJECTIVE_FETCH = 1
        public constant integer OBJECTIVE_KILL = 2
        public constant integer OBJECTIVE_TALK = 3
        public constant integer OBJECTIVE_PURCHASE = 4
        public constant integer OBJECTIVE_ESCORT = 5
        public constant integer OBJECTIVE_FIND = 6

        public constant integer HERO_LINE_ACCEPT = 1
        public constant integer HERO_LINE_COMPLETE_KILL = 2
        public constant integer HERO_LINE_COMPLETE_TALK = 3
        public constant integer HERO_LINE_COMPLETE_FETCH = 4
        public constant integer HERO_LINE_PROGRESS = 5
        public constant integer HERO_LINE_REQUEST_SUPPLY = 6
        public constant integer HERO_LINE_ASK_TO_BUY = 7
        public constant integer HERO_LINE_COMPLETE_ESCORT = 8
        public constant integer HERO_LINE_ACCEPT_KILL = 9
        public constant integer HERO_LINE_ACCEPT_FETCH = 10
        public constant integer HERO_LINE_ACCEPT_TALK = 11
        public constant integer HERO_LINE_ACCEPT_ESCORT = 12
        public constant integer HERO_LINE_PROGRESS_KILL = 13
        public constant integer HERO_LINE_PROGRESS_FETCH = 14
        public constant integer HERO_LINE_PROGRESS_TALK = 15
        public constant integer HERO_LINE_PROGRESS_ESCORT = 16

        private constant integer QG_MAX_DEFINITIONS = 128
        private constant integer QG_MAX_QUESTS = 500
        private constant integer QG_MAX_DAILY_VARIANTS = 512
        private constant integer QG_MAX_PROGRESS_VARIANTS = 64
        private constant integer QG_MAX_HERO_VOICE_VARIANTS = 256
        private constant integer QG_MAX_KILL_CANDIDATES_PER_DEFINITION = 8
        private constant integer QG_MAX_OBJECTIVES_PER_DEFINITION = 7
        private constant integer QG_OBJECTIVE_SLOT_STRIDE = 8
        private constant integer QG_MAX_REGISTERED_UNITS = 256
        private constant integer QG_ACTION_BASE = 10000
        private constant integer QG_PENDING_ACCEPT = 1
        private constant integer QG_PENDING_COMPLETE = 2

        private integer QG_DefinitionCount = 0
        private integer array QG_GiverUnitType
        private unit array QG_GiverUnit
        private string array QG_QuestName
        private string array QG_QuestType
        private string array QG_QuestCategory
        private integer array QG_QuestLevel
        private string array QG_Title
        private string array QG_IconPath
        private string array QG_Description
        private integer array QG_ObjectiveType
        private integer array QG_TargetType
        private integer array QG_TargetAmount
        private string array QG_TargetName
        private integer array QG_GoldBonus
        private string array QG_FactionName
        private integer array QG_ReputationBonus
        private boolean array QG_ReputationLinked
        private string array QG_VoiceType
        private integer array QG_VoiceIndex
        private string array QG_IntroText
        private string array QG_CompleteText
        private string array QG_AcceptExtraText
        private integer array QG_AcceptExtraVoiceIndex
        private string array QG_CompleteExtraText
        private integer array QG_CompleteExtraVoiceIndex
        private integer array QG_KillCandidateCount
        private integer array QG_KillCandidateUnitType
        private integer array QG_KillCandidateZoneId
        private integer array QG_ObjectiveCount
        private integer array QG_ObjectiveTypeBySlot
        private integer array QG_ObjectiveTargetType
        private integer array QG_ObjectiveTargetAmount
        private string array QG_ObjectiveTargetName
        private unit array QG_ObjectiveTargetUnit
        private boolean array QG_ObjectiveConsumesItem
        private integer array QG_ReceiverUnitType
        private unit array QG_ReceiverUnit
        private string array QG_ReceiverName
        private string array QG_ReceiverVoiceType
        private integer array QG_ReceiverCompleteVoiceIndex
        private string array QG_ReceiverCompleteText

        private integer QG_QuestCount = 0
        private integer array QG_QuestIds
        private Table QG_DefinitionByQuest = 0
        private Table QG_TargetTypeByQuest = 0
        private Table QG_InstantiatedByUnit = 0
        private Table QG_LastHeroVoiceChoice = 0
        private Table QG_RegisteredUnitByType = 0
        private Table QG_RegisteredUnitHandle = 0
        private Table QG_RegisteredUnitName = 0
        private integer QG_RegisteredUnitCount = 0
        private unit array QG_RegisteredUnit

        private integer QG_DailyVariantCount = 0
        private string array QG_DailyVariantVoiceType
        private integer array QG_DailyVariantObjectiveType
        private string array QG_DailyVariantText
        private integer array QG_DailyVariantVoiceIndex

        private integer QG_ProgressVariantCount = 0
        private integer array QG_ProgressVariantDefinitionId
        private integer array QG_ProgressVariantObjectiveType
        private string array QG_ProgressVariantText
        private string array QG_ProgressVariantSoundKey

        private integer QG_HeroVoiceVariantCount = 0
        private integer array QG_HeroVoiceVariantDefinitionId
        private integer array QG_HeroVoiceVariantLineType
        private string array QG_HeroVoiceVariantVoiceType
        private string array QG_HeroVoiceVariantText
        private integer array QG_HeroVoiceVariantIndex

        private string QG_HeroAcceptText = ""
        private string QG_HeroCompleteKillText = ""
        private string QG_HeroCompleteFetchText = ""
        private string QG_HeroCompleteTalkText = ""
        private string QG_HeroCompleteEscortText = ""
        private string QG_HeroProgressText = ""
        private string QG_GiverProgressPrefix = ""
        private string QG_NazgrekVoiceType = ""
        private string QG_ZulkisVoiceType = ""

        private integer QG_PendingQuestId = 0
        private integer QG_PendingDefinitionId = 0
        private integer QG_PendingAction = 0
        private unit QG_PendingGiver = null
    endglobals

    private function QG_FormatSoundKey takes string voiceType, integer lineIndex returns string
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

    public function FormatSoundKey takes string voiceType, integer lineIndex returns string
        return QG_FormatSoundKey(voiceType, lineIndex)
    endfunction

    public function ConfigureSharedDialogue takes string heroAccept, string heroCompleteKill, string heroCompleteFetch, string heroCompleteTalk, string heroCompleteEscort, string heroProgress, string giverProgressPrefix, string nazgrekVoiceType, string zulkisVoiceType returns nothing
        set QG_HeroAcceptText = heroAccept
        set QG_HeroCompleteKillText = heroCompleteKill
        set QG_HeroCompleteFetchText = heroCompleteFetch
        set QG_HeroCompleteTalkText = heroCompleteTalk
        set QG_HeroCompleteEscortText = heroCompleteEscort
        set QG_HeroProgressText = heroProgress
        set QG_GiverProgressPrefix = giverProgressPrefix
        set QG_NazgrekVoiceType = nazgrekVoiceType
        set QG_ZulkisVoiceType = zulkisVoiceType
    endfunction

    private function QG_GetObjectiveSlot takes integer definitionId, integer objectiveIndex returns integer
        return definitionId * QG_OBJECTIVE_SLOT_STRIDE + objectiveIndex
    endfunction

    private function QG_SetObjectiveSlot takes integer definitionId, integer objectiveIndex, integer objectiveType, integer targetType, integer targetAmount, string targetName, unit targetUnit returns nothing
        local integer slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)

        set QG_ObjectiveTypeBySlot[slot] = objectiveType
        set QG_ObjectiveTargetType[slot] = targetType
        set QG_ObjectiveTargetAmount[slot] = targetAmount
        set QG_ObjectiveTargetName[slot] = targetName
        set QG_ObjectiveTargetUnit[slot] = targetUnit
        set QG_ObjectiveConsumesItem[slot] = false
        set targetUnit = null
    endfunction

    private function QG_RegisterDefinition takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer objectiveType, integer targetType, integer targetAmount, string targetName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        local integer definitionId

        if giverUnitTypeId == 0 or questName == "" or title == "" or QG_DefinitionCount >= QG_MAX_DEFINITIONS then
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

        set QG_DefinitionCount = QG_DefinitionCount + 1
        set definitionId = QG_DefinitionCount
        set QG_GiverUnitType[definitionId] = giverUnitTypeId
        set QG_QuestName[definitionId] = questName
        set QG_QuestType[definitionId] = questType
        set QG_QuestCategory[definitionId] = "general"
        set QG_QuestLevel[definitionId] = questLevel
        set QG_Title[definitionId] = title
        set QG_IconPath[definitionId] = iconPath
        set QG_Description[definitionId] = description
        set QG_ObjectiveType[definitionId] = objectiveType
        set QG_TargetType[definitionId] = targetType
        set QG_TargetAmount[definitionId] = targetAmount
        set QG_TargetName[definitionId] = targetName
        set QG_ObjectiveCount[definitionId] = 1
        call QG_SetObjectiveSlot(definitionId, 1, objectiveType, targetType, targetAmount, targetName, null)
        set QG_GoldBonus[definitionId] = goldBonus
        set QG_VoiceType[definitionId] = voiceType
        set QG_VoiceIndex[definitionId] = voiceIndex
        set QG_IntroText[definitionId] = introText
        set QG_CompleteText[definitionId] = completeText
        return definitionId
    endfunction

    public function RegisterFetchQuest takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer itemTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QG_RegisterDefinition(giverUnitTypeId, questName, questType, questLevel, title, iconPath, description, OBJECTIVE_FETCH, itemTypeId, amount, "", goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterKillQuest takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer unitTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QG_RegisterDefinition(giverUnitTypeId, questName, questType, questLevel, title, iconPath, description, OBJECTIVE_KILL, unitTypeId, amount, "", goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    private function QG_GetKillCandidateSlot takes integer definitionId, integer candidateIndex returns integer
        return definitionId * QG_MAX_KILL_CANDIDATES_PER_DEFINITION + candidateIndex
    endfunction

    public function AddKillTargetCandidate takes integer definitionId, integer unitTypeId returns nothing
        local integer candidateCount

        if definitionId <= 0 or definitionId > QG_DefinitionCount or QG_ObjectiveType[definitionId] != OBJECTIVE_KILL or unitTypeId == 0 then
            return
        endif
        set candidateCount = QG_KillCandidateCount[definitionId]
        if candidateCount >= QG_MAX_KILL_CANDIDATES_PER_DEFINITION then
            return
        endif
        set candidateCount = candidateCount + 1
        set QG_KillCandidateCount[definitionId] = candidateCount
        set QG_KillCandidateUnitType[QG_GetKillCandidateSlot(definitionId, candidateCount)] = unitTypeId
    endfunction

    public function SetKillTargetZone takes integer definitionId, integer zoneId returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount or QG_ObjectiveType[definitionId] != OBJECTIVE_KILL then
            return
        endif
        set QG_KillCandidateZoneId[definitionId] = zoneId
    endfunction

    public function RegisterTalkQuest takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, string targetName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QG_RegisterDefinition(giverUnitTypeId, questName, questType, questLevel, title, iconPath, description, OBJECTIVE_TALK, 0, 1, targetName, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterFindQuest takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer targetUnitTypeId, string targetName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QG_RegisterDefinition(giverUnitTypeId, questName, questType, questLevel, title, iconPath, description, OBJECTIVE_FIND, targetUnitTypeId, 1, targetName, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterEscortQuest takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, string destinationName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QG_RegisterDefinition(giverUnitTypeId, questName, questType, questLevel, title, iconPath, description, OBJECTIVE_ESCORT, 0, 1, destinationName, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function SetObjective takes integer definitionId, integer objectiveType, integer targetType, integer targetAmount, string targetName returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            return
        endif
        if objectiveType < OBJECTIVE_FETCH or objectiveType > OBJECTIVE_FIND then
            return
        endif
        if targetAmount < 1 then
            set targetAmount = 1
        endif
        set QG_ObjectiveType[definitionId] = objectiveType
        set QG_TargetType[definitionId] = targetType
        set QG_TargetAmount[definitionId] = targetAmount
        set QG_TargetName[definitionId] = targetName
        call QG_SetObjectiveSlot(definitionId, 1, objectiveType, targetType, targetAmount, targetName, null)
    endfunction

    public function SetDeliveryObjective takes integer definitionId, integer itemTypeId, integer amount, string targetName returns nothing
        call SetObjective(definitionId, OBJECTIVE_TALK, itemTypeId, amount, targetName)
        if definitionId > 0 and definitionId <= QG_DefinitionCount then
            set QG_ObjectiveConsumesItem[QG_GetObjectiveSlot(definitionId, 1)] = true
        endif
    endfunction

    private function QG_AddObjective takes integer definitionId, integer objectiveType, integer targetType, integer targetAmount, string targetName, unit targetUnit returns boolean
        local integer objectiveIndex

        if definitionId <= 0 or definitionId > QG_DefinitionCount or objectiveType < OBJECTIVE_FETCH or objectiveType > OBJECTIVE_FIND then
            set targetUnit = null
            return false
        endif
        set objectiveIndex = QG_ObjectiveCount[definitionId] + 1
        if objectiveIndex > QG_MAX_OBJECTIVES_PER_DEFINITION then
            set targetUnit = null
            return false
        endif
        if targetAmount < 1 then
            set targetAmount = 1
        endif
        set QG_ObjectiveCount[definitionId] = objectiveIndex
        call QG_SetObjectiveSlot(definitionId, objectiveIndex, objectiveType, targetType, targetAmount, targetName, targetUnit)
        set targetUnit = null
        return true
    endfunction

    public function AddFetchObjective takes integer definitionId, integer itemTypeId, integer amount returns boolean
        return QG_AddObjective(definitionId, OBJECTIVE_FETCH, itemTypeId, amount, "", null)
    endfunction

    public function AddKillObjective takes integer definitionId, integer unitTypeId, integer amount returns boolean
        return QG_AddObjective(definitionId, OBJECTIVE_KILL, unitTypeId, amount, "", null)
    endfunction

    public function AddTalkObjective takes integer definitionId, unit targetNPC, string targetName returns boolean
        local integer targetUnitTypeId = 0
        local boolean added

        if targetNPC != null then
            set targetUnitTypeId = GetUnitTypeId(targetNPC)
        endif
        set added = QG_AddObjective(definitionId, OBJECTIVE_TALK, targetUnitTypeId, 1, targetName, targetNPC)
        set targetNPC = null
        return added
    endfunction

    public function AddFindObjective takes integer definitionId, integer targetUnitTypeId, string targetName returns boolean
        return QG_AddObjective(definitionId, OBJECTIVE_FIND, targetUnitTypeId, 1, targetName, null)
    endfunction

    public function SetObjectiveTargetUnit takes integer definitionId, integer objectiveIndex, unit targetUnit returns nothing
        local integer slot

        if definitionId <= 0 or definitionId > QG_DefinitionCount or objectiveIndex < 1 or objectiveIndex > QG_ObjectiveCount[definitionId] then
            set targetUnit = null
            return
        endif
        set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
        set QG_ObjectiveTargetUnit[slot] = targetUnit
        if targetUnit != null then
            set QG_ObjectiveTargetType[slot] = GetUnitTypeId(targetUnit)
        endif
        set targetUnit = null
    endfunction

    public function SetGiverUnit takes integer definitionId, unit giver returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount or giver == null or GetUnitTypeId(giver) != QG_GiverUnitType[definitionId] then
            set giver = null
            return
        endif
        set QG_GiverUnit[definitionId] = giver
        set giver = null
    endfunction

    public function SetReceiverUnit takes integer definitionId, unit receiver, string receiverName returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            set receiver = null
            return
        endif
        set QG_ReceiverUnit[definitionId] = receiver
        if receiver != null then
            set QG_ReceiverUnitType[definitionId] = GetUnitTypeId(receiver)
        endif
        set QG_ReceiverName[definitionId] = receiverName
        set receiver = null
    endfunction

    public function SetReceiverUnitType takes integer definitionId, integer receiverUnitTypeId, string receiverName returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            return
        endif
        set QG_ReceiverUnitType[definitionId] = receiverUnitTypeId
        set QG_ReceiverName[definitionId] = receiverName
    endfunction

    public function SetReceiverDialogue takes integer definitionId, string voiceType, integer completeVoiceIndex, string completeText returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            return
        endif
        set QG_ReceiverVoiceType[definitionId] = voiceType
        set QG_ReceiverCompleteVoiceIndex[definitionId] = completeVoiceIndex
        set QG_ReceiverCompleteText[definitionId] = completeText
    endfunction

    public function SetQuestCategory takes integer definitionId, string category returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            return
        endif
        if category == "story" or category == "dungeon" or category == "class" or category == "profession" then
            set QG_QuestCategory[definitionId] = category
        else
            set QG_QuestCategory[definitionId] = "general"
        endif
    endfunction

    public function SetFactionReward takes integer definitionId, string factionName, integer reputationBonus, boolean linked returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount or factionName == null or factionName == "" then
            return
        endif
        set QG_FactionName[definitionId] = factionName
        set QG_ReputationBonus[definitionId] = reputationBonus
        set QG_ReputationLinked[definitionId] = linked
    endfunction

    public function SetExtendedDialogue takes integer definitionId, string acceptText, integer acceptVoiceIndex, string completeText, integer completeVoiceIndex returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            return
        endif
        set QG_AcceptExtraText[definitionId] = acceptText
        set QG_AcceptExtraVoiceIndex[definitionId] = acceptVoiceIndex
        set QG_CompleteExtraText[definitionId] = completeText
        set QG_CompleteExtraVoiceIndex[definitionId] = completeVoiceIndex
    endfunction

    public function RegisterDailyAcceptanceVariant takes string voiceType, integer objectiveType, string text, integer voiceIndex returns nothing
        if voiceType == null or voiceType == "" or text == null or text == "" or voiceIndex <= 0 or QG_DailyVariantCount >= QG_MAX_DAILY_VARIANTS then
            return
        endif
        set QG_DailyVariantCount = QG_DailyVariantCount + 1
        set QG_DailyVariantVoiceType[QG_DailyVariantCount] = voiceType
        set QG_DailyVariantObjectiveType[QG_DailyVariantCount] = objectiveType
        set QG_DailyVariantText[QG_DailyVariantCount] = text
        set QG_DailyVariantVoiceIndex[QG_DailyVariantCount] = voiceIndex
    endfunction

    private function QG_RegisterHeroVoiceVariant takes integer definitionId, integer lineType, string voiceType, string text, integer voiceIndex returns nothing
        if lineType < HERO_LINE_ACCEPT or lineType > HERO_LINE_PROGRESS_ESCORT or voiceType == null or voiceType == "" or text == null or text == "" or voiceIndex <= 0 or QG_HeroVoiceVariantCount >= QG_MAX_HERO_VOICE_VARIANTS then
            return
        endif
        set QG_HeroVoiceVariantCount = QG_HeroVoiceVariantCount + 1
        set QG_HeroVoiceVariantDefinitionId[QG_HeroVoiceVariantCount] = definitionId
        set QG_HeroVoiceVariantLineType[QG_HeroVoiceVariantCount] = lineType
        set QG_HeroVoiceVariantVoiceType[QG_HeroVoiceVariantCount] = voiceType
        set QG_HeroVoiceVariantText[QG_HeroVoiceVariantCount] = text
        set QG_HeroVoiceVariantIndex[QG_HeroVoiceVariantCount] = voiceIndex
    endfunction

    public function RegisterHeroVoiceVariant takes integer lineType, string voiceType, string text, integer voiceIndex returns nothing
        call QG_RegisterHeroVoiceVariant(0, lineType, voiceType, text, voiceIndex)
        if lineType == HERO_LINE_ACCEPT then
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_ACCEPT_KILL, voiceType, text, voiceIndex)
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_ACCEPT_FETCH, voiceType, text, voiceIndex)
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_ACCEPT_TALK, voiceType, text, voiceIndex)
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_ACCEPT_ESCORT, voiceType, text, voiceIndex)
        elseif lineType == HERO_LINE_PROGRESS then
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_PROGRESS_KILL, voiceType, text, voiceIndex)
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_PROGRESS_FETCH, voiceType, text, voiceIndex)
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_PROGRESS_TALK, voiceType, text, voiceIndex)
            call QG_RegisterHeroVoiceVariant(0, HERO_LINE_PROGRESS_ESCORT, voiceType, text, voiceIndex)
        endif
    endfunction

    public function RegisterDefinitionHeroVoiceVariant takes integer definitionId, integer lineType, string voiceType, string text, integer voiceIndex returns nothing
        if definitionId > 0 and definitionId <= QG_DefinitionCount then
            call QG_RegisterHeroVoiceVariant(definitionId, lineType, voiceType, text, voiceIndex)
        endif
    endfunction

    public function RegisterProgressVariant takes integer objectiveType, string text, string soundKey returns nothing
        if objectiveType < OBJECTIVE_FETCH or objectiveType > OBJECTIVE_FIND or text == null or text == "" or QG_ProgressVariantCount >= QG_MAX_PROGRESS_VARIANTS then
            return
        endif
        set QG_ProgressVariantCount = QG_ProgressVariantCount + 1
        set QG_ProgressVariantDefinitionId[QG_ProgressVariantCount] = 0
        set QG_ProgressVariantObjectiveType[QG_ProgressVariantCount] = objectiveType
        set QG_ProgressVariantText[QG_ProgressVariantCount] = text
        if soundKey == null then
            set soundKey = ""
        endif
        set QG_ProgressVariantSoundKey[QG_ProgressVariantCount] = soundKey
    endfunction

    public function RegisterDefinitionProgressVariant takes integer definitionId, string text, integer voiceIndex returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount or text == null or text == "" or voiceIndex <= 0 or QG_ProgressVariantCount >= QG_MAX_PROGRESS_VARIANTS then
            return
        endif
        set QG_ProgressVariantCount = QG_ProgressVariantCount + 1
        set QG_ProgressVariantDefinitionId[QG_ProgressVariantCount] = definitionId
        set QG_ProgressVariantObjectiveType[QG_ProgressVariantCount] = QG_ObjectiveType[definitionId]
        set QG_ProgressVariantText[QG_ProgressVariantCount] = text
        set QG_ProgressVariantSoundKey[QG_ProgressVariantCount] = QG_FormatSoundKey(QG_VoiceType[definitionId], voiceIndex)
    endfunction

    private function QG_GetInfoText takes string questType returns string
        if questType == "daily" then
            return "|cff80a0ffDaily quest|r\n\n"
        elseif questType == "repeatable" then
            return "|cff80a0ffRepeatable quest|r\n\n"
        endif
        return "|cffffcc00Quest|r\n\n"
    endfunction

    private function QG_IsPointInZoneOrChild takes real x, real y, integer targetZoneId returns boolean
        local integer zoneId

        if targetZoneId <= 0 then
            return true
        endif
        static if LIBRARY_ZonesCore then
            set zoneId = ZonesCore_GetZoneIdAtPoint(x, y)
            loop
                if zoneId == targetZoneId then
                    return true
                endif
                exitwhen zoneId <= 0
                set zoneId = ZonesCore_GetParentZoneId(zoneId)
            endloop
            return false
        else
            return true
        endif
    endfunction

    private function QG_IsKillCandidatePresent takes integer unitTypeId, integer zoneId returns boolean
        local group worldUnits = CreateGroup()
        local rect worldBounds = GetWorldBounds()
        local unit enumUnit
        local boolean found = false

        call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
        loop
            set enumUnit = FirstOfGroup(worldUnits)
            exitwhen enumUnit == null
            call GroupRemoveUnit(worldUnits, enumUnit)
            if GetUnitTypeId(enumUnit) == unitTypeId and GetWidgetLife(enumUnit) > 0.405 and QG_IsPointInZoneOrChild(GetUnitX(enumUnit), GetUnitY(enumUnit), zoneId) then
                set found = true
                set enumUnit = null
                exitwhen true
            endif
        endloop

        call DestroyGroup(worldUnits)
        call RemoveRect(worldBounds)
        set worldUnits = null
        set worldBounds = null
        set enumUnit = null
        return found
    endfunction

    private function QG_SelectKillTarget takes integer definitionId, unit giver returns integer
        local integer candidateIndex = 1
        local integer candidateCount = QG_KillCandidateCount[definitionId]
        local integer eligibleCount = 0
        local integer selectedType = QG_TargetType[definitionId]
        local integer unitTypeId
        local integer zoneId = QG_KillCandidateZoneId[definitionId]

        if candidateCount <= 0 then
            set giver = null
            return selectedType
        endif
        static if LIBRARY_ZonesCore then
            if zoneId <= 0 and giver != null then
                set zoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(giver), GetUnitY(giver))
            endif
        endif
        loop
            exitwhen candidateIndex > candidateCount
            set unitTypeId = QG_KillCandidateUnitType[QG_GetKillCandidateSlot(definitionId, candidateIndex)]
            if QG_IsKillCandidatePresent(unitTypeId, zoneId) then
                set eligibleCount = eligibleCount + 1
                if GetRandomInt(1, eligibleCount) == 1 then
                    set selectedType = unitTypeId
                endif
            endif
            set candidateIndex = candidateIndex + 1
        endloop

        set giver = null
        return selectedType
    endfunction

    private function QG_ResolveReceiver takes integer definitionId, unit giver returns unit
        local unit receiver = QG_ReceiverUnit[definitionId]

        if receiver != null and DialogInteraction_IsUnitAlive(receiver) then
            set giver = null
            return receiver
        endif
        if QG_ReceiverUnitType[definitionId] == 0 then
            set receiver = giver
        else
            set receiver = QG_RegisteredUnitByType.unit[QG_ReceiverUnitType[definitionId]]
        endif
        set giver = null
        return receiver
    endfunction

    private function QG_ResolveObjectiveTarget takes integer definitionId, integer objectiveIndex returns unit
        local integer slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
        local unit target = QG_ObjectiveTargetUnit[slot]

        if target != null and DialogInteraction_IsUnitAlive(target) then
            return target
        endif
        if QG_ObjectiveTargetType[slot] != 0 then
            set target = QG_RegisteredUnitByType.unit[QG_ObjectiveTargetType[slot]]
        endif
        return target
    endfunction

    private function QG_CanCreateQuest takes integer definitionId, unit giver returns boolean
        local integer objectiveIndex = 1
        local integer slot
        local integer objectiveType
        local unit target
        local unit receiver

        if definitionId <= 0 or definitionId > QG_DefinitionCount or giver == null then
            set giver = null
            return false
        endif
        set receiver = QG_ResolveReceiver(definitionId, giver)
        if receiver == null or not DialogInteraction_IsUnitAlive(receiver) then
            set giver = null
            set receiver = null
            return false
        endif
        loop
            exitwhen objectiveIndex > QG_ObjectiveCount[definitionId]
            set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
            set objectiveType = QG_ObjectiveTypeBySlot[slot]
            if objectiveType == OBJECTIVE_FIND then
                set target = QG_ResolveObjectiveTarget(definitionId, objectiveIndex)
                if target == null or not DialogInteraction_IsUnitAlive(target) then
                    set giver = null
                    set receiver = null
                    set target = null
                    return false
                endif
            endif
            set objectiveIndex = objectiveIndex + 1
        endloop
        set giver = null
        set receiver = null
        set target = null
        return true
    endfunction

    private function QG_CreateQuest takes integer definitionId, unit giver, string giverName returns boolean
        local QuestData q
        local string info2Text
        local string factionName
        local string receiverName
        local integer objectiveIndex = 1
        local integer slot
        local integer objectiveType
        local integer targetType
        local integer targetAmount
        local string targetName
        local unit targetUnit
        local unit receiver

        if definitionId <= 0 or definitionId > QG_DefinitionCount or giver == null or QG_QuestCount >= QG_MAX_QUESTS or not QG_CanCreateQuest(definitionId, giver) then
            set giver = null
            return false
        endif
        if giverName == null or giverName == "" then
            set giverName = GetUnitName(giver)
        endif
        set receiver = QG_ResolveReceiver(definitionId, giver)
        set receiverName = QG_ReceiverName[definitionId]
        if receiverName == null or receiverName == "" then
            set receiverName = GetUnitName(receiver)
        endif
        if not QuestMaster_IsRegisteredGiver(receiver) then
            call QuestGiver_Register(receiver)
        endif

        set factionName = QG_FactionName[definitionId]
        if factionName == null or factionName == "" then
            set factionName = Reputation_GetUnitFactionName(giver)
        endif
        set info2Text = "|cffffcc00Recommended level:|r " + I2S(QG_QuestLevel[definitionId]) + "\n\n"
        set q = QuestGiver_CreateConfiguredQuest(QG_QuestName[definitionId], giver, QG_QuestType[definitionId], QG_QuestLevel[definitionId], receiver, QG_Title[definitionId], QG_IconPath[definitionId], QG_Description[definitionId] + "\n\n", QG_GetInfoText(QG_QuestType[definitionId]), info2Text, QG_QuestLevel[definitionId], true, true, true, factionName, receiverName)
        if q == 0 then
            set giver = null
            set receiver = null
            return false
        endif
        call QuestGiver_SetQuestCategory(q, QG_QuestCategory[definitionId])
        if factionName != null and factionName != "" then
            call QuestGiver_SetQuestRequiredReputation(q, Reputation_REP_NEUTRAL)
        endif
        call QuestGiver_SetQuestRewards(q, true, 0, true, QG_GoldBonus[definitionId], false, 0, QG_ReputationBonus[definitionId] != 0, QG_ReputationBonus[definitionId], QG_ReputationLinked[definitionId])

        loop
            exitwhen objectiveIndex > QG_ObjectiveCount[definitionId]
            set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
            set objectiveType = QG_ObjectiveTypeBySlot[slot]
            set targetType = QG_ObjectiveTargetType[slot]
            set targetAmount = QG_ObjectiveTargetAmount[slot]
            set targetName = QG_ObjectiveTargetName[slot]
            if objectiveIndex == 1 and objectiveType == OBJECTIVE_KILL then
                set targetType = QG_SelectKillTarget(definitionId, giver)
            endif
            if objectiveType == OBJECTIVE_FETCH or objectiveType == OBJECTIVE_PURCHASE then
                call QuestGiver_RegisterItemRequirement(q.id, giver, objectiveIndex, targetType, targetAmount)
            elseif objectiveType == OBJECTIVE_KILL then
                call QuestGiver_RegisterUnitKillRequirement(q.id, giver, objectiveIndex, targetType, targetAmount)
            elseif objectiveType == OBJECTIVE_TALK then
                set targetUnit = QG_ResolveObjectiveTarget(definitionId, objectiveIndex)
                call QuestGiver_RegisterTalkToRequirement(q.id, giver, objectiveIndex, targetUnit, targetName)
            elseif objectiveType == OBJECTIVE_FIND then
                set targetUnit = QG_ResolveObjectiveTarget(definitionId, objectiveIndex)
                call QuestGiver_RegisterFindNPCRequirement(q.id, giver, objectiveIndex, targetUnit, targetName)
                call QuestGiver_SetObjectiveTarget(q.id, objectiveIndex, targetUnit)
            endif
            if objectiveIndex == 1 then
                set QG_TargetTypeByQuest.integer[q.id] = targetType
            endif
            set objectiveIndex = objectiveIndex + 1
        endloop

        set QG_QuestCount = QG_QuestCount + 1
        set QG_QuestIds[QG_QuestCount] = q.id
        set QG_DefinitionByQuest.integer[q.id] = definitionId
        call QuestMaster_RefreshAvailabilityForGiver(giver)
        set giver = null
        set receiver = null
        set targetUnit = null
        return true
    endfunction

    public function HasDefinitionForUnitType takes integer unitTypeId returns boolean
        local integer definitionId = 1

        if unitTypeId == 0 then
            return false
        endif
        loop
            exitwhen definitionId > QG_DefinitionCount
            if QG_GiverUnitType[definitionId] == unitTypeId then
                return true
            endif
            set definitionId = definitionId + 1
        endloop
        return false
    endfunction

    public function HasReceiverDefinitionForUnitType takes integer unitTypeId returns boolean
        local integer definitionId = 1

        if unitTypeId == 0 then
            return false
        endif
        loop
            exitwhen definitionId > QG_DefinitionCount
            if QG_ReceiverUnitType[definitionId] == unitTypeId then
                return true
            endif
            set definitionId = definitionId + 1
        endloop
        return false
    endfunction

    public function HasInteractionForUnitType takes integer unitTypeId returns boolean
        return HasDefinitionForUnitType(unitTypeId) or HasReceiverDefinitionForUnitType(unitTypeId)
    endfunction

    private function QG_DefinitionMatchesGiver takes integer definitionId, unit giver returns boolean
        if definitionId <= 0 or definitionId > QG_DefinitionCount or giver == null or QG_GiverUnitType[definitionId] != GetUnitTypeId(giver) then
            set giver = null
            return false
        endif
        if QG_GiverUnit[definitionId] != null and QG_GiverUnit[definitionId] != giver then
            set giver = null
            return false
        endif
        set giver = null
        return true
    endfunction

    private function QG_IsRelevantUnitType takes integer unitTypeId returns boolean
        local integer definitionId = 1
        local integer objectiveIndex
        local integer slot

        if HasInteractionForUnitType(unitTypeId) then
            return true
        endif
        loop
            exitwhen definitionId > QG_DefinitionCount
            set objectiveIndex = 1
            loop
                exitwhen objectiveIndex > QG_ObjectiveCount[definitionId]
                set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
                if QG_ObjectiveTypeBySlot[slot] == OBJECTIVE_FIND and QG_ObjectiveTargetType[slot] == unitTypeId then
                    return true
                endif
                set objectiveIndex = objectiveIndex + 1
            endloop
            set definitionId = definitionId + 1
        endloop
        return false
    endfunction

    private function QG_CreateRegisteredQuests takes nothing returns nothing
        local integer unitIndex = 1
        local integer definitionId
        local integer handleId
        local unit giver
        local Table instantiated

        loop
            exitwhen unitIndex > QG_RegisteredUnitCount
            set giver = QG_RegisteredUnit[unitIndex]
            if giver != null and DialogInteraction_IsUnitAlive(giver) then
                set handleId = GetHandleId(giver)
                set instantiated = QG_InstantiatedByUnit.link(handleId)
                set definitionId = 1
                loop
                    exitwhen definitionId > QG_DefinitionCount
                    if QG_DefinitionMatchesGiver(definitionId, giver) and not instantiated.boolean[definitionId] and QG_CanCreateQuest(definitionId, giver) then
                        if QG_CreateQuest(definitionId, giver, QG_RegisteredUnitName.string[handleId]) then
                            set instantiated.boolean[definitionId] = true
                        endif
                    endif
                    set definitionId = definitionId + 1
                endloop
            endif
            set unitIndex = unitIndex + 1
        endloop
        set giver = null
    endfunction

    public function RegisterUnit takes unit giver, string giverName returns nothing
        local integer handleId

        if giver == null or GetUnitTypeId(giver) == 0 then
            set giver = null
            return
        endif
        if not QG_IsRelevantUnitType(GetUnitTypeId(giver)) then
            set giver = null
            return
        endif
        set handleId = GetHandleId(giver)
        set QG_RegisteredUnitByType.unit[GetUnitTypeId(giver)] = giver
        set QG_RegisteredUnitName.string[handleId] = giverName
        if not QG_RegisteredUnitHandle.boolean[handleId] and QG_RegisteredUnitCount < QG_MAX_REGISTERED_UNITS then
            set QG_RegisteredUnitHandle.boolean[handleId] = true
            set QG_RegisteredUnitCount = QG_RegisteredUnitCount + 1
            set QG_RegisteredUnit[QG_RegisteredUnitCount] = giver
        endif
        if HasInteractionForUnitType(GetUnitTypeId(giver)) and not QuestMaster_IsRegisteredGiver(giver) then
            call QuestGiver_Register(giver)
        endif
        call QG_CreateRegisteredQuests()
        if QuestMaster_IsRegisteredGiver(giver) then
            call QuestMaster_RefreshAvailabilityForGiver(giver)
        endif
        set giver = null
    endfunction

    public function GetDefinitionForQuest takes integer questId returns integer
        return QG_DefinitionByQuest.integer[questId]
    endfunction

    public function GetQuestCount takes nothing returns integer
        return QG_QuestCount
    endfunction

    public function GetQuestIdByIndex takes integer index returns integer
        if index < 1 or index > QG_QuestCount then
            return 0
        endif
        return QG_QuestIds[index]
    endfunction

    public function GetObjectiveType takes integer definitionId returns integer
        return QG_ObjectiveType[definitionId]
    endfunction

    public function GetTargetType takes integer definitionId returns integer
        return QG_TargetType[definitionId]
    endfunction

    public function GetQuestTargetType takes integer questId returns integer
        return QG_TargetTypeByQuest.integer[questId]
    endfunction

    public function GetTargetAmount takes integer definitionId returns integer
        return QG_TargetAmount[definitionId]
    endfunction

    public function AddDialogButtons takes dialog d, unit giver, code actionFunc returns integer
        local integer index = 1
        local integer added = 0
        local integer questId
        local QuestData q
        local button b

        if d == null or giver == null or actionFunc == null then
            set d = null
            set giver = null
            set b = null
            return 0
        endif
        loop
            exitwhen index > QG_QuestCount
            set questId = QG_QuestIds[index]
            set q = QuestMaster_GetById(questId)
            if q != 0 and ((q.giver == giver and (q.state != QUEST_STATE_READY_TURNIN or q.receiver == giver)) or (q.receiver == giver and q.state == QUEST_STATE_READY_TURNIN)) then
                set b = DialogSystem_AddButtonQuestState(d, q.title, q.state, QG_ACTION_BASE + questId)
                if b != null then
                    call DialogSystem_BindButtonCode(b, actionFunc)
                    set added = added + 1
                endif
            endif
            set index = index + 1
        endloop
        set d = null
        set giver = null
        set b = null
        return added
    endfunction

    public function IsQuestAction takes integer actionId returns boolean
        return actionId > QG_ACTION_BASE and QG_DefinitionByQuest.integer.has(actionId - QG_ACTION_BASE)
    endfunction

    public function GetQuestIdFromAction takes integer actionId returns integer
        if not IsQuestAction(actionId) then
            return 0
        endif
        return actionId - QG_ACTION_BASE
    endfunction

    private function QG_IsItemObjective takes integer slot returns boolean
        return QG_ObjectiveTypeBySlot[slot] == OBJECTIVE_FETCH or QG_ObjectiveTypeBySlot[slot] == OBJECTIVE_PURCHASE or QG_ObjectiveConsumesItem[slot]
    endfunction

    private function QG_IsFirstItemObjective takes integer definitionId, integer objectiveIndex returns boolean
        local integer slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
        local integer earlierIndex = 1
        local integer earlierSlot

        loop
            exitwhen earlierIndex >= objectiveIndex
            set earlierSlot = QG_GetObjectiveSlot(definitionId, earlierIndex)
            if QG_IsItemObjective(earlierSlot) and QG_ObjectiveTargetType[earlierSlot] == QG_ObjectiveTargetType[slot] then
                return false
            endif
            set earlierIndex = earlierIndex + 1
        endloop
        return true
    endfunction

    private function QG_GetRequiredItemTotal takes integer definitionId, integer itemTypeId returns integer
        local integer objectiveIndex = 1
        local integer slot
        local integer total = 0

        loop
            exitwhen objectiveIndex > QG_ObjectiveCount[definitionId]
            set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
            if QG_IsItemObjective(slot) and QG_ObjectiveTargetType[slot] == itemTypeId then
                set total = total + QG_ObjectiveTargetAmount[slot]
            endif
            set objectiveIndex = objectiveIndex + 1
        endloop
        return total
    endfunction

    private function QG_HasTurnInItems takes integer definitionId returns boolean
        local integer objectiveIndex = 1
        local integer slot
        local integer requiredAmount

        loop
            exitwhen objectiveIndex > QG_ObjectiveCount[definitionId]
            set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
            if QG_IsItemObjective(slot) and QG_IsFirstItemObjective(definitionId, objectiveIndex) then
                set requiredAmount = QG_GetRequiredItemTotal(definitionId, QG_ObjectiveTargetType[slot])
                if not HeroItemCheckBoth(QG_ObjectiveTargetType[slot], requiredAmount) then
                    return false
                endif
            endif
            set objectiveIndex = objectiveIndex + 1
        endloop
        return true
    endfunction

    private function QG_RemoveTurnInItems takes integer definitionId returns nothing
        local integer objectiveIndex = 1
        local integer slot
        local integer requiredAmount

        loop
            exitwhen objectiveIndex > QG_ObjectiveCount[definitionId]
            set slot = QG_GetObjectiveSlot(definitionId, objectiveIndex)
            if QG_IsItemObjective(slot) and QG_IsFirstItemObjective(definitionId, objectiveIndex) then
                set requiredAmount = QG_GetRequiredItemTotal(definitionId, QG_ObjectiveTargetType[slot])
                call HeroItemCheckBothAndRemove(QG_ObjectiveTargetType[slot], requiredAmount)
            endif
            set objectiveIndex = objectiveIndex + 1
        endloop
    endfunction

    private function QG_ClearPendingAction takes nothing returns nothing
        set QG_PendingQuestId = 0
        set QG_PendingDefinitionId = 0
        set QG_PendingAction = 0
        set QG_PendingGiver = null
    endfunction

    public function CancelPendingAction takes nothing returns nothing
        call QG_ClearPendingAction()
    endfunction

    private function QG_GetHeroCompleteText takes integer definitionId returns string
        if QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
            return QG_HeroCompleteKillText
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK or QG_ObjectiveType[definitionId] == OBJECTIVE_FIND then
            return QG_HeroCompleteTalkText
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_ESCORT then
            return QG_HeroCompleteEscortText
        endif
        return QG_HeroCompleteFetchText
    endfunction

    private function QG_GetHeroCompleteVoiceIndex takes integer definitionId returns integer
        if QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
            return 5
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK or QG_ObjectiveType[definitionId] == OBJECTIVE_FIND then
            return 9
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_ESCORT then
            return 29
        endif
        return 13
    endfunction

    private function QG_GetAcceptHeroLineType takes integer definitionId returns integer
        if QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
            return HERO_LINE_ACCEPT_KILL
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK or QG_ObjectiveType[definitionId] == OBJECTIVE_FIND then
            return HERO_LINE_ACCEPT_TALK
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_ESCORT then
            return HERO_LINE_ACCEPT_ESCORT
        endif
        return HERO_LINE_ACCEPT_FETCH
    endfunction

    private function QG_GetProgressHeroLineType takes integer definitionId returns integer
        if QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
            return HERO_LINE_PROGRESS_KILL
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK or QG_ObjectiveType[definitionId] == OBJECTIVE_FIND then
            return HERO_LINE_PROGRESS_TALK
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_ESCORT then
            return HERO_LINE_PROGRESS_ESCORT
        endif
        return HERO_LINE_PROGRESS_FETCH
    endfunction

    private function QG_CountHeroVoiceVariants takes integer definitionId, integer lineType, string voiceType returns integer
        local integer index = 1
        local integer count = 0

        loop
            exitwhen index > QG_HeroVoiceVariantCount
            if QG_HeroVoiceVariantDefinitionId[index] == definitionId and QG_HeroVoiceVariantLineType[index] == lineType and QG_HeroVoiceVariantVoiceType[index] == voiceType then
                set count = count + 1
            endif
            set index = index + 1
        endloop
        return count
    endfunction

    private function QG_PickHeroVoiceVariant takes integer definitionId, integer lineType, string voiceType, integer count returns integer
        local integer key = StringHash(voiceType + ":" + I2S(definitionId) + ":" + I2S(lineType))
        local integer previousChoice = QG_LastHeroVoiceChoice.integer[key]
        local integer choice
        local integer index = 1
        local integer found = 0

        if count <= 0 then
            return 0
        elseif count == 1 then
            set choice = 1
        elseif previousChoice >= 1 and previousChoice <= count then
            set choice = GetRandomInt(1, count - 1)
            if choice >= previousChoice then
                set choice = choice + 1
            endif
        else
            set choice = GetRandomInt(1, count)
        endif
        set QG_LastHeroVoiceChoice.integer[key] = choice
        loop
            exitwhen index > QG_HeroVoiceVariantCount
            if QG_HeroVoiceVariantDefinitionId[index] == definitionId and QG_HeroVoiceVariantLineType[index] == lineType and QG_HeroVoiceVariantVoiceType[index] == voiceType then
                set found = found + 1
                if found == choice then
                    return index
                endif
            endif
            set index = index + 1
        endloop
        return 0
    endfunction

    private function QG_AddHeroVoiceVariantLine takes integer seq, unit hero, unit lookTarget, integer definitionId, integer lineType, integer fallbackLineType, string fallbackText, integer fallbackVoiceIndex returns nothing
        local string voiceType = ""
        local string selectedText = fallbackText
        local string soundKey = ""
        local integer count
        local integer selected = 0
        local integer matchDefinitionId = definitionId
        local integer matchLineType = lineType

        if hero == udg_Nazgrek then
            set voiceType = QG_NazgrekVoiceType
        elseif hero == udg_Zulkis then
            set voiceType = QG_ZulkisVoiceType
        endif
        if voiceType != "" then
            set count = QG_CountHeroVoiceVariants(matchDefinitionId, matchLineType, voiceType)
            if count <= 0 and fallbackLineType != matchLineType then
                set matchLineType = fallbackLineType
                set count = QG_CountHeroVoiceVariants(matchDefinitionId, matchLineType, voiceType)
            endif
            if count <= 0 and matchDefinitionId > 0 then
                set matchDefinitionId = 0
                set matchLineType = lineType
                set count = QG_CountHeroVoiceVariants(matchDefinitionId, matchLineType, voiceType)
            endif
            if count <= 0 and fallbackLineType != matchLineType then
                set matchLineType = fallbackLineType
                set count = QG_CountHeroVoiceVariants(matchDefinitionId, matchLineType, voiceType)
            endif
            if count > 0 then
                set selected = QG_PickHeroVoiceVariant(matchDefinitionId, matchLineType, voiceType, count)
                if selected > 0 then
                    set selectedText = QG_HeroVoiceVariantText[selected]
                    set soundKey = QG_FormatSoundKey(voiceType, QG_HeroVoiceVariantIndex[selected])
                endif
            elseif fallbackVoiceIndex > 0 then
                set soundKey = QG_FormatSoundKey(voiceType, fallbackVoiceIndex)
            endif
        endif
        if hero == udg_Nazgrek then
            call DialogInteraction_AddHeroLookAtLineForVoices(seq, hero, lookTarget, selectedText, soundKey, "")
        elseif hero == udg_Zulkis then
            call DialogInteraction_AddHeroLookAtLineForVoices(seq, hero, lookTarget, selectedText, "", soundKey)
        else
            call DialogInteraction_AddHeroLookAtLineForVoices(seq, hero, lookTarget, selectedText, "", "")
        endif
        set hero = null
        set lookTarget = null
    endfunction

    public function AddHeroVoiceVariantLine takes integer seq, unit hero, unit lookTarget, integer lineType, string fallbackText, integer fallbackVoiceIndex returns nothing
        call QG_AddHeroVoiceVariantLine(seq, hero, lookTarget, 0, lineType, lineType, fallbackText, fallbackVoiceIndex)
        set hero = null
        set lookTarget = null
    endfunction

    private function QG_AddDailyAcceptanceVariant takes integer seq, unit giver, string giverName, integer definitionId returns nothing
        local integer index = 1
        local integer count = 0
        local integer selected

        loop
            exitwhen index > QG_DailyVariantCount
            if QG_DailyVariantVoiceType[index] == QG_VoiceType[definitionId] and QG_DailyVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                set count = count + 1
            endif
            set index = index + 1
        endloop
        if count <= 0 then
            set giver = null
            return
        endif
        set selected = GetRandomInt(1, count)
        set index = 1
        set count = 0
        loop
            exitwhen index > QG_DailyVariantCount
            if QG_DailyVariantVoiceType[index] == QG_VoiceType[definitionId] and QG_DailyVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                set count = count + 1
                if count == selected then
                    call DialogSystem_AddLine(seq, giver, giverName, QG_DailyVariantText[index], QG_FormatSoundKey(QG_DailyVariantVoiceType[index], QG_DailyVariantVoiceIndex[index]), true)
                    set giver = null
                    return
                endif
            endif
            set index = index + 1
        endloop
        set giver = null
    endfunction

    private function QG_AddProgressVariant takes integer seq, unit giver, string giverName, integer definitionId, QuestData q returns nothing
        local integer index = 1
        local integer count = 0
        local integer selected
        local integer matchDefinitionId = definitionId

        loop
            exitwhen index > QG_ProgressVariantCount
            if QG_ProgressVariantDefinitionId[index] == matchDefinitionId and QG_ProgressVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                set count = count + 1
            endif
            set index = index + 1
        endloop
        if count <= 0 and matchDefinitionId > 0 then
            set matchDefinitionId = 0
            set index = 1
            loop
                exitwhen index > QG_ProgressVariantCount
                if QG_ProgressVariantDefinitionId[index] == 0 and QG_ProgressVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                    set count = count + 1
                endif
                set index = index + 1
            endloop
        endif
        if count <= 0 then
            call DialogSystem_AddLine(seq, giver, giverName, QG_GiverProgressPrefix + q.title + ". " + q.requirement1, "", true)
            set giver = null
            return
        endif

        set selected = GetRandomInt(1, count)
        set index = 1
        set count = 0
        loop
            exitwhen index > QG_ProgressVariantCount
            if QG_ProgressVariantDefinitionId[index] == matchDefinitionId and QG_ProgressVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                set count = count + 1
                if count == selected then
                    if matchDefinitionId > 0 then
                        call DialogSystem_AddLine(seq, giver, giverName, QG_ProgressVariantText[index], QG_ProgressVariantSoundKey[index], true)
                    else
                        call DialogSystem_AddLine(seq, giver, giverName, QG_ProgressVariantText[index] + " " + q.requirement1, QG_ProgressVariantSoundKey[index], true)
                    endif
                    set giver = null
                    return
                endif
            endif
            set index = index + 1
        endloop
        set giver = null
    endfunction

    private function QG_CreateActionSequence takes unit giver, string giverName, unit hero, integer definitionId, QuestData q, integer pendingAction returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string soundKey
        local string completeText
        local string completeVoiceType
        local integer completeVoiceIndex

        call DialogSystem_SetSequenceDefaultSpeaker(seq, giver, giverName)
        call DialogSystem_AddMakeFaceEachOther(seq, giver, hero, 0.45, 0.00)
        if pendingAction == QG_PENDING_ACCEPT then
            set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_VoiceIndex[definitionId])
            if QG_IntroText[definitionId] != "" or soundKey != "" then
                call DialogSystem_AddLine(seq, giver, giverName, QG_IntroText[definitionId], soundKey, true)
            endif
            call QG_AddHeroVoiceVariantLine(seq, hero, giver, definitionId, QG_GetAcceptHeroLineType(definitionId), HERO_LINE_ACCEPT, QG_HeroAcceptText, 1)
            if QG_QuestType[definitionId] == "daily" then
                call QG_AddDailyAcceptanceVariant(seq, giver, giverName, definitionId)
            elseif QG_AcceptExtraText[definitionId] != "" then
                set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_AcceptExtraVoiceIndex[definitionId])
                call DialogSystem_AddLine(seq, giver, giverName, QG_AcceptExtraText[definitionId], soundKey, true)
            endif
        elseif pendingAction == QG_PENDING_COMPLETE then
            if QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
                call QG_AddHeroVoiceVariantLine(seq, hero, giver, definitionId, HERO_LINE_COMPLETE_KILL, HERO_LINE_COMPLETE_KILL, QG_GetHeroCompleteText(definitionId), QG_GetHeroCompleteVoiceIndex(definitionId))
            elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK or QG_ObjectiveType[definitionId] == OBJECTIVE_FIND then
                call QG_AddHeroVoiceVariantLine(seq, hero, giver, definitionId, HERO_LINE_COMPLETE_TALK, HERO_LINE_COMPLETE_TALK, QG_GetHeroCompleteText(definitionId), QG_GetHeroCompleteVoiceIndex(definitionId))
            elseif QG_ObjectiveType[definitionId] == OBJECTIVE_ESCORT then
                call QG_AddHeroVoiceVariantLine(seq, hero, giver, definitionId, HERO_LINE_COMPLETE_ESCORT, HERO_LINE_COMPLETE_ESCORT, QG_GetHeroCompleteText(definitionId), QG_GetHeroCompleteVoiceIndex(definitionId))
            else
                call QG_AddHeroVoiceVariantLine(seq, hero, giver, definitionId, HERO_LINE_COMPLETE_FETCH, HERO_LINE_COMPLETE_FETCH, QG_GetHeroCompleteText(definitionId), QG_GetHeroCompleteVoiceIndex(definitionId))
            endif
            set completeText = QG_CompleteText[definitionId]
            set completeVoiceType = QG_VoiceType[definitionId]
            set completeVoiceIndex = QG_VoiceIndex[definitionId] + 1
            if q.receiver != q.giver then
                if QG_ReceiverCompleteText[definitionId] != "" then
                    set completeText = QG_ReceiverCompleteText[definitionId]
                endif
                set completeVoiceType = QG_ReceiverVoiceType[definitionId]
                set completeVoiceIndex = QG_ReceiverCompleteVoiceIndex[definitionId]
            endif
            set soundKey = QG_FormatSoundKey(completeVoiceType, completeVoiceIndex)
            if completeText != "" or soundKey != "" then
                call DialogSystem_AddLine(seq, giver, giverName, completeText, soundKey, true)
            endif
            if q.receiver == q.giver and QG_CompleteExtraText[definitionId] != "" then
                set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_CompleteExtraVoiceIndex[definitionId])
                call DialogSystem_AddLine(seq, giver, giverName, QG_CompleteExtraText[definitionId], soundKey, true)
            endif
        else
            call QG_AddHeroVoiceVariantLine(seq, hero, giver, definitionId, QG_GetProgressHeroLineType(definitionId), HERO_LINE_PROGRESS, QG_HeroProgressText, 17)
            call QG_AddProgressVariant(seq, giver, giverName, definitionId, q)
        endif
        set giver = null
        set hero = null
        return seq
    endfunction

    public function BeginAction takes integer actionId, unit giver, string giverName, unit hero returns integer
        local integer questId = actionId - QG_ACTION_BASE
        local integer definitionId = QG_DefinitionByQuest.integer[questId]
        local QuestData q = QuestMaster_GetById(questId)
        local integer pendingAction = 0
        local integer seq

        call QG_ClearPendingAction()
        if definitionId <= 0 or q == 0 or giver == null or hero == null then
            set giver = null
            set hero = null
            return 0
        endif
        if (q.state == QUEST_STATE_READY_TURNIN and q.receiver != giver) or (q.state != QUEST_STATE_READY_TURNIN and q.giver != giver) then
            set giver = null
            set hero = null
            return 0
        endif
        if giverName == null or giverName == "" then
            set giverName = GetUnitName(giver)
        endif

        if q.state == QUEST_STATE_AVAILABLE then
            set pendingAction = QG_PENDING_ACCEPT
        elseif q.state == QUEST_STATE_READY_TURNIN then
            if not QG_HasTurnInItems(definitionId) then
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8040You no longer have all required quest items.|r")
                set giver = null
                set hero = null
                return 0
            endif
            set pendingAction = QG_PENDING_COMPLETE
        elseif q.state != QUEST_STATE_IN_PROGRESS then
            set giver = null
            set hero = null
            return 0
        endif

        if pendingAction != 0 then
            set QG_PendingQuestId = questId
            set QG_PendingDefinitionId = definitionId
            set QG_PendingAction = pendingAction
            set QG_PendingGiver = giver
        endif
        set seq = QG_CreateActionSequence(giver, giverName, hero, definitionId, q, pendingAction)
        set giver = null
        set hero = null
        return seq
    endfunction

    public function FinishPendingAction takes nothing returns nothing
        local QuestData q = QuestMaster_GetById(QG_PendingQuestId)

        if q != 0 then
            if QG_PendingAction == QG_PENDING_ACCEPT and q.giver == QG_PendingGiver and q.state == QUEST_STATE_AVAILABLE then
                call QuestGiver_AcceptQuest(QG_PendingQuestId)
            elseif QG_PendingAction == QG_PENDING_COMPLETE and q.receiver == QG_PendingGiver and q.state == QUEST_STATE_READY_TURNIN and QG_HasTurnInItems(QG_PendingDefinitionId) then
                call QG_RemoveTurnInItems(QG_PendingDefinitionId)
                call QuestGiver_CompleteQuest(QG_PendingQuestId)
            endif
        endif
        call QG_ClearPendingAction()
    endfunction

    private function Init takes nothing returns nothing
        set QG_DefinitionByQuest = Table.create()
        set QG_TargetTypeByQuest = Table.create()
        set QG_InstantiatedByUnit = Table.create()
        set QG_LastHeroVoiceChoice = Table.create()
        set QG_RegisteredUnitByType = Table.create()
        set QG_RegisteredUnitHandle = Table.create()
        set QG_RegisteredUnitName = Table.create()
    endfunction
endlibrary
