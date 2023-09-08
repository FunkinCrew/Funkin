package funkin.data;

import openfl.Assets;
import funkin.util.assets.DataAssets;
import funkin.util.VersionUtil;
import haxe.Constraints.Constructible;
import json2object.Position;
import json2object.Position.Line;
import json2object.Error;

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

  /**
   * The version rule to use when loading entries.
   * If the entry's version does not match this rule, migration is needed.
   */
  final versionRule:thx.semver.VersionRule;

  // public abstract static final instance:BaseRegistry<T, J> = new BaseRegistry<>();

  /**
   * @param registryId A readable ID for this registry, used when logging.
   * @param dataFilePath The path (relative to `assets/data`) to search for JSON files.
   */
  public function new(registryId:String, dataFilePath:String, versionRule:thx.semver.VersionRule = null)
  {
    this.registryId = registryId;
    this.dataFilePath = dataFilePath;
    this.versionRule = versionRule == null ? "1.0.x" : versionRule;

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
        // Print the error.
        trace('  Failed to load entry data: ${entryId}');
        trace(e);
        continue;
      }
    }
  }

  /**
   * Retrieve a list of all entry IDs in this registry.
   * @return The list of entry IDs.
   */
  public function listEntryIds():Array<String>
  {
    return entries.keys().array();
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
   * Fetch an entry by its ID.
   * @param id The ID of the entry to fetch.
   * @return The entry, or `null` if it does not exist.
   */
  public function fetchEntry(id:String):Null<T>
  {
    return entries.get(id);
  }

  public function toString():String
  {
    return 'Registry(' + registryId + ', ${countEntries()} entries)';
  }

  public function fetchEntryVersion(id:String):Null<thx.semver.Version>
  {
    var entryStr:String = loadEntryFile(id).contents;
    var entryVersion:thx.semver.Version = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  function log(message:String):Void
  {
    trace('[' + registryId + '] ' + message);
  }

  function loadEntryFile(id:String):JsonFile
  {
    var entryFilePath:String = Paths.json('${dataFilePath}/${id}');
    var rawJson:String = openfl.Assets.getText(entryFilePath).trim();
    return {
      fileName: entryFilePath,
      contents: rawJson
    };
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
   * NOTE: Must be implemented on the implementation class.
   */
  public abstract function parseEntryData(id:String):Null<J>;

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object,
   * accounting for old versions of the data.
   *
   * NOTE: Extend this function to handle migration.
   */
  public function parseEntryDataWithMigration(id:String, version:thx.semver.Version):Null<J>
  {
    // If a version rule is not specified, do not check against it.
    if (versionRule == null || VersionUtil.validateVersion(version, versionRule))
    {
      return parseEntryData(id);
    }
    else
    {
      throw '[${registryId}] Entry ${id} does not support migration to version ${versionRule}.';
    }

    // Example:
    // if (VersionUtil.validateVersion(version, "0.1.x")) {
    //   return parseEntryData_v0_1_x(id);
    // } else {
    //   super.parseEntryDataWithMigration(id, version);
    // }
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
    return new T(id);
  }

  /**
   * Create a entry, attached to a scripted class, from the given class name.
   * @param clsName
   */
  abstract function createScriptedEntry(clsName:String):Null<T>;

  function printErrors(errors:Array<Error>, id:String = ''):Void
  {
    trace('[${registryId}] Failed to parse entry data: ${id}');

    for (error in errors)
      printError(error);
  }

  function printError(error:Error):Void
  {
    switch (error)
    {
      case IncorrectType(vari, expected, pos):
        trace('  Expected field "$vari" to be of type "$expected".');
        printPos(pos);
      case IncorrectEnumValue(value, expected, pos):
        trace('  Invalid enum value (expected "$expected", got "$value")');
        printPos(pos);
      case InvalidEnumConstructor(value, expected, pos):
        trace('  Invalid enum constructor (epxected "$expected", got "$value")');
        printPos(pos);
      case UninitializedVariable(vari, pos):
        trace('  Uninitialized variable "$vari"');
        printPos(pos);
      case UnknownVariable(vari, pos):
        trace('  Unknown variable "$vari"');
        printPos(pos);
      case ParserError(message, pos):
        trace('  Parsing error: ${message}');
        printPos(pos);
      case CustomFunctionException(e, pos):
        if (Std.isOfType(e, String))
        {
          trace('  ${e}');
        }
        else
        {
          printUnknownError(e);
        }
        printPos(pos);
      default:
        printUnknownError(error);
    }
  }

  function printUnknownError(e:Dynamic):Void
  {
    switch (Type.typeof(e))
    {
      case TClass(c):
        trace('  [${Type.getClassName(c)}] ${e.toString()}');
      case TEnum(c):
        trace('  [${Type.getEnumName(c)}] ${e.toString()}');
      default:
        trace('  [${Type.typeof(e)}] ${e.toString()}');
    }
  }

  /**
   * TODO: Figure out the nicest way to print this.
   * Maybe look up how other JSON parsers format their errors?
   * @see https://github.com/elnabo/json2object/blob/master/src/json2object/Position.hx
   */
  function printPos(pos:Position):Void
  {
    if (pos.lines[0].number == pos.lines[pos.lines.length - 1].number)
    {
      trace('    at ${(pos.file == '') ? 'line ' : '${pos.file}:'}${pos.lines[0].number}');
    }
    else
    {
      trace('    at ${(pos.file == '') ? 'line ' : '${pos.file}:'}${pos.lines[0].number}-${pos.lines[pos.lines.length - 1].number}');
    }
  }
}

typedef JsonFile =
{
  fileName:String,
  contents:String
};
