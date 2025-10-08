library Reputation initializer InitReputations requires Table

globals
    private constant integer MAX_FACTIONS = 11
    private constant integer REP_MIN = -20000
    private constant integer REP_MAX =  20000
    private constant integer REP_NEUTRAL = 0
    private constant integer REP_FRIENDLY = 3000
    private constant integer REP_HOSTILE = -6000

    private constant real BOARD_UPDATE_INTERVAL = 1.50
    private constant real RELATION_UPDATE_INTERVAL = 5.00

    private Table REP_KILL_DELTA = Table.create()
    private trigger tKillListener
    private Table prevStates
endglobals

struct Faction
    string name
    integer id
    Table linked
    Table weights
    player p
    integer nextIndex

    static Table byName
    static Faction array all
    static integer total = 1

    static method create takes string name, player owner returns thistype
        local thistype this = allocate()
        set this.name = name
        set this.p = owner
        set this.linked = Table.create()
        set this.weights = Table.create()
        set this.nextIndex = 0
        set byName.string[ StringHash(name) ] = I2S(this)
        set this.id = total
        set all[total] = this
        set total = total + 1
        return this
    endmethod

    method link takes Faction other, real factor returns nothing
        local integer i = 0
        loop
            exitwhen i >= this.nextIndex
            if this.linked[i] == other then
                set this.weights.real[other.id] = factor
                return
            endif
            set i = i + 1
        endloop
        set this.linked[this.nextIndex] = other
        set this.weights.real[other.id] = factor
        set this.nextIndex = this.nextIndex + 1
    endmethod

    static method get takes string name returns Faction
        local string idStr = byName.string[ StringHash(name) ]
        if idStr != "" then
            return Faction(S2I(idStr))
        endif
        return null
    endmethod

    static method getByPlayer takes player p returns Faction
        local integer i = 1
        if all == null then
            return null
        endif
        loop
            exitwhen i >= total
            if all[i] != null and all[i].p == p then
                return all[i]
            endif
            set i = i + 1
        endloop
        return null
    endmethod

    static method onInit takes nothing returns nothing
        set byName = Table.create()
        set all = array(MAX_FACTIONS, null)
    endmethod
endstruct

struct Reputation
    static Table rep

    static method getRep takes player p, Faction f returns integer
        return rep[GetPlayerId(p) * MAX_FACTIONS + f.id]
    endmethod

    static method setRep takes player p, Faction f, integer value returns nothing
        if value > REP_MAX then
            set value = REP_MAX
        elseif value < REP_MIN then
            set value = REP_MIN
        endif
        set rep[GetPlayerId(p) * MAX_FACTIONS + f.id] = value
    endmethod

    static method addRaw takes player p, Faction f, integer delta returns nothing
        local integer newVal
        if udg_InCinematic then
            return
        endif
        set newVal = .getRep(p, f) + delta
        call .setRep(p, f, newVal)
        if delta > 0 then
            call DisplayTextToPlayer(p, 0, 0, "|cff80a0ff" + f.name + "|r reputation +" + I2S(delta))
        else
            call DisplayTextToPlayer(p, 0, 0, "|cff80a0ff" + f.name + "|r reputation " + I2S(delta))
        endif
    endmethod

    static method addLinked takes player p, Faction f, integer delta returns nothing
        local integer i = 0
        local Faction other
        call .addRaw(p, f, delta)
        if delta != 0 then
            loop
                exitwhen i >= f.nextIndex
                set other = f.linked[i]
                if other != null then
                    call .addRaw(p, other, R2I(delta * f.weights.real[other.id]))
                endif
                set i = i + 1
            endloop
        endif
    endmethod

    static method getStatus takes player p, Faction f returns string
        local integer val = .getRep(p, f)
        if val <= REP_HOSTILE then
            return "|cffff4040Hostile|r"
        elseif val < REP_FRIENDLY then
            return "|cffc0c0c0Neutral|r"
        else
            return "|cff40ff40Friendly|r"
        endif
    endmethod

    static method OnUnitKilled takes unit killer, unit victim returns nothing
        local player pKiller = GetOwningPlayer(killer)
        local Faction fVictim = Faction.getByPlayer(GetOwningPlayer(victim))
        local integer delta
        if fVictim == null then 
            return 
        endif
        if REP_KILL_DELTA.has(fVictim.id) then
            set delta = R2I(REP_KILL_DELTA.real[fVictim.id])
        else
            set delta = 0
        endif
        if delta != 0 then
            call .addLinked(pKiller, fVictim, delta)
        endif
    endmethod

    static method onInit takes nothing returns nothing
        set rep = Table.create()
    endmethod
