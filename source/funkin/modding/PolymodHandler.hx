package funkin.modding;

import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.module.ModuleHandler;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.save.Save;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import funkin.util.macro.ClassMacro;
import polymod.Polymod;
import polymod.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.TextFileFormat;
import polymod.fs.ZipFileSystem;

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
  public static final API_VERSION_RULE:String = '>=0.8.0 <0.10.0';

  /**
   * Where relative to the game executable that mods are located.
   */
  public static final MOD_FOLDER:String =
    #if (REDIRECT_ASSETS_FOLDER && mac)
    '../../../../../../../example_mods'
    #elseif REDIRECT_ASSETS_FOLDER
    '../../../../example_mods'
    #else
    'mods'
    #end;

  /**
   * Where relative to the game executable that core assets are located.
   */
  public static final CORE_FOLDER:Null<String> =
    #if (REDIRECT_ASSETS_FOLDER && mac)
    '../../../../../../../assets'
    #elseif REDIRECT_ASSETS_FOLDER
    '../../../../assets'
    #else
    null
    #end;

  /**
   * Populated with the directories of mods once they're successfully loaded.
   */
  public static var loadedModDirs:Array<String> = [];

  /**
   * Populated with the IDs of mods once they're successfully loaded.
   */
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
    loadModsById(Save.instance.enabledModIds.value);
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
   * Load all the mods with the directories they're in.
   * @param modIds The ORDERED list of mod IDs to load.
   */
  public static function loadModsById(modIds:Array<String>):Void
  {
    buildImports();

    // The scripts that were stopped by an error are gone now, so let the new ones run.
    funkin.modding.ScriptGuard.clear();

    try
    {
      if (modFileSystem == null) modFileSystem = buildFileSystem();
    }
    catch (e:Dynamic)
    {
      trace('Failed to build mod file system: ${Std.string(e)}');
    }

    // Check if the mods to load are actually present before trying to load them.
    var allModIds:Array<String> = getAllModIds();
    var toRemove:Array<String> = [];
    for (modId in modIds)
    {
      if (!allModIds.contains(modId))
      {
        trace('Warning: Mod with ID "${modId}" was configured to be loaded, but was not found in the mods folder!');
        toRemove.push(modId);
      }
    }

    for (modId in toRemove) modIds.remove(modId);

    var loadedModList:Array<ModMetadata> = polymod.Polymod.init({
      // Root directory for all mods.
      modRoot: MOD_FOLDER,
      // The IDs for one or more mods to load.
      modIds: modIds,
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

      // We plan to parse hxc files LATER!
      useScriptedClasses: false,
      loadScriptsAsync: false
    });

    if (loadedModList == null)
    {
      trace('An error occurred! Failed when loading mods!');
    }
    else
    {
      if (loadedModList.length == 0)
      {
        trace('Mod loading complete. We loaded no mods / ${modIds.length} mods.');
      }
      else
      {
        trace('Mod loading complete. We loaded ${loadedModList.length} / ${modIds.length} mods.');
      }
    }

    loadedModIds = [];
    loadedModDirs = [];
    for (mod in loadedModList)
    {
      trace(' * ${mod.title} v${mod.modVersion} [${mod.id}]');
      loadedModDirs.push(mod.dirName);
      loadedModIds.push(mod.id);
    }

    #if false
    // These log calls can get VERY spammy with a lot of mods, I had just 14 mods installed and it was roughly 8,000 lines of logs.

    var fileList:Array<String> = Polymod.listModFiles(PolymodAssetType.IMAGE);
    trace('Installed mods have replaced ${fileList.length} images.');
    for (item in fileList)
    {
      trace(' * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.TEXT);
    trace('Installed mods have added/replaced ${fileList.length} text files.');
    for (item in fileList)
    {
      trace(' * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_MUSIC);
    trace('Installed mods have replaced ${fileList.length} music files.');
    for (item in fileList)
    {
      trace(' * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_SOUND);
    trace('Installed mods have replaced ${fileList.length} sound files.');
    for (item in fileList)
    {
      trace(' * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_GENERIC);
    trace('Installed mods have replaced ${fileList.length} generic audio files.');
    for (item in fileList)
    {
      trace(' * $item');
    }
    #end
  }

  public static function loadScripts(async:Bool = true):lime.app.Future<
    {success:Int, total:Int}>
  {
    #if FEATURE_CPPIA
    polymod.hscript._internal.PolymodCppiaClassReference.expectedVersion = lime.app.Application.current.meta.get('version');
    #end

    if (async)
    {
      return Polymod.registerAllScriptClassesAsync().then((result) ->
      {
        var total = 0;
        var success = 0;

        for (future in result)
        {
          total += 1;
          if (future.isComplete) success += 1;
        }

        return lime.app.Future.withValue({
          success: success,
          total: total
        });
      });
    }
    else
    {
      var result = Polymod.registerAllScriptClasses();

      var total = result.size();
      var success = result.values().filter((v) -> (v == true)).length;
      return lime.app.Future.withValue({
        success: success,
        total: total
      });
    }
  }

  /**
   * Replace the file system used for scanning.
   * NOTE: Won't replace the file system used for actual mods until you rerun `Polymod.init()`.
   *
   * @return polymod.fs.ZipFileSystem
   */
  static function buildFileSystem():polymod.fs.ZipFileSystem
  {
    polymod.Polymod.onError = PolymodErrorHandler.onPolymodError;
    return new ZipFileSystem({
      modRoot: MOD_FOLDER,
      autoScan: true
    });
  }

  static function buildImports():Void
  {
    buildConvenienceAliases();
    buildCompatAliases();
    buildBlacklist();
  }

  /**
   * Build Polymod imports and aliases for general convenience.
   */
  static function buildConvenienceAliases():Void
  {
    // Add default imports for common classes.
    final DEFAULT_IMPORTS:Array<Class<Dynamic>> = [
      funkin.Assets,
      funkin.Paths,
      funkin.Preferences,
      funkin.util.Constants,
      flixel.FlxG
    ];

    for (cls in DEFAULT_IMPORTS)
    {
      Polymod.addDefaultImport(cls);
    }
  }

  /**
   * Build Polymod imports and aliases for compatibility with older mods.
   */
  static function buildCompatAliases():Void
  {
    // Older paths for certain classes.
    Polymod.addImportAlias('funkin.data.dialogue.conversation.ConversationRegistry', funkin.data.dialogue.ConversationRegistry);
    Polymod.addImportAlias('funkin.data.dialogue.dialoguebox.DialogueBoxRegistry', funkin.data.dialogue.DialogueBoxRegistry);
    Polymod.addImportAlias('funkin.data.dialogue.speaker.SpeakerRegistry', funkin.data.dialogue.SpeakerRegistry);
    Polymod.addImportAlias('funkin.play.character.CharacterDataParser', funkin.data.character.CharacterData.CharacterDataParser);
    Polymod.addImportAlias('funkin.play.character.CharacterData.CharacterDataParser', funkin.data.character.CharacterData.CharacterDataParser);

    Polymod.addImportAlias('funkin.modding.base.ScriptedFunkinSprite', funkin.graphics.FunkinSprite);
    Polymod.addImportAlias('funkin.modding.base.ScriptedMusicBeatState', funkin.ui.MusicBeatState);
    Polymod.addImportAlias('funkin.modding.base.ScriptedMusicBeatSubState', funkin.ui.MusicBeatSubState);

    Polymod.addImportAlias('funkin.play.character.CharacterDataParser', funkin.data.character.CharacterData.CharacterDataParser);

    // TODO: Does this work?
    Polymod.addImportAlias('funkin.graphics.adobeanimate.FlxAtlasSprite', funkin.graphics.FunkinSprite);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxAtlasSprite', funkin.graphics.FunkinSprite);

    // Sandboxing for compatibility.
    Polymod.addImportAlias('funkin.play.cutscene.VideoCutscene', funkin.modding.compat.VideoCutscene);
    Polymod.addImportAlias('funkin.FunkinMemory', funkin.memory.FunkinMemory);

    // Backwards compatibility for many classes that were removed.
    // These are just wrapper scripted classes that extend the original class.
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxBasic', flixel.FlxBasic);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxObject', flixel.FlxObject);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxSprite', flixel.FlxSprite);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxState', flixel.FlxState);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxSubState', flixel.FlxSubState);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxStrip', flixel.FlxStrip);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxTransitionableState', flixel.addons.transition.FlxTransitionableState);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxSpriteGroup', flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup);
    Polymod.addImportAlias('funkin.modding.base.ScriptedFlxTypedGroup', flixel.group.FlxGroup.FlxTypedGroup);
    Polymod.addImportAlias('funkin.graphics.ScriptedFunkinSprite', funkin.graphics.FunkinSprite);
    Polymod.addImportAlias('funkin.group.ScriptedFunkinGroup', funkin.group.FunkinGroup);
    Polymod.addImportAlias('funkin.graphics.video.ScriptedFunkinVideoSprite', funkin.graphics.video.FunkinVideoSprite);
    Polymod.addImportAlias('funkin.play.character.ScriptedBaseCharacter', funkin.play.character.BaseCharacter);
    Polymod.addImportAlias('funkin.play.character.ScriptedSparrowCharacter', funkin.play.character.SparrowCharacter);
    Polymod.addImportAlias('funkin.play.character.ScriptedMultiSparrowCharacter', funkin.play.character.MultiSparrowCharacter);
    Polymod.addImportAlias('funkin.play.character.ScriptedMultiAnimateAtlasCharacter', funkin.play.character.MultiAnimateAtlasCharacter);
    Polymod.addImportAlias('funkin.play.character.ScriptedPackerCharacter', funkin.play.character.PackerCharacter);
    Polymod.addImportAlias('funkin.play.character.ScriptedAnimateAtlasCharacter', funkin.play.character.AnimateAtlasCharacter);
    Polymod.addImportAlias('funkin.play.cutscene.dialogue.ScriptedConversation', funkin.play.cutscene.dialogue.Conversation);
    Polymod.addImportAlias('funkin.play.cutscene.dialogue.ScriptedDialogueBox', funkin.play.cutscene.dialogue.DialogueBox);
    Polymod.addImportAlias('funkin.play.cutscene.dialogue.ScriptedSpeaker', funkin.play.cutscene.dialogue.Speaker);
    Polymod.addImportAlias('funkin.play.event.ScriptedSongEvent', funkin.play.event.SongEvent);
    Polymod.addImportAlias('funkin.play.notes.ScriptedStrumline', funkin.play.notes.Strumline);
    Polymod.addImportAlias('funkin.play.notes.notekind.ScriptedNoteKind', funkin.play.notes.notekind.NoteKind);
    Polymod.addImportAlias('funkin.play.notes.notestyle.ScriptedNoteStyle', funkin.play.notes.notestyle.NoteStyle);
    Polymod.addImportAlias('funkin.play.song.ScriptedSong', funkin.play.song.Song);
    Polymod.addImportAlias('funkin.play.stage.ScriptedBopper', funkin.play.stage.Bopper);
    Polymod.addImportAlias('funkin.play.stage.ScriptedStage', funkin.play.stage.Stage);
    Polymod.addImportAlias('funkin.play.stage.ScriptedStageProp', funkin.play.stage.StageProp);
    Polymod.addImportAlias('funkin.ui.ScriptedMusicBeatState', funkin.ui.MusicBeatState);
    Polymod.addImportAlias('funkin.ui.ScriptedMusicBeatSubState', funkin.ui.MusicBeatSubState);
    Polymod.addImportAlias('funkin.ui.freeplay.ScriptedAlbum', funkin.ui.freeplay.Album);
    Polymod.addImportAlias('funkin.ui.freeplay.ScriptedFreeplayStyle', funkin.ui.freeplay.FreeplayStyle);
    Polymod.addImportAlias('funkin.ui.freeplay.backcards.ScriptedBackingCard', funkin.ui.freeplay.backcards.BackingCard);
    Polymod.addImportAlias('funkin.ui.freeplay.charselect.ScriptedPlayableCharacter', funkin.ui.freeplay.charselect.PlayableCharacter);
    Polymod.addImportAlias('funkin.ui.freeplay.dj.ScriptedAnimateAtlasFreeplayDJ', funkin.ui.freeplay.dj.AnimateAtlasFreeplayDJ);
    Polymod.addImportAlias('funkin.ui.freeplay.dj.ScriptedBaseFreeplayDJ', funkin.ui.freeplay.dj.BaseFreeplayDJ);
    Polymod.addImportAlias('funkin.ui.freeplay.dj.ScriptedSparrowFreeplayDJ', funkin.ui.freeplay.dj.SparrowFreeplayDJ);
    Polymod.addImportAlias('funkin.ui.freeplay.dj.ScriptedMultiSparrowFreeplayDJ', funkin.ui.freeplay.dj.MultiSparrowFreeplayDJ);
    Polymod.addImportAlias('funkin.ui.freeplay.dj.ScriptedPackerFreeplayDJ', funkin.ui.freeplay.dj.PackerFreeplayDJ);
    Polymod.addImportAlias('funkin.ui.story.ScriptedLevel', funkin.ui.story.Level);
    Polymod.addImportAlias('funkin.ui.transition.stickers.ScriptedStickerPack', funkin.ui.transition.stickers.StickerPack);

    // `FixedBitmapData` was literally just `BitmapData`.
    Polymod.addImportAlias('funkin.graphics.framebuffer.FixedBitmapData', openfl.display.BitmapData);
  }

  /**
   * Build Polymod's blacklist for prohibited classes and packages.
   */
  static function buildBlacklist():Void
  {
    // `lime.utils.Assets` literally just has a private `resolveClass` function for some reason? so we replace it with our own.
    Polymod.addImportAlias('lime.utils.Assets', funkin.Assets);
    Polymod.addImportAlias('openfl.utils.Assets', funkin.Assets);
    Polymod.addImportAlias('openfl.Assets', funkin.Assets);

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

    // `haxe.Http`
    // An alias for `sys.Http`, which is also a blacklisted package.
    Polymod.blacklistImport('haxe.Http');

    // `haxe.Unserializer`
    // Unserializer.DEFAULT_RESOLVER.resolveClass() can access blacklisted packages
    Polymod.blacklistImport('haxe.Unserializer');

    // `lime.utils.AssetLibrary`
    // If you create your own library using a manifest, AssetLibrary.__fromManifest() can access blacklisted packages apparently.
    Polymod.blacklistImport('lime.utils.AssetLibrary');

    // Disable access to all Mobile Utils
    for (cls in ClassMacro.listClassesInPackage('funkin.mobile.util'))
    {
      if (cls == null) continue;
      var className:String = Type.getClassName(cls);
      Polymod.blacklistImport(className);
    }

    // Disable access to all Extension in the extension package
    for (cls in ClassMacro.listClassesInPackage('extension'))
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

    // `flixel.util.FlxSave`
    // resolveFlixelClasses() can access blacklisted packages
    Polymod.blacklistStaticFields(flixel.util.FlxSave, ['resolveFlixelClasses']);
    // Disallow direct manipulation of save data.
    Polymod.blacklistStaticFields(flixel.FlxG, ['save']);

    /**
     * Using the `AssetManifest` class can get you a `Future` that holds an `AssetLibrary`
     * that you can then use to resolve to blacklisted classes using the `classTypes` field.
    **/
    Polymod.blacklistInstanceFields(lime.utils.AssetLibrary, ['classTypes']);

    // `haxe.Unserializer`
    // Just to be double-sure, lets blacklist some fields of the Unserializer to make it harder to use if you DO get one.
    Polymod.blacklistStaticFields(haxe.Unserializer, ['run']);
    Polymod.blacklistInstanceFields(haxe.Unserializer, ['unserialize']);

    // `funkin.save.Save`
    // Direct access to save data is important for scripts (like checking unlocks),
    // but we don't want scripts to be able to perform operations like writing scores.
    Polymod.blacklistInstanceFields(funkin.save.Save, [
      // No direct field access
      'data', // LMFAO definitely not
      'clearData', // No score manipulation please
      'setLevelScore',
      'setSongScore',
      'applySongRank'
    ]);

    // `funkin.Assets`
    // getLibrary() can use libraries to get blacklisted packages
    Polymod.blacklistStaticFields(funkin.Assets, ['getLibrary']);

    // `openfl.filesystem.FileStream`, `openfl.net.Socket`, `openfl.utils.ByteArray.ByteArrayData`
    // Returns `Unseralizer.run` if encoded in HXSF format, though it does have to be seralized correctly for the exploit to work.
    #if !html5 Polymod.blacklistInstanceFields(openfl.filesystem.FileStream, ['readObject']); #end
    Polymod.blacklistInstanceFields(openfl.net.Socket, ['readObject']);
    Polymod.blacklistInstanceFields(openfl.utils.ByteArray.ByteArrayData, ['readObject']);

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

    // External classes for android that bridge to private JNI methods & callbacks
    Polymod.blacklistImport('funkin.external.android.CallbackUtil');
    Polymod.blacklistImport('funkin.external.android.DataFolderUtil');
    Polymod.blacklistImport('funkin.external.android.JNIUtil');

    // Blacklists accessing the interp for polymod hscript
    Polymod.blacklistInstanceFields(polymod.hscript._internal.PolymodScriptClass.PolymodScriptClass, ['_interp']);

    Polymod.blacklistDynamicFieldNames([
      'resolveFlixelClasses',
      'classTypes',
      'unserialize',
      'getLibrary',
      'readObject',
      'clearData',
      'setLevelScore',
      'setSongScore',
      'applySongRank',
      '_interp'
    ]);
  }

  /**
   * Build a list of file paths that will be ignored in mods.
   */
  static function buildIgnoreList():Array<String>
  {
    var result = Polymod.getDefaultIgnoreList();

    result.push('.vscode');
    result.push('.idea');
    result.push('.git');
    result.push('.gitignore');
    result.push('.gitattributes');
    result.push('.jj');
    result.push('.DS_Store');
    result.push('README.md');
    // Sources and build scripts a mod ships for its compiled code. Not assets.
    result.push('cppia-src');
    result.push('build.sh');
    result.push('build.ps1');

    return result;
  }

  static function buildParseRules():polymod.format.ParseRules
  {
    var output:polymod.format.ParseRules = polymod.format.ParseRules.getDefault();
    // Ensure TXT files have merge support.
    output.addType('txt', TextFileFormat.LINES);

    // You can specify the format of a specific file, with file extension.
    // output.addFile("data/introText.txt", TextFileFormat.LINES)
    return output;
  }

  static inline function buildFrameworkParams():polymod.Polymod.FrameworkParams
  {
    return {
      assetLibraryPaths: ['default' => ''],
      coreAssetRedirect: CORE_FOLDER,
    }
  }

  /**
   * Get all installed mods. Incompatible mods are excluded.
   *
   * @param force Force the game to reload the list of mods from the file system.
   * @return An array of mod metadata
   */
  public static function getAllMods(force:Bool = false):Array<ModMetadata>
  {
    return scanMods(false, force);
  }

  /**
   * Get all installed mods including incompatible ones.
   * Used by the Mod Menu.
   *
   * @param force Force the game to reload the list of mods from the file system.
   * @return An array of mod metadata
   */
  public static function getAllModsIncludingIncompatible(force:Bool = false):Array<ModMetadata>
  {
    return scanMods(true, force);
  }

  /**
   * Scan the mods folder. Optionally include incompatible mods.
   *
   * @param includeIncompatible Whether to return mods that don't satisfy `API_VERSION_RULE`.
   * @param force Force the game to reload the list of mods from the file system.
   * @return An array of mod metadata
   */
  static function scanMods(includeIncompatible:Bool, force:Bool):Array<ModMetadata>
  {
    trace('Scanning the mods folder...');

    var modMetadata:Array<ModMetadata> = [];
    try
    {
      if (modFileSystem == null || force) modFileSystem = buildFileSystem();

      var scanParams:Dynamic = {
        modRoot: MOD_FOLDER,
        fileSystem: modFileSystem,
        errorCallback: PolymodErrorHandler.onPolymodError
      };
      if (!includeIncompatible) scanParams.apiVersionRule = API_VERSION_RULE;
      modMetadata = Polymod.scan(scanParams);
    }
    catch (e:Dynamic)
    {
      trace('Error scanning mods folder: ${Std.string(e)}');
      return [];
    }
    trace('Found ${modMetadata.length} mods when scanning.');
    return modMetadata;
  }

  /**
   * Check if a mod is compatible with the current API version.
   *
   * @param mod The mod metadata to check.
   * @return Whether the mod satisfies `API_VERSION_RULE`.
   */
  public static function isModCompatible(mod:ModMetadata):Bool
  {
    if (mod == null) return true;
    return mod.isCompatible(API_VERSION_RULE);
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
   * Retrieve a list of ALL mod directory names, including disabled mods.
   * @return An array of mod direcotry names
   */
  public static function getAllModDirs():Array<String>
  {
    var modDirs:Array<String> = [for (i in getAllMods()) i.dirName];
    return modDirs;
  }

  /**
   * Enable a mod by its ID.
   * @param modId The ID of the mod to enable, which can be found in the mod's metadata.
   */
  public static function enableMod(modId:String):Void
  {
    var enabledModIds:Array<String> = Save.instance.enabledModIds.value;
    if (!enabledModIds.contains(modId))
    {
      enabledModIds.push(modId);
      Save.instance.enabledModIds.value = enabledModIds;
      Save.system.flush();
    }
  }

  /**
   * Disable a mod by its ID.
   * @param modId The ID of the mod to disable, which can be found in the mod's metadata.
   */
  public static function disableMod(modId:String):Void
  {
    var enabledModIds:Array<String> = Save.instance.enabledModIds.value;
    if (enabledModIds.contains(modId))
    {
      enabledModIds.remove(modId);
      Save.instance.enabledModIds.value = enabledModIds;
      Save.system.flush();
    }
  }

  public static function disableAllMods():Void
  {
    Save.instance.enabledModIds.value = [];
    Save.system.flush();
  }

  /**
   * Retrieve a list of metadata for all enabled mods.
   * @return An array of mod metadata, in mod load order.
   */
  public static function getEnabledMods():Array<ModMetadata>
  {
    var enabledModIds:Array<String> = Save.instance.enabledModIds.value;
    var modMetadata:Array<ModMetadata> = getAllMods();
    var enabledMods:Array<ModMetadata> = modMetadata.filter((item) ->
    {
      return enabledModIds.contains(item.id);
    });

    // Sort the mods by the order they are enabled in.
    enabledMods.sort((a, b) ->
    {
      return enabledModIds.indexOf(a.id) - enabledModIds.indexOf(b.id);
    });

    return enabledMods;
  }

  /**
   * Retrieve a list of metadata for all disabled mods.
   * @return An array of mod metadata, in alphabetical order by mod title.
   */
  public static function getDisabledMods():Array<ModMetadata>
  {
    var modMetadata:Array<ModMetadata> = getAllMods();
    var enabledModIds:Array<String> = Save.instance.enabledModIds.value;
    var disabledMods:Array<ModMetadata> = modMetadata.filter((item) ->
    {
      return !enabledModIds.contains(item.id);
    });

    // Sort the mods by alphabetical mod title.
    disabledMods.sort((a, b) ->
    {
      return SortUtil.alphabetically(a.title, b.title);
    });

    return disabledMods;
  }

  /**
   * Get all disabled mods including incompatible ones.
   * Incompatible mods sort to the bottom.
   * @return An array of mod metadata, in alphabetical order by mod title.
   */
  public static function getDisabledModsIncludingIncompatible(force:Bool = false):Array<ModMetadata>
  {
    var modMetadata:Array<ModMetadata> = getAllModsIncludingIncompatible(force);
    var enabledModIds:Array<String> = Save.instance.enabledModIds.value;
    var disabledMods:Array<ModMetadata> = modMetadata.filter((item) ->
    {
      return !enabledModIds.contains(item.id);
    });

    // Sort the mods by alphabetical mod title, pushing incompatible mods to the bottom.
    disabledMods.sort((a, b) ->
    {
      var aCompatible:Bool = isModCompatible(a);
      var bCompatible:Bool = isModCompatible(b);
      if (aCompatible != bCompatible) return aCompatible ? 1 : -1;
      return SortUtil.alphabetically(a.title, b.title);
    });

    return disabledMods;
  }

  /**
   * Clear and reload from disk all data assets, synchronously.
   * Useful for "hot reloading" for fast iteration!
   */
  public static function forceReloadAssets():Void
  {
    // Forcibly clear scripts so that scripts can be edited.
    ModuleHandler.clearModuleCache();
    Polymod.clearScripts();

    // Forcibly reload Polymod so it finds any new files.
    // This will also register all scripts.
    funkin.modding.PolymodHandler.loadEnabledMods();

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
    NoteKindManager.initialize();
    ModuleHandler.loadModuleCache();
    ModuleHandler.callOnCreate();
  }
}
