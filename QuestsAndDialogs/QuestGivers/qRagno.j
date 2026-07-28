//============================================================================
// qRagno
//============================================================================
// Ragno quest giver conversion from legacy GUI triggers.
//
// Converted GUI trigger groups:
// - Ragno
// - Ragno quest turn-in side of Chieftain Thork's first summon chain
//
// Purpose:
// - Provides Ragno's qXXX sublibrary using the shared QuestGiver,
//   QuestMaster, DialogInteraction, and DialogSystem APIs.
// - Keeps Ragno's repeatable outpost tasks, Kobold stash drops, lumber peon
//   support, Satyr Negotiations update hooks, and the Thork letter handoff in
//   one library.
//
// Notes:
// - "Giving the Letter" is owned by Ragno but has Chieftain Thork as receiver,
//   so the ready turn-in marker appears on Thork while the quest remains part
//   of Ragno's chain.
// - The large Mountain Defense battle script is intentionally left as an
//   external chain; this library exposes a quest-facing hook for its ending.
//============================================================================
library qRagno initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, FollowSystem, HeroItemCheck, UnitDeathEvent, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_GIVING_LETTER = "Giving the Letter"
    public constant string QUEST_GNOLL_HEADCOUNT = "Gnoll Headcount"
    public constant string QUEST_LUMBERJACK_DUTIES = "Lumberjack Duties"
    public constant string QUEST_KOBOLD_THIEVES = "Kobold Thieves"
    public constant string QUEST_SATYR_NEGOTIATIONS = "Satyr Negotiations"
    public constant string QUEST_MOUNTAIN_DEFENSE = "Mountain Defense"

    private constant integer ITEM_BLOOD_SIGNED_LETTER = 'I625'
    private constant integer ITEM_GNOLL_HEAD = 'I69A'
    private constant integer ITEM_PILE_WOOD = 'I60K'
    private constant integer ITEM_STOLEN_GOODS = 'I69B'

    private constant integer UNIT_KOBOLD_LEADER = 'n62T'
    private constant integer UNIT_LUMBER_PEON = 'opeo'
    private constant integer DESTRUCT_STASH_QUEST = 'B61D'
    private constant integer DESTRUCT_LUMBER_TREE = 'B61E'

    private constant integer GNOLL_HEAD_REQUIRED = 20
    private constant integer PILE_WOOD_REQUIRED = 10
    private constant integer STOLEN_GOODS_REQUIRED = 6
    private constant integer KOBOLD_CHEST_ACTIVE_MAX = 6
    private constant integer KOBOLD_CHEST_SLOT_COUNT = 8

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

    private unit Ragno = null
    private unit Thork = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit SelectedHero = null
    private unit LumberPeon = null

    private dialog RagnoDialog = null
    private timer RagnoDialogCooldown = null
    private timer KoboldChestTimer = null
    private trigger KoboldChestDeathTrigger = null
    private trigger LumberPeonDeathTrigger = null
    private trigger LumberPeonOrderTrigger = null
    private destructable array KoboldChest
    private integer KoboldChestCount = 0
    private boolean KoboldLeaderKilled = false
    private boolean SatyrNegotiationsReady = false
    private boolean GivingLetterUnlocked = false
    private boolean MountainDefenseActive = false
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
    call DialogInteraction_StartConfiguredDialogExitTransition(Ragno, SelectedHero, RagnoDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
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
    elseif q.name == QUEST_GIVING_LETTER then
        call SetRagnoQuestBaseRequirements(q, "Bring the blood signed letter to Chieftain Thork", "", "", "")
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
    if q != 0 and (q.completed or q.failed) then
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
    return GivingLetterUnlocked
endfunction

private function IsRagnoDialogEnabled takes nothing returns boolean
    return true
endfunction

private function RefreshRagnoAvailabilityInternal takes nothing returns nothing
    if Ragno == null then
        return
    endif

    call QuestGiver_RefreshAvailabilityForGiver(Ragno)
    if QuestGiver_QuestExistsByNameAndGiver(QUEST_GIVING_LETTER, Ragno) and not GivingLetterUnlocked and not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_GIVING_LETTER, Ragno) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_GIVING_LETTER, Ragno) then
        call QuestGiver_SetStateByNameAndGiver(QUEST_GIVING_LETTER, Ragno, QUEST_STATE_UNAVAILABLE)
    endif
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
    call DestroyLumberTriggers()
    if LumberPeon != null then
        call FollowSystem_RemoveUnit(LumberPeon)
        if removePeon then
            call RemoveUnit(LumberPeon)
            set LumberPeon = null
        endif
    endif
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

