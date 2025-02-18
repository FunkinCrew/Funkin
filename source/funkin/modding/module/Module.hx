package funkin.modding.module;

import funkin.modding.IScriptedClass.IGlobalScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * A module is a scripted class which receives all events without requiring a specific context.
 * You may have the module active at all times, or only when another script enables it.
 */
class Module implements IGlobalScriptedClass
{
  /**
   * Whether the module is currently active.
   */
  public var active(default, set):Bool = true;

  function set_active(value:Bool):Bool
  {
    return this.active = value;
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
   * NOTE: To make the module start inactive, call `this.active = false` in the constructor.
   */
  public function new(moduleId:String, priority:Int = 1000):Void
  {
    this.moduleId = moduleId;
    this.priority = priority;
  }

  public function toString()
  {
    return 'Module(' + this.moduleId + ')';
  }

  // TODO: Half of these aren't actually being called!!!!!!!

  public function onScriptEvent(event:ScriptEvent) {}

  /**
   * Called when the game is first initialized, before the title screen appears.
   * This happens only once, immediately after the module's first `onCreate` event.
   */
  public function onGameInit(event:ScriptEvent) {}

  /**
   * Called when the game is closed for any reason.
   * This happens only once, immediately before the module's last `onDestroy` event.
   */
  public function onGameClose(event:GameCloseScriptEvent) {}

  /**
   * Called when the module is created.
   * This happens when the game is first initialized or after a mod reload.
   */
  public function onCreate(event:ScriptEvent) {}

  /**
   * Called when a module is destroyed.
   * This happens when reloading modules with F5 or when the game is closed.
   */
  public function onDestroy(event:ScriptEvent) {}

  public function onUpdate(event:UpdateScriptEvent) {}

  public function onPlayStateCreate(event:ScriptEvent) {}

  public function onPlayStateClose(event:ScriptEvent) {}

  public function onPause(event:PauseScriptEvent) {}

  public function onResume(event:ScriptEvent) {}

  public function onSongStart(event:ScriptEvent) {}

  public function onSongEnd(event:ScriptEvent) {}

  public function onGameOver(event:ScriptEvent) {}

  public function onNoteIncoming(event:NoteScriptEvent) {}

  public function onNoteHit(event:HitNoteScriptEvent) {}

  public function onNoteMiss(event:NoteScriptEvent) {}

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent) {}

  public function onStepHit(event:SongTimeScriptEvent) {}

  public function onBeatHit(event:SongTimeScriptEvent) {}

  public function onSongEvent(event:SongEventScriptEvent) {}

  public function onCountdownStart(event:CountdownScriptEvent) {}

  public function onCountdownStep(event:CountdownScriptEvent) {}

  public function onCountdownEnd(event:CountdownScriptEvent) {}

  public function onSongLoaded(event:SongLoadScriptEvent) {}

  public function onStateChangeBegin(event:StateChangeScriptEvent) {}

  public function onStateChangeEnd(event:StateChangeScriptEvent) {}

  public function onFocusGained(event:FocusScriptEvent) {}

  public function onFocusLost(event:FocusScriptEvent) {}

  public function onSubStateOpenBegin(event:SubStateScriptEvent) {}

  public function onSubStateOpenEnd(event:SubStateScriptEvent) {}

  public function onSubStateCloseBegin(event:SubStateScriptEvent) {}

  public function onSubStateCloseEnd(event:SubStateScriptEvent) {}

  public function onSongRetry(event:SongRetryEvent) {}
}
