library RapidSound requires optional TimerUtils

    globals
        // Actually, just leave this value
        private constant real MIN_DELAY_FACTOR = 4.0
    endglobals

    /* v1.6

        Description
        ¯¯¯¯¯¯¯¯¯¯¯
            Allows you to play sounds rapidly and flawlessly without limit.
            Remember one sound file can only have one RSound instance.
        
        
        External Dependencies
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
            (Optional)
            TimerUtils by Vexorian
                wc3c.net/showthread.php?t=101322
    
    
        User API
        ¯¯¯¯¯¯¯¯
            struct RSound
        
                Instantiate an RapidSound instance
                    | static method create takes string fileName, boolean is3D, boolean autoStop, integer inRate, integer outRate returns thistype
                        autoStop => stop when sound is out of range
                        inRate   => fade in rate
                        outRate  => fade out rate
                
                Play the sound at given coordinate
                    | method play takes real x, real y, real z, integer volume returns nothing
                
                Stop sound
                    | method stop takes boolean fadeOut returns nothing
            
                Destroy RapidSound instance
                    | method kill takes nothing returns nothing
            
                Sound file duration (in second)
                    | method operator duration takes nothing returns real
    
    
        Resource Link
        ¯¯¯¯¯¯¯¯¯¯¯¯¯
            hiveworkshop.com/threads/snippet-rapidsound.258991/
    */

    struct RSound

        private static constant integer MAX_COUNT = 4
        private static integer  Counter = -1
        private static string   array StrLib
        private static thistype array StrDex
    
        private integer ct
        private integer lib
        private integer dex
        private real    dur
				real    pitch
    
        private sound array snd[thistype.MAX_COUNT]
        private timer array tmr[thistype.MAX_COUNT]
    
        method operator duration takes nothing returns real
            return .dur*MIN_DELAY_FACTOR
        endmethod
    
        method kill takes nothing returns nothing
    
            local integer i
        
            set .ct = .ct - 1
            if .ct == 0 then
                set i = 0
                loop
                    exitwhen i == MAX_COUNT
                    call StopSound(.snd[i], true, false)
                    static if LIBRARY_TimerUtils then
                        call ReleaseTimer(.tmr[i])
                    else
                        call DestroyTimer(.tmr[i])
                    endif
                    set .snd[i] = null
                    set .tmr[i] = null
                    set i = i + 1
                endloop
                set StrLib[.lib] = StrLib[Counter]
                set StrDex[.lib] = StrDex[Counter]
                set Counter = Counter - 1
                call deallocate()
            endif
        
        endmethod
    
        method stop takes boolean fadeOut returns nothing
    
            local integer i = 0
        
            loop
                exitwhen i == MAX_COUNT
                call StopSound(.snd[i], false, fadeOut)
                set i = i + 1
            endloop
        
        endmethod
    
        method play takes real x, real y, real z, integer volume returns nothing
        
            set .dex = .dex + 1
            if .dex == MAX_COUNT then
                set .dex = 0
            endif
            if TimerGetRemaining(.tmr[.dex]) == 0 then
                call StopSound(.snd[.dex], false, false)
                call SetSoundPosition(.snd[.dex], x, y, z)
                call SetSoundVolume(.snd[.dex], volume)
				call SetSoundPitch(.snd[.dex], .pitch)
                call StartSound(.snd[.dex])
                call TimerStart(.tmr[.dex], .dur, false, null)
            endif
        
        endmethod
    
        static method create takes string fileName, boolean is3D, boolean autoStop, integer inRate, integer outRate returns thistype
    
            local thistype this
            local integer  i = 0
            local boolean  b = true
        
            loop
                exitwhen i > Counter
                if fileName == StrLib[i] then
                    set b = false
                    exitwhen true
                endif
                set i = i + 1
            endloop
        
            if b then
                set this = allocate()
                set Counter = Counter + 1
                set StrLib[Counter] = fileName
                set StrDex[Counter] = this
            
                set .ct  = 1
                set .dex = -1
                set .lib = Counter
				set .pitch = 1
                set .dur = I2R(GetSoundFileDuration(fileName))/(1000.*MIN_DELAY_FACTOR)
                set i = 0
                loop
                    exitwhen i == MAX_COUNT
                    set .snd[i] = CreateSound(fileName, false, is3D, autoStop, inRate, outRate, "")
                    static if LIBRARY_TimerUtils then
                        set .tmr[i] = NewTimer()
                        call TimerStart(.tmr[i], 0, false, null)
                        call PauseTimer(.tmr[i])
                    else
                        set .tmr[i] = CreateTimer()
                    endif
                    set i = i + 1
                endloop
            else
                set this = StrDex[i]
                set .ct  = .ct + 1
            endif
        
            return this
        endmethod
    
    endstruct

endlibrary