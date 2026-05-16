param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotCandidates = @(
    "E:\GameDev\Godot_v4.6.2-stable_win64_console.exe",
    "E:\GameDev\Godot_v4.6.2-stable_win64.exe"
)
$GodotExe = $GodotCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$EnvRoot = Join-Path $ProjectRoot ".codex_godot_env"
$LocalAppData = Join-Path $EnvRoot "LocalAppData"
$AppData = Join-Path $EnvRoot "AppDataRoaming"
$Temp = Join-Path $EnvRoot "Temp"

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    throw "Godot executable not found. Checked: $($GodotCandidates -join ', ')"
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
