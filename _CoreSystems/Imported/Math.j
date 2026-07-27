/*
    Collection of simple math functions involving real and integer types
  
    Functions:
        AngleXY         : Calculates the angle from (x1, y1) to (x2, y2)
        DistanceXY      : Calculates the straight-line distance from (x1, y1) to (x2, y2)
        PolarX          : Calculates a new X coordinate by moving it 'dist' units in 'angle' direction
        PolarY          : Calculates a new Y coordinate by moving it 'dist' units in 'angle' direction
        AbsR            : Calculates the absolute value for real numbers
        AbsI            : Calculates the absolute value for integer numbers numbers
        Round           : Rounds a real number to the nearest integer
        Floor           : Takes a real value and returns the closest integer less than or equal to it
        Ceiling         : Takes a real value and returns the closest integer greater than or equal to it
        Mod             : Returns the modulus of two integer values
        MinR            : Calculates the minimum of two real numbers
        MaxR            : Calculates the maximum of two real numbers
        MinI            : Calculates the minimum of two integer numbers
        MaxI            : Calculates the maximum of two integer numbers
        ClampR          : Restricts a real number between a minimum and maximum value
        ClampI          : Restricts an integer number between a minimum and maximum value
        ClampBetweenR   : Restricts a real number between two other real values.
        ClampBetweenI   : Restricts an integer number between two other integer values.
        Lerp            : Gives a linear interpolation between two real values based on a percentage input
        InvLerp         : Gives the percentage input that would produce the desired value between two real values
        Transform       : Takes a value between two numbers and returns a new value that is similarly positioned between two new numbers
*/

