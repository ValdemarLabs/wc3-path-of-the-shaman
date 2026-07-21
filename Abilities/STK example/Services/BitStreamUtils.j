library BSRW

    globals
        public constant integer MAX_BIT_LENGTH = 1000
    endglobals

    public struct BitStreamReader

        private string data
        private integer pointer
        private integer array bitArray[MAX_BIT_LENGTH]
        public string lastReadChunk
        
        static method create takes string data returns BitStreamReader
            local BitStreamReader bsr = BitStreamReader.allocate()
            local integer length = StringLength(data)
            local integer i = 0

            set bsr.data = data
            set bsr.pointer = 0

            loop
                exitwhen i >= length
                set bsr.bitArray[i] = S2I(SubString(data, i, i+1))
                set i = i + 1
            endloop

            return bsr
        endmethod

        public method readStr takes integer bitCount returns string
            local string readBits = SubString(this.data, this.pointer, this.pointer + bitCount)
            set this.pointer = this.pointer + bitCount
            return readBits
        endmethod

        public method readInt takes integer bitCount returns integer
            local integer value = 0
            local integer end = this.pointer + bitCount
            set this.lastReadChunk = SubString(this.data, this.pointer, end)
            loop
                exitwhen this.pointer >= end
                set value = value * 2 + this.bitArray[this.pointer]
                set this.pointer = this.pointer + 1
            endloop
            return value
        endmethod
    endstruct

    public struct BitStreamWriter

        private string data
        private integer length
        public string lastWrittenChunk
        
        static method create takes nothing returns BitStreamWriter
            local thistype this = thistype.allocate()
            set this.data = ""
            set this.length = 0
            return this
        endmethod

        public method writeStream takes string bitStream returns nothing
            set this.lastWrittenChunk = bitStream
            set this.data = this.data + this.lastWrittenChunk
            set this.length = this.length + StringLength(this.lastWrittenChunk)
        endmethod

        public method write takes integer value, integer bitCount returns nothing
            local integer i = 0
            set this.lastWrittenChunk = ""
            loop
                exitwhen i >= bitCount
                set this.lastWrittenChunk = I2S(ModuloInteger(value, 2)) + this.lastWrittenChunk
                set value = value / 2
                set i = i + 1
            endloop
            if (value > 0) then
                call BJDebugMsg("BitStreamWriter: Value could not be fully represented in " + I2S(bitCount) + " bits.")
            endif
            set this.data = this.data + this.lastWrittenChunk
            set this.length = this.length + bitCount
        endmethod

        public method writeInt takes integer value returns nothing
            call this.write(value, 32)
        endmethod

        public method get takes nothing returns string
            return this.data
        endmethod

        public method flush takes nothing returns BitStreamWriter
            set this.data = ""
            set this.length = 0
            set this.lastWrittenChunk = ""
            return this
        endmethod
    endstruct
endlibrary