package funkin.play.scoring;

import funkin.util.tools.ISingleton;

/**
 * A class that handles storing the current score in PlayState.
 */
class SongScore implements ISingleton
{
  /**
   * The player's current score.
   * This needs to be a float because you gain partial points as you hold a hold note.
   */
  private var points:Float = 0;

  /**
   * Sometimes there are points that need to be calculated,
   * but need to be displayed before the calculation is entirely finished (e.g. hold notes)
   */
  private var pendingPoints:Float = 0;

  public function new()
  {
  }

  /**
   * Returns the current score points, including `pendingPoints`.
   * Should be used for retrieving the score, like when doing script shenanigans.
   * @return Points
   */
  public function getScoreWithPending():Float
  {
    return points + pendingPoints;
  }

  /**
   * Returns the current score points, excluding `pendingPoints`.
   * Should be used for retrieving the score, like when doing script shenanigans.
   * @return Points
   */
  public function getScore():Float
  {
    return points;
  }

  /**
   * Returns the current score points (excluding `pendingPoints`) as an integer.
   * Should be used for storing the score, like after a song ends.
   * @return Points
   */
  public function getScoreInt():Int
  {
    return Std.int(points);
  }

  /**
   * Adds points to the song score.
   * @param score The score to add
   */
  public function addScore(score:Float):Void
  {
    points += score;
  }

  /**
   * Sets the amount of pending score.
   * Used by PlayState to handle hold notes.
   * @param score The score to set
   */
  public function setPendingScore(score:Float):Void
  {
    pendingPoints = score;
  }

  /**
   * Resets the score back to zero.
   */
  public function reset():Void
  {
    points = 0;
  }
}
