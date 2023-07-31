package funkin.modding;

import funkin.util.macro.ClassMacro;
import funkin.modding.module.ModuleHandler;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.song.SongData;
import funkin.play.stage.StageData;
import polymod.Polymod;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.TextFileFormat;
import funkin.play.event.SongEventData.SongEventParser;
import funkin.util.FileUtil;
import funkin.data.level.LevelRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.cutscene.dialogue.ConversationDataParser;
import funkin.play.cutscene.dialogue.DialogueBoxDataParser;
import funkin.play.cutscene.dialogue.SpeakerDataParser;

class PolymodHandler
{
  /**
   * The API version that mods should comply with.
   * Format this with Semantic Versioning; <MAJOR>.<MINOR>.<PATCH>.
   * Bug fixes increment the patch version, new features increment the minor version.
   * Changes that break old mods increment the major version.
   */
  static final API_VERSION = "0.1.0";

  /**
   * Where relative to the executable that mods are located.
   */
  static final MOD_FOLDER:String = #if (REDIRECT_ASSETS_FOLDER && macos) "../../../../../../../example_mods" #elseif REDIRECT_ASSETS_FOLDER "../../../../example_mods" #else "mods" #end;

  static final CORE_FOLDER:Null<String> = #if (REDIRECT_ASSETS_FOLDER && macos) "../../../../../../../assets" #elseif REDIRECT_ASSETS_FOLDER "../../../../assets" #else null #end;

  public static function createModRoot()
  {
    FileUtil.createDirIfNotExists(MOD_FOLDER);
  }

  /**
   * Loads the game with ALL mods enabled with Polymod.
   */
  public static function loadAllMods()
  {
    // Create the mod root if it doesn't exist.
    createModRoot();
    trace("Initializing Polymod (using all mods)...");
    loadModsById(getAllModIds());
  }

  /**
   * Loads the game with configured mods enabled with Polymod.
   */
  public static function loadEnabledMods()
  {
    // Create the mod root if it doesn't exist.
    createModRoot();

    trace("Initializing Polymod (using configured mods)...");
    loadModsById(getEnabledModIds());
  }

  /**
   * Loads the game without any mods enabled with Polymod.
   */
  public static function loadNoMods()
  {
    // Create the mod root if it doesn't exist.
    createModRoot();

    // We still need to configure the debug print calls etc.
    trace("Initializing Polymod (using no mods)...");
    loadModsById([]);
  }

