#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

echo "Note! This should be run from the root of the main Funkin repo, after creating a universal macOS build!"
echo "This script will assist in codesigning the Funkin.app for macOS"
echo ""

TEAM_ID="Z7G7AVNGSH"
ISSUER_ID="5205caca-2a9b-4b5e-9390-1db124cf51f4"
DEVELOPER_CERT_NAME="Developer ID Application: The Funkin' Crew Incorporated ($TEAM_ID)"
APP_PATH="export/release/macosUniversal/Funkin.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_PATH does not exist! Please build the app first."
  exit 1
fi

echo "Preparing/Checking the AuthKey"
team_key_path=~/.appstoreconnect/private_keys/
# Check if directory exists, if not, create it
if [ ! -d "$team_key_path" ]; then
  echo "The directory $team_key_path does not exist! Creating it now."
  mkdir -p "$team_key_path"
  echo ""
  echo "$team_key_path created, put the private key file in there (should be called 'AuthKey_XXXXXXX.p8')"
  echo "Ask Cameron for the private key file!"
  echo ""
fi

# wait for the user to put the file in the directory, if it's not there
while [ ! -f "${team_key_path}"AuthKey_*.p8 ]; do
  echo "Waiting for the private key file to be placed in $team_key_path... (press Ctrl+C to exit)"
  sleep 5
done

key_id=$(ls "$team_key_path" | grep -oE '[A-Z0-9]{10}' | head -n 1)
if [ -z "$key_id" ]; then
  echo "Error: Could not extract key ID from the AuthKey file name"
  exit 1
fi

echo "Found AuthKey with key id: $key_id"
key_path="${team_key_path}AuthKey_${key_id}.p8"

cd export/release/macosUniversal || { echo "Failed to change directory"; exit 1; }

echo "Ensuring properly formatted Entitlements.plist"
if [ ! -f "Funkin.app/Contents/Entitlements.plist" ]; then
  echo "Error: Entitlements.plist not found"
  exit 1
fi

plutil -convert xml1 Funkin.app/Contents/Entitlements.plist
plutil -convert xml1 Funkin.app/Contents/Info.plist
plutil -lint Funkin.app/Contents/Entitlements.plist
plutil -lint Funkin.app/Contents/Info.plist
echo "Entitlements.plist and Info.plist should be properly formatted..."
echo "Codesigning - Funkin.app"
# Check the keychain for the funkin crew certificate
echo "Checking for The Funkin' Crew certificate in the keychain..."
if ! security find-identity -p codesigning | grep -q "The Funkin' Crew Incorporated"; then
  echo "The Funkin' Crew Developer ID Application certificate was not found in the keychain!"
  echo "Download the certificate from:"
  echo "https://developer.apple.com/account/resources/certificates/download/Z62SXF29U7"
  exit 1
fi

echo "Codesigning - Funkin.app"
codesign --force --deep --timestamp --sign "$DEVELOPER_CERT_NAME" --options runtime Funkin.app || {
  echo "Code signing failed"
  exit 1
}

echo "Codesigning - Funkin.app done!"
# Debug info to see if the app is properly signed
codesign -vv --deep --strict Funkin.app || {
  echo "Code signing verification failed"
  exit 1
}
echo ""
echo "Zipping Funkin.app for notarization (using ditto)..."
# Check if Funkin.app.zip already exists, if so, delete it
if [ -f Funkin.app.zip ]; then
  echo "Funkin.app.zip already exists, deleting it..."
  rm -rf Funkin.app.zip
fi

ditto -c -k --keepParent Funkin.app Funkin.app.zip || {
  echo "Failed to create zip file"
  exit 1
}

echo "Funkin.app zipped, now sending to Apple for notarization..."
xcrun notarytool submit Funkin.app.zip --issuer "$ISSUER_ID" --key-id "$key_id" --key "$key_path" --wait || {
  echo "Notarization submission failed"
  exit 1
}

# Clean up zip file
rm -rf Funkin.app.zip

echo "Stapling Funkin.app"
xcrun stapler staple Funkin.app || {
  echo "Stapling failed"
  exit 1
}

echo "Code sign information!"
codesign -dv --verbose=4 Funkin.app

echo "Notarization information (stapler):"
xcrun stapler validate Funkin.app || {
  echo "Stapler validation failed"
  exit 1
}

cd ../../.. || { echo "Failed to return to original directory"; exit 1; }
echo "Notarization complete! Funkin.app is now codesigned and notarized!"

