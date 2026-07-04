/**
    PetDefinitions

    Author: Valdemar
    Credits:
    - Consolidates pet unit, meat, class, role, ability, and stat-profile data
      that was previously split between Pet and UnitExperience.
    Version:

    Description:
    Central data library for pet/tameable beast definitions. Pet gameplay,
    unit experience scaling, and pet UI panels should read pet type data here
    instead of duplicating rawcodes and classification rules.

    How to install:
    Import this library before Pet, UnitExperience, and UI systems that display
    pet metadata.

    API:
    call PetDefinitions_IsPetType(integer unitTypeId) returns boolean
    call PetDefinitions_IsTameableType(integer unitTypeId) returns boolean
    call PetDefinitions_IsRawMeat(integer itemTypeId) returns boolean
    call PetDefinitions_GetClassText(integer unitTypeId) returns string
    call PetDefinitions_GetRoleText(integer unitTypeId) returns string
    call PetDefinitions_GetAbilityInfoText(integer unitTypeId) returns string
    call PetDefinitions_IsTankStatType(integer unitTypeId) returns boolean
    call PetDefinitions_IsDamageStatType(integer unitTypeId) returns boolean
    call PetDefinitions_IsBalancedStatType(integer unitTypeId) returns boolean
    call PetDefinitions_IsBruiserStatType(integer unitTypeId) returns boolean
    call PetDefinitions_GetAbilityDefinitionKey(integer unitTypeId) returns integer
    call PetDefinitions_GetTrainingTitle(integer definitionKey) returns string
    call PetDefinitions_GetTrainingBody(integer definitionKey) returns string

**/
library PetDefinitions

globals
    public constant integer ABILITY_DEF_WOLF = 910201
    public constant integer ABILITY_DEF_BEAR = 910202
    public constant integer ABILITY_DEF_FELINE = 910203
    public constant integer ABILITY_DEF_TURTLE = 910204
    public constant integer ABILITY_DEF_STAG = 910205
    public constant integer ABILITY_DEF_BOAR = 910206
    public constant integer ABILITY_DEF_MOTH = 910207
    public constant integer ABILITY_DEF_GENERIC = 910299

    private constant integer UNIT_SHADOWCLAW = 'n655'
    private constant integer UNIT_PIG_5 = 'n63C'
    private constant integer UNIT_PIG_10 = 'n63U'
    private constant integer UNIT_TIMBER_WOLF = 'nwlt'
    private constant integer UNIT_GIANT_WOLF = 'nwlg'
    private constant integer UNIT_DIRE_WOLF = 'nwld'
    private constant integer UNIT_STAG_1 = 'nder'
    private constant integer UNIT_STAG_5 = 'n63A'
    private constant integer UNIT_STAG_10 = 'n63B'
    private constant integer UNIT_BEAR_CUB = 'ngz1'
    private constant integer UNIT_BEAR = 'ngz2'
    private constant integer UNIT_MOTHER_BEAR = 'ngz4'
    private constant integer UNIT_FEROCIOUS_BEAR = 'ngza'
    private constant integer UNIT_PANTHER_CUB = 'n61O'
    private constant integer UNIT_PANTHER_10 = 'n016'
    private constant integer UNIT_PANTHER_15 = 'n015'
    private constant integer UNIT_TIGER_2 = 'n61P'
    private constant integer UNIT_TIGER_10 = 'n017'
    private constant integer UNIT_TIGER_15 = 'n018'
    private constant integer UNIT_SEA_TURTLE_10 = 'n01F'
    private constant integer UNIT_GIANT_SEA_TURTLE_15 = 'n01G'
    private constant integer UNIT_GIANT_MOTH_12 = 'n00V'
    private constant integer UNIT_LYNX_5 = 'n63M'

    private constant integer UNIT_GIANT_SEA_TURTLE = 'nrtg'
    private constant integer UNIT_GARGANTUAN_SEA_TURTLE = 'ntrt'
    private constant integer UNIT_SEA_TURTLE = 'ntrs'
    private constant integer UNIT_SEA_TURTLE_HATCHLING = 'ntrh'

    private constant integer ITEM_RAW_WOLF = 'I61O'
    private constant integer ITEM_RAW_STAG = 'I61P'
    private constant integer ITEM_RAW_BEAR = 'I61Q'
    private constant integer ITEM_RAW_LIZARD = 'I61R'
    private constant integer ITEM_RAW_HAWK = 'I61S'
    private constant integer ITEM_RAW_MURLOC = 'I61T'
    private constant integer ITEM_RAW_TURTLE = 'I61U'
    private constant integer ITEM_RAW_TIGER = 'I61V'
    private constant integer ITEM_RAW_PANTHER = 'I61W'
    private constant integer ITEM_RAW_RAPTOR = 'I61X'
    private constant integer ITEM_RAW_SNAKE = 'I61Y'
    private constant integer ITEM_RAW_MAKRURA = 'I61Z'
    private constant integer ITEM_RAW_BOAR = 'I620'
    private constant integer ITEM_RAW_CRAWLER = 'I621'
    private constant integer ITEM_RAW_RABBIT = 'I622'
    private constant integer ITEM_RAW_COW = 'I623'
