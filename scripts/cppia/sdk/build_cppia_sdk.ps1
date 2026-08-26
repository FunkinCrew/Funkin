# Usage: ./build_cppia_sdk.ps1 [--target <platform>] [--config <debug|release>] <game-root> [output-dir]
# 	target defaults to windows
# 	config defaults to release
# 	output-dir defaults to <game-root>/export/<config>/<target>/cppia-sdk

# This creates the 'export_classes.info' file for CPPIA exports. Typically, you do not need to run this script. haha

param(
	[Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
)

$Target = 'windows'
$Config = 'release'
$positional = @()
for ($i = 0; $i -lt $Arguments.Count; $i++) {
	if ($Arguments[$i] -in @('--target', '-target', '-Target')) {
		if ($i + 1 -ge $Arguments.Count) { Write-Error "--target needs a platform after it." }
		$Target = $Arguments[$i + 1]
		$i++
	}
	elseif ($Arguments[$i] -in @('--config', '-config', '-Config')) {
		if ($i + 1 -ge $Arguments.Count) { Write-Error "--config needs debug or release after it." }
		$Config = $Arguments[$i + 1]
		$i++
	}
	else {
		$positional += $Arguments[$i]
	}
}

if ($positional.Count -lt 1) {
	Write-Error "Usage: build_cppia_sdk.ps1 [--target <platform>] [--config <debug|release>] <game-root> [output-dir]"
}

$GameRoot = $positional[0]
$OutDir = if ($positional.Count -gt 1) { $positional[1] } else { $null }

$ErrorActionPreference = 'Stop'

if (-not (Test-Path (Join-Path $GameRoot 'project.hxp'))) {
	Write-Error "$GameRoot does not look like the game checkout, no project.hxp there."
}
$root = (Resolve-Path $GameRoot).Path.TrimEnd('\', '/')
if (-not $OutDir) { $OutDir = Join-Path $root "export\$Config\$Target\cppia-sdk" }

$hostClasses = Join-Path $root 'export_classes.info'
if (-not (Test-Path $hostClasses)) {
	Write-Error "Missing $hostClasses. Build the game once with FEATURE_CPPIA enabled first, -D scriptable writes it."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$rootFwd = $root.TrimEnd('\', '/') -replace '\\', '/'

Push-Location $root
try { $lines = haxelib run lime display $Target "-$Config" } finally { Pop-Location }

$kept = $lines | Where-Object {
	($_ -notmatch '^-main ') -and
	($_ -notmatch '^-cpp ') -and
	($_ -notmatch '^--no-output$') -and
	($_ -notmatch '^-D scriptable$') -and
	($_ -notmatch '^--macro keep\(')
} | ForEach-Object {
	$line = $_ -replace '\\', '/'
	$line = $line -replace ('(?i)' + [regex]::Escape($rootFwd + '/')), ''
	$line -replace ('(?i)' + [regex]::Escape($rootFwd)), '.'
}

$outside = '^-D [A-Za-z0-9_.]+=([A-Za-z]:/|/)'
$dropped = @($kept | Where-Object { $_ -match $outside })
$kept = @($kept | Where-Object { $_ -notmatch $outside })

foreach ($line in $dropped) {
	Write-Host "	dropped $line"
}

[System.IO.File]::WriteAllLines((Join-Path $OutDir 'cppia.hxml'), $kept, (New-Object System.Text.UTF8Encoding($false)))

Copy-Item $hostClasses (Join-Path $OutDir 'export_classes.info') -Force
Remove-Item $hostClasses -Force

$classCount = (Select-String -Path (Join-Path $OutDir 'export_classes.info') -Pattern '^(class|interface|enum) ').Count
Write-Host "Wrote $Target $Config cppia SDK to $OutDir"
Write-Host "	cppia.hxml	$($kept.Count) lines"
Write-Host "	export_classes.info	$classCount classes"
