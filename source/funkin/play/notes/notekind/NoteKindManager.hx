package funkin.play.notes.notekind;

import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;

class NoteKindManager
{
  static var noteKinds:Map<String, NoteKind> = [];

  public static function loadScripts():Void
  {
    var scriptedClassName:Array<String> = ScriptedNoteKind.listScriptClasses();
    if (scriptedClassName.length > 0)
    {
      trace('Instantiating ${scriptedClassName.length} scripted note kind(s)...');
      for (scriptedClass in scriptedClassName)
      {
        try
        {
          var script:NoteKind = ScriptedNoteKind.init(scriptedClass, "unknown");
          trace(' Initialized scripted note kind: ${script.noteKind}');
          noteKinds.set(script.noteKind, script);
          ChartEditorDropdowns.NOTE_KINDS.set(script.noteKind, script.description);
        }
        catch (e)
        {
          trace(' FAILED to instantiate scripted note kind: ${scriptedClass}');
          trace(e);
        }
      }
    }
  }

  /**
   * Calls the given event for note kind scripts
   * @param event The event
   */
  public static function callEvent(event:ScriptEvent):Void
  {
    // if it is a note script event,
    // then only call the event for the specific note kind script
    if (Std.isOfType(event, NoteScriptEvent))
    {
      var noteEvent:NoteScriptEvent = cast(event, NoteScriptEvent);

      var noteKind:NoteKind = noteKinds.get(noteEvent.note.noteData.kind);

      if (noteKind != null)
      {
        ScriptEventDispatcher.callEvent(noteKind, event);
      }
    }
    else // call the event for all note kind scripts
    {
      for (noteKind in noteKinds.iterator())
      {
        ScriptEventDispatcher.callEvent(noteKind, event);
      }
    }
  }
}
