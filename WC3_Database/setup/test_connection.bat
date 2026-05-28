@echo off
REM ============================================================================
REM Database Connection Test Script
REM ============================================================================
REM This script tests your PostgreSQL database connection
REM ============================================================================

echo.
echo ========================================
echo PostgreSQL Connection Test
echo ========================================
echo.

REM Check if database.ini exists
if not exist "database.ini" (
    echo [!] ERROR: database.ini not found
    echo [!] Please copy database.ini.example to database.ini and edit it
    echo.
    pause
    exit /b 1
)

REM Parse database.ini
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

echo Configuration from database.ini:
echo   Host:     %DB_HOST%
echo   Port:     %DB_PORT%
echo   Database: %DB_NAME%
echo   User:     %DB_USER%
echo   Password: %DB_PASSWORD%
echo.

REM If no password, prompt
if "%DB_PASSWORD%"=="" (
    set /p DB_PASSWORD="Enter password: "
)

set PGPASSWORD=%DB_PASSWORD%

echo ========================================
echo Test 1: Check if PostgreSQL is running
echo ========================================
psql --version >nul 2>&1
if errorlevel 1 (
    echo [!] FAIL: psql command not found
    echo [!] Please ensure PostgreSQL is installed and in your PATH
    echo.
    pause
    exit /b 1
) else (
    echo [+] PASS: psql command found
)
echo.

echo ========================================
echo Test 2: Connect to PostgreSQL server
echo ========================================
echo Connecting to PostgreSQL server (postgres database)...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "SELECT version();" 2>error.tmp
if errorlevel 1 (
    echo [!] FAIL: Could not connect to PostgreSQL server
    echo.
    echo Common issues:
    echo   1. PostgreSQL service not running
    echo   2. Wrong host/port
    echo   3. Wrong username/password
    echo   4. PostgreSQL not configured to accept connections from %DB_HOST%
    echo.
    if exist error.tmp (
        echo Error details:
        type error.tmp
        del error.tmp
    )
    echo.
    pause
    exit /b 1
) else (
    echo [+] PASS: Successfully connected to PostgreSQL server
    if exist error.tmp del error.tmp
)
echo.

echo ========================================
echo Test 3: Check if database exists
echo ========================================
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='%DB_NAME%';" 2>nul | findstr "1" >nul
if errorlevel 1 (
    echo [!] WARNING: Database '%DB_NAME%' does not exist
    echo.
    choice /C YN /M "Do you want to create the database now"
    if errorlevel 2 (
        echo.
        echo Database was not created. You can create it manually with:
        echo   psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "CREATE DATABASE \"%DB_NAME%\";"
        echo.
        pause
        exit /b 0
    )
    echo.
    echo Creating database '%DB_NAME%'...
    psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d postgres -c "CREATE DATABASE \"%DB_NAME%\";" 2>error.tmp
    if errorlevel 1 (
        echo [!] FAIL: Could not create database
        if exist error.tmp (
            type error.tmp
            del error.tmp
        )
        pause
        exit /b 1
    ) else (
        echo [+] SUCCESS: Database created
        if exist error.tmp del error.tmp
    )
) else (
    echo [+] PASS: Database '%DB_NAME%' exists
)
echo.

echo ========================================
echo Test 4: Connect to target database
echo ========================================
echo Connecting to database '%DB_NAME%'...
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -c "SELECT current_database(), current_user;" 2>error.tmp
if errorlevel 1 (
    echo [!] FAIL: Could not connect to database '%DB_NAME%'
    if exist error.tmp (
        type error.tmp
        del error.tmp
    )
    pause
    exit /b 1
) else (
    echo [+] PASS: Successfully connected to database '%DB_NAME%'
    if exist error.tmp del error.tmp
)
echo.

echo ========================================
echo Test 5: Check if stat tables exist
echo ========================================
psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'stat_definitions';" 2>nul | findstr "1" >nul
if errorlevel 1 (
    echo [!] WARNING: Enhanced stat tables not installed
    echo [!] Run setup_existing_db.bat to install them
) else (
    echo [+] PASS: Enhanced stat tables are installed
    
    REM Count stats
    for /f "tokens=*" %%a in ('psql -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM stat_definitions;" 2^>nul') do set STAT_COUNT=%%a
    set STAT_COUNT=%STAT_COUNT: =%
    echo [+] Found %STAT_COUNT% stat definitions
)
echo.

echo ========================================
echo All Tests Complete!
echo ========================================
echo.
echo Your database connection is working correctly.
echo You can now use:
echo   - setup_existing_db.bat   (to install stat system)
echo   - wc3_exporter_enhanced.py (to export items)
echo.
pause
