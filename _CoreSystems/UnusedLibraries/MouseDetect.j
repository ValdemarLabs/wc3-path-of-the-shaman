library Mouse requires Memory, Version

static if USE_MEMORY_HACK then
struct MouseEnv extends array  //Library Version will initialize the struct.
    implement MemArrayReal
endstruct

function GetMouseX takes nothing returns real
    return MouseEnv(0).value
endfunction

function GetMouseY takes nothing returns real
    return MouseEnv(1).value
endfunction

function GetMouseZ takes nothing returns real
    return MouseEnv(2).value
endfunction
endif

endlibrary