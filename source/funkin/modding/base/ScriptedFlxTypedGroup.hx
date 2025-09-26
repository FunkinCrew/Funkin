package funkin.modding.base;

/**
 * A script that can be tied to an FlxTypedGroup.
 * Create a scripted class that extends FlxTypedGroup to use this.
 */
@:hscriptClass
class ScriptedFlxTypedGroup extends flixel.group.FlxGroup.FlxTypedGroup<Dynamic> implements HScriptedClass {}
