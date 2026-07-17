#define AppName "Path of the Shaman"
#define AppPublisher "Path of the Shaman"
#define AppRegistryKey "Software\Path of the Shaman"
#define PotsLogoWizardFile "assets\pots-logo-wizard.png"
#ifexist "assets\pots-logo-wizard.png"
#define IncludeFinishedBackImage 1
#else
#define IncludeFinishedBackImage 0
#endif
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
#if IncludeInstallRandomImages
WizardBackColor=white
#else
#if IncludeFinishedBackImage
WizardBackColor=white
#endif
#endif
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
#if IncludeInstallRandomImages
#if IncludeInstallRandomImage1
Source: "{#InstallRandomImage1Source}"; DestName: "{#InstallRandomImage1FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage2
Source: "{#InstallRandomImage2Source}"; DestName: "{#InstallRandomImage2FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage3
Source: "{#InstallRandomImage3Source}"; DestName: "{#InstallRandomImage3FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage4
Source: "{#InstallRandomImage4Source}"; DestName: "{#InstallRandomImage4FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage5
Source: "{#InstallRandomImage5Source}"; DestName: "{#InstallRandomImage5FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage6
Source: "{#InstallRandomImage6Source}"; DestName: "{#InstallRandomImage6FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage7
Source: "{#InstallRandomImage7Source}"; DestName: "{#InstallRandomImage7FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage8
Source: "{#InstallRandomImage8Source}"; DestName: "{#InstallRandomImage8FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage9
Source: "{#InstallRandomImage9Source}"; DestName: "{#InstallRandomImage9FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage10
Source: "{#InstallRandomImage10Source}"; DestName: "{#InstallRandomImage10FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage11
Source: "{#InstallRandomImage11Source}"; DestName: "{#InstallRandomImage11FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage12
Source: "{#InstallRandomImage12Source}"; DestName: "{#InstallRandomImage12FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage13
Source: "{#InstallRandomImage13Source}"; DestName: "{#InstallRandomImage13FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage14
Source: "{#InstallRandomImage14Source}"; DestName: "{#InstallRandomImage14FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage15
Source: "{#InstallRandomImage15Source}"; DestName: "{#InstallRandomImage15FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage16
Source: "{#InstallRandomImage16Source}"; DestName: "{#InstallRandomImage16FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage17
Source: "{#InstallRandomImage17Source}"; DestName: "{#InstallRandomImage17FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage18
Source: "{#InstallRandomImage18Source}"; DestName: "{#InstallRandomImage18FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage19
Source: "{#InstallRandomImage19Source}"; DestName: "{#InstallRandomImage19FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage20
Source: "{#InstallRandomImage20Source}"; DestName: "{#InstallRandomImage20FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage21
Source: "{#InstallRandomImage21Source}"; DestName: "{#InstallRandomImage21FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage22
Source: "{#InstallRandomImage22Source}"; DestName: "{#InstallRandomImage22FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage23
Source: "{#InstallRandomImage23Source}"; DestName: "{#InstallRandomImage23FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage24
Source: "{#InstallRandomImage24Source}"; DestName: "{#InstallRandomImage24FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage25
Source: "{#InstallRandomImage25Source}"; DestName: "{#InstallRandomImage25FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage26
Source: "{#InstallRandomImage26Source}"; DestName: "{#InstallRandomImage26FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage27
Source: "{#InstallRandomImage27Source}"; DestName: "{#InstallRandomImage27FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage28
Source: "{#InstallRandomImage28Source}"; DestName: "{#InstallRandomImage28FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage29
Source: "{#InstallRandomImage29Source}"; DestName: "{#InstallRandomImage29FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage30
Source: "{#InstallRandomImage30Source}"; DestName: "{#InstallRandomImage30FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage31
Source: "{#InstallRandomImage31Source}"; DestName: "{#InstallRandomImage31FileName}"; Flags: dontcopy nocompression
#endif
#if IncludeInstallRandomImage32
Source: "{#InstallRandomImage32Source}"; DestName: "{#InstallRandomImage32FileName}"; Flags: dontcopy nocompression
#endif
#endif
#if IncludeFinishedBackImage
Source: "{#PotsLogoWizardFile}"; DestName: "pots-logo-wizard.png"; Flags: dontcopy nocompression
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
#if IncludeInstallRandomImages
  InstallSlideActive: Boolean;
  CurrentInstallImageIndex: Integer;
  InstallSlideTimerID: Integer;
  InstallSlideTimerCallback: Integer;
