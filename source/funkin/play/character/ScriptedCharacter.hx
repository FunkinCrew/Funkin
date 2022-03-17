package funkin.play.character;

import funkin.play.character.render.PackerCharacter;
import funkin.play.character.render.SparrowCharacter;
import funkin.modding.IHook;

@:hscriptClass
class ScriptedCharacter extends SparrowCharacter implements IHook {}

@:hscriptClass
class ScriptedSparrowCharacter extends SparrowCharacter implements IHook {}

@:hscriptClass
class ScriptedPackerCharacter extends PackerCharacter implements IHook {}
