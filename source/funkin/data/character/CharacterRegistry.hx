package funkin.data.character;

import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData;
import funkin.data.character.migrator.CharacterData_v1_0_0;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.BaseCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.PackerCharacter;
import funkin.play.character.SparrowCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedAnimateAtlasCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedBaseCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedMultiSparrowCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedPackerCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedSparrowCharacter;
import funkin.util.assets.DataAssets;
import funkin.util.VersionUtil;
import haxe.Json;
import flixel.graphics.frames.FlxFrame;

using funkin.data.character.migrator.CharacterDataMigrator;

/**
 * NOTE: This doesn't act the same as the other registries.
 * It doesn't implement `BaseRegistry` and fetching produces a new instance rather than reusing them.
 */
class CharacterRegistry
{
  /**
   * The current version string for the character data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateCharacterData()` function.
   */
  public static final CHARACTER_DATA_VERSION:String = '1.1.0';

  /**
   * The current version rule check for the stage data format.
   */
  public static final CHARACTER_DATA_VERSION_RULE:String = '1.1.x';

  static final characterCache:Map<String, CharacterData> = new Map<String, CharacterData>();
  static final characterScriptedClass:Map<String, String> = new Map<String, String>();

  static final DEFAULT_CHAR_ID:String = 'UNKNOWN';

