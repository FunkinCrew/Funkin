cd ../..

# ask for version
$version = Read-Host "Enter version (Will display on the website)"

# regenerate XML files?
$regenerateXml = Read-Host "Regenerate XML files? (y/n)"

if ($regenerateXml -eq "y") {
    Write-Host "Regenerating XML files..."
    echo "Generating docs for version $version..."

    lime build linux -xml -cpp --no-output -Ddoc-gen
    lime build windows -xml -cpp --no-output -Ddoc-gen

    copy export\release\windows\types.xml docs\dox\Windows.xml
    copy export\release\linux\types.xml docs\dox\Linux.xml
} else {
    Write-Host "Skipping XML regeneration..."
}

# Then run dox
haxelib run dox `
  -i .\docs\dox\ `
  -o docs/dox/output `
  --title "Funkin'" `
  -theme "docs/dox/funkin-theme" `
  -D version "$version" `
  -D source-path "https://github.com/FunkinCrew/Funkin/tree/main/source" `
  -D website "https://funkin.me/" `
  -D description "Friday Night Funkin' API Reference" `
  -in "funkin" `
  -in "openfl" `
  -in "lime" `
  -in "flixel" `
  -ex "funkin.ui.debug.*" `
  -ex "funkin.macro.*" `
  -ex "funkin.save.*" `
  -ex "funkin.api.*" `
  -ex "funkin.vis.*"

cd docs/dox
