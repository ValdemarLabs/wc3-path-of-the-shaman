library AIHeroSystem version = "1.1"

// AI Hero System - vJASS
// Design: Event-driven primary model + lightweight shared pooled timer for non-critical periodic tasks (wander scheduling, camp checks, shop checks)
// Dependencies (optional adapters provided): Alloc, ListT, Table, TimerUtils, GCSM (Combat State Manager), UnitEvent, UnitIndexer, DamageEngine
// This file intentionally minimizes per-unit timers: we use one global pooled timer which processes a bounded number of AI heroes per tick.

// ======================
// CONFIGURATION
// ======================

globals
    hashtable AIH_Hasher = InitHashtable()
    integer AIH_RegisteredCount = 0
    AIHero array AIH_Registry = null // keyed by unit handle id (sparse)

    timer AIH_GlobalTimer = null
    real AIH_GlobalInterval = 0.50 // seconds per tick
    integer AIH_ProcessPerTick = 12 // how many heroes processed per global tick (bounded work)
    integer AIH_ProcessIndex = 0 // rotating index into registry processing

    constant real AIH_DEFAULT_WANDER_RADIUS = 600.0
    constant real AIH_DEFAULT_LOW_HP_PCT = 0.35
    constant real AIH_DEFAULT_CRITICAL_HP_PCT = 0.12
    constant real AIH_WANDER_INTERVAL_MIN = 3.0
    constant real AIH_WANDER_INTERVAL_MAX = 6.0

    // Hero classes
    constant integer AIH_CLASS_WARLOCK = 0
    constant integer AIH_CLASS_RESTOSHAMAN = 1
    constant integer AIH_CLASS_WARRIOR = 2
    constant integer AIH_CLASS_ROGUE = 3
    constant integer AIH_CLASS_PALADIN = 4
    constant integer AIH_CLASS_ENGINEER = 5

    // Feature flags
    constant integer AIH_FEATURE_WANDER = 1
    constant integer AIH_FEATURE_COMBAT = 2
    constant integer AIH_FEATURE_RETREAT = 4
    constant integer AIH_FEATURE_ITEMS = 8
    constant integer AIH_FEATURE_TRAVEL = 16

endglobals

// ======================
// AIHero struct
// ======================

struct AIHero
    unit u
    integer owner
    integer featureFlags
    integer classId

    real wanderRadius
    real lowHpPct
    real criticalHpPct

    real nextWanderAt // game time when next wander should trigger
    boolean wantWander

    boolean isRetreating
    location retreatPoint
    integer state // 0 idle,1 combat,2 retreat,3 camping

    // casting/bookkeeping
    real castReadyAt
    boolean isCasting

    // bookkeeping
    integer handleId

    static AIHero array AITable

    static method AIHero create(unit who, integer classId)
        local AIHero h = AIHero.allocate()
        set h.u = who
        set h.handleId = GetHandleId(who)
        set h.owner = GetUnitOwner(who)
        set h.classId = classId
        set h.featureFlags = AIH_FEATURE_WANDER | AIH_FEATURE_COMBAT | AIH_FEATURE_RETREAT | AIH_FEATURE_ITEMS
        set h.wanderRadius = AIH_DEFAULT_WANDER_RADIUS
        set h.lowHpPct = AIH_DEFAULT_LOW_HP_PCT
        set h.criticalHpPct = AIH_DEFAULT_CRITICAL_HP_PCT
        set h.isRetreating = false
        set h.state = 0
        set h.nextWanderAt = 0.0
        set h.wantWander = true
        set h.castReadyAt = 0.0
        set h.isCasting = false
        set AITable[h.handleId] = h
        return h
    endmethod

    static method AIHero get(unit who)
        return AITable[GetHandleId(who)]
    endmethod

    static method AIHero getById(integer hid)
        return AITable[hid]
    endmethod

    static method AIHero remove(unit who)
        local integer hid = GetHandleId(who)
        local AIHero h = AITable[hid]
        if h != null then
            call AIHero.cleanup(h)
            set AITable[hid] = null
            set AIH_RegisteredCount = AIH_RegisteredCount - 1
        endif
    endmethod

    static method AIHero cleanup(AIHero h)
        if h == null then return
        if h.retreatPoint != null then
            call RemoveLocation(h.retreatPoint)
            set h.retreatPoint = null
        endif
        // other resource cleanup if needed
    endmethod

    // lightweight allocator wrapper (so struct allocations remain centralized)
    static method AIHero allocate takes nothing returns AIHero
        local AIHero temp
        set temp = AIHero.alloc() // vJASS struct allocation
        return temp
    endmethod

