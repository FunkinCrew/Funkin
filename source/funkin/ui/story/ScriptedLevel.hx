package funkin.ui.story;

/**
 * A script that can be tied to a Level, which persists across states.
 * Create a scripted class that extends Level to use this.
 * This allows you to customize how a specific level appears.
 */
@:hscriptClass
class ScriptedLevel extends funkin.ui.story.Level implements polymod.hscript.HScriptedClass {}
