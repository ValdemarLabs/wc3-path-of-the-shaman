/**
    qRagno

    Author: Valdemar
    Version: 1.1.9

    Description:
    Implements Ragno's quest dialogue, daily outpost tasks, Protect the
    Outpost encounter, and the Call of the Horde letter handoff.

    Credits:
    Converted from the original Ragno GUI triggers.

    How to install:
    Import after qZulkis and the required quest, dialogue, cinematic, follow,
    loot, reputation, death-event, hero-item, fallen-hero, ambient-event, and
    voiceline libraries.

    API:
    Public quest-state hooks are declared at the end of this library.

**/
library qRagno initializer Init requires qZulkis, QuestGiver, QuestMaster, DialogInteraction, DialogSystem, CameraControl, CinematicMover, FollowSystem, HeroItemCheck, ItemLootSystem, Reputation, UnitDeathEvent, VoicelinesNazgrek, VoicelinesOrcGrunt, VoicelinesOrcPeon, FallenHeroState, HordeUnitsRandomChat

globals
    private constant boolean DEBUG = false

    public constant string QUEST_GIVING_LETTER = "Call of the Horde"
    public constant string QUEST_PROTECT_OUTPOST = "Protect the Outpost"
    public constant string QUEST_GNOLL_HEADCOUNT = "Gnoll Headcount"
    public constant string QUEST_LUMBERJACK_DUTIES = "Lumberjack Duties"
    public constant string QUEST_KOBOLD_THIEVES = "Kobold Thieves"
    public constant string QUEST_SATYR_NEGOTIATIONS = "Satyr Negotiations"
    public constant string QUEST_MOUNTAIN_DEFENSE = "Protect the Outpost"

    private constant integer ITEM_BLOOD_SIGNED_LETTER = 'I625'
    private constant integer ITEM_GNOLL_HEAD = 'I69A'
    private constant integer ITEM_PILE_WOOD = 'I60K'
    private constant integer ITEM_STOLEN_GOODS = 'I69B'

    private constant integer UNIT_RAGNO = 'o61L'
    private constant integer UNIT_GRUNT = 'ogru'
    private constant integer UNIT_GNOLL = 'ngno'
    private constant integer UNIT_GNOLL_BRUTE = 'ngnb'
    private constant integer UNIT_GNOLL_POACHER = 'ngna'
    private constant integer UNIT_GNOLL_WARDEN = 'ngnw'
    private constant integer UNIT_GNOLL_RAVAGER = 'n61A'
    private constant integer UNIT_GNOLL_CRUSHER = 'n626'
    private constant integer UNIT_KOBOLD_LEADER = 'n62T'
    private constant integer UNIT_LUMBER_PEON = 'opeo'
    private constant integer UNIT_LUMBER_RETURN = 'n62U'
    private constant integer DESTRUCT_STASH_QUEST = 'B61D'
    private constant integer DESTRUCT_LUMBER_TREE = 'LTlt'
    private constant integer DESTRUCT_LUMBER_TREE_ALT = 'B61E'
    private constant integer DESTRUCT_LUMBER_BLOCKER = 'B61F'

    private constant integer GNOLL_HEAD_REQUIRED = 20
    private constant integer PILE_WOOD_REQUIRED = 10
    private constant integer STOLEN_GOODS_REQUIRED = 6
    private constant integer GNOLL_HEAD_DROP_CHANCE = 2500
    private constant integer GNOLL_HEAD_DROP_WEIGHT = 80
    private constant integer KOBOLD_CHEST_ACTIVE_MAX = 6
    private constant integer KOBOLD_CHEST_SLOT_COUNT = 8
    private constant integer RAGNO_OWNER = 5
    private constant integer RAGNO_PLAYER_COLOR = 22
    private constant integer OUTPOST_GNOLL_OWNER = 11

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00

    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = true
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 1050.00
    private constant real CAMERA_Z_OFFSET = 20.00
    private constant real CAMERA_ANGLE = 350.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 60.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true
    private constant real LUMBER_NEAR_TREE_PERIOD = 0.20
    private constant real LUMBER_NEAR_TREE_RANGE = 250.00
    private constant real LUMBER_NEAR_TREE_RANGE_SQ = 62500.00
    private constant real LUMBER_HARVEST_ORDER_DELAY = 0.10
    private constant real LUMBER_HARVEST_DURATION = 10.00
    private constant real LUMBER_HARVEST_RETURN_DELAY = 1.00
    private constant real OUTPOST_WAVE_CHECK_PERIOD = 0.50
    private constant integer OUTPOST_SECOND_WAVE_LIVING_THRESHOLD = 2
    private constant real OUTPOST_INTRO_GRUNT_RESPONSE_DELAY = 4.00
    private constant real OUTPOST_CINEMATIC_FADE_DURATION = 1.00
    private constant real OUTPOST_CINEMATIC_END_FADE_DURATION = 0.50
    private constant real OUTPOST_PET_DISTANCE = 120.00
    private constant real OUTPOST_PET_ANGLE_OFFSET = -90.00
    private constant real OUTPOST_RAGNO_CONVERSATION_DISTANCE = 140.00
    private constant real OUTPOST_RAGNO_CONVERSATION_MOVE_WAIT = 5.00
    private constant real OUTPOST_COMPLETION_PERIOD = 2.00
    private constant real OUTPOST_COMPLETION_RESPAWN_REVEAL_DELAY = 2.05
    private constant real OUTPOST_COMPLETION_RESPAWN_DIALOG_DELAY = 2.25

    private unit Ragno = null
    private unit Thork = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit SelectedHero = null
    private unit LumberPeon = null
    private unit ProtectOutpostGruntPick = null
    private unit ProtectOutpostCameraTarget = null

    private dialog RagnoDialog = null
    private timer RagnoDialogCooldown = null
    private timer KoboldChestTimer = null
    private timer LumberPeonChatTimer = null
    private timer LumberPeonNearTreeTimer = null
    private timer LumberPeonWanderTimer = null
    private timer LumberPeonHarvestOrderTimer = null
    private timer LumberPeonHarvestTimer = null
    private timer LumberPeonReturnTimer = null
    private timer ProtectOutpostSecondWaveTimer = null
    private timer ProtectOutpostCompletionTimer = null
    private timer ProtectOutpostIntroCameraAssistTimer = null
    private timer ProtectOutpostIntroCameraReturnTimer = null
    private timer ProtectOutpostCompletionDelayTimer = null
    private timer ProtectOutpostLetterDelayTimer = null
    private timer ProtectOutpostRagnoRespawnTimer = null
    private trigger KoboldChestDeathTrigger = null
    private trigger LumberPeonDeathTrigger = null
    private trigger LumberPeonOrderTrigger = null
    private trigger ProtectOutpostStartTrigger = null
    private group ProtectOutpostGnolls = null
    private group ProtectOutpostGrunts = null
    private group ProtectOutpostHiddenGnolls = null
    private group ProtectOutpostEnumGroup = null
    private rect LumberPeonScanRect = null
    private destructable array KoboldChest
    private destructable LumberPeonTreePick = null
    private destructable LumberPeonHarvestTree = null
    private unit LumberReturnUnit = null
    private integer KoboldChestCount = 0
    private integer ProtectOutpostLivingGnolls = 0
    private boolean KoboldLeaderKilled = false
    private boolean SatyrNegotiationsReady = false
    private boolean GivingLetterUnlocked = false
    private boolean MountainDefenseActive = false
    private boolean ProtectOutpostStarted = false
    private boolean ProtectOutpostIntroFinished = false
    private boolean ProtectOutpostCompleted = false
    private boolean ProtectOutpostSecondWaveSpawned = false
    private boolean ProtectOutpostRagnoRespawnPending = false
    private boolean ProtectOutpostCinematicUnitsMoved = false
    private boolean LumberPeonHarvestOrderPending = false
    private boolean LumberPeonHarvesting = false
    private boolean RagnoGreeted = false
    private boolean RagnoInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qRagno]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Ragno != null and udg_Ragno != Ragno then
        set Ragno = udg_Ragno
    endif
    if udg_Thork != null and udg_Thork != Thork then
        set Thork = udg_Thork
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    local unit hero
    call SyncUnitReferences()
    set hero = DialogInteraction_ResolveDialogHero(SelectedHero, Ragno, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if hero == null and DialogInteraction_IsUnitAlive(Nazgrek) then
        set hero = Nazgrek
    endif
    return hero
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogSystem_ClearEscapeAction()
    call DialogInteraction_StartConfiguredDialogExitTransition(Ragno, SelectedHero, RagnoDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function OnRagnoEscape takes nothing returns nothing
    call DialogSystem_ClearEscapeAction()
    call DialogInteraction_CloseActiveDialog()
    call StartExitFadeOut()
endfunction

private function GetRagnoQuest takes string questName returns QuestData
    call SyncUnitReferences()
    if Ragno == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(questName, Ragno)
endfunction

private function SetRagnoQuestBaseRequirements takes QuestData q, string r1, string r2, string r3, string r4 returns nothing
    if q == 0 then
        return
    endif

    set q.requirementHeading = ""
    set q.requirement1 = r1
    set q.requirement2 = r2
    set q.requirement3 = r3
    set q.requirement4 = r4
    set q.requirement5 = ""
    set q.requirement6 = ""
    set q.requirement7 = ""
    set q.requirement8 = ""

    call q.updateRequirementText(1, r1)
    call q.updateRequirementText(2, r2)
    call q.updateRequirementText(3, r3)
    call q.updateRequirementText(4, r4)
    call q.updateRequirementText(5, "")
    call q.updateRequirementText(6, "")
    call q.updateRequirementText(7, "")
    call q.updateRequirementText(8, "")
    call q.refreshQuestLog()
endfunction

private function RestoreBaseRequirements takes QuestData q returns nothing
    if q == 0 then
        return
    endif

    if q.name == QUEST_GNOLL_HEADCOUNT then
        call SetRagnoQuestBaseRequirements(q, "Bring 20 Gnoll Heads to Ragno", "", "", "")
    elseif q.name == QUEST_LUMBERJACK_DUTIES then
        call SetRagnoQuestBaseRequirements(q, "Harvest 10 Pile Of Wood", "Peon must survive", "", "")
    elseif q.name == QUEST_KOBOLD_THIEVES then
        call SetRagnoQuestBaseRequirements(q, "Kill Razzlewhip Mudgrubber", "Retrieve 6 Stolen Goods", "", "")
    elseif q.name == QUEST_SATYR_NEGOTIATIONS then
        call SetRagnoQuestBaseRequirements(q, "Meet with the satyrs and learn what they want", "", "", "")
    elseif q.name == QUEST_PROTECT_OUTPOST then
        call SetRagnoQuestBaseRequirements(q, "Protect the mountain outpost from the gnoll attack", "", "", "")
    elseif q.name == QUEST_GIVING_LETTER then
        call SetRagnoQuestBaseRequirements(q, "Take the Blood Signed Summon Letter to Chieftain Thork", "", "", "")
    endif
endfunction

private function ClearQuestProgress takes QuestData q returns nothing
    if q == 0 then
        return
    endif

    set q.active = false
    set q.completed = false
    set q.discovered = false
    set q.failed = false
    set q.req1Completed = false
    set q.req2Completed = false
    set q.req3Completed = false
    set q.req4Completed = false
    set q.req5Completed = false
    set q.req6Completed = false
    set q.req7Completed = false
    set q.req8Completed = false
    set q.hasReturnReq = false
    set q.returnReqIndex = 0

    if q.wcQuest != null then
        call DestroyQuest(q.wcQuest)
    endif
    set q.wcQuest = null
    set q.req1 = null
    set q.req2 = null
    set q.req3 = null
    set q.req4 = null
    set q.req5 = null
    set q.req6 = null
    set q.req7 = null
    set q.req8 = null
    call q.markRequirementCompleted(1, false)
    call q.markRequirementCompleted(2, false)
    call q.markRequirementCompleted(3, false)
    call q.markRequirementCompleted(4, false)
    call q.markRequirementCompleted(5, false)
    call q.markRequirementCompleted(6, false)
    call q.markRequirementCompleted(7, false)
    call q.markRequirementCompleted(8, false)
    call RestoreBaseRequirements(q)
    call q.setState(QUEST_STATE_AVAILABLE)
endfunction

private function PrepareRepeatableForDialog takes string questName returns nothing
    local QuestData q = GetRagnoQuest(questName)
    if q != 0 and q.failed then
        call ClearQuestProgress(q)
    endif
    set q = 0
endfunction

private function RefreshQuestAfterAccept takes string questName returns nothing
    local QuestData q = GetRagnoQuest(questName)
    if q != 0 then
        call QuestGiver_RefreshItemRequirementsForQuest(q.id)
    endif
    set q = 0
endfunction

private function CanOfferGivingLetter takes nothing returns boolean
    return GivingLetterUnlocked and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno)
endfunction

private function CanOfferProtectOutpost takes nothing returns boolean
    return false
endfunction

private function IsRagnoDialogEnabled takes nothing returns boolean
    return not MountainDefenseActive
endfunction

private function RestorePostOutpostQuestAvailability takes string questName returns nothing
    local QuestData q = GetRagnoQuest(questName)

    if q != 0 and (ProtectOutpostCompleted or QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno)) and not q.active and not q.completed and not q.failed then
        if q.discovered then
            call q.setDiscovered(false)
        endif
        if q.state != QUEST_STATE_AVAILABLE then
            call q.setState(QUEST_STATE_AVAILABLE)
            call DebugMsg("Restored post-outpost availability for " + questName + ".")
        endif
    endif

    set q = 0
