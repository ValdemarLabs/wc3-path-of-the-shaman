// Floating Text Simple v1.0
// Non-arcing simplified version of FloatingTextArc
// - color-aware creation
// - owner visibility checks (per-player visibility)
// - lastCreated, scaling, timeScaling fields retained
// - uses SetTextTagVelocity for simple upwards floating
// - boolean to control if we want the text to drift upwards or not
// - boolean to control if we want the text to follow the unit
library FloatingTextSimple
    globals
        private constant real SIZE_MIN     = 0.018
        private constant real SIZE_BONUS   = 0.012   // unused for linear but kept for compatibility
        private constant real TIME_LIFE    = 1.0
        private constant real TIME_FADE    = 0.8
        private constant real Z_OFFSET     = 50
        private constant real MAX_DISTANCE = 2500.0
        private             timer TMR     = CreateTimer()
        private             location LOC = Location(0.0, 0.0)

    endglobals

    // Efficient helper to get terrain Z without leaks
    private function GetWorldZ takes real x, real y returns real
        call MoveLocation(LOC, x, y)
        return GetLocationZ(LOC)
    endfunction

    struct FloatingTextTag extends array
        private texttag tt
        private real t           // remaining life (internal timer)
        private real x
        private real y
        private string s
        private player owner
        private real r
        private real g
        private real b
        private unit u   
        private boolean floatUp
        private boolean followUnit

        private static integer array next
        private static integer array prev
        private static integer array rn
        private static integer ic = 0

        private real scale
        private real timeScale
        public static thistype lastCreated = 0

        // Called every tick to update visibility and cleanup
        private static method update takes nothing returns nothing
            local thistype this = next[0]
            local real camX = GetCameraEyePositionX()
            local real camY = GetCameraEyePositionY()
            local real camZ = GetCameraEyePositionZ()
            local real z
            local real dx
            local real dy
            local real dz
            local real dist
            loop
                // Decrement life
                set .t = .t - 0.03125

                // If texttag exists, perform per-frame visibility check & color/size refresh (keeps consistency)
                if .tt != null then
                    // Update size (in case scale or lifetime affects it) - use a simple linear scale with remaining life
                    call SetTextTagText(.tt, .s, SIZE_MIN * .scale)

                    // Position's height is controlled by engine via SetTextTagVelocity - still useful to compute true 3D visibility
                    if .followUnit and .u != null then
                        set .x = GetUnitX(u)
                        set .y = GetUnitY(u)
                    endif

                    set z = GetWorldZ(.x, .y) + Z_OFFSET
                    call SetTextTagPos(.tt, .x, .y, z)
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

                // Cleanup expired tex tag
                if .t <= 0.0 then
                    set .tt = null
                    // remove from linked list pool
                    set next[prev[this]] = next[this]
                    set prev[next[this]] = prev[this]
                    set rn[this] = rn[0]
                    set rn[0] = this
                    // if list empty, stop timer
                    if next[0] == 0 then
                        call PauseTimer(TMR)
                    endif
                endif
                set this = next[this]
                exitwhen this == 0
            endloop
        endmethod

        // color-aware create: create simple floating text that moves straight up
        public static method create takes string s, unit u, real duration, real size, player p, real rr, real gg, real bb, boolean floatUp, boolean followUnit returns thistype
            local thistype this = rn[0]
            if this == 0 then
                set ic = ic + 1
                set this = ic
            else
                set rn[0] = rn[this]
            endif

            set .scale = size
            set .timeScale = RMaxBJ(duration, 0.001)

            // insert into linked list (add to tail)
            set next[this] = 0
            set prev[this] = prev[0]
            set next[prev[0]] = this
            set prev[0] = this

            set .s = s
            set .x = GetUnitX(u)
            set .y = GetUnitY(u)
            set .t = TIME_LIFE * duration
            set .owner = p
            set .r = rr
            set .g = gg
            set .b = bb
            set .u = u
            set .floatUp = floatUp
            set .followUnit = followUnit

            // Only create visible texttag for that player if unit is visible to them
            if IsUnitVisible(u, p) then
                set .tt = CreateTextTag()
                call SetTextTagPermanent(.tt, false)
                call SetTextTagLifespan(.tt, .t)
                call SetTextTagFadepoint(.tt, TIME_FADE * duration)
                call SetTextTagText(.tt, s, SIZE_MIN * size)
                call SetTextTagPos(.tt, .x, .y, Z_OFFSET)
                call SetTextTagColor(.tt, R2I(rr * 255.0), R2I(gg * 255.0), R2I(bb * 255.0), 255)
                // Simple straight up velocity (y-axis here is engine vertical component for texttags)
                // Values used in WE community: 0.0, 0.03 is a reasonable upward speed
                if floatUp then
                    call SetTextTagVelocity(.tt, 0.0, 0.035)
                else
                    call SetTextTagVelocity(.tt, 0.0, 0.001)
                endif
            else
                set .tt = null
            endif

            // Start the global timer on first insertion
            if prev[this] == 0 then
                call TimerStart(TMR, 0.03125, true, function thistype.update)
            endif

            set .lastCreated = this
            return this
        endmethod

        // Convenience wrapper: default white text, default owner = local player
        public static method createSimple takes string s, unit u, real duration, real size, boolean floatUp, boolean followUnit returns thistype
            return thistype.create(s, u, duration, size, GetLocalPlayer(), 1.0, 1.0, 1.0, floatUp, followUnit)
        endmethod
    endstruct
endlibrary
