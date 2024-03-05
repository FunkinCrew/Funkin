package funkin;

import flixel.FlxG;

/**
 * A core class which handles tracking score and combo for the current song.
 */
class Highscore
{
  /**
   * Keeps track of notes hit for the current song / week,
   * and how accurate you were with each note (bad, missed, shit, etc.)
   */
  public static var tallies:Tallies = new Tallies();
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
