# modding.base

This package is used to allow modders to create scripted classes which extend these base classes.
For example, one script can extend FlxSprite and another can call `ScriptedFlxSprite.init('ClassName')`.
Most of these scripted class stubs are not used by the game itself, so this package has been explicitly marked to be ignored by DCE.
