package funkin.util;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.input.touch.FlxTouch;

class TouchUtil
{
  public static var pressed(get, never):Bool;
  public static var justPressed(get, never):Bool;
  public static var justReleased(get, never):Bool;
  public static var touch(get, never):FlxTouch;

  public static function overlaps(object:FlxBasic, ?camera:FlxCamera):Bool
  {
    if (object == null) return false;
    for (touch in FlxG.touches.list)
      if (touch.overlaps(object, camera ?? object.camera)) return true;
    return false;
  }

  public static function overlapsComplex(object:FlxObject):Bool
  {
    if (object == null) return false;
    var overlap = false;
    for (camera in object.cameras)
    {
      for (touch in FlxG.touches.list)
      {
        @:privateAccess
        if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera)) overlap = true;
      }
    }
    return overlap;
  }

  @:noCompletion
  private static function get_pressed():Bool
  {
    for (touch in FlxG.touches.list)
      if (touch.pressed) return true;
    return false;
  }

  @:noCompletion
  private static function get_justPressed():Bool
  {
    for (touch in FlxG.touches.list)
      if (touch.justPressed) return true;
    return false;
  }

  @:noCompletion
  private static function get_justReleased():Bool
  {
    for (touch in FlxG.touches.list)
      if (touch.justReleased) return true;
    return false;
  }

  @:noCompletion
  private static function get_touch():FlxTouch
  {
    for (touch in FlxG.touches.list)
    {
      if (touch == null) continue;
      return touch;
    }
    return FlxG.touches.getFirst();
  }
}
