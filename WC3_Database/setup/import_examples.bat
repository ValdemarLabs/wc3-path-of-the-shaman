@echo off
REM ===========================================================================
REM WC3 Database Import Example Data Script
REM ===========================================================================
REM This script imports the example items into the database
REM ===========================================================================

echo.
echo ============================================================
echo WC3 PotS Database - Import Example Data
echo ============================================================
echo.

REM Check if Python is available
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    pause
    exit /b 1
)

echo [1/2] Checking if example_items.json exists...
if not exist "example_items.json" (
    echo ERROR: example_items.json not found
    echo Please ensure you are in the WC3_Database directory
    pause
    exit /b 1
)
echo OK: Found example_items.json
echo.

echo [2/2] Importing example data...
python wc3_importer.py example_items.json --format json

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo Import completed successfully!
    echo ============================================================
    echo.
    echo You can now:
    echo   - View items in pgAdmin or psql
    echo   - Export to JASS: python wc3_exporter.py --output Items.j --format jass
    echo   - Query database: psql -U postgres -d wc3_pots
    echo.
) else (
    echo.
    echo ERROR: Import failed
    echo Please check the error messages above
    echo.
)

pause
