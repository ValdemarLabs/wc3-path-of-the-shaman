library Track /* v3.1.0.0
*****************************************************************************
*
*  Manages trackable objects, allowing for easy event registrations, data
*  retrieval, and the capability of retrieving which player interacted with
*  the trackable.
*
*****************************************************************************
*
*   */uses/*
*
*       */ Table /*   hiveworkshop.com/forums/jass-functions-413/snippet-new-table-188084/ 
*
*****************************************************************************
*
*  SETTINGS
*/
globals
    private constant integer PLATFORM = 'OTip'
endglobals
/*
*****************************************************************************
*
*  FUNCTIONS
*
*      CreateTrack( string modelPath, real x, real y, real z, real facing ) returns Track
*        - Creates a trackable of modelPath at coordinates ( x, y, z ) with
*        - "facing" in radians. Returns the trackable instance.
*
*      CreateTrackForPlayer( string modelPath, real x, real y, real z, real facing, player who ) returns Track
*        - Same as function above, but creates it for one player.
*
*      RegisterAnyClickEvent( code c ) returns nothing 
*      RegisterAnyHoverEvent( code c ) returns nothing 
*        - Fires "c" when any trackable is clicked or hovered.
*
*      RegisterClickEvent( Track obj, code c ) returns nothing
*      RegisterHoverEvent( Track obj, code c ) returns nothing
*        - Fires "c" when the trackable of "obj" is clicked or hovered respectively.
*      RegisterInteractEvent( Track obj, code c ) returns nothing
*        - Fires "c" when the trackable of "obj" is clicked or hovered.
*        - Use GetTriggerEventId() == EVENT_GAME_TRACKABLE_TRACK
*          to differentiate between the two event occurrences. This
*          method is more efficient on handles than the two above.
*
*      EnableTrackInstance( Track obj, boolean flag ) returns nothing
*        - A disabled Track instance will not fire its events.
*        - Track instances are enabled by default.
*      IsTrackInstanceEnabled( Track obj ) returns boolean
*        - Returns whether an instance is enabled.
*
*  EVENT RESPONSES
*
*      GetTriggerTrackInstance() returns Track
*        - Returns the Track instance that had a player interaction.
*      GetTriggerTrackable() returns trackable
*        - Returns the trackable object that had a player interaction.
*      GetTriggerTrackablePlayer() returns player
*        - Returns the player that interacted with the trackable object.
*
*****************************************************************************
*
*   struct Track
*
*        static Track instance
*           - The triggering instance of the event.
*        static trackable object
*           - The triggering trackable object of the event.
*        static player tracker
*           - The player who interacted with the trackable object.
*
*        readonly real x
*        readonly real y
*        readonly real z
*        readonly real facing
*        readonly string model
*           - Instance properties.
*           - Warning: the invisible platform has a default z-value
*             of 2.94794. So if you input 0 into the system, it'll
*             end up ~3 units above the ground. For an alternative model,
*             see: [url]http://www.hiveworkshop.com/forums/2661555-post54.html[/url]
*
*        method operator enabled= takes boolean flag returns nothing
*        method operator enabled takes nothing returns boolean
*        
*        static method create takes string modelPath, real x, real y, real z, real facing returns Track
*        static method createForPlayer takes string modelPath, real x, real y, real z, real facing, player p returns Track
*
*        static method registerAnyClick takes code c returns nothing
*        static method registerAnyHover takes code c returns nothing
*
*        method registerClick takes code c returns nothing
*        method registerHover takes code c returns nothing
*        method registerInteract takes code c returns nothing
*
*            - All equivalent to their function counterparts.
*
*****************************************************************************
*    
*    Credits
*       - Azlier: Trackable2 (inspiration)
*       - Arhowk: bugfix
*       - Dalvengyr: bugfix from a typo.
*       - Uberplayer: bugfix; info on the invisible platform Z issue.
*
****************************************************************************/
    
    private module Init
        private static method onInit takes nothing returns nothing
            set thistype.TrackTable = Table.create()
        endmethod
    endmodule

    struct Track extends array
        private static trigger anyClick = CreateTrigger()
        private static trigger anyHover = CreateTrigger()
        private static Table TrackTable = 0
        
        static thistype  instance = 0
        static trackable object   = null
        static player    tracker  = null
        
        private static integer ic = 0
        private static integer ir = 0
        private thistype rn
        
        readonly real    x
        readonly real    y
        readonly real    z
        readonly real    facing
        readonly string  model
        
        private trigger  reg
        private trigger  onClick
        private trigger  onHover
        private Table    playerIndex
        
        boolean  enabled
        
        static method registerAnyClick takes code c returns nothing
            call TriggerAddCondition(.anyClick, Filter(c))
        endmethod
        static method registerAnyHover takes code c returns nothing
            call TriggerAddCondition(.anyHover, Filter(c))
        endmethod
        
        method registerClick takes code c returns nothing
            if .onClick == null then
                set .onClick = CreateTrigger()
            endif
            call TriggerAddCondition(.onClick, Filter(c))
        endmethod
        method registerHover takes code c returns nothing
            if .onHover == null then
                set .onHover = CreateTrigger()
            endif
            call TriggerAddCondition(.onHover, Filter(c))
        endmethod
        method registerInteract takes code c returns nothing
            call TriggerAddCondition(.reg, Filter(c))
        endmethod
        
        method destroy takes nothing returns nothing
            call TrackTable.remove(GetHandleId(.reg))
            call DestroyTrigger(.reg)
            call DestroyTrigger(.onClick)
            call DestroyTrigger(.onHover)
            call .playerIndex.destroy()
            set .rn = ir
            set ir  = this
        endmethod
        
        private static method onInteract takes nothing returns boolean
            set instance = TrackTable[GetHandleId(GetTriggeringTrigger())]
            
            if instance.enabled then
                set object  = GetTriggeringTrackable()
                set tracker = Player(instance.playerIndex[GetHandleId(object)])
                
                if GetTriggerEventId() == EVENT_GAME_TRACKABLE_TRACK then
                    call TriggerEvaluate(instance.onHover)
                    call TriggerEvaluate(anyHover)
                else
                    call TriggerEvaluate(instance.onClick)
                    call TriggerEvaluate(anyClick)
                endif
            endif
            
            return false
        endmethod
        
        private static method createTrack takes string modelPath, real x, real y, real z, real facing, player j returns thistype
            local destructable dest = null
            local thistype     this = ir
            local integer      i    = 11
            local trackable tr 
            local player p
            local string s
            
            /* Allocate */
            if this == 0 then
                set ic   = ic + 1
                set this = ic
            else
                set ir = .rn
            endif
            
            /* Create platform to give the trackable a z-offset */
            if z != 0 then
                set dest = CreateDestructableZ(PLATFORM, x, y, z, 0, 1, 0)
            endif
            if j != null then
                set i = GetPlayerId(j)
            endif
            
            set .x = x 
            set .y = y
            set .z = z
            set .enabled = true
            set .facing  = facing
            set .model   = modelPath
            set .reg     = CreateTrigger()
            set .onClick = null
            set .onHover = null
            set .playerIndex = Table.create()
            
            set TrackTable[GetHandleId(.reg)] = this
            call TriggerAddCondition(.reg, Condition(function thistype.onInteract))
            
            /* Create a separate trackable for each player playing */
            loop
                set p = Player(i)
                if GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(p) == MAP_CONTROL_USER then
                    if GetLocalPlayer() == p then
                        set s = modelPath
                    else
                        set s = ""
                    endif 
                    set tr = CreateTrackable(s, .x, .y, .facing)
                    call TriggerRegisterTrackableHitEvent(.reg, tr)
                    call TriggerRegisterTrackableTrackEvent(.reg, tr)
                    set .playerIndex[GetHandleId(tr)] = i
                    exitwhen j != null
                endif
                exitwhen i == 0
                set i = i - 1
            endloop
            
            /* Remove the platform if it exists */
            if dest != null then
                call RemoveDestructable(dest)
                set dest = null
            endif
            set p  = null
            set tr = null
            
            return this
        endmethod
        
        static method create takes string modelPath, real x, real y, real z, real facing returns thistype
            return thistype.createTrack(modelPath, x, y, z, facing, null)
        endmethod 
        
        static method createForPlayer takes string modelPath, real x, real y, real z, real facing, player p returns thistype
            if not (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(p) == MAP_CONTROL_USER) then
                return 0
            endif
            return thistype.createTrack(modelPath, x, y, z, facing, p)
        endmethod
        
        implement Init
    endstruct
    
    /* Function Wrappers */
    
    function CreateTrack takes string modelPath, real x, real y, real z, real facing returns Track
        return Track.create(modelPath, x, y, z, facing)
    endfunction
    
    function CreateTrackForPlayer takes string modelPath, real x, real y, real z, real facing, player who returns Track 
        return Track.createForPlayer(modelPath, x, y, z, facing, who)
    endfunction
    
    function EnableTrackInstance takes Track instance, boolean flag returns nothing
        set instance.enabled = flag
    endfunction
    
    function IsTrackInstanceEnabled takes Track instance returns boolean
        return instance.enabled
    endfunction
    
    function RegisterAnyClickEvent takes code c returns nothing
        call Track.registerAnyClick(c)
    endfunction
    
    function RegisterAnyHoverEvent takes code c returns nothing
        call Track.registerAnyHover(c)
    endfunction
    
    function RegisterClickEvent takes Track obj, code c returns nothing
        call obj.registerClick(c)
    endfunction
    
    function RegisterHoverEvent takes Track obj, code c returns nothing
        call obj.registerHover(c)
    endfunction
    
    function RegisterInteractEvent takes Track obj, code c returns nothing
        call obj.registerInteract(c)
    endfunction
    
    function GetTriggerTrackInstance takes nothing returns Track
        return Track.instance
    endfunction
    
    function GetTriggerTrackable takes nothing returns trackable
        return Track.object
    endfunction
    
    function GetTriggerTrackablePlayer takes nothing returns player
        return Track.tracker
    endfunction
endlibrary