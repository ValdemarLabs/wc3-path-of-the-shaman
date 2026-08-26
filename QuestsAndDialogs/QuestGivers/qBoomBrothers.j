/**
    qBoomBrothers

    Author: Valdemar
    Version: 1.0.0

    Description:
    Converts the recovered Boom Brothers GUI quest chain, including the
    Mandatory Training escort, Atex Blix's betrayal, and Mad Blix completion.

    Credits:
    - QuestsAndDialogs/OLDGUI/BoomBrothers
    - QuestsAndDialogs/OLDGUI/AtexBlix

    How to install:
    Import after the quest/dialog systems, HeroItemCheck, FollowSystem,
    DamageEngine, DungeonBoomBrothersMine, BossMadBlix, and the Boom Brothers, Atex Blix,
    and Nazgrek voiceline libraries. Keep the referenced placed-unit globals
    and Boom Brothers quest rects. Disable both recovered legacy GUI folders.

    API:
    - qBoomBrothers_GetGiver()
    - qBoomBrothers_RefreshAvailability()
    - qBoomBrothers_RefreshRespawnedUnitHooks()
    - qBoomBrothers_ReportMadBlixDefeated()
    - qBoomBrothers_IsTrainingActive()
    - qBoomBrothers_IsMineClaimedByBlix()
    - qBoomBrothers_IsMineReclaimed()
    - qBoomBrothers_IsMineAccessGranted()

**/
library qBoomBrothers initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, FollowSystem, DamageEngine, DungeonBoomBrothersMine, BossMadBlix, Voicelines, VoicelinesBoomBrothers, VoicelinesAtexBlix, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_EXPLOSIVE_CRISIS = "Explosive Crisis"
    public constant string QUEST_BOOMSITE_COMPLIANCE = "Boomsite Compliance Inspection"
    public constant string QUEST_DUST_CULTURE = "Dust Isn't Just Dirt - It's Combustible Culture"
    public constant string QUEST_MANDATORY_TRAINING = "Mandatory Training"
    public constant string QUEST_BOOM_WILL_BE_BACK = "Boom Will Be Back"

    private constant string BOOM_NAME = "Boom Brothers"
    private constant string ATEX_NAME = "Atex Blix"
    private constant string MAD_BLIX_NAME = "Mad Blix"
    private constant integer ITEM_BARREL_EXPLOSIVES = 'I00F'
    private constant integer ITEM_SAFETY_INSTRUCTIONS = 'I012'
    private constant integer ITEM_CROWN_OF_KINGS = 'ckng'
    private constant integer UNIT_MAD_BLIX = 'n01B'
    private constant integer UNIT_TURRET = 'n01I'
    private constant integer ESCORT_OWNER = 18
    private constant integer BETRAYAL_OWNER = 11
    private constant integer DUNGEON_ZONE_ID = 104

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
    private constant real CAMERA_DIST = 750.00
    private constant real CAMERA_Z_OFFSET = 100.00
    private constant real CAMERA_ANGLE = 358.00
    private constant real CAMERA_ROT_OFFSET = 0.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 75.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true
    private constant real ESCORT_MAX_DISTANCE = 1800.00

    private unit BoomBrothers = null
    private unit AtexBlix = null
    private unit SelectedHero = null
    private unit TrainingHero = null
    private unit BetrayalTurret1 = null
    private unit BetrayalTurret2 = null
    private unit TemporaryMadBlix = null
    private dialog BoomDialog = null
    private timer BoomDialogCooldown = null
    private timer TrainingMonitorTimer = null
    private timer TravelBarkTimer = null
    private timer TemporaryMadBlixTimer = null
    private integer TrainingStage = 0
    private boolean TrainingActive = false
    private boolean MineClaimedByBlix = false
    private boolean MineReclaimed = false
    private boolean RuntimeRegistered = false
    private boolean BarrelExplosionProcessing = false
    private boolean InitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cffff6633[qBoomBrothers]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_BoomBrothers != null and udg_BoomBrothers != BoomBrothers then
        set BoomBrothers = udg_BoomBrothers
    endif
    if udg_AtexBlix != null and udg_AtexBlix != AtexBlix then
        set AtexBlix = udg_AtexBlix
    endif
