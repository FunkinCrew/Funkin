@echo off
color 0a
cd ..
@echo on
echo BUILDING GAME
lime build hl -debug
echo UPLOADING 64 BIT VERSION TO ITCH
butler push ./export/debug/hl/bin ninja-muffin24/funkin:windows-64bit
lime build hl -debug -32
echo UPLOADING 32 BIT VERSION TO ITCH
butler push ./export/debug/hl/bin ninja-muffin24/funkin:windows-32bit
butler status ninja-muffin24/funkin:windows-32bit
butler status ninja-muffin24/funkin:windows-64bit
echo ITCH SHIT UPDATED LMAOOOOO
pause