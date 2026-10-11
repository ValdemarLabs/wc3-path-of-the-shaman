/*



            Don't edit this
            


*/
library NSLSaveLoad initializer Init requires NSLSizeEnum, NSLHelper
	globals
		private string NSL_Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-"
		private integer NSL_CharsetLen = 64
		private integer NSL_BitPerChar = 6
		
		private integer NSL_HT_KEY_CODE_ID = 0
		private integer NSL_HT_KEY_PROGRESS_INDEX = 1
		private integer NSL_HT_KEY_BITS_OFFSET = 2

		private hashtable NSL_Hashtable = InitHashtable()
		private hashtable NSL_HashtableValue = InitHashtable()
		private timer array NSL_Timers
	endglobals
	
	function interface NSL_PlayerLoadCallback takes integer playerId, boolean is_valid, NSL_Code loader returns nothing
	function interface NSL_PlayerSaveCallback takes integer playerId, string generated_code returns nothing
	
	private function Init takes nothing returns nothing
		local integer i = 0
		
        loop
			set NSL_Timers[i] = CreateTimer()
			set i = i + 1
			exitwhen i == 24
		endloop
	endfunction
	
	private function CharAt takes integer index returns string
		return SubString(NSL_Charset, index, index + 1)
	endfunction
	
	private function GenerateTimerCallback takes nothing returns nothing
		local integer timerId = GetHandleId(GetExpiredTimer())
		local NSL_Code inst = LoadInteger(NSL_Hashtable, timerId, NSL_HT_KEY_CODE_ID)
		call inst.Generate()
	endfunction
	
	private function LoadTimerCallback takes nothing returns nothing
		local integer timerId = GetHandleId(GetExpiredTimer())
		local NSL_Code inst = LoadInteger(NSL_Hashtable, timerId, NSL_HT_KEY_CODE_ID)
		call inst.Load()
	endfunction
	
	private function IndexOf takes string char returns integer
		local integer i = 0
		loop
			if(CharAt(i) == char) then
				return i
			endif
			set i = i + 1
			exitwhen i == NSL_CharsetLen
		endloop

		return 0
	endfunction
	
	private function GetPlayerHash takes integer player_id returns integer
		local string name = GetPlayerName(Player(player_id))
		local integer len = StringLength(name)
		local integer hash = 0
		local integer i = 0
		loop
			set hash = hash + IndexOf(SubString(name, i, i + 1)) * NSL_Key * NSL_Key
			set i = i + 1
			exitwhen i == len
		endloop
		return hash
	endfunction
	
	struct NSL_Code
		private integer player_id
		private integer bits_count
		private boolean is_started
		private boolean is_ready
		private integer code_key
		private string player_code
		private integer code_hash
		private integer player_hash
		private integer code_length
		private integer value_count
		private integer array security_hash[6]
        private integer read_offset
		
		private NSL_PlayerLoadCallback on_loaded
		private NSL_PlayerSaveCallback on_saved
		
        integer code_version

		static method create_save takes integer player_id, NSL_PlayerSaveCallback on_saved returns NSL_Code
			local thistype inst = thistype.create(player_id)
			
			set inst.on_saved = on_saved
            set inst.code_version = NSL_CodeVersion
			
			return inst
		endmethod
		
		static method create_load takes integer player_id, string player_code, NSL_PlayerLoadCallback on_loaded returns nothing
			local thistype inst = thistype.create(player_id)
			
			set inst.player_code = player_code
			set inst.on_loaded = on_loaded
            set inst.code_version = -1
			
			if(not inst.Load()) then
				call on_loaded.execute(player_id, false, inst)
			endif
		endmethod
		
		private static method create takes integer player_id returns NSL_Code
			local thistype inst = thistype.allocate()
			
			set inst.player_id = player_id
			set inst.bits_count = 0
			set inst.is_started = false
			set inst.is_ready = false
			set inst.code_key = 0
			set inst.player_code = ""
			set inst.code_hash = 0
			set inst.player_hash = 0
			set inst.code_length = 0
			set inst.value_count = 0
            set inst.read_offset = 0
			
			call FlushChildHashtable(NSL_Hashtable, player_id)
			call FlushChildHashtable(NSL_HashtableValue, player_id)
			
			return inst
		endmethod
		
		private method StoreBit takes integer value returns nothing
			call SaveInteger(NSL_Hashtable, .player_id, NSL_HT_KEY_BITS_OFFSET + .bits_count, value)
			set .bits_count = .bits_count + 1
		endmethod 
		
		private method Pad takes integer length returns nothing
			local integer i = 0
			loop
				call StoreBit(0)
				set i = i + 1
				exitwhen i == length
			endloop
		endmethod
		
		private method InsertImpl takes integer value, integer size returns nothing
			local integer size_done = 0
			local integer exponent = size - 1
			local integer current = 0
			
			if(value == 0) then
				call .Pad(size)
				return
			endif
			
			loop
				set current = NSLHelper_TwoPow(exponent)
				if(value >= current) then
					call StoreBit(1)
					set size_done = size_done + 1
					set value = value - current
				else
					call StoreBit(0)
					set size_done = size_done + 1
				endif
				set exponent = exponent - 1
				if(size_done > size) then
					call BJDebugMsg("|cffff3333[Save Error]|r Invalid size")
				endif
				exitwhen value == 0
			endloop
			if(size_done < size) then
				call Pad(size - size_done)
			endif
		endmethod
		
		private method Insert takes nothing returns nothing
			local integer offset = LoadInteger(NSL_Hashtable, player_id, NSL_HT_KEY_PROGRESS_INDEX)
			if(offset == .value_count) then
				set .is_started = false
				set .is_ready = true
				call TimerStart(NSL_Timers[.player_id], 0.0, false, function GenerateTimerCallback)
				return
			endif

			if(.is_started) then
				call .InsertImpl(LoadInteger(NSL_HashtableValue, .player_id, offset * 2), LoadInteger(NSL_HashtableValue, .player_id, offset * 2 + 1))
				call SaveInteger(NSL_Hashtable, .player_id, NSL_HT_KEY_PROGRESS_INDEX, offset + 1)
				call TimerStart(NSL_Timers[.player_id], 0.0, false, function GenerateTimerCallback)
				return
			endif
			
			call SaveInteger(NSL_Hashtable, GetHandleId(NSL_Timers[.player_id]), NSL_HT_KEY_CODE_ID, this)
			call SaveInteger(NSL_Hashtable, .player_id, NSL_HT_KEY_PROGRESS_INDEX, 0)
			
			set .is_started = true
            call .InsertImpl(NSL_CodeVersion, NSL_SIZE_LESS_THAN_1024)
			call TimerStart(NSL_Timers[.player_id], 0.0, false, function GenerateTimerCallback)
		endmethod

		public method SV takes integer value, integer size returns nothing
            if(value < 0) then
                call BJDebugMsg("|cffff3333[Error]|r Attempting to save negative value !")
            endif
			call SaveInteger(NSL_HashtableValue, .player_id, .value_count * 2, value)
			call SaveInteger(NSL_HashtableValue, .player_id, .value_count * 2 + 1, size)
			set .value_count = .value_count + 1
		endmethod
		
		private method BitAt takes integer pos returns integer
			return LoadInteger(NSL_Hashtable, .player_id, NSL_HT_KEY_BITS_OFFSET + pos)
		endmethod
		
		private method EncodeImpl takes integer offset returns integer
			local integer last_index = IMinBJ(.bits_count, offset + NSL_BitPerChar)
			local integer value = 0
			local integer exponent = (last_index - offset) - 1
			local integer i = offset
			
			loop
				if(.BitAt(i) == 1) then
					set value = value + NSLHelper_TwoPow(exponent)
				endif
				set exponent = exponent - 1
				set i = i + 1
				exitwhen i == last_index
			endloop
			
			call SaveInteger(NSL_Hashtable, player_id, NSL_HT_KEY_PROGRESS_INDEX, last_index)
			return value
		endmethod
		
		private method Encode takes nothing returns integer
			local integer offset = LoadInteger(NSL_Hashtable, player_id, NSL_HT_KEY_PROGRESS_INDEX)
			if(offset == .bits_count) then
				return -1
			endif
			
			return .EncodeImpl(offset)
		endmethod
		
		private method GenerateSecurity takes nothing returns nothing
			set player_hash = GetPlayerHash(.player_id)
			
			set player_code = player_code + CharAt(ModuloInteger(code_hash, NSL_CharsetLen))
			set player_code = player_code + CharAt(ModuloInteger(code_hash / 2, NSL_CharsetLen))
			set player_code = player_code + CharAt(ModuloInteger(code_hash / 3, NSL_CharsetLen))
			
            set player_code = player_code + CharAt(ModuloInteger(player_hash, NSL_CharsetLen))
			set player_code = player_code + CharAt(ModuloInteger(player_hash / 4, NSL_CharsetLen))
			set player_code = player_code + CharAt(ModuloInteger(player_hash / 8, NSL_CharsetLen))

			set player_code = player_code + CharAt(ModuloInteger(.code_key, NSL_CharsetLen))
		endmethod
		
		private method GenerateImpl takes nothing returns nothing
			local integer value = .Encode()
			
			if(value == -1) then
				call .GenerateSecurity()
				call .on_saved.execute(.player_id, .player_code)
                call this.destroy()
				return
			endif
			
			set player_code = player_code + CharAt(ModuloInteger(value + code_hash, NSL_CharsetLen))
			set code_hash = code_hash + (value + .code_key) * NSL_Key			
            
			call TimerStart(NSL_Timers[.player_id], 0.0, false, function GenerateTimerCallback)
		endmethod
		
		public method Generate takes nothing returns nothing
			if(not .is_ready) then
				call .Insert()
				return
			endif
			if(.is_started) then
				call .GenerateImpl()
				return
			endif
			
			call SaveInteger(NSL_Hashtable, GetHandleId(NSL_Timers[.player_id]), NSL_HT_KEY_CODE_ID, this)
			call SaveInteger(NSL_Hashtable, player_id, NSL_HT_KEY_PROGRESS_INDEX, 0)
			
			if(ModuloInteger(.bits_count, NSL_BitPerChar) != 0) then
				call .Pad(NSL_BitPerChar - ModuloInteger(.bits_count, NSL_BitPerChar))
			endif

			set .is_started = true
			set .code_key = ModuloInteger(GetRandomInt(1, 2147483647), NSL_CharsetLen)
			set .code_hash = .code_key
			call TimerStart(NSL_Timers[.player_id], 0.0, false, function GenerateTimerCallback)
		endmethod

		private method Decode takes nothing returns integer
			local integer offset = LoadInteger(NSL_Hashtable, .player_id, NSL_HT_KEY_PROGRESS_INDEX)
			if(offset == .code_length) then
				return -1
			endif
			
			call SaveInteger(NSL_Hashtable, player_id, NSL_HT_KEY_PROGRESS_INDEX, offset + 1)
			return ModuloInteger(IndexOf(SubString(.player_code, offset, offset + 1)) - code_hash, NSL_CharsetLen)
		endmethod

		private method CheckSecurity takes nothing returns boolean
			if(.security_hash[0] != ModuloInteger(.code_hash, NSL_CharsetLen)) then
                return false
			endif
			if(.security_hash[1] != ModuloInteger(.code_hash / 2, NSL_CharsetLen)) then
				return false
			endif
			if(.security_hash[2] != ModuloInteger(.code_hash / 3, NSL_CharsetLen)) then
				return false
			endif
			return true
		endmethod

		private method LoadImpl takes nothing returns nothing
			local integer value = Decode()
			if(value == -1) then
                if(not .CheckSecurity()) then
					call .on_loaded.execute(.player_id, false, this)
				else
                    set .code_version = .ReadValueImpl(NSL_SIZE_LESS_THAN_1024)
					call .on_loaded.execute(.player_id, true, this)
				endif
				return
			endif
			
			call .InsertImpl(value, NSL_BitPerChar)
			set .code_hash = .code_hash + (value + .code_key) * NSL_Key
			call TimerStart(NSL_Timers[.player_id], 0.0, false, function LoadTimerCallback)
		endmethod

		public method Load takes nothing returns boolean
			if(.is_started) then
				call .LoadImpl()
				return true
			endif
			
			call SaveInteger(NSL_Hashtable, GetHandleId(NSL_Timers[.player_id]), NSL_HT_KEY_CODE_ID, this)
			call SaveInteger(NSL_Hashtable, player_id, NSL_HT_KEY_PROGRESS_INDEX, 0)
			
			set .is_started = true
			set .player_code = player_code
			set .code_length = StringLength(player_code) - 7
			set .player_hash = GetPlayerHash(.player_id)
			set .code_key = IndexOf(SubString(.player_code, code_length + 6, code_length + 7))
			set .code_hash = .code_key
			
			set .security_hash[0] = IndexOf(SubString(.player_code, code_length, code_length + 1))
			set .security_hash[1] = IndexOf(SubString(.player_code, code_length + 1, code_length + 2))
			set .security_hash[2] = IndexOf(SubString(.player_code, code_length + 2, code_length + 3))
			set .security_hash[3] = IndexOf(SubString(.player_code, code_length + 3, code_length + 4))
			set .security_hash[4] = IndexOf(SubString(.player_code, code_length + 4, code_length + 5))
			set .security_hash[5] = IndexOf(SubString(.player_code, code_length + 5, code_length + 6))
			
			if(security_hash[3] != (ModuloInteger(.player_hash, NSL_CharsetLen))) then
				return false
			endif
			
			if(security_hash[4] != (ModuloInteger(.player_hash / 4, NSL_CharsetLen))) then
				return false
			endif
			
			if(security_hash[5] != (ModuloInteger(.player_hash / 8, NSL_CharsetLen))) then
				return false
			endif
			
			call TimerStart(NSL_Timers[.player_id], 0.0, false, function LoadTimerCallback)
			return true
		endmethod
		
        private method ReadValueImpl takes integer size returns integer
            local integer value = 0
            local integer last_index = IMinBJ(.bits_count, .read_offset + size)
            local integer exponent = (last_index - .read_offset) - 1
            local integer i = .read_offset
            loop
                if(BitAt(i) == 1) then
                    set value = value + NSLHelper_TwoPow(exponent)
                endif
                set exponent = exponent - 1
                set i = i + 1
                exitwhen i == last_index
            endloop
            set .read_offset = last_index
            return value
        endmethod
        
        public method RV takes integer size returns integer
            if(.read_offset == .bits_count) then
                return -1
            endif
            
            return ReadValueImpl(size)
        endmethod
	endstruct
	
endlibrary