endfunction

private function GetBoomQuest takes string questName returns QuestData
    call SyncUnitReferences()
    if BoomBrothers == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(questName, BoomBrothers)
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, BoomBrothers, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    local unit hero = SelectedHero
    set SelectedHero = null
    call DialogInteraction_StartConfiguredDialogExitTransition(BoomBrothers, hero, BoomDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    set hero = null
endfunction

private function IsAllowedHeroInRect takes rect whichRect returns boolean
    return whichRect != null and ((DialogInteraction_IsUnitAlive(udg_Nazgrek) and RectContainsUnit(whichRect, udg_Nazgrek)) or (DialogInteraction_IsUnitAlive(udg_Zulkis) and RectContainsUnit(whichRect, udg_Zulkis)))
endfunction

private function RemoveTemporaryMadBlix takes nothing returns nothing
    if TemporaryMadBlix != null then
        call RemoveUnit(TemporaryMadBlix)
        set TemporaryMadBlix = null
    endif
endfunction

private function OnTemporaryMadBlixTimer takes nothing returns nothing
    call RemoveTemporaryMadBlix()
endfunction

private function RemoveBetrayalTurrets takes nothing returns nothing
    if BetrayalTurret1 != null then
        call RemoveUnit(BetrayalTurret1)
        set BetrayalTurret1 = null
    endif
    if BetrayalTurret2 != null then
        call RemoveUnit(BetrayalTurret2)
        set BetrayalTurret2 = null
    endif
endfunction

private function CreateBetrayalTurrets takes nothing returns nothing
    call RemoveBetrayalTurrets()
    set BetrayalTurret1 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_TURRET, GetRectCenterX(gg_rct_BoomBrotherTurret1), GetRectCenterY(gg_rct_BoomBrotherTurret1), bj_UNIT_FACING)
    set BetrayalTurret2 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_TURRET, GetRectCenterX(gg_rct_BoomBrotherTurret2), GetRectCenterY(gg_rct_BoomBrotherTurret2), bj_UNIT_FACING)
endfunction

private function HideAtexForBetrayal takes nothing returns nothing
    if DialogInteraction_IsUnitAlive(AtexBlix) then
        call PauseUnit(AtexBlix, true)
        call ShowUnit(AtexBlix, false)
    endif
endfunction

private function OnTravelBark takes nothing returns nothing
    local integer pick
    if not TrainingActive or not DialogInteraction_IsUnitAlive(BoomBrothers) then
        return
    endif
    if not DialogSystem_IsSequenceActive() and not DialogSystem_IsFieldLineQueueActive() then
        set pick = GetRandomInt(1, 6)
        if pick == 1 then
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0060_KEY, VL_BOOMBROTHERS_0060_TEXT)
        elseif pick == 2 then
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0061_KEY, VL_BOOMBROTHERS_0061_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0062_KEY, VL_BOOMBROTHERS_0062_TEXT)
        elseif pick == 3 then
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0063_KEY, VL_BOOMBROTHERS_0063_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0064_KEY, VL_BOOMBROTHERS_0064_TEXT)
        elseif pick == 4 then
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0065_KEY, VL_BOOMBROTHERS_0065_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0066_KEY, VL_BOOMBROTHERS_0066_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0067_KEY, VL_BOOMBROTHERS_0067_TEXT)
        elseif pick == 5 then
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0068_KEY, VL_BOOMBROTHERS_0068_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0069_KEY, VL_BOOMBROTHERS_0069_TEXT)
        else
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0070_KEY, VL_BOOMBROTHERS_0070_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0071_KEY, VL_BOOMBROTHERS_0071_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0072_KEY, VL_BOOMBROTHERS_0072_TEXT)
            call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0073_KEY, VL_BOOMBROTHERS_0073_TEXT)
        endif
    endif
    call TimerStart(TravelBarkTimer, GetRandomReal(45.00, 105.00), false, function OnTravelBark)
endfunction

