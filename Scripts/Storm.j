library Storm initializer Init
    
    // Storm v1.3.1
    // by OVOgenez
    
    /*
    ====================================================================================================================
                                          Imitation of lightning and thunder.
    
                                                   How to import:
    Copy this library to TE.
    Copy 'h000' (Ldummy) unit to OE.
    Import "Ldummy.mdx".
    If you want to use the models and sounds "out of the box", simply import these files:
        "L1.mdx"
        "L2.mdx"
        "L3.mdx"
        "T1.wav"
        "T2.wav"
        "T3.wav"
    otherwise, import your analogs by specifying their paths and params in the Init initialization function.
    
    ====================================================================================================================
                                                       A P I
    ====================================================================================================================
    
    call Storm_ImitateLocal(variant, count, azimuth, zenith, localplayer)
    call Storm_ImitateRandomLocal(variant, localplayer)
    call Storm_Imitate(variant, count, azimuth, zenith)
    call Storm_ImitateRandom(variant)
    
    ====================================================================================================================
                                                    C O N F I G
    ====================================================================================================================
    */

    globals
        private constant integer DUMMY_ID  = 'h000'     // Dummy unit ID
        public  constant integer VAR_COUNT = 3          // Number of storm variations
        
        private string array LightningPath              // Path to lightning models
        private string array ThunderPath                // Path to thunder sounds
        
        //==========================================
        // These fog parameters can be dynamically changed (if dynamic fog is used).
        //
        public  boolean TF          = true              // Whether fog is used        
        public  integer TF_style    = 0                 // Fog style
        public  real    TF_zstart   = 1000.0            // Fog start Z value
        public  real    TF_zend     = 3000.0            // Fog end Z value
        public  real    TF_density  = 0.0               // Fog density
        public  real    TF_red      = 0.0               // Red color of fog
        public  real    TF_green    = 0.0               // Green color of fog
        public  real    TF_blue     = 0.0               // Blue color of fog
        //==========================================
        
        //==========================================
        // These parameters affect the rendering of fog during the flash (if fog is used).
        //
        private boolean USE_zstart  = false             // Modify zstart (depends on L_intensity)
        private boolean USE_zend    = false             // Modify zend (depends on L_intensity)
        private boolean USE_density = false             // Modify density (depends on L_intensity)
        private boolean USE_color   = true              // Modify color (depends on L_intensity, L_red, L_green, L_blue)
        
        private real array L_intensity                  // Light sources intensity
        private real array L_red                        // Red color of light sources
        private real array L_green                      // Green color of light sources
        private real array L_blue                       // Blue color of light sources
        //==========================================
    endglobals
    
    //==========================================
    // Initialization of array values. NOT related to the number of variations (VAR_COUNT).
    // 
    private function Init takes nothing returns nothing
        set LightningPath[1] = "L1.mdx"
        set LightningPath[2] = "L2.mdx"
        set LightningPath[3] = "L3.mdx"
        set ThunderPath[1]   = "T1.wav"
        set ThunderPath[2]   = "T2.wav"
        set ThunderPath[3]   = "T3.wav"
        
        set L_intensity[1] = 0.4
        set L_intensity[2] = 0.8
        set L_intensity[3] = 1.2
        set L_red[1]       = 0.5
        set L_red[2]       = 0.5
        set L_red[3]       = 0.5
        set L_green[1]     = 0.75
        set L_green[2]     = 0.75
        set L_green[3]     = 0.75
        set L_blue[1]      = 1.0
        set L_blue[2]      = 1.0
        set L_blue[3]      = 1.0
    endfunction
    
    //==========================================
    // Settings for determining lightning and thunder properties based on other values.
    // 
    private module Settings
        static constant real PERIOD = 0.03125  // Timer period
        
        //==========================================
        // These values can be used in the methods below to determine the result. DO NOT edit this.
        //
        readonly integer Variant     // Storm variation            (from 1 to VAR_COUNT)
        readonly integer Count       // Number of light flashes    (from 1 to ...)
        readonly integer Current     // Current light flash        (from 1 to Count; 0 when delay before thunder)
        readonly integer Azimuth     // Horizontal light angle     (from -180 to 180)
        readonly integer Zenith      // Vertical light angle       (from -90 to 90)
        readonly integer LIndex      // Current lightning model index for LightningPath array
        readonly integer TIndex      // Current thunder sound index for ThunderPath array
        //==========================================
        
        //==========================================
        // Return the lightning model index for LightningPath array.
        //
        method operator GetLightningIndex takes nothing returns integer
            return .Variant
        endmethod
        
        //==========================================
        // Return the thunder sound index for ThunderPath array.
        //
        method operator GetThunderIndex takes nothing returns integer
            return .Variant
        endmethod
        
        //==========================================
        // Return the duration of lightning flash.
        //
        method operator GetPlayDuration takes nothing returns real
            return GetRandomInt(2, 4)*PERIOD
        endmethod
        
        //==========================================
        // Return the duration between lightning flashes.
        //
        method operator GetStopDuration takes nothing returns real
            return GetRandomInt(1, 3)*PERIOD
        endmethod
        
        //==========================================
        // Return the delay before thunder sound.
        //
        method operator GetSoundDelay takes nothing returns real
            return (10*(VAR_COUNT*VAR_COUNT - .Variant*.Variant) + GetRandomInt(0, 10))*PERIOD
        endmethod
        
        //==========================================
        // Return the volume of thunder sound.
        //
        method operator GetSoundVolume takes nothing returns integer
            return GetRandomInt(102, 127)
        endmethod
        
        //==========================================
        // Return the pitch of thunder sound.
        //
        method operator GetSoundPitch takes nothing returns real
            return GetRandomReal(0.9, 1.1)
        endmethod
    endmodule
    
    //==================================================================================================================
    
    private module Array
        private static thistype array ARRAY
        private static integer SIZE = 0
        private integer INDEX = 0
        
        static method operator size takes nothing returns integer
            return SIZE
        endmethod
        static method operator [] takes integer i returns thistype
            return ARRAY[i]
        endmethod
        
        method remove takes nothing returns nothing
            if INDEX != 0 then
                set ARRAY[SIZE].INDEX = INDEX
                set ARRAY[INDEX] = ARRAY[SIZE]
                set ARRAY[SIZE] = 0
                set INDEX = 0
                set SIZE = SIZE - 1
            endif
        endmethod
        
        method add takes nothing returns nothing
            if INDEX == 0 then
                set SIZE = SIZE + 1
                set INDEX = SIZE
                set ARRAY[SIZE] = this
            endif
        endmethod
    endmodule
    
    private struct TStorm
        implement Array
        implement Settings
        
        private static boolean TempTF         = TF
        private static integer TempTF_style   = TF_style
        private static real    TempTF_zstart  = TF_zstart
        private static real    TempTF_zend    = TF_zend
        private static real    TempTF_density = TF_density
        private static real    TempTF_red     = TF_red
        private static real    TempTF_green   = TF_green
        private static real    TempTF_blue    = TF_blue
        
        private static timer Timer = CreateTimer()
        
        private unit    Unit
        private effect  Effect
        private real    Time
        private boolean Mode
        private boolean Local
        
        private method toCamera takes nothing returns nothing
            call SetUnitX(.Unit, GetCameraTargetPositionX())
            call SetUnitY(.Unit, GetCameraTargetPositionY())
        endmethod
        
        method destroy takes nothing returns nothing
            call this.remove()
            // --------------------
            call .toCamera()
            call DestroyEffect(.Effect)
            call KillUnit(.Unit)
            set .Effect = null
            set .Unit = null
            // --------------------
            call this.deallocate()
        endmethod
        
        private method Function takes nothing returns nothing
            local sound s
            call .toCamera()
            set .Time = .Time - PERIOD
            if .Time <= 0 then
                if .Current > 0 and .Current <= .Count then
                    if not .Mode then
                        set .Mode = true
                        set .Time = .GetPlayDuration
                        set .LIndex = .GetLightningIndex
                        if .Local then
                            set .Effect = AddSpecialEffectTarget(LightningPath[.LIndex], .Unit, "origin")
                        else
                            set .Effect = AddSpecialEffectTarget("", .Unit, "origin")
                        endif
                    else
                        set .Mode = false
                        set .Time = .GetStopDuration
                        set .Current = .Current + 1
                        if .Current > .Count then
                            set .Current = 0
                            set .Time = .GetSoundDelay
                        endif
                        call DestroyEffect(.Effect)
                        set .Effect = null
                    endif
                elseif .Current == 0 then
                    set .TIndex = .GetThunderIndex
                    if .Local then
                        set s = CreateSound(ThunderPath[.TIndex], false, false, false, 10, 10, "DoodadsEAX")
                        call SetSoundChannel(s, 10)
                    else
                        set s = CreateSound("", false, false, false, 10, 10, "")
                        call SetSoundChannel(s, -1)
                    endif
                    call SetSoundVolume(s, .GetSoundVolume)
                    call SetSoundPitch(s, .GetSoundPitch)
                    call StartSound(s)
                    call KillSoundWhenDone(s)
                    set s = null
                    call this.destroy()
                endif
            endif
        endmethod
        
        private static method Periodic takes nothing returns nothing
            local real li
            local real zs = TF_zstart
            local real ze = TF_zend
            local real d  = TF_density
            local real r  = TF_red
            local real g  = TF_green
            local real b  = TF_blue
            local integer i = thistype.size
            loop
                exitwhen i <= 0
                call thistype[i].Function()
                if TF and thistype[i] > 0 and thistype[i].Current > 0 and thistype[i].Mode and thistype[i].Local then
                    set li = L_intensity[thistype[i].LIndex]
                    if USE_zstart then
                        set zs = RMaxBJ(zs, TF_zstart*(1 + li))
                    endif
                    if USE_zend then
                        set ze = RMaxBJ(ze, TF_zend*(1 + li))
                    endif
                    if USE_density then
                        set d  = RMinBJ(d, TF_density/(1 + li))
                    endif
                    if USE_color then
                        set r  = RMinBJ(1, r + L_red[thistype[i].LIndex]*li)
                        set g  = RMinBJ(1, g + L_green[thistype[i].LIndex]*li)
                        set b  = RMinBJ(1, b + L_blue[thistype[i].LIndex]*li)
                    endif
                endif
                set i = i - 1
            endloop
            if TF then
                if TempTF         != TF         or /*
                */ TempTF_style   != TF_style   or /*
                */ TempTF_zstart  != zs         or /*
                */ TempTF_zend    != ze         or /*
                */ TempTF_density != d          or /*
                */ TempTF_red     != r          or /*
                */ TempTF_green   != g          or /*
                */ TempTF_blue    != b          then
                    set TempTF_style   = TF_style
                    set TempTF_zstart  = zs
                    set TempTF_zend    = ze
                    set TempTF_density = d
                    set TempTF_red     = r
                    set TempTF_green   = g
                    set TempTF_blue    = b
                    call SetTerrainFogEx(TF_style, zs, ze, d, r, g, b)
                endif
            elseif TempTF != TF then
                call ResetTerrainFog()
            endif
            set TempTF = TF
        endmethod
        
        static method create takes integer variant, integer count, integer azimuth, integer zenith, boolean localplayer returns thistype
            local thistype this = thistype.allocate()
            // --------------------
            set .Variant = variant
            set .Count = count
            set .Current = 1
            set .Azimuth = azimuth
            set .Zenith = zenith
            set .Local = localplayer
            set .Time = 0
            set .Mode = false
            set .Unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_ID, 0, 0, azimuth)
            call SetUnitAnimationByIndex(.Unit, zenith + 90)
            // --------------------
            call this.add()
            return this
        endmethod
        
        private static method onInit takes nothing returns nothing
            call TimerStart(Timer, PERIOD, true, function thistype.Periodic)
        endmethod
    endstruct
    
    //==================================================================================================================
    
    //==========================================
    // Imitate storm with local player:
    //   variant     - Storm variation           (from 1 to VAR_COUNT)
    //   count       - Number of light flashes   (from 1 to ...)
    //   azimuth     - Horizontal light angle    (from -180 to 180)
    //   zenith      - Vertical light angle      (from -90 to 90)
    //   localplayer - Logical expression
    //
    public function ImitateLocal takes integer variant, integer count, integer azimuth, integer zenith, boolean localplayer returns nothing
        if variant > 0 and variant <= VAR_COUNT and count > 0 then
            call TStorm.create(variant, count, azimuth, zenith, localplayer)
        endif
    endfunction
    
    //==========================================
    // Imitate randomized storm with local player:
    //   variant     - Storm variation           (from 1 to VAR_COUNT)
    //   localplayer - Logical expression
    //
    public function ImitateRandomLocal takes integer variant, boolean localplayer returns nothing
        call ImitateLocal(variant, GetRandomInt(2, 4), GetRandomInt(-180, 180), GetRandomInt(-90, -30), localplayer)
    endfunction
    
    //==========================================
    // Imitate storm:
    //   variant - Storm variation           (from 1 to VAR_COUNT)
    //   count   - Number of light flashes   (from 1 to ...)
    //   azimuth - Horizontal light angle    (from -180 to 180)
    //   zenith  - Vertical light angle      (from -90 to 90)
    //
    public function Imitate takes integer variant, integer count, integer azimuth, integer zenith returns nothing
        call ImitateLocal(variant, count, azimuth, zenith, true)
    endfunction
    
    //==========================================
    // Imitate randomized storm:
    //   variant - Storm variation           (from 1 to VAR_COUNT)
    //
    public function ImitateRandom takes integer variant returns nothing
        call ImitateRandomLocal(variant, true)
    endfunction

endlibrary