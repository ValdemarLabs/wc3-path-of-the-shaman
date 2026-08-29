/**
    qKrezgrel

    Author: Valdemar
    Version: 1.0.0

    Description:
    Converts Krezgrel's Murloc Fins and Rescue The Grunts daily quests. The
    upside-down grunts use selectable invisible unit proxies paired with
    pitched special effects because Reforged ignores negative unit pitch.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Krezgrel.

    How to install:
    Import after the quest/dialog, Krezgrel, and Orc Grunt voiceline
    libraries. Remove the eight old World Editor placed upside-down grunts
    and retain rects gg_rct_UpsideGrunt01 through gg_rct_UpsideGrunt08.

    API:
    - qKrezgrel_GetRescuedGruntCount()
    - qKrezgrel_RebuildRescueTargets()
    - qKrezgrel_RefreshAvailability()
    - qKrezgrel_RefreshRespawnedUnitHooks()

**/
library qKrezgrel initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, VoicelinesKrezgrel, VoicelinesNazgrek, VoicelinesOrcGrunt

globals
    private constant boolean DEBUG = false

    public constant string QUEST_MURLOC_FINS = "Murloc Fins"
    public constant string QUEST_RESCUE_GRUNTS = "Rescue The Grunts"
    private constant string KREZGREL_NAME = "Krezgrel"

    private constant integer ITEM_MURLOC_FIN = 'I6AE'
    private constant integer UNIT_GRUNT = 'ogru'
    private constant integer RESCUE_TARGET_COUNT = 8
    private constant integer RESCUE_REQUIRED = 3
    private constant integer RESCUED_GRUNT_OWNER = 1
    private constant real RESCUE_TARGET_COOLDOWN = 240.00
    private constant real RESCUE_PROXY_Z_OFFSET = -30.00
    private constant real RESCUE_INTERACT_RANGE_SQ = 62500.00
    private constant string GRUNT_MODEL = "Units\\Orc\\Grunt\\Grunt.mdl"
    private constant string WATER_EFFECT = "war3campImported\\Water_Effect.mdx"

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

    private unit Krezgrel = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit SelectedHero = null
    private dialog KrezgrelDialog = null
    private timer KrezgrelDialogCooldown = null
    private timer RescueRecycleTimer = null
    private trigger RescueSelectionTrigger = null
    private trigger RescuedGruntRemovalTrigger = null
    private group RescuedGruntGroup = null
    private unit array RescueProxy
    private effect array RescueVisual
    private real array RescueCooldown
    private integer RescuedGruntCount = 0
    private boolean KrezgrelInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qKrezgrel]|r " + msg)
    endif
endfunction

private function IsAlive takes unit u returns boolean
    return u != null and GetUnitTypeId(u) != 0 and GetWidgetLife(u) > 0.405 and not IsUnitType(u, UNIT_TYPE_DEAD)
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Krezgrel != null and udg_Krezgrel != Krezgrel then
        set Krezgrel = udg_Krezgrel
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Krezgrel, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetKrezgrelQuest takes string questName returns QuestData
    call SyncUnitReferences()
    if Krezgrel == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(questName, Krezgrel)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Krezgrel, SelectedHero, KrezgrelDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function GetRescueRect takes integer index returns rect
    if index == 1 then
        return gg_rct_UpsideGrunt01
    elseif index == 2 then
        return gg_rct_UpsideGrunt02
    elseif index == 3 then
        return gg_rct_UpsideGrunt03
    elseif index == 4 then
        return gg_rct_UpsideGrunt04
    elseif index == 5 then
        return gg_rct_UpsideGrunt05
    elseif index == 6 then
        return gg_rct_UpsideGrunt06
    elseif index == 7 then
        return gg_rct_UpsideGrunt07
    endif
    return gg_rct_UpsideGrunt08
endfunction

private function DestroyRescueVisual takes integer index returns nothing
    if RescueVisual[index] != null then
        call DestroyEffect(RescueVisual[index])
        set RescueVisual[index] = null
    endif
endfunction