private function OnLumberPeonOrder takes nothing returns nothing
    local destructable target = GetOrderTargetDestructable()
    local real x
    local real y
    local QuestData q

    if GetTriggerUnit() != LumberPeon or target == null then
        set target = null
        return
    endif
    if GetIssuedOrderId() != OrderId("harvest") and GetIssuedOrderId() != OrderId("smart") then
        set target = null
        return
    endif
    if GetDestructableTypeId(target) != DESTRUCT_LUMBER_TREE or GetDestructableLife(target) <= 0.405 then
        set target = null
        return
    endif

    set q = GetRagnoQuest(QUEST_LUMBERJACK_DUTIES)
    if q == 0 or not q.active or q.completed or q.failed then
        set target = null
        set q = 0
        return
    endif

    set x = GetDestructableX(target)
    set y = GetDestructableY(target)
    call KillDestructable(target)
    if GetRandomInt(1, 2) == 1 then
        call CreateItem(ITEM_PILE_WOOD, x, y)
    endif
    if DialogInteraction_IsUnitAlive(LumberPeon) and DialogInteraction_IsUnitAlive(Nazgrek) then
        call FollowSystem_SetFollow(LumberPeon, Nazgrek, 1200.00, true, 5.00, FOLLOW_STYLE_PASSIVE, true, true)
    endif
    call RefreshQuestAfterAccept(QUEST_LUMBERJACK_DUTIES)

    set target = null
    set q = 0
endfunction

private function StartLumberjackRuntime takes nothing returns nothing
    local real x
    local real y

    call CleanupLumberjackRuntime(true)
    set x = GetRectCenterX(gg_rct_LumberPeonSpawn)
    set y = GetRectCenterY(gg_rct_LumberPeonSpawn)
    set LumberPeon = CreateUnit(Player(0), UNIT_LUMBER_PEON, x, y, 345.00)
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
endfunction

private function OnAnyUnitDeath takes nothing returns nothing
    local unit killed = GetDyingUnit()
    local QuestData q

    if killed != null and GetUnitTypeId(killed) == UNIT_KOBOLD_LEADER and GetOwningPlayer(GetKillingUnit()) == Player(0) then
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "The stench of gnoll is growing stronger around the outpost. Bring me their heads and thin their numbers.", "OrcGrunt_0094", true)
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Ah, back already? Let the gnolls learn to fear the Horde again.", "OrcGrunt_0095", true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteGnollHeadcountEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnAcceptLumberjackEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_LUMBERJACK_DUTIES, Ragno)
    call RefreshQuestAfterAccept(QUEST_LUMBERJACK_DUTIES)
    call StartLumberjackRuntime()
    call StartExitFadeOut()
endfunction

private function OnAcceptLumberjack takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Our settlements are hungry for lumber.", "OrcGrunt_0097", true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Grab a peon and gather what wood you can. Keep him alive.", "OrcGrunt_0098", true)
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Well, well, well. That should keep the outpost stocked for now.", "OrcGrunt_0099", true)
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Kobolds dared to trespass and steal from the Horde. Slay their leader and recover the stolen goods.", "OrcGrunt_0104", true)
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "You've returned, bags full and kobolds humbled. Good work.", "OrcGrunt_0106", true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteKoboldThievesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnAcceptSatyrNegotiationsEnd takes nothing returns nothing
    set SatyrNegotiationsReady = false
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_SATYR_NEGOTIATIONS, Ragno)
    call RefreshRagnoAvailabilityInternal()
    call StartExitFadeOut()
endfunction

