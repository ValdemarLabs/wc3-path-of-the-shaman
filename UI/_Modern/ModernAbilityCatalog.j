/**
    ModernAbilityCatalog

    Author: Valdemar
    Version: 0.2.0

    Description:
    Classifies player shaman abilities for the modern action bar. The catalog
    separates presentation and targeting policy from the existing spellbook
    wrappers and from each ability's gameplay implementation.

    Credits:
    - Blizzard Entertainment, Warcraft III ability and frame APIs
    - Forgotten Hollow, compact action-bar presentation reference

    How to install:
    Import after AbilitiesPlayer. Import before ModernAbilityLoadout and
    ModernAbilityTargeting.

    API:
    - set kind = ModernAbilityCatalog_GetActionKind(abilityId)
    - set policy = ModernAbilityCatalog_GetTargetPolicy(abilityId)
    - set radius = ModernAbilityCatalog_GetAcquireRadius(abilityId)
    - set orderId = ModernAbilityCatalog_GetOrderId(abilityId)
    - set ready = ModernAbilityCatalog_IsRuntimeReady(abilityId)
    - set allowed = ModernAbilityCatalog_IsAssignable(abilityId)
    - set allowed = ModernAbilityCatalog_AllowsSelfFallback(abilityId)

**/
library ModernAbilityCatalog initializer Init requires AbilitiesPlayer

globals
    public constant integer ACTION_NONE = 0
    public constant integer ACTION_PASSIVE = 1
    public constant integer ACTION_IMMEDIATE = 2
    public constant integer ACTION_UNIT = 3
    public constant integer ACTION_POINT = 4
    public constant integer ACTION_SUBMENU = 5

    public constant integer TARGET_NONE = 0
    public constant integer TARGET_SELF = 1
    public constant integer TARGET_SOFT_HOSTILE = 2
    public constant integer TARGET_SOFT_FRIENDLY = 3
    public constant integer TARGET_MELEE_AUTO = 4
    public constant integer TARGET_APPROXIMATE_POINT = 5
    public constant integer TARGET_PRECISE_POINT = 6

    private constant real MAC_DEFAULT_SOFT_RADIUS = 180.00
    private constant real MAC_DEFAULT_MELEE_RADIUS = 250.00

    private integer array MAC_ActionKind
    private integer array MAC_TargetPolicy
    private real array MAC_AcquireRadius
    private boolean array MAC_SelfFallback
    private integer array MAC_OrderId
    private boolean array MAC_RuntimeReady
endglobals

private function MAC_Register takes integer abilityId, integer actionKind, integer targetPolicy, real acquireRadius, boolean selfFallback returns nothing
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return
    endif

    set MAC_ActionKind[entryIndex] = actionKind
    set MAC_TargetPolicy[entryIndex] = targetPolicy
    set MAC_AcquireRadius[entryIndex] = acquireRadius
    set MAC_SelfFallback[entryIndex] = selfFallback
endfunction

private function MAC_RegisterOrder takes integer abilityId, string orderString, boolean runtimeReady returns nothing
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return
    endif

    if orderString != null and orderString != "" then
        set MAC_OrderId[entryIndex] = OrderId(orderString)
    endif
    set MAC_RuntimeReady[entryIndex] = runtimeReady and MAC_OrderId[entryIndex] != 0
endfunction

private function MAC_RegisterElemental takes nothing returns nothing
    call MAC_Register('A6A0', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false) // Lightning Bolt
    call MAC_Register('A67H', ACTION_POINT, TARGET_APPROXIMATE_POINT, 0.00, false)              // Lightning Strike
    call MAC_Register('A67L', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false) // Chain Lightning
    call MAC_Register('A67J', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false) // Fire Shock
    call MAC_Register('A69L', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false) // Frost Shock
    call MAC_Register('A69N', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false) // Nature Shock
    call MAC_Register('A68H', ACTION_UNIT, TARGET_SELF, 0.00, true)                             // Lightning Shield
    call MAC_Register('A67Q', ACTION_SUBMENU, TARGET_NONE, 0.00, false)                         // Summon Elemental
