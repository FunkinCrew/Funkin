package funkin.modding.module;

import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.events.ScriptEvent.KeyboardInputScriptEvent;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.CountdownScriptEvent;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.IScriptedClass.IStateChangingScriptedClass;

/**
 * A module is a scripted class which receives all events without requiring a specific context.
 * You may have the module active at all times, or only when another script enables it.
 */
class Module implements IPlayStateScriptedClass implements IStateChangingScriptedClass
{
	/**
	 * Whether the module is currently active.
	 */
	public var active(default, set):Bool = false;

	function set_active(value:Bool):Bool
	{
		this.active = value;
		return value;
	}

	public var moduleId(default, null):String = 'UNKNOWN';

	/**
	 * Determines the order in which modules receive events.
	 * You can modify this to change the order in which a given module receives events.
	 * 
	 * Priority 1 is processed before Priority 1000, etc.
	 */
	public var priority(default, set):Int;

	function set_priority(value:Int):Int
	{
		this.priority = value;
		@:privateAccess
		ModuleHandler.reorderModuleCache();
		return value;
	}

	/**
	 * Called when the module is initialized.
	 * It may not be safe to reference other modules here since they may not be loaded yet.
	 * 
	 * @param startActive Whether to start with the module active.
	 *   If false, the module will be inactive and must be enabled by another script,
	 *   such as a stage or another module.
	 */
	public function new(moduleId:String, active:Bool = true, priority:Int = 1000):Void
	{
		this.moduleId = moduleId;
		this.active = active;
		this.priority = priority;
	}

	public function toString()
	{
		return 'Module(' + this.moduleId + ')';
	}

	// TODO: Half of these aren't actually being called!!!!!!!

	public function onScriptEvent(event:ScriptEvent) {}

	/**
	 * Called when the module is first created.
	 * This happens before the title screen appears!
	 */
	public function onCreate(event:ScriptEvent) {}

	/**
	 * Called when a module is destroyed.
	 * This currently only happens when reloading modules with F5.
	 */
	public function onDestroy(event:ScriptEvent) {}

	public function onUpdate(event:UpdateScriptEvent) {}

	public function onPause(event:ScriptEvent) {}

	public function onResume(event:ScriptEvent) {}

	public function onSongStart(event:ScriptEvent) {}

	public function onSongEnd(event:ScriptEvent) {}

	public function onSongReset(event:ScriptEvent) {}

	public function onGameOver(event:ScriptEvent) {}

	public function onGameRetry(event:ScriptEvent) {}

	public function onNoteHit(event:NoteScriptEvent) {}

	public function onNoteMiss(event:NoteScriptEvent) {}

	public function onStepHit(event:SongTimeScriptEvent) {}

	public function onBeatHit(event:SongTimeScriptEvent) {}

	public function onCountdownStart(event:CountdownScriptEvent) {}

	public function onCountdownStep(event:CountdownScriptEvent) {}

	public function onCountdownEnd(event:CountdownScriptEvent) {}

	public function onSongLoaded(eent:SongLoadScriptEvent) {}

	public function onStateChangeBegin(event:StateChangeScriptEvent) {}

	public function onStateChangeEnd(event:StateChangeScriptEvent) {}
}