endfunction

private function ApplyRagnoQuestAccessRule takes string questName returns nothing
    local QuestData q = GetRagnoQuest(questName)

    if q != 0 then
        call QuestGiver_SetQuestRequiredReputation(q, Reputation_REP_ENEMY)
    endif

    set q = 0
endfunction

private function RefreshRagnoAvailabilityInternal takes nothing returns nothing
    if Ragno == null then
        return
    endif

    call QuestGiver_RefreshAvailabilityForGiver(Ragno)
    call RestorePostOutpostQuestAvailability(QUEST_GNOLL_HEADCOUNT)
    call RestorePostOutpostQuestAvailability(QUEST_LUMBERJACK_DUTIES)
    call RestorePostOutpostQuestAvailability(QUEST_KOBOLD_THIEVES)
    call RestorePostOutpostQuestAvailability(QUEST_SATYR_NEGOTIATIONS)
    if QuestGiver_QuestExistsByNameAndGiver(QUEST_GIVING_LETTER, Ragno) and not GivingLetterUnlocked and not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_GIVING_LETTER, Ragno) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_GIVING_LETTER, Ragno) then
        call QuestGiver_SetStateByNameAndGiver(QUEST_GIVING_LETTER, Ragno, QUEST_STATE_UNAVAILABLE)
    endif
endfunction

private function UnlockGivingLetterInternal takes nothing returns nothing
    local QuestData q

    call SyncUnitReferences()
    if Ragno == null or Thork == null or not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno) then
        return
    endif

    set GivingLetterUnlocked = true
    call RefreshRagnoAvailabilityInternal()
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_GIVING_LETTER, Ragno)
    set q = GetRagnoQuest(QUEST_GIVING_LETTER)
    if q != 0 and not q.completed then
        call QuestGiver_GiveUniqueQuestItemToHero(Nazgrek, ITEM_BLOOD_SIGNED_LETTER, 0, "Blood Signed Summon Letter")
        call q.setState(QUEST_STATE_READY_TURNIN)
    endif

    set q = 0
endfunction

private function RefreshKoboldTurnInState takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_KOBOLD_THIEVES)
    if q != 0 and q.active and not q.completed and not q.failed then
        if KoboldLeaderKilled and HeroItemCheckBoth(ITEM_STOLEN_GOODS, STOLEN_GOODS_REQUIRED) then
            call q.markRequirementCompleted(1, true)
            call q.markRequirementCompleted(2, true)
            if q.state != QUEST_STATE_READY_TURNIN then
                call q.setState(QUEST_STATE_READY_TURNIN)
                call q.addReturnRequirement()
            endif
        elseif q.state == QUEST_STATE_READY_TURNIN then
            call q.setState(QUEST_STATE_IN_PROGRESS)
        endif
    endif
    set q = 0
endfunction

private function CanCompleteKoboldThieves takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_KOBOLD_THIEVES)
    local boolean result = false
    if q != 0 and q.active and not q.completed and not q.failed then
        set result = KoboldLeaderKilled and HeroItemCheckBoth(ITEM_STOLEN_GOODS, STOLEN_GOODS_REQUIRED)
    endif
    set q = 0
    return result
endfunction

private function CanCompleteSatyrNegotiations takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    local boolean result = false
    if q != 0 and q.active and not q.completed and not q.failed then
        set result = SatyrNegotiationsReady or q.state == QUEST_STATE_READY_TURNIN
    endif
    set q = 0
    return result
endfunction

private function RefreshZaekolaerrAvailabilityExternal takes nothing returns nothing
    call ExecuteFunc("qZaekolaerr_RefreshAvailability")
endfunction

private function GetKoboldChestRect takes integer index returns rect
    if index == 1 then
        return gg_rct_KoboldsChest01
    elseif index == 2 then
        return gg_rct_KoboldsChest02
    elseif index == 3 then
        return gg_rct_KoboldsChest03
    elseif index == 4 then
        return gg_rct_KoboldsChest04
    elseif index == 5 then
        return gg_rct_KoboldsChest05
    elseif index == 6 then
        return gg_rct_KoboldsChest06
    elseif index == 7 then
        return gg_rct_KoboldsChest07
    elseif index == 8 then
        return gg_rct_KoboldsChest08
    endif
    return null
endfunction

private function RemoveKoboldChestAtIndex takes integer index returns nothing
    if index < 1 or index > KOBOLD_CHEST_SLOT_COUNT then
        return
    endif
    if KoboldChest[index] != null then
        call RemoveDestructable(KoboldChest[index])
        set KoboldChest[index] = null
        if KoboldChestCount > 0 then
            set KoboldChestCount = KoboldChestCount - 1
        endif
    endif
endfunction

private function ClearKoboldChests takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > KOBOLD_CHEST_SLOT_COUNT
        call RemoveKoboldChestAtIndex(i)
        set i = i + 1
    endloop
    set KoboldChestCount = 0
endfunction

private function SpawnKoboldChestSlot takes integer slot returns boolean
    local rect r
    local destructable d

    if slot < 1 or slot > KOBOLD_CHEST_SLOT_COUNT then
        return false
    endif
    if KoboldChest[slot] != null then
        return false
    endif

    set r = GetKoboldChestRect(slot)
    if r == null then
        set r = null
        return false
    endif

    set d = CreateDestructable(DESTRUCT_STASH_QUEST, GetRectCenterX(r), GetRectCenterY(r), GetRandomReal(0.00, 360.00), 1.70, 0)
    if d == null then
        set r = null
        set d = null
        return false
    endif

    set KoboldChest[slot] = d
    set KoboldChestCount = KoboldChestCount + 1
    call TriggerRegisterDeathEvent(KoboldChestDeathTrigger, d)

    set r = null
    set d = null
    return true
endfunction

private function SpawnRandomKoboldChest takes nothing returns nothing
    local integer attempts = 0
    local integer slot

    if KoboldChestCount >= KOBOLD_CHEST_ACTIVE_MAX then
        return
    endif

    loop
        exitwhen attempts >= 12
        set slot = GetRandomInt(1, KOBOLD_CHEST_SLOT_COUNT)
        if SpawnKoboldChestSlot(slot) then
            return
        endif
        set attempts = attempts + 1
    endloop
endfunction

private function OnKoboldChestDeath takes nothing returns nothing
    local destructable d = GetTriggerDestructable()
    local integer i = 1
    local real x
    local real y

    loop
        exitwhen i > KOBOLD_CHEST_SLOT_COUNT
        if KoboldChest[i] == d then
            set x = GetDestructableX(d)
            set y = GetDestructableY(d)
            set KoboldChest[i] = null
            if KoboldChestCount > 0 then
                set KoboldChestCount = KoboldChestCount - 1
            endif
            if GetRandomInt(1, 2) == 1 then
                call CreateItem(ITEM_STOLEN_GOODS, x, y)
            endif
            call RemoveDestructable(d)
            set d = null
            return
        endif
        set i = i + 1
    endloop

    set d = null
endfunction

private function OnKoboldChestTimer takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_KOBOLD_THIEVES)
    if q != 0 and q.active and not q.completed and not q.failed then
        call SpawnRandomKoboldChest()
        call TimerStart(KoboldChestTimer, GetRandomReal(30.00, 100.00), false, function OnKoboldChestTimer)
    endif
    set q = 0
endfunction

private function StartKoboldChests takes nothing returns nothing
    if KoboldChestTimer == null then
        set KoboldChestTimer = CreateTimer()
    endif
    if KoboldChestDeathTrigger == null then
        set KoboldChestDeathTrigger = CreateTrigger()
        call TriggerAddAction(KoboldChestDeathTrigger, function OnKoboldChestDeath)
    endif
    call ClearKoboldChests()
    call SpawnRandomKoboldChest()
    call TimerStart(KoboldChestTimer, GetRandomReal(30.00, 100.00), false, function OnKoboldChestTimer)
endfunction

private function StopKoboldChests takes boolean removeExisting returns nothing
    if KoboldChestTimer != null then
        call PauseTimer(KoboldChestTimer)
    endif
    if removeExisting then
        call ClearKoboldChests()
    endif
endfunction

private function IsLumberjackQuestActive takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_LUMBERJACK_DUTIES)
    local boolean result = q != 0 and q.active and not q.completed and not q.failed
    set q = 0
    return result
endfunction

private function QueueLumberPeonLine takes string soundKey, string text returns nothing
    if DialogInteraction_IsUnitAlive(LumberPeon) then
        call DialogSystem_QueueFieldLine(LumberPeon, "Peon", soundKey, text)
    endif
endfunction

