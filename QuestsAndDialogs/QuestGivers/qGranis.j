/**
    qGranis

    Author: Valdemar
    Version:

    Description:
    Converts Granis's Rol'jin hunt and the distinct second mountain-outpost
    defense from legacy GUI. Granis owns and rewards Mountain Defense, while
    Ragno is its field commander, encounter anchor, and required survivor.
    The defense uses UnitWaves for its nine staged gnoll assaults.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Granis.

    How to install:
    Import after qRagno, UnitWaves, the quest/dialog systems, and Granis and
    Nazgrek voicelines. Keep the referenced map rects and GUI unit globals.

    API:
    - qGranis_IsProofTaskComplete()
    - qGranis_IsMountainDefenseActive()
    - qGranis_RefreshAvailability()
    - qGranis_RefreshRespawnedUnitHooks()

**/
library qGranis initializer Init requires qRagno, UnitWaves, QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, VoicelinesGranis, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_PUNISH = "Punish"
    public constant string QUEST_MOUNTAIN_DEFENSE = "Mountain Defense"
    private constant string GRANIS_NAME = "Granis"

    private constant integer ITEM_ROLJIN_HEAD = 'I600'
    private constant integer ITEM_HEALING_SALVE = 'hslv'
    private constant integer ITEM_SPRING_WATER = 'I60Z'
    private constant integer ITEM_HEALING_POTION = 'phea'
    private constant integer ITEM_SCROLL_RESTORATION = 'sres'
    private constant integer ITEM_SCROLL_HEALING = 'shea'
    private constant integer ITEM_SCROLL_MANA = 'sman'
    private constant integer ITEM_HEALTH_STONE = 'hlst'
    private constant integer ITEM_REPLENISHMENT = 'rej3'

    private constant integer UNIT_GRUNT = 'ogru'
    private constant integer UNIT_GNOLL = 'ngno'
    private constant integer UNIT_GNOLL_POACHER = 'ngna'
    private constant integer UNIT_GNOLL_BRUTE = 'ngnb'
    private constant integer UNIT_GNOLL_WARDEN = 'ngnw'
    private constant integer UNIT_GNOLL_ASSASSIN = 'n60F'
    private constant integer UNIT_GNOLL_OVERSEER = 'n60J'
    private constant integer UNIT_GNOLL_NECROMANCER = 'n60O'
    private constant integer UNIT_GNOLL_RAVAGER = 'n61A'
    private constant integer UNIT_GNOLL_CRUSHER = 'n626'
    private constant integer DEFENDER_OWNER = 5
    private constant integer ATTACKER_OWNER = 11
    private constant integer DEFENDER_COUNT = 8
    private constant integer DEFENDER_MIN_SURVIVORS = 5
    private constant integer DEFENSE_WAVE_COUNT = 9

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00
    private constant real DEFENSE_MONITOR_PERIOD = 2.00

    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = false
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

    private unit Granis = null
    private unit Ragno = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit SelectedHero = null
    private dialog GranisDialog = null
    private timer GranisDialogCooldown = null
    private timer DefenseMonitorTimer = null
    private trigger DefenseStartTrigger = null
    private group DefenseDefenders = null
    private UnitWaveEvent DefenseEvent = 0
    private integer LivingDefenderCount = 0
    private boolean DefenseActive = false
    private boolean GranisInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qGranis]|r " + msg)
    endif
endfunction