endstruct

// initialize static arrays
private function AIH_EnsureRegistry takes nothing returns nothing
    if AIHero.AITable == null then
        set AIHero.AITable = AIHero array 131072 // generous sparse table keyed by handle id
    endif
endfunction

// ======================
// UTIL
// ======================

private function RandRealRange takes real a, real b returns real
    return a + (b - a) * GetRandomReal(0.0, 1.0)
endfunction

private function GameTimeNow takes nothing returns real
    return GetGameTime()
endfunction

// ======================
// PUBLIC API
// ======================

function AIH_SystemInit takes nothing returns nothing
    call AIH_EnsureRegistry()
    if AIH_GlobalTimer == null then
        set AIH_GlobalTimer = CreateTimer()
        call TimerStart(AIH_GlobalTimer, AIH_GlobalInterval, true, function AIH_GlobalTick)
    endif

    // register common global events: unit death to cleanup, unit create if you want auto-registers
    // Use UnitEvent library if you have it. Fallback generic register examples left as comments.
    // call UnitEvent_RegisterUnitDeathHandler(function AIH_OnUnitDeath)
    // call UnitEvent_RegisterUnitCreateHandler(function AIH_OnUnitCreated)

    // Wire DamageEngine global callback registration if available
    // call DamageEngine_RegisterGlobalDamageCallback(function AIH_DamageGlobalCallback)
endfunction

function AIH_RegisterHero takes unit who, integer classId returns nothing
    local AIHero h
    if who == null then return
    endif
    call AIH_EnsureRegistry()
    set h = AIHero.get(who)
    if h != null then
        // already registered: update class if needed
        set h.classId = classId
        return
    endif
    set h = AIHero.create(who, classId)
    set AIH_Registry[AIH_RegisteredCount] = h
    set AIH_RegisteredCount = AIH_RegisteredCount + 1

    // Register per-hero event hooks (damage, orders) using DamageEngine & UnitEvent
    call AIH_AttachDamageHook(h)
    call AIH_AttachOrderHook(h)

    // schedule first wander quickly
    set h.nextWanderAt = GameTimeNow() + RandRealRange(AIH_WANDER_INTERVAL_MIN, AIH_WANDER_INTERVAL_MAX)
endfunction

function AIH_UnregisterHero takes unit who returns nothing
    local AIHero h = AIHero.get(who)
    if h == null then return
    endif
    call AIHero.remove(who)
    // remove from registry array (simple linear remove)
    local integer i = 0
    loop
        exitwhen i >= AIH_RegisteredCount
        if AIH_Registry[i] == h then
            // move last into i
            set AIH_Registry[i] = AIH_Registry[AIH_RegisteredCount - 1]
            set AIH_Registry[AIH_RegisteredCount - 1] = null
            set AIH_RegisteredCount = AIH_RegisteredCount - 1
            break
        endif
        set i = i + 1
    endloop
endfunction

function AIH_EnableFeature takes unit who, integer feature, boolean enable returns nothing
    local AIHero h = AIHero.get(who)
    if h == null then return
    endif
    if enable then
        set h.featureFlags = h.featureFlags | feature
    else
        set h.featureFlags = h.featureFlags & (~feature)
    endif
endfunction

// ======================
// Global tick: batched processing
// Processes up to AIH_ProcessPerTick heroes per global tick to handle wander decisions & light checks
// ======================

private function AIH_GlobalTick takes nothing returns nothing
    local integer processed = 0
    local integer startIndex = AIH_ProcessIndex
    if AIH_RegisteredCount == 0 then return
    endif

    while processed < AIH_ProcessPerTick and AIH_RegisteredCount > 0
        set AIH_ProcessIndex = (AIH_ProcessIndex + 1) % AIH_RegisteredCount
        set processed = processed + 1
        local AIHero h = AIH_Registry[AIH_ProcessIndex]
        if h == null or h.u == null or not UnitAlive(h.u) then
            // cleanup nulls: remove
            call AIH_UnregisterHero(h.u)
            cycle
        endif

        // Skip if in combat or retreating
        if h.state == 0 and (h.featureFlags & AIH_FEATURE_WANDER) != 0 and h.wantWander then
            if GameTimeNow() >= h.nextWanderAt then
                call AIH_PerformWander(h)
                set h.nextWanderAt = GameTimeNow() + RandRealRange(AIH_WANDER_INTERVAL_MIN, AIH_WANDER_INTERVAL_MAX)
            endif
        endif

        // lightweight health checks (only if retreat feature enabled)
        if (h.featureFlags & AIH_FEATURE_RETREAT) != 0 then
            call AIH_CheckHealthForRetreat(h)
        endif

    endloop
