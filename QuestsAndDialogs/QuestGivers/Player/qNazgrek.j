/**
    qNazgrek

    Author: Valdemar
    Version:

    Description:

    Owns Nazgrek's self-discovered prologue quests. Wolf Hunt I gathers the
    skins that lead Nazgrek to prepare his legacy flask recipe before facing
    the Wolf Mother. These quests start through public story hooks and
    auto-complete, so this library intentionally has no quest-giver dialog.

    Credits:

    The flask objectives and delayed Empty Flask reminder are converted from
    the original Nazgrek GUI triggers.

    How to install:

    Import after QuestGiver, QuestMaster, DialogSystem, SharedDInvLib,
    UnitDeathEvent, and VoicelinesNazgrek. Call
    qNazgrek_StartIntroQuestChain() when Nazgrek's opening gameplay begins,
    then disable the legacy Nazgrek's Flask GUI trigger folder.

    API:

    qNazgrek_StartIntroQuestChain() starts Wolf Hunt I.
    qNazgrek_StartFlaskQuest() starts the flask quest for recovery/testing.
    qNazgrek_RefreshProgress() immediately refreshes both active quests.
    qNazgrek_IsWolfHuntICompleted() reports the first hunt's completion.
    qNazgrek_IsFlaskCompleted() reports the flask quest's completion.

**/
library qNazgrek initializer Init requires QuestGiver, QuestMaster, DialogSystem, SharedDInvLib, UnitDeathEvent, VoicelinesNazgrek
    globals
        // Quest configuration
        public constant string QUEST_WOLF_HUNT_I = "Wolf Hunt I"
        public constant string QUEST_NAZGREKS_FLASK = "Nazgrek's Flask"

        private constant integer ITEM_WOLF_SKIN = 'I61F'
        private constant integer ITEM_FOREST_FLOWER = 'I60Y'
        private constant integer ITEM_AGAVE = 'I60W'
        private constant integer ITEM_EARTH_ROOTS = 'I60X'
        private constant integer ITEM_STAG_HAIR = 'I614'
        private constant integer ITEM_FROG_SLIME = 'I615'
        private constant integer ITEM_EMPTY_FLASK = 'I61M'
        private constant integer ITEM_NAZGREKS_FLASK = 'I61L'

        private constant integer UNIT_WOLF_1 = 'o600'
        private constant integer UNIT_WOLF_2 = 'o601'
        private constant integer UNIT_WOLF_3 = 'o602'
        private constant integer UNIT_ALPHA_WOLF = 'n64B'

        private constant integer WOLF_KILL_REQUIRED = 6
        private constant integer WOLF_SKIN_REQUIRED = 6
        private constant integer FOREST_FLOWER_REQUIRED = 6
        private constant integer AGAVE_REQUIRED = 3
        private constant integer EARTH_ROOTS_REQUIRED = 2
        private constant integer STAG_HAIR_REQUIRED = 6
        private constant integer FROG_SLIME_REQUIRED = 2
        private constant integer EMPTY_FLASK_REQUIRED = 1

        private constant real PROGRESS_INTERVAL = 0.50
        private constant real EMPTY_FLASK_REMINDER_DELAY = 175.00

        private constant boolean DEBUG = false

        // Runtime state
        private unit Nazgrek = null
        private QuestData WolfHuntIQuest = 0
        private QuestData NazgreksFlaskQuest = 0
        private timer InitTimer = null
        private timer ProgressTimer = null
        private timer EmptyFlaskReminderTimer = null
        private integer array LastItemCount
        private integer WolfKills = 0
        private boolean Initialized = false
        private boolean IntroStartRequested = false
        private boolean FlaskStartRequested = false
        private boolean EmptyFlaskRequirementRevealed = false
        private boolean InitWaitingLogged = false
    endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qNazgrek]|r " + msg)
    endif
endfunction

private function GetNazgrekItemCount takes integer itemTypeId returns integer
    if Nazgrek == null then
        return 0
    endif
    return GetDInvItemChargesByType(Nazgrek, itemTypeId)
endfunction

private function IsRequirementCompleted takes QuestData q, integer index returns boolean
    if q == 0 then
        return false
    elseif index == 1 then
        return q.req1Completed
    elseif index == 2 then
        return q.req2Completed
    elseif index == 3 then
        return q.req3Completed
    elseif index == 4 then
        return q.req4Completed
    elseif index == 5 then
        return q.req5Completed
    elseif index == 6 then
        return q.req6Completed
    elseif index == 7 then
        return q.req7Completed
    elseif index == 8 then
        return q.req8Completed
    endif
    return false
endfunction