private function PlaceRescueTarget takes integer index returns nothing
    local rect targetRect = GetRescueRect(index)
    local real x = GetRandomReal(GetRectMinX(targetRect), GetRectMaxX(targetRect))
    local real y = GetRandomReal(GetRectMinY(targetRect), GetRectMaxY(targetRect))
    local real yaw = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    local real scale = GetRandomReal(0.90, 1.10)

    call DestroyRescueVisual(index)
    if RescueProxy[index] == null or GetUnitTypeId(RescueProxy[index]) == 0 then
        set RescueProxy[index] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_GRUNT, x, y, 0.00)
        call SetUnitInvulnerable(RescueProxy[index], true)
        call SetUnitPathing(RescueProxy[index], false)
        call PauseUnit(RescueProxy[index], true)
        call SetUnitAcquireRange(RescueProxy[index], 0.00)
        call SetUnitVertexColor(RescueProxy[index], 255, 255, 255, 0)
    else
        call ShowUnit(RescueProxy[index], true)
        call SetUnitPosition(RescueProxy[index], x, y)
    endif
    call SetUnitFacing(RescueProxy[index], yaw * bj_RADTODEG)

    set RescueVisual[index] = AddSpecialEffect(GRUNT_MODEL, x, y)
    call BlzSetSpecialEffectYaw(RescueVisual[index], yaw)
    call BlzSetSpecialEffectPitch(RescueVisual[index], -bj_PI)
    call BlzSetSpecialEffectScale(RescueVisual[index], scale)
    call BlzSetSpecialEffectZ(RescueVisual[index], BlzGetLocalSpecialEffectZ(RescueVisual[index]) + RESCUE_PROXY_Z_OFFSET)
    set RescueCooldown[index] = 0.00
    set targetRect = null
endfunction

private function RebuildRescueTargetsInternal takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > RESCUE_TARGET_COUNT
        call PlaceRescueTarget(i)
        set i = i + 1
    endloop
endfunction

private function DeactivateRescueTarget takes integer index returns nothing
    call DestroyRescueVisual(index)
    if RescueProxy[index] != null then
        call ShowUnit(RescueProxy[index], false)
    endif
    set RescueCooldown[index] = RESCUE_TARGET_COOLDOWN
endfunction

private function FindRescueProxyIndex takes unit target returns integer
    local integer i = 1
    loop
        exitwhen i > RESCUE_TARGET_COUNT
        if RescueProxy[i] == target then
            return i
        endif
        set i = i + 1
    endloop
    return 0
endfunction

private function IsHeroNearRescueTarget takes unit target returns boolean
    local real dx
    local real dy
    call SyncUnitReferences()
    if IsAlive(Nazgrek) then
        set dx = GetUnitX(target) - GetUnitX(Nazgrek)
        set dy = GetUnitY(target) - GetUnitY(Nazgrek)
        if dx * dx + dy * dy <= RESCUE_INTERACT_RANGE_SQ then
            return true
        endif
    endif
    if IsAlive(Zulkis) then
        set dx = GetUnitX(target) - GetUnitX(Zulkis)
        set dy = GetUnitY(target) - GetUnitY(Zulkis)
        if dx * dx + dy * dy <= RESCUE_INTERACT_RANGE_SQ then
            return true
        endif
    endif
    return false
endfunction

private function ShowDrownedText takes unit corpse returns nothing
    local texttag tag = CreateTextTag()
    call SetTextTagText(tag, "Grunt has drowned!", TextTagSize2Height(13.00))
    call SetTextTagPosUnit(tag, corpse, 25.00)
    call SetTextTagColor(tag, 255, 13, 26, 255)
    call SetTextTagVelocityBJ(tag, 75.00, 90.00)
    call SetTextTagPermanent(tag, false)
    call SetTextTagLifespan(tag, 3.50)
    call SetTextTagFadepoint(tag, 1.40)
    set tag = null
endfunction

private function ResolveDrownedGrunt takes real x, real y returns nothing
    local unit corpse
    call DestroyEffect(AddSpecialEffect(WATER_EFFECT, x, y))
    set corpse = CreateUnit(Player(RESCUED_GRUNT_OWNER), UNIT_GRUNT, x, y, GetRandomReal(0.00, 360.00))
    call KillUnit(corpse)
    call ShowDrownedText(corpse)
    set corpse = null
endfunction

