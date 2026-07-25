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
        call DialogSystem_RegisterGreetLine("Totem Master", "The sky is quiet around you, young shaman. Stay awhile and listen.", "TrainerTotemic_0001", true)
        call DialogSystem_RegisterGreetLine("Totem Master", "Walk softly. We don't want to anger the spirits near the totems.", "TrainerTotemic_0002", true)
        call DialogSystem_RegisterGreetLine("Totem Master", "Totems are all that you need, young one.", "TrainerTotemic_0003", true)
        call DialogSystem_RegisterGreetLine("Totem Master", "Remember, we can only have one totem of each elemental aspects placed on the ground.", "TrainerTotemic_0004", true)

        call DialogSystem_RegisterFarewellLine("Totem Master", "May the spirits guide you.", "TrainerTotemic_0005", true)
        call DialogSystem_RegisterFarewellLine("Totem Master", "You are always most welcome to come back.", "TrainerTotemic_0006", true)
        call DialogSystem_RegisterFarewellLine("Totem Master", "Farewell for now, young shaman.", "TrainerTotemic_0007", true)
    endfunction

    private function RegisterRestoration takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Restoration Master", "Greetings, mon. Ya be ready for training?", "TrainerRestoration_0001", true)
        call DialogSystem_RegisterGreetLine("Restoration Master", "Da spirits whisper of mending. You be ready ta listen?", "TrainerRestoration_0002", true)
        call DialogSystem_RegisterGreetLine("Restoration Master", "There be more to healing than ya know.", "TrainerRestoration_0003", true)
        call DialogSystem_RegisterGreetLine("Restoration Master", "Da old troll got lessons for ya.", "TrainerRestoration_0004", true)

        call DialogSystem_RegisterFarewellLine("Restoration Master", "Go careful, mon... and be the spirits with ya.", "TrainerRestoration_0005", true)
        call DialogSystem_RegisterFarewellLine("Restoration Master", "Remember da old troll's lessons.", "TrainerRestoration_0006", true)
        call DialogSystem_RegisterFarewellLine("Restoration Master", "Farewell, young one.", "TrainerRestoration_0007", true)
    endfunction

    private function RegisterElemental takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Elemental Master", "Storms gather for those strong enough to call them.", "TrainerElemental_0001", true)
        call DialogSystem_RegisterGreetLine("Elemental Master", "The elements do not serve the weak. Speak your purpose.", "TrainerElemental_0002", true)
        call DialogSystem_RegisterGreetLine("Elemental Master", "Fire, frost, and thunder... choose carefully.", "TrainerElemental_0003", true)
        call DialogSystem_RegisterGreetLine("Elemental Master", "The storms are listening.", "TrainerElemental_0004", true)

        call DialogSystem_RegisterFarewellLine("Elemental Master", "May thunder answer when you call.", "TrainerElemental_0005", true)
        call DialogSystem_RegisterFarewellLine("Elemental Master", "Keep your will sharp. The elements shall test your hesitation.", "TrainerElemental_0006", true)
        call DialogSystem_RegisterFarewellLine("Elemental Master", "Go. Let the storm know your name.", "TrainerElemental_0007", true)
    endfunction

    private function RegisterEnhancement takes nothing returns nothing
        call DialogSystem_RegisterGreetLine("Enhancement Master", "Grip your weapon. The spirits favor action.", "TrainerEnhancement_0001", true)
        call DialogSystem_RegisterGreetLine("Enhancement Master", " A shaman must imbue their weapons.", "TrainerEnhancement_0002", true)
        call DialogSystem_RegisterGreetLine("Enhancement Master", "Young wolves must prove their worthiness.", "TrainerEnhancement_0003", true)
        call DialogSystem_RegisterGreetLine("Enhancement Master", "The whirlwind combined with stormstrike is a powerful combo.", "TrainerEnhancement_0004", true)

        call DialogSystem_RegisterFarewellLine("Enhancement Master", "Strike hard, move faster, and don't fall over.", "TrainerEnhancement_0005", true)
        call DialogSystem_RegisterFarewellLine("Enhancement Master", "It was foretold that you will return.", "TrainerEnhancement_0006", true)
        call DialogSystem_RegisterFarewellLine("Enhancement Master", "Do not waste the strength you asked the spirits to lend.", "TrainerEnhancement_0007", true)
    endfunction

    private function Init takes nothing returns nothing
        call RegisterTotemic()
        call RegisterRestoration()
        call RegisterElemental()
        call RegisterEnhancement()
    endfunction
endlibrary
