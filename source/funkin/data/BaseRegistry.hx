package funkin.data;

import funkin.util.VersionUtil;
import haxe.Constraints.Constructible;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Assets;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

typedef RegistryParams =
{
  /**
   * The internal ID of this entry. Used when logging.
   */
  var registryId:String;

  /**
   * The path where data files for this registry can be found.
   */
  var dataFilePath:String;

  /**
   * Whether data files are expected to be nested.
   * If `false`, files will be at `<dataFilePath>/<id>.json`
   * If `true`, files will be at `<dataFilePath>/<id>/<id>.json`
   * @default `false`
   */
  var ?nestedEntries:Bool;

  /**
   * (Optional) Define a version rule for validating entries.
   * @default Any version
   */
  var ?versionRule:thx.semver.VersionRule;
}

/**
 * The entry's constructor function takes 2 arguments, the entry ID and optional parameters.
 */
typedef EntryConstructorFunction = (String, ?Dynamic) -> Void;

/**
 * A base type for a Registry, which is an object which handles loading scriptable objects.
 *
 * @param T The type to construct. Must implement `IRegistryEntry`.
 * @param J The type of the JSON data used when constructing.
 * @param P The type of the parameters used for `fetchEntry()`.
 */
@:nullSafety
@:generic
@:autoBuild(funkin.util.macro.RegistryMacro.buildRegistry())
abstract class BaseRegistry<T:(IRegistryEntry<J> & Constructible<EntryConstructorFunction>), J, P>
{
  /**
   * The ID of the registry. Used when logging.
   */
  public final registryId:String;

  /**
   * The file path where data files for this registry can be found.
   */
  final dataFilePath:String;

  /**
   * Whether data files are expected to be nested.
   */
  final nestedEntries:Bool;

  /**
   * A map of entry IDs to entries.
   */
  #if FEATURE_MULTITHREADING
  final entries:SynchronizedMap<String, T>; // Use a thread safe map when needed.
  #else
  final entries:Map<String, T>;
  #end
  /**
   * A map of entry IDs to scripted class names.
   */
  #if FEATURE_MULTITHREADING
  final scriptedEntryIds:SynchronizedMap<String, String>; // Use a thread safe map when needed.
  #else
  final scriptedEntryIds:Map<String, String>;
  #end

  /**
   * The version rule to use when loading entries.
   * If the entry's version does not match this rule, migration is needed.
   */
  final versionRule:thx.semver.VersionRule;

  final ASSET_BLACKLIST:Array<String> = ['Animation', 'spritemap1'];

  // public abstract static final instance:BaseRegistry<T, J> = new BaseRegistry<>();

  /**
   * @param registryId A readable ID for this registry, used when logging.
   * @param dataFilePath The path (relative to `assets/data`) to search for JSON files.
   */
  public function new(params:RegistryParams)
  {
    final DEFAULT_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    this.registryId = params.registryId;
    this.dataFilePath = params.dataFilePath;
    this.nestedEntries = params.nestedEntries ?? false;
    this.versionRule = params.versionRule ?? DEFAULT_VERSION_RULE;

    #if FEATURE_MULTITHREADING
    this.entries = SynchronizedMap.newStringMap();
    this.scriptedEntryIds = SynchronizedMap.newStringMap();
    #else
    this.entries = [];
    this.scriptedEntryIds = [];
    #end

    // Lazy initialization of singletons should let this get called,
    // but we have this check just in case.
    if (FlxG.game != null)
    {
      FlxG.console.registerObject('registry$registryId', this);
    }
  }

