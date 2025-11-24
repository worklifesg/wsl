param(
  [string]$BucketName,
  [string]$Version = "latest",
  [string]$DistroName = "MyDevDistro",
  [string]$InstallPath = "C:\\WSL"
)

$Key = "custom-wsl-${Version}.tar.gz"
$LocalImage = "$env:TEMP\custom-wsl-${Version}.tar.gz"
$DistroPath = Join-Path $InstallPath $DistroName

Write-Host "Downloading $Key from S3 bucket $BucketName..."
aws s3 cp "s3://$BucketName/$Key" $LocalImage

if (-not (Test-Path $LocalImage)) {
    Write-Error "Failed to download image."
    exit 1
}

Write-Host "Importing into WSL ($DistroName)..."
if (wsl --list --quiet | Select-String -Pattern $DistroName) {
    Write-Warning "Distro $DistroName already exists. Unregistering..."
    wsl --unregister $DistroName
}

New-Item -ItemType Directory -Path $DistroPath -Force | Out-Null
wsl --import $DistroName $DistroPath $LocalImage --version 2

Write-Host "Setting systemd=true in /etc/wsl.conf"
wsl -d $DistroName -u root -- bash -lc "mkdir -p /etc && echo -e '[boot]\nsystemd=true' >> /etc/wsl.conf"

Write-Host "Shutdown WSL to apply systemd"
wsl --shutdown

Write-Host "Done. Start distro with: wsl -d $DistroName"