endstruct

struct ReputationBoard
    static multiboard array boards
    static timer updater

    static method show takes player p, boolean flag returns nothing
        local integer pid = GetPlayerId(p)
        if boards[pid] == null then
            call .createBoard(p)
        endif
        call MultiboardDisplay(udg_Multiboard, not flag)
        call MultiboardDisplay(boards[pid], flag)
    endmethod

    static method createBoard takes player p returns nothing
        local multiboard mb = CreateMultiboard()
        local integer rows = Faction.total + 1
        local integer i = 0
        local Faction f
        local string value

        call MultiboardSetTitleText(mb, "Reputation Overview")
        call MultiboardSetRowCount(mb, rows)
        call MultiboardSetColumnCount(mb, 2)

        call MultiboardSetItemValue(MultiboardGetItem(mb, 0, 0), "Faction")
        call MultiboardSetItemValue(MultiboardGetItem(mb, 0, 1), "Status")

        loop
            exitwhen i >= Faction.total
            set f = Faction.all[i]
            if f != null then
                call MultiboardSetItemValue(MultiboardGetItem(mb, i + 1, 0), f.name)
                set value = Reputation.getStatus(p, f) + " (" + I2S(Reputation.getRep(p, f)) + ")"
                call MultiboardSetItemValue(MultiboardGetItem(mb, i + 1, 1), value)
            endif
            set i = i + 1
        endloop

        set boards[GetPlayerId(p)] = mb
        call MultiboardDisplay(mb, false)
    endmethod

    static method update takes nothing returns nothing
        local player p = Player(0)
        local Faction f
        local multiboard mb
        local integer row
        local string value

        if udg_InCinematic then
            return
        endif

        set mb = boards[GetPlayerId(p)]
        if mb != null then
            set row = 1
            loop
                exitwhen row > Faction.total
                set f = Faction.all[row - 1]
                if f != null then
                    set value = Reputation.getStatus(p, f) + " (" + I2S(Reputation.getRep(p, f)) + ")"
                    call MultiboardSetItemValue(MultiboardGetItem(mb, row, 1), value)
                endif
                set row = row + 1
            endloop
        endif
    endmethod

    static method onInit takes nothing returns nothing
        set updater = CreateTimer()
        call TimerStart(updater, BOARD_UPDATE_INTERVAL, true, function thistype.update)
    endmethod
endstruct

function UpdateFactionAlliances takes nothing returns nothing
    local integer i = 0
    local player mainPlayer = Player(0)
    local player otherPlayer
    local Faction f
    local integer rep
    local string newStatus
    local string oldStatus
    local integer key

    if prevStates == null then
        set prevStates = Table.create()
    endif

    loop
        exitwhen i >= Faction.total
        set f = Faction.all[i]
        if f != null and f.p != null then
            set otherPlayer = f.p
            set rep = Reputation.getRep(mainPlayer, f)

            if rep <= REP_HOSTILE then
                set newStatus = "Hostile"
            elseif rep < REP_FRIENDLY then
                set newStatus = "Neutral"
            else
                set newStatus = "Friendly"
            endif

            set key = f.id
            set oldStatus = prevStates.string[key]

            if oldStatus != newStatus then
                if newStatus == "Hostile" then
                    call SetPlayerAllianceStateBJ(mainPlayer, otherPlayer, bj_ALLIANCE_UNALLIED)
                    call SetPlayerAllianceStateBJ(otherPlayer, mainPlayer, bj_ALLIANCE_UNALLIED)
                    call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffff4040You are now Hostile toward " + f.name + "!|r")
                elseif newStatus == "Neutral" then
                    call SetPlayerAllianceStateBJ(mainPlayer, otherPlayer, bj_ALLIANCE_NEUTRAL)
                    call SetPlayerAllianceStateBJ(otherPlayer, mainPlayer, bj_ALLIANCE_NEUTRAL)
                    call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffc0c0c0You are now Neutral with " + f.name + ".|r")
                elseif newStatus == "Friendly" then
                    call SetPlayerAllianceStateBJ(mainPlayer, otherPlayer, bj_ALLIANCE_ALLIED)
                    call SetPlayerAllianceStateBJ(otherPlayer, mainPlayer, bj_ALLIANCE_ALLIED)
                    call DisplayTextToPlayer(mainPlayer, 0, 0, "|cff40ff40You are now Friendly with " + f.name + "!|r")
                endif

                set prevStates.string[key] = newStatus
            endif
        endif
        set i = i + 1
    endloop
