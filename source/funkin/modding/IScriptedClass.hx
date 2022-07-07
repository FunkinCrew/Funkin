package funkin.modding;

import funkin.modding.events.ScriptEvent;

/**
 * Defines a set of callbacks available to all scripted classes.
 * 
 * Includes events handling basic life cycle relevant to all scripted classes.
 */
interface IScriptedClass
{
	public function onScriptEvent(event:ScriptEvent):Void;

	public function onCreate(event:ScriptEvent):Void;
	public function onDestroy(event:ScriptEvent):Void;
	public function onUpdate(event:UpdateScriptEvent):Void;
}

/**
 * Defines a set of callbacks available to scripted classes which can follow the game between states.
 */
interface IStateChangingScriptedClass extends IScriptedClass
{
	public function onStateChangeBegin(event:StateChangeScriptEvent):Void;
	public function onStateChangeEnd(event:StateChangeScriptEvent):Void;

	public function onSubstateOpenBegin(event:SubStateScriptEvent):Void;
	public function onSubstateOpenEnd(event:SubStateScriptEvent):Void;
	public function onSubstateCloseBegin(event:SubStateScriptEvent):Void;
	public function onSubstateCloseEnd(event:SubStateScriptEvent):Void;
}

/**
 * Defines a set of callbacks available to scripted classes which represent notes.
 */
interface INoteScriptedClass extends IScriptedClass
{
	public function onNoteHit(event:NoteScriptEvent):Void;
	public function onNoteMiss(event:NoteScriptEvent):Void;
}

/**
 * Developer note:
 * 
 * I previously considered adding events for onKeyDown, onKeyUp, mouse events, etc.
 * However, I realized that you can simply call something like the following within a module:
 * `FlxG.state.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);`
 * This is more efficient than adding an entire event handler for every key press.
 *
 * -Eric
 */
/**
 * Defines a set of callbacks available to scripted classes that involve the lifecycle of the Play State.
 */
interface IPlayStateScriptedClass extends IScriptedClass
{
	public function onPause(event:PauseScriptEvent):Void;
	public function onResume(event:ScriptEvent):Void;

	public function onSongLoaded(eent:SongLoadScriptEvent):Void;
	public function onSongStart(event:ScriptEvent):Void;
	public function onSongEnd(event:ScriptEvent):Void;
	public function onGameOver(event:ScriptEvent):Void;
	public function onSongRetry(event:ScriptEvent):Void;

	public function onNoteHit(event:NoteScriptEvent):Void;
	public function onNoteMiss(event:NoteScriptEvent):Void;
	public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void;

	public function onStepHit(event:SongTimeScriptEvent):Void;
	public function onBeatHit(event:SongTimeScriptEvent):Void;

	public function onCountdownStart(event:CountdownScriptEvent):Void;
	public function onCountdownStep(event:CountdownScriptEvent):Void;
	public function onCountdownEnd(event:CountdownScriptEvent):Void;
}
