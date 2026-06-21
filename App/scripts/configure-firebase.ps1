param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectId
)

$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot\..

dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure `
  --project=$ProjectId `
  --platforms=android `
  --android-package-name=com.handyapp.handy_app `
  --yes

Pop-Location

Write-Host "Firebase configured. Run: flutter run --dart-define-from-file=config/backend.json"
