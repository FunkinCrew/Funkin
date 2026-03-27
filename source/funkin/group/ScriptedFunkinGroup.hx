package funkin.group;

/**
 * A script that can be tied to a FunkinGroup.
 * Create a scripted class that extends FunkinGroup to use this.
 */
@:hscriptClass
class ScriptedFunkinGroup extends funkin.group.FunkinGroup<Dynamic> implements polymod.hscript.HScriptedClass {}

/**
 * A script that can be tied to a FunkinSpriteGroup.
 * Create a scripted class that extends FunkinSpriteGroup to use this.
 */
@:hscriptClass
class ScriptedFunkinSpriteGroup extends funkin.group.FunkinGroup.FunkinSpriteGroup implements polymod.hscript.HScriptedClass {}
