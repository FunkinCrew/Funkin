package funkin.play.stage;

import funkin.data.animation.AnimationData;
import funkin.play.stage.ScriptedStage;
import funkin.play.stage.Stage;
import funkin.util.VersionUtil;
import funkin.util.assets.DataAssets;
import haxe.Json;
import openfl.Assets;

/**
 * Contains utilities for loading and parsing stage data.
 */
class StageDataParser
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final STAGE_DATA_VERSION:String = "1.0.0";

  /**
   * The current version rule check for the stage data format.
   */
  public static final STAGE_DATA_VERSION_RULE:String = "1.0.x";

  static final stageCache:Map<String, Stage> = new Map<String, Stage>();

  static final DEFAULT_STAGE_ID = 'UNKNOWN';

  /**
   * Parses and preloads the game's stage data and scripts when the game starts.
   *
   * If you want to force stages to be reloaded, you can just call this function again.
   */
  public static function loadStageCache():Void
  {
    // Clear any stages that are cached if there were any.
    clearStageCache();
    trace("Loading stage cache...");

    //
    // SCRIPTED STAGES
    //
    var scriptedStageClassNames:Array<String> = ScriptedStage.listScriptClasses();
    trace('  Instantiating ${scriptedStageClassNames.length} scripted stages...');
    for (stageCls in scriptedStageClassNames)
    {
      var stage:Stage = ScriptedStage.init(stageCls, DEFAULT_STAGE_ID);
      if (stage != null)
      {
        trace('    Loaded scripted stage: ${stage.stageName}');
        // Disable the rendering logic for stage until it's loaded.
        // Note that kill() =/= destroy()
        stage.kill();

        // Then store it.
        stageCache.set(stage.stageId, stage);
      }
      else
      {
        trace('    Failed to instantiate scripted stage class: ${stageCls}');
      }
    }

    //
    // UNSCRIPTED STAGES
    //
    var stageIdList:Array<String> = DataAssets.listDataFilesInPath('stages/');
    var unscriptedStageIds:Array<String> = stageIdList.filter(function(stageId:String):Bool {
      return !stageCache.exists(stageId);
    });
    trace('  Instantiating ${unscriptedStageIds.length} non-scripted stages...');
    for (stageId in unscriptedStageIds)
    {
      var stage:Stage;
      try
      {
        stage = new Stage(stageId);
        if (stage != null)
        {
          trace('    Loaded stage data: ${stage.stageName}');
          stageCache.set(stageId, stage);
        }
      }
      catch (e)
      {
        trace('    An error occurred while loading stage data: ${stageId}');
        // Assume error was already logged.
        continue;
      }
    }

    trace('  Successfully loaded ${Lambda.count(stageCache)} stages.');
  }

  public static function fetchStage(stageId:String):Null<Stage>
  {
    if (stageCache.exists(stageId))
    {
      trace('Successfully fetch stage: ${stageId}');
      var stage:Stage = stageCache.get(stageId);
      stage.revive();
      return stage;
    }
    else
    {
      trace('Failed to fetch stage, not found in cache: ${stageId}');
      return null;
    }
  }

  static function clearStageCache():Void
  {
    if (stageCache != null)
    {
      for (stage in stageCache)
      {
        stage.destroy();
      }
      stageCache.clear();
    }
  }

  /**
   * Load a stage's JSON file, parse its data, and return it.
   *
   * @param stageId The stage to load.
   * @return The stage data, or null if validation failed.
   */
  public static function parseStageData(stageId:String):Null<StageData>
  {
    var rawJson:String = loadStageFile(stageId);

    var stageData:StageData = migrateStageData(rawJson, stageId);

    return validateStageData(stageId, stageData);
  }

  public static function listStageIds():Array<String>
  {
    return stageCache.keys().array();
  }

  static function loadStageFile(stagePath:String):String
  {
    var stageFilePath:String = Paths.json('stages/${stagePath}');
    var rawJson = Assets.getText(stageFilePath).trim();

    while (!rawJson.endsWith("}"))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }

  static function migrateStageData(rawJson:String, stageId:String):Null<StageData>
  {
    // If you update the stage data format in a breaking way,
    // handle migration here by checking the `version` value.

    try
    {
      var parser = new json2object.JsonParser<StageData>();
      parser.fromJson(rawJson, '$stageId.json');

      if (parser.errors.length > 0)
      {
        trace('[STAGE] Failed to parse stage data');

        for (error in parser.errors)
          funkin.data.DataError.printError(error);

        return null;
      }
      return parser.value;
    }
    catch (e)
    {
      trace('  Error parsing data for stage: ${stageId}');
      trace('    ${e}');
      return null;
    }
  }

  static final DEFAULT_ANIMTYPE:String = "sparrow";
  static final DEFAULT_CAMERAZOOM:Float = 1.0;
  static final DEFAULT_DANCEEVERY:Int = 0;
  static final DEFAULT_ISPIXEL:Bool = false;
  static final DEFAULT_NAME:String = "Untitled Stage";
  static final DEFAULT_OFFSETS:Array<Float> = [0, 0];
  static final DEFAULT_CAMERA_OFFSETS_BF:Array<Float> = [-100, -100];
  static final DEFAULT_CAMERA_OFFSETS_DAD:Array<Float> = [150, -100];
  static final DEFAULT_POSITION:Array<Float> = [0, 0];
  static final DEFAULT_SCALE:Float = 1.0;
  static final DEFAULT_ALPHA:Float = 1.0;
  static final DEFAULT_SCROLL:Array<Float> = [0, 0];
  static final DEFAULT_ZINDEX:Int = 0;

  static final DEFAULT_CHARACTER_DATA:StageDataCharacter =
    {
      zIndex: DEFAULT_ZINDEX,
      position: DEFAULT_POSITION,
      cameraOffsets: DEFAULT_OFFSETS,
    }

  /**
   * Set unspecified parameters to their defaults.
   * If the parameter is mandatory, print an error message.
   * @param id
   * @param input
   * @return The validated stage data
   */
  static function validateStageData(id:String, input:StageData):Null<StageData>
  {
    if (input == null)
    {
      trace('ERROR: Could not parse stage data for "${id}".');
      return null;
    }

    if (input.version == null)
    {
      trace('ERROR: Could not load stage data for "$id": missing version');
      return null;
    }

    if (!VersionUtil.validateVersionStr(input.version, STAGE_DATA_VERSION_RULE))
    {
      trace('ERROR: Could not load stage data for "$id": bad version (got ${input.version}, expected ${STAGE_DATA_VERSION_RULE})');
      return null;
    }

    if (input.name == null)
    {
      trace('WARN: Stage data for "$id" missing name');
      input.name = DEFAULT_NAME;
    }

    if (input.cameraZoom == null)
    {
      input.cameraZoom = DEFAULT_CAMERAZOOM;
    }

    if (input.props == null)
    {
      input.props = [];
    }

    for (inputProp in input.props)
    {
      // It's fine for inputProp.name to be null

      if (inputProp.assetPath == null)
      {
        trace('ERROR: Could not load stage data for "$id": missing assetPath for prop "${inputProp.name}"');
        return null;
      }

      if (inputProp.position == null)
      {
        inputProp.position = DEFAULT_POSITION;
      }

      if (inputProp.zIndex == null)
      {
        inputProp.zIndex = DEFAULT_ZINDEX;
      }

      if (inputProp.isPixel == null)
      {
        inputProp.isPixel = DEFAULT_ISPIXEL;
      }

      if (inputProp.danceEvery == null)
      {
        inputProp.danceEvery = DEFAULT_DANCEEVERY;
      }

      if (inputProp.animType == null)
      {
        inputProp.animType = DEFAULT_ANIMTYPE;
      }

      switch (inputProp.scale)
      {
        case null:
          inputProp.scale = Right([DEFAULT_SCALE, DEFAULT_SCALE]);
        case Left(value):
          inputProp.scale = Right([value, value]);
        case Right(_):
          // Do nothing
      }

      switch (inputProp.scroll)
      {
        case null:
          inputProp.scroll = Right(DEFAULT_SCROLL);
        case Left(value):
          inputProp.scroll = Right([value, value]);
        case Right(_):
          // Do nothing
      }

      if (inputProp.alpha == null)
      {
        inputProp.alpha = DEFAULT_ALPHA;
      }

      if (inputProp.animations == null)
      {
        inputProp.animations = [];
      }

      if (inputProp.animations.length == 0 && inputProp.startingAnimation != null)
      {
        trace('ERROR: Could not load stage data for "$id": missing animations for prop "${inputProp.name}"');
        return null;
      }

      for (inputAnimation in inputProp.animations)
      {
        if (inputAnimation.name == null)
        {
          trace('ERROR: Could not load stage data for "$id": missing animation name for prop "${inputProp.name}"');
          return null;
        }

        if (inputAnimation.frameRate == null)
        {
          inputAnimation.frameRate = 24;
        }

        if (inputAnimation.offsets == null)
        {
          inputAnimation.offsets = DEFAULT_OFFSETS;
        }

        if (inputAnimation.looped == null)
        {
          inputAnimation.looped = true;
        }

        if (inputAnimation.flipX == null)
        {
          inputAnimation.flipX = false;
        }

        if (inputAnimation.flipY == null)
        {
          inputAnimation.flipY = false;
        }
      }
    }

    if (input.characters == null)
    {
      trace('ERROR: Could not load stage data for "$id": missing characters');
      return null;
    }

    if (input.characters.bf == null)
    {
      input.characters.bf = DEFAULT_CHARACTER_DATA;
      input.characters.bf.cameraOffsets = DEFAULT_CAMERA_OFFSETS_BF;
    }
    if (input.characters.dad == null)
    {
      input.characters.dad = DEFAULT_CHARACTER_DATA;
      input.characters.dad.cameraOffsets = DEFAULT_CAMERA_OFFSETS_DAD;
    }
    if (input.characters.gf == null)
    {
      input.characters.gf = DEFAULT_CHARACTER_DATA;
    }

    for (inputCharacter in [input.characters.bf, input.characters.dad, input.characters.gf])
    {
      if (inputCharacter.zIndex == null)
      {
        inputCharacter.zIndex = 0;
      }
      if (inputCharacter.position == null || inputCharacter.position.length != 2)
      {
        inputCharacter.position = [0, 0];
      }
      if (inputCharacter.cameraOffsets == null || inputCharacter.cameraOffsets.length != 2)
      {
        if (inputCharacter == input.characters.bf) inputCharacter.cameraOffsets = DEFAULT_CAMERA_OFFSETS_BF;
        else if (inputCharacter == input.characters.dad) inputCharacter.cameraOffsets = DEFAULT_CAMERA_OFFSETS_DAD;
        else
        {
          inputCharacter.cameraOffsets = [0, 0];
        }
      }
    }

    // All good!
    return input;
  }
}

