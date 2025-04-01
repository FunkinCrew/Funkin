package funkin.play.stage;

/**
 * A script that can be tied to a Stage.
 * Create a scripted class that extends Stage,
 * and call `super('stageID')` in the constructor.
 */
@:hscriptClass
class ScriptedStage extends funkin.play.stage.Stage implements polymod.hscript.HScriptedClass {}
