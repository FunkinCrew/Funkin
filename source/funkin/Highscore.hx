package funkin;

class Highscore
{
  #if (haxe >= "4.0.0")
  public static var songScores:Map<String, Int> = new Map();
  #else
  public static var songScores:Map<String, Int> = new Map<String, Int>();
  #end

  #if (haxe >= "4.0.0")
  public static var songCompletion:Map<String, Float> = new Map();
  #else
  public static var songCompletion:Map<String, Float> = new Map<String, Float>();
  #end

  public static var tallies:Tallies = new Tallies();

  public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0):Bool
  {
    var formattedSong:String = formatSong(song, diff);

    #if newgrounds
    NGio.postScore(score, song);
    #end

    if (songScores.exists(formattedSong))
    {
      if (songScores.get(formattedSong) < score)
      {
        setScore(formattedSong, score);
        return true;
        // new highscore
      }
    }
    else
      setScore(formattedSong, score);

    return false;
  }

  public static function saveScoreForDifficulty(song:String, score:Int = 0, diff:String = 'normal'):Bool
  {
    var diffInt:Int = 1;

    if (diff == 'easy') diffInt = 0;
    else if (diff == 'hard') diffInt = 2;

    return saveScore(song, score, diffInt);
  }

  public static function saveCompletion(song:String, completion:Float, diff:Int = 0):Bool
  {
    var formattedSong:String = formatSong(song, diff);

    if (songCompletion.exists(formattedSong))
    {
      if (songCompletion.get(formattedSong) < completion)
      {
        setCompletion(formattedSong, completion);
        return true;
      }
    }
    else
      setCompletion(formattedSong, completion);

    return false;
  }

  public static function saveCompletionForDifficulty(song:String, completion:Float, diff:String = 'normal'):Bool
  {
    var diffInt:Int = 1;

    if (diff == 'easy') diffInt = 0;
    else if (diff == 'hard') diffInt = 2;

    return saveCompletion(song, completion, diffInt);
  }

  public static function saveWeekScore(week:String, score:Int = 0, diff:Int = 0):Void
  {
    #if newgrounds
    NGio.postScore(score, 'Campaign ID $week');
    #end

    var formattedSong:String = formatSong(week, diff);

    if (songScores.exists(formattedSong))
    {
      if (songScores.get(formattedSong) < score) setScore(formattedSong, score);
    }
    else
    {
      setScore(formattedSong, score);
    }
  }

  public static function saveWeekScoreForDifficulty(week:String, score:Int = 0, diff:String = 'normal'):Void
  {
    var diffInt:Int = 1;

    if (diff == 'easy') diffInt = 0;
    else if (diff == 'hard') diffInt = 2;

    saveWeekScore(week, score, diffInt);
  }

  static function setCompletion(formattedSong:String, completion:Float):Void
  {
    songCompletion.set(formattedSong, completion);
    FlxG.save.data.songCompletion = songCompletion;
    FlxG.save.flush();
  }

  /**
   * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
   */
  static function setScore(formattedSong:String, score:Int):Void
  {
    /** GeoKureli
     * References to Highscore were wrapped in `#if !switch` blocks. I wasn't sure if this
     * is because switch doesn't use NGio, or because switch has a different saving method.
     * I moved the compiler flag here, rather than using it everywhere else.
     */
    #if ! switch
    // Reminder that I don't need to format this song, it should come formatted!
    songScores.set(formattedSong, score);
    FlxG.save.data.songScores = songScores;
    FlxG.save.flush();
    #end
  }

  public static function formatSong(song:String, diff:Int):String
  {
    var daSong:String = song;

    if (diff == 0) daSong += '-easy';
    else if (diff == 2) daSong += '-hard';

    return daSong;
  }

  public static function getScore(song:String, diff:Int):Int
  {
    if (!songScores.exists(formatSong(song, diff))) setScore(formatSong(song, diff), 0);

    return songScores.get(formatSong(song, diff));
  }

  public static function getCompletion(song, diff):Float
  {
    if (!songCompletion.exists(formatSong(song, diff))) setCompletion(formatSong(song, diff), 0);

    return songCompletion.get(formatSong(song, diff));
  }

  public static function getAllScores():Void
  {
    trace(songScores.toString());
  }

  public static function getWeekScore(week:Int, diff:Int):Int
  {
    if (!songScores.exists(formatSong('week' + week, diff))) setScore(formatSong('week' + week, diff), 0);

    return songScores.get(formatSong('week' + week, diff));
  }

  public static function load():Void
  {
    if (FlxG.save.data.songScores != null)
    {
      songScores = FlxG.save.data.songScores;
    }

    if (FlxG.save.data.songCompletion != null) songCompletion = FlxG.save.data.songCompletion;
  }
}

// i only do forward metadata cuz george did!

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
   * How many notes PASSED BY AND/OR HIT!!!
   */
  var totalNotes:Int;
}