private function IsAlive takes unit u returns boolean
    return u != null and GetUnitTypeId(u) != 0 and GetWidgetLife(u) > 0.405 and not IsUnitType(u, UNIT_TYPE_DEAD)
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Granis != null and udg_Granis != Granis then
        set Granis = udg_Granis
    endif
    if udg_Ragno != null and udg_Ragno != Ragno then
        set Ragno = udg_Ragno
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
    return DialogInteraction_ResolveDialogHero(SelectedHero, Granis, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetGranisQuest takes string questName returns QuestData
    call SyncUnitReferences()
    if Granis == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(questName, Granis)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Granis, SelectedHero, GranisDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function RemoveDefenseDefenders takes nothing returns nothing
    local unit u
    loop
        set u = FirstOfGroup(DefenseDefenders)
        exitwhen u == null
        call GroupRemoveUnit(DefenseDefenders, u)
        if GetUnitTypeId(u) != 0 then
            call RemoveUnit(u)
        endif
    endloop
    set u = null
endfunction

private function CountLivingDefenderEnum takes nothing returns nothing
    if IsAlive(GetEnumUnit()) then
        set LivingDefenderCount = LivingDefenderCount + 1
    endif
endfunction

private function CountLivingDefenders takes nothing returns integer
    set LivingDefenderCount = 0
    call ForGroup(DefenseDefenders, function CountLivingDefenderEnum)
    return LivingDefenderCount
endfunction

private function SpawnDefenseDefenders takes nothing returns nothing
    local integer i = 0
    local real x
    local real y
    local unit u
    call RemoveDefenseDefenders()
    loop
        exitwhen i >= DEFENDER_COUNT
        set x = GetRandomReal(GetRectMinX(gg_rct_HordeMountainCamp2), GetRectMaxX(gg_rct_HordeMountainCamp2))
        set y = GetRandomReal(GetRectMinY(gg_rct_HordeMountainCamp2), GetRectMaxY(gg_rct_HordeMountainCamp2))
        set u = CreateUnit(Player(DEFENDER_OWNER), UNIT_GRUNT, x, y, GetRandomReal(0.00, 360.00))
        call GroupAddUnit(DefenseDefenders, u)
        set i = i + 1
    endloop
    set u = null
endfunction

private function ResetDefenseRequirements takes QuestData q returns nothing
    if q == 0 then
        return
    endif
    call q.updateRequirementText(1, "Aid Ragno in defense of the mountain outpost")
    call q.markRequirementCompleted(1, false)
    call q.updateRequirementText(2, "At least 5 orcs must survive the attacks")
    call q.markRequirementCompleted(2, false)
    call q.updateRequirementText(3, "Ragno must survive")
    call q.markRequirementCompleted(3, false)
    call q.removeReturnRequirement()
    call q.refreshQuestLog()
endfunction

private function FailDefense takes string reason returns nothing
    local QuestData q
    if not DefenseActive then
        return
    endif
    set DefenseActive = false
    call PauseTimer(DefenseMonitorTimer)
    if DefenseEvent != 0 then
        call DefenseEvent.cancel(true)
    endif
    call RemoveDefenseDefenders()
    set q = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    if q != 0 and not q.completed then
        call QuestGiver_FailQuestByNameAndGiver(QUEST_MOUNTAIN_DEFENSE, Granis, reason)
        call ResetDefenseRequirements(q)
        call q.resetAfterFail()
        call QuestGiver_RefreshAvailabilityForGiver(Granis)
    endif
    set q = 0
endfunction

private function OnDefenseMonitor takes nothing returns nothing
    call SyncUnitReferences()
    if not DefenseActive then
        call PauseTimer(DefenseMonitorTimer)
    elseif not IsAlive(Ragno) then
        call FailDefense("Ragno was slain during the defense.")
    elseif CountLivingDefenders() < DEFENDER_MIN_SURVIVORS then
        call FailDefense("Too many outpost defenders were slain.")
    endif
endfunction

private function SpawnDefenseHelperItems takes nothing returns nothing
    local integer pick = GetRandomInt(1, 10)
    local real x = GetRectCenterX(gg_rct_MountainDefenseItems)
    local real y = GetRectCenterY(gg_rct_MountainDefenseItems)
    if pick == 1 then
        call CreateItem(ITEM_HEALING_SALVE, x, y)
        call CreateItem(ITEM_SPRING_WATER, x, y)
    elseif pick == 2 then
        call CreateItem(ITEM_HEALING_POTION, x, y)
    elseif pick == 3 then
        call CreateItem(ITEM_SCROLL_RESTORATION, x, y)
    elseif pick == 4 then
        call CreateItem(ITEM_SCROLL_HEALING, x, y)
    elseif pick == 5 then
        call CreateItem(ITEM_SCROLL_MANA, x, y)
    elseif pick == 6 then
        call CreateItem(ITEM_HEALTH_STONE, x, y)
    elseif pick == 7 then
        call CreateItem(ITEM_REPLENISHMENT, x, y)
    endif
endfunction

private function OnDefenseWaveStart takes nothing returns nothing
    local QuestData q = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    local integer waveIndex = UnitWaves_GetTriggeringWaveIndex()
    if q != 0 and DefenseActive then
        call q.updateRequirementText(1, "Defeat gnoll wave " + I2S(waveIndex) + " / " + I2S(DEFENSE_WAVE_COUNT))
        call q.refreshQuestLog()
    endif
    set q = 0
endfunction

private function OnDefenseWaveCleared takes nothing returns nothing
    if UnitWaves_GetTriggeringWaveIndex() < DEFENSE_WAVE_COUNT then
        call SpawnDefenseHelperItems()
    endif
endfunction

private function PlayDefenseVictorySequence takes nothing returns nothing
    local integer seq
    call SyncUnitReferences()
    if not IsAlive(Ragno) or not IsAlive(Nazgrek) then
        return
    endif
    set seq = DialogInteraction_CreateBaseSequence(Ragno, "Ragno")
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "The gnoll attack is over! We have prevailed!", "OrcGrunt_0063", true)
    call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0163_TEXT, VL_NAZGREK_0163_KEY, true)
    call DialogSystem_AddLine(seq, Ragno, "Ragno", "Yes, I fear that this was just the beginning. Tell Granis what happened here.", "OrcGrunt_0064", true)
    call DialogSystem_PlaySequence(seq, Player(0), Ragno)
