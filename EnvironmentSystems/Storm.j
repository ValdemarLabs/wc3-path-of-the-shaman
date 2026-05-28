library Storm initializer Init requires DNC, ZoneEvent
    
    // Storm v1.3.1
    // by OVOgenez
    // Slight modifications by Valdemar to fit PotS WeatherSystem
    
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
        // Stored fog settings (before storm effects) for restoration
        //
        private boolean StoredTF         = false        // Stored fog enabled state
        private integer StoredTF_style   = 0            // Stored fog style
        private real    StoredTF_zstart  = 1000.0       // Stored fog start Z
        private real    StoredTF_zend    = 3000.0       // Stored fog end Z
        private real    StoredTF_density = 0.0          // Stored fog density
        private real    StoredTF_red     = 0.0          // Stored fog red
        private real    StoredTF_green   = 0.0          // Stored fog green
        private real    StoredTF_blue    = 0.0          // Stored fog blue
        private boolean FogStored        = false        // Whether we have stored fog settings
        //==========================================
        
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
    // Store current fog settings before storm effects
    //
    private function StoreFogSettings takes nothing returns nothing
        if not FogStored then
            set StoredTF         = TF
            set StoredTF_style   = TF_style
            set StoredTF_zstart  = TF_zstart
            set StoredTF_zend    = TF_zend
            set StoredTF_density = TF_density
            set StoredTF_red     = TF_red
            set StoredTF_green   = TF_green
            set StoredTF_blue    = TF_blue
            set FogStored        = true
        endif
    endfunction
    
    //==========================================
    // Restore fog settings after storm effects complete
    //
    private function RestoreFogSettings takes nothing returns nothing
        if FogStored then
            set TF         = StoredTF
            set TF_style   = StoredTF_style
            set TF_zstart  = StoredTF_zstart
            set TF_zend    = StoredTF_zend
            set TF_density = StoredTF_density
            set TF_red     = StoredTF_red
            set TF_green   = StoredTF_green
            set TF_blue    = StoredTF_blue
            set FogStored  = false
            
            // Apply the restored fog settings
            if TF then
                call SetTerrainFogEx(TF_style, TF_zstart, TF_zend, TF_density, TF_red, TF_green, TF_blue)
            else
                call ResetTerrainFog()
            endif
            
            // Run zone's DNC trigger to restore zone-specific day/night cycle settings

            
            /* legacy code
            if Zones_GetCurrentZone() > 0 and Zones_GetCurrentZone() < 8192 then
                if udg_ZoneTrigger[Zones_GetCurrentZone()] != null then
                    call TriggerExecute(udg_ZoneTrigger[Zones_GetCurrentZone()])
                endif
            endif
            */
        endif

        call ZoneEvent_ApplyCurrentZoneEffects()
        call BJDebugMsg("[Storm] ZoneEvent_ApplyCurrentZoneEffects() run")

    endfunction
    
    //==========================================
    // Check if local player should see/hear storm effects
    // (only if player's selected unit is in the storm zone)
    //
    private function IsLocalPlayerInZone takes integer expectedZone returns boolean
        // Always return true if expectedZone is 0 or negative (global storm)
        if expectedZone <= 0 then
            return true
        endif
        /*
        // Only show effects if the local player's current zone matches the storm's zone
        // UNUSUED BECAUSE NO LIBRARY ACCESS????
        // return Zones_GetCurrentZone() == expectedZone
        */
        return true
    endfunction
    
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
        private static integer ActiveStorms = 0  // Track number of active storms
        
        private unit    Unit
        private effect  Effect
        private real    Time
        private boolean Mode
        private boolean Local
        private integer ZoneId  // Zone where storm is active (0 = global)
        
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
            
            // Track active storms and restore fog when last one ends
            set ActiveStorms = ActiveStorms - 1
            if ActiveStorms <= 0 then
                set ActiveStorms = 0
                call RestoreFogSettings()
            endif
            
            // Ensure zone effects are reapplied immediately after this storm ends
            call ZoneEvent_ApplyCurrentZoneEffects()
            call BJDebugMsg("[Storm] ZoneEvent_ApplyCurrentZoneEffects() run")

            call this.deallocate()
        endmethod
        
        private method Function takes nothing returns nothing
            local sound s
            local boolean showEffects = .Local and IsLocalPlayerInZone(.ZoneId)
            
            call .toCamera()
            set .Time = .Time - PERIOD
            if .Time <= 0 then
                if .Current > 0 and .Current <= .Count then
                    if not .Mode then
                        set .Mode = true
                        set .Time = .GetPlayDuration
                        set .LIndex = .GetLightningIndex
                        // Only show lightning if local player is in the zone
                        if showEffects then
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
                    // Only play thunder if local player is in the zone
                    if showEffects then
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
            local boolean applyFog
            
            loop
                exitwhen i <= 0
                call thistype[i].Function()
                
                // Only apply fog effects if local player is in the storm zone
                set applyFog = thistype[i].Local and IsLocalPlayerInZone(thistype[i].ZoneId)
                
                if TF and thistype[i] > 0 and thistype[i].Current > 0 and thistype[i].Mode and applyFog then
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
        
        static method create takes integer variant, integer count, integer azimuth, integer zenith, boolean localplayer, integer zoneId returns thistype
            local thistype this = thistype.allocate()
            // --------------------
            set .Variant = variant
            set .Count = count
            set .Current = 1
            set .Azimuth = azimuth
            set .Zenith = zenith
            set .Local = localplayer
            set .ZoneId = zoneId
            set .Time = 0
            set .Mode = false
            set .Unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_ID, 0, 0, azimuth)
            call SetUnitAnimationByIndex(.Unit, zenith + 90)
            // --------------------
            
            // Store fog settings when first storm is created
            if ActiveStorms == 0 then
                call StoreFogSettings()
            endif
            set ActiveStorms = ActiveStorms + 1
            
            call this.add()
            // Notify DNC that a storm has started (DNC_Storm in DNC.j)
            call DNC_Storm()
            return this
        endmethod
        
        private static method onInit takes nothing returns nothing
            call TimerStart(Timer, PERIOD, true, function thistype.Periodic)
        endmethod
    endstruct
    
    //==================================================================================================================
    
    //==========================================
    // Imitate storm with local player and zone:
    //   variant     - Storm variation           (from 1 to VAR_COUNT)
    //   count       - Number of light flashes   (from 1 to ...)
    //   azimuth     - Horizontal light angle    (from -180 to 180)
    //   zenith      - Vertical light angle      (from -90 to 90)
    //   localplayer - Logical expression
    //   zoneId      - Zone ID (0 = global, >0 = specific zone from udg_ZoneCurrent)
    //
    public function ImitateLocalZone takes integer variant, integer count, integer azimuth, integer zenith, boolean localplayer, integer zoneId returns nothing
        if variant > 0 and variant <= VAR_COUNT and count > 0 then
            call TStorm.create(variant, count, azimuth, zenith, localplayer, zoneId)
        endif
    endfunction
    
    //==========================================
    // Imitate storm with local player (legacy - uses current zone):
    //   variant     - Storm variation           (from 1 to VAR_COUNT)
    //   count       - Number of light flashes   (from 1 to ...)
    //   azimuth     - Horizontal light angle    (from -180 to 180)
    //   zenith      - Vertical light angle      (from -90 to 90)
    //   localplayer - Logical expression
    //
    public function ImitateLocal takes integer variant, integer count, integer azimuth, integer zenith, boolean localplayer returns nothing
        //call ImitateLocalZone(variant, count, azimuth, zenith, localplayer, Zones_GetCurrentZone())
        // temporarily set zoneID to 1 instead of GetCurrentZone
        call ImitateLocalZone(variant, count, azimuth, zenith, localplayer, 1)
    endfunction
    
    //==========================================
    // Imitate randomized storm with local player and zone:
    //   variant     - Storm variation           (from 1 to VAR_COUNT)
    //   localplayer - Logical expression
    //   zoneId      - Zone ID (0 = global, >0 = specific zone)
    //
    public function ImitateRandomLocalZone takes integer variant, boolean localplayer, integer zoneId returns nothing
        call ImitateLocalZone(variant, GetRandomInt(2, 4), GetRandomInt(-180, 180), GetRandomInt(-90, -30), localplayer, zoneId)
    endfunction
    
    //==========================================
    // Imitate randomized storm with local player (legacy - uses current zone):
    //   variant     - Storm variation           (from 1 to VAR_COUNT)
    //   localplayer - Logical expression
    //
    public function ImitateRandomLocal takes integer variant, boolean localplayer returns nothing
        //call ImitateRandomLocalZone(variant, localplayer, Zones_GetCurrentZone())
        // temporarily set zoneID to 1 instead of GetCurrentZone
        call ImitateRandomLocalZone(variant, localplayer, 1)
    endfunction
    
    //==========================================
    // Imitate storm with zone:
    //   variant - Storm variation           (from 1 to VAR_COUNT)
    //   count   - Number of light flashes   (from 1 to ...)
    //   azimuth - Horizontal light angle    (from -180 to 180)
    //   zenith  - Vertical light angle      (from -90 to 90)
    //   zoneId  - Zone ID (0 = global, >0 = specific zone)
    //
    public function ImitateZone takes integer variant, integer count, integer azimuth, integer zenith, integer zoneId returns nothing
        call ImitateLocalZone(variant, count, azimuth, zenith, true, zoneId)
    endfunction
    
    //==========================================
    // Imitate storm (legacy - uses current zone):
    //   variant - Storm variation           (from 1 to VAR_COUNT)
    //   count   - Number of light flashes   (from 1 to ...)
    //   azimuth - Horizontal light angle    (from -180 to 180)
    //   zenith  - Vertical light angle      (from -90 to 90)
    //
    public function Imitate takes integer variant, integer count, integer azimuth, integer zenith returns nothing
        //call ImitateLocalZone(variant, count, azimuth, zenith, true, Zones_GetCurrentZone())
        // temporarily set zoneID to 1 instead of GetCurrentZone
        call ImitateLocalZone(variant, count, azimuth, zenith, true, 1)
    endfunction
    
    //==========================================
    // Imitate randomized storm with zone:
    //   variant - Storm variation           (from 1 to VAR_COUNT)
    //   zoneId  - Zone ID (0 = global, >0 = specific zone)
    //
    public function ImitateRandomZone takes integer variant, integer zoneId returns nothing
        call ImitateRandomLocalZone(variant, true, zoneId)
    endfunction
    
    //==========================================
    // Imitate randomized storm (legacy - uses current zone):
    //   variant - Storm variation           (from 1 to VAR_COUNT)
    //
    public function ImitateRandom takes integer variant returns nothing
        //call ImitateRandomLocalZone(variant, true, Zones_GetCurrentZone())
        // temporarily set zoneID to 1 instead of GetCurrentZone
        call ImitateRandomLocalZone(variant, true, 1)
    endfunction

endlibrary