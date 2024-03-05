package funkin;

import flixel.FlxG;

/**
 * A core class which handles tracking score and combo for the current song.
 */
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

  public static function combineTallies(tally1:Tallies, tally2:Tallies):Tallies
  {
    var combinedTally:Tallies = new Tallies();
    combinedTally.combo = tally1.combo + tally2.combo;
    combinedTally.missed = tally1.missed + tally2.missed;
    combinedTally.shit = tally1.shit + tally2.shit;
    combinedTally.bad = tally1.bad + tally2.bad;
    combinedTally.good = tally1.good + tally2.good;
    combinedTally.sick = tally1.sick + tally2.sick;
    combinedTally.totalNotes = tally1.totalNotes + tally2.totalNotes;
    combinedTally.totalNotesHit = tally1.totalNotesHit + tally2.totalNotesHit;
    combinedTally.maxCombo = tally1.maxCombo + tally2.maxCombo;

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
        isNewHighscore: false
      }
  }
}

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
