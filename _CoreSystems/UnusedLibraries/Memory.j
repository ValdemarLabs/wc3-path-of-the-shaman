library Memory initializer InitArrays requires Typecast

globals
    integer array Memory
    real array RMemory
    //Arrays for unaligned memory access.
    integer array Memory1
    integer array Memory2
    integer array Memory3

    integer bytecode  // Not used, it's here just to fool Jasshelper
    integer array l__bytecode
    private integer Count = 0
   
    private trigger t = CreateTrigger()
    private integer GetArrayAddress_Id
endglobals

static if USE_MEMORY_HACK then
function ReadMemory takes integer address returns integer
    return Memory[address/4] //Inline-friendly
endfunction

function ReadMemory1 takes integer address returns integer
    return Memory1[address/4] //Inline-friendly
endfunction

function ReadMemory2 takes integer address returns integer
    return Memory2[address/4] //Inline-friendly
endfunction

function ReadMemory3 takes integer address returns integer
    return Memory3[address/4] //Inline-friendly
endfunction

function ReadMemoryReal takes integer address returns real
    return RMemory[address/4] //Inline-friendly
endfunction

private function Structs takes nothing returns integer
    return -0x120
    return 0x220
    return 0x320
endfunction

function GetArrayAddress takes integer StructAddr returns integer
    return Memory[StructAddr/4+3]
endfunction

//# +nosemanticerror
private function RegisterBCArray takes integer id, code func returns nothing
    set l__bytecode[Count] = 0x0E000400
    set l__bytecode[Count+1] = id
    call setCode(func)
    set l__bytecode[Count+2] = 0x11000000
    set l__bytecode[Count+3] = Memory[l__Code/4 + 1]
    set l__bytecode[Count+4] = 0x16000000
    set l__bytecode[Count+5] = Memory[l__Code/4 - 1]
    set Count = Count + 6
    set l__bytecode[Count] = 0x27000000
endfunction

module Bytecode
    integer value
    static integer id
    static integer address

    static if thistype.hasTrigger then
        static trigger trigger = CreateTrigger()
    endif

    static method operator[] takes integer i returns integer
        return thistype(i).value
    endmethod

    static method operator[]= takes integer i, integer value returns nothing
        set thistype(i).value = value
    endmethod
   
    private static method onRegister takes nothing returns nothing
        set address = Memory[address/4 + 3]
        static if thistype.hasTrigger then
            call TriggerClearConditions(trigger)
            call TriggerAddCondition(trigger, Condition(I2C(address)))
        endif
    endmethod

    private static method onInit takes nothing returns nothing
        set thistype(8190).value = 0            //Always allocate full size of the array
        set id = Memory[C2I(function thistype.onInit)/4 + 9]
        call RegisterBCArray(id, function thistype.onRegister)
    endmethod
endmodule

private function RegisterMemArray takes integer id, integer id2 returns nothing
    set l__bytecode[Count] = 0x0E000400
    set l__bytecode[Count+1] = id
    set l__bytecode[Count+2] = 0x13000000
    set l__bytecode[Count+4] = 0x16000000
    set l__bytecode[Count+5] = GetArrayAddress_Id
    set l__bytecode[Count+6] = 0x0B010000
    set l__bytecode[Count+8] = 0x06040000
    set l__bytecode[Count+9] = id2
    set l__bytecode[Count+10] = 0x11000000
    set l__bytecode[Count+11] = id2
    set Count = Count + 12
    set l__bytecode[Count] = 0x27000000
endfunction

//! textmacro MemArray takes NAME, TYPE
module MemArray$NAME$
    $TYPE$ value
    private integer struct

    static method operator address takes nothing returns integer
        return thistype(3).struct
    endmethod

    static method operator address= takes integer i returns nothing
        set thistype(3).struct = i
    endmethod

    static method operator[] takes integer i returns $TYPE$
        return thistype(i).value
    endmethod

    private static method onInit takes nothing returns nothing
        set thistype(2).struct = 0xFFFFFFFF
        set thistype(1).struct = 0xFFFFFFFF
        call RegisterMemArray(Memory[C2I(function thistype.onInit)/4 + 9], Memory[C2I(function thistype.onInit)/4-13])
    endmethod
endmodule
//! endtextmacro

//! runtextmacro MemArray("","integer")
//! runtextmacro MemArray("Real","real")

