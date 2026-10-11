/*
                        [ Manual Saving and Loading ]
        
        • You can either set `NSL_UseSimpleSaveLoad = true` in `NSL_Implementation` to use to integrated saving and loading bindings
            • it allow the use of `-save <save_slot_name>` and `-load <load_slot_name` with the entire integration provided into `NSL_Implementation`


        • If you want a better control by doing it manually with your own trigger, you can set `NSL_UseSimpleSaveLoad = false` and call the executor functions yourself at any point :
            • to save: 
                `function NSLSaveLoadExecutor_Save takes integer playerId, string saveSlotName`

            • to load:
                `function NSLSaveLoadExecutor_Load takes integer playerId, string loadSlotName`
                
            - Note: `integer playerId` is 0-indexed, meaning that :
                    → 0 is Red,
                    → 1 is Blue, ...

            - These functions also check against `CanSave` and `CanLoad` functions to make sure you can't force an invalid save
            
                → Manual saving and loading will be useful when saving player stats from games on start/end of the match (aka. Direct Strike, Tower Survivor...)
*/




