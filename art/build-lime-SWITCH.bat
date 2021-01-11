@echo off
cd ..
@echo on
echo REBUILDING LIME FOR EXPORT (VERBOSE)
@echo off
color 0b
@echo on
lime rebuild windows -clean -v
@echo off
color 0a
@echo on
lime rebuild switch -clean -v
@echo off
color 0e
@echo on
lime rebuild tools -clean -v
echo HOPE AND PRAY...
@echo off
color 0a
@echo on
echo BUILDING GAME
lime build switch -final -clean -v
@echo off
color 0b
@echo on
echo NSP FILE CREATED
pause