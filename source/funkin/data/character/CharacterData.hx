package funkin.data.character;

import funkin.data.animation.AnimationData;

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
   * Renders the character using a spritesheet of symbols and JSON data.
   */
  public var AnimateAtlas = 'animateatlas';

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
   * The sematic version number of the character data JSON format.
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
  @:optional
  @:default('sparrow')
  var renderType:CharacterRenderType;

  /**
   * Behavior varies by render type:
   * - SPARROW: Path to retrieve both the spritesheet and the XML data from.
   * - PACKER: Path to retrieve both the spritsheet and the TXT data from.
   */
  var assetPaths:Array<String>;

  /**
   * The scale of the graphic as a float.
   * Pro tip: On pixel-art levels, save the sprites small and set this value to 6 or so to save memory.
   * @default 1
   */
  @:optional
  @:default(1.0)
  var scale:Null<Float>;

  /**
   * Optional data about the health icon for the character.
   */
  @:optional
  var healthIcon:Null<HealthIconData>;

  @:optional
  var death:Null<DeathData>;

  /**
   * The global offset to the character's position, in pixels.
   * @default [0, 0]
   */
  @:optional
  @:default([0, 0])
  var offsets:Null<Array<Float>>;

  /**
   * The amount to offset the camera by while focusing on this character.
   * Default value focuses on the character directly.
   * @default [0, 0]
   */
  @:optional
  @:default([0, 0])
  var cameraOffsets:Array<Float>;

  /**
   * Setting this to true disables anti-aliasing for the character.
   * @default false
   */
  @:optional
  @:default(false)
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
   * @default 8.0
   */
  @:optional
  @:default(8.0)
  var singTime:Null<Float>;

  /**
   * An optional array of animations which the character can play.
   */
  var animations:Array<AnimationData>;

  /**
   * If animations are used, this is the name of the animation to play first.
   * @default idle
   */
  @:optional
  @:default('idle')
  var startingAnimation:Null<String>;

  /**
   * Whether or not the whole ass sprite is flipped by default.
   * Useful for characters that could also be played (Pico)
   *
   * @default false
   */
  @:optional
  @:default(false)
  var flipX:Null<Bool>;
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
  @:optional
  var id:Null<String>;

  /**
   * The scale of the health icon.
   */
  @:optional
  @:default(1.0)
  var scale:Null<Float>;

  /**
   * Whether to flip the health icon horizontally.
   * @default false
   */
  @:optional
  @:default(false)
  var flipX:Null<Bool>;

  /**
   * Multiply scale by 6 and disable antialiasing
   * @default false
   */
  @:optional
  @:default(false)
  var isPixel:Null<Bool>;

  /**
   * The offset of the health icon, in pixels.
   * @default [0, 25]
   */
  @:optional
  @:default([0, 25])
  var offsets:Null<Array<Float>>;
}

typedef DeathData =
{
  /**
   * The amount to offset the camera by while focusing on this character as they die.
   * Default value focuses on the character's graphic midpoint.
   * @default [0, 0]
   */
  @:optional
  @:default([0, 0])
  var ?cameraOffsets:Array<Float>;

  /**
   * The amount to zoom the camera by while focusing on this character as they die.
   * Value is a multiplier of the default camera zoom for the stage.
   * @default 1.0
   */
  @:optional
  @:default(1.0)
  var ?cameraZoom:Float;

  /**
   * Impose a delay between when the character reaches `0` health and when the death animation plays.
   * @default 0.0
   */
  @:optional
  @:default(0.0)
  var ?preTransitionDelay:Float;
}