private function OnAcceptSatyrNegotiations takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "The woods are about to drown in satyr schemes. Speak with them and learn where their game leads.", "OrcGrunt_0101", true)
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
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteSatyrNegotiations takes nothing returns nothing
    local integer seq

    set RagnoGreeted = true
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "You made it back. I had begun to think the satyrs had claimed you.", "OrcGrunt_0102", true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Ha, I knew I could count on you.", "OrcGrunt_0103", true)
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "I've been expecting you. The outpost will need every axe we can muster.", "OrcGrunt_0055", true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "We must prepare our defense before the gnolls strike again.", "OrcGrunt_0056", true)
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
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Strength and honor.", "OrcGrunt_0091", true)
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
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0170_TEXT, VL_NAZGREK_0170_KEY, true)
        call DialogSystem_AddLine(seq, Ragno, "Ragno", "Hail Nazgrek! I sense the Horde's fire still burns in you.", "OrcGrunt_0085", true)
        call DialogSystem_AddLine(seq, Ragno, "Ragno", "If you are interested in work, I have tasks that need a steady hand.", "OrcGrunt_0088", true)
    else
        call DialogSystem_AddLine(seq, Ragno, "Ragno", "Lok'tar, my friend.", "OrcGrunt_0090", true)
        call DialogSystem_AddLine(seq, Ragno, "Ragno", "What do you have in mind?", "OrcGrunt_0089", true)
    endif
    set RagnoGreeted = true
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Ragno, "Ragno", hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
    call AddPreDialogBark(seq, hero)
    call DialogInteraction_PlayGreetSequenceEx(seq, Ragno, Player(0), RagnoDialog, CINEMATIC)
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

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_GNOLL_HEADCOUNT, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_GNOLL_HEADCOUNT, Ragno, "daily", 2, null, QUEST_GNOLL_HEADCOUNT, "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Ragno wants you to thin out the gnolls threatening the mountain outpost.\n\n", infoText, info2DailyText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 200, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Bring 20 Gnoll Heads to Ragno", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 1, ITEM_GNOLL_HEAD, GNOLL_HEAD_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_LUMBERJACK_DUTIES, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_LUMBERJACK_DUTIES, Ragno, "daily", 2, null, QUEST_LUMBERJACK_DUTIES, "ReplaceableTextures\\CommandButtons\\BTNBundleOfLumber.blp", "Harvest 10 Pile Of Wood for the mountain outpost. A peon will help, but he must survive.\n\n", infoText, info2DailyText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 200, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Harvest 10 Pile Of Wood", "Peon must survive", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 1, ITEM_PILE_WOOD, PILE_WOOD_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_KOBOLD_THIEVES, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_KOBOLD_THIEVES, Ragno, "daily", 2, null, QUEST_KOBOLD_THIEVES, "ReplaceableTextures\\CommandButtons\\BTNKobold.blp", "Kill the kobold leader and recover the stolen goods taken from the Horde.\n\n", infoText, info2DailyText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 200, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Kill Razzlewhip Mudgrubber", "Retrieve 6 Stolen Goods", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 2, ITEM_STOLEN_GOODS, STOLEN_GOODS_REQUIRED)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_SATYR_NEGOTIATIONS, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_SATYR_NEGOTIATIONS, Ragno, "normal", 3, null, QUEST_SATYR_NEGOTIATIONS, "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "The relations between the Horde and the satyrs are unstable. Meet with them and learn whether diplomacy is still possible.\n\n", infoText, info2MainText, 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", giverName)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 150, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Meet with the satyrs and learn what they want", "", "", "", "", "", "", "")
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_GIVING_LETTER, Ragno) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_GIVING_LETTER, Ragno, "normal", 1, Thork, QUEST_GIVING_LETTER, "ReplaceableTextures\\CommandButtons\\BTNOrcCaptureFlag.blp", "Ragno has given Nazgrek a blood-signed summon letter. Bring it to Chieftain Thork at the Horde camp.\n\n", infoText, "|cffffcc00Quest receiver:|r Chieftain Thork\n\n", 1, true, ALLOW_NAZGREK, false, "Horde", "Chieftain Thork")
        call QuestGiver_SetQuestRewards(q, false, 0, false, 0, false, 0, false, 0, false)
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferGivingLetter))
        call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
        call QuestGiver_SetRequirements(q.id, "", "Bring the blood signed letter to Chieftain Thork", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Ragno, 1, ITEM_BLOOD_SIGNED_LETTER, 1)
        call QuestGiver_SetStateByNameAndGiver(QUEST_GIVING_LETTER, Ragno, QUEST_STATE_UNAVAILABLE)
    endif

    set availabilityCondition = null
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Ragno, "Strength and honor.", "OrcGrunt_0091", true)
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
    call CreateQuests()
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
        call RefreshAvailability()
    endif
endfunction

public function DiscoverGivingTheLetter takes nothing returns nothing
    local QuestData q

    call SyncUnitReferences()
    if Ragno == null or Thork == null then
        return
    endif

    set GivingLetterUnlocked = true
    call RefreshRagnoAvailabilityInternal()
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_GIVING_LETTER, Ragno)
    set q = GetRagnoQuest(QUEST_GIVING_LETTER)
    if q != 0 and not q.completed then
        call QuestGiver_GiveUniqueQuestItemToHero(Nazgrek, ITEM_BLOOD_SIGNED_LETTER, 0, "Blood Signed Summon Letter")
        call QuestGiver_RefreshItemRequirementsForQuest(q.id)
    endif

    set q = 0
endfunction

public function CompleteMountainDefenseAndDiscoverLetter takes nothing returns nothing
    call DiscoverGivingTheLetter()
endfunction

public function SetMountainDefenseActive takes boolean active returns nothing
    set MountainDefenseActive = active
endfunction

public function UpdateSatyrNegotiationsArena takes nothing returns nothing
    local QuestData q = GetRagnoQuest(QUEST_SATYR_NEGOTIATIONS)
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(1, true)
        call q.updateRequirementText(2, "Enter the Coliseum and survive the satyr trial")
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
    endif
    set q = 0
endfunction

endlibrary
