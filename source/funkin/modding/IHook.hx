package funkin.modding;

import polymod.hscript.HScriptable;

/**
 * Functions annotated with @:hscript will call the relevant script.
 * Functions annotated with @:hookable can be reassigned.
 *   NOTE: If you receive the following error when making a function use @:hookable:
 *   `Cannot access this or other member field in variable initialization`
 *   This is because you need to perform calls and assignments using a static variable referencing the target object.
 */
@:hscript({
	// ALL of these values are added to ALL scripts in the child classes.
	context: [FlxG, FlxSprite, Math, Paths, Std]
})
@:autoBuild(funkin.util.macro.HookableMacro.build())
interface IHook extends HScriptable {}
