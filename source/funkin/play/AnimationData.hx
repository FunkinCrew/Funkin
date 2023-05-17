package funkin.play;

typedef AnimationData =
{
  /**
   * The name for the animation.
   * This should match the animation name queried by the game;
   * for example, characters need animations with names `idle`, `singDOWN`, `singUPmiss`, etc.
   */
  var name:String;

  /**
   * The prefix for the frames of the animation as defined by the XML file.
   * This will may or may not differ from the `name` of the animation,
   * depending on how your animator organized their FLA or whatever.
   */
  var prefix:String;

  /**
   * Optionally specify an asset path to use for this specific animation.
   * ONLY for use by MultiSparrow characters.
   * @default The assetPath of the parent sprite
   */
  @:default(null)
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
  var looped:Null<Bool>;

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