private function SyncUnitReferences takes nothing returns nothing
    local unit oldNazgrek

    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set oldNazgrek = Nazgrek
        set Nazgrek = udg_Nazgrek
        if oldNazgrek != null then
            call QuestGiver_UpdateGiverUnitReference(oldNazgrek, Nazgrek)
        endif
        if Initialized then
            call QuestMaster_SetGiverIconsSuppressed(Nazgrek, true)
        endif
    endif
    set oldNazgrek = null
endfunction

private function UpdateItemRequirement takes QuestData q, integer index, integer itemTypeId, integer amount, integer trackingSlot returns nothing
    local integer current
    local string text

    if q == 0 or not q.active then
        return
    endif

    set current = GetNazgrekItemCount(itemTypeId)
    if current > amount then
        set current = amount
    endif

    if current != LastItemCount[trackingSlot] then
        set LastItemCount[trackingSlot] = current
        set text = "Gather " + I2S(amount) + " " + GetObjectName(itemTypeId) + " (" + I2S(current) + "/" + I2S(amount) + ")"
        call q.updateRequirementText(index, text)
        call q.refreshQuestLog()
    endif

    if current >= amount and not IsRequirementCompleted(q, index) then
        call QuestGiver_SetRequirementCompleted(q.id, index, true)
    endif
endfunction

private function RevealEmptyFlaskRequirement takes boolean playReminder returns nothing
    if EmptyFlaskRequirementRevealed or NazgreksFlaskQuest == 0 or not NazgreksFlaskQuest.active then
        return
    endif

    set EmptyFlaskRequirementRevealed = true
    set LastItemCount[7] = -1
    call QuestGiver_SetRequirement(NazgreksFlaskQuest.id, 7, "Buy or find an Empty Flask")
    if playReminder and not udg_InCinematic and not DialogSystem_IsSequenceActive() and not DialogSystem_IsFieldLineQueueActive() then
        call DialogSystem_PlayLine(Nazgrek, "Nazgrek", VL_NAZGREK_0008_TEXT, VL_NAZGREK_0008_KEY, false)
    endif
endfunction

private function OnEmptyFlaskReminder takes nothing returns nothing
    call RevealEmptyFlaskRequirement(true)
endfunction

private function StartFlaskQuestInternal takes nothing returns nothing
    if NazgreksFlaskQuest == 0 or NazgreksFlaskQuest.completed or NazgreksFlaskQuest.active then
        return
    endif

    set FlaskStartRequested = true
    set EmptyFlaskRequirementRevealed = false
    set LastItemCount[2] = -1
    set LastItemCount[3] = -1
    set LastItemCount[4] = -1
    set LastItemCount[5] = -1
    set LastItemCount[6] = -1
    set LastItemCount[7] = -1
    call QuestGiver_AcceptQuest(NazgreksFlaskQuest.id)
    call DialogSystem_PlayLine(Nazgrek, "Nazgrek", VL_NAZGREK_0009_TEXT, VL_NAZGREK_0009_KEY, false)
    call TimerStart(EmptyFlaskReminderTimer, EMPTY_FLASK_REMINDER_DELAY, false, function OnEmptyFlaskReminder)
    call DebugMsg("Started Nazgrek's Flask.")
endfunction

private function CompleteWolfHuntI takes nothing returns nothing
    if WolfHuntIQuest == 0 or WolfHuntIQuest.completed then
        return
    endif

    if not IsRequirementCompleted(WolfHuntIQuest, 2) then
        call QuestGiver_SetRequirementCompleted(WolfHuntIQuest.id, 2, true)
    endif
    call QuestGiver_CompleteQuest(WolfHuntIQuest.id)
    set FlaskStartRequested = true
    call StartFlaskQuestInternal()
endfunction

private function IsTrackedWolfType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_WOLF_1 or unitTypeId == UNIT_WOLF_2 or unitTypeId == UNIT_WOLF_3 or unitTypeId == UNIT_ALPHA_WOLF
endfunction

private function UpdateWolfKillProgress takes nothing returns nothing
    if WolfHuntIQuest == 0 or not WolfHuntIQuest.active or WolfHuntIQuest.completed or WolfKills >= WOLF_KILL_REQUIRED then
        return
    endif

    set WolfKills = WolfKills + 1
    call WolfHuntIQuest.updateRequirementText(1, "Kill 6 wolves (" + I2S(WolfKills) + "/6)")
    call WolfHuntIQuest.refreshQuestLog()
    if WolfKills >= WOLF_KILL_REQUIRED and not IsRequirementCompleted(WolfHuntIQuest, 1) then
        call QuestGiver_SetRequirementCompleted(WolfHuntIQuest.id, 1, true)
    endif
    if WolfKills >= WOLF_KILL_REQUIRED and GetNazgrekItemCount(ITEM_WOLF_SKIN) >= WOLF_SKIN_REQUIRED then
        call CompleteWolfHuntI()
    endif
