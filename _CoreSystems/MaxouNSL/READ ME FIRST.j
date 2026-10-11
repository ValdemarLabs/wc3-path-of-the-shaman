/*

                [ If you plan to use this system you need to copy the custom ability in the object editor ]
                
                - Copy this ability into your map : `(Z000) NSL Buffer Ability`
                    - [!] Make sure you copy it
                    
                    
                [ If you already have an ability using the id `Z000` ]
                    - Change [line 52] in FileIO :
                        > static constant integer BufferAbility = '<your id>'
                    - make sure the BufferAbility has 50 levels, and set all of its `Tooltip Normal` to a UNIQUE value per level
                        ie. :
                            > Tooltip 1
                            > Tooltip 2
                            > Tooltip 3
                            > Tooltip 4
                            > Tooltip 5
                    - It NEEDS to be unique.

                - This ability is used by (my edited) FileIO to retrieve the content of the save file.
                - It is then sync'd to other players in the game to be used.

*/