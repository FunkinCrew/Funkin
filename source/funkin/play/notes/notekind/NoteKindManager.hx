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

  public static function callEvent(noteKind:String, event:ScriptEvent):Void
  {
    var noteKind:NoteKind = noteKinds.get(noteKind);

    if (noteKind == null)
    {
      return;
    }

    ScriptEventDispatcher.callEvent(noteKind, event);
  }
}
