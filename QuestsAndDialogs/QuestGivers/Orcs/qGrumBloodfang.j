/**
    qGrumBloodfang

    Author: Valdemar
    Version:

    Description:
    Converts Grum Bloodfang's four-quest Emberpeak dragon-hunt chain and
    periodic drake attack from the recovered legacy GUI triggers.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/GrumBloodfang.

    How to install:
    Import after the quest/dialog systems, UnitDeathEvent, HeroItemCheck,
    and the Grum Bloodfang and Nazgrek voiceline libraries. Keep Grum's
    placed-unit global and the two referenced Emberpeak rects.

    API:
    - qGrumBloodfang_AreEggsDelivered()
    - qGrumBloodfang_IsMordraxDefeated()
    - qGrumBloodfang_IsDragonChainComplete()
    - qGrumBloodfang_IsDrakeAttackActive()
    - qGrumBloodfang_StartDrakeAttack()
    - qGrumBloodfang_RefreshAvailability()
    - qGrumBloodfang_RefreshRespawnedUnitHooks()

**/
library qGrumBloodfang initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, UnitDeathEvent, VoicelinesGrumBloodfang, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_WHELPS_DESTRUCTION = "Whelps of Destruction"
    public constant string QUEST_DRAGON_EGG_HUNT = "Dragon Egg Hunt"
    public constant string QUEST_DRAKE_HUNT = "Drake Hunt"
    public constant string QUEST_DESOLATOR = "The Desolator"
    private constant string GRUM_NAME = "Grum Bloodfang"

    private constant integer ITEM_WHELP_SCALE = 'I00S'
    private constant integer ITEM_DRAGON_EGG = 'I00P'
    private constant integer ITEM_MORDRAX_SCALE = 'I00T'
    private constant integer ITEM_REINFORCED_LEATHER_GLOVES = 'I65X'
    private constant integer ITEM_DRAGONSLAYER_SWORD = 'I00U'

    private constant integer UNIT_SCORCHING_DRAKE_10 = 'n63D'
    private constant integer UNIT_RED_DRAKE_10 = 'n63G'
    private constant integer UNIT_SCORCHING_DRAKE_20 = 'n657'
    private constant integer UNIT_RED_DRAKE_20 = 'n65A'
    private constant integer UNIT_SPEARTHROWER_12 = 'o003'
    private constant integer DRAKE_RAID_OWNER = 11
    private constant integer DRAKE_KILL_COUNT = 6

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00
    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = false
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 750.00
    private constant real CAMERA_Z_OFFSET = 100.00
    private constant real CAMERA_ANGLE = 358.00
    private constant real CAMERA_ROT_OFFSET = 0.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 75.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private constant real DRAKE_RAID_MIN_DELAY = 180.00
    private constant real DRAKE_RAID_MAX_DELAY = 300.00
    private constant real DRAKE_RAID_FOLLOWUP_DELAY = 15.00
    private constant real DRAKE_RAID_BARK_RANGE = 1500.00

    private unit Grum = null
    private unit Nazgrek = null
    private unit SelectedHero = null
    private unit RaidDrake = null
    private unit RaidSpearthrower = null
    private dialog GrumDialog = null
    private timer GrumDialogCooldown = null
    private timer DrakeRaidTimer = null
    private timer DrakeRaidFollowupTimer = null
    private group RaidSearchGroup = null
    private integer DrakeKills = 0
    private boolean DrakeRaidActive = false
    private boolean RuntimeRegistered = false
    private boolean GrumInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cffff6633[qGrumBloodfang]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Grum != null and udg_Grum != Grum then
        set Grum = udg_Grum
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Grum, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetGrumQuest takes string questName returns QuestData
    call SyncUnitReferences()
    if Grum == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(questName, Grum)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    local unit hero = SelectedHero
    set SelectedHero = null
    call DialogInteraction_StartConfiguredDialogExitTransition(Grum, hero, GrumDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    set hero = null
endfunction

private function IsTrackedDrakeType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_SCORCHING_DRAKE_10 or unitTypeId == UNIT_RED_DRAKE_10 or unitTypeId == UNIT_SCORCHING_DRAKE_20 or unitTypeId == UNIT_RED_DRAKE_20
endfunction

private function UpdateDrakeHuntProgress takes nothing returns nothing
    local QuestData q = GetGrumQuest(QUEST_DRAKE_HUNT)
    if q == 0 or not q.active or q.completed or DrakeKills >= DRAKE_KILL_COUNT then
        set q = 0
        return
    endif
    set DrakeKills = DrakeKills + 1
    call q.updateRequirementText(1, "Kill 6 aggressive drakes (" + I2S(DrakeKills) + " / 6)")
    call QuestMaster_ShowUpdateMessage(q.id, "Drakes killed: " + I2S(DrakeKills) + " / 6")
    if DrakeKills >= DRAKE_KILL_COUNT then
        call q.markRequirementCompleted(1, true)
        call q.addReturnRequirement()
        call q.setState(QUEST_STATE_READY_TURNIN)
        call QuestGiver_RefreshAvailabilityForGiver(Grum)
    endif
    call q.refreshQuestLog()
    set q = 0
endfunction

private function FindRaidSpearthrower takes nothing returns nothing
    local unit u
    set RaidSpearthrower = null
    call GroupEnumUnitsInRect(RaidSearchGroup, gg_rct_GrumBloodfangArea, null)
    loop
        set u = FirstOfGroup(RaidSearchGroup)
        exitwhen u == null
        call GroupRemoveUnit(RaidSearchGroup, u)
        if RaidSpearthrower == null and GetUnitTypeId(u) == UNIT_SPEARTHROWER_12 and DialogInteraction_IsUnitAlive(u) then
            set RaidSpearthrower = u
        endif
    endloop
    set u = null
endfunction

private function HasPlayerUnitNearGrum takes nothing returns boolean
    local unit u
    local boolean found = false
    call GroupEnumUnitsInRange(RaidSearchGroup, GetUnitX(Grum), GetUnitY(Grum), DRAKE_RAID_BARK_RANGE, null)
    loop
        set u = FirstOfGroup(RaidSearchGroup)
        exitwhen u == null
        call GroupRemoveUnit(RaidSearchGroup, u)
        if not found and GetOwningPlayer(u) == Player(0) and DialogInteraction_IsUnitAlive(u) then
            set found = true
        endif
    endloop
    set u = null
    return found
endfunction

private function PlayRaidStartBark takes nothing returns nothing
    local integer seq
    if not HasPlayerUnitNearGrum() or DialogSystem_IsSequenceActive() then
        return
    endif
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    if DialogInteraction_IsUnitAlive(RaidSpearthrower) then
        call DialogSystem_AddLine(seq, RaidSpearthrower, "Orc Spearthrower", VL_GRUMBLOODFANG_0062_TEXT, VL_GRUMBLOODFANG_0062_KEY, true)
    endif
    if DialogInteraction_IsUnitAlive(Grum) then
        call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0063_TEXT, VL_GRUMBLOODFANG_0063_KEY, true)
    endif
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
endfunction

