scope MultiArray // v1.0.0

    /****************************************************************************************
    
        == MultiArray ==
                by: Dalvengyr
                
                
        I. Description
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯
            Allows you to declare a multidimensional array variable.
            
            Basically is an over-sized one-dimensional array variable represented in
            a fairly decent multi-dimensional array interface.
            
            The variable could be declared as a global or a static struct member.
        
        
        II. Disadvantages
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
            - Allocate tons of memory space for each generated variable.
            - Has max size of 2023.
            
            
        III. API
        ¯¯¯¯¯¯¯¯
            1. Declaring new variable
                | //! textmacro CREATE_MULTI_ARRAY takes TYPE, NAME, DIMENSION
                        TYPE    => integer, real, unit, string, etc.
                        NAME    => the variable's name
                    
            2. Write the declared variable somewhere (global, struct, etc.)
                | //! textmacro PASTE_MULTI_ARRAY_VARIABLE takes PREFIX, NAME
                        NAME    => the variable's name
                        PREFIX  => private, public, static, constant, etc.
                    
            3. Initialize the variable, should be placed at map init
                | //! textmacro INIT_MULTI_ARRAY_VARIABLE takes NAME
                        
            4. Returns max index you may use
                | method operator maxIndex takes nothing returns integer
                
            5. Returns dimension of the variable
                | method operator dimension takes nothing returns integer
                
            6. Returns the contained value based on assigned indexes.
                | method operator value takes nothing returns $TYPE$
                
                | method operator [] takes integer i returns thistype
                | method operator []= takes integer i, $TYPE$ param returns nothing
            
        
        V. Link
        ¯¯¯¯¯¯¯
            -
            
     ***************************************************************************************/
     
    //! textmacro INIT_MULTI_ARRAY_VARIABLE takes NAME
    set $NAME$ = MultiArray__$NAME$__s.create()
    //! endtextmacro
    
    // Write the variable declaration somewhere (globals, struct, etc.)
    //! textmacro PASTE_MULTI_ARRAY_VARIABLE takes PREFIX, NAME
    $PREFIX$ MultiArray__$NAME$__s $NAME$
    //! endtextmacro
     
    //! textmacro CREATE_MULTI_ARRAY takes TYPE, NAME, DIMENSION
    scope MultiArray$NAME$var
        
        globals
            // Allocated array size per container
            private constant integer ALLOCATED_SPACE = 0x63EAE
            // Max index for each dimension for the generated variable
            private constant integer MAX_INDEX = R2I(Pow(ALLOCATED_SPACE*10, 1./$DIMENSION$))
            // Containers
            private $TYPE$ array Container__1[ALLOCATED_SPACE]
            private $TYPE$ array Container__2[ALLOCATED_SPACE]
            private $TYPE$ array Container__3[ALLOCATED_SPACE]
            private $TYPE$ array Container__4[ALLOCATED_SPACE]
            private $TYPE$ array Container__5[ALLOCATED_SPACE]
            private $TYPE$ array Container__6[ALLOCATED_SPACE]
            private $TYPE$ array Container__7[ALLOCATED_SPACE]
            private $TYPE$ array Container__8[ALLOCATED_SPACE]
            private $TYPE$ array Container__9[ALLOCATED_SPACE]
            private $TYPE$ array Container__10[ALLOCATED_SPACE]
        endglobals
        
        struct MultiArray__$NAME$__s
        
            private static integer read = 0
            private static integer array indices
            
            // Check whether some conditions are valid or not
            private static method validateIndices takes string state returns boolean
            
                local integer i = 0
                
                // Check the size boundary
                loop
                    exitwhen i == $DIMENSION$
                    if indices[i] < 0 or indices[i] >= MAX_INDEX then
                        debug call BJDebugMsg("$Error occured :: NAME$ var (on " + state + ") :: index-" + I2S(i+1) + " is out of bound of 0 or " + I2S(MAX_INDEX-1) + " at " + I2S(indices[i]) + ".")
                        return false
                    endif
                    set i = i + 1
                endloop
                
                // If the assigned dimension is valid
                if read < $DIMENSION$ then
                    debug call BJDebugMsg("Error occured :: $NAME$ var (on " + state + ") :: index-" + I2S($DIMENSION$-($DIMENSION$-read-1)) + " couldn't be read.")
                    return false
                elseif read > $DIMENSION$ then
                    debug call BJDebugMsg("Error occured :: $NAME$ var (on " + state + ") :: assigned indexes oversized the dimension of " + I2S($DIMENSION$) + " at " + I2S(read) + ".")
                    return false
                endif
                
                return true
            endmethod
            
            // Returns address based on assigned indices (indexes)
            private static method getMemoryOffset takes nothing returns integer
            
                local integer i = 1
                local integer result = indices[0]
                
                loop
                    exitwhen i == $DIMENSION$
                    set result = result * MAX_INDEX + indices[i]
                    set i = i + 1
                endloop
                
                return result
            endmethod
            
            // Max index which user may use
            method operator maxIndex takes nothing returns integer
                return MAX_INDEX-1
            endmethod
            
            // Dimension of generated variable
            method operator dimension takes nothing returns integer
                return $DIMENSION$
            endmethod
            
            // Returns the current value of generated variable
            method operator value takes nothing returns $TYPE$
            
                local integer loc
                local integer offset
                local integer index
                
                if not validateIndices("read") then
                    set read = 0
                endif
                
                // Calculate the address
                set offset = getMemoryOffset()
                set loc = offset/ALLOCATED_SPACE
                set index = offset-loc*ALLOCATED_SPACE
                
                set read = 0
                // Locate the position of the address
                if loc == 0 then
                    return Container__1[index]
                elseif loc == 1 then
                    return Container__2[index]
                elseif loc == 2 then
                    return Container__3[index]
                elseif loc == 3 then
                    return Container__4[index]
                elseif loc == 4 then
                    return Container__5[index]
                elseif loc == 5 then
                    return Container__6[index]
                elseif loc == 6 then
                    return Container__7[index]
                elseif loc == 7 then
                    return Container__8[index]
                elseif loc == 8 then
                    return Container__9[index]
                elseif loc == 9 then
                    return Container__10[index]
                endif
                
                return 0
            endmethod
            
            // Read indices (indexes)
            method operator [] takes integer i returns thistype
            
                set indices[read] = i
                set read = read + 1
                
                return this
            endmethod
            
            // Assign a value to the generated variable
            method operator []= takes integer i, $TYPE$ param returns nothing
            
                local integer loc
                local integer offset
                local integer index
                
                // Read the last index
                set indices[read] = i
                set read = read + 1
                
                if not validateIndices("write") then
                    set read = 0
                endif
                
                // Calculate the address
                set offset = getMemoryOffset()
                set loc = offset/ALLOCATED_SPACE
                set index = offset-loc*ALLOCATED_SPACE
                
                set read = 0
                // Locate the position of the address
                if loc == 0 then
                    set Container__1[index] = param
                elseif loc == 1 then
                    set Container__2[index] = param
                elseif loc == 2 then
                    set Container__3[index] = param
                elseif loc == 3 then
                    set Container__4[index] = param
                elseif loc == 4 then
                    set Container__5[index] = param
                elseif loc == 5 then
                    set Container__6[index] = param
                elseif loc == 6 then
                    set Container__7[index] = param
                elseif loc == 7 then
                    set Container__8[index] = param
                elseif loc == 8 then
                    set Container__9[index] = param
                elseif loc == 9 then
                    set Container__10[index] = param
                endif
                
            endmethod
            
        endstruct
        
    endscope
    //! endtextmacro
    
endscope