class StageData
{
  /**
   * The sematic version number of the stage data JSON format.
   * Supports fancy comparisons like NPM does it's neat.
   */
  public var version:String;

  public var name:String;
  public var cameraZoom:Null<Float>;
  public var props:Array<StageDataProp>;
  public var characters:StageDataCharacters;

  public function new()
  {
    this.version = StageDataParser.STAGE_DATA_VERSION;
  }

  /**
   * Convert this StageData into a JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    var writer = new json2object.JsonWriter<StageData>();
    return writer.write(this, pretty ? '  ' : null);
  }
}

typedef StageDataCharacters =
{
  var bf:StageDataCharacter;
  var dad:StageDataCharacter;
  var gf:StageDataCharacter;
};

typedef StageDataProp =
{
  /**
   * The name of the prop for later lookup by scripts.
   * Optional; if unspecified, the prop can't be referenced by scripts.
   */
  @:optional
  var name:String;

  /**
   * The asset used to display the prop.
   */
  var assetPath:String;

  /**
   * The position of the prop as an [x, y] array of two floats.
   */
  var position:Array<Float>;

  /**
   * A number determining the stack order of the prop, relative to other props and the characters in the stage.
   * Props with lower numbers render below those with higher numbers.
   * This is just like CSS, it isn't hard.
   * @default 0
   */
  @:optional
  @:default(0)
  var zIndex:Int;

