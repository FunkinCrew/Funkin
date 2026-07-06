package funkin.play.scoring;

/**
 * Points Based On Timing scoring system, version 1
 * Scores the player based on the offset based on timing, represented by a sigmoid function.
 */
class ScoringPBOT1 extends Scoring
{
  /**
   * The maximum score a note can receive.
   */
  public static final PBOT1_MAX_SCORE:Int = 500;

  /**
   * The offset of the sigmoid curve for the scoring function.
   */
  public static final PBOT1_SCORING_OFFSET:Float = 54.99;

  /**
   * The slope of the sigmoid curve for the scoring function.
   */
  public static final PBOT1_SCORING_SLOPE:Float = 0.080;

  /**
   * The minimum score a note can receive while still being considered a hit.
   */
  public static final PBOT1_MIN_SCORE:Float = 9.0;

  /**
   * The score a note receives when it is missed.
   */
  public static final PBOT1_MISS_SCORE:Int = -100;

  /**
   * The threshold at which a note hit is considered perfect and always given the max score.
   */
  public static final PBOT1_PERFECT_THRESHOLD:Float = 5.0; // 5ms

  /**
   * The threshold at which a note hit is considered missed.
   * `160ms`
   */
  public static final PBOT1_MISS_THRESHOLD:Float = 160.0;

  /**
   * The time within which a note is considered to have been hit with the Killer judgement.
   * `~7.5% of the hit window, or 12.5ms`
   */
  public static final PBOT1_KILLER_THRESHOLD:Float = 12.5;

  /**
   * The time within which a note is considered to have been hit with the Sick judgement.
   * `~25% of the hit window, or 45ms`
   */
  public static final PBOT1_SICK_THRESHOLD:Float = 45.0;

  /**
   * The time within which a note is considered to have been hit with the Good judgement.
   * `~55% of the hit window, or 90ms`
   */
  public static final PBOT1_GOOD_THRESHOLD:Float = 90.0;

  /**
   * The time within which a note is considered to have been hit with the Bad judgement.
   * `~85% of the hit window, or 135ms`
   */
  public static final PBOT1_BAD_THRESHOLD:Float = 135.0;

  /**
   * The time within which a note is considered to have been hit with the Shit judgement.
   * `100% of the hit window, or 160ms`
   */
  public static final PBOT1_SHIT_THRESHOLD:Float = 160.0;

  public function new()
  {
    super('pbot1');
  }

  public override function scoreNote(msTiming:Float):Int
  {
    // Absolute value because otherwise late hits are always given the max score.
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ > PBOT1_MISS_THRESHOLD) => true:
        PBOT1_MISS_SCORE;
      case(_ < PBOT1_PERFECT_THRESHOLD) => true:
        PBOT1_MAX_SCORE;
      default:
        // Fancy equation.
        var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-PBOT1_SCORING_SLOPE * (absTiming - PBOT1_SCORING_OFFSET))));

        var score:Int = Std.int(PBOT1_MAX_SCORE * factor + PBOT1_MIN_SCORE);

        score;
    }
  }

  public override function judgeNote(msTiming:Float):String
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      // case(_ <= PBOT1_KILLER_THRESHOLD) => true:
      //   'killer';
      case(_ <= PBOT1_SICK_THRESHOLD) => true:
        'sick';
      case(_ <= PBOT1_GOOD_THRESHOLD) => true:
        'good';
      case(_ <= PBOT1_BAD_THRESHOLD) => true:
        'bad';
      case(_ <= PBOT1_SHIT_THRESHOLD) => true:
        'shit';
      default:
        FlxG.log.warn('Missed note: Bad timing ($absTiming < $PBOT1_SHIT_THRESHOLD)');
        'miss';
    }
  }

  public override function getMissScore():Int
  {
    return PBOT1_MISS_SCORE;
  }
}
