/**
    TalentsRestoration

    Author: Valdemar
    Version:

    Description:
    Restoration shaman talent definitions for Talents.j.

    Credits:

    How to install:
    Import after Talents.j and AbilitiesPlayer.j.

    API:
    - call TalentsRestoration_Register()

**/
library TalentsRestoration requires Talents, AbilitiesPlayer
    private constant function TRS_Rows takes nothing returns integer
        return 8
    endfunction

    private constant function TRS_Columns takes nothing returns integer
        return 6
    endfunction

    public function Register takes nothing returns nothing
        call Talents_RegisterTreeDimensions(AbilitiesPlayer_TREE_RESTORATION, TRS_Rows(), TRS_Columns())
        call Talents_RegisterTalent(Talents_TALENT_RESTORATION_TIDAL_FOCUS, AbilitiesPlayer_TREE_RESTORATION, 1, 1, 5, 0, 0, 0, 'A66Y', Talents_EFFECT_HEAL_PERCENT, 'A66Y', 4, "", "Tidal Focus", "Increases Healing Wave healing.")
        call Talents_RegisterTalent(Talents_TALENT_RESTORATION_MENDING_RAIN, AbilitiesPlayer_TREE_RESTORATION, 1, 3, 5, 0, 0, 0, 'A66W', Talents_EFFECT_HEAL_PERCENT, 'A66W', 3, "", "Mending Rain", "Increases Healing Rain healing.")
        call Talents_RegisterTalent(Talents_TALENT_RESTORATION_ANCESTRAL_GRACE, AbilitiesPlayer_TREE_RESTORATION, 2, 1, 3, 5, Talents_TALENT_RESTORATION_TIDAL_FOCUS, 3, 'A6AL', Talents_EFFECT_SPECIAL, 'A6AL', 1, "", "Ancestral Grace", "Enables Ancestral Ward scripts to add stronger protective effects.")
        call Talents_RegisterTalent(Talents_TALENT_RESTORATION_SPIRIT_FLOW, AbilitiesPlayer_TREE_RESTORATION, 3, 1, 1, 10, Talents_TALENT_RESTORATION_ANCESTRAL_GRACE, 3, 'A6A2', Talents_EFFECT_SPECIAL, 'A01Z', 1, "", "Spirit Flow", "Unlock hook talent for Spirit Link and Spiritmender synergy.")
    endfunction
endlibrary
