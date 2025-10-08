// Last checked for update: 2023 Oct 02

library Table /* made by Bribe, special thanks to Vexorian & Nestharus, version 5.1.0.0

    One map, one hashtable. Welcome to NewTable.

    This latest version of Table introduces the following API:
    Table2D (the new alias for the HashTable struct)
    Table2DT (the new alias for the HashTableEx struct)
    Table3D, Table4D and Table 5D.

    More N-dimensional tables can be quickly generated if needed. Scroll to the
    bottom of this script to find the textmacro TableXD.

    Special thanks to @emperor_d3st for the inspiration for this update.

    API

    ------------
    struct Table
    | static method create takes nothing returns Table
    |     create a new Table
    |
    | method destroy takes nothing returns nothing
    |     destroy it
    |
    | method flush takes nothing returns nothing
    |     flush all stored values inside of it
    |
    | method remove takes integer key returns nothing
    |     remove the value at index "key"
    |
    | method operator []= takes integer key, $TYPE$ value returns nothing
    |     assign "value" to index "key"
    |
    | method operator [] takes integer key returns $TYPE$
    |     load the value at index "key"
    |
    | method has takes integer key returns boolean
    |     whether or not the key was assigned
    |
    ----------------
    struct TableArray
    | static method operator [] takes integer array_size returns TableArray
    |     create a new array of Tables of size "array_size"
    |
    | method destroy takes nothing returns nothing
    |     destroy it
    |
    | method flush takes nothing returns nothing
    |     flush and destroy it
    |
    | method operator size takes nothing returns integer
    |     returns the size of the TableArray
    |
    | method operator [] takes integer key returns Table
    |     returns a Table accessible exclusively to index "key"
*/

globals
    private integer tableIDGenerator = 8190  //Index generation for Tables starts from here. Configure it if your map contains more than this many structs or 'key' objects.

    private hashtable ht = InitHashtable() // The last hashtable.

    private constant boolean TEST = true       // set to `true` to enable error messages and `print`/`toString` API.
    private constant boolean DEEP_TEST = false // set to `true` to enable informational messages.

    private keyword instanceData
endglobals

private struct handles extends array
    method operator []= takes integer key, handle h returns nothing
        if h != null then
            // "But I need hashtables to typecast generic handles into ..." - say no more. I got u fam.
            call SaveFogStateHandle(ht, this, key, ConvertFogState(GetHandleId(h)))
        elseif HaveSavedHandle(ht, this, key) then
            // table.handle[key] = null becomes an alias for table.handle.remove(key)
            call RemoveSavedHandle(ht, this, key)
        endif
    endmethod
    method has takes integer key returns boolean
        return HaveSavedHandle(ht, this, key)
    endmethod
    method remove takes integer key returns nothing
        call RemoveSavedHandle(ht, this, key)
    endmethod
endstruct

private struct agents extends array
    method operator []= takes integer key, agent value returns nothing
        call SaveAgentHandle(ht, this, key, value)
    endmethod
endstruct

//! textmacro NEW_ARRAY_BASIC takes SUPER, FUNC, TYPE
private struct $TYPE$s extends array
    method operator [] takes integer key returns $TYPE$
        return Load$FUNC$(ht, this, key)
    endmethod
    method operator []= takes integer key, $TYPE$ value returns nothing
        call Save$FUNC$(ht, this, key, value)
    endmethod
    method has takes integer key returns boolean
        return HaveSaved$SUPER$(ht, this, key)
    endmethod
    method remove takes integer key returns nothing
        call RemoveSaved$SUPER$(ht, this, key)
    endmethod
endstruct
private module $TYPE$m
    method operator $TYPE$ takes nothing returns $TYPE$s
        return this
    endmethod
endmodule
//! endtextmacro

