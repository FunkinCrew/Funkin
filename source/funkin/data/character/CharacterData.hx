package funkin.data.character;

import funkin.data.animation.AnimationData;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.ScriptedCharacter.ScriptedAnimateAtlasCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedBaseCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedMultiSparrowCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedMultiAnimateAtlasCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedPackerCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedSparrowCharacter;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.BaseCharacter;
import funkin.play.character.SparrowCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.MultiAnimateAtlasCharacter;
import funkin.play.character.PackerCharacter;
import funkin.util.assets.DataAssets;
import funkin.util.VersionUtil;
import haxe.Json;
import flixel.graphics.frames.FlxFrame;

@:nullSafety
class CharacterDataParser
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   *
   * - Version 1.0.1 adds `death.cameraOffsets`
   */
  public static final CHARACTER_DATA_VERSION:String = '1.0.1';

  /**
   * The current version rule check for the stage data format.
   */
  public static final CHARACTER_DATA_VERSION_RULE:String = '1.0.x';

  static final characterCache:Map<String, CharacterData> = new Map<String, CharacterData>();
  static final characterScriptedClass:Map<String, String> = new Map<String, String>();

  static final DEFAULT_CHAR_ID:String = 'UNKNOWN';

  /**
   * Helper function to format variation names from file names.
   * Converts hyphen-separated names to Title Case with spaces.
   * Example: "dark-christmas" becomes "Dark Christmas"
   * NOT AN ACTUAL VARIATION
   */
  static function formatVariationName(variationName:String):String
  {
    if (variationName == null || variationName == '') return '';

    // Replace hyphens with spaces
    var withSpaces:String = variationName.replace('-', ' ');

    // Split into words and capitalize each word
    var words:Array<String> = withSpaces.split(' ');
    var formattedWords:Array<String> = [];

    for (word in words)
    {
      if (word.length > 0)
      {
        // Capitalize first letter, lowercase the rest
        var formattedWord:String = word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
        formattedWords.push(formattedWord);
      }
    }

    return formattedWords.join(' ');
  }

  /**
   * Parses and preloads the game's stage data and scripts when the game starts.
   *
   * If you want to force stages to be reloaded, you can just call this function again.
   */
  public static function loadCharacterCache():Void
  {
    // Clear any stages that are cached if there were any.
    clearCharacterCache();
    log(' INFO '.info() + 'Parsing all entries...');

    // HANDLE CHARACTERS VARIATIONS
    // VariationCharacterName -> {VariationName, TargetCharacter}
    var variationsOnHold:Map<String, {variationName:String, targetCharacter:String}> = [];

    //
    // UNSCRIPTED CHARACTERS
    //
    var charIdList:Array<String> = DataAssets.listDataFilesInPath('characters/');
    var unscriptedCharIds:Array<String> = charIdList.filter(function(charId:String):Bool
    {
      return !characterCache.exists(charId);
    });
    log('Fetching data for ${unscriptedCharIds.length} characters...');
    for (charId in unscriptedCharIds)
    {
      try
      {
        var charData:Null<CharacterData> = parseCharacterData(charId);
        if (charData != null)
        {
          log('Loaded character "${charId}"');
          characterCache.set(charId, charData);

          @:nullSafety(Off)
          // Check if character has variationFor explicitly set to null - if so, skip auto-detection
          var shouldSkipAutoDetection:Bool = false;
          if (charData.variations != null && charData.variations.variationFor == null)
          {
            // Check if variationFor was explicitly set in JSON (not from filename auto-detection)
            // We can check if variationName is also null, or if the character ID has hyphen
            if (charData.variations.variationName == null)
            {
              // Both variationFor and variationName are null, likely explicitly set
              // Check if filename has hyphen but JSON explicitly sets variationFor to null
              if (charId.indexOf('-') != -1)
              {
                // Filename has hyphen but JSON explicitly says no variation
                shouldSkipAutoDetection = true;
                trace('Skipping auto-detection for ${charId}: variationFor explicitly set to null');
              }
            }
          }

          // Only auto-detect if not explicitly skipped and filename has hyphen
          if (!shouldSkipAutoDetection && charId.indexOf('-') != -1)
          {
            var parts:Array<String> = charId.split('-');
            if (parts.length >= 2)
            {
              var baseId:String = parts[0];
              var variationName:String = parts.slice(1).join('-');
              var formattedVariationName:String = formatVariationName(variationName);

              var baseData:Null<CharacterData> = characterCache.get(baseId);
              @:nullSafety(Off)
              if (baseData != null && !baseData.isVariation)
              {
                charData.isVariation = true;
                charData.variations.variationFor = baseId;
                charData.variations.variationName = formattedVariationName;

                if (baseData.variations.variations == null)
                {
                  baseData.variations.variations = new Map<String, String>();
                }
                baseData.variations.variations.set(formattedVariationName, charId);

                trace('Auto-detected variation: ${charId} is variation "${formattedVariationName}" of ${baseId}');
              }
              else if (charData?.variations?.variationName != null && charData?.variations?.variationFor != null)
              {
                @:nullSafety(Off)
                variationsOnHold.set(charId, {variationName: charData.variations.variationName, targetCharacter: charData.variations.variationFor});
              }
            }
          }
          else if (charData?.variations?.variationName != null && charData?.variations?.variationFor != null)
          {
            @:nullSafety(Off)
            variationsOnHold.set(charId, {variationName: charData.variations.variationName, targetCharacter: charData.variations.variationFor});
          }
        }
      }
      catch (e)
      {
        // Assume error was already logged.
        continue;
      }
    }

    // CONCAT VARIATIONS
    @:nullSafety(Off) // i hate you
    for (variationCharacter => variationMicroData in variationsOnHold)
    {
      if (!characterCache.exists(variationMicroData.targetCharacter))
      {
        trace('WARN: Attempted to add "${variationMicroData.variationName}" variation for non-existent "${variationMicroData.targetCharacter}" character!');
        continue;
      }
      final targetCharData = characterCache.get(variationMicroData.targetCharacter);
      if (targetCharData != null)
      {
        targetCharData.variations.variations.set(variationMicroData.variationName, variationCharacter);
        characterCache.get(variationCharacter).isVariation = true;
      }
    }

    //
    // SCRIPTED CHARACTERS
    //

    // Fuck I wish scripted classes supported static functions.

    var scriptedCharClassNames1:Array<String> = ScriptedSparrowCharacter.listScriptClasses();
    if (scriptedCharClassNames1.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames1.length} (Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames1)
      {
        try
        {
          var character:SparrowCharacter = ScriptedSparrowCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          log('Loaded character ${character.characterName} (scripted: $charCls)');
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to initialize scripted Sparrow character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }

    var scriptedCharClassNames2:Array<String> = ScriptedPackerCharacter.listScriptClasses();
    if (scriptedCharClassNames2.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames2.length} (Packer) scripted characters...');
      for (charCls in scriptedCharClassNames2)
      {
        try
        {
          var character:PackerCharacter = ScriptedPackerCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          log('Loaded character ${character.characterName} (scripted: $charCls)');
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to initialize scripted Packer character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }

    var scriptedCharClassNames3:Array<String> = ScriptedMultiSparrowCharacter.listScriptClasses();
    if (scriptedCharClassNames3.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames3.length} (Multi-Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames3)
      {
        try
        {
          var character:MultiSparrowCharacter = ScriptedMultiSparrowCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          log('Loaded character ${character.characterName} (scripted: $charCls)');
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to initialize scripted Multi-Sparrow character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }

    var scriptedCharClassNames4:Array<String> = ScriptedAnimateAtlasCharacter.listScriptClasses();
    if (scriptedCharClassNames4.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames4.length} (Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames4)
      {
        try
        {
          var character:AnimateAtlasCharacter = ScriptedAnimateAtlasCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          log('Loaded character ${character.characterName} (scripted: $charCls)');
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to initialize scripted Animate Atlas character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }

    var scriptedCharClassNames5:Array<String> = ScriptedMultiAnimateAtlasCharacter.listScriptClasses();
    if (scriptedCharClassNames5.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames5.length} (Multi-Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames5)
      {
        try
        {
          var character:MultiAnimateAtlasCharacter = ScriptedMultiAnimateAtlasCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          log('Loaded character ${character.characterName} (scripted: $charCls)');
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to initialize scripted Multi-Animate Atlas character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }

    // NOTE: Only instantiate the ones not populated above.
    // ScriptedBaseCharacter.listScriptClasses() will pick up scripts extending the other classes.
    var scriptedCharClassNames:Array<String> = ScriptedBaseCharacter.listScriptClasses();
    scriptedCharClassNames = scriptedCharClassNames.filter(function(charCls:String):Bool
    {
      return !(scriptedCharClassNames1.contains(charCls)
        || scriptedCharClassNames2.contains(charCls)
        || scriptedCharClassNames3.contains(charCls)
        || scriptedCharClassNames4.contains(charCls)
        || scriptedCharClassNames5.contains(charCls));
    });

    if (scriptedCharClassNames.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames.length} (Base) scripted characters...');
      for (charCls in scriptedCharClassNames)
      {
        var character:BaseCharacter = ScriptedBaseCharacter.scriptInit(charCls, DEFAULT_CHAR_ID, Custom);
        if (character == null)
        {
          log(' ERROR '.error() + 'Failed to initialize scripted character: $charCls');
          continue;
        }
        else
        {
          log('Loaded character ${character.characterName} (scripted: $charCls)');
          characterScriptedClass.set(character.characterId, charCls);
        }
      }
    }

    log(' INFO '.info() + 'Successfully loaded ${characterCache.size()} stages.');
  }

  /**
   * Fetches data for a character and returns a BaseCharacter instance,
   * ready to be added to the scene.
   * @param charId The character ID to fetch.
   * @return The character instance, or null if the character was not found.
   */
  public static function fetchCharacter(charId:String, debug:Bool = false):Null<BaseCharacter>
  {
    if (charId == null || charId == '' || !characterCache.exists(charId))
    {
      // Gracefully handle songs that don't use this character,
      // or throw an error if the character is missing.

      if (charId != null && charId != '') trace('Failed to build character, not found in cache: ${charId}');
      return null;
    }

    var charData:Null<CharacterData> = characterCache.get(charId);
    var charScriptClass:Null<String> = characterScriptedClass.get(charId);

    var char:Null<BaseCharacter> = null;

    if (charScriptClass != null)
    {
      if (charData != null) switch (charData.renderType)
      {
        case CharacterRenderType.AnimateAtlas:
          char = ScriptedAnimateAtlasCharacter.scriptInit(charScriptClass, charId);
        case CharacterRenderType.MultiSparrow:
          char = ScriptedMultiSparrowCharacter.scriptInit(charScriptClass, charId);
        case CharacterRenderType.Sparrow:
          char = ScriptedSparrowCharacter.scriptInit(charScriptClass, charId);
        case CharacterRenderType.Packer:
          char = ScriptedPackerCharacter.scriptInit(charScriptClass, charId);
        case CharacterRenderType.MultiAnimateAtlas:
          char = ScriptedMultiAnimateAtlasCharacter.scriptInit(charScriptClass, charId);
        default:
          // We're going to assume that the script class does the rendering.
          char = ScriptedBaseCharacter.scriptInit(charScriptClass, charId, CharacterRenderType.Custom);
      }
    }
    else
    {
      if (charData != null) switch (charData.renderType)
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
          trace(' WARNING '.warning() + ' Creating character with undefined renderType ${charData.renderType}');
          char = new BaseCharacter(charId, CharacterRenderType.Custom);
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
    ScriptEventDispatcher.callEvent(char, new ScriptEvent(CREATE));

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
   * Gets the base character ID for a variation.
   * @param charId Character ID (can be a variation)
   * @return Base character ID or null
   */
  public static function getBaseCharacterId(charId:String):Null<String>
  {
    if (charId == null || charId == '') return null;

    var charData:Null<CharacterData> = fetchCharacterData(charId);
    if (charData == null) return null;

    if (charData.isVariation && charData.variations != null && charData.variations.variationFor != null)
    {
      return charData.variations.variationFor;
    }

    if (charId.indexOf('-') != -1)
    {
      var parts:Array<String> = charId.split('-');
      var potentialBaseId:String = parts[0];

      var baseData:Null<CharacterData> = fetchCharacterData(potentialBaseId);
      @:nullSafety(Off)
      if (baseData != null && !baseData.isVariation)
      {
        return potentialBaseId;
      }
    }

    return charId;
  }

  /**
   * Gets the variation name for a character.
   * @param charId Character ID
   * @return Variation name or null if not a variation
   */
  public static function getVariationName(charId:String):Null<String>
  {
    if (charId == null || charId == '') return null;

    var charData:Null<CharacterData> = fetchCharacterData(charId);
    if (charData == null) return null;

    if (charData.isVariation && charData.variations != null && charData.variations.variationName != null)
    {
      return charData.variations.variationName;
    }

    if (charId.indexOf('-') != -1)
    {
      var parts:Array<String> = charId.split('-');
      if (parts.length >= 2)
      {
        return formatVariationName(parts.slice(1).join('-'));
      }
    }

    return null;
  }

  public static function getCharVariations(charId:String):Map<String, String>
  {
    var charData:Null<CharacterData> = fetchCharacterData(charId);
    if (charData != null && charData.variations != null && charData.variations.variations != null)
    {
      return charData.variations.variations;
    }
    return new Map<String, String>();
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
   */
  public static function getCharPixelIconAsset(char:String):Null<FlxFrame>
  {
    var charPath:String = "freeplay/icons/";

    final charIDParts:Array<String> = char.split("-");
    var iconName:String = "";
    var lastValidIconName:String = "";
    for (i in 0...charIDParts.length)
    {
      iconName += charIDParts[i];

      if (Assets.exists(Paths.image(charPath + '${iconName}pixel')))
      {
        lastValidIconName = iconName;
      }

      if (i < charIDParts.length - 1) iconName += '-';
    }

    charPath += '${lastValidIconName}pixel';

    if (!Assets.exists(Paths.image(charPath)))
    {
      trace(' WARNING '.warning() + ' Character ${char} has no freeplay icon.');
      return null;
    }

    var isAnimated = Assets.exists(Paths.file('images/$charPath.xml'));
    var frame:Null<FlxFrame> = null;

    if (isAnimated)
    {
      var frames = Paths.getSparrowAtlas(charPath);

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
      var imageFrame = flixel.graphics.frames.FlxImageFrame.fromImage(Paths.image(charPath));
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
    var charFilePath:String = Paths.json('characters/${charPath}');
    var rawJson = Assets.getText(charFilePath).trim();

    while (!StringTools.endsWith(rawJson, '}'))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
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
  public static final DEFAULT_RENDERTYPE:CharacterRenderType = CharacterRenderType.Sparrow;
  public static final DEFAULT_SCALE:Float = 1;
  public static final DEFAULT_SCROLL:Array<Float> = [0, 0];
  public static final DEFAULT_STARTINGANIM:String = 'idle';
  public static final DEFAULT_APPLYSTAGEMATRIX:Bool = false;
  public static final DEFAULT_ANIMTYPE:String = "framelabel";
  public static final DEFAULT_ATLASSETTINGS:funkin.data.stage.StageData.TextureAtlasData = {
    swfMode: true,
    cacheOnLoad: false,
    filterQuality: 1,
    applyStageMatrix: false,
    useRenderTexture: false
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
    if (input.isVariation == null)
    {
      input.isVariation = false;
    }

    if (input.variations == null)
    {
      input.variations =
        {
          variations: new Map<String, String>(),
          variationFor: null,
          variationName: null
        };
    }
    else if (input.variations.variations == null)
    {
      input.variations.variations = new Map<String, String>();
    }

    // If filename contains hyphen, try to determine base character and variation name
    // But only if variationFor is not explicitly set to null in JSON
    if (input.variations.variationFor == null && input.variations.variationName == null && id.indexOf('-') != -1)
    {
      var parts:Array<String> = id.split('-');
      if (parts.length >= 2)
      {
        // Set temporary values, may be overridden in loadCharacterCache
        input.variations.variationFor = parts[0];
        input.variations.variationName = formatVariationName(parts.slice(1).join('-'));
      }
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
   * Optional data about the health icon for the character.
   */
  var variations:Null<VariationsData>;

  @:optional
  @:default(false)
  var isVariation:Null<Bool>;

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
  @:optional
  @:default(1.0)
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
};

typedef VariationsData =
{
  /**
   * Available variations list for character. ([dark => bf-dark, car => bf-car] etc.)
   */
  @:optional
  @:default([])
  var variations:Null<Map<String, String>>;

  /**
   * If current character IS A specific variation of a character, this is the variation name. (Dark, Car, Christmas, Pixel)
   */
  @:optional
  var variationName:Null<String>;

  /**
   * Character's file name which this character is a variation of.
   */
  @:optional
  var variationFor:Null<String>;
}

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
