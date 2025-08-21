package funkin;

/**
 * A core class which handles tracking score and combo for the current song.
 */
@:nullSafety
class Highscore
{
  /**
   * Keeps track of notes hit for the current song
   * and how accurate you were with each note (bad, missed, shit, etc.)
   */
  public static var tallies:Tallies = new Tallies();

  /**
   * Keeps track of notes hit for the current WEEK / level
   * for use with storymode, or likely any other "playlist" esque option
   */
  public static var talliesLevel:Tallies = new Tallies();

  /**
   * Produces a new Tallies object which represents the sum of two existing Tallies
   * @param newTally The first tally
   * @param baseTally The second tally
   * @return The combined tally
   */
  public static function combineTallies(newTally:Tallies, baseTally:Tallies):Tallies
  {
    var combinedTally:Tallies = new Tallies();
    combinedTally.missed = newTally.missed + baseTally.missed;
    combinedTally.shit = newTally.shit + baseTally.shit;
    combinedTally.bad = newTally.bad + baseTally.bad;
    combinedTally.good = newTally.good + baseTally.good;
    combinedTally.sick = newTally.sick + baseTally.sick;
    combinedTally.totalNotes = newTally.totalNotes + baseTally.totalNotes;
    combinedTally.totalNotesHit = newTally.totalNotesHit + baseTally.totalNotesHit;

    // Current combo = use most recent.
    combinedTally.combo = newTally.combo;
    // Max combo = use maximum value.
    combinedTally.maxCombo = Std.int(Math.max(newTally.maxCombo, baseTally.maxCombo));

    return combinedTally;
  }
}

@:forward
abstract Tallies(RawTallies)
{
  public function new()
  {
    this =
      {
        combo: 0,
        missed: 0,
        shit: 0,
        bad: 0,
        good: 0,
        sick: 0,
        totalNotes: 0,
        totalNotesHit: 0,
        maxCombo: 0,
        score: 0,
        isNewHighscore: false
      }
  }
}

/**
 * A structure object containing the data for highscore tallies.
 */
typedef RawTallies =
{
  var combo:Int;

  /**
   * How many notes you let scroll by.
   */
  var missed:Int;

  var shit:Int;
  var bad:Int;
  var good:Int;
  var sick:Int;
  var maxCombo:Int;

  var score:Int;

  var isNewHighscore:Bool;

  /**
   * How many notes total that you hit. (NOT how many notes total in the song!)
   */
  var totalNotesHit:Int;

  /**
   * How many notes in the current chart
   */
  var totalNotes:Int;
}