private function OnBetrayalSequenceEnd takes nothing returns nothing
    local QuestData q = GetBoomQuest(QUEST_MANDATORY_TRAINING)
    set TrainingActive = false
    set TrainingStage = 0
    set MineClaimedByBlix = true
    call PauseTimer(TravelBarkTimer)
    if BetrayalTurret1 != null then
        call SetUnitOwner(BetrayalTurret1, Player(BETRAYAL_OWNER), true)
        call IssueTargetOrder(BetrayalTurret1, "attack", BoomBrothers)
    endif
    if BetrayalTurret2 != null then
        call SetUnitOwner(BetrayalTurret2, Player(BETRAYAL_OWNER), true)
        call IssueTargetOrder(BetrayalTurret2, "attack", BoomBrothers)
    endif
    if TemporaryMadBlix != null then
        call IssuePointOrder(TemporaryMadBlix, "move", GetRectCenterX(gg_rct_BoomBrothersWP02), GetRectCenterY(gg_rct_BoomBrothersWP02))
        call TimerStart(TemporaryMadBlixTimer, 12.00, false, function OnTemporaryMadBlixTimer)
    endif
    if q != 0 and q.active and not q.completed then
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_MANDATORY_TRAINING, BoomBrothers)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    set TrainingHero = null
    set q = 0
endfunction

private function PlayBetrayalSequence takes nothing returns nothing
    local integer seq
    call RemoveTemporaryMadBlix()
    set TemporaryMadBlix = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_MAD_BLIX, GetRectCenterX(gg_rct_MadBlixPoint1), GetRectCenterY(gg_rct_MadBlixPoint1), bj_UNIT_FACING)
    if TemporaryMadBlix != null then
        call SetUnitPathing(TemporaryMadBlix, false)
        call IssuePointOrder(TemporaryMadBlix, "move", GetRectCenterX(gg_rct_BoomBrothersWP01), GetRectCenterY(gg_rct_BoomBrothersWP01))
    endif
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0077_TEXT, VL_BOOMBROTHERS_0077_KEY, true)
    call DialogSystem_AddLine(seq, TemporaryMadBlix, MAD_BLIX_NAME, VL_ATEXBLIX_0058_TEXT, VL_ATEXBLIX_0058_KEY, true)
    call DialogSystem_AddLine(seq, TemporaryMadBlix, MAD_BLIX_NAME, VL_ATEXBLIX_0059_TEXT, VL_ATEXBLIX_0059_KEY, true)
    call DialogInteraction_AddHeroLine(seq, TrainingHero, VL_NAZGREK_0278_TEXT, VL_NAZGREK_0278_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0083_TEXT, VL_BOOMBROTHERS_0083_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0078_TEXT, VL_BOOMBROTHERS_0078_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0079_TEXT, VL_BOOMBROTHERS_0079_KEY, true)
    call DialogSystem_AddLine(seq, TemporaryMadBlix, MAD_BLIX_NAME, VL_ATEXBLIX_0060_TEXT, VL_ATEXBLIX_0060_KEY, true)
    call DialogSystem_AddLine(seq, TemporaryMadBlix, MAD_BLIX_NAME, VL_ATEXBLIX_0061_TEXT, VL_ATEXBLIX_0061_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnBetrayalSequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
endfunction

private function ReachKoboldCamp takes nothing returns nothing
    local QuestData q = GetBoomQuest(QUEST_MANDATORY_TRAINING)
    set TrainingStage = 2
    call HideAtexForBetrayal()
    call CreateBetrayalTurrets()
    if q != 0 then
        call q.markRequirementCompleted(1, true)
        call q.updateRequirementText(2, "Return with the Boom Brothers to the Boom Mine entrance")
        call q.refreshQuestLog()
        call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80ff80Objective completed:|r Reach the kobold safety camp\n|cff80a0ffNew objective:|r Return with the Boom Brothers to the Boom Mine entrance.")
    endif
    call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0074_KEY, VL_BOOMBROTHERS_0074_TEXT)
    call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0075_KEY, VL_BOOMBROTHERS_0075_TEXT)
    call DialogSystem_QueueFieldLine(BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0076_KEY, VL_BOOMBROTHERS_0076_TEXT)
    if TrainingHero == udg_Nazgrek then
        call DialogSystem_QueueFieldLine(TrainingHero, DialogInteraction_GetHeroName(TrainingHero), VL_NAZGREK_0277_KEY, VL_NAZGREK_0277_TEXT)
    endif
    set q = 0
