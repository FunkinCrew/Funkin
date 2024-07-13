package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirection;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import funkin.util.TimerUtil;
import funkin.util.EaseUtil;
import openfl.utils.Assets;

class PopUpStuff extends FlxTypedGroup<FunkinSprite>
{
  public var offsets:Array<Int> = [0, 0];

  /**
   * Which alternate graphic on popup to use.
   * You can set this via script.
   * For example, in Week 6 it is `-pixel`.
   */
  public static var graphicSuffix:String = '';

  override public function new()
  {
    super();
  }

  static function resolveGraphicPath(suffix:String, index:String):Null<String>
  {
    var folder:String;
    if (suffix != '') folder = suffix.substring(0, suffix.indexOf("-")) + suffix.substring(suffix.indexOf("-") + 1);
    else
      folder = 'normal';
    var basePath:String = 'gameplay/popup/$folder/$index';
    var spritePath:String = basePath + suffix;
    trace(spritePath);
    while (!Assets.exists(Paths.image(spritePath)) && suffix.length > 0)
    {
      suffix = suffix.split('-').slice(0, -1).join('-');
      spritePath = basePath + suffix;
    }
    if (!Assets.exists(Paths.image(spritePath))) return null;
    return spritePath;
  }

  public function displayRating(daRating:String)
  {
    var perfStart:Float = TimerUtil.start();

    if (daRating == null) daRating = "good";

    var ratingPath:String = resolveGraphicPath(graphicSuffix, daRating);

    // if (PlayState.instance.currentStageId.startsWith('school')) ratingPath = "weeb/pixelUI/" + ratingPath + "-pixel";

    var rating:FunkinSprite = FunkinSprite.create(0, 0, ratingPath);
    rating.scrollFactor.set(0.2, 0.2);

    rating.zIndex = 1000;
    rating.x = (FlxG.width * 0.474) + offsets[0];
    // rating.x -= FlxG.camera.scroll.x * 0.2;
    rating.y = (FlxG.camera.height * 0.45 - 60) + offsets[1];
    rating.acceleration.y = 550;
    rating.velocity.y -= FlxG.random.int(140, 175);
    rating.velocity.x -= FlxG.random.int(0, 10);

    add(rating);

    var fadeEase = null;

    if (graphicSuffix.toLowerCase().contains('pixel'))
    {
      rating.setGraphicSize(Std.int(rating.width * Constants.PIXEL_ART_SCALE * 0.7));
      rating.antialiasing = false;
      rating.pixelPerfectRender = true;
      rating.pixelPerfectPosition = true;
      fadeEase = EaseUtil.stepped(2);
    }
    else
    {
      rating.setGraphicSize(Std.int(rating.width * 0.65));
      rating.antialiasing = true;
    }
    rating.updateHitbox();

    rating.x -= rating.width / 2;
    rating.y -= rating.height / 2;

    FlxTween.tween(rating, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          remove(rating, true);
          rating.destroy();
        },
        startDelay: Conductor.instance.beatLengthMs * 0.001,
        ease: fadeEase
      });

    trace('displayRating took: ${TimerUtil.seconds(perfStart)}');
  }

  public function displayCombo(?combo:Int = 0):Int
  {
    var perfStart:Float = TimerUtil.start();

    if (combo == null) combo = 0;

    var comboPath:String = resolveGraphicPath(graphicSuffix, Std.string(combo));
    var comboSpr:FunkinSprite = FunkinSprite.create(comboPath);
    comboSpr.y = (FlxG.camera.height * 0.44) + offsets[1];
    comboSpr.x = (FlxG.width * 0.507) + offsets[0];
    // comboSpr.x -= FlxG.camera.scroll.x * 0.2;

    comboSpr.acceleration.y = 600;
    comboSpr.velocity.y -= 150;
    comboSpr.velocity.x += FlxG.random.int(1, 10);

    // add(comboSpr);

    var fadeEase = null;

    if (graphicSuffix.toLowerCase().contains('pixel'))
    {
      comboSpr.setGraphicSize(Std.int(comboSpr.width * Constants.PIXEL_ART_SCALE * 1));
      comboSpr.antialiasing = false;
      comboSpr.pixelPerfectRender = true;
      comboSpr.pixelPerfectPosition = true;
      fadeEase = EaseUtil.stepped(2);
    }
    else
    {
      comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
      comboSpr.antialiasing = true;
    }
    comboSpr.updateHitbox();

    FlxTween.tween(comboSpr, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          remove(comboSpr, true);
          comboSpr.destroy();
        },
        startDelay: Conductor.instance.beatLengthMs * 0.001,
        ease: fadeEase
      });

    var seperatedScore:Array<Int> = [];
    var tempCombo:Int = combo;

    while (tempCombo != 0)
    {
      seperatedScore.push(tempCombo % 10);
      tempCombo = Std.int(tempCombo / 10);
    }
    while (seperatedScore.length < 3)
      seperatedScore.push(0);

    // seperatedScore.reverse();

    var daLoop:Int = 1;
    for (i in seperatedScore)
    {
      var numScore:FunkinSprite = FunkinSprite.create(0, comboSpr.y, resolveGraphicPath(graphicSuffix, 'num' + Std.int(i)));

      if (graphicSuffix.toLowerCase().contains('pixel'))
      {
        numScore.setGraphicSize(Std.int(numScore.width * Constants.PIXEL_ART_SCALE * 1));
        numScore.antialiasing = false;
        numScore.pixelPerfectRender = true;
        numScore.pixelPerfectPosition = true;
      }
      else
      {
        numScore.setGraphicSize(Std.int(numScore.width * 0.45));
        numScore.antialiasing = true;
      }
      numScore.updateHitbox();

      numScore.x = comboSpr.x - (36 * daLoop) - 65; //- 90;
      numScore.acceleration.y = FlxG.random.int(250, 300);
      numScore.velocity.y -= FlxG.random.int(130, 150);
      numScore.velocity.x = FlxG.random.float(-5, 5);

      add(numScore);

      FlxTween.tween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            remove(numScore, true);
            numScore.destroy();
          },
          startDelay: Conductor.instance.beatLengthMs * 0.002,
          ease: fadeEase
        });

      daLoop++;
    }

    trace('displayCombo took: ${TimerUtil.seconds(perfStart)}');

    return combo;
  }

  /**
   * Reset the popup configuration to the default.
   */
  public static function reset()
  {
    graphicSuffix = '';
  }
}