endfunction

// ======================
// Wander implementation (issues move orders)
// ======================

private function AIH_PerformWander takes AIHero h returns nothing
    if h == null or h.u == null then return
    endif
    // don't wander if in combat (double-check using GCSM if available)
    if (h.featureFlags & AIH_FEATURE_COMBAT) != 0 then
        // if GCSM library exists, try to use it (adapter): if UnitInCombat(h.u) then return
        // We'll use a safe adapter call: AIH_UnitInCombat(h.u)
        if AIH_UnitInCombat(h.u) then
            return
        endif
    endif

    if h.isRetreating then return
    endif

    local real tx = GetUnitX(h.u) + GetRandomReal(-h.wanderRadius, h.wanderRadius)
    local real ty = GetUnitY(h.u) + GetRandomReal(-h.wanderRadius, h.wanderRadius)
    call IssuePointOrder(h.u, "move", tx, ty)
endfunction

// ======================
// Health/retreat checks
// ======================

private function AIH_CheckHealthForRetreat takes AIHero h returns nothing
    if h == null or h.u == null then return
    endif
    local real hp = GetUnitState(h.u, UNIT_STATE_LIFE)
    local real maxhp = GetUnitState(h.u, UNIT_STATE_MAX_LIFE)
    local real pct = 1.0
    if maxhp > 0.0 then set pct = hp / maxhp
    endif

    if pct <= h.criticalHpPct then
        if not h.isRetreating then
            set h.state = 2
            call AIH_ForceRetreat(h, true)
        endif
    elseif pct <= h.lowHpPct then
        if not h.isRetreating then
            set h.state = 2
            call AIH_ForceRetreat(h, false)
        endif
    endif
endfunction

private function AIH_ForceRetreat takes AIHero h, boolean extreme returns nothing
    if h == null or h.u == null then return
    endif
    // determine safe point - prefer unit indexer home location if present
    // Adapter stub: if UnitIndexer has home location for owner, use it
    local real tx = GetStartLocationX(h.owner)
    local real ty = GetStartLocationY(h.owner)
    if h.retreatPoint != null then
        call RemoveLocation(h.retreatPoint)
        set h.retreatPoint = null
    endif
    set h.retreatPoint = Location(tx, ty)
    set h.isRetreating = true
    call IssuePointOrder(h.u, "move", tx, ty)

    // if extreme, try to use travel/hearth integration (adapter point)
    if extreme then
        // e.g., call TravelSystem_RequestTeleport(h.u)
    endif
endfunction

function AIH_OnReachRetreatPoint takes unit who returns nothing
    local AIHero h = AIHero.get(who)
    if h == null then return
    endif
    // health recovered? simple check
    local real hp = GetUnitState(h.u, UNIT_STATE_LIFE)
    local real maxhp = GetUnitState(h.u, UNIT_STATE_MAX_LIFE)
    if maxhp > 0.0 and hp / maxhp > h.lowHpPct then
        set h.isRetreating = false
        set h.state = 0
        if h.retreatPoint != null then
            call RemoveLocation(h.retreatPoint)
            set h.retreatPoint = null
        endif
    endif
endfunction

// ======================
// Damage / Order hooks
// Adapter points: wire these to DamageEngine & UnitEvent implementations
// ======================

private function AIH_AttachDamageHook takes AIHero h returns nothing
    // Example expected: DamageEngine_RegisterUnitDamageCallback(unit, function callback)
    // We'll use a generic global DamageEngine register if you have it: DamageEngine_RegisterOnTakeDamage(function AIH_DamageCallback)
    // For now: leave as stub to be wired by map author
endfunction

