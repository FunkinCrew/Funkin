package funkin.ui.debug.results;

import funkin.save.Save.SaveScoreTallyData;

/**
 * Just lil class to hold different score tallies for debug purposes
 */
class DebugTallies
{
  /**
   * 2400 total notes = 7% = LOSS
   */
  public static var LOSS:SaveScoreTallyData =
    {
      sick: 130,
      good: 60,
      bad: 69,
      shit: 69,
      missed: 69,
      combo: 69,
      maxCombo: 69,
      totalNotesHit: 170,
      totalNotes: 2400
    };

  /**
   * 275 total notes = 69% = NICE
   */
  public static var NICE:SaveScoreTallyData =
    {
      sick: 130,
      good: 60,
      bad: 69,
      shit: 69,
      missed: 69,
      combo: 69,
      maxCombo: 69,
      totalNotesHit: 190,
      totalNotes: 275
    };

  /**
   * 240 total notes = 79% = GOOD
   */
  public static var GOOD:SaveScoreTallyData =
    {
      sick: 130,
      good: 60,
      bad: 69,
      shit: 69,
      missed: 69,
      combo: 69,
      maxCombo: 69,
      totalNotesHit: 190,
      totalNotes: 240
    };

  /**
   * 230 total notes = 82% = GREAT
   */
  public static var GREAT:SaveScoreTallyData =
    {
      sick: 130,
      good: 60,
      bad: 69,
      shit: 69,
      missed: 69,
      combo: 69,
      maxCombo: 69,
      totalNotesHit: 190,
      totalNotes: 230
    };

  /**
   * 210 total notes = 91% = EXCELLENT
   */
  public static var EXCELLENT:SaveScoreTallyData =
    {
      sick: 130,
      good: 60,
      bad: 69,
      shit: 69,
      missed: 69,
      combo: 69,
      maxCombo: 69,
      totalNotesHit: 190,
      totalNotes: 210
    };

  /**
   * 190 total notes = PERFECT
   */
  public static var PERFECT:SaveScoreTallyData =
    {
      sick: 130,
      good: 60,
      bad: 69,
      shit: 69,
      missed: 69,
      combo: 69,
      maxCombo: 69,
      totalNotesHit: 190,
      totalNotes: 190
    };

  public static function getTallyForRank(rank:DebugRank):SaveScoreTallyData
  {
    return switch (rank)
    {
      case LOSS_RANK: LOSS;
      case NICE_RANK: NICE;
      case GOOD_RANK: GOOD;
      case GREAT_RANK: GREAT;
      case EXCELLENT_RANK: EXCELLENT;
      case PERFECT_RANK: PERFECT;
    }
  }

  public static var DEBUG_RANKS:Array<DebugRank> = [LOSS_RANK, NICE_RANK, GOOD_RANK, GREAT_RANK, EXCELLENT_RANK, PERFECT_RANK];
}

enum abstract DebugRank(String) from String to String
{
  var LOSS_RANK = "Loss";
  var NICE_RANK = "Nice";
  var GOOD_RANK = "Good";
  var GREAT_RANK = "Great";
  var EXCELLENT_RANK = "Excellent";
  var PERFECT_RANK = "Perfect";
}