endglobals

public function IsShadowclawType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_SHADOWCLAW
endfunction

public function IsWolfType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_SHADOWCLAW or unitTypeId == UNIT_TIMBER_WOLF or unitTypeId == UNIT_GIANT_WOLF or unitTypeId == UNIT_DIRE_WOLF
endfunction

public function IsBearType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_BEAR_CUB or unitTypeId == UNIT_BEAR or unitTypeId == UNIT_MOTHER_BEAR or unitTypeId == UNIT_FEROCIOUS_BEAR
endfunction

public function IsFelineType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_PANTHER_CUB or unitTypeId == UNIT_PANTHER_10 or unitTypeId == UNIT_PANTHER_15 or unitTypeId == UNIT_TIGER_2 or unitTypeId == UNIT_TIGER_10 or unitTypeId == UNIT_TIGER_15 or unitTypeId == UNIT_LYNX_5
endfunction

public function IsTurtleType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_SEA_TURTLE_10 or unitTypeId == UNIT_GIANT_SEA_TURTLE_15 or unitTypeId == UNIT_GIANT_SEA_TURTLE or unitTypeId == UNIT_GARGANTUAN_SEA_TURTLE or unitTypeId == UNIT_SEA_TURTLE or unitTypeId == UNIT_SEA_TURTLE_HATCHLING
endfunction

public function IsStagType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_STAG_1 or unitTypeId == UNIT_STAG_5 or unitTypeId == UNIT_STAG_10
endfunction

public function IsBoarType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_PIG_5 or unitTypeId == UNIT_PIG_10
endfunction

public function IsMothType takes integer unitTypeId returns boolean
    return unitTypeId == UNIT_GIANT_MOTH_12
endfunction

public function IsTameableType takes integer unitTypeId returns boolean
    return IsBoarType(unitTypeId) or unitTypeId == UNIT_TIMBER_WOLF or unitTypeId == UNIT_GIANT_WOLF or unitTypeId == UNIT_DIRE_WOLF or IsStagType(unitTypeId) or IsBearType(unitTypeId) or IsFelineType(unitTypeId) or unitTypeId == UNIT_SEA_TURTLE_10 or unitTypeId == UNIT_GIANT_SEA_TURTLE_15 or IsMothType(unitTypeId)
endfunction

public function IsPetType takes integer unitTypeId returns boolean
    return IsShadowclawType(unitTypeId) or IsTameableType(unitTypeId)
endfunction

public function IsRawMeat takes integer itemTypeId returns boolean
    return itemTypeId == ITEM_RAW_WOLF or itemTypeId == ITEM_RAW_STAG or itemTypeId == ITEM_RAW_BEAR or itemTypeId == ITEM_RAW_LIZARD or itemTypeId == ITEM_RAW_HAWK or itemTypeId == ITEM_RAW_MURLOC or itemTypeId == ITEM_RAW_TURTLE or itemTypeId == ITEM_RAW_TIGER or itemTypeId == ITEM_RAW_PANTHER or itemTypeId == ITEM_RAW_RAPTOR or itemTypeId == ITEM_RAW_SNAKE or itemTypeId == ITEM_RAW_MAKRURA or itemTypeId == ITEM_RAW_BOAR or itemTypeId == ITEM_RAW_CRAWLER or itemTypeId == ITEM_RAW_RABBIT or itemTypeId == ITEM_RAW_COW
endfunction

public function GetClassText takes integer unitTypeId returns string
    if IsWolfType(unitTypeId) then
        return "Wolf"
    elseif IsBearType(unitTypeId) then
        return "Bear"
    elseif unitTypeId == UNIT_LYNX_5 then
        return "Lynx"
    elseif unitTypeId == UNIT_TIGER_2 or unitTypeId == UNIT_TIGER_10 or unitTypeId == UNIT_TIGER_15 then
        return "Tiger"
    elseif IsFelineType(unitTypeId) then
        return "Panther"
    elseif IsTurtleType(unitTypeId) then
        return "Turtle"
    elseif IsStagType(unitTypeId) then
        return "Stag"
    elseif IsBoarType(unitTypeId) then
        return "Boar"
    elseif IsMothType(unitTypeId) then
        return "Moth"
    endif

    return "Tamed Beast"
