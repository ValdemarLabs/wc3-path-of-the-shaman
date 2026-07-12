# Path of the Shaman Installer

This folder contains the Windows installer project for player-facing Path of the Shaman releases.

The installer source is kept in git. The actual release payload is not kept in git.

## Payload Location

Put the latest files here before building:

- `Installer/payload/map/`
  - Put the latest `.w3x` map file here.
- `Installer/payload/local-files/`
  - Put the contents that must be installed to `Warcraft III\_retail_\Pots` here.
  - Do not include an extra top-level `Pots` folder unless that is intentionally part of the final path.
- `Installer/payload/rebirth-mod/`
  - Put the unpacked Warcraft III Rebirth mod files here.
  - These files are copied directly into `Warcraft III\_retail_`.

`Installer/payload/` and `Installer/output/` are ignored by git. Only the folder placeholders are tracked.

## Updating a Release

1. Replace the payload files in `Installer/payload/`.
2. Edit `Installer/release-manifest.json`.
3. Bump the versions for the sections you are shipping.
4. Set `enabled` to `false` for sections not included in this installer build.
5. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Installer\build-installer.ps1
```

The setup executable is written to `Installer/output/`.

## Installer Behavior

The installer has three sections:

- Map
  - Default target: `%USERPROFILE%\Documents\Warcraft III\Maps`
- PotS local files
  - Target: selected `Warcraft III\_retail_` folder plus `\Pots`
- Warcraft III Rebirth mod
  - Target: selected `Warcraft III\_retail_` folder

The installer records installed versions in:

```text
HKLM\Software\Path of the Shaman
```

When rerun, it shows each section as:

- `Install` when there is no installed version record.
- `Update` when the package version differs from the installed version.
- `Repair` when the package version matches the installed version.
- `Skip` when the section is not selected or not included in the package.

Repair/update both copy the package files again. Existing extra files in target folders are not deleted.

## Requirements

Build machine:

- Windows
- Inno Setup 6 installed

Player machine:

- Windows
- Warcraft III installed
- Administrator approval when installing into `Warcraft III\_retail_` under Program Files

Because the Rebirth mod and PotS local files may be installed under Program Files, the installer requests administrator rights. If Windows asks for a different administrator account, check the map folder page before continuing; the map should point to the actual player's `Documents\Warcraft III\Maps` folder.