endfunction

private function ReturnToBoomMine takes nothing returns nothing
    set TrainingStage = 3
    call PauseTimer(TravelBarkTimer)
    if FollowSystem_IsFollowing(BoomBrothers) then
        call FollowSystem_RemoveUnit(BoomBrothers)
    endif
    call SetUnitOwner(BoomBrothers, Player(PLAYER_NEUTRAL_PASSIVE), true)
    call IssueImmediateOrder(BoomBrothers, "stop")
    call PlayBetrayalSequence()
endfunction

private function OnTrainingMonitor takes nothing returns nothing
    if not TrainingActive or not DialogInteraction_IsUnitAlive(BoomBrothers) then
        return
    endif
    if TrainingStage == 1 and RectContainsUnit(gg_rct_KoboldCamp, BoomBrothers) and IsAllowedHeroInRect(gg_rct_KoboldCamp) then
        call ReachKoboldCamp()
    elseif TrainingStage == 2 and RectContainsUnit(gg_rct_BoomBrotherMineEntrance, BoomBrothers) and IsAllowedHeroInRect(gg_rct_BoomBrotherMineEntrance) then
        call ReturnToBoomMine()
    endif
endfunction

private function StartMandatoryTraining takes unit hero returns nothing
    set TrainingHero = hero
    set TrainingActive = true
    set TrainingStage = 1
    set MineClaimedByBlix = false
    call RemoveTemporaryMadBlix()
    call RemoveBetrayalTurrets()
    call SetUnitInvulnerable(BoomBrothers, true)
    call SetUnitOwner(BoomBrothers, Player(ESCORT_OWNER), true)
    call FollowSystem_SetFollow(BoomBrothers, hero, ESCORT_MAX_DISTANCE, true, 5.00, FOLLOW_STYLE_PASSIVE, true, true)
    call QuestGiver_GiveUniqueQuestItemToHero(hero, ITEM_SAFETY_INSTRUCTIONS, 0, "Safety Instructions")
    call TimerStart(TrainingMonitorTimer, 1.00, true, function OnTrainingMonitor)
    call TimerStart(TravelBarkTimer, GetRandomReal(45.00, 105.00), false, function OnTravelBark)
endfunction

private function OnAcceptExplosivesEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_EXPLOSIVE_CRISIS, BoomBrothers)
    call StartExitFadeOut()
endfunction

private function OnAcceptExplosives takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0010_TEXT, VL_BOOMBROTHERS_0010_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0011_TEXT, VL_BOOMBROTHERS_0011_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0012_TEXT, VL_BOOMBROTHERS_0012_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0262_TEXT, VL_NAZGREK_0262_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0015_TEXT, VL_BOOMBROTHERS_0015_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0016_TEXT, VL_BOOMBROTHERS_0016_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptExplosivesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnCompleteExplosivesEnd takes nothing returns nothing
    local QuestData q = GetBoomQuest(QUEST_EXPLOSIVE_CRISIS)
    local effect boomEffect
    if q != 0 and q.active and not q.completed and HeroItemCheckBothAndRemove(ITEM_BARREL_EXPLOSIVES, 6) then
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_EXPLOSIVE_CRISIS, BoomBrothers)
        set boomEffect = AddSpecialEffectTarget("Objects\\Spawnmodels\\Human\\HCancelDeath\\HCancelDeath.mdl", BoomBrothers, "chest")
        call DestroyEffect(boomEffect)
        call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    endif
    call StartExitFadeOut()
    set boomEffect = null
    set q = 0
endfunction

private function OnCompleteExplosives takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0264_TEXT, VL_NAZGREK_0264_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0019_TEXT, VL_BOOMBROTHERS_0019_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0020_TEXT, VL_BOOMBROTHERS_0020_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteExplosivesEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnAcceptComplianceEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_BOOMSITE_COMPLIANCE, BoomBrothers)
    call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    call StartExitFadeOut()
endfunction

private function OnAcceptCompliance takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0025_TEXT, VL_BOOMBROTHERS_0025_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0023_TEXT, VL_ATEXBLIX_0023_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0024_TEXT, VL_ATEXBLIX_0024_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0265_TEXT, VL_NAZGREK_0265_KEY)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0026_TEXT, VL_ATEXBLIX_0026_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0027_TEXT, VL_ATEXBLIX_0027_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptComplianceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnAcceptDustEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_DUST_CULTURE, BoomBrothers)
    call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    call StartExitFadeOut()