private function AIH_AttachOrderHook takes AIHero h returns nothing
    // Use UnitEvent or UnitOrder library to capture orders. For example: register for EVENT_UNIT_ISSUED_ORDER
    // On relevant orders (shop, use item, cast ability), call AIH_HandleOrder(h, orderId, target)
endfunction

// Global damage callback expected signature: function AIH_DamageGlobalCallback(unit victim, unit attacker, real damage)
function AIH_DamageGlobalCallback takes unit victim, unit attacker, real damage returns nothing
    local AIHero h = AIHero.get(victim)
    if h == null then return
    endif
    // On damage, update state and maybe enter combat
    // If Combat State Manager (GCSM) exists prefer it, otherwise quick heuristic: set state=1
    set h.state = 1

    // Check retreat immediately
    call AIH_CheckHealthForRetreat(h)

    // class-specific reactions (interrupt, cast shield, flee, etc.)
    call AIH_HandleDamageReaction(h, attacker, damage)
endfunction

private function AIH_HandleDamageReaction takes AIHero h, unit attacker, real damage returns nothing
    if h == null then return
    endif
    // dispatch by class for quick reactive abilities
    if h.classId == AIH_CLASS_WARLOCK then
        // warlock: maybe cast fear or escape when low hp
        call AIH_Class_Warlock_OnDamage(h, attacker, damage)
    elseif h.classId == AIH_CLASS_RESTOSHAMAN then
        call AIH_Class_RestoShaman_OnDamage(h, attacker, damage)
    elseif h.classId == AIH_CLASS_WARRIOR then
        call AIH_Class_Warrior_OnDamage(h, attacker, damage)
    elseif h.classId == AIH_CLASS_ROGUE then
        call AIH_Class_Rogue_OnDamage(h, attacker, damage)
    elseif h.classId == AIH_CLASS_PALADIN then
        call AIH_Class_Paladin_OnDamage(h, attacker, damage)
    elseif h.classId == AIH_CLASS_ENGINEER then
        call AIH_Class_Engineer_OnDamage(h, attacker, damage)
    endif
endfunction

// ======================
// Class-specific skeletons (implement ability logic here)
// Keep these lightweight and event-driven: do small checks, then issue orders or call ability engine
// ======================

private function AIH_Class_Warlock_OnDamage takes AIHero h, unit attacker, real damage returns nothing
    if h == null then return
    endif
    // immediate defensive reaction
    if GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE) < 0.25 then
        // try to cast escape spell (adapter)
        call AIH_ForceCastByName(h.u, "Fear")
        // set a short cooldown so we don't spam
        set h.castReadyAt = GameTimeNow() + 3.00
        return
    endif

    // Otherwise attempt normal ability logic if ready
    call AIH_Class_Warlock_TryAbilities(h)
endfunction

// Warlock behavior: translated from GUI triggers into vJASS
private integer AIH_Warlock_FilterOwner = 0

private function AIH_Warlock_EnemyFilter takes unit u returns boolean
    // filter used with GroupEnumUnitsInRange; checks alive and enemy of provided owner
    if u == null then return false
    endif
    if not IsUnitAliveBJ(u) then return false
    endif
    if IsUnitEnemy(u, Player(AIH_Warlock_FilterOwner)) == false then return false
    endif
    return true
endfunction