private function OnDrakeRaidFollowup takes nothing returns nothing
    local integer seq
    if DrakeRaidActive and HasPlayerUnitNearGrum() and not DialogSystem_IsSequenceActive() then
        set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
        if GetRandomInt(1, 2) == 1 then
            if DialogInteraction_IsUnitAlive(RaidSpearthrower) then
                call DialogSystem_AddLine(seq, RaidSpearthrower, "Orc Spearthrower", VL_GRUMBLOODFANG_0064_TEXT, VL_GRUMBLOODFANG_0064_KEY, true)
            endif
            if DialogInteraction_IsUnitAlive(Grum) then
                call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0066_TEXT, VL_GRUMBLOODFANG_0066_KEY, true)
            endif
        elseif DialogInteraction_IsUnitAlive(Grum) then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0065_TEXT, VL_GRUMBLOODFANG_0065_KEY, true)
        endif
        call DialogSystem_PlaySequence(seq, Player(0), Grum)
    endif
    set DrakeRaidActive = false
    set RaidSpearthrower = null
endfunction

private function StartDrakeRaidInternal takes nothing returns nothing
    local real spawnX
    local real spawnY
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Grum) then
        return
    endif
    if DialogInteraction_IsUnitAlive(RaidDrake) then
        return
    endif
    set RaidDrake = null
    set DrakeRaidActive = true
    call SetWidgetLife(Grum, GetUnitState(Grum, UNIT_STATE_MAX_LIFE))
    set spawnX = GetRectCenterX(gg_rct_EmberpeakDrakeSpawn01)
    set spawnY = GetRectCenterY(gg_rct_EmberpeakDrakeSpawn01)
    set RaidDrake = CreateUnit(Player(DRAKE_RAID_OWNER), UNIT_SCORCHING_DRAKE_10, spawnX, spawnY, bj_UNIT_FACING)
    call IssuePointOrder(RaidDrake, "attack", GetUnitX(Grum), GetUnitY(Grum))
    call FindRaidSpearthrower()
    if DialogInteraction_IsUnitAlive(RaidSpearthrower) then
        call SetUnitFacing(RaidSpearthrower, bj_RADTODEG * Atan2(spawnY - GetUnitY(RaidSpearthrower), spawnX - GetUnitX(RaidSpearthrower)))
    endif
    if SelectedHero != null then
        if GrumDialog != null then
            call DialogSystem_HideDialog(GrumDialog, Player(0))
        endif
        call DialogInteraction_CancelActiveTransition()
        call DialogSystem_CancelActiveSpeech()
        call StartExitFadeOut()
    endif
    call PlayRaidStartBark()
    call TimerStart(DrakeRaidFollowupTimer, DRAKE_RAID_FOLLOWUP_DELAY, false, function OnDrakeRaidFollowup)
