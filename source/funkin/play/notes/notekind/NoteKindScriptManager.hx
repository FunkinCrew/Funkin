package funkin.play.notes.notekind;

import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;

class NoteKindScriptManager
{
  static var noteKindScripts:Map<String, NoteKindScript> = [];

  public static function loadScripts():Void
  {
    var scriptedClassName:Array<String> = ScriptedNoteKindScript.listScriptClasses();
    if (scriptedClassName.length > 0)
    {
      trace('Instantiating ${scriptedClassName.length} scripted note kind...');
      for (scriptedClass in scriptedClassName)
      {
        try
        {
          var script:NoteKindScript = ScriptedNoteKindScript.init(scriptedClass, "unknown");
          trace(' Initialized scripted note kind: ${script.noteKind}');
          noteKindScripts.set(script.noteKind, script);
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

  public static function callEvent(noteKind:String, event:ScriptEvent):Void
  {
    var noteKindScript:NoteKindScript = noteKindScripts.get(noteKind);

    if (noteKindScript == null)
    {
      return;
    }

    ScriptEventDispatcher.callEvent(noteKindScript, event);
  }
}
