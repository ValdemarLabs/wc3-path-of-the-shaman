
library DialogCamera initializer Init
//===========================================================================
/*
    DialogCamera 

    Author: [Valdemar]

    Description:
    A simple dialog camera system for Warcraft III that focuses the camera on a specified NPC unit.
    It allows setting distance, height offset, angle, rotation, far clipping plane, and field of view.
    It also saves and restores the player's original camera settings.
    
    Usage:
        call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck)

    Params for DialogCameraStart:
      p             - Player to affect
      u             - Target NPC unit
      dist          - Distance from NPC (default 1200 if <= 0)
      zOffset       - Vertical offset above terrain (default 350 if <= 0)
      angle   - Pitch (Angle of Attack) adjustment (default 0)
      rotationOffset- Yaw (Rotation) adjustment (default 0)
      farZ          - Far clipping plane (default 1000 if <= 0)
      fov           - Field of View (default 60 if <= 0)
    

    EXAMPLES: Start dialog camera on Player 1, targeting udg_DialogNPC unit
        // use system default radius (BLOCK_RADIUS = 350.0)
        call DialogCameraStart(Player(0), u, 1000.0, 400.0, 15.0, 30.0, 1200.0, 70.0, 0.0, true)

        // provide custom radius of 500
        call DialogCameraStart(Player(0), u, 1000.0, 400.0, 15.0, 30.0, 1200.0, 70.0, 500.0, true)

        // disable blocking entirely
        call DialogCameraStart(Player(0), u, 1000.0, 400.0, 15.0, 30.0, 1200.0, 70.0, 0.0, false)

        // To restore original camera:
            call DialogCameraReset(p, duration) to restore original camera over 'duration' seconds
            call DialogCameraReset(Player(0), 2.0)

Note: Ensure the target unit is valid and alive before calling DialogCameraStart.
*/ 
//===========================================================================

globals
    private constant real DEFAULT_DISTANCE       = 1200.0
    private constant real DEFAULT_ZOFFSET        = 350.0
    private constant real DEFAULT_FOV            = 60.0
    private constant real DEFAULT_FARZ           = 1000.0
    private constant real DEFAULT_ANGLE          = 340.0
    private constant real DEFAULT_ROTATIONOFFSET = 0.0
    private constant real DEFAULT_NEARZ          = 20.0
    private constant real DEFAULT_CAMTIME        = 0.0

    private constant real DEFAULT_BLOCK_RADIUS   = 350.0    // how close a destructible must be to count as blocking; default 350
    private constant real BLOCK_SCANRANGE        = 200.0    // how far around the check point to scan for destructibles

    private camerasetup array savedCamera // per-player restore setups

    // internal vars for blocking checks
    private real CAMERA_CHECKX
    private real CAMERA_CHECKY
    private real CAMERA_TMPRADIUS
    private boolean CAMERA_BLOCKED

endglobals

//===========================================================================
// Internal: returns terrain-corrected Z height
//===========================================================================
private function GetSafeZ takes real x, real y, real offset returns real
    local location loc = Location(x, y)
    local real terrainZ = GetLocationZ(loc)
    call RemoveLocation(loc)
    return terrainZ + offset
endfunction

//===========================================================================
// Helper: Check destructibles near a point ===
//===========================================================================
private function CameraCheckDestructableEnum takes nothing returns nothing
    local destructable d = GetEnumDestructable()
    local real dx = GetDestructableX(d) - CAMERA_CHECKX
    local real dy = GetDestructableY(d) - CAMERA_CHECKY
    if dx*dx + dy*dy < CAMERA_TMPRADIUS*CAMERA_TMPRADIUS then
        set CAMERA_BLOCKED = true
    endif
    set d = null
endfunction

