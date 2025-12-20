package funkin.play.notes.notekind;

import funkin.data.song.SongData.SongNoteData;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notekind.ScriptedNoteKind;
import funkin.play.notes.notekind.NoteKind.NoteKindParam;
import funkin.util.macro.ClassMacro;

class NoteKindManager
{
  /**
   * Every built-in note kind class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  static final BUILTIN_KINDS:List<Class<NoteKind>> = ClassMacro.listSubclassesOf(NoteKind);

  /**
   * A map of all note kinds, keyed by their name.
   * This is used to retrieve note kinds by their name.
   */
  public static var noteKinds:Map<String, NoteKind> = [];

  /**
   * Retrieve a note kind by its name.
   * @param noteKind The name of the note kind.
   * @return The note kind, or null if it doesn't exist.
   */
  public static function getNoteKind(?noteKind:String):Null<NoteKind>
  {
    if (noteKind == null) return null;
    return noteKinds.get(noteKind);
  }

  /**
   * Initialize custom behavior for note kinds.
   */
  public static function initialize():Void
  {
    clearNoteKindCache();

    //
    // BASE GAME EVENTS
    //
    registerBaseNoteKinds();
    registerScriptedNoteKinds();
  }

  /**
   * Register the hard-coded note kinds.
   */
  public static function registerBaseNoteKinds():Void
  {
    trace('Instantiating ${BUILTIN_KINDS.length} built-in note kinds...');
    for (noteKindCls in BUILTIN_KINDS)
    {
      var noteKindClsName:String = Type.getClassName(noteKindCls);
      if (noteKindClsName == 'funkin.play.notes.notekind.NoteKind'
        || noteKindClsName == 'funkin.play.notes.notekind.ScriptedNoteKind') continue;

      var kind:NoteKind = Type.createInstance(noteKindCls, ["UNKNOWN"]);

      if (kind != null)
      {
        trace(' Loaded built-in note kind: ${kind.noteKind}');
        noteKinds.set(kind.noteKind, kind);
      }
      else
      {
        trace(' Failed to load built-in note kind: ${noteKindClsName}');
      }
    }
  }

  /**
   * Register the scripted note kinds provided by mods.
   */
  public static function registerScriptedNoteKinds():Void
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
          #if FEATURE_CHART_EDITOR
          ChartEditorDropdowns.NOTE_KINDS.set(script.noteKind, script.description);
          #end
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

  /**
   * Get a list of all the note styles used by the given notes.
   * Great for preloading.
   * @param songNoteDatas The notes to query for note styles.
   * @return The note styles to load.
   */
  public static function listNoteStylesByNoteData(songNoteDatas:Array<SongNoteData>):Array<NoteStyle>
  {
    var results:Array<NoteStyle> = [];
    for (songNoteData in songNoteDatas)
    {
      var noteStyle:NoteStyle = getNoteStyle(songNoteData.kind, null);
      if (noteStyle != null && !results.contains(noteStyle))
      {
        results.push(noteStyle);
      }
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

  /**
   * Clear the note kind cache.
   * Be sure to register the note kinds again before trying to use them.
   */
  public static function clearNoteKindCache():Void
  {
    noteKinds.clear();
  }
}
