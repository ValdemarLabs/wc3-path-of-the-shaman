/**
    QuestsGeneric

    Author: Valdemar
    Version: 1.1.0

    Description:
    Reusable kill, fetch, talk, and purchase quest templates built on
    QuestGiver and QuestMaster. Any NPC integration can instantiate templates,
    add contextual dialog buttons, and run interrupt-safe quest sequences.

    Credits:

    How to install:
    Import after QuestGiver, QuestMaster, DialogSystem, DialogInteraction,
    HeroItemCheck, and Table. Import VoicelinesQuests afterward to configure
    shared dialogue and daily acceptance variants.

    API:
    - QuestsGeneric_RegisterFetchQuest(...) registers an item template.
    - QuestsGeneric_RegisterKillQuest(...) registers a kill template.
    - QuestsGeneric_RegisterTalkQuest(...) registers a manual talk template.
    - QuestsGeneric_SetObjective(...) changes an uninstantiated definition.
    - QuestsGeneric_SetFactionReward(...) configures reputation rewards.
    - QuestsGeneric_SetExtendedDialogue(...) adds authored normal-quest lines.
    - QuestsGeneric_ConfigureSharedDialogue(...) sets shared text and hero voices.
    - QuestsGeneric_RegisterDailyAcceptanceVariant(...) adds a random line.
    - QuestsGeneric_RegisterProgressVariant(...) adds shared incomplete dialogue.
    - QuestsGeneric_HasDefinitionForUnitType(...) checks template ownership.
    - QuestsGeneric_RegisterUnit(giver, displayName) instantiates templates.
    - QuestsGeneric_AddDialogButtons(...) adds managed quest choices.
    - QuestsGeneric_BeginAction/FinishPendingAction/CancelPendingAction manage
      interrupt-safe accept, progress, and completion dialogue.

**/
library QuestsGeneric initializer Init requires QuestGiver, QuestMaster, DialogSystem, DialogInteraction, HeroItemCheck, Table
    globals
        public constant integer OBJECTIVE_FETCH = 1
        public constant integer OBJECTIVE_KILL = 2
        public constant integer OBJECTIVE_TALK = 3
        public constant integer OBJECTIVE_PURCHASE = 4

        private constant integer QG_MAX_DEFINITIONS = 128
        private constant integer QG_MAX_QUESTS = 512
        private constant integer QG_MAX_DAILY_VARIANTS = 96
        private constant integer QG_MAX_PROGRESS_VARIANTS = 16
        private constant integer QG_ACTION_BASE = 10000
        private constant integer QG_PENDING_ACCEPT = 1
        private constant integer QG_PENDING_COMPLETE = 2

        private integer QG_DefinitionCount = 0
        private integer array QG_GiverUnitType
        private string array QG_QuestName
        private string array QG_QuestType
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

        private integer QG_QuestCount = 0
        private integer array QG_QuestIds
        private Table QG_DefinitionByQuest = 0
        private Table QG_InstantiatedByUnit = 0

        private integer QG_DailyVariantCount = 0
        private string array QG_DailyVariantVoiceType
        private integer array QG_DailyVariantObjectiveType
        private string array QG_DailyVariantText
        private integer array QG_DailyVariantVoiceIndex

        private integer QG_ProgressVariantCount = 0
        private integer array QG_ProgressVariantObjectiveType
        private string array QG_ProgressVariantText
        private string array QG_ProgressVariantSoundKey

        private string QG_HeroAcceptText = ""
        private string QG_HeroCompleteKillText = ""
        private string QG_HeroCompleteFetchText = ""
        private string QG_HeroCompleteTalkText = ""
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

    public function ConfigureSharedDialogue takes string heroAccept, string heroCompleteKill, string heroCompleteFetch, string heroCompleteTalk, string heroProgress, string giverProgressPrefix, string nazgrekVoiceType, string zulkisVoiceType returns nothing
        set QG_HeroAcceptText = heroAccept
        set QG_HeroCompleteKillText = heroCompleteKill
        set QG_HeroCompleteFetchText = heroCompleteFetch
        set QG_HeroCompleteTalkText = heroCompleteTalk
        set QG_HeroProgressText = heroProgress
        set QG_GiverProgressPrefix = giverProgressPrefix
        set QG_NazgrekVoiceType = nazgrekVoiceType
        set QG_ZulkisVoiceType = zulkisVoiceType
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
        set QG_QuestLevel[definitionId] = questLevel
        set QG_Title[definitionId] = title
        set QG_IconPath[definitionId] = iconPath
        set QG_Description[definitionId] = description
        set QG_ObjectiveType[definitionId] = objectiveType
        set QG_TargetType[definitionId] = targetType
        set QG_TargetAmount[definitionId] = targetAmount
        set QG_TargetName[definitionId] = targetName
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

    public function RegisterTalkQuest takes integer giverUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, string targetName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QG_RegisterDefinition(giverUnitTypeId, questName, questType, questLevel, title, iconPath, description, OBJECTIVE_TALK, 0, 1, targetName, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function SetObjective takes integer definitionId, integer objectiveType, integer targetType, integer targetAmount, string targetName returns nothing
        if definitionId <= 0 or definitionId > QG_DefinitionCount then
            return
        endif
        if objectiveType < OBJECTIVE_FETCH or objectiveType > OBJECTIVE_PURCHASE then
            return
        endif
        if targetAmount < 1 then
            set targetAmount = 1
        endif
        set QG_ObjectiveType[definitionId] = objectiveType
        set QG_TargetType[definitionId] = targetType
        set QG_TargetAmount[definitionId] = targetAmount
        set QG_TargetName[definitionId] = targetName
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

    public function RegisterProgressVariant takes integer objectiveType, string text, string soundKey returns nothing
        if objectiveType < OBJECTIVE_FETCH or objectiveType > OBJECTIVE_PURCHASE or text == null or text == "" or QG_ProgressVariantCount >= QG_MAX_PROGRESS_VARIANTS then
            return
        endif
        set QG_ProgressVariantCount = QG_ProgressVariantCount + 1
        set QG_ProgressVariantObjectiveType[QG_ProgressVariantCount] = objectiveType
        set QG_ProgressVariantText[QG_ProgressVariantCount] = text
        if soundKey == null then
            set soundKey = ""
        endif
        set QG_ProgressVariantSoundKey[QG_ProgressVariantCount] = soundKey
    endfunction

    private function QG_GetInfoText takes string questType returns string
        if questType == "daily" then
            return "|cff80a0ffDaily quest|r\n\n"
        elseif questType == "repeatable" then
            return "|cff80a0ffRepeatable quest|r\n\n"
        endif
        return "|cffffcc00Quest|r\n\n"
    endfunction

    private function QG_CreateQuest takes integer definitionId, unit giver, string giverName returns nothing
        local QuestData q
        local string info2Text
        local string factionName

        if definitionId <= 0 or definitionId > QG_DefinitionCount or giver == null or QG_QuestCount >= QG_MAX_QUESTS then
            set giver = null
            return
        endif
        if giverName == null or giverName == "" then
            set giverName = GetUnitName(giver)
        endif

        set factionName = QG_FactionName[definitionId]
        if factionName == null or factionName == "" then
            set factionName = Reputation_GetUnitFactionName(giver)
        endif
        set info2Text = "|cffffcc00Recommended level:|r " + I2S(QG_QuestLevel[definitionId]) + "\n\n"
        set q = QuestGiver_CreateConfiguredQuest(QG_QuestName[definitionId], giver, QG_QuestType[definitionId], QG_QuestLevel[definitionId], null, QG_Title[definitionId], QG_IconPath[definitionId], QG_Description[definitionId] + "\n\n", QG_GetInfoText(QG_QuestType[definitionId]), info2Text, QG_QuestLevel[definitionId], true, true, true, factionName, giverName)
        if factionName != null and factionName != "" then
            call QuestGiver_SetQuestRequiredReputation(q, Reputation_REP_NEUTRAL)
        endif
        call QuestGiver_SetQuestRewards(q, true, 0, true, QG_GoldBonus[definitionId], false, 0, QG_ReputationBonus[definitionId] != 0, QG_ReputationBonus[definitionId], QG_ReputationLinked[definitionId])

        if QG_ObjectiveType[definitionId] == OBJECTIVE_FETCH or QG_ObjectiveType[definitionId] == OBJECTIVE_PURCHASE then
            call QuestGiver_RegisterItemRequirement(q.id, giver, 1, QG_TargetType[definitionId], QG_TargetAmount[definitionId])
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
            call QuestGiver_RegisterUnitKillRequirement(q.id, giver, 1, QG_TargetType[definitionId], QG_TargetAmount[definitionId])
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK then
            call QuestGiver_RegisterTalkToRequirement(q.id, giver, 1, null, QG_TargetName[definitionId])
        endif

        set QG_QuestCount = QG_QuestCount + 1
        set QG_QuestIds[QG_QuestCount] = q.id
        set QG_DefinitionByQuest.integer[q.id] = definitionId
        call QuestMaster_RefreshAvailabilityForGiver(giver)
        set giver = null
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

    public function RegisterUnit takes unit giver, string giverName returns nothing
        local integer definitionId = 1
        local integer handleId
        local Table instantiated

        if giver == null or GetUnitTypeId(giver) == 0 then
            set giver = null
            return
        endif
        set handleId = GetHandleId(giver)
        set instantiated = QG_InstantiatedByUnit.link(handleId)
        loop
            exitwhen definitionId > QG_DefinitionCount
            if QG_GiverUnitType[definitionId] == GetUnitTypeId(giver) and not instantiated.boolean[definitionId] then
                set instantiated.boolean[definitionId] = true
                call QG_CreateQuest(definitionId, giver, giverName)
            endif
            set definitionId = definitionId + 1
        endloop
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

    public function GetTargetAmount takes integer definitionId returns integer
        return QG_TargetAmount[definitionId]
    endfunction

    public function AddDialogButtons takes dialog d, unit giver, code actionFunc returns integer
        local integer count
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
        set count = QuestMaster_GetGiverQuestCount(giver)
        loop
            exitwhen index > count
            set questId = QuestMaster_GetGiverQuestIdByIndex(giver, index)
            if QG_DefinitionByQuest.integer.has(questId) then
                set q = QuestMaster_GetById(questId)
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

    private function QG_HasTurnInItems takes integer definitionId returns boolean
        if QG_ObjectiveType[definitionId] == OBJECTIVE_FETCH or QG_ObjectiveType[definitionId] == OBJECTIVE_PURCHASE or (QG_ObjectiveType[definitionId] == OBJECTIVE_TALK and QG_TargetType[definitionId] != 0) then
            return HeroItemCheckBoth(QG_TargetType[definitionId], QG_TargetAmount[definitionId])
        endif
        return true
    endfunction

    private function QG_RemoveTurnInItems takes integer definitionId returns nothing
        if QG_ObjectiveType[definitionId] == OBJECTIVE_FETCH or QG_ObjectiveType[definitionId] == OBJECTIVE_PURCHASE or (QG_ObjectiveType[definitionId] == OBJECTIVE_TALK and QG_TargetType[definitionId] != 0) then
            call HeroItemCheckBothAndRemove(QG_TargetType[definitionId], QG_TargetAmount[definitionId])
        endif
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
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK then
            return QG_HeroCompleteTalkText
        endif
        return QG_HeroCompleteFetchText
    endfunction

    private function QG_GetHeroCompleteVoiceIndex takes integer definitionId returns integer
        if QG_ObjectiveType[definitionId] == OBJECTIVE_KILL then
            return 2
        elseif QG_ObjectiveType[definitionId] == OBJECTIVE_TALK then
            return 3
        endif
        return 4
    endfunction

    private function QG_AddHeroLookAtLine takes integer seq, unit hero, unit lookTarget, string text, integer voiceIndex returns nothing
        call DialogInteraction_AddHeroLookAtLineForVoices(seq, hero, lookTarget, text, QG_FormatSoundKey(QG_NazgrekVoiceType, voiceIndex), QG_FormatSoundKey(QG_ZulkisVoiceType, voiceIndex))
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

        loop
            exitwhen index > QG_ProgressVariantCount
            if QG_ProgressVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                set count = count + 1
            endif
            set index = index + 1
        endloop
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
            if QG_ProgressVariantObjectiveType[index] == QG_ObjectiveType[definitionId] then
                set count = count + 1
                if count == selected then
                    call DialogSystem_AddLine(seq, giver, giverName, QG_ProgressVariantText[index] + " " + q.requirement1, QG_ProgressVariantSoundKey[index], true)
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

        call DialogSystem_SetSequenceDefaultSpeaker(seq, giver, giverName)
        call DialogSystem_AddMakeFaceEachOther(seq, giver, hero, 0.45, 0.00)
        if pendingAction == QG_PENDING_ACCEPT then
            set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_VoiceIndex[definitionId])
            call DialogSystem_AddLine(seq, giver, giverName, QG_IntroText[definitionId], soundKey, true)
            call QG_AddHeroLookAtLine(seq, hero, giver, QG_HeroAcceptText, 1)
            if QG_QuestType[definitionId] == "daily" then
                call QG_AddDailyAcceptanceVariant(seq, giver, giverName, definitionId)
            elseif QG_AcceptExtraText[definitionId] != "" then
                set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_AcceptExtraVoiceIndex[definitionId])
                call DialogSystem_AddLine(seq, giver, giverName, QG_AcceptExtraText[definitionId], soundKey, true)
            endif
        elseif pendingAction == QG_PENDING_COMPLETE then
            call QG_AddHeroLookAtLine(seq, hero, giver, QG_GetHeroCompleteText(definitionId), QG_GetHeroCompleteVoiceIndex(definitionId))
            set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_VoiceIndex[definitionId] + 1)
            call DialogSystem_AddLine(seq, giver, giverName, QG_CompleteText[definitionId], soundKey, true)
            if QG_CompleteExtraText[definitionId] != "" then
                set soundKey = QG_FormatSoundKey(QG_VoiceType[definitionId], QG_CompleteExtraVoiceIndex[definitionId])
                call DialogSystem_AddLine(seq, giver, giverName, QG_CompleteExtraText[definitionId], soundKey, true)
            endif
        else
            call QG_AddHeroLookAtLine(seq, hero, giver, QG_HeroProgressText, 5)
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
        if definitionId <= 0 or q == 0 or giver == null or hero == null or q.giver != giver then
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
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8040You no longer have the required " + GetObjectName(QG_TargetType[definitionId]) + ".|r")
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

        if q != 0 and q.giver == QG_PendingGiver then
            if QG_PendingAction == QG_PENDING_ACCEPT and q.state == QUEST_STATE_AVAILABLE then
                call QuestGiver_AcceptQuest(QG_PendingQuestId)
            elseif QG_PendingAction == QG_PENDING_COMPLETE and q.state == QUEST_STATE_READY_TURNIN and QG_HasTurnInItems(QG_PendingDefinitionId) then
                call QG_RemoveTurnInItems(QG_PendingDefinitionId)
                call QuestGiver_CompleteQuest(QG_PendingQuestId)
            endif
        endif
        call QG_ClearPendingAction()
    endfunction

    private function Init takes nothing returns nothing
        set QG_DefinitionByQuest = Table.create()
        set QG_InstantiatedByUnit = Table.create()
    endfunction
endlibrary
