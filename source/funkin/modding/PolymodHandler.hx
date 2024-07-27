package funkin.modding;

import polymod.fs.ZipFileSystem;
import funkin.data.dialogue.conversation.ConversationRegistry;
import funkin.data.dialogue.dialoguebox.DialogueBoxRegistry;
import funkin.data.dialogue.speaker.SpeakerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.modding.module.ModuleHandler;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.save.Save;
import funkin.util.FileUtil;
import funkin.util.macro.ClassMacro;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.TextFileFormat;
import polymod.Polymod;

/**
 * A class for interacting with Polymod, the atomic modding framework for Haxe.
 */
class PolymodHandler
{
  /**
   * The API version that mods should comply with.
   * Format this with Semantic Versioning; <MAJOR>.<MINOR>.<PATCH>.
   * Bug fixes increment the patch version, new features increment the minor version.
   * Changes that break old mods increment the major version.
   */
  static final API_VERSION:String = '0.1.0';

  /**
   * Where relative to the executable that mods are located.
   */
  static final MOD_FOLDER:String =
    #if (REDIRECT_ASSETS_FOLDER && macos)
    '../../../../../../../example_mods'
    #elseif REDIRECT_ASSETS_FOLDER
    '../../../../example_mods'
    #else
    'mods'
    #end;

  static final CORE_FOLDER:Null<String> =
    #if (REDIRECT_ASSETS_FOLDER && macos)
    '../../../../../../../assets'
    #elseif REDIRECT_ASSETS_FOLDER
    '../../../../assets'
    #else
    null
    #end;

  public static var loadedModIds:Array<String> = [];

  // Use SysZipFileSystem on desktop and MemoryZipFilesystem on web.
  static var modFileSystem:Null<ZipFileSystem> = null;

  /**
   * If the mods folder doesn't exist, create it.
   */
  public static function createModRoot():Void
  {
    FileUtil.createDirIfNotExists(MOD_FOLDER);
  }

  /**
   * Loads the game with ALL mods enabled with Polymod.
   */
  public static function loadAllMods():Void
  {
    // Create the mod root if it doesn't exist.
    createModRoot();
    trace('Initializing Polymod (using all mods)...');
    loadModsById(getAllModIds());
  }

  /**
   * Loads the game with configured mods enabled with Polymod.
   */
  public static function loadEnabledMods():Void
  {
    // Create the mod root if it doesn't exist.
    createModRoot();

    trace('Initializing Polymod (using configured mods)...');
    loadModsById(Save.instance.enabledModIds);
  }

  /**
   * Loads the game without any mods enabled with Polymod.
   */
  public static function loadNoMods():Void
  {
    // Create the mod root if it doesn't exist.
    createModRoot();

    // We still need to configure the debug print calls etc.
    trace('Initializing Polymod (using no mods)...');
    loadModsById([]);
  }

  /**
   * Load all the mods with the given ids.
   * @param ids The ORDERED list of mod ids to load.
   */
  public static function loadModsById(ids:Array<String>):Void
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

    if (modFileSystem == null) modFileSystem = buildFileSystem();

