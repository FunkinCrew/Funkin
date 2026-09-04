package funkin.data.character;

import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.animation.AnimationData;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.BaseCharacter;
import funkin.play.character.SparrowCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.MultiAnimateAtlasCharacter;
import funkin.play.character.PackerCharacter;
import funkin.util.VersionUtil;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
import haxe.Json;
import flixel.graphics.frames.FlxFrame;
import funkin.assets.Paths;
import funkin.assets.Assets;
import lime.app.Promise;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end

@:nullSafety
class CharacterDataParser
{
  /**
   * The current version string for the character data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateCharacterData()` function.
   *
   * - Version 1.0.1 adds `death.cameraOffsets`
   */
  public static final CHARACTER_DATA_VERSION:String = '1.0.2';

  /**
   * The current version rule check for the character data format.
   */
  public static final CHARACTER_DATA_VERSION_RULE:String = '1.0.x';

  #if FEATURE_MULTITHREADING
  static final characterCache:SynchronizedMap<String, CharacterData> = SynchronizedMap.newStringMap();
  #else
  static final characterCache:Map<String, CharacterData> = [];
  #end
  #if FEATURE_MULTITHREADING
  static final characterScriptedClass:SynchronizedMap<String, String> = SynchronizedMap.newStringMap();
  #else
  static final characterScriptedClass:Map<String, String> = [];
  #end
  static final DEFAULT_CHAR_ID:String = 'UNKNOWN';
  static final ASSET_BLACKLIST:Array<String> = ['Animation', 'spritemap1'];
  static final DATA_FILE_PATH:String = 'gameplay/characters/';