endfunction

private function OnUnitDeathHandler takes nothing returns nothing
    local unit killer = GetKillingUnit()
    local unit victim = GetDyingUnit()
    call Reputation.OnUnitKilled(killer, victim)
endfunction

function InitReputations takes nothing returns nothing
    local player p = Player(0)
    local Faction horde        = Faction.create("Horde", Player(5))
    local Faction satyr        = Faction.create("Satyr", Player(12))
    local Faction riverbane    = Faction.create("Riverbane", Player(14))
    local Faction alliance     = Faction.create("Alliance", Player(8))
    local Faction felorcs      = Faction.create("Felorcs", Player(3))
    local Faction undead       = Faction.create("Undead", Player(20))
    local Faction goblins      = Faction.create("Goblins", Player(13))
    local Faction elarindor    = Faction.create("Elarindor", Player(15))
    local Faction bonecrushers = Faction.create("Bonecrushers", Player(10))
    local Faction realhorde    = Faction.create("RealHorde", Player(7))
    local Faction humancitizen = Faction.create("HumanCitizen", Player(2))

    set tKillListener = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(tKillListener, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(tKillListener, function OnUnitDeathHandler)

    call Faction.onInit()
    call Reputation.onInit()
    call ReputationBoard.onInit()

    call horde.link(alliance, -1.0)
    call alliance.link(horde, -1.0)
    call horde.link(felorcs, -0.5)
    call horde.link(satyr, -0.25)

    set REP_KILL_DELTA[ Faction.get("Horde").id ] = 100
    set REP_KILL_DELTA[ Faction.get("Satyr").id ] = -200
    set REP_KILL_DELTA[ Faction.get("Riverbane").id ] = 50
    set REP_KILL_DELTA[ Faction.get("Alliance").id ] = -200
    set REP_KILL_DELTA[ Faction.get("Felorcs").id ] = -200
    set REP_KILL_DELTA[ Faction.get("Undead").id ] = -100
    set REP_KILL_DELTA[ Faction.get("Goblins").id ] = 100
    set REP_KILL_DELTA[ Faction.get("Elarindor").id ] = 50
    set REP_KILL_DELTA[ Faction.get("Bonecrushers").id ] = -100
    set REP_KILL_DELTA[ Faction.get("RealHorde").id ] = 100
    set REP_KILL_DELTA[ Faction.get("HumanCitizen").id ] = 50

    call Reputation.setRep(p, horde, 0)
    call Reputation.setRep(p, satyr, 0)
    call Reputation.setRep(p, riverbane, 0)
    call Reputation.setRep(p, alliance, -20000)
    call Reputation.setRep(p, felorcs, -20000)
    call Reputation.setRep(p, undead, -20000)
    call Reputation.setRep(p, goblins, 0)
    call Reputation.setRep(p, elarindor, 0)
    call Reputation.setRep(p, bonecrushers, 0)
    call Reputation.setRep(p, realhorde, 0)
    call Reputation.setRep(p, humancitizen, 0)

    call TimerStart(CreateTimer(), RELATION_UPDATE_INTERVAL, true, function UpdateFactionAlliances)
endfunction

endlibrary
