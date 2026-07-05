package funkin.play.scoring;

/**
 * The scoring system used in versions of the game Week 6 and older.
 * Scores the player based on judgement, represented by a step function.
 */
class ScoringLegacy extends Scoring
{
  /**
   * The window of time in which a note is considered to be hit, on the Funkin Legacy scoring system.
   * Currently equal to 10 frames at 60fps, or ~166ms.
   */
  public static final LEGACY_HIT_WINDOW:Float = (10 / 60) * 1000; // 166.67 ms hit window (10 frames at 60fps)

  /**
   * The threshold at which a note is considered a "Sick" hit rather than another judgement.
   * Represented as a percentage of the total hit window.
   */
  public static final LEGACY_SICK_THRESHOLD:Float = 0.2;

  /**
   * The threshold at which a note is considered a "Good" hit rather than another judgement.
   * Represented as a percentage of the total hit window.
   */
  public static final LEGACY_GOOD_THRESHOLD:Float = 0.75;

  /**
   * The threshold at which a note is considered a "Bad" hit rather than another judgement.
   * Represented as a percentage of the total hit window.
   */
  public static final LEGACY_BAD_THRESHOLD:Float = 0.9;

  /**
   * The score a note receives when hit within the Shit threshold, rather than a miss.
   * Represented as a percentage of the total hit window.
   */
  public static final LEGACY_SHIT_THRESHOLD:Float = 1.0;

  /**
   * The score a note receives when hit within the Sick threshold.
   */
  public static final LEGACY_SICK_SCORE:Int = 350;

  /**
   * The score a note receives when hit within the Good threshold.
   */
  public static final LEGACY_GOOD_SCORE:Int = 200;

  /**
   * The score a note receives when hit within the Bad threshold.
   */
  public static final LEGACY_BAD_SCORE:Int = 100;

  /**
   * The score a note receives when hit within the Shit threshold.
   */
  public static final LEGACY_SHIT_SCORE:Int = 50;

  /**
   * The score a note receives when missed.
   */
  public static final LEGACY_MISS_SCORE:Int = -10;

  public function new()
  {
    super('legacy');
  }

  public override function scoreNote(msTiming:Float):Int
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ < LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) => true:
        LEGACY_SICK_SCORE;
      case(_ < LEGACY_HIT_WINDOW * LEGACY_GOOD_THRESHOLD) => true:
        LEGACY_GOOD_SCORE;
      case(_ < LEGACY_HIT_WINDOW * LEGACY_BAD_THRESHOLD) => true:
        LEGACY_BAD_SCORE;
      case(_ < LEGACY_HIT_WINDOW * LEGACY_SHIT_THRESHOLD) => true:
        LEGACY_SHIT_SCORE;
      default:
        0;
    }
  }

  public override function judgeNote(msTiming:Float):String
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ <= LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) => true:
        'sick';
      case(_ <= LEGACY_HIT_WINDOW * LEGACY_GOOD_THRESHOLD) => true:
        'good';
      case(_ <= LEGACY_HIT_WINDOW * LEGACY_BAD_THRESHOLD) => true:
        'bad';
      case(_ <= LEGACY_HIT_WINDOW * LEGACY_SHIT_THRESHOLD) => true:
        'shit';
      default:
        FlxG.log.warn('Missed note: Bad timing ($absTiming < $LEGACY_SHIT_THRESHOLD)');
        'miss';
    }
  }

  public override function getMissScore():Int
  {
    return LEGACY_MISS_SCORE;
  }
}
