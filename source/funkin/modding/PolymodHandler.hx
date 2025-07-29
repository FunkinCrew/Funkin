package funkin.modding;

import polymod.fs.ZipFileSystem;
import funkin.data.dialogue.conversation.ConversationRegistry;
import funkin.data.dialogue.dialoguebox.DialogueBoxRegistry;
import funkin.data.dialogue.speaker.SpeakerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.data.song.SongRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
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
@:nullSafety
class PolymodHandler
{
  /**
   * The API version for the current version of the game. Since 0.5.0, we've just made this the game version!
   * Minor updates rarely impact mods but major versions sometimes do.
   */
  public static var API_VERSION(get, never):String;

  static function get_API_VERSION():String
  {
    return Constants.VERSION;
  }

  /**
   * The Semantic Versioning rule
   * Indicates which mods are compatible with this version of the game.
   * Using more complex rules allows mods from older compatible versions to stay functioning,
   * while preventing mods made for future versions from being installed.
   */
  public static final API_VERSION_RULE:String = ">=0.6.3 <0.8.0";

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

  // Use SysZipFileSystem on native and MemoryZipFilesystem on web.
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
    #if sys
    // Create the mod root if it doesn't exist.
    createModRoot();
    #end
    trace('Initializing Polymod (using all mods)...');
    loadModsById(getAllModIds());
  }

  /**
   * Loads the game with configured mods enabled with Polymod.
   */
  public static function loadEnabledMods():Void
  {
    #if sys
    // Create the mod root if it doesn't exist.
    createModRoot();
    #end
    trace('Initializing Polymod (using configured mods)...');
    loadModsById(Save.instance.enabledModIds);
  }

  /**
   * Loads the game without any mods enabled with Polymod.
   */
  public static function loadNoMods():Void
  {
    #if sys
    // Create the mod root if it doesn't exist.
    createModRoot();
    #end
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
        apiVersionRule: API_VERSION_RULE,
        // Call this function any time an error occurs.
        errorCallback: PolymodErrorHandler.onPolymodError,
        // Enforce semantic version patterns for each mod.
        // modVersions: null,
        // A map telling Polymod what the asset type is for unfamiliar file extensions.
        // extensionMap: [],

        customFilesystem: modFileSystem,

        frameworkParams: buildFrameworkParams(),

        // List of filenames to ignore in mods. Use the default list to ignore the metadata file, etc.
        ignoredFiles: buildIgnoreList(),

        // Parsing rules for various data formats.
        parseRules: buildParseRules(),

        skipDependencyErrors: true,

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

    #if FEATURE_DEBUG_FUNCTIONS
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
    Polymod.addDefaultImport(funkin.Assets);
    Polymod.addDefaultImport(funkin.Paths);

    // Add import aliases for certain classes.
    // NOTE: Scripted classes are automatically aliased to their parent class.
    Polymod.addImportAlias('flixel.math.FlxPoint', flixel.math.FlxPoint.FlxBasePoint);

    Polymod.addImportAlias('funkin.data.event.SongEventSchema', funkin.data.event.SongEventSchema.SongEventSchemaRaw);

    // `lime.utils.Assets` literally just has a private `resolveClass` function for some reason? so we replace it with our own.
    Polymod.addImportAlias('lime.utils.Assets', funkin.Assets);
    Polymod.addImportAlias('openfl.utils.Assets', funkin.Assets);

    // Backward compatibility for certain scripted classes outside `funkin.modding.base`.
    Polymod.addImportAlias('funkin.modding.base.ScriptedFunkinSprite', funkin.graphics.ScriptedFunkinSprite);
    Polymod.addImportAlias('funkin.modding.base.ScriptedMusicBeatState', funkin.ui.ScriptedMusicBeatState);
    Polymod.addImportAlias('funkin.modding.base.ScriptedMusicBeatSubState', funkin.ui.ScriptedMusicBeatSubState);

    // `funkin.util.FileUtil` has unrestricted access to the file system.
    Polymod.addImportAlias('funkin.util.FileUtil', funkin.util.FileUtilSandboxed);

    #if FEATURE_NEWGROUNDS
    // `funkin.api.newgrounds.Leaderboards` allows for submitting cheated scores.
    // We still grant read-only access.
    Polymod.addImportAlias('funkin.api.newgrounds.Leaderboards', funkin.api.newgrounds.Leaderboards.LeaderboardsSandboxed);

    // `funkin.api.newgrounds.Medals` allows for unfair granting of medals.
    // We still grant read-only access.
    Polymod.addImportAlias('funkin.api.newgrounds.Medals', funkin.api.newgrounds.Medals.MedalsSandboxed);

    // `funkin.api.newgrounds.NewgroundsClientSandboxed` allows for submitting cheated data.
    // We still grant read-only access.
    Polymod.addImportAlias('funkin.api.newgrounds.NewgroundsClient', funkin.api.newgrounds.NewgroundsClient.NewgroundsClientSandboxed);
    #end

    Polymod.addImportAlias('funkin.api.discord.DiscordClient', funkin.api.discord.DiscordClient.DiscordClientSandboxed);

    // Add blacklisting for prohibited classes and packages.

    // `Sys`
    // Sys.command() can run malicious processes
    Polymod.blacklistImport('Sys');

    // `Reflect`
    // Reflect.callMethod() can access blacklisted packages, but some functions are whitelisted
    Polymod.addImportAlias('Reflect', funkin.util.ReflectUtil);

    // `Type`
    // Type.createInstance(Type.resolveClass()) can access blacklisted packages, but some functions are whitelisted
    Polymod.addImportAlias('Type', funkin.util.ReflectUtil);

    // `cpp.Lib`
    // Lib.load() can load malicious DLLs
    Polymod.blacklistImport('cpp.Lib');

    // `haxe.Unserializer`
    // Unserializer.DEFAULT_RESOLVER.resolveClass() can access blacklisted packages
    Polymod.blacklistImport('haxe.Unserializer');

    // `flixel.util.FlxSave`
    // FlxSave.resolveFlixelClasses() can access blacklisted packages
    Polymod.blacklistImport('flixel.util.FlxSave');

    // Disable access to AdMob Util
    Polymod.blacklistImport('funkin.mobile.util.AdMobUtil');

    // Disable access to In-App Purchases Util
    Polymod.blacklistImport('funkin.mobile.util.InAppPurchasesUtil');

    // Disable access to Admob Extension
    for (cls in ClassMacro.listClassesInPackage('extension.admob'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // Disable access to AndroidTools Extension
    for (cls in ClassMacro.listClassesInPackage('extension.androidtools'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // Disable access to IAPCore Extension
    for (cls in ClassMacro.listClassesInPackage('extension.iapcore'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // Disable access to Haptics Extension
    for (cls in ClassMacro.listClassesInPackage('extension.haptics'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `lime.system.CFFI`
    // Can load and execute compiled binaries.
    Polymod.blacklistImport('lime.system.CFFI');

    // `lime.system.JNI`
    // Can load and execute compiled binaries.
    Polymod.blacklistImport('lime.system.JNI');

    // `lime.system.System`
    // System.load() can load malicious DLLs
    Polymod.blacklistImport('lime.system.System');

    // `lime.utils.Assets`
    // Literally just has a private `resolveClass` function for some reason?
    Polymod.blacklistImport('lime.utils.Assets');
    Polymod.blacklistImport('openfl.utils.Assets');
    Polymod.blacklistImport('openfl.Lib');
    Polymod.blacklistImport('openfl.system.ApplicationDomain');
    Polymod.blacklistImport('openfl.net.SharedObject');

    // `openfl.desktop.NativeProcess`
    // Can load native processes on the host operating system.
    Polymod.blacklistImport('openfl.desktop.NativeProcess');

    // Contains critical private environment variables.
    Polymod.blacklistImport('funkin.util.macro.EnvironmentConfigMacro');

    // `funkin.api.*`
    // Contains functions which may allow for cheating and such.
    for (cls in ClassMacro.listClassesInPackage('funkin.api'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      if (polymod.hscript._internal.PolymodScriptClass.importOverrides.exists(className)) continue;
      Polymod.blacklistImport(className);
    }

    // `polymod.*`
    // Contains functions which may allow for un-blacklisting other modules.
    for (cls in ClassMacro.listClassesInPackage('polymod'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `hscript.*
    // Contains functions which may allow for interpreting unsanitized strings.
    for (cls in ClassMacro.listClassesInPackage('hscript'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `funkin.api.newgrounds.*`
    // Contains functions which allow for cheating medals and leaderboards.
    for (cls in ClassMacro.listClassesInPackage('funkin.api.newgrounds'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `io.newgrounds.*`
    // Contains functions which allow for cheating medals and leaderboards.
    for (cls in ClassMacro.listClassesInPackage('io.newgrounds'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `sys.*`
    // Access to system utilities such as the file system.
    for (cls in ClassMacro.listClassesInPackage('sys'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // `funkin.util.macro.*`
    // CompiledClassList's get function allows access to sys and Newgrounds classes
    // None of the classes are suitable for mods anyway
    for (cls in ClassMacro.listClassesInPackage('funkin.util.macro'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }
  }

  /**
   * Build a list of file paths that will be ignored in mods.
   */
  static function buildIgnoreList():Array<String>
  {
    var result = Polymod.getDefaultIgnoreList();

    result.push('.git');
    result.push('.gitignore');
    result.push('.gitattributes');
    result.push('README.md');

    return result;
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
        'default' => 'preload',
        'shared' => 'shared',
        'songs' => 'songs',
        'videos' => 'videos',
        'tutorial' => 'tutorial',
        'week1' => 'week1',
        'week2' => 'week2',
        'week3' => 'week3',
        'week4' => 'week4',
        'week5' => 'week5',
        'week6' => 'week6',
        'week7' => 'week7',
        'weekend1' => 'weekend1',
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
        apiVersionRule: API_VERSION_RULE,
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
    SongEventRegistry.loadEventCache();

    SongRegistry.instance.loadEntries();
    LevelRegistry.instance.loadEntries();
    NoteStyleRegistry.instance.loadEntries();
    PlayerRegistry.instance.loadEntries();
    ConversationRegistry.instance.loadEntries();
    DialogueBoxRegistry.instance.loadEntries();
    SpeakerRegistry.instance.loadEntries();
    AlbumRegistry.instance.loadEntries();
    StageRegistry.instance.loadEntries();
    StickerRegistry.instance.loadEntries();
    FreeplayStyleRegistry.instance.loadEntries();

    CharacterDataParser.loadCharacterCache(); // TODO: Migrate characters to BaseRegistry.
    NoteKindManager.loadScripts();
    ModuleHandler.loadModuleCache();
  }
}
