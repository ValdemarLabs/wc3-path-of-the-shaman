/**
    WantedPosts

    Author: Valdemar
    Version: 1.2.0
    Status: Draft content - to be revisited and refined by zone and quest overall design.

    Description:
    Automatically discovers every preplaced wanted sign, resolves its most
    specific ZonesCore zone, and registers its standalone dialog. Every sign
    remains a unique exact giver and owns its quest definitions and state.
    Draft regional quest sets are supplied for Mok'natha, Ironspine Post, the
    Sereneglade Horde mountain camp, and the Thornwoods Horde Scout Base; all
    turn in at separate preplaced receivers and remain subject to location-led
    design review.

    Credits:

    How to install:
    Import after QuestsGenericDialog, ZonesCore, and Table. Preplace any number
    of 'n05N' signs inside configured zone/subzone rects; discovery is
    automatic. Do not call the draft configuration functions in the production
    map until the regional content has been reviewed and approved. Supply the
    exact wanted sign, remote receiver, and optional missing-person target
    after generated unit globals exist. The sign's resolved zone validates the
    selected regional package but never merges it with another sign. Pass true
    for registerReceiverDialog only when the receiver has no bespoke qXXX
    selection handler; custom dialogs must embed the QuestsGeneric
    button/action lifecycle themselves.

    API:
    - WantedPosts_AutoRegisterPreplacedSigns()
    - WantedPosts_GetSignCountForZone(zoneId)
    - WantedPosts_GetSignZoneId(wantedPost)
    - WantedPosts_IsRegisteredSign(wantedPost)
    - WantedPosts_ConfigureMoknatha(...)
    - WantedPosts_ConfigureIronspine(...)
    - WantedPosts_ConfigureSerenegladeMountainCamp(...)
    - WantedPosts_ConfigureThornwoodsScoutBase(...)

**/
library WantedPosts initializer Init requires QuestsGenericDialog, ZonesCore, Table
    globals
        private constant integer MAX_WANTED_SIGNS = 256
        private constant string WANTED_POST_NAME = "Wanted Post"
        private constant integer ZONE_SERENGLADE_MOUNTAIN_CAMP = 201
        private constant integer ZONE_MOKNATHA = 1401
        private constant integer ZONE_IRONSPINE_POST = 1901
        private constant integer ZONE_HORDE_SCOUT_BASE = 8810

        private Table DiscoveredSign = 0
        private Table SignZone = 0
        private Table SignCountByZone = 0
        private Table ConfiguredSign = 0
        private unit array WantedSign
        private integer WantedSignCount = 0
        private boolean SignsScanned = false
    endglobals

    private function DiscoverSign takes unit wantedPost returns nothing
        local integer handleId
        local integer zoneId

        if wantedPost == null or GetUnitTypeId(wantedPost) != QuestsGenericDialog_WANTED_POST_UNIT_TYPE then
            set wantedPost = null
            return
        endif
        set handleId = GetHandleId(wantedPost)
        if DiscoveredSign.boolean[handleId] or WantedSignCount >= MAX_WANTED_SIGNS then
            set wantedPost = null
            return
        endif
        set zoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(wantedPost), GetUnitY(wantedPost))
        set DiscoveredSign.boolean[handleId] = true
        set SignZone.integer[handleId] = zoneId
        set WantedSignCount = WantedSignCount + 1
        set WantedSign[WantedSignCount] = wantedPost
        if zoneId > 0 then
            set SignCountByZone.integer[zoneId] = SignCountByZone.integer[zoneId] + 1
        endif
        set wantedPost = null
    endfunction

    private function FinalizeSigns takes nothing returns nothing
        local integer index = 1
        local unit wantedPost

        loop
            exitwhen index > WantedSignCount
            set wantedPost = WantedSign[index]
            call QuestsGenericDialog_RegisterWantedPost(wantedPost, WANTED_POST_NAME)
            set index = index + 1
        endloop
        set wantedPost = null
    endfunction

    private function ScanPreplacedSigns takes nothing returns nothing
        local group worldUnits
        local rect worldBounds
        local unit enumUnit

        if SignsScanned then
            set worldUnits = null
            set worldBounds = null
            set enumUnit = null
            return
        endif
        set SignsScanned = true
        set worldUnits = CreateGroup()
        set worldBounds = GetWorldBounds()
        call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
        loop
            set enumUnit = FirstOfGroup(worldUnits)
            exitwhen enumUnit == null
            call GroupRemoveUnit(worldUnits, enumUnit)
            call DiscoverSign(enumUnit)
        endloop
        call FinalizeSigns()
        call DestroyGroup(worldUnits)
        call RemoveRect(worldBounds)
        set worldUnits = null
        set worldBounds = null
        set enumUnit = null
    endfunction

    public function AutoRegisterPreplacedSigns takes nothing returns nothing
        call ScanPreplacedSigns()
    endfunction

    public function GetSignCountForZone takes integer zoneId returns integer
        call ScanPreplacedSigns()
        return SignCountByZone.integer[zoneId]
    endfunction

    public function GetSignZoneId takes unit wantedPost returns integer
        local integer zoneId

        call ScanPreplacedSigns()
        if wantedPost == null then
            set wantedPost = null
            return 0
        endif
        set zoneId = SignZone.integer[GetHandleId(wantedPost)]
        set wantedPost = null
        return zoneId
    endfunction

    public function IsRegisteredSign takes unit wantedPost returns boolean
        local boolean isRegistered

        call ScanPreplacedSigns()
        if wantedPost == null then
            set wantedPost = null
            return false
        endif
        set isRegistered = DiscoveredSign.boolean[GetHandleId(wantedPost)]
        set wantedPost = null
        return isRegistered
    endfunction

    private function ResolveName takes unit whichUnit, string configuredName returns string
        if configuredName != null and configuredName != "" then
            set whichUnit = null
            return configuredName
        endif
        if whichUnit != null then
            set configuredName = GetUnitName(whichUnit)
        endif
        set whichUnit = null
        return configuredName
    endfunction

    private function CanConfigureSign takes unit wantedPost, integer expectedZoneId, unit receiver returns boolean
        local integer handleId

        call ScanPreplacedSigns()
        if wantedPost == null or receiver == null or wantedPost == receiver then
            set wantedPost = null
            set receiver = null
            return false
        endif
        set handleId = GetHandleId(wantedPost)
        if GetUnitTypeId(wantedPost) != QuestsGenericDialog_WANTED_POST_UNIT_TYPE or not DiscoveredSign.boolean[handleId] or SignZone.integer[handleId] != expectedZoneId or ConfiguredSign.boolean[handleId] then
            set wantedPost = null
            set receiver = null
            return false
        endif
        set ConfiguredSign.boolean[handleId] = true
        set wantedPost = null
        set receiver = null
        return true
    endfunction

    private function ConfigureDefinition takes integer definitionId, unit wantedPost, unit receiver, string receiverName, string completeText, integer reputationBonus returns nothing
        if definitionId <= 0 then
            set wantedPost = null
            set receiver = null
            return
        endif
        call QuestsGeneric_SetGiverUnit(definitionId, wantedPost)
        call QuestsGeneric_SetReceiverUnit(definitionId, receiver, receiverName)
        call QuestsGeneric_SetReceiverDialogue(definitionId, "", 0, completeText)
        call QuestsGeneric_SetFactionReward(definitionId, "Horde", reputationBonus, false)
        set wantedPost = null
        set receiver = null
    endfunction

    private function RegisterActors takes unit wantedPost, unit receiver, string receiverName, unit missingPerson, string missingPersonName, boolean registerReceiverDialog returns nothing
        if missingPerson != null then
            call QuestsGeneric_RegisterUnit(missingPerson, missingPersonName)
        endif
        if registerReceiverDialog then
            call QuestsGenericDialog_RegisterNPC(receiver, receiverName)
        else
            call QuestsGeneric_RegisterUnit(receiver, receiverName)
        endif
        call QuestsGeneric_RegisterUnit(wantedPost, WANTED_POST_NAME)
        set wantedPost = null
        set receiver = null
        set missingPerson = null
    endfunction

    public function ConfigureMoknatha takes unit wantedPost, unit receiver, string receiverName, unit missingScout, string missingScoutName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanConfigureSign(wantedPost, ZONE_MOKNATHA, receiver) then
            set wantedPost = null
            set receiver = null
            set missingScout = null
            return
        endif
        set receiverName = ResolveName(receiver, receiverName)
        set missingScoutName = ResolveName(missingScout, missingScoutName)

        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Raiders of Zul'Garok", "daily", 12, "Raiders of Zul'Garok", "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Defeat nine jungle trolls raiding the paths between Mok'natha and the ruins of Zul'Garok.", 'nftr', 9, 65, "", 0, "The notice marks fresh troll raids along the road to Zul'Garok.", "")
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nftr')
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nftt')
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nftb')
        call QuestsGeneric_SetKillTargetZone(definitionId, 1402)
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The road crews report fewer raids. The bounty is yours.", 15)

        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Serpentshore Patrol", "daily", 12, "Serpentshore Patrol", "ReplaceableTextures\\CommandButtons\\BTNSnapDragon.blp", "Defeat eight naga or their beasts along Serpentshore before they reach Mok'natha.", 'nmyr', 8, 65, "", 0, "The notice warns that another naga patrol has left Serpentshore.", "")
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nmyr')
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nnsw')
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nsnp')
        call QuestsGeneric_SetKillTargetZone(definitionId, 1404)
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "Serpentshore is quieter for now. Take the posted payment.", 15)

        if missingScout != null then
            set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Songs Beneath the Surf", "normal", 13, "Songs Beneath the Surf", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Break through the naga screen at Serpentshore and find the missing Mok'natha scout.", 'nmyr', 6, 90, "", 0, "A scout vanished after reporting a song beneath the waves. The notice asks for a search beyond the naga line.", "")
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nmyr')
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nnsw')
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'nsnp')
            call QuestsGeneric_SetKillTargetZone(definitionId, 1404)
            call QuestsGeneric_AddFindObjective(definitionId, GetUnitTypeId(missingScout), missingScoutName)
            call QuestsGeneric_SetObjectiveTargetUnit(definitionId, 2, missingScout)
            call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The scout's account confirms that something beneath Serpentshore is calling to the living.", 30)
        endif

        call RegisterActors(wantedPost, receiver, receiverName, missingScout, missingScoutName, registerReceiverDialog)
        set wantedPost = null
        set receiver = null
        set missingScout = null
    endfunction

    public function ConfigureIronspine takes unit wantedPost, unit receiver, string receiverName, unit missingWatcher, string missingWatcherName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanConfigureSign(wantedPost, ZONE_IRONSPINE_POST, receiver) then
            set wantedPost = null
            set receiver = null
            set missingWatcher = null
            return
        endif
        set receiverName = ResolveName(receiver, receiverName)
        set missingWatcherName = ResolveName(missingWatcher, missingWatcherName)

        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Antlers in the Fog", "daily", 8, "Antlers in the Fog", "ReplaceableTextures\\CommandButtons\\BTNStag.blp", "Cull six diseased stags crowding the fogbound approaches to Ironspine Post.", 'n65D', 6, 40, "", 0, "The notice warns that diseased stags have blocked the outer watch paths.", "")
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The outer paths are open again. Here is the posted reward.", 15)

        set definitionId = QuestsGeneric_RegisterFetchQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Ichor for Ironspine", "repeatable", 8, "Ichor for Ironspine", "ReplaceableTextures\\CommandButtons\\BTNSpiderGreen.blp", "Gather five measures of spider ichor for Ironspine's warding braziers.", 'I66Q', 5, 40, "", 0, "Ironspine is buying spider ichor for the mixtures burned in its outer braziers.", "")
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "This will keep the warding fires bitter enough to cut through the fog.", 10)

        if missingWatcher != null then
            set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Lost Beyond the Watchfires", "normal", 9, "Lost Beyond the Watchfires", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Clear five diseased stags from the outer trail and find the watcher missing beyond Ironspine's fires.", 'n65D', 5, 60, "", 0, "An outer watcher missed the last signal. The notice marks the trail where the fog swallowed the patrol.", "")
            call QuestsGeneric_AddFindObjective(definitionId, GetUnitTypeId(missingWatcher), missingWatcherName)
            call QuestsGeneric_SetObjectiveTargetUnit(definitionId, 2, missingWatcher)
            call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "You found our watcher and cleared the trail. Ironspine remembers that service.", 30)
        endif

        call RegisterActors(wantedPost, receiver, receiverName, missingWatcher, missingWatcherName, registerReceiverDialog)
        set wantedPost = null
        set receiver = null
        set missingWatcher = null
    endfunction

    public function ConfigureSerenegladeMountainCamp takes unit wantedPost, unit receiver, string receiverName, unit missingScout, string missingScoutName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanConfigureSign(wantedPost, ZONE_SERENGLADE_MOUNTAIN_CAMP, receiver) then
            set wantedPost = null
            set receiver = null
            set missingScout = null
            return
        endif
        set receiverName = ResolveName(receiver, receiverName)
        set missingScoutName = ResolveName(missingScout, missingScoutName)

        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Scales and Stingers", "daily", 3, "Scales and Stingers", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Cull six salamander hatchlings and gather four shed snake scales from the slopes around the mountain camp.", 'n02K', 6, 20, "", 0, "The mountain camp has posted a bounty on the scaled pests nesting along its supply slopes.", "")
        call QuestsGeneric_AddFetchObjective(definitionId, 'j0b0', 4)
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The slopes should be safer, and these scales will serve the camp's healers.", 15)

        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Frenzy Below the Camp", "daily", 3, "Frenzy Below the Camp", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Kill eight frenzy gathering in the shallows below the Horde mountain camp.", 'n62G', 8, 20, "", 0, "The notice warns that a school of frenzy is making the lower water unsafe.", "")
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The lower water is passable again. Take the bounty.", 15)

        if missingScout != null then
            set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Lost on the North Slope", "normal", 4, "Lost on the North Slope", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Cull four salamander hatchlings and find the scout missing on the mountain camp's north slope.", 'n02K', 4, 35, "", 0, "A scout failed to return from the north slope after reporting nests close to the trail.", "")
            call QuestsGeneric_AddFindObjective(definitionId, GetUnitTypeId(missingScout), missingScoutName)
            call QuestsGeneric_SetObjectiveTargetUnit(definitionId, 2, missingScout)
            call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The scout is accounted for and the nearest nests are broken. Well done.", 25)
        endif

        call RegisterActors(wantedPost, receiver, receiverName, missingScout, missingScoutName, registerReceiverDialog)
        set wantedPost = null
        set receiver = null
        set missingScout = null
    endfunction

    public function ConfigureThornwoodsScoutBase takes unit wantedPost, unit receiver, string receiverName, unit missingCourier, string missingCourierName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanConfigureSign(wantedPost, ZONE_HORDE_SCOUT_BASE, receiver) then
            set wantedPost = null
            set receiver = null
            set missingCourier = null
            return
        endif
        set receiverName = ResolveName(receiver, receiverName)
        set missingCourierName = ResolveName(missingCourier, missingCourierName)

        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Tidecallers at the Ford", "daily", 7, "Tidecallers at the Ford", "ReplaceableTextures\\CommandButtons\\BTNMurloc.blp", "Defeat six murloc sorcerers or tidecallers threatening the ford near the Horde Scout Base.", 'n62A', 6, 35, "", 0, "The scouts have posted a bounty on the murloc spellcasters gathering at the ford.", "")
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'n62A')
        call QuestsGeneric_AddKillTargetCandidate(definitionId, 'n62B')
        call QuestsGeneric_SetKillTargetZone(definitionId, 6)
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The ford patrol saw the murlocs break. The bounty is yours.", 15)

        set definitionId = QuestsGeneric_RegisterFetchQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Stolen Scout Supplies", "repeatable", 6, "Stolen Scout Supplies", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Recover five bundles of gnoll pillage for the Horde Scout Base quartermaster.", 'I6A4', 5, 35, "", 0, "The notice offers payment for supplies recovered from Thornwoods gnolls.", "")
        call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "These stores still bear Horde marks. They are back where they belong.", 10)

        if missingCourier != null then
            set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "The Road to the Scout Base", "normal", 7, "The Road to the Scout Base", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Defeat eight gnoll ambushers and find the courier missing on the road to the Horde Scout Base.", 'ngno', 8, 50, "", 0, "A supply courier vanished after reporting gnoll movement along the road to the scout base.", "")
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'ngno')
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'ngnb')
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'ngna')
            call QuestsGeneric_AddKillTargetCandidate(definitionId, 'ngnw')
            call QuestsGeneric_SetKillTargetZone(definitionId, 6)
            call QuestsGeneric_AddFindObjective(definitionId, GetUnitTypeId(missingCourier), missingCourierName)
            call QuestsGeneric_SetObjectiveTargetUnit(definitionId, 2, missingCourier)
            call ConfigureDefinition(definitionId, wantedPost, receiver, receiverName, "The courier is found and the road has breathing room again. The scout base owes you.", 30)
        endif

        call RegisterActors(wantedPost, receiver, receiverName, missingCourier, missingCourierName, registerReceiverDialog)
        set wantedPost = null
        set receiver = null
        set missingCourier = null
    endfunction

    private function InitDelayed takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call ScanPreplacedSigns()
        call DestroyTimer(expiredTimer)
        set expiredTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set DiscoveredSign = Table.create()
        set SignZone = Table.create()
        set SignCountByZone = Table.create()
        set ConfiguredSign = Table.create()
        call TimerStart(initTimer, 0.00, false, function InitDelayed)
        set initTimer = null
    endfunction
endlibrary