  /**
   * Loads all JSON files, constructs the appropriate entries, and adds them to the registry.
   * This function operates synchronously and only returns once all entries have been loaded.
   */
  public function loadEntries():Void
  {
    var perf = new funkin.util.logging.Perf('loadEntriesSync(${registryId})');
    clearEntries();

    //
    // SCRIPTED ENTRIES
    //
    var scriptedEntryClassNames:Array<String> = getScriptedClassNames();
    log(' INFO '.info() + 'Parsing ${scriptedEntryClassNames.length} scripted entries...');

    for (entryCls in scriptedEntryClassNames)
    {
      var entry:Null<T> = null;
      try
      {
        entry = createScriptedEntry(entryCls);
      }
      catch (e)
      {
        log('Failed to instantiate scripted entry (${entryCls})');
        continue;
      }

      if (entry != null)
      {
        onScriptedEntryLoaded(entryCls, entry);
        log('Instantiated scripted entry (${entryCls} = ${entry.id})');
      }
      else
      {
        log('Failed to instantiate scripted entry (${entryCls})');
      }
    }

    //
    // UNSCRIPTED ENTRIES
    //
    var entryIdList:Array<String> = fetchEntryIdsFromFiles();
    var unscriptedEntryIds:Array<String> = entryIdList.filter((entryId:String) ->
    {
      return !entries.exists(entryId);
    });
    log(' INFO '.info() + 'Parsing ${unscriptedEntryIds.length} unscripted entries...');
    for (entryId in unscriptedEntryIds)
    {
      try
      {
        var entry:Null<T> = createEntry(entryId);
        if (entry != null)
        {
          onUnscriptedEntryLoaded(entry);
          log('Instantiated unscripted entry (${entry.id})');
        }
      }
      catch (e)
      {
        // Print the error.
        log(' WARNING '.warning() + ' Failed to instantiate unscripted entry (${entryId})');
        continue;
      }
    }

    perf.print();
  }

  /**
   * Called when a scripted entry has been successfully loaded.
   * @param entry The entry that was loaded.
   */
  function onScriptedEntryLoaded(clsName:String, entry:T):Void
  {
    entries.set(entry.id, entry);
    scriptedEntryIds.set(entry.id, clsName);
  }

  /**
   * Called when an unscripted entry has been successfully loaded.
   * @param entry The entry that was loaded.
   */
  function onUnscriptedEntryLoaded(entry:T):Void
  {
    entries.set(entry.id, entry);
  }