private function AIH_Class_Warlock_TryAbilities takes AIHero h returns nothing
    if h == null or h.u == null then return
    endif

    // respect casting cooldown
    if GameTimeNow() < h.castReadyAt then return
    endif

    // 1) try consumables if below thresholds or any charged consumable exists
    if AIH_Warlock_TryUseConsumable(h) then
        set h.castReadyAt = GameTimeNow() + 0.5
        return
    endif

    // 2) Summon imp if none exists (uses custom indexing - map author must set CustomValue on pet unit)
    if AIH_Warlock_TrySummonImp(h) then
        set h.castReadyAt = GameTimeNow() + 3.00
        return
    endif

    // 3) Life Tap logic: if mana <=75% and hp >=30% and random chance
    if (GetUnitState(h.u, UNIT_STATE_MANA) / GetUnitState(h.u, UNIT_STATE_MAX_MANA)) <= 0.75 and (GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE)) >= 0.30 and I2R(GetRandomInt(1,2)) == 1 and GameTimeNow() >= h.castReadyAt then
        // add ability then cast (GUI added ability and removed it after)
        call UnitAddAbility(h.u, 'A000') // placeholder rawcode for LifeTap ability; replace with actual
        call IssueImmediateOrder(h.u, "Orc Troll Berserker - Berserk")
        set h.castReadyAt = GameTimeNow() + 2.00
        // schedule removal of added ability via TimerUtils or simple delayed trigger if desired
        return
    endif

    // 4) Offensive spells - find enemies in range
    local group g = CreateGroup()
    set AIH_Warlock_FilterOwner = h.owner
    call GroupEnumUnitsInRange(g, GetUnitX(h.u), GetUnitY(h.u), 600.00, function AIH_Warlock_EnemyFilter)

    if CountUnitsInGroup(g) > 0 then
        local unit target = FirstOfGroup(g)
        // Randomly pick between Shadowbolt (Firebolt) and Curse of Agony (Parasite)
        if GetRandomInt(1,2) == 1 then
            call IssueTargetOrder(h.u, "Neutral - Firebolt", target)
            set h.castReadyAt = GameTimeNow() + 2.00
        else
            call IssueTargetOrder(h.u, "Neutral - Parasite", target)
            set h.castReadyAt = GameTimeNow() + 1.00
        endif

        // Additional conditional casts
        if (GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE)) <= 0.75 and GetRandomInt(1,3) == 1 then
            call IssueTargetOrder(h.u, "Neutral Dark Ranger - Life Drain", target)
            set h.castReadyAt = GameTimeNow() + 5.00
        endif

        if CountUnitsInGroup(g) > 2 and GetRandomInt(1,3) == 1 then
            call IssueTargetOrder(h.u, "Undead Dreadlord - Sleep", target)
            set h.castReadyAt = GameTimeNow() + 2.00
        endif

        if CountUnitsInGroup(g) > 2 and GetRandomInt(1,5) == 1 then
            // Rain of Fire on random target position
            local real tx = GetUnitX(target)
            local real ty = GetUnitY(target)
            call IssuePointOrder(h.u, "Neutral Pit Lord - Rain Of Fire", tx, ty)
            set h.castReadyAt = GameTimeNow() + 6.00
        endif

        if CountUnitsInGroup(g) > 2 and GetRandomInt(1,4) == 1 then
            call IssueTargetOrder(h.u, "Human Blood Mage - Banish", target)
            set h.castReadyAt = GameTimeNow() + 3.00
        endif

    endif

    call DestroyGroup(g)
endfunction

private function AIH_Warlock_TryUseConsumable takes AIHero h returns boolean
    if h == null then return false
    endif
    // iterate inventory slots 0..5 and try to use first charged item
    local integer i = 0
    loop
        exitwhen i >= 6
        local item it = UnitItemInSlot(h.u, i)
        if it != null then
            // simplistic check: if item has charges or is consumable - map author should expand this
            if GetItemCharge(it) > 0 then
                // attempt to use item via immediate order (map-specific)
                call IssueImmediateOrder(h.u, "use-item")
                return true
            endif
        endif
        set i = i + 1
    endloop
    return false
endfunction

private function AIH_Warlock_TrySummonImp takes AIHero h returns boolean
    if h == null then return false
    endif
    // Check custom value or unit indexer if the imp is alive - adapter stub
    // For now, always attempt summon if random and not currently casting
    if GetRandomInt(1,2) == 1 then
        call IssueImmediateOrder(h.u, "Orc Far Seer - Feral Spirit")
        return true
    endif
    return false
endfunction

private function AIH_Class_RestoShaman_OnDamage takes AIHero h, unit attacker, real damage returns nothing
    // Example: cast heal on self or totems when in combat
    if h == null then return
    endif
    if AIH_UnitHasSpellReady(h.u, "Chain Heal") then
        call AIH_ForceCastByName(h.u, "Chain Heal")
    endif
endfunction

private function AIH_Class_Warrior_OnDamage takes AIHero h, unit attacker, real damage returns nothing
    // Example: shield or rage; if very low, try to retreat
    if h == null then return
    endif
    if GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE) < 0.18 then
        call AIH_ForceCastByName(h.u, "Charge")
    endif
endfunction

private function AIH_Class_Rogue_OnDamage takes AIHero h, unit attacker, real damage returns nothing
    // Example: stealth / vanish on high threat
    if h == null then return
    endif
    if GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE) < 0.30 then
        call AIH_ForceCastByName(h.u, "Vanish")
    endif