endfunction

private function OnDrakeRaidTimer takes nothing returns nothing
    call StartDrakeRaidInternal()
    call TimerStart(DrakeRaidTimer, GetRandomReal(DRAKE_RAID_MIN_DELAY, DRAKE_RAID_MAX_DELAY), false, function OnDrakeRaidTimer)
endfunction

private function OnAnyUnitDeath takes nothing returns nothing
    local unit dying = UnitDeathEvent_GetDyingUnit()
    local integer unitTypeId
    if dying == null then
        return
    endif
    set unitTypeId = GetUnitTypeId(dying)
    if dying == RaidDrake then
        set RaidDrake = null
        set RaidSpearthrower = null
        set DrakeRaidActive = false
        call PauseTimer(DrakeRaidFollowupTimer)
    endif
    if IsTrackedDrakeType(unitTypeId) then
        call UpdateDrakeHuntProgress()
    endif
    set dying = null
endfunction

private function OnAcceptWhelpsEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_WHELPS_DESTRUCTION, Grum)
    call StartExitFadeOut()
endfunction

private function OnAcceptWhelps takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0020_TEXT, VL_GRUMBLOODFANG_0020_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0021_TEXT, VL_GRUMBLOODFANG_0021_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0022_TEXT, VL_GRUMBLOODFANG_0022_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0292_TEXT, VL_NAZGREK_0292_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0023_TEXT, VL_GRUMBLOODFANG_0023_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptWhelpsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function OnCompleteWhelpsEnd takes nothing returns nothing
    local QuestData q = GetGrumQuest(QUEST_WHELPS_DESTRUCTION)
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_WHELP_SCALE, 10) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_WHELP_SCALE, 0, 10)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_WHELPS_DESTRUCTION, Grum)
        call QuestGiver_RefreshAvailabilityForGiver(Grum)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteWhelps takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0026_TEXT, VL_GRUMBLOODFANG_0026_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0027_TEXT, VL_GRUMBLOODFANG_0027_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteWhelpsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
endfunction

private function OnAcceptEggsEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_DRAGON_EGG_HUNT, Grum)
    call StartExitFadeOut()
endfunction

private function OnAcceptEggs takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0031_TEXT, VL_GRUMBLOODFANG_0031_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0032_TEXT, VL_GRUMBLOODFANG_0032_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0033_TEXT, VL_GRUMBLOODFANG_0033_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0303_TEXT, VL_NAZGREK_0303_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0035_TEXT, VL_GRUMBLOODFANG_0035_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptEggsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function OnCompleteEggsEnd takes nothing returns nothing
    local QuestData q = GetGrumQuest(QUEST_DRAGON_EGG_HUNT)
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_DRAGON_EGG, 6) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_DRAGON_EGG, 0, 6)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_DRAGON_EGG_HUNT, Grum)
        call QuestGiver_RefreshAvailabilityForGiver(Grum)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteEggs takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0036_TEXT, VL_GRUMBLOODFANG_0036_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0037_TEXT, VL_GRUMBLOODFANG_0037_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0307_TEXT, VL_NAZGREK_0307_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0038_TEXT, VL_GRUMBLOODFANG_0038_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteEggsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function OnAcceptDrakesEnd takes nothing returns nothing
    set DrakeKills = 0
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_DRAKE_HUNT, Grum)
    call StartExitFadeOut()
