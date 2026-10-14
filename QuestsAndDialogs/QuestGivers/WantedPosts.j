/**
    WantedPosts

    Author: Valdemar
    Version: 1.0.1
    Status: Draft content - to be revisited and refined by zone and quest overall design.

    Description:
    Defines draft regional quest sets for the preplaced wanted posts at
    Mok'natha, Ironspine Post, the Sereneglade Horde mountain camp, and the
    Thornwoods Horde Scout Base. Every definition binds to one exact
    wanted-post unit and turns in at a separate preplaced receiver. The quest
    names, objectives, counts, rewards, cadence, and receivers remain subject
    to location-led design review.

    Credits:

    How to install:
    Import after QuestsGenericDialog and Table. Do not call these draft
    registration functions in the production map until the regional quest set
    has been reviewed and approved. In World Editor, preplace one 'n05N'
    wanted post, one receiver, and the optional missing-person target for each
    approved location. Call the matching registration function after generated
    unit globals exist. Pass true for registerReceiverDialog only when the
    receiver has no bespoke qXXX selection handler; custom dialogs must embed
    the QuestsGeneric button/action lifecycle themselves.

    API:
    - WantedPosts_RegisterMoknatha(...)
    - WantedPosts_RegisterIronspine(...)
    - WantedPosts_RegisterSerenegladeMountainCamp(...)
    - WantedPosts_RegisterThornwoodsScoutBase(...)

**/
library WantedPosts initializer Init requires QuestsGenericDialog, Table
    globals
        // Prevents duplicate definitions when map setup is invoked twice.
        private Table RegisteredPost = 0
    endglobals

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

    private function CanRegister takes unit wantedPost, unit receiver returns boolean
        local integer handleId

        if wantedPost == null or receiver == null or wantedPost == receiver or GetUnitTypeId(wantedPost) != QuestsGenericDialog_WANTED_POST_UNIT_TYPE then
            set wantedPost = null
            set receiver = null
            return false
        endif
        set handleId = GetHandleId(wantedPost)
        if RegisteredPost.boolean[handleId] then
            set wantedPost = null
            set receiver = null
            return false
        endif
        set RegisteredPost.boolean[handleId] = true
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
        call QuestsGenericDialog_RegisterWantedPost(wantedPost, "Wanted Post")
        set wantedPost = null
        set receiver = null
        set missingPerson = null
    endfunction

    public function RegisterMoknatha takes unit wantedPost, unit receiver, string receiverName, unit missingScout, string missingScoutName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanRegister(wantedPost, receiver) then
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

    public function RegisterIronspine takes unit wantedPost, unit receiver, string receiverName, unit missingWatcher, string missingWatcherName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanRegister(wantedPost, receiver) then
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

    public function RegisterSerenegladeMountainCamp takes unit wantedPost, unit receiver, string receiverName, unit missingScout, string missingScoutName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanRegister(wantedPost, receiver) then
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

    public function RegisterThornwoodsScoutBase takes unit wantedPost, unit receiver, string receiverName, unit missingCourier, string missingCourierName, boolean registerReceiverDialog returns nothing
        local integer definitionId

        if not CanRegister(wantedPost, receiver) then
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

    private function Init takes nothing returns nothing
        set RegisteredPost = Table.create()
    endfunction
endlibrary
