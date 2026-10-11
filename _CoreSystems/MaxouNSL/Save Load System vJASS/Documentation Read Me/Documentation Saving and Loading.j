/*
                        [ Saving and Loading ]
        
        • What to use in `SavePlayer` and `LoadPlayerVer<<version>>` to save and load data :
        
            - If you're looking for a basic usage you can simply use :                
                `call CodeHelper_Save_Int(saver, <<value to save>>)`
                and
                `call CodeHelper_Read_Int(loader)`
                
            - It'll save an integer (positive or negative) using the largest size possible (maximum value of 2'147'483'648)
            - This should always work and cause no issue, if you're a semi-beginner at vJASS you can stop reading this and move on to implementing your save/load

*/


/*
                        [ Saving and Loading (advanced) ]
        
        • Within `CodeHelper` you're provided with a few utility methods that allow the saving/loading of values using a `size`
        
            - `function Save_Positive_Int takes NSL_Code inst, integer value, integer size`
                • NSL_Code inst → the saver provided into `SavePlayer`
                • integer value → the ALWAYS POSITIVE integer value to save
                • integer size → the maximum size `value` can reach (if it goes above, the code will go boom), valid values are found in `NSL Size Enum`
                    - ie: `NSL_SIZE_LESS_THAN_1024 = 10`
                    - ie: using `NSL_SIZE_LESS_THAN_1024` means your `value` will never exceed 1'024, and also means you'll end up using `10` bits for the saving of that value
                    - Note: also saves 1 bit compared to `Save_Any_Int` due to assuming the number is always >= 0 and not having to store the sign (- or +)
                    
                • associated reading function: 
                    - `function Read_Positive_Int takes NSL_Code inst, integer size returns integer`
                        • NSL_Code inst → the loader provided into `LoadPlayerVer<<version>>`
                        • integer size → the same size defined at the matching `Save_Position_Int` call

            - Following that logic you're provided with :
                - `function Save/Read_FourCC takes NSL_Code inst, integer fourcc returns nothing`
                    → size is auto-defined at `NSL_SIZE_LESS_THAN_2147483648 = 31`
                    - Note: a FourCC is a itemtype, unittype, etc... it can be useful to use this function if creating an entire store to match itemtype to integer isn't necessary for few items aka.:
                        - item[0] = 'I001'
                        - item[1] = 'I005'
                        - item[2] = 'I077'
                        - item[3] = 'I0XU'
                        → and saving [0] [1] [2] [3] to later call `CreateItem( item[ Read_Positive_Int(inst, NSL_SIZE_LESS_THAN_2048) ], ...)`
                            - though it is an optimization that saves up (in the case you're having <= 2048 total items possible to save) about 20 bits per itemtype saved into the code
                              which is non-trivial if saving a lot of items with multiple stashes for example
                            
                - `function Save/Read_Any_Int takes NSL_Code inst, integer value, integer size returns nothing` → uses (size + 1) bits to save, one bit being the sign
                    - Note: supports negative and positive values due to having to save the sign before
                    - Note: does the same job as `Save_Int` but with a customizable size (advanced usage)
*/

/*
                        [ Multi-versioning codes ]
        
        • Using Codex(s) and code versions, you can support multiple code formats while preserving a single save format (the most up-to-date), see details in `Save Load System MultiVersion` folder
        
*/



