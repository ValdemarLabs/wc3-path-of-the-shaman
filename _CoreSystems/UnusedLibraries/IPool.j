library IPool requires Table, Alloc
/*
IPool 3.0.0.0 by Bribe

Special thanks to Pyrogasm on wc3c.net for the original Pools resource, and to
Rising_Dusk for popularizing it.

Quick Intro of IPool:

Do you want a random integer from a multiple-choice list instead of a number
between x and y? Do you want one of those choices to have a lower or higher chance
to be picked? How about each item has its own odds of being picked?

IPool is similar to the native types itempool and unitpool, however returns
integers instead of handles. Integer-based pools can be used for all sorts of
things, ranging from randomized creep drops, spawning systems, random abilities
being cast (a la traps), random instances of a atruct, etc.

Object-Types of IPool:

    IPool - Fast .getItem() method, slow add/remove. Uses a Table index formatted
    as an array to get a random item without searching.

    SubPool - Fast add/remove, slower .getItem method. Uses an O(n) search to
    get a random item.

Main IPool API:
    
    IPool.create()->IPool
        returns a new IPool for your needs
    
    iPoolInstance.flush()
        reset all values of the IPool to default settings
    
    iPoolInstance.destroy()
        use this if you are totally done with that IPool

    iPoolInstance.add(integer value, integer weight)
        add any integer to the pool. The weight must be greater than 0 to have a
        chance of being picked.

    iPoolInstance.remove(integer value)
        that value will no longer have a chance if you use this method on it!

    iPoolInstance.getItem()->integer
        returns one of the integers you added. Has higher chance to pick an item
        with higher weight

Main SubPool API:

    SubPool.create(integer totalWeight)->SubPool
        The totalWeight must be equal to or greater than the sum of all items you
        will add to the SubPool. Each added item has a chance of itsWeight/
        totalWeight.

    The rest of the main API is the same as IPool. Only keep in mind that
    subPoolInstance.getItem() will return 0 in many cases due to the improbability
    of an integer being picked.

Secondary API for both structs is included as follows:

    poolInstance.contains(integer value)->boolean
        Was the value added to the pool?

    poolInstance.copy()->pool
        Returns a new pool with the same properties as the pool you want copied.

    debug poolInstance.print()
        Useful for identifying what objects are in the pool during tests.

    poolInstance.lock/unlock()
        SubPools can associate with another subPool and/or an IPool. If you
        have a single nested pool you wish to not get auto-destroyed, simply
        call pool.lock(). pool.unlock() reverses it. If you do not use these, all
        nested pools will auto-destruct when the containing SubPool is destroyed.

API for getting/setting the weight of an already-added value to a pool:

    iPoolInstance.add(integer value, integer additionalWeight)
        You can add more weight to a value in IPool, but the only way to reduce
        it is to completely null it using the .remove(integer value) method. This
        is to avoid the cumbersome giant that was the original IPool.

    subPoolInstance[integer value].weight = integer newWeight
        Setting a SubPool value's weight can be done arbitrarily.

    iPoolInstance.weightOf(integer value)->integer
    &
    subPoolInstance[integer value].weight
        Just in case you lost track of how much weight you assigned to a value.

API for nesting pools:

    subPoolInstance.subPool = SubPool.create()
        The SubPool member can be get and set arbitrarily. It cannot be the same
        SubPool as the SubPool that's trying to nest it, as that would cause
        recursion errors.
        If the SubPool was not able to pick an integer, it will default to the
        next nested SubPool within itself.

    subPoolInstance.pool = IPool.create()
        The .pool member can be get and set arbitrarily. If the SubPool and any
        nested SubPools could not pick an integer, this pool will be the last resort.
*/
private module Init
    private static method onInit takes nothing returns nothing
        set .tar = TableArray[8192]
    endmethod
endmodule
private struct data extends array
    static TableArray tar
    integer int
    integer locks
    integer weight
    implement Alloc
    implement Init
endstruct

    private function Create takes nothing returns data
        local data this = data.allocate()
        set this.locks = 0
        return this
    endfunction
    private function Destroy takes data this returns boolean
        if this.locks == -1 or this == 0 then
            debug call BJDebugMsg("IPool Error: Attempt to double-free instance!")
            return false
        endif
        set this.locks = -1
        call this.deallocate()
        return true
    endfunction

    private function Lock takes data i returns nothing
        if i.locks == -1 then
            debug call BJDebugMsg("IPool Error: Attempt to lock a destroyed instance!")
            return
        endif
        set i.locks = i.locks + 1
    endfunction
    private function Unlock takes data i returns boolean
        if i.locks == -1 then
            debug call BJDebugMsg("IPool Error: Attempt to unlock destroyed instance!")
            return false
        endif
        set i.locks = i.locks - 1
        return i.locks == 0
    endfunction

