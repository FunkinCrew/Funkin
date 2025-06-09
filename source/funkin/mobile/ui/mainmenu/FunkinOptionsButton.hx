package funkin.mobile.ui.mainmenu;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.util.HapticUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;

class FunkinOptionsButton extends FunkinButton
{
  public var onConfirmEnd(default, null):FlxSignal = new FlxSignal();

  var instant:Bool = false;

  /**
   * Creates a new FunkinOptionsButton instance.
   *
   * @param xPos The x position of the object.
   * @param yPos The y position of the object.
   * @param confirmCallback An optional callback function that will be triggered when the object is clicked.
   * @param instant An optional flag that makes the button not play the full animation before calling the callback.
   */
  public function new(?xPos:Float = 0, ?yPos:Float = 0, ?confirmCallback:Void->Void, _instant:Bool = false):Void
  {
    super(xPos, yPos);

    frames = Paths.getSparrowAtlas("mainmenu/optionsButton");
    animation.addByIndices('idle', 'options', [0], "", 24, false);
    animation.addByIndices('hold', 'options', [3], "", 24, false);
    animation.addByIndices('confirm', 'options', [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], "", 24, false);
    animation.play("idle");

    scale.set(0.7, 0.7);
    updateHitbox();

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
  }

  function playConfirmAnim():Void
  {
    FlxTween.cancelTweensOf(this);
    HapticUtil.vibrate(0, 0.05, 0.5);
    animation.play('confirm');
    FunkinSound.playOnce(Paths.sound('confirmMenu'));

    new FlxTimer().start(0.05, function(_) {
      HapticUtil.vibrate(0, 0.01, 0.2);
    }, 4);

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
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if android
    if (FlxG.android.justReleased.BACK) onDown.dispatch();
    #end
  }
}
