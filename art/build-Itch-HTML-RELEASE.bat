@echo off
color 0a
cd ..
@echo on
echo BUILDING GAME
lime build html5 -final
echo UPLOADING TO ITCH
butler push ./export/release/html5/bin ninja-muffin24/funkin:html5
butler status ninja-muffin24/funkin:html5
echo ITCH SHIT UPDATED LMAOOOOO
pause