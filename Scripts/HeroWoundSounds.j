library HeroWoundSounds initializer Init

/*
    ===========================================================================================
                                        Hero Wound Sounds
                                            by Antares
   
            Easily add on-damage "ouch"-sounds to heroes for your rpg or other hero map.
           
                                            How to import:
    Copy this library into your map. Extract the imported sound files into an empty folder, then
    import those that you need into your map. Saving your map in folder mode might make the
    import process more convenient.
   
    Edit the parameters in the config section to your liking.
    
    To import additional wound sounds from World of Warcraft characters, go to www.wowhead.com, then
    go to Database -> Sounds. In the Name field, enter either "Wound" or the name of your race/gender
    combination, for example "TaurenFemale." The names of the wound sound files are not entirely
    consistent and it might take some experimentation to find the ones you are looking for.
    
    Download the sound files, then you need to convert the .ogg files to .flac or .mp3. You can
    do this via online tools or with Audacity (freeware). To do so, select all sound files in your
    explorer, then drag them into the Audacity window. On the left, increase the volume of each
    file by roughly 3 db. Then go to File -> Export -> Export Multiple and select .mp3 as the
    output format.
    
    Rename the files to
    YourNameHit1.mp3
    YourNameHit2.mp3
    ...
    YourNameCrit.mp3
    
    Import the sound files into the specified subfolder and add a line to the Init function to
    tell the library how many normal wound sounds exist. For example, if you import TaurenFemale
    and it has 4 wound sounds plus a crit sound, it should be:
    call SaveInteger(hash, StringHash("TaurenFemale"), 0, 4)

    ===========================================================================================
    API
    ===========================================================================================
   
    AddWoundSoundsToUnit takes unit whichUnit, string whichSoundPath returns nothing
    RemoveWoundSoundsFromUnit takes unit whichUnit returns nothing
    PauseWoundSoundsForUnit takes unit whichUnit returns nothing
    AdjustWoundSoundVolumeForUnit takes unit whichUnit, real volumePercent returns nothing

    ===========================================================================================
    */

globals
    //=========================================================================================
    //Config
    //=========================================================================================

    private constant real WOUND_SOUND_COOLDOWN              = 1.25              //Minimum time between to wound sounds. Crit sounds will play even when normal wound sounds are on cooldown.
    
    private constant boolean ENABLE_HIT_SOUNDS              = true              //Disable if you only want wound crit sounds.
    private constant real HIT_SOUND_THRESHOLD               = 3                 //Damage required to trigger a normal wound sound.
    private constant boolean ENABLE_CRIT_SOUNDS             = true              //Disable if you only want normal wound sounds.
    private constant real CRIT_SOUND_THRESHOLD              = 10                //Damage required to trigger a wound crit sound.
    private constant boolean THRESHOLD_IN_PERCENT           = true              //true if thresholds are given in percentage of hero max hp. false if thresholds are given in absolute values.
    
    private constant boolean TRIGGER_ON_ATTACK_DAMAGE       = true              //Disable if attacks should not trigger wound sounds.
    private constant boolean TRIGGER_ON_NON_ATTACK_DAMAGE   = true              //Disable if only attacks should trigger wound sounds.

    private constant boolean PLAY_ONLY_FOR_OWNER            = true              //Disable if every player should hear the wound sounds, not just the owner.
    private constant boolean PLAY_AS_3D_SOUND               = false             //Enable if wound sounds should be played as a 3D sound on the hero's location.
    private constant real SOUND_3D_MIN_DIST                 = 600               //Only if PLAY_AS_3D_SOUND is enabled.
    private constant real SOUND_3D_MAX_DIST                 = 4000              //Only if PLAY_AS_3D_SOUND is enabled.
	
	private constant boolean AUTO_CLEANUP_ON_DEATH			= false				//Enable if memory leaks should automatically be handled on death of a nonhero unit. Otherwise, leaks must be
																				//manually removed with RemoveWoundSoundsFromUnit.

    private constant string SOUND_FILE_SUBFOLDER            = "WoundSounds\\"   //The subfolder where the imported wound sounds are stored in.
    
    //=========================================================================================

    private hashtable hash = InitHashtable()
endglobals