private function QueueRandomLumberPeonChat takes nothing returns nothing
    local integer roll = GetRandomInt(1, 7)
    if roll == 1 then
        call QueueLumberPeonLine(VL_ORCPEON_0001_KEY, VL_ORCPEON_0001_TEXT)
    elseif roll == 2 then
        call QueueLumberPeonLine(VL_ORCPEON_0002_KEY, VL_ORCPEON_0002_TEXT)
    elseif roll == 3 then
        call QueueLumberPeonLine(VL_ORCPEON_0003_KEY, VL_ORCPEON_0003_TEXT)
    elseif roll == 4 then
        call QueueLumberPeonLine(VL_ORCPEON_0004_KEY, VL_ORCPEON_0004_TEXT)
    elseif roll == 5 then
        call QueueLumberPeonLine(VL_ORCPEON_0006_KEY, VL_ORCPEON_0006_TEXT)
    elseif roll == 6 then
        call QueueLumberPeonLine(VL_ORCPEON_0007_KEY, VL_ORCPEON_0007_TEXT)
    else
        call QueueLumberPeonLine(VL_ORCPEON_0008_KEY, VL_ORCPEON_0008_TEXT)
    endif
endfunction

private function OnLumberPeonChatTimer takes nothing returns nothing
    if IsLumberjackQuestActive() and DialogInteraction_IsUnitAlive(LumberPeon) and not LumberPeonHarvesting and not DialogSystem_IsSequenceActive() then
        call QueueRandomLumberPeonChat()
    endif
    if LumberPeonChatTimer != null and IsLumberjackQuestActive() then
        call TimerStart(LumberPeonChatTimer, GetRandomReal(30.00, 200.00), false, function OnLumberPeonChatTimer)
    endif
endfunction

private function IsLumberjackTree takes destructable d returns boolean
    local integer typeId
    if d == null then
        return false
    endif
    set typeId = GetDestructableTypeId(d)
    return typeId == DESTRUCT_LUMBER_TREE or typeId == DESTRUCT_LUMBER_TREE_ALT
endfunction

private function ResetLumberjackDestructableEnum takes nothing returns nothing
    local destructable d = GetEnumDestructable()

    if d == null then
        return
    endif
    if IsLumberjackTree(d) then
        if GetDestructableLife(d) <= 0.405 then
            call DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
        endif
    elseif GetDestructableTypeId(d) == DESTRUCT_LUMBER_BLOCKER then
        call RemoveDestructable(d)
    endif

    set d = null
endfunction

private function ResetLumberjackTrees takes nothing returns nothing
    call EnumDestructablesInRect(bj_mapInitialPlayableArea, null, function ResetLumberjackDestructableEnum)
endfunction

private function StopLumberTimers takes nothing returns nothing
    if LumberPeonChatTimer != null then
        call PauseTimer(LumberPeonChatTimer)
    endif
    if LumberPeonNearTreeTimer != null then
        call PauseTimer(LumberPeonNearTreeTimer)
    endif
    if LumberPeonWanderTimer != null then
        call PauseTimer(LumberPeonWanderTimer)
    endif
    if LumberPeonHarvestOrderTimer != null then
        call PauseTimer(LumberPeonHarvestOrderTimer)
    endif
    if LumberPeonHarvestTimer != null then
        call PauseTimer(LumberPeonHarvestTimer)
    endif
    if LumberPeonReturnTimer != null then
        call PauseTimer(LumberPeonReturnTimer)
    endif
endfunction

private function DestroyLumberTriggers takes nothing returns nothing
    if LumberPeonDeathTrigger != null then
        call DestroyTrigger(LumberPeonDeathTrigger)
        set LumberPeonDeathTrigger = null
    endif
    if LumberPeonOrderTrigger != null then
        call DestroyTrigger(LumberPeonOrderTrigger)
        set LumberPeonOrderTrigger = null
    endif
endfunction

private function CleanupLumberjackRuntime takes boolean removePeon returns nothing
    call StopLumberTimers()
    call DestroyLumberTriggers()
    set LumberPeonHarvestOrderPending = false
    set LumberPeonHarvesting = false
    set LumberPeonTreePick = null
    set LumberPeonHarvestTree = null
    if LumberReturnUnit != null then
        call RemoveUnit(LumberReturnUnit)
        set LumberReturnUnit = null
    endif
    if LumberPeon != null then
        call FollowSystem_RemoveUnit(LumberPeon)
        if removePeon then
            call RemoveUnit(LumberPeon)
            set LumberPeon = null
        endif
    endif
    call ResetLumberjackTrees()
endfunction

private function OnLumberPeonDies takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_LUMBERJACK_DUTIES)
    if q != 0 and q.active and not q.completed and not q.failed then
        call CleanupLumberjackRuntime(false)
        call QuestGiver_FailQuestByNameAndGiver(QUEST_LUMBERJACK_DUTIES, Ragno, "The lumber peon was slain.")
        call RefreshRagnoAvailabilityInternal()
    endif
    set q = 0
endfunction

private function OnLumberHarvestResume takes nothing returns nothing
    set LumberPeonHarvestOrderPending = false
    set LumberPeonHarvesting = false
    set LumberPeonHarvestTree = null
    if LumberReturnUnit != null then
        call RemoveUnit(LumberReturnUnit)
        set LumberReturnUnit = null
    endif
    if DialogInteraction_IsUnitAlive(LumberPeon) then
        call IssueImmediateOrder(LumberPeon, "stop")
        if IsLumberjackQuestActive() and DialogInteraction_IsUnitAlive(Nazgrek) then
            call FollowSystem_SetFollow(LumberPeon, Nazgrek, 1200.00, true, 5.00, FOLLOW_STYLE_PASSIVE, true, true)
        endif
    endif
endfunction

private function QueueLumberHarvestResultLine takes boolean goodWood returns nothing
    local integer roll
    if goodWood then
        call QueueLumberPeonLine(VL_ORCPEON_0011_KEY, VL_ORCPEON_0011_TEXT)
    else
        set roll = GetRandomInt(1, 3)
        if roll == 1 then
            call QueueLumberPeonLine(VL_ORCPEON_0012_KEY, VL_ORCPEON_0012_TEXT)
        elseif roll == 2 then
            call QueueLumberPeonLine(VL_ORCPEON_0013_KEY, VL_ORCPEON_0013_TEXT)
        else
            call QueueLumberPeonLine(VL_ORCPEON_0014_KEY, VL_ORCPEON_0014_TEXT)
        endif
    endif
endfunction

private function OnLumberHarvestComplete takes nothing returns nothing
    local destructable target = LumberPeonHarvestTree
    local real x
    local real y
    local boolean goodWood

    if not IsLumberjackQuestActive() or not DialogInteraction_IsUnitAlive(LumberPeon) or target == null or GetDestructableLife(target) <= 0.405 then
        set target = null
        call OnLumberHarvestResume()
        return
    endif

    set x = GetDestructableX(target)
    set y = GetDestructableY(target)
    call KillDestructable(target)
    call CreateDestructable(DESTRUCT_LUMBER_BLOCKER, x, y, GetRandomReal(0.00, 360.00), 1.00, 0)

    set goodWood = GetRandomInt(1, 2) == 1
    if goodWood then
        call CreateItem(ITEM_PILE_WOOD, GetUnitX(LumberPeon), GetUnitY(LumberPeon))
    endif
    call QueueLumberHarvestResultLine(goodWood)

    if LumberReturnUnit != null then
        call RemoveUnit(LumberReturnUnit)
    endif
    set LumberReturnUnit = CreateUnit(Player(1), UNIT_LUMBER_RETURN, GetUnitX(LumberPeon), GetUnitY(LumberPeon), bj_UNIT_FACING)
    if LumberReturnUnit != null then
        call IssueTargetOrder(LumberPeon, "smart", LumberReturnUnit)
    endif
    if LumberPeonReturnTimer == null then
        set LumberPeonReturnTimer = CreateTimer()
    endif
    call TimerStart(LumberPeonReturnTimer, LUMBER_HARVEST_RETURN_DELAY, false, function OnLumberHarvestResume)
    call RefreshQuestAfterAccept(QUEST_LUMBERJACK_DUTIES)

    set target = null
endfunction

private function OnLumberPeonOrder takes nothing returns nothing
    local destructable target = GetOrderTargetDestructable()
    local QuestData q

    if GetTriggerUnit() != LumberPeon or target == null or LumberPeonHarvesting then
        set target = null
        return
    endif
    if GetIssuedOrderId() != OrderId("harvest") and GetIssuedOrderId() != OrderId("smart") then
        set target = null
        return
    endif
    if not IsLumberjackTree(target) or GetDestructableLife(target) <= 0.405 then
        set target = null
        return
    endif

    set q = GetRagnoQuest(QUEST_LUMBERJACK_DUTIES)
    if q == 0 or not q.active or q.completed or q.failed then
        set target = null
        set q = 0
        return
    endif

    set LumberPeonHarvestOrderPending = false
    set LumberPeonHarvesting = true
    set LumberPeonHarvestTree = target
    call FollowSystem_RemoveUnit(LumberPeon)
    call QueueLumberPeonLine(VL_ORCPEON_0009_KEY, VL_ORCPEON_0009_TEXT)
    call QueueLumberPeonLine(VL_ORCPEON_0010_KEY, VL_ORCPEON_0010_TEXT)
    if LumberPeonHarvestTimer == null then
        set LumberPeonHarvestTimer = CreateTimer()
    endif
    call TimerStart(LumberPeonHarvestTimer, LUMBER_HARVEST_DURATION, false, function OnLumberHarvestComplete)

    set target = null
    set q = 0
endfunction

private function OnLumberPeonHarvestOrder takes nothing returns nothing
    local destructable target = LumberPeonHarvestTree

    set LumberPeonHarvestOrderPending = false
    if not IsLumberjackQuestActive() or not DialogInteraction_IsUnitAlive(LumberPeon) or target == null or GetDestructableLife(target) <= 0.405 then
        set target = null
        call OnLumberHarvestResume()
        return
    endif

    if not IssueTargetDestructableOrder(LumberPeon, "harvest", target) then
        call OnLumberHarvestResume()
    endif
    set target = null
endfunction

private function PickNearbyLumberTreeEnum takes nothing returns nothing
    local destructable d = GetEnumDestructable()
    local real dx
    local real dy

    if LumberPeonTreePick != null or d == null then
        set d = null
        return
    endif
    if not IsLumberjackTree(d) or GetDestructableLife(d) <= 0.405 then
        set d = null
        return
    endif

    set dx = GetDestructableX(d) - GetUnitX(LumberPeon)
    set dy = GetDestructableY(d) - GetUnitY(LumberPeon)
    if dx * dx + dy * dy <= LUMBER_NEAR_TREE_RANGE_SQ then
        set LumberPeonTreePick = d
    endif

    set d = null
endfunction

