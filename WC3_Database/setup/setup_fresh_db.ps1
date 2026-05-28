# ============================================================================
# Create Fresh WC3_POTS Database with Enhanced Stat System
# ============================================================================
# This script:
#   1. Creates a fresh WC3_POTS database
#   2. Installs base schema + enhanced stat system
# ============================================================================

Write-Host ""
Write-Host "========================================"
Write-Host "WC3_POTS Fresh Database Setup"
Write-Host "========================================"
Write-Host ""

# Add PostgreSQL to PATH
$env:PATH = "C:\Program Files\PostgreSQL\18\bin;$env:PATH"

# Check if database.ini exists
if (-not (Test-Path "database.ini")) {
    Write-Host "[!] ERROR: database.ini not found" -ForegroundColor Red
    Write-Host "[!] Please ensure database.ini is configured" -ForegroundColor Red
    pause
    exit 1
}

# Parse database.ini
Write-Host "[*] Reading configuration from database.ini..."
$config = @{}
Get-Content "database.ini" | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $config[$key] = $value
    }
}

$DB_HOST = $config['host']
$DB_PORT = $config['port']
$DB_NAME = $config['database']
$DB_USER = $config['user']
$DB_PASSWORD = $config['password']

if (-not $DB_PASSWORD) {
    $securePassword = Read-Host "Enter PostgreSQL password" -AsSecureString
    $DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
}

$env:PGPASSWORD = $DB_PASSWORD

Write-Host ""
Write-Host "Configuration:"
Write-Host "  Host:     $DB_HOST"
Write-Host "  Port:     $DB_PORT"
Write-Host "  Database: $DB_NAME"
Write-Host "  User:     $DB_USER"
Write-Host ""

# Test connection to PostgreSQL
Write-Host "[*] Testing PostgreSQL connection..."
$result = & psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d postgres -c "SELECT version();" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Could not connect to PostgreSQL" -ForegroundColor Red
    Write-Host "[!] Please check your credentials" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[+] PostgreSQL connection OK" -ForegroundColor Green
Write-Host ""

# Create new database
Write-Host "[*] Creating fresh database '$DB_NAME'..."
$result = & psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d postgres -c "CREATE DATABASE `"$DB_NAME`" WITH ENCODING='UTF8';" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Could not create database" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[+] Database '$DB_NAME' created successfully" -ForegroundColor Green

# Wait for database to be fully ready
Start-Sleep -Milliseconds 500

Write-Host ""

# Install base schema
Write-Host "[*] Installing base schema (schema.sql)..."
$result = & psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f schema.sql 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Failed to install base schema" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    Write-Host "[!] Check schema.sql for errors" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[+] Base schema installed" -ForegroundColor Green
Write-Host ""

# Install enhanced stat system
Write-Host "[*] Installing enhanced stat system (schema_stats_enhancement.sql)..."
$result = & psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f schema_stats_enhancement.sql 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Failed to install stat system enhancement" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    Write-Host "[!] Check schema_stats_enhancement.sql for errors" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[+] Enhanced stat system installed" -ForegroundColor Green
Write-Host ""

# Verify installation
Write-Host "[*] Verifying installation..."
$STAT_COUNT = (& psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM stat_definitions;" 2>&1).Trim()
$ABILITY_COUNT = (& psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM ability_codes;" 2>&1).Trim()
$TABLE_COUNT = (& psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>&1).Trim()

Write-Host ""
Write-Host "========================================"
Write-Host "Installation Summary"
Write-Host "========================================"
Write-Host "[+] Database: $DB_NAME" -ForegroundColor Green
Write-Host "[+] Tables created: $TABLE_COUNT" -ForegroundColor Green
Write-Host "[+] Stat definitions: $STAT_COUNT (expected 39)" -ForegroundColor Green
Write-Host "[+] Ability codes: $ABILITY_COUNT (expected 16)" -ForegroundColor Green
Write-Host ""

if ($STAT_COUNT -eq "39" -and $ABILITY_COUNT -eq "16") {
    Write-Host "[+] SUCCESS: All components installed correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your fresh database is ready with:"
    Write-Host "  - Full 39-stat DEquipment system"
    Write-Host "  - 16 ability codes with field mappings"
    Write-Host "  - item_stat_bonuses table for flexible stat assignment"
    Write-Host "  - Helper views for easy querying"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Add items: psql -U $DB_USER -d $DB_NAME"
    Write-Host "  2. Add stats to items using statids (see QUICKSTART_EXISTING_DB.md)"
    Write-Host "  3. Export: python wc3_exporter_enhanced.py --output items.j"
    Write-Host ""
    Write-Host "Documentation:"
    Write-Host "  - STAT_SYSTEM_REFERENCE.md (all 39 stats)"
    Write-Host "  - QUICKSTART_EXISTING_DB.md (common operations)"
    Write-Host "  - MIGRATION_GUIDE.md (detailed guide)"
    Write-Host ""
} else {
    Write-Host "[!] WARNING: Verification check mismatch" -ForegroundColor Yellow
    Write-Host "  Expected: 39 stats, 16 abilities" -ForegroundColor Yellow
    Write-Host "  Found: $STAT_COUNT stats, $ABILITY_COUNT abilities" -ForegroundColor Yellow
}

Write-Host ""
pause
