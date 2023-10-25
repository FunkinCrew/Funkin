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
      case ScriptEventType.CREATE:
        target.onCreate(event);
        return;
      case ScriptEventType.DESTROY:
        target.onDestroy(event);
        return;
      case ScriptEventType.UPDATE:
        target.onUpdate(cast event);
        return;
    }

    if (Std.isOfType(target, IStateStageProp))
    {
      var t:IStateStageProp = cast(target, IStateStageProp);
      switch (event.type)
      {
        case ScriptEventType.ADDED:
          t.onAdd(cast event);
          return;
      }
    }

    if (Std.isOfType(target, IDialogueScriptedClass))
    {
      var t:IDialogueScriptedClass = cast(target, IDialogueScriptedClass);
      switch (event.type)
      {
        case ScriptEventType.DIALOGUE_START:
          t.onDialogueStart(cast event);
          return;
        case ScriptEventType.DIALOGUE_LINE:
          t.onDialogueLine(cast event);
          return;
        case ScriptEventType.DIALOGUE_COMPLETE_LINE:
          t.onDialogueCompleteLine(cast event);
          return;
        case ScriptEventType.DIALOGUE_SKIP:
          t.onDialogueSkip(cast event);
          return;
        case ScriptEventType.DIALOGUE_END:
          t.onDialogueEnd(cast event);
          return;
      }
    }

    if (Std.isOfType(target, IPlayStateScriptedClass))
    {
      var t:IPlayStateScriptedClass = cast(target, IPlayStateScriptedClass);
      switch (event.type)
      {
        case ScriptEventType.NOTE_HIT:
          t.onNoteHit(cast event);
          return;
        case ScriptEventType.NOTE_MISS:
          t.onNoteMiss(cast event);
          return;
        case ScriptEventType.NOTE_GHOST_MISS:
          t.onNoteGhostMiss(cast event);
          return;
        case ScriptEventType.SONG_BEAT_HIT:
          t.onBeatHit(cast event);
          return;
        case ScriptEventType.SONG_STEP_HIT:
          t.onStepHit(cast event);
          return;
        case ScriptEventType.SONG_START:
          t.onSongStart(event);
          return;
        case ScriptEventType.SONG_END:
          t.onSongEnd(event);
          return;
        case ScriptEventType.SONG_RETRY:
          t.onSongRetry(event);
          return;
        case ScriptEventType.GAME_OVER:
          t.onGameOver(event);
          return;
        case ScriptEventType.PAUSE:
          t.onPause(cast event);
          return;
        case ScriptEventType.RESUME:
          t.onResume(event);
          return;
        case ScriptEventType.SONG_EVENT:
          t.onSongEvent(cast event);
          return;
        case ScriptEventType.COUNTDOWN_START:
          t.onCountdownStart(cast event);
          return;
        case ScriptEventType.COUNTDOWN_STEP:
          t.onCountdownStep(cast event);
          return;
        case ScriptEventType.COUNTDOWN_END:
          t.onCountdownEnd(cast event);
          return;
        case ScriptEventType.SONG_LOADED:
          t.onSongLoaded(cast event);
          return;
      }
    }

    if (Std.isOfType(target, IStateChangingScriptedClass))
    {
      var t = cast(target, IStateChangingScriptedClass);
      switch (event.type)
      {
        case ScriptEventType.STATE_CHANGE_BEGIN:
          t.onStateChangeBegin(cast event);
          return;
        case ScriptEventType.STATE_CHANGE_END:
          t.onStateChangeEnd(cast event);
          return;
        case ScriptEventType.SUBSTATE_OPEN_BEGIN:
          t.onSubStateOpenBegin(cast event);
          return;
        case ScriptEventType.SUBSTATE_OPEN_END:
          t.onSubStateOpenEnd(cast event);
          return;
        case ScriptEventType.SUBSTATE_CLOSE_BEGIN:
          t.onSubStateCloseBegin(cast event);
          return;
        case ScriptEventType.SUBSTATE_CLOSE_END:
          t.onSubStateCloseEnd(cast event);
          return;
      }
    }
    else
    {
      // Prevent "NO HELPER error."
      return;
    }

    // If you get a crash on this line, that means ERIC FUCKED UP!
    // throw 'No function called for event type: ${event.type}';
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
