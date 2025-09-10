package funkin.play.components;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import funkin.graphics.FunkinSprite;
import funkin.util.EaseUtil;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.math.FlxPoint;
import funkin.util.SortUtil;
import flixel.util.FlxSort;

// @:nullSafety
class PopUpStuff extends FlxSpriteGroup
{
  /**
   * The current note style to use. This determines which graphics to display.
   * For example, Week 6 uses the `pixel` note style, and mods can create their own.
   */
  var noteStyle:NoteStyle;

  /**
   * Offsets that are applied to all elements, independent of the note style.
   * Used to allow scripts to reposition the elements.
   */
  var offsets:Array<Int> = [0, 0];

  var ratingGroup:FlxTypedSpriteGroup<Null<FunkinSprite>>;
  var latestZIndex:Int = 0;

  var numberGroup:FlxTypedSpriteGroup<Null<FunkinSprite>>;

  override public function new(noteStyle:NoteStyle)
  {
    super();

    this.noteStyle = noteStyle;

    ratingGroup = new FlxTypedSpriteGroup<Null<FunkinSprite>>();
    // ratingGroup.zIndex = 1000;
    numberGroup = new FlxTypedSpriteGroup<Null<FunkinSprite>>();

    add(numberGroup);
    add(ratingGroup);
  }

  /*
    * Display the player's rating when hitting a note.
    @param daRating Null<String>
    @return
   */
  public function displayRating(daRating:Null<String>):Void
  {
    if (daRating == null) daRating = "good";

    var rating:Null<FunkinSprite> = null;

    rating = ratingGroup.getFirstDead();

    if (rating != null)
    {
      rating.acceleration.y = 0;
      rating.velocity.y = 0;
      rating.velocity.x = 0;
      // rating.zIndex = 0;
      rating.alpha = 1;
      rating.revive();
    }
    else
    {
      rating = new FunkinSprite();
      ratingGroup.add(rating);
    }

    if (rating == null) return;
    var ratingInfo = noteStyle.buildJudgementSprite(daRating) ??
      {
        assetPath: null,
        scale: new FlxPoint(1.0, 1.0),
        scrollFactor: new FlxPoint(1.0, 1.0),
        isPixel: false,
      };

    rating.zIndex = latestZIndex;
    latestZIndex--;
    ratingGroup.sort(SortUtil.byZIndex, FlxSort.DESCENDING);
    trace("rating Z index: " + rating.zIndex);
    rating.loadTexture(ratingInfo.assetPath);

    rating.scale = ratingInfo.scale;
    rating.scrollFactor = ratingInfo.scrollFactor;

    rating.antialiasing = !ratingInfo.isPixel;
    rating.pixelPerfectRender = ratingInfo.isPixel;
    rating.pixelPerfectPosition = ratingInfo.isPixel;
    rating.updateHitbox();

    trace(ratingGroup.length);
    rating.x = (FlxG.width * 0.474);
    rating.x -= rating.width / 2;
    rating.y = (FlxG.camera.height * 0.45 - 60);
    rating.y -= rating.height / 2;
    rating.x += offsets[0];
    rating.y += offsets[1];
    var styleOffsets = noteStyle.getJudgementSpriteOffsets(daRating);

    rating.x += styleOffsets[0];
    rating.y += styleOffsets[1];
    rating.acceleration.y = 550;
    rating.velocity.y -= FlxG.random.int(140, 175);
    rating.velocity.x -= FlxG.random.int(0, 10);

    var fadeEase = noteStyle.isJudgementSpritePixel(daRating) ? EaseUtil.stepped(2) : null;

    FlxTween.tween(rating, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          // rating.zIndex = 1000;
          rating.kill();
          trace("Killed Rating!");
        },
        startDelay: Conductor.instance.beatLengthMs * 0.001,
        ease: fadeEase
      });
  }

  /*
    * Display the player's combo when hitting a note.
     @param combo Int
   */
  public function displayCombo(combo:Int = 0):Void
  {
    var seperatedScore:Array<Int> = [];
    var tempCombo:Int = combo;

    while (tempCombo != 0)
    {
      seperatedScore.push(tempCombo % 10);
      tempCombo = Std.int(tempCombo / 10);
    }
    while (seperatedScore.length < 3)
      seperatedScore.push(0);

    var daLoop:Int = 1;
    for (digit in seperatedScore)
    {
      var numScore:Null<FunkinSprite> = null;

      numScore = new FunkinSprite();
      var comboInfo = noteStyle.buildComboNumSprite(digit);

      numScore.loadTexture(comboInfo.assetPath);
      // if (numScore == null) continue;

      // numScore.x = (FlxG.width * 0.507) - (36 * daLoop) - 65;
      // numScore.y = (FlxG.camera.height * 0.44);

      // numScore.x += offsets[0];
      // numScore.y += offsets[1];
      // var styleOffsets = noteStyle.getComboNumSpriteOffsets(digit);
      // numScore.x += styleOffsets[0];
      // numScore.y += styleOffsets[1];

      // numScore.acceleration.y = FlxG.random.int(250, 300);
      // numScore.velocity.y -= FlxG.random.int(130, 150);
      // numScore.velocity.x = FlxG.random.float(-5, 5);

      numberGroup.add(numScore);

      var fadeEase = noteStyle.isComboNumSpritePixel(digit) ? EaseUtil.stepped(2) : null;

      FlxTween.tween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            numberGroup.remove(numScore, true);
            numScore.destroy();
          },
          startDelay: Conductor.instance.beatLengthMs * 0.002,
          ease: fadeEase
        });

      daLoop++;
    }
  }
}

typedef JudgementSpriteInfo =
{
  var assetPath:Null<String>;
  var scale:FlxPoint;
  var scrollFactor:FlxPoint;
  var isPixel:Bool;
}
