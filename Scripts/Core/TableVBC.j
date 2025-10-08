library TableVBC
/*
    Backwards-compatibility add-on for scripts employing Vexorian's Table.

    Compatible with Table version 6+

    Disclaimer:

    The this.flush(key) method from the original Table cannot be parsed with
    the new Table. For the scripts that use this method, they need to be up-
    dated to use the more hashtable-API-fitting this.remove(key) method. The
    `flush` method was retained by Vexorian's Table because of the matching
    gamecache API.

    Note: This issue does not occur with HandleTables & StringTables; only
    with the standard, integer-keyed Table, so you do not need to make any
    changes to StringTable/HandleTable-employing scripts.

    If you want to use StringTables/HandleTables with features exclusive
    to the new Table, you'll want to use the new wrapper methods introduced
    in Table version 6 and switch away from StringTable/HandleTable types.
*/

//! textmacro TABLE_VBC_METHODS
    method reset takes nothing returns nothing
        call this.flush()
    endmethod
    method exists takes integer key returns boolean
        return this.has(key)
    endmethod
    static method operator [] takes string key returns Table
        return Table(StringTable.typeid).join(key)
    endmethod
    static method flush2D takes string key returns nothing
        call Table(StringTable.typeid).delete(key)
    endmethod
//! endtextmacro

//! textmacro TABLE_VBC_STRUCTS
struct HandleTable extends array
    static method operator [] takes string key returns thistype
        return Table[key]
    endmethod
    static method flush2D takes string key returns nothing
        call Table.flush2D(key)
    endmethod
    method operator [] takes handle key returns integer
        return Table(this).get(key)
    endmethod
    method operator []= takes handle key, integer value returns nothing
        call Table(this).store(key, value)
    endmethod
    method flush takes handle key returns nothing
        call Table(this).forget(key)
    endmethod
    method exists takes handle key returns boolean
        return Table(this).stores(key)
    endmethod
    method reset takes nothing returns nothing
        call Table(this).flush()
    endmethod
    method destroy takes nothing returns nothing
        call Table(this).destroy()
    endmethod
    static method create takes nothing returns thistype
        return Table.create()
    endmethod
endstruct

struct StringTable extends array
    static method operator [] takes string key returns thistype
        return Table[key]
    endmethod
    static method flush2D takes string key returns nothing
        call Table.flush2D(key)
    endmethod
    method operator [] takes string key returns integer
        return Table(this).read(key)
    endmethod
    method operator []= takes string key, integer value returns nothing
        call Table(this).write(key, value)
    endmethod
    method flush takes string key returns nothing
        call Table(this).delete(key)
    endmethod
    method exists takes string key returns boolean
        return Table(this).written(key)
    endmethod
    method reset takes nothing returns nothing
        call Table(this).flush()
    endmethod
    method destroy takes nothing returns nothing
        call Table(this).destroy()
    endmethod
    static method create takes nothing returns thistype
        return Table.create()
    endmethod
endstruct
//! endtextmacro

endlibrary