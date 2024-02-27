package flixel.tweens.misc;

/**
 * Tweens the background color of a state.
 * Tweens the red, green, blue, and/or alpha values of the color.
 *
 * @see `flixel.tweens.misc.ColorTween` for something that operates on sprites!
 */
class BackgroundColorTween extends FlxTween
{
  public var color(default, null):FlxColor;

  var startColor:FlxColor;
  var endColor:FlxColor;

  /**
   * State object whose color to tween
   */
  public var targetState(default, null):FlxState;

  /**
   * Clean up references
   */
  override public function destroy()
  {
    super.destroy();
    targetState = null;
  }

  /**
   * Tweens the color to a new color and an alpha to a new alpha.
   *
   * @param	duration		  Duration of the tween.
   * @param	fromColor		  Start color.
   * @param	toColor			  End color.
   * @param	targetState		Optional sprite object whose color to tween.
   * @return  The tween for chaining.
   */
  public function tween(duration:Float, fromColor:FlxColor, toColor:FlxColor, ?targetState:FlxSprite):ColorTween
  {
    this.color = startColor = fromColor;
    this.endColor = toColor;
    this.duration = duration;
    this.targetState = targetState;
    this.start();
    return this;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    color = FlxColor.interpolate(startColor, endColor, scale);

    if (targetState != null)
    {
      targetState.bgColor = color;
      // Alpha should apply inherently.
      // targetState.alpha = color.alphaFloat;
    }
  }

  override function isTweenOf(object:Dynamic, ?field:String):Bool
  {
    return targetState == object && (field == null || field == "color");
  }
}
