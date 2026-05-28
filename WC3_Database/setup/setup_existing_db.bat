@echo off
REM ============================================================================
REM WC3 POTS Database - Quick Start Script for Existing Database
REM ============================================================================
REM This script helps you upgrade your existing database to use the stat system
REM ============================================================================

echo.
echo ========================================
echo WC3 POTS Database Enhancement Setup
echo ========================================
echo.

REM Check if database.ini exists
if not exist "database.ini" (
    echo [!] database.ini not found.
    echo [*] Creating from database.ini.example...
    copy database.ini.example database.ini
    echo.
    echo [!] IMPORTANT: Edit database.ini with your database credentials!
    echo [!] Then run this script again.
    notepad database.ini
    pause
    exit /b 1
)

echo [*] Found database.ini
echo.

REM Parse database.ini to get connection details
for /f "tokens=2 delims==" %%a in ('findstr "^host" database.ini') do set DB_HOST=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^port" database.ini') do set DB_PORT=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^database" database.ini') do set DB_NAME=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^user" database.ini') do set DB_USER=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^password" database.ini') do set DB_PASSWORD=%%a

REM Remove leading and trailing spaces
for /f "tokens=* delims= " %%a in ("%DB_HOST%") do set DB_HOST=%%a
for /f "tokens=* delims= " %%a in ("%DB_PORT%") do set DB_PORT=%%a
for /f "tokens=* delims= " %%a in ("%DB_NAME%") do set DB_NAME=%%a
for /f "tokens=* delims= " %%a in ("%DB_USER%") do set DB_USER=%%a
for /f "tokens=* delims= " %%a in ("%DB_PASSWORD%") do set DB_PASSWORD=%%a

REM If no password in config, prompt for it
if "%DB_PASSWORD%"=="" (
    set /p DB_PASSWORD="Enter your PostgreSQL password: "
)

REM Set PGPASSWORD environment variable for psql
set PGPASSWORD=%DB_PASSWORD%

echo [*] Database Configuration:
echo     Host: %DB_HOST%
echo     Port: %DB_PORT%
echo     Database: %DB_NAME%
echo     User: %DB_USER%
echo.

REM Test database connection
echo [*] Testing database connection...
echo [*] Trying to connect to: %DB_NAME% on %DB_HOST%:%DB_PORT% as user %DB_USER%
echo.

REM First check if PostgreSQL server is accessible
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Could not connect to PostgreSQL server.
    echo [!] Please check:
    echo [!]   - PostgreSQL is running
    echo [!]   - Host: %DB_HOST%
    echo [!]   - Port: %DB_PORT%
    echo [!]   - User: %DB_USER%
    echo [!]   - Password is correct
    echo.
    pause
    exit /b 1
)

REM Check if the database exists
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "SELECT 1 FROM pg_database WHERE datname='%DB_NAME%';" -t >nul 2>&1
if errorlevel 1 (
    echo [!] WARNING: Database '%DB_NAME%' does not exist.
    echo.
    choice /C YN /M "Do you want to create the database now"
    if errorlevel 2 (
        echo [!] Setup cancelled.
        pause
        exit /b 1
    )
    echo [*] Creating database '%DB_NAME%'...
    psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "CREATE DATABASE \"%DB_NAME%\";" >nul 2>&1
    if errorlevel 1 (
        echo [!] ERROR: Failed to create database.
        pause
        exit /b 1
    )
    echo [+] Database created successfully!
)

REM Test connection to the actual database
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -c "SELECT version();" >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Could not connect to database '%DB_NAME%'.
    echo [!] Please check your credentials in database.ini
    pause
    exit /b 1
)
echo [+] Database connection successful!
echo.

