package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS
import io.newgrounds.Call;
import io.newgrounds.objects.ScoreBoard as LeaderboardData;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result;

class Leaderboards
{
  public static function listLeaderboardData():Map<Leaderboard, LeaderboardData>
  {
    if (NewgroundsClient.instance.leaderboards == null)
    {
      trace('[NEWGROUNDS] Not logged in, cannot fetch medal data!');
      return [];
    }

    var result:Map<Leaderboard, LeaderboardData> = [];

    for (leaderboardId in NewgroundsClient.instance.leaderboards.keys())
    {
      var leaderboardData = NewgroundsClient.instance.leaderboards.get(leaderboardId);
      if (leaderboardData == null) continue;

      // A little hacky, but it works.
      result.set(cast leaderboardId, leaderboardData);
    }

    return result;
  }

  /**
   * Submit a score to Newgrounds.
   * @param leaderboard The leaderboard to submit to.
   * @param score The score to submit.
   * @param tag An optional tag to attach to the score.
   */
  public static function submitScore(leaderboard:Leaderboard, score:Int, ?tag:String):Void
  {
    // Silently reject submissions for unknown leaderboards.
    if (leaderboard == Leaderboard.Unknown) return;

    if (NewgroundsClient.instance.isLoggedIn())
    {
      var leaderboardData = NewgroundsClient.instance.leaderboards.get(leaderboard.getId());
      if (leaderboardData != null)
      {
        leaderboardData.postScore(score, function(outcome:Outcome<CallError>):Void {
          switch (outcome)
          {
            case SUCCESS:
              trace('[NEWGROUNDS] Submitted score!');
            case FAIL(error):
              trace('[NEWGROUNDS] Failed to submit score!');
              trace(error);
          }
        });
      }
    }
  }

  /**
   * Submit a score for a Story Level to Newgrounds.
   */
  public static function submitLevelScore(levelId:String, difficultyId:String, score:Int):Void
  {
    var tag = '${difficultyId}';
    Leaderboards.submitScore(Leaderboard.getLeaderboardByLevel(levelId), score, tag);
  }

  /**
   * Submit a score for a song to Newgrounds.
   */
  public static function submitSongScore(songId:String, difficultyId:String, score:Int):Void
  {
    var tag = '${difficultyId}';
    Leaderboards.submitScore(Leaderboard.getLeaderboardBySong(songId), score, tag);
  }
}
#end

enum abstract Leaderboard(Int)
{
  /**
   * Represents an undefined or invalid leaderboard.
   */
  var Unknown = -1;

  //
  // STORY LEVELS
  //
  var StoryWeek1 = #if FEATURE_NEWGROUNDS_DEBUG 14239 #else 9615 #end;
  var StoryWeek2 = #if FEATURE_NEWGROUNDS_DEBUG 14240 #else 9616 #end;
  var StoryWeek3 = #if FEATURE_NEWGROUNDS_DEBUG 14242 #else 9767 #end;
  var StoryWeek4 = #if FEATURE_NEWGROUNDS_DEBUG 14241 #else 9866 #end;
  var StoryWeek5 = #if FEATURE_NEWGROUNDS_DEBUG 14243 #else 9956 #end;
  var StoryWeek6 = #if FEATURE_NEWGROUNDS_DEBUG 14244 #else 9957 #end;
  var StoryWeek7 = #if FEATURE_NEWGROUNDS_DEBUG 14245 #else 1000000 #end;
  var StoryWeekend1 = #if FEATURE_NEWGROUNDS_DEBUG 14237 #else 1000000 #end;

  //
  // SONGS
  //
  // Tutorial
  var Tutorial = #if FEATURE_NEWGROUNDS_DEBUG 14249 #else 1000000 #end;

  // Week 1
  var Bopeebo = #if FEATURE_NEWGROUNDS_DEBUG 14246 #else 9603 #end;
  var Fresh = #if FEATURE_NEWGROUNDS_DEBUG 14247 #else 9602 #end;
  var DadBattle = #if FEATURE_NEWGROUNDS_DEBUG 14248 #else 9605 #end;

  // Week 2
  var Spookeez = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9604 #end;
  var South = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9606 #end;
  var Monster = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;

  // Week 3
  var Pico = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9766 #end;
  var PhillyNice = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9769 #end;
  var Blammed = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9768 #end;

  // Week 4
  var SatinPanties = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var High = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9867 #end;
  var MILF = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9868 #end;

  // Week 5
  var Cocoa = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var Eggnog = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var WinterHorrorland = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;

  // Week 6
  var Senpai = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9958 #end;
  var Roses = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9959 #end;
  var Thorns = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 9960 #end;

  // Week 7
  var Ugh = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var Guns = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var Stress = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;

  // Weekend 1
  var Darnell = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var LitUp = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;
  var TwoHot = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end; // Variable names can't start with a number!
  var Blazin = #if FEATURE_NEWGROUNDS_DEBUG 1000000 #else 1000000 #end;

  public function getId():Int
  {
    return this;
  }

  /**
   * Get the leaderboard for a given level and difficulty.
   * @param levelId The ID for the story level.
   * @param difficulty The current difficulty.
   * @return The Leaderboard ID for the given level and difficulty.
   */
  public static function getLeaderboardByLevel(levelId:String):Leaderboard
  {
    switch (levelId)
    {
      case "week1":
        return StoryWeek1;
      case "week2":
        return StoryWeek2;
      case "week3":
        return StoryWeek3;
      case "week4":
        return StoryWeek4;
      case "week5":
        return StoryWeek5;
      case "week6":
        return StoryWeek6;
      case "week7":
        return StoryWeek7;
      case "weekend1":
        return StoryWeekend1;
      default:
        return Unknown;
    }
  }

  /**
   * Get the leaderboard for a given level and difficulty.
   * @param levelId The ID for the story level.
   * @param difficulty The current difficulty.
   * @return The Leaderboard ID for the given level and difficulty.
   */
  public static function getLeaderboardBySong(songId:String):Leaderboard
  {
    switch (songId)
    {
      case "tutorial":
        return Tutorial;
      case "bopeebo":
        return Bopeebo;
      case "fresh":
        return Fresh;
      case "dadbattle":
        return DadBattle;
      case "spookeez":
        return Spookeez;
      case "south":
        return South;
      case "monster":
        return Monster;
      case "pico":
        return Pico;
      case "philly-nice":
        return PhillyNice;
      case "blammed":
        return Blammed;
      case "satin-panties":
        return SatinPanties;
      case "high":
        return High;
      case "milf":
        return MILF;
      case "cocoa":
        return Cocoa;
      case "eggnog":
        return Eggnog;
      case "winter-horrorland":
        return WinterHorrorland;
      case "senpai":
        return Senpai;
      case "roses":
        return Roses;
      case "thorns":
        return Thorns;
      case "ugh":
        return Ugh;
      case "guns":
        return Guns;
      case "stress":
        return Stress;
      case "darnell":
        return Darnell;
      case "litup":
        return LitUp;
      case "2hot":
        return TwoHot;
      case "blazin":
        return Blazin;
      default:
        return Unknown;
    }
  }
}