private function Init takes nothing returns nothing
    //=========================================================================================
    //Here, the number of wound sounds for each race/gender combination are stored. When you
    //import new sound files, add them here.
    //=========================================================================================
    static if ENABLE_HIT_SOUNDS then
        call SaveInteger(hash, StringHash("BloodElfFemale"), 0,     4)
        call SaveInteger(hash, StringHash("BloodElfMale"), 0,       4)
        call SaveInteger(hash, StringHash("Cat"), 0,                3)
        call SaveInteger(hash, StringHash("DraeneiMale"), 0,        5)
        call SaveInteger(hash, StringHash("DwarfFemale"), 0,        5)
        call SaveInteger(hash, StringHash("DwarfMale"), 0,          4)
        call SaveInteger(hash, StringHash("GnomeFemale"), 0,        3)
        call SaveInteger(hash, StringHash("GnomeMale"), 0,          4)
        call SaveInteger(hash, StringHash("GoblinFemale"), 0,       5)
        call SaveInteger(hash, StringHash("GoblinMale"), 0,         4)
        call SaveInteger(hash, StringHash("HumanFemale"), 0,        4)
        call SaveInteger(hash, StringHash("HumanMale"), 0,          3)
        call SaveInteger(hash, StringHash("NagaFemale"), 0,         4)
        call SaveInteger(hash, StringHash("NightElfFemale"), 0,     4)
        call SaveInteger(hash, StringHash("NightElfMale"), 0,       4)
        call SaveInteger(hash, StringHash("OrcMale"), 0,            5)
        call SaveInteger(hash, StringHash("PandarenMale"), 0,       4)
        call SaveInteger(hash, StringHash("TaurenMale"), 0,         3)
        call SaveInteger(hash, StringHash("TrollMale"), 0,          5)
        call SaveInteger(hash, StringHash("UndeadFemale"), 0,       3)
        call SaveInteger(hash, StringHash("UndeadMale"), 0,         3)
        call SaveInteger(hash, StringHash("VoidElfFemale"), 0,      4)
        call SaveInteger(hash, StringHash("VrykulFemale"), 0,       5)
    endif
endfunction

static if AUTO_CLEANUP_ON_DEATH then
	private function OnDeath takes nothing returns nothing
		local unit u = GetTriggerUnit()
		local woundSound whichWoundSound = LoadInteger(hash, GetHandleId(u), 0)
		call whichWoundSound.destroy()
		set u = null
	endfunction
endif

private function PlayWoundSound takes string soundPath, real volumePercent, unit whichUnit returns nothing
	local real volume = volumePercent
	local sound s = CreateSound(soundPath, false, PLAY_AS_3D_SOUND, PLAY_AS_3D_SOUND, 10, 10, "DefaultEAXON")
	
    static if PLAY_ONLY_FOR_OWNER then
        if GetLocalPlayer() != GetOwningPlayer(whichUnit) then
            set volume = 0
        endif
    endif

    static if PLAY_AS_3D_SOUND then
        call SetSoundPosition( s, GetUnitX(whichUnit), GetUnitY(whichUnit), 50)
        call SetSoundDistances( s , SOUND_3D_MIN_DIST , SOUND_3D_MAX_DIST )
    endif
        
	call SetSoundVolumeBJ(s, volume)
	call StartSound(s)
	call KillSoundWhenDone(s)
	set s = null
endfunction