struct IPool extends array
   
    method operator weight takes nothing returns integer
        return data(this).weight
    endmethod
    private method operator weight= takes integer lbs returns nothing
        set data(this).weight = lbs
    endmethod

    private method operator table takes nothing returns Table
        return data(this).int
    endmethod
    private method operator table= takes Table t returns nothing
        set data(this).int = t
    endmethod

    static method create takes nothing returns thistype
        local thistype this = Create()
        set this.table = Table.create()
        return this
    endmethod
    method flush takes nothing returns nothing
        call this.table.flush()
        call data.tar[this].flush()
        set this.weight = 0
    endmethod

    method destroy takes nothing returns nothing
        if Destroy(this) then
            call this.table.destroy()
            call data.tar[this].flush()
            set this.weight = 0
        endif
    endmethod

    method lock takes nothing returns nothing
        call Lock(this)
    endmethod
    method unlock takes nothing returns nothing
        if Unlock(this) then
            call this.destroy()
        endif
    endmethod

    //One-liner method to get a random item from the pool based on weight
    method getItem takes nothing returns integer
        return this.table[GetRandomInt(0, this.weight -1)]
    endmethod

    method weightOf takes integer value returns integer
        return data.tar[this][value]
    endmethod
    method chanceOf takes integer value returns real //returns between 0. and 1.
        return this.weightOf(value) / (this.weight + 0.) //don't divide by 0 here or else!
    endmethod
    method contains takes integer value returns boolean
        return data.tar[this].has(value)
    endmethod

    method add takes integer value, integer lbs returns nothing
        local Table tb = this.table
        local integer i = this.weight
        if lbs < 1 then
            debug call BJDebugMsg("IPool Error: Tried to add value with invalid weight!")
            return
        endif
        set data.tar[this][value] = data.tar[this][value] + lbs
        set lbs = i + lbs
        set this.weight = lbs //Important
        loop
            exitwhen i == lbs
            set tb[i] = value //treat this.table as an array
            set i = i + 1
        endloop
    endmethod
   
    method remove takes integer value returns nothing
        local Table tb = this.table
        local Table new
        local integer i = this.weight
        local integer n = 0
        local integer val
        if not this.contains(value) then
            debug call BJDebugMsg("IPool Error: Attempt to remove un-added instance!")
            return
        endif
        set new = Table.create()
        set this.table = new
        loop
            set i = i - 1
            set val = tb[i]
            if val != value then
                set new[n] = val //write to the new Table without gaps
                set n = n + 1
            endif
            exitwhen i == 0
        endloop
        set this.weight = n //lower pool weight
        call tb.destroy() //abandon old Table instance
        call data.tar[this].remove(value) //clear the value's weight now that it's gone
    endmethod

    method copy takes nothing returns thistype
        local thistype new = .create()
        local integer i = this.weight
        local Table tt = this.table
        local Table nt = new.table
        local Table dt = data.tar[new]
        local integer val
        if i == 0 then
            debug call BJDebugMsg("IPool Error: Attempt to copy invalid instance!")
            call new.destroy()
            return 0
        endif
        set new.weight = i
        loop
            set i = i - 1
            exitwhen i == 0
            set val = tt[i]
            set nt[i] = val
            set dt[val] = dt[val] + 1
        endloop
        return new
    endmethod
       
    static if DEBUG_MODE then
        method print takes nothing returns nothing //print the array of the pool
            local string s = "IPool: |cffffcc33Weight: "
            local integer i = this.weight
            local Table t = this.table
            set s = s + I2S(i) + "; Indices: "
            loop
                set i = i - 1
                exitwhen i <= 0
                set s = s + "[" + I2S(t[i]) + "]"
            endloop
            call BJDebugMsg(s + "|r")
        endmethod

    endif

endstruct