private function InitBytecode takes integer i, integer r, integer func returns nothing
    set l__bytecode[8190] = 0
    set l__bytecode[0] = 0x0C000300 //op: 0C(LITERAL), type: 03(code), reg: 00
    set l__bytecode[1] = C2I(function Structs)
    set l__bytecode[2] = 0x06030000 //op: 06(NEWGLOBAL), type: 03(code)
    set l__bytecode[3] = i
    set l__bytecode[4] = 0x11000000 //op: 11(SETVAR), reg: 01, var: "Memory"
    set l__bytecode[5] = i
    set l__bytecode[6] = 0x06030000 //op: 06(NEWGLOBAL), type: 03(code)
    set l__bytecode[7] = r
    set l__bytecode[8] = 0x11000000 //op: 11(SETVAR), reg: 01, var: "RMemory"
    set l__bytecode[9] = r
    set l__bytecode[10] = 0x16000000 //op: 16(JASSCALL), func: "Step2"
    set l__bytecode[11] = func
endfunction

//# +nosemanticerror
private function Step2 takes nothing returns nothing
    set l__bytecode[12] = 0x0C010300 //op: 0C(LITERAL), type: 03(code), reg: 01
    set l__bytecode[13] = l__Code-7
    set l__bytecode[14] = 0x0C020300 //op: 0C(LITERAL), type: 03(code), reg: 02
    set l__bytecode[15] = l__Code+25
    set l__bytecode[16] = 0x0C030300 //op: 0C(LITERAL), type: 03(code), reg: 03
    set l__bytecode[17] = l__Code+49
    set l__bytecode[18] = 0x06030000 //op: 06(NEWGLOBAL), type: 03(code)
    set l__bytecode[19] = Memory[C2I(function ReadMemory1)/4+13]
    set l__bytecode[20] = 0x11010000 //op: 11(SETVAR), reg: 01, var: "Memory1"
    set l__bytecode[21] = l__bytecode[19]
    set l__bytecode[22] = 0x06030000 //op: 06(NEWGLOBAL), type: 03(code)
    set l__bytecode[23] = Memory[C2I(function ReadMemory2)/4+13]
    set l__bytecode[24] = 0x11020000 //op: 11(SETVAR), reg: 02, var: "Memory2"
    set l__bytecode[25] = l__bytecode[23]
    set l__bytecode[26] = 0x06030000 //op: 06(NEWGLOBAL), type: 03(code)
    set l__bytecode[27] = Memory[C2I(function ReadMemory3)/4+13]
    set l__bytecode[28] = 0x11030000 //op: 11(SETVAR), reg: 03, var: "Memory3"
    set l__bytecode[29] = l__bytecode[27]
    set l__bytecode[30] = 0x27000000
    set GetArrayAddress_Id = Memory[C2I(function GetArrayAddress)/4-1]
endfunction

private function Typecast takes nothing returns nothing
    local integer bytecode
endfunction

//# +nosemanticerror
private function Step1 takes nothing returns nothing
    local integer array stand
    call InitBytecode(stand[C2I(function ReadMemory)/4+13], stand[C2I(function ReadMemoryReal)/4+13], stand[C2I(function Step2)/4-1])
    call TriggerAddCondition(t, Condition(I2C(stand[l__bytecode/4+3])))
endfunction

private function Step0 takes nothing returns integer
    local code stand = function Structs
    return -0xC5F0603
    return 0x2700
endfunction

//Initialize registered bytecode arrays.
//# +nosemanticerror
private function InitArrays takes nothing returns boolean
    call ForForce(bj_FORCE_PLAYER[0], I2C(Memory[l__bytecode/4+3]))
    return false
endfunction

private module Init
//# +nosemanticerror
private static method onInit takes nothing returns nothing
    call setCode(function Step0)
    call TriggerAddCondition(t, Condition(I2C(l__Code+26)))
    call TriggerAddCondition(t, Condition(I2C(l__Code+8)))
    call setCode(function Step1)
    call TriggerAddCondition(t, Condition(I2C(l__Code+8)))
    call TriggerEvaluate(t)
    call TriggerClearConditions(t)
    call TriggerRegisterGameEvent(t, EVENT_GAME_LOADED)
    call TriggerAddCondition(t, Condition(function InitArrays))
endmethod
endmodule

private struct MemInit extends array
    implement Init
endstruct

struct CustomMem extends array
    implement MemArray
endstruct
endif
endlibrary