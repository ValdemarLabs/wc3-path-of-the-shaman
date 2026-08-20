/**
    VoicelinesDrunk

    Author: Valdemar
    Version: 1.0.0

    Description:
    Randomized hero, AI companion, wake-up, and Horde vendor lines used by
    Drunk and A Night To Remember.

    Credits:
    - Fish Audio

    How to install:
    Import after Voicelines and VoicelinesVendorLines.

    API:
    call VoicelinesDrunk_PickHeroReaction(speaker, passOut)
    call VoicelinesDrunk_PickHeroNightReply(speaker)
    call VoicelinesDrunk_PickAIReaction(speaker, passOut)
    call VoicelinesDrunk_PickWakeLine(speaker)
    call VoicelinesDrunk_PickVendorLine(voiceType, firstIndex)
    Read VoicelinesDrunk_PickedText and VoicelinesDrunk_PickedKey.

**/
library VoicelinesDrunk initializer Init requires Voicelines, VoicelinesVendorLines

globals
    string VoicelinesDrunk_PickedText = ""
    string VoicelinesDrunk_PickedKey = ""

    // Folder declarations also drive tools/voicelines.ps1.
    constant string VL_NAZGREKDRUNK_FOLDER = "Nazgrek"
    constant string VL_ZULKISDRUNK_FOLDER = "Zulkis"
    constant string VL_HEROENGINEERDRUNK_FOLDER = "HeroEngineer"
    constant string VL_HEROPALADINDRUNK_FOLDER = "HeroPaladin"
    constant string VL_HEROSHAMANDRUNK_FOLDER = "HeroRestoshaman"
    constant string VL_HEROROGUEDRUNK_FOLDER = "HeroRogue"
    constant string VL_HEROWARLOCKDRUNK_FOLDER = "HeroWarlock"
    constant string VL_HEROWARRIORDRUNK_FOLDER = "HeroWarrior"
    constant string VL_AVELINEDRUNK_FOLDER = "Aveline"

    // Nazgrek reactions and wake-up lines.
    constant string VL_NAZGREKDRUNK_PUKE1_KEY = "Nazgrek_DrunkPuke1"
    constant string VL_NAZGREKDRUNK_PUKE1_TEXT = "Easy there. The mug is not your enemy."
    constant string VL_NAZGREKDRUNK_PUKE2_KEY = "Nazgrek_DrunkPuke2"
    constant string VL_NAZGREKDRUNK_PUKE2_TEXT = "You should drink that stuff more carefully."
    constant string VL_NAZGREKDRUNK_PASSOUT1_KEY = "Nazgrek_DrunkPassOut1"
    constant string VL_NAZGREKDRUNK_PASSOUT1_TEXT = "Zul'kis! Wake up, you reckless troll!"
    constant string VL_NAZGREKDRUNK_PASSOUT2_KEY = "Nazgrek_DrunkPassOut2"
    constant string VL_NAZGREKDRUNK_PASSOUT2_TEXT = "Zul'kis? Spirits, what have you done?"
    constant string VL_NAZGREKDRUNK_WAKE1_KEY = "Nazgrek_HangoverWake1"
    constant string VL_NAZGREKDRUNK_WAKE1_TEXT = "My skull feels like a kodo drum."
    constant string VL_NAZGREKDRUNK_WAKE2_KEY = "Nazgrek_HangoverWake2"
    constant string VL_NAZGREKDRUNK_WAKE2_TEXT = "The elements are far too loud this morning."
    constant string VL_NAZGREKDRUNK_WAKE3_KEY = "Nazgrek_HangoverWake3"
    constant string VL_NAZGREKDRUNK_WAKE3_TEXT = "Where am I, and why do I smell like a brewery?"
    constant string VL_NAZGREKDRUNK_NIGHT1_KEY = "Nazgrek_LastNight1"
    constant string VL_NAZGREKDRUNK_NIGHT1_TEXT = "You led a parade with no followers and saluted every barrel."
    constant string VL_NAZGREKDRUNK_NIGHT2_KEY = "Nazgrek_LastNight2"
    constant string VL_NAZGREKDRUNK_NIGHT2_TEXT = "You borrowed my cloak, lost your boots, and returned with a goat."
    constant string VL_NAZGREKDRUNK_NIGHT3_KEY = "Nazgrek_LastNight3"
    constant string VL_NAZGREKDRUNK_NIGHT3_TEXT = "I stopped asking questions when you challenged the moon."

    // Zul'kis reactions and wake-up lines.
    constant string VL_ZULKISDRUNK_PUKE1_KEY = "Zulkis_DrunkPuke1"
    constant string VL_ZULKISDRUNK_PUKE1_TEXT = "Slow down, mon. Da cup not be runnin' away."
    constant string VL_ZULKISDRUNK_PUKE2_KEY = "Zulkis_DrunkPuke2"
    constant string VL_ZULKISDRUNK_PUKE2_TEXT = "Ya supposed ta drink it, not fight it."
    constant string VL_ZULKISDRUNK_PASSOUT1_KEY = "Zulkis_DrunkPassOut1"
    constant string VL_ZULKISDRUNK_PASSOUT1_TEXT = "Nazgrek?! What ya doin', mon? Wake up!"
    constant string VL_ZULKISDRUNK_PASSOUT2_KEY = "Zulkis_DrunkPassOut2"
    constant string VL_ZULKISDRUNK_PASSOUT2_TEXT = "Nazgrek, dis not be a good place for a nap!"
    constant string VL_ZULKISDRUNK_WAKE1_KEY = "Zulkis_HangoverWake1"
    constant string VL_ZULKISDRUNK_WAKE1_TEXT = "Da spirits be whisperin'. Could dey whisper softer?"
    constant string VL_ZULKISDRUNK_WAKE2_KEY = "Zulkis_HangoverWake2"
    constant string VL_ZULKISDRUNK_WAKE2_TEXT = "My head be hurtin' in three different languages."
    constant string VL_ZULKISDRUNK_WAKE3_KEY = "Zulkis_HangoverWake3"
    constant string VL_ZULKISDRUNK_WAKE3_TEXT = "I remember a barrel, a song, and den nothin'."
    constant string VL_ZULKISDRUNK_NIGHT1_KEY = "Zulkis_LastNight1"
    constant string VL_ZULKISDRUNK_NIGHT1_TEXT = "Ya crowned a keg king and demanded we all bow, mon."
    constant string VL_ZULKISDRUNK_NIGHT2_KEY = "Zulkis_LastNight2"
    constant string VL_ZULKISDRUNK_NIGHT2_TEXT = "Ya danced on a table till da table surrendered."
    constant string VL_ZULKISDRUNK_NIGHT3_KEY = "Zulkis_LastNight3"
    constant string VL_ZULKISDRUNK_NIGHT3_TEXT = "I lost ya after ya followed a very suspicious chicken."

    // AI companion reactions. Aveline remains text-only until a Fish voice ID is supplied.
    constant string VL_HEROENGINEERDRUNK_PUKE1_KEY = "HeroEngineer_DrunkPuke1"
    constant string VL_HEROENGINEERDRUNK_PUKE1_TEXT = "That intake exceeded every safe operating tolerance."
    constant string VL_HEROENGINEERDRUNK_PUKE2_KEY = "HeroEngineer_DrunkPuke2"
    constant string VL_HEROENGINEERDRUNK_PUKE2_TEXT = "Next time, install a regulator between the bottle and your mouth."
    constant string VL_HEROPALADINDRUNK_PUKE1_KEY = "HeroPaladin_DrunkPuke1"
    constant string VL_HEROPALADINDRUNK_PUKE1_TEXT = "Temperance would spare you this indignity."
    constant string VL_HEROPALADINDRUNK_PUKE2_KEY = "HeroPaladin_DrunkPuke2"
    constant string VL_HEROPALADINDRUNK_PUKE2_TEXT = "Drink water before you challenge another keg."
    constant string VL_HEROSHAMANDRUNK_PUKE1_KEY = "HeroShaman_DrunkPuke1"
    constant string VL_HEROSHAMANDRUNK_PUKE1_TEXT = "Your body is rejecting what your judgment welcomed."
    constant string VL_HEROSHAMANDRUNK_PUKE2_KEY = "HeroShaman_DrunkPuke2"
    constant string VL_HEROSHAMANDRUNK_PUKE2_TEXT = "The water spirits recommend water next time."
    constant string VL_HEROROGUEDRUNK_PUKE1_KEY = "HeroRogue_DrunkPuke1"
    constant string VL_HEROROGUEDRUNK_PUKE1_TEXT = "Subtle. No one will ever know you were drinking."
    constant string VL_HEROROGUEDRUNK_PUKE2_KEY = "HeroRogue_DrunkPuke2"
    constant string VL_HEROROGUEDRUNK_PUKE2_TEXT = "Try stealing smaller sips next time."
    constant string VL_HEROWARLOCKDRUNK_PUKE1_KEY = "HeroWarlock_DrunkPuke1"
    constant string VL_HEROWARLOCKDRUNK_PUKE1_TEXT = "Even demons show more restraint at a feast."
    constant string VL_HEROWARLOCKDRUNK_PUKE2_KEY = "HeroWarlock_DrunkPuke2"
    constant string VL_HEROWARLOCKDRUNK_PUKE2_TEXT = "A curse would have been cleaner than this."
    constant string VL_HEROWARRIORDRUNK_PUKE1_KEY = "HeroWarrior_DrunkPuke1"
    constant string VL_HEROWARRIORDRUNK_PUKE1_TEXT = "Hold your ground. And your stomach."
    constant string VL_HEROWARRIORDRUNK_PUKE2_KEY = "HeroWarrior_DrunkPuke2"
    constant string VL_HEROWARRIORDRUNK_PUKE2_TEXT = "You fought that drink bravely. The drink won."
    constant string VL_AVELINEDRUNK_PUKE1_KEY = "Aveline_DrunkPuke1"
    constant string VL_AVELINEDRUNK_PUKE1_TEXT = "That is why soldiers pace their drinks."
    constant string VL_AVELINEDRUNK_PUKE2_KEY = "Aveline_DrunkPuke2"
    constant string VL_AVELINEDRUNK_PUKE2_TEXT = "Clean yourself up before something smells weakness."

    private integer VD_VendorVoiceCount = 0
    private string array VD_VendorVoiceType
    private integer array VD_VendorFirstIndex
    private string array VD_VendorText1
    private string array VD_VendorText2
    private string array VD_VendorText3
