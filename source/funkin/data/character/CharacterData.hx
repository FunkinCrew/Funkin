package funkin.data.character;

import funkin.data.animation.AnimationData;
import funkin.util.VersionUtil;
@:nullSafety
class CharacterData
{
  /**
   * The semantic version number of the character data JSON format.
   */
  public var version:String;

  /**
   * The readable name of the character.
   */
  public var name:String;

  /**
   * Behavior varies by render type:
   * - SPARROW: Path to retrieve both the spritesheet and the XML data from.
   * - PACKER: Path to retrieve both the spritesheet and the TXT data from.
   */
  public var assetPath:Null<String>;

  /**
   * The type of rendering system to use for the character.
   * @default sparrow
   */
  @:optional
  public var renderType:Null<CharacterRenderType>;

  /**
   * The scale of the graphic as a float.
   * Pro tip: On pixel-art levels, save the sprites small and set this value to 6 or so to save memory.
   * @default 1
   */
  @:optional
  public var scale:Null<Float>;

  /**
   * Optional data about the health icon for the character.
   */
  @:optional
  public var healthIcon:Null<HealthIconData>;

  /**
   * Optional data about the death animation for the character.
   */
  @:optional
  public var death:Null<DeathData>;

  /**
   * The global offset to the character's position, in pixels.
   * @default [0, 0]
   */
  @:optional
  public var offsets:Null<Array<Float>>;

  /**
   * The amount to offset the camera by while focusing on this character.
   * Default value focuses on the character directly.
   * @default [0, 0]
   */
  @:optional
  public var cameraOffsets:Null<Array<Float>>;

  /**
   * Setting this to true disables anti-aliasing for the character.
   * @default false
   */
  @:optional
  public var isPixel:Null<Bool>;

  /**
   * The frequency at which the character will play its idle animation, in beats.
   * Increasing this number will make the character dance less often.
   * Supports up to `0.25` precision.
   * @default `1.0` on characters
   */
  @:optional @:default(1.0)
  public var danceEvery:Null<Float>;

  /**
   * The minimum duration that a character will play a note animation for, in beats.
   * If this number is too low, you may see the character start playing the idle animation between notes.
   * If this number is too high, you may see the the character play the sing animation for too long after the notes are gone.
   *
   * Examples:
   * - Daddy Dearest uses a value of `1.525`.
   * @default 1.0
   */
  @:optional
  public var singTime:Null<Float>;

  /**
   * An optional array of animations which the character can play.
   */
  @:optional
  public var animations:Null<Array<AnimationData>>;

  /**
   * If animations are used, this is the name of the animation to play first.
   * @default idle
   */
  @:optional
  public var startingAnimation:Null<String>;

  /**
   * Whether or not the whole ass sprite is flipped by default.
   * Useful for characters that could also be played (Pico)
   *
   * @default false
   */
  @:optional
  public var flipX:Null<Bool>;

  /**
   * NOTE: This only applies to animate atlas characters.
   *
   * Whether to apply the stage matrix, if it was exported from a symbol instance.
   * Also positions the Texture Atlas as it displays in Animate.
   * Turning this on is only recommended if you prepositioned the character in Animate.
   * For other cases, it should be turned off to act similarly to a normal FlxSprite.
   */
  @:optional
  public var applyStageMatrix:Null<Bool>;

  /**
   * Various settings for the prop.
   * Only available for texture atlases.
   */
  @:optional
  public var atlasSettings:Null<funkin.data.stage.StageData.TextureAtlasData>;

  /**
   * An external image link for the health icon.
   * This is used for Discord Rich Presence.
   */
  @:optional
  public var discordRPCImage:Null<String>;

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

  public function new(name:String)
  {
    this.version = CharacterRegistry.CHARACTER_DATA_VERSION;
    this.name = name;
  }

  /**
   * Set unspecified parameters to their defaults.
   * If the parameter is mandatory, print an error message.
   * @param id
   * @param input
   * @return The validated character data
   */
  public static function validateCharacterData(id:String, input:Null<CharacterData>):Null<CharacterData>
  {
    if (input == null)
    {
      trace('ERROR: Could not parse character data for "${id}".');
      return null;
    }

    if (input.version == null)
    {
      trace('WARN: No semantic version specified for character data file "$id", assuming ${CharacterRegistry.CHARACTER_DATA_VERSION}');
      input.version = CharacterRegistry.CHARACTER_DATA_VERSION;
    }

    if (!VersionUtil.validateVersionStr(input.version, CharacterRegistry.CHARACTER_DATA_VERSION_RULE))
    {
      trace('ERROR: Could not load character data for "$id": bad version (got ${input.version}, expected ${CharacterRegistry.CHARACTER_DATA_VERSION_RULE})');
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
  var ?shouldBop:Null<Bool>;

  /**
   * The scale of the health icon.
   */
  var ?scale:Null<Float>;

  /**
   * Whether to flip the health icon horizontally.
   * @default false
   */
  var ?flipX:Null<Bool>;

  /**
   * Multiply scale by 6 and disable antialiasing
   * @default false
   */
  var ?isPixel:Null<Bool>;

  /**
   * The offset of the health icon, in pixels.
   * @default [0, 25]
   */
  var ?offsets:Null<Array<Float>>;
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
