package funkin.play.scoring;

import funkin.save.Save.SaveScoreData;

/**
 * Which system to use when scoring and judging notes.
 */
enum abstract ScoringSystem(String)
{
  /**
   * The scoring system used in versions of the game Week 6 and older.
   * Scores the player based on judgement, represented by a step function.
   */
  var LEGACY;

  /**
   * The scoring system used in Week 7. It has tighter scoring windows than Legacy.
   * Scores the player based on judgement, represented by a step function.
   */
  var WEEK7;

  /**
   * Points Based On Timing scoring system, version 1
   * Scores the player based on the offset based on timing, represented by a sigmoid function.
   */
  var PBOT1;
}

/**
 * A static class which holds any functions related to scoring.
 */
class Scoring
{
  /**
   * Determine the score a note receives under a given scoring system.
   * @param msTiming The difference between the note's time and when it was hit.
   * @param scoringSystem The scoring system to use.
   * @return The score the note receives.
   */
  public static function scoreNote(msTiming:Float, scoringSystem:ScoringSystem = PBOT1):Int
  {
    return switch (scoringSystem)
    {
      case LEGACY: scoreNoteLEGACY(msTiming);
      case WEEK7: scoreNoteWEEK7(msTiming);
      case PBOT1: scoreNotePBOT1(msTiming);
      default:
        FlxG.log.error('Unknown scoring system: ${scoringSystem}');
        0;
    }
  }

  /**
   * Determine the judgement a note receives under a given scoring system.
   * @param msTiming The difference between the note's time and when it was hit.
   * @param scoringSystem The scoring system to use.
   * @return The judgement the note receives.
   */
  public static function judgeNote(msTiming:Float, scoringSystem:ScoringSystem = PBOT1):String
  {
    return switch (scoringSystem)
    {
      case LEGACY: judgeNoteLEGACY(msTiming);
      case WEEK7: judgeNoteWEEK7(msTiming);
      case PBOT1: judgeNotePBOT1(msTiming);
      default:
        FlxG.log.error('Unknown scoring system: ${scoringSystem}');
        'miss';
    }
  }

  public static function getMissScore(scoringSystem:ScoringSystem = PBOT1):Int
  {
    return switch (scoringSystem)
    {
      case LEGACY: LEGACY_MISS_SCORE;
      case WEEK7: WEEK7_MISS_SCORE;
      case PBOT1: PBOT1_MISS_SCORE;
      default:
        FlxG.log.error('Unknown scoring system: ${scoringSystem}');
        0;
    }
  }

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

  static function scoreNotePBOT1(msTiming:Float):Int
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

