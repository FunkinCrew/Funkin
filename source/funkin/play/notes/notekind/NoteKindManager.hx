package funkin.play.notes.notekind;

import lime.app.Promise;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.song.SongData.SongNoteData;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notekind.NoteKind.NoteKindParam;
import funkin.util.macro.ClassMacro;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end

@:nullSafety
class NoteKindManager
{
  /**
   * Every built-in note kind class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  #if FEATURE_MULTITHREADING
  static final BUILTIN_KINDS:SynchronizedArray<Class<NoteKind>> = new SynchronizedArray<Class<NoteKind>>(ClassMacro.listSubclassesOf(NoteKind).filter((cls) ->
  {
    !['funkin.play.notes.notekind.NoteKind'].contains(Type.getClassName(cls));
  }));
  #else
  static final BUILTIN_KINDS:Array<Class<NoteKind>> = ClassMacro.listSubclassesOf(NoteKind).filter((cls) ->
  {
    !['funkin.play.notes.notekind.NoteKind'].contains(Type.getClassName(cls));
  });
  #end
  /**
   * A map of all note kinds, keyed by their name.
   * This is used to retrieve note kinds by their name.
   */
  #if FEATURE_MULTITHREADING
  public static var noteKinds:SynchronizedMap<String, NoteKind> = SynchronizedMap.newStringMap();
  #else
  public static var noteKinds:SynchronizedMap<String, NoteKind> = [];
  #end

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
   * Retrieve a list of known valid note kinds.
   * @return A list of note kinds
   */
  public static function listNoteKinds():Array<String>
  {
    #if FEATURE_MULTITHREADING
    // MapTools can't be used for SynchronizedMap.
    return[for (k => v in noteKinds) k];
    #else
    return noteKinds.keyValues();
    #end
  }

