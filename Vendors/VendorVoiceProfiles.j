/**
    VendorVoiceProfiles

    Author: Valdemar
    Version: 2.0.0

    Description:
    Compatibility dependency for maps that already import VendorVoiceProfiles.
    Merchant dialogue data and profile constants now live together in
    Voicelines/Voicelines_VendorLines.j.

    Credits:

    How to install:
    Import VoicelinesVendorLines before vendor catalog and faction libraries.

    API:
    - Use VL_VENDOR_PROFILE_* constants from VoicelinesVendorLines.

**/
library VendorVoiceProfiles requires VoicelinesVendorLines
endlibrary