private function OnLumberPeonNearTreeTimer takes nothing returns nothing
    local real x
    local real y

    if not IsLumberjackQuestActive() or not DialogInteraction_IsUnitAlive(LumberPeon) or LumberPeonHarvestOrderPending or LumberPeonHarvesting then
        return
    endif
    if not DialogInteraction_IsUnitAlive(Nazgrek) or not IsUnitInRange(LumberPeon, Nazgrek, LUMBER_NEAR_TREE_RANGE) then
        return
    endif

    set x = GetUnitX(LumberPeon)
    set y = GetUnitY(LumberPeon)
    set LumberPeonTreePick = null
    call SetRect(LumberPeonScanRect, x - LUMBER_NEAR_TREE_RANGE, y - LUMBER_NEAR_TREE_RANGE, x + LUMBER_NEAR_TREE_RANGE, y + LUMBER_NEAR_TREE_RANGE)
    call EnumDestructablesInRect(LumberPeonScanRect, null, function PickNearbyLumberTreeEnum)
    if LumberPeonTreePick != null then
        set LumberPeonHarvestOrderPending = true
        set LumberPeonHarvestTree = LumberPeonTreePick
        call FollowSystem_RemoveUnit(LumberPeon)
        call IssueImmediateOrder(LumberPeon, "stop")
        set LumberPeonTreePick = null
        if LumberPeonHarvestOrderTimer == null then
            set LumberPeonHarvestOrderTimer = CreateTimer()
        endif
        call TimerStart(LumberPeonHarvestOrderTimer, LUMBER_HARVEST_ORDER_DELAY, false, function OnLumberPeonHarvestOrder)
    endif
endfunction

private function StartLumberjackRuntime takes nothing returns nothing
    local real x
    local real y

    call CleanupLumberjackRuntime(true)
    set x = GetRectCenterX(gg_rct_LumberPeonSpawn)
    set y = GetRectCenterY(gg_rct_LumberPeonSpawn)
    set LumberPeon = CreateUnit(Player(1), UNIT_LUMBER_PEON, x, y, 345.00)
    if LumberPeon == null then
        call DebugMsg("Failed to create lumber peon.")
        return
    endif

    call IssuePointOrder(LumberPeon, "move", GetRectCenterX(gg_rct_LumberPeonMove), GetRectCenterY(gg_rct_LumberPeonMove))
    if DialogInteraction_IsUnitAlive(Nazgrek) then
        call FollowSystem_SetFollow(LumberPeon, Nazgrek, 1200.00, true, 5.00, FOLLOW_STYLE_PASSIVE, true, true)
    endif

    set LumberPeonDeathTrigger = CreateTrigger()
    call TriggerRegisterUnitEvent(LumberPeonDeathTrigger, LumberPeon, EVENT_UNIT_DEATH)
    call TriggerAddAction(LumberPeonDeathTrigger, function OnLumberPeonDies)

    set LumberPeonOrderTrigger = CreateTrigger()
    call TriggerRegisterUnitEvent(LumberPeonOrderTrigger, LumberPeon, EVENT_UNIT_ISSUED_TARGET_ORDER)
    call TriggerAddAction(LumberPeonOrderTrigger, function OnLumberPeonOrder)

    if LumberPeonChatTimer == null then
        set LumberPeonChatTimer = CreateTimer()
    endif
    if LumberPeonNearTreeTimer == null then
        set LumberPeonNearTreeTimer = CreateTimer()
    endif
    if LumberPeonScanRect == null then
        set LumberPeonScanRect = Rect(0.00, 0.00, 1.00, 1.00)
    endif
    call TimerStart(LumberPeonNearTreeTimer, LUMBER_NEAR_TREE_PERIOD, true, function OnLumberPeonNearTreeTimer)
    call TimerStart(LumberPeonChatTimer, GetRandomReal(30.00, 200.00), false, function OnLumberPeonChatTimer)
endfunction

private function AddLumberPeonIntroLines takes integer seq returns nothing
    if DialogInteraction_IsUnitAlive(LumberPeon) then
        call DialogSystem_AddDelay(seq, 2.00)
        call DialogSystem_AddLine(seq, LumberPeon, "Peon", VL_ORCPEON_0016_TEXT, VL_ORCPEON_0016_KEY, true)
        call DialogSystem_AddLine(seq, LumberPeon, "Peon", VL_ORCPEON_0005_TEXT, VL_ORCPEON_0005_KEY, true)
        call DialogSystem_AddLine(seq, LumberPeon, "Peon", VL_ORCPEON_0017_TEXT, VL_ORCPEON_0017_KEY, true)
    endif
endfunction

private function RegisterBaseGnollHeadDrops takes nothing returns nothing
    call RegisterSpecificDrop(UNIT_GNOLL, ITEM_GNOLL_HEAD, GNOLL_HEAD_DROP_CHANCE, false, GNOLL_HEAD_DROP_WEIGHT)
    call RegisterSpecificDrop(UNIT_GNOLL_BRUTE, ITEM_GNOLL_HEAD, GNOLL_HEAD_DROP_CHANCE, false, GNOLL_HEAD_DROP_WEIGHT)
    call RegisterSpecificDrop(UNIT_GNOLL_POACHER, ITEM_GNOLL_HEAD, GNOLL_HEAD_DROP_CHANCE, false, GNOLL_HEAD_DROP_WEIGHT)
    call RegisterSpecificDrop(UNIT_GNOLL_WARDEN, ITEM_GNOLL_HEAD, GNOLL_HEAD_DROP_CHANCE, false, GNOLL_HEAD_DROP_WEIGHT)
endfunction

private function EnsureProtectOutpostRuntime takes nothing returns nothing
    if ProtectOutpostGnolls == null then
        set ProtectOutpostGnolls = CreateGroup()
    endif
    if ProtectOutpostGrunts == null then
        set ProtectOutpostGrunts = CreateGroup()
    endif
    if ProtectOutpostHiddenGnolls == null then
        set ProtectOutpostHiddenGnolls = CreateGroup()
    endif
    if ProtectOutpostEnumGroup == null then
        set ProtectOutpostEnumGroup = CreateGroup()
    endif
    if ProtectOutpostSecondWaveTimer == null then
        set ProtectOutpostSecondWaveTimer = CreateTimer()
    endif
    if ProtectOutpostCompletionTimer == null then
        set ProtectOutpostCompletionTimer = CreateTimer()
    endif
    if ProtectOutpostIntroCameraAssistTimer == null then
        set ProtectOutpostIntroCameraAssistTimer = CreateTimer()
    endif
    if ProtectOutpostIntroCameraReturnTimer == null then
        set ProtectOutpostIntroCameraReturnTimer = CreateTimer()
    endif
    if ProtectOutpostCompletionDelayTimer == null then
        set ProtectOutpostCompletionDelayTimer = CreateTimer()
    endif
    if ProtectOutpostLetterDelayTimer == null then
        set ProtectOutpostLetterDelayTimer = CreateTimer()
    endif
    if ProtectOutpostRagnoRespawnTimer == null then
        set ProtectOutpostRagnoRespawnTimer = CreateTimer()
    endif
endfunction

private function PickProtectOutpostGruntEnum takes nothing returns nothing
    local unit u = GetEnumUnit()

    if DialogInteraction_IsUnitAlive(u) and GetUnitTypeId(u) == UNIT_GRUNT then
        call GroupAddUnit(ProtectOutpostGrunts, u)
    endif

    set u = null
endfunction

private function SelectProtectOutpostGrunts takes nothing returns nothing
    call EnsureProtectOutpostRuntime()
    call GroupClear(ProtectOutpostGrunts)
    call GroupClear(ProtectOutpostEnumGroup)
    call GroupEnumUnitsInRect(ProtectOutpostEnumGroup, gg_rct_HordeMountainCampSouth, null)
    call ForGroup(ProtectOutpostEnumGroup, function PickProtectOutpostGruntEnum)
    call GroupClear(ProtectOutpostEnumGroup)
endfunction

private function PickProtectOutpostSurvivingGruntEnum takes nothing returns nothing
    local unit u = GetEnumUnit()

    if ProtectOutpostGruntPick == null and DialogInteraction_IsUnitAlive(u) then
        set ProtectOutpostGruntPick = u
    endif

    set u = null
endfunction

private function GetProtectOutpostSurvivingGrunt takes nothing returns unit
    set ProtectOutpostGruntPick = null
    if ProtectOutpostGrunts != null then
        call ForGroup(ProtectOutpostGrunts, function PickProtectOutpostSurvivingGruntEnum)
    endif
    return ProtectOutpostGruntPick
endfunction

private function MovePlayerUnitsToProtectOutpostCinematic takes rect sceneCenterRect, rect nazgrekRect returns nothing
    local location centerPoint = null
    local location nazgrekPoint = null
    local location zulkisPoint = null

    set ProtectOutpostCinematicUnitsMoved = false
    if not DialogInteraction_IsUnitAlive(Nazgrek) or sceneCenterRect == null or nazgrekRect == null then
        return
    endif

    set centerPoint = Location(GetRectCenterX(sceneCenterRect), GetRectCenterY(sceneCenterRect))
    set nazgrekPoint = Location(GetRectCenterX(nazgrekRect), GetRectCenterY(nazgrekRect))
    set zulkisPoint = Location(GetRectCenterX(sceneCenterRect), GetRectCenterY(sceneCenterRect))
    set udg_CinematicTriggerUnit = Nazgrek
    set udg_CinematicMoveMode = 1
    set udg_CinematicMovePoint[0] = centerPoint
    set udg_CinematicMovePoint[1] = nazgrekPoint
    set udg_CinematicMovePoint[2] = zulkisPoint
    call CinematicMover_MoveUnitsToCinematic(Nazgrek, 1)
    set udg_CinematicMovePoint[0] = null
    set udg_CinematicMovePoint[1] = null
    set udg_CinematicMovePoint[2] = null
    call RemoveLocation(centerPoint)
    call RemoveLocation(nazgrekPoint)
    call RemoveLocation(zulkisPoint)
    set centerPoint = null
    set nazgrekPoint = null
    set zulkisPoint = null
    set ProtectOutpostCinematicUnitsMoved = true
endfunction

private function ReturnPlayerUnitsFromProtectOutpostCinematic takes nothing returns nothing
    if ProtectOutpostCinematicUnitsMoved and Nazgrek != null then
        call CinematicMover_ReturnUnitsFromCinematic(Nazgrek)
    endif
    set ProtectOutpostCinematicUnitsMoved = false
endfunction

private function IsProtectOutpostQuestOpen takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_PROTECT_OUTPOST)
    local boolean result = q != 0 and not q.completed and not q.failed
    set q = 0
    return result
endfunction

private function HideProtectOutpostPreplacedGnollEnum takes nothing returns nothing
    local unit u = GetEnumUnit()

    if FallenHeroState_IsAlive(u) and GetOwningPlayer(u) == Player(PLAYER_NEUTRAL_AGGRESSIVE) then
        call GroupAddUnit(ProtectOutpostHiddenGnolls, u)
        call ShowUnit(u, false)
    endif

    set u = null
endfunction

private function HideProtectOutpostPreplacedGnolls takes nothing returns nothing
    call EnsureProtectOutpostRuntime()
    call GroupClear(ProtectOutpostHiddenGnolls)
    call GroupClear(ProtectOutpostEnumGroup)
    call GroupEnumUnitsInRect(ProtectOutpostEnumGroup, gg_rct_GnollMountainCamp, null)
    call ForGroup(ProtectOutpostEnumGroup, function HideProtectOutpostPreplacedGnollEnum)
    call GroupClear(ProtectOutpostEnumGroup)
endfunction

private function UnhideProtectOutpostPreplacedGnollEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    if u != null and GetUnitTypeId(u) != 0 then
        call ShowUnit(u, true)
    endif
    set u = null
endfunction

