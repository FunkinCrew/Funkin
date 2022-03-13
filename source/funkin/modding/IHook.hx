package funkin.modding;

import polymod.hscript.HScriptable;

/**
 * Functions annotated with @:hscript will call the relevant script.
 * Functions annotated with @:hookable can be reassigned.
 */
@:hscript({
	// ALL of these values are added to ALL scripts in the child classes.
	context: [FlxG, FlxSprite, Math, Paths, Std]
})
// @:autoBuild(funkin.util.macro.HookableMacro.build())
interface IHook extends HScriptable {}
