package funkin.modding.base;

/**
 * A script that can be tied to an FlxSpriteGroup.
 * Create a scripted class that extends FlxSpriteGroup to use this.
 */
@:hscriptClass
class ScriptedFlxSpriteGroup extends flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<flixel.FlxSprite> implements HScriptedClass {}