private function UpdateRescueProgress takes nothing returns nothing
    local QuestData q = GetKrezgrelQuest(QUEST_RESCUE_GRUNTS)
    if q == 0 then
        return
    endif
    call q.updateRequirementText(1, "Rescue 3 Grunts from murloc waters (" + I2S(RescuedGruntCount) + " / " + I2S(RESCUE_REQUIRED) + ")")
    if RescuedGruntCount >= RESCUE_REQUIRED then
        call q.markRequirementCompleted(1, true)
        call q.addReturnRequirement()
        call q.setState(QUEST_STATE_READY_TURNIN)
    endif
    call q.refreshQuestLog()
    call QuestGiver_RefreshAvailabilityForGiver(Krezgrel)
    set q = 0
endfunction

private function ResolveLivingGrunt takes real x, real y returns nothing
    local unit rescued
    local integer bark = GetRandomInt(1, 3)
    call DestroyEffect(AddSpecialEffect(WATER_EFFECT, x, y))
    set RescuedGruntCount = RescuedGruntCount + 1
    set rescued = CreateUnit(Player(RESCUED_GRUNT_OWNER), UNIT_GRUNT, x, y, GetRandomReal(0.00, 360.00))
    call SetUnitCreepGuard(rescued, false)
    call GroupAddUnit(RescuedGruntGroup, rescued)
    if bark == 1 then
        call DialogSystem_PlayLine(rescued, "Grunt", VL_ORCGRUNT_0120_TEXT, VL_ORCGRUNT_0120_KEY, true)
    elseif bark == 2 then
        call DialogSystem_PlayLine(rescued, "Grunt", VL_ORCGRUNT_0121_TEXT, VL_ORCGRUNT_0121_KEY, true)
    else
        call DialogSystem_PlayLine(rescued, "Grunt", VL_ORCGRUNT_0122_TEXT, VL_ORCGRUNT_0122_KEY, true)
    endif
    call IssuePointOrder(rescued, "move", GetRectCenterX(gg_rct_UpsideGruntRemoval), GetRectCenterY(gg_rct_UpsideGruntRemoval))
    call UpdateRescueProgress()
    set rescued = null
endfunction

private function OnRescueProxySelected takes nothing returns nothing
    local unit target = GetTriggerUnit()
    local integer index = FindRescueProxyIndex(target)
    local QuestData q
    local real x
    local real y
    if index == 0 or RescueCooldown[index] > 0.00 or not IsHeroNearRescueTarget(target) then
        set target = null
        return
    endif
    set q = GetKrezgrelQuest(QUEST_RESCUE_GRUNTS)
    if q == 0 or not q.active or q.completed or q.failed or RescuedGruntCount >= RESCUE_REQUIRED then
        set q = 0
        set target = null
        return
    endif
    set x = GetUnitX(target)
    set y = GetUnitY(target)
    call DeactivateRescueTarget(index)
    if GetRandomInt(1, 2) == 1 then
        call ResolveDrownedGrunt(x, y)
    else
        call ResolveLivingGrunt(x, y)
    endif
    set q = 0
    set target = null
endfunction

private function OnRescueRecycle takes nothing returns nothing
    local integer i = 1
    loop
        exitwhen i > RESCUE_TARGET_COUNT
        if RescueCooldown[i] > 0.00 then
            set RescueCooldown[i] = RescueCooldown[i] - 1.00
            if RescueCooldown[i] <= 0.00 then
                call PlaceRescueTarget(i)
            endif
        endif
        set i = i + 1
    endloop
endfunction

private function OnRescuedGruntLeaves takes nothing returns nothing
    local unit u = GetEnteringUnit()
    if IsUnitInGroup(u, RescuedGruntGroup) then
        call GroupRemoveUnit(RescuedGruntGroup, u)
        call RemoveUnit(u)
    endif
    set u = null
endfunction

private function ClearRescuedGrunts takes nothing returns nothing
    local unit u
    loop
        set u = FirstOfGroup(RescuedGruntGroup)
        exitwhen u == null
        call GroupRemoveUnit(RescuedGruntGroup, u)
        if GetUnitTypeId(u) != 0 then
            call RemoveUnit(u)
        endif
    endloop
    set u = null
endfunction