//! textmacro NEW_ARRAY takes FUNC, TYPE
private struct $TYPE$s extends array
    method operator [] takes integer key returns $TYPE$
        return Load$FUNC$Handle(ht, this, key)
    endmethod
    method operator []= takes integer key, $TYPE$ value returns nothing
        call Save$FUNC$Handle(ht, this, key, value)
    endmethod
    method has takes integer key returns boolean
        return HaveSavedHandle(ht, this, key)
    endmethod
    method remove takes integer key returns nothing
        call RemoveSavedHandle(ht, this, key)
    endmethod
endstruct
private module $TYPE$m
    method operator $TYPE$ takes nothing returns $TYPE$s
        return this
    endmethod
endmodule
//! endtextmacro

/*
    Create API for stuff like:
        set table.unit[key] = GetTriggerUnit()
        local boolean b = table.handle.has(key)
        local unit u = table.unit[key]
        set table.handle.remove(key)
*/

//Run these textmacros to include the entire hashtable API as wrappers.
//Don't be intimidated by the number of macros - Vexorian's map optimizer is
//supposed to kill functions which inline (all of these functions inline).
//! runtextmacro NEW_ARRAY_BASIC("Real", "Real", "real")
//! runtextmacro NEW_ARRAY_BASIC("Boolean", "Boolean", "boolean")
//! runtextmacro NEW_ARRAY_BASIC("String", "Str", "string")
//! runtextmacro NEW_ARRAY_BASIC("Integer", "Integer", "integer")

//! runtextmacro NEW_ARRAY("Player", "player")
//! runtextmacro NEW_ARRAY("Widget", "widget")
//! runtextmacro NEW_ARRAY("Destructable", "destructable")
//! runtextmacro NEW_ARRAY("Item", "item")
//! runtextmacro NEW_ARRAY("Unit", "unit")
//! runtextmacro NEW_ARRAY("Ability", "ability")
//! runtextmacro NEW_ARRAY("Timer", "timer")
//! runtextmacro NEW_ARRAY("Trigger", "trigger")
//! runtextmacro NEW_ARRAY("TriggerCondition", "triggercondition")
//! runtextmacro NEW_ARRAY("TriggerAction", "triggeraction")
//! runtextmacro NEW_ARRAY("TriggerEvent", "event")
//! runtextmacro NEW_ARRAY("Force", "force")
//! runtextmacro NEW_ARRAY("Group", "group")
//! runtextmacro NEW_ARRAY("Location", "location")
//! runtextmacro NEW_ARRAY("Rect", "rect")
//! runtextmacro NEW_ARRAY("BooleanExpr", "boolexpr")
//! runtextmacro NEW_ARRAY("Sound", "sound")
//! runtextmacro NEW_ARRAY("Effect", "effect")
//! runtextmacro NEW_ARRAY("UnitPool", "unitpool")
//! runtextmacro NEW_ARRAY("ItemPool", "itempool")
//! runtextmacro NEW_ARRAY("Quest", "quest")
//! runtextmacro NEW_ARRAY("QuestItem", "questitem")
//! runtextmacro NEW_ARRAY("DefeatCondition", "defeatcondition")
//! runtextmacro NEW_ARRAY("TimerDialog", "timerdialog")
//! runtextmacro NEW_ARRAY("Leaderboard", "leaderboard")
//! runtextmacro NEW_ARRAY("Multiboard", "multiboard")
//! runtextmacro NEW_ARRAY("MultiboardItem", "multiboarditem")
//! runtextmacro NEW_ARRAY("Trackable", "trackable")
//! runtextmacro NEW_ARRAY("Dialog", "dialog")
//! runtextmacro NEW_ARRAY("Button", "button")
//! runtextmacro NEW_ARRAY("TextTag", "texttag")
//! runtextmacro NEW_ARRAY("Lightning", "lightning")
//! runtextmacro NEW_ARRAY("Image", "image")
//! runtextmacro NEW_ARRAY("Ubersplat", "ubersplat")
//! runtextmacro NEW_ARRAY("Region", "region")
//! runtextmacro NEW_ARRAY("FogState", "fogstate")
//! runtextmacro NEW_ARRAY("FogModifier", "fogmodifier")
//! runtextmacro NEW_ARRAY("Hashtable", "hashtable")

