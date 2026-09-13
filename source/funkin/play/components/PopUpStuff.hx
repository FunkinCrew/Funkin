package funkin.play.components;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import funkin.graphics.FunkinSprite;
import funkin.util.EaseUtil;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.PlayState;

@:nullSafety
class PopUpStuff extends FlxTypedGroup<FunkinSprite>
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

  override public function new(noteStyle:NoteStyle)
  {
    super();

    this.noteStyle = noteStyle;
  }

  var judgementPool:Map<String, Array<FunkinSprite>> = [];
  var comboNumPool:Map<Int, Array<FunkinSprite>> = [];

  function acquireJudgementSprite(rating:String):Null<FunkinSprite>
  {
    var pool:Null<Array<FunkinSprite>> = judgementPool.get(rating);
    if (pool != null && pool.length > 0) return resetPooledSprite(pool.pop());

    var sprite:Null<FunkinSprite> = noteStyle.buildJudgementSprite(rating);
    if (sprite == null) return null;

    if (pool == null) judgementPool.set(rating, []);
    return sprite;
  }

  function releaseJudgementSprite(rating:String, sprite:FunkinSprite):Void
  {
    remove(sprite, true);
    var pool:Null<Array<FunkinSprite>> = judgementPool.get(rating);
    if (pool == null)
    {
      pool = [];
      judgementPool.set(rating, pool);
    }
    pool.push(sprite);
  }

  function acquireComboNumSprite(digit:Int):Null<FunkinSprite>
  {
    var pool:Null<Array<FunkinSprite>> = comboNumPool.get(digit);
    if (pool != null && pool.length > 0) return resetPooledSprite(pool.pop());

    var sprite:Null<FunkinSprite> = noteStyle.buildComboNumSprite(digit);
    if (sprite == null) return null;

    if (pool == null) comboNumPool.set(digit, []);

    // The blacklist is keyed by graphic, so a pooled sprite only needs registering once.
    if (PlayState.instance != null)
    {
      PlayState.instance.dropShadowLayer.renderer.blacklistSprite(sprite);
    }

    return sprite;
  }

  function releaseComboNumSprite(digit:Int, sprite:FunkinSprite):Void
  {
    remove(sprite, true);
    var pool:Null<Array<FunkinSprite>> = comboNumPool.get(digit);
    if (pool == null)
    {
      pool = [];
      comboNumPool.set(digit, pool);
    }
    pool.push(sprite);
  }

  function resetPooledSprite(sprite:Null<FunkinSprite>):Null<FunkinSprite>
  {
    if (sprite == null) return null;
    sprite.alpha = 1.0;
    sprite.velocity.set(0, 0);
    sprite.acceleration.set(0, 0);
    return sprite;
  }

  override public function destroy():Void
  {
    super.destroy();

    for (pool in judgementPool)
    {
      for (sprite in pool)
      {
        sprite.destroy();
      }
    }
    judgementPool.clear();

    for (pool in comboNumPool)
    {
      for (sprite in pool)
      {
        sprite.destroy();
      }
    }
    comboNumPool.clear();
  }

  public function displayRating(daRating:Null<String>)
  {
    if (daRating == null) daRating = "good";

    var rating:Null<FunkinSprite> = acquireJudgementSprite(daRating);
    if (rating == null) return;

    rating.zIndex = 1000;

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

    rating.graphic.destroyOnNoUse = false;

    add(rating);

    var fadeEase = noteStyle.isJudgementSpritePixel(daRating) ? EaseUtil.stepped(2) : null;

    final ratingKey:String = daRating;
    FlxTween.tween(rating, {
      alpha: 0
    }, 0.2, {
      onComplete: function(tween:FlxTween)
      {
        releaseJudgementSprite(ratingKey, rating);
      },
      startDelay: Conductor.instance.beatLengthMs * 0.001,
      ease: fadeEase
    });
  }

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

    // seperatedScore.reverse();

    var daLoop:Int = 1;
    for (digit in seperatedScore)
    {
      var numScore:Null<FunkinSprite> = acquireComboNumSprite(digit);
      if (numScore == null) continue;

      numScore.x = (FlxG.width * 0.507) - (36 * daLoop) - 65;
      numScore.y = (FlxG.camera.height * 0.44);

      numScore.x += offsets[0];
      numScore.y += offsets[1];
      var styleOffsets = noteStyle.getComboNumSpriteOffsets(digit);
      numScore.x += styleOffsets[0];
      numScore.y += styleOffsets[1];

      numScore.acceleration.y = FlxG.random.int(250, 300);
      numScore.velocity.y -= FlxG.random.int(130, 150);
      numScore.velocity.x = FlxG.random.float(-5, 5);

      numScore.graphic.destroyOnNoUse = false;

      add(numScore);

      var fadeEase = noteStyle.isComboNumSpritePixel(digit) ? EaseUtil.stepped(2) : null;

      final digitKey:Int = digit;
      FlxTween.tween(numScore, {
        alpha: 0
      }, 0.2, {
        onComplete: function(tween:FlxTween)
        {
          releaseComboNumSprite(digitKey, numScore);
        },
        startDelay: Conductor.instance.beatLengthMs * 0.002,
        ease: fadeEase
      });

      daLoop++;
    }
  }
}
