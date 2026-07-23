/**
    TalentsElemental

    Author: Valdemar
    Version:

    Description:
    Elemental shaman talent definitions for Talents.j.

    Credits:

    How to install:
    Import after Talents.j and AbilitiesPlayer.j.

    API:
    - call TalentsElemental_Register()

**/
library TalentsElemental requires Talents, AbilitiesPlayer
    private constant function TEL_Rows takes nothing returns integer
        return 8
    endfunction

    private constant function TEL_Columns takes nothing returns integer
        return 6
    endfunction

    public function Register takes nothing returns nothing
        call Talents_RegisterTreeDimensions(AbilitiesPlayer_TREE_ELEMENTAL, TEL_Rows(), TEL_Columns())
        call Talents_RegisterTalent(Talents_TALENT_ELEMENTAL_CONVECTION, AbilitiesPlayer_TREE_ELEMENTAL, 1, 1, 5, 0, 0, 0, 'A6A0', Talents_EFFECT_DAMAGE_PERCENT, 'A6A0', 4, "", "Convection", "Increases Lightning Bolt damage.")
        call Talents_RegisterTalent(Talents_TALENT_ELEMENTAL_SHOCK_MASTERY, AbilitiesPlayer_TREE_ELEMENTAL, 1, 3, 5, 0, 0, 0, 'A67J', Talents_EFFECT_DAMAGE_PERCENT, 'A67J', 3, "", "Shock Mastery", "Increases Fire Shock damage.")
        call Talents_RegisterTalent(Talents_TALENT_ELEMENTAL_STORM_FOCUS, AbilitiesPlayer_TREE_ELEMENTAL, 2, 1, 3, 5, Talents_TALENT_ELEMENTAL_CONVECTION, 3, 'A67H', Talents_EFFECT_COOLDOWN_PERCENT, 'A67H', 4, "", "Storm Focus", "Reduces Lightning Strike cooldown when scripts query this bonus.")
        call Talents_RegisterTalent(Talents_TALENT_ELEMENTAL_ELEMENTAL_PRECISION, AbilitiesPlayer_TREE_ELEMENTAL, 3, 1, 1, 10, Talents_TALENT_ELEMENTAL_STORM_FOCUS, 3, 'A6A3', Talents_EFFECT_SPECIAL, 'A67Q', 1, "", "Elemental Precision", "Unlock hook talent for stronger elemental follow-up effects.")
    endfunction
endlibrary