endfunction

private function OnDefenseComplete takes nothing returns nothing
    local QuestData q = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    call SyncUnitReferences()
    if not IsAlive(Ragno) then
        call FailDefense("Ragno was slain during the defense.")
        set q = 0
        return
    endif
    if CountLivingDefenders() < DEFENDER_MIN_SURVIVORS then
        call FailDefense("Too many outpost defenders were slain.")
        set q = 0
        return
    endif
    set DefenseActive = false
    call PauseTimer(DefenseMonitorTimer)
    call RemoveDefenseDefenders()
    if q != 0 and q.active and not q.completed then
        call q.markRequirementCompleted(1, true)
        call q.markRequirementCompleted(2, true)
        call q.markRequirementCompleted(3, true)
        call q.addReturnRequirement()
        call q.setState(QUEST_STATE_READY_TURNIN)
        call q.refreshQuestLog()
        call QuestGiver_RefreshAvailabilityForGiver(Granis)
        call PlayDefenseVictorySequence()
    endif
    set q = 0
endfunction

private function AddStageSpawn takes UnitWaveStage stage, integer unitTypeId, integer count, rect spawnRect returns nothing
    call stage.addSpawnRect(unitTypeId, count, spawnRect)
endfunction

private function ConfigureDefenseWaves takes nothing returns nothing
    local UnitWaveStage stage
    if DefenseEvent != 0 then
        return
    endif
    set DefenseEvent = UnitWaveEvent.create(Player(ATTACKER_OWNER), GetRectCenterX(gg_rct_HordeMountainCamp), GetRectCenterY(gg_rct_HordeMountainCamp))
    call DefenseEvent.setTiming(2.00, 40.00)
    call DefenseEvent.setCallbacks(function OnDefenseWaveStart, function OnDefenseWaveCleared, function OnDefenseComplete, null)

    set stage = DefenseEvent.addStage(5.00, 5.00)
    call AddStageSpawn(stage, UNIT_GNOLL, 4, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 3, gg_rct_GnollAttackRegion01)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_BRUTE, 1, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 3, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion02)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 3, gg_rct_GnollAttackRegion02)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_ASSASSIN, 4, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 2, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL, 4, gg_rct_GnollAttackRegion01)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_WARDEN, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_WARDEN, 2, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL, 4, gg_rct_GnollAttackRegion03)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_OVERSEER, 1, gg_rct_GnollAttackRegion04)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 2, gg_rct_GnollAttackRegion04)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion04)
    call AddStageSpawn(stage, UNIT_GNOLL_BRUTE, 2, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL, 2, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL_BRUTE, 2, gg_rct_GnollAttackRegion02)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion02)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_NECROMANCER, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 1, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_RAVAGER, 4, gg_rct_GnollAttackRegion02)
    call AddStageSpawn(stage, UNIT_GNOLL_NECROMANCER, 2, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion03)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 1, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 1, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion03)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 1, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_POACHER, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 1, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 1, gg_rct_GnollAttackRegion04)
    call AddStageSpawn(stage, UNIT_GNOLL, 3, gg_rct_GnollAttackRegion04)

    set stage = DefenseEvent.addStage(30.00, 60.00)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 1, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_NECROMANCER, 2, gg_rct_GnollAttackRegion01)
    call AddStageSpawn(stage, UNIT_GNOLL_CRUSHER, 3, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL_NECROMANCER, 3, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL_WARDEN, 1, gg_rct_GnollAttackRegion03)
    call AddStageSpawn(stage, UNIT_GNOLL_RAVAGER, 5, gg_rct_GnollAttackRegion03)
    set stage = 0
