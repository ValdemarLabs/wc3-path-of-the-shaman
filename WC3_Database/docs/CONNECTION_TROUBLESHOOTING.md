# Database Connection Troubleshooting Guide

## Quick Diagnosis

Run this test script to check your connection:

```powershell
.\test_connection.bat
```

This will test:
1. ✅ PostgreSQL is installed
2. ✅ Can connect to PostgreSQL server
3. ✅ Database exists (or offer to create it)
4. ✅ Can connect to your specific database
5. ✅ Enhanced stat tables are installed

---

## Common Issues & Solutions

### Issue 1: "Could not connect to database"

**Check these:**

1. **PostgreSQL is running**
   ```powershell
   # Check if PostgreSQL service is running
   Get-Service postgresql*
   
   # Start it if stopped
   Start-Service postgresql-x64-14  # (adjust version number)
   ```

2. **Correct password in database.ini**
   ```ini
   password = YOUR_ACTUAL_PASSWORD
   ```
   **NOT:** `password = YOUR_PASSWORD_HERE` (change this!)

3. **Database exists**
   ```powershell
   # Check if database exists
   psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "SELECT datname FROM pg_database;"
   
   # Create it if missing
   psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE \"WC3_POTS\";"
   ```

4. **Correct database name** (case matters on Linux/Mac, not Windows)
   - Your config says: `WC3_POTS`
   - Make sure database actually has that name

### Issue 2: "psql: command not found"

**Solution:** Add PostgreSQL to PATH

```powershell
# Find PostgreSQL installation
$pgPath = "C:\Program Files\PostgreSQL\14\bin"  # Adjust version

# Add to PATH temporarily
$env:Path += ";$pgPath"

# Or add permanently via System Properties > Environment Variables
```

### Issue 3: "Password authentication failed"

**Solutions:**

1. **Check password is correct**
   - Try connecting manually:
   ```powershell
   psql -U postgres -h 127.0.0.1 -p 5432 -d postgres
   # Enter password when prompted
   ```

2. **Reset PostgreSQL password**
   - Find `pg_hba.conf` (usually in `C:\Program Files\PostgreSQL\14\data\`)
   - Change `md5` to `trust` temporarily
   - Restart PostgreSQL service
   - Connect and change password:
   ```sql
   ALTER USER postgres WITH PASSWORD 'new_password';
   ```
   - Change `trust` back to `md5` in pg_hba.conf
   - Restart PostgreSQL service

### Issue 4: "Database does not exist"

**Solution:** Create the database first

```powershell
# Set password
$env:PGPASSWORD="your_password"

# Create database (using name from your config)
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE \"WC3_POTS\";"

# Or create with different name
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE wc3_pots;"

# Then update database.ini to match:
database = wc3_pots
```

### Issue 5: Connection timeout

**Check:**

1. **PostgreSQL is listening on 127.0.0.1**
   - Edit `postgresql.conf`:
   ```
   listen_addresses = 'localhost, 127.0.0.1'
   ```

2. **Port 5432 is not blocked**
   ```powershell
   # Check if port is open
   Test-NetConnection -ComputerName 127.0.0.1 -Port 5432
   ```

3. **Firewall allows PostgreSQL**
   - Windows Firewall → Allow PostgreSQL

---

## Step-by-Step Manual Test

### 1. Check your database.ini file

```powershell
notepad database.ini
```

Make sure it looks like:
```ini
[postgresql]
host = 127.0.0.1
port = 5432
database = WC3_POTS    # Your database name
user = postgres
password = 009900      # Your actual password
```

### 2. Test connection manually

```powershell
# Set password
$env:PGPASSWORD="009900"  # Use your actual password

# Try connecting to PostgreSQL server
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "SELECT version();"
```

**If this fails:** PostgreSQL isn't running or password is wrong

**If this works:** PostgreSQL is fine, check database name

### 3. Check if your database exists

```powershell
$env:PGPASSWORD="009900"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "SELECT datname FROM pg_database WHERE datname='WC3_POTS';"
```

**If nothing returned:** Database doesn't exist, create it:

```powershell
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE \"WC3_POTS\";"
```

### 4. Test connecting to your database

```powershell
$env:PGPASSWORD="009900"
psql -U postgres -h 127.0.0.1 -p 5432 -d WC3_POTS -c "SELECT current_database();"
```

**If this works:** Connection is fine! Run setup_existing_db.bat

---

## Quick Fixes

### Option A: Use Default Database Name

Change your `database.ini` to use the standard name:

```ini
database = wc3_pots
```

Then create it:

```powershell
$env:PGPASSWORD="009900"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE wc3_pots;"
```

### Option B: Create Database with Your Current Name

```powershell
$env:PGPASSWORD="009900"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE \"WC3_POTS\";"
```

---

## After Fixing Connection

Once connection works, run:

```powershell
# Test connection
.\test_connection.bat

# If all tests pass, install stat system
.\setup_existing_db.bat
```

---

## Still Not Working?

### Get detailed error information:

```powershell
# Run with verbose output
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres --echo-errors
```

### Check PostgreSQL logs:

Usually in: `C:\Program Files\PostgreSQL\14\data\log\`

### Common error messages:

| Error Message | Solution |
|---------------|----------|
| "connection refused" | PostgreSQL service not running |
| "password authentication failed" | Wrong password in database.ini |
| "database does not exist" | Create database first |
| "role does not exist" | User 'postgres' doesn't exist (check user name) |
| "could not connect to server" | Wrong host/port or PostgreSQL not installed |

---

## Need Help?

1. Run `.\test_connection.bat` and copy the output
2. Check PostgreSQL logs
3. Verify database.ini has correct values
4. Make sure PostgreSQL service is running

**The test_connection.bat script will tell you exactly what's wrong!**