  static function judgeNotePBOT1(msTiming:Float):String
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      // case(_ < PBOT1_KILLER_THRESHOLD) => true:
      //   'killer';
      case(_ < PBOT1_SICK_THRESHOLD) => true:
        'sick';
      case(_ < PBOT1_GOOD_THRESHOLD) => true:
        'good';
      case(_ < PBOT1_BAD_THRESHOLD) => true:
        'bad';
      case(_ < PBOT1_SHIT_THRESHOLD) => true:
        'shit';
      default:
        FlxG.log.warn('Missed note: Bad timing ($absTiming < $PBOT1_SHIT_THRESHOLD)');
        'miss';
    }
  }

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

  static function scoreNoteLEGACY(msTiming:Float):Int
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

  static function judgeNoteLEGACY(msTiming:Float):String
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ < LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) => true:
        'sick';
      case(_ < LEGACY_HIT_WINDOW * LEGACY_GOOD_THRESHOLD) => true:
        'good';
      case(_ < LEGACY_HIT_WINDOW * LEGACY_BAD_THRESHOLD) => true:
        'bad';
      case(_ < LEGACY_HIT_WINDOW * LEGACY_SHIT_THRESHOLD) => true:
        'shit';
      default:
        FlxG.log.warn('Missed note: Bad timing ($absTiming < $LEGACY_SHIT_THRESHOLD)');
        'miss';
    }
  }

  /**
   * The window of time in which a note is considered to be hit, on the Funkin Classic scoring system.
   * Same as L 10 frames at 60fps, or ~166ms.
   */
  public static final WEEK7_HIT_WINDOW:Float = LEGACY_HIT_WINDOW;

  public static final WEEK7_BAD_THRESHOLD:Float = 0.8; // 80% of the hit window, or ~125ms
  public static final WEEK7_GOOD_THRESHOLD:Float = 0.55; // 55% of the hit window, or ~91ms
  public static final WEEK7_SICK_THRESHOLD:Float = 0.2; // 20% of the hit window, or ~33ms
  public static final WEEK7_MISS_SCORE:Int = -10;
  public static final WEEK7_SHIT_SCORE:Int = 50;
  public static final WEEK7_BAD_SCORE:Int = 100;
  public static final WEEK7_GOOD_SCORE:Int = 200;
  public static final WEEK7_SICK_SCORE:Int = 350;

  static function scoreNoteWEEK7(msTiming:Float):Int
  {
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ < WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD) => true:
        LEGACY_SICK_SCORE;
      case(_ < WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD) => true:
        LEGACY_GOOD_SCORE;
      case(_ < WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD) => true:
        LEGACY_BAD_SCORE;
      case(_ < WEEK7_HIT_WINDOW) => true:
        LEGACY_SHIT_SCORE;
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

  static function judgeNoteWEEK7(msTiming:Float):String
  {
    var absTiming = Math.abs(msTiming);
    if (absTiming < WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD)
    {
      return 'sick';
    }
    else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD)
    {
      return 'good';
    }
    else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD)
    {
      return 'bad';
    }
    else if (absTiming < WEEK7_HIT_WINDOW)
    {
      return 'shit';
    }
    else
    {
      FlxG.log.warn('Missed note: Bad timing ($absTiming < $WEEK7_HIT_WINDOW)');
      return 'miss';
    }
  }

  public static function calculateRank(scoreData:Null<SaveScoreData>):Null<ScoringRank>
  {
    if (scoreData?.tallies.totalNotes == 0 || scoreData == null) return null;

    // we can return null here, meaning that the player hasn't actually played and finished the song (thus has no data)
    if (scoreData.tallies.totalNotes == 0) return null;

    // Perfect (Platinum) is a Sick Full Clear
    var isPerfectGold = scoreData.tallies.sick == scoreData.tallies.totalNotes;
    if (isPerfectGold)
    {
      return ScoringRank.PERFECT_GOLD;
    }

    // Else, use the standard grades

    // Final Grade = (Sick + Good - Miss) / (Total Notes)

    var grade = (scoreData.tallies.sick + scoreData.tallies.good - scoreData.tallies.missed) / scoreData.tallies.totalNotes;

    if (grade == Constants.RANK_PERFECT_THRESHOLD)
    {
      return ScoringRank.PERFECT;
    }
    else if (grade >= Constants.RANK_EXCELLENT_THRESHOLD)
    {
      return ScoringRank.EXCELLENT;
    }
    else if (grade >= Constants.RANK_GREAT_THRESHOLD)
    {
      return ScoringRank.GREAT;
    }
    else if (grade >= Constants.RANK_GOOD_THRESHOLD)
    {
      return ScoringRank.GOOD;
    }
    else
    {
      return ScoringRank.SHIT;
    }
  }
}

enum abstract ScoringRank(String)
{
  var PERFECT_GOLD;
  var PERFECT;
  var EXCELLENT;
  var GREAT;
  var GOOD;
  var SHIT;

  /**
   * Converts ScoringRank to an integer value for comparison.
   * Better ranks should be tied to a higher value.
   */
  static function getValue(rank:Null<ScoringRank>):Int
  {
    if (rank == null) return -1;
    switch (rank)
    {
      case PERFECT_GOLD:
        return 5;
      case PERFECT:
        return 4;
      case EXCELLENT:
        return 3;
      case GREAT:
        return 2;
      case GOOD:
        return 1;
      case SHIT:
        return 0;
      default:
        return -1;
    }
  }