private function OnAcceptFinsEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_MURLOC_FINS, Krezgrel)
    call StartExitFadeOut()
endfunction

private function OnAcceptFins takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Krezgrel, KREZGREL_NAME)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0020_TEXT, VL_KREZGREL_0020_KEY, true)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0021_TEXT, VL_KREZGREL_0021_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptFinsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Krezgrel)
endfunction

private function OnCompleteFinsEnd takes nothing returns nothing
    local QuestData q = GetKrezgrelQuest(QUEST_MURLOC_FINS)
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_MURLOC_FIN, 10) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_MURLOC_FIN, 0, 10)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_MURLOC_FINS, Krezgrel)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteFins takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Krezgrel, KREZGREL_NAME)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0022_TEXT, VL_KREZGREL_0022_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteFinsEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Krezgrel)
endfunction

private function OnAcceptRescueEnd takes nothing returns nothing
    local QuestData q = GetKrezgrelQuest(QUEST_RESCUE_GRUNTS)
    set RescuedGruntCount = 0
    call ClearRescuedGrunts()
    call RebuildRescueTargetsInternal()
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RESCUE_GRUNTS, Krezgrel)
    if q != 0 then
        call q.updateRequirementText(1, "Rescue 3 Grunts from murloc waters (0 / 3)")
        call q.markRequirementCompleted(1, false)
        call q.removeReturnRequirement()
        call q.refreshQuestLog()
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnAcceptRescue takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Krezgrel, KREZGREL_NAME)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0010_TEXT, VL_KREZGREL_0010_KEY, true)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0011_TEXT, VL_KREZGREL_0011_KEY, true)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0012_TEXT, VL_KREZGREL_0012_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptRescueEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Krezgrel)
endfunction

private function OnCompleteRescueEnd takes nothing returns nothing
    local QuestData q = GetKrezgrelQuest(QUEST_RESCUE_GRUNTS)
    if q != 0 and q.active and not q.completed and RescuedGruntCount >= RESCUE_REQUIRED then
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_RESCUE_GRUNTS, Krezgrel)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteRescue takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Krezgrel, KREZGREL_NAME)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0013_TEXT, VL_KREZGREL_0013_KEY, true)
    call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0014_TEXT, VL_KREZGREL_0014_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteRescueEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Krezgrel)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(Krezgrel, KREZGREL_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Krezgrel)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    if KrezgrelDialog == null then
        set KrezgrelDialog = DialogSystem_CreateDialog(KREZGREL_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Krezgrel)
    call DialogSystem_ClearDialog(KrezgrelDialog)
    call DialogSystem_SetTitle(KrezgrelDialog, KREZGREL_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(KrezgrelDialog, QUEST_MURLOC_FINS, Krezgrel, 1, function OnAcceptFins, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(KrezgrelDialog, QUEST_MURLOC_FINS, Krezgrel, 2, function OnCompleteFins, true)
    call QuestGiver_AddAvailableQuestAcceptButton(KrezgrelDialog, QUEST_RESCUE_GRUNTS, Krezgrel, 3, function OnAcceptRescue, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(KrezgrelDialog, QUEST_RESCUE_GRUNTS, Krezgrel, 4, function OnCompleteRescue, false)
    set b = DialogSystem_AddFarewellButton(KrezgrelDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq
    if not DialogInteraction_IsFirstGreetDone(Krezgrel) then
        set seq = DialogInteraction_CreateBaseSequence(Krezgrel, KREZGREL_NAME)
        call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0001_TEXT, VL_KREZGREL_0001_KEY, true)
        call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0002_TEXT, VL_KREZGREL_0002_KEY, true)
        call DialogInteraction_PlayFirstGreetSequenceEx(Krezgrel, Player(0), KrezgrelDialog, seq, CINEMATIC)
    else
        set seq = DialogInteraction_CreateGreetSequenceBase(Krezgrel, KREZGREL_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
        call DialogSystem_AddLine(seq, Krezgrel, KREZGREL_NAME, VL_KREZGREL_0006_TEXT, VL_KREZGREL_0006_KEY, true)
        call DialogInteraction_PlayGreetSequenceEx(seq, Krezgrel, Player(0), KrezgrelDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Krezgrel) then
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
    if not DialogInteraction_IsUnitAlive(Krezgrel) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Krezgrel, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Krezgrel, SelectedHero, DIALOG_RANGE, KrezgrelDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Krezgrel, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qKrezgrel_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + KREZGREL_NAME + "\n|cffffcc00Zone:|r Thornwoods (6)\n"
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MURLOC_FINS, Krezgrel) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_MURLOC_FINS, Krezgrel, "daily", 3, null, QUEST_MURLOC_FINS, "ReplaceableTextures\\CommandButtons\\BTNMurloc.blp", "Gather murloc fins so Krezgrel can vary the warriors' food supply.\n\n", infoText, "|cffffcc00Recommended level:|r 3\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", KREZGREL_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 150, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Gather 10 Murloc fins for Krezgrel", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Krezgrel, 1, ITEM_MURLOC_FIN, 10)
    endif
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_RESCUE_GRUNTS, Krezgrel) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_RESCUE_GRUNTS, Krezgrel, "daily", 3, null, QUEST_RESCUE_GRUNTS, "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp", "Rescue living orc grunts from the murloc waters before they drown.\n\n", infoText, "|cffffcc00Recommended level:|r 3\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", KREZGREL_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 150, false, 0, false, 0, false)
        call QuestGiver_SetRequirements(q.id, "", "Rescue 3 Grunts from murloc waters (0 / 3)", "", "", "", "", "", "", "")
    endif
    set q = 0