endglobals

private function SetPicked takes string text, string key returns nothing
    set VoicelinesDrunk_PickedText = text
    set VoicelinesDrunk_PickedKey = key
endfunction

private function PickTwo takes string text1, string key1, string text2, string key2 returns nothing
    if GetRandomInt(1, 2) == 1 then
        call SetPicked(text1, key1)
    else
        call SetPicked(text2, key2)
    endif
endfunction

public function PickHeroReaction takes unit speaker, boolean passOut returns nothing
    if speaker == udg_Nazgrek then
        if passOut then
            call PickTwo(VL_NAZGREKDRUNK_PASSOUT1_TEXT, VL_NAZGREKDRUNK_PASSOUT1_KEY, VL_NAZGREKDRUNK_PASSOUT2_TEXT, VL_NAZGREKDRUNK_PASSOUT2_KEY)
        else
            call PickTwo(VL_NAZGREKDRUNK_PUKE1_TEXT, VL_NAZGREKDRUNK_PUKE1_KEY, VL_NAZGREKDRUNK_PUKE2_TEXT, VL_NAZGREKDRUNK_PUKE2_KEY)
        endif
    elseif passOut then
        call PickTwo(VL_ZULKISDRUNK_PASSOUT1_TEXT, VL_ZULKISDRUNK_PASSOUT1_KEY, VL_ZULKISDRUNK_PASSOUT2_TEXT, VL_ZULKISDRUNK_PASSOUT2_KEY)
    else
        call PickTwo(VL_ZULKISDRUNK_PUKE1_TEXT, VL_ZULKISDRUNK_PUKE1_KEY, VL_ZULKISDRUNK_PUKE2_TEXT, VL_ZULKISDRUNK_PUKE2_KEY)
    endif
    set speaker = null