struct Table extends array

    static Table instanceData = thistype.typeid

    // Implement modules for handle/agent/integer/real/boolean/string/etc syntax.
    implement realm
    implement integerm
    implement booleanm
    implement stringm
    implement playerm
    implement widgetm
    implement destructablem
    implement itemm
    implement unitm
    implement abilitym
    implement timerm
    implement triggerm
    implement triggerconditionm
    implement triggeractionm
    implement eventm
    implement forcem
    implement groupm
    implement locationm
    implement rectm
    implement boolexprm
    implement soundm
    implement effectm
    implement unitpoolm
    implement itempoolm
    implement questm
    implement questitemm
    implement defeatconditionm
    implement timerdialogm
    implement leaderboardm
    implement multiboardm
    implement multiboarditemm
    implement trackablem
    implement dialogm
    implement buttonm
    implement texttagm
    implement lightningm
    implement imagem
    implement ubersplatm
    implement regionm
    implement fogstatem
    implement fogmodifierm
    implement hashtablem

    method operator handle takes nothing returns handles
        return this
    endmethod

    method operator agent takes nothing returns agents
        return this
    endmethod

    method operator [] takes integer key returns Table
        return this.integer[key]
    endmethod

    method operator []= takes integer key, Table tab returns nothing
        set this.integer[key] = tab
    endmethod

    method has takes integer key returns boolean
        return this.integer.has(key)
    endmethod

    method remove takes integer key returns nothing
        call this.integer.remove(key)
    endmethod

    // Remove all keys and values from a Table instance
    method flush takes nothing returns nothing
        call FlushChildHashtable(ht, this)
    endmethod

    // Returns a new Table instance that can store any hashtable-compatible data types.
    static method create takes nothing returns Table
        local Table this = instanceData[0]

        if this == 0 then
            set this = tableIDGenerator + 1
            set tableIDGenerator = this
            static if DEEP_TEST then
                call BJDebugMsg("Creating Table: " + I2S(this))
            endif
        else
            set instanceData[0] = instanceData[this]
            static if DEEP_TEST then
                call BJDebugMsg("Re-using Table: " + I2S(this))
            endif
        endif

        set instanceData[this] = -1
        return this
    endmethod

    // Removes all data from a Table instance and recycles its index.
    method destroy takes nothing returns nothing
        call flush()

        if instanceData[this] != -1 then
            static if TEST then
                call BJDebugMsg("Table Error: Tried to double-free instance: " + I2S(this))
            endif
            return
        endif

        static if DEEP_TEST then
            call BJDebugMsg("Destroying Table: " + I2S(this))
        endif

        set instanceData[this] = instanceData[0]
        set instanceData[0] = this
    endmethod

    //! runtextmacro optional TABLE_BC_METHODS()
endstruct

//! runtextmacro optional TABLE_BC_STRUCTS()

