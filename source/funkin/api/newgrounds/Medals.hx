package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS
import io.newgrounds.objects.Medal as MedalData;
import funkin.util.plugins.NewgroundsMedalPlugin;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

class Medals
{
  public static function listMedalData():Map<Medal, MedalData>
  {
    if (NewgroundsClient.instance.medals == null)
    {
      trace('[NEWGROUNDS] Not logged in, cannot fetch medal data!');
      return [];
    }

    var result:Map<Medal, MedalData> = [];

    for (medalId in NewgroundsClient.instance.medals.keys())
    {
      var medalData = NewgroundsClient.instance.medals.get(medalId);
      if (medalData == null) continue;

      // A little hacky, but it works.
      result.set(cast medalId, medalData);
    }

    return result;
  }

  public static function award(medal:Medal):Void
  {
    if (NewgroundsClient.instance.isLoggedIn())
    {
      var medalData = NewgroundsClient.instance.medals.get(medal.getId());
      if (!medalData.unlocked)
      {
        trace('[NEWGROUNDS] Awarding medal (${medal}).');
        medalData.sendUnlock();

        // Play the medal unlock animation, but only if the user has not already unlocked it.
        BitmapData.loadFromFile("https:" + medalData.icon).onComplete(function(bmp:BitmapData) {
          NewgroundsMedalPlugin.play(medalData.value, medalData.name, FlxGraphic.fromBitmapData(bmp));
        });
      }
      else
      {
        trace('[NEWGROUNDS] User already awarded medal (${medal}).');
      }
    }
    else
    {
      trace('[NEWGROUNDS] Attempted to award medal (${medal}), but not logged into Newgrounds.');
    }
  }

  public static function awardStoryLevel(id:String):Void
  {
    switch (id)
    {
      case 'tutorial':
        Medals.award(Medal.StoryTutorial);
      case 'week1':
        Medals.award(Medal.StoryWeek1);
      case 'week2':
        Medals.award(Medal.StoryWeek2);
      case 'week3':
        Medals.award(Medal.StoryWeek3);
      case 'week4':
        Medals.award(Medal.StoryWeek4);
      case 'week5':
        Medals.award(Medal.StoryWeek5);
      case 'week6':
        Medals.award(Medal.StoryWeek6);
      case 'week7':
        Medals.award(Medal.StoryWeek7);
      case 'weekend1':
        Medals.award(Medal.StoryWeekend1);
      default:
        trace('[NEWGROUNDS] Story level does not have a medal! (${id}).');
    }
  }
}
#end

enum abstract Medal(Int)
{
  /**
   * Represents an undefined or invalid medal.
   */
  var Unknown = -1;

  /**
   * I Said Funkin'!
   * Start the game for the first time.
   */
  var StartGame = #if FEATURE_NEWGROUNDS_DEBUG 80894 #else 60960 #end;

  /**
   * That's How You Do It!
   * Beat Tutoria l in Story Mode (on any difficulty).
   */
  var StoryTutorial = 80906;

  /**
   * More Like Daddy Queerest
   * Beat Week 1 in Story Mode (on any difficulty).
   */
  var StoryWeek1 = #if FEATURE_NEWGROUNDS_DEBUG 80899 #else 60961 #end;

  /**
   * IT IS THE SPOOKY MONTH
   * Beat Week 2 in Story Mode (on any difficulty).
   */
  var StoryWeek2 = #if FEATURE_NEWGROUNDS_DEBUG 80900 #else 1000000 #end;

  /**
   * Zeboim Damn Ima Nut
   * Beat Week 3 in Story Mode (on any difficulty).
   */
  var StoryWeek3 = #if FEATURE_NEWGROUNDS_DEBUG 80901 #else 1000000 #end;

  /**
   * Mommy Must Murder
   * Beat Week 4 in Story Mode (on any difficulty).
   */
  var StoryWeek4 = #if FEATURE_NEWGROUNDS_DEBUG 80902 #else 1000000 #end;

  /**
   * FNF Corruption Mod (real)
   * Beat Week 5 in Story Mode (on any difficulty).
   */
  var StoryWeek5 = #if FEATURE_NEWGROUNDS_DEBUG 80903 #else 1000000 #end;

  /**
   * The Original .EXE
   * Beat Week 6 in Story Mode (on any difficulty).
   */
  var StoryWeek6 = #if FEATURE_NEWGROUNDS_DEBUG 80904 #else 1000000 #end;

  /**
   * I'm Gonna Beep-Beep a Garbage Truck Into Your Girlfriend's Face!
   * Beat Week 7 in Story Mode (on any difficulty).
   */
  var StoryWeek7 = #if FEATURE_NEWGROUNDS_DEBUG 80905 #else 1000000 #end;

  /**
   * Yo, Really Think So?
   * Beat Weekend 1 in Story Mode (on any difficulty).
   */
  var StoryWeekend1 = #if FEATURE_NEWGROUNDS_DEBUG 80907 #else 1000000 #end;

  /**
   * A Challenger Appears
   * Beat any Pico remix in Freeplay (on any difficulty).
   */
  var FreeplayPicoMix = #if FEATURE_NEWGROUNDS_DEBUG 80910 #else 1000000 #end;

  /**
   * The Sex Update
   * Earn a Perfect rating on any song on Hard difficulty or higher.
   * NOTE: Should also be awarded for a Gold Perfect because otherwise that would be annoying.
   */
  var PerfectRatingHard = #if FEATURE_NEWGROUNDS_DEBUG 80908 #else 1000000 #end;

  /**
   * Get Ratio'd
   * Earn a Loss rating on any song (on any difficulty).
   */
  var LossRating = #if FEATURE_NEWGROUNDS_DEBUG 80915 #else 1000000 #end;

  /**
   * You Should Drink More Water
   * Earn a Golden Perfect rating on any song on Hard difficulty or higher.
   */
  var GoldPerfectRatingHard = #if FEATURE_NEWGROUNDS_DEBUG 80909 #else 1000000 #end;

  /**
   * Harder Than Hard
   * Beat any Erect remix in Freeplay on Erect or Nightmare difficulty.
   */
  var ErectDifficulty = #if FEATURE_NEWGROUNDS_DEBUG 80911 #else 1000000 #end;

  /**
   * The Rap God
   * Earn a Gold Perfect rating on any song on Nightmare difficulty.
   */
  var GoldPerfectRatingNightmare = #if FEATURE_NEWGROUNDS_DEBUG 80912 #else 1000000 #end;

  /**
   * Just Like The Game!
   * Get freaky on a Friday.
   * NOTE: You must beat at least one song on any difficulty.
   */
  var FridayNight = #if FEATURE_NEWGROUNDS_DEBUG 80913 #else 61034 #end;

  /**
   * Nice
   * Earn a rating of EXACTLY 69% (good luck).
   */
  var Nice = 80914;

  public function getId():Int
  {
    return this;
  }

  public static function getMedalByStoryLevel(levelId:String):Medal
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
}
