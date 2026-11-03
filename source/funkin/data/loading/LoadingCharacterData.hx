package funkin.data.loading;

/**
 * Data for a character in the loading screen.
 */
typedef LoadingCharacterData =
{
  /**
   * The character's offsets.
   */
  var charOffsets:Array<Float>;

  /**
   * The character's scale.
   */
  var charScale:Float;

  /**
   * The antialiasing of the character.
   */
  var charAntialiasing:Bool;

  /**
   * The possibility of flipping the character on the X axis.
   */
  var charFlipX:Bool;

  /**
   * The weight of the character.
   * A higher weight increases the chance of this character being chosen.
   */
  var weight:Float;

  /**
   * The offset of the loading bar.
   */
  var barOffsets:Array<Float>;

  /**
   * The scale of the loading bar.
   */
  var barScale:Float;

  /**
   * The antialiasing of the loading bar.
   */
  var barAntialiasing:Bool;

  /**
   * The possibility of flipping the loading bar on the X axis.
   */
  var barFlipX:Bool;
}
