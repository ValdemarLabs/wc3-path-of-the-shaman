library Typecast

globals
    //These are not used, they are here just to fool Jasshelper.
    code Code
    integer Int
    string Str
    boolean Bool
 
    //These are the actual ones used for typecasting.
    code l__Code
    integer l__Int
    string l__Str
    boolean l__Bool
endglobals

static if USE_MEMORY_HACK then

//The "return" line prevents Jasshelper from inlining these functions
function setCode takes code c returns nothing
    set l__Code = c
    return
endfunction

function setInt takes integer i returns nothing
    set l__Int = i
    return
endfunction

function setStr takes string s returns nothing
    set l__Str = s
    return
endfunction

function setBool takes boolean b returns nothing
    set l__Bool = b
    return
endfunction

//Jasshelper will append an "l__" prefix to all Typecast locals
private function Typecast1 takes nothing returns nothing
    local integer Str   //l__Str
    local string Int    //l__Int
endfunction

//# +nosemanticerror
function SH2I takes string s returns integer
    call setStr(s)
    return l__Str
endfunction

//# +nosemanticerror
function I2SH takes integer i returns string
    call setInt(i)
    return l__Int
endfunction

private function Typecast2 takes nothing returns nothing
    local integer Bool  //l_Bool
    local boolean Int   //l_Int
endfunction

//# +nosemanticerror
function B2I takes boolean b returns integer
    call setBool(b)
    return l__Bool
endfunction

//# +nosemanticerror
function I2B takes integer i returns boolean
    call setInt(i)
    return l__Int
endfunction

private function Typecast3 takes nothing returns nothing
    local integer Code   //l__Code
    local code Int       //l_Int
endfunction

//# +nosemanticerror
function C2I takes code c returns integer
    call setCode(c)
    return l__Code
endfunction

//# +nosemanticerror
function I2C takes integer i returns code
    call setInt(i)
    return l__Int
endfunction

//# +nosemanticerror
function realToIndex takes real r returns integer
    return r
endfunction

function cleanInt takes integer i returns integer
    return i
endfunction

//# +nosemanticerror
function indexToReal takes integer i returns real
    return i
endfunction

function cleanReal takes real r returns real
    return r
endfunction

endif

endlibrary