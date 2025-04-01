package funkin.play.character;

/**
 * A script that can be tied to a BaseCharacter, which persists across states.
 * Create a scripted class that extends BaseCharacter to use this.
 * Note: Making a scripted class extending BaseCharacter is not recommended.
 * Do so ONLY if are handling all the character rendering yourself,
 * and can't use one of the built-in render modes.
 */
@:hscriptClass
class ScriptedBaseCharacter extends BaseCharacter implements polymod.hscript.HScriptedClass {}

/**
 * A script that can be tied to a SparrowCharacter, which persists across states.
 * Create a scripted class that extends SparrowCharacter,
 * then call `super('charId')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedSparrowCharacter extends SparrowCharacter implements polymod.hscript.HScriptedClass {}

/**
 * A script that can be tied to a MultiSparrowCharacter, which persists across states.
 * Create a scripted class that extends MultiSparrowCharacter,
 * then call `super('charId')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedMultiSparrowCharacter extends MultiSparrowCharacter implements polymod.hscript.HScriptedClass {}

/**
 * A script that can be tied to a PackerCharacter, which persists across states.
 * Create a scripted class that extends PackerCharacter,
 * then call `super('charId')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedPackerCharacter extends PackerCharacter implements polymod.hscript.HScriptedClass {}

/**
 * A script that can be tied to an AnimateAtlasCharacter, which persists across states.
 * Create a scripted class that extends AnimateAtlasCharacter,
 * then call `super('charId')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedAnimateAtlasCharacter extends AnimateAtlasCharacter implements polymod.hscript.HScriptedClass {}
