library PlayerUtils
/**************************************************************
*
*   v1.2.9 by TriggerHappy
*
*   This library provides a struct which caches data about players
*   as well as provides functionality for manipulating player colors.
*
*   Constants
*   ------------------
*
*       force FORCE_PLAYING - Player group of everyone who is playing.
*
*   Struct API
*   -------------------
*     struct User
*
*       static method fromIndex takes integer i returns User
*       static method fromLocal takes nothing returns User
*       static method fromPlaying takes integer id returns User
*
*       static method operator []    takes integer id returns User
*       static method operator count takes nothing returns integer
*
*       method operator name         takes nothing returns string
*       method operator name=        takes string name returns nothing
*       method operator color        takes nothing returns playercolor
*       method operator color=       takes playercolor c returns nothing
*       method operator defaultColor takes nothing returns playercolor
*       method operator hex          takes nothing returns string
*       method operator nameColored  takes nothing returns string
*
*       method toPlayer takes nothing returns player
*       method colorUnits takes playercolor c returns nothing
*
*       readonly string originalName
*       readonly boolean isPlaying
*       readonly static player Local
*       readonly static integer LocalId
*       readonly static integer AmountPlaying
*       readonly static playercolor array Color
*       readonly static player array PlayingPlayer
*
**************************************************************/

    globals
        constant force FORCE_PLAYING = CreateForce()
   
        private string array Name
        private string array Hex
        private string array OriginalHex
        private playercolor array CurrentColor
    endglobals

    private keyword PlayerUtilsInit

    struct User extends array
     
        static constant integer NULL = bj_MAX_PLAYER_SLOTS
       
        readonly player handle
        readonly integer id
        readonly thistype next
        readonly thistype prev

        readonly string originalName
        readonly boolean isPlaying
   
        readonly static thistype first
        readonly static thistype last
        readonly static player Local
        readonly static integer LocalId
        readonly static integer AmountPlaying = 0
        readonly static playercolor array Color
        private static thistype array PlayingPlayer
        private static integer array PlayingPlayerIndex
   
        // similar to Player(#)
        static method fromIndex takes integer i returns thistype
            return thistype(i)
        endmethod
   
        // similar to GetLocalPlayer
        static method fromLocal takes nothing returns thistype
            return thistype(thistype.LocalId)
        endmethod
   
        // access active players array
        static method fromPlaying takes integer index returns thistype
            return PlayingPlayer[index]
        endmethod
   
        static method operator [] takes player p returns thistype
            return thistype(GetPlayerId(p))
        endmethod
   
        method toPlayer takes nothing returns player
            return this.handle
        endmethod
     
        method operator name takes nothing returns string
           return GetPlayerName(this.handle)
        endmethod
   
        method operator name= takes string newName returns nothing
            call SetPlayerName(this.handle, newName)
        endmethod
   
        method operator color takes nothing returns playercolor
           return GetPlayerColor(this.handle)
        endmethod
   
        method operator hex takes nothing returns string
            return OriginalHex[GetHandleId(this.color)]
        endmethod
   
        method operator color= takes playercolor c returns nothing
            call SetPlayerColor(this.handle, c)
        endmethod
   
        method operator defaultColor takes nothing returns playercolor
            return Color[this]
        endmethod
   
        method operator nameColored takes nothing returns string
            return hex + this.name + "|r"
        endmethod
   
        static method onLeave takes nothing returns boolean
            local thistype p  = thistype[GetTriggerPlayer()]
            local integer i   = .PlayingPlayerIndex[p.id]
       
            // clean up
            call ForceRemovePlayer(FORCE_PLAYING, p.toPlayer())
       
            // recycle index
            set .AmountPlaying = .AmountPlaying - 1
            set .PlayingPlayerIndex[i] = .PlayingPlayerIndex[.AmountPlaying]
            set .PlayingPlayer[i] = .PlayingPlayer[.AmountPlaying]
           
            if (.AmountPlaying == 1) then
                set p.prev.next = User.NULL
                set p.next.prev = User.NULL
            else
                set p.prev.next = p.next
                set p.next.prev = p.prev
            endif

            set .last = .PlayingPlayer[.AmountPlaying]
           
            set p.isPlaying = false
       
            return false
        endmethod
   
        implement PlayerUtilsInit
   
    endstruct

    private module PlayerUtilsInit
        private static method onInit takes nothing returns nothing
            local trigger t = CreateTrigger()
            local integer i = 0
            local thistype p
       
            set thistype.Local   = GetLocalPlayer()
            set thistype.LocalId = GetPlayerId(thistype.Local)
       
            set OriginalHex[0]  = "|cffff0303"
            set OriginalHex[1]  = "|cff0042ff"
            set OriginalHex[2]  = "|cff1ce6b9"
            set OriginalHex[3]  = "|cff540081"
            set OriginalHex[4]  = "|cfffffc01"
            set OriginalHex[5]  = "|cfffe8a0e"
            set OriginalHex[6]  = "|cff20c000"
            set OriginalHex[7]  = "|cffe55bb0"
            set OriginalHex[8]  = "|cff959697"
            set OriginalHex[9]  = "|cff7ebff1"
            set OriginalHex[10] = "|cff106246"
            set OriginalHex[11] = "|cff4e2a04"
            
            if (bj_MAX_PLAYERS > 12) then
                set OriginalHex[12] = "|cff9B0000"
                set OriginalHex[13] = "|cff0000C3"
                set OriginalHex[14] = "|cff00EAFF"
                set OriginalHex[15] = "|cffBE00FE"
                set OriginalHex[16] = "|cffEBCD87"
                set OriginalHex[17] = "|cffF8A48B"
                set OriginalHex[18] = "|cffBFFF80"
                set OriginalHex[19] = "|cffDCB9EB"
                set OriginalHex[20] = "|cff282828"
                set OriginalHex[21] = "|cffEBF0FF"
                set OriginalHex[22] = "|cff00781E"
                set OriginalHex[23] = "|cffA46F33"
            endif
         
            set thistype.first = User.NULL

            loop
                exitwhen i == bj_MAX_PLAYERS

                set p         = User(i)
                set p.handle  = Player(i)
                set p.id      = i
           
                set thistype.Color[i] = GetPlayerColor(p.handle)
                set CurrentColor[i] = thistype.Color[i]
             
                if (GetPlayerController(p.handle) == MAP_CONTROL_USER and GetPlayerSlotState(p.handle) == PLAYER_SLOT_STATE_PLAYING) then

                    set .PlayingPlayer[AmountPlaying] = p
                    set .PlayingPlayerIndex[i] = .AmountPlaying
                   
                   set .last = i
                   
                    if (.first == User.NULL) then
                        set .first = i
                        set User(i).next = User.NULL
                        set User(i).prev = User.NULL
                    else
                        set User(i).prev = PlayingPlayer[AmountPlaying-1].id
                        set PlayingPlayer[AmountPlaying-1].next = User(i)
                        set User(i).next = User.NULL
                    endif

                    set p.isPlaying = true
               
                    call TriggerRegisterPlayerEvent(t, p.handle, EVENT_PLAYER_LEAVE)
                    call ForceAddPlayer(FORCE_PLAYING, p.handle)
               
                    set Hex[p] = OriginalHex[GetHandleId(thistype.Color[i])]
               
                    set .AmountPlaying = .AmountPlaying + 1

                endif
           
                set Name[p] = GetPlayerName(p.handle)
                set p.originalName=Name[p]
           
                set i = i + 1
            endloop
       
            call TriggerAddCondition(t, Filter(function thistype.onLeave))
        endmethod
    endmodule

    //===========================================================================

	public function Print takes integer playerId, string str returns nothing
		call DisplayTimedTextToPlayer(Player(playerId), 0, 0, 5.0, str)
	endfunction

endlibrary