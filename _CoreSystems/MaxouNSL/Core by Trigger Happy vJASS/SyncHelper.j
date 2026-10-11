library SyncHelper

    globals
        public constant string SYNC_PREFIX_COUNT = "CP"
        public constant string SYNC_PREFIX = "CS"
        private constant integer SYNC_SIZE_CHUNK = 200
    endglobals
    
    private keyword INITS
    
    private struct Sync extends array
        static trigger TriggerCount = CreateTrigger()
        static trigger Trigger = CreateTrigger()
        implement INITS
    endstruct
    
    function SyncString takes string s returns nothing
        local integer len = StringLength(s)
        local integer parts = (len / SYNC_SIZE_CHUNK) + 1
		local string sub
        local integer i = 0
        if(ModuloInteger(len, SYNC_SIZE_CHUNK) == 0) then
            set parts = parts - 1
        endif
        call BlzSendSyncData(SYNC_PREFIX_COUNT, I2S(parts))
		loop
			set sub = SubString(s, i * SYNC_SIZE_CHUNK, (i + 1) * SYNC_SIZE_CHUNK)
			if(StringLength(sub) > 0) then
                call BlzSendSyncData(SYNC_PREFIX, sub)
			endif
			set i = i + 1
			exitwhen i == parts
		endloop
    endfunction
    
    function OnSyncString takes code func returns triggeraction
        return TriggerAddAction(Sync.Trigger, func)
    endfunction
    
    function OnSyncStringCount takes code func returns triggeraction
        return TriggerAddAction(Sync.TriggerCount, func)
    endfunction
    
    function RemoveSyncString takes triggeraction t returns nothing
        call TriggerRemoveAction(Sync.Trigger, t)
    endfunction
    
    private module INITS
        private static method onInit takes nothing returns nothing
            local integer i  = 0
            
            loop
                call BlzTriggerRegisterPlayerSyncEvent(.TriggerCount, Player(i), SYNC_PREFIX_COUNT, false)
                call BlzTriggerRegisterPlayerSyncEvent(.Trigger, Player(i), SYNC_PREFIX, false)
                set i = i + 1
                
                exitwhen i == bj_MAX_PLAYER_SLOTS
            endloop
        endmethod
    endmodule
endlibrary