package funkin.play.scoring;

/**
 * A static class which holds any functions to manage the accuracy parameter.
 */
class SongScore
{
  private static var points:Int = 0;

  /**
   * Returns the value of the score
   * @return the score variable
   */
  public static function getPoints():Int
  {
    return points;
  }

  /**
   * Adds points to the song score
   * @param score
   */
  public static function addToPoints(score:Int):Void
  {
    points += score;
  }

  /**
   * This function resets the score variable
   */
  public static function reset():Void
  {
    points = 0;
  }
}
