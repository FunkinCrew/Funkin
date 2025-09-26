package funkin.data.animation;

@:nullSafety
class AnimationDataUtil
{
  public static function toNamed(data:UnnamedAnimationData, name:String = ""):AnimationData
  {
    return {
      name: name,
      prefix: data.prefix,
      assetPath: data.assetPath,
      offsets: data.offsets,
      looped: data.looped,
      flipX: data.flipX,
      flipY: data.flipY,
      frameRate: data.frameRate,
      frameIndices: data.frameIndices
    };
  }

  /**
   * @param data
   * @param name (adds index to name)
   * @return Array<AnimationData>
   */
  public static function toNamedArray(data:Array<UnnamedAnimationData>, name:String = ""):Array<AnimationData>
  {
    return data.mapi(function(animItem, ind) return toNamed(animItem, '$name$ind'));
  }

  public static function toUnnamed(data:AnimationData):UnnamedAnimationData
  {
    return {
      prefix: data.prefix,
      assetPath: data.assetPath,
      offsets: data.offsets,
      looped: data.looped,
      flipX: data.flipX,
      flipY: data.flipY,
      frameRate: data.frameRate,
      frameIndices: data.frameIndices
    };
  }

  public static function toUnnamedArray(data:Array<AnimationData>):Array<UnnamedAnimationData>
  {
    return data.map(toUnnamed);
  }
}

/**
 * A data structure representing an animation in a spritesheet.
 * This is a generic data structure used by characters, stage props, and more!
 * BE CAREFUL when changing it.
 */
typedef AnimationData =
{
  > UnnamedAnimationData,

  /**
   * The name for the animation.
   * This should match the animation name queried by the game;
   * for example, characters need animations with names `idle`, `singDOWN`, `singUPmiss`, etc.
   */
  var name:String;
}

/**
 * A data structure representing an animation in a spritesheet.
 * This animation doesn't specify a name, that's presumably specified by the parent data structure.
 */
typedef UnnamedAnimationData =
{
  /**
   * The prefix for the frames of the animation as defined by the XML file.
   * This will may or may not differ from the `name` of the animation,
   * depending on how your animator organized their FLA or whatever.
   *
   * NOTE: For Sparrow animations, this is not optional, but for Packer animations it is.
   */
  @:optional
  var prefix:String;

  /**
   * Optionally specify an asset path to use for this specific animation.
   * ONLY for use by MultiSparrow characters.
   * @default The assetPath of the parent sprite
   */
  @:optional
  var assetPath:Null<String>;

  /**
   * Offset the character's position by this amount when playing this animation.
   * @default [0, 0]
   */
  @:default([0, 0])
  @:optional
  var offsets:Null<Array<Float>>;

  /**
   * Whether the animation should loop when it finishes.
   * @default false
   */
  @:default(false)
  @:optional
  var looped:Bool;

  /**
   * Whether the animation's sprites should be flipped horizontally.
   * @default false
   */
  @:default(false)
  @:optional
  var flipX:Null<Bool>;

  /**
   * Whether the animation's sprites should be flipped vertically.
   * @default false
   */
  @:default(false)
  @:optional
  var flipY:Null<Bool>;

  /**
   * The frame rate of the animation.
   * @default 24
   */
  @:default(24)
  @:optional
  var frameRate:Null<Int>;

  /**
   * If you want this animation to use only certain frames of an animation with a given prefix,
   * select them here.
   * @example [0, 1, 2, 3] (use only the first four frames)
   * @default [] (all frames)
   */
  @:default([])
  @:optional
  var frameIndices:Null<Array<Int>>;
}