struct TableArray extends array

    private static integer keyGen = 0
    private static Table arraySizes = thistype.typeid

    //Returns a new TableArray to do your bidding. Simply use:
    //
    //    local TableArray ta = TableArray[array_size]
    //
    static method operator [] takes integer array_size returns TableArray
        local Table recycleList = arraySizes[array_size] //Get the unique recycle list for this array size
        local TableArray this = recycleList[0]           //The last-destroyed TableArray that had this array size

        if array_size <= 0 then
            static if TEST then
                call BJDebugMsg("TypeError: Invalid specified TableArray size: " + I2S(array_size))
            endif
            return 0
        endif

        if this == 0 then
            set this = keyGen - array_size
            set keyGen = this
        else
            set recycleList[0] = recycleList[this]  //Set the last destroyed to the last-last destroyed
            call recycleList.remove(this)  //Clear hashed memory
        endif

        set arraySizes[this] = array_size
        return this
    endmethod

    //Returns the size of the TableArray
    method operator size takes nothing returns integer
        return arraySizes[this]
    endmethod

    //This magic method enables two-dimensional[array][syntax] for Tables,
    //similar to the two-dimensional utility provided by hashtables them-
    //selves.
    //
    //ta[integer a].unit[integer b] = unit u
    //ta[integer a][integer c] = integer d
    //
    //Inline-friendly when not running in `TEST` mode
    //
    method operator [] takes integer key returns Table
        static if TEST then
            local integer i = size
            if i == 0 then
                call BJDebugMsg("IndexError: Tried to get key from invalid TableArray instance: " + I2S(this))
                return 0
            elseif key < 0 or key >= i then
                call BJDebugMsg("IndexError: Tried to get key [" + I2S(key) + "] from outside TableArray bounds: " + I2S(i))
                return 0
            endif
        endif
        return this + key
    endmethod

    //Destroys a TableArray without flushing it; I assume you call .flush()
    //if you want it flushed too. This is a public method so that you don't
    //have to loop through all TableArray indices to flush them if you don't
    //need to (ie. if you were flushing all child-keys as you used them).
    //
    method destroy takes nothing returns nothing
        local Table recycleList = arraySizes[size]

        if size == 0 then
            static if TEST then
                call BJDebugMsg("TypeError: Tried to destroy an invalid TableArray: " + I2S(this))
            endif
            return
        endif

        if recycleList == 0 then
            //Create a Table to index recycled instances with their array size
            set recycleList = Table.create()
            set arraySizes[size] = recycleList
        endif

        call arraySizes.remove(this) //Clear the array size from hash memory

        set recycleList[this] = recycleList[0]
        set recycleList[0] = this
    endmethod

    private static Table tempTable
    private static integer tempEnd

    //Avoids hitting the op limit
    private static method clean takes nothing returns nothing
        local Table tab = tempTable
        local integer end = tab + 0x1000
        if end < tempEnd then
            set tempTable = end
            call ForForce(bj_FORCE_PLAYER[0], function thistype.clean)
        else
            set end = tempEnd
        endif
        loop
            call tab.flush()
            set tab = tab + 1
            exitwhen tab == end
        endloop
    endmethod

    //Flushes the TableArray and also destroys it. Doesn't get any more
    //similar to the FlushParentHashtable native than this.
    method flush takes nothing returns nothing
        if size == 0 then
            static if TEST then
                call BJDebugMsg("TypeError: Tried to flush an invalid TableArray instance: " + I2S(this))
            endif
            return
        endif
        set tempTable = this
        set tempEnd = this + size
        call ForForce(bj_FORCE_PLAYER[0], function thistype.clean)
        call destroy()
    endmethod

endstruct

// Added in version 4.0, renamed from HashTable to Table2D in 5.1.
struct Table2D extends array

    //Enables myHash[parentKey][childKey] syntax.
    //Basically, it creates a Table in the place of the parent key if
    //it didn't already get created earlier.
    method operator [] takes integer index returns Table
        local Table tab = Table(this)[index]
        if tab == 0 then
            set tab = Table.create()
            set Table(this)[index] = tab
        endif
        return tab
    endmethod

    //You need to call this on each parent key that you used if you
    //intend to destroy the Table2D or simply no longer need that key.
    method remove takes integer index returns nothing
        local Table tab = Table(this)[index]
        if tab != 0 then
            call Table(this).remove(index)
            if Table.instanceData[tab] == -1 then
                call tab.destroy()
            else
                static if TEST then
                    call BJDebugMsg("Table2D Error: Inactive Table " + I2S(tab) + " used as key of Table2D " + I2S(this) + " at index " + I2S(index))
                endif
            endif
        else
            static if TEST then
                call BJDebugMsg("Table2D Warning: " + I2S(tab) + " does not contain anything at index " + I2S(index))
            endif
        endif
    endmethod

    method has takes integer index returns boolean
        return Table(this).has(index)
    endmethod

    method destroy takes nothing returns nothing
        call Table(this).destroy()
    endmethod

    static method create takes nothing returns thistype
        return Table.create()
    endmethod