#endif

#if IncludeInstallRandomImages
function SetTimer(hWnd: Integer; nIDEvent: Integer; uElapse: Integer; lpTimerFunc: Integer): Integer;
  external 'SetTimer@user32.dll stdcall';
function KillTimer(hWnd: Integer; uIDEvent: Integer): Integer;
  external 'KillTimer@user32.dll stdcall';
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

function TryRegistryRetailPath(RootKey: Integer; Subkey: string; ValueName: string; var RetailPath: string): Boolean;
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

procedure CopyDirectoryContents(SourceDir: string; DestDir: string);
var
  FindRec: TFindRec;
  SourcePath: string;
  DestPath: string;
begin
  if not DirExists(SourceDir) then
    RaiseException('Required extracted folder was not found: ' + SourceDir);

  if not ForceDirectories(DestDir) then
    RaiseException('Could not create target folder: ' + DestDir);

  if FindFirst(AddBackslash(SourceDir) + '*', FindRec) then
  begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
        begin
          SourcePath := AddBackslash(SourceDir) + FindRec.Name;
          DestPath := AddBackslash(DestDir) + FindRec.Name;

          if DirExists(SourcePath) then
          begin
            CopyDirectoryContents(SourcePath, DestPath);
          end
          else
          begin
            if not ForceDirectories(ExtractFileDir(DestPath)) then
              RaiseException('Could not create target folder: ' + ExtractFileDir(DestPath));

            if not CopyFile(SourcePath, DestPath, False) then
              RaiseException('Could not copy file: ' + SourcePath + ' to ' + DestPath);
          end;
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;
end;

procedure ExtractArchiveSubdirToRetail(ArchiveFileName: string; ArchiveSubdir: string; DisplayName: string);
var
  ArchivePath: string;
  ExtractRoot: string;
  SourceRoot: string;
begin
  ExtractRoot := AddBackslash(ExpandConstant('{tmp}')) + ArchiveFileName + '-extract';

  if not ForceDirectories(ExtractRoot) then
    RaiseException('Could not create temp extraction folder: ' + ExtractRoot);

  WizardForm.StatusLabel.Caption := 'Extracting ' + DisplayName + '...';
  Log('Extracting ' + DisplayName + ' to temp folder ' + ExtractRoot);

  ExtractTemporaryFile(ArchiveFileName);
  ArchivePath := AddBackslash(ExpandConstant('{tmp}')) + ArchiveFileName;
  ExtractArchive(ArchivePath, ExtractRoot, '', True, nil);

  SourceRoot := ExtractRoot;
  if ArchiveSubdir <> '' then
    SourceRoot := AddBackslash(ExtractRoot) + ArchiveSubdir;

  WizardForm.StatusLabel.Caption := 'Installing ' + DisplayName + '...';
  Log('Copying ' + SourceRoot + ' to ' + GetRetailInstallDir(''));
  CopyDirectoryContents(SourceRoot, GetRetailInstallDir(''));
end;

#if IncludeInstallRandomImages
function GetInstallImageFileName(ImageIndex: Integer): string;
begin
  case ImageIndex of
#if IncludeInstallRandomImage1
    0: Result := '{#InstallRandomImage1FileName}';
#endif
#if IncludeInstallRandomImage2
    1: Result := '{#InstallRandomImage2FileName}';
#endif
#if IncludeInstallRandomImage3
    2: Result := '{#InstallRandomImage3FileName}';
#endif
#if IncludeInstallRandomImage4
    3: Result := '{#InstallRandomImage4FileName}';
#endif
#if IncludeInstallRandomImage5
    4: Result := '{#InstallRandomImage5FileName}';
#endif
#if IncludeInstallRandomImage6
    5: Result := '{#InstallRandomImage6FileName}';
#endif
#if IncludeInstallRandomImage7
    6: Result := '{#InstallRandomImage7FileName}';
#endif
#if IncludeInstallRandomImage8
    7: Result := '{#InstallRandomImage8FileName}';
#endif
#if IncludeInstallRandomImage9
    8: Result := '{#InstallRandomImage9FileName}';
#endif
#if IncludeInstallRandomImage10
    9: Result := '{#InstallRandomImage10FileName}';
#endif
#if IncludeInstallRandomImage11
    10: Result := '{#InstallRandomImage11FileName}';