  #if FEATURE_MULTITHREADING
  /**
   * Loads all JSON files, constructs the appropriate entries, and adds them to the registry.
   * This function operates asynchronously, and returns a Future representing a fulfilled promise.
   * You can add an `onComplete` callback to perform some action when all entries have been loaded.
   * @return A future representing the fulfilled entry loading.
   */
  @:haxe.warning('-WVarInit')
  public function loadEntriesAsync():lime.app.Future<LoadEntriesResult>
  {
    // Fuuuck dude this code is so nasty fuuuck

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadEntriesAsync(${registryId})');

    // Clear the entries before we start loading new ones.
    clearEntries();

    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();

    var doneScriptedEntries:Bool = false;

    var entryCount:Int = 0;
    var scriptedEntryClassNames:Array<String> = [];
    var unscriptedEntryIds:Array<String> = [];

    // A thread-safe array to store errors in.
    var entryErrors:SynchronizedArray<
      {
        ?entryId:String,
        error:Any,
        ?entryCls:String
      }> = new SynchronizedArray();

    var startUnscriptedEntries:() -> Void;

    // Callback when one task completes
    // When the last task completes, we can complete the promise.
    var checkComplete:Void->Void = () ->
    {
      var completedCount = countEntries() + entryErrors.length;
      if (completedCount == entryCount)
      {
        if (!doneScriptedEntries)
        {
          doneScriptedEntries = true;
          startUnscriptedEntries();
          log('Finished loading entries (1/2) ($completedCount / ${entryCount})');
          return;
        }
        else
        {
          log('Finished loading entries (2/2) ($completedCount / ${entryCount})');
          promise.complete({
            entriesLoaded: countEntries(),
            entriesFailed: entryErrors.length
          });
          perf.print();
        }
      }
      else
      {
        if ((entryCount - completedCount) == 1)
        {
          // *mercy gif* Use this snippet if the asset loading gets stuck.
          /*
            var unfinishedEntries:Array<String> = []
            unfinishedEntries.appendUnique(unscriptedEntryIds.filter((id) -> !entries.exists(id)))
            unfinishedEntries.appendUnique(scriptedEntryClassNames.filter((clsName) -> !scriptedEntryIds.exists(clsName)))
            log('  Only one entry left!')
            log('  Unfinished: ${unfinishedEntries.join(', ')}')
            log('  Scripted (${scriptedEntryIds.length}): ${scriptedEntryClassNames.join(', ')}')
            log('  Unscripted (${unscriptedEntryIds.length}): ${unscriptedEntryIds.join(', ')}')
            log('  Entries (${countEntries()}): ${entries.keys().array().join(', ')}')
           */
        }
      }
    };

    // Callback when one task completes with failure
    var onError:({error:Any, entryCls:Null<String>, entryId:Null<String>}) -> Void = (state) ->
    {
      entryErrors.push({
        entryId: state.entryId,
        entryCls: state.entryCls,
        error: state.error
      });
      log('  Failed to load entry data: ${state.entryId} (${state.entryCls}): ${state.error}');
      checkComplete();
    };

    // Callback when one task completes with success
    var onScriptedEntryLoadedAsync:({entryId:String, entry:T, entryCls:String}) -> Void = (state) ->
    {
      onScriptedEntryLoaded(state.entryCls, state.entry);

      log('  Loaded scripted entry: ${state.entry.id} (${state.entryCls}) (${countEntries()}+${entryErrors.length}/${entryCount})');
      checkComplete();
    };

    // Callback when one task completes with success
    var onUnscriptedEntryLoadedAsync:(
      {entryId:String, entry:T}) -> Void = (state) ->
      {
        onUnscriptedEntryLoaded(state.entry);
        log('  Loaded unscripted entry: ${state.entryId} (${countEntries()}+${entryErrors.length}/${entryCount})');
        checkComplete();
      };

    // Task to perform for each scripted entry
    var performScriptedEntryLoad:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      try
      {
        var entry:Null<T> = funkin.util.tasks.ScriptLock.run(() -> createScriptedEntry(currentState.entryCls));

        if (entry != null)
        {
          // log('Successfully created scripted entry (${currentState.entryCls} = ${entry.id})')
          workOutput.sendComplete({
            entryId: entry.id,
            entryCls: currentState.entryCls,
            entry: entry
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryCls: currentState.entryCls,
            error: 'Failed to create scripted entry (${currentState.entryCls})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryCls: currentState.entryCls,
          error: e,
        });
      }
    };

    // Task to perform for each unscripted entry
    var performUnscriptedEntryLoad:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      try
      {
        var entry:Null<T> = createEntry(currentState.entryId);
        if (entry != null)
        {
          // log('Successfully created unscripted entry (${entry.id})')
          workOutput.sendComplete({
            entryId: entry.id,
            entry: entry
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryId: currentState.entryId,
            error: 'Failed to create entry (${currentState.entryId})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryId: currentState.entryId,
          error: e
        });
      }
    }

    // Start loading unscripted entries.
    startUnscriptedEntries = () ->
    {
      var tallyUnscriptedEntriesFuture = TaskHandler.performSimpleTask(() ->
      {
        // Asynchronously tally up the unscripted entries to load,
        // then queue the tasks on the main thread in onComplete,
        // because you can't add tasks from another thread.
        var entryIdList:Array<String> = fetchEntryIdsFromFiles();
        log('  Found ${entryIdList.length} entry files, ${entries.size()} entries already loaded...');
        unscriptedEntryIds = entryIdList.filter((entryId) ->
        {
          return !entries.exists(entryId);
        });

        entryCount = scriptedEntryClassNames.length + unscriptedEntryIds.length;

        return true;
      });

      tallyUnscriptedEntriesFuture.onError(onError);
      tallyUnscriptedEntriesFuture.onComplete((_) ->
      {
        if (unscriptedEntryIds.length == 0)
        {
          checkComplete();
        }
        else
        {
          // TODO: Is it better to make one Future that loads them one at a time,
          // or X futures which each load one entry?
          for (entryId in unscriptedEntryIds)
          {
            var unscriptedEntryFuture = TaskHandler.performTask({
              task: performUnscriptedEntryLoad,
              initialState: {
                entryId: entryId
              }
            }, new lime.app.Promise<
              {entryId:String, entry:T}>());

            unscriptedEntryFuture.onError(onError);
            unscriptedEntryFuture.onComplete(onUnscriptedEntryLoadedAsync);
          }
        }
      });
    }

    // Tally up scripted entries.
    var tallyScriptedEntriesFuture = TaskHandler.performSimpleTask(() ->
    {
      // Asynchronously tally up the scripted entries to load,
      // then queue the tasks on the main thread in onComplete,
      // because you can't add tasks from another thread.

      scriptedEntryClassNames = getScriptedClassNames();

      log('Queuing loading for ${scriptedEntryClassNames.length} scripted entries...');

      entryCount = scriptedEntryClassNames.length;

      return true;
    });

    // Queue loading of scripted entries.
    tallyScriptedEntriesFuture.onError(onError);
    tallyScriptedEntriesFuture.onComplete((_) ->
    {
      // NOTE: onComplete() is run in the main thread.
      if (scriptedEntryClassNames.length == 0)
      {
        // If no scripted entries, start loading unscripted entries.
        checkComplete();
      }
      else
      {
        // TODO: Is it better to make one Future that loads them one at a time,
        // or X futures which each load one entry?
        for (entryCls in scriptedEntryClassNames)
        {
          var scriptedEntryFuture = TaskHandler.performTask({
            task: performScriptedEntryLoad,
            initialState: {
              entryCls: entryCls
            },
          }, new lime.app.Promise<
            {entryId:String, entry:T, entryCls:String}>());

          scriptedEntryFuture.onError(onError);
          scriptedEntryFuture.onComplete(onScriptedEntryLoadedAsync);
        }
      }
    });

    return promise.future;
  }
  #end

