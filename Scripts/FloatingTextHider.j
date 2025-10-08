library FloatingTextHider initializer Init

globals
    private constant real CHECK_PERIOD   = 0.10   // seconds between checks
    private constant real MAX_DISTANCE   = 1200.0 // max visible distance
    private constant integer MAX_TAGS    = 8192   // safety cap

    private texttag array tagArray
    private real array tagX
    private real array tagY
    private player array tagOwner
    private integer tagCount = 0
endglobals


//==================================================
// Register a texttag with its position + owner
//==================================================
function RegisterFloatingText takes texttag t, real x, real y, player whichPlayer returns nothing
    if tagCount < MAX_TAGS then
        set tagCount = tagCount + 1
        set tagArray[tagCount] = t
        set tagX[tagCount] = x
        set tagY[tagCount] = y
        set tagOwner[tagCount] = whichPlayer
    endif
endfunction


//==================================================
// Periodically hide/show text depending on distance
//==================================================
private function Periodic takes nothing returns nothing
    local integer i = 1
    local player p
    local real dx
    local real dy
    local real dist
    
    loop
        exitwhen i > tagCount
        
        set p = tagOwner[i]
        set dx = tagX[i] - GetCameraTargetPositionX()
        set dy = tagY[i] - GetCameraTargetPositionY()
        set dist = SquareRoot(dx*dx + dy*dy)

        if dist > MAX_DISTANCE then
            call SetTextTagVisibility(tagArray[i], false)
        else
            call SetTextTagVisibility(tagArray[i], true)
        endif
        
        set i = i + 1
    endloop
endfunction


//==================================================
// Init
//==================================================
private function Init takes nothing returns nothing
    call TimerStart(CreateTimer(), CHECK_PERIOD, true, function Periodic)
endfunction

endlibrary
