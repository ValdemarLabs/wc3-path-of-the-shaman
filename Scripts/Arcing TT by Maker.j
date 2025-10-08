// Arcing Text Tag v1.0.2.0 by Maker with added API by Bribe and features proposed by Ugabunda and Kusanagi Kuro
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
        private constant    real    SIZE_MIN        = 0.018         // Minimum size of text
        private constant    real    SIZE_BONUS      = 0.012         // Text size increase
        private constant    real    TIME_LIFE       = 1.0           // How long the text lasts
        private constant    real    TIME_FADE       = 0.8           // When does the text start to fade
        private constant    real    Z_OFFSET        = 50            // Height above unit
        private constant    real    Z_OFFSET_BON    = 50            // How much extra height the text gains
        private constant    real    VELOCITY        = 2             // How fast the text move in x/y plane
        private constant    real    ANGLE           = bj_PI/2       // Movement angle of the text. Does not apply if
                                                                    // ANGLE_RND is true
        private constant    boolean ANGLE_RND       = true          // Is the angle random or fixed
        private             timer   TMR             = CreateTimer()
    endglobals
    
    struct ArcingTextTag extends array        
        private texttag tt
        private real as         // angle, sin component
        private real ac         // angle, cos component
        private real t          // time
        private real x          // origin x
        private real y          // origin y
        private string s        // text
        private static integer array next
        private static integer array prev
        private static integer array rn
        private static integer ic           = 0       // Instance count   
        
        private real scale
        private real timeScale
        
        public static thistype lastCreated = 0
        
        private static method update takes nothing returns nothing
            local thistype this=next[0]
            local real p
            loop
                set p = Sin(bj_PI*(.t / timeScale))
                set .t = .t - 0.03125
                set .x = .x + .ac
                set .y = .y + .as
                call SetTextTagPos(.tt, .x, .y, Z_OFFSET + Z_OFFSET_BON*p)
                call SetTextTagText(.tt, .s, (SIZE_MIN + SIZE_BONUS*p)*.scale)
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
        
        public static method createEx takes string s, unit u, real duration, real size, player p returns thistype
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
            
            if IsUnitVisible(u, p) then
                set .tt = CreateTextTag()
                call SetTextTagPermanent(.tt, false)
                call SetTextTagLifespan(.tt, TIME_LIFE*duration)
                call SetTextTagFadepoint(.tt, TIME_FADE*duration)
                call SetTextTagText(.tt, s, SIZE_MIN*size)
                call SetTextTagPos(.tt, .x, .y, Z_OFFSET)
            else
                set .tt = null
            endif
            
            if prev[this] == 0 then
                call TimerStart(TMR, 0.03125, true, function thistype.update)
            endif
            
            set .lastCreated = this
            
            return this
        endmethod
        public static method create takes string s, unit u returns thistype
            return thistype.createEx(s, u, TIME_LIFE, 1.00, GetLocalPlayer())
        endmethod
    endstruct
endlibrary