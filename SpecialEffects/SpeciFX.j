/*
//==============================================================================
// SpeciFX System v1.2
//==============================================================================
A simple special effects library for creating and managing special effects on units and points with extended control options.

Author: [Valdemar]

Features:
 - Create effects on units with attachment points
 - Create effects on points/locations
 - Support for scale, height, and XYZ offsets
 - Terrain-aligned special effects (by Antares - Hiveworkshop)
 - Automatic cleanup on unit death
 - Ignores FollowSystem and QuestIconSystem effects when destroying
 - Uses Bribe's Table library for data storage

 API:
 - void SpeciFX_AddToUnit(unit, string effectPath, string attachPoint, string tag)
 - void SpeciFX_AddToUnitEx(unit, string effectPath, string attachPoint, string tag, real scale, real height, real offsetX, real offsetY, real offsetZ)
 - void SpeciFX_AddToPoint(real x, real y, string effectPath, string tag)
 - void SpeciFX_AddToPointEx(real x, real y, string effectPath, string tag, real scale, real height, real offsetZ)
 - void SpeciFX_AddToLocation(location whichLoc, string effectPath, string tag)
 - void SpeciFX_AddToLocationEx(location whichLoc, string effectPath, string tag, real scale, real height, real offsetZ)
 - void SpeciFX_Duration(real duration) - destroys the latest created SpeciFX/GUI effect after duration
 - void SpeciFX_DestroyTimed(effect whichEffect, real duration) - explicit timed destroy for any effect handle
 - void SpeciFX_RemoveFromUnit(unit, string tag) - removes specific tagged effect
 - void SpeciFX_RemoveAllFromUnit(unit) - removes all effects except FollowSystem/QuestIconSystem
 - void SpeciFX_RemoveByTag(string tag) - removes all effects with this tag
 - void SpeciFX_SetScaleOnUnit(unit, string tag, real scale)
 - void SpeciFX_SetHeightOnUnit(unit, string tag, real height)
 - void SpeciFX_ConfigureEffect(unit, string tag, integer red, integer green, integer blue, integer alpha, animtype whichAnim, real orientation, real pitch, real yaw, real roll, real timeScale, real time)
   Optional configurational API - use -1 for any parameter to skip modification (use null for animtype to skip)

    === Terrain Alignment API (by Antares) ===
    https://www.hiveworkshop.com/threads/terrain-aligned-special-effect.358171/
    - effect SpeciFX_AddTerrainAligned(string effectPath, real x, real y, real yaw)
    Creates effect aligned to terrain slope with facing angle (yaw in radians)
    - void SpeciFX_AlignToTerrain(effect whichEffect)
    Aligns existing effect to terrain at its current position
    - void SpeciFX_AddToPointTerrainAligned(real x, real y, string effectPath, string tag, real yaw)
    Creates tracked terrain-aligned effect with tag for later removal
    - void SpeciFX_AlignUnitEffectToTerrain(unit u, string tag)
    Aligns a tagged effect on unit to terrain

   ===== ===============SpeciFX_ConfigureEffect
    // Parameters:
    red, green, blue (0-255) - Color tinting
    alpha (0-255) - Transparency (255 = opaque, 0 = invisible)
    whichAnim - Animation type to play (ANIM_TYPE_BIRTH, ANIM_TYPE_DEATH, ANIM_TYPE_SPELL, etc.) - use null to skip
    orientation - Rotation around Z-axis (degrees)
    pitch - Rotation around Y-axis (degrees)
    yaw - Rotation around Z-axis (degrees)
    roll - Rotation around X-axis (degrees)
    timeScale - Animation speed multiplier (1.0 = normal, 2.0 = double speed)
    time - Jump to specific animation time (seconds)

    Use -1 (or -1.0 for reals) to skip any parameter you don't want to modify! Use null for animtype to skip.

    // Create an effect first
    call SpeciFX_AddToUnit(hero, "Abilities\\Spells\\Other\\Drain\\ManaDrainTarget.mdl", "overhead", "drain")

    // Make it red and semi-transparent
    call SpeciFX_ConfigureEffect(hero, "drain", 255, 0, 0, 128, null, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0)

    // Rotate it 90 degrees and speed up animation
    call SpeciFX_ConfigureEffect(hero, "drain", -1, -1, -1, -1, null, 90.0, -1.0, -1.0, -1.0, 2.0, -1.0)

    // Play spell animation with slow-motion
    call SpeciFX_ConfigureEffect(hero, "drain", -1, -1, -1, -1, ANIM_TYPE_SPELL, -1.0, -1.0, -1.0, -1.0, 0.5, -1.0)

    ===== Terrain Alignment Examples =====

    // Create a footprint effect that follows terrain slope facing east
    local effect footprint = SpeciFX_AddTerrainAligned("Abilities\\Spells\\Other\\Crash\\CrashingWaveDamage.mdl", x, y, 0.0)

    // Create a tracked terrain-aligned effect you can remove later
    call SpeciFX_AddToPointTerrainAligned(x, y, "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", "crater", GetUnitFacing(caster) * bj_DEGTORAD)
    // Remove it later:
    call SpeciFX_RemoveByTag("crater")

    // Align an existing effect to terrain
    local effect myEffect = AddSpecialEffect("effect.mdl", x, y)
    call SpeciFX_AlignToTerrain(myEffect)
    call SpeciFX_DestroyTimed(myEffect, 2.00)

    // Align a tagged effect on a unit to terrain
    call SpeciFX_AlignUnitEffectToTerrain(myUnit, "shadow")

    // Destroy the most recently created SpeciFX/GUI effect after 2 seconds
    call SpeciFX_Duration(2.00)

    Requirements:
    - Bribe's Table library

//==============================================================================
*/

