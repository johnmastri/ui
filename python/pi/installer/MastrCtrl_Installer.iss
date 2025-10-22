; MastrCtrl VST Plugin Installer Script
; Inno Setup 6.x
; 
; This installer:
;   1. Installs the VST3 plugin
;   2. Installs the UI files
;   3. Installs the USB driver for hardware controller
;   4. Creates shortcuts and documentation

#define MyAppName "MastrCtrl"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company Name"
#define MyAppURL "https://yourwebsite.com"

[Setup]
AppId={{YOUR-GUID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE.txt
OutputDir=output
OutputBaseFilename=MastrCtrl_Setup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; VST3 Plugin (adjust path to your actual VST3 file)
Source: "..\..\VSTMastrCtrl\build\Release\MastrCtrl.vst3\*"; DestDir: "{commoncf64}\VST3\MastrCtrl.vst3"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: Is64BitInstallMode

; UI Files (adjust path to your actual UI build)
Source: "..\..\ui\dist\*"; DestDir: "{app}\ui"; Flags: ignoreversion recursesubdirs createallsubdirs

; USB Driver
Source: "MastrCtrl_USB.inf"; DestDir: "{app}\driver"; Flags: ignoreversion

; Documentation
Source: "WINDOWS_USER_GUIDE.md"; DestDir: "{app}\docs"; Flags: ignoreversion
Source: "USB_GADGET_SETUP_GUIDE.md"; DestDir: "{app}\docs"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\ui\index.html"
Name: "{group}\User Guide"; Filename: "{app}\docs\WINDOWS_USER_GUIDE.md"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\ui\index.html"; Tasks: desktopicon

[Run]
; Install USB Driver silently
Filename: "pnputil.exe"; Parameters: "/add-driver ""{app}\driver\MastrCtrl_USB.inf"" /install"; Flags: runhidden; StatusMsg: "Installing USB driver..."

; Optionally show the user guide after installation
Filename: "{app}\docs\WINDOWS_USER_GUIDE.md"; Description: "View User Guide"; Flags: postinstall shellexec skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  
  // Check if running as administrator
  if not IsAdminInstallMode then
  begin
    MsgBox('This installer requires administrator privileges to install the USB driver.' + #13#10 + 
           'Please run the installer as Administrator.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Additional post-install tasks if needed
  end;
end;

[UninstallRun]
; Remove the driver on uninstall
Filename: "pnputil.exe"; Parameters: "/delete-driver MastrCtrl_USB.inf /uninstall /force"; Flags: runhidden; RunOnceId: "RemoveDriver"

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%nThis includes:%n• MastrCtrl VST3 Plugin%n• User Interface Files%n• USB Hardware Driver%n%nIt is recommended that you close all other applications before continuing.



