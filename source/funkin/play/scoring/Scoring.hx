package funkin.play.scoring;

import flixel.util.FlxColor;
import funkin.save.Save.SaveScoreData;
import funkin.save.Save.SaveScoreTallyData;

/**
 * A static class which holds any functions related to scoring.
 */
class Scoring
{
  /**
   * Determine the score a note receives under a given scoring system.
   * @param msTiming The difference between the note's time and when it was hit.
   * @return The score the note receives.
   */
  public static function scoreNote(msTiming:Float):Int
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

  /**
   * Determine the judgement a note receives under a given scoring system.
   * @param msTiming The difference between the note's time and when it was hit.
   * @return The judgement the note receives.
   */
  public static function judgeNote(msTiming:Float):String
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

  public static function getMissScore():Int
  {
    return PBOT1_MISS_SCORE;
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

  public static function calculateRank(scoreData:Null<SaveScoreData>):Null<ScoringRank>
  {
    if (scoreData?.tallies.totalNotes == 0 || scoreData == null) return null;

    // we can return null here, meaning that the player hasn't actually played and finished the song (thus has no data)
    if (scoreData.tallies.totalNotes == 0) return null;

    // Perfect (Gold) is a Sick Full Clear
    if (scoreData.tallies.sick == scoreData.tallies.totalNotes)
    {
      return ScoringRank.PERFECT_GOLD;
    }

    // Else, use the standard grades

    // Final Grade = (Sick + Good - Miss) / (Total Notes)

    var completionAmount:Float = Scoring.tallyCompletion(scoreData.tallies);

    if (completionAmount == Constants.RANK_PERFECT_THRESHOLD)
    {
      return ScoringRank.PERFECT;
    }
    else if (completionAmount >= Constants.RANK_EXCELLENT_THRESHOLD)
    {
      return ScoringRank.EXCELLENT;
    }
    else if (completionAmount >= Constants.RANK_GREAT_THRESHOLD)
    {
      return ScoringRank.GREAT;
    }
    else if (completionAmount >= Constants.RANK_GOOD_THRESHOLD)
    {
      return ScoringRank.GOOD;
    }
    else
    {
      return ScoringRank.SHIT;
    }
  }

  /**
   * Calculates the "completion" of a song, based on how many GOOD and SICK notes were hit, minus how many were missed
   * Top secret funkin crew patented algorithm
   * TODO: Could possibly move more of the "tallying" related handling here.
   *       In FreeplayState we make sure it's clamped between 0 and 1, and we probably always want to assume that?
   *
   * @param tallies
   * @return Float Completion, as a float value between 0 and 1. If `tallies` is `null`, we return 0;
   */
  public static function tallyCompletion(?tallies:SaveScoreTallyData):Float
  {
    if (tallies == null) return 0.0;
    return ((
      tallies.sick
      + tallies.good
      - tallies.missed
    ) / tallies.totalNotes).clamp(0, 1); // Needs to be clamped to make sure Perfect ranks are saved properly
  }
}

enum abstract ScoringRank(String)
{
  public var PERFECT_GOLD;
  public var PERFECT;
  public var EXCELLENT;
  public var GREAT;
  public var GOOD;
  public var SHIT;

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
  @:op(A > B)
  static function compareGT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 > temp2;
  }

  // Greater than or equal to comparison
  @:op(A >= B)
  static function compareGTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 >= temp2;
  }

  // Less than comparison
  @:op(A < B)
  static function compareLT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 < temp2;
  }

  // Less than or equal to comparison
  @:op(A <= B)
  static function compareLTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
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
        return 2 / 24;
    }
  }

  public function getBFDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
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
        return 95 / 24;
    }
  }

  public function getFlashDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
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
        return 186 / 24;
    }
  }

  public function getHighscoreDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
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
        return 207 / 24;
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

  public function getHorTextAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return Paths.image('ui/results/rank-text/scroll-perfect');
      case PERFECT:
        return Paths.image('ui/results/rank-text/scroll-perfect');
      case EXCELLENT:
        return Paths.image('ui/results/rank-text/scroll-excellent');
      case GREAT:
        return Paths.image('ui/results/rank-text/scroll-great');
      case GOOD:
        return Paths.image('ui/results/rank-text/scroll-good');
      case SHIT:
        return Paths.image('ui/results/rank-text/scroll-loss');
      default:
        return Paths.image('ui/results/rank-text/scroll-loss');
    }
  }

  public function getVerTextAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return Paths.image('ui/results/rank-text/text-perfect');
      case PERFECT:
        return Paths.image('ui/results/rank-text/text-perfect');
      case EXCELLENT:
        return Paths.image('ui/results/rank-text/text-excellent');
      case GREAT:
        return Paths.image('ui/results/rank-text/text-great');
      case GOOD:
        return Paths.image('ui/results/rank-text/text-good');
      case SHIT:
        return Paths.image('ui/results/rank-text/text-loss');
      default:
        return Paths.image('ui/results/rank-text/text-loss');
    }
  }

  public function getRankingFreeplayColor():FlxColor
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
      default:
        0xFF6044FF;
    }
  }

  public function toString():String
  {
    return this;
  }
}
