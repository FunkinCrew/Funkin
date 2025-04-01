package funkin.util;

import flixel.addons.plugin.taskManager.FlxTask;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class FlxTweenUtil
{
  public static function pauseTween(tween:FlxTween):Void
  {
    if (tween != null)
    {
      tween.active = false;
    }
  }

  public static function resumeTween(tween:FlxTween):Void
  {
    if (tween != null)
    {
      tween.active = true;
    }
  }

  public static function pauseTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
  {
    @:privateAccess
    FlxTween.globalManager.forEachTweensOf(Object, FieldPaths, pauseTween);
  }

  public static function resumeTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
  {
    @:privateAccess
    FlxTween.globalManager.forEachTweensOf(Object, FieldPaths, resumeTween);
  }
}
