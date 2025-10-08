//TESH.scrollpos=0
//TESH.alwaysfold=0
library Stealth initializer Init
// A useful expansion to the existing "windwalk" ability:
//  The caster can only stealth when enemies aren't near
//  Enemies can detect the unit when they come close enough
//  whenever the caster is behind an enemy the detect range is highly decreased!
//   ( well you have no eyes on your back too ;D )

globals
    // the ability based on "windwalk"
    private constant integer ABILITY_ID = 'A6CR'
    
    // your custom buff ADDED BY THE MODIFIED ABILITY!!
    private constant integer BUFF_ID = 'B618'
    
    // the timer interval
    private constant real INTERVAL = 0.03           
    
    // the detect distance changing factor when you are behind the enemies when stealthing
    // DEFAULT private constant real VIEW_FACTOR = 0.5 
    private constant real VIEW_FACTOR = 0.0  
    
    // an additional animation tag, added when stealthed
    private constant string ANIMATION_TAG = "walk moderate"
    
    // the special effect created when an enemy detects you
    private constant string DETECTED_SFX = "Abilities\\Spells\\Human\\FlakCannons\\FlakTarget.mdl"
    
    // the max instances of this spell that can run the same time
    private constant integer MAX_INSTANCES = 300

    // Custom: Throw Rock ability does not remove stealth
    private constant integer THROW_ROCK_ID = 'A6CT'
endglobals

private function GetMaxDuration takes integer lvl returns real
    return 30. * lvl    // + 30 seconds each level
endfunction

private function GetDetectRange takes integer lvl returns real
    return 500. - 100 * lvl      // enemies must come in 500/400/300 range to detect the hero
endfunction

private function GetCastRange takes integer lvl returns real
    return 900. - 150 * lvl      // enemies must be 750/600/450 away if you want to stealth
endfunction

//-----------Don't modify anything below this line---------

globals
    private group g = CreateGroup()
    private group StealthedUnits = CreateGroup()             
    private boolexpr bool = null
endglobals

private function DistanceBetweenUnits takes unit a, unit b returns real
    local real dx = GetUnitX(b) - GetUnitX(a)
    local real dy = GetUnitY(b) - GetUnitY(a)
    return SquareRoot(dx * dx + dy * dy)
endfunction

private function GetAngleDifference takes real a1, real a2 returns real
    local real x
    set a1=ModuloReal(a1,360)
    set a2=ModuloReal(a2,360)
    if a1>a2 then
        set x=a1
        set a1=a2
        set a2=x
    endif
    set x=a2-360
    if a2-a1 > a1-x then
        set a2=x
    endif
    return RAbsBJ(a1-a2)
endfunction

private struct data
    unit u
    real t = 0  
    string tag
    integer l
    integer id = -2
    
    static thistype array DATA[MAX_INSTANCES]
    static integer datas = 0
    static timer tim = CreateTimer()
    static thistype TEMP
    
    private static method execute takes nothing returns nothing
        local data dat
        local integer i = 0
        loop
            exitwhen i >= .datas
            set dat = .DATA[i]
            set dat.t = dat.t + INTERVAL
            set .TEMP = dat
            call GroupClear(g)
            call GroupEnumUnitsInRange(g,GetUnitX(dat.u),GetUnitY(dat.u),GetDetectRange(dat.l),bool) 
            if GetUnitAbilityLevel(dat.u, BUFF_ID) == 0 or dat.t > GetMaxDuration(dat.l) or not IsUnitInGroup(dat.u,StealthedUnits) or FirstOfGroup(g) != null then
                call dat.destroy()
            endif
            set i = i + 1
        endloop
    endmethod

    static method Cast takes nothing returns boolean
        local unit caster = GetSpellAbilityUnit()
        local integer lvl = GetUnitAbilityLevel(caster, ABILITY_ID)
        local data dat
        if GetSpellAbilityId() == ABILITY_ID then
            if not IsUnitInGroup(caster,StealthedUnits) then
                call GroupAddUnit(StealthedUnits,caster)
                set dat = data.create()
                set dat.u = caster
                set dat.l = lvl
                set .TEMP = dat
                call GroupClear(g)
                call GroupEnumUnitsInRange(g,GetUnitX(caster),GetUnitY(caster),GetCastRange(lvl),bool) 
                set dat.id = .datas
                call UnitRemoveAbility( caster,ABILITY_ID )
                call UnitAddAbility( caster,ABILITY_ID )
                call SetUnitAbilityLevel(caster,ABILITY_ID, lvl) 

                 // Prevent funny “whirlwind” animation
                call ResetUnitAnimation(caster)
                call SetUnitAnimation(caster, "stand")
                call QueueUnitAnimation(caster, "stand")

                call AddUnitAnimationProperties(caster,ANIMATION_TAG,true)
                if FirstOfGroup(g) != null then
                    call GroupRemoveUnit(StealthedUnits,caster)
                endif
                if .datas == 0 then 
                    call TimerStart(.tim,INTERVAL,true, function data.execute)
                endif
                set .DATA[dat.id] = dat
                set .datas = .datas + 1
                call DestroyEffect(AddSpecialEffect(DETECTED_SFX,GetUnitX(dat.u),GetUnitY(dat.u)))
            else
                call GroupRemoveUnit(StealthedUnits,caster)
            endif
        endif          
        set caster = null                  
        return false
    endmethod

    method onDestroy takes nothing returns nothing
        call UnitRemoveAbility( .u, BUFF_ID )
        call DestroyEffect(AddSpecialEffect(DETECTED_SFX,GetUnitX(.u),GetUnitY(.u)))
        call AddUnitAnimationProperties(.u,ANIMATION_TAG,false)
        call GroupRemoveUnit(StealthedUnits,.u)
        set .datas = .datas - 1
        set .DATA[.id] = .DATA[.datas]
        set .DATA[.id].id = .id
        if .datas == 0 then
            call PauseTimer(.tim)
        endif
    endmethod
endstruct

private function EnemiesOnly takes nothing returns boolean
    local boolean b = IsUnitEnemy(GetFilterUnit(),GetOwningPlayer(data.TEMP.u)) and not (IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) or GetUnitTypeId(GetFilterUnit()) == 0 )
    local real AngleDif = GetAngleDifference(GetUnitFacing(GetFilterUnit()),bj_RADTODEG * Atan2(GetUnitY(GetFilterUnit()) - GetUnitY(data.TEMP.u), GetUnitX(GetFilterUnit()) - GetUnitX(data.TEMP.u)))
    if b then
        if data.TEMP.id == -2 then
            if AngleDif < 90 and DistanceBetweenUnits(GetFilterUnit(),data.TEMP.u) > GetCastRange(data.TEMP.l) * VIEW_FACTOR then
                set b = false
            endif
        else
            if AngleDif < 90 and DistanceBetweenUnits(GetFilterUnit(),data.TEMP.u) > GetDetectRange(data.TEMP.l) * VIEW_FACTOR then
                set b = false
            endif
        endif
    endif
    return b
endfunction

private function Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    local integer i = 0
    set bool = Condition( function EnemiesOnly)
    call TriggerAddCondition(t,Condition(function data.Cast))
    loop
        call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
        set i = i + 1
        exitwhen i == bj_MAX_PLAYER_SLOTS
    endloop
endfunction

endlibrary