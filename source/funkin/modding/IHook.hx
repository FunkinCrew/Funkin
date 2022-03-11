package funkin.modding;

import polymod.hscript.HScriptable;

/**
 * Functions annotated with @:hscript will call the relevant script.
 */
@:hscript({
	// ALL of these values are added to ALL scripts in the child classes.
	context: [FlxG, FlxSprite, Math, Paths, Std]
})
interface IHook extends HScriptable {}