endfunction

private function MAC_RegisterEnhancement takes nothing returns nothing
    call MAC_Register('A685', ACTION_IMMEDIATE, TARGET_MELEE_AUTO, MAC_DEFAULT_MELEE_RADIUS, false) // Stormstrike
    call MAC_Register('A6DP', ACTION_IMMEDIATE, TARGET_MELEE_AUTO, MAC_DEFAULT_MELEE_RADIUS, false) // Whirlwind
    call MAC_Register('A026', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false)     // Wind Shear
    call MAC_Register('A022', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false)     // Primal Force
    call MAC_Register('A67N', ACTION_IMMEDIATE, TARGET_NONE, 0.00, false)                            // Bloodlust
    call MAC_Register('A68Y', ACTION_IMMEDIATE, TARGET_SELF, 0.00, true)                             // Ghost Wolf
    call MAC_Register('A679', ACTION_IMMEDIATE, TARGET_NONE, 0.00, false)                            // Feral Spirits
    call MAC_Register('A673', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false)     // Hex
    call MAC_Register('A675', ACTION_UNIT, TARGET_SOFT_HOSTILE, MAC_DEFAULT_SOFT_RADIUS, false)     // Voodoo Curse
    call MAC_Register('A677', ACTION_IMMEDIATE, TARGET_NONE, 0.00, false)                            // Voodoo Spirits
endfunction

private function MAC_RegisterRestoration takes nothing returns nothing
    call MAC_Register('A66Y', ACTION_UNIT, TARGET_SOFT_FRIENDLY, MAC_DEFAULT_SOFT_RADIUS, true) // Healing Wave
    call MAC_Register('A672', ACTION_UNIT, TARGET_SOFT_FRIENDLY, MAC_DEFAULT_SOFT_RADIUS, true) // Chain Heal
    call MAC_Register('A66W', ACTION_IMMEDIATE, TARGET_NONE, 0.00, false)                       // Healing Rain
    call MAC_Register('A69W', ACTION_UNIT, TARGET_SOFT_FRIENDLY, MAC_DEFAULT_SOFT_RADIUS, true) // Rejuvenation
    call MAC_Register('A62Z', ACTION_UNIT, TARGET_SELF, 0.00, true)                             // Water Shield
    call MAC_Register('A01Z', ACTION_UNIT, TARGET_SOFT_FRIENDLY, MAC_DEFAULT_SOFT_RADIUS, true) // Spirit Link
    call MAC_Register('A6AL', ACTION_UNIT, TARGET_SOFT_FRIENDLY, MAC_DEFAULT_SOFT_RADIUS, true) // Ancestral Ward
    call MAC_Register('A638', ACTION_PASSIVE, TARGET_NONE, 0.00, false)                         // Spiritual Healing
    call MAC_Register('A69Y', ACTION_PASSIVE, TARGET_NONE, 0.00, false)                         // Totemic Resurgence
    call MAC_Register('A68A', ACTION_PASSIVE, TARGET_NONE, 0.00, false)                         // Reincarnation
endfunction