endfunction

public function PickWakeLine takes unit speaker returns nothing
    local integer roll = GetRandomInt(1, 3)
    if speaker == udg_Nazgrek then
        if roll == 1 then
            call SetPicked(VL_NAZGREKDRUNK_WAKE1_TEXT, VL_NAZGREKDRUNK_WAKE1_KEY)
        elseif roll == 2 then
            call SetPicked(VL_NAZGREKDRUNK_WAKE2_TEXT, VL_NAZGREKDRUNK_WAKE2_KEY)
        else
            call SetPicked(VL_NAZGREKDRUNK_WAKE3_TEXT, VL_NAZGREKDRUNK_WAKE3_KEY)
        endif
    elseif roll == 1 then
        call SetPicked(VL_ZULKISDRUNK_WAKE1_TEXT, VL_ZULKISDRUNK_WAKE1_KEY)
    elseif roll == 2 then
        call SetPicked(VL_ZULKISDRUNK_WAKE2_TEXT, VL_ZULKISDRUNK_WAKE2_KEY)
    else
        call SetPicked(VL_ZULKISDRUNK_WAKE3_TEXT, VL_ZULKISDRUNK_WAKE3_KEY)
    endif
    set speaker = null
endfunction

public function PickHeroNightReply takes unit speaker returns nothing
    local integer roll = GetRandomInt(1, 3)
    if speaker == udg_Nazgrek then
        if roll == 1 then
            call SetPicked(VL_NAZGREKDRUNK_NIGHT1_TEXT, VL_NAZGREKDRUNK_NIGHT1_KEY)
        elseif roll == 2 then
            call SetPicked(VL_NAZGREKDRUNK_NIGHT2_TEXT, VL_NAZGREKDRUNK_NIGHT2_KEY)
        else
            call SetPicked(VL_NAZGREKDRUNK_NIGHT3_TEXT, VL_NAZGREKDRUNK_NIGHT3_KEY)
        endif
    elseif roll == 1 then
        call SetPicked(VL_ZULKISDRUNK_NIGHT1_TEXT, VL_ZULKISDRUNK_NIGHT1_KEY)
    elseif roll == 2 then
        call SetPicked(VL_ZULKISDRUNK_NIGHT2_TEXT, VL_ZULKISDRUNK_NIGHT2_KEY)
    else
        call SetPicked(VL_ZULKISDRUNK_NIGHT3_TEXT, VL_ZULKISDRUNK_NIGHT3_KEY)
    endif
    set speaker = null
