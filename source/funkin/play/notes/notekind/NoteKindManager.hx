package funkin.play.notes.notekind;

import funkin.data.song.SongData.SongNoteData;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notekind.ScriptedNoteKind;
import funkin.play.notes.notekind.NoteKind.NoteKindParam;

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

      var noteKind:NoteKind = noteKinds.get(noteEvent?.note?.kind);

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

  /**
   * Retrieve the note style from the given note kind
   * @param noteKind note kind name
   * @param suffix Used for song note styles
   * @return NoteStyle
   */
  public static function getNoteStyle(noteKind:String, ?suffix:String):Null<NoteStyle>
  {
    var noteStyleId:Null<String> = getNoteStyleId(noteKind, suffix);

    if (noteStyleId == null)
    {
      return null;
    }

    return NoteStyleRegistry.instance.fetchEntry(noteStyleId);
  }

  public static function listNoteStyles(songNoteDatas:Array<SongNoteData>):Array<NoteStyle>
  {
    var results:Array<NoteStyle> = [];
    for (songNoteData in songNoteDatas)
    {
      var noteStyle:NoteStyle = getNoteStyle(songNoteData.kind, null);
    }
    return results;
  }

  /**
   * Retrieve the note style id from the given note kind
   * @param noteKind Note kind name
   * @param suffix Used for song note styles
   * @return Null<String>
   */
  public static function getNoteStyleId(noteKind:String, ?suffix:String):Null<String>
  {
    if (suffix == '')
    {
      suffix = null;
    }

    var noteStyleId:Null<String> = noteKinds.get(noteKind)?.noteStyleId;
    if (noteStyleId != null && suffix != null)
    {
      noteStyleId = NoteStyleRegistry.instance.hasEntry('$noteStyleId-$suffix') ? '$noteStyleId-$suffix' : noteStyleId;
    }

    return noteStyleId;
  }

  /**
   * Retrive custom params of the given note kind
   * @param noteKind Name of the note kind
   * @return Array<NoteKindParam>
   */
  public static function getParams(noteKind:Null<String>):Array<NoteKindParam>
  {
    if (noteKind == null)
    {
      return [];
    }

    return noteKinds.get(noteKind)?.params ?? [];
  }
}
