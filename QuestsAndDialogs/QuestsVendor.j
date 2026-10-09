/**
    QuestsVendor

    Author: Valdemar
    Version: 1.8.0

    Description:
    Shop-vendor adapter for QuestsGeneric. Generic giver quests are delegated
    to the shared template engine; this library independently instantiates
    placed vendor quest givers and owns cross-vendor handoff and purchase
    interactions, one-time escorts for vendors or generic NPCs, trade-unlock
    gates, and vendor display-name integration. Escort NPCs walk autonomously
    to a unit, point, rect, or zone and wait whenever their leader falls behind.

    Credits:

    How to install:
    Import after QuestsGeneric, VoicelinesQuests, Shop,
    EscortMovement, UnitSpawn, ZonesCore, Companions, AI, and Table. VendorDialogs
    may require this library and register discovered vendors.

    API:
    - QuestsVendor_RegisterFetchQuest/RegisterKillQuest register generic quests.
    - QuestsVendor_RegisterSupplyQuest registers a target-vendor objective.
    - QuestsVendor_RegisterEscortQuest registers a one-time Normal escort.
    - QuestsVendor_SetSupplyRequiresPurchase overrides stock detection.
    - QuestsVendor_SetEscortTradeLocked gates Trade until escort completion.
    - QuestsVendor_SetEscortTravelDialogue adds route and companion chatter.
    - QuestsVendor_SetEscortRoundTrip adds a return leg to the start point.
    - QuestsVendor_SetEscortDestinationUnit/UnitType/Point/Rect/Zone selects it.
    - QuestsVendor_SetEscortLeaderRange configures the wait-for-hero leash.
    - QuestsVendor_AddEscortWaypoint/Rect adds optional ordered route points.
    - QuestsVendor_RegisterEscortAmbush adds a route-progress enemy attack.
    - QuestsVendor_RegisterEscortAmbushes adds one to five fixed/random attacks.
    - QuestsVendor_RegisterEscortProgressVariant adds giver progress dialogue.
    - QuestsVendor_RegisterEscortHeroProgressVariant adds hero replies.
    - QuestsVendor_SetFactionReward/SetExtendedDialogue configure definitions.
    - QuestsVendor_RegisterUnit registers matching givers and destination NPCs.
    - QuestsVendor_RegisterExistingQuestGivers scans placed givers and targets.
    - QuestsVendor_AddDialogButtons adds giver and target-vendor choices.
    - QuestsVendor_BeginAction/FinishPendingAction/CancelPendingAction manage
      vendor quest dialogue and target-vendor side effects.
    - QuestsVendor_IsTradeUnlocked/GetTradeLockText expose escort trade gates.

**/
library QuestsVendor initializer Init requires QuestsGeneric, VoicelinesQuests, QuestGiver, QuestMaster, DialogSystem, DialogInteraction, HeroItemCheck, Shop, EscortMovement, UnitSpawn, ZonesCore, Companions, AI, Table
    globals
        private constant integer QV_MAX_SUPPLY_DEFINITIONS = 32
        private constant integer QV_MAX_ESCORT_DEFINITIONS = 16
        private constant integer QV_MAX_ESCORT_WAYPOINTS = 8
        private constant integer QV_MAX_ESCORT_AMBUSHES = 32
        private constant integer QV_AMBUSH_STATE_KEY_STRIDE = 64
        private constant integer QV_AMBUSH_WAVE_KEY_STRIDE = 512
        private constant integer QV_AMBUSH_OCCURRENCE_STRIDE = 8
        private constant integer QV_MAX_AMBUSH_OCCURRENCES = 5
        private constant integer QV_TARGET_ACTION_BASE = 20000
        private constant integer QV_PENDING_HANDOFF = 1
        private constant real QV_ESCORT_DESTINATION_RADIUS = 425.00
        private constant real QV_ESCORT_DEFAULT_LEADER_RANGE = 2400.00
        private constant real QV_ESCORT_DEFAULT_WAYPOINT_RADIUS = 160.00
        private constant real QV_ESCORT_AREA_ARRIVAL_RADIUS = 96.00
        private constant real QV_ESCORT_CHECK_INTERVAL = 0.50

        public constant integer ESCORT_LEG_OUTBOUND = 1
        public constant integer ESCORT_LEG_RETURN = 2
        public constant integer ESCORT_DESTINATION_UNIT = 1
        public constant integer ESCORT_DESTINATION_POINT = 2
        public constant integer ESCORT_DESTINATION_RECT = 3
        public constant integer ESCORT_DESTINATION_ZONE = 4

        private integer QV_SupplyCount = 0
        private integer array QV_SupplyDefinitionId
        private integer array QV_TargetVendorUnitType
        private string array QV_TargetVendorName
        private unit array QV_TargetVendor
        private integer array QV_SupplyItemType
        private boolean array QV_RequiresPurchase
        private boolean array QV_ModeConfigured
        private Table QV_SupplyIndexByDefinition = 0
        private Table QV_SupplyClaimed = 0

        private integer QV_EscortCount = 0
        private integer array QV_EscortDefinitionId
        private integer array QV_EscortDestinationType
        private integer array QV_EscortDestinationUnitType
        private string array QV_EscortDestinationName
        private string array QV_EscortVoiceType
        private unit array QV_EscortDestination
        private real array QV_EscortDestinationX
        private real array QV_EscortDestinationY
        private real array QV_EscortDestinationRadius
        private rect array QV_EscortConfiguredRect
        private integer array QV_EscortDestinationZoneId
        private boolean array QV_EscortExactDestination
        private boolean array QV_EscortTradeLocked
        private string array QV_EscortTravelText
        private integer array QV_EscortTravelVoiceIndex
        private string array QV_EscortCompanionReply
        private boolean array QV_EscortRoundTrip
        private string array QV_EscortReturnName
        private string array QV_EscortReturnText
        private integer array QV_EscortReturnVoiceIndex
        private real array QV_EscortLeaderRange
        private integer array QV_EscortWaypointCount
        private real array QV_EscortWaypointX
        private real array QV_EscortWaypointY
        private real array QV_EscortWaypointRadius
        private Table QV_EscortIndexByDefinition = 0
        private Table QV_EscortLeader = 0
        private Table QV_EscortWasInvulnerable = 0
        private Table QV_EscortOriginStored = 0
        private Table QV_EscortOriginX = 0
        private Table QV_EscortOriginY = 0
        private Table QV_EscortOriginFacing = 0
        private Table QV_EscortLeg = 0
        private Table QV_EscortLegDistance = 0

        private integer QV_AmbushCount = 0
        private integer array QV_AmbushDefinitionId
        private integer array QV_AmbushLeg
        private real array QV_AmbushProgress
        private integer array QV_AmbushEnemyUnitType
        private integer array QV_AmbushEnemyCount
        private real array QV_AmbushSpawnDistance
        private string array QV_AmbushAlertText
        private integer array QV_AmbushAlertVoiceIndex
        private integer array QV_AmbushMinOccurrences
        private integer array QV_AmbushMaxOccurrences
        private Table QV_AmbushOccurrenceTarget = 0
        private Table QV_AmbushOccurrenceCount = 0
        private Table QV_AmbushWave = 0
        private unit QV_AmbushOrderTarget = null

        private integer QV_PendingQuestId = 0
        private integer QV_PendingSupplyIndex = 0
        private integer QV_PendingAction = 0
        private unit QV_PendingVendor = null
        private unit QV_PendingHero = null
        private boolean QV_PendingOpenTrade = false
        private boolean QV_OpenTradeRequest = false
        private integer QV_PendingEscortQuestId = 0
        private integer QV_PendingEscortIndex = 0
        private unit QV_PendingEscortVendor = null
        private unit QV_PendingEscortHero = null
    endglobals

    public function RegisterFetchQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer itemTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QuestsGeneric_RegisterFetchQuest(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, itemTypeId, amount, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterKillQuest takes integer vendorUnitTypeId, string questName, string questType, integer questLevel, string title, string iconPath, string description, integer unitTypeId, integer amount, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        return QuestsGeneric_RegisterKillQuest(vendorUnitTypeId, questName, questType, questLevel, title, iconPath, description, unitTypeId, amount, goldBonus, voiceType, voiceIndex, introText, completeText)
    endfunction

    public function RegisterEscortQuest takes integer giverUnitTypeId, string questName, integer questLevel, string title, string iconPath, string description, integer destinationUnitTypeId, string destinationName, integer goldBonus, string voiceType, integer voiceIndex, string introText, string completeText returns integer
        local integer definitionId

        if QV_EscortCount >= QV_MAX_ESCORT_DEFINITIONS then
            return 0
        endif
        set definitionId = QuestsGeneric_RegisterEscortQuest(giverUnitTypeId, questName, "normal", questLevel, title, iconPath, description, destinationName, goldBonus, voiceType, voiceIndex, introText, completeText)
        if definitionId <= 0 then
            return 0
        endif
        set QV_EscortCount = QV_EscortCount + 1
        set QV_EscortDefinitionId[QV_EscortCount] = definitionId
        set QV_EscortDestinationType[QV_EscortCount] = ESCORT_DESTINATION_UNIT
        set QV_EscortDestinationUnitType[QV_EscortCount] = destinationUnitTypeId
        set QV_EscortDestinationName[QV_EscortCount] = destinationName
        set QV_EscortDestinationRadius[QV_EscortCount] = QV_ESCORT_DESTINATION_RADIUS
        set QV_EscortLeaderRange[QV_EscortCount] = QV_ESCORT_DEFAULT_LEADER_RANGE
        set QV_EscortVoiceType[QV_EscortCount] = voiceType
        set QV_EscortIndexByDefinition.integer[definitionId] = QV_EscortCount
        return definitionId
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

    public function SetEscortTradeLocked takes integer definitionId, boolean locked returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex > 0 then
            set QV_EscortTradeLocked[escortIndex] = locked
        endif
    endfunction

    private function QV_GetEscortWaypointSlot takes integer escortIndex, integer waypointIndex returns integer
        return escortIndex*QV_MAX_ESCORT_WAYPOINTS + waypointIndex
    endfunction

    public function SetEscortLeaderRange takes integer definitionId, real leaderRange returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 then
            return
        endif
        if leaderRange <= 0.00 then
            set leaderRange = QV_ESCORT_DEFAULT_LEADER_RANGE
        endif
        set QV_EscortLeaderRange[escortIndex] = leaderRange
    endfunction

    public function AddEscortWaypoint takes integer definitionId, real x, real y, real radius returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
        local integer waypointIndex

        if escortIndex <= 0 or QV_EscortWaypointCount[escortIndex] >= QV_MAX_ESCORT_WAYPOINTS then
            return
        endif
        if radius <= 0.00 then
            set radius = QV_ESCORT_DEFAULT_WAYPOINT_RADIUS
        endif
        set waypointIndex = QV_EscortWaypointCount[escortIndex] + 1
        set QV_EscortWaypointCount[escortIndex] = waypointIndex
        set QV_EscortWaypointX[QV_GetEscortWaypointSlot(escortIndex, waypointIndex)] = x
        set QV_EscortWaypointY[QV_GetEscortWaypointSlot(escortIndex, waypointIndex)] = y
        set QV_EscortWaypointRadius[QV_GetEscortWaypointSlot(escortIndex, waypointIndex)] = radius
    endfunction

    public function AddEscortWaypointRect takes integer definitionId, rect waypointRect, real radius returns nothing
        if waypointRect == null then
            set waypointRect = null
            return
        endif
        call AddEscortWaypoint(definitionId, (GetRectMinX(waypointRect) + GetRectMaxX(waypointRect))*0.50, (GetRectMinY(waypointRect) + GetRectMaxY(waypointRect))*0.50, radius)
        set waypointRect = null
    endfunction

    public function SetEscortTravelDialogue takes integer definitionId, string vendorText, integer vendorVoiceIndex, string companionReply returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 then
            return
        endif
        set QV_EscortTravelText[escortIndex] = vendorText
        set QV_EscortTravelVoiceIndex[escortIndex] = vendorVoiceIndex
        set QV_EscortCompanionReply[escortIndex] = companionReply
    endfunction

    public function SetEscortRoundTrip takes integer definitionId, string returnName, string returnText, integer returnVoiceIndex returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 then
            return
        endif
        set QV_EscortRoundTrip[escortIndex] = true
        set QV_EscortReturnName[escortIndex] = returnName
        set QV_EscortReturnText[escortIndex] = returnText
        set QV_EscortReturnVoiceIndex[escortIndex] = returnVoiceIndex
    endfunction

    public function SetEscortDestinationUnitType takes integer definitionId, integer destinationUnitTypeId, real radius returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 or destinationUnitTypeId == 0 then
            return
        endif
        if radius <= 0.00 then
            set radius = QV_ESCORT_DESTINATION_RADIUS
        endif
        set QV_EscortDestinationType[escortIndex] = ESCORT_DESTINATION_UNIT
        set QV_EscortDestinationUnitType[escortIndex] = destinationUnitTypeId
        set QV_EscortDestinationRadius[escortIndex] = radius
        set QV_EscortDestination[escortIndex] = null
        set QV_EscortConfiguredRect[escortIndex] = null
        set QV_EscortDestinationZoneId[escortIndex] = 0
        set QV_EscortExactDestination[escortIndex] = false
    endfunction

    public function SetEscortDestinationUnit takes integer definitionId, unit destination, real radius returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 or destination == null then
            set destination = null
            return
        endif
        if radius <= 0.00 then
            set radius = QV_ESCORT_DESTINATION_RADIUS
        endif
        set QV_EscortDestinationType[escortIndex] = ESCORT_DESTINATION_UNIT
        set QV_EscortDestinationUnitType[escortIndex] = GetUnitTypeId(destination)
        set QV_EscortDestinationRadius[escortIndex] = radius
        set QV_EscortDestination[escortIndex] = destination
        set QV_EscortConfiguredRect[escortIndex] = null
        set QV_EscortDestinationZoneId[escortIndex] = 0
        set QV_EscortExactDestination[escortIndex] = true
        set destination = null
    endfunction

    public function SetEscortDestinationPoint takes integer definitionId, real x, real y, real radius returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 then
            return
        endif
        if radius <= 0.00 then
            set radius = QV_ESCORT_DESTINATION_RADIUS
        endif
        set QV_EscortDestinationType[escortIndex] = ESCORT_DESTINATION_POINT
        set QV_EscortDestinationUnitType[escortIndex] = 0
        set QV_EscortDestination[escortIndex] = null
        set QV_EscortDestinationX[escortIndex] = x
        set QV_EscortDestinationY[escortIndex] = y
        set QV_EscortDestinationRadius[escortIndex] = radius
        set QV_EscortConfiguredRect[escortIndex] = null
        set QV_EscortDestinationZoneId[escortIndex] = 0
        set QV_EscortExactDestination[escortIndex] = false
    endfunction

    public function SetEscortDestinationRect takes integer definitionId, rect destination returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 or destination == null then
            set destination = null
            return
        endif
        set QV_EscortDestinationType[escortIndex] = ESCORT_DESTINATION_RECT
        set QV_EscortDestinationUnitType[escortIndex] = 0
        set QV_EscortDestination[escortIndex] = null
        set QV_EscortConfiguredRect[escortIndex] = destination
        set QV_EscortDestinationZoneId[escortIndex] = 0
        set QV_EscortExactDestination[escortIndex] = false
        set destination = null
    endfunction

    public function SetEscortDestinationZone takes integer definitionId, integer zoneId returns nothing
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]

        if escortIndex <= 0 or zoneId <= 0 then
            return
        endif
        set QV_EscortDestinationType[escortIndex] = ESCORT_DESTINATION_ZONE
        set QV_EscortDestinationUnitType[escortIndex] = 0
        set QV_EscortDestination[escortIndex] = null
        set QV_EscortConfiguredRect[escortIndex] = null
        set QV_EscortDestinationZoneId[escortIndex] = zoneId
        set QV_EscortExactDestination[escortIndex] = false
    endfunction

    private function QV_RegisterEscortAmbush takes integer definitionId, integer leg, real progress, integer minOccurrences, integer maxOccurrences, integer enemyUnitTypeId, integer enemyCount, real spawnDistance, string alertText, integer alertVoiceIndex returns nothing
        if QV_EscortIndexByDefinition.integer[definitionId] <= 0 or QV_AmbushCount >= QV_MAX_ESCORT_AMBUSHES or enemyUnitTypeId == 0 or enemyCount <= 0 then
            return
        endif
        if leg != ESCORT_LEG_RETURN then
            set leg = ESCORT_LEG_OUTBOUND
        endif
        if leg == ESCORT_LEG_RETURN and not QV_EscortRoundTrip[QV_EscortIndexByDefinition.integer[definitionId]] then
            return
        endif
        if progress < 0.10 then
            set progress = 0.10
        elseif progress > 0.90 then
            set progress = 0.90
        endif
        if spawnDistance < 250.00 then
            set spawnDistance = 250.00
        endif
        if minOccurrences < 1 then
            set minOccurrences = 1
        elseif minOccurrences > QV_MAX_AMBUSH_OCCURRENCES then
            set minOccurrences = QV_MAX_AMBUSH_OCCURRENCES
        endif
        if maxOccurrences < minOccurrences then
            set maxOccurrences = minOccurrences
        elseif maxOccurrences > QV_MAX_AMBUSH_OCCURRENCES then
            set maxOccurrences = QV_MAX_AMBUSH_OCCURRENCES
        endif
        set QV_AmbushCount = QV_AmbushCount + 1
        set QV_AmbushDefinitionId[QV_AmbushCount] = definitionId
        set QV_AmbushLeg[QV_AmbushCount] = leg
        set QV_AmbushProgress[QV_AmbushCount] = progress
        set QV_AmbushEnemyUnitType[QV_AmbushCount] = enemyUnitTypeId
        set QV_AmbushEnemyCount[QV_AmbushCount] = enemyCount
        set QV_AmbushSpawnDistance[QV_AmbushCount] = spawnDistance
        set QV_AmbushAlertText[QV_AmbushCount] = alertText
        set QV_AmbushAlertVoiceIndex[QV_AmbushCount] = alertVoiceIndex
        set QV_AmbushMinOccurrences[QV_AmbushCount] = minOccurrences
        set QV_AmbushMaxOccurrences[QV_AmbushCount] = maxOccurrences
    endfunction

    public function RegisterEscortAmbush takes integer definitionId, integer leg, real progress, integer enemyUnitTypeId, integer enemyCount, real spawnDistance, string alertText, integer alertVoiceIndex returns nothing
        call QV_RegisterEscortAmbush(definitionId, leg, progress, 1, 1, enemyUnitTypeId, enemyCount, spawnDistance, alertText, alertVoiceIndex)
    endfunction

    public function RegisterEscortAmbushes takes integer definitionId, integer leg, real progress, integer minOccurrences, integer maxOccurrences, integer enemyUnitTypeId, integer enemyCount, real spawnDistance, string alertText, integer alertVoiceIndex returns nothing
        call QV_RegisterEscortAmbush(definitionId, leg, progress, minOccurrences, maxOccurrences, enemyUnitTypeId, enemyCount, spawnDistance, alertText, alertVoiceIndex)
    endfunction

    public function RegisterEscortProgressVariant takes integer definitionId, string text, integer voiceIndex returns nothing
        if QV_EscortIndexByDefinition.integer[definitionId] > 0 then
            call QuestsGeneric_RegisterDefinitionProgressVariant(definitionId, text, voiceIndex)
        endif
    endfunction

    public function RegisterEscortHeroProgressVariant takes integer definitionId, string heroVoiceType, string text, integer voiceIndex returns nothing
        if QV_EscortIndexByDefinition.integer[definitionId] > 0 then
            call QuestsGeneric_RegisterDefinitionHeroVoiceVariant(definitionId, QuestsGeneric_HERO_LINE_PROGRESS, heroVoiceType, text, voiceIndex)
        endif
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

    private function QV_GetSpeakerName takes unit giver returns string
        local string speakerName

        if giver == null then
            set giver = null
            return "Quest giver"
        endif
        set speakerName = Shop_GetVendorUnitDisplayName(giver)
        if speakerName == null or speakerName == "" then
            set speakerName = GetUnitName(giver)
        endif
        set giver = null
        return speakerName
    endfunction

    private function QV_FindEscortCompanion takes unit hero, unit vendor returns unit
        local integer index = 1
        local integer count = Companions_GetControlledDisplayCount()
        local integer seen = 0
        local unit candidate
        local unit selected = null

        loop
            exitwhen index > count
            set candidate = Companions_GetControlledDisplayUnit(index)
            if candidate != null and candidate != hero and candidate != vendor and AI_GetInstance(candidate) > 0 and DialogInteraction_IsUnitAlive(candidate) and not IsUnitHidden(candidate) and IsUnitInRange(candidate, hero, 1200.00) then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set selected = candidate
                endif
            endif
            set index = index + 1
        endloop
        set candidate = null
        set hero = null
        set vendor = null
        return selected
    endfunction

    private function QV_QueueEscortTravelDialogue takes integer escortIndex, unit vendor, unit hero returns nothing
        local unit companion
        local string soundKey = ""

        if escortIndex <= 0 or vendor == null or hero == null then
            set vendor = null
            set hero = null
            return
        endif
        if QV_EscortTravelVoiceIndex[escortIndex] > 0 then
            set soundKey = QuestsGeneric_FormatSoundKey(QV_EscortVoiceType[escortIndex], QV_EscortTravelVoiceIndex[escortIndex])
        endif
        if QV_EscortTravelText[escortIndex] != "" then
            call DialogSystem_QueueFieldLine(vendor, QV_GetSpeakerName(vendor), soundKey, QV_EscortTravelText[escortIndex])
        endif
        set companion = QV_FindEscortCompanion(hero, vendor)
        if companion != null and QV_EscortCompanionReply[escortIndex] != "" then
            call DialogSystem_QueueFieldLine(companion, GetUnitName(companion), "", QV_EscortCompanionReply[escortIndex])
        endif
        set companion = null
        set vendor = null
        set hero = null
    endfunction

    private function QV_ProtectEscort takes integer questId, unit vendor returns nothing
        if questId <= 0 or vendor == null then
            set vendor = null
            return
        endif
        if not QV_EscortWasInvulnerable.boolean.has(questId) then
            set QV_EscortWasInvulnerable.boolean[questId] = BlzIsUnitInvulnerable(vendor)
        endif
        call SetUnitInvulnerable(vendor, true)
        set vendor = null
    endfunction

    private function QV_RecordEscortOrigin takes integer questId, unit vendor returns nothing
        if questId > 0 and vendor != null and not QV_EscortOriginStored.boolean[questId] then
            set QV_EscortOriginStored.boolean[questId] = true
            set QV_EscortOriginX.real[questId] = GetUnitX(vendor)
            set QV_EscortOriginY.real[questId] = GetUnitY(vendor)
            set QV_EscortOriginFacing.real[questId] = GetUnitFacing(vendor)
        endif
        set vendor = null
    endfunction

    private function QV_ClearEscortOrigin takes integer questId returns nothing
        call QV_EscortOriginStored.boolean.remove(questId)
        call QV_EscortOriginX.real.remove(questId)
        call QV_EscortOriginY.real.remove(questId)
        call QV_EscortOriginFacing.real.remove(questId)
    endfunction

    private function QV_ResetEscortToOrigin takes integer questId, unit vendor returns nothing
        if vendor != null and QV_EscortOriginStored.boolean[questId] then
            call SetUnitPosition(vendor, QV_EscortOriginX.real[questId], QV_EscortOriginY.real[questId])
            call SetUnitFacing(vendor, QV_EscortOriginFacing.real[questId])
        endif
        call QV_ClearEscortOrigin(questId)
        set vendor = null
    endfunction

    private function QV_GetDestinationX takes integer escortIndex returns real
        local ZoneData z
        local rect destinationRect
        local real result = 0.00

        if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT and QV_EscortDestination[escortIndex] != null then
            return GetUnitX(QV_EscortDestination[escortIndex])
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_POINT then
            return QV_EscortDestinationX[escortIndex]
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_RECT then
            set destinationRect = QV_EscortConfiguredRect[escortIndex]
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_ZONE then
            set z = ZonesCore_GetZoneData(QV_EscortDestinationZoneId[escortIndex])
            if z != 0 and z.enterRegionCount > 0 then
                set destinationRect = z.enterRegions[0]
            endif
        endif
        if destinationRect != null then
            set result = (GetRectMinX(destinationRect) + GetRectMaxX(destinationRect))*0.50
        endif
        set destinationRect = null
        return result
    endfunction

    private function QV_GetDestinationY takes integer escortIndex returns real
        local ZoneData z
        local rect destinationRect
        local real result = 0.00

        if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT and QV_EscortDestination[escortIndex] != null then
            return GetUnitY(QV_EscortDestination[escortIndex])
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_POINT then
            return QV_EscortDestinationY[escortIndex]
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_RECT then
            set destinationRect = QV_EscortConfiguredRect[escortIndex]
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_ZONE then
            set z = ZonesCore_GetZoneData(QV_EscortDestinationZoneId[escortIndex])
            if z != 0 and z.enterRegionCount > 0 then
                set destinationRect = z.enterRegions[0]
            endif
        endif
        if destinationRect != null then
            set result = (GetRectMinY(destinationRect) + GetRectMaxY(destinationRect))*0.50
        endif
        set destinationRect = null
        return result
    endfunction

    private function QV_IsZoneOrChild takes integer zoneId, integer destinationZoneId returns boolean
        local integer depth = 0

        loop
            exitwhen zoneId <= 0 or depth >= 16
            if zoneId == destinationZoneId then
                return true
            endif
            set zoneId = ZonesCore_GetParentZoneId(zoneId)
            set depth = depth + 1
        endloop
        return false
    endfunction

    private function QV_IsEscortDestinationAvailable takes integer escortIndex returns boolean
        local ZoneData z

        if escortIndex <= 0 then
            return false
        endif
        if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT then
            return DialogInteraction_IsUnitAlive(QV_EscortDestination[escortIndex])
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_POINT then
            return QV_EscortDestinationRadius[escortIndex] > 0.00
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_RECT then
            return QV_EscortConfiguredRect[escortIndex] != null
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_ZONE then
            set z = ZonesCore_GetZoneData(QV_EscortDestinationZoneId[escortIndex])
            return z != 0 and z.enterRegionCount > 0
        endif
        return false
    endfunction

    private function QV_IsAtEscortDestination takes integer escortIndex, unit escortUnit returns boolean
        local integer pointZoneId
        local real dx
        local real dy
        local real radius

        if escortUnit == null or not QV_IsEscortDestinationAvailable(escortIndex) then
            set escortUnit = null
            return false
        endif
        if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_RECT then
            if RectContainsCoords(QV_EscortConfiguredRect[escortIndex], GetUnitX(escortUnit), GetUnitY(escortUnit)) then
                set escortUnit = null
                return true
            endif
        elseif QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_ZONE then
            set pointZoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(escortUnit), GetUnitY(escortUnit))
            if QV_IsZoneOrChild(pointZoneId, QV_EscortDestinationZoneId[escortIndex]) then
                set escortUnit = null
                return true
            endif
        else
            set dx = QV_GetDestinationX(escortIndex) - GetUnitX(escortUnit)
            set dy = QV_GetDestinationY(escortIndex) - GetUnitY(escortUnit)
            set radius = QV_EscortDestinationRadius[escortIndex]
            if dx*dx + dy*dy <= radius*radius then
                set escortUnit = null
                return true
            endif
        endif
        set escortUnit = null
        return false
    endfunction

    private function QV_GetAmbushStateKey takes integer questId, integer ambushIndex returns integer
        return questId*QV_AMBUSH_STATE_KEY_STRIDE + ambushIndex
    endfunction

    private function QV_GetAmbushWaveKey takes integer questId, integer ambushIndex, integer occurrence returns integer
        return questId*QV_AMBUSH_WAVE_KEY_STRIDE + ambushIndex*QV_AMBUSH_OCCURRENCE_STRIDE + occurrence
    endfunction

    private function QV_OrderAmbushUnit takes nothing returns nothing
        local unit attacker = GetEnumUnit()

        if attacker != null and QV_AmbushOrderTarget != null then
            call IssueTargetOrder(attacker, "attack", QV_AmbushOrderTarget)
        endif
        set attacker = null
    endfunction

    private function QV_CleanupEscortAmbushes takes integer questId, integer definitionId returns nothing
        local integer ambushIndex = 1
        local integer occurrence
        local integer stateKey
        local integer ambushKey
        local Wave wave

        loop
            exitwhen ambushIndex > QV_AmbushCount
            if QV_AmbushDefinitionId[ambushIndex] == definitionId then
                set occurrence = 1
                loop
                    exitwhen occurrence > QV_MAX_AMBUSH_OCCURRENCES
                    set ambushKey = QV_GetAmbushWaveKey(questId, ambushIndex, occurrence)
                    set wave = QV_AmbushWave.integer[ambushKey]
                    if wave != 0 then
                        call wave.destroy()
                    endif
                    call QV_AmbushWave.integer.remove(ambushKey)
                    set occurrence = occurrence + 1
                endloop
                set stateKey = QV_GetAmbushStateKey(questId, ambushIndex)
                call QV_AmbushOccurrenceTarget.integer.remove(stateKey)
                call QV_AmbushOccurrenceCount.integer.remove(stateKey)
            endif
            set ambushIndex = ambushIndex + 1
        endloop
    endfunction

    private function QV_ClearEscortLeg takes integer questId returns nothing
        call QV_EscortLeg.integer.remove(questId)
        call QV_EscortLegDistance.real.remove(questId)
    endfunction

    private function QV_PrepareEscortLeg takes integer questId, integer escortIndex, unit vendor, integer leg returns nothing
        local real targetX
        local real targetY
        local real dx
        local real dy

        if questId <= 0 or escortIndex <= 0 or vendor == null then
            set vendor = null
            return
        endif
        if leg == ESCORT_LEG_RETURN then
            set targetX = QV_EscortOriginX.real[questId]
            set targetY = QV_EscortOriginY.real[questId]
        elseif QV_IsEscortDestinationAvailable(escortIndex) then
            set targetX = QV_GetDestinationX(escortIndex)
            set targetY = QV_GetDestinationY(escortIndex)
        else
            set vendor = null
            return
        endif
        set QV_EscortLeg.integer[questId] = leg
        set dx = targetX - GetUnitX(vendor)
        set dy = targetY - GetUnitY(vendor)
        set QV_EscortLegDistance.real[questId] = SquareRoot(dx*dx + dy*dy)
        set vendor = null
    endfunction

    private function QV_GetEscortArrivalRadius takes integer escortIndex returns real
        if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT or QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_POINT then
            return QV_EscortDestinationRadius[escortIndex]
        endif
        return QV_ESCORT_AREA_ARRIVAL_RADIUS
    endfunction

    private function QV_StartEscortMovement takes integer questId, integer escortIndex, unit vendor, unit hero returns nothing
        local integer leg = QV_EscortLeg.integer[questId]
        local integer waypointIndex
        local integer waypointSlot
        local real destinationX
        local real destinationY
        local real arrivalRadius

        if vendor == null or hero == null or leg <= 0 then
            set vendor = null
            set hero = null
            return
        endif
        call EscortMovement_Begin(vendor, hero, QV_EscortLeaderRange[escortIndex])
        if leg == ESCORT_LEG_RETURN then
            set waypointIndex = QV_EscortWaypointCount[escortIndex]
            loop
                exitwhen waypointIndex <= 0
                set waypointSlot = QV_GetEscortWaypointSlot(escortIndex, waypointIndex)
                call EscortMovement_AddWaypoint(vendor, QV_EscortWaypointX[waypointSlot], QV_EscortWaypointY[waypointSlot], QV_EscortWaypointRadius[waypointSlot])
                set waypointIndex = waypointIndex - 1
            endloop
            set destinationX = QV_EscortOriginX.real[questId]
            set destinationY = QV_EscortOriginY.real[questId]
            set arrivalRadius = QV_ESCORT_DESTINATION_RADIUS
        else
            set waypointIndex = 1
            loop
                exitwhen waypointIndex > QV_EscortWaypointCount[escortIndex]
                set waypointSlot = QV_GetEscortWaypointSlot(escortIndex, waypointIndex)
                call EscortMovement_AddWaypoint(vendor, QV_EscortWaypointX[waypointSlot], QV_EscortWaypointY[waypointSlot], QV_EscortWaypointRadius[waypointSlot])
                set waypointIndex = waypointIndex + 1
            endloop
            set destinationX = QV_GetDestinationX(escortIndex)
            set destinationY = QV_GetDestinationY(escortIndex)
            set arrivalRadius = QV_GetEscortArrivalRadius(escortIndex)
        endif
        call EscortMovement_Start(vendor, destinationX, destinationY, arrivalRadius)
        set vendor = null
        set hero = null
    endfunction

    private function QV_EnsureEscortMovement takes integer questId, integer escortIndex, unit vendor returns nothing
        local unit hero
        local integer leg
        local boolean leaderChanged = false

        if vendor == null then
            set vendor = null
            return
        endif
        set hero = QV_EscortLeader.unit[questId]
        if not DialogInteraction_IsUnitAlive(hero) then
            set hero = DialogInteraction_GetAvailableHero(vendor, 0.00)
            set leaderChanged = true
        endif
        if hero == null then
            set vendor = null
            set hero = null
            return
        endif
        call QV_RecordEscortOrigin(questId, vendor)
        call QV_ProtectEscort(questId, vendor)
        set QV_EscortLeader.unit[questId] = hero
        if not QV_EscortLeg.integer.has(questId) then
            call QV_PrepareEscortLeg(questId, escortIndex, vendor, ESCORT_LEG_OUTBOUND)
        endif
        set leg = QV_EscortLeg.integer[questId]
        if leaderChanged and EscortMovement_IsActive(vendor) then
            call EscortMovement_Stop(vendor)
        endif
        if not EscortMovement_IsActive(vendor) then
            call QV_StartEscortMovement(questId, escortIndex, vendor, hero)
        elseif leg == ESCORT_LEG_OUTBOUND and QV_IsEscortDestinationAvailable(escortIndex) then
            call EscortMovement_UpdateDestination(vendor, QV_GetDestinationX(escortIndex), QV_GetDestinationY(escortIndex))
        endif
        set vendor = null
        set hero = null
    endfunction

    private function QV_GetEscortLegProgress takes integer questId, integer escortIndex, unit vendor returns real
        local integer leg = QV_EscortLeg.integer[questId]
        local real routeDistance = QV_EscortLegDistance.real[questId]
        local real targetX
        local real targetY
        local real dx
        local real dy
        local real progress

        if routeDistance <= 0.00 or vendor == null then
            set vendor = null
            return 0.00
        endif
        if leg == ESCORT_LEG_RETURN then
            set targetX = QV_EscortOriginX.real[questId]
            set targetY = QV_EscortOriginY.real[questId]
        elseif QV_IsEscortDestinationAvailable(escortIndex) then
            set targetX = QV_GetDestinationX(escortIndex)
            set targetY = QV_GetDestinationY(escortIndex)
        else
            set vendor = null
            return 0.00
        endif
        set dx = targetX - GetUnitX(vendor)
        set dy = targetY - GetUnitY(vendor)
        set progress = 1.00 - SquareRoot(dx*dx + dy*dy)/routeDistance
        set vendor = null
        if progress < 0.00 then
            return 0.00
        elseif progress > 1.00 then
            return 1.00
        endif
        return progress
    endfunction

    private function QV_SpawnEscortAmbush takes integer questId, integer escortIndex, integer ambushIndex, integer occurrence, unit vendor returns nothing
        local integer ambushKey = QV_GetAmbushWaveKey(questId, ambushIndex, occurrence)
        local real angle = GetRandomReal(0.00, 360.00)*bj_DEGTORAD
        local real centerX = GetUnitX(vendor) + QV_AmbushSpawnDistance[ambushIndex]*Cos(angle)
        local real centerY = GetUnitY(vendor) + QV_AmbushSpawnDistance[ambushIndex]*Sin(angle)
        local string soundKey = ""
        local Wave wave = Wave.create()

        call UnitSpawn_SpawnUnitRandomlyForWaveEx(wave, Player(PLAYER_NEUTRAL_AGGRESSIVE), QV_AmbushEnemyUnitType[ambushIndex], centerX, centerY, 140.00, QV_AmbushEnemyCount[ambushIndex], "", 0.00, "", 0.00, false, null, null)
        set QV_AmbushWave.integer[ambushKey] = wave
        set QV_AmbushOrderTarget = vendor
        call ForGroup(wave.units, function QV_OrderAmbushUnit)
        set QV_AmbushOrderTarget = null
        if QV_AmbushAlertVoiceIndex[ambushIndex] > 0 then
            set soundKey = QuestsGeneric_FormatSoundKey(QV_EscortVoiceType[escortIndex], QV_AmbushAlertVoiceIndex[ambushIndex])
        endif
        if QV_AmbushAlertText[ambushIndex] != null and QV_AmbushAlertText[ambushIndex] != "" then
            call DialogSystem_QueueFieldLine(vendor, QV_GetSpeakerName(vendor), soundKey, QV_AmbushAlertText[ambushIndex])
        endif
        set vendor = null
    endfunction

    private function QV_CheckEscortAmbushes takes integer questId, integer definitionId, integer escortIndex, unit vendor returns nothing
        local integer ambushIndex = 1
        local integer leg = QV_EscortLeg.integer[questId]
        local integer stateKey
        local integer targetOccurrences
        local integer completedOccurrences
        local real threshold
        local real progress = QV_GetEscortLegProgress(questId, escortIndex, vendor)

        loop
            exitwhen ambushIndex > QV_AmbushCount
            if QV_AmbushDefinitionId[ambushIndex] == definitionId and QV_AmbushLeg[ambushIndex] == leg then
                set stateKey = QV_GetAmbushStateKey(questId, ambushIndex)
                if not QV_AmbushOccurrenceTarget.integer.has(stateKey) then
                    set QV_AmbushOccurrenceTarget.integer[stateKey] = GetRandomInt(QV_AmbushMinOccurrences[ambushIndex], QV_AmbushMaxOccurrences[ambushIndex])
                endif
                set targetOccurrences = QV_AmbushOccurrenceTarget.integer[stateKey]
                set completedOccurrences = QV_AmbushOccurrenceCount.integer[stateKey]
                if targetOccurrences <= 1 then
                    set threshold = QV_AmbushProgress[ambushIndex]
                else
                    set threshold = QV_AmbushProgress[ambushIndex] + (0.90 - QV_AmbushProgress[ambushIndex])*I2R(completedOccurrences)/I2R(targetOccurrences - 1)
                endif
                if completedOccurrences < targetOccurrences and progress >= threshold then
                    set completedOccurrences = completedOccurrences + 1
                    set QV_AmbushOccurrenceCount.integer[stateKey] = completedOccurrences
                    call QV_SpawnEscortAmbush(questId, escortIndex, ambushIndex, completedOccurrences, vendor)
                endif
            endif
            set ambushIndex = ambushIndex + 1
        endloop
        set vendor = null
    endfunction

    private function QV_BeginEscortReturnLeg takes integer questId, integer escortIndex, unit vendor returns nothing
        local string soundKey = ""
        local unit hero = QV_EscortLeader.unit[questId]

        call QV_PrepareEscortLeg(questId, escortIndex, vendor, ESCORT_LEG_RETURN)
        if hero != null then
            call QV_StartEscortMovement(questId, escortIndex, vendor, hero)
        endif
        call QuestGiver_UpdateRequirementText(questId, 1, "Escort " + QV_GetSpeakerName(vendor) + " back to " + QV_EscortReturnName[escortIndex])
        call QuestGiver_SetObjectiveTarget(questId, 1, null)
        if QV_EscortReturnVoiceIndex[escortIndex] > 0 then
            set soundKey = QuestsGeneric_FormatSoundKey(QV_EscortVoiceType[escortIndex], QV_EscortReturnVoiceIndex[escortIndex])
        endif
        if QV_EscortReturnText[escortIndex] != null and QV_EscortReturnText[escortIndex] != "" then
            call DialogSystem_QueueFieldLine(vendor, QV_GetSpeakerName(vendor), soundKey, QV_EscortReturnText[escortIndex])
        endif
        set vendor = null
        set hero = null
    endfunction

    private function QV_CompleteEscort takes integer questId returns nothing
        local QuestData q = QuestMaster_GetById(questId)

        if q != 0 then
            call QuestGiver_SetRequirementCompleted(questId, 1, true)
            call QuestGiver_SetStateByNameAndGiver(q.name, q.giver, QUEST_STATE_READY_TURNIN)
            call q.addReturnRequirement()
        endif
    endfunction

    private function QV_CheckEscortProgress takes integer questId, integer escortIndex, unit vendor returns nothing
        local integer leg = QV_EscortLeg.integer[questId]
        local real dx
        local real dy

        if vendor == null then
            set vendor = null
            return
        endif
        if leg == ESCORT_LEG_OUTBOUND and QV_IsAtEscortDestination(escortIndex, vendor) then
            if QV_EscortRoundTrip[escortIndex] then
                call QV_BeginEscortReturnLeg(questId, escortIndex, vendor)
            else
                call QV_CompleteEscort(questId)
            endif
        elseif leg == ESCORT_LEG_RETURN then
            set dx = QV_EscortOriginX.real[questId] - GetUnitX(vendor)
            set dy = QV_EscortOriginY.real[questId] - GetUnitY(vendor)
            if dx*dx + dy*dy <= QV_ESCORT_DESTINATION_RADIUS*QV_ESCORT_DESTINATION_RADIUS then
                call QV_CompleteEscort(questId)
            endif
        endif
        set vendor = null
    endfunction

    private function QV_OnEscortCheck takes nothing returns nothing
        local integer index = 1
        local integer questId
        local integer definitionId
        local integer escortIndex
        local QuestData q

        loop
            exitwhen index > QuestsGeneric_GetQuestCount()
            set questId = QuestsGeneric_GetQuestIdByIndex(index)
            set definitionId = QuestsGeneric_GetDefinitionForQuest(questId)
            set escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
            if escortIndex > 0 then
                set q = QuestMaster_GetById(questId)
                if q != 0 and q.active and q.state == QUEST_STATE_IN_PROGRESS and DialogInteraction_IsUnitAlive(q.giver) then
                    call QV_EnsureEscortMovement(questId, escortIndex, q.giver)
                    call QV_CheckEscortAmbushes(questId, definitionId, escortIndex, q.giver)
                    call QV_CheckEscortProgress(questId, escortIndex, q.giver)
                endif
            endif
            set index = index + 1
        endloop
    endfunction

    private function QV_StartEscort takes integer questId, integer escortIndex, unit vendor, unit hero returns nothing
        local QuestData q = QuestMaster_GetById(questId)

        if q == 0 or not q.active or q.completed or escortIndex <= 0 or vendor == null or hero == null then
            set vendor = null
            set hero = null
            return
        endif
        call QV_RecordEscortOrigin(questId, vendor)
        set QV_EscortLeader.unit[questId] = hero
        call QV_PrepareEscortLeg(questId, escortIndex, vendor, ESCORT_LEG_OUTBOUND)
        call QV_ProtectEscort(questId, vendor)
        call QV_StartEscortMovement(questId, escortIndex, vendor, hero)
        call QV_QueueEscortTravelDialogue(escortIndex, vendor, hero)
        set vendor = null
        set hero = null
    endfunction

    private function QV_StopEscort takes integer questId, unit vendor returns nothing
        if vendor != null and EscortMovement_IsActive(vendor) then
            call EscortMovement_Stop(vendor)
        endif
        if vendor != null and QV_EscortWasInvulnerable.boolean.has(questId) then
            call SetUnitInvulnerable(vendor, QV_EscortWasInvulnerable.boolean[questId])
            call QV_EscortWasInvulnerable.boolean.remove(questId)
        endif
        call QV_EscortLeader.unit.remove(questId)
        set vendor = null
    endfunction

    private function QV_RefreshEscortObjective takes integer questId, integer escortIndex, unit vendor returns nothing
        local unit destination
        local QuestData q

        if questId <= 0 or escortIndex <= 0 or vendor == null then
            set vendor = null
            return
        endif
        set q = QuestMaster_GetById(questId)
        if q != 0 then
            if QV_EscortLeg.integer[questId] == ESCORT_LEG_RETURN then
                call q.setRequirement(1, "Escort " + QV_GetSpeakerName(vendor) + " back to " + QV_EscortReturnName[escortIndex])
            elseif QV_EscortRoundTrip[escortIndex] then
                call q.setRequirement(1, "Escort " + QV_GetSpeakerName(vendor) + " to " + QV_EscortDestinationName[escortIndex] + " and back to " + QV_EscortReturnName[escortIndex])
            else
                call q.setRequirement(1, "Escort " + QV_GetSpeakerName(vendor) + " to " + QV_EscortDestinationName[escortIndex])
            endif
        endif
        if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT then
            set destination = QV_EscortDestination[escortIndex]
            call QuestGiver_SetObjectiveTarget(questId, 1, destination)
        else
            call QuestGiver_SetObjectiveTarget(questId, 1, null)
        endif
        set destination = null
        set vendor = null
    endfunction

    private function QV_RefreshObjectiveTargets takes nothing returns nothing
        local integer index = 1
        local integer definitionId
        local integer supplyIndex
        local integer escortIndex
        local integer questId
        local QuestData q

        loop
            exitwhen index > QuestsGeneric_GetQuestCount()
            set questId = QuestsGeneric_GetQuestIdByIndex(index)
            set definitionId = QuestsGeneric_GetDefinitionForQuest(questId)
            set supplyIndex = QV_SupplyIndexByDefinition.integer[definitionId]
            if supplyIndex > 0 and QV_TargetVendor[supplyIndex] != null then
                call QuestGiver_SetObjectiveTarget(questId, 1, QV_TargetVendor[supplyIndex])
            endif
            set escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
            if escortIndex > 0 then
                set q = QuestMaster_GetById(questId)
                if q != 0 and not q.completed and q.state != QUEST_STATE_COMPLETE then
                    call QV_RefreshEscortObjective(questId, escortIndex, q.giver)
                    if q.active and q.state == QUEST_STATE_IN_PROGRESS then
                        call QV_EnsureEscortMovement(questId, escortIndex, q.giver)
                    endif
                endif
            endif
            set index = index + 1
        endloop
    endfunction

    private function QV_IsRelevantUnitType takes integer unitTypeId returns boolean
        local integer supplyIndex = 1
        local integer escortIndex = 1

        if unitTypeId == 0 then
            return false
        endif
        if QuestsGeneric_HasDefinitionForUnitType(unitTypeId) then
            return true
        endif
        loop
            exitwhen supplyIndex > QV_SupplyCount
            if QV_TargetVendorUnitType[supplyIndex] == unitTypeId then
                return true
            endif
            set supplyIndex = supplyIndex + 1
        endloop
        loop
            exitwhen escortIndex > QV_EscortCount
            if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT and QV_EscortDestinationUnitType[escortIndex] == unitTypeId then
                return true
            endif
            set escortIndex = escortIndex + 1
        endloop
        return false
    endfunction

    public function RegisterUnit takes unit vendor returns nothing
        local integer supplyIndex = 1
        local integer escortIndex = 1

        if vendor == null then
            set vendor = null
            return
        endif
        call QV_ConfigureSupplyObjectives()
        loop
            exitwhen supplyIndex > QV_SupplyCount
            if QV_TargetVendorUnitType[supplyIndex] == GetUnitTypeId(vendor) then
                set QV_TargetVendor[supplyIndex] = vendor
            endif
            set supplyIndex = supplyIndex + 1
        endloop
        loop
            exitwhen escortIndex > QV_EscortCount
            if QV_EscortDestinationType[escortIndex] == ESCORT_DESTINATION_UNIT and not QV_EscortExactDestination[escortIndex] and QV_EscortDestinationUnitType[escortIndex] == GetUnitTypeId(vendor) and DialogInteraction_IsUnitAlive(vendor) then
                set QV_EscortDestination[escortIndex] = vendor
            endif
            set escortIndex = escortIndex + 1
        endloop
        call QuestsGeneric_RegisterUnit(vendor, QV_GetSpeakerName(vendor))
        call QV_RefreshObjectiveTargets()
        set vendor = null
    endfunction

    public function RegisterExistingQuestGivers takes nothing returns nothing
        local group worldUnits = CreateGroup()
        local rect worldBounds = GetWorldBounds()
        local unit vendor

        call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
        loop
            set vendor = FirstOfGroup(worldUnits)
            exitwhen vendor == null
            call GroupRemoveUnit(worldUnits, vendor)
            if QV_IsRelevantUnitType(GetUnitTypeId(vendor)) then
                call QuestsVendor_RegisterUnit(vendor)
            endif
        endloop

        call DestroyGroup(worldUnits)
        call RemoveRect(worldBounds)
        set worldUnits = null
        set worldBounds = null
        set vendor = null
    endfunction

    private function QV_RegisterExistingDelayed takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call QuestsVendor_RegisterExistingQuestGivers()
        call DestroyTimer(expiredTimer)
        set expiredTimer = null
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

    public function IsTradeUnlocked takes unit vendor returns boolean
        local integer index = 1
        local integer escortIndex
        local integer definitionId
        local QuestData q

        if vendor == null then
            set vendor = null
            return false
        endif
        loop
            exitwhen index > QuestsGeneric_GetQuestCount()
            set q = QuestMaster_GetById(QuestsGeneric_GetQuestIdByIndex(index))
            if q != 0 and q.giver == vendor then
                set definitionId = QuestsGeneric_GetDefinitionForQuest(q.id)
                set escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
                if escortIndex > 0 and QV_EscortTradeLocked[escortIndex] and not q.completed then
                    set vendor = null
                    return false
                endif
            endif
            set index = index + 1
        endloop
        set vendor = null
        return true
    endfunction

    public function GetTradeLockText takes unit vendor returns string
        local integer index = 1
        local integer escortIndex
        local integer definitionId
        local QuestData q

        if vendor == null then
            set vendor = null
            return "Complete this vendor's escort quest before trading."
        endif
        loop
            exitwhen index > QuestsGeneric_GetQuestCount()
            set q = QuestMaster_GetById(QuestsGeneric_GetQuestIdByIndex(index))
            if q != 0 and q.giver == vendor then
                set definitionId = QuestsGeneric_GetDefinitionForQuest(q.id)
                set escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
                if escortIndex > 0 and QV_EscortTradeLocked[escortIndex] and not q.completed then
                    set vendor = null
                    if QV_EscortRoundTrip[escortIndex] then
                        return "Escort " + QV_GetSpeakerName(q.giver) + " to " + QV_EscortDestinationName[escortIndex] + " and back before trading."
                    endif
                    return "Escort " + QV_GetSpeakerName(q.giver) + " to " + QV_EscortDestinationName[escortIndex] + " before trading."
                endif
            endif
            set index = index + 1
        endloop
        set vendor = null
        return "Complete this vendor's escort quest before trading."
    endfunction

    private function QV_ClearPendingAction takes nothing returns nothing
        set QV_PendingQuestId = 0
        set QV_PendingSupplyIndex = 0
        set QV_PendingAction = 0
        set QV_PendingVendor = null
        set QV_PendingHero = null
        set QV_PendingOpenTrade = false
        set QV_PendingEscortQuestId = 0
        set QV_PendingEscortIndex = 0
        set QV_PendingEscortVendor = null
        set QV_PendingEscortHero = null
    endfunction

    public function CancelPendingAction takes nothing returns nothing
        call QuestsGeneric_CancelPendingAction()
        call QV_ClearPendingAction()
        set QV_OpenTradeRequest = false
    endfunction

    private function QV_CreateTargetSequence takes unit vendor, unit hero, integer supplyIndex, boolean alreadyHandedOff returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string speakerName = QV_GetSpeakerName(vendor)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, vendor, speakerName)
        call DialogSystem_AddMakeFaceEachOther(seq, vendor, hero, 0.45, 0.00)
        if QV_RequiresPurchase[supplyIndex] then
            call QuestsGeneric_AddHeroVoiceVariantLine(seq, hero, vendor, QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_QUEST_HERO_ASK_TO_BUY, 25)
            call DialogSystem_AddLine(seq, vendor, speakerName, VL_QUEST_VENDOR_PURCHASE, "", true)
        else
            call QuestsGeneric_AddHeroVoiceVariantLine(seq, hero, vendor, QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_QUEST_HERO_REQUEST_SUPPLY, 21)
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
        local integer questId
        local integer definitionId
        local integer escortIndex
        local QuestData q

        call QV_ClearPendingAction()
        set QV_OpenTradeRequest = false
        if actionId > QV_TARGET_ACTION_BASE then
            call QuestsGeneric_CancelPendingAction()
            set seq = QV_BeginTargetAction(actionId, vendor, hero)
        else
            set questId = QuestsGeneric_GetQuestIdFromAction(actionId)
            set definitionId = QuestsGeneric_GetDefinitionForQuest(questId)
            set q = QuestMaster_GetById(questId)
            set escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
            if q != 0 and q.state == QUEST_STATE_AVAILABLE and escortIndex > 0 and not QV_IsEscortDestinationAvailable(escortIndex) then
                call QuestsVendor_RegisterExistingQuestGivers()
            endif
            if q != 0 and q.state == QUEST_STATE_AVAILABLE and escortIndex > 0 and not QV_IsEscortDestinationAvailable(escortIndex) then
                call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 7.00, "|cffff8040Escort destination unavailable: " + QV_EscortDestinationName[escortIndex] + ". Check that its configured NPC, rect, point, or zone exists.|r")
                call QuestsGeneric_CancelPendingAction()
                set vendor = null
                set hero = null
                return 0
            endif
            if q != 0 and q.state == QUEST_STATE_AVAILABLE and escortIndex > 0 then
                set QV_PendingEscortQuestId = questId
                set QV_PendingEscortIndex = escortIndex
                set QV_PendingEscortVendor = vendor
                set QV_PendingEscortHero = hero
            endif
            set seq = QuestsGeneric_BeginAction(actionId, vendor, QV_GetSpeakerName(vendor), hero)
        endif
        set vendor = null
        set hero = null
        return seq
    endfunction

    public function FinishPendingAction takes nothing returns nothing
        local QuestData q = QuestMaster_GetById(QV_PendingQuestId)
        local boolean openTrade = QV_PendingOpenTrade
        local integer escortQuestId = QV_PendingEscortQuestId
        local integer escortIndex = QV_PendingEscortIndex
        local unit escortVendor = QV_PendingEscortVendor
        local unit escortHero = QV_PendingEscortHero

        call QuestsGeneric_FinishPendingAction()
        if escortQuestId > 0 then
            call QV_StartEscort(escortQuestId, escortIndex, escortVendor, escortHero)
        endif
        if QV_PendingAction == QV_PENDING_HANDOFF and q != 0 and q.active and not q.completed and QV_PendingVendor != null and GetUnitTypeId(QV_PendingVendor) == QV_TargetVendorUnitType[QV_PendingSupplyIndex] then
            if QuestGiver_GiveQuestItemToHero(QV_PendingHero, QV_SupplyItemType[QV_PendingSupplyIndex], 0, GetObjectName(QV_SupplyItemType[QV_PendingSupplyIndex])) then
                set QV_SupplyClaimed.boolean[QV_PendingQuestId] = true
                call QuestGiver_CompleteTalkToRequirement(QV_PendingQuestId, 1)
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cff80ff80Received " + GetObjectName(QV_SupplyItemType[QV_PendingSupplyIndex]) + " for " + q.title + ".|r")
            endif
        endif
        call QV_ClearPendingAction()
        set QV_OpenTradeRequest = openTrade
        set escortVendor = null
        set escortHero = null
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

    private function QV_OnQuestStateChanged takes nothing returns nothing
        local integer questId = QuestMaster_EventQuestId
        local integer definitionId = QuestsGeneric_GetDefinitionForQuest(questId)
        local integer escortIndex = QV_EscortIndexByDefinition.integer[definitionId]
        local QuestData q = QuestMaster_GetById(questId)

        if escortIndex <= 0 or q == 0 then
            return
        endif
        if q.active and q.state == QUEST_STATE_IN_PROGRESS then
            call QV_EnsureEscortMovement(questId, escortIndex, q.giver)
        elseif q.state == QUEST_STATE_READY_TURNIN then
            call QV_StopEscort(questId, q.giver)
            call QV_CleanupEscortAmbushes(questId, definitionId)
            call QV_ClearEscortLeg(questId)
        else
            call QV_StopEscort(questId, q.giver)
            call QV_CleanupEscortAmbushes(questId, definitionId)
            call QV_ClearEscortLeg(questId)
            if q.state == QUEST_STATE_COMPLETE then
                call QV_ClearEscortOrigin(questId)
            else
                call QV_ResetEscortToOrigin(questId, q.giver)
            endif
            if q.state == QUEST_STATE_AVAILABLE then
                call QV_RefreshEscortObjective(questId, escortIndex, q.giver)
            endif
        endif
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer
        local timer escortTimer

        set QV_SupplyIndexByDefinition = Table.create()
        set QV_SupplyClaimed = Table.create()
        set QV_EscortIndexByDefinition = Table.create()
        set QV_EscortLeader = Table.create()
        set QV_EscortWasInvulnerable = Table.create()
        set QV_EscortOriginStored = Table.create()
        set QV_EscortOriginX = Table.create()
        set QV_EscortOriginY = Table.create()
        set QV_EscortOriginFacing = Table.create()
        set QV_EscortLeg = Table.create()
        set QV_EscortLegDistance = Table.create()
        set QV_AmbushOccurrenceTarget = Table.create()
        set QV_AmbushOccurrenceCount = Table.create()
        set QV_AmbushWave = Table.create()
        call QuestMaster_AddDailyResetAction(function QV_OnDailyReset)
        call QuestMaster_AddStateChangedAction(function QV_OnQuestStateChanged)
        set escortTimer = CreateTimer()
        call TimerStart(escortTimer, QV_ESCORT_CHECK_INTERVAL, true, function QV_OnEscortCheck)
        set initTimer = CreateTimer()
        call TimerStart(initTimer, 0.10, false, function QV_RegisterExistingDelayed)
        set initTimer = null
        set escortTimer = null
    endfunction
endlibrary
