@echo off
color 0a
cd ..
@echo on
echo BUILDING GAME
lime build windows -final
echo UPLOADING TO ITCH
butler push ./export/release/html5/bin ninja-muffin24/ld47:windows
butler status ninja-muffin24/ld47:windows
echo ITCH SHIT UPDATED LMAOOOOO
pause