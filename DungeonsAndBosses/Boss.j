/**
    Boss

    Author: Valdemar
    Version: 0.3.0

    Description:
    Shared foundation for PotS boss encounters. The library registers
    boss units, tracks idle/active/resetting/defeated state, exposes phase and
    lifecycle callbacks, supports optional attack-start and combat-area reset,
    and can intercept lethal damage for scripted defeat sequences. Registered
    bosses are removed from ordinary creep respawn so Boss or Dungeon remains
    the single owner of their lifecycle.

    Encounter libraries can also publish a short overview, phase summary,
    ability summary, and tactics text for quest/UI consumers. Boss_Respawn
    recreates a defeated boss at its captured home and preserves its id and
    callbacks.

    Credits:
    - DungeonsAndBosses/OpenWorld/Unknown Entity/_OldGui
    - DungeonsAndBosses/OpenWorld/Void Entity/_OldGUI
    - DungeonsAndBosses/_oldGUI/Init Boss Units

    How to install:
    Import after Table, Events, UnitDeathEvent, DamageEngine, and CreepRespawn.
    Import this library before encounter-specific boss libraries. Combat-area
    rects passed to Boss_SetCombatArea are borrowed map references.

    API:
    - set bossId = Boss_Register(whichUnit, displayName)
    - set whichUnit = Boss_FindUnitByName(unitName, searchRect)
    - call Boss_Unregister(bossId)
    - call Boss_ReplaceUnit(bossId, newUnit, true)
    - call Boss_SetEventCallback(bossId, eventType, function YourCallback)
    - call Boss_SetAutoStartOnAttack(bossId, true)
    - call Boss_SetCombatArea(bossId, combatRect, Player(0), true)
    - call Boss_SetArena(bossId, combatRect, Player(0), true) // Compatibility
    - call Boss_SetDefeatMode(bossId, BOSS_DEFEAT_MODE_SCRIPTED)
    - call Boss_SetPhaseCount(bossId, 3)
    - call Boss_SetDescription(bossId, overview, phases, abilities, tactics)
    - call Boss_SetDungeonId(bossId, dungeonId)
    - call Boss_Start(bossId)
    - call Boss_SetPhase(bossId, phase)
    - call Boss_AdvancePhase(bossId)
    - call Boss_Reset(bossId)
    - call Boss_Defeat(bossId, killer)
    - call Boss_FinishScriptedDefeat(bossId)
    - set whichUnit = Boss_Respawn(bossId)
    - set bossId = Boss_GetId(whichUnit)
    - set whichUnit = Boss_GetUnit(bossId)
    - set text = Boss_GetName(bossId)
    - set text = Boss_GetOverview(bossId)
    - set text = Boss_GetPhaseDescription(bossId)
    - set text = Boss_GetAbilityDescription(bossId)
    - set text = Boss_GetTactics(bossId)
    - set state = Boss_GetState(bossId)
    - set phase = Boss_GetPhase(bossId)
    - set text = Boss_GetEncounterText(bossId)

    Event callbacks read Boss_EventBossId, Boss_EventType, Boss_EventUnit,
    Boss_EventKiller, Boss_EventPreviousPhase, and Boss_EventPhase.

**/
library Boss initializer Init requires Table, Events, UnitDeathEvent, DamageEngine, CreepRespawn
    globals
        // Lifecycle states.
        constant integer BOSS_STATE_NONE = 0
        constant integer BOSS_STATE_IDLE = 1
        constant integer BOSS_STATE_ACTIVE = 2
        constant integer BOSS_STATE_RESETTING = 3
        constant integer BOSS_STATE_DEFEATED = 4

        // Per-boss callback slots.
        constant integer BOSS_EVENT_START = 1
        constant integer BOSS_EVENT_RESET = 2
        constant integer BOSS_EVENT_PHASE = 3
        constant integer BOSS_EVENT_DEFEAT = 4
        constant integer BOSS_EVENT_DEATH = 5
        constant integer BOSS_EVENT_RESPAWN = 6

        // Normal bosses die through the native death flow. Scripted bosses
        // stop at one life so their encounter library can finish presentation.
        constant integer BOSS_DEFEAT_MODE_NORMAL = 0
        constant integer BOSS_DEFEAT_MODE_SCRIPTED = 1

        // Current callback context.
        integer Boss_EventBossId = 0
        integer Boss_EventType = 0
        unit Boss_EventUnit = null
        unit Boss_EventKiller = null
        integer Boss_EventPreviousPhase = 0
        integer Boss_EventPhase = 0

        private constant integer BOSS_MAX_COUNT = 128
        private constant integer BOSS_EVENT_MAX = 7
        private constant real BOSS_COMBAT_AREA_CHECK_INTERVAL = 5.00

        private Table Boss_UnitId = 0
        private integer Boss_Count = 0
        private integer Boss_ActiveCount = 0
        private unit array Boss_Unit
        private integer array Boss_UnitTypeId
        private string array Boss_Name
        private string array Boss_Overview
        private string array Boss_PhaseDescription
        private string array Boss_AbilityDescription
        private string array Boss_Tactics
        private integer array Boss_State
        private integer array Boss_Phase
        private integer array Boss_PhaseCount
        private integer array Boss_DefeatMode
        private integer array Boss_DungeonId
        private boolean array Boss_AutoStartOnAttack
        private boolean array Boss_ResetWhenCombatAreaEmpty
        private rect array Boss_CombatArea
        private player array Boss_ResetPlayer
        private player array Boss_ResetOwner
        private real array Boss_HomeX
        private real array Boss_HomeY
        private real array Boss_HomeFacing
        private trigger array Boss_Callback
        private group Boss_CombatAreaSearchGroup = null
        private group Boss_FindGroup = null
        private unit Boss_FindResult = null
        private timer Boss_CombatAreaCheckTimer = null
        private boolean Boss_DebugEnabled = false
    endglobals

    private function Boss_Debug takes string message returns nothing
        if Boss_DebugEnabled then
            call BJDebugMsg("|cffcc66ff[Boss]|r " + message)
        endif
    endfunction

    private function Boss_Error takes string message returns nothing
        call BJDebugMsg("|cffff8080[Boss] ERROR:|r " + message)
    endfunction

    private function Boss_IsValidId takes integer bossId returns boolean
        return bossId > 0 and bossId <= Boss_Count and Boss_State[bossId] != BOSS_STATE_NONE and Boss_Unit[bossId] != null
    endfunction

    private function Boss_IsValidEventType takes integer eventType returns boolean
        return eventType >= BOSS_EVENT_START and eventType <= BOSS_EVENT_RESPAWN
    endfunction

    private function Boss_IsUnitAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function Boss_GetCallbackIndex takes integer bossId, integer eventType returns integer
        return bossId * BOSS_EVENT_MAX + eventType
    endfunction

    private function Boss_RunEvent takes integer bossId, integer eventType, unit killer, integer previousPhase, integer newPhase returns nothing
        local trigger callbackTrigger
        local integer previousBossId
        local integer previousEventType
        local unit previousEventUnit
        local unit previousEventKiller
        local integer previousEventPreviousPhase
        local integer previousEventPhase

        if not Boss_IsValidId(bossId) or not Boss_IsValidEventType(eventType) then
            return
        endif

        set callbackTrigger = Boss_Callback[Boss_GetCallbackIndex(bossId, eventType)]
        if callbackTrigger == null then
            return
        endif

        set previousBossId = Boss_EventBossId
        set previousEventType = Boss_EventType
        set previousEventUnit = Boss_EventUnit
        set previousEventKiller = Boss_EventKiller
        set previousEventPreviousPhase = Boss_EventPreviousPhase
        set previousEventPhase = Boss_EventPhase

        set Boss_EventBossId = bossId
        set Boss_EventType = eventType
        set Boss_EventUnit = Boss_Unit[bossId]
        set Boss_EventKiller = killer
        set Boss_EventPreviousPhase = previousPhase
        set Boss_EventPhase = newPhase
        call TriggerExecute(callbackTrigger)

        set Boss_EventBossId = previousBossId
        set Boss_EventType = previousEventType
        set Boss_EventUnit = previousEventUnit
        set Boss_EventKiller = previousEventKiller
        set Boss_EventPreviousPhase = previousEventPreviousPhase
        set Boss_EventPhase = previousEventPhase

        set callbackTrigger = null
        set previousEventUnit = null
        set previousEventKiller = null
    endfunction

    private function Boss_DefeatInternal takes integer bossId, unit killer returns boolean
        local unit whichUnit = null
        local integer phase

        if not Boss_IsValidId(bossId) or (Boss_State[bossId] != BOSS_STATE_ACTIVE and Boss_State[bossId] != BOSS_STATE_IDLE) then
            return false
        endif

        set whichUnit = Boss_Unit[bossId]
        set phase = Boss_Phase[bossId]
        if Boss_State[bossId] == BOSS_STATE_ACTIVE and Boss_ActiveCount > 0 then
            set Boss_ActiveCount = Boss_ActiveCount - 1
        endif
        set Boss_State[bossId] = BOSS_STATE_DEFEATED

        if Boss_DefeatMode[bossId] == BOSS_DEFEAT_MODE_SCRIPTED and Boss_IsUnitAlive(whichUnit) then
            call SetUnitInvulnerable(whichUnit, true)
            call PauseUnit(whichUnit, true)
            call IssueImmediateOrder(whichUnit, "stop")
        endif

        call Boss_Debug("Defeated " + Boss_Name[bossId] + ".")
        call Boss_RunEvent(bossId, BOSS_EVENT_DEFEAT, killer, phase, phase)
        set whichUnit = null
        return true
    endfunction

    private function Boss_CombatAreaHasResetPlayerUnit takes integer bossId returns boolean
        local unit whichUnit = null
        local boolean found = false

        if Boss_CombatArea[bossId] == null or Boss_ResetPlayer[bossId] == null then
            return false
        endif

        call GroupClear(Boss_CombatAreaSearchGroup)
        call GroupEnumUnitsInRect(Boss_CombatAreaSearchGroup, Boss_CombatArea[bossId], null)
        loop
            set whichUnit = FirstOfGroup(Boss_CombatAreaSearchGroup)
            exitwhen whichUnit == null
            call GroupRemoveUnit(Boss_CombatAreaSearchGroup, whichUnit)
            if GetOwningPlayer(whichUnit) == Boss_ResetPlayer[bossId] and Boss_IsUnitAlive(whichUnit) then
                set found = true
                exitwhen true
            endif
        endloop
        call GroupClear(Boss_CombatAreaSearchGroup)
        set whichUnit = null
        return found
    endfunction

    public function SetDebugEnabled takes boolean enabled returns nothing
        set Boss_DebugEnabled = enabled
    endfunction

    public function GetId takes unit whichUnit returns integer
        if whichUnit == null or Boss_UnitId == 0 then
            return 0
        endif
        return Boss_UnitId[GetHandleId(whichUnit)]
    endfunction

    public function GetUnit takes integer bossId returns unit
        if not Boss_IsValidId(bossId) then
            return null
        endif
        return Boss_Unit[bossId]
    endfunction

    public function GetName takes integer bossId returns string
        if not Boss_IsValidId(bossId) then
            return "Boss"
        endif
        return Boss_Name[bossId]
    endfunction

    public function GetOverview takes integer bossId returns string
        if not Boss_IsValidId(bossId) then
            return ""
        endif
        return Boss_Overview[bossId]
    endfunction

    public function GetPhaseDescription takes integer bossId returns string
        if not Boss_IsValidId(bossId) then
            return ""
        endif
        return Boss_PhaseDescription[bossId]
    endfunction

    public function GetAbilityDescription takes integer bossId returns string
        if not Boss_IsValidId(bossId) then
            return ""
        endif
        return Boss_AbilityDescription[bossId]
    endfunction

    public function GetTactics takes integer bossId returns string
        if not Boss_IsValidId(bossId) then
            return ""
        endif
        return Boss_Tactics[bossId]
    endfunction

    public function GetEncounterText takes integer bossId returns string
        local string text

        if not Boss_IsValidId(bossId) then
            return ""
        endif

        set text = Boss_Overview[bossId]
        if Boss_PhaseDescription[bossId] != "" then
            set text = text + "|n|n|cffffcc00Phases|r|n" + Boss_PhaseDescription[bossId]
        endif
        if Boss_AbilityDescription[bossId] != "" then
            set text = text + "|n|n|cffffcc00Abilities|r|n" + Boss_AbilityDescription[bossId]
        endif
        if Boss_Tactics[bossId] != "" then
            set text = text + "|n|n|cff80ff80Tactics|r|n" + Boss_Tactics[bossId]
        endif
        return text
    endfunction

    public function GetDungeonId takes integer bossId returns integer
        if not Boss_IsValidId(bossId) then
            return 0
        endif
        return Boss_DungeonId[bossId]
    endfunction

    public function GetState takes integer bossId returns integer
        if not Boss_IsValidId(bossId) then
            return BOSS_STATE_NONE
        endif
        return Boss_State[bossId]
    endfunction

    public function GetPhase takes integer bossId returns integer
        if not Boss_IsValidId(bossId) then
            return 0
        endif
        return Boss_Phase[bossId]
    endfunction

    public function GetPhaseCount takes integer bossId returns integer
        if not Boss_IsValidId(bossId) then
            return 0
        endif
        return Boss_PhaseCount[bossId]
    endfunction

    public function GetActiveCount takes nothing returns integer
        return Boss_ActiveCount
    endfunction

    public function IsRegistered takes unit whichUnit returns boolean
        return GetId(whichUnit) > 0
    endfunction

    public function IsActive takes integer bossId returns boolean
        return Boss_IsValidId(bossId) and Boss_State[bossId] == BOSS_STATE_ACTIVE
    endfunction

    public function FindUnitByName takes string unitName, rect searchRect returns unit
        local unit pickedUnit = null

        if unitName == "" then
            return null
        endif
        set Boss_FindResult = null
        call GroupClear(Boss_FindGroup)
        if searchRect == null then
            call GroupEnumUnitsInRect(Boss_FindGroup, bj_mapInitialPlayableArea, null)
        else
            call GroupEnumUnitsInRect(Boss_FindGroup, searchRect, null)
        endif
        loop
            set pickedUnit = FirstOfGroup(Boss_FindGroup)
            exitwhen pickedUnit == null
            call GroupRemoveUnit(Boss_FindGroup, pickedUnit)
            if GetUnitName(pickedUnit) == unitName then
                set Boss_FindResult = pickedUnit
                call GroupClear(Boss_FindGroup)
                set pickedUnit = null
                return Boss_FindResult
            endif
        endloop
        call GroupClear(Boss_FindGroup)
        set pickedUnit = null
        return null
    endfunction

    public function Register takes unit whichUnit, string displayName returns integer
        local integer bossId

        if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
            call Boss_Error("Cannot register a null or removed unit.")
            return 0
        endif

        set bossId = GetId(whichUnit)
        if bossId > 0 then
            return bossId
        endif
        if Boss_Count >= BOSS_MAX_COUNT then
            call Boss_Error("Maximum registered boss count reached (" + I2S(BOSS_MAX_COUNT) + ").")
            return 0
        endif

        set Boss_Count = Boss_Count + 1
        set bossId = Boss_Count
        set Boss_Unit[bossId] = whichUnit
        set Boss_UnitTypeId[bossId] = GetUnitTypeId(whichUnit)
        if displayName == null or displayName == "" then
            set Boss_Name[bossId] = GetUnitName(whichUnit)
        else
            set Boss_Name[bossId] = displayName
        endif
        set Boss_State[bossId] = BOSS_STATE_IDLE
        set Boss_Phase[bossId] = 0
        set Boss_PhaseCount[bossId] = 1
        set Boss_DefeatMode[bossId] = BOSS_DEFEAT_MODE_NORMAL
        set Boss_DungeonId[bossId] = 0
        set Boss_AutoStartOnAttack[bossId] = false
        set Boss_ResetWhenCombatAreaEmpty[bossId] = false
        set Boss_ResetPlayer[bossId] = Player(0)
        set Boss_ResetOwner[bossId] = GetOwningPlayer(whichUnit)
        set Boss_HomeX[bossId] = GetUnitX(whichUnit)
        set Boss_HomeY[bossId] = GetUnitY(whichUnit)
        set Boss_HomeFacing[bossId] = GetUnitFacing(whichUnit)
        set Boss_UnitId[GetHandleId(whichUnit)] = bossId
        call CreepRespawn_DiscardUnit(whichUnit)

        if udg_BOSS == null then
            set udg_BOSS = CreateGroup()
        endif
        call GroupAddUnit(udg_BOSS, whichUnit)
        call Boss_Debug("Registered " + Boss_Name[bossId] + " as id " + I2S(bossId) + ".")
        return bossId
    endfunction

    public function Unregister takes integer bossId returns nothing
        local integer eventType
        local integer callbackIndex
        local trigger callbackTrigger = null

        if not Boss_IsValidId(bossId) then
            return
        endif

        if Boss_State[bossId] == BOSS_STATE_ACTIVE and Boss_ActiveCount > 0 then
            set Boss_ActiveCount = Boss_ActiveCount - 1
        endif
        call Boss_UnitId.remove(GetHandleId(Boss_Unit[bossId]))
        if udg_BOSS != null then
            call GroupRemoveUnit(udg_BOSS, Boss_Unit[bossId])
        endif

        set eventType = BOSS_EVENT_START
        loop
            exitwhen eventType > BOSS_EVENT_RESPAWN
            set callbackIndex = Boss_GetCallbackIndex(bossId, eventType)
            set callbackTrigger = Boss_Callback[callbackIndex]
            if callbackTrigger != null then
                call DestroyTrigger(callbackTrigger)
                set Boss_Callback[callbackIndex] = null
            endif
            set eventType = eventType + 1
        endloop

        set Boss_Unit[bossId] = null
        set Boss_UnitTypeId[bossId] = 0
        set Boss_Name[bossId] = ""
        set Boss_Overview[bossId] = ""
        set Boss_PhaseDescription[bossId] = ""
        set Boss_AbilityDescription[bossId] = ""
        set Boss_Tactics[bossId] = ""
        set Boss_State[bossId] = BOSS_STATE_NONE
        set Boss_Phase[bossId] = 0
        set Boss_PhaseCount[bossId] = 0
        set Boss_DefeatMode[bossId] = BOSS_DEFEAT_MODE_NORMAL
        set Boss_DungeonId[bossId] = 0
        set Boss_AutoStartOnAttack[bossId] = false
        set Boss_ResetWhenCombatAreaEmpty[bossId] = false
        set Boss_CombatArea[bossId] = null
        set Boss_ResetPlayer[bossId] = null
        set Boss_ResetOwner[bossId] = null
        set Boss_HomeX[bossId] = 0.00
        set Boss_HomeY[bossId] = 0.00
        set Boss_HomeFacing[bossId] = 0.00
        set callbackTrigger = null
    endfunction

    public function ReplaceUnit takes integer bossId, unit newUnit, boolean captureHome returns boolean
        local unit oldUnit = null
        local integer existingId

        if not Boss_IsValidId(bossId) or newUnit == null or GetUnitTypeId(newUnit) == 0 then
            return false
        endif
        set existingId = GetId(newUnit)
        if existingId > 0 and existingId != bossId then
            call Boss_Error("Replacement unit is already registered to boss id " + I2S(existingId) + ".")
            return false
        endif

        set oldUnit = Boss_Unit[bossId]
        call Boss_UnitId.remove(GetHandleId(oldUnit))
        if udg_BOSS != null then
            call GroupRemoveUnit(udg_BOSS, oldUnit)
        endif

        set Boss_Unit[bossId] = newUnit
        set Boss_UnitId[GetHandleId(newUnit)] = bossId
        call CreepRespawn_DiscardUnit(newUnit)
        if udg_BOSS == null then
            set udg_BOSS = CreateGroup()
        endif
        call GroupAddUnit(udg_BOSS, newUnit)
        if captureHome then
            set Boss_UnitTypeId[bossId] = GetUnitTypeId(newUnit)
            set Boss_ResetOwner[bossId] = GetOwningPlayer(newUnit)
            set Boss_HomeX[bossId] = GetUnitX(newUnit)
            set Boss_HomeY[bossId] = GetUnitY(newUnit)
            set Boss_HomeFacing[bossId] = GetUnitFacing(newUnit)
        endif

        set oldUnit = null
        return true
    endfunction

    public function SetEventCallback takes integer bossId, integer eventType, code callback returns nothing
        local integer callbackIndex
        local trigger oldTrigger = null

        if not Boss_IsValidId(bossId) or not Boss_IsValidEventType(eventType) then
            return
        endif

        set callbackIndex = Boss_GetCallbackIndex(bossId, eventType)
        set oldTrigger = Boss_Callback[callbackIndex]
        if oldTrigger != null then
            call DestroyTrigger(oldTrigger)
            set Boss_Callback[callbackIndex] = null
        endif
        if callback != null then
            set Boss_Callback[callbackIndex] = CreateTrigger()
            call TriggerAddAction(Boss_Callback[callbackIndex], callback)
        endif
        set oldTrigger = null
    endfunction

    public function SetAutoStartOnAttack takes integer bossId, boolean enabled returns nothing
        if Boss_IsValidId(bossId) then
            set Boss_AutoStartOnAttack[bossId] = enabled
        endif
    endfunction

    public function SetCombatArea takes integer bossId, rect combatRect, player resetPlayer, boolean resetWhenEmpty returns nothing
        if not Boss_IsValidId(bossId) then
            return
        endif
        set Boss_CombatArea[bossId] = combatRect
        if resetPlayer == null then
            set Boss_ResetPlayer[bossId] = Player(0)
        else
            set Boss_ResetPlayer[bossId] = resetPlayer
        endif
        set Boss_ResetWhenCombatAreaEmpty[bossId] = resetWhenEmpty and combatRect != null
    endfunction

    public function SetArena takes integer bossId, rect combatRect, player resetPlayer, boolean resetWhenEmpty returns nothing
        call SetCombatArea(bossId, combatRect, resetPlayer, resetWhenEmpty)
    endfunction

    public function SetResetOwner takes integer bossId, player resetOwner returns nothing
        if Boss_IsValidId(bossId) then
            set Boss_ResetOwner[bossId] = resetOwner
        endif
    endfunction

    public function SetHome takes integer bossId, real x, real y, real facing returns nothing
        if Boss_IsValidId(bossId) then
            set Boss_HomeX[bossId] = x
            set Boss_HomeY[bossId] = y
            set Boss_HomeFacing[bossId] = facing
        endif
    endfunction

    public function CaptureHome takes integer bossId returns nothing
        if Boss_IsValidId(bossId) then
            call SetHome(bossId, GetUnitX(Boss_Unit[bossId]), GetUnitY(Boss_Unit[bossId]), GetUnitFacing(Boss_Unit[bossId]))
            set Boss_ResetOwner[bossId] = GetOwningPlayer(Boss_Unit[bossId])
        endif
    endfunction

    public function SetDefeatMode takes integer bossId, integer defeatMode returns nothing
        if not Boss_IsValidId(bossId) then
            return
        endif
        if defeatMode == BOSS_DEFEAT_MODE_SCRIPTED then
            set Boss_DefeatMode[bossId] = BOSS_DEFEAT_MODE_SCRIPTED
        else
            set Boss_DefeatMode[bossId] = BOSS_DEFEAT_MODE_NORMAL
        endif
    endfunction

    public function SetPhaseCount takes integer bossId, integer phaseCount returns nothing
        if not Boss_IsValidId(bossId) then
            return
        endif
        if phaseCount < 1 then
            set phaseCount = 1
        endif
        set Boss_PhaseCount[bossId] = phaseCount
        if Boss_Phase[bossId] > phaseCount then
            set Boss_Phase[bossId] = phaseCount
        endif
    endfunction

    public function SetDescription takes integer bossId, string overview, string phases, string abilities, string tactics returns nothing
        if not Boss_IsValidId(bossId) then
            return
        endif
        set Boss_Overview[bossId] = overview
        set Boss_PhaseDescription[bossId] = phases
        set Boss_AbilityDescription[bossId] = abilities
        set Boss_Tactics[bossId] = tactics
    endfunction

    public function SetDungeonId takes integer bossId, integer dungeonId returns nothing
        if Boss_IsValidId(bossId) then
            set Boss_DungeonId[bossId] = dungeonId
        endif
    endfunction

    public function Start takes integer bossId returns boolean
        if not Boss_IsValidId(bossId) or Boss_State[bossId] != BOSS_STATE_IDLE or not Boss_IsUnitAlive(Boss_Unit[bossId]) then
            return false
        endif

        set Boss_State[bossId] = BOSS_STATE_ACTIVE
        set Boss_Phase[bossId] = 1
        set Boss_ActiveCount = Boss_ActiveCount + 1
        call Boss_Debug("Started " + Boss_Name[bossId] + ".")
        call Boss_RunEvent(bossId, BOSS_EVENT_START, null, 0, 1)
        return true
    endfunction

    public function SetPhase takes integer bossId, integer newPhase returns boolean
        local integer previousPhase

        if not Boss_IsValidId(bossId) or Boss_State[bossId] != BOSS_STATE_ACTIVE then
            return false
        endif
        if newPhase < 1 then
            set newPhase = 1
        elseif newPhase > Boss_PhaseCount[bossId] then
            set newPhase = Boss_PhaseCount[bossId]
        endif
        if newPhase == Boss_Phase[bossId] then
            return false
        endif

        set previousPhase = Boss_Phase[bossId]
        set Boss_Phase[bossId] = newPhase
        call Boss_Debug(Boss_Name[bossId] + " entered phase " + I2S(newPhase) + ".")
        call Boss_RunEvent(bossId, BOSS_EVENT_PHASE, null, previousPhase, newPhase)
        return true
    endfunction

    public function AdvancePhase takes integer bossId returns boolean
        if not Boss_IsValidId(bossId) then
            return false
        endif
        return SetPhase(bossId, Boss_Phase[bossId] + 1)
    endfunction

    public function Reset takes integer bossId returns boolean
        local unit whichUnit = null
        local integer previousPhase

        if not Boss_IsValidId(bossId) or (Boss_State[bossId] != BOSS_STATE_ACTIVE and Boss_State[bossId] != BOSS_STATE_DEFEATED) then
            return false
        endif
        set whichUnit = Boss_Unit[bossId]
        if not Boss_IsUnitAlive(whichUnit) then
            set whichUnit = null
            return false
        endif

        if Boss_State[bossId] == BOSS_STATE_ACTIVE and Boss_ActiveCount > 0 then
            set Boss_ActiveCount = Boss_ActiveCount - 1
        endif
        set previousPhase = Boss_Phase[bossId]
        set Boss_State[bossId] = BOSS_STATE_RESETTING

        call SetUnitInvulnerable(whichUnit, false)
        call PauseUnit(whichUnit, false)
        call IssueImmediateOrder(whichUnit, "stop")
        if Boss_ResetOwner[bossId] != null and GetOwningPlayer(whichUnit) != Boss_ResetOwner[bossId] then
            call SetUnitOwner(whichUnit, Boss_ResetOwner[bossId], true)
        endif
        call SetUnitPosition(whichUnit, Boss_HomeX[bossId], Boss_HomeY[bossId])
        call SetUnitFacing(whichUnit, Boss_HomeFacing[bossId])
        call SetWidgetLife(whichUnit, GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE))
        call SetUnitState(whichUnit, UNIT_STATE_MANA, GetUnitState(whichUnit, UNIT_STATE_MAX_MANA))
        set Boss_Phase[bossId] = 0

        call Boss_Debug("Reset " + Boss_Name[bossId] + ".")
        call Boss_RunEvent(bossId, BOSS_EVENT_RESET, null, previousPhase, 0)
        if Boss_IsValidId(bossId) then
            set Boss_State[bossId] = BOSS_STATE_IDLE
        endif
        set whichUnit = null
        return true
    endfunction

    public function Defeat takes integer bossId, unit killer returns boolean
        return Boss_DefeatInternal(bossId, killer)
    endfunction

    public function FinishScriptedDefeat takes integer bossId returns boolean
        local unit whichUnit = null

        if not Boss_IsValidId(bossId) or Boss_State[bossId] != BOSS_STATE_DEFEATED or Boss_DefeatMode[bossId] != BOSS_DEFEAT_MODE_SCRIPTED then
            return false
        endif
        set whichUnit = Boss_Unit[bossId]
        if not Boss_IsUnitAlive(whichUnit) then
            set whichUnit = null
            return false
        endif

        call PauseUnit(whichUnit, false)
        call SetUnitInvulnerable(whichUnit, false)
        call KillUnit(whichUnit)
        set whichUnit = null
        return true
    endfunction

    public function Respawn takes integer bossId returns unit
        local unit oldUnit = null
        local unit newUnit = null
        local player ownerPlayer = null

        if not Boss_IsValidId(bossId) or Boss_State[bossId] != BOSS_STATE_DEFEATED or Boss_UnitTypeId[bossId] == 0 or Boss_IsUnitAlive(Boss_Unit[bossId]) then
            return null
        endif

        set oldUnit = Boss_Unit[bossId]
        set ownerPlayer = Boss_ResetOwner[bossId]
        if ownerPlayer == null then
            set ownerPlayer = Player(PLAYER_NEUTRAL_AGGRESSIVE)
        endif
        set newUnit = CreateUnit(ownerPlayer, Boss_UnitTypeId[bossId], Boss_HomeX[bossId], Boss_HomeY[bossId], Boss_HomeFacing[bossId])
        if newUnit == null then
            set oldUnit = null
            set ownerPlayer = null
            return null
        endif

        if not ReplaceUnit(bossId, newUnit, false) then
            call RemoveUnit(newUnit)
            set oldUnit = null
            set newUnit = null
            set ownerPlayer = null
            return null
        endif
        if oldUnit != null and oldUnit != newUnit and GetUnitTypeId(oldUnit) != 0 then
            call RemoveUnit(oldUnit)
        endif

        call SetUnitOwner(newUnit, ownerPlayer, true)
        call SetUnitPosition(newUnit, Boss_HomeX[bossId], Boss_HomeY[bossId])
        call SetUnitFacing(newUnit, Boss_HomeFacing[bossId])
        call SetWidgetLife(newUnit, GetUnitState(newUnit, UNIT_STATE_MAX_LIFE))
        call SetUnitState(newUnit, UNIT_STATE_MANA, GetUnitState(newUnit, UNIT_STATE_MAX_MANA))
        call SetUnitInvulnerable(newUnit, false)
        call PauseUnit(newUnit, false)
        set Boss_State[bossId] = BOSS_STATE_IDLE
        set Boss_Phase[bossId] = 0
        call Boss_RunEvent(bossId, BOSS_EVENT_RESPAWN, null, 0, 0)
        call Boss_Debug("Respawned " + Boss_Name[bossId] + ".")

        set oldUnit = null
        set ownerPlayer = null
        return newUnit
    endfunction

    private function Boss_OnUnitAttacked takes nothing returns nothing
        local unit attackedUnit = GetTriggerUnit()
        local unit attackingUnit = GetAttacker()
        local integer bossId = GetId(attackedUnit)

        if Boss_IsValidId(bossId) and Boss_AutoStartOnAttack[bossId] then
            call Start(bossId)
        endif
        set bossId = GetId(attackingUnit)
        if Boss_IsValidId(bossId) and Boss_AutoStartOnAttack[bossId] then
            call Start(bossId)
        endif
        set attackingUnit = null
        set attackedUnit = null
    endfunction

    private function Boss_OnLethalDamage takes nothing returns nothing
        local unit target = udg_DamageEventTarget
        local unit killer = udg_DamageEventSource
        local integer bossId = GetId(target)

        if Boss_IsValidId(bossId) and Boss_State[bossId] == BOSS_STATE_ACTIVE and Boss_DefeatMode[bossId] == BOSS_DEFEAT_MODE_SCRIPTED then
            set udg_LethalDamageHP = 1.00
            call Boss_DefeatInternal(bossId, killer)
        endif
        set target = null
        set killer = null
    endfunction

    private function Boss_OnUnitDeath takes nothing returns nothing
        local unit dyingUnit = UnitDeathEvent_GetDyingUnit()
        local unit killingUnit = UnitDeathEvent_GetKillingUnit()
        local integer bossId = GetId(dyingUnit)
        local integer phase

        if Boss_IsValidId(bossId) then
            set phase = Boss_Phase[bossId]
            if Boss_State[bossId] == BOSS_STATE_ACTIVE or Boss_State[bossId] == BOSS_STATE_IDLE then
                call Boss_DefeatInternal(bossId, killingUnit)
            endif
            call Boss_RunEvent(bossId, BOSS_EVENT_DEATH, killingUnit, phase, phase)
        endif
        set dyingUnit = null
        set killingUnit = null
    endfunction

    private function Boss_OnCombatAreaCheck takes nothing returns nothing
        local integer bossId = 1

        loop
            exitwhen bossId > Boss_Count
            if Boss_IsValidId(bossId) and Boss_State[bossId] == BOSS_STATE_ACTIVE and Boss_ResetWhenCombatAreaEmpty[bossId] and not Boss_CombatAreaHasResetPlayerUnit(bossId) then
                call Reset(bossId)
            endif
            set bossId = bossId + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        set Boss_UnitId = Table.create()
        set Boss_CombatAreaSearchGroup = CreateGroup()
        set Boss_FindGroup = CreateGroup()
        set Boss_CombatAreaCheckTimer = CreateTimer()
        call TimerStart(Boss_CombatAreaCheckTimer, BOSS_COMBAT_AREA_CHECK_INTERVAL, true, function Boss_OnCombatAreaCheck)
        call Events_RegisterUnitAttacked(function Boss_OnUnitAttacked)
        call UnitDeathEvent_Register(function Boss_OnUnitDeath)
        call RegisterDamageEngine(function Boss_OnLethalDamage, "Lethal", 1.00)
    endfunction
endlibrary
