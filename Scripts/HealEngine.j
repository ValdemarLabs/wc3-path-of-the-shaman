/*
    vJass HealEngine 1.0.4
    by Marchombre

    Requirement if using HealDetection: GUI Unit Indexer 1.4.0.0 (by Bribe)
*/

/*
    ==================
    ==== Jass API ====
    ==================

    // This struct is used for native healing and regen detection
    struct HealDetection
        // Add unit (by its index) to the detection system
        static method AddUnit takes integer unitId returns nothing

        // Remove unit (by its index) from the detection system
        static method SystemRemoveUnit takes integer unitId returns nothing

        // Used for Optionnal trigger
        // Force a check on target unit. Used before applying damage.
        static method Adjust takes unit target returns nothing

        // Used for Optionnal trigger
        // Adjust values after taking damage, or some events might not trigger due to HP diff
        static method AdjustAfterDamage takes unit target, real dmg returns nothing

        // Adjust values after receiving a triggered heal, to avoid triggering the healing event a second time by detection
        static method AdjustAfterHeal takes unit u, real heal returns nothing

    // This struct is used for triggered healing and complete Heal Events
    struct Heal
        // User Entry Point. Takes heal source, target and amount
        // If an other heal is currently running, postpon new one to avoid conflicts
        static method HealUnit takes unit source, unit target, real amount

*/
library HealEngine
    globals 
        /*
            Variables used for detecting war3 native heals and regeneration
        */
        private constant boolean USE_HEAL_DETECTION     = true      // Enable/disable HealDetection triggers. If set to true, make sure to have Unit Indexer requirement

        private constant real HEAL_THRESHOLD            = 5.00
        private constant real HEAL_CHECK_INTERVAL       = 0.05

        private constant real REGEN_STRENGTH_VALUE      = 0.05
        private constant real REGEN_THRESHOLD           = 5.00
        private constant real REGEN_EVENT_INTERVAL      = 1.00

        private constant boolean IS_NATIVE_HEALING_SELF = false     // True: native healing will be considered selfhealing. False: considered from an unknown source
        private constant boolean IS_NATIVE_REGEN_SELF   = false      // True: regen will be considered selfhealing. False: considered from an unknown source

        // Booleans to control control what type of units should be ignored by the HealDetection system.
        private constant boolean IGNORE_LOCUST          = true      // Units with locust ability (ex: dummies)
        private constant boolean IGNORE_STRUCTURE       = false     // Structures (unit classification must be consistent)
        private constant boolean IGNORE_MECHANICAL      = false     // Mechanical (unit classification must be consistent)
        private constant boolean IGNORE_SUMMONED        = false     // Summoned units (unit classification must be consistent)
        private constant boolean IGNORE_HERO            = false     // Heroes
        private constant boolean IGNORE_NON_HERO        = false     // Every units except heroes

        /*
            Config for Events
        */
        private constant real ZEROHEAL_THRESHOLD        = 1.00      // Heal under this value will fire ZeroHealEvent
        private constant real OVERHEAL_THRESHOLD        = 1.00      // How much overheal is needed to fire OverHealEvent
        private constant real MAX_PREHEAL_EVENTS        = 4.00      // PreHealEvent will fire this many time. Useful if you want to make sure modifiers are applierd if the right order (% then flat for example).
        
        private constant boolean ALLOW_NEGATIVE_HEALING = false     // If true, negative healing after PreHealEvents will do damage. Else, heal won't go under 0. 
        private constant real NEGATIVE_HEAL_THRESHOLD   = -1.00     // Used if ALLOW_NEGATIVE_HEALING = true. Threshold for firing NegativeHealEvent. 
    endglobals 

    // GUI vars for those who really don't want to call custom script 
    // These are set before running a trigger calling this engine
    /*
        unit                udg_NextHealSource
        unit                udg_NextHealTarget
        real                udg_NextHealAmount
    */

    // GUI Vars to catch events
    /*

        // Variables you can access to get infos on current heal
        unit                udg_HealSource
        unit                udg_HealTarget

        real                udg_HealAmount              // Current heal amount
        real                udg_HealBaseAmount          // Heal amount before any event was fired.
        real                udg_HealPrvAmount           // Heal amount at the start of this event

        real                udg_EffectiveHealAmount     // How much HPs was actually healed
        real                udg_OverHealAmount          // How much heal is left after getting the unit to full HP.
        boolean             udg_IsSelfHeal

        // Events variables
        real                udg_PreHealEvent            // Can be 0.00 or X.00, with 1 <= X <= MAX_PREHEAL_EVENTS  
        real                udg_AfterHealEvent          // Can be 0.00 or 1.00 or 0.50
        real                udg_ZeroHealEvent           // Can be 0.00 or 1.00
        real                udg_OverHealEvent           // Can be 0.00 or 1.00
        real                udg_NegativeHealEvent       // Can be 0.00 or 1.00

    */
    
    struct HealDetection
        private static trigger checkLoopTrigger
        private static trigger addUnitTrigger
        private static trigger removeUnitTrigger

        private static boolean array isInSystem
        private static integer array indices
        private static integer array indexRef
        
        private static real array lastLife
        private static real array regen

        private static real array regenBuildUp
        private static real array regenTimeLeft
        
        private static integer count        = 0
        private static integer unitIndex    = 0

        private static timer healTimer
        
        
        static method AddUnit takes integer unitId returns nothing
            // if Unit is already in system or unit match one ignore config, then do nothing
            if isInSystem[unitId] /*
                */ or (GetUnitAbilityLevel(udg_UDexUnits[unitId], 'Aloc') > 0 and IGNORE_LOCUST)/*
                */ or (IsUnitType(udg_UDexUnits[unitId], UNIT_TYPE_MECHANICAL) and IGNORE_MECHANICAL) /*
                */ or (IsUnitType(udg_UDexUnits[unitId], UNIT_TYPE_STRUCTURE) and IGNORE_STRUCTURE) /*
                */ or (IsUnitType(udg_UDexUnits[unitId], UNIT_TYPE_SUMMONED) and IGNORE_SUMMONED) /*
                */ or (IsUnitType(udg_UDexUnits[unitId], UNIT_TYPE_HERO) and IGNORE_HERO) /*
                */ or (not IsUnitType(udg_UDexUnits[unitId], UNIT_TYPE_HERO) and IGNORE_NON_HERO) /*
                */ then
                return
            endif

            set isInSystem[unitId]      = true
            set indices[count]          = unitId
            set indexRef[unitId]        = count
            set lastLife[unitId]        = GetWidgetLife(udg_UDexUnits[unitId])
            set regenTimeLeft[unitId]   = REGEN_EVENT_INTERVAL
            
            set count = count +1

            // If first unit added, turn on checkloop
            if count == 1 then
                call EnableTrigger(checkLoopTrigger)
            endif

        endmethod

        static method SystemRemoveUnit takes integer unitId returns nothing
            // If unit not in system, can't remove them, so just returns
            if not isInSystem[unitId] then
                return
            endif

            set isInSystem[unitId]          = false
            set count = count -1
            set indices[indexRef[unitId]]   = indices[count]
            set indexRef[indices[count]]    = indexRef[unitId]

            // If last unit in system, turn off checkloop
            if count == 0 then
                call DisableTrigger(checkLoopTrigger)
            endif

        endmethod

        private static method CheckLoop takes nothing returns nothing
            local integer max = count -1
            local integer unitIndex = 0

            local unit target
            local real unitHP
            local real diff
            local real heal
            
            loop
                exitwhen unitIndex > max
                
                set unitIndex = indices[unitIndex]

                set target              = udg_UDexUnits[unitIndex]
                set unitHP              = GetWidgetLife(target)
                set diff                = unitHP - lastLife[unitIndex]
                set lastLife[unitIndex] = unitHP

                set heal                = diff - RMaxBJ(0.00, regen[unitIndex])

                if heal > HEAL_THRESHOLD then
                    // Set Up variables
                    set udg_HealAmount = heal
                    set udg_HealTarget = target

                    if IS_NATIVE_HEALING_SELF then
                        set udg_HealSource = target
                    else
                        set udg_HealSource = null   // Can't know the source of a native healing sadly
                    endif
                    
                    set udg_IsSelfHeal = IS_NATIVE_HEALING_SELF

                    // Fire AfterHealEvent
                    set udg_AfterHealEvent  = 0.00
                    set udg_AfterHealEvent  = 1.00
                    set udg_AfterHealEvent  = 0.00
                else
                    // Check Regen
                    set regen[unitIndex] = (regen[unitIndex] + diff) * 0.5

                    set regenBuildUp[unitIndex]     = regenBuildUp[unitIndex] + diff
                    set regenTimeLeft[unitIndex]    = regenTimeLeft[unitIndex] - HEAL_CHECK_INTERVAL

                    if regenTimeLeft[unitIndex] <= 0.00 then
                        // reset clock
                        set regenTimeLeft[unitIndex] = REGEN_EVENT_INTERVAL

                        set heal = regenBuildUp[unitIndex]
                        set regenBuildUp[unitIndex] = 0.00
                        
                        set diff = heal

                        // Ignore regen from hero stats
                        if IsUnitType(target, UNIT_TYPE_HERO) then
                            set diff = diff - REGEN_STRENGTH_VALUE * I2R(GetHeroStr(target, true))
                        endif

                        // Fire Regen Event (AfterHealEvent = 0.5)
                        if diff > REGEN_THRESHOLD then
                             // Set Up variables
                            set udg_HealAmount = heal
                            set udg_HealTarget = target

                            if IS_NATIVE_REGEN_SELF then
                                set udg_HealSource = target
                            else
                                set udg_HealSource = null   // Can't know the source of a native healing sadly
                            endif
                            
                            set udg_IsSelfHeal = IS_NATIVE_REGEN_SELF

                            // Fire AfterHealEvent
                            set udg_AfterHealEvent  = 0.00
                            set udg_AfterHealEvent  = 0.50
                            set udg_AfterHealEvent  = 0.00
                        endif
                    endif
                endif

                set unitIndex = indexRef[unitIndex]
                set unitIndex = unitIndex +1
            endloop
        endmethod

        // Check unit new life and fire AfterHealEvent if needed
        static method Adjust takes unit target returns nothing
            local integer index     = GetUnitUserData(target)
            local real u_hp         = GetWidgetLife(target)
            
            local real heal = u_hp - lastLife[index] - regen[index] * TimerGetElapsed(healTimer) / HEAL_CHECK_INTERVAL

            if heal > HEAL_THRESHOLD then 
                set lastLife[index] = lastLife[index] + heal
                
                // Set Up variables
                set udg_HealAmount = heal
                set udg_HealTarget = target

                if IS_NATIVE_HEALING_SELF then
                    set udg_HealSource = target
                else
                    set udg_HealSource = null   // Can't know the source of a native healing sadly
                endif
                
                set udg_IsSelfHeal = IS_NATIVE_HEALING_SELF

                // Fire AfterHealEvent
                set udg_AfterHealEvent  = 0.00
                set udg_AfterHealEvent  = 1.00
                set udg_AfterHealEvent  = 0.00
            endif
        endmethod

        // Adjust values when unit takes damage, or heal might not be detected
        static method AdjustAfterDamage takes unit target, real dmg returns nothing
            local integer index     = GetUnitUserData(target)
            local real u_hp         = GetWidgetLife(target)

            if dmg > 0 then 
                set lastLife[index] = u_hp - regen[index] * TimerGetElapsed(healTimer) / HEAL_CHECK_INTERVAL
            else 
                call Adjust(target)
            endif
        endmethod

        // Adjust after heal, avoiding a double event for one heal
        static method AdjustAfterHeal takes unit u, real heal returns nothing
            local integer index = GetUnitUserData(u)
            set lastLife[index] = lastLife[index] + heal
        endmethod

        private static method ActionAddUnit takes nothing returns nothing
            call AddUnit(udg_UDex)
        endmethod

        private static method ActionRemoveUnit takes nothing returns nothing
            call SystemRemoveUnit(udg_UDex)
        endmethod

        private static method onInit takes nothing returns nothing
            if USE_HEAL_DETECTION then 
                set healTimer           = CreateTimer()
                set checkLoopTrigger    = CreateTrigger()
                set addUnitTrigger      = CreateTrigger()
                set removeUnitTrigger   = CreateTrigger()

                call StartTimerBJ(healTimer, true, HEAL_CHECK_INTERVAL)
                
                call TriggerRegisterTimerExpireEvent(checkLoopTrigger, healTimer)
                call TriggerAddAction(checkLoopTrigger, function HealDetection.CheckLoop)

                call TriggerRegisterVariableEvent(addUnitTrigger, "udg_UnitIndexEvent", EQUAL, 1.00)
                call TriggerRegisterVariableEvent(addUnitTrigger, "udg_DeathEvent", EQUAL, 2.00)
                call TriggerAddAction(addUnitTrigger, function HealDetection.ActionAddUnit)

                call TriggerRegisterVariableEvent(removeUnitTrigger, "udg_UnitIndexEvent", EQUAL, 2.00)
                call TriggerRegisterVariableEvent(removeUnitTrigger, "udg_DeathEvent", EQUAL, 0.50)
                call TriggerRegisterVariableEvent(removeUnitTrigger, "udg_DeathEvent", EQUAL, 1.00)
                call TriggerRegisterVariableEvent(removeUnitTrigger, "udg_DeathEvent", EQUAL, 3.00)
                call TriggerAddAction(removeUnitTrigger, function HealDetection.ActionRemoveUnit)
            endif
        endmethod
    endstruct

    struct Heal

        /*
            Variables used in healing 
        */
        private unit healSource
        private unit healTarget

        private real healBaseAmt
        private real healPrevAmt
        private real healAmount
        
        private real effectiveHealAmt
        private real overHealAmount

        private boolean isSelfHeal
        
        /*
            Variables used for listing
        */
        private Heal next

        private static Heal first
        private static Heal last


        private static method create takes unit source, unit target, real amount returns Heal
            local Heal this = Heal.allocate()

            set this.healSource         = source
            set this.healTarget         = target
            set this.healAmount         = amount
            set this.healBaseAmt        = amount
            set this.healPrevAmt        = amount

            set this.isSelfHeal         = (source == target)
            set this.overHealAmount     = 0
            set this.effectiveHealAmt   = 0

            set this.next = 0
            
            return this
        endmethod

        private method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod

        private static method onInit takes nothing returns nothing
            set first = 0
            set last = 0
        endmethod

        /*
            Entry point for user. 
        */
        static method HealUnit takes unit source, unit target, real amount returns nothing
            local Heal h = Heal.create(source, target, amount)

            if first == 0 then 
                set first = h
                set last = h
                call Heal.Run()
            else
                set last.next = h
                set last = last.next
            endif

        endmethod

        // Put this instance members into GUI variables
        private method setEventVariables takes nothing returns nothing
            set udg_HealSource              = this.healSource
            set udg_HealTarget              = this.healTarget
            
            set udg_HealAmount              = this.healAmount
            set udg_HealBaseAmount          = this.healBaseAmt
            set udg_HealPrvAmount           = this.healPrevAmt
            
            set udg_EffectiveHealAmount     = this.effectiveHealAmt
            set udg_OverHealAmount          = this.overHealAmount

            set udg_IsSelfHeal              = this.isSelfHeal
        endmethod

        // Updates this instance members with GUI vars that might have been updated
        private method getEventVariables takes nothing returns nothing
            set this.healSource     = udg_HealSource
            set this.healTarget     = udg_HealTarget
            set this.healAmount     = udg_HealAmount
            set this.healPrevAmt    = udg_HealAmount    // Stores this step result for reference in next step if needed.

            set this.isSelfHeal     = (this.healSource == this.healTarget)
        endmethod

        // Reset Variables to a neutral state
        private static method resetEventVariables takes nothing returns nothing
            set udg_HealSource              = null
            set udg_HealTarget              = null

            set udg_HealBaseAmount          = 0.00
            set udg_HealPrvAmount           = 0.00
            set udg_HealAmount              = 0.00

            set udg_EffectiveHealAmount     = 0.00
            set udg_OverHealAmount          = 0.00

            set udg_IsSelfHeal              = false
        endmethod

        /*
            Function where the healing and Events are done.
            Healing are dealt one at the time. Healing created during Events will be postponed.
        */
        private static method Run takes nothing returns nothing
            local Heal h
            local integer u_custom
            local real u_current_hp
            local real u_max_hp
            local real u_missing_hp
            local real new_missing_hp
            local real i = 1.00

            loop 
                exitwhen first == null
                
                set h = first 
                
                // Using not == instead of !=; the idea is to eliminate floating point bugs when two numbers are very close to 0,
                // because JASS uses a less-strict comparison for checking if a number is equal than when it is unequal.
                if not (h.healAmount == 0.00) then

                    loop 
                        exitwhen i > MAX_PREHEAL_EVENTS
                        // Set GUI vars
                        call h.setEventVariables()

                        // Fire PreHealEvent
                        set udg_PreHealEvent    = 0.00
                        set udg_PreHealEvent    = i
                        set udg_PreHealEvent    = 0.00

                        // Update fields in case event was caught and variables changed.
                        call h.getEventVariables()

                        set i = i +1.00
                    endloop

                    if not ALLOW_NEGATIVE_HEALING and h.healAmount < 0.00 then
                        set h.healAmount = 0.00
                    endif                        
                    
                    // Get target infos
                    set u_custom            = GetUnitUserData(h.healTarget)
                    set u_max_hp            = GetUnitState(h.healTarget, UNIT_STATE_MAX_LIFE) 
                    set u_current_hp        = GetWidgetLife(h.healTarget)
                    set u_missing_hp        = u_max_hp - u_current_hp
                    
                    if h.healAmount > 0 then
                        // Healing itself.
                        call SetWidgetLife(h.healTarget, u_current_hp + h.healAmount)
                        
                        // Getting new missing hp
                        set new_missing_hp = GetUnitState(h.healTarget, UNIT_STATE_MAX_LIFE) - GetWidgetLife(h.healTarget)

                        // Computing effective healing and possible overhealing
                        set h.effectiveHealAmt = u_missing_hp - new_missing_hp
                        set h.overHealAmount = h.healAmount - h.effectiveHealAmt
                    else
                        // Use Damage function to be compatible with damage engines
                        call UnitDamageTargetBJ(h.healSource, h.healTarget, h.healAmount, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_MAGIC)
                        set h.effectiveHealAmt = h.healAmount
                    endif
                    
                    // Fire OverHealEvent
                    if h.overHealAmount > OVERHEAL_THRESHOLD then
                        // Set GUI vars
                        call h.setEventVariables()

                        set udg_OverHealEvent   = 0.00
                        set udg_OverHealEvent   = 1.00
                        set udg_OverHealEvent   = 0.00
                    endif

                    // Fire AfterHealEvent if enough healing was done, else ZeroHealEvent
                    if h.effectiveHealAmt > ZEROHEAL_THRESHOLD or (h.overHealAmount > 0.00) then
                        // Update HealDetection system, avoiding the event triggering twice for this heal
                        call HealDetection.AdjustAfterHeal(h.healTarget, h.healAmount)

                        // Set GUI vars
                        call h.setEventVariables()

                        set udg_AfterHealEvent  = 0.00
                        set udg_AfterHealEvent  = 1.00
                        set udg_AfterHealEvent  = 0.00
                    elseif h.effectiveHealAmt < NEGATIVE_HEAL_THRESHOLD then
                        // Set GUI vars
                        call h.setEventVariables()

                        set udg_NegativeHealEvent   = 0.00
                        set udg_NegativeHealEvent   = 1.00
                        set udg_NegativeHealEvent   = 0.00
                    else
                        // Set GUI vars
                        call h.setEventVariables()

                        set udg_ZeroHealEvent   = 0.00
                        set udg_ZeroHealEvent   = 1.00
                        set udg_ZeroHealEvent   = 0.00
                    endif

                endif

                // Resets variables
                call resetEventVariables()

                // Set the next heal that will be run
                set first = h.next
                
                // Free resources
                call h.destroy()
            endloop

        endmethod
    endstruct

endlibrary