package funkin.play.components;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.graphics.FunkinSprite;

class ScrollSpeedChanger extends FlxSpriteGroup
{
  var bg:FunkinSprite;
  var scrollSpeedLabel:FlxText;
  public var scrollSpeedValue:FlxText;

  var hideTimer:FlxTimer;
  var hideTween:FlxTween;
  static inline var hideDelay:Float = 2.0;

  public function new(x:Float, y:Float, ?initialSpeed:Float)
  {
    super(x, y);

    initialSpeed = initialSpeed ?? Constants.DEFAULT_SCROLLSPEED;

    bg = new FunkinSprite(0, 0);
    bg.makeGraphic(200, 65, 0x99000000);
    add(bg);

    scrollSpeedLabel = new FlxText(0, 10, bg.width, "Scroll Speed");
    scrollSpeedLabel.setFormat('VCR OSD Mono', 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(scrollSpeedLabel);

    scrollSpeedValue = new FlxText(0, scrollSpeedLabel.height + 10, bg.width, Std.string(FlxMath.roundDecimal(initialSpeed, 2)) + "x");
    scrollSpeedValue.setFormat('VCR OSD Mono', 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(scrollSpeedValue);

    scrollFactor.set();

    alpha = 0;
  }

  /**
   * Update the scroll speed value text.
   *
   * @param speed The current scroll speed value to display.
   */
  public function updateSpeed(speed:Float):Void
  {
    scrollSpeedValue.text = Std.string(FlxMath.roundDecimal(speed, 2)) + "x";

    show();

    if (hideTimer != null) hideTimer.cancel();
    hideTimer = new FlxTimer().start(hideDelay, (tmr:FlxTimer) -> hide());
  }

  function show():Void {
    if (hideTween != null) hideTween.cancel();
    hideTween = FlxTween.tween(this, {alpha: 1}, 0.2, {ease: FlxEase.quartOut});
  }

  function hide():Void {
    if (hideTween != null) hideTween.cancel();
    hideTween = FlxTween.tween(this, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
  }

  override public function destroy():Void
  {
    if (hideTimer != null) hideTimer.cancel();
    if (hideTween != null) hideTween.cancel();
    super.destroy();
  }
}

/**
 * An abstract enum for scroll speed modes.
 */
enum abstract ScrollSpeedMode(Int) from Int to Int
{
  /**
   * Scroll speed adapts dynamically during the song (e.g. responds to song events)
   */
  var OFF:Int = 0;

  /**
   * Scroll speed is fixed to the player's set value (cannot be changed unless modified by mods)
   */
  var STATIC:Int = 1;

  /**
   * Scroll speed adapts dynamically during the song (e.g. responds to song events)
   */
  var ADAPTIVE:Int = 2;
}