endstruct

// Added in Table 5.0. Similar to the Table2D struct, but with the
// ability to log each value saved into the Table2DT to automate
// deallocation.
struct Table2DT extends array

    private static Table2D tracker = Table2D.typeid
    private static Table seenTables = thistype.typeid

    method operator [] takes integer index returns Table
        local integer i
        local Table innerTable = Table(this)[index]
        local Table trackingTable

        if innerTable == 0 then
            // If this key was never referenced before, create a table to handle this depth:
            set innerTable = Table.create()
            set Table(this)[index] = innerTable

            set trackingTable = tracker[this]          //get the tracking table
            set i = trackingTable[0] + 1               //increase its size
            set trackingTable[0] = i                   //save that size
            set trackingTable[i] = index               //index the user's index to the tracker's slot at 'size'
            static if DEEP_TEST then
                call BJDebugMsg("Increasing tracked table size to " + I2S(i))
            endif
        endif
        static if DEEP_TEST then
            call BJDebugMsg("Tracked-Table(" + I2S(this) + ")[" + I2S(index) + "] => " + I2S(innerTable))
        endif
        return innerTable
    endmethod

    method has takes integer index returns boolean
        return Table(this).has(index)
    endmethod

    private method flushAndDestroy takes nothing returns nothing
        local Table trackTable = tracker[this]
        local integer i = trackTable[0] //get the number of tracked indices
        local Table tab
        local integer tableStatus

        // Mark this table as seen to avoid potentially-infinite recursion
        set seenTables.boolean[this] = true

        loop
            exitwhen i == 0
            set tab = Table(this)[trackTable[i]] // Get the actual table using the index from trackTable
            if tab != 0 then
                if Table.instanceData[tab] == -1 then
                    if tracker.has(tab) and not seenTables.boolean[tab] then
                        call thistype(tab).flushAndDestroy()
                    else
                        call tab.destroy()
                    endif
                endif
            endif
            set i = i - 1
        endloop

        // Now destroy the tracking table and the table itself
        call trackTable.destroy()  //clear tracking sub-table
        call Table(tracker).remove(this)  //clear reference to that table
        call Table(this).destroy()
    endmethod

    method destroy takes nothing returns nothing
        if Table.instanceData[this] != -1 then
            static if TEST then
                call BJDebugMsg("Table2DT Error: Tried to double-free: " + I2S(this))
            endif
            return
        endif
        call flushAndDestroy()
        call seenTables.flush()
    endmethod

    //Extremely inefficient, but gets the job done if needed.
    method remove takes integer index returns nothing
        local integer i
        local integer j
        local Table innerTable = Table(this)[index]
        local Table trackingTable = tracker[this]
        if Table.instanceData[this] != -1 then
            static if TEST then
                call BJDebugMsg("Table2DT Error: Tried to remove index " + I2S(index) + " from destroyed Tracked-Table(" + I2S(this) + ")")
            endif
        endif
        if innerTable == 0 then
            static if TEST then
                call BJDebugMsg("Table2DT Error: " + I2S(this) + " does not have any indices to remove, so could not remove: " + I2S(index))
            endif
            return
        endif
        call Table(this).remove(index)
        if Table.instanceData[innerTable] != -1 then
            static if TEST then
                call BJDebugMsg("Table2DT Error: " + I2S(this) + " contains destroyed table " + I2S(innerTable) + " at key: " + I2S(index))
            endif
            return
        endif
        if tracker.has(innerTable) then
            call thistype(innerTable).destroy()
        else
            call innerTable.destroy()
        endif
        set i = trackingTable[0]
        set j = i
        loop
            if (i == 0) then
                static if TEST then
                    call BJDebugMsg("Table2DT Error: Tried to remove index: " + I2S(index) + " which does not exist in " + I2S(this))
                endif
                return
            endif
            exitwhen trackingTable[i] == index //removal is o(n) based
            set i = i - 1
        endloop
        if i < j then
            set trackingTable[i] = trackingTable[j] //pop last item in the stack and insert in place of this removed item
        endif
        call trackingTable.remove(j) //free reference to the index
        set trackingTable[0] = j - 1 //decrease size of stack
    endmethod

    static method create takes nothing returns thistype
        local thistype this = Table.create()
        set tracker[this][0] = 0
        return this
    endmethod

    static if TEST then
        private method toStringFn takes integer depth returns string
            local Table trackTable = Table(tracker)[this]
            local integer i = trackTable[0]
            local thistype tab
            local string indent = ""
            local integer k = 0
            local string output
            local integer index
            local integer data

            // Determine if this is a tracked table and if it's already been seen
            if trackTable != 0 then
                if seenTables.boolean[this] then
                    return "Tracked-Table(" + I2S(this) + ")"
                endif
                set seenTables.boolean[this] = true
                if i == 0 then
                    return "Tracked-Table(" + I2S(this) + ")[-]"
                endif
                set output = "Tracked-Table(" + I2S(this) + ")["
            else
                set data = Table.instanceData[this]
                if data == -1 then
                    return "Table(" + I2S(this) + ")[?]"
                elseif data > 0 then
                    return "DESTROYED Table(" + I2S(this) + ")"
                else
                    return I2S(this)
                endif
            endif

            loop
                exitwhen k == depth
                set indent = indent + "  "
                set k = k + 1
            endloop

            loop
                exitwhen i == 0
                set index = trackTable[i]
                set tab = Table(this)[index]

                set output = output + "\n" + indent + "  [" + thistype(index).toStringFn(depth) + "] = " + thistype(tab).toStringFn(depth + 1)
                set i = i - 1
            endloop

            return output + "\n" + indent + "]"
        endmethod

        method toString takes nothing returns string
            local string result = toStringFn(0)
            call seenTables.flush()
            return result
        endmethod

        method print takes nothing returns nothing
            call BJDebugMsg(toString())
        endmethod
    endif