endfunction

private function OnAcceptDrakes takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0042_TEXT, VL_GRUMBLOODFANG_0042_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0043_TEXT, VL_GRUMBLOODFANG_0043_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptDrakesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
endfunction

private function OnCompleteDrakesEnd takes nothing returns nothing
    local QuestData q = GetGrumQuest(QUEST_DRAKE_HUNT)
    if q != 0 and q.active and not q.completed and q.state == QUEST_STATE_READY_TURNIN then
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_DRAKE_HUNT, Grum)
        call QuestGiver_RefreshAvailabilityForGiver(Grum)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteDrakes takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0316_TEXT, VL_NAZGREK_0316_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0046_TEXT, VL_GRUMBLOODFANG_0046_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0047_TEXT, VL_GRUMBLOODFANG_0047_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteDrakesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function OnAcceptDesolatorEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_DESOLATOR, Grum)
    call StartExitFadeOut()
endfunction

private function OnAcceptDesolator takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0051_TEXT, VL_GRUMBLOODFANG_0051_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0052_TEXT, VL_GRUMBLOODFANG_0052_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0323_TEXT, VL_NAZGREK_0323_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0053_TEXT, VL_GRUMBLOODFANG_0053_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0054_TEXT, VL_GRUMBLOODFANG_0054_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptDesolatorEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function OnCompleteDesolatorEnd takes nothing returns nothing
    local QuestData q = GetGrumQuest(QUEST_DESOLATOR)
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_MORDRAX_SCALE, 1) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_MORDRAX_SCALE, 0, 1)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_DESOLATOR, Grum)
        call QuestGiver_RefreshAvailabilityForGiver(Grum)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteDesolator takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0327_TEXT, VL_NAZGREK_0327_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0057_TEXT, VL_GRUMBLOODFANG_0057_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0058_TEXT, VL_GRUMBLOODFANG_0058_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0059_TEXT, VL_GRUMBLOODFANG_0059_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteDesolatorEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(Grum, GRUM_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Grum)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    if GrumDialog == null then
        set GrumDialog = DialogSystem_CreateDialog(GRUM_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Grum)
    call DialogSystem_ClearDialog(GrumDialog)
    call DialogSystem_SetTitle(GrumDialog, GRUM_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(GrumDialog, QUEST_WHELPS_DESTRUCTION, Grum, 1, function OnAcceptWhelps, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(GrumDialog, QUEST_WHELPS_DESTRUCTION, Grum, 2, function OnCompleteWhelps, true)
    call QuestGiver_AddAvailableQuestAcceptButton(GrumDialog, QUEST_DRAGON_EGG_HUNT, Grum, 3, function OnAcceptEggs, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(GrumDialog, QUEST_DRAGON_EGG_HUNT, Grum, 4, function OnCompleteEggs, true)
    call QuestGiver_AddAvailableQuestAcceptButton(GrumDialog, QUEST_DRAKE_HUNT, Grum, 5, function OnAcceptDrakes, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(GrumDialog, QUEST_DRAKE_HUNT, Grum, 6, function OnCompleteDrakes, false)
    call QuestGiver_AddAvailableQuestAcceptButton(GrumDialog, QUEST_DESOLATOR, Grum, 7, function OnAcceptDesolator, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(GrumDialog, QUEST_DESOLATOR, Grum, 8, function OnCompleteDesolator, true)
    set b = DialogSystem_AddFarewellButton(GrumDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddFirstDialogGreeting takes integer seq returns nothing
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0288_TEXT, VL_NAZGREK_0288_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0001_TEXT, VL_GRUMBLOODFANG_0001_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0002_TEXT, VL_GRUMBLOODFANG_0002_KEY, true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0290_TEXT, VL_NAZGREK_0290_KEY, true)
    call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0003_TEXT, VL_GRUMBLOODFANG_0003_KEY, true)
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    local QuestData whelps = GetGrumQuest(QUEST_WHELPS_DESTRUCTION)
    local QuestData eggs = GetGrumQuest(QUEST_DRAGON_EGG_HUNT)
    local QuestData drakes = GetGrumQuest(QUEST_DRAKE_HUNT)
    local QuestData desolator = GetGrumQuest(QUEST_DESOLATOR)
    local integer pick = GetRandomInt(1, 2)
    if whelps != 0 and whelps.active and not whelps.completed then
        if pick == 1 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0024_TEXT, VL_GRUMBLOODFANG_0024_KEY, true)
        else
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0025_TEXT, VL_GRUMBLOODFANG_0025_KEY, true)
        endif
    elseif eggs != 0 and eggs.active and not eggs.completed then
        if pick == 1 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0034_TEXT, VL_GRUMBLOODFANG_0034_KEY, true)
        else
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0035_TEXT, VL_GRUMBLOODFANG_0035_KEY, true)
        endif
    elseif drakes != 0 and drakes.active and not drakes.completed then
        if pick == 1 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0044_TEXT, VL_GRUMBLOODFANG_0044_KEY, true)
        else
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0045_TEXT, VL_GRUMBLOODFANG_0045_KEY, true)
        endif
    elseif desolator != 0 and desolator.active and not desolator.completed then
        if pick == 1 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0055_TEXT, VL_GRUMBLOODFANG_0055_KEY, true)
        else
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0056_TEXT, VL_GRUMBLOODFANG_0056_KEY, true)
        endif
    else
        set pick = GetRandomInt(1, 4)
        if pick == 1 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0006_TEXT, VL_GRUMBLOODFANG_0006_KEY, true)
        elseif pick == 2 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0007_TEXT, VL_GRUMBLOODFANG_0007_KEY, true)
        elseif pick == 3 then
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0008_TEXT, VL_GRUMBLOODFANG_0008_KEY, true)
        else
            call DialogSystem_AddLine(seq, Grum, GRUM_NAME, VL_GRUMBLOODFANG_0009_TEXT, VL_GRUMBLOODFANG_0009_KEY, true)
        endif
    endif
    set whelps = 0
    set eggs = 0
    set drakes = 0
    set desolator = 0
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq
    if not DialogInteraction_IsFirstGreetDone(Grum) then
        set seq = DialogInteraction_CreateBaseSequence(Grum, GRUM_NAME)
        call AddFirstDialogGreeting(seq)
        call DialogInteraction_PlayFirstGreetSequenceEx(Grum, Player(0), GrumDialog, seq, CINEMATIC)
    else
        set seq = DialogInteraction_CreateGreetSequenceBase(Grum, GRUM_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
        call AddPreDialogBark(seq)
        call DialogInteraction_PlayGreetSequenceEx(seq, Grum, Player(0), GrumDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Grum) or DrakeRaidActive then
        call StartExitFadeOut()
        return
    endif
    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif
    call BuildDialog()
    call PlayDialogGreeting(hero)
    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Grum) or DrakeRaidActive then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Grum, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Grum, SelectedHero, DIALOG_RANGE, GrumDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Grum, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qGrumBloodfang_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + GRUM_NAME + "\n|cffffcc00Zone:|r Emberpeak Highlands (3)\n"
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_WHELPS_DESTRUCTION, Grum) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_WHELPS_DESTRUCTION, Grum, "normal", 10, null, QUEST_WHELPS_DESTRUCTION, "ReplaceableTextures\\CommandButtons\\BTNFireBolt.blp", "Cull the dangerous dragon whelps threatening Emberpeak and return their scales as proof to Grum Bloodfang.\n\n", infoText, "|cffffcc00Recommended level:|r 10\n\n", 7, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRUM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "", "Bring 10 Whelp Scales to Grum Bloodfang", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Grum, 1, ITEM_WHELP_SCALE, 10)
    endif
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_DRAGON_EGG_HUNT, Grum) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_DRAGON_EGG_HUNT, Grum, "normal", 10, null, QUEST_DRAGON_EGG_HUNT, "ReplaceableTextures\\CommandButtons\\BTNINV_Food_Egg_03.TGA", "Recover six unhatched dragon eggs from Emberpeak and bring them to Grum, who refuses to explain what will happen to them.\n\n", infoText, "|cffffcc00Recommended level:|r 10\n\n", 7, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRUM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 100, true, 300, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_WHELPS_DESTRUCTION, Grum)
        call QuestGiver_SetRequirements(q.id, "", "Bring 6 Dragon Eggs to Grum Bloodfang", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Grum, 1, ITEM_DRAGON_EGG, 6)
    endif
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_DRAKE_HUNT, Grum) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_DRAKE_HUNT, Grum, "normal", 12, null, QUEST_DRAKE_HUNT, "ReplaceableTextures\\CommandButtons\\BTNRedDragon.blp", "Hunt aggressive red and scorching drakes around Emberpeak before they burn the surrounding lands.\n\n", infoText, "|cffffcc00Recommended level:|r 12\n\n", 9, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRUM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 200, true, 400, false, 0, false, 0, false)
        call q.setRewardItemType(ITEM_REINFORCED_LEATHER_GLOVES)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_DRAGON_EGG_HUNT, Grum)
        call QuestGiver_SetRequirements(q.id, "", "Kill 6 aggressive drakes (0 / 6)", "", "", "", "", "", "", "")
    endif
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_DESOLATOR, Grum) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_DESOLATOR, Grum, "normal", 15, null, QUEST_DESOLATOR, "ReplaceableTextures\\CommandButtons\\BTNDragonRoost.blp", "Defeat Mordrax the Desolator and bring one of the ancient dragon's shattered scales to Grum Bloodfang.\n\n", infoText, "|cffffcc00Recommended level:|r 15\n\n", 12, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRUM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 400, true, 600, false, 0, false, 0, false)
        call q.setRewardItemType(ITEM_DRAGONSLAYER_SWORD)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_DRAKE_HUNT, Grum)
        call QuestGiver_SetRequirements(q.id, "", "Bring the Scale of Mordrax to Grum Bloodfang", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Grum, 1, ITEM_MORDRAX_SCALE, 1)
    endif
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Grum, VL_GRUMBLOODFANG_0004_TEXT, VL_GRUMBLOODFANG_0004_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(Grum, VL_GRUMBLOODFANG_0005_TEXT, VL_GRUMBLOODFANG_0005_KEY, true)
endfunction