endfunction

private function OnDailyReset takes nothing returns nothing
    local QuestData q = GetKrezgrelQuest(QUEST_RESCUE_GRUNTS)
    if q != 0 and QuestGiver_GetEventQuestId() == q.id then
        set RescuedGruntCount = 0
        call ClearRescuedGrunts()
        call RebuildRescueTargetsInternal()
    endif
    set q = 0
endfunction

private function RegisterRuntimeTriggers takes nothing returns nothing
    if RescueSelectionTrigger == null then
        set RescueSelectionTrigger = CreateTrigger()
        call TriggerRegisterPlayerUnitEvent(RescueSelectionTrigger, Player(0), EVENT_PLAYER_UNIT_SELECTED, null)
        call TriggerAddAction(RescueSelectionTrigger, function OnRescueProxySelected)
    endif
    if RescuedGruntRemovalTrigger == null then
        set RescuedGruntRemovalTrigger = CreateTrigger()
        call TriggerRegisterEnterRectSimple(RescuedGruntRemovalTrigger, gg_rct_UpsideGruntRemoval)
        call TriggerAddAction(RescuedGruntRemovalTrigger, function OnRescuedGruntLeaves)
    endif
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Krezgrel, VL_KREZGREL_0007_TEXT, VL_KREZGREL_0007_KEY, true)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Krezgrel == null or Nazgrek == null then
        if not KrezgrelInitWaitingLogged then
            call DebugMsg("Waiting for Krezgrel and Nazgrek.")
            set KrezgrelInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Krezgrel)
    call DialogInteraction_ConfigureDialogTransition(Krezgrel, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call RebuildRescueTargetsInternal()
    call RegisterRuntimeTriggers()
    call RegisterDialogLines()
    call DialogInteraction_RegisterSelectionHandler(Krezgrel, function OnSelected)
    call QuestMaster_AddDailyResetAction(function OnDailyReset)
    call TimerStart(RescueRecycleTimer, 1.00, true, function OnRescueRecycle)
    call QuestGiver_RefreshAvailabilityForGiver(Krezgrel)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set KrezgrelDialogCooldown = CreateTimer()
    set RescueRecycleTimer = CreateTimer()
    set RescuedGruntGroup = CreateGroup()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function GetRescuedGruntCount takes nothing returns integer
    return RescuedGruntCount
endfunction

public function RebuildRescueTargets takes nothing returns nothing
    call RebuildRescueTargetsInternal()
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Krezgrel != null then
        call QuestGiver_RefreshAvailabilityForGiver(Krezgrel)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Krezgrel != null then
        call QuestGiver_Register(Krezgrel)
        call DialogInteraction_ConfigureDialogTransition(Krezgrel, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Krezgrel, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
