package play.stage;

import modding.IHook;

/**
 * NOTE: Turns out one of the few edge case that scripted classes are broken with,
 * that being generic classes with a constrained type argument, applies to FlxSpriteGroup.
 * Will have to find a fix for the issue before stages can have scripting enabled.
 * 
 * In the meantime though, I want to get stages working just with JSON.
 * -Eric
 */
// @:hscriptClass
// class ScriptedStage extends Stage implements IHook
// {
// 	// No body needed for this class, it's magic ;)
// }
