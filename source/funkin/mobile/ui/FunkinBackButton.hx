package funkin.mobile.ui;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import funkin.audio.FunkinSound;
import funkin.util.HapticUtil;

class FunkinBackButton extends FunkinButton
{
  public var onConfirmStart(default, null):FlxSignal = new FlxSignal();
  public var onConfirmEnd(default, null):FlxSignal = new FlxSignal();

  public var enabled:Bool = true;

  var confirming:Bool = false;

  public var restingOpacity:Float;

  var instant:Bool = false;
  var held:Bool = false;

  /**
   * Creates a new FunkinBackButton instance.
   *
   * @param x The x position of the object.
   * @param y The y position of the object.
   * @param color Button's optional color.
   * @param confirmCallback An optional callback function that will be triggered when the object is clicked.
   * @param restingOpacity An optional float that is the alpha the button will be when not selected/hovered over.
   * @param instant An optional flag that makes the button not play the full animation before calling the callback.
   */
  public function new(?x:Float = 0, ?y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3,
      instant:Bool = false):Void
  {
    super(x, y);

    frames = Paths.getSparrowAtlas("backButton");
    animation.addByIndices('idle', 'back', [0], "", 24, false);
    animation.addByIndices('hold', 'back', [5], "", 24, false);
    animation.addByIndices('confirm', 'back', [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22], "", 24, false);
    animation.play("idle");

    scale.set(0.7, 0.7);
    updateHitbox();

    this.color = color;
    this.restingOpacity = restingOpacity;
    this.instant = instant;
    this.alpha = restingOpacity;
    this.ignoreDownHandler = true;

    onUp.add(playConfirmAnim);
    onDown.add(playHoldAnim);
    onOut.add(playOutAnim);

    onConfirmEnd.add(confirmCallback);
  }

  function playHoldAnim():Void
  {
    if (confirming || held || !enabled) return;

    held = true;

    FlxTween.cancelTweensOf(this);
    HapticUtil.vibrate(0, 0.01, 0.5);
    animation.play('hold');

    alpha = 1;
  }

  function playConfirmAnim():Void
  {
    if (!enabled) return;

    if (instant)
    {
      onConfirmEnd.dispatch();
      return;
    }
    else if (confirming)
    {
      return;
    }

    confirming = true;

    FlxTween.cancelTweensOf(this);
    HapticUtil.vibrate(0, 0.05, 0.5);
    animation.play('confirm');

    FunkinSound.playOnce(Paths.sound('cancelMenu'));

    onConfirmStart.dispatch();

    animation.onFinish.addOnce(function(name:String) {
      if (name != 'confirm') return;
      confirming = false;
      held = false;
      onConfirmEnd.dispatch();
    });
  }

  function playOutAnim():Void
  {
    if (confirming || !enabled) return;

    FlxTween.cancelTweensOf(this);
    HapticUtil.vibrate(0, 0.01, 0.2);
    animation.play('idle');

    FlxTween.tween(this, {alpha: restingOpacity}, 0.5,
      {
        ease: FlxEase.expoOut,
        onComplete: function(tween:FlxTween):Void {
          held = false;
        }
      });
  }

  public function resetCallbacks():Void
  {
    onUp.removeAll();
    onDown.removeAll();
    onOut.removeAll();

    confirming = false;
    held = false;

    onUp.add(playConfirmAnim);
    onDown.add(playHoldAnim);
    onOut.add(playOutAnim);
  }

  override public function update(elapsed:Float):Void
  {
    #if android
    if (FlxG.android.justReleased.BACK) onConfirmEnd.dispatch();
    #end

    super.update(elapsed);
  }

  override function destroy():Void
  {
    super.destroy();

    onConfirmStart.removeAll();
    onConfirmEnd.removeAll();

    if (animation != null && animation.onFinish != null) animation.onFinish.removeAll();
  }
}