library SpeciFX requires Table

    globals
        // Effect data storage
        private Table EffectHandle // Maps effect ID -> effect handle
        private Table EffectUnit // Maps effect -> unit
        private Table EffectType // Maps effect -> type (0=point, 1=unit)
        private Table EffectTag // Maps effect -> tag hash
        
        // Unit effect tracking
        private Table UnitEffects // Maps unit -> first effect
        private Table EffectNext // Linked list of effects per unit
        
        // Tag tracking
        private Table TagEffects // Maps tag hash -> first effect
        private Table EffectTagNext // Linked list of effects per tag
        
        // Effect exclusion lists (FollowSystem and QuestIconSystem)
        private Table ExcludedEffects // Effects that should not be destroyed
        private Table TimerEffect // Maps timer -> effect ID
        
        // Constants
        private constant integer EFFECT_TYPE_POINT = 0
        private constant integer EFFECT_TYPE_UNIT = 1
        
        // Trigger for unit death cleanup
        private trigger DeathTrigger = null
        
        // Terrain alignment helper
        private location moveableLoc = Location(0, 0)
        
        // Last created effect tracking
        private effect LastCreatedEffect = null
        private integer LastKnownBjEffectId = 0
    endglobals
    
    //==========================================================================
    // Internal Functions
    //==========================================================================
    
    // Get Z coordinate at position (Terrain height helper)
    private function GetLocZ takes real x, real y returns real
        call MoveLocation(moveableLoc, x, y)
        return GetLocationZ(moveableLoc)
    endfunction
    
    // Get hash for string tag
    private function GetTagHash takes string tag returns integer
        return StringHash(tag)
    endfunction
    
    private function IsRegisteredEffect takes effect e returns boolean
        local integer efxId = GetHandleId(e)
        return e != null and EffectHandle[efxId] == efxId and EffectHandle.effect[efxId] != null
    endfunction
    
    private function RememberCreatedEffect takes effect e returns nothing
        set LastCreatedEffect = e
        set LastKnownBjEffectId = GetHandleId(GetLastCreatedEffectBJ())
    endfunction
    
    private function GetLatestCreatedEffect takes nothing returns effect
        local effect bjEffect = GetLastCreatedEffectBJ()
        local integer bjEffectId = GetHandleId(bjEffect)
        
        if bjEffect != null and bjEffectId != LastKnownBjEffectId then
            set LastKnownBjEffectId = bjEffectId
            set LastCreatedEffect = bjEffect
        endif
        
        set bjEffect = null
        return LastCreatedEffect
    endfunction
    
    // Register an effect for tracking
    private function RegisterEffect takes effect e, unit u, integer effectType, string tag returns nothing
        local integer efxId = GetHandleId(e)
        local integer tagHash = 0
        local integer unitId = 0
        
        if e == null then
            return
        endif
        
        set EffectHandle[efxId] = efxId
        set EffectHandle.effect[efxId] = e
        set EffectType[efxId] = effectType
        call RememberCreatedEffect(e)
        
        // Store tag if provided
        if tag != null and tag != "" then
            set tagHash = GetTagHash(tag)
            set EffectTag[efxId] = tagHash
            
            // Add to tag linked list
            set EffectTagNext[efxId] = TagEffects[tagHash]
            set TagEffects[tagHash] = efxId
        endif
        
        if effectType == EFFECT_TYPE_UNIT and u != null then
            set unitId = GetHandleId(u)
            
            // Store unit reference
            set EffectUnit[efxId] = unitId
            
            // Add to linked list for this unit
            set EffectNext[efxId] = UnitEffects[unitId]
            set UnitEffects[unitId] = efxId
        endif
    endfunction
    
    // Unregister an effect
    private function UnregisterEffect takes effect e returns nothing
        local integer efxId = GetHandleId(e)
        local integer unitId = EffectUnit[efxId]
        local integer tagHash = EffectTag[efxId]
        local integer currentId
        local integer prevId = 0
        
        // Remove from unit's linked list if attached to unit
        if unitId != 0 then
            set currentId = UnitEffects[unitId]
            
            loop
                exitwhen currentId == 0
                
                if currentId == efxId then
                    // Found it, remove from list
                    if prevId == 0 then
                        set UnitEffects[unitId] = EffectNext[efxId]
                    else
                        set EffectNext[prevId] = EffectNext[efxId]
                    endif
                    
                    set EffectNext[efxId] = 0
                    exitwhen true
                endif
                
                set prevId = currentId
                set currentId = EffectNext[currentId]
            endloop
            
            set EffectUnit[efxId] = 0
        endif
        
        // Remove from tag's linked list
        if tagHash != 0 then
            set currentId = TagEffects[tagHash]
            set prevId = 0
            
            loop
                exitwhen currentId == 0
                
                if currentId == efxId then
                    // Found it, remove from list
                    if prevId == 0 then
                        set TagEffects[tagHash] = EffectTagNext[efxId]
                    else
                        set EffectTagNext[prevId] = EffectTagNext[efxId]
                    endif
                    
                    set EffectTagNext[efxId] = 0
                    exitwhen true
                endif
                
                set prevId = currentId
                set currentId = EffectTagNext[currentId]
            endloop
            
            set EffectTag[efxId] = 0
        endif
        
        set EffectType[efxId] = 0
        set ExcludedEffects[efxId] = 0
        set EffectHandle.effect[efxId] = null
    endfunction
    
    private function DestroyManagedEffect takes effect e returns nothing
        if e == null then
            return
        endif
        
        call DestroyEffect(e)
        if IsRegisteredEffect(e) then
            call UnregisterEffect(e)
        endif
    endfunction
    
    private function OnDurationExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer timerId = GetHandleId(t)
        local integer efxId = TimerEffect[timerId]
        local effect e = EffectHandle.effect[efxId]
        
        if e != null then
            call DestroyManagedEffect(e)
        endif
        
        set TimerEffect[timerId] = 0
        call DestroyTimer(t)
        set e = null
        set t = null
    endfunction
    
    // Check if effect should be excluded from destruction
    private function IsExcludedEffect takes effect e returns boolean
        return ExcludedEffects[GetHandleId(e)] == 1
    endfunction
    
    // Mark effect as excluded (for FollowSystem/QuestIconSystem)
    public function MarkAsExcluded takes effect e returns nothing
        set ExcludedEffects[GetHandleId(e)] = 1
    endfunction
    
    // Unit death cleanup
    private function OnUnitDeath takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local integer unitId = GetHandleId(u)
        local integer currentId = UnitEffects[unitId]
        local integer nextId
        local effect e
        
        // Destroy all effects on this unit (except excluded ones)
        loop
            exitwhen currentId == 0
            
            set nextId = EffectNext[currentId]
            set e = EffectHandle.effect[currentId]
            
            if e != null and not IsExcludedEffect(e) then
                call DestroyEffect(e)
                call UnregisterEffect(e)
            endif
            
            set currentId = nextId
        endloop
        
        set UnitEffects[unitId] = 0
        set u = null
    endfunction
    
    //==========================================================================
    // Public API Functions
    //==========================================================================
    
    // Add effect to unit with attachment point and optional tag
    public function AddToUnit takes unit u, string effectPath, string attachPoint, string tag returns nothing
        local effect e
        
        if u == null or effectPath == null or effectPath == "" then
            return
        endif
        
        set e = AddSpecialEffectTarget(effectPath, u, attachPoint)
        call RegisterEffect(e, u, EFFECT_TYPE_UNIT, tag)
        set e = null
    endfunction
    
    // Add effect to unit with extended options
    public function AddToUnitEx takes unit u, string effectPath, string attachPoint, string tag, real scale, real height, real offsetX, real offsetY, real offsetZ returns nothing
        local effect e
        
        if u == null or effectPath == null or effectPath == "" then
            return
        endif
        
        set e = AddSpecialEffectTarget(effectPath, u, attachPoint)
        
        if scale != 1.0 then
            call BlzSetSpecialEffectScale(e, scale)
        endif
        
        if height != 0.0 then
            call BlzSetSpecialEffectHeight(e, height)
        endif
        
        if offsetX != 0.0 or offsetY != 0.0 or offsetZ != 0.0 then
            call BlzSetSpecialEffectPosition(e, GetUnitX(u) + offsetX, GetUnitY(u) + offsetY, BlzGetLocalSpecialEffectZ(e) + offsetZ)
        endif
        
        call RegisterEffect(e, u, EFFECT_TYPE_UNIT, tag)
        set e = null
    endfunction
    
    // Add effect to point with optional tag
    public function AddToPoint takes real x, real y, string effectPath, string tag returns nothing
        local effect e
        if effectPath == null or effectPath == "" then
            return
        endif
        set e = AddSpecialEffect(effectPath, x, y)
        call RegisterEffect(e, null, EFFECT_TYPE_POINT, tag)
        set e = null
    endfunction

    // Add effect to point with extended options
    public function AddToPointEx takes real x, real y, string effectPath, string tag, real scale, real height, real offsetZ returns nothing
        local effect e
        if effectPath == null or effectPath == "" then
            return
        endif
        set e = AddSpecialEffect(effectPath, x, y)
        if scale != 1.0 then
            call BlzSetSpecialEffectScale(e, scale)
        endif
        if height != 0.0 then
            call BlzSetSpecialEffectHeight(e, height)
        endif
        if offsetZ != 0.0 then
            call BlzSetSpecialEffectPosition(e, x, y, BlzGetLocalSpecialEffectZ(e) + offsetZ)
        endif
        call RegisterEffect(e, null, EFFECT_TYPE_POINT, tag)
        set e = null
    endfunction

    // Add effect to location with optional tag
    public function AddToLocation takes location whichLoc, string effectPath, string tag returns nothing
        local effect e
        if whichLoc == null or effectPath == null or effectPath == "" then
            return
        endif
        set e = AddSpecialEffectLoc(effectPath, whichLoc)
        call RegisterEffect(e, null, EFFECT_TYPE_POINT, tag)
        set e = null
    endfunction

    // Add effect to location with extended options
    public function AddToLocationEx takes location whichLoc, string effectPath, string tag, real scale, real height, real offsetZ returns nothing
        local effect e
        local real x
        local real y
        if whichLoc == null or effectPath == null or effectPath == "" then
            return
        endif
        set x = GetLocationX(whichLoc)
        set y = GetLocationY(whichLoc)
        set e = AddSpecialEffectLoc(effectPath, whichLoc)
        if scale != 1.0 then
            call BlzSetSpecialEffectScale(e, scale)
        endif
        if height != 0.0 then
            call BlzSetSpecialEffectHeight(e, height)
        endif
        if offsetZ != 0.0 then
            call BlzSetSpecialEffectPosition(e, x, y, BlzGetLocalSpecialEffectZ(e) + offsetZ)
        endif
        call RegisterEffect(e, null, EFFECT_TYPE_POINT, tag)
        set e = null
    endfunction
    
    // Remove specific tagged effect from unit
    public function RemoveFromUnit takes unit u, string tag returns nothing
        local integer unitId
        local integer tagHash
        local integer currentId
        local integer nextId
        local effect e
        
        if u == null or tag == null or tag == "" then
            return
        endif
        
        set unitId = GetHandleId(u)
        set tagHash = GetTagHash(tag)
        set currentId = UnitEffects[unitId]
        
        loop
            exitwhen currentId == 0
            
            set nextId = EffectNext[currentId]
            
            if EffectTag[currentId] == tagHash then
                set e = EffectHandle.effect[currentId]
                if e != null and not IsExcludedEffect(e) then
                    call DestroyEffect(e)
                    call UnregisterEffect(e)
                endif
            endif
            
            set currentId = nextId
        endloop
        
        set e = null
    endfunction
    
    // Remove all effects from a unit (except excluded ones)
    public function RemoveAllFromUnit takes unit u returns nothing
        local integer unitId
        local integer currentId
        local integer nextId
        local effect e
        
        if u == null then
            return
        endif
        
        set unitId = GetHandleId(u)
        set currentId = UnitEffects[unitId]
        
        loop
            exitwhen currentId == 0
            
            set nextId = EffectNext[currentId]
            set e = EffectHandle.effect[currentId]
            
            if e != null and not IsExcludedEffect(e) then
                call DestroyEffect(e)
                call UnregisterEffect(e)
            endif
            
            set currentId = nextId
        endloop
        
        set e = null
    endfunction
    
    // Remove all effects with specific tag (across all units/points)
    public function RemoveByTag takes string tag returns nothing
        local integer tagHash
        local integer currentId
        local integer nextId
        local effect e
        
        if tag == null or tag == "" then
            return
        endif
        
        set tagHash = GetTagHash(tag)
        set currentId = TagEffects[tagHash]
        
        loop
            exitwhen currentId == 0
            
            set nextId = EffectTagNext[currentId]
            set e = EffectHandle.effect[currentId]
            
            if e != null and not IsExcludedEffect(e) then
                call DestroyEffect(e)
                call UnregisterEffect(e)
            endif
            
            set currentId = nextId
        endloop
        
        set e = null
    endfunction
    
    // Set scale for tagged effect on unit
    public function SetScaleOnUnit takes unit u, string tag, real scale returns nothing
        local integer unitId
        local integer tagHash
        local integer currentId
        local effect e
        
        if u == null or tag == null or tag == "" then
            return
        endif
        
        set unitId = GetHandleId(u)
        set tagHash = GetTagHash(tag)
        set currentId = UnitEffects[unitId]
        
        loop
            exitwhen currentId == 0
            
            if EffectTag[currentId] == tagHash then
                set e = EffectHandle.effect[currentId]
                if e != null then
                    call BlzSetSpecialEffectScale(e, scale)
                endif
            endif
            
            set currentId = EffectNext[currentId]
        endloop
    endfunction
    
    // Set height for tagged effect on unit
    public function SetHeightOnUnit takes unit u, string tag, real height returns nothing
        local integer unitId
        local integer tagHash
        local integer currentId
        local effect e
        
        if u == null or tag == null or tag == "" then
            return
        endif
        
        set unitId = GetHandleId(u)
        set tagHash = GetTagHash(tag)
        set currentId = UnitEffects[unitId]
        
        loop
            exitwhen currentId == 0
            
            if EffectTag[currentId] == tagHash then
                set e = EffectHandle.effect[currentId]
                if e != null then
                    call BlzSetSpecialEffectHeight(e, height)
                endif
            endif
            
            set currentId = EffectNext[currentId]
        endloop
    endfunction
    
    //==========================================================================
    // Terrain Alignment API (by Antares - Hiveworkshop)
    //==========================================================================
    
    // Create a special effect aligned to terrain slope with specified yaw
    // This makes effects naturally follow terrain angles instead of being flat
    // effectPath: Path to the effect model
    // x, y: World coordinates
    // yaw: Facing angle in radians (use unit facing * bj_DEGTORAD)
    public function AddTerrainAligned takes string effectPath, real x, real y, real yaw returns effect
        local effect newEffect = AddSpecialEffect(effectPath, x, y)
        local real dzdx = (GetLocZ(x + 1, y) - GetLocZ(x - 1, y))/2
        local real dzdy = (GetLocZ(x, y + 1) - GetLocZ(x, y - 1))/2
        local real nx = -dzdx
        local real ny = -dzdy
        local real totalAngle = Acos(1/SquareRoot(nx*nx + ny*ny + 1))
        local real phiNormal = Atan2(ny, nx)
        local real pitch = totalAngle*Cos(yaw - phiNormal)
        local real roll = totalAngle*Sin(yaw - phiNormal)

        call BlzSetSpecialEffectOrientation(newEffect, yaw, pitch, roll)
        call RememberCreatedEffect(newEffect)

        return newEffect
    endfunction
    
    // Align an existing effect to terrain slope (auto-detects position and yaw=0)
    // Useful for effects that need to be aligned after creation or when moved
    public function AlignToTerrain takes effect whichEffect returns nothing
        local real x = BlzGetLocalSpecialEffectX(whichEffect)
        local real y = BlzGetLocalSpecialEffectY(whichEffect)
        local real dzdx = (GetLocZ(x + 1, y) - GetLocZ(x - 1, y))/2
        local real dzdy = (GetLocZ(x, y + 1) - GetLocZ(x, y - 1))/2
        local real nx = -dzdx
        local real ny = -dzdy
        local real totalAngle = Acos(1/SquareRoot(nx*nx + ny*ny + 1))
        local real phiNormal = Atan2(ny, nx)
        local real pitch = totalAngle*Cos(-phiNormal)
        local real roll = totalAngle*Sin(-phiNormal)

        call BlzSetSpecialEffectOrientation(whichEffect, 0, pitch, roll)
    endfunction
    
    // Create terrain-aligned effect on unit with tag (combines AddToPoint with terrain alignment)
    // Useful for persistent terrain-aligned effects that need tracking/removal
    public function AddToPointTerrainAligned takes real x, real y, string effectPath, string tag, real yaw returns nothing
        local effect e = AddTerrainAligned(effectPath, x, y, yaw)
        call RegisterEffect(e, null, EFFECT_TYPE_POINT, tag)
    endfunction
    
    // Explicit timed destroy for any effect handle.
    public function DestroyTimed takes effect whichEffect, real duration returns nothing
        local timer t
        local integer timerId
        
        if whichEffect == null then
            return
        endif
        
        if not IsRegisteredEffect(whichEffect) then
            call RegisterEffect(whichEffect, null, EFFECT_TYPE_POINT, null)
        endif
        
        if duration <= 0.0 then
            call DestroyManagedEffect(whichEffect)
            return
        endif
        
        set t = CreateTimer()
        set timerId = GetHandleId(t)
        set TimerEffect[timerId] = GetHandleId(whichEffect)
        call TimerStart(t, duration, false, function OnDurationExpire)
        set t = null
    endfunction

    // Destroy the latest created SpeciFX or GUI effect after a delay.
    // For direct native AddSpecialEffect(...) usage, prefer SpeciFX_DestroyTimed(effect, duration).
    public function Duration takes real duration returns nothing
        call DestroyTimed(GetLatestCreatedEffect(), duration)
    endfunction
    

    // Align a tagged effect on a unit to terrain (updates existing effect)
    public function AlignUnitEffectToTerrain takes unit u, string tag returns nothing
        local integer unitId
        local integer tagHash
        local integer currentId
        local effect e
        
        if u == null or tag == null or tag == "" then
            return
        endif
        
        set unitId = GetHandleId(u)
        set tagHash = GetTagHash(tag)
        set currentId = UnitEffects[unitId]
        
        loop
            exitwhen currentId == 0
            
            if EffectTag[currentId] == tagHash then
                set e = EffectHandle.effect[currentId]
                if e != null then
                    call AlignToTerrain(e)
                endif
            endif
            
            set currentId = EffectNext[currentId]
        endloop
    endfunction

    // Configure effect properties - use -1 (integer) or -1.0 (real) to skip a parameter, use null for animtype
    // This function provides full control over effect appearance and behavior
    // Usage: call SpeciFX_ConfigureEffect(myUnit, "myEffect", 255, 128, 64, 255, ANIM_TYPE_SPELL, 90.0, 0.0, 0.0, 0.0, 1.5, -1.0)
    public function ConfigureEffect takes unit u, string tag, integer red, integer green, integer blue, integer alpha, animtype whichAnim, real orientation, real pitch, real yaw, real roll, real timeScale, real time returns nothing
        local integer unitId
        local integer tagHash
        local integer currentId
        local effect e
        
        if u == null or tag == null or tag == "" then
            return
        endif
        
        set unitId = GetHandleId(u)
        set tagHash = GetTagHash(tag)
        set currentId = UnitEffects[unitId]
        
        loop
            exitwhen currentId == 0
            
            if EffectTag[currentId] == tagHash then
                set e = EffectHandle.effect[currentId]
                if e != null then
                    // Set color (0-255 for each component)
                    if red >= 0 and green >= 0 and blue >= 0 then
                        call BlzSetSpecialEffectColor(e, red, green, blue)
                    endif
                    
                    // Set alpha transparency (0-255, where 255 is fully opaque)
                    if alpha >= 0 then
                        call BlzSetSpecialEffectAlpha(e, alpha)
                    endif
                    
                    // Set animation by type
                    if whichAnim != null then
                        call BlzPlaySpecialEffect(e, whichAnim)
                    endif
                    
                    // Set orientation (yaw around Z axis in degrees)
                    if orientation >= 0.0 then
                        call BlzSetSpecialEffectYaw(e, orientation * bj_DEGTORAD)
                    endif
                    
                    // Set pitch (rotation around Y axis in degrees)
                    if pitch >= 0.0 then
                        call BlzSetSpecialEffectPitch(e, pitch * bj_DEGTORAD)
                    endif
                    
                    // Set yaw (rotation around Z axis in degrees)
                    if yaw >= 0.0 then
                        call BlzSetSpecialEffectYaw(e, yaw * bj_DEGTORAD)
                    endif
                    
                    // Set roll (rotation around X axis in degrees)
                    if roll >= 0.0 then
                        call BlzSetSpecialEffectRoll(e, roll * bj_DEGTORAD)
                    endif
                    
                    // Set time scale (animation speed multiplier, 1.0 = normal)
                    if timeScale >= 0.0 then
                        call BlzSetSpecialEffectTimeScale(e, timeScale)
                    endif
                    
                    // Set time (current animation time in seconds)
                    if time >= 0.0 then
                        call BlzSetSpecialEffectTime(e, time)
                    endif
                endif
            endif
            
            set currentId = EffectNext[currentId]
        endloop
    endfunction
    
    //==========================================================================
    // Initialization
    //==========================================================================
    
    private function Init takes nothing returns nothing
        // Initialize tables
        set EffectHandle = Table.create()
        set EffectUnit = Table.create()
        set EffectType = Table.create()
        set EffectTag = Table.create()
        set UnitEffects = Table.create()
        set EffectNext = Table.create()
        set TagEffects = Table.create()
        set EffectTagNext = Table.create()
        set ExcludedEffects = Table.create()
        set TimerEffect = Table.create()
        
        // Setup death trigger for automatic cleanup
        set DeathTrigger = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(DeathTrigger, EVENT_PLAYER_UNIT_DEATH)
        call TriggerAddCondition(DeathTrigger, Condition(function OnUnitDeath))
    endfunction
    
    private module InitModule
        private static method onInit takes nothing returns nothing
            call Init()
        endmethod
    endmodule
    
    private struct Initializer extends array
        implement InitModule
    endstruct

endlibrary
