@echo off
color 0a
cd ..
@echo on
echo BUILDING GAME
lime build windows -debug
echo UPLOADING 64 BIT VERSION TO ITCH
butler push ./export/debug/windows/bin ninja-muffin24/funkin:windows-secretBeta
butler status ninja-muffin24/funkin:windows-secretBeta
echo ITCH SHIT UPDATED LMAOOOOO
pause