private function RegisterRuntime takes nothing returns nothing
    if RuntimeRegistered then
        return
    endif
    set RuntimeRegistered = true
    call UnitDeathEvent_Register(function OnAnyUnitDeath)
    call TimerStart(DrakeRaidTimer, GetRandomReal(DRAKE_RAID_MIN_DELAY, DRAKE_RAID_MAX_DELAY), false, function OnDrakeRaidTimer)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Grum == null or Nazgrek == null then
        if not GrumInitWaitingLogged then
            call DebugMsg("Waiting for Grum and Nazgrek.")
            set GrumInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Grum)
    call DialogInteraction_ConfigureDialogTransition(Grum, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call RegisterDialogLines()
    call RegisterRuntime()
    call DialogInteraction_RegisterSelectionHandler(Grum, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Grum)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set GrumDialogCooldown = CreateTimer()
    set DrakeRaidTimer = CreateTimer()
    set DrakeRaidFollowupTimer = CreateTimer()
    set RaidSearchGroup = CreateGroup()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function AreEggsDelivered takes nothing returns boolean
    call SyncUnitReferences()
    return Grum != null and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_DRAGON_EGG_HUNT, Grum)
endfunction

public function IsMordraxDefeated takes nothing returns boolean
    call SyncUnitReferences()
    return Grum != null and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_DESOLATOR, Grum)
endfunction

public function IsDragonChainComplete takes nothing returns boolean
    return IsMordraxDefeated()
endfunction

public function IsDrakeAttackActive takes nothing returns boolean
    return DrakeRaidActive
endfunction

public function StartDrakeAttack takes nothing returns nothing
    call StartDrakeRaidInternal()
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Grum != null then
        call QuestGiver_RefreshAvailabilityForGiver(Grum)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Grum != null then
        call QuestGiver_Register(Grum)
        call DialogInteraction_ConfigureDialogTransition(Grum, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Grum, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
