package funkin.mobile.util;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

/**
 * Utility class for handling touch input in a FlxG context.
 */
class TouchUtil
{
  /**
   * Indicates if any touch is currently pressed.
   */
  public static var pressed(get, never):Bool;

  /**
   * Indicates if any touch was just pressed this frame.
   */
  public static var justPressed(get, never):Bool;

  /**
   * Indicates if any touch was just released this frame.
   */
  public static var justReleased(get, never):Bool;

  /**
   * The first touch in the FlxG.touches list.
   */
  public static var touch(get, never):FlxTouch;

  /**
   * Checks if the specified object overlaps with any touch.
   *
   * @param object The FlxBasic object to check against touches.
   * @param camera Optional camera to use for overlap check. If null, object's camera is used.
   *
   * @return `true` if there is an overlap with any touch; `false` otherwise.
   */
  public static function overlaps(object:FlxBasic, ?camera:FlxCamera):Bool
  {
    if (object == null) return false;

    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.overlaps(object, camera ?? object.camera)) return true;
    }
    #end

    return false;
  }

  /**
   * Checks if the specified object overlaps with any touch using precise point checks.
   *
   * @param object The FlxObject to check against touches.
   *
   * @return `true` if there is a precise overlap with any touch; `false` otherwise.
   */
  public static function overlapsComplex(object:FlxObject):Bool
  {
    if (object == null) return false;

    #if FLX_TOUCH
    for (camera in object.cameras)
    {
      for (touch in FlxG.touches.list)
      {
        @:privateAccess
        if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera)) return true;
      }
    }
    #end

    return false;
  }

  @:noCompletion
  private static function get_pressed():Bool
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.pressed) return true;
    }
    #end

    return false;
  }

  @:noCompletion
  private static function get_justPressed():Bool
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.justPressed) return true;
    }
    #end

    return false;
  }

  @:noCompletion
  private static function get_justReleased():Bool
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.justReleased) return true;
    }
    #end

    return false;
  }

  @:noCompletion
  private static function get_touch():FlxTouch
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch != null) return touch;
    }

    return FlxG.touches.getFirst();
    #else
    return null;
    #end
  }
}
