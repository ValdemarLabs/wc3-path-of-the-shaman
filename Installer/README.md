# Path of the Shaman Installer

This folder contains the Windows installer project for player-facing Path of the Shaman releases.

The installer source is kept in git. The actual release payload is not kept in git.

## Planned DE external-asset architecture

> **Work in progress:** This section defines the intended installer architecture. The current installer behavior documented later in this file still uses the older payload layout and does not yet implement manifest-based component removal.

The installer will own and manage three separately selectable release components:

1. **PotS map**: the `.w3x` installed under the player's Warcraft III maps directory.
2. **WC3 Rebirth DE**: the validated Rebirth DE compatibility package installed as loose files under Warcraft III's `_retail_` directory. The current converted-model staging candidate is `_WC3Rebirth\Assets\PotS_DE\WC3Rebirth_DE_Full\`.
3. **PotS external assets**: selected models, textures, sounds, and supporting files moved out of the map and installed as loose files under `_retail_`.

PotS external assets must keep the exact relative path used by the map import. For example:

```text
Map import path:
war3mapImported\Units\Nazgrek.mdx

Installed external path:
<Warcraft III>\_retail_\war3mapImported\Units\Nazgrek.mdx
```

Externalizing an asset must not require changing its map reference merely because it moved out of the map. The staged installer payload must reproduce the complete import-relative directory tree beneath `_retail_`, including the exact filename. Dependencies such as textures, portrait models, attachment models, sounds, and FaceFX files must be included at their own resolved paths.

Many existing PotS imports are expected to move into this external layout later. Before an imported SD model is externalized, it still needs dependency inventory, SD-to-HD/DE conversion where applicable, and in-game validation. Moving assets out of the map and converting them for DE are related but separate release gates.

### Required maintenance experience

The finished installer must provide a user-friendly maintenance flow after installation. It must detect the current installation and offer clear actions for:

- installing, updating, or repairing all supported components;
- adding or removing WC3 Rebirth DE without forcing removal of the PotS map or PotS external assets;
- adding or removing PotS external assets without broadly deleting other `_retail_` content;
- removing the map while retaining selected external components;
- removing the complete PotS installation;
- previewing and confirming which components and files will be installed or removed.

Each component must have its own version and installed-file manifest. Installation, update, repair, and removal must use those manifests instead of directory-wide deletion. Removal may delete only files owned by the selected component and may prune only directories left empty by that operation. It must never delete Warcraft III's `_retail_` directory, shared game data, or files owned by unrelated mods.

If a package path collides with a pre-existing file not owned by the same PotS component, the installer must either back up and later restore that file or stop and present a clear collision choice. Uninstall and partial removal must not silently destroy files that existed before PotS was installed.

The component manifests should record at least:

- component identifier and version;
- destination path relative to the selected Warcraft III or maps root;
- installed file size and checksum;
- whether an older file was backed up and where that backup is owned;
- enough state to distinguish install, update, repair, partial removal, and complete removal.

Until this architecture is implemented and tested, the current installer and manual Rebirth DE copy workflow remain development-only paths rather than the final player-facing DE installation flow.

## Current Payload Location

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
  - This is the current legacy Rebirth payload path, not the final WC3 Rebirth DE component design described above.

`Installer/payload/` and `Installer/output/` are ignored by git. Only the folder placeholders are tracked.

## Updating the Current Installer Release

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

## Current Installer Behavior

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