library Math
    /*
        AngleXY
            Calculates the angle from (x1, y1) to (x2, y2)
      
        An equivalent to AngleBetweenPoints that doesn't use location types
        Coordinate order matters, so switching the order inverts the direction of the angle
    */
    public function AngleXY takes real x1, real y1, real x2, real y2 returns real
        return bj_RADTODEG * Atan2(y2 - y1, x2 - x1)
    endfunction
  
    /*
        DistanceXY
            Calculates the straight-line distance from (x1, y1) to (x2, y2)
          
        An equivalent to DistanceBetweenPoints that doesn't use location types
    */
    public function DistanceXY takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        return SquareRoot(dx * dx + dy * dy)
    endfunction
  
    /*
        PolarX
            Calculates a new X coordinate by moving it 'dist' units in 'angle' direction
          
        A partial equivalent to PolarProjectionBJ that doesn't use location types
    */
    public function PolarX takes real x, real dist, real angle returns real
        return x + dist * Cos(angle * bj_DEGTORAD)
    endfunction

    /*
        PolarY
            Calculates a new Y coordinate by moving it 'dist' units in 'angle' direction
          
        A partial equivalent to PolarProjectionBJ that doesn't use location types
    */
    public function PolarY takes real y, real dist, real angle returns real
        return y + dist * Sin(angle * bj_DEGTORAD)
    endfunction
  
    /*
        AbsR
            Calculates the absolute value for real numbers
          
        Examples:
            AbsR(1.5) gives a value of 1.5
            AbsR(-1.5) gives a value of 1.5
    */
    public function AbsR takes real value returns real
        if (value < 0) then
            return value * -1.0
        endif
        return value
    endfunction

    /*
        AbsI
            Calculates the absolute value for integer numbers numbers
          
        Examples:
            AbsI(2) gives a value of 2
            AbsI(-2) gives a value of 2
    */
    public function AbsI takes integer value returns integer
        if (value < 0) then
            return value * -1
        endif
        return value
    endfunction
  
    /*
        Round
            Rounds a real number to the nearest integer
    */
    public function Round takes real value returns integer
        return R2I(value + 0.5)
    endfunction
  
    /*
        Floor
            Takes a real value and returns the closest integer less than or equal to it
    */
    public function Floor takes real value returns integer
        return R2I(value)
    endfunction
  
    /*
        Ceiling
            Takes a real value and returns the closest integer greater than or equal to it
    */
    public function Ceiling takes real value returns integer
        local integer result = R2I(value)
        if (I2R(result) == value) then
            return result
        endif
        return result + 1
    endfunction
  
    /*
        Mod
            Returns the modulus of two integer values
          
        The modulus is the remainder after division takes place
      
        Examples:
            Mod(3, 3) gives a value of 0
            Mod(4, 3) gives a value of 1
            Mod(5, 3) gives a value of 2
            Mod(6, 3) gives a value of 0
            Mod(7, 3) gives a value of 1
            Mod(8, 3) gives a value of 2
    */
    public function Mod takes integer value, integer divisor returns integer
        return value - (value / divisor) * divisor
    endfunction

    /*
        MinR
            Calculates the minimum of two real numbers
      
        Examples:
            MinR(1.5, 2.5) gives a value of 1.5
            MinR(-3.0, 1.0) gives a value of -3.0
    */
    public function MinR takes real a, real b returns real
        if (a < b) then
            return a
        else
            return b
        endif
    endfunction
  
    /*
        MaxR
            Calculates the maximum of two real numbers
      
        Examples:
            MaxR(1.5, 2.5) gives a value of 2.5
            MaxR(-3.0, 1.0) gives a value of 1.0
    */
    public function MaxR takes real a, real b returns real
        if (a < b) then
            return b
        else
            return a
        endif
    endfunction

    /*
        MinI
            Calculates the minimum of two integer numbers
      
        Examples:
            MinI(1, 2) gives a value of 1
            MinI(-3, 1) gives a value of -3
    */
    public function MinI takes integer a, integer b returns integer
        if (a < b) then
            return a
        else
            return b
        endif
    endfunction
  
    /*
        MaxI
            Calculates the maximum of two integer numbers
      
        Examples:
            MaxI(1, 2) gives a value of 2
            MaxI(-3, 1) gives a value of 1
    */
    public function MaxI takes integer a, integer b returns integer
        if (a < b) then
            return b
        else
            return a
        endif
    endfunction
  
    /*
        ClampR
            Restricts a real number between a minimum and maximum value
      
        Examples:
            ClampR(1.0, 2.0, 4.0) gives a value of 2.0
            ClampR(2.0, 2.0, 4.0) gives a value of 2.0
            ClampR(3.0, 2.0, 4.0) gives a value of 3.0
            ClampR(4.0, 2.0, 4.0) gives a value of 4.0
            ClampR(5.0, 2.0, 4.0) gives a value of 4.0
    */
    public function ClampR takes real value, real min, real max returns real
        return MaxR(MinR(value, max), min)
    endfunction

    /*
        ClampI
            Restricts an integer number between a minimum and maximum value
      
        Examples:
            ClampI(1, 2, 4) gives a value of 2
            ClampI(2, 2, 4) gives a value of 2
            ClampI(3, 2, 4) gives a value of 3
            ClampI(4, 2, 4) gives a value of 4
            ClampI(5, 2, 4) gives a value of 4
    */
    public function ClampI takes integer value, integer min, integer max returns integer
        return MaxI(MinI(value, max), min)
    endfunction
  
    /*
        ClampBetweenR
            Restricts a real number between two other real values.
      
        This version doesn't require you to sort your min and max values

        Examples:
            ClampBetweenR(1.0, 4.0, 2.0) gives a value of 2.0
            ClampBetweenR(2.0, 4.0, 2.0) gives a value of 2.0
            ClampBetweenR(3.0, 4.0, 2.0) gives a value of 3.0
            ClampBetweenR(4.0, 4.0, 2.0) gives a value of 4.0
            ClampBetweenR(5.0, 4.0, 2.0) gives a value of 4.0
    */
    public function ClampBetweenR takes real value, real first, real second returns real
        local real min = MinR(first, second)
        local real max = MaxR(first, second)
        return ClampR(value, min, max)
    endfunction

    /*
        ClampBetweenI
            Restricts an integer number between two other integer values.
      
        This version doesn't require you to sort your min and max values

        Examples:
            ClampBetweenI(1, 4, 2) gives a value of 2
            ClampBetweenI(2, 4, 2) gives a value of 2
            ClampBetweenI(3, 4, 2) gives a value of 3
            ClampBetweenI(4, 4, 2) gives a value of 4
            ClampBetweenI(5, 4, 2) gives a value of 4
    */
    public function ClampBetweenI takes integer value, integer first, integer second returns integer
        local integer min = MinI(first, second)
        local integer max = MaxI(first, second)
        return ClampI(value, min, max)
    endfunction

    /*
        Lerp
            Gives a linear interpolation between two real values based on a percentage input
      
        A percentage value of 0.0 gives the first number.
        A percentage value of 1.0 gives the second number.
        A percentage value of 0.5 gives a value halfway between first and second
      
        The percentage can be outside 0.0-1.0 if desired
      
        Examples:
            Lerp(4.0, 8.0, 0.00) gives a value of 4.0
            Lerp(4.0, 8.0, 0.25) gives a value of 5.0
            Lerp(4.0, 8.0, 0.50) gives a value of 6.0
            Lerp(4.0, 8.0, 0.75) gives a value of 7.0
            Lerp(4.0, 8.0, 1.00) gives a value of 8.0
    */
    public function Lerp takes real first, real second, real percent returns real
        return first + (second - first) * percent
    endfunction

    /*
        InvLerp (Inverse Lerp)
            Gives the percentage input that would produce the desired value between two real values
      
        Examples:
            InvLerp(4.0, 8.0, 4.0) gives a value of 0.00 (0%)
            InvLerp(4.0, 8.0, 5.0) gives a value of 0.25 (25%)
            InvLerp(4.0, 8.0, 6.0) gives a value of 0.50 (50%)
            InvLerp(4.0, 8.0, 7.0) gives a value of 0.75 (75%)
            InvLerp(4.0, 8.0, 8.0) gives a value of 1.00 (100%)
    */
    public function InvLerp takes real first, real second, real value returns real
        return (value - first) / (second - first)
    endfunction
  
    /*
        Transform
            Takes a value between two numbers and returns a new value that is similarly positioned between two new numbers
      
        Input value does not strictly need to be between the first and second numbers
      
        Examples:
            Take a number between 2.0 and 4.0 and transform it to a number between 100.0 and 150.0
                Transform(2.0, 2.0, 4.0, 100.0, 150.0)   gives a value of 100.0
                Transform(2.5, 2.0, 4.0, 100.0, 150.0)   gives a value of 112.5
                Transform(3.0, 2.0, 4.0, 100.0, 150.0)   gives a value of 125.0
                Transform(3.5, 2.0, 4.0, 100.0, 150.0)   gives a value of 137.5
                Transform(4.0, 2.0, 4.0, 100.0, 150.0)   gives a value of 150.0
          
            An AOE spell of range 500 that deals more damage the closer you are to the center.
            Let's say the damage at the center is 150 and the damage at the edge is 50
            The distance from the center would be the input
                damage = Transform(distance, maxAOE, minAOE, minDamage, maxDamage)
                
                Transform(  0.0, 500.0, 0.0, 50.0, 150.0)   gives a value of 150.0 damage
                Transform(100.0, 500.0, 0.0, 50.0, 150.0)   gives a value of 130.0 damage
                Transform(200.0, 500.0, 0.0, 50.0, 150.0)   gives a value of 110.0 damage
                Transform(300.0, 500.0, 0.0, 50.0, 150.0)   gives a value of  90.0 damage
                Transform(400.0, 500.0, 0.0, 50.0, 150.0)   gives a value of  70.0 damage
                Transform(500.0, 500.0, 0.0, 50.0, 150.0)   gives a value of  50.0 damage
    */
    public function Transform takes real value, real first, real second, real newFirst, real newSecond returns real
        return Lerp(newFirst, newSecond, InvLerp(first, second, value))
    endfunction

    public function I2B takes integer i returns boolean
        return i != 0
    endfunction

    public function B2I takes boolean b returns integer
        if b then
            return 1
        endif
        return 0
    endfunction
    
endlibrary