  /**
   * Initialize custom behavior for note kinds.
   */
  public static function initialize():Void
  {
    clearNoteKindCache();

    trace('Instantiating ${BUILTIN_KINDS.length} built-in note kinds...');
    for (noteKindCls in BUILTIN_KINDS)
    {
      var noteKindClsName:String = Type.getClassName(noteKindCls);
      var kind:NoteKind = Type.createInstance(noteKindCls, ['UNKNOWN']);

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

    var scriptedClassName:Array<String> = NoteKind.listScriptClasses();
    if (scriptedClassName.length > 0)
    {
      trace('Instantiating ${scriptedClassName.length} scripted note kind(s)...');
      for (scriptedClass in scriptedClassName)
      {
        try
        {
          var script:Null<NoteKind> = NoteKind.scriptInit(scriptedClass, 'unknown');
          if (script == null)
          {
            trace(' ERROR '.error() + 'Failed to instantiate scripted note kind ($scriptedClass)');
            continue;
          }
          else
          {
            trace('Instantiated scripted note kind ($scriptedClass = ${script.noteKind})');
            noteKinds.set(script.noteKind, script);
          }
        }
        catch (e)
        {
          trace(' FAILED to instantiate scripted note kind: ${scriptedClass}');
          trace(e);
        }
      }
    }
  }

  #if FEATURE_MULTITHREADING
  public static function loadNoteKindsAsync():lime.app.Future<LoadEntriesResult>
  {
    clearNoteKindCache();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadNoteKindsAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();
    var scriptedNoteKindClasses:Array<String> = NoteKind.listScriptClasses();
    var entryCount:Int = 0;
    var loadedBaseNoteKinds:Bool = false;

    var loadBaseNoteKindsAsync:Void->Void = () -> {};
    var loadScriptedNoteKindsAsync:Void->Void = () -> {};

    var checkAsyncProgress = () ->
    {
      var current:Int = noteKinds.size() + entryErrors.length;
      if (current == entryCount)
      {
        if (!loadedBaseNoteKinds)
        {
          loadedBaseNoteKinds = true;
          loadScriptedNoteKindsAsync();
          trace('Finished loading built-in note kinds (1/2) ($current / $entryCount)');
        }
        else
        {
          trace('Finished loading scripted note kinds (2/2) ($current / $entryCount)');
          promise.complete({
            entriesLoaded: noteKinds.size(),
            entriesFailed: entryErrors.length
          });
          perf.print();
        }
      }
    }

    var onError:(String,
      {error:Any, entryCls:Null<String>}) -> Void = (entryId, state) ->
      {
        entryErrors.push({
          entryId: entryId,
          error: state.error
        });
        trace('  Failed to load note kind (${entryId}): ${state.error}');
        checkAsyncProgress();
      };

    var performLoadBaseNoteKind:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var noteKindClsName:String = Type.getClassName(currentState.noteKindCls);
      var noteKindCls:Class<NoteKind> = currentState.noteKindCls;

      try
      {
        var noteKind:Null<NoteKind> = Type.createInstance(noteKindCls, []);
        if (noteKind != null)
        {
          workOutput.sendComplete({
            kind: noteKind
          }, []);
        }
        else
        {
          workOutput.sendError({
            noteKindId: noteKindClsName,
            error: 'Failed to create built-in note kind ($noteKindClsName)'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          eventId: noteKindClsName,
          error: e
        });
      }
    }

    var performLoadScriptedNoteKind:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryCls:String = currentState.entryCls;
      try
      {
        var noteKind:Null<NoteKind> = NoteKind.scriptInit(entryCls, 'UNKNOWN');
        if (noteKind != null)
        {
          workOutput.sendComplete({
            kind: noteKind,
            entryCls: entryCls
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryCls: entryCls,
            error: 'Failed to create scripted note kind (${entryCls})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryCls: entryCls,
          error: e,
        });
      }
    }

    var onBaseNoteKindLoaded:(String,
      {kind:NoteKind}) -> Void = (entryId, state) ->
      {
        noteKinds.set(state.kind.noteKind, state.kind);
        trace(' Loaded built-in note kind: ${state.kind.noteKind} ($entryId)');
        checkAsyncProgress();
      };

    var onScriptedNoteKindLoaded:(String,
      {kind:NoteKind, entryCls:String}) -> Void = (_, state) ->
      {
        var entryId:String = state.kind.noteKind;
        noteKinds.set(entryId, state.kind);
        trace('  Loaded scripted note kind: ${entryId} (${state.entryCls}) (${noteKinds.size()}+${entryErrors.length} / ${entryCount})');
        checkAsyncProgress();
      };

    loadBaseNoteKindsAsync = () ->
    {
      entryCount = BUILTIN_KINDS.length;
      trace('Instantiating ${BUILTIN_KINDS.length} built-in note kinds...');

      if (BUILTIN_KINDS.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (noteKindCls in BUILTIN_KINDS)
        {
          var entryClsName:String = Type.getClassName(noteKindCls);
          var baseNoteKindFuture = TaskHandler.performTask({
            task: performLoadBaseNoteKind,
            initialState: {
              noteKindCls: noteKindCls
            },
          }, new Promise<
            {kind:NoteKind}>());

          baseNoteKindFuture.onError(onError.bind(entryClsName));
          baseNoteKindFuture.onComplete(onBaseNoteKindLoaded.bind(entryClsName));
        }
      }
    }

    loadScriptedNoteKindsAsync = () ->
    {
      entryCount = noteKinds.size() + scriptedNoteKindClasses.length;
      trace('Instantiating ${scriptedNoteKindClasses.length} scripted note kind(s)...');

      if (scriptedNoteKindClasses.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (entryCls in scriptedNoteKindClasses)
        {
          var scriptedNoteKindFuture = TaskHandler.performTask({
            task: performLoadScriptedNoteKind,
            initialState: {
              entryCls: entryCls
            }
          }, new lime.app.Promise<
            {
              kind:NoteKind,
              entryCls:String
            }>());

          scriptedNoteKindFuture.onError(onError.bind(entryCls));
          scriptedNoteKindFuture.onComplete(onScriptedNoteKindLoaded.bind(entryCls));
        }
      }
    }

    loadBaseNoteKindsAsync();

    return promise.future;
  }
  #end

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

      var kind = noteEvent?.note?.kind;
      if (kind == null) return;

      var noteKind:Null<NoteKind> = noteKinds.get(kind);

      if (noteKind != null)
      {
        ScriptEventDispatcher.callEvent(noteKind, event);
      }
    }
    else // call the event for all note kind scripts
    {
      for (noteKind in noteKinds.values())
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
      var kind = songNoteData.kind;
      if (kind == null) continue;

      var noteStyle:Null<NoteStyle> = getNoteStyle(kind, null);
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
