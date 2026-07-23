/**
    TalentsEnhancement

    Author: Valdemar
    Version:

    Description:
    Enhancement shaman talent definitions for Talents.j.

    Credits:

    How to install:
    Import after Talents.j and AbilitiesPlayer.j.

    API:
    - call TalentsEnhancement_Register()

**/
library TalentsEnhancement requires Talents, AbilitiesPlayer
    private constant function TEN_Rows takes nothing returns integer
        return 8
    endfunction

    private constant function TEN_Columns takes nothing returns integer
        return 6
    endfunction

    public function Register takes nothing returns nothing
        call Talents_RegisterTreeDimensions(AbilitiesPlayer_TREE_ENHANCEMENT, TEN_Rows(), TEN_Columns())
        call Talents_RegisterTalent(Talents_TALENT_ENHANCEMENT_WEAPON_MASTERY, AbilitiesPlayer_TREE_ENHANCEMENT, 1, 1, 5, 0, 0, 0, 'A685', Talents_EFFECT_DAMAGE_PERCENT, 'A685', 4, "", "Weapon Mastery", "Increases Stormstrike damage.")
        call Talents_RegisterTalent(Talents_TALENT_ENHANCEMENT_PRIMAL_MOMENTUM, AbilitiesPlayer_TREE_ENHANCEMENT, 1, 3, 5, 0, 0, 0, 'A6DP', Talents_EFFECT_DAMAGE_PERCENT, 'A6DP', 3, "", "Primal Momentum", "Increases Whirlwind damage.")
        call Talents_RegisterTalent(Talents_TALENT_ENHANCEMENT_FERAL_BOND, AbilitiesPlayer_TREE_ENHANCEMENT, 2, 1, 3, 5, Talents_TALENT_ENHANCEMENT_WEAPON_MASTERY, 3, 'A679', Talents_EFFECT_SPECIAL, 'A679', 1, "", "Feral Bond", "Enables Feral Spirits scripts to scale companion effects by rank.")
        call Talents_RegisterTalent(Talents_TALENT_ENHANCEMENT_SPIRIT_FURY, AbilitiesPlayer_TREE_ENHANCEMENT, 3, 1, 1, 10, Talents_TALENT_ENHANCEMENT_FERAL_BOND, 3, 'A6A4', Talents_EFFECT_SPECIAL, 'A677', 1, "", "Spirit Fury", "Unlock hook talent for stronger spirit and voodoo effects.")
    endfunction
endlibrary
