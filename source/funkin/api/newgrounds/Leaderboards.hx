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
  var StoryWeek1 = 14239;
  var StoryWeek2 = 14240;
  var StoryWeek3 = 14242;
  var StoryWeek4 = 14241;
  var StoryWeek5 = 14243;
  var StoryWeek6 = 14244;
  var StoryWeek7 = 14245;
  var StoryWeekend1 = 14237;

  //
  // SONGS
  //
  // Tutorial
  var Tutorial = 14249;

  // Week 1
  var Bopeebo = 14246;
  var Fresh = 14247;
  var DadBattle = 14248;

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
      default:
        return Unknown;
    }
  }
}