endfunction

private function AIH_Class_Paladin_OnDamage takes AIHero h, unit attacker, real damage returns nothing
    if h == null then return
    endif
    if AIH_UnitHasSpellReady(h.u, "Divine Shield") and GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE) < 0.20 then
        call AIH_ForceCastByName(h.u, "Divine Shield")
    endif
endfunction

private function AIH_Class_Engineer_OnDamage takes AIHero h, unit attacker, real damage returns nothing
    if h == null then return
    endif
    // Example: deploy turret or use wrench ability
    if AIH_UnitHasSpellReady(h.u, "Deploy Turret") then
        call AIH_ForceCastByName(h.u, "Deploy Turret")
    endif
endfunction

// ======================
// Small helpers for forcing casts (string-based adapter)
// In many maps abilities have raw order strings or ids; adapt as needed.
// ======================

private function AIH_ForceCastByName takes unit who, string spellName returns boolean
    if who == null then return false
    endif
    // This is a naive implementation using IssueImmediateOrder with the spell name as order string.
    // For robust behavior, map spellName to raw-order codes or use ability ids with custom order issuing.
    call IssueImmediateOrder(who, spellName)
    return true
endfunction

private function AIH_UnitHasSpellReady takes unit who, string spellName returns boolean
    // Adapter stub: check cooldowns and mana using UnitIndexer or ability state
    // Fallback: always return true (map author should override)
    return true
endfunction

// ======================
// Utility: adapter for Combat State Manager (GCSM)
// If you have GCSM, map function name here for a faster in-combat check
// ======================

private function AIH_UnitInCombat takes unit who returns boolean
    // Default: use GCSM if available. Leave as false-if-unknown to avoid blocking behavior.
    // If GCSM provides: return GCSM_UnitInCombat(who)
    return false
endfunction

// ======================
// Cleanup and map hooks
// ======================

function AIH_OnUnitDeath takes unit who returns nothing
    call AIH_UnregisterHero(who)
endfunction

// ======================
// End of library
// ======================