endfunction

private function StartDefense takes nothing returns nothing
    local QuestData q = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    call SyncUnitReferences()
    if DefenseActive or q == 0 or not q.active or q.completed or q.state == QUEST_STATE_READY_TURNIN then
        set q = 0
        return
    endif
    if not IsAlive(Ragno) then
        call QuestMaster_ShowUpdateMessage(q.id, "Ragno is not ready to begin the defense.")
        set q = 0
        return
    endif
    call ConfigureDefenseWaves()
    call DefenseEvent.reset(true)
    call SpawnDefenseDefenders()
    call ResetDefenseRequirements(q)
    set DefenseActive = true
    call TimerStart(DefenseMonitorTimer, DEFENSE_MONITOR_PERIOD, true, function OnDefenseMonitor)
    if not DefenseEvent.start() then
        call FailDefense("The gnoll assault could not be started.")
    endif
    set q = 0
endfunction

private function OnDefenseAreaEntered takes nothing returns nothing
    local unit entering = GetEnteringUnit()
    if entering == Nazgrek or entering == Zulkis then
        call StartDefense()
    endif
    set entering = null
endfunction

private function OnAcceptPunishEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_PUNISH, Granis)
    call StartExitFadeOut()
endfunction

private function OnAcceptPunish takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Granis, GRANIS_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0140_TEXT, VL_NAZGREK_0140_KEY, true)
    call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0013_TEXT, VL_GRANIS_0013_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0141_TEXT, VL_NAZGREK_0141_KEY, true)
    call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0014_TEXT, VL_GRANIS_0014_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptPunishEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Granis)
    set hero = null
endfunction

private function OnCompletePunishEnd takes nothing returns nothing
    local QuestData q = GetGranisQuest(QUEST_PUNISH)
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_ROLJIN_HEAD, 1) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_ROLJIN_HEAD, 0, 1)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_PUNISH, Granis)
        call ExecuteFunc("qChieftainThork_ReportGranisTaskComplete")
        call QuestGiver_RefreshAvailabilityForGiver(Granis)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompletePunish takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Granis, GRANIS_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0144_TEXT, VL_NAZGREK_0144_KEY, true)
    call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0017_TEXT, VL_GRANIS_0017_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompletePunishEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Granis)
    set hero = null
endfunction

private function OnAcceptDefenseEnd takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local QuestData q = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_MOUNTAIN_DEFENSE, Granis)
    if q != 0 then
        call ResetDefenseRequirements(q)
    endif
    call StartExitFadeOut()
    if hero != null and RectContainsCoords(gg_rct_HordeMountainCamp2, GetUnitX(hero), GetUnitY(hero)) then
        call StartDefense()
    endif
    set hero = null
    set q = 0
endfunction

