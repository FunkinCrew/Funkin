package funkin.data.loading;

/**
 * Data for a character in the loading screen.
 */
typedef LoadingCharacterData =
{
  /**
   * The character's offsets.
   */
  var offsets:Array<Float>;

  /**
   * The character's scale.
   */
  var scale:Float;

  /**
   * The weight of the character.
   * A higher weight increases the chance of this character being chosen.
   */
  var weight:Float;
}
