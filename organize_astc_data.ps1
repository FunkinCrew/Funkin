# Organizes astc-compression-data alphabetically because i hate it when it's not organized -zack

$InputFile = "./astc-compression-data.json"
$OutputFile = "./astc-compression-data.json"

if (-not (Test-Path $InputFile)) {
    Write-Host "❌ File $InputFile not found"
    exit 1
}

if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    Write-Host "jq is not installed. Download from https://jqlang.github.io/jq/ or install via:"
    Write-Host "  winget install jqlang.jq"
    exit 1
}

jq '.
  | .custom = ( .custom | sort_by(.asset) )
  | .excludes = ( .excludes | sort )
' $InputFile | Out-File -Encoding utf8 $OutputFile

Write-Host "✅ Sorted JSON written to $OutputFile WOOHOOO !!"