  /**
   * Retrieve a list of all entry IDs in this registry.
   * @return The list of entry IDs.
   */
  public function listEntryIds():Array<String>
  {
    return entries.keys().array();
  }

  /**
   * Retrieve a list of all entry IDs available in the data directory.
   */
  function fetchEntryIdsFromFiles():Array<String>
  {
    return funkin.modding.compat.RegistryData.listEntryIds(dataFilePath, nestedEntries);
  }

  /**
   * Count the number of entries in this registry.
   * @return The number of entries.
   */
  public function countEntries():Int
  {
    return entries.size();
  }

  /**
   * Query assets needed by the REGISTRY ITSELF, usually for parsing entry data.
   *
   * @param type The type of asset to query.
   * @return The list of asset paths.
   */
  public function queryRegistryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    switch (type)
    {
      case JSON:
        return funkin.modding.compat.RegistryData.listAssetPaths(dataFilePath).filterNull();
      default:
        return [];
    }
  }

  /**
   * Return whether the entry ID is known to have an attached script.
   * @param id The ID of the entry.
   * @return `true` if the entry has an attached script, `false` otherwise.
   */
  public function isScriptedEntry(id:String, ?params:P):Bool
  {
    return scriptedEntryIds.exists(id);
  }

  /**
   * Return the class name of the scripted entry with the given ID, if it exists.
   * @param id The ID of the entry.
   * @return The class name, or `null` if it does not exist.
   */
  public function getScriptedEntryClassName(id:String, ?params:P):Null<String>
  {
    return scriptedEntryIds.get(id);
  }

  /**
   * Return whether the registry has successfully parsed an entry with the given ID.
   * @param id The ID of the entry.
   * @return `true` if the entry exists, `false` otherwise.
   */
  public function hasEntry(id:String):Bool
  {
    return entries.exists(id);
  }

  /**
   * Fetch an entry by its ID.
   * @param id The ID of the entry to fetch.
   * @return The entry, or `null` if it does not exist.
   */
  public function fetchEntry(id:String, ?params:P):Null<T>
  {
    var result:Null<T> = entries.get(id);
    if (result == null)
    {
      log(' ERROR '.warning() + 'Failed to fetch registry entry $id(${params})');
    }
    return result;
  }

  /**
   * A list of all entries included in the base game.
   * The actual function exists and is auto-generated on each registry at build time.
   * @return Array<String>
   */
  // public function listBaseGameEntryIds():Array<String> {}

  /**
   * A list of all entries that are not included in the base game.
   * @return Array<String>
   */
  // public function listModdedEntryIds():Array<String> {}

  public function toString():String
  {
    return 'Registry(' + registryId + ', ${countEntries()} entries)';
  }

  /**
   * Retrieve the data for an entry and parse its Semantic Version.
   * @param id The ID of the entry.
   * @return The entry's version, or `null` if it does not exist or is invalid.
   */
  public function fetchEntryVersion(id:String):Null<thx.semver.Version>
  {
    var entryStr:String = loadEntryFile(id).contents;
    var entryVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  function log(message:String):Void
  {
    trace(' $registryId '.bold().bg_note_down() + ' $message');
  }

  function loadEntryFile(id:String):JsonFile
  {
    try
    {
      return funkin.modding.compat.RegistryData.loadEntryData(id, '', dataFilePath, nestedEntries);
    }
    catch (e)
    {
      log(' WARNING '.bold().bg_yellow() + ' Could not locate entry $id');
      log(' WARNING '.bold().bg_yellow() + '   $e');
      throw e;
    }
  }

  function clearEntries():Void
  {
    log('Destroying ${countEntries()} entries in registry...');

    for (entry in entries)
    {
      entry.destroy();
    }

    entries.clear();
    scriptedEntryIds.clear();
  }

  //
  // FUNCTIONS TO IMPLEMENT
  //

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param id The ID of the entry.
   * @return The created entry.
   */
  public abstract function parseEntryData(id:String):Null<J>;

  /**
   * Parse and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param contents The JSON as a string.
   * @param fileName An optional file name for error reporting.
   * @return The created entry.
   */
  public abstract function parseEntryDataRaw(contents:String, ?fileName:String):Null<J>;

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object,
   * accounting for old versions of the data.
   *
   * NOTE: Extend this function to handle migration.
   * @param id The ID of the entry.
   * @param version The entry's version (use `fetchEntryVersion(id)`).
   * @return The created entry.
   */
  public function parseEntryDataWithMigration(id:String,
    version:Null<thx.semver.Version>):Null<J>
  {
    if (version == null)
    {
      throw '[${registryId}] Entry ${id} could not be JSON-parsed or does not have a parseable version.';
    }

    // If a version rule is not specified, do not check against it.
    if (versionRule == null || VersionUtil.validateVersion(version, versionRule))
    {
      return parseEntryData(id);
    }
    else
    {
      throw '[${registryId}] Entry ${id} does not support migration to version ${versionRule}.';
    }

    /*
     * An example of what you should override this with:
     *
     * ```haxe
     * if (VersionUtil.validateVersion(version, "0.1.x")) {
     *   return parseEntryData_v0_1_x(id);
     * } else {
     *   super.parseEntryDataWithMigration(id, version);
     * }
     * ```
     */
  }

  /**
   * Retrieve the list of scripted class names to load.
   * @return An array of scripted class names.
   */
  abstract function getScriptedClassNames():Array<String>;

  /**
   * Create an entry from the given ID.
   * @param id
   */
  function createEntry(id:String):Null<T>
  {
    // We enforce that T is Constructible to ensure this is valid.
    return new T(id);
  }

  /**
   * Create a entry, attached to a scripted class, from the given class name.
   * @param clsName
   */
  function createScriptedEntry(clsName:String):Null<T>
  {
    throw 'createScriptedEntry() not implemented for registry: ${registryId}';
  }

  function printErrors(errors:Array<json2object.Error>,
    id:String = ''):Void
  {
    log(' ERROR '.error() + 'Failed to parse entry data: ${id}');

    for (error in errors)
    {
      DataError.printError(error);
    }
  }
}

/**
 * The result of attempting to load all the registry's entries.
 */
typedef LoadEntriesResult =
{
  /**
   * The number of entries with successfully loaded.
   */
  var entriesLoaded:Int;

  /**
   * The number of entries with successfully loaded.
   */
  var entriesFailed:Int;
};
