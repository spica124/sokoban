param([switch]$Build)
$ErrorActionPreference = 'Stop'
$projectDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$godot = 'C:\Users\limji\Godot\Godot.exe'
$qaDirectory = Join-Path $projectDirectory 'docs/art'
$saveFile = Join-Path $env:APPDATA 'Godot/app_userdata/Sokoban/save.json'
$saveBefore = if (Test-Path -LiteralPath $saveFile) { (Get-FileHash -LiteralPath $saveFile -Algorithm SHA256).Hash } else { 'MISSING' }
$saveBefore | Set-Content -LiteralPath (Join-Path $qaDirectory 'qa-farm-save-before.sha256')
function Run-Godot([string]$Name, [string[]]$Arguments) {
    $outFile = Join-Path $qaDirectory ('qa-farm-' + $Name + '.log')
    $errFile = Join-Path $qaDirectory ('qa-farm-' + $Name + '-errors.log')
    $process = Start-Process -FilePath $godot -ArgumentList $Arguments -WorkingDirectory $projectDirectory -WindowStyle Hidden -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { Get-Content -LiteralPath $errFile; throw "Godot failed: $Name ($($process.ExitCode))" }
    $errors = Get-Content -LiteralPath $errFile -Raw
    if ($errors -match 'SCRIPT ERROR|Parse Error|ERROR:') { throw "Godot errors in $errFile" }
    Write-Output "PASS: $Name"
}
Run-Godot 'import' @('--headless','--path','.','--editor','--quit')
$captures = @(
    @('menu', -1, 'down', 'none', 'res://docs/screenshots/assets_menu.png'),
    @('stage1', 0, 'down', 'none', 'res://assets/store/screenshots/stage1.png'),
    @('stage9', 8, 'right', 'none', 'res://assets/store/screenshots/stage9.png'),
    @('stage24', 23, 'up', 'none', 'res://assets/store/screenshots/stage24.png'),
    @('left', 0, 'left', 'none', 'res://docs/screenshots/capybara_left.png'),
    @('settings', -1, 'down', 'settings', 'res://docs/screenshots/farm_settings.png'),
    @('pause', 8, 'right', 'pause', 'res://docs/screenshots/farm_pause.png'),
    @('tutorial', 0, 'down', 'tutorial', 'res://docs/screenshots/farm_tutorial.png'),
    @('clear', 8, 'right', 'clear', 'res://docs/screenshots/farm_clear.png')
)
foreach ($shot in $captures) {
    $arguments = @('--path','.','--script','res://tools/capture_assets.gd','--',('--asset-output='+$shot[4]),'--asset-tier=2',('--asset-facing='+$shot[2]),('--asset-overlay='+$shot[3]))
    if ($shot[1] -ge 0) { $arguments += '--asset-level=' + $shot[1] }
    Run-Godot $shot[0] $arguments
}
$saveAfter = if (Test-Path -LiteralPath $saveFile) { (Get-FileHash -LiteralPath $saveFile -Algorithm SHA256).Hash } else { 'MISSING' }
if ($saveAfter -ne $saveBefore) { throw 'Capture changed saved progress or settings.' }
Write-Output 'PASS: saved progress and settings unchanged'
& (Join-Path $PSScriptRoot 'check_art.ps1')
if ($Build) {
    Run-Godot 'windows-build' @('--headless','--path','.','--export-release','"Windows Desktop"','build/Sokoban.exe')
    Run-Godot 'android-build' @('--headless','--path','.','--export-debug','Android','build/Sokoban.apk')
}