private function OnAcceptDefense takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Granis, GRANIS_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0153_TEXT, VL_NAZGREK_0153_KEY, true)
    call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0028_TEXT, VL_GRANIS_0028_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptDefenseEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Granis)
    set hero = null
endfunction

private function OnCompleteDefenseEnd takes nothing returns nothing
    local QuestData q = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    if q != 0 and q.active and q.state == QUEST_STATE_READY_TURNIN then
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_MOUNTAIN_DEFENSE, Granis)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteDefense takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Granis, GRANIS_NAME)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0166_TEXT, VL_NAZGREK_0166_KEY, true)
    call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0041_TEXT, VL_GRANIS_0041_KEY, true)
    call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0042_TEXT, VL_GRANIS_0042_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteDefenseEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Granis)
    set hero = null
endfunction

private function OnDeclineEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnDecline takes nothing returns nothing
    local QuestData punish = GetGranisQuest(QUEST_PUNISH)
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Granis, GRANIS_NAME)
    if punish != 0 and punish.state == QUEST_STATE_AVAILABLE and not punish.completed then
        call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0142_TEXT, VL_NAZGREK_0142_KEY, true)
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0015_TEXT, VL_GRANIS_0015_KEY, true)
    else
        call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0154_TEXT, VL_NAZGREK_0154_KEY, true)
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0029_TEXT, VL_GRANIS_0029_KEY, true)
    endif
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnDeclineEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Granis)
    set punish = 0
    set hero = null
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(Granis, GRANIS_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Granis)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    local boolean offered = false
    if GranisDialog == null then
        set GranisDialog = DialogSystem_CreateDialog(GRANIS_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Granis)
    call DialogSystem_ClearDialog(GranisDialog)
    call DialogSystem_SetTitle(GranisDialog, GRANIS_NAME)
    if QuestGiver_AddAvailableQuestAcceptButton(GranisDialog, QUEST_PUNISH, Granis, 1, function OnAcceptPunish, true, true) then
        set offered = true
    endif
    call QuestGiver_AddReadyQuestCompleteButton(GranisDialog, QUEST_PUNISH, Granis, 2, function OnCompletePunish, true)
    if QuestGiver_AddAvailableQuestAcceptButton(GranisDialog, QUEST_MOUNTAIN_DEFENSE, Granis, 3, function OnAcceptDefense, true, true) then
        set offered = true
    endif
    call QuestGiver_AddReadyQuestCompleteButton(GranisDialog, QUEST_MOUNTAIN_DEFENSE, Granis, 4, function OnCompleteDefense, false)
    if offered then
        set b = DialogSystem_AddButton(GranisDialog, "Decline", 5)
        call DialogSystem_BindButtonCode(b, function OnDecline)
        set b = null
    endif
    set b = DialogSystem_AddFarewellButton(GranisDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    local QuestData punish = GetGranisQuest(QUEST_PUNISH)
    local QuestData defense = GetGranisQuest(QUEST_MOUNTAIN_DEFENSE)
    if punish != 0 and punish.active and punish.state == QUEST_STATE_READY_TURNIN then
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0017_TEXT, VL_GRANIS_0017_KEY, true)
    elseif punish != 0 and punish.active then
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0016_TEXT, VL_GRANIS_0016_KEY, true)
        call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", VL_NAZGREK_0143_TEXT, VL_NAZGREK_0143_KEY, true)
    elseif punish != 0 and not punish.completed then
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0010_TEXT, VL_GRANIS_0010_KEY, true)
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0011_TEXT, VL_GRANIS_0011_KEY, true)
    elseif defense != 0 and defense.state == QUEST_STATE_AVAILABLE and not defense.completed then
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0025_TEXT, VL_GRANIS_0025_KEY, true)
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0026_TEXT, VL_GRANIS_0026_KEY, true)
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0027_TEXT, VL_GRANIS_0027_KEY, true)
    elseif defense != 0 and defense.active and defense.state != QUEST_STATE_READY_TURNIN then
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0040_TEXT, VL_GRANIS_0040_KEY, true)
    else
        call DialogSystem_AddLine(seq, Granis, GRANIS_NAME, VL_GRANIS_0006_TEXT, VL_GRANIS_0006_KEY, true)
    endif
    set punish = 0
    set defense = 0
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Granis, GRANIS_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, false)
    call AddPreDialogBark(seq)
    call DialogInteraction_PlayGreetSequenceEx(seq, Granis, Player(0), GranisDialog, CINEMATIC)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Granis) then
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
    if not DialogInteraction_IsUnitAlive(Granis) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Granis, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Granis, SelectedHero, DIALOG_RANGE, GranisDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Granis, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qGranis_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + GRANIS_NAME + "\n|cffffcc00Zone:|r Thornwoods (6)\n"
    local string defenseInfoText = infoText + "|cffffcc00Field commander:|r Ragno\n"
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_PUNISH, Granis) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_PUNISH, Granis, "normal", 6, null, QUEST_PUNISH, "ReplaceableTextures\\CommandButtons\\BTNForestTroll.blp", "Kill troll warlord Rol'jin and return his head to Granis as proof.\n\n", infoText, "|cffffcc00Recommended level:|r 6\n\n", 3, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRANIS_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 700, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "", "Bring Rol'jin's head to Granis", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Granis, 1, ITEM_ROLJIN_HEAD, 1)
    endif
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MOUNTAIN_DEFENSE, Granis) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_MOUNTAIN_DEFENSE, Granis, "normal", 6, null, QUEST_MOUNTAIN_DEFENSE, "ReplaceableTextures\\CommandButtons\\BTNDefend.blp", "Granis sends you to reinforce Ragno, who commands the second defense of the mountain outpost against a larger gnoll assault.\n\n", defenseInfoText, "|cffffcc00Recommended level:|r 6\n\n", 3, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Horde", GRANIS_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 700, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_PUNISH, Granis)
        call QuestGiver_AddQuestPrerequisite(q, qRagno_QUEST_PROTECT_OUTPOST, Ragno)
        call QuestGiver_SetRequirements(q.id, "", "Aid Ragno in defense of the mountain outpost", "At least 5 orcs must survive the attacks", "Ragno must survive", "", "", "", "", "")
    endif
    set q = 0
