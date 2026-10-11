/*



            Don't edit this
            


*/
library NSLHelper initializer Init
    globals
        private integer array TWO_POW_CACHE
    endglobals

    // vJass compiler should inline this function call
	public function TwoPow takes integer exp returns integer
        return TWO_POW_CACHE[exp]
	endfunction
    
    private function Init takes nothing returns nothing
        // Cache for better performance
        set TWO_POW_CACHE[0] = 1
        set TWO_POW_CACHE[1] = 2
        set TWO_POW_CACHE[2] = 4
        set TWO_POW_CACHE[3] = 8
        set TWO_POW_CACHE[4] = 16
        set TWO_POW_CACHE[5] = 32
        set TWO_POW_CACHE[6] = 64
        set TWO_POW_CACHE[7] = 128
        set TWO_POW_CACHE[8] = 256
        set TWO_POW_CACHE[9] = 512
        set TWO_POW_CACHE[10] = 1024
        set TWO_POW_CACHE[11] = 2048
        set TWO_POW_CACHE[12] = 4096
        set TWO_POW_CACHE[13] = 8192
        set TWO_POW_CACHE[14] = 16384
        set TWO_POW_CACHE[15] = 32768
        set TWO_POW_CACHE[16] = 65536
        set TWO_POW_CACHE[17] = 131072
        set TWO_POW_CACHE[18] = 262144
        set TWO_POW_CACHE[19] = 524288
        set TWO_POW_CACHE[20] = 1048576
        set TWO_POW_CACHE[21] = 2097152
        set TWO_POW_CACHE[22] = 4194304
        set TWO_POW_CACHE[23] = 8388608
        set TWO_POW_CACHE[24] = 16777216
        set TWO_POW_CACHE[25] = 33554432
        set TWO_POW_CACHE[26] = 67108864
        set TWO_POW_CACHE[27] = 134217728
        set TWO_POW_CACHE[28] = 268435456
        set TWO_POW_CACHE[29] = 536870912
        set TWO_POW_CACHE[30] = 1073741824
        set TWO_POW_CACHE[31] = 2147483648
    endfunction
endlibrary