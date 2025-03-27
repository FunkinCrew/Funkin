package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS
import io.newgrounds.objects.Medal as MedalData;
import funkin.util.plugins.NewgroundsMedalPlugin;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

class Medals
{
  public static var medalJSON:Array<MedalJSON>;

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

  static function isValid(medalData:MedalData):Bool
  {
    // IDK why medalData can exist but _data can be null...
    // TODO: Move checks to the NG library.
    @:privateAccess
    return (medalData != null && medalData._data != null);
  }

  public static function award(medal:Medal):Void
  {
    if (NewgroundsClient.instance.isLoggedIn())
    {
      var medalData = NewgroundsClient.instance.medals.get(medal.getId());
      if (!isValid(medalData))
      {
        trace('[NEWGROUNDS] Could not retrieve data for medal: ${medal}');
        return;
      }

      if (!medalData.unlocked)
      {
        trace('[NEWGROUNDS] Awarding medal (${medal}).');
        medalData.sendUnlock();

        // Play the medal unlock animation, but only if the user has not already unlocked it.
        #if html5
        // Web builds support parsing the bitmap data from the URL directly.
        BitmapData.loadFromFile("https:" + medalData.icon).onComplete(function(bmp:BitmapData) {
          var medalGraphic = FlxGraphic.fromBitmapData(bmp);
          medalGraphic.persist = true;
          NewgroundsMedalPlugin.play(medalData.value, medalData.name, medalGraphic);
        });
        #else
        if (medalJSON == null) loadMedalJSON();
        // We have to use a medal image from the game files. We use a Base64 encoded image that NG spits out.
        var g:FlxGraphic = null;
        var str:String = medalJSON.filter(function(jsonMedal) return medal == jsonMedal.id)[0].icon;
        // Lime/OpenFL parses it without the included prefix stuff, so we remove it.
        str = str.replace("data:image/png;base64,", "").trim();
        var bitmapData = BitmapData.fromBase64(str, "image/png");
        if (str != null) g = FlxGraphic.fromBitmapData(bitmapData);
        g.persist = true;

        NewgroundsMedalPlugin.play(medalData.value, medalData.name, g);
        #end
      }
      else
      {
        trace('[NEWGROUNDS] User already has medal (${medal}).');
      }
    }
    else
    {
      trace('[NEWGROUNDS] Attempted to award medal (${medal}), but not logged into Newgrounds.');
    }
  }

  public static function loadMedalJSON():Void
  {
    var jsonPath = Paths.json('medals');
    var jsonString = Assets.getText(jsonPath);
    medalJSON = cast Json.parse(jsonString);
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

/**
 * Represents NG Medal data in a JSON format.
 */
typedef MedalJSON =
{
  var id:Int;
  var name:String;
  var icon:String;
}

enum abstract Medal(Int) from Int to Int
{
  /**
   * Represents an undefined or invalid medal.
   */
  var Unknown = -1;

  /**
   * I Said Funkin'!
   * Start the game for the first time.
   */
  var StartGame = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80894 #else 60960 #end;

  /**
   * That's How You Do It!
   * Beat Tutoria l in Story Mode (on any difficulty).
   */
  var StoryTutorial = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80906 #else 1000000 #end;

  /**
   * More Like Daddy Queerest
   * Beat Week 1 in Story Mode (on any difficulty).
   */
  var StoryWeek1 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80899 #else 60961 #end;

  /**
   * IT IS THE SPOOKY MONTH
   * Beat Week 2 in Story Mode (on any difficulty).
   */
  var StoryWeek2 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80900 #else 1000000 #end;

  /**
   * Zeboim Damn Ima Nut
   * Beat Week 3 in Story Mode (on any difficulty).
   */
  var StoryWeek3 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80901 #else 1000000 #end;

  /**
   * Mommy Must Murder
   * Beat Week 4 in Story Mode (on any difficulty).
   */
  var StoryWeek4 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80902 #else 1000000 #end;

  /**
   * FNF Corruption Mod (real)
   * Beat Week 5 in Story Mode (on any difficulty).
   */
  var StoryWeek5 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80903 #else 1000000 #end;

  /**
   * The Original .EXE
   * Beat Week 6 in Story Mode (on any difficulty).
   */
  var StoryWeek6 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80904 #else 1000000 #end;

  /**
   * I'm Gonna Beep-Beep a Garbage Truck Into Your Girlfriend's Face!
   * Beat Week 7 in Story Mode (on any difficulty).
   */
  var StoryWeek7 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80905 #else 1000000 #end;

  /**
   * Yo, Really Think So?
   * Beat Weekend 1 in Story Mode (on any difficulty).
   */
  var StoryWeekend1 = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80907 #else 1000000 #end;

  /**
   * A Challenger Appears
   * Beat any Pico remix in Freeplay (on any difficulty).
   */
  var FreeplayPicoMix = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80910 #else 1000000 #end;

  /**
   * The Sex Update
   * Earn a Perfect rating on any song on Hard difficulty or higher.
   * NOTE: Should also be awarded for a Gold Perfect because otherwise that would be annoying.
   */
  var PerfectRatingHard = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80908 #else 1000000 #end;

  /**
   * Get Ratio'd
   * Earn a Loss rating on any song (on any difficulty).
   */
  var LossRating = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80915 #else 1000000 #end;

  /**
   * You Should Drink More Water
   * Earn a Golden Perfect rating on any song on Hard difficulty or higher.
   */
  var GoldPerfectRatingHard = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80909 #else 1000000 #end;

  /**
   * Harder Than Hard
   * Beat any Erect remix in Freeplay on Erect or Nightmare difficulty.
   */
  var ErectDifficulty = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80911 #else 1000000 #end;

  /**
   * The Rap God
   * Earn a Gold Perfect rating on any song on Nightmare difficulty.
   */
  var GoldPerfectRatingNightmare = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80912 #else 1000000 #end;

  /**
   * Just Like The Game!
   * Get freaky on a Friday.
   * NOTE: You must beat at least one song on any difficulty.
   */
  var FridayNight = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80913 #else 61034 #end;

  /**
   * Nice
   * Earn a rating of EXACTLY 69% (good luck).
   */
  var Nice = #if FEATURE_NEWGROUNDS_TESTING_MEDALS 80914 #else 1000000 #end;

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