  /**
   * If set to true, anti-aliasing will be forcibly disabled on the sprite.
   * This prevents blurry images on pixel-art levels.
   * @default false
   */
  @:optional
  @:default(false)
  var isPixel:Bool;

  /**
   * Either the scale of the prop as a float, or the [w, h] scale as an array of two floats.
   * Pro tip: On pixel-art levels, save the sprite small and set this value to 6 or so to save memory.
   */
  @:jcustomparse(funkin.data.DataParse.eitherFloatOrFloats)
  @:jcustomwrite(funkin.data.DataWrite.eitherFloatOrFloats)
  @:optional
  var scale:haxe.ds.Either<Float, Array<Float>>;

  /**
   * The alpha of the prop, as a float.
   * @default 1.0
   */
  @:optional
  @:default(1.0)
  var alpha:Float;

  /**
   * If not zero, this prop will play an animation every X beats of the song.
   * This requires animations to be defined. If `danceLeft` and `danceRight` are defined,
   * they will alternated between, otherwise the `idle` animation will be used.
   *
   * @default 0
   */
  @:default(0)
  @:optional
  var danceEvery:Int;

  /**
   * How much the prop scrolls relative to the camera. Used to create a parallax effect.
   * Represented as a float or as an [x, y] array of two floats.
   * [1, 1] means the prop moves 1:1 with the camera.
   * [0.5, 0.5] means the prop half as much as the camera.
   * [0, 0] means the prop is not moved.
   * @default [0, 0]
   */
  @:jcustomparse(funkin.data.DataParse.eitherFloatOrFloats)
  @:jcustomwrite(funkin.data.DataWrite.eitherFloatOrFloats)
  @:optional
  var scroll:haxe.ds.Either<Float, Array<Float>>;

  /**
   * An optional array of animations which the prop can play.
   * @default Prop has no animations.
   */
  @:optional
  var animations:Array<AnimationData>;

  /**
   * If animations are used, this is the name of the animation to play first.
   * @default Don't play an animation.
   */
  @:optional
  var startingAnimation:Null<String>;

  /**
   * The animation type to use.
   * Options: "sparrow", "packer"
   * @default "sparrow"
   */
  @:default("sparrow")
  @:optional
  var animType:String;
};

typedef StageDataCharacter =
{
  /**
   * A number determining the stack order of the character, relative to props and other characters in the stage.
   * Again, just like CSS.
   * @default 0
   */
  @:optional
  @:default(0)
  var zIndex:Int;

  /**
   * The position to render the character at.
   */
  @:optional
  @:default([0, 0])
  var position:Array<Float>;

  /**
   * The camera offsets to apply when focusing on the character on this stage.
   * @default [-100, -100] for BF, [100, -100] for DAD/OPPONENT, [0, 0] for GF
   */
  @:optional
  @:default([0, 0])
  var cameraOffsets:Array<Float>;
};
