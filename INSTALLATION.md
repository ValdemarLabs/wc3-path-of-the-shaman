# WC3 - Path of the Shaman
## INSTALLATION
*Last updated: 2026-08-07*

> ### Installation notes:
> These are player-facing installation instructions for Path of the Shaman (PotS).
> The PotS installer is the recommended installation and update method.
> These instructions may change as the installer and game requirements are updated.

## Table of Contents

- [Requirements](#requirements)
- [What the installer installs](#what-the-installer-installs)
- [Installing Path of the Shaman](#installing-path-of-the-shaman)
  - [1. Run the installer](#1-run-the-installer)
  - [2. Select the installation type](#2-select-the-installation-type)
  - [3. Check the Warcraft III folders](#3-check-the-warcraft-iii-folders)
  - [4. Review the installation summary](#4-review-the-installation-summary)
  - [5. Install](#5-install)
- [Launching the map](#launching-the-map)
- [Updating Path of the Shaman](#updating-path-of-the-shaman)
- [Troubleshooting](#troubleshooting)
  - [Map does not appear in Warcraft III](#map-does-not-appear-in-warcraft-iii)
  - [Missing sounds, music, or other PotS assets](#missing-sounds-music-or-other-pots-assets)
  - [Installer cannot find the Warcraft III installation](#installer-cannot-find-the-warcraft-iii-installation)
  - [Rebirth mod is missing or does not work correctly](#rebirth-mod-is-missing-or-does-not-work-correctly)
  - [PotS local files still do not load](#pots-local-files-still-do-not-load)
  - [Problems continue after repair](#problems-continue-after-repair)


### Requirements

- Windows
- Warcraft III Reforged installed
- Latest supported Warcraft III retail patch
- Administrator approval for installing PotS files into the Warcraft III installation directory

> **Important:** PotS is intended for the current Warcraft III Reforged retail version. Older game versions, such as patch 1.36, are not supported by the current map.


### What the installer installs

A normal PotS installation consists of three parts:

- **Path of the Shaman map**
  - Installed into your Warcraft III Maps folder.
  - Default location:
    `%USERPROFILE%\Documents\Warcraft III\Maps`

- **PotS local files**
  - Contains external assets used by the map, such as sounds and music.
  - Installed into:
    `Warcraft III\_retail_\Pots`

- **Warcraft III Rebirth mod**
  - Installed into the Warcraft III `_retail_` directory.
  - The current PotS installer uses the required Rebirth **9th Release + FixesLast2023** package.

If you use the **Full installation**, you do not need to separately download or manually extract the PotS local files or the Rebirth archives.


### Installing Path of the Shaman

#### 1. Run the installer

Run the PotS setup executable:

`PathOfTheShamanSetup-<version>.exe`

Windows may request administrator approval because some files are installed into the Warcraft III `_retail_` directory.

It is recommended to close Warcraft III before installing or updating PotS.


#### 2. Select the installation type

The installer provides the following installation types:

- **Full installation**
  - Installs the map
  - Installs the PotS local files
  - Installs the required Warcraft III Rebirth mod
  - Recommended for a normal first-time installation

- **Map and PotS local files**
  - Installs the map and required PotS local assets
  - Does not install Rebirth
  - Intended for cases where the correct Rebirth version is already installed

- **Custom installation**
  - Allows the installer components available in the current package to be reviewed or selected
  - The map and PotS local files are core components of the current installer


#### 3. Check the Warcraft III folders

The installer attempts to detect the Warcraft III installation automatically.

Verify the following locations before continuing:

**Warcraft III `_retail_` folder**

This must point to the actual `_retail_` directory of your Warcraft III installation, for example:

`C:\Program Files (x86)\Warcraft III\_retail_`

The exact Warcraft III installation location may be different on your computer.

**Warcraft III Maps folder**

The default location is:

`%USERPROFILE%\Documents\Warcraft III\Maps`

The map itself is installed here.

> **Important:** If Windows asks you to enter credentials for a different administrator account, verify the Maps folder carefully before continuing. It should point to the **player's** Warcraft III Maps folder, not another Windows user's Documents folder.


#### 4. Review the installation summary

Before installation, PotS displays the installed and package versions for each available component.

The installer may show one of the following actions:

- **Install** - the component has not previously been recorded as installed
- **Update** - the package contains a different version than the installed version
- **Repair** - the same version is already installed and its files will be copied again
- **Skip** - the component is not selected or is not included in the current installer package

Review the selected folders and component actions before continuing.


#### 5. Install

Continue through the installer.

Depending on the selected components, the installer will:

- extract the PotS map into the Warcraft III Maps folder
- copy the `Pots` local asset folder into `Warcraft III\_retail_\Pots`
- install the bundled Warcraft III Rebirth files into `Warcraft III\_retail_`

When the installer reports that installation has completed, PotS is ready to be launched.


### Launching the map

1. Start Warcraft III.
2. Open **Single Player**.
3. Open **Custom Games**.
4. Locate **Path of the Shaman**.
5. Start the map.


### Updating Path of the Shaman

Use the newest PotS installer when updating the map or its external files.

Run the installer normally and review the **Installation summary**. The installer compares the package versions against the versions recorded from the previous installation.

- A newer or otherwise different package version is shown as **Update**.
- The same package version is shown as **Repair**.
- A component not previously recorded is shown as **Install**.

Both **Update** and **Repair** copy the packaged files again.

> **Note:** Repairing or updating does not delete unrelated or additional files already present in the target folders. This is particularly relevant if different Rebirth versions or other files have previously been installed manually.


### Troubleshooting

#### Map does not appear in Warcraft III

Verify that the map was installed into the correct Warcraft III Maps folder:

`%USERPROFILE%\Documents\Warcraft III\Maps`

If your Documents folder has been moved or redirected, use the actual Warcraft III Maps directory used by your Windows account.

You can rerun the PotS installer and verify the Maps folder on the **Select Warcraft III folders** page.


#### Missing sounds, music, or other PotS assets

Verify that the following folder exists inside the active Warcraft III retail installation:

`Warcraft III\_retail_\Pots`

Do not rename the `Pots` folder or move its contents to another Warcraft III installation such as `_ptr_`.

Also verify that Warcraft III is updated to the latest supported retail patch.


#### Installer cannot find the Warcraft III installation

Select the actual Warcraft III `_retail_` folder manually.

The selected directory must exist when installing the PotS local files or Rebirth mod.

A typical installation may be located under:

`C:\Program Files (x86)\Warcraft III\_retail_`

but your installation path may differ.


#### Rebirth mod is missing or does not work correctly

For the normal installation, rerun the PotS installer and use **Full installation** so that the Rebirth version bundled for PotS is installed.

The current PotS package uses Warcraft III Rebirth **9th Release + FixesLast2023**.

If another Rebirth version or other mod files have previously been installed manually, be aware that PotS **Repair** and **Update** operations copy required files but do not delete additional existing files.


#### PotS local files still do not load

Current Warcraft III Reforged versions may not require the old **Allow Local Files** registry setting. If local external assets still fail to load, it can be checked as a troubleshooting step:

1. Press **Windows + R**.
2. Enter `regedit.exe`.
3. Navigate to:
   `HKEY_CURRENT_USER\Software\Blizzard Entertainment\Warcraft III`
4. Check for a **DWORD (32-bit) Value** named:
   `Allow Local Files`
5. Set its value to:
   `1`
6. Restart Warcraft III.

Editing the Windows Registry should only be done when necessary. The PotS installer itself does not currently configure this setting.


#### Problems continue after repair

- Confirm that Warcraft III is using the latest supported retail patch.
- Confirm that PotS was installed into the active Warcraft III `_retail_` directory.
- Confirm that the map is in the correct Windows user's Warcraft III Maps folder.
- Run the installer again and use **Repair** for the installed components.
- If you have manually installed other Rebirth versions or Warcraft III mods, conflicting leftover files may require separate cleanup.