endstruct

//! textmacro TableXD takes NAME, SPEEDY_OR_TRACKED, MAP_TO_WHAT
struct $NAME$ extends array
    method operator [] takes integer index returns $MAP_TO_WHAT$
        return $SPEEDY_OR_TRACKED$(this)[index]
    endmethod

    method remove takes integer index returns nothing
        call $SPEEDY_OR_TRACKED$(this).remove(index)
    endmethod

    method has takes integer index returns boolean
        return Table(this).has(index)
    endmethod

    method destroy takes nothing returns nothing
        call $SPEEDY_OR_TRACKED$(this).destroy()
    endmethod

    static method create takes nothing returns thistype
        return $SPEEDY_OR_TRACKED$.create()
    endmethod
endstruct
//! endtextmacro

// Comment-out any of these if you don't need them. Note that the optimizer will inline alias methods.
//! runtextmacro TableXD("Table3D", "Table2D", "Table2D")
//! runtextmacro TableXD("Table4D", "Table2D", "Table3D")
//! runtextmacro TableXD("Table5D", "Table2D", "Table4D")

//! runtextmacro TableXD("Table3DT", "Table2DT", "Table2DT")
//! runtextmacro TableXD("Table4DT", "Table2DT", "Table3DT")
//! runtextmacro TableXD("Table5DT", "Table2DT", "Table4DT")

// Run these to support backwards-compatibility. Comment-out if you don't need them.
//! runtextmacro TableXD("HashTable", "Table2D", "Table")
//! runtextmacro TableXD("HashTableEx", "Table2DT", "Table")

endlibrary