@echo off
REM ===========================================================================
REM WC3 Database Quick Setup Script
REM ===========================================================================
REM This script helps set up the WC3 Items PostgreSQL database
REM ===========================================================================

echo.
echo ============================================================
echo WC3 PotS PostgreSQL Database - Quick Setup
echo ============================================================
echo.

REM Check if PostgreSQL is installed
where psql >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: PostgreSQL is not installed or not in PATH
    echo.
    echo Please install PostgreSQL from:
    echo https://www.postgresql.org/download/windows/
    echo.
    pause
    exit /b 1
)

echo [1/5] PostgreSQL found
echo.

REM Check if Python is installed
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo.
    echo Please install Python 3.7+ from:
    echo https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [2/5] Python found
echo.

REM Install Python dependencies
echo [3/5] Installing Python dependencies...
python -m pip install --upgrade pip
python -m pip install psycopg2-binary
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install Python dependencies
    pause
    exit /b 1
)
echo.

REM Copy configuration file if it doesn't exist
if not exist "database.ini" (
    echo [4/5] Creating database.ini configuration file...
    copy database.ini.example database.ini
    echo.
    echo IMPORTANT: Please edit database.ini and set your PostgreSQL password!
    echo.
    notepad database.ini
) else (
    echo [4/5] database.ini already exists
)
echo.

REM Try to create database
echo [5/5] Creating database...
echo.
set /p DB_PASS="Enter PostgreSQL password for user 'postgres': "
set PGPASSWORD=%DB_PASS%
echo.

REM Parse database name from config if it exists
if exist "database.ini" (
    for /f "tokens=2 delims==" %%a in ('findstr "^database" database.ini') do set DB_NAME=%%a
    for /f "tokens=* delims= " %%a in ("%DB_NAME%") do set DB_NAME=%%a
) else (
    set DB_NAME=wc3_pots
)

REM Create database using the name from config
echo Creating database '%DB_NAME%'...
psql -U postgres -h localhost -c "CREATE DATABASE \"%DB_NAME%\";" 2>nul
if %ERRORLEVEL% equ 0 (
    echo Database '%DB_NAME%' created successfully
) else (
    echo Database '%DB_NAME%' already exists or creation failed
)
echo.

REM Initialize schema
echo Initializing database schema...
set PGPASSWORD=%PGPASSWORD%
psql -U postgres -d wc3_pots -f schema.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to initialize database schema
    pause
    exit /b 1
)
echo.

echo ============================================================
echo Setup completed successfully!
echo ============================================================
echo.
echo Next steps:
echo   1. Edit database.ini with your PostgreSQL credentials
echo   2. Import example data: python wc3_importer.py example_items.json
echo   3. View items in database: psql -U postgres -d wc3_pots
echo.
echo Quick commands:
echo   - Import: python wc3_importer.py your_file.json
echo   - Export: python wc3_exporter.py --output Items.j --format jass
echo   - Query:  psql -U postgres -d wc3_pots
echo.
echo See README.md for detailed documentation
echo.
pause
