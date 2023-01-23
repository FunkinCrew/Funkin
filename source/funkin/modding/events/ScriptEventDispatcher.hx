package funkin.modding.events;

import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.IScriptedClass;

/**
 * Utility functions to assist with handling scripted classes.
 */
class ScriptEventDispatcher
{
  public static function callEvent(target:IScriptedClass, event:ScriptEvent):Void
  {
    if (target == null || event == null) return;

    target.onScriptEvent(event);

    // If one target says to stop propagation, stop.
    if (!event.shouldPropagate)
    {
      return;
    }

    // IScriptedClass
    switch (event.type)
    {
      case ScriptEvent.CREATE:
        target.onCreate(event);
        return;
      case ScriptEvent.DESTROY:
        target.onDestroy(event);
        return;
      case ScriptEvent.UPDATE:
        target.onUpdate(cast event);
        return;
    }

    if (Std.isOfType(target, IPlayStateScriptedClass))
    {
      var t = cast(target, IPlayStateScriptedClass);
      switch (event.type)
      {
        case ScriptEvent.NOTE_HIT:
          t.onNoteHit(cast event);
          return;
        case ScriptEvent.NOTE_MISS:
          t.onNoteMiss(cast event);
          return;
        case ScriptEvent.NOTE_GHOST_MISS:
          t.onNoteGhostMiss(cast event);
          return;
        case ScriptEvent.SONG_BEAT_HIT:
          t.onBeatHit(cast event);
          return;
        case ScriptEvent.SONG_STEP_HIT:
          t.onStepHit(cast event);
          return;
        case ScriptEvent.SONG_START:
          t.onSongStart(event);
          return;
        case ScriptEvent.SONG_END:
          t.onSongEnd(event);
          return;
        case ScriptEvent.SONG_RETRY:
          t.onSongRetry(event);
          return;
        case ScriptEvent.GAME_OVER:
          t.onGameOver(event);
          return;
        case ScriptEvent.PAUSE:
          t.onPause(cast event);
          return;
        case ScriptEvent.RESUME:
          t.onResume(event);
          return;
        case ScriptEvent.COUNTDOWN_START:
          t.onCountdownStart(cast event);
          return;
        case ScriptEvent.COUNTDOWN_STEP:
          t.onCountdownStep(cast event);
          return;
        case ScriptEvent.COUNTDOWN_END:
          t.onCountdownEnd(cast event);
          return;
        case ScriptEvent.SONG_LOADED:
          t.onSongLoaded(cast event);
          return;
      }
    }

    if (Std.isOfType(target, IStateChangingScriptedClass))
    {
      var t = cast(target, IStateChangingScriptedClass);
      switch (event.type)
      {
        case ScriptEvent.STATE_CHANGE_BEGIN:
          t.onStateChangeBegin(cast event);
          return;
        case ScriptEvent.STATE_CHANGE_END:
          t.onStateChangeEnd(cast event);
          return;
        case ScriptEvent.SUBSTATE_OPEN_BEGIN:
          t.onSubstateOpenBegin(cast event);
          return;
        case ScriptEvent.SUBSTATE_OPEN_END:
          t.onSubstateOpenEnd(cast event);
          return;
        case ScriptEvent.SUBSTATE_CLOSE_BEGIN:
          t.onSubstateCloseBegin(cast event);
          return;
        case ScriptEvent.SUBSTATE_CLOSE_END:
          t.onSubstateCloseEnd(cast event);
          return;
      }
    }
    else
    {
      // Prevent "NO HELPER error."
      return;
    }

    throw "No function called for event type: " + event.type;
  }

  public static function callEventOnAllTargets(targets:Iterator<IScriptedClass>, event:ScriptEvent):Void
  {
    if (targets == null || event == null) return;

    if (Std.isOfType(targets, Array))
    {
      var t = cast(targets, Array<Dynamic>);
      if (t.length == 0) return;
    }

    for (target in targets)
    {
      var t:IScriptedClass = cast target;
      if (t == null) continue;

      callEvent(t, event);

      // If one target says to stop propagation, stop.
      if (!event.shouldPropagate)
      {
        return;
      }
    }
  }
}