endfunction

private function OnAcceptDust takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0040_TEXT, VL_BOOMBROTHERS_0040_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0041_TEXT, VL_BOOMBROTHERS_0041_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0036_TEXT, VL_ATEXBLIX_0036_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0037_TEXT, VL_ATEXBLIX_0037_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0271_TEXT, VL_NAZGREK_0271_KEY)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0040_TEXT, VL_ATEXBLIX_0040_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptDustEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnAcceptTrainingEnd takes nothing returns nothing
    local unit hero = SelectedHero
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_MANDATORY_TRAINING, BoomBrothers)
    call StartMandatoryTraining(hero)
    call StartExitFadeOut()
    set hero = null
endfunction

private function OnAcceptTraining takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0050_TEXT, VL_ATEXBLIX_0050_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0051_TEXT, VL_ATEXBLIX_0051_KEY, true)
    call DialogSystem_AddLine(seq, AtexBlix, ATEX_NAME, VL_ATEXBLIX_0052_TEXT, VL_ATEXBLIX_0052_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0275_TEXT, VL_NAZGREK_0275_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0056_TEXT, VL_BOOMBROTHERS_0056_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0057_TEXT, VL_BOOMBROTHERS_0057_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0276_TEXT, VL_NAZGREK_0276_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0058_TEXT, VL_BOOMBROTHERS_0058_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0059_TEXT, VL_BOOMBROTHERS_0059_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptTrainingEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnAcceptFinalEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_BOOM_WILL_BE_BACK, BoomBrothers)
    call StartExitFadeOut()
endfunction

