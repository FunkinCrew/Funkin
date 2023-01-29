@echo off

SET /P yesno=do you really want to install all dependencies? [y/n]:
IF "%yesno%"=="y" GOTO Confirmation
IF "%yesno%"=="Y" GOTO Confirmation
IF "%yesno%"=="n" GOTO End
IF "%yesno%"=="N" GOTO End

:Confirmation
haxelib install hmm --quiet --always
haxelib run hmm install

:End
exit