private function UnhideProtectOutpostPreplacedGnolls takes nothing returns nothing
    if ProtectOutpostHiddenGnolls != null then
        call ForGroup(ProtectOutpostHiddenGnolls, function UnhideProtectOutpostPreplacedGnollEnum)
        call GroupClear(ProtectOutpostHiddenGnolls)
    endif
endfunction

private function CountLivingProtectOutpostGnollEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    if FallenHeroState_IsAlive(u) then
        set ProtectOutpostLivingGnolls = ProtectOutpostLivingGnolls + 1
    endif
    set u = null
endfunction

private function GetLivingProtectOutpostGnollCount takes nothing returns integer
    if ProtectOutpostGnolls == null then
        return 0
    endif
    set ProtectOutpostLivingGnolls = 0
    call ForGroup(ProtectOutpostGnolls, function CountLivingProtectOutpostGnollEnum)
    return ProtectOutpostLivingGnolls
endfunction

private function IsProtectOutpostGnollAtSpawn takes unit u returns boolean
    if gg_rct_GnollCinemaSpawnRegion != null and RectContainsUnit(gg_rct_GnollCinemaSpawnRegion, u) then
        return true
    endif
    if gg_rct_GnollSpawnRegion != null and RectContainsUnit(gg_rct_GnollSpawnRegion, u) then
        return true
    endif
    return gg_rct_GnollSpawnRegion2 != null and RectContainsUnit(gg_rct_GnollSpawnRegion2, u)
endfunction

private function ReissueProtectOutpostGnollOrderEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    if FallenHeroState_IsAlive(u) and (GetUnitCurrentOrder(u) == 0 or IsProtectOutpostGnollAtSpawn(u)) then
        call IssuePointOrder(u, "attack", GetRectCenterX(gg_rct_HordeMountainCamp), GetRectCenterY(gg_rct_HordeMountainCamp))
    endif
    set u = null
endfunction

private function ReissueProtectOutpostGnollOrders takes nothing returns nothing
    if ProtectOutpostGnolls != null then
        call ForGroup(ProtectOutpostGnolls, function ReissueProtectOutpostGnollOrderEnum)
    endif
endfunction

private function SpawnProtectOutpostGnoll takes integer unitTypeId, rect spawnRect returns nothing
    local unit u
    if spawnRect == null then
        return
    endif
    set u = CreateUnit(Player(OUTPOST_GNOLL_OWNER), unitTypeId, GetRectCenterX(spawnRect), GetRectCenterY(spawnRect), bj_UNIT_FACING)
    if u != null then
        call GroupAddUnit(ProtectOutpostGnolls, u)
        call IssuePointOrder(u, "attack", GetRectCenterX(gg_rct_HordeMountainCamp), GetRectCenterY(gg_rct_HordeMountainCamp))
    endif
    set u = null
endfunction

private function SpawnProtectOutpostFirstWave takes nothing returns nothing
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_BRUTE, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_BRUTE, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL, gg_rct_GnollCinemaSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL, gg_rct_GnollCinemaSpawnRegion)
endfunction

private function SpawnProtectOutpostSecondWave takes nothing returns nothing
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_BRUTE, gg_rct_GnollSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_BRUTE, gg_rct_GnollSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_POACHER, gg_rct_GnollSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_WARDEN, gg_rct_GnollSpawnRegion)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_BRUTE, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_BRUTE, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_RAVAGER, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_RAVAGER, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL_CRUSHER, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL, gg_rct_GnollSpawnRegion2)
    call SpawnProtectOutpostGnoll(UNIT_GNOLL, gg_rct_GnollSpawnRegion2)
    set ProtectOutpostSecondWaveSpawned = true
endfunction

private function OnProtectOutpostIntroCameraAssist takes nothing returns nothing
    call CameraSetupApplyForPlayer(true, gg_cam_ProtectOutpost02, Player(0), 0.00)
    call IssuePointOrder(Ragno, "attack", GetRectCenterX(gg_rct_HordeMountaintCampAssist), GetRectCenterY(gg_rct_HordeMountaintCampAssist))
    call IssuePointOrder(gg_unit_ogru_1633, "attack", GetRectCenterX(gg_rct_HordeMountaintCampAssist), GetRectCenterY(gg_rct_HordeMountaintCampAssist))
    call IssuePointOrder(gg_unit_orai_1221, "attack", GetRectCenterX(gg_rct_HordeMountaintCampAssist), GetRectCenterY(gg_rct_HordeMountaintCampAssist))
endfunction

private function OnProtectOutpostIntroCameraReturn takes nothing returns nothing
    call CameraSetupApplyForPlayer(true, gg_cam_ProtectOutpost01, Player(0), 0.00)
endfunction

private function OnProtectOutpostIntroCinematicStart takes nothing returns nothing
    set ProtectOutpostCameraTarget = CameraControl_GetTargetUnit(Player(0))
    if not DialogInteraction_IsUnitAlive(ProtectOutpostCameraTarget) then
        set ProtectOutpostCameraTarget = Nazgrek
    endif
    call CameraControl_Suspend(Player(0))
    call DialogInteraction_BeginCinematicSequence(CINEMATIC)
    if DialogInteraction_IsUnitAlive(Nazgrek) then
        call IssueImmediateOrder(Nazgrek, "stop")
    endif
endfunction

private function StageProtectOutpostIntroCinematic takes nothing returns nothing
    call MovePlayerUnitsToProtectOutpostCinematic(gg_rct_RagnoIntroPlayerUnits, gg_rct_RagnoIntroRegionNazgrek)
    if DialogInteraction_IsUnitAlive(Nazgrek) then
        call IssueImmediateOrder(Nazgrek, "stop")
        call SetUnitFacing(Nazgrek, 49.00)
    endif
    call CameraSetupApplyForPlayer(true, gg_cam_ProtectOutpost01, Player(0), 0.00)
    call TimerStart(ProtectOutpostIntroCameraAssistTimer, 5.00 + OUTPOST_INTRO_GRUNT_RESPONSE_DELAY, false, function OnProtectOutpostIntroCameraAssist)
    call TimerStart(ProtectOutpostIntroCameraReturnTimer, 8.00 + OUTPOST_INTRO_GRUNT_RESPONSE_DELAY, false, function OnProtectOutpostIntroCameraReturn)
endfunction

private function OnProtectOutpostIntroCinematicEnd takes nothing returns nothing
    local QuestData q

    call PauseTimer(ProtectOutpostIntroCameraAssistTimer)
    call PauseTimer(ProtectOutpostIntroCameraReturnTimer)
    call CameraSetupApplyForPlayer(true, gg_cam_ProtectOutpostSkipped, Player(0), 0.00)
    call ReturnPlayerUnitsFromProtectOutpostCinematic()
    call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, OUTPOST_CINEMATIC_END_FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    call DialogInteraction_EndCinematicSequence(CINEMATIC)
    if not DialogInteraction_IsUnitAlive(ProtectOutpostCameraTarget) then
        set ProtectOutpostCameraTarget = Nazgrek
    endif
    call CameraControl_SetTargetUnit(Player(0), ProtectOutpostCameraTarget)
    call CameraControl_ResumeQuick(Player(0))
    set ProtectOutpostCameraTarget = null
    set ProtectOutpostIntroFinished = true

    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno)
    set q = GetRagnoQuest(QUEST_PROTECT_OUTPOST)
    if q != 0 then
        call q.updateRequirementText(1, "Defeat the attacking gnolls")
        call q.refreshQuestLog()
    endif

    if DialogInteraction_IsUnitAlive(Nazgrek) then
        call IssuePointOrder(Nazgrek, "attack", GetRectCenterX(gg_rct_GnollAttackRegion2), GetRectCenterY(gg_rct_GnollAttackRegion2))
    endif
    set q = 0
endfunction

private function PlayProtectOutpostIntroCinematic takes nothing returns nothing
    local unit grunt = GetProtectOutpostSurvivingGrunt()
    local integer seq = DialogInteraction_CreateBaseSequence(Nazgrek, "Nazgrek")

    call DialogSystem_SetSequenceCallbacks(seq, function OnProtectOutpostIntroCinematicStart, function OnProtectOutpostIntroCinematicEnd)
    call DialogSystem_AddFadeTransition(seq, OUTPOST_CINEMATIC_FADE_DURATION, OUTPOST_CINEMATIC_FADE_DURATION, function StageProtectOutpostIntroCinematic)
    call DialogSystem_AddDelay(seq, 1.00)
    if grunt != null then
        call DialogSystem_AddLine(seq, grunt, "Grunt", VL_ORCGRUNT_0012_TEXT, VL_ORCGRUNT_0012_KEY, true)
        call DialogSystem_AddDelay(seq, OUTPOST_INTRO_GRUNT_RESPONSE_DELAY)
        call DialogSystem_AddLine(seq, grunt, "Grunt", VL_ORCGRUNT_0013_TEXT, VL_ORCGRUNT_0013_KEY, true)
    endif
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0057_TEXT, VL_NAZGREK_0057_KEY, true)
    call DialogSystem_AddFadeOut(seq, OUTPOST_CINEMATIC_END_FADE_DURATION)
    call DialogSystem_PlaySequence(seq, Player(0), Nazgrek)
    set grunt = null
endfunction

private function OnProtectOutpostLetterDelay takes nothing returns nothing
    call UnlockGivingLetterInternal()
    call RefreshRagnoAvailabilityInternal()
endfunction

private function RefreshProtectOutpostRespawnedRagnoQuestHooks takes nothing returns nothing
    call QuestGiver_UpdateGiverUnitReferenceByType(UNIT_RAGNO, Ragno)
    call QuestGiver_RefreshAvailabilityForGiver(Ragno)
    call ExecuteFunc("qRagno_RefreshRespawnedUnitHooks")
    call ExecuteFunc("qChieftainThork_RefreshAvailability")
endfunction

private function PrepareProtectOutpostCompletionRagno takes nothing returns nothing
    local unit oldRagno = Ragno

    set ProtectOutpostRagnoRespawnPending = false
    if DialogInteraction_IsUnitAlive(Ragno) then
        set oldRagno = null
        return
    endif

    set Ragno = CreateUnit(Player(RAGNO_OWNER), UNIT_RAGNO, GetRectCenterX(gg_rct_RagnoPoint), GetRectCenterY(gg_rct_RagnoPoint), 73.00)
    if Ragno == null then
        set Ragno = oldRagno
        set oldRagno = null
        return
    endif

    call SetUnitColor(Ragno, ConvertPlayerColor(RAGNO_PLAYER_COLOR))
    call ShowUnit(Ragno, false)
    set udg_Ragno = Ragno
    set bj_lastCreatedUnit = Ragno
    set ProtectOutpostRagnoRespawnPending = true
    call RefreshProtectOutpostRespawnedRagnoQuestHooks()

    if oldRagno != null then
        call RemoveUnit(oldRagno)
    endif
    set oldRagno = null
endfunction

private function RevealProtectOutpostRespawnedRagno takes nothing returns nothing
    if ProtectOutpostRagnoRespawnPending and DialogInteraction_IsUnitAlive(Ragno) then
        call SetUnitPosition(Ragno, GetRectCenterX(gg_rct_RagnoPoint), GetRectCenterY(gg_rct_RagnoPoint))
        call SetUnitFacing(Ragno, 73.00)
        call ShowUnit(Ragno, true)
        call QuestGiver_RefreshAvailabilityForGiver(Ragno)
    endif
    set ProtectOutpostRagnoRespawnPending = false