REM Check if items table exists
echo [*] Checking existing database structure...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -c "\dt items" >nul 2>&1
if errorlevel 1 (
    echo [!] WARNING: Items table not found.
    echo [!] This script assumes you have an existing database with items.
    echo.
    choice /C YN /M "Do you want to create a fresh database instead"
    if errorlevel 2 goto :upgrade_existing
    if errorlevel 1 goto :fresh_install
) else (
    echo [+] Found existing items table
    
    REM Count items
    for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM items;"') do set ITEM_COUNT=%%a
    set ITEM_COUNT=%ITEM_COUNT: =%
    echo [+] Current items in database: %ITEM_COUNT%
    echo.
    goto :upgrade_existing
)

:fresh_install
echo.
echo ========================================
echo Fresh Installation
echo ========================================
echo [*] Installing base schema...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -f schema.sql
if errorlevel 1 (
    echo [!] ERROR: Failed to install base schema
    pause
    exit /b 1
)
echo [+] Base schema installed
goto :install_enhancements

:upgrade_existing
echo.
echo ========================================
echo Upgrading Existing Database
echo ========================================
echo.
echo [!] IMPORTANT: This will add new tables to your database.
echo [!] Your existing items and data will NOT be deleted.
echo.
choice /C YN /M "Do you want to create a backup first"
if errorlevel 2 goto :skip_backup
if errorlevel 1 goto :create_backup

:create_backup
echo.
echo [*] Creating backup...
set BACKUP_FILE=backup_before_statid_%DATE:~-4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.sql
set BACKUP_FILE=%BACKUP_FILE: =0%
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -c "\! pg_dump -U %DB_USER% -h %DB_HOST% -p %DB_PORT% %DB_NAME% > %BACKUP_FILE%"
if errorlevel 1 (
    echo [!] WARNING: Backup may have failed, but continuing...
) else (
    echo [+] Backup created: %BACKUP_FILE%
)
echo.

:skip_backup
:install_enhancements
echo [*] Installing stat system enhancements...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -f schema_stats_enhancement.sql
if errorlevel 1 (
    echo [!] ERROR: Failed to install enhancements
    pause
    exit /b 1
)
echo [+] Stat system enhancements installed!
echo.

REM Verify installation
echo [*] Verifying installation...
for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM stat_definitions;"') do set STAT_COUNT=%%a
set STAT_COUNT=%STAT_COUNT: =%
for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM ability_codes;"') do set ABILITY_COUNT=%%a
set ABILITY_COUNT=%ABILITY_COUNT: =%

if "%STAT_COUNT%"=="39" (
    echo [+] stat_definitions table: %STAT_COUNT% stats
) else (
    echo [!] WARNING: Expected 39 stats, found %STAT_COUNT%
)

if "%ABILITY_COUNT%"=="16" (
    echo [+] ability_codes table: %ABILITY_COUNT% abilities
) else (
    echo [!] WARNING: Expected 16 abilities, found %ABILITY_COUNT%
)
echo.

echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo [+] Your database now supports the full DEquipment stat system!
echo.
echo Next Steps:
echo   1. Add stats to your items using statids (see MIGRATION_GUIDE.md)
echo   2. Export items: python wc3_exporter_enhanced.py --output items.j --format deq_enhanced
echo   3. Review documentation: STAT_SYSTEM_REFERENCE.md
echo.
echo Example: Add +50 STR to an item:
echo   psql -U %DB_USER% -d %DB_NAME%
echo   INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
echo   SELECT id, 1, 50 FROM items WHERE item_code = 'I000';
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] WARNING: Python not found. You'll need Python to use the exporters.
    echo [!] Install Python 3.7+ from https://www.python.org/
) else (
    echo [*] Python detected. Installing requirements...
    pip install -r requirements.txt >nul 2>&1
    if errorlevel 1 (
        echo [!] Note: Some Python packages may need to be installed manually
        echo [!] Run: pip install -r requirements.txt
    ) else (
        echo [+] Python packages installed
    )
)
echo.

choice /C YN /M "Do you want to view the migration guide now"
if errorlevel 2 goto :end
if errorlevel 1 start MIGRATION_GUIDE.md

:end
echo.
echo Done! Press any key to exit...
pause >nul
