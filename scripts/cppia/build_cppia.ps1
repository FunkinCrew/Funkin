# Compiles a mod's scripted classes to a single .cppia the game can load.
# Usage: ./build_cppia.ps1 [--sdk <sdk-dir>] [--target <platform>] [--config <debug|release>] <game-root> <script-dir> <output.cppia> [Class ...]
# 	target defaults to windows and config to release, they only pick which SDK folder is used by default

# SDK here contains `export_classes.info and cppia.hxml`, and you also need the game checked out (as seen by 'game root)
# That refers to the games source code, not a compiled version of the game.

# A full example of it might be:
# ./build_cppia.ps1 --sdk ./funkin-cppia-sdk ./Funkin ./my-mod/scripts/cppia-src/ MyMod.cppia

# You are also able (as seen by 'Class ...') to write specific classes you want to compile.
# IE: [MyModule YourModule OurModule]

param(
	[Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

$Sdk = $null
$Target = 'windows'
$Config = 'release'
$KeepResources = $false
$positional = @()
for ($i = 0; $i -lt $Arguments.Count; $i++) {
	if ($Arguments[$i] -in @('--keep-resources', '-keep-resources', '-KeepResources')) {
		$KeepResources = $true
	}
	elseif ($Arguments[$i] -in @('--sdk', '-sdk', '-Sdk')) {
		if ($i + 1 -ge $Arguments.Count) { Write-Error "--sdk needs a directory after it." }
		$Sdk = $Arguments[$i + 1]
		$i++
	}
	elseif ($Arguments[$i] -in @('--target', '-target', '-Target')) {
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

if ($positional.Count -lt 3) {
	Write-Error "Usage: build_cppia.ps1 [--sdk <sdk-dir>] [--keep-resources] <game-root> <script-dir> <output.cppia> [Class ...]"
}

$GameRoot = $positional[0]
$ScriptDir = $positional[1]
$Output = $positional[2]
$Classes = @()
if ($positional.Count -gt 3) { $Classes = $positional[3..($positional.Count - 1)] }

if (-not (Test-Path (Join-Path $GameRoot 'project.hxp'))) {
	Write-Error "$GameRoot does not look like the game checkout, no project.hxp there."
}
$root = (Resolve-Path $GameRoot).Path.TrimEnd('\', '/')

if (-not $Sdk) {
	$default = Join-Path $root "export\$Config\$Target\cppia-sdk"
	if (Test-Path (Join-Path $default 'cppia.hxml')) { $Sdk = $default }
}

if (-not (Test-Path $ScriptDir -PathType Container)) {
	Write-Error "No such script directory: $ScriptDir"
}

$generated = Join-Path ([System.IO.Path]::GetTempPath()) ("cppia-" + [System.Guid]::NewGuid().ToString('N') + ".hxml")

try {
	if ($Sdk) {
		$sdkAbs = (Resolve-Path $Sdk).Path
		$hostClasses = Join-Path $sdkAbs 'export_classes.info'

		if (-not (Test-Path $hostClasses)) {
			Write-Error "SDK at $sdkAbs has no export_classes.info"
		}

		$kept = Get-Content (Join-Path $sdkAbs 'cppia.hxml') | ForEach-Object {
			$_ -replace [regex]::Escape('${FUNKIN_ROOT}'), $root
		}
		Write-Host "Using SDK $sdkAbs"
	}
	else {
		$hostClasses = Join-Path $root 'export_classes.info'
		if (-not (Test-Path $hostClasses)) {
			Write-Error "No SDK found at $root\export\$Config\$Target\cppia-sdk, and no $hostClasses to fall back on. Build the game once for this target and config, or pass --sdk <dir>."
		}

		Push-Location $root
		try { $lines = haxelib run lime display $Target "-$Config" } finally { Pop-Location }
		$kept = $lines | Where-Object {
			($_ -notmatch '^-main ') -and
			($_ -notmatch '^-cpp ') -and
			($_ -notmatch '^--no-output$') -and
			($_ -notmatch '^-D scriptable$') -and
			($_ -notmatch '^--macro keep\(')
		}
		Write-Host "No SDK given, deriving arguments from $root"
	}

	if (-not $Classes -or $Classes.Count -eq 0) {
		$base = (Resolve-Path $ScriptDir).Path.TrimEnd('\', '/')
		$Classes = Get-ChildItem -Path $base -Recurse -Filter '*.hx' | ForEach-Object {
			$rel = $_.FullName.Substring($base.Length).TrimStart('\', '/')
			($rel -replace '\.hx$', '') -replace '[\\/]', '.'
		} | Sort-Object
	}

	if (-not $Classes -or $Classes.Count -eq 0) {
		Write-Error "No .hx files found under $ScriptDir"
	}

	$kept += "-cp $((Resolve-Path $ScriptDir).Path.TrimEnd('\', '/'))"

	$kept += "cpp.cppia.HostClasses"

	$kept += $Classes

	$classList = ($Classes | ForEach-Object { "'$_'" }) -join ','
	$kept += "--macro funkin.util.macro.CppiaManifestMacro.build([$classList])"

	if (-not $KeepResources) {
		$kept += "--macro funkin.util.macro.CppiaStripMacro.stripResources()"
	}

	if (-not [System.IO.Path]::IsPathRooted($Output)) {
		$Output = Join-Path (Get-Location).Path $Output
	}

	$kept += "-D dll_import=$hostClasses"
	$kept += "--cppia $Output"

	[System.IO.File]::WriteAllLines($generated, $kept, (New-Object System.Text.UTF8Encoding($false)))

	Write-Host "Building $Output from $ScriptDir"
	Write-Host "  $($Classes.Count) class(es): $($Classes -join ', ')"

	Push-Location $root
	try { haxe $generated } finally { Pop-Location }
	if ($LASTEXITCODE -ne 0) { Write-Error "haxe failed with exit code $LASTEXITCODE" }

	if (-not (Test-Path $Output)) { Write-Error "haxe reported success but produced no $Output" }

	Write-Host "Wrote $Output ($((Get-Item $Output).Length) bytes)"
}
finally {
	Remove-Item $generated -ErrorAction SilentlyContinue
}