private function MAC_RegisterTotemic takes nothing returns nothing
    call MAC_Register('A63F', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Earth Totem
    call MAC_Register('A63G', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Fire Totem
    call MAC_Register('A63H', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Water Totem
    call MAC_Register('A63I', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Wind Totem
    call MAC_Register('A68J', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Stoneskin Totem
    call MAC_Register('A68L', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Earthbind Totem
    call MAC_Register('A68F', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Cleansing Totem
    call MAC_Register('A68T', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Windfury Totem
    call MAC_Register('A01U', ACTION_POINT, TARGET_PRECISE_POINT, 0.00, false) // Skyfury Totem
    call MAC_Register('A636', ACTION_PASSIVE, TARGET_NONE, 0.00, false)        // Totem Master
endfunction

private function MAC_RegisterOrders takes nothing returns nothing
    call MAC_RegisterOrder('A6A0', "firebolt", true)
    call MAC_RegisterOrder('A67H', "blizzard", true)
    call MAC_RegisterOrder('A67L', "chainlightning", true)
    call MAC_RegisterOrder('A67J', "firebolt", true)
    call MAC_RegisterOrder('A69L', "frostnova", true)
    call MAC_RegisterOrder('A69N', "thunderbolt", true)
    call MAC_RegisterOrder('A68H', "lightningshield", true)
    call MAC_RegisterOrder('A67Q', "", false)

    call MAC_RegisterOrder('A685', "summonbear", true)
    call MAC_RegisterOrder('A6DP', "whirlwind", true)
    call MAC_RegisterOrder('A026', "thunderbolt", true)
    call MAC_RegisterOrder('A022', "thunderbolt", true)
    call MAC_RegisterOrder('A67N', "berserk", true)
    call MAC_RegisterOrder('A68Y', "fanofknives", true)
    call MAC_RegisterOrder('A679', "spiritwolf", true)
    call MAC_RegisterOrder('A673', "hex", true)
    call MAC_RegisterOrder('A675', "acidbomb", true)
    call MAC_RegisterOrder('A677', "locustswarm", true)

    call MAC_RegisterOrder('A66Y', "holybolt", true)
    call MAC_RegisterOrder('A672', "healingwave", true)
    call MAC_RegisterOrder('A66W', "tranquility", true)
    call MAC_RegisterOrder('A69W', "rejuvination", true)
    call MAC_RegisterOrder('A62Z', "innerfire", true)
    call MAC_RegisterOrder('A01Z', "spiritlink", true)
    call MAC_RegisterOrder('A6AL', "innerfire", true)

    call MAC_RegisterOrder('A63F', "transmute", true)
    call MAC_RegisterOrder('A63G', "unavatar", true)
    call MAC_RegisterOrder('A63H', "unavengerform", true)
    call MAC_RegisterOrder('A63I', "unbearform", true)
    call MAC_RegisterOrder('A68J', "uncoldarrows", true)
    call MAC_RegisterOrder('A68L', "uncorporealform", true)
    call MAC_RegisterOrder('A68F', "unholyfrenzy", true)
    // The export disagrees between aord=undeadbuild and Ncl6=uncoldarrows.
    call MAC_RegisterOrder('A68T', "uncoldarrows", false)
    call MAC_RegisterOrder('A01U', "unburrow", true)
endfunction

public function GetActionKind takes integer abilityId returns integer
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return ACTION_NONE
    endif
    return MAC_ActionKind[entryIndex]
endfunction

public function GetTargetPolicy takes integer abilityId returns integer
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return TARGET_NONE
    endif
    return MAC_TargetPolicy[entryIndex]
endfunction

public function GetAcquireRadius takes integer abilityId returns real
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return 0.00
    endif
    return MAC_AcquireRadius[entryIndex]
endfunction

public function GetOrderId takes integer abilityId returns integer
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    if entryIndex == 0 then
        return 0
    endif
    return MAC_OrderId[entryIndex]
endfunction

public function IsRuntimeReady takes integer abilityId returns boolean
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    return entryIndex != 0 and MAC_RuntimeReady[entryIndex]
endfunction

public function AllowsSelfFallback takes integer abilityId returns boolean
    local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)

    return entryIndex != 0 and MAC_SelfFallback[entryIndex]
endfunction

public function IsAssignable takes integer abilityId returns boolean
    local integer actionKind = GetActionKind(abilityId)

    return actionKind == ACTION_IMMEDIATE or actionKind == ACTION_UNIT or actionKind == ACTION_POINT or actionKind == ACTION_SUBMENU
endfunction

private function Init takes nothing returns nothing
    call AbilitiesPlayer_EnsureInitialized()
    call MAC_RegisterElemental()
    call MAC_RegisterEnhancement()
    call MAC_RegisterRestoration()
    call MAC_RegisterTotemic()
    call MAC_RegisterOrders()
endfunction

endlibrary
