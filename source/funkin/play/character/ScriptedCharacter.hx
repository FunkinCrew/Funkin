package funkin.play.character;

import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.PackerCharacter;
import funkin.play.character.SparrowCharacter;
import polymod.hscript.HScriptedClass;

/**
 * Note: Making a scripted class extending BaseCharacter is not recommended.
 * Do so ONLY if are handling all the character rendering yourself,
 * and can't use one of the built-in render modes.
 */
@:hscriptClass
class ScriptedBaseCharacter extends BaseCharacter implements HScriptedClass {}

@:hscriptClass
class ScriptedSparrowCharacter extends SparrowCharacter implements HScriptedClass {}

@:hscriptClass
class ScriptedMultiSparrowCharacter extends MultiSparrowCharacter implements HScriptedClass {}

@:hscriptClass
class ScriptedPackerCharacter extends PackerCharacter implements HScriptedClass {}