endfunction

public function PickAIReaction takes unit speaker, boolean passOut returns nothing
    local integer unitTypeId = GetUnitTypeId(speaker)
    if unitTypeId == 'N64O' or unitTypeId == 'N661' then
        call PickTwo(VL_HEROENGINEERDRUNK_PUKE1_TEXT, VL_HEROENGINEERDRUNK_PUKE1_KEY, VL_HEROENGINEERDRUNK_PUKE2_TEXT, VL_HEROENGINEERDRUNK_PUKE2_KEY)
    elseif unitTypeId == 'H60Y' then
        call PickTwo(VL_HEROPALADINDRUNK_PUKE1_TEXT, VL_HEROPALADINDRUNK_PUKE1_KEY, VL_HEROPALADINDRUNK_PUKE2_TEXT, VL_HEROPALADINDRUNK_PUKE2_KEY)
    elseif unitTypeId == 'O61H' then
        call PickTwo(VL_HEROSHAMANDRUNK_PUKE1_TEXT, VL_HEROSHAMANDRUNK_PUKE1_KEY, VL_HEROSHAMANDRUNK_PUKE2_TEXT, VL_HEROSHAMANDRUNK_PUKE2_KEY)
    elseif unitTypeId == 'O631' then
        call PickTwo(VL_HEROROGUEDRUNK_PUKE1_TEXT, VL_HEROROGUEDRUNK_PUKE1_KEY, VL_HEROROGUEDRUNK_PUKE2_TEXT, VL_HEROROGUEDRUNK_PUKE2_KEY)
    elseif unitTypeId == 'O61K' or unitTypeId == 'H60X' then
        call PickTwo(VL_HEROWARLOCKDRUNK_PUKE1_TEXT, VL_HEROWARLOCKDRUNK_PUKE1_KEY, VL_HEROWARLOCKDRUNK_PUKE2_TEXT, VL_HEROWARLOCKDRUNK_PUKE2_KEY)
    elseif unitTypeId == 'O009' then
        call PickTwo(VL_AVELINEDRUNK_PUKE1_TEXT, VL_AVELINEDRUNK_PUKE1_KEY, VL_AVELINEDRUNK_PUKE2_TEXT, VL_AVELINEDRUNK_PUKE2_KEY)
    else
        call PickTwo(VL_HEROWARRIORDRUNK_PUKE1_TEXT, VL_HEROWARRIORDRUNK_PUKE1_KEY, VL_HEROWARRIORDRUNK_PUKE2_TEXT, VL_HEROWARRIORDRUNK_PUKE2_KEY)
    endif
    set speaker = null
endfunction

