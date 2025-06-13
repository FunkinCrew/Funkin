package funkin.mobile.ui;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.util.HapticUtil;
import flixel.util.FlxSignal;

class FunkinBackButton extends FunkinButton
{
  var restingOpacity:Float;

  public var onConfirmEnd(default, null):FlxSignal = new FlxSignal();

  var instant:Bool = false;

  /**
   * Creates a new FunkinBackButton instance.
   *
   * @param xPos The x position of the object.
   * @param yPos The y position of the object.
   * @param theColor Button's optional color.
   * @param confirmCallback An optional callback function that will be triggered when the object is clicked.
   * @param restOpacity An optional float that is the alpha the button will be when not selected/hovered over.
   * @param instant An optional flag that makes the button not play the full animation before calling the callback.
   */
  public function new(?xPos:Float = 0, ?yPos:Float = 0, ?theColor:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?_restOpacity:Float = 0.3,
      _instant:Bool = false):Void
  {
    super(xPos, yPos);

    frames = Paths.getSparrowAtlas("backButton");
    animation.addByIndices('idle', 'back', [0], "", 24, false);
    animation.addByIndices('hold', 'back', [5], "", 24, false);
    animation.addByIndices('confirm', 'back', [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22], "", 24, false);
    animation.play("idle");
    color = theColor;

    scale.set(0.7, 0.7);
    updateHitbox();

    restingOpacity = _restOpacity;
    alpha = restingOpacity;

    ignoreDownHandler = true;
    instant = _instant;

    if (instant)
    {
      onUp.add(confirmCallback);
    }
    else
    {
      onConfirmEnd.add(confirmCallback);
    }

    onUp.add(playConfirmAnim);
    onDown.add(playHoldAnim);
    onOut.add(playOutAnim);
  }

  function playHoldAnim():Void
  {
    FlxTween.cancelTweensOf(this);

    HapticUtil.vibrate(0, 0.01, 0.2);

    animation.play('hold');

    alpha = 1;
  }

  function playConfirmAnim():Void
  {
    FlxTween.cancelTweensOf(this);
    HapticUtil.vibrate(0, 0.05, 0.5);
    animation.play('confirm');
    funkin.audio.FunkinSound.playOnce(Paths.sound('cancelMenu'));

    if (!instant)
    {
      animation.onFinish.add(function(name:String) {
        onConfirmEnd.dispatch();
      });
    }

    onUp.remove(playConfirmAnim);
    onDown.remove(playHoldAnim);
    onOut.remove(playOutAnim);
  }

  function playOutAnim():Void
  {
    FlxTween.cancelTweensOf(this);
    HapticUtil.vibrate(0, 0.01, 0.2);
    animation.play('idle');
    FlxTween.tween(this, {alpha: restingOpacity}, 0.5, {ease: FlxEase.expoOut});
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if android
    if (FlxG.android.justReleased.BACK) onDown.dispatch();
    #end
  }
}
