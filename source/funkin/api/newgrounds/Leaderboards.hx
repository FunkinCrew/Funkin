package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS
import io.newgrounds.Call.CallError;
import io.newgrounds.components.ScoreBoardComponent.Period;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard as LeaderboardData;
import io.newgrounds.objects.User;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.utils.ScoreBoardList;

/**
 * Handles interactions with the leaderboards on the Newgrounds website.
 */
@:nullSafety
class Leaderboards
{
  /**
   * Retrieve the leaderboard data via the Newgrounds API.
   * @return The leaderboard data.
   */
  public static function listLeaderboardData():Map<Leaderboard, LeaderboardData>
  {
    var leaderboardList:Null<ScoreBoardList> = NewgroundsClient.instance.leaderboards;
    if (leaderboardList == null)
    {
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Not logged in, cannot fetch medal data!');
      return [];
    }

    return @:privateAccess leaderboardList._map?.copy() ?? [];
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
    if (leaderboard == Leaderboard.Unknown)
    {
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Unknown leaderboard, skipping score submission...');
      return;
    }

    if (NewgroundsClient.instance.isLoggedIn())
    {
      var leaderboardData:Null<LeaderboardData> = listLeaderboardData().get(leaderboard.getId());
      if (leaderboardData != null)
      {
        leaderboardData.postScore(score, function(outcome:Outcome<CallError>):Void
        {
          switch (outcome)
          {
            case SUCCESS:
              trace(' NEWGROUNDS '.bold().bg_orange() + ' Submitted leaderboard score!');
            case FAIL(error):
              trace(' NEWGROUNDS '.bold().bg_orange() + ' ERROR '.error() + ' Failed to submit leaderboard score!');
              trace(' ERROR '.error() + error);
          }
        });
      }
    }
  }

  /**
   * Request to receive scores from Newgrounds.
   * @param leaderboard The leaderboard to fetch scores from.
   * @param params Additional parameters for fetching the score.
   */
  public static function requestScores(leaderboard:Leaderboard, ?params:RequestScoresParams)
  {
    // Silently reject retrieving scores from unknown leaderboards.
    if (leaderboard == Leaderboard.Unknown) return;

    var leaderboardData:Null<LeaderboardData> = listLeaderboardData().get(leaderboard.getId());
    if (leaderboardData == null) return;

    var user:Null<User> = null;
    if ((params?.useCurrentUser ?? false) && NewgroundsClient.instance.isLoggedIn()) user = NewgroundsClient.instance.user;

    leaderboardData.requestScores(params?.limit ?? 10, params?.skip ?? 0, params?.period ?? ALL, params?.social ?? false, params?.tag, user,
      function(outcome:Outcome<CallError>):Void
      {
        switch (outcome)
        {
          case SUCCESS:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Fetched scores!');
            if (params != null && params.onComplete != null) params.onComplete(leaderboardData.scores);

          case FAIL(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' ERROR '.error() + ' Failed to fetch scores!');
            trace(' ERROR '.error() + error);
            if (params != null && params.onFail != null) params.onFail();
        }
      });
  }

  /**
   * Submit a score for a Story Level to Newgrounds.
   *
   * @param levelId The ID for the story level.
   * @param difficultyId The current difficulty.
   * @param score The score to submit.
   */
  public static function submitLevelScore(levelId:String, difficultyId:String, score:Int):Void
  {
    var tag = '${difficultyId}';
    trace(' NEWGROUNDS '.bold().bg_orange() + 'Submitting score for level "${levelId}"...');
    Leaderboards.submitScore(Leaderboard.getLeaderboardByLevel(levelId), score, tag);
  }

  /**
   * Submit a score for a song to Newgrounds.
   *
   * @param songId The ID for the song.
   * @param difficultyId The current difficulty.
   * @param score The score to submit.
   */
  public static function submitSongScore(songId:String, difficultyId:String, score:Int):Void
  {
    var tag = '${difficultyId}';
    trace(' NEWGROUNDS '.bold().bg_orange() + 'Submitting score for song "${songId}" (${difficultyId})...');
    Leaderboards.submitScore(Leaderboard.getLeaderboardBySong(songId, difficultyId), score, tag);
  }
}

/**
 * Wrapper for `Leaderboards` that prevents submitting scores.
 */
