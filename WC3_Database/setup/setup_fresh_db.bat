@echo off
REM ============================================================================
REM Create Fresh WC3_POTS Database with Enhanced Stat System
REM ============================================================================
REM This script:
REM   1. Renames existing WC3_POTS to WC3_POTS_test (if it exists)
REM   2. Creates a fresh WC3_POTS database
REM   3. Installs base schema + enhanced stat system
REM ============================================================================

echo.
echo ========================================
echo WC3_POTS Fresh Database Setup
echo ========================================
echo.

REM Check if database.ini exists
if not exist "database.ini" (
    echo [!] ERROR: database.ini not found
    echo [!] Please ensure database.ini is configured
    pause
    exit /b 1
)

REM Parse database.ini - Use a more robust method
for /f "usebackq tokens=1,* delims==" %%a in (`findstr /b "host" database.ini`) do (
    for /f "tokens=*" %%c in ("%%b") do set "DB_HOST=%%c"
)
for /f "usebackq tokens=1,* delims==" %%a in (`findstr /b "port" database.ini`) do (
    for /f "tokens=*" %%c in ("%%b") do set "DB_PORT=%%c"
)
for /f "usebackq tokens=1,* delims==" %%a in (`findstr /b "database" database.ini`) do (
    for /f "tokens=*" %%c in ("%%b") do set "DB_NAME=%%c"
)
for /f "usebackq tokens=1,* delims==" %%a in (`findstr /b "user" database.ini`) do (
    for /f "tokens=*" %%c in ("%%b") do set "DB_USER=%%c"
)
for /f "usebackq tokens=1,* delims==" %%a in (`findstr /b "password" database.ini`) do (
    for /f "tokens=*" %%c in ("%%b") do set "DB_PASSWORD=%%c"
)

if "%DB_PASSWORD%"=="" (
    set /p DB_PASSWORD="Enter PostgreSQL password: "
)

set PGPASSWORD=%DB_PASSWORD%

echo Configuration:
echo   Host:     %DB_HOST%
echo   Port:     %DB_PORT%
echo   Database: %DB_NAME%
echo   User:     %DB_USER%
echo.

REM Test connection to PostgreSQL
echo [*] Testing PostgreSQL connection...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "SELECT version();" >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Could not connect to PostgreSQL
    echo [!] Please check your credentials
    pause
    exit /b 1
)
echo [+] PostgreSQL connection OK
echo.

REM Check if database exists
echo [*] Checking if database '%DB_NAME%' exists...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='%DB_NAME%';" 2>nul | findstr "1" >nul
if not errorlevel 1 (
    echo [!] Database '%DB_NAME%' already exists
    echo.
    choice /C YN /M "Do you want to rename it to '%DB_NAME%_test' and create a fresh database"
    if errorlevel 2 (
        echo [!] Setup cancelled
        pause
        exit /b 0
    )
    
    echo.
    echo [*] Checking if any connections are using the database...
    psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DB_NAME%' AND pid <> pg_backend_pid();" >nul 2>&1
    
    echo [*] Renaming '%DB_NAME%' to '%DB_NAME%_test'...
    psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "ALTER DATABASE \"%DB_NAME%\" RENAME TO \"%DB_NAME%_test\";" 2>error.tmp
    if errorlevel 1 (
        echo [!] WARNING: Could not rename database
        if exist error.tmp (
            type error.tmp
            del error.tmp
        )
        echo [!] You may need to disconnect any active connections first
        pause
        exit /b 1
    )
    echo [+] Database renamed to '%DB_NAME%_test'
    if exist error.tmp del error.tmp
    echo.
)

REM Create new database
echo [*] Creating fresh database '%DB_NAME%'...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "CREATE DATABASE \"%DB_NAME%\" WITH ENCODING='UTF8';" 2>error.tmp
if errorlevel 1 (
    echo [!] ERROR: Could not create database
    if exist error.tmp (
        type error.tmp
        del error.tmp
    )
    pause
    exit /b 1
)
echo [+] Database '%DB_NAME%' created successfully
if exist error.tmp del error.tmp
echo.

REM Install base schema
echo [*] Installing base schema (schema.sql)...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -f schema.sql >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Failed to install base schema
    echo [!] Check schema.sql for errors
    pause
    exit /b 1
)
echo [+] Base schema installed
echo.

REM Install enhanced stat system
echo [*] Installing enhanced stat system (schema_stats_enhancement.sql)...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -f schema_stats_enhancement.sql >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Failed to install stat system enhancement
    echo [!] Check schema_stats_enhancement.sql for errors
    pause
    exit /b 1
)
echo [+] Enhanced stat system installed
echo.

REM Verify installation
echo [*] Verifying installation...
for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM stat_definitions;" 2^>nul') do set STAT_COUNT=%%a
for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM ability_codes;" 2^>nul') do set ABILITY_COUNT=%%a
for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2^>nul') do set TABLE_COUNT=%%a

set STAT_COUNT=%STAT_COUNT: =%
set ABILITY_COUNT=%ABILITY_COUNT: =%
set TABLE_COUNT=%TABLE_COUNT: =%

echo.
echo ========================================
echo Installation Summary
echo ========================================
echo [+] Database: %DB_NAME%
echo [+] Tables created: %TABLE_COUNT%
echo [+] Stat definitions: %STAT_COUNT% (expected 39)
echo [+] Ability codes: %ABILITY_COUNT% (expected 16)
echo.

if "%STAT_COUNT%"=="39" (
    if "%ABILITY_COUNT%"=="16" (
        echo [+] SUCCESS: All components installed correctly!
        echo.
        echo Your fresh database is ready with:
        echo   - Full 39-stat DEquipment system
        echo   - 16 ability codes with field mappings
        echo   - item_stat_bonuses table for flexible stat assignment
        echo   - Helper views for easy querying
        echo.
        echo Next steps:
        echo   1. Add items: psql -U %DB_USER% -d %DB_NAME%
        echo   2. Add stats to items using statids (see QUICKSTART_EXISTING_DB.md)
        echo   3. Export: python wc3_exporter_enhanced.py --output items.j
        echo.
        echo Documentation:
        echo   - STAT_SYSTEM_REFERENCE.md (all 39 stats)
        echo   - QUICKSTART_EXISTING_DB.md (common operations)
        echo   - MIGRATION_GUIDE.md (detailed guide)
        echo.
    ) else (
        echo [!] WARNING: Expected 16 ability codes, found %ABILITY_COUNT%
    )
) else (
    echo [!] WARNING: Expected 39 stat definitions, found %STAT_COUNT%
)

echo Old test database is preserved as: %DB_NAME%_test
echo You can drop it later with: DROP DATABASE "%DB_NAME%_test";
echo.
pause
