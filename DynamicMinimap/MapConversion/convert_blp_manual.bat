@echo off
REM Batch convert PNG to BLP using BLPLab
REM This will open BLPLab GUI - you need to do File > Batch Convert manually

set BLPLAB="H:\Pelit\WC3_Tools\BLP Laboratory\blplab.exe"
set INPUT_DIR="war3mapImportedBLP"

echo Starting BLPLab...
echo.
echo Instructions:
echo 1. BLPLab will open
echo 2. Go to: File ^> Batch Convert
echo 3. Select folder: %INPUT_DIR%
echo 4. Choose "PNG to BLP" conversion
echo 5. Set output format: BLP1 or BLP2 (recommended: BLP1)
echo 6. Click Convert All
echo.
pause

start "" %BLPLAB%

echo.
echo Or use this PowerShell one-liner for manual conversion:
echo Get-ChildItem war3mapImported\*.png ^| ForEach-Object { "Convert: $($_.Name)" }
