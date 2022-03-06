package modding;

import polymod.hscript.HScriptable;

/**
 * Add this interface to a class to make it a scriptable object.
 * Functions annotated with @:hscript will call the relevant script.
 */
@:hscript({
	// ALL of these values are added to ALL scripts in the child classes.
	context: [FlxG, FlxSprite, Math, Paths, Std]
})
interface IHook extends HScriptable {}