  /**
   * Parses and preloads the game's stage data and scripts when the game starts.
   *
   * If you want to force stages to be reloaded, you can just call this function again.
   */
  public static function loadCharacterCache():Void
  {
    // Clear any stages that are cached if there were any.
    clearCharacterCache();
    trace('[CHARACTER] Parsing all entries...');

    //
    // UNSCRIPTED CHARACTERS
    //
    var charIdList:Array<String> = DataAssets.listDataFilesInPath('characters/');
    var unscriptedCharIds:Array<String> = charIdList.filter(function(charId:String):Bool {
      return !characterCache.exists(charId);
    });
    trace('  Fetching data for ${unscriptedCharIds.length} characters...');
    for (charId in unscriptedCharIds)
    {
      try
      {
        var charData:CharacterData = parseCharacterData(charId);
        if (charData != null)
        {
          trace('    Loaded character data: ${charId}');
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

    var scriptedCharClassNames1:Array<String> = ScriptedSparrowCharacter.listScriptClasses();
    if (scriptedCharClassNames1.length > 0)
    {
      trace('  Instantiating ${scriptedCharClassNames1.length} (Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames1)
      {
        try
        {
          var character:SparrowCharacter = ScriptedSparrowCharacter.init(charCls, DEFAULT_CHAR_ID);
          trace('  Initialized character ${character.characterName}');
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          trace('    FAILED to instantiate scripted Sparrow character: ${charCls}');
          trace(e);
        }
      }
    }

    var scriptedCharClassNames2:Array<String> = ScriptedPackerCharacter.listScriptClasses();
    if (scriptedCharClassNames2.length > 0)
    {
      trace('  Instantiating ${scriptedCharClassNames2.length} (Packer) scripted characters...');
      for (charCls in scriptedCharClassNames2)
      {
        try
        {
          var character:PackerCharacter = ScriptedPackerCharacter.init(charCls, DEFAULT_CHAR_ID);
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          trace('    FAILED to instantiate scripted Packer character: ${charCls}');
          trace(e);
        }
      }
    }

    var scriptedCharClassNames3:Array<String> = ScriptedMultiSparrowCharacter.listScriptClasses();
    if (scriptedCharClassNames3.length > 0)
    {
      trace('  Instantiating ${scriptedCharClassNames3.length} (Multi-Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames3)
      {
        try
        {
          var character:MultiSparrowCharacter = ScriptedMultiSparrowCharacter.init(charCls, DEFAULT_CHAR_ID);
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          trace('    FAILED to instantiate scripted Multi-Sparrow character: ${charCls}');
          trace(e);
        }
      }
    }

    var scriptedCharClassNames4:Array<String> = ScriptedAnimateAtlasCharacter.listScriptClasses();
    if (scriptedCharClassNames4.length > 0)
    {
      trace('  Instantiating ${scriptedCharClassNames4.length} (Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames4)
      {
        try
        {
          var character:AnimateAtlasCharacter = ScriptedAnimateAtlasCharacter.init(charCls, DEFAULT_CHAR_ID);
          characterScriptedClass.set(character.characterId, charCls);
        }
        catch (e)
        {
          trace('    FAILED to instantiate scripted Animate Atlas character: ${charCls}');
          trace(e);
        }
      }
    }

    // NOTE: Only instantiate the ones not populated above.
    // ScriptedBaseCharacter.listScriptClasses() will pick up scripts extending the other classes.
    var scriptedCharClassNames:Array<String> = ScriptedBaseCharacter.listScriptClasses();
    scriptedCharClassNames = scriptedCharClassNames.filter(function(charCls:String):Bool {
      return !(scriptedCharClassNames1.contains(charCls)
        || scriptedCharClassNames2.contains(charCls)
        || scriptedCharClassNames3.contains(charCls)
        || scriptedCharClassNames4.contains(charCls));
    });

    if (scriptedCharClassNames.length > 0)
    {
      trace('  Instantiating ${scriptedCharClassNames.length} (Base) scripted characters...');
      for (charCls in scriptedCharClassNames)
      {
        var character:BaseCharacter = ScriptedBaseCharacter.init(charCls, DEFAULT_CHAR_ID, Custom);
        if (character == null)
        {
          trace('    Failed to instantiate scripted character: ${charCls}');
          continue;
        }
        else
        {
          trace('    Successfully instantiated scripted character: ${charCls}');
          characterScriptedClass.set(character.characterId, charCls);
        }
      }
    }

    trace('  Successfully loaded ${Lambda.count(characterCache)} stages.');
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

    var charData:CharacterData = characterCache.get(charId);
    var charScriptClass:String = characterScriptedClass.get(charId);

    var char:BaseCharacter;

    if (charScriptClass != null)
    {
      switch (charData.renderType)
      {
        case CharacterRenderType.AnimateAtlas:
          char = ScriptedAnimateAtlasCharacter.init(charScriptClass, charId);
        case CharacterRenderType.MultiSparrow:
          char = ScriptedMultiSparrowCharacter.init(charScriptClass, charId);
        case CharacterRenderType.Sparrow:
          char = ScriptedSparrowCharacter.init(charScriptClass, charId);
        case CharacterRenderType.Packer:
          char = ScriptedPackerCharacter.init(charScriptClass, charId);
        default:
          // We're going to assume that the script class does the rendering.
          char = ScriptedBaseCharacter.init(charScriptClass, charId, CharacterRenderType.Custom);
      }
    }
    else
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
        default:
          trace('[WARN] Creating character with undefined renderType ${charData.renderType}');
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
  public static function getCharPixelIconAsset(char:String):FlxFrame
  {
    var charPath:String = "freeplay/icons/";

    // FunkinCrew please dont skin me alive for copying pixelated icon and changing it a tiny bit
    switch (char)
    {
      case "bf-christmas" | "bf-car" | "bf-pixel" | "bf-holding-gf" | "bf-dark":
        charPath += "bfpixel";
      case "monster-christmas":
        charPath += "monsterpixel";
      case "mom" | "mom-car":
        charPath += "mommypixel";
      case "pico-blazin" | "pico-playable" | "pico-speaker":
        charPath += "picopixel";
      case "gf-christmas" | "gf-car" | "gf-pixel" | "gf-tankmen" | "gf-dark":
        charPath += "gfpixel";
      case "dad":
        charPath += "dadpixel";
      case "darnell-blazin":
        charPath += "darnellpixel";
      case "senpai-angry":
        charPath += "senpaipixel";
      case "spooky-dark":
        charPath += "spookypixel";
      case "tankman-atlas":
        charPath += "tankmanpixel";
      case "pico-christmas" | "pico-dark":
        charPath += "picopixel";
      default:
        charPath += '${char}pixel';
    }

    if (!Assets.exists(Paths.image(charPath)))
    {
      trace('[WARN] Character ${char} has no freeplay icon.');
      return null;
    }

    var isAnimated = Assets.exists(Paths.file('images/$charPath.xml'));
    var frame:FlxFrame = null;

    if (isAnimated)
    {
      var frames = Paths.getSparrowAtlas(charPath);

      var idleFrame:FlxFrame = frames.frames.find(function(frame:FlxFrame):Bool {
        return frame.name.startsWith('idle');
      });

      if (idleFrame == null)
      {
        trace('[WARN] Character ${char} has no idle in their freeplay icon.');
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
    var rawJson:JsonFile = loadCharacterFile(charId);

    var version = fetchEntryVersion(rawJson);

    if (version == null)
    {
      return null;
    }

    var data:Null<CharacterData> = null;

    if (CHARACTER_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, CHARACTER_DATA_VERSION_RULE))
    {
      data = buildCharacterData(rawJson, charId);
    }
    else if (VersionUtil.validateVersion(version, "1.0.x"))
    {
      data = buildCharacterData_v1_0_0(rawJson, charId);
    }
    else
    {
      trace('[CHARACTER] Could not load character data for "$charId": bad version (got ${version}, expected ${CHARACTER_DATA_VERSION_RULE})');
      return null;
    }

    return validateCharacterData(charId, data);
  }

  static function loadCharacterFile(charPath:String):JsonFile
  {
    var charFilePath:String = Paths.json('characters/${charPath}');
    var rawJson = Assets.getText(charFilePath).trim();

    while (!StringTools.endsWith(rawJson, '}'))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return {
      fileName: charFilePath,
      contents: rawJson
    };
  }

  static function fetchEntryVersion(rawJson:JsonFile):Null<thx.semver.Version>
  {
    return VersionUtil.getVersionFromJSON(rawJson.contents);
  }

  static function buildCharacterData(rawJson:JsonFile, charId:String):Null<CharacterData>
  {
    var parser = new json2object.JsonParser<CharacterData>();
    parser.ignoreUnknownVariables = false;

    switch (rawJson)
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      trace(parser.errors, charId);
      return null;
    }

    return parser.value;
  }

  static function buildCharacterData_v1_0_0(rawJson:JsonFile, charId:String):Null<CharacterData>
  {
    var parser = new json2object.JsonParser<CharacterData_v1_0_0>();
    parser.ignoreUnknownVariables = false;

    switch (rawJson)
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      trace(parser.errors, charId);
      return null;
    }

    return parser.value.migrate();
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

  /**
   * Set unspecified parameters to their defaults.
   * If the parameter is mandatory, print an error message.
   * @param id
   * @param input
   * @return The validated character data
   */
  static function validateCharacterData(id:String, input:CharacterData):Null<CharacterData>
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

    if (input.assetPaths == null)
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
      input.healthIcon =
        {
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
    }

    // All good!
    return input;
  }
}
