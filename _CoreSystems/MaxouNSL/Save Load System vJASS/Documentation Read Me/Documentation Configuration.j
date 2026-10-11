/*
                        [ Configuration ]
        
            • [ Variables ]
        
                - `NSL_CodeVersion` → is your current code version, this is saved within the code itself to figure out which Codex to use when loading your player's data
                    - Note: a Codex defines how to read the data inside the code, aka. → is it two numbers and one boolean, or three booleans and one number ?
                    - Note: you should change this version everytime you make changes to your saving while editing the codex associated to create default values to previous codex(s) you might have
                            (there will be examples later on)
                
                - `NSL_FolderName` → defines the folder under which your savecodes will be located at :
                    → Documents\Warcraft III\CustomMapData\<<NSL_FolderName>>\SaveChar_<<Save_Name>>.pld
                
                - `NSL_Key` → the encryption key for your savecodes, MUST BE a prime number
                    → changing it invalidates all generated codes with a different key, only change this when you want to cause a wipe

*/

/*

                        [ Using vJASS version ]
            
            • You can delete the `Save Load System GUI` folder and enable all scripts inside the `Save Load System vJASS`
            
*/