//////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
/////////////////////////////////
// WORK IN PROGRESS 
library AIHeroSystem endlib

    library AIHeroSystem initializer Init requires UnitIndexer, Table, TimerUtils, DamageEngine, UnitEvent

    globals
        private constant real TICK_INTERVAL = 0.25 // pooled timer interval

        private constant integer AIH_STATE_IDLE     = 0
        private constant integer AIH_STATE_WANDER   = 1
        private constant integer AIH_STATE_COMBAT   = 2
        private constant integer AIH_STATE_RETREATC = 3
        private constant integer AIH_STATE_RETREATB = 4
        private constant integer AIH_STATE_ASSIST   = 5

        private timer ai_timer
        private real   ai_now
    endglobals

    struct AIHero
        unit u
        integer state
        real stateUntil
        real castReadyAt
        integer classId // 0 = warlock, others later

        boolean enableWander
        boolean enableCombat
        boolean enableRetreat

        AIHero next
        AIHero prev
        static AIHero head = 0

        method disable takes nothing returns nothing
            call this.deallocate()
        endmethod

        static method create takes unit who, integer classId returns AIHero
            local AIHero h = AIHero.allocate()
            set h.u = who
            set h.state = AIH_STATE_IDLE
            set h.stateUntil = 0.
            set h.castReadyAt = 0.
            set h.classId = classId
            set h.enableWander = true
            set h.enableCombat = true
            set h.enableRetreat = true
            set h.next = AIHero.head
            if AIHero.head != 0 then
                set AIHero.head.prev = h
            endif
            set AIHero.head = h
            set h.prev = 0
            return h
        endmethod
    endstruct

    // =======================
    // STATE MACHINE
    // =======================

    private function AIH_DetermineState takes AIHero h returns integer
        local real hp = GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE)
        local integer order = GetUnitCurrentOrder(h.u)

        if (hp < 0.10 and h.enableRetreat) then
            return AIH_STATE_RETREATB
        elseif (hp < 0.25 and h.enableRetreat) then
            return AIH_STATE_RETREATC
        elseif (h.enableCombat and h.castReadyAt <= ai_now and order != OrderId("spell") and order != OrderId("cast")) then
            return AIH_STATE_COMBAT
        elseif (h.enableWander and hp >= 0.25 and GetRandomInt(1,10) == 1) then
            return AIH_STATE_WANDER
        else
            return AIH_STATE_IDLE
        endif
    endfunction

    private function AIH_RunState takes AIHero h returns nothing
        if h.classId == 0 then
            if h.state == AIH_STATE_COMBAT then
                call AIH_Class_Warlock_TryAbilities(h)
            elseif h.state == AIH_STATE_WANDER then
                call AIH_Class_Warlock_Wander(h)
            elseif h.state == AIH_STATE_RETREATC then
                call AIH_Class_Warlock_RetreatCombat(h)
            elseif h.state == AIH_STATE_RETREATB then
                call AIH_Class_Warlock_RetreatBase(h)
            elseif h.state == AIH_STATE_IDLE then
                call AIH_Class_Warlock_Idle(h)
            endif
        endif
    endfunction

    private function AIH_Tick takes nothing returns nothing
        local AIHero h = AIHero.head
        local integer newState
        set ai_now = TimerGetElapsed(ai_timer)
        loop
            exitwhen h == 0
            if IsUnitAliveBJ(h.u) then
                set newState = AIH_DetermineState(h)
                if newState != h.state then
                    set h.state = newState
                    set h.stateUntil = ai_now + 1.0
                endif
                call AIH_RunState(h)
            else
                call h.disable()
            endif
            set h = h.next
        endloop
    endfunction

    // =======================
    // WARLOCK IMPLEMENTATION
    // =======================

    private function AIH_Class_Warlock_TryAbilities takes AIHero h returns nothing
    local real now = ai_now
    if h == null or h.u == null then return
    endif

    // respect casting cooldown
    if now < h.castReadyAt then return
    endif

    // 1) Try consumables first (if low or any charged consumable present)
    if AIH_Warlock_TryUseConsumable(h) then
        set h.castReadyAt = now + 0.50
        return
    endif

    // 2) Summon Imp if none exists (adapter for UnitIndexer/custom value recommended)
    if AIH_Warlock_TrySummonImp(h) then
        set h.castReadyAt = now + 3.00
        return
    endif

    // 3) Life Tap branch: mana <=75% and life >=30% with chance
    local real manaPct = 1.0
    local real lifePct = 1.0
    if GetUnitState(h.u, UNIT_STATE_MAX_MANA) > 0.0 then
        set manaPct = GetUnitState(h.u, UNIT_STATE_MANA) / GetUnitState(h.u, UNIT_STATE_MAX_MANA)
    endif
    if GetUnitState(h.u, UNIT_STATE_MAX_LIFE) > 0.0 then
        set lifePct = GetUnitState(h.u, UNIT_STATE_LIFE) / GetUnitState(h.u, UNIT_STATE_MAX_LIFE)
    endif

    if manaPct <= 0.75 and lifePct >= 0.30 and GetRandomInt(1,2) == 1 then
        // NOTE: replace 'A000' with your real LifeTap ability rawcode and order string
        call UnitAddAbility(h.u, 'A000')
        call IssueImmediateOrder(h.u, "Orc Troll Berserker - Berserk")
        set h.castReadyAt = now + 2.00
        // schedule ability removal via TimerUtils or external cleaner if needed
        return
    endif

    // 4) Offensive spells: pick target group in 600 range
    local unit target = AIH_SelectRandomEnemyInRange(h, 600.00)
    if target == null then return
    endif

    // Randomly decide spell usage following your GUI probabilities
    local integer pick = GetRandomInt(1,100)

    if pick <= 40 then
        // SHADOWBOLT (Firebolt)
        call IssueTargetOrder(h.u, "Neutral - Firebolt", target)
        set h.castReadyAt = now + 2.00
        return
    elseif pick <= 70 then
        // CURSE OF AGONY (Parasite)
        call IssueTargetOrder(h.u, "Neutral - Parasite", target)
        set h.castReadyAt = now + 1.00
        return
    elseif pick <= 80 and lifePct <= 0.75 then
        // LIFE DRAIN
        call IssueTargetOrder(h.u, "Neutral Dark Ranger - Life Drain", target)
        set h.castReadyAt = now + 5.00
        return
    elseif pick <= 90 and AIH_CountEnemiesAround(target, 300) > 2 then
        // FEAR
        call IssueTargetOrder(h.u, "Undead Dreadlord - Sleep", target)
        set h.castReadyAt = now + 2.00
        return
    elseif pick <= 95 and AIH_CountEnemiesAround(target, 300) > 2 then
        // RAIN OF FIRE on target position
        call IssuePointOrder(h.u, "Neutral Pit Lord - Rain Of Fire", GetUnitX(target), GetUnitY(target))
        set h.castReadyAt = now + 6.00
        return
    else
        // BANISH
        call IssueTargetOrder(h.u, "Human Blood Mage - Banish", target)
        set h.castReadyAt = now + 3.00
        return
    endif