endfunction

private function RegisterRuntimeTriggers takes nothing returns nothing
    if DefenseStartTrigger == null then
        set DefenseStartTrigger = CreateTrigger()
        call TriggerRegisterEnterRectSimple(DefenseStartTrigger, gg_rct_HordeMountainCamp2)
        call TriggerAddAction(DefenseStartTrigger, function OnDefenseAreaEntered)
    endif
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Granis, VL_GRANIS_0007_TEXT, VL_GRANIS_0007_KEY, true)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Granis == null or Ragno == null or Nazgrek == null or not QuestGiver_QuestExistsByNameAndGiver(qRagno_QUEST_PROTECT_OUTPOST, Ragno) then
        if not GranisInitWaitingLogged then
            call DebugMsg("Waiting for Granis, Ragno, Nazgrek, and Ragno's outpost quest.")
            set GranisInitWaitingLogged = true
        endif
        call TimerStart(GetExpiredTimer(), 0.50, false, function InitDelayed)
        return
    endif
    call QuestGiver_Register(Granis)
    call DialogInteraction_ConfigureDialogTransition(Granis, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call ConfigureDefenseWaves()
    call RegisterRuntimeTriggers()
    call RegisterDialogLines()
    call DialogInteraction_RegisterSelectionHandler(Granis, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Granis)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set GranisDialogCooldown = CreateTimer()
    set DefenseMonitorTimer = CreateTimer()
    set DefenseDefenders = CreateGroup()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function IsProofTaskComplete takes nothing returns boolean
    call SyncUnitReferences()
    return Granis != null and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_PUNISH, Granis)
endfunction

public function IsMountainDefenseActive takes nothing returns boolean
    return DefenseActive
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Granis != null then
        call QuestGiver_RefreshAvailabilityForGiver(Granis)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Granis != null then
        call QuestGiver_Register(Granis)
        call DialogInteraction_ConfigureDialogTransition(Granis, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Granis, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