private function OnAcceptFinal takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0084_TEXT, VL_BOOMBROTHERS_0084_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0085_TEXT, VL_BOOMBROTHERS_0085_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0086_TEXT, VL_BOOMBROTHERS_0086_KEY, true)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0283_TEXT, VL_NAZGREK_0283_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0087_TEXT, VL_BOOMBROTHERS_0087_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0088_TEXT, VL_BOOMBROTHERS_0088_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptFinalEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnCompleteFinalEnd takes nothing returns nothing
    local QuestData q = GetBoomQuest(QUEST_BOOM_WILL_BE_BACK)
    if q != 0 and q.active and not q.completed and q.state == QUEST_STATE_READY_TURNIN then
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_BOOM_WILL_BE_BACK, BoomBrothers)
        set MineClaimedByBlix = false
        set MineReclaimed = true
        call RemoveBetrayalTurrets()
        call SetUnitInvulnerable(BoomBrothers, false)
        call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteFinal takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
    call DialogInteraction_AddHeroLine(seq, hero, VL_NAZGREK_0284_TEXT, VL_NAZGREK_0284_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0092_TEXT, VL_BOOMBROTHERS_0092_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0093_TEXT, VL_BOOMBROTHERS_0093_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0094_TEXT, VL_BOOMBROTHERS_0094_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteFinalEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(BoomBrothers, BOOM_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), BoomBrothers)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    if BoomDialog == null then
        set BoomDialog = DialogSystem_CreateDialog(BOOM_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    call DialogSystem_ClearDialog(BoomDialog)
    call DialogSystem_SetTitle(BoomDialog, BOOM_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(BoomDialog, QUEST_EXPLOSIVE_CRISIS, BoomBrothers, 1, function OnAcceptExplosives, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(BoomDialog, QUEST_EXPLOSIVE_CRISIS, BoomBrothers, 2, function OnCompleteExplosives, true)
    call QuestGiver_AddAvailableQuestAcceptButton(BoomDialog, QUEST_BOOMSITE_COMPLIANCE, BoomBrothers, 3, function OnAcceptCompliance, true, true)
    call QuestGiver_AddAvailableQuestAcceptButton(BoomDialog, QUEST_DUST_CULTURE, BoomBrothers, 4, function OnAcceptDust, true, true)
    call QuestGiver_AddAvailableQuestAcceptButton(BoomDialog, QUEST_MANDATORY_TRAINING, BoomBrothers, 5, function OnAcceptTraining, true, true)
    call QuestGiver_AddAvailableQuestAcceptButton(BoomDialog, QUEST_BOOM_WILL_BE_BACK, BoomBrothers, 6, function OnAcceptFinal, true, true)
    call QuestGiver_AddReadyQuestCompleteButton(BoomDialog, QUEST_BOOM_WILL_BE_BACK, BoomBrothers, 7, function OnCompleteFinal, false)
    set b = DialogSystem_AddFarewellButton(BoomDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddFirstDialogGreeting takes integer seq returns nothing
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0001_TEXT, VL_BOOMBROTHERS_0001_KEY, true)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0002_TEXT, VL_BOOMBROTHERS_0002_KEY, true)
    call DialogInteraction_AddHeroLine(seq, SelectedHero, VL_NAZGREK_0260_TEXT, VL_NAZGREK_0260_KEY)
    call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0003_TEXT, VL_BOOMBROTHERS_0003_KEY, true)
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    local QuestData explosive = GetBoomQuest(QUEST_EXPLOSIVE_CRISIS)
    local QuestData finalQuest = GetBoomQuest(QUEST_BOOM_WILL_BE_BACK)
    if explosive != 0 and explosive.active and not explosive.completed then
        call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0017_TEXT, VL_BOOMBROTHERS_0017_KEY, true)
    elseif finalQuest != 0 and finalQuest.active and not finalQuest.completed then
        call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0089_TEXT, VL_BOOMBROTHERS_0089_KEY, true)
    elseif MineReclaimed then
        call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0096_TEXT, VL_BOOMBROTHERS_0096_KEY, true)
    elseif GetRandomInt(1, 2) == 1 then
        call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0006_TEXT, VL_BOOMBROTHERS_0006_KEY, true)
    else
        call DialogSystem_AddLine(seq, BoomBrothers, BOOM_NAME, VL_BOOMBROTHERS_0007_TEXT, VL_BOOMBROTHERS_0007_KEY, true)
    endif
    set explosive = 0
    set finalQuest = 0
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq
    if not DialogInteraction_IsFirstGreetDone(BoomBrothers) then
        set seq = DialogInteraction_CreateBaseSequence(BoomBrothers, BOOM_NAME)
        call AddFirstDialogGreeting(seq)
        call DialogInteraction_PlayFirstGreetSequenceEx(BoomBrothers, Player(0), BoomDialog, seq, CINEMATIC)
    else
        set seq = DialogInteraction_CreateGreetSequenceBase(BoomBrothers, BOOM_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
        call AddPreDialogBark(seq)
        call DialogInteraction_PlayGreetSequenceEx(seq, BoomBrothers, Player(0), BoomDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(BoomBrothers) or TrainingActive then
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
    if not DialogInteraction_IsUnitAlive(BoomBrothers) or TrainingActive then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(BoomBrothers, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    // Betrayal turrets deliberately keep the invulnerable giver in combat.
    if not DialogInteraction_PassDialogSelectionGate(BoomBrothers, SelectedHero, DIALOG_RANGE, BoomDialogCooldown, true, true, true, false, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(BoomBrothers, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qBoomBrothers_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + BOOM_NAME + "\n|cffffcc00Zone:|r Sirensong (14)\n"
    local string explosiveHint = "|cffffcc00Hint:|r If the thieves leave no trail, Snikka Sparkdust, a goblin reagent merchant in Sirensong, is rumored to keep a few explosive barrels behind the counter for a steep price.\n\n"

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_EXPLOSIVE_CRISIS, BoomBrothers) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_EXPLOSIVE_CRISIS, BoomBrothers, "normal", 10, null, QUEST_EXPLOSIVE_CRISIS, "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp", "Recover or replace six Barrel of Explosives stolen from the Boom Brothers and return them before their mining claim stalls.\n\n" + explosiveHint, infoText, "|cffffcc00Recommended level:|r 10\n\n", 7, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", BOOM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "", "Bring 6 Barrel of Explosives to the Boom Brothers", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, BoomBrothers, 1, ITEM_BARREL_EXPLOSIVES, 6)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_BOOMSITE_COMPLIANCE, BoomBrothers) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_BOOMSITE_COMPLIANCE, BoomBrothers, "normal", 10, AtexBlix, QUEST_BOOMSITE_COMPLIANCE, "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp", "Bring piles of wood to Atex Blix for individual inspection until ten logs meet his reinforcement standards. Rejected logs are consumed during inspection.\n\n", infoText, "|cffffcc00Recommended level:|r 10\n\n", 7, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", ATEX_NAME)
        call QuestGiver_SetQuestRewards(q, true, 250, true, 250, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_EXPLOSIVE_CRISIS, BoomBrothers)
        call QuestGiver_SetRequirements(q.id, "", "Have Atex inspect suitable logs (0 / 10)", "", "", "", "", "", "", "")
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_DUST_CULTURE, BoomBrothers) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_DUST_CULTURE, BoomBrothers, "normal", 12, AtexBlix, QUEST_DUST_CULTURE, "ReplaceableTextures\\CommandButtons\\BTNWallOfFire.blp", "Acquire the three machines Atex demands for dust mitigation before the next sanctioned detonation.\n\n", infoText, "|cffffcc00Recommended level:|r 12\n\n", 9, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", ATEX_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_BOOMSITE_COMPLIANCE, BoomBrothers)
        call QuestGiver_SetRequirements(q.id, "", "Bring 1 Dust Collector M25 to Atex Blix", "Bring 1 Dustfilter 9000-BA to Atex Blix", "Bring 1 Vent-o-Matic Blower R200 to Atex Blix", "", "", "", "", "")
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MANDATORY_TRAINING, BoomBrothers) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_MANDATORY_TRAINING, BoomBrothers, "normal", 10, null, QUEST_MANDATORY_TRAINING, "ReplaceableTextures\\CommandButtons\\BTNGoblinSapper.blp", "Escort the Boom Brothers to the kobold-run safety camp, complete the formal training checklist, and bring them back to the Boom Mine entrance.\n\n", infoText, "|cffffcc00Recommended level:|r 10\n\n", 7, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", BOOM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_DUST_CULTURE, BoomBrothers)
        call QuestGiver_SetRequirements(q.id, "", "Escort the Boom Brothers to the kobold safety camp", "", "", "", "", "", "", "")
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_BOOM_WILL_BE_BACK, BoomBrothers) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_BOOM_WILL_BE_BACK, BoomBrothers, "dungeon", 15, null, QUEST_BOOM_WILL_BE_BACK, "ReplaceableTextures\\CommandButtons\\BTNJunkGolem.blp", "Enter Boom Mine, defeat Mad Blix, and return control of the mine to the Boom Brothers.\n\n", infoText, "|cffffcc00Recommended level:|r 15\n\n", 12, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", BOOM_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call q.setRewardItemType(ITEM_CROWN_OF_KINGS)
        call QuestGiver_SetQuestCategory(q, "dungeon")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_MANDATORY_TRAINING, BoomBrothers)
        call QuestGiver_SetRequirements(q.id, "", "Defeat Mad Blix in Boom Mine", "", "", "", "", "", "", "")
        call q.setTargetZone(DUNGEON_ZONE_ID)
    endif
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(BoomBrothers, VL_BOOMBROTHERS_0004_TEXT, VL_BOOMBROTHERS_0004_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(BoomBrothers, VL_BOOMBROTHERS_0005_TEXT, VL_BOOMBROTHERS_0005_KEY, true)
endfunction

private function RegisterSoundKeys takes nothing returns nothing
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0001_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0002_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0003_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0004_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0005_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0006_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0007_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0010_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0011_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0012_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0015_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0016_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0017_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0019_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0020_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0025_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0040_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0041_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0056_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0057_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0058_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0059_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0060_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0061_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0062_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0063_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0064_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0065_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0066_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0067_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0068_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0069_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0070_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0071_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0072_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0073_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0074_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0075_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0076_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0077_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0078_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0079_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0083_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0084_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0085_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0086_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0087_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0088_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0089_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0092_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0093_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0094_KEY)
    call Voicelines_RegisterKey(VL_BOOMBROTHERS_FOLDER, VL_BOOMBROTHERS_0096_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0260_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0262_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0264_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0265_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0271_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0275_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0276_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0277_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0278_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0283_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0284_KEY)