//===========================================================================
// === Check if camera is blocked by destructibles in forward line ===
//===========================================================================
private function IsCameraBlocked takes real x, real y, real rotation, real distance, real radius returns boolean
    local real checkX = x + distance * Cos(rotation * bj_DEGTORAD) // Forward point in the direction of rotation
    local real checkY = y + distance * Sin(rotation * bj_DEGTORAD)
    local rect r

    set CAMERA_CHECKX = checkX
    set CAMERA_CHECKY = checkY
    set CAMERA_TMPRADIUS = radius   //  how close a destructible must be to count as blocking
    set CAMERA_BLOCKED = false      // reset before scan

    // Scan a rect around the point to find destructibles
    set r = Rect(checkX - radius, checkY - radius, checkX + radius, checkY + radius)
    call EnumDestructablesInRect(r, null, function CameraCheckDestructableEnum)
    call RemoveRect(r)

    return CAMERA_BLOCKED
endfunction

//===========================================================================
// Start dialog camera for one player
//===========================================================================
function DialogCameraStart takes player p, unit u, real dist, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius, boolean doBlockCheck returns nothing
    local integer pid
    local real x
    local real y
    local real anglevar
    local real camX
    local real camY
    local real camZ
    local real finalRot
    local real finalPitch
    local real nearz
    local boolean blocked

    // Validate inputs  
    if (u == null) or (p == null) then
        return
    endif

    // Get player ID
    set pid = GetPlayerId(p)

    // Apply defaults
    if dist <= 0 then
        set dist = DEFAULT_DISTANCE
    endif

    if zOffset <= 0 then
        set zOffset = DEFAULT_ZOFFSET
    endif

    if fov <= 0 then
        set fov = DEFAULT_FOV
    endif

    if farZ <= 0 then
        set farZ = DEFAULT_FARZ
    endif

    if angle == 0 then
        set angle = DEFAULT_ANGLE
    endif

    if rotationOffset == 0 then
        set rotationOffset = DEFAULT_ROTATIONOFFSET
    endif

    if blockRadius <= 0 then
        set blockRadius = DEFAULT_BLOCK_RADIUS
    endif

    set nearz = DEFAULT_NEARZ

   // Save current camera settings
    set savedCamera[pid] = GetCurrentCameraSetup()

    // pan to unit position
    set x = GetUnitX(u)
    set y = GetUnitY(u)
    call PanCameraToTimedForPlayer(p, x, y, DEFAULT_CAMTIME)

    // Safe Z for terrain/cliffs
    set camZ = GetSafeZ(x, y, zOffset)

    // Calculate camera position based on angle and distance
    set finalRot   = GetUnitFacing(u) + rotationOffset
    set finalPitch = angle

     // Check if blocked → flip rotation
    if doBlockCheck then
        set blocked = IsCameraBlocked(x, y, finalRot, dist, blockRadius)
        if blocked then
            // flip camera 180 degrees
            set finalRot = finalRot + 180.0
        endif
    endif

    // Apply to this player only (Blizzard.j wrappers)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_TARGET_DISTANCE, dist,       DEFAULT_CAMTIME)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_FARZ,            farZ,       DEFAULT_CAMTIME)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_FIELD_OF_VIEW,   fov,        DEFAULT_CAMTIME)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_ANGLE_OF_ATTACK, finalPitch, DEFAULT_CAMTIME)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_ROTATION,        finalRot,   DEFAULT_CAMTIME)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_ZOFFSET,         zOffset,    DEFAULT_CAMTIME)
    call SetCameraFieldForPlayer(p, CAMERA_FIELD_NEARZ,           nearz,      DEFAULT_CAMTIME)

endfunction

//===========================================================================
// Reset dialog camera for one player
//===========================================================================
function DialogCameraReset takes player p, real duration returns nothing
    local integer pid
    if p == null then
        return
    endif
    set pid = GetPlayerId(p)

    if savedCamera[pid] != null then
        // Smooth restore using BJ helper (per-player safe)
        call CameraSetupApplyForPlayer(true, savedCamera[pid], p, duration)

        // If you want a hard "force" restore instead, use this local block:
        // if GetLocalPlayer() == p then
        //     call CameraSetupApplyForceDuration(savedCamera[pid], true, duration)
        // endif

        // Drop reference so GC can reclaim it when appropriate
        set savedCamera[pid] = null
    endif
endfunction

//===========================================================================
private function Init takes nothing returns nothing
endfunction

endlibrary
