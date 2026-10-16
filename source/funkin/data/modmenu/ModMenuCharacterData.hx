package funkin.data.modmenu;

import funkin.data.animation.AnimationData;

/**
 * Data for a character in the mod menu.
 */
typedef ModMenuCharacterData =
{
  /**
   * Optional render type for the character. Defaults to using texture atlases.
   */
  @:optional @:default('animateatlas')
  var renderType:String;

  /**
   * Optional list of animations for the character.
   */
  @:optional
  var animations:Array<AnimationData>;

  /**
   * Optional settings for the character's texture atlas, if it is one.
   */
  @:optional
  var atlasSettings:funkin.data.stage.StageData.TextureAtlasData;

  /**
   * The global offsets for the character's position.
   */
  @:optional @:default([0, 0])
  var offsets:Array<Float>;

  /**
   * The scale of the character.
   */
  @:optional @:default(0.7)
  var scale:Float;

  /**
   * Whether the character has custom wire animations.
   * If `true`, the Mod Menu's default wires will be hidden.
   */
  @:optional @:default(false)
  var hasCustomWires:Bool;

  /**
   * The mod menu has 2 variants of the foreground wires:
   * 1. The regular one, used for BF and GF.
   * 2. The small one, used for Pinhead.
   *
   * If `true`, the small wire will be used.
   */
  @:optional @:default(false)
  var useSmallWire:Bool;

  /**
   * The offsets for the character's smoke.
   * Used during the crispy animation.
   */
  @:optional @:default([0, 0])
  var smokeOffsets:Array<Float>;

  /**
   * The scale of the character's smoke.
   * Used during the crispy animation.
   *
   * NOTE: Is an array instead of a single float for better flexibility.
   *
   * (ex. `[0.5, 0.5]` instead of `0.5`)
   */
  @:optional @:default([0.5, 0.5])
  var smokeScale:Array<Float>;

  /**
   * Data for the starting frame of the character's animation.
   * Useful if your idle animation is super long.
   */
  @:optional
  var startingFrame:StartFrameData;
}

/**
 * Data for the starting frame of the character's animation.
 */
typedef StartFrameData =
{
  /**
   * The starting frame in the BF position.
   */
  @:optional @:default(0)
  var bf:Int;

  /**
   * The starting frame in the GF position.
   */
  @:optional @:default(0)
  var gf:Int;
}