endfunction

private function UpdateWolfHuntI takes nothing returns nothing
    if WolfHuntIQuest == 0 or not WolfHuntIQuest.active or WolfHuntIQuest.completed then
        return
    endif

    call UpdateItemRequirement(WolfHuntIQuest, 2, ITEM_WOLF_SKIN, WOLF_SKIN_REQUIRED, 1)
    if WolfKills >= WOLF_KILL_REQUIRED and GetNazgrekItemCount(ITEM_WOLF_SKIN) >= WOLF_SKIN_REQUIRED then
        call CompleteWolfHuntI()
    endif
endfunction

private function OnAnyUnitDeath takes nothing returns nothing
    local unit dying = UnitDeathEvent_GetDyingUnit()
    local unit killer = UnitDeathEvent_GetKillingUnit()

    if dying != null and killer != null and GetOwningPlayer(killer) == Player(0) and IsTrackedWolfType(GetUnitTypeId(dying)) then
        call UpdateWolfKillProgress()
    endif
    set dying = null
    set killer = null
endfunction

private function CompleteFlaskQuest takes nothing returns nothing
    local integer index = 1

    if NazgreksFlaskQuest == 0 or NazgreksFlaskQuest.completed then
        return
    endif

    if not EmptyFlaskRequirementRevealed then
        call RevealEmptyFlaskRequirement(false)
    endif
    loop
        exitwhen index > 7
        if not IsRequirementCompleted(NazgreksFlaskQuest, index) then
            call QuestGiver_SetRequirementCompleted(NazgreksFlaskQuest.id, index, true)
        endif
        set index = index + 1
    endloop
    call PauseTimer(EmptyFlaskReminderTimer)
    call QuestGiver_CompleteQuest(NazgreksFlaskQuest.id)
    call PauseTimer(ProgressTimer)
    call DebugMsg("Completed Nazgrek's Flask.")
endfunction

private function UpdateFlaskQuest takes nothing returns nothing
    if NazgreksFlaskQuest == 0 or not NazgreksFlaskQuest.active or NazgreksFlaskQuest.completed then
        return
    endif

    if GetNazgrekItemCount(ITEM_NAZGREKS_FLASK) >= 1 then
        call CompleteFlaskQuest()
        return
    endif

    call UpdateItemRequirement(NazgreksFlaskQuest, 2, ITEM_FOREST_FLOWER, FOREST_FLOWER_REQUIRED, 2)
    call UpdateItemRequirement(NazgreksFlaskQuest, 3, ITEM_AGAVE, AGAVE_REQUIRED, 3)
    call UpdateItemRequirement(NazgreksFlaskQuest, 4, ITEM_EARTH_ROOTS, EARTH_ROOTS_REQUIRED, 4)
    call UpdateItemRequirement(NazgreksFlaskQuest, 5, ITEM_STAG_HAIR, STAG_HAIR_REQUIRED, 5)
    call UpdateItemRequirement(NazgreksFlaskQuest, 6, ITEM_FROG_SLIME, FROG_SLIME_REQUIRED, 6)
    if EmptyFlaskRequirementRevealed then
        call UpdateItemRequirement(NazgreksFlaskQuest, 7, ITEM_EMPTY_FLASK, EMPTY_FLASK_REQUIRED, 7)
    endif
endfunction

private function RefreshProgressInternal takes nothing returns nothing
    call SyncUnitReferences()
    call UpdateWolfHuntI()
    call UpdateFlaskQuest()
endfunction

private function OnProgressTimer takes nothing returns nothing
    call RefreshProgressInternal()
endfunction

private function StartWolfHuntIInternal takes nothing returns nothing
    if WolfHuntIQuest == 0 or WolfHuntIQuest.completed or WolfHuntIQuest.active then
        if WolfHuntIQuest != 0 and WolfHuntIQuest.completed then
            call StartFlaskQuestInternal()
        endif
        return
    endif

    set IntroStartRequested = true
    set WolfKills = 0
    set LastItemCount[1] = -1
    call QuestGiver_AcceptQuest(WolfHuntIQuest.id)
    call RefreshProgressInternal()
    call DebugMsg("Started Wolf Hunt I.")
endfunction

private function CanOfferWolfHuntI takes nothing returns boolean
    return IntroStartRequested
endfunction

private function CanOfferFlask takes nothing returns boolean
    return FlaskStartRequested or (WolfHuntIQuest != 0 and WolfHuntIQuest.completed)
endfunction

