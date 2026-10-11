/*

    - Disable `NSL_Implementation` in `Save Load System` folder and enable `NSL Implementation MultiVersion Test`
    - Start and type : -save code1
    
    - Quit and edit `NSL_CodeVersion` to 2 in `NSL Implementation MultiVersion Test`
    - Add these two lines at the end of `SavePlayer` function: 

        call CodeHelper_Save_Int(saver, 15)
        call CodeHelper_Save_Int(saver, -15)
    
    - Start and type : -save code2
    
    - Type : -load code1 → it'll be successful with the 4 values displayed
    - Type : -load code2 → it'll be successful too with the 6 values displayed
    
    - Now it's your job to have a correct behavior in the version=1 Codex to fix up default values if required
        - example:
            - In version2 you added a player rating with a base value of 1000,
            - It saves properly on version2, but older codes under version1 won't have that value,
            - You'll have to edit the codex for version1 so that on executed, it'll set the player's rating to 1000 (the base value) to work properly
            - Saving will encode it under version2 and use the correct codex afterward
*/