endfunction

public function GetRoleText takes integer unitTypeId returns string
    if IsTurtleType(unitTypeId) then
        return "Tank"
    elseif IsBearType(unitTypeId) then
        return "Bruiser"
    elseif IsFelineType(unitTypeId) then
        return "Melee Damage"
    elseif IsWolfType(unitTypeId) then
        return "Balanced Beast"
    elseif IsMothType(unitTypeId) then
        return "Support"
    endif

    return "Utility Beast"
endfunction

public function GetAbilityInfoText takes integer unitTypeId returns string
    if IsWolfType(unitTypeId) then
        return "Balanced pet scaling, pet inventory, persistent pet fatigue/revive"
    elseif IsBearType(unitTypeId) then
        return "Bruiser pet scaling, pet inventory, persistent pet fatigue/revive"
    elseif IsFelineType(unitTypeId) then
        return "Damage pet scaling, pet inventory, persistent pet fatigue/revive"
    elseif IsTurtleType(unitTypeId) then
        return "Tank pet scaling, pet inventory, persistent pet fatigue/revive"
    elseif IsMothType(unitTypeId) then
        return "Support pet scaling, pet inventory, persistent pet fatigue/revive"
    endif

    return "Tamed beast abilities, pet inventory, persistent pet fatigue/revive"
endfunction

public function IsTankStatType takes integer unitTypeId returns boolean
    return IsTurtleType(unitTypeId)
endfunction

public function IsDamageStatType takes integer unitTypeId returns boolean
    return IsFelineType(unitTypeId)
endfunction

public function IsBalancedStatType takes integer unitTypeId returns boolean
    return IsWolfType(unitTypeId)
endfunction

public function IsBruiserStatType takes integer unitTypeId returns boolean
    return IsBearType(unitTypeId)
endfunction

public function GetAbilityDefinitionKey takes integer unitTypeId returns integer
    if IsWolfType(unitTypeId) then
        return ABILITY_DEF_WOLF
    elseif IsBearType(unitTypeId) then
        return ABILITY_DEF_BEAR
    elseif IsFelineType(unitTypeId) then
        return ABILITY_DEF_FELINE
    elseif IsTurtleType(unitTypeId) then
        return ABILITY_DEF_TURTLE
    elseif IsStagType(unitTypeId) then
        return ABILITY_DEF_STAG
    elseif IsBoarType(unitTypeId) then
        return ABILITY_DEF_BOAR
    elseif IsMothType(unitTypeId) then
        return ABILITY_DEF_MOTH
    elseif IsPetType(unitTypeId) then
        return ABILITY_DEF_GENERIC
    endif

    return 0
endfunction

public function GetTrainingTitle takes integer definitionKey returns string
    if definitionKey == ABILITY_DEF_WOLF then
        return "Wolf Training"
    elseif definitionKey == ABILITY_DEF_BEAR then
        return "Bear Training"
    elseif definitionKey == ABILITY_DEF_FELINE then
        return "Feline Training"
    elseif definitionKey == ABILITY_DEF_TURTLE then
        return "Turtle Training"
    elseif definitionKey == ABILITY_DEF_STAG then
        return "Stag Training"
    elseif definitionKey == ABILITY_DEF_BOAR then
        return "Boar Training"
    elseif definitionKey == ABILITY_DEF_MOTH then
        return "Moth Training"
    endif

    return "Beast Training"
endfunction

public function GetTrainingBody takes integer definitionKey returns string
    if definitionKey == ABILITY_DEF_WOLF then
        return "Balanced beast growth with steady life, armor, damage, dodge, and hit gains."
    elseif definitionKey == ABILITY_DEF_BEAR then
        return "Bruiser beast growth with strong life and damage gains and moderate defensive growth."
    elseif definitionKey == ABILITY_DEF_FELINE then
        return "Damage beast growth with stronger damage, critical strike, and hit gains."
    elseif definitionKey == ABILITY_DEF_TURTLE then
        return "Tank beast growth with stronger life, armor, block, and dodge gains."
    elseif definitionKey == ABILITY_DEF_STAG then
        return "Utility beast growth for a mobile companion with general pet scaling."
    elseif definitionKey == ABILITY_DEF_BOAR then
        return "Utility beast growth for a sturdy companion with general pet scaling."
    elseif definitionKey == ABILITY_DEF_MOTH then
        return "Support beast growth for a companion with general pet scaling."
    endif

    return "General tamed beast growth through the pet experience system."
endfunction

endlibrary
