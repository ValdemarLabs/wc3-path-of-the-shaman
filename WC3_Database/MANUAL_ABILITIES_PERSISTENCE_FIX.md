# Manual Abilities Persistence Fix

## Problem
Manual abilities (Code, Type, Description) were being lost when loading items because only the ability **codes** were stored in the database, not the Type and Description columns from the DataGridView.

## Solution
Added complete persistence for manual ability data using JSON storage:

### 1. Database Schema
- **New Column**: `manual_abilities_data` (JSONB)
- **Purpose**: Store complete manual ability information including Code, Type, and Description
- **Format**: JSON array like `[{"Code":"A001","Type":"Passive","Description":"Bash - random stun"}]`
- **Auto-Creation**: Column is automatically created on startup if it doesn't exist

### 2. Code Changes

#### ItemEditForm.cs

**Added Helper Class**:
```csharp
public class ManualAbilityData
{
    public string Code { get; set; }
    public string Type { get; set; }
    public string Description { get; set; }
}
```

**Added Methods**:
- `EnsureManualAbilitiesColumn()` - Creates database column if missing
- `LoadManualAbilitiesFromCodes()` - Fallback for legacy data

**Modified Methods**:
- **Constructor**: Added call to `EnsureManualAbilitiesColumn()`
- **AddParameters()**: Serializes DataGridView data to JSON and saves to `manual_abilities_data`
- **LoadItem()**: Deserializes JSON and populates DataGridView with Code, Type, and Description
- **SQL Queries**: Added `manual_abilities_data` to both INSERT and UPDATE statements

### 3. Behavior

#### When Saving:
1. Collects all rows from `dgvManualAbilities`
2. Creates `ManualAbilityData` objects for each row
3. Serializes to JSON using `System.Text.Json`
4. Saves to `manual_abilities_data` column

#### When Loading:
1. Reads `manual_abilities_data` JSON from database
2. Deserializes to `List<ManualAbilityData>`
3. Populates DataGridView with all three columns (Code, Type, Description)
4. Falls back to code-only loading if JSON is missing (legacy compatibility)

### 4. Files Changed
- `ItemEditForm.cs` - Main implementation
- `add_manual_abilities_field.sql` - Database migration script (optional, auto-created by code)

### 5. Testing
1. Close the running application
2. Rebuild: `dotnet build WC3ItemManager.csproj`
3. Run the application
4. Edit an item with manual abilities
5. Add Type and Description values
6. Save the item
7. Close and reload the item
8. **Expected**: Type and Description are now preserved

## Technical Details
- **Serialization**: Uses `System.Text.Json.JsonSerializer`
- **Database Type**: JSONB (PostgreSQL native JSON with indexing support)
- **Backward Compatible**: Legacy items with code-only data still load correctly
- **Non-Breaking**: If column creation fails, application continues without error

## Migration
No manual migration required - the database column is automatically created on first run after this update.
