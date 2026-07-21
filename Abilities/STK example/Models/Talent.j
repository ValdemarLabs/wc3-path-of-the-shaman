library STKTalent initializer init

    globals
        private boolexpr defaultCallback
    endglobals

    private function ReturnsTrue takes nothing returns boolean
        return true
    endfunction

    function interface Callback takes nothing returns boolean

    public struct Talent
        public string name
        public string description
        public string iconEnabled
        public string iconDisabled

        public trigger onAllocate     //= defaultCallback
        public trigger onDeallocate   //= defaultCallback
        public trigger onActivate     //= defaultCallback
        public trigger onDeactivate   //= defaultCallback
        public trigger requirements   //= defaultCallback

        public integer dependencyLeft       = 0
        public integer dependencyUp         = 0
        public integer dependencyRight      = 0
        public integer dependencyDown       = 0
        public integer startingLevel        = 0
        public integer cost                 = 1 // Default cost is 1
        public boolean isLink               = false
        public boolean isFinalDescription   = false

        public Talent nextRank              = 0
        public Talent previousRank          = 0
        public integer maxRank              = 0
        private integer rank                = 0
        private integer chainId              = 0
        // Tag?: any;
        
        static method create takes nothing returns Talent
            local Talent this = Talent.allocate()
            return this
        endmethod

        static method createCopy takes Talent talent returns Talent
            local Talent new = Talent.allocate()
            set new.name = talent.name
            set new.description = talent.description
            set new.iconEnabled = talent.iconEnabled
            set new.iconDisabled = talent.iconDisabled
            set new.onAllocate = talent.onAllocate
            set new.onDeallocate = talent.onDeallocate
            set new.onActivate = talent.onActivate
            set new.onDeactivate = talent.onDeactivate
            set new.requirements = talent.requirements
            set new.dependencyLeft = talent.dependencyLeft
            set new.dependencyUp = talent.dependencyUp
            set new.dependencyRight = talent.dependencyRight
            set new.dependencyDown = talent.dependencyDown
            set new.startingLevel = talent.startingLevel
            set new.cost = talent.cost
            set new.isLink = talent.isLink
            set new.chainId = talent.chainId

            return new
        endmethod

        method SetName takes string name returns Talent
            set this.name = name
            return this
        endmethod

        method SetDescription takes string description returns Talent
            set this.description = description
            return this
        endmethod

        method SetIcon takes string name returns Talent
            set this.iconEnabled = "ReplaceableTextures\\CommandButtons\\BTN" + name
            set this.iconDisabled = "ReplaceableTextures\\CommandButtonsDisabled\\DISBTN" + name
            return this
        endmethod

        method SetIconEnabled takes string path returns Talent
            set this.iconEnabled = path
            return this
        endmethod

        method SetIconDisabled takes string path returns Talent
            set this.iconDisabled = path
            return this
        endmethod

        method SetOnAllocate takes code func returns Talent
            set this.onAllocate = CreateTrigger()
            call TriggerAddCondition(this.onAllocate, Condition(func))
            return this
        endmethod

        method SetOnDeallocate takes code func returns Talent
            set this.onDeallocate = CreateTrigger()
            call TriggerAddCondition(this.onDeallocate, Condition(func))
            return this
        endmethod

        method SetOnActivate takes code func returns Talent
            set this.onActivate = CreateTrigger()
            call TriggerAddCondition(this.onActivate, Condition(func))
            return this
        endmethod

        method SetOnDeactivate takes code func returns Talent
            set this.onDeactivate = CreateTrigger()
            call TriggerAddCondition(this.onDeactivate, Condition(func))
            return this
        endmethod

        method SetRequirements takes code func returns Talent
            set this.requirements = CreateTrigger()
            call TriggerAddCondition(this.requirements, Condition(func))
            return this
        endmethod

        method SetDependencies takes integer left, integer up, integer right, integer down returns Talent
            set this.dependencyLeft = left
            set this.dependencyUp = up
            set this.dependencyRight = right
            set this.dependencyDown = down
            return this
        endmethod

        method SetCost takes integer cost returns Talent
            set this.cost = cost
            return this
        endmethod

        method SetChainId takes integer chainId returns Talent
            set this.chainId = chainId
            return this
        endmethod

        method GetChainId takes nothing returns integer
            return this.chainId
        endmethod

        method GetNextRank takes nothing returns Talent
            if (this.nextRank != 0) then
                return this.nextRank
            endif
            return this
        endmethod

        method SetNextRank takes Talent talent returns nothing
            if (this == talent) then
                call BJDebugMsg("ERROR - ASSIGNING SAME TALENT " + I2S(this))
            endif
            set this.nextRank = talent
            set talent.previousRank = this
        endmethod

        method SetLastRank takes Talent talent returns nothing
            if (this.nextRank != 0) then
                call this.nextRank.SetLastRank(talent)
                return
            endif
            call this.SetNextRank(talent)
        endmethod

        method UpdateMaxRank takes nothing returns nothing
            local thistype talent
            local integer maxRank = 1
            
            set talent = this
            loop
                set talent = talent.previousRank
                exitwhen talent == 0 or talent.isFinalDescription
                set maxRank = maxRank + 1
            endloop

            set talent = this
            loop
                set talent = talent.nextRank
                exitwhen talent == 0 or talent.isFinalDescription
                set maxRank = maxRank + 1
            endloop

            set this.maxRank = maxRank
            set talent = this
            loop
                set talent = talent.previousRank
                exitwhen talent == 0
                set talent.maxRank = maxRank
            endloop

            set talent = this
            loop
                set talent = talent.nextRank
                exitwhen talent == 0
                set talent.maxRank = maxRank
            endloop
        endmethod

        method GetTalentRank takes nothing returns integer
            return this.rank
        endmethod

        method CreateTalentFinalDescription takes nothing returns STKTalent_Talent
            
            local STKTalent_Talent talent = STKTalent_Talent.create()
            set talent.name = this.name
            set talent.description = this.description
            set talent.iconEnabled = this.iconEnabled
            set talent.iconDisabled = this.iconDisabled
            set talent.dependencyLeft = this.dependencyLeft
            set talent.dependencyUp = this.dependencyUp
            set talent.dependencyRight = this.dependencyRight
            set talent.dependencyDown = this.dependencyDown
            set talent.maxRank = 0
            set talent.chainId = this.chainId
            set talent.isFinalDescription = true
            
            call this.SetNextRank(talent)
            set talent.maxRank = talent.maxRank
            return talent
        endmethod

        method SetTalentFinalDescription takes nothing returns nothing
            local thistype finalDesc

            if (this.nextRank != 0 and this.nextRank.isFinalDescription == false) then
                call this.nextRank.SetTalentFinalDescription()
                return
            endif
            set finalDesc = this.CreateTalentFinalDescription()
            call this.SetNextRank(finalDesc)
        endmethod

        method RemoveTalentFinalDescription takes nothing returns nothing
            if (this.nextRank != 0 and this.nextRank.isFinalDescription) then
                set this.nextRank = 0
                return
            elseif (this.nextRank != 0) then
                call this.nextRank.RemoveTalentFinalDescription()
            endif
        endmethod
        
        method onDestroy takes nothing returns nothing
            
        endmethod
    endstruct

    private function init takes nothing returns nothing
        set defaultCallback = Condition(function ReturnsTrue)
    endfunction

endlibrary