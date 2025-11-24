param(
  [string]$LocalTar = "C:\\Downloads\\custom-wsl.tar.gz",
  [string]$DistroName = "MyDevDistro"
)

New-Item -ItemType Directory -Path "C:\\WSL\\$DistroName" -Force | Out-Null
wsl --import $DistroName "C:\\WSL\\$DistroName" $LocalTar --version 2
Write-Host "Imported $DistroName. Run: wsl -d $DistroName"