private function CreateQuests takes nothing returns nothing
    local string infoText = "|cffffcc00Source:|r Self-discovered\n|cffffcc00Zone:|r Sereneglade (2)\n"
    local trigger availabilityCondition

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_WOLF_HUNT_I, Nazgrek) then
        set WolfHuntIQuest = QuestGiver_CreateConfiguredQuest(QUEST_WOLF_HUNT_I, Nazgrek, "normal", 1, null, QUEST_WOLF_HUNT_I, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Hunt the wolves prowling Sereneglade and keep enough skins for the work ahead.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, true, true, false, "", "")
        call QuestGiver_SetQuestRewards(WolfHuntIQuest, false, 0, false, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(WolfHuntIQuest, "story")
        call QuestGiver_SetRequirements(WolfHuntIQuest.id, "", "Kill 6 wolves (0/6)", "Gather 6 Wolf Skin (0/6)", "", "", "", "", "", "")
        call WolfHuntIQuest.setAutoComplete(true)
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferWolfHuntI))
        call QuestGiver_SetQuestCustomCondition(WolfHuntIQuest, availabilityCondition)
        call QuestGiver_SetStateByNameAndGiver(QUEST_WOLF_HUNT_I, Nazgrek, QUEST_STATE_UNAVAILABLE)
    else
        set WolfHuntIQuest = QuestGiver_GetByNameAndGiver(QUEST_WOLF_HUNT_I, Nazgrek)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_NAZGREKS_FLASK, Nazgrek) then
        set NazgreksFlaskQuest = QuestGiver_CreateConfiguredQuest(QUEST_NAZGREKS_FLASK, Nazgrek, "normal", 1, null, QUEST_NAZGREKS_FLASK, "ReplaceableTextures\\CommandButtons\\BTNVialFull.blp", "Gather the legacy reagents and use an alchemy cauldron to create Nazgrek's Flask before confronting the Wolf Mother.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, true, true, false, "", "")
        call QuestGiver_SetQuestRewards(NazgreksFlaskQuest, false, 0, false, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(NazgreksFlaskQuest, "story")
        call QuestGiver_SetRequirements(NazgreksFlaskQuest.id, "", "Create Nazgrek's Flask", "Gather 6 Forest Flower (0/6)", "Gather 3 Agave (0/3)", "Gather 2 Earth Roots (0/2)", "Gather 6 Stag Hair (0/6)", "Gather 2 Frog Slime (0/2)", "", "")
        call NazgreksFlaskQuest.setAutoComplete(true)
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferFlask))
        call QuestGiver_SetQuestCustomCondition(NazgreksFlaskQuest, availabilityCondition)
        call QuestGiver_SetStateByNameAndGiver(QUEST_NAZGREKS_FLASK, Nazgrek, QUEST_STATE_UNAVAILABLE)
    else
        set NazgreksFlaskQuest = QuestGiver_GetByNameAndGiver(QUEST_NAZGREKS_FLASK, Nazgrek)
    endif
    set availabilityCondition = null
endfunction

private function InitDelayed takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()

    call SyncUnitReferences()
    if Nazgrek == null then
        if not InitWaitingLogged then
            call DebugMsg("Waiting for Nazgrek's unit reference.")
            set InitWaitingLogged = true
        endif
        call TimerStart(expiredTimer, 0.50, false, function InitDelayed)
        set expiredTimer = null
        return
    endif

    call CreateQuests()
    call QuestMaster_SetGiverIconsSuppressed(Nazgrek, true)
    call UnitDeathEvent_Register(function OnAnyUnitDeath)
    set Initialized = true
    call TimerStart(ProgressTimer, PROGRESS_INTERVAL, true, function OnProgressTimer)
    if IntroStartRequested then
        call StartWolfHuntIInternal()
    elseif FlaskStartRequested then
        call StartFlaskQuestInternal()
    endif
    call DestroyTimer(expiredTimer)
    set InitTimer = null
    set expiredTimer = null
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set InitTimer = CreateTimer()
    set ProgressTimer = CreateTimer()
    set EmptyFlaskReminderTimer = CreateTimer()
    call TimerStart(InitTimer, 0.00, false, function InitDelayed)
endfunction

public function StartIntroQuestChain takes nothing returns nothing
    set IntroStartRequested = true
    if Initialized then
        call StartWolfHuntIInternal()
    endif
endfunction

public function StartFlaskQuest takes nothing returns nothing
    set FlaskStartRequested = true
    if Initialized then
        call StartFlaskQuestInternal()
    endif
endfunction

public function RefreshProgress takes nothing returns nothing
    if Initialized then
        call RefreshProgressInternal()
    endif
endfunction

public function IsWolfHuntICompleted takes nothing returns boolean
    return WolfHuntIQuest != 0 and WolfHuntIQuest.completed
endfunction

public function IsFlaskCompleted takes nothing returns boolean
    return NazgreksFlaskQuest != 0 and NazgreksFlaskQuest.completed
endfunction
endlibrary