  public static function loadModsById(ids:Array<String>)
  {
    if (ids.length == 0)
    {
      trace('You attempted to load zero mods.');
    }
    else
    {
      trace('Attempting to load ${ids.length} mods...');
    }

    buildImports();

    var loadedModList = polymod.Polymod.init(
      {
        // Root directory for all mods.
        modRoot: MOD_FOLDER,
        // The directories for one or more mods to load.
        dirs: ids,
        // Framework being used to load assets.
        framework: OPENFL,
        // The current version of our API.
        apiVersionRule: API_VERSION,
        // Call this function any time an error occurs.
        errorCallback: PolymodErrorHandler.onPolymodError,
        // Enforce semantic version patterns for each mod.
        // modVersions: null,
        // A map telling Polymod what the asset type is for unfamiliar file extensions.
        // extensionMap: [],

        frameworkParams: buildFrameworkParams(),

        // List of filenames to ignore in mods. Use the default list to ignore the metadata file, etc.
        ignoredFiles: Polymod.getDefaultIgnoreList(),

        // Parsing rules for various data formats.
        parseRules: buildParseRules(),

        // Parse hxc files and register the scripted classes in them.
        useScriptedClasses: true,
      });

    if (loadedModList == null)
    {
      trace('An error occurred! Failed when loading mods!');
    }
    else
    {
      if (loadedModList.length == 0)
      {
        trace('Mod loading complete. We loaded no mods / ${ids.length} mods.');
      }
      else
      {
        trace('Mod loading complete. We loaded ${loadedModList.length} / ${ids.length} mods.');
      }
    }

    for (mod in loadedModList)
    {
      trace('  * ${mod.title} v${mod.modVersion} [${mod.id}]');
    }

    #if debug
    var fileList = Polymod.listModFiles(PolymodAssetType.IMAGE);
    trace('Installed mods have replaced ${fileList.length} images.');
    for (item in fileList)
      trace('  * $item');

    fileList = Polymod.listModFiles(PolymodAssetType.TEXT);
    trace('Installed mods have added/replaced ${fileList.length} text files.');
    for (item in fileList)
      trace('  * $item');

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_MUSIC);
    trace('Installed mods have replaced ${fileList.length} music files.');
    for (item in fileList)
      trace('  * $item');

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_SOUND);
    trace('Installed mods have replaced ${fileList.length} sound files.');
    for (item in fileList)
      trace('  * $item');

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_GENERIC);
    trace('Installed mods have replaced ${fileList.length} generic audio files.');
    for (item in fileList)
      trace('  * $item');
    #end
  }

  static function buildImports():Void
  {
    // Add default imports for common classes.

    // Add import aliases for certain classes.
    // NOTE: Scripted classes are automatically aliased to their parent class.
    Polymod.addImportAlias('flixel.math.FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
    Polymod.addImportAlias('flixel.system.FlxSound', flixel.sound.FlxSound);

    // Add blacklisting for prohibited classes and packages.
    // `polymod.*`
    for (cls in ClassMacro.listClassesInPackage('polymod'))
    {
      if (cls == null) continue;
      var className = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }
  }

  static function buildParseRules():polymod.format.ParseRules
  {
    var output = polymod.format.ParseRules.getDefault();
    // Ensure TXT files have merge support.
    output.addType("txt", TextFileFormat.LINES);
    // Ensure script files have merge support.
    output.addType("hscript", TextFileFormat.PLAINTEXT);
    output.addType("hxs", TextFileFormat.PLAINTEXT);
    output.addType("hxc", TextFileFormat.PLAINTEXT);
    output.addType("hx", TextFileFormat.PLAINTEXT);

    // You can specify the format of a specific file, with file extension.
    // output.addFile("data/introText.txt", TextFileFormat.LINES)
    return output;
  }

  static inline function buildFrameworkParams():polymod.Polymod.FrameworkParams
  {
    return {
      assetLibraryPaths: [
        "default" => "preload", "shared" => "", "songs" => "songs", "tutorial" => "tutorial", "week1" => "week1", "week2" => "week2", "week3" => "week3",
        "week4" => "week4", "week5" => "week5", "week6" => "week6", "week7" => "week7", "weekend1" => "weekend1",
      ],
      coreAssetRedirect: CORE_FOLDER,
    }
  }

  public static function getAllMods():Array<ModMetadata>
  {
    trace('Scanning the mods folder...');
    var modMetadata = Polymod.scan(
      {
        modRoot: MOD_FOLDER,
        apiVersionRule: API_VERSION,
        errorCallback: PolymodErrorHandler.onPolymodError
      });
    trace('Found ${modMetadata.length} mods when scanning.');
    return modMetadata;
  }

  public static function getAllModIds():Array<String>
  {
    var modIds = [for (i in getAllMods()) i.id];
    return modIds;
  }

  public static function setEnabledMods(newModList:Array<String>):Void
  {
    FlxG.save.data.enabledMods = newModList;
    // Make sure to COMMIT the changes.
    FlxG.save.flush();
  }

  /**
   * Returns the list of enabled mods.
   * @return Array<String>
   */
  public static function getEnabledModIds():Array<String>
  {
    if (FlxG.save.data.enabledMods == null)
    {
      // NOTE: If the value is null, the enabled mod list is unconfigured.
      // Currently, we default to disabling newly installed mods.
      // If we want to auto-enable new mods, but otherwise leave the configured list in place,
      // we will need some custom logic.
      FlxG.save.data.enabledMods = [];
    }
    return FlxG.save.data.enabledMods;
  }

  public static function getEnabledMods():Array<ModMetadata>
  {
    var modIds = getEnabledModIds();
    var modMetadata = getAllMods();
    var enabledMods = [];
    for (item in modMetadata)
    {
      if (modIds.indexOf(item.id) != -1)
      {
        enabledMods.push(item);
      }
    }
    return enabledMods;
  }

  public static function forceReloadAssets()
  {
    // Forcibly clear scripts so that scripts can be edited.
    ModuleHandler.clearModuleCache();
    Polymod.clearScripts();

    // Forcibly reload Polymod so it finds any new files.
    // TODO: Replace this with loadEnabledMods().
    funkin.modding.PolymodHandler.loadAllMods();

    // Reload scripted classes so stages and modules will update.
    Polymod.registerAllScriptClasses();

    // Reload everything that is cached.
    // Currently this freezes the game for a second but I guess that's tolerable?

    // TODO: Reload event callbacks

    // These MUST be imported at the top of the file and not referred to by fully qualified name,
    // to ensure build macros work properly.
    LevelRegistry.instance.loadEntries();
    NoteStyleRegistry.instance.loadEntries();
    SongEventParser.loadEventCache();
    ConversationDataParser.loadConversationCache();
    DialogueBoxDataParser.loadDialogueBoxCache();
    SpeakerDataParser.loadSpeakerCache();
    SongDataParser.loadSongCache();
    StageDataParser.loadStageCache();
    CharacterDataParser.loadCharacterCache();
    ModuleHandler.loadModuleCache();
  }
}
