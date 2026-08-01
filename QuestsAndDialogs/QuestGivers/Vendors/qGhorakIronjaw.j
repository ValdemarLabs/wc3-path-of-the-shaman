/**
    qGhorakIronjaw

    Author: Valdemar
    Version: 1.0.0

    Description:
    Daily vendor quest content for Ghorak Ironjaw, Orc weaponsmith.

    Credits:

    How to install:
    Import after VendorQuests and VoicelinesVendorQuests.

    API:
    Registers Ghorak's vendor quest automatically.

**/
library qGhorakIronjaw initializer Init requires VendorQuests, VoicelinesVendorQuests
    private function Init takes nothing returns nothing
        call VendorQuests_RegisterFetchQuest('o011', "Ore for the Edge", "daily", 4, "Ore for the Edge", "ReplaceableTextures\\CommandButtons\\BTNOrcMeleeUpOne.blp", "Bring Ghorak iron ore suitable for sharpening the day's weapon stock.", 'I67E', 5, 25, VL_VENDORQUEST_ORC_TYPE, 1, "A sharp blade starts with honest ore. Bring me five pieces before the forge cools.", "Good weight, clean grain. These will make blades worth carrying.")
    endfunction
endlibrary