#endif
#if IncludeInstallRandomImage12
    11: Result := '{#InstallRandomImage12FileName}';
#endif
#if IncludeInstallRandomImage13
    12: Result := '{#InstallRandomImage13FileName}';
#endif
#if IncludeInstallRandomImage14
    13: Result := '{#InstallRandomImage14FileName}';
#endif
#if IncludeInstallRandomImage15
    14: Result := '{#InstallRandomImage15FileName}';
#endif
#if IncludeInstallRandomImage16
    15: Result := '{#InstallRandomImage16FileName}';
#endif
#if IncludeInstallRandomImage17
    16: Result := '{#InstallRandomImage17FileName}';
#endif
#if IncludeInstallRandomImage18
    17: Result := '{#InstallRandomImage18FileName}';
#endif
#if IncludeInstallRandomImage19
    18: Result := '{#InstallRandomImage19FileName}';
#endif
#if IncludeInstallRandomImage20
    19: Result := '{#InstallRandomImage20FileName}';
#endif
#if IncludeInstallRandomImage21
    20: Result := '{#InstallRandomImage21FileName}';
#endif
#if IncludeInstallRandomImage22
    21: Result := '{#InstallRandomImage22FileName}';
#endif
#if IncludeInstallRandomImage23
    22: Result := '{#InstallRandomImage23FileName}';
#endif
#if IncludeInstallRandomImage24
    23: Result := '{#InstallRandomImage24FileName}';
#endif
#if IncludeInstallRandomImage25
    24: Result := '{#InstallRandomImage25FileName}';
#endif
#if IncludeInstallRandomImage26
    25: Result := '{#InstallRandomImage26FileName}';
#endif
#if IncludeInstallRandomImage27
    26: Result := '{#InstallRandomImage27FileName}';
#endif
#if IncludeInstallRandomImage28
    27: Result := '{#InstallRandomImage28FileName}';
#endif
#if IncludeInstallRandomImage29
    28: Result := '{#InstallRandomImage29FileName}';
#endif
#if IncludeInstallRandomImage30
    29: Result := '{#InstallRandomImage30FileName}';
#endif
#if IncludeInstallRandomImage31
    30: Result := '{#InstallRandomImage31FileName}';
#endif
#if IncludeInstallRandomImage32
    31: Result := '{#InstallRandomImage32FileName}';
#endif
  else
    Result := '{#InstallRandomImage1FileName}';
  end;
end;

procedure SetInstallBackImageByIndex(ImageIndex: Integer);
var
  BackImages: TArrayOfGraphic;
  ImageFileName: string;
  ImagePath: string;
begin
  try
    ImageFileName := GetInstallImageFileName(ImageIndex);
    ExtractTemporaryFile(ImageFileName);
    ImagePath := AddBackslash(ExpandConstant('{tmp}')) + ImageFileName;

    SetLength(BackImages, 1);
    if CompareText(ExtractFileExt(ImageFileName), '.bmp') = 0 then
      BackImages[0] := TBitmap.Create
    else
      BackImages[0] := TPngImage.Create;

    try
      BackImages[0].LoadFromFile(ImagePath);
      WizardSetBackImage(BackImages, False, True, 110);
      CurrentInstallImageIndex := ImageIndex;
      Log('Install progress background image: ' + ImageFileName);
    finally
      BackImages[0].Free;
    end;
  except
    Log('Could not set random install background image: ' + GetExceptionMessage);
  end;
end;

function GetNextInstallImageIndex: Integer;
var
  NextImageIndex: Integer;
