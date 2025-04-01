package funkin.data.dialogue.speaker;

import funkin.data.animation.AnimationData;

/**
 * A type definition for a specific speaker in a conversation.
 * It includes things like what sprite to use and its available animations.
 * @see https://lib.haxe.org/p/json2object/
 */
typedef SpeakerData =
{
  /**
   * Semantic version of the speaker data.
   */
  public var version:String;

  /**
   * A human-readable name for the speaker.
   */
  public var name:String;

  /**
   * The path to the asset to use for the speaker's sprite.
   */
  public var assetPath:String;

  /**
   * Whether the sprite should be flipped horizontally.
   */
  @:optional
  @:default(false)
  public var flipX:Bool;

  /**
   * Whether the sprite should be flipped vertically.
   */
  @:optional
  @:default(false)
  public var flipY:Bool;

  /**
   * Whether to disable anti-aliasing for the dialogue box sprite.
   */
  @:optional
  @:default(false)
  public var isPixel:Bool;

  /**
   * The offsets to apply to the sprite's position.
   */
  @:optional
  @:default([0, 0])
  public var offsets:Array<Float>;

  /**
   * The scale to apply to the sprite.
   */
  @:optional
  @:default(1.0)
  public var scale:Float;

  /**
   * The available animations for the speaker.
   */
  @:optional
  @:default([])
  public var animations:Array<AnimationData>;
}