//New struct to handle deliberately-rare chances
struct SubPool extends array
   
    private IPool iPool //for association if you want it
    private thistype nest //you can nest IPoolMinis for poolception

    //you can change a value's weight via subpoolinstance[value].weight = blah
    //you can also change the entire pool's weight via subpoolinstance.weight = blah.
    method operator weight takes nothing returns integer
        return data(this).weight
    endmethod
    method operator weight= takes integer lbs returns nothing
        set data(this).weight = lbs
    endmethod

    private method operator value takes nothing returns integer
        return data(this).int
    endmethod
    private method operator value= takes integer val returns nothing
        set data(this).int = val
    endmethod

    private thistype next
    private thistype prev

    method operator pool takes nothing returns IPool
        return this.iPool
    endmethod
    method operator pool= takes IPool ip returns nothing
        if ip != 0 then
            call ip.lock()
        endif
        if this.iPool != 0 then
            call this.iPool.unlock()
        endif
        set this.iPool = ip
    endmethod

    static method create takes integer totalWeight returns thistype
        local thistype this = Create()
        set this.next = this
        set this.prev = this //I'm my own best friend
        set this.weight = totalWeight
        return this
    endmethod
    method destroy takes nothing returns nothing
        local thistype curr = this
        if this.next == -1 then
            debug call BJDebugMsg("SubPool Error: Attempt to double-free!")
            return
        endif
        loop
            set curr = curr.next
            call Destroy(curr) //destroy all the things
            exitwhen curr == this
        endloop
        set this.next = -1
        set this.pool = 0
        if this.nest != 0 then
            if data(this.nest).locks == 1 then
                call this.nest.destroy()
            else
                call Unlock(this.nest)
            endif
            set this.nest = 0
        endif
        call data.tar[this].flush()
    endmethod

    method lock takes nothing returns nothing
        call Lock(this)
    endmethod
    method unlock takes nothing returns nothing
        if Unlock(this) then
            call this.destroy()
        endif
    endmethod

    method operator subPool takes nothing returns thistype //need to return thistype and not IPool :P
        return this.nest
    endmethod
    method operator subPool= takes thistype ip returns nothing
        if this == ip then
            debug call BJDebugMsg("SubPool Error: Don't set a subPool within itself. Use the .copy() method, instead.")
            return
        endif
        if ip != 0 then
            call ip.lock()
        endif
        if this.nest != 0 then
            call this.nest.unlock()
        endif
        set this.nest = ip
    endmethod

    method add takes integer val, integer lbs returns nothing
        local thistype new
        if lbs <= 0 then
            debug call BJDebugMsg("SubPool Error: Don't add a value without weight")
            return
        endif
        if data.tar[this].has(val) then
            set new = data.tar[this][val]
            set new.weight = new.weight + lbs
            return
        endif
        set new = Create()
        set new.prev = this.prev
        set this.prev.next = new
        set this.prev = new
        set new.next = this

        set new.value = val
        set new.weight = lbs
       
        set data.tar[this][val] = new
    endmethod

    method contains takes integer val returns boolean
        return data.tar[this].has(val)
    endmethod
    method operator [] takes integer val returns thistype
        return data.tar[this][val]
    endmethod
    method operator []= takes integer val, integer newWeight returns nothing
        set this[val].weight = newWeight
    endmethod

    method remove takes integer val returns nothing
        local thistype node = this[val]
        if Destroy(node) then
            set node.prev.next = node.next
            set node.next.prev = node.prev
            call data.tar[this].remove(val)
        else
            debug call BJDebugMsg("SubPool Error: Attempt to remove non-added value")
        endif
    endmethod
    method getItem takes nothing returns integer
        local thistype curr = this
        local integer i = GetRandomInt(1, this.weight)
        loop
            set curr = curr.next
            set i = i - curr.weight
            exitwhen i <= 0
        endloop
        if curr == this then
            if this.nest != 0 then
                set i = this.nest.getItem()
            else
                set i = 0
            endif
            if i == 0 and this.pool != 0 then //if no low-probability item could be found...
                set i = this.pool.getItem() //pick a random int from main pool
            endif
        else
            set i = curr.value
        endif
        return i
    endmethod

    method copy takes nothing returns thistype
        local thistype new = .create(this.weight)
        local thistype curr = this
        set new.pool = this.iPool
        set new.subPool = this.nest
        loop
            set curr = curr.next
            exitwhen curr == this
            call new.add(curr.value, curr.weight)
        endloop
        return new
    endmethod

    static if DEBUG_MODE then
        method print takes nothing returns nothing
            local thistype curr = this
            local string s = "SubPool: |cffffcc33Instance: " + I2S(this) + ", TotalWeight: " + I2S(this.weight) + ", Indices: "
            if curr.next == this then
                call BJDebugMsg("SubPool is empty!")
                //return
            endif
            loop
                set curr = curr.next
                exitwhen curr == this
                set s = s + "[" + I2S(curr.value) + "]<" + I2S(curr.weight) + ">"
            endloop
            call BJDebugMsg(s + "|r")
            if this.nest != 0 then
                call this.nest.print()
            endif
            if this.iPool != 0 then
                call this.iPool.print()
            endif
        endmethod
    endif
endstruct

endlibrary