# WC3 Manager

A Windows Forms application for managing Path of the Shaman content in the PotS PostgreSQL database. The application currently covers items, loot tables, unit/destructible drops, gathering nodes, and quest design.

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

### Quest Designer

- Create and maintain quest givers, quests, turn-in relationships, and prerequisite graphs.
- Author QuestMaster-compatible objectives and the live reward configuration.
- Build ordered dialog/event sequences with line, delay, facing, look-at, fade, and safe action-hook steps.
- Maintain source-reconciled voiceline references and explicit World Editor dependencies.
- Preview Details, Description, Objectives, and Rewards using the same information model as `UI/QuestUI.j`.
- Export only changed managed or hybrid qXXX JASS libraries with JSON snapshots, validation reports, and World Editor manifests.
- Mark complex existing libraries as External so the exporter never overwrites them.
- Synchronize existing `QuestGivers` and `GenericQuests` JASS into source-owned external rows, including standard qXXX quests and vendor fetch/kill/supply registrations.
- Distinguish synchronized source, managed, hybrid, and manual external records with ownership banners and guarded editing actions. Synchronized rows expose only uniquely mapped JASS literals; custom/shared/computed fields remain gray with a repository-only explanation.
- Review field-level source patches before writing, reject overlapping repository/manager edits, preserve unmapped code byte-for-byte, create a temporary recovery copy, validate the patched structure, and synchronize the result automatically.
- Add standard external quests only inside explicit `WC3M-BEGIN/END QUEST CONSTANTS` and parameterized `WC3M-BEGIN/END QUESTS` regions reviewed in the repository.
- Browse the repository-style Quest Library with folder overviews and giver/quest search (`Ctrl+F`).

## Prerequisites

- .NET 10.0.300 SDK (pinned by the repository `global.json`)
- Visual Studio 2022 (recommended) or VS Code
- PostgreSQL database (wc3_pots)

## SDK Selection

This repository currently pins the .NET SDK with `global.json` to keep builds stable even if newer SDKs are installed side by side.

- Current pinned SDK: `10.0.300`
- App target framework: `net8.0-windows`
- Reason: the app now builds on a modern SDK while staying on the .NET 8 LTS desktop runtime for lower behavioral risk than a direct jump to `net10.0-windows`.

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
# Output: bin\Release\net8.0-windows\win-x64\publish\WC3ItemManager.exe
```

The executable and project keep the legacy `WC3ItemManager` technical name for launcher and solution compatibility. The product and UI are branded **WC3 Manager**.

## Quest Designer Database Setup

Apply the idempotent quest migration to a non-production database before opening **Quests > Open Quest Designer**:

```powershell
psql -U postgres -d wc3_pots -f .\WC3_Database\migrations\run_all_quest_migrations.sql
```

The migration adds normalized tables for quest givers, quests, objectives, rewards, prerequisites, sequences, sequence steps, voiceline references, and World Editor dependencies. Run the migration twice when validating a disposable database to confirm idempotency.

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

**Quests menu**
- **Open Quest Designer**: Edit giver/quest data, relationships, objectives, rewards, dialog sequences, preview, voicelines, and World Editor dependencies.
- **Sync existing JASS** (Quest Designer toolbar): Scan both `QuestsAndDialogs/QuestGivers` and `QuestsAndDialogs/GenericQuests`, then create or refresh guarded external source projections. Managed/hybrid rows are never overwritten.
- **Export Changed qXXX Quest Libraries**: Generate timestamped JASS scaffolds plus validation, JSON, and World Editor follow-up artifacts only when the generated library's SHA-256 fingerprint differs from its last successful export.

The navigation tree mirrors the repository hierarchy (`QuestGivers` folders and `GenericQuests`) and keeps database-authored managed/hybrid records under a separate root. Edit uniquely mapped synchronized literals through a reviewed source patch, edit all custom logic directly in the repository `.j` source, and sync afterward. Edit managed libraries in WC3 Manager and export afterward; generated output is not reverse-imported.

For a command-line synchronization against the configured database:

```powershell
dotnet .\WC3_Database\WC3ItemManager\bin\Debug\net8.0-windows\WC3ItemManager.dll --sync-quest-sources .\QuestsAndDialogs
```

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
- Check SDK pinning: `dotnet --version` (should resolve to `10.0.300` in this repo)

**Missing Data**
- Run importer first: `python importers/wc3_w3t_importer_v2.py`
- Verify items table has data: `SELECT COUNT(*) FROM items;`

## Architecture

```
WC3ItemManager/
├── Program.cs              # Entry point
├── MainForm.cs            # Main window (grid, filters, search)
├── ItemEditForm.cs        # Edit/Add dialog (tabbed interface)
├── WC3ItemManager.csproj  # Project file (.NET 8)
└── README.md              # This file
```

The Quest Designer is kept in a bounded module: `QuestDesignerForm.cs`, `QuestLogPreviewControl.cs`, `Models/QuestDesignerModels.cs`, `Repositories/QuestDesignerRepository.cs`, `Importers/QuestSourceSynchronizer.cs`, and `Exporters/QuestLibraryExporter.cs`. This keeps the existing item grid and feature forms independent.

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

**v1.1.0** (2026-08-28)
- Renamed the user-facing application to WC3 Manager.
- Added the database-backed Quest Designer.
- Added quest relationships, dialog/event sequences, voiceline references, and QuestUI preview.
- Added validated managed/hybrid qXXX exports and World Editor dependency manifests.

**v1.0.0** (2026-03-11)
- Initial release
- Full CRUD operations
- Advanced filtering
- Three-tab edit interface
- PostgreSQL integration
- Support for all WC3 fields

## License

Part of the Path of the Shaman project.