@:nullSafety
class LeaderboardsSandboxed
{
  /**
   * Get the leaderboard for a given song and difficulty.
   *
   * @param songId The ID for the song.
   * @param difficultyId The current difficulty, suffixed with the variation, like `easy-pico` or `nightmare`.
   * @return The Leaderboard ID for the given level and difficulty.
   */
  public static function getLeaderboardBySong(songId:String, difficultyId:String):Leaderboard
  {
    return Leaderboard.getLeaderboardBySong(songId, difficultyId);
  }

  /**
   * Get the leaderboard for a given story level and difficulty.
   * @param levelId The ID for the story level.
   * @return The Leaderboard ID for the given level and difficulty.
   */
  public static function getLeaderboardByLevel(levelId:String):Leaderboard
  {
    return Leaderboard.getLeaderboardByLevel(levelId);
  }

  /**
   * Request to receive scores from Newgrounds.
   * @param leaderboard The leaderboard to fetch scores from.
   * @param params Additional parameters for fetching the score.
   */
  public function requestScores(leaderboard:Leaderboard, params:RequestScoresParams)
  {
    Leaderboards.requestScores(leaderboard, params);
  }
}

/**
 * Additional parameters for `Leaderboards.requestScores()`
 */
typedef RequestScoresParams =
{
  /**
   * How many scores to include in a list.
   * @default `10`
   */
  var ?limit:Int;

  /**
   * How many scores to skip before starting the list.
   * @default `0`
   */
  var ?skip:Int;

  /**
   * The time-frame to pull the scores from.
   * @default `Period.ALL`
   */
  var ?period:Period;

  /**
   * If true, only scores by the user and their friends will be loaded. Ignored if no user is set.
   * @default `false`
   */
  var ?social:Bool;

  /**
   * An optional tag to filter the results by.
   * @default `null`
   */
  var ?tag:String;

  /**
   * If true, only the scores from the currently logged in user will be loaded.
   * Additionally, if `social` is set to true, the scores of the user's friend will be loaded.
   * @default `false`
   */
  var ?useCurrentUser:Bool;

  var ?onComplete:Array<Score>->Void;
  var ?onFail:Void->Void;
}
#end

/**
 * An enumeration of Newgrounds leaderboards for the game's levels and songs.
 */
enum abstract Leaderboard(Int) from Int to Int
{
  /**
   * Represents an undefined or invalid leaderboard.
   */
  public var Unknown = -1;

  //
  // STORY LEVELS
  //
  // Tutorial only has one song.
  public var StoryWeek1 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14239 #else 9615 #end;
  public var StoryWeek2 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14240 #else 9616 #end;
  public var StoryWeek3 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14242 #else 9767 #end;
  public var StoryWeek4 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14241 #else 9866 #end;
  public var StoryWeek5 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14243 #else 9956 #end;
  public var StoryWeek6 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14244 #else 9957 #end;
  public var StoryWeek7 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14245 #else 14682 #end;
  public var StoryWeekend1 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14237 #else 14683 #end;

  // Collab 1 only has one song.
  //
  // SONGS
  //
  // Tutorial
  public var Tutorial = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14249 #else 14684 #end;

  // Week 1
  public var Bopeebo = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14246 #else 9603 #end;
  public var BopeeboErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14685 #end;
  public var BopeeboPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14686 #end;
  public var Fresh = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14247 #else 9602 #end;
  public var FreshErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14687 #end;
  public var FreshPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14688 #end;
  public var DadBattle = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 14248 #else 9605 #end;
  public var DadBattleErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14689 #end;
  public var DadBattlePicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14690 #end;

  // Week 2
  public var Spookeez = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9604 #end;
  public var SpookeezErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14691 #end;
  public var SpookeezPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14692 #end;
  public var South = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9606 #end;
  public var SouthErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14693 #end;
  public var SouthPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14694 #end;
  public var Monster = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14703 #end;

  // Week 3
  public var Pico = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9766 #end;
  public var PicoErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14695 #end;
  public var PicoPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14696 #end;
  public var PhillyNice = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9769 #end;
  public var PhillyNiceErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14697 #end;
  public var PhillyNicePicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14698 #end;
  public var Blammed = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9768 #end;
  public var BlammedErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14704 #end;
  public var BlammedPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14705 #end;

  // Week 4
  public var SatinPanties = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9869 #end;
  public var SatinPantiesErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14701 #end;
  public var High = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9867 #end;
  public var HighErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14699 #end;
  public var MILF = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9868 #end;

  // Week 5
  public var Cocoa = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14706 #end;
  public var CocoaErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14707 #end;
  public var CocoaPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14708 #end;
  public var Eggnog = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14709 #end;
  public var EggnogErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14711 #end;
  public var EggnogPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14710 #end;
  public var WinterHorrorland = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14712 #end;