endfunction

private function OnProtectOutpostCompletionCinematicStart takes nothing returns nothing
    call DialogInteraction_BeginCinematicSequence(CINEMATIC)
    if DialogInteraction_IsUnitAlive(Nazgrek) then
        call IssueImmediateOrder(Nazgrek, "stop")
    endif
endfunction

private function PlaceProtectOutpostPetByNazgrek takes nothing returns nothing
    local real angle
    local real x
    local real y
    if not DialogInteraction_IsUnitAlive(Nazgrek) or not DialogInteraction_IsUnitAlive(udg_Shadowclaw) or IsUnitHidden(udg_Shadowclaw) then
        return
    endif
    if udg_Shadowclaw != udg_TamedUnit and (udg_TamedUnits == null or not IsUnitInGroup(udg_Shadowclaw, udg_TamedUnits)) then
        return
    endif
    set angle = (GetUnitFacing(Nazgrek) + OUTPOST_PET_ANGLE_OFFSET) * bj_DEGTORAD
    set x = GetUnitX(Nazgrek) + OUTPOST_PET_DISTANCE * Cos(angle)
    set y = GetUnitY(Nazgrek) + OUTPOST_PET_DISTANCE * Sin(angle)
    call SetUnitPosition(udg_Shadowclaw, x, y)
    call SetUnitFacing(udg_Shadowclaw, GetUnitFacing(Nazgrek))
    call IssueImmediateOrder(udg_Shadowclaw, "stop")
endfunction

private function StageProtectOutpostCompletionCinematic takes nothing returns nothing
    call MovePlayerUnitsToProtectOutpostCinematic(gg_rct_RagnoIntroPlayerUnits, gg_rct_RagnoIntroNazgrek)
    call CameraSetupApplyForPlayer(true, gg_cam_ProtectOutpost03, Player(0), 0.00)
    if ProtectOutpostRagnoRespawnPending then
        call TimerStart(ProtectOutpostRagnoRespawnTimer, OUTPOST_COMPLETION_RESPAWN_REVEAL_DELAY, false, function RevealProtectOutpostRespawnedRagno)
    endif
    if DialogInteraction_IsUnitAlive(Nazgrek) then
        call SetUnitPosition(Nazgrek, GetRectCenterX(gg_rct_RagnoIntroNazgrek), GetRectCenterY(gg_rct_RagnoIntroNazgrek))
        call SetUnitFacing(Nazgrek, 73.00)
        call IssueImmediateOrder(Nazgrek, "stop")
    endif
    if DialogInteraction_IsUnitAlive(Ragno) then
        call SetUnitPosition(Ragno, GetRectCenterX(gg_rct_RagnoPoint), GetRectCenterY(gg_rct_RagnoPoint))
        call SetUnitFacing(Ragno, 73.00)
    endif
    call PlaceProtectOutpostPetByNazgrek()
endfunction

private function OnProtectOutpostCompletionCinematicEnd takes nothing returns nothing
    call ReturnPlayerUnitsFromProtectOutpostCinematic()
    call PlaceProtectOutpostPetByNazgrek()
    set MountainDefenseActive = false
    call UnhideProtectOutpostPreplacedGnolls()
    call HordeUnitsRandomChat_EnableMountainChat()
    if DialogInteraction_IsUnitAlive(Ragno) then
        call IssuePointOrder(Ragno, "move", GetRectCenterX(gg_rct_RagnoIntroRagno2), GetRectCenterY(gg_rct_RagnoIntroRagno2))
    endif
    call TimerStart(ProtectOutpostLetterDelayTimer, 2.00, false, function OnProtectOutpostLetterDelay)
    if qZulkis_IsPrologueCompleted() then
        call CameraSetupApplyForPlayer(true, gg_cam_ProtectOutpostSkipped02, Player(0), 0.00)
        call DialogInteraction_EndCinematicSequence(CINEMATIC)
        call ResetToGameCameraForPlayer(Player(0), 0.00)
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, OUTPOST_CINEMATIC_END_FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    else
        call qZulkis_StartPrologue()
    endif
endfunction

private function MoveRagnoToProtectOutpostConversation takes nothing returns nothing
    local real angle
    local real x
    local real y

    if DialogInteraction_IsUnitAlive(Ragno) and DialogInteraction_IsUnitAlive(Nazgrek) then
        set angle = GetUnitFacing(Nazgrek) * bj_DEGTORAD
        set x = GetUnitX(Nazgrek) + OUTPOST_RAGNO_CONVERSATION_DISTANCE * Cos(angle)
        set y = GetUnitY(Nazgrek) + OUTPOST_RAGNO_CONVERSATION_DISTANCE * Sin(angle)
        call IssuePointOrder(Ragno, "move", x, y)
    endif
endfunction

private function FinishRagnoProtectOutpostConversationMove takes nothing returns nothing
    local real angle
    local real x
    local real y

    if DialogInteraction_IsUnitAlive(Ragno) and DialogInteraction_IsUnitAlive(Nazgrek) then
        set angle = GetUnitFacing(Nazgrek) * bj_DEGTORAD
        set x = GetUnitX(Nazgrek) + OUTPOST_RAGNO_CONVERSATION_DISTANCE * Cos(angle)
        set y = GetUnitY(Nazgrek) + OUTPOST_RAGNO_CONVERSATION_DISTANCE * Sin(angle)
        call SetUnitPosition(Ragno, x, y)
    endif
endfunction

private function PlayProtectOutpostCompletionCinematic takes nothing returns nothing
    local unit grunt
    local integer seq
    local integer moveLine
    local integer faceLine

    call EnsureProtectOutpostRuntime()
    call PrepareProtectOutpostCompletionRagno()
    set grunt = GetProtectOutpostSurvivingGrunt()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_SetSequenceCallbacks(seq, function OnProtectOutpostCompletionCinematicStart, function OnProtectOutpostCompletionCinematicEnd)
    call DialogSystem_AddFadeTransition(seq, OUTPOST_CINEMATIC_FADE_DURATION, OUTPOST_CINEMATIC_FADE_DURATION, function StageProtectOutpostCompletionCinematic)
    if ProtectOutpostRagnoRespawnPending then
        call DialogSystem_AddDelay(seq, OUTPOST_COMPLETION_RESPAWN_DIALOG_DELAY)
    else
        call DialogSystem_AddDelay(seq, 2.00)
    endif
    if grunt != null then
        call DialogSystem_AddMakeFaceEachOther(seq, Nazgrek, grunt, 1.00, 0.00)
        call DialogSystem_AddLine(seq, grunt, "Grunt", VL_ORCGRUNT_0014_TEXT, VL_ORCGRUNT_0014_KEY, true)
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0058_TEXT, VL_NAZGREK_0058_KEY, true)
        call DialogSystem_AddDelay(seq, 1.00)
    endif
    call DialogSystem_AddMakeFaceEachOther(seq, Ragno, Nazgrek, 1.00, 0.00)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0015_TEXT, VL_ORCGRUNT_0015_KEY, true)
    set moveLine = DialogSystem_AddDelay(seq, OUTPOST_RAGNO_CONVERSATION_MOVE_WAIT)
    call DialogSystem_BindLineAction(seq, moveLine, function MoveRagnoToProtectOutpostConversation)
    set faceLine = DialogSystem_AddMakeFaceEachOther(seq, Ragno, Nazgrek, 1.00, 1.00)
    call DialogSystem_BindLineAction(seq, faceLine, function FinishRagnoProtectOutpostConversationMove)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0059_TEXT, VL_NAZGREK_0059_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0016_TEXT, VL_ORCGRUNT_0016_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0060_TEXT, VL_NAZGREK_0060_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0017_TEXT, VL_ORCGRUNT_0017_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0005_TEXT, VL_ORCGRUNT_0005_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0061_TEXT, VL_NAZGREK_0061_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0006_TEXT, VL_ORCGRUNT_0006_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0007_TEXT, VL_ORCGRUNT_0007_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0062_TEXT, VL_NAZGREK_0062_KEY, true)
    call DialogSystem_AddFadeOut(seq, OUTPOST_CINEMATIC_END_FADE_DURATION)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)

    set grunt = null
endfunction

private function OnProtectOutpostCompletionDelay takes nothing returns nothing
    call PlayProtectOutpostCompletionCinematic()
endfunction

private function CompleteProtectOutpost takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_PROTECT_OUTPOST)

    if ProtectOutpostCompletionTimer != null then
        call PauseTimer(ProtectOutpostCompletionTimer)
    endif
    if ProtectOutpostSecondWaveTimer != null then
        call PauseTimer(ProtectOutpostSecondWaveTimer)
    endif
    set ProtectOutpostCompleted = true

    if q != 0 and not q.completed then
        if not q.active then
            call QuestGiver_AcceptQuestByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno)
        endif
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno)
    endif
    call RefreshRagnoAvailabilityInternal()
    call TimerStart(ProtectOutpostCompletionDelayTimer, 6.00, false, function OnProtectOutpostCompletionDelay)

    set q = 0
endfunction

private function OnProtectOutpostCompletionTimer takes nothing returns nothing
    call ReissueProtectOutpostGnollOrders()
    if ProtectOutpostStarted and ProtectOutpostSecondWaveSpawned and not ProtectOutpostCompleted and GetLivingProtectOutpostGnollCount() == 0 then
        call CompleteProtectOutpost()
    endif
endfunction

private function OnProtectOutpostSecondWaveTimer takes nothing returns nothing
    if not ProtectOutpostStarted or ProtectOutpostCompleted then
        call PauseTimer(ProtectOutpostSecondWaveTimer)
        return
    endif
    if not ProtectOutpostIntroFinished then
        return
    endif
    call ReissueProtectOutpostGnollOrders()
    if not ProtectOutpostSecondWaveSpawned and GetLivingProtectOutpostGnollCount() <= OUTPOST_SECOND_WAVE_LIVING_THRESHOLD then
        call PauseTimer(ProtectOutpostSecondWaveTimer)
        call SpawnProtectOutpostSecondWave()
        if ProtectOutpostCompletionTimer != null then
            call TimerStart(ProtectOutpostCompletionTimer, OUTPOST_COMPLETION_PERIOD, true, function OnProtectOutpostCompletionTimer)
        endif
    endif
endfunction

private function PrepareProtectOutpostCinematic takes nothing returns nothing
    call DialogSystem_ClearEscapeAction()
    call DialogSystem_SkipActiveSequence()
    call DialogInteraction_CloseActiveDialog()
    call DialogInteraction_AbortActiveTransition()
    call DialogSystem_StopDialogCamera(Player(0), 0.00, USE_DIALOG_CAMERA)
endfunction

private function StartProtectOutpostEncounter takes nothing returns boolean
    call SyncUnitReferences()
    if ProtectOutpostStarted or ProtectOutpostCompleted or GivingLetterUnlocked or not IsProtectOutpostQuestOpen() then
        return false
    endif

    call EnsureProtectOutpostRuntime()
    call GroupClear(ProtectOutpostGnolls)
    call HideProtectOutpostPreplacedGnolls()
    call SelectProtectOutpostGrunts()
    set ProtectOutpostStarted = true
    set ProtectOutpostIntroFinished = false
    set ProtectOutpostSecondWaveSpawned = false
    set MountainDefenseActive = true
    call PrepareProtectOutpostCinematic()

    call SpawnProtectOutpostFirstWave()
    call PlayProtectOutpostIntroCinematic()
    call TimerStart(ProtectOutpostSecondWaveTimer, OUTPOST_WAVE_CHECK_PERIOD, true, function OnProtectOutpostSecondWaveTimer)
    return true
