package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirection;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import funkin.util.TimerUtil;
import openfl.utils.Assets;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;

class PopUpStuff extends FlxTypedGroup<FlxSprite>
{
  public var offsets:Array<Int> = [0, 0];

  /**
   * Which alternate graphic on popup to use.
   * This is set via the current notestyle.
   * For example, in Week 6 it is `pixel`.
   */
  static var noteStyle:NoteStyle;

  static var fallbackNoteStyle:Null<NoteStyle>;

  static var isPixel:Bool = false;

  override public function new()
  {
    super();

    fetchNoteStyle();
  }

  static function fetchNoteStyle():Void
  {
    var fetchedNoteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(PlayState.instance.currentChart.noteStyle);
    if (fetchedNoteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
    else noteStyle = fetchedNoteStyle;
    fallbackNoteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyle.getFallbackID());
    isPixel = false;
  }

  static function resolveGraphicPath(noteStyle:NoteStyle, index:String):Null<String>
  {
    fetchNoteStyle();
    var basePath:String = 'ui/popup/';
    var spritePath:String = basePath + noteStyle.id + '/$index';

    while (!Assets.exists(Paths.image(spritePath)) && fallbackNoteStyle != null)
    {
      noteStyle = fallbackNoteStyle;
      fallbackNoteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyle.getFallbackID());
      spritePath = basePath + noteStyle.id + '/$index';
    }
    if (noteStyle.isHoldNotePixel()) isPixel = true;

    // If nothing is found, revert it to default notestyle skin
    if (!Assets.exists(Paths.image(spritePath)))
    {
      if (!isPixel) spritePath = basePath + Constants.DEFAULT_NOTE_STYLE + '/$index';
      else spritePath = basePath + Constants.DEFAULT_PIXEL_NOTE_STYLE + '/$index';
    }

    return spritePath;
  }

  public function displayRating(daRating:String)
  {
    var perfStart:Float = TimerUtil.start();

    if (daRating == null) daRating = "good";

    var ratingPath:String = resolveGraphicPath(noteStyle, daRating);

    //if (PlayState.instance.currentStageId.startsWith('school')) ratingPath = "weeb/pixelUI/" + ratingPath + "-pixel";

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

    if (isPixel)
    {
      rating.setGraphicSize(Std.int(rating.width * Constants.PIXEL_ART_SCALE * 0.7));
      rating.antialiasing = false;
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
        startDelay: Conductor.instance.beatLengthMs * 0.001
      });

    trace('displayRating took: ${TimerUtil.seconds(perfStart)}');
  }

  public function displayCombo(?combo:Int = 0):Int
  {
    var perfStart:Float = TimerUtil.start();

    if (combo == null) combo = 0;

    var comboPath:String = resolveGraphicPath(noteStyle, 'combo');
    var comboSpr:FunkinSprite = FunkinSprite.create(comboPath);
    comboSpr.y = (FlxG.camera.height * 0.44) + offsets[1];
    comboSpr.x = (FlxG.width * 0.507) + offsets[0];
    // comboSpr.x -= FlxG.camera.scroll.x * 0.2;

    comboSpr.acceleration.y = 600;
    comboSpr.velocity.y -= 150;
    comboSpr.velocity.x += FlxG.random.int(1, 10);

    // add(comboSpr);

    if (isPixel) comboSpr.setGraphicSize(Std.int(comboSpr.width * Constants.PIXEL_ART_SCALE * 0.7));
    else comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));

    comboSpr.antialiasing = !isPixel;
    comboSpr.updateHitbox();

    FlxTween.tween(comboSpr, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          remove(comboSpr, true);
          comboSpr.destroy();
        },
        startDelay: Conductor.instance.beatLengthMs * 0.001
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
      var numScore:FunkinSprite = FunkinSprite.create(0, comboSpr.y, resolveGraphicPath(noteStyle, 'num' + Std.int(i)));

      if (isPixel) numScore.setGraphicSize(Std.int(numScore.width * Constants.PIXEL_ART_SCALE * 0.7));
      else numScore.setGraphicSize(Std.int(numScore.width * 0.45));

      numScore.antialiasing = !isPixel;
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
          startDelay: Conductor.instance.beatLengthMs * 0.002
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
    noteStyle = NoteStyleRegistry.instance.fetchDefault();
    isPixel = false;
  }
}
