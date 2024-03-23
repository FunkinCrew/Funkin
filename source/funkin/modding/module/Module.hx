package funkin.modding.module;

import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.IScriptedClass.IStateChangingScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * A module is a scripted class which receives all events without requiring a specific context.
 * You may have the module active at all times, or only when another script enables it.
 */
class Module implements IPlayStateScriptedClass implements IStateChangingScriptedClass
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

  public function onSubStateOpenBegin(event:SubStateScriptEvent) {}

  public function onSubStateOpenEnd(event:SubStateScriptEvent) {}

  public function onSubStateCloseBegin(event:SubStateScriptEvent) {}

  public function onSubStateCloseEnd(event:SubStateScriptEvent) {}

  public function onSongRetry(event:ScriptEvent) {}
}