struct woundSound
    unit hero
    string soundPath
    timer woundTimer
    timer woundCritTimer
    trigger damageTrigger
	trigger deathTrigger
    integer numSounds
    boolean isPaused
    integer lastSound
    real volumePercent

    static method OnDamage takes nothing returns nothing
        local unit u = BlzGetEventDamageTarget()
        local real amount = GetEventDamage()
        local woundSound this
        local string fullPath
        
        if amount > GetUnitState(u, UNIT_STATE_LIFE) then
            set u = null
            return
        endif
        
        static if not TRIGGER_ON_ATTACK_DAMAGE then
            if BlzGetEventIsAttack() then
                set u = null
                return
            endif
        endif
        
        static if not TRIGGER_ON_NON_ATTACK_DAMAGE then
            if not BlzGetEventIsAttack() then
                set u = null
                return
            endif
        endif
        
        static if ENABLE_HIT_SOUNDS then
            if (amount > HIT_SOUND_THRESHOLD and not THRESHOLD_IN_PERCENT) or (amount > HIT_SOUND_THRESHOLD*BlzGetUnitMaxHP(u)/100 and THRESHOLD_IN_PERCENT) then
                set this = LoadInteger(hash, GetHandleId(u), 0)
                if .isPaused then
                    set u = null
                    return
                endif
                
                static if ENABLE_CRIT_SOUNDS then
                    if ((amount > CRIT_SOUND_THRESHOLD and not THRESHOLD_IN_PERCENT) or (amount > CRIT_SOUND_THRESHOLD*BlzGetUnitMaxHP(u)/100 and THRESHOLD_IN_PERCENT)) then
                        if TimerGetRemaining(.woundCritTimer) == 0 then
                            set fullPath = .soundPath + "Crit.mp3"
                            if WOUND_SOUND_COOLDOWN > 0 then
                                call TimerStart(.woundTimer, WOUND_SOUND_COOLDOWN, false, null)
                                call TimerStart(.woundCritTimer, WOUND_SOUND_COOLDOWN, false, null)
                            endif
                            call PlayWoundSound(fullPath, .volumePercent, u)
                        endif
                    elseif TimerGetRemaining(.woundTimer) == 0 then
                        set .lastSound = ModuloInteger(.lastSound + GetRandomInt(0,.numSounds-2), .numSounds) + 1
                        set fullPath = .soundPath + "Hit" + I2S(.lastSound) + ".mp3"
                        if WOUND_SOUND_COOLDOWN > 0 then
                            call TimerStart(.woundTimer, WOUND_SOUND_COOLDOWN, false, null)
                        endif
                        call PlayWoundSound(fullPath, .volumePercent, u)
                    endif
                else
                    if TimerGetRemaining(.woundTimer) == 0 then
                        set .lastSound = ModuloInteger(.lastSound + GetRandomInt(0,.numSounds-2), .numSounds) + 1
                        set fullPath = .soundPath + "Hit" + I2S(.lastSound) + ".mp3"
                        if WOUND_SOUND_COOLDOWN > 0 then
                            call TimerStart(.woundTimer, WOUND_SOUND_COOLDOWN, false, null)
                        endif
                        call PlayWoundSound(fullPath, .volumePercent, u)
                    endif
                endif
            endif
        else
            static if ENABLE_CRIT_SOUNDS then
                if (amount > CRIT_SOUND_THRESHOLD and not THRESHOLD_IN_PERCENT) or (amount > CRIT_SOUND_THRESHOLD*BlzGetUnitMaxHP(u)/100 and THRESHOLD_IN_PERCENT) then
                    set this = LoadInteger(hash, GetHandleId(u), 0)
                    if .isPaused then
                        set u = null
                        return
                    endif
                    if TimerGetRemaining(.woundCritTimer) == 0 then
                        set fullPath = .soundPath + "Crit.mp3"
                        if WOUND_SOUND_COOLDOWN > 0 then
                            call TimerStart(.woundCritTimer, WOUND_SOUND_COOLDOWN, false, null)
                        endif
                        call PlayWoundSound(fullPath, .volumePercent, u)
                    endif
                endif
            endif
        endif
        set u = null
    endmethod
    
    static method create takes unit whichUnit, string whichSoundPath returns woundSound
        local woundSound this = woundSound.allocate()
        set .hero = whichUnit
        set .soundPath = SOUND_FILE_SUBFOLDER + whichSoundPath
        set .damageTrigger = CreateTrigger()
        static if ENABLE_HIT_SOUNDS then
            if WOUND_SOUND_COOLDOWN > 0 then
                set .woundTimer = CreateTimer()
            endif
            set .numSounds = LoadInteger(hash, StringHash(whichSoundPath), 0)
        endif
        static if ENABLE_CRIT_SOUNDS then
            if WOUND_SOUND_COOLDOWN > 0 then
                set .woundCritTimer = CreateTimer()
            endif
        endif
        set .isPaused = false
        set .lastSound = 0
        set .volumePercent = 100
        
        call TriggerAddAction(.damageTrigger, function woundSound.OnDamage)
        call TriggerRegisterUnitEvent(.damageTrigger, .hero, EVENT_UNIT_DAMAGED)
        
        call SaveInteger(hash, GetHandleId(.hero), 0, this)
		
		static if AUTO_CLEANUP_ON_DEATH then
			if not IsUnitType(whichUnit, UNIT_TYPE_HERO)
				set .deathTrigger = CreateTrigger()
				call TriggerAddAction(.deathTrigger, function OnDeath)
				call TriggerRegisterUnitEvent(.deathTrigger, whichUnit, EVENT_UNIT_DEATH)
			endif
		endif

        return this
    endmethod
    
    method onDestroy takes nothing returns nothing
        if WOUND_SOUND_COOLDOWN > 0 then
            call DestroyTimer(.woundTimer)
            call DestroyTimer(.woundCritTimer)
        endif
        call DestroyTrigger(.damageTrigger)
        call RemoveSavedInteger(hash, GetHandleId(.hero), 0)
		static if AUTO_CLEANUP_ON_DEATH then
			if not IsUnitType(.hero, UNIT_TYPE_HERO) then
				call DestroyTrigger(.deathTrigger)
			endif
		endif
    endmethod
endstruct

function AddWoundSoundsToUnit takes unit whichUnit, string whichSoundPath returns nothing
    call woundSound.create(whichUnit,whichSoundPath)
endfunction

function RemoveWoundSoundsFromUnit takes unit whichUnit returns nothing
    local woundSound whichWoundSound = LoadInteger(hash, GetHandleId(whichUnit), 0)
    call whichWoundSound.destroy()
endfunction

function PauseWoundSoundsForUnit takes unit whichUnit, boolean pause returns nothing
    local woundSound whichWoundSound = LoadInteger(hash, GetHandleId(whichUnit), 0)
    set whichWoundSound.isPaused = pause
endfunction

function AdjustWoundSoundVolumeForUnit takes unit whichUnit, real percentage returns nothing
    local woundSound whichWoundSound = LoadInteger(hash, GetHandleId(whichUnit), 0)
    set whichWoundSound.volumePercent = RMinBJ(100,percentage)
endfunction

endlibrary