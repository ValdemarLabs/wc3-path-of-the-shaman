/**
    TalentsTotemic

    Author: Valdemar
    Version:

    Description:
    Totemic shaman talent definitions for Talents.j.

    Credits:

    How to install:
    Import after Talents.j and AbilitiesPlayer.j.

    API:
    - call TalentsTotemic_Register()

**/
library TalentsTotemic requires Talents, AbilitiesPlayer
    private constant function TTO_Rows takes nothing returns integer
        return 8
    endfunction

    private constant function TTO_Columns takes nothing returns integer
        return 6
    endfunction

    public function Register takes nothing returns nothing
        call Talents_RegisterTreeDimensions(AbilitiesPlayer_TREE_TOTEMIC, TTO_Rows(), TTO_Columns())
        call Talents_RegisterTalent(Talents_TALENT_TOTEMIC_EARTHEN_RESONANCE, AbilitiesPlayer_TREE_TOTEMIC, 1, 1, 5, 0, 0, 0, 'A63F', Talents_EFFECT_SPECIAL, 'A63F', 1, "", "Earthen Resonance", "Enables earth totem scripts to scale their defensive effects by rank.")
        call Talents_RegisterTalent(Talents_TALENT_TOTEMIC_TOTEMIC_MIGHT, AbilitiesPlayer_TREE_TOTEMIC, 1, 3, 5, 0, 0, 0, 'A636', Talents_EFFECT_SPECIAL, 'A636', 1, "", "Totemic Might", "Enables general totem scripts to scale their bonuses by rank.")
        call Talents_RegisterTalent(Talents_TALENT_TOTEMIC_SKYFURY_FOCUS, AbilitiesPlayer_TREE_TOTEMIC, 2, 3, 3, 5, Talents_TALENT_TOTEMIC_TOTEMIC_MIGHT, 3, 'A01U', Talents_EFFECT_DAMAGE_PERCENT, 'A01U', 4, "", "Skyfury Focus", "Increases Skyfury Totem damage when scripts query this bonus.")
        call Talents_RegisterTalent(Talents_TALENT_TOTEMIC_TOTEMIC_HARMONY, AbilitiesPlayer_TREE_TOTEMIC, 3, 3, 1, 10, Talents_TALENT_TOTEMIC_SKYFURY_FOCUS, 3, 'A6A5', Talents_EFFECT_SPECIAL, 'A636', 1, "", "Totemic Harmony", "Unlock hook talent for Totemist capstone behavior.")
    endfunction
endlibrary
