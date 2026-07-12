#define AppName "Path of the Shaman"
#define AppPublisher "Path of the Shaman"
#define AppRegistryKey "Software\Path of the Shaman"
#include "release-version.generated.iss"

[Setup]
AppId={{8B8E5A8D-8E10-42A5-B013-5880134D0B2B}
AppName={#AppName}
AppVersion={#InstallerVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\Path of the Shaman
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=PathOfTheShamanSetup-{#InstallerVersion}
Compression=lzma2/ultra64
SolidCompression=yes
ArchiveExtraction=full
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayName={#AppName}
SetupLogging=yes
VersionInfoVersion={#InstallerFileVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} installer
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#InstallerVersion}

[Types]
Name: "full"; Description: "Full installation"
Name: "compact"; Description: "Map and PotS local files"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
#if IncludeMap
Name: "map"; Description: "Map - package version {#MapVersion}"; Types: full compact custom; Flags: fixed
#endif
#if IncludeLocalFiles
Name: "localfiles"; Description: "PotS local files - package version {#LocalFilesVersion}"; Types: full compact custom; Flags: fixed
#endif
#if IncludeRebirthMod
Name: "rebirth"; Description: "Warcraft III Rebirth mod - package version {#RebirthModVersion}"; Types: full custom
#endif

[Dirs]
#if IncludeMap
Name: "{code:GetMapInstallDir}"; Components: map
#endif
#if IncludeLocalFiles
Name: "{code:GetLocalFilesInstallDir}"; Components: localfiles
#endif
#if IncludeRebirthMod
Name: "{code:GetRetailInstallDir}"; Components: rebirth
#endif

[Files]
#if IncludeMap
Source: "{#MapArchiveSource}"; DestName: "{#MapArchiveFileName}"; Flags: dontcopy nocompression; Components: map
#endif
#if IncludeLocalFiles
Source: "{#LocalFilesSource}\*"; DestDir: "{code:GetLocalFilesInstallDir}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".gitkeep,Thumbs.db,.DS_Store"; Components: localfiles
#endif
#if IncludeRebirthMod
#if IncludeRebirthArchive1
Source: "{#RebirthArchive1Source}"; DestName: "{#RebirthArchive1FileName}"; Flags: dontcopy nocompression; Components: rebirth
#endif
#if IncludeRebirthArchive2
Source: "{#RebirthArchive2Source}"; DestName: "{#RebirthArchive2FileName}"; Flags: dontcopy nocompression; Components: rebirth
#endif
#if IncludeRebirthArchive3
Source: "{#RebirthArchive3Source}"; DestName: "{#RebirthArchive3FileName}"; Flags: dontcopy nocompression; Components: rebirth
#endif
#if IncludeRebirthArchive4
Source: "{#RebirthArchive4Source}"; DestName: "{#RebirthArchive4FileName}"; Flags: dontcopy nocompression; Components: rebirth
#endif
#endif

[Registry]
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "InstallerVersion"; ValueData: "{#InstallerVersion}"; Flags: uninsdeletevalue
#if IncludeMap
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "MapVersion"; ValueData: "{#MapVersion}"; Components: map; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "MapPath"; ValueData: "{code:GetMapInstallDir}\{#MapInstalledFileName}"; Components: map; Flags: uninsdeletevalue
#endif
#if IncludeLocalFiles
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "LocalFilesVersion"; ValueData: "{#LocalFilesVersion}"; Components: localfiles; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "LocalFilesPath"; ValueData: "{code:GetLocalFilesInstallDir}"; Components: localfiles; Flags: uninsdeletevalue
#endif
#if IncludeRebirthMod
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "RebirthModVersion"; ValueData: "{#RebirthModVersion}"; Components: rebirth; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#AppRegistryKey}"; ValueType: string; ValueName: "RetailPath"; ValueData: "{code:GetRetailInstallDir}"; Components: rebirth; Flags: uninsdeletevalue
#endif

[Code]
var
  TargetPathPage: TInputDirWizardPage;
  VersionPage: TWizardPage;
  VersionIntroLabel: TNewStaticText;
#if IncludeMap
  MapVersionLabel: TNewStaticText;
#endif
#if IncludeLocalFiles
  LocalFilesVersionLabel: TNewStaticText;
#endif
#if IncludeRebirthMod
  RebirthModVersionLabel: TNewStaticText;
#endif

function NormalizeRetailDir(Path: string): string;
var
  CleanPath: string;
begin
  CleanPath := RemoveBackslashUnlessRoot(Path);

  if CompareText(ExtractFileName(CleanPath), '_retail_') = 0 then
    Result := CleanPath
  else
    Result := AddBackslash(CleanPath) + '_retail_';
end;

function TryRegistryRetailPath(RootKey: HKEY; Subkey: string; ValueName: string; var RetailPath: string): Boolean;
var
  Candidate: string;
begin
  Result := False;

  if RegQueryStringValue(RootKey, Subkey, ValueName, Candidate) then
  begin
    Candidate := NormalizeRetailDir(Candidate);
    if DirExists(Candidate) then
    begin
      RetailPath := Candidate;
      Result := True;
    end;
  end;
end;

function DetectRetailDir: string;
var
  Candidate: string;
begin
  if TryRegistryRetailPath(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\Blizzard Entertainment\Warcraft III', 'InstallPath', Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  if TryRegistryRetailPath(HKEY_CURRENT_USER, 'Software\Blizzard Entertainment\Warcraft III', 'InstallPath', Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  if IsWin64 then
  begin
    Candidate := ExpandConstant('{commonpf64}\Warcraft III\_retail_');
    if DirExists(Candidate) then
    begin
      Result := Candidate;
      Exit;
    end;
  end;

  Candidate := ExpandConstant('{commonpf32}\Warcraft III\_retail_');
  if DirExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Result := ExpandConstant('{commonpf32}\Warcraft III\_retail_');
end;

function GetRetailInstallDir(Param: string): string;
begin
  Result := NormalizeRetailDir(TargetPathPage.Values[0]);
end;

function GetMapInstallDir(Param: string): string;
begin
  Result := RemoveBackslashUnlessRoot(TargetPathPage.Values[1]);
end;

function GetLocalFilesInstallDir(Param: string): string;
begin
  Result := AddBackslash(GetRetailInstallDir('')) + 'Pots';
end;

function ReadInstalledVersion(ValueName: string): string;
var
  Value: string;
begin
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, '{#AppRegistryKey}', ValueName, Value) then
    Result := Value
  else
    Result := '';
end;

function VersionDisplay(Version: string): string;
begin
  if Version = '' then
    Result := 'Not installed'
  else
    Result := Version;
end;

function SectionAction(ComponentName: string; InstalledVersion: string; PackageVersion: string): string;
begin
  if not WizardIsComponentSelected(ComponentName) then
    Result := 'Skip'
  else if InstalledVersion = '' then
    Result := 'Install'
  else if CompareText(InstalledVersion, PackageVersion) = 0 then
    Result := 'Repair'
  else
    Result := 'Update';
end;

procedure ConfigureLabel(LabelControl: TNewStaticText; Top: Integer; Height: Integer);
begin
  LabelControl.Left := 0;
  LabelControl.Top := Top;
  LabelControl.Width := VersionPage.SurfaceWidth;
  LabelControl.Height := Height;
  LabelControl.AutoSize := False;
  LabelControl.WordWrap := True;
end;

procedure SetVersionLabel(LabelControl: TNewStaticText; DisplayName: string; ComponentName: string; InstalledVersion: string; PackageVersion: string);
begin
  LabelControl.Caption :=
    DisplayName + #13#10 +
    'Installed: ' + VersionDisplay(InstalledVersion) + #13#10 +
    'Package: ' + PackageVersion + #13#10 +
    'Action: ' + SectionAction(ComponentName, InstalledVersion, PackageVersion);
end;

procedure RefreshVersionPage;
begin
#if IncludeMap
  SetVersionLabel(MapVersionLabel, 'Map', 'map', ReadInstalledVersion('MapVersion'), '{#MapVersion}');
#endif
#if IncludeLocalFiles
  SetVersionLabel(LocalFilesVersionLabel, 'PotS local files', 'localfiles', ReadInstalledVersion('LocalFilesVersion'), '{#LocalFilesVersion}');
#endif
#if IncludeRebirthMod
  SetVersionLabel(RebirthModVersionLabel, 'Warcraft III Rebirth mod', 'rebirth', ReadInstalledVersion('RebirthModVersion'), '{#RebirthModVersion}');
#endif
end;

procedure ExtractBundledArchive(ArchiveFileName: string; DestDir: string; DisplayName: string; FullPaths: Boolean);
var
  ArchivePath: string;
begin
  if not ForceDirectories(DestDir) then
    RaiseException('Could not create target folder: ' + DestDir);

  WizardForm.StatusLabel.Caption := 'Extracting ' + DisplayName + '...';
  Log('Extracting ' + DisplayName + ' to ' + DestDir);

  ExtractTemporaryFile(ArchiveFileName);
  ArchivePath := AddBackslash(ExpandConstant('{tmp}')) + ArchiveFileName;
  ExtractArchive(ArchivePath, DestDir, '', FullPaths, nil);
end;

procedure InitializeWizard;
var
  NextTop: Integer;
begin
  TargetPathPage :=
    CreateInputDirPage(
      wpSelectComponents,
      'Select Warcraft III folders',
      'Choose the target folders for Path of the Shaman.',
      'The map goes to Documents. PotS local files and Rebirth mod go under Warcraft III _retail_.',
      False,
      ''
    );

  TargetPathPage.Add('Warcraft III _retail_ folder:');
  TargetPathPage.Values[0] := DetectRetailDir;
  TargetPathPage.Add('Warcraft III Maps folder:');
  TargetPathPage.Values[1] := ExpandConstant('{userdocs}\Warcraft III\Maps');

  VersionPage :=
    CreateCustomPage(
      TargetPathPage.ID,
      'Installation summary',
      'Review installed versions and package versions.'
    );

  VersionIntroLabel := TNewStaticText.Create(VersionPage);
  VersionIntroLabel.Parent := VersionPage.Surface;
  ConfigureLabel(VersionIntroLabel, 0, 42);
  VersionIntroLabel.Caption :=
    'Same-version sections are repaired by copying files again. Different package versions are installed as updates.';

  NextTop := 52;

#if IncludeMap
  MapVersionLabel := TNewStaticText.Create(VersionPage);
  MapVersionLabel.Parent := VersionPage.Surface;
  ConfigureLabel(MapVersionLabel, NextTop, 76);
  NextTop := NextTop + 86;
#endif

#if IncludeLocalFiles
  LocalFilesVersionLabel := TNewStaticText.Create(VersionPage);
  LocalFilesVersionLabel.Parent := VersionPage.Surface;
  ConfigureLabel(LocalFilesVersionLabel, NextTop, 76);
  NextTop := NextTop + 86;
#endif

#if IncludeRebirthMod
  RebirthModVersionLabel := TNewStaticText.Create(VersionPage);
  RebirthModVersionLabel.Parent := VersionPage.Surface;
  ConfigureLabel(RebirthModVersionLabel, NextTop, 76);
#endif
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = VersionPage.ID then
    RefreshVersionPage;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
#if IncludeMap
    if WizardIsComponentSelected('map') then
      ExtractBundledArchive('{#MapArchiveFileName}', GetMapInstallDir(''), 'map archive', False);
#endif

#if IncludeRebirthMod
    if WizardIsComponentSelected('rebirth') then
    begin
#if IncludeRebirthArchive1
      ExtractBundledArchive('{#RebirthArchive1FileName}', GetRetailInstallDir(''), '{#RebirthArchive1FileName}', True);
#endif
#if IncludeRebirthArchive2
      ExtractBundledArchive('{#RebirthArchive2FileName}', GetRetailInstallDir(''), '{#RebirthArchive2FileName}', True);
#endif
#if IncludeRebirthArchive3
      ExtractBundledArchive('{#RebirthArchive3FileName}', GetRetailInstallDir(''), '{#RebirthArchive3FileName}', True);
#endif
#if IncludeRebirthArchive4
      ExtractBundledArchive('{#RebirthArchive4FileName}', GetRetailInstallDir(''), '{#RebirthArchive4FileName}', True);
#endif
    end;
#endif
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = TargetPathPage.ID then
  begin
    TargetPathPage.Values[0] := NormalizeRetailDir(TargetPathPage.Values[0]);
    TargetPathPage.Values[1] := RemoveBackslashUnlessRoot(TargetPathPage.Values[1]);

    if (WizardIsComponentSelected('localfiles') or WizardIsComponentSelected('rebirth')) and
       (not DirExists(TargetPathPage.Values[0])) then
    begin
      MsgBox('Select an existing Warcraft III _retail_ folder.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    if TargetPathPage.Values[1] = '' then
    begin
      MsgBox('Select a Warcraft III Maps folder.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;
end;
