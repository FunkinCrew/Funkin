package funkin.data;

import openfl.Assets;
import funkin.util.assets.DataAssets;
import haxe.Constraints.Constructible;

/**
 * The entry's constructor function must take a single argument, the entry's ID.
 */
typedef EntryConstructorFunction = String->Void;

/**
 * A base type for a Registry, which is an object which handles loading scriptable objects.
 *
 * @param T The type to construct. Must implement `IRegistryEntry`.
 * @param J The type of the JSON data used when constructing.
 */
@:generic
abstract class BaseRegistry<T:(IRegistryEntry<J> & Constructible<EntryConstructorFunction>), J>
{
  public final registryId:String;

  final dataFilePath:String;

  final entries:Map<String, T>;

  // public abstract static final instance:BaseRegistry<T, J> = new BaseRegistry<>();

  /**
   * @param registryId A readable ID for this registry, used when logging.
   * @param dataFilePath The path (relative to `assets/data`) to search for JSON files.
   */
  public function new(registryId:String, dataFilePath:String)
  {
    this.registryId = registryId;
    this.dataFilePath = dataFilePath;

    this.entries = new Map<String, T>();
  }

  public function loadEntries():Void
  {
    clearEntries();

    //
    // SCRIPTED ENTRIES
    //
    var scriptedEntryClassNames:Array<String> = getScriptedClassNames();
    log('Registering ${scriptedEntryClassNames.length} scripted entries...');

    for (entryCls in scriptedEntryClassNames)
    {
      var entry:T = createScriptedEntry(entryCls);

      if (entry != null)
      {
        log('Successfully created scripted entry (${entryCls} = ${entry.id})');
        entries.set(entry.id, entry);
      }
      else
      {
        log('Failed to create scripted entry (${entryCls})');
      }
    }

    //
    // UNSCRIPTED ENTRIES
    //
    var entryIdList:Array<String> = DataAssets.listDataFilesInPath('${dataFilePath}/');
    var unscriptedEntryIds:Array<String> = entryIdList.filter(function(entryId:String):Bool {
      return !entries.exists(entryId);
    });
    log('Fetching data for ${unscriptedEntryIds.length} unscripted entries...');
    for (entryId in unscriptedEntryIds)
    {
      try
      {
        var entry:T = createEntry(entryId);
        if (entry != null)
        {
          trace('  Loaded entry data: ${entry}');
          entries.set(entry.id, entry);
        }
      }
      catch (e:Dynamic)
      {
        trace('  Failed to load entry data: ${entryId}');
        trace(e);
        continue;
      }
    }
  }

  public function listEntryIds():Array<String>
  {
    return entries.keys().array();
  }

  public function countEntries():Int
  {
    return entries.size();
  }

  public function fetchEntry(id:String):Null<T>
  {
    return entries.get(id);
  }

  public function toString():String
  {
    return 'Registry(' + registryId + ', ${countEntries()} entries)';
  }

  function log(message:String):Void
  {
    trace('[' + registryId + '] ' + message);
  }

  function loadEntryFile(id:String):String
  {
    var entryFilePath:String = Paths.json('${dataFilePath}/${id}');
    var rawJson:String = openfl.Assets.getText(entryFilePath).trim();
    return rawJson;
  }

  function clearEntries():Void
  {
    for (entry in entries)
    {
      entry.destroy();
    }

    entries.clear();
  }

  //
  // FUNCTIONS TO IMPLEMENT
  //

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class annd
   */
  public abstract function parseEntryData(id:String):Null<J>;

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
    return new T(id);
  }

  /**
   * Create a entry, attached to a scripted class, from the given class name.
   * @param clsName
   */
  abstract function createScriptedEntry(clsName:String):Null<T>;
}
