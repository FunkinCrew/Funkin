package funkin.util.tools;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenManager;

class FlxTweenTools
{
  /**
   * Tween the background color of a FlxState.
   * @param globalManager `flixel.tweens.FlxTween.globalManager`
   * @param targetState The FlxState to tween the background color of.
   * @param duration The duration of the tween.
   * @param fromColor The starting color.
   * @param toColor The ending color.
   * @param options The options for the tween.
   * @return The tween.
   */
  public static function bgColor(globalManager:FlxTweenManager, targetState:FlxState, duration:Float = 1.0, fromColor:FlxColor, toColor:FlxColor,
      ?options:TweenOptions):BackgroundColorTween
  {
    var tween = new BackgroundColorTween(options, this);
    tween.tween(duration, fromColor, toColor, targetState);
    globalManager.add(tween);
  }
}
