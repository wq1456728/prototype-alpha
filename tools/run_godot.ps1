param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotExe = "E:\GameDev\Godot_v4.6.2-stable_win64_console.exe"
$EnvRoot = Join-Path $ProjectRoot ".codex_godot_env"
$LocalAppData = Join-Path $EnvRoot "LocalAppData"
$AppData = Join-Path $EnvRoot "AppDataRoaming"
$Temp = Join-Path $EnvRoot "Temp"

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot console executable not found: $GodotExe"
}

New-Item -ItemType Directory -Force -Path $LocalAppData, $AppData, $Temp | Out-Null

$env:LOCALAPPDATA = $LocalAppData
$env:APPDATA = $AppData
$env:TEMP = $Temp
$env:TMP = $Temp

if ($GodotArgs.Count -eq 0) {
    $GodotArgs = @("--version")
}

& $GodotExe @GodotArgs
exit $LASTEXITCODE