endfunction

private function OnProtectOutpostRegionEnter takes nothing returns nothing
    if GetOwningPlayer(GetTriggerUnit()) == Player(0) then
        if StartProtectOutpostEncounter() then
            call DisableTrigger(ProtectOutpostStartTrigger)
        endif
    endif
endfunction

private function IsOwnedHeroInProtectOutpostStartRegion takes unit u returns boolean
    if u == null then
        return false
    endif
    if GetOwningPlayer(u) != Player(0) then
        return false
    endif
    return RectContainsUnit(gg_rct_RagnoIntroRegion01, u) or RectContainsUnit(gg_rct_RagnoIntroRegion02, u) or RectContainsUnit(gg_rct_RagnoIntroRegion03, u) or RectContainsUnit(gg_rct_RagnoIntroRegion04, u)
endfunction

private function RegisterProtectOutpostStartTrigger takes nothing returns nothing
    if ProtectOutpostStartTrigger != null then
        call DestroyTrigger(ProtectOutpostStartTrigger)
    endif
    set ProtectOutpostStartTrigger = CreateTrigger()
    call TriggerRegisterEnterRectSimple(ProtectOutpostStartTrigger, gg_rct_RagnoIntroRegion01)
    call TriggerRegisterEnterRectSimple(ProtectOutpostStartTrigger, gg_rct_RagnoIntroRegion02)
    call TriggerRegisterEnterRectSimple(ProtectOutpostStartTrigger, gg_rct_RagnoIntroRegion03)
    call TriggerRegisterEnterRectSimple(ProtectOutpostStartTrigger, gg_rct_RagnoIntroRegion04)
    call TriggerAddAction(ProtectOutpostStartTrigger, function OnProtectOutpostRegionEnter)
    if IsOwnedHeroInProtectOutpostStartRegion(Nazgrek) or IsOwnedHeroInProtectOutpostStartRegion(Zulkis) then
        if StartProtectOutpostEncounter() then
            call DisableTrigger(ProtectOutpostStartTrigger)
        endif
    endif
endfunction

private function OnAnyUnitDeath takes nothing returns nothing
    local unit killed = UnitDeathEvent_GetDyingUnit()
    local QuestData q

    if killed != null and GetUnitTypeId(killed) == UNIT_KOBOLD_LEADER and GetOwningPlayer(UnitDeathEvent_GetKillingUnit()) == Player(0) then
        set q = GetRagnoQuest(QUEST_KOBOLD_THIEVES)
        if q != 0 and q.active and not q.completed and not q.failed then
            set KoboldLeaderKilled = true
            call q.markRequirementCompleted(1, true)
            call RefreshKoboldTurnInState()
        endif
    endif

    set killed = null
    set q = 0
endfunction

private function CompleteItemQuest takes string questName, integer itemTypeId, integer amount returns boolean
    local QuestData q = GetRagnoQuest(questName)
    if q == 0 then
        return false
    endif

    if HeroItemCheckBothAndRemove(itemTypeId, amount) then
        call QuestGiver_CompleteItemRequirements(q.id)
        call QuestGiver_CompleteQuestByNameAndGiver(questName, Ragno)
        call RefreshRagnoAvailabilityInternal()
        set q = 0
        return true
    endif

    set q = 0
    return false
endfunction

private function OnAcceptGnollHeadcountEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_GNOLL_HEADCOUNT, Ragno)
    call RefreshQuestAfterAccept(QUEST_GNOLL_HEADCOUNT)
    call StartExitFadeOut()
endfunction

private function OnAcceptGnollHeadcount takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0094_TEXT, VL_ORCGRUNT_0094_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0160_TEXT, VL_ORCGRUNT_0160_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0161_TEXT, VL_ORCGRUNT_0161_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptGnollHeadcountEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnCompleteGnollHeadcountEnd takes nothing returns nothing
    call CompleteItemQuest(QUEST_GNOLL_HEADCOUNT, ITEM_GNOLL_HEAD, GNOLL_HEAD_REQUIRED)
    call StartExitFadeOut()
endfunction

private function OnCompleteGnollHeadcount takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0162_TEXT, VL_ORCGRUNT_0162_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0163_TEXT, VL_ORCGRUNT_0163_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteGnollHeadcountEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnAcceptLumberjackEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_LUMBERJACK_DUTIES, Ragno)
    call RefreshQuestAfterAccept(QUEST_LUMBERJACK_DUTIES)
    call StartExitFadeOut()
endfunction

private function OnAcceptLumberjack takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call StartLumberjackRuntime()
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0097_TEXT, VL_ORCGRUNT_0097_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0098_TEXT, VL_ORCGRUNT_0098_KEY, true)
    call AddLumberPeonIntroLines(seq)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptLumberjackEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnCompleteLumberjackEnd takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_LUMBERJACK_DUTIES)
    if q != 0 and HeroItemCheckBothAndRemove(ITEM_PILE_WOOD, PILE_WOOD_REQUIRED) then
        call QuestGiver_CompleteItemRequirements(q.id)
        call q.markRequirementCompleted(2, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_LUMBERJACK_DUTIES, Ragno)
        call CleanupLumberjackRuntime(true)
        call RefreshRagnoAvailabilityInternal()
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteLumberjack takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0164_TEXT, VL_ORCGRUNT_0164_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0165_TEXT, VL_ORCGRUNT_0165_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0166_TEXT, VL_ORCGRUNT_0166_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteLumberjackEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnAcceptKoboldThievesEnd takes nothing returns nothing
    set KoboldLeaderKilled = false
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_KOBOLD_THIEVES, Ragno)
    call RefreshQuestAfterAccept(QUEST_KOBOLD_THIEVES)
    call StartKoboldChests()
    call StartExitFadeOut()
endfunction

private function OnAcceptKoboldThieves takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0104_TEXT, VL_ORCGRUNT_0104_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptKoboldThievesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnCompleteKoboldThievesEnd takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_KOBOLD_THIEVES)
    if q != 0 and CanCompleteKoboldThieves() and HeroItemCheckBothAndRemove(ITEM_STOLEN_GOODS, STOLEN_GOODS_REQUIRED) then
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteItemRequirements(q.id)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_KOBOLD_THIEVES, Ragno)
        call StopKoboldChests(true)
        call RefreshRagnoAvailabilityInternal()
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteKoboldThieves takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0106_TEXT, VL_ORCGRUNT_0106_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteKoboldThievesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnAcceptSatyrNegotiationsEnd takes nothing returns nothing
    set SatyrNegotiationsReady = false
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_SATYR_NEGOTIATIONS, Ragno)
    call RefreshRagnoAvailabilityInternal()
    call RefreshZaekolaerrAvailabilityExternal()
    call StartExitFadeOut()
endfunction

private function OnAcceptSatyrNegotiations takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0101_TEXT, VL_ORCGRUNT_0101_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptSatyrNegotiationsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnCompleteSatyrNegotiationsEnd takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and CanCompleteSatyrNegotiations() then
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        call q.markRequirementCompleted(3, true)
        call q.markRequirementCompleted(4, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_SATYR_NEGOTIATIONS, Ragno)
        call RefreshRagnoAvailabilityInternal()
        call RefreshZaekolaerrAvailabilityExternal()
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteSatyrNegotiations takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0102_TEXT, VL_ORCGRUNT_0102_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0103_TEXT, VL_ORCGRUNT_0103_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteSatyrNegotiationsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnAidMountainDefenseEnd takes nothing returns nothing
    set MountainDefenseActive = true
    call StartExitFadeOut()
endfunction

private function OnAidMountainDefense takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0055_TEXT, VL_ORCGRUNT_0055_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0056_TEXT, VL_ORCGRUNT_0056_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAidMountainDefenseEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    if hero == Nazgrek then
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0004_TEXT, VL_NAZGREK_0004_KEY, true)
    endif
    call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0091_TEXT, VL_ORCGRUNT_0091_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)

    set hero = null
endfunction

private function AddMountainDefenseButton takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_MOUNTAIN_DEFENSE)
    local button b

    if q != 0 and q.discovered and not q.completed and not q.failed and not MountainDefenseActive then
        set b = DialogSystem_AddButton(RagnoDialog, QUEST_MOUNTAIN_DEFENSE + " (Aid Ragno)", 9)
        call DialogSystem_BindButtonCode(b, function OnAidMountainDefense)
        set b = null
    endif

    set q = 0
endfunction

