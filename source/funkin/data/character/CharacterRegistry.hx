package funkin.data.character;

import funkin.assets.Paths;
import funkin.assets.Assets;
import funkin.data.BaseRegistry;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.DefaultRegistryImpl;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import flixel.graphics.frames.FlxFrame;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.BaseCharacter;
import funkin.play.character.SparrowCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.MultiAnimateAtlasCharacter;
import funkin.play.character.PackerCharacter;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
import funkin.util.tools.ISingleton;
import lime.app.Promise;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end

@:nullSafety
class CharacterRegistry extends BaseRegistry<BaseCharacter, CharacterData, CharacterEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the character data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateCharacterData()` function.
   */
  public static final CHARACTER_DATA_VERSION:thx.semver.Version = '1.0.2';

  public static final CHARACTER_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';
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

  public function new()
  {
    super({
      registryId: 'CHARACTER',
      dataFilePath: 'gameplay/characters/',
      nestedEntries: true,
      versionRule: CHARACTER_DATA_VERSION_RULE
    });
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

  public override function loadEntries():Void
  {
    // Instead of loading the entries, we load the character data.
    log(' INFO '.info() + 'Parsing all entries...');

    var charIdList:Array<String> = fetchEntryIdsFromFiles();
    log('Fetching data for ${charIdList.length} characters characters...');

    for (charId in charIdList)
    {
      try
      {
        var charData:Null<CharacterData> = parseEntryData(charId);
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
  public override function loadEntriesAsync():lime.app.Future<LoadEntriesResult>
  {
    clearEntries();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadCharacterCacheAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();

    var charIdList:Array<String> = fetchEntryIdsFromFiles();
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
        var charData:Null<CharacterData> = parseEntryData(entryId);
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
   * Retrieves a character from the given id and additional parameters.
   * Unlike other registries, this instantiates a new character instead of just re-using an existing entry.
   * @param id The id of the character to fetch.
   * @param params Optional params when loading this character.
   * @return Null<BaseCharacter>
   */
  public override function fetchEntry(id:String, ?params:CharacterEntryParams):Null<BaseCharacter>
  {
    if (id == null || id == '' || !characterCache.exists(id))
    {
      // Gracefully handle songs that don't use this character,
      // or throw an error if the character is missing.

      if (id != null && id != '') trace('Failed to instantiate character, not found in cache: ${id}');
      return null;
    }

    var charData:Null<CharacterData> = characterCache.get(id);
    var charScriptClass:Null<String> = characterScriptedClass.get(id);

    var char:Null<BaseCharacter> = null;

    if (charScriptClass != null)
    {
      if (charData != null)
      {
        switch (charData.renderType)
        {
          case CharacterRenderType.AnimateAtlas:
            char = AnimateAtlasCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.MultiSparrow:
            char = MultiSparrowCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.Sparrow:
            char = SparrowCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.Packer:
            char = PackerCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.MultiAnimateAtlas:
            char = MultiAnimateAtlasCharacter.scriptInit(charScriptClass, id);
          default:
            // We're going to assume that the script class does the rendering.
            char = BaseCharacter.scriptInit(charScriptClass, id, {
              renderType: CharacterRenderType.Custom
            });
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
            char = new AnimateAtlasCharacter(id);
          case CharacterRenderType.MultiSparrow:
            char = new MultiSparrowCharacter(id);
          case CharacterRenderType.Sparrow:
            char = new SparrowCharacter(id);
          case CharacterRenderType.Packer:
            char = new PackerCharacter(id);
          case CharacterRenderType.MultiAnimateAtlas:
            char = new MultiAnimateAtlasCharacter(id);
          default:
            trace(' WARNING '.warning() + ' Instantiating character with undefined renderType ${charData.renderType}');
            char = new BaseCharacter(id, {
              renderType: CharacterRenderType.Custom
            });
        }
      }
    }

    if (char == null)
    {
      trace('Failed to instantiate character: ${id}');
      return null;
    }
    var debug:Bool = params?.debug ?? false;

    trace('Successfully instantiated character (${debug ? 'debug' : 'stable'}): ${id}');

    char.debug = debug;

    // Call onCreate only in the fetchCharacter() function, not at application initialization.
    var event:ScriptEvent = ScriptEvent.get(CREATE);
    ScriptEventDispatcher.callEvent(char, event);
    event.finish();

    return char;
  }

  public override function clearEntries():Void
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

  public override function hasEntry(id:String):Bool
  {
    return characterCache.exists(id);
  }

  public override function countEntries():Int
  {
    return characterCache.size();
  }

  public override function isScriptedEntry(id:String, ?params:CharacterEntryParams):Bool
  {
    return characterScriptedClass.exists(id);
  }

  public override function getScriptedEntryClassName(id:String, ?params:CharacterEntryParams):Null<String>
  {
    return characterScriptedClass.get(id);
  }

  public override function listEntryIds():Array<String>
  {
    return characterCache.keys().array();
  }

  public function parseEntryData(id:String):Null<CharacterData>
  {
    var parser = new json2object.JsonParser<CharacterData>({
      ignoreUnknownVariables: false
    });

    @:privateAccess
    switch (this.loadEntryFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(funkin.util.SerializerUtil.sanitizeJSON(contents), fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      @:privateAccess
      this.printErrors(parser.errors, id);
      return null;
    }

    // Validate character data after parsing.
    return CharacterData.validateCharacterData(id, parser.value);
  }

  /**
   * Fetches just the character data for a character.
   * @param charId The character ID to fetch.
   * @return The character data, or null if the character was not found.
   */
  public function fetchCharacterData(charId:String):Null<CharacterData>
  {
    if (characterCache.exists(charId)) return characterCache.get(charId);

    return null;
  }
}

typedef CharacterEntryParams =
{
  /**
   * Whether this character should be in debug mode when loaded.
   */
  var ?debug:Bool;
}