    var loadedModList:Array<ModMetadata> = polymod.Polymod.init(
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

        customFilesystem: modFileSystem,

        frameworkParams: buildFrameworkParams(),

        // List of filenames to ignore in mods. Use the default list to ignore the metadata file, etc.
        ignoredFiles: Polymod.getDefaultIgnoreList(),

        // Parsing rules for various data formats.
        parseRules: buildParseRules(),

        // Parse hxc files and register the scripted classes in them.
        useScriptedClasses: true,
        loadScriptsAsync: #if html5 true #else false #end,
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

    loadedModIds = [];
    for (mod in loadedModList)
    {
      trace('  * ${mod.title} v${mod.modVersion} [${mod.id}]');
      loadedModIds.push(mod.id);
    }

    #if debug
    var fileList:Array<String> = Polymod.listModFiles(PolymodAssetType.IMAGE);
    trace('Installed mods have replaced ${fileList.length} images.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.TEXT);
    trace('Installed mods have added/replaced ${fileList.length} text files.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_MUSIC);
    trace('Installed mods have replaced ${fileList.length} music files.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_SOUND);
    trace('Installed mods have replaced ${fileList.length} sound files.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_GENERIC);
    trace('Installed mods have replaced ${fileList.length} generic audio files.');
    for (item in fileList)
    {
      trace('  * $item');
    }
    #end
  }

  static function buildFileSystem():polymod.fs.ZipFileSystem
  {
    polymod.Polymod.onError = PolymodErrorHandler.onPolymodError;
    return new ZipFileSystem(
      {
        modRoot: MOD_FOLDER,
        autoScan: true
      });
  }

  static function buildImports():Void
  {
    // Add default imports for common classes.

    // Add import aliases for certain classes.
    // NOTE: Scripted classes are automatically aliased to their parent class.

    Polymod.addImportAlias('flixel.math.FlxPoint', flixel.math.FlxPoint.FlxBasePoint);

    Polymod.addImportAlias('funkin.util.FileUtil', funkin.util.FileUtil.FileUtilSandboxed);

    // Add blacklisting for prohibited classes and packages.

    // `Sys`
    // Sys.command() can run malicious processes
    Polymod.blacklistImport('Sys');

    // `Reflect`
    // Reflect.callMethod() can access blacklisted packages
    Polymod.blacklistImport('Reflect');

    // `Type`
    // Type.createInstance(Type.resolveClass()) can access blacklisted packages
    Polymod.blacklistImport('Type');

    // `cpp.Lib`
    // Lib.load() can load malicious DLLs
    Polymod.blacklistImport('cpp.Lib');

    // `polymod.*`
    // You can probably unblacklist a module
    for (cls in ClassMacro.listClassesInPackage('polymod'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `sys.*`
    for (cls in ClassMacro.listClassesInPackage('sys'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }
  }

  static function buildParseRules():polymod.format.ParseRules
  {
    var output:polymod.format.ParseRules = polymod.format.ParseRules.getDefault();
    // Ensure TXT files have merge support.
    output.addType('txt', TextFileFormat.LINES);
    // Ensure script files have merge support.
    output.addType('hscript', TextFileFormat.PLAINTEXT);
    output.addType('hxs', TextFileFormat.PLAINTEXT);
    output.addType('hxc', TextFileFormat.PLAINTEXT);
    output.addType('hx', TextFileFormat.PLAINTEXT);

    // You can specify the format of a specific file, with file extension.
    // output.addFile("data/introText.txt", TextFileFormat.LINES)
    return output;
  }

  static inline function buildFrameworkParams():polymod.Polymod.FrameworkParams
  {
    return {
      assetLibraryPaths: [
        'default' => 'preload', 'shared' => 'shared', 'songs' => 'songs', 'videos' => 'videos', 'tutorial' => 'tutorial', 'week1' => 'week1',
        'week2' => 'week2', 'week3' => 'week3', 'week4' => 'week4', 'week5' => 'week5', 'week6' => 'week6', 'week7' => 'week7', 'weekend1' => 'weekend1',
      ],
      coreAssetRedirect: CORE_FOLDER,
    }
  }

  /**
   * Retrieve a list of metadata for ALL installed mods, including disabled mods.
   * @return An array of mod metadata
   */
  public static function getAllMods():Array<ModMetadata>
  {
    trace('Scanning the mods folder...');

    if (modFileSystem == null) modFileSystem = buildFileSystem();

    var modMetadata:Array<ModMetadata> = Polymod.scan(
      {
        modRoot: MOD_FOLDER,
        apiVersionRule: API_VERSION,
        fileSystem: modFileSystem,
        errorCallback: PolymodErrorHandler.onPolymodError
      });
    trace('Found ${modMetadata.length} mods when scanning.');
    return modMetadata;
  }

  /**
   * Retrieve a list of ALL mod IDs, including disabled mods.
   * @return An array of mod IDs
   */
  public static function getAllModIds():Array<String>
  {
    var modIds:Array<String> = [for (i in getAllMods()) i.id];
    return modIds;
  }

  /**
   * Retrieve a list of metadata for all enabled mods.
   * @return An array of mod metadata
   */
  public static function getEnabledMods():Array<ModMetadata>
  {
    var modIds:Array<String> = Save.instance.enabledModIds;
    var modMetadata:Array<ModMetadata> = getAllMods();
    var enabledMods:Array<ModMetadata> = [];
    for (item in modMetadata)
    {
      if (modIds.indexOf(item.id) != -1)
      {
        enabledMods.push(item);
      }
    }
    return enabledMods;
  }

  /**
   * Clear and reload from disk all data assets.
   * Useful for "hot reloading" for fast iteration!
   */
  public static function forceReloadAssets():Void
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
    SongRegistry.instance.loadEntries();
    LevelRegistry.instance.loadEntries();
    NoteStyleRegistry.instance.loadEntries();
    SongEventRegistry.loadEventCache();
    ConversationRegistry.instance.loadEntries();
    DialogueBoxRegistry.instance.loadEntries();
    SpeakerRegistry.instance.loadEntries();
    AlbumRegistry.instance.loadEntries();
    StageRegistry.instance.loadEntries();
    CharacterDataParser.loadCharacterCache(); // TODO: Migrate characters to BaseRegistry.
    ModuleHandler.loadModuleCache();
  }
}
