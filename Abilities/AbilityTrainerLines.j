/**
    AbilityTrainerLines

    Author: Valdemar
    Version:

    Description:
    Registers generic dialogue lines and stable display names for the shaman
    ability trainer unit-types used by AbilityTrainerDialogs.

    Credits:

    How to install:
    Import after DialogSystem and AbilitiesPlayer.

    API:
    - set name = AbilityTrainerLines_GetTrainerNameByType(unitTypeId)
    - set name = AbilityTrainerLines_GetTrainerName(trainer)

**/
library AbilityTrainerLines initializer Init requires DialogSystem, AbilitiesPlayer
    public function GetTrainerNameByType takes integer unitTypeId returns string
        if unitTypeId == AbilitiesPlayer_TRAINER_TOTEMIC then
            return "Totem Master"
        elseif unitTypeId == AbilitiesPlayer_TRAINER_RESTORATION then
            return "Restoration Master"
        elseif unitTypeId == AbilitiesPlayer_TRAINER_ELEMENTAL then
            return "Elemental Master"
        elseif unitTypeId == AbilitiesPlayer_TRAINER_ENHANCEMENT then
            return "Enhancement Master"
        endif
        return "Ability Trainer"
    endfunction

    public function GetTrainerName takes unit trainer returns string
        if trainer == null then
            return "Ability Trainer"
        endif
        return GetTrainerNameByType(GetUnitTypeId(trainer))
    endfunction

    private function RegisterTotemic takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Totem Master", "The sky is quiet around you, young shaman. Listen, and the totems will answer.", "", true)
        call DialogSystem_RegisterGreetLine("Totem Master", "Walk softly. The spirits are already speaking.", "", true)
        call DialogSystem_RegisterGreetLine("Totem Master", "Your path touches earth, wind, fire, and water. Which voice do you seek?", "", true)
        call DialogSystem_RegisterGreetLine("Totem Master", "The astral winds bend near you. Stand still and hear them.", "", true)

        call DialogSystem_RegisterFarewellLine("Totem Master", "May your spirit drift true between earth and stars.", "", true)
        call DialogSystem_RegisterFarewellLine("Totem Master", "Carry the totems with patience, and they will carry you in turn.", "", true)
        call DialogSystem_RegisterFarewellLine("Totem Master", "Go with calm steps. The spirits remember.", "", true)
    endfunction

    private function RegisterRestoration takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Restoration Master", "Come, mon. Da waters know where ya wounds be.", "", true)
        call DialogSystem_RegisterGreetLine("Restoration Master", "Da spirits whisper of mending. You be ready ta listen?", "", true)
        call DialogSystem_RegisterGreetLine("Restoration Master", "Healing be more than soft hands, mon. It be strong spirit.", "", true)
        call DialogSystem_RegisterGreetLine("Restoration Master", "Sit close. Da old waters got lessons for ya.", "", true)

        call DialogSystem_RegisterFarewellLine("Restoration Master", "Go careful, mon. Keep ya blood warm and ya spirit warmer.", "", true)
        call DialogSystem_RegisterFarewellLine("Restoration Master", "Da waters remember ya name. Come back when ya need mending.", "", true)
        call DialogSystem_RegisterFarewellLine("Restoration Master", "Walk steady, mon. No wound be stronger than da spirits.", "", true)
    endfunction

    private function RegisterElemental takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Elemental Master", "Storms gather for those strong enough to call them.", "", true)
        call DialogSystem_RegisterGreetLine("Elemental Master", "The elements do not serve the weak. Speak your purpose.", "", true)
        call DialogSystem_RegisterGreetLine("Elemental Master", "Fire, frost, and thunder wait behind every breath. Choose carefully.", "", true)
        call DialogSystem_RegisterGreetLine("Elemental Master", "The storm is listening. Make your words worth its anger.", "", true)

        call DialogSystem_RegisterFarewellLine("Elemental Master", "May thunder answer when you call.", "", true)
        call DialogSystem_RegisterFarewellLine("Elemental Master", "Keep your will sharp. The elements test hesitation.", "", true)
        call DialogSystem_RegisterFarewellLine("Elemental Master", "Go. Let the storm know your name.", "", true)
    endfunction

    private function RegisterEnhancement takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Enhancement Master", "Grip your weapon. The spirits favor action.", "", true)
        call DialogSystem_RegisterGreetLine("Enhancement Master", "A shaman who cannot fight cannot guard the clan.", "", true)
        call DialogSystem_RegisterGreetLine("Enhancement Master", "Steel, claw, and spirit move together when the heart is ready.", "", true)
        call DialogSystem_RegisterGreetLine("Enhancement Master", "The battlefield teaches fast. I teach faster.", "", true)

        call DialogSystem_RegisterFarewellLine("Enhancement Master", "Strike hard, move faster, and let the spirits keep pace.", "", true)
        call DialogSystem_RegisterFarewellLine("Enhancement Master", "Return when your weapon asks for a stronger hand.", "", true)
        call DialogSystem_RegisterFarewellLine("Enhancement Master", "Do not waste the strength you asked the spirits to lend.", "", true)
    endfunction

    private function Init takes nothing returns nothing
        call RegisterTotemic()
        call RegisterRestoration()
        call RegisterElemental()
        call RegisterEnhancement()
    endfunction
endlibrary
