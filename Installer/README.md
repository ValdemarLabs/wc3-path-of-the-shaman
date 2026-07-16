# Path of the Shaman Installer

This folder contains the Windows installer project for player-facing Path of the Shaman releases.

The installer source is kept in git. The actual release payload is not kept in git.

## Payload Location

Put the latest files here before building:

- `Installer/assets/`
  - Optional PotS logo files used by the installer UI.
  - `pots-logo-small.png`: square logo for the top-right wizard logo area. Recommended at least `147x147`.
  - `pots-logo-wizard.png`: tall welcome/finished-page image. Recommended ratio `164:314`; use at least `240x459`.
  - Use both files if you want the logo visible across the normal pages and the welcome/finished pages.
- `Installer/assets/install-random/`
  - Optional `.png` or `.bmp` files looped as low-opacity backgrounds during the Installing page.
  - Recommended ratio is about `497:360`; use at least `596x432`.
  - The build supports up to 32 files in this folder.
  - Images are shown centered without stretching.
- `Installer/payload/map/`
  - Put the latest map `.zip` here.
  - The zip must contain one `.w3x` map file.
- `Installer/payload/local-files/`
  - Put the latest `Pots` folder here, for example `Installer/payload/local-files/Pots`.
  - The contents of that folder are copied to `Warcraft III\_retail_\Pots`.
- `Installer/payload/rebirth-mod/`
  - Put `9thRelease.rar` and `FixesLast2023.rar` here.
  - `9thRelease.rar` is unpacked to temp, then only the contents of its `9thRelease` folder are copied into `Warcraft III\_retail_`.
  - `FixesLast2023.rar` is unpacked to temp, then only the contents of `FixesLast2023\FixesLast2023\FixHighElfBarracksCentaurKhanWarlock` are copied into `Warcraft III\_retail_`.

`Installer/payload/` and `Installer/output/` are ignored by git. Only the folder placeholders are tracked.

## Updating a Release

1. Replace the payload files in `Installer/payload/`.
2. Edit `Installer/release-manifest.json`.
3. Bump the versions for the sections you are shipping.
4. Set `enabled` to `false` for sections not included in this installer build.
5. Run:

```powershell
cd H:\Pelit\PotS_JASS
powershell -ExecutionPolicy Bypass -File .\Installer\build-installer.ps1
```

The setup executable is written to `Installer/output/`.

## Installer Behavior

The installer has three sections:

- Map
  - Default target: `%USERPROFILE%\Documents\Warcraft III\Maps`
  - Source package: `Installer/payload/map/Path of the Shaman-202607130202.zip`
- PotS local files
  - Target: selected `Warcraft III\_retail_` folder plus `\Pots`
  - Source folder: `Installer/payload/local-files/Pots`
- Warcraft III Rebirth mod
  - Target: selected `Warcraft III\_retail_` folder
  - Source archives: `Installer/payload/rebirth-mod/9thRelease.rar`, then `Installer/payload/rebirth-mod/FixesLast2023.rar`

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
- Inno Setup 6.7 or newer installed
  - Inno Setup 6.7.3 is the recommended stable version.
  - Inno Setup 7 also works in principle, but the current public Inno 7 release is beta.

Player machine:

- Windows
- Warcraft III installed
- Administrator approval when installing into `Warcraft III\_retail_` under Program Files

Because the Rebirth mod and PotS local files may be installed under Program Files, the installer requests administrator rights. If Windows asks for a different administrator account, check the map folder page before continuing; the map should point to the actual player's `Documents\Warcraft III\Maps` folder.
