package funkin.ui.debug.results;

import funkin.save.Save.SaveScoreTallyData;

/**
 * Just lil class to hold different score tallies for debug purposes
 */
@SuppressWarnings('checkstyle:MagicNumber')
class DebugTallies
{
  /**
   * 2400 total notes = 7% = LOSS
   */
  public static var LOSS:SaveScoreTallyData = {
    sick: 190,
    good: 69,
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
  public static var NICE:SaveScoreTallyData = {
    sick: 190,
    good: 69,
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
  public static var GOOD:SaveScoreTallyData = {
    sick: 190,
    good: 69,
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
  public static var GREAT:SaveScoreTallyData = {
    sick: 190,
    good: 69,
    bad: 69,
    shit: 69,
    missed: 69,
    combo: 69,
    maxCombo: 69,
    totalNotesHit: 190,
    totalNotes: 230
  };

  /**
   * 210 total notes = 90% = EXCELLENT
   */
  public static var EXCELLENT:SaveScoreTallyData = {
    sick: 190,
    good: 69,
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
  public static var PERFECT:SaveScoreTallyData = {
    sick: 190,
    good: 69,
    bad: 69,
    shit: 69,
    missed: 69,
    combo: 69,
    maxCombo: 69,
    totalNotesHit: 190,
    totalNotes: 190
  };

  /**
   * 190 total sicks and total notes = PERFECT GOLD
   */
  public static var PERFECT_GOLD:SaveScoreTallyData = {
    sick: 190,
    good: 0,
    bad: 69,
    shit: 69,
    missed: 0,
    combo: 69,
    maxCombo: 69,
    totalNotesHit: 190,
    totalNotes: 190
  };

  /**
   * Retrieve the score tally data for the given rank.
   * Used for debugging the Results screen.
   *
   * @param rank The intended rank to display.
   * @return A score
   */
  public static function getTallyForRank(rank:DebugRank):SaveScoreTallyData
  {
    return switch (rank)
    {
      case LOSS_RANK:
        LOSS;
      case NICE_RANK:
        NICE;
      case GOOD_RANK:
        GOOD;
      case GREAT_RANK:
        GREAT;
      case EXCELLENT_RANK:
        EXCELLENT;
      case PERFECT_RANK:
        PERFECT;
      case PERFECT_GOLD_RANK:
        PERFECT_GOLD;
    }
  }

  public static var DEBUG_RANKS:Array<DebugRank> = [
    LOSS_RANK,
    NICE_RANK,
    GOOD_RANK,
    GREAT_RANK,
    EXCELLENT_RANK,
    PERFECT_RANK,
    PERFECT_GOLD_RANK
  ];
}

enum abstract DebugRank(String) from String to String
{
  public var LOSS_RANK = 'Loss';
  public var NICE_RANK = 'Nice';
  public var GOOD_RANK = 'Good';
  public var GREAT_RANK = 'Great';
  public var EXCELLENT_RANK = 'Excellent';
  public var PERFECT_RANK = 'Perfect';
  public var PERFECT_GOLD_RANK = 'Perfect (Gold)';
}