endfunction

private function OnCarriedBarrelDamaged takes nothing returns nothing
    local QuestData q
    local unit target
    local effect explosionEffect
    if BarrelExplosionProcessing then
        return
    endif
    set target = udg_DamageEventTarget
    if target != udg_Nazgrek and target != udg_Zulkis then
        set target = null
        return
    endif
    set q = GetBoomQuest(QUEST_EXPLOSIVE_CRISIS)
    if q != 0 and q.active and not q.completed and HeroItemCheck(target, ITEM_BARREL_EXPLOSIVES, 1) and GetRandomInt(1, 5) == 1 then
        set BarrelExplosionProcessing = true
        if HeroItemCheckAndRemove(target, ITEM_BARREL_EXPLOSIVES, 1) then
            set udg_DamageEventAmount = 600.00
            set explosionEffect = AddSpecialEffectTarget("Objects\\Spawnmodels\\Human\\HCancelDeath\\HCancelDeath.mdl", target, "chest")
            call DestroyEffect(explosionEffect)
        endif
        set BarrelExplosionProcessing = false
    endif
    set explosionEffect = null
    set target = null
    set q = 0
endfunction

private function RegisterRuntime takes nothing returns nothing
    if RuntimeRegistered then
        return
    endif
    set RuntimeRegistered = true
    call RegisterDamageEngine(function OnCarriedBarrelDamaged, "Modifier", 1.00)
    call TimerStart(TrainingMonitorTimer, 1.00, true, function OnTrainingMonitor)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if BoomBrothers == null or AtexBlix == null or udg_Nazgrek == null or DungeonBoomBrothersMine_GetDungeonId() == 0 or BossMadBlix_GetId() == 0 then
        if not InitWaitingLogged then
            call DebugMsg("Waiting for Boom Brothers, Atex Blix, Nazgrek, Boom Mine, and Mad Blix.")
            set InitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(BoomBrothers)
    call QuestGiver_Register(AtexBlix)
    call DialogInteraction_ConfigureDialogTransition(BoomBrothers, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call RegisterSoundKeys()
    call RegisterDialogLines()
    call RegisterRuntime()
    call DialogInteraction_RegisterSelectionHandler(BoomBrothers, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    call DestroyTimer(GetExpiredTimer())
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set BoomDialogCooldown = CreateTimer()
    set TrainingMonitorTimer = CreateTimer()
    set TravelBarkTimer = CreateTimer()
    set TemporaryMadBlixTimer = CreateTimer()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function GetGiver takes nothing returns unit
    call SyncUnitReferences()
    return BoomBrothers
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if BoomBrothers != null then
        call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    endif
    if AtexBlix != null then
        call QuestGiver_RefreshAvailabilityForGiver(AtexBlix)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if BoomBrothers != null then
        call QuestGiver_Register(BoomBrothers)
        call DialogInteraction_ConfigureDialogTransition(BoomBrothers, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(BoomBrothers, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

public function ReportMadBlixDefeated takes nothing returns nothing
    local QuestData q = GetBoomQuest(QUEST_BOOM_WILL_BE_BACK)
    if q != 0 and q.active and not q.completed and q.state != QUEST_STATE_READY_TURNIN then
        call q.markRequirementCompleted(1, true)
        call q.addReturnRequirement()
        call q.setState(QUEST_STATE_READY_TURNIN)
        call q.refreshQuestLog()
        set MineClaimedByBlix = false
        call QuestGiver_RefreshAvailabilityForGiver(BoomBrothers)
    endif
    set q = 0
endfunction

public function IsTrainingActive takes nothing returns boolean
    return TrainingActive
endfunction

public function IsMineClaimedByBlix takes nothing returns boolean
    return MineClaimedByBlix
endfunction

public function IsMineReclaimed takes nothing returns boolean
    local QuestData q = GetBoomQuest(QUEST_BOOM_WILL_BE_BACK)
    local boolean result = MineReclaimed or (q != 0 and q.completed)
    set q = 0
    return result
endfunction

public function IsMineAccessGranted takes nothing returns boolean
    return IsMineReclaimed()
endfunction

endlibrary