  // Yes, we really need a different function for each comparison operator.
  @:op(A > B) static function compareGT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 > temp2;
  }

  // Greater than or equal to comparison
  @:op(A >= B) static function compareGTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 >= temp2;
  }

  // Less than comparison
  @:op(A < B) static function compareLT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 < temp2;
  }

  // Less than or equal to comparison
  @:op(A <= B) static function compareLTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 <= temp2;
  }

  // @:op(A == B) isn't necessary!

  /**
   * Delay in seconds
   */
  public function getMusicDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 95 / 24;
      case EXCELLENT:
        return 0;
      case GREAT:
        return 5 / 24;
      case GOOD:
        return 3 / 24;
      case SHIT:
        return 2 / 24;
      default:
        return 3.5;
    }
  }

  public function getBFDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 95 / 24;
      case EXCELLENT:
        return 97 / 24;
      case GREAT:
        return 95 / 24;
      case GOOD:
        return 95 / 24;
      case SHIT:
        return 95 / 24;
      default:
        return 3.5;
    }
  }

  public function getFlashDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 129 / 24;
      case EXCELLENT:
        return 122 / 24;
      case GREAT:
        return 109 / 24;
      case GOOD:
        return 107 / 24;
      case SHIT:
        return 186 / 24;
      default:
        return 3.5;
    }
  }

  public function getHighscoreDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 140 / 24;
      case EXCELLENT:
        return 140 / 24;
      case GREAT:
        return 129 / 24;
      case GOOD:
        return 127 / 24;
      case SHIT:
        return 207 / 24;
      default:
        return 3.5;
    }
  }

  public function getFreeplayRankIconAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'PERFECTSICK';
      case PERFECT:
        return 'PERFECT';
      case EXCELLENT:
        return 'EXCELLENT';
      case GREAT:
        return 'GREAT';
      case GOOD:
        return 'GOOD';
      case SHIT:
        return 'LOSS';
      default:
        return 'LOSS';
    }
  }

  public function getHorTextAsset()
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'resultScreen/rankText/rankScrollPERFECT';
      case PERFECT:
        return 'resultScreen/rankText/rankScrollPERFECT';
      case EXCELLENT:
        return 'resultScreen/rankText/rankScrollEXCELLENT';
      case GREAT:
        return 'resultScreen/rankText/rankScrollGREAT';
      case GOOD:
        return 'resultScreen/rankText/rankScrollGOOD';
      case SHIT:
        return 'resultScreen/rankText/rankScrollLOSS';
      default:
        return 'resultScreen/rankText/rankScrollGOOD';
    }
  }

  public function getVerTextAsset()
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'resultScreen/rankText/rankTextPERFECT';
      case PERFECT:
        return 'resultScreen/rankText/rankTextPERFECT';
      case EXCELLENT:
        return 'resultScreen/rankText/rankTextEXCELLENT';
      case GREAT:
        return 'resultScreen/rankText/rankTextGREAT';
      case GOOD:
        return 'resultScreen/rankText/rankTextGOOD';
      case SHIT:
        return 'resultScreen/rankText/rankTextLOSS';
      default:
        return 'resultScreen/rankText/rankTextGOOD';
    }
  }

  public function getRankingFreeplayColor()
  {
    return switch (abstract)
    {
      case SHIT:
        0xFF6044FF;
      case GOOD:
        0xFFEF8764;
      case GREAT:
        0xFFEAF6FF;
      case EXCELLENT:
        0xFFFDCB42;
      case PERFECT:
        0xFFFF58B4;
      case PERFECT_GOLD:
        0xFFFFB619;
    }
  }

  public function toString():String
  {
    return this;
  }
}
