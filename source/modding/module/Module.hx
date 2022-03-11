package modding.module;

import modding.module.events.ModuleEvent;

/**
 * A module is an interface which provides for scripts to perform custom behavior
 * without requiring a specific context.
 * 
 * You may have the module active at all times, or only when another script enables it.
 */
class Module
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
	 * Called when the module is initialized.
	 * It may not be safe to reference other modules here since they may not be loaded yet.
	 * 
	 * @param startActive Whether to start with the module active.
	 *   If false, the module will be inactive and must be enabled by another script,
	 *   such as a stage or another module.
	 */
	public function new(moduleId:String, startActive:Bool)
	{
		this.moduleId = moduleId;
		this.active = startActive;
	}

	/**
	 * Called after the module was initialized, but before anything else.
	 * Other modules may still be uninitialized at this stage.
	 */
	public function onPostCreate() {}

	/**
	 * Called at the beginning of a song, before the countdown begins.
	 */
	public function onSongStart() {}

	/**
	 * Called at the end of a song, after the song fades out.
	 */
	public function onSongEnd() {}

	/**
	 * Called at the beginning of the countdown.
	 */
	public function onBeginCountdown(event:ModuleEvent) {}

	/**
	 * Called four times per section of a song.
	 */
	public function onSongBeat() {}

	/**
	 * Called sixteen times per section of a song.
	 */
	public function onSongStep() {}

	/**
	 * Called at the end of the `update()` loop.
	 * Be careful! Using this can have a significant impact on performance.
	 */
	public function onUpdate(event:UpdateModuleEvent) {}

	public function onNoteHit() {}

	public function onNoteMiss() {}
}