  // Week 6
  public var Senpai = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9958 #end;
  public var SenpaiErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14713 #end;
  public var SenpaiPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14716 #end;
  public var Roses = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9959 #end;
  public var RosesErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14714 #end;
  public var RosesPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14717 #end;
  public var Thorns = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 9960 #end;
  public var ThornsErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14715 #end;

  // Week 7
  public var Ugh = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14718 #end;
  public var UghErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14722 #end;
  public var UghPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14721 #end;
  public var Guns = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14719 #end;
  public var GunsPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14723 #end;
  public var Stress = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14720 #end;
  public var StressPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14724 #end;

  // Weekend 1
  public var Darnell = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14725 #end;
  public var DarnellErect = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14727 #end;
  public var DarnellBFMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14726 #end;
  public var LitUp = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14728 #end;
  public var LitUpBFMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14729 #end;
  public var TwoHot = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14730 #end; // Variable names can't start with a number!
  public var Blazin = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 1000000 #else 14731 #end;

  // Collab 1
  public var Spaghetti = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 15448 #else 15451 #end;

  /**
   * Get the numeric ID for the leaderboard on the Newgrounds site.
   * @return The numeric ID for the leaderboard.
   */
  public function getId():Int
  {
    return this;
  }

  /**
   * Get the leaderboard for a given level and difficulty.
   * @param levelId The ID for the story level.
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
      // Collab 1 has only one song.
      default:
        return Unknown;
    }
  }

  /**
   * Get the leaderboard for a given song and difficulty.
   *
   * @param songId The ID for the song.
   * @param difficulty The current difficulty, suffixed with the variation, like `easy-pico` or `nightmare`.
   * @return The Leaderboard ID for the given level and difficulty.
   */
  public static function getLeaderboardBySong(songId:String, difficulty:String):Leaderboard
  {
    var variation = Constants.DEFAULT_VARIATION;
    var difficultyParts = difficulty.split('-');

    if (difficultyParts.length >= 2)
    {
      variation = difficultyParts[difficultyParts.length - 1];
    }
    else if (Constants.DEFAULT_DIFFICULTY_LIST_ERECT.contains(difficulty))
    {
      variation = "erect";
    }

    switch (variation)
    {
      case "pico":
        switch (songId)
        {
          case "bopeebo":
            return BopeeboPicoMix;
          case "fresh":
            return FreshPicoMix;
          case "dadbattle":
            return DadBattlePicoMix;
          case "spookeez":
            return SpookeezPicoMix;
          case "south":
            return SouthPicoMix;
          case "pico":
            return PicoPicoMix;
          case "philly-nice":
            return PhillyNicePicoMix;
          case "blammed":
            return BlammedPicoMix;
          case "cocoa":
            return CocoaPicoMix;
          case "eggnog":
            return EggnogPicoMix;
          case "senpai":
            return SenpaiPicoMix;
          case "roses":
            return RosesPicoMix;
          case "ugh":
            return UghPicoMix;
          case "guns":
            return GunsPicoMix;
          case "stress":
            return StressPicoMix;
          default:
            return Unknown;
        }
      case "bf":
        switch (songId)
        {
          case "darnell":
            return DarnellBFMix;
          case "lit-up":
            return LitUpBFMix;
          default:
            return Unknown;
        }
      case "erect":
        switch (songId)
        {
          case "bopeebo":
            return BopeeboErect;
          case "fresh":
            return FreshErect;
          case "dadbattle":
            return DadBattleErect;
          case "spookeez":
            return SpookeezErect;
          case "south":
            return SouthErect;
          case "pico":
            return PicoErect;
          case "philly-nice":
            return PhillyNiceErect;
          case "blammed":
            return BlammedErect;
          case "satin-panties":
            return SatinPantiesErect;
          case "high":
            return HighErect;
          case "cocoa":
            return CocoaErect;
          case "eggnog":
            return EggnogErect;
          case "senpai":
            return SenpaiErect;
          case "roses":
            return RosesErect;
          case "thorns":
            return ThornsErect;
          case "ugh":
            return UghErect;
          case "darnell":
            return DarnellErect;
          default:
            return Unknown;
        }
      case "default":
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
          case "lit-up":
            return LitUp;
          case "2hot":
            return TwoHot;
          case "blazin":
            return Blazin;
          case "spaghetti":
            return Spaghetti;
          default:
            return Unknown;
        }
      default:
        return Unknown;
    }
  }
}
