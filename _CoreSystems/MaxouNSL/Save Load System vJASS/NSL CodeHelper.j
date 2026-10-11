/*



            Don't edit this
            


*/
library NSLCodeHelper requires NSLNumberUtils
    public function Save_Positive_Int takes NSL_Code inst, integer value, integer size returns nothing
        call inst.SV(value, size)
    endfunction
    
    public function Read_Positive_Int takes NSL_Code inst, integer size returns integer
        return inst.RV(size)
    endfunction
    
    public function Save_FourCC takes NSL_Code inst, integer fourcc returns nothing
        call Save_Positive_Int(inst, fourcc, NSL_SIZE_LESS_THAN_2147483648)
    endfunction
    
    public function Read_FourCC takes NSL_Code inst returns integer
        return Read_Positive_Int(inst, NSL_SIZE_LESS_THAN_2147483648)
    endfunction

    public function Save_Any_Int takes NSL_Code inst, integer value, integer size returns nothing
        call inst.SV(NSLNumberUtils_GetSign(value), NSL_SIZE_BOOLEAN)
        call Save_Positive_Int(inst, IAbsBJ(value), size)
    endfunction

    public function Read_Any_Int takes NSL_Code inst, integer size returns integer
        return NSLNumberUtils_GetSignInvert(Read_Positive_Int(inst, NSL_SIZE_BOOLEAN)) * Read_Positive_Int(inst, size)
    endfunction

    public function Save_Int takes NSL_Code inst, integer value returns nothing
        call Save_Any_Int(inst, value, NSL_SIZE_LESS_THAN_2147483648)
    endfunction
    
    public function Read_Int takes NSL_Code inst returns integer
        return Read_Any_Int(inst, NSL_SIZE_LESS_THAN_2147483648)
    endfunction

endlibrary