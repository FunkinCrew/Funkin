package funkin.data.loading;

/**
 * Data for a character in the loading screen.
 */
typedef LoadingCharacterData =
{
  /**
   * The character's offsets.
   */
  @:optional @:default([40, 105])
  var offsets:Array<Float>;

  /**
   * The character's scale.
   */
  @:optional @:default(0.35)
  var scale:Float;

  /**
   * The antialiasing of the character.
   */
  @:optional @:default(true)
  var antialiasing:Bool;

  /**
   * The possibility of flipping the character on the X axis.
   */
  @:optional @:default(false)
  var flipX:Bool;

  /**
   * The weight of the character.
   * A higher weight increases the chance of this character being chosen.
   */
  var weight:Float;

  /**
   * The offset of the loading bar.
   */
  @:optional @:default([0, 0])
  var barOffsets:Array<Float>;

  /**
   * The scale of the loading bar.
   */
  @:optional @:default(0.34)
  var barScale:Float;

  /**
   * The antialiasing of the loading bar.
   */
  @:optional @:default(true)
  var barAntialiasing:Bool;

  /**
   * The possibility of flipping the loading bar on the X axis.
   */
  @:optional @:default(false)
  var barFlipX:Bool;
}
