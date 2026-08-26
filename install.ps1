$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$mainScript = Join-Path $repoRoot 'main.ahk'
$startupFolder = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupFolder 'Window Manager.lnk'

if (-not (Test-Path -LiteralPath $mainScript -PathType Leaf)) {
    throw "Could not find main.ahk in $repoRoot."
}

winget install --id AutoHotkey.AutoHotkey --exact --silent --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    throw "AutoHotkey installation failed with exit code $LASTEXITCODE."
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $mainScript
$shortcut.WorkingDirectory = $repoRoot
$shortcut.Description = 'Start the Window Manager AutoHotkey script'
$shortcut.Save()

Start-Process -FilePath $mainScript

Write-Host 'AutoHotkey is installed, Window Manager is running, and it will start automatically on startup.'