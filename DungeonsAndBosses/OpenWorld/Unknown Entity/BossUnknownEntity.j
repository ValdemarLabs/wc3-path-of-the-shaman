/**
    BossUnknownEntity

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements the Unknown Entity lake encounter without legacy GUI triggers.
    The encounter is armed by its quest giver, spawns ambient tentacles while
    the lake is investigated, accepts raw meat as a lure, reveals and starts
    the boss through Boss.j, and cleans up the lake when the boss dies.

    Credits:
    - Legacy GUI triggers in DungeonsAndBosses/Unknown Entity/_OldGui.

    How to install:
    Import after Boss, ExSound, and VoicelinesNazgrek. Disable the legacy
    Unknown Entity GUI trigger group. Import this library before the quest
    giver that calls BossUnknownEntity_Arm.

    API:
    - call BossUnknownEntity_SetQuestCallbacks(onLureReady, onBossRevealed, onBossDefeated)
    - call BossUnknownEntity_SetMarkerUnit(whichUnit)
    - call BossUnknownEntity_Arm()
    - call BossUnknownEntity_Disarm()
    - BossUnknownEntity_GetBoss()
    - BossUnknownEntity_GetBossId()
    - BossUnknownEntity_GetStage()

**/
library BossUnknownEntity initializer Init requires Boss, ExSound, VoicelinesNazgrek
    globals
        // Encounter object data.
        private constant integer UNIT_UNKNOWN_ENTITY = 'n621'
        private constant integer UNIT_TENTACLE = 'nntg'
        private constant integer ITEM_DISGUSTING_SLIME = 'I66O'
        private constant integer TIMED_LIFE_BUFF = 'BTLF'

        // Encounter stages.
        public constant integer STAGE_DORMANT = 0
        public constant integer STAGE_INVESTIGATE = 1
        public constant integer STAGE_CLUE_PENDING = 2
        public constant integer STAGE_LURE_READY = 3
        public constant integer STAGE_REVEALING = 4
        public constant integer STAGE_ACTIVE = 5
        public constant integer STAGE_DEFEATED = 6

        private constant boolean DEBUG = false
        private constant real TENTACLE_LIFETIME = 180.00
        private constant real TENTACLE_COOLDOWN_MIN = 80.00
        private constant real TENTACLE_COOLDOWN_MAX = 200.00
        private constant real CLUE_DELAY = 10.00
        private constant real CLUE_LINE_DURATION = 7.00
        private constant real LURE_REMOVE_DELAY = 0.10
        private constant real BOSS_SPAWN_DELAY = 3.50
        private constant real BOSS_LINE_DELAY = 1.50
        private constant real BOSS_LINE_DURATION = 2.00
        private constant real BOSS_OBJECTIVE_DELAY = 1.50
        private constant real BOSS_HOSTILE_DELAY = 1.00
        private constant real BOSS_FACING = 70.00
        private constant string NAZGREK_NAME = "Nazgrek"

        private integer EncounterStage = STAGE_DORMANT
        private integer UnknownEntityBossId = 0
        private unit UnknownEntityBoss = null
        private unit MarkerUnit = null
        private item LureItem = null

        private rect array TentacleRect
        private timer array TentacleCooldownTimer
        private trigger TentacleEnterTrigger = null
        private trigger LureDropTrigger = null
        private trigger LureReadyCallback = null
        private trigger BossRevealedCallback = null
        private trigger BossDefeatedCallback = null
        private timer ClueTimer = null
        private timer LureRemoveTimer = null
        private timer BossSpawnTimer = null
        private timer BossSequenceTimer = null
        private group SearchGroup = null
        private group CleanupGroup = null
    endglobals

    private function DebugMsg takes string message returns nothing
        if DEBUG then
            call BJDebugMsg("|cffcc66ff[BossUnknownEntity]|r " + message)
        endif
    endfunction

    private function IsUnitAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function IsUnitInRect takes unit whichUnit, rect whichRect returns boolean
        local real x
        local real y

        if whichUnit == null or whichRect == null then
            return false
        endif
        set x = GetUnitX(whichUnit)
        set y = GetUnitY(whichUnit)
        return x >= GetRectMinX(whichRect) and x <= GetRectMaxX(whichRect) and y >= GetRectMinY(whichRect) and y <= GetRectMaxY(whichRect)
    endfunction

    private function IsAmbientHeroOwner takes player ownerPlayer returns boolean
        return ownerPlayer == Player(0) or ownerPlayer == Player(1) or ownerPlayer == Player(5)
    endfunction

    private function IsRawMeat takes integer itemTypeId returns boolean
        return itemTypeId == 'I61Q' or itemTypeId == 'I620' or itemTypeId == 'I623' or itemTypeId == 'I621' or itemTypeId == 'I61S' or itemTypeId == 'I61R' or itemTypeId == 'I61Z' or itemTypeId == 'I61T' or itemTypeId == 'I61W' or itemTypeId == 'I622' or itemTypeId == 'I61X' or itemTypeId == 'I61Y' or itemTypeId == 'I61P' or itemTypeId == 'I61V' or itemTypeId == 'I61U' or itemTypeId == 'I61O'
    endfunction

    private function RunCallback takes trigger callbackTrigger returns nothing
        if callbackTrigger != null then
            call TriggerExecute(callbackTrigger)
        endif
    endfunction

    private function CreateCallback takes code callback returns trigger
        local trigger callbackTrigger = null

        if callback != null then
            set callbackTrigger = CreateTrigger()
            call TriggerAddAction(callbackTrigger, callback)
        endif
        return callbackTrigger
    endfunction

    private function FindMarkerUnit takes nothing returns nothing
        local unit pickedUnit = null
        local integer unitTypeId

        if MarkerUnit != null and GetUnitTypeId(MarkerUnit) != 0 then
            return
        endif

        call GroupClear(SearchGroup)
        call GroupEnumUnitsInRect(SearchGroup, gg_rct_UnknownEntityLureArea, null)
        loop
            set pickedUnit = FirstOfGroup(SearchGroup)
            exitwhen pickedUnit == null
            call GroupRemoveUnit(SearchGroup, pickedUnit)
            set unitTypeId = GetUnitTypeId(pickedUnit)
            if unitTypeId == 'ncp2' or unitTypeId == 'ncp3' or GetUnitName(pickedUnit) == "Circle of Power" then
                set MarkerUnit = pickedUnit
                exitwhen true
            endif
        endloop
        call GroupClear(SearchGroup)
        set pickedUnit = null
    endfunction

    private function SetMarkerVisible takes boolean visible returns nothing
        call FindMarkerUnit()
        if MarkerUnit != null then
            call ShowUnit(MarkerUnit, visible)
        elseif visible then
            call DebugMsg("Circle of Power marker was not found in UnknownEntityLureArea.")
        endif
    endfunction

    private function GetTentacleRectIndex takes unit whichUnit returns integer
        local integer index = 1

        loop
            exitwhen index > 9
            if IsUnitInRect(whichUnit, TentacleRect[index]) then
                return index
            endif
            set index = index + 1
        endloop
        return 0
    endfunction

    private function IsAmbientSpawningEnabled takes nothing returns boolean
        return EncounterStage >= STAGE_INVESTIGATE and EncounterStage <= STAGE_LURE_READY
    endfunction

    private function OnTentacleCooldownExpired takes nothing returns nothing
    endfunction

    private function SpawnTentacles takes integer rectIndex, unit target returns nothing
        local integer count
        local integer index = 0
        local real x
        local real y
        local unit tentacle = null

        if rectIndex <= 0 or rectIndex > 9 or TimerGetRemaining(TentacleCooldownTimer[rectIndex]) > 0.00 then
            return
        endif

        set count = GetRandomInt(1, 3)
        loop
            exitwhen index >= count
            set x = GetRandomReal(GetRectMinX(TentacleRect[rectIndex]), GetRectMaxX(TentacleRect[rectIndex]))
            set y = GetRandomReal(GetRectMinY(TentacleRect[rectIndex]), GetRectMaxY(TentacleRect[rectIndex]))
            set tentacle = CreateUnit(Player(11), UNIT_TENTACLE, x, y, GetRandomReal(0.00, 360.00))
            call UnitApplyTimedLife(tentacle, TIMED_LIFE_BUFF, TENTACLE_LIFETIME)
            if IsUnitAlive(target) then
                call IssueTargetOrder(tentacle, "attack", target)
            endif
            set index = index + 1
        endloop
        call TimerStart(TentacleCooldownTimer[rectIndex], GetRandomReal(TENTACLE_COOLDOWN_MIN, TENTACLE_COOLDOWN_MAX), false, function OnTentacleCooldownExpired)
        set tentacle = null
    endfunction

    private function CleanupLakeTentacles takes nothing returns nothing
        local unit pickedUnit = null

        call GroupClear(CleanupGroup)
        call GroupEnumUnitsInRect(CleanupGroup, gg_rct_LakeAmbient62, null)
        loop
            set pickedUnit = FirstOfGroup(CleanupGroup)
            exitwhen pickedUnit == null
            call GroupRemoveUnit(CleanupGroup, pickedUnit)
            if GetUnitTypeId(pickedUnit) == UNIT_TENTACLE and IsUnitAlive(pickedUnit) then
                call KillUnit(pickedUnit)
            endif
        endloop
        call GroupClear(CleanupGroup)
        set pickedUnit = null
    endfunction

    private function OnBossDeath takes nothing returns nothing
        if Boss_EventBossId != UnknownEntityBossId or EncounterStage == STAGE_DEFEATED then
            return
        endif

        set EncounterStage = STAGE_DEFEATED
        call CleanupLakeTentacles()
        call CreateItem(ITEM_DISGUSTING_SLIME, GetUnitX(UnknownEntityBoss), GetUnitY(UnknownEntityBoss))
        call RunCallback(BossDefeatedCallback)
        call DebugMsg("Unknown Entity defeated.")
    endfunction

    private function OnBossBecomeHostile takes nothing returns nothing
        if EncounterStage != STAGE_REVEALING or not IsUnitAlive(UnknownEntityBoss) then
            return
        endif

        call SetUnitOwner(UnknownEntityBoss, Player(11), true)
        if Boss_Start(UnknownEntityBossId) then
            set EncounterStage = STAGE_ACTIVE
            call IssuePointOrder(UnknownEntityBoss, "attack", GetRectCenterX(gg_rct_UnknownEntityPoint001), GetRectCenterY(gg_rct_UnknownEntityPoint001))
            call DebugMsg("Unknown Entity encounter started.")
        endif
    endfunction

    private function OnBossObjectiveReady takes nothing returns nothing
        if EncounterStage != STAGE_REVEALING or not IsUnitAlive(UnknownEntityBoss) then
            return
        endif

        call RunCallback(BossRevealedCallback)
        call IssuePointOrder(UnknownEntityBoss, "move", GetRectCenterX(gg_rct_UnknownEntityPoint001), GetRectCenterY(gg_rct_UnknownEntityPoint001))
        call TimerStart(BossSequenceTimer, BOSS_HOSTILE_DELAY, false, function OnBossBecomeHostile)
    endfunction

    private function OnBossRevealLine takes nothing returns nothing
        if EncounterStage != STAGE_REVEALING or not IsUnitAlive(UnknownEntityBoss) then
            return
        endif

        if IsUnitAlive(udg_Nazgrek) then
            call ExSound_PlayAtUnit(VL_NAZGREK_0046_KEY, udg_Nazgrek, VL_NAZGREK_0046_TEXT)
            call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, udg_Nazgrek, NAZGREK_NAME, null, VL_NAZGREK_0046_TEXT, bj_TIMETYPE_SET, BOSS_LINE_DURATION, false)
        else
            call ExSound_Play(VL_NAZGREK_0046_KEY, VL_NAZGREK_0046_TEXT)
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, BOSS_LINE_DURATION, VL_NAZGREK_0046_TEXT)
        endif
        call TimerStart(BossSequenceTimer, BOSS_LINE_DURATION + BOSS_OBJECTIVE_DELAY, false, function OnBossObjectiveReady)
    endfunction

    private function OnBossSpawn takes nothing returns nothing
        local real x
        local real y

        if EncounterStage != STAGE_REVEALING then
            return
        endif

        set x = GetRectCenterX(gg_rct_UnknownEntitySurface)
        set y = GetRectCenterY(gg_rct_UnknownEntitySurface)
        set UnknownEntityBoss = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_UNKNOWN_ENTITY, x, y, BOSS_FACING)
        set UnknownEntityBossId = Boss_Register(UnknownEntityBoss, "Unknown Entity")
        if UnknownEntityBossId == 0 then
            call DebugMsg("Failed to register Unknown Entity with Boss.j.")
            return
        endif
        call Boss_SetEventCallback(UnknownEntityBossId, BOSS_EVENT_DEATH, function OnBossDeath)
        call Boss_SetPhaseCount(UnknownEntityBossId, 1)
        call TimerStart(BossSequenceTimer, BOSS_LINE_DELAY, false, function OnBossRevealLine)
    endfunction

    private function OnRemoveLureItem takes nothing returns nothing
        if LureItem != null then
            call RemoveItem(LureItem)
            set LureItem = null
        endif
    endfunction

    private function OnLureDropped takes nothing returns nothing
        local unit hero = GetTriggerUnit()
        local item droppedItem = GetManipulatedItem()
        local unit tentacle = null
        local real x
        local real y

        if EncounterStage != STAGE_LURE_READY or GetOwningPlayer(hero) != Player(0) or droppedItem == null or not IsUnitInRect(hero, gg_rct_UnknownEntityLureArea) or not IsRawMeat(GetItemTypeId(droppedItem)) then
            set hero = null
            set droppedItem = null
            return
        endif

        set EncounterStage = STAGE_REVEALING
        set LureItem = droppedItem
        set x = GetUnitX(hero)
        set y = GetUnitY(hero)
        call SetItemPosition(LureItem, x, y)
        set tentacle = CreateUnit(Player(11), UNIT_TENTACLE, x, y, BOSS_FACING)
        call UnitApplyTimedLife(tentacle, TIMED_LIFE_BUFF, 5.00)
        call SetUnitAnimation(tentacle, "birth")
        call QueueUnitAnimation(tentacle, "attack")
        call QueueUnitAnimation(tentacle, "stand")
        call SetMarkerVisible(false)
        call TimerStart(LureRemoveTimer, LURE_REMOVE_DELAY, false, function OnRemoveLureItem)
        call TimerStart(BossSpawnTimer, BOSS_SPAWN_DELAY, false, function OnBossSpawn)
        call DebugMsg("Raw meat lure accepted.")

        set hero = null
        set droppedItem = null
        set tentacle = null
    endfunction

    private function OnClueLineFinished takes nothing returns nothing
        if EncounterStage != STAGE_CLUE_PENDING then
            return
        endif

        set EncounterStage = STAGE_LURE_READY
        call RunCallback(LureReadyCallback)
        call DebugMsg("Unknown Entity lure objective unlocked.")
    endfunction

    private function OnClueLine takes nothing returns nothing
        if EncounterStage != STAGE_CLUE_PENDING then
            return
        endif

        if IsUnitAlive(udg_Nazgrek) then
            call ExSound_PlayAtUnit(VL_NAZGREK_0045_KEY, udg_Nazgrek, VL_NAZGREK_0045_TEXT)
            call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, udg_Nazgrek, NAZGREK_NAME, null, VL_NAZGREK_0045_TEXT, bj_TIMETYPE_SET, CLUE_LINE_DURATION, false)
        else
            call ExSound_Play(VL_NAZGREK_0045_KEY, VL_NAZGREK_0045_TEXT)
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, CLUE_LINE_DURATION, VL_NAZGREK_0045_TEXT)
        endif
        call TimerStart(ClueTimer, CLUE_LINE_DURATION, false, function OnClueLineFinished)
    endfunction

    private function OnTentacleRegionEntered takes nothing returns nothing
        local unit enteringUnit = GetEnteringUnit()
        local player ownerPlayer = GetOwningPlayer(enteringUnit)
        local integer rectIndex

        if not IsAmbientSpawningEnabled() or not IsAmbientHeroOwner(ownerPlayer) then
            set enteringUnit = null
            set ownerPlayer = null
            return
        endif

        set rectIndex = GetTentacleRectIndex(enteringUnit)
        call SpawnTentacles(rectIndex, enteringUnit)
        if EncounterStage == STAGE_INVESTIGATE and ownerPlayer == Player(0) then
            set EncounterStage = STAGE_CLUE_PENDING
            call TimerStart(ClueTimer, CLUE_DELAY, false, function OnClueLine)
        endif

        set enteringUnit = null
        set ownerPlayer = null
    endfunction

    public function SetQuestCallbacks takes code onLureReady, code onBossRevealed, code onBossDefeated returns nothing
        if LureReadyCallback != null then
            call DestroyTrigger(LureReadyCallback)
        endif
        if BossRevealedCallback != null then
            call DestroyTrigger(BossRevealedCallback)
        endif
        if BossDefeatedCallback != null then
            call DestroyTrigger(BossDefeatedCallback)
        endif
        set LureReadyCallback = CreateCallback(onLureReady)
        set BossRevealedCallback = CreateCallback(onBossRevealed)
        set BossDefeatedCallback = CreateCallback(onBossDefeated)
    endfunction

    public function SetMarkerUnit takes unit whichUnit returns nothing
        set MarkerUnit = whichUnit
        if EncounterStage == STAGE_DORMANT or EncounterStage > STAGE_LURE_READY then
            call SetMarkerVisible(false)
        endif
    endfunction

    public function Arm takes nothing returns nothing
        if EncounterStage == STAGE_ACTIVE or EncounterStage == STAGE_REVEALING or EncounterStage == STAGE_DEFEATED then
            return
        endif

        set EncounterStage = STAGE_INVESTIGATE
        call SetMarkerVisible(true)
        call DebugMsg("Unknown Entity encounter armed.")
    endfunction

    public function Disarm takes nothing returns nothing
        if EncounterStage == STAGE_ACTIVE or EncounterStage == STAGE_REVEALING then
            return
        endif

        set EncounterStage = STAGE_DORMANT
        call PauseTimer(ClueTimer)
        call SetMarkerVisible(false)
    endfunction

    public function GetBoss takes nothing returns unit
        return UnknownEntityBoss
    endfunction

    public function GetBossId takes nothing returns integer
        return UnknownEntityBossId
    endfunction

    public function GetStage takes nothing returns integer
        return EncounterStage
    endfunction

    private function InitDelayed takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local integer index = 1

        set TentacleRect[1] = gg_rct_Tentacles001
        set TentacleRect[2] = gg_rct_Tentacles002
        set TentacleRect[3] = gg_rct_Tentacles003
        set TentacleRect[4] = gg_rct_Tentacles004
        set TentacleRect[5] = gg_rct_Tentacles005
        set TentacleRect[6] = gg_rct_Tentacles006
        set TentacleRect[7] = gg_rct_Tentacles007
        set TentacleRect[8] = gg_rct_Tentacles008
        set TentacleRect[9] = gg_rct_Tentacles009

        set SearchGroup = CreateGroup()
        set CleanupGroup = CreateGroup()
        set ClueTimer = CreateTimer()
        set LureRemoveTimer = CreateTimer()
        set BossSpawnTimer = CreateTimer()
        set BossSequenceTimer = CreateTimer()
        set TentacleEnterTrigger = CreateTrigger()
        loop
            exitwhen index > 9
            set TentacleCooldownTimer[index] = CreateTimer()
            call TriggerRegisterEnterRectSimple(TentacleEnterTrigger, TentacleRect[index])
            set index = index + 1
        endloop
        call TriggerAddAction(TentacleEnterTrigger, function OnTentacleRegionEntered)

        set LureDropTrigger = CreateTrigger()
        call TriggerRegisterPlayerUnitEvent(LureDropTrigger, Player(0), EVENT_PLAYER_UNIT_DROP_ITEM, null)
        call TriggerAddAction(LureDropTrigger, function OnLureDropped)

        call FindMarkerUnit()
        call SetMarkerVisible(false)
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
    endfunction
endlibrary