begin
#if InstallRandomImageCount > 1
  NextImageIndex := Random({#InstallRandomImageCount});
  if NextImageIndex = CurrentInstallImageIndex then
    NextImageIndex := (NextImageIndex + 1) mod {#InstallRandomImageCount};
  Result := NextImageIndex;
#else
  Result := 0;
#endif
end;

procedure ShowNextInstallBackImage;
begin
  if InstallSlideActive then
    SetInstallBackImageByIndex(GetNextInstallImageIndex);
end;

procedure InstallSlideTimerProc(hWnd: Integer; Msg: Integer; TimerID: Integer; SysTime: Integer);
begin
  ShowNextInstallBackImage;
end;

procedure StartInstallSlideShow;
begin
  InstallSlideActive := True;
  CurrentInstallImageIndex := -1;
  ShowNextInstallBackImage;

  if ({#InstallRandomImageCount} > 1) and (InstallSlideTimerID = 0) and (InstallSlideTimerCallback <> 0) then
    InstallSlideTimerID := SetTimer(0, 0, 5000, InstallSlideTimerCallback);
end;

procedure StopInstallSlideShow;
begin
  InstallSlideActive := False;

  if InstallSlideTimerID <> 0 then
  begin
    KillTimer(0, InstallSlideTimerID);
    InstallSlideTimerID := 0;
  end;
end;
#endif

#if IncludeFinishedBackImage
procedure SetFinishedBackImage;
var
  BackImages: TArrayOfGraphic;
  ImagePath: string;
begin
  try
    ExtractTemporaryFile('pots-logo-wizard.png');
    ImagePath := AddBackslash(ExpandConstant('{tmp}')) + 'pots-logo-wizard.png';

    SetLength(BackImages, 1);
    BackImages[0] := TPngImage.Create;
    try
      BackImages[0].LoadFromFile(ImagePath);
      WizardSetBackImage(BackImages, False, True, 165);
      Log('Finished page background image: pots-logo-wizard.png');
    finally
      BackImages[0].Free;
    end;
  except
    Log('Could not set finished page background image: ' + GetExceptionMessage);
  end;
end;
#endif

procedure ConfigureFinishedPageLayout;
var
  ContentLeft: Integer;
  ContentWidth: Integer;
begin
  ContentLeft := ScaleX(36);
  ContentWidth := WizardForm.FinishedLabel.Parent.Width - (ContentLeft * 2);

  WizardForm.WizardBitmapImage.Visible := False;
  WizardForm.WizardBitmapImage2.Visible := False;
  WizardForm.WizardBitmapImage2.Width := 0;

  WizardForm.FinishedHeadingLabel.Left := ContentLeft;
  WizardForm.FinishedHeadingLabel.Width := ContentWidth;
  WizardForm.FinishedLabel.Left := ContentLeft;
  WizardForm.FinishedLabel.Width := ContentWidth;
end;

#if IncludeInstallRandomImages
procedure ClearInstallBackImage;
begin
  try
    WizardSetBackImage([], False, True, 0);
  except
    Log('Could not clear install background image: ' + GetExceptionMessage);
  end;
end;
#endif

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

#if IncludeInstallRandomImages
  InstallSlideActive := False;
  CurrentInstallImageIndex := -1;
  InstallSlideTimerID := 0;
  InstallSlideTimerCallback := CreateCallback(@InstallSlideTimerProc);
#endif

  WizardForm.WizardSmallBitmapImage.Visible := False;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = VersionPage.ID then
    RefreshVersionPage;

  if CurPageID = wpFinished then
    ConfigureFinishedPageLayout;

#if IncludeFinishedBackImage
  if CurPageID = wpFinished then
    SetFinishedBackImage;
#endif
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
#if IncludeInstallRandomImages
    StartInstallSlideShow;
#endif

#if IncludeMap
    if WizardIsComponentSelected('map') then
      ExtractBundledArchive('{#MapArchiveFileName}', GetMapInstallDir(''), 'map archive', False);
#endif

#if IncludeRebirthMod
    if WizardIsComponentSelected('rebirth') then
    begin
#if IncludeRebirthArchive1
      ExtractArchiveSubdirToRetail('{#RebirthArchive1FileName}', '{#RebirthArchive1ExtractSubdir}', '{#RebirthArchive1FileName}');
#endif
#if IncludeRebirthArchive2
      ExtractArchiveSubdirToRetail('{#RebirthArchive2FileName}', '{#RebirthArchive2ExtractSubdir}', '{#RebirthArchive2FileName}');
#endif
#if IncludeRebirthArchive3
      ExtractArchiveSubdirToRetail('{#RebirthArchive3FileName}', '{#RebirthArchive3ExtractSubdir}', '{#RebirthArchive3FileName}');
#endif
#if IncludeRebirthArchive4
      ExtractArchiveSubdirToRetail('{#RebirthArchive4FileName}', '{#RebirthArchive4ExtractSubdir}', '{#RebirthArchive4FileName}');
#endif
    end;
#endif
  end;
#if IncludeInstallRandomImages
  if CurStep = ssPostInstall then
  begin
    StopInstallSlideShow;
#if IncludeFinishedBackImage
    SetFinishedBackImage;
#else
    ClearInstallBackImage;
#endif
  end;
#endif
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