private function BuildDialog takes nothing returns nothing
    local button b

    if RagnoDialog == null then
        set RagnoDialog = DialogSystem_CreateDialog("Ragno")
    endif

    call PrepareRepeatableForDialog(QUEST_GNOLL_HEADCOUNT)
    call PrepareRepeatableForDialog(QUEST_LUMBERJACK_DUTIES)
    call PrepareRepeatableForDialog(QUEST_KOBOLD_THIEVES)
    call RefreshKoboldTurnInState()

    call DialogSystem_ClearDialog(RagnoDialog)
    call DialogSystem_SetTitle(RagnoDialog, "Available Quests")

    call QuestGiver_AddAvailableQuestAcceptButton(RagnoDialog, QUEST_GNOLL_HEADCOUNT, Ragno, 1, function OnAcceptGnollHeadcount, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(RagnoDialog, QUEST_GNOLL_HEADCOUNT, Ragno, 2, function OnCompleteGnollHeadcount, true)

    call QuestGiver_AddAvailableQuestAcceptButton(RagnoDialog, QUEST_LUMBERJACK_DUTIES, Ragno, 3, function OnAcceptLumberjack, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(RagnoDialog, QUEST_LUMBERJACK_DUTIES, Ragno, 4, function OnCompleteLumberjack, true)

    call QuestGiver_AddAvailableQuestAcceptButton(RagnoDialog, QUEST_KOBOLD_THIEVES, Ragno, 5, function OnAcceptKoboldThieves, true, true)
    if CanCompleteKoboldThieves() then
        set b = DialogSystem_AddButtonQuestComplete(RagnoDialog, QUEST_KOBOLD_THIEVES, 6)
        call DialogSystem_BindButtonCode(b, function OnCompleteKoboldThieves)
        set b = null
    endif

    call QuestGiver_AddAvailableQuestAcceptButton(RagnoDialog, QUEST_SATYR_NEGOTIATIONS, Ragno, 7, function OnAcceptSatyrNegotiations, true, false)
    if CanCompleteSatyrNegotiations() then
        set b = DialogSystem_AddButtonQuestComplete(RagnoDialog, QUEST_SATYR_NEGOTIATIONS, 8)
        call DialogSystem_BindButtonCode(b, function OnCompleteSatyrNegotiations)
        set b = null
    endif

    call AddMountainDefenseButton()

    set b = DialogSystem_AddFarewellButton(RagnoDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddPreDialogBark takes integer seq, unit hero returns nothing
    if not RagnoGreeted and hero == Nazgrek then
        call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0085_TEXT, VL_ORCGRUNT_0085_KEY, true)
        call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0088_TEXT, VL_ORCGRUNT_0088_KEY, true)
    else
        call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0090_TEXT, VL_ORCGRUNT_0090_KEY, true)
        call DialogSystem_AddLine(seq, Ragno, "Ragno", VL_ORCGRUNT_0089_TEXT, VL_ORCGRUNT_0089_KEY, true)
    endif
    set RagnoGreeted = true
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    if hero != null then
        call DialogSystem_AddMakeFaceEachOther(seq, Ragno, hero, 0.75, 0.00)
    endif
    call DialogSystem_AddDelay(seq, DIALOG_FADE_OUT)
    call AddPreDialogBark(seq, hero)
    call DialogInteraction_PlayGreetSequenceEx(seq, Ragno, Player(0), RagnoDialog, CINEMATIC)
    if not DialogSystem_IsSequenceActive() and not DialogSystem_IsDialogVisible() then
        call DialogSystem_SetContext(Ragno, Player(0))
        call DialogSystem_ShowDialog(RagnoDialog, Player(0))
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero

    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Ragno) or not IsRagnoDialogEnabled() then
        call StartExitFadeOut()
        return
    endif

    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif

    call RefreshRagnoAvailabilityInternal()
    call BuildDialog()
    call DialogSystem_SetEscapeAction(function OnRagnoEscape)
    call PlayDialogGreeting(hero)

    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Ragno) or not IsRagnoDialogEnabled() then
        return
    endif

    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Ragno, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Ragno, SelectedHero, DIALOG_RANGE, RagnoDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif

    call DialogInteraction_StartConfiguredDialogEntryTransition(Ragno, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qRagno_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string giverName = "Ragno"
    local string infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
    local string info2DailyText = "|cffffcc00Recommended level:|r 10\n\n"
    local string info2MainText = "|cffffcc00Recommended level:|r 8\n\n"
    local trigger availabilityCondition

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_PROTECT_OUTPOST, Ragno, "normal", 1, null, QUEST_PROTECT_OUTPOST, "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Gnolls are attacking the mountain outpost.\n\n", "", "", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", "")
        call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, true, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Protect the mountain outpost from the gnoll attack", "", "", "", "", "", "", "")
        call q.setAutoComplete(true)
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferProtectOutpost))
        call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
        call QuestGiver_SetStateByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno, QUEST_STATE_UNAVAILABLE)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_GNOLL_HEADCOUNT, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_GNOLL_HEADCOUNT, Ragno, "daily", 1, null, QUEST_GNOLL_HEADCOUNT, "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Ragno wants you to thin out the gnolls threatening the mountain outpost.\n\n", infoText, info2DailyText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 200, false, 0, true, 0, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_PROTECT_OUTPOST, Ragno)
        call QuestGiver_SetRequirements(q.id, "", "Bring 20 Gnoll Heads to Ragno", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 1, ITEM_GNOLL_HEAD, GNOLL_HEAD_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_LUMBERJACK_DUTIES, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_LUMBERJACK_DUTIES, Ragno, "daily", 1, null, QUEST_LUMBERJACK_DUTIES, "ReplaceableTextures\\CommandButtons\\BTNBundleOfLumber.blp", "Harvest 10 Pile Of Wood for the mountain outpost. A peon will help, but he must survive.\n\n", infoText, info2DailyText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 200, false, 0, true, 0, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_PROTECT_OUTPOST, Ragno)
        call QuestGiver_SetRequirements(q.id, "", "Harvest 10 Pile Of Wood", "Peon must survive", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 1, ITEM_PILE_WOOD, PILE_WOOD_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_KOBOLD_THIEVES, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_KOBOLD_THIEVES, Ragno, "daily", 1, null, QUEST_KOBOLD_THIEVES, "ReplaceableTextures\\CommandButtons\\BTNKobold.blp", "Kill the kobold leader and recover the stolen goods taken from the Horde.\n\n", infoText, info2DailyText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 200, false, 0, true, 0, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_PROTECT_OUTPOST, Ragno)
        call QuestGiver_SetRequirements(q.id, "", "Kill Razzlewhip Mudgrubber", "Retrieve 6 Stolen Goods", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 2, ITEM_STOLEN_GOODS, STOLEN_GOODS_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_SATYR_NEGOTIATIONS, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_SATYR_NEGOTIATIONS, Ragno, "normal", 1, null, QUEST_SATYR_NEGOTIATIONS, "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "The relations between the Horde and the satyrs are unstable. Meet with them and learn whether diplomacy is still possible.\n\n", infoText, info2MainText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 150, false, 0, true, 0, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_PROTECT_OUTPOST, Ragno)
        call QuestGiver_SetRequirements(q.id, "", "Meet with the satyrs and learn what they want", "", "", "", "", "", "", "")
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_GIVING_LETTER, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_GIVING_LETTER, Ragno, "normal", 1, Thork, QUEST_GIVING_LETTER, "ReplaceableTextures\\CommandButtons\\BTNOrcCaptureFlag.blp", "Ragno has given Nazgrek a blood-signed summon letter. Bring it to Chieftain Thork at the Horde camp.\n\n", infoText, "|cffffcc00Quest receiver:|r Chieftain Thork\n\n", 1, true, ALLOW_NAZGREK, false, "Horde", "Chieftain Thork")
        call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, true, 0, false)
        call QuestGiver_AddQuestPrerequisite(q, QUEST_PROTECT_OUTPOST, Ragno)
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferGivingLetter))
        call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
        call QuestGiver_SetRequirements(q.id, "", "Take the Blood Signed Summon Letter to Chieftain Thork", "", "", "", "", "", "", "")
        call QuestGiver_SetStateByNameAndGiver(QUEST_GIVING_LETTER, Ragno, QUEST_STATE_UNAVAILABLE)
    endif
    set q = QuestGiver_GetByNameAndGiver(QUEST_GIVING_LETTER, Ragno)
    call QuestGiver_SetQuestUnitSpecificHero(q, Nazgrek)

    call ApplyRagnoQuestAccessRule(QUEST_PROTECT_OUTPOST)
    call ApplyRagnoQuestAccessRule(QUEST_GNOLL_HEADCOUNT)
    call ApplyRagnoQuestAccessRule(QUEST_LUMBERJACK_DUTIES)
    call ApplyRagnoQuestAccessRule(QUEST_KOBOLD_THIEVES)
    call ApplyRagnoQuestAccessRule(QUEST_SATYR_NEGOTIATIONS)
    call ApplyRagnoQuestAccessRule(QUEST_GIVING_LETTER)

    set availabilityCondition = null
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Ragno, VL_ORCGRUNT_0091_TEXT, VL_ORCGRUNT_0091_KEY, true)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()

    if Ragno == null or Nazgrek == null or Thork == null then
        if not RagnoInitWaitingLogged then
            call DebugMsg("Waiting for Ragno, Nazgrek, and Chieftain Thork unit references.")
            set RagnoInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif

    call QuestGiver_Register(Ragno)
    call DialogInteraction_ConfigureDialogTransition(Ragno, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call RegisterDialogLines()
    call RegisterBaseGnollHeadDrops()
    call CreateQuests()
    if QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_PROTECT_OUTPOST, Ragno) then
        set ProtectOutpostCompleted = true
        set MountainDefenseActive = false
        call UnlockGivingLetterInternal()
        call HordeUnitsRandomChat_EnableMountainChat()
    endif
    call RegisterProtectOutpostStartTrigger()
    call RefreshRagnoAvailabilityInternal()
    call DialogInteraction_RegisterSelectionHandler(Ragno, function OnSelected)
    call UnitDeathEvent_Register(function OnAnyUnitDeath)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set RagnoDialogCooldown = CreateTimer()
    set KoboldChestTimer = CreateTimer()
    set KoboldChestDeathTrigger = CreateTrigger()
    call TriggerAddAction(KoboldChestDeathTrigger, function OnKoboldChestDeath)
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    call RefreshRagnoAvailabilityInternal()
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Ragno != null then
        call QuestGiver_Register(Ragno)
        call DialogInteraction_ConfigureDialogTransition(Ragno, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Ragno, function OnSelected)
        call RegisterProtectOutpostStartTrigger()
        call RefreshAvailability()
    endif
endfunction

public function DiscoverGivingTheLetter takes nothing returns nothing
    call UnlockGivingLetterInternal()
endfunction

public function CompleteMountainDefenseAndDiscoverLetter takes nothing returns nothing
    if not ProtectOutpostCompleted then
        call CompleteProtectOutpost()
    else
        call DiscoverGivingTheLetter()
    endif
endfunction

public function SetMountainDefenseActive takes boolean active returns nothing
    set MountainDefenseActive = active
endfunction

public function IsSatyrNegotiationsActive takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    local boolean result = q != 0 and q.active and not q.completed and not q.failed
    set q = 0
    return result
endfunction

public function IsSatyrNegotiationsOpen takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    local boolean result = false
    if q != 0 then
        set result = q.discovered and not q.completed and not q.failed and not SatyrNegotiationsReady and q.state != QUEST_STATE_READY_TURNIN
    endif
    set q = 0
    return result
endfunction

public function IsSatyrNegotiationsCompleted takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    local boolean result = q != 0 and q.completed
    set q = 0
    return result
endfunction

public function IsSatyrNegotiationsReady takes nothing returns boolean
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    local boolean result = SatyrNegotiationsReady
    if q != 0 then
        set result = result or q.state == QUEST_STATE_READY_TURNIN
    endif
    set q = 0
    return result
endfunction

public function UpdateSatyrNegotiationsArena takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(1, true)
        call q.updateRequirementText(2, "Speak with the satyr arena master and complete a challenge in the Coliseum of Ages")
        call q.refreshQuestLog()
    endif
    set q = 0
endfunction

public function UpdateSatyrNegotiationsDiplomacyGoneWrong takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(1, true)
        call q.updateRequirementText(3, "Escape the satyr territory")
        call q.refreshQuestLog()
    endif
    set q = 0
endfunction

public function UpdateSatyrNegotiationsUnlikelyAlliances takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(1, true)
        call q.updateRequirementText(4, "Earn the trust of the satyrs")
        call q.refreshQuestLog()
    endif
    set q = 0
endfunction

public function MarkSatyrNegotiationsReady takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    set SatyrNegotiationsReady = true
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.setState(QUEST_STATE_READY_TURNIN)
        call q.addReturnRequirement()
    endif
    call RefreshZaekolaerrAvailabilityExternal()
    set q = 0
endfunction

public function CompleteSatyrNegotiationsArena takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(2, true)
        call q.refreshQuestLog()
        call MarkSatyrNegotiationsReady()
    endif
    set q = 0
endfunction

public function CompleteSatyrNegotiations takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and not q.completed then
        set SatyrNegotiationsReady = true
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        call q.markRequirementCompleted(3, true)
        call q.markRequirementCompleted(4, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_SATYR_NEGOTIATIONS, Ragno)
        call RefreshRagnoAvailabilityInternal()
        call RefreshZaekolaerrAvailabilityExternal()
    endif
    set q = 0
endfunction

endlibrary