private function RegisterVendorVoice takes string voiceType, integer firstIndex, string folder, string text1, string text2, string text3 returns nothing
    set VD_VendorVoiceCount = VD_VendorVoiceCount + 1
    set VD_VendorVoiceType[VD_VendorVoiceCount] = voiceType
    set VD_VendorFirstIndex[VD_VendorVoiceCount] = firstIndex
    set VD_VendorText1[VD_VendorVoiceCount] = text1
    set VD_VendorText2[VD_VendorVoiceCount] = text2
    set VD_VendorText3[VD_VendorVoiceCount] = text3
    call ExSound_RegisterSequence(voiceType, firstIndex, firstIndex + 2, "Pots\\Sound\\Voicelines\\" + folder + "\\")
endfunction

public function PickVendorLine takes string voiceType, integer firstIndex returns nothing
    local integer index = 1
    local integer roll = GetRandomInt(1, 3)
    loop
        exitwhen index > VD_VendorVoiceCount
        if VD_VendorVoiceType[index] == voiceType and VD_VendorFirstIndex[index] == firstIndex then
            if roll == 1 then
                call SetPicked(VD_VendorText1[index], voiceType + I2S(firstIndex))
            elseif roll == 2 then
                call SetPicked(VD_VendorText2[index], voiceType + I2S(firstIndex + 1))
            else
                call SetPicked(VD_VendorText3[index], voiceType + I2S(firstIndex + 2))
            endif
            return
        endif
        set index = index + 1
    endloop
    call SetPicked("I remember enough to know you owe someone an apology.", "")
endfunction

private function Init takes nothing returns nothing
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PASSOUT1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PASSOUT2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_WAKE1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_WAKE2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_WAKE3_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PASSOUT1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PASSOUT2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_WAKE1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_WAKE2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_WAKE3_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_PUKE2_KEY)

    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_1_TYPE, 1101, "GenericOrcMale1", "You sang to my fish barrel, then blamed the fish for joining in.", "You promised to pay your tab with a treasure map drawn on a napkin.", "Last night you challenged a chair to single combat. The chair won.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_3_TYPE, 1101, "GenericOrcMale3", "You spoke great wisdom last night. None of it belonged to you.", "You left carrying a keg and returned carrying a road sign.", "Your ancestors may remember the night. You certainly do not.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_4_TYPE, 1101, "GenericOrcMale4", "You tried to sharpen a spoon and called it a war blade.", "You arm-wrestled my anvil. I respect the courage, not the result.", "You ordered armor for a barrel and insisted it was your cousin.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_5_TYPE, 1101, "GenericOrcMale5", "You ate tomorrow's stew and paid with yesterday's promises.", "You slept in the flour sack. We sold around you.", "You called my cooking legendary, then seasoned it with your boot.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_8_TYPE, 1101, "GenericOrcMale8", "The spirits were quiet. You supplied enough noise for all of them.", "You asked the tide for directions and argued with its answer.", "Your shadow left before you did. Sensible shadow.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_9_TYPE, 1101, "GenericOrcMale9", "You bought a whetstone for your teeth. I refused the demonstration.", "You declared war on an empty bottle and demanded reinforcements.", "Your weapon was safe. Everyone near your dancing was not.")
    call RegisterVendorVoice(VL_GENERIC_TAUREN_MALE_1_TYPE, 1101, "GenericTaurenMale1", "You tried to race a windmill. The windmill remained dignified.", "You offered a solemn toast to a hitching post.", "The earth remembers every step. Last night, yours formed circles.")
    call RegisterVendorVoice(VL_GENERIC_TAUREN_MALE_2_TYPE, 1101, "GenericTaurenMale2", "You slept beneath my counter and called it a mountain shelter.", "You tried to mine a cobblestone with a drinking horn.", "Your trail was easy to follow. It smelled strongly of ale.")
    call RegisterVendorVoice(VL_GENERIC_TAUREN_MALE_3_TYPE, 1101, "GenericTaurenMale3", "You traded your left boot for a story. The story was about your right boot.", "You packed three empty mugs and forgot your supplies.", "You asked me to send a parcel to tomorrow morning.")
    call RegisterVendorVoice(VL_GENERIC_TROLL_MALE_1_TYPE, 1001, "GenericTrollMale1", "Ya tried ta pay with shiny pebbles, mon. Dey were beans.", "Ya asked me ta cut a gem shaped like ya headache.", "Ya danced with da display case. It still be shaken.")
    call RegisterVendorVoice(VL_GENERIC_TROLL_MALE_2_TYPE, 1001, "GenericTrollMale2", "Ya asked for a cure before ya finished makin' da problem.", "Da spirits say ya owe three mugs and one apology.", "Ya bought smoke, lost da smoke, den accused da moon.")
endfunction

endlibrary
