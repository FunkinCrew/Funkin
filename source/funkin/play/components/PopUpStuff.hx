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

/*
 * The class which is responsible for managing in-game Pop-ups.
 */
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

  /*
   * A group that contains all of the rating Pop-ups.
   * Used to easily recycle previous ratings.
   */
  var ratingGroup:FlxTypedSpriteGroup<Null<FunkinSprite>>;

  var latestRatingZIndex:Int = 0;

  /*
   * A group that contains all of the combo number Pop-ups
   * Used to easily recycle previous combo numbers.
   */
  var numberGroup:FlxTypedSpriteGroup<Null<FunkinSprite>>;

  var latestComboZIndex:Int = 0;

  override public function new(noteStyle:NoteStyle)
  {
    super();

    this.noteStyle = noteStyle;

    ratingGroup = new FlxTypedSpriteGroup<Null<FunkinSprite>>(0, -60);
    ratingGroup.scrollFactor.set(0.2, 0.2);
    numberGroup = new FlxTypedSpriteGroup<Null<FunkinSprite>>(FlxG.width * 0.033, FlxG.camera.height * 0.01);

    add(ratingGroup);
    add(numberGroup);
  }

  /*
    * Creates a Rating Pop-up and displays it when the player hits a note.
    @param daRating Null<String>
    @return Void
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
      rating.alpha = 1;
      rating.setPosition(ratingGroup.x, ratingGroup.y);
      rating.revive();
    }
    else
    {
      rating = new FunkinSprite();
      ratingGroup.add(rating);
    }

    var ratingInfo:JudgementSpriteInfo = noteStyle.buildJudgementSprite(daRating) ??
      {
        assetPath: null,
        scale: new FlxPoint(1.0, 1.0),
        isPixel: false,
      };

    // Can't think of a better way to do this.
    rating.zIndex = latestRatingZIndex;
    latestRatingZIndex++;
    ratingGroup.sort(SortUtil.byZIndex, FlxSort.ASCENDING);

    rating.loadTexture(ratingInfo.assetPath);

    rating.scale = ratingInfo.scale;

    rating.antialiasing = !ratingInfo.isPixel;
    rating.pixelPerfectRender = ratingInfo.isPixel;
    rating.pixelPerfectPosition = ratingInfo.isPixel;
    rating.updateHitbox();

    rating.x -= rating.width / 2;
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
          rating.kill();
        },
        startDelay: Conductor.instance.beatLengthMs * 0.001,
        ease: fadeEase
      });
  }

  /*
    * Creates a Combo Pop-up to display the player's combo when hitting a note.
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

    for (i in 0...seperatedScore.length)
    {
      var numScore:Null<FunkinSprite> = null;

      numScore = numberGroup.getFirstDead();

      if (numScore != null)
      {
        numScore.acceleration.y = 0;
        numScore.velocity.set(0, 0);
        numScore.alpha = 1;
        numScore.setPosition(numberGroup.x, numberGroup.y);
        numScore.revive();
      }
      else
      {
        numScore = new FunkinSprite();
        numberGroup.add(numScore);
      }

      var comboInfo:JudgementSpriteInfo = noteStyle.buildComboNumSprite(seperatedScore[i]);

      numScore.zIndex = latestComboZIndex;
      latestComboZIndex++;
      numberGroup.sort(SortUtil.byZIndex, FlxSort.ASCENDING);
      numScore.loadTexture(comboInfo.assetPath);

      numScore.scale = comboInfo.scale;

      numScore.antialiasing = !comboInfo.isPixel;
      numScore.pixelPerfectRender = comboInfo.isPixel;
      numScore.pixelPerfectPosition = comboInfo.isPixel;
      numScore.updateHitbox();

      numScore.x = numberGroup.x - (36 * (i + 1)) - 65;
      numScore.x += offsets[0];
      numScore.y += offsets[1];
      var styleOffsets = noteStyle.getComboNumSpriteOffsets(seperatedScore[i]);
      numScore.x += styleOffsets[0];
      numScore.y += styleOffsets[1];

      numScore.acceleration.y = FlxG.random.int(250, 300);
      numScore.velocity.y -= FlxG.random.int(130, 150);
      numScore.velocity.x = FlxG.random.float(-5, 5);

      var fadeEase = noteStyle.isComboNumSpritePixel(seperatedScore[i]) ? EaseUtil.stepped(2) : null;

      FlxTween.tween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            numScore.kill();
          },
          startDelay: Conductor.instance.beatLengthMs * 0.002,
          ease: fadeEase
        });
    }
  }
}

typedef JudgementSpriteInfo =
{
  var assetPath:Null<String>;
  var scale:FlxPoint;
  var isPixel:Bool;
}
