package funkin.play.scoring;

/**
 * The scoring system used in Week 7. It has tighter scoring windows than Legacy.
 * Scores the player based on judgement, represented by a step function.
 */
class ScoringWeek7 extends Scoring
{
  /**
   * The window of time in which a note is considered to be hit, on the Funkin Classic scoring system.
   * Same as L 10 frames at 60fps, or ~166ms.
   */
  public static final WEEK7_HIT_WINDOW:Float = (10 / 60) * 1000; // 166.67 ms hit window (10 frames at 60fps)

  public static final WEEK7_BAD_THRESHOLD:Float = 0.8; // 80% of the hit window, or ~125ms
  public static final WEEK7_GOOD_THRESHOLD:Float = 0.55; // 55% of the hit window, or ~91ms
  public static final WEEK7_SICK_THRESHOLD:Float = 0.2; // 20% of the hit window, or ~33ms
  public static final WEEK7_MISS_SCORE:Int = -10;
  public static final WEEK7_SHIT_SCORE:Int = 50;
  public static final WEEK7_BAD_SCORE:Int = 100;
  public static final WEEK7_GOOD_SCORE:Int = 200;
  public static final WEEK7_SICK_SCORE:Int = 350;

  public function new()
  {
    super('week7');
  }

  override function scoreNote(msTiming:Float):Int
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ < WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD) => true:
        WEEK7_SICK_SCORE;
      case(_ < WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD) => true:
        WEEK7_GOOD_SCORE;
      case(_ < WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD) => true:
        WEEK7_BAD_SCORE;
      case(_ < WEEK7_HIT_WINDOW) => true:
        WEEK7_SHIT_SCORE;
      default:
        0;
    }

    if (absTiming < WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD)
    {
      return WEEK7_SICK_SCORE;
    }
    else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD)
    {
      return WEEK7_GOOD_SCORE;
    }
    else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD)
    {
      return WEEK7_BAD_SCORE;
    }
    else if (absTiming < WEEK7_HIT_WINDOW)
    {
      return WEEK7_SHIT_SCORE;
    }
    else
    {
      return 0;
    }
  }

  override function judgeNote(msTiming:Float):String
  {
    var absTiming = Math.abs(msTiming);

    if (absTiming <= WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD)
    {
      return 'sick';
    }
    else if (absTiming <= WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD)
    {
      return 'good';
    }
    else if (absTiming <= WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD)
    {
      return 'bad';
    }
    else if (absTiming <= WEEK7_HIT_WINDOW)
    {
      return 'shit';
    }
    else
    {
      FlxG.log.warn('Missed note: Bad timing ($absTiming < $WEEK7_HIT_WINDOW)');
      return 'miss';
    }
  }

  public override function getMissScore():Int
  {
    return WEEK7_MISS_SCORE;
  }
}
