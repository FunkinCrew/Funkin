package funkin.mobile.util;

#if FLX_POINTER_INPUT
import flixel.FlxG;
#end

/**
 * Utility class for handling swipe gestures in HaxeFlixel and dispatching signals for different swipe directions.
 *
 * Example usage:
 *
 * ```haxe
 * if (SwipeUtil.swipeLeft) trace("Swiped left!");
 *
 * if (SwipeUtil.swipeRight) trace("Swiped right!");
 *
 * if (SwipeUtil.swipeUp) trace("Swiped up!");
 *
 * if (SwipeUtil.swipeDown) trace("Swiped down!");
 *
 * if (SwipeUtil.swipeAny) trace("Swiped in any direction!");
 * ```
 */
class SwipeUtil
{
  /**
   * Indicates if there is a down swipe gesture detected.
   */
  public static var swipeDown(get, never):Bool;

  /**
   * Indicates if there is a left swipe gesture detected.
   */
  public static var swipeLeft(get, never):Bool;

  /**
   * Indicates if there is a right swipe gesture detected.
   */
  public static var swipeRight(get, never):Bool;

  /**
   * Indicates if there is an up swipe gesture detected.
   */
  public static var swipeUp(get, never):Bool;

  /**
   * Indicates if there is any swipe gesture detected.
   */
  public static var swipeAny(get, never):Bool;

  /**
   * Determines if there is a down swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is down, false otherwise.
   */
  @:noCompletion
  static function get_swipeDown():Bool
  {
    #if FLX_POINTER_INPUT
    for (swipe in FlxG.swipes)
    {
      if (swipe.degrees > -135 && swipe.degrees < -45 && swipe.distance > 20) return true;
    }
    #end

    return false;
  }

  /**
   * Determines if there is a left swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is left, false otherwise.
   */
  @:noCompletion
  static function get_swipeLeft():Bool
  {
    #if FLX_POINTER_INPUT
    for (swipe in FlxG.swipes)
    {
      if ((swipe.degrees > 135 || swipe.degrees < -135) && swipe.distance > 20) return true;
    }
    #end

    return false;
  }

  /**
   * Determines if there is a right swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is right, false otherwise.
   */
  @:noCompletion
  static function get_swipeRight():Bool
  {
    #if FLX_POINTER_INPUT
    for (swipe in FlxG.swipes)
    {
      if (swipe.degrees > -45 && swipe.degrees < 45 && swipe.distance > 20) return true;
    }
    #end

    return false;
  }

  /**
   * Determines if there is an up swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is up, false otherwise.
   */
  @:noCompletion
  static function get_swipeUp():Bool
  {
    #if FLX_POINTER_INPUT
    for (swipe in FlxG.swipes)
    {
      if (swipe.degrees > 45 && swipe.degrees < 135 && swipe.distance > 20) return true;
    }
    #end

    return false;
  }

  /**
   * Determines if there is any swipe in the FlxG.swipes array.
   *
   * @return True if any swipe input is detected, false otherwise.
   */
  @:noCompletion
  static function get_swipeAny():Bool
  {
    return swipeDown || swipeLeft || swipeRight || swipeUp;
  }
}
