package funkin.util;

import flixel.tweens.FlxTween;

@:nullSafety
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

  /**
   * Cancels any tweens targeting the sprite's pooled points.
   *
   * @param sprite The sprite that is about to be destroyed.
   */
  @:nullSafety(Off)
  public static function cancelPointTweens(sprite:flixel.FlxSprite):Void
  {
    if (sprite == null) return;

    @:privateAccess
    if (FlxTween.globalManager._tweens.length == 0) return;

    if (sprite.scale != null) FlxTween.cancelTweensOf(sprite.scale);
    if (sprite.offset != null) FlxTween.cancelTweensOf(sprite.offset);
    if (sprite.origin != null) FlxTween.cancelTweensOf(sprite.origin);
    if (sprite.scrollFactor != null) FlxTween.cancelTweensOf(sprite.scrollFactor);
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
