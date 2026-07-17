# Path of the Shaman Release Plan

## Purpose

Path of the Shaman releases should be tracked as release bundles, not only as a Git branch or merge commit.

A player release contains multiple versioned parts:

- PotS release version
- Warcraft III map build
- JASS/source code state
- PotS local files
- Warcraft III Rebirth mod payload
- Installer version

The Git `main` branch and Git tags identify the source code state. The release manifest and generated release lock identify the exact player-facing files included in an installer.

## Version Model

Use one top-level PotS release version for the player bundle, for example:

```text
0.1.0
```

Track each included section separately:

```text
PotS release:       0.1.0
Installer version:  0.1.0
Map build:          202607130202
Source tag:         v0.1.0
Source commit:      exact Git commit SHA
Local files:        0.1.0
Rebirth mod:        9thRelease+FixesLast2023
```

The installer version may stay equal to the PotS release version for normal releases. If only the installer UI or installer logic changes, the installer can receive a small patch version while the map/local/Rebirth payload versions stay unchanged.

## Release Manifest

`Installer/release-manifest.json` is the editable release input. It should describe what the installer intends to package.

Recommended structure:

```json
{
  "releaseVersion": "0.1.0",
  "installerVersion": "0.1.0",
  "source": {
    "gitTag": "v0.1.0",
    "gitCommit": ""
  },
  "map": {
    "enabled": true,
    "version": "202607130202",
    "source": "payload/map/Path of the Shaman-202607130202.zip",
    "sha256": ""
  },
  "localFiles": {
    "enabled": true,
    "version": "0.1.0",
    "source": "payload/local-files/Pots",
    "treeSha256": ""
  },
  "rebirthMod": {
    "enabled": true,
    "version": "9thRelease+FixesLast2023",
    "archives": [
      {
        "source": "payload/rebirth-mod/9thRelease.rar",
        "extractSubdir": "9thRelease",
        "sha256": ""
      },
      {
        "source": "payload/rebirth-mod/FixesLast2023.rar",
        "extractSubdir": "FixesLast2023/FixesLast2023/FixHighElfBarracksCentaurKhanWarlock",
        "sha256": ""
      }
    ]
  }
}
```

The editable manifest may leave hash fields blank before building. The build/release process should generate a locked release file with actual hashes.

## Release Lock

Each built installer should have a generated release lock file in `Installer/output`, for example:

```text
Installer/output/PathOfTheShamanSetup-0.1.0.release.json
```

This file should record the exact files packaged into the installer:

- release version
- installer version
- Git tag
- Git commit SHA
- map archive path and SHA256
- detected `.w3x` filename inside the map zip
- local files folder version and tree hash
- Rebirth archive paths, extract subfolders, and SHA256 hashes
- final installer EXE filename and SHA256

The generated release lock is the best source of truth for what a released installer contains.

## Release Workflow

1. Finish and validate the map/source changes on `dev`.
2. Export/package the map into `Installer/payload/map`.
3. Update `Installer/release-manifest.json`.
4. Place or update PotS local files under `Installer/payload/local-files/Pots`.
5. Place or update Rebirth archives under `Installer/payload/rebirth-mod`.
6. Build the installer.
7. Generate the release lock file with hashes.
8. Test the installer on a clean Warcraft III install path when possible.
9. Merge `dev` into `main`.
10. Tag the exact release commit on `main`, for example `v0.1.0`.
11. Attach the installer EXE and release lock JSON to the external release/distribution location.

## Git Rules

Use Git for source and release metadata:

- JASS libraries
- installer scripts
- manifest template/input
- changelog
- release plan

Do not commit large binary payloads unless there is a clear reason:

- map zip payloads
- local audio files
- Rebirth archives
- built installer EXEs

These payload files should stay ignored and should be represented in releases by filenames, versions, and hashes.

## Naming

Recommended Git tag:

```text
v0.1.0
```

Recommended installer filename:

```text
PathOfTheShamanSetup-0.1.0.exe
```

Recommended release lock filename:

```text
PathOfTheShamanSetup-0.1.0.release.json
```

Recommended map archive naming:

```text
Path of the Shaman-YYYYMMDDHHMM.zip
```

Example:

```text
Path of the Shaman-202607130202.zip
```

## Meaning of `main`

`main` should mean:

```text
This source code state was used for a released or release-candidate PotS bundle.
```

`main` alone does not prove what binary payloads were released. The release tag plus release lock file prove that.

## Meaning of a Release

A release is complete only when all of these exist:

- Git tag on the release commit
- changelog entry
- installer EXE
- release lock JSON with hashes
- known map/local-files/Rebirth versions

The merge commit message can describe the release, but it should not be the only release record.