  /**
   * Parses and preloads the game's character data and scripts when the game starts.
   *
   * If you want to force characters to be reloaded, you can just call this function again.
   */
  public static function loadCharacterCache():Void
  {
    // Clear any characters that are cached if there were any.
    clearCharacterCache();
    log(' INFO '.info() + 'Parsing all entries...');

    //
    // UNSCRIPTED CHARACTERS
    //

    var charIdList:Array<String> = funkin.modding.compat.RegistryData.listEntryIds(DATA_FILE_PATH, true);
    var unscriptedCharIds:Array<String> = charIdList.filter((charId:String) ->
    {
      return !characterCache.exists(charId);
    });
    log('Fetching data for ${unscriptedCharIds.length} unscripted characters...');
    for (charId in unscriptedCharIds)
    {
      try
      {
        var charData:Null<CharacterData> = parseCharacterData(charId);
        if (charData != null)
        {
          log('Loaded character "${charId}"');
          characterCache.set(charId, charData);
        }
      }
      catch (e)
      {
        // Assume error was already logged.
        continue;
      }
    }

    //
    // SCRIPTED CHARACTERS
    //
    // Fuck I wish scripted classes supported static functions.
    var scriptedCharClassNames1:Array<String> = SparrowCharacter.listScriptClasses();
    if (scriptedCharClassNames1.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames1.length} (Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames1)
      {
        try
        {
          var character:Null<SparrowCharacter> = SparrowCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Sparrow character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Sparrow character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Sparrow character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames2:Array<String> = PackerCharacter.listScriptClasses();
    if (scriptedCharClassNames2.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames2.length} (Packer) scripted characters...');
      for (charCls in scriptedCharClassNames2)
      {
        try
        {
          var character:Null<PackerCharacter> = PackerCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Packer character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Packer character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Packer character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames3:Array<String> = MultiSparrowCharacter.listScriptClasses();
    if (scriptedCharClassNames3.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames3.length} (Multi-Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames3)
      {
        try
        {
          var character:Null<MultiSparrowCharacter> = MultiSparrowCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Sparrow character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Multi-Sparrow character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Sparrow character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames4:Array<String> = AnimateAtlasCharacter.listScriptClasses();
    if (scriptedCharClassNames4.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames4.length} (Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames4)
      {
        try
        {
          var character:Null<AnimateAtlasCharacter> = AnimateAtlasCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted character: $charCls');
            continue;
          }
          else
          {
            log('Instantiated Animate Atlas character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Animate Atlas character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames5:Array<String> = MultiAnimateAtlasCharacter.listScriptClasses();
    if (scriptedCharClassNames5.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames5.length} (Multi-Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames5)
      {
        try
        {
          var character:Null<MultiAnimateAtlasCharacter> = MultiAnimateAtlasCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Animate Atlas character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Multi-Animate Atlas character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Animate Atlas character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    // NOTE: Only initialize the ones not populated above.
    // BaseCharacter.listScriptClasses() will pick up scripts extending the other classes.
    var scriptedCharClassNames:Array<String> = BaseCharacter.listScriptClasses();

    scriptedCharClassNames = scriptedCharClassNames.filter((charCls:String) ->
    {
      return !(
        scriptedCharClassNames1.contains(charCls)
        || scriptedCharClassNames2.contains(charCls)
        || scriptedCharClassNames3.contains(charCls)
        || scriptedCharClassNames4.contains(charCls)
        || scriptedCharClassNames5.contains(charCls)
      );
    });

    if (scriptedCharClassNames.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames.length} (Base) scripted characters...');
      for (charCls in scriptedCharClassNames)
      {
        var character:Null<BaseCharacter> = BaseCharacter.scriptInit(charCls, DEFAULT_CHAR_ID, Custom);
        if (character == null)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted character ($charCls)');
          continue;
        }
        else
        {
          log('Instantiated base scripted character ($charCls = ${character.characterId})');
          characterScriptedClass.set(character.characterId, charCls);
        }
      }
    }
    log(' INFO '.info() + 'Successfully instantiated ${characterCache.size()} characters.');
  }

  #if FEATURE_MULTITHREADING
  public static function loadCharacterCacheAsync():lime.app.Future<LoadEntriesResult>
  {
    clearCharacterCache();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadCharacterCacheAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();

    var charIdList:Array<String> = funkin.modding.compat.RegistryData.listEntryIds(DATA_FILE_PATH, true);
    var previousScriptedEntryClasses:SynchronizedArray<String> = new SynchronizedArray<String>();
    var scriptedEntryClassNames:SynchronizedArray<String> = new SynchronizedArray<String>();
    var entryCount:Int = 0;

    // Used to track the state we're in while loading the characters. This can either be us loading all character data, or loading each scripted character types.
    // For example, `data means we're loading all of the character data currently
    // `packer` means we're currently loading the scripted classes for PackerCharacter, etc.
    var entryLoadingState:String = 'data';

    var loadCharacterDataAsync:Void->Void = () -> {
    }
    var loadScriptedEntriesAsync:Void->Void = () -> {
    }

    var checkAsyncProgress = () ->
    {
      // We're checking the progress on loading the data for all characters.
      if (entryLoadingState == 'data')
      {
        var current:Int = characterCache.size() + entryErrors.length;
        if (current == entryCount)
        {
          entryCount = 0; // Reset the entry count so it can be used for scripted classes now.
          entryLoadingState = 'sparrow'; // Move to loading scripted characters.
          loadScriptedEntriesAsync();
          log('Finished loading data for characters (1/2)');
        }
      }
      else
      {
        // We're checking the progress on what characters are scripted.
        var current:Int = characterScriptedClass.size() + entryErrors.length;
        if (current == entryCount)
        {
          // We've finished loading the scripted entries for a character type, use a basic state machine switching to the next one.
          switch (entryLoadingState)
          {
            case 'sparrow':
              entryLoadingState = 'packer';
              log('Finished loading scripted sparrow characters (1/6) ($current / ${entryCount})');
            case 'packer':
              entryLoadingState = 'animateatlas';
              log('Finished loading scripted packer characters (2/6) ($current / ${entryCount})');
            case 'animateatlas':
              entryLoadingState = 'multisparrow';
              log('Finished loading scripted animateatlas characters (3/6) ($current / ${entryCount})');
            case 'multisparrow':
              entryLoadingState = 'multianimateatlas';
              log('Finished loading scripted multi-sparrow characters (4/6) ($current / ${entryCount})');
            case 'multianimateatlas':
              entryLoadingState = 'base';
              log('Finished loading scripted multi-animateatlas characters (5/6) ($current / ${entryCount})');
            case 'base':
              log('Finished loading scripted base characters (6/6) ($current / ${entryCount})');
              log('Finished loading all scripted classes for characters (2/2)');

              // NOTE: `entriesFailed` is the sum of errors from loading both scripted classes & data for characters
              // Same for how `entriesLoaded` is the sum successfully loaded entries for character data & scripted classes
              promise.complete({
                entriesLoaded: characterCache.size() + characterScriptedClass.size(),
                entriesFailed: entryErrors.length
              });
              perf.print();
              return;
          }

          // Restart loading scripted entries.
          loadScriptedEntriesAsync();
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

        // Log based on the current state.
        switch (entryLoadingState)
        {
          case 'data':
            log(' ERROR '.error() + 'Failed to load data for character entry ($entryId)');
          case 'sparrow':
            log(' ERROR '.error() + 'Failed to instantiate scripted Sparrow character ($entryId)');
          case 'packer':
            log(' ERROR '.error() + 'Failed to instantiate scripted Packer character ($entryId)');
          case 'animateatlas':
            log(' ERROR '.error() + 'Failed to instantiate scripted Animate Atlas character ($entryId)');
          case 'multisparrow':
            log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Sparrow character ($entryId)');
          case 'multianimateatlas':
            log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Animate Atlas character ($entryId)');
          case 'base':
            log(' ERROR '.error() + 'Failed to instantiate scripted base character ($entryId)');
        }
        checkAsyncProgress();
      };

    var onUnscriptedEntryLoaded:(String,
      {entryData:CharacterData}) -> Void = (entryId, state) ->
      {
        characterCache.set(entryId, state.entryData);
        log('  Loaded data for character: ${entryId} (${characterCache.size()}+${entryErrors.length} / ${charIdList.length})');
        checkAsyncProgress();
      };

    var onScriptedEntryLoaded:(String,
      {entry:BaseCharacter, entryCls:String}) -> Void = (_, state) ->
      {
        var entryId:String = state.entry.characterId;
        characterScriptedClass.set(entryId, state.entryCls);

        log('  Loaded scripted entry: ${entryId} (${state.entryCls}) (${characterScriptedClass.size()}+${entryErrors.length} / ${entryCount})');
        checkAsyncProgress();
      };

    var performLoadUnscriptedEntryData:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryId:String = currentState.entryId;
      try
      {
        var charData:Null<CharacterData> = parseCharacterData(entryId);
        if (charData != null)
        {
          workOutput.sendComplete({
            entryData: charData
          }, []);
        }
        else
        {
          workOutput.sendError({
            error: 'Failed to load data for character entry (${entryId})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryId: entryId,
          error: e
        });
      }
    }

    var performLoadScriptedEntry:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryCls:String = currentState.entryCls;
      try
      {
        var character:Null<BaseCharacter> = switch (entryLoadingState)
        {
          case 'sparrow':
            SparrowCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'packer':
            PackerCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'animateatlas':
            AnimateAtlasCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'multianimateatlas':
            MultiAnimateAtlasCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'multisparrow':
            MultiSparrowCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'base':
            BaseCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          default:
            null;
        }

        if (character != null)
        {
          workOutput.sendComplete({
            entryCls: entryCls,
            entry: character
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryCls: entryCls,
            error: 'Failed to create scripted entry (${entryCls})'
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

    loadCharacterDataAsync = () ->
    {
      var loadCharacterDataFuture = TaskHandler.performSimpleTask(() ->
      {
        log('Loading data for ${charIdList.length} characters...');

        entryCount = charIdList.length;

        return true;
      });

      loadCharacterDataFuture.onComplete((_) ->
      {
        for (entryId in charIdList)
        {
          var loadUnscriptedEntryDataFuture = TaskHandler.performTask({
            task: performLoadUnscriptedEntryData,
            initialState: {
              entryId: entryId
            }
          }, new Promise<
            {entryData:CharacterData}>());

          loadUnscriptedEntryDataFuture.onError(onError.bind(entryId));
          loadUnscriptedEntryDataFuture.onComplete(onUnscriptedEntryLoaded.bind(entryId));
        }
      });
    }

    // NOTE: Runs several times as we have to load the scripted classes for multiple different types of characters.
    loadScriptedEntriesAsync = () ->
    {
      var loadScriptedEntriesFuture = TaskHandler.performSimpleTask(() ->
      {
        var scriptedClsNames:Array<String> = switch (entryLoadingState)
        {
          case 'sparrow':
            SparrowCharacter.listScriptClasses();
          case 'packer':
            PackerCharacter.listScriptClasses();
          case 'animateatlas':
            AnimateAtlasCharacter.listScriptClasses();
          case 'multisparrow':
            MultiSparrowCharacter.listScriptClasses();
          case 'multianimateatlas':
            MultiAnimateAtlasCharacter.listScriptClasses();
          case 'base':
            var scriptedClasses:Array<String> = BaseCharacter.listScriptClasses().filter((charCls:String) ->
            {
              // ONLY populate the base character classes that hasn't already been populated.
              return !previousScriptedEntryClasses.contains(charCls);
            });
            scriptedClasses;
          default:
            [];
        }
        scriptedEntryClassNames.clear();
        scriptedEntryClassNames.addAll(scriptedClsNames);

        // We concatenate this list so we can use this when checking for BaseCharacter entries.
        previousScriptedEntryClasses.addAll(scriptedClsNames);

        log('Queuing loading for ${scriptedClsNames.length} $entryLoadingState character scripted entries...');
        entryCount += scriptedClsNames.length; // Since this function is called several times, we increment the entry count for each use.

        return true;
      });

      loadScriptedEntriesFuture.onComplete((_) ->
      {
        if (scriptedEntryClassNames.length == 0)
        {
          checkAsyncProgress();
        }
        else
        {
          for (entryCls in scriptedEntryClassNames)
          {
            var loadScriptedEntryFuture = TaskHandler.performTask({
              task: performLoadScriptedEntry,
              initialState: {
                entryCls: entryCls
              }
            }, new Promise<
              {
                entry:BaseCharacter,
                entryCls:String
              }>());
            loadScriptedEntryFuture.onError(onError.bind(entryCls));
            loadScriptedEntryFuture.onComplete(onScriptedEntryLoaded.bind(entryCls));
          }
        }
      });
    }

    // First load the character data for all characters.
    loadCharacterDataAsync();

    return promise.future;
  }
  #end

  /**
   * Query assets needed by the REGISTRY ITSELF, usually for parsing entry data.
   *
   * @param type The type of asset to query.
   * @return The list of asset paths.
   */
  public static function queryRegistryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    switch (type)
    {
      case JSON:
        return funkin.modding.compat.RegistryData.listAssetPaths('gameplay/characters/').filterNull();
      default:
        return [];
    }
  }

  /**
   * Fetches data for a character and returns a BaseCharacter instance,
   * ready to be added to the scene.
   *
   * @param charId The character ID to fetch.
   * @param debug If `true`, the character will be initialized for use in a debug view, not necessarily a stage.
   * @return The character instance, or `null` if the character was not found.
   */
  public static function fetchCharacter(charId:String, debug:Bool = false):Null<BaseCharacter>
  {
    if (charId == null || charId == '' || !characterCache.exists(charId))
    {
      // Gracefully handle songs that don't use this character,
      // or throw an error if the character is missing.

      if (charId != null && charId != '') trace('Failed to instantiate character, not found in cache: ${charId}');
      return null;
    }

    var charData:Null<CharacterData> = characterCache.get(charId);
    var charScriptClass:Null<String> = characterScriptedClass.get(charId);

    var char:Null<BaseCharacter> = null;

    if (charScriptClass != null)
    {
      if (charData != null)
      {
        switch (charData.renderType)
        {
          case CharacterRenderType.AnimateAtlas:
            char = AnimateAtlasCharacter.scriptInit(charScriptClass, charId);
          case CharacterRenderType.MultiSparrow:
            char = MultiSparrowCharacter.scriptInit(charScriptClass, charId);
          case CharacterRenderType.Sparrow:
            char = SparrowCharacter.scriptInit(charScriptClass, charId);
          case CharacterRenderType.Packer:
            char = PackerCharacter.scriptInit(charScriptClass, charId);
          case CharacterRenderType.MultiAnimateAtlas:
            char = MultiAnimateAtlasCharacter.scriptInit(charScriptClass, charId);
          default:
            // We're going to assume that the script class does the rendering.
            char = BaseCharacter.scriptInit(charScriptClass, charId, CharacterRenderType.Custom);
        }
      }
    }
    else
    {
      if (charData != null)
      {
        switch (charData.renderType)
        {
          case CharacterRenderType.AnimateAtlas:
            char = new AnimateAtlasCharacter(charId);
          case CharacterRenderType.MultiSparrow:
            char = new MultiSparrowCharacter(charId);
          case CharacterRenderType.Sparrow:
            char = new SparrowCharacter(charId);
          case CharacterRenderType.Packer:
            char = new PackerCharacter(charId);
          case CharacterRenderType.MultiAnimateAtlas:
            char = new MultiAnimateAtlasCharacter(charId);
          default:
            trace(' WARNING '.warning() + ' Instantiating character with undefined renderType ${charData.renderType}');
            char = new BaseCharacter(charId, CharacterRenderType.Custom);
        }
      }
    }

    if (char == null)
    {
      trace('Failed to instantiate character: ${charId}');
      return null;
    }

    trace('Successfully instantiated character (${debug ? 'debug' : 'stable'}): ${charId}');

    char.debug = debug;

    // Call onCreate only in the fetchCharacter() function, not at application initialization.
    var event:ScriptEvent = ScriptEvent.get(CREATE);
    ScriptEventDispatcher.callEvent(char, event);
    event.finish();

    return char;
  }

  /**
   * Fetches just the character data for a character.
   * @param charId The character ID to fetch.
   * @return The character data, or null if the character was not found.
   */
  public static function fetchCharacterData(charId:String):Null<CharacterData>
  {
    if (characterCache.exists(charId)) return characterCache.get(charId);

    return null;
  }

  /**
   * Lists all the valid character IDs.
   * @return An array of character IDs.
   */
  public static function listCharacterIds():Array<String>
  {
    return characterCache.keys().array();
  }

  /**
   * Returns the idle frame of a character.
   * TODO: Too similar to the other function in PixellatedIcon and really needs a damn rewrite.
   */
  public static function getCharPixelIconAsset(char:String):Null<FlxFrame>
  {
    var charPath:String = 'ui/freeplay/characters/';

    var charIDParts:Array<String> = char.split('-');
    var iconName:String = '';
    var lastValidIconName:String = '';
    for (i in 0...charIDParts.length)
    {
      iconName += charIDParts[i];

      if (Paths.image(charPath + '${iconName}', false).exists())
      {
        lastValidIconName = iconName;
      }

      if (i < charIDParts.length - 1) iconName += '-';
    }

    charPath += '${lastValidIconName}';

    var assetPath:AssetPath = Paths.image(charPath, false).withPixelData();

    if (!assetPath.exists())
    {
      trace(' WARNING '.warning() + ' Character ${char} has no freeplay icon.');
      return null;
    }

    var isAnimated = assetPath.withAssetType(XML).exists();

    var frame:Null<FlxFrame> = null;

    if (isAnimated)
    {
      var frames = Assets.getSparrowAtlas(assetPath);

      var idleFrame:Null<FlxFrame> = frames.frames.find(function(frame:FlxFrame):Bool
      {
        return frame.name.startsWith('idle');
      });

      if (idleFrame == null)
      {
        trace(' WARNING '.warning() + ' Character ${char} has no idle in their freeplay icon.');
        return null;
      }

      // so, haxe.ui.backend.AssetsImpl uses the parent width and height, which makes the image go crazy when rendered
      // so this is a work around so that it uses the actual width and height
      var imageGraphic = flixel.graphics.FlxGraphic.fromFrame(idleFrame);

      var imageFrame = flixel.graphics.frames.FlxImageFrame.fromImage(imageGraphic);
      frame = imageFrame.frame;
    }
    else
    {
      var imageFrame = flixel.graphics.frames.FlxImageFrame.fromImage(assetPath.toFlxGraphicAsset());
      frame = imageFrame.frame;
    }

    return frame;
  }

  /**
   * Clears the character data cache.
   */
  static function clearCharacterCache():Void
  {
    if (characterCache != null)
    {
      characterCache.clear();
    }
    if (characterScriptedClass != null)
    {
      characterScriptedClass.clear();
    }
  }

  /**
   * Load a character's JSON file and parse its data.
   *
   * @param charId The character to load.
   * @return The character data, or null if validation failed.
   */
  public static function parseCharacterData(charId:String):Null<CharacterData>
  {
    var rawJson:String = loadCharacterFile(charId);

    var charData:Null<CharacterData> = migrateCharacterData(rawJson, charId);

    return validateCharacterData(charId, charData);
  }

  static function loadCharacterFile(charPath:String):String
  {
    var result:JsonFile = funkin.modding.compat.RegistryData.loadEntryData(charPath, '', DATA_FILE_PATH, true);

    return result.contents;
  }

  static function migrateCharacterData(rawJson:String, charId:String):Null<CharacterData>
  {
    // If you update the character data format in a breaking way,
    // handle migration here by checking the `version` value.

    try
    {
      var charData:CharacterData = cast Json.parse(rawJson);
      return charData;
    }
    catch (e)
    {
      trace(' Error parsing data for character: ${charId}');
      trace('   ${e}');
      return null;
    }
  }

  /**
   * The default time the character should sing for, in steps.
   * Values that are too low will cause the character to stop singing between notes.
   * Values that are too high will cause the character to hold their singing pose for too long after they're done.
   * @default `8 steps`
   */
  public static final DEFAULT_SINGTIME:Float = 8.0;

  public static final DEFAULT_DANCEEVERY:Float = 1.0;
  public static final DEFAULT_FLIPX:Bool = false;
  public static final DEFAULT_FLIPY:Bool = false;
  public static final DEFAULT_FRAMERATE:Int = 24;
  public static final DEFAULT_ISPIXEL:Bool = false;
  public static final DEFAULT_LOOP:Bool = false;
  public static final DEFAULT_NAME:String = 'Untitled Character';
  public static final DEFAULT_OFFSETS:Array<Float> = [0, 0];
  public static final DEFAULT_HEALTHICON_OFFSETS:Array<Int> = [0, 25];
  public static final DEFAULT_SHOULDBOP:Bool = true;
  public static final DEFAULT_RENDERTYPE:CharacterRenderType = CharacterRenderType.Sparrow;
  public static final DEFAULT_SCALE:Float = 1;
  public static final DEFAULT_SCROLL:Array<Float> = [0, 0];
  public static final DEFAULT_STARTINGANIM:String = 'idle';
  public static final DEFAULT_APPLYSTAGEMATRIX:Bool = false;
  public static final DEFAULT_ANIMTYPE:String = 'framelabel';
  public static final DEFAULT_ATLASSETTINGS:funkin.data.stage.StageData.TextureAtlasData = {
    swfMode: true,
    cacheOnLoad: false,
    filterQuality: 1,
    applyStageMatrix: false,
    useRenderTexture: false,
    postStageMatrixApply: false
  };

  /**
   * Set unspecified parameters to their defaults.
   * If the parameter is mandatory, print an error message.
   * @param id
   * @param input
   * @return The validated character data
   */
  static function validateCharacterData(id:String, input:Null<CharacterData>):Null<CharacterData>
  {
    if (input == null)
    {
      trace('ERROR: Could not parse character data for "${id}".');
      return null;
    }

    if (input.version == null)
    {
      trace('WARN: No semantic version specified for character data file "$id", assuming ${CHARACTER_DATA_VERSION}');
      input.version = CHARACTER_DATA_VERSION;
    }

    if (!VersionUtil.validateVersionStr(input.version, CHARACTER_DATA_VERSION_RULE))
    {
      trace('ERROR: Could not load character data for "$id": bad version (got ${input.version}, expected ${CHARACTER_DATA_VERSION_RULE})');
      return null;
    }

    if (input.name == null)
    {
      trace('WARN: Character data for "$id" missing name');
      input.name = DEFAULT_NAME;
    }

    if (input.renderType == null)
    {
      input.renderType = DEFAULT_RENDERTYPE;
    }

    if (input.assetPath == null)
    {
      trace('ERROR: Could not load character data for "$id": missing assetPath');
      return null;
    }

    if (input.offsets == null)
    {
      input.offsets = DEFAULT_OFFSETS;
    }

    if (input.cameraOffsets == null)
    {
      input.cameraOffsets = DEFAULT_OFFSETS;
    }

    if (input.healthIcon == null)
    {
      input.healthIcon = {
        id: null,
        shouldBop: null,
        scale: null,
        flipX: null,
        isPixel: null,
        offsets: null
      };
    }

    if (input.healthIcon.id == null)
    {
      input.healthIcon.id = id;
    }

    if (input.healthIcon.shouldBop == null)
    {
      input.healthIcon.shouldBop = DEFAULT_SHOULDBOP;
    }

    if (input.healthIcon.scale == null)
    {
      input.healthIcon.scale = DEFAULT_SCALE;
    }

    if (input.healthIcon.flipX == null)
    {
      input.healthIcon.flipX = DEFAULT_FLIPX;
    }

    if (input.healthIcon.offsets == null)
    {
      input.healthIcon.offsets = DEFAULT_OFFSETS;
    }

    if (input.startingAnimation == null)
    {
      input.startingAnimation = DEFAULT_STARTINGANIM;
    }

    if (input.scale == null)
    {
      input.scale = DEFAULT_SCALE;
    }

    if (input.isPixel == null)
    {
      input.isPixel = DEFAULT_ISPIXEL;
    }

    if (input.healthIcon.isPixel == null)
    {
      input.healthIcon.isPixel = input.isPixel;
    }

    if (input.danceEvery == null)
    {
      input.danceEvery = DEFAULT_DANCEEVERY;
    }

    if (input.singTime == null)
    {
      input.singTime = DEFAULT_SINGTIME;
    }

    if (input.animations == null || input.animations.length == 0)
    {
      trace('ERROR: Could not load character data for "$id": missing animations');
      input.animations = [];
    }

    if (input.flipX == null)
    {
      input.flipX = DEFAULT_FLIPX;
    }

    if (input.applyStageMatrix == null)
    {
      input.applyStageMatrix = DEFAULT_APPLYSTAGEMATRIX;
    }

    if (input.atlasSettings == null)
    {
      input.atlasSettings = DEFAULT_ATLASSETTINGS;
    }

    if (input.animations.length == 0 && input.startingAnimation != null)
    {
      return null;
    }

    for (inputAnimation in input.animations)
    {
      if (inputAnimation.name == null)
      {
        trace('ERROR: Could not load character data for "$id": missing animation name for prop "${input.name}"');
        return null;
      }

      if (inputAnimation.frameRate == null)
      {
        inputAnimation.frameRate = DEFAULT_FRAMERATE;
      }

      if (inputAnimation.offsets == null)
      {
        inputAnimation.offsets = DEFAULT_OFFSETS;
      }

      if (inputAnimation.looped == null)
      {
        inputAnimation.looped = DEFAULT_LOOP;
      }

      if (inputAnimation.flipX == null)
      {
        inputAnimation.flipX = DEFAULT_FLIPX;
      }

      if (inputAnimation.flipY == null)
      {
        inputAnimation.flipY = DEFAULT_FLIPY;
      }

      if (inputAnimation.animType == null)
      {
        inputAnimation.animType = DEFAULT_ANIMTYPE;
      }
    }

    // All good!
    return input;
  }

  static function log(message:String):Void
  {
    trace(' CHARACTER '.bold().bg_note_down() + ' $message');
  }
}

/**
 * Describes the available rendering types for a character.
 */
enum abstract CharacterRenderType(String) from String to String
{
  /**
   * Renders the character using a single spritesheet and XML data.
   */
  public var Sparrow = 'sparrow';

  /**
   * Renders the character using a single spritesheet and TXT data.
   */
  public var Packer = 'packer';

  /**
   * Renders the character using multiple spritesheets and XML data.
   */
  public var MultiSparrow = 'multisparrow';

  /**
   * Renders the character using a single spritesheet of symbols and JSON data.
   */
  public var AnimateAtlas = 'animateatlas';

  /**
   * Renders the character using multiple spritesheets of symbols and JSON data.
   */
  public var MultiAnimateAtlas = 'multianimateatlas';

  /**
   * Renders the character using a custom method.
   */
  public var Custom = 'custom';
}

/**
 * The JSON data schema used to define a character.
 */
typedef CharacterData =
{
  /**
   * The semantic version number of the character data JSON format.
   */
  var version:String;

  /**
   * The readable name of the character.
   */
  var name:String;

  /**
   * The type of rendering system to use for the character.
   * @default sparrow
   */
  var renderType:CharacterRenderType;

  /**
   * Behavior varies by render type:
   * - SPARROW: Path to retrieve both the spritesheet and the XML data from.
   * - PACKER: Path to retrieve both the spritesheet and the TXT data from.
   */
  var assetPath:String;

  /**
   * The scale of the graphic as a float.
   * Pro tip: On pixel-art levels, save the sprites small and set this value to 6 or so to save memory.
   * @default 1
   */
  var scale:Null<Float>;

  /**
   * Optional data about the health icon for the character.
   */
  var healthIcon:Null<HealthIconData>;

  /**
   * Optional data about the death animation for the character.
   */
  var death:Null<DeathData>;

  /**
   * The global offset to the character's position, in pixels.
   * @default [0, 0]
   */
  var offsets:Null<Array<Float>>;

  /**
   * The amount to offset the camera by while focusing on this character.
   * Default value focuses on the character directly.
   * @default [0, 0]
   */
  var cameraOffsets:Array<Float>;

  /**
   * Setting this to true disables anti-aliasing for the character.
   * @default false
   */
  var isPixel:Null<Bool>;

  /**
   * The frequency at which the character will play its idle animation, in beats.
   * Increasing this number will make the character dance less often.
   * Supports up to `0.25` precision.
   * @default `1.0` on characters
   */
  @:optional @:default(1.0)
  var danceEvery:Null<Float>;

  /**
   * The minimum duration that a character will play a note animation for, in beats.
   * If this number is too low, you may see the character start playing the idle animation between notes.
   * If this number is too high, you may see the the character play the sing animation for too long after the notes are gone.
   *
   * Examples:
   * - Daddy Dearest uses a value of `1.525`.
   * @default 1.0
   */
  var singTime:Null<Float>;

  /**
   * An optional array of animations which the character can play.
   */
  var animations:Array<AnimationData>;

  /**
   * If animations are used, this is the name of the animation to play first.
   * @default idle
   */
  var startingAnimation:Null<String>;

  /**
   * Whether or not the whole ass sprite is flipped by default.
   * Useful for characters that could also be played (Pico)
   *
   * @default false
   */
  var flipX:Null<Bool>;

  /**
   * NOTE: This only applies to animate atlas characters.
   *
   * Whether to apply the stage matrix, if it was exported from a symbol instance.
   * Also positions the Texture Atlas as it displays in Animate.
   * Turning this on is only recommended if you prepositioned the character in Animate.
   * For other cases, it should be turned off to act similarly to a normal FlxSprite.
   */
  var applyStageMatrix:Null<Bool>;

  /**
   * Various settings for the prop.
   * Only available for texture atlases.
   */
  @:optional
  var atlasSettings:funkin.data.stage.StageData.TextureAtlasData;

  /**
   * An external image link for the health icon.
   * This is used for Discord Rich Presence.
   */
  @:optional
  var discordRPCImage:Null<String>;
};

/**
 * The JSON data schema used to define the health icon for a character.
 */
typedef HealthIconData =
{
  /**
   * The ID to use for the health icon.
   * @default The character's ID
   */
  var id:Null<String>;

  /**
   * Whether the health icon should bop or not.
   * @default true
   */
  var shouldBop:Null<Bool>;

  /**
   * The scale of the health icon.
   */
  var scale:Null<Float>;

  /**
   * Whether to flip the health icon horizontally.
   * @default false
   */
  var flipX:Null<Bool>;

  /**
   * Multiply scale by 6 and disable antialiasing
   * @default false
   */
  var isPixel:Null<Bool>;

  /**
   * The offset of the health icon, in pixels.
   * @default [0, 25]
   */
  var offsets:Null<Array<Float>>;
}

typedef DeathData =
{
  /**
   * The amount to offset the camera by while focusing on this character as they die.
   * Default value focuses on the character's graphic midpoint.
   * @default [0, 0]
   */
  var ?cameraOffsets:Array<Float>;

  /**
   * The amount to zoom the camera by while focusing on this character as they die.
   * Value is a multiplier of the default camera zoom for the stage.
   * @default 1.0
   */
  var ?cameraZoom:Float;

  /**
   * Impose a delay between when the character reaches `0` health and when the death animation plays.
   * @default 0.0
   */
  var ?preTransitionDelay:Float;
}
