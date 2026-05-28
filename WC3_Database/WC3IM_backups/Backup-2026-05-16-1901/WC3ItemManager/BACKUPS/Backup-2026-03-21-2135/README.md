# WC3 Item Manager

A powerful Windows Forms application for managing Warcraft 3 items in the PotS PostgreSQL database.

## Features

✅ **Full CRUD Operations**
- Create new items
- Edit existing items
- Delete items
- View all items in sortable grid

✅ **Advanced Filtering**
- Search by name, code, or tooltip
- Filter by rarity (Common, Uncommon, Rare, Epic, Legendary)
- Filter by class (MISC, CONSUMABLE, ARTIFACT, QUEST)
- Filter by item level range
- Custom items only filter

✅ **Comprehensive Item Editing**
- **Basic Info Tab**: Code, name, level, costs, charges, flags
- **Extended Info Tab**: Tooltips, description, hotkey
- **WC3 Properties Tab**: Classification, paths, abilities

✅ **Database Integration**
- Direct PostgreSQL connection
- All 60+ WC3 fields supported
- Preserves tooltip_extended, hotkey, abilities
- Auto-creates rarity/class entries

## Prerequisites

- .NET 6.0 SDK or later
- Visual Studio 2022 (recommended) or VS Code
- PostgreSQL database (wc3_pots)

## Building the Application

### Option 1: Visual Studio 2022
```bash
cd WC3ItemManager
# Open WC3ItemManager.csproj in Visual Studio
# Press F5 to build and run
```

### Option 2: Command Line
```bash
cd WC3ItemManager
dotnet restore
dotnet build
dotnet run
```

### Option 3: Create Standalone EXE
```bash
cd WC3ItemManager
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
# Output: bin\Release\net6.0-windows\win-x64\publish\WC3ItemManager.exe
```

## Database Connection

The application connects to:
- **Host**: 127.0.0.1
- **Port**: 5432
- **Database**: wc3_pots
- **User**: postgres
- **Password**: 009900

To change connection settings, edit `MainForm.cs` line 13:
```csharp
private string connectionString = "Host=127.0.0.1;Port=5432;Database=wc3_pots;Username=postgres;Password=009900";
```

## Usage Guide

### Main Window

**Search & Filters**
- Type in search box to filter by name/code/tooltip (instant filter)
- Select rarity/class filters to narrow results
- Use level range slider to filter by item level
- Check "Custom Items Only" to show only custom items

**Grid**
- Click column headers to sort
- Double-click row to edit item
- Select row and click Edit button

**Buttons**
- **➕ Add New**: Create a new item
- **✏️ Edit**: Edit selected item
- **🗑️ Delete**: Delete selected item (with confirmation)
- **🔄 Refresh**: Reload data from database
- **💾 Export to W3T**: Export items to .w3t file

### Edit/Add Item Dialog

**Basic Info Tab**
- Item Code: 4-character WC3 code (lowercase)
- Item Name: Display name (supports color codes)
- Base Item ID: For custom items (leave empty for original mods)
- Rarity, Class, Level, Costs, Charges, Stack
- Checkboxes: Droppable, Sellable, Pawnable, etc.

**Extended Info Tab**
- Tooltip (Basic): Short description
- Extended Tooltip (Ubertip): Detailed description
- Description: Lore text
- Hotkey: Single character hotkey

**WC3 Properties Tab**
- WC3 Classification: Permanent/Charged/Powerup/etc.
- Icon Path: Icon file path
- Model Path: 3D model file path
- Abilities: Comma-separated ability codes (e.g., "AIx2,AId1")

### Tips

1. **Color Codes in Names**: Use WC3 color codes like `|c0090EE90Green Text|r`
2. **Item Codes**: Must be exactly 4 lowercase characters
3. **Custom Items**: Set Base Item ID to create variants
4. **Abilities**: Enter raw WC3 ability codes separated by commas

## Troubleshooting

**Connection Error**
- Ensure PostgreSQL is running
- Verify database exists: `psql -U postgres -l`
- Check connection string matches your setup

**Build Errors**
- Restore NuGet packages: `dotnet restore`
- Update .NET SDK: `dotnet --version` (should be 6.0+)

**Missing Data**
- Run importer first: `python importers/wc3_w3t_importer_v2.py`
- Verify items table has data: `SELECT COUNT(*) FROM items;`

## Architecture

```
WC3ItemManager/
├── Program.cs              # Entry point
├── MainForm.cs            # Main window (grid, filters, search)
├── ItemEditForm.cs        # Edit/Add dialog (tabbed interface)
├── WC3ItemManager.csproj  # Project file (.NET 6)
└── README.md              # This file
```

## Features in Detail

### Filtering System
- **Instant search**: Filters as you type
- **Multiple filters**: All filters work together (AND logic)
- **Case-insensitive**: Search is case-insensitive
- **Smart matching**: Searches name, code, and tooltip

### Data Validation
- Item code must be 4 characters
- Item name required
- Numeric fields have min/max limits
- Auto-formatting (lowercase codes, uppercase hotkeys)

### Database Features
- Auto-creates rarity/class entries if missing
- Updates timestamps automatically
- Full WC3 field support (60+ fields)
- Preserves original_modifications JSON

## Future Enhancements

Planned features:
- [ ] Export selected items to .w3t
- [ ] Import from .w3t file
- [ ] Bulk edit operations
- [ ] Item duplication
- [ ] Search history
- [ ] Recent items list
- [ ] Item preview with icon display
- [ ] Ability code lookup/autocomplete
- [ ] Export to Excel/CSV
- [ ] Undo/Redo support

## Version History

**v1.0.0** (2026-03-11)
- Initial release
- Full CRUD operations
- Advanced filtering
- Three-tab edit interface
- PostgreSQL integration
- Support for all WC3 fields

## License

Part of the Path of the Shaman project.
