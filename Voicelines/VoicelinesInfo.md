# PotS Voiceline Workflow

## Source Of Truth

JASS voiceline libraries are the runtime source of truth. The old Excel
workbook is kept as legacy draft/reference material and can still provide draft
text, quest notes, and completion hints, but `Done` values in Excel are not
authoritative.

The scanner treats audio files in the master folder as authoritative for whether
a line has already been generated:

```text
H:\Pelit\WC3_PotS_Files\001 OFFICIAL FILES\Pots\Sound\Voicelines
```

Generated FishAudio files must always go to the review/temp folder first:

```text
tools/temp/fishaudio-review
```

Do not generate directly into the master folder. Listen/check files in the temp
folder first, then manually copy accepted audio into the master folder.

Repo-side `Voicelines/<SpeakerFolder>/` directories are reference-only. Do not
treat them as scanner input, generation output, or canonical audio storage. The
external master folder and `tools/temp/fishaudio-review` are the only audio
roots used by this workflow.

## JASS Structure

`Voicelines.j` is the base helper library and requires `ExSound`. Speaker
libraries require `Voicelines`; the base library does not import every speaker.

Example speaker library declaration:

```jass
library VoicelinesAradion initializer Init requires Voicelines
```

Speaker libraries should define constants in this shape:

```jass
constant string VL_ARADION_0001_KEY = "Aradion_0001"
constant string VL_ARADION_0001_TEXT = "Line text here."
```

Use comment blocks to group related quest/event lines. Consumers should require
only the speaker libraries they use and pass the constants to dialog/bark APIs.

## Scanner

Run the scan from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines.ps1 -Mode Scan
```

The scan writes:

```text
tools/temp/voicelines/voicelines-scan.csv
```

This CSV is disposable generated output. Do not edit it by hand and do not
treat it as a voiceline source file. Re-run the scanner whenever you want a
fresh report.

The report flags:

- `present_in_master`
- `pending_review`
- `missing_audio`
- `excel_only`
- `excel_only_blank_text`
- `jass_only`
- `duplicate_key`
- `duplicate_text_variants`
- `orphan_audio`
- `folder_mismatch`

`excel_only` rows are legacy draft/reference rows from the old workbook that
still have text but do not have a matching JASS constant. They are not runtime
lines and the generator will not create audio for them unless the line is first
migrated into a `Voicelines_*.j` library. `excel_only_blank_text` rows are old
workbook filename placeholders without draft text.

Folder mismatches are report-only. Do not auto-rename master folders or audio
files based on scan output.

## Excel Draft Import

Use the importer only when intentionally migrating remaining workbook draft text
into JASS constants:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines-import-excel.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines-import-excel.ps1 -Apply
```

The importer preserves existing JASS keys/text and only adds workbook rows whose
keys are still missing from `Voicelines_*.j`. It also canonicalizes old
`Peon_####` workbook names to `OrcPeon_####` because the master audio files use
the `OrcPeon` prefix.

## FishAudio Generation

Dry-run before generating:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines.ps1 -Mode Generate -DryRun -MaxCount 1
```

Generate missing audio only after FishAudio credentials/reference IDs are set:

```powershell
$env:FISH_API_KEY = "<api-key>"
$env:FISH_REFERENCE_ID_ARADION = "<reference-id>"
powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines.ps1 -Mode Generate -Speaker Aradion -MaxCount 1
```

Generated files are written to:

```text
tools/temp/fishaudio-review/<SpeakerFolder>/<FileName>.mp3
```

The generator always skips files already present in the master folder. It skips
files already pending in the review folder unless `-Force` is used. Rows with
duplicate text variants are scan/report items and are skipped by generation
until the text ambiguity is resolved.

## Speaker Folder Mapping

The tooling keeps explicit speaker/folder mapping because disk folders may use
names such as `Orc Grunt` or `Orc Peon` while JASS keys use compact prefixes.
Update `tools/voicelines.ps1` when a new speaker prefix needs a non-obvious
folder name.

## Migration Notes

Initial active speaker constants have been split for Aradion, Valeria, and
Nazgrek. AI-heavy bark and companion reply text should live in dedicated
`Voicelines_*.j` helper libraries while AI behavior logic and profile
registration remain in the current AI files.