endfunction

// -------------------------
// Warlock helpers
// -------------------------

private function AIH_SelectRandomEnemyInRange takes AIHero h, real range returns unit
    if h == null or h.u == null then return null
    endif
    local group g = CreateGroup()
    local unit picked = null
    local integer cnt = 0
    local integer i = 1
    local unit utemp

    // filter: alive and enemy of hero owner
    call GroupEnumUnitsInRange(g, GetUnitX(h.u), GetUnitY(h.u), range, function AIH_Warlock_EnemyFilter)
    set cnt = CountUnitsInGroup(g)
    if cnt == 0 then
        call DestroyGroup(g)
        return null
    endif

    local integer r = GetRandomInt(1, cnt)
    loop
        exitwhen CountUnitsInGroup(g) == 0
        set utemp = FirstOfGroup(g)
        call GroupRemoveUnit(g, utemp)
        if i == r then
            set picked = utemp
            exitwhen true
        endif
        set i = i + 1
    endloop

    // cleanup remaining
    call DestroyGroup(g)
    return picked
endfunction

private function AIH_Warlock_TryUseConsumable takes AIHero h returns boolean
    if h == null or h.u == null then return false
    endif
    local integer slot = 0
    local item it
    loop
        exitwhen slot >= 6
        set it = UnitItemInSlot(h.u, slot)
        if it != null then
            if GetItemCharge(it) > 0 then
                // ISSUE: replace "use-item" with exact order string for item use if needed
                call IssueImmediateOrder(h.u, "use-item")
                return true
            endif
        endif
        set slot = slot + 1
    endloop
    return false
endfunction

private function AIH_Warlock_TrySummonImp takes AIHero h returns boolean
    if h == null or h.u == null then return false
    endif
    // adapter: use UnitIndexer or custom value to check if imp exists. Fallback random attempt
    if GetRandomInt(1,2) == 1 then
        call IssueImmediateOrder(h.u, "Orc Far Seer - Feral Spirit")
        return true
    endif
    return false
endfunction

private function AIH_CountEnemiesAround takes unit who, real radius returns integer
    local group g = CreateGroup()
    local integer res = 0
    call GroupEnumUnitsInRange(g, GetUnitX(who), GetUnitY(who), radius, Condition(function (takes unit u returns boolean) return IsUnitEnemy(u, GetOwningPlayer(who)) end))
    set res = CountUnitsInGroup(g)
    call DestroyGroup(g)
    return res
endfunction

    private function AIH_Class_Warlock_Wander takes AIHero h returns nothing
        local real x = GetUnitX(h.u) + GetRandomReal(-600,600)
        local real y = GetUnitY(h.u) + GetRandomReal(-600,600)
        call IssuePointOrder(h.u, "move", x, y)
    endfunction

    private function AIH_Class_Warlock_RetreatCombat takes AIHero h returns nothing
        // move away from nearest enemy, or to safe point
        call IssuePointOrder(h.u, "move", GetStartLocationX(0), GetStartLocationY(0))
    endfunction

    private function AIH_Class_Warlock_RetreatBase takes AIHero h returns nothing
        call IssuePointOrder(h.u, "move", GetStartLocationX(0), GetStartLocationY(0))
    endfunction

    private function AIH_Class_Warlock_Idle takes AIHero h returns nothing
        // reset flags, set idle timer
    endfunction

    // =======================
    // INIT
    // =======================

    private function Periodic takes nothing returns nothing
        call AIH_Tick()
    endfunction

    private function Init takes nothing returns nothing
        set ai_timer = NewTimer()
        call TimerStart(ai_timer, TICK_INTERVAL, true, function Periodic)
    endfunction

endlibrary

