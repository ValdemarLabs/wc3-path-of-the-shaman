// Arcing Text Tag v1.0.2.0 by Maker with added API by Bribe and features proposed by Ugabunda and Kusanagi Kuro
// Modified by Valdermar to include visibility check and owner tracking (angled camera purpose) + color-aware creation
// 
// Added API in 1.0.1.0:
//   public static ArcingTextTag lastCreated
//   - Get the last created ArcingTextTag
//   public real scaling
//   - Set the size ratio of the texttag - 1.00 is the default
//   public real timeScaling
//   - Set the duration ratio of the texttag - 1.00 is the default
library FloatingTextArc
    globals
        private constant    real    SIZE_MIN        = 0.018             // Minimum size of text
        private constant    real    SIZE_BONUS      = 0.012             // Text size increase
        private constant    real    TIME_LIFE       = 1.0               // How long the text lasts
        private constant    real    TIME_FADE       = 0.8               // When does the text start to fade
        private constant    real    Z_OFFSET        = 50                // Height above unit
        private constant    real    Z_OFFSET_BON    = 50                // How much extra height the text gains
        private constant    real    VELOCITY        = 2                 // How fast the text move in x/y plane
        private constant    real    ANGLE           = bj_PI/2           // Movement angle of the text. Does not apply if
                                                                        // ANGLE_RND is true
        private constant    boolean ANGLE_RND       = true  
        private constant    real    MAX_DISTANCE    = 2500.0             // NEW: text cutoff distance
        private             timer   TMR             = CreateTimer()
        private             location LOC            = Location(0.0, 0.0) // Reusable global location
    endglobals
    
    // Efficient helper to get terrain Z without leaks
    private function GetWorldZ takes real x, real y returns real
        call MoveLocation(LOC, x, y)
        return GetLocationZ(LOC)
    endfunction

    struct ArcingTextTag extends array        
        private texttag tt
        private real as         // angle, sin component
        private real ac         // angle, cos component
        private real t          // time
        private real x          // origin x
        private real y          // origin y
        private string s        // text
        private player owner    // NEW: store owning player
        private real r          // color red
        private real g          // color green
        private real b          // color blue
        private static integer array next
        private static integer array prev
        private static integer array rn
        private static integer ic = 0    // Instance count
        
        private real scale
        private real timeScale
        
        public static thistype lastCreated = 0  
        
        private static method update takes nothing returns nothing
            local thistype this = next[0]
            local real p
            local real dx
            local real dy
            local real dz
            local real z
            local real dist
            local real camX = GetCameraEyePositionX()
            local real camY = GetCameraEyePositionY()
            local real camZ = GetCameraEyePositionZ()
            loop
                set p = Sin(bj_PI*(.t / timeScale))
                set .t = .t - 0.03125
                set .x = .x + .ac
                set .y = .y + .as

                if .tt != null then
                    // Position and visual update
                    call SetTextTagPos(.tt, .x, .y, Z_OFFSET + Z_OFFSET_BON * p)
                    call SetTextTagText(.tt, .s, (SIZE_MIN + SIZE_BONUS * p) * .scale)
                    call SetTextTagColor(.tt, R2I(.r * 255), R2I(.g * 255), R2I(.b * 255), 255)

                    // === True 3D visibility check ===
                    set z = GetWorldZ(.x, .y) + Z_OFFSET + Z_OFFSET_BON * p
                    set dx = .x - camX
                    set dy = .y - camY
                    set dz = z - camZ
                    set dist = dx*dx + dy*dy + dz*dz

                    if dist > MAX_DISTANCE * MAX_DISTANCE then
                        call SetTextTagVisibility(.tt, false)
                    else
                        call SetTextTagVisibility(.tt, true)
                    endif
                endif
                // ============================
                // Cleanup expired text tags
                if .t <= 0 then
                    set .tt = null
                    set next[prev[this]] = next[this]
                    set prev[next[this]] = prev[this]
                    set rn[this] = rn[0]
                    set rn[0] = this
                    if next[0]==0 then
                        call PauseTimer(TMR)
                    endif
                endif
                set this = next[this]
                exitwhen this == 0
            endloop
        endmethod
        
        // NEW: color-aware creation
        public static method createEx takes string s, unit u, real duration, real size, player p, real r, real g, real b returns thistype
            local thistype this = rn[0]
            static if ANGLE_RND then
                local real a = GetRandomReal(0, 2*bj_PI)
            else
                local real a = ANGLE
            endif
            if this == 0 then
                set ic = ic + 1
                set this = ic
            else
                set rn[0] = rn[this]
            endif
            
            set .scale = size
            set .timeScale = RMaxBJ(duration, 0.001)

            set next[this] = 0
            set prev[this] = prev[0]
            set next[prev[0]] = this
            set prev[0] = this

            set .s = s
            set .x = GetUnitX(u)
            set .y = GetUnitY(u)
            set .t = TIME_LIFE
            set .as = Sin(a)*VELOCITY
            set .ac = Cos(a)*VELOCITY
            set .owner = p
            set .r = r
            set .g = g
            set .b = b
            
            if IsUnitVisible(u, p) then
                set .tt = CreateTextTag()
                call SetTextTagPermanent(.tt, false)
                call SetTextTagLifespan(.tt, TIME_LIFE*duration)
                call SetTextTagFadepoint(.tt, TIME_FADE*duration)
                call SetTextTagText(.tt, s, SIZE_MIN*size)
                call SetTextTagPos(.tt, .x, .y, Z_OFFSET)
                call SetTextTagColor(.tt, R2I(r*255), R2I(g*255), R2I(b*255), 255)
            else
                set .tt = null
            endif
            
            if prev[this] == 0 then
                call TimerStart(TMR, 0.03125, true, function thistype.update)
            endif
            
            set .lastCreated = this
            return this
        endmethod
        
        // Old signature, default white text
        public static method create takes string s, unit u, real duration, real size, player p returns thistype
            return thistype.createEx(s, u, duration, 1.0, GetLocalPlayer(), 1.0, 1.0, 1.0)
        endmethod

        // New simple floating text API
        public static method createLinear takes string s, unit u, real duration, real size, player p, real r, real g, real b returns thistype
            local thistype this = rn[0]

            if this == 0 then
                set ic = ic + 1
                set this = ic
            else
                set rn[0] = rn[this]
            endif

            set .scale = size
            set .timeScale = RMaxBJ(duration, 0.001)

            set next[this] = 0
            set prev[this] = prev[0]
            set next[prev[0]] = this
            set prev[0] = this

            set .s = s
            set .x = GetUnitX(u)
            set .y = GetUnitY(u)
            set .t = TIME_LIFE
            set .as = 0.00          // no sideways movement
            set .ac = 0.00
            set .owner = p
            set .r = r
            set .g = g
            set .b = b

            if IsUnitVisible(u, p) then
                set .tt = CreateTextTag()
                call SetTextTagPermanent(.tt, false)
                call SetTextTagLifespan(.tt, TIME_LIFE*duration)
                call SetTextTagFadepoint(.tt, TIME_FADE*duration)
                call SetTextTagText(.tt, s, SIZE_MIN*size)
                call SetTextTagPos(.tt, .x, .y, Z_OFFSET)
                call SetTextTagColor(.tt, R2I(r*255), R2I(g*255), R2I(b*255), 255)
                call SetTextTagVelocity(.tt, 0.0, 0.035) // 90° upwards
            else
                set .tt = null
            endif

            if prev[this] == 0 then
                call TimerStart(TMR, 0.03125, true, function thistype.update)
            endif

            set .lastCreated = this
            return this
        endmethod
    endstruct
endlibrary