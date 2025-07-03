package funkin.util;

import flixel.FlxG;
import flixel.FlxObject;
#if FLX_POINTER_INPUT
import flixel.input.FlxSwipe;
#end
import funkin.util.TouchUtil;
import flixel.util.FlxAxes;

/**
 * Utility class for handling swipe gestures in HaxeFlixel and dispatching signals for different swipe directions.
 *
 * Example usage:
 *
 * ```haxe
 * if (SwipeUtil.justSwipedLeft) trace("Swiped left!");
 *
 * if (SwipeUtil.swipeRight) trace("User is swiping/dragging right!");
 *
 * if (SwipeUtil.justFlickedUp) trace("Flicked up!");
 *
 * if (SwipeUtil.flickUp) trace("User has flicked up!");
 *
 * if (SwipeUtil.justSwipedAny) trace("Swiped in any direction!");
 * ```
 */
class SwipeUtil
{
  /**
   * Tracks if an upward swipe has been detected.
   */
  public static var swipeUp(get, never):Bool;

  /**
   * Tracks if a rightward swipe has been detected.
   */
  public static var swipeRight(get, never):Bool;

  /**
   * Tracks if a leftward swipe has been detected.
   */
  public static var swipeLeft(get, never):Bool;

  /**
   * Tracks if a downward swipe has been detected.
   */
  public static var swipeDown(get, never):Bool;

  /**
   * Tracks if any swipe direction is detected (down, left, up, or right).
   */
  public static var swipeAny(get, never):Bool;

  /**
   * Indicates if there is an up swipe gesture detected.
   */
  public static var justSwipedUp(get, never):Bool;

  /**
   * Indicates if there is a right swipe gesture detected.
   */
  public static var justSwipedRight(get, never):Bool;

  /**
   * Indicates if there is a left swipe gesture detected.
   */
  public static var justSwipedLeft(get, never):Bool;

  /**
   * Indicates if there is a down swipe gesture detected.
   */
  public static var justSwipedDown(get, never):Bool;

  /**
   * Indicates if there is any swipe gesture detected.
   */
  public static var justSwipedAny(get, never):Bool;

  /**
   * Checks if an upward flick direction is detected.
   */
  public static var flickUp(get, never):Bool;

  /**
   * Checks if a rightward flick direction is detected.
   */
  public static var flickRight(get, never):Bool;

  /**
   * Checks if a leftward flick direction is detected.
   */
  public static var flickLeft(get, never):Bool;

  /**
   * Checks if a downward flick direction is detected.
   */
  public static var flickDown(get, never):Bool;

  /**
   *  Boolean variable that returns true if any flick direction is detected (down, left, up, or right).
   */
  public static var flickAny(get, never):Bool;

  /**
   * Updates the swipe threshold based on the provided group.
   *
   * @param items The array whose items' positions are used to calculate the swipe threshold.
   * @param axes The axis to calculate the swipe threshold for.
   * @param multiplier Optional value that multiplies the final swipe threshold with it.
   */
  public static function calculateSwipeThreshold(items:Array<Dynamic>, axes:FlxAxes, ?multiplier:Float = 1):Void
  {
    #if FEATURE_TOUCH_CONTROLS
    final itemCount:Int = items.length - 1;

    if (itemCount <= 0)
    {
      FlxG.touches.swipeThreshold.set(100, 100);
      return;
    }

    var totalDistanceX:Float = 0;
    var totalDistanceY:Float = 0;

    for (i in 0...itemCount)
    {
      if (axes.x) totalDistanceX += Math.abs(items[i + 1].x - items[i].x);
      if (axes.y) totalDistanceY += Math.abs(items[i + 1].y - items[i].y);
    }

    totalDistanceX = Math.abs((totalDistanceX / itemCount) * 0.9);
    totalDistanceY = Math.abs((totalDistanceY / itemCount) * 0.9);

    FlxG.touches.swipeThreshold.x = (axes.x) ? totalDistanceX * multiplier : 100;
    FlxG.touches.swipeThreshold.y = (axes.y) ? totalDistanceY * multiplier : 100;
    #end
    return;
  }

  @:noCompletion
  inline static function get_swipeUp():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch?.justMovedUp ?? false;
    #else
    return FlxG.mouse.justMovedUp && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_swipeRight():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch?.justMovedRight ?? false;
    #else
    return FlxG.mouse.justMovedRight && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_swipeLeft():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch?.justMovedLeft ?? false;
    #else
    return FlxG.mouse.justMovedLeft && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_swipeDown():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch?.justMovedDown ?? false;
    #else
    return FlxG.mouse.justMovedDown && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_swipeAny():Bool
    return swipeDown || swipeLeft || swipeRight || swipeUp;

  @:noCompletion
  inline static function get_justSwipedUp():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > 45 && swipe?.degrees < 135 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_justSwipedRight():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > -45 && swipe?.degrees < 45 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_justSwipedLeft():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return ((swipe?.degrees > 135 || swipe?.degrees < -135) && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_justSwipedDown():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > -135 && swipe?.degrees < -45 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_justSwipedAny():Bool
    return justSwipedDown || justSwipedLeft || justSwipedRight || justSwipedUp;

  @:noCompletion
  inline static function get_flickUp():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickUp;
    #else
    return FlxG.mouse.flickManager.flickUp;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_flickRight():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickRight;
    #else
    return FlxG.mouse.flickManager.flickRight;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_flickLeft():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickLeft;
    #else
    return FlxG.mouse.flickManager.flickLeft;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_flickDown():Bool
  {
    #if FEATURE_TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickDown;
    #else
    return FlxG.mouse.flickManager.flickDown;
    #end
    #else
    return false;
    #end
  }

  @:noCompletion
  inline static function get_flickAny():Bool
  {
    return flickUp || flickRight || flickLeft || flickDown;
  }

  /**
   * Calls the destroy function from both the global mouse and the touch manager.
   */
  public static inline function resetSwipeVelocity():Void
  {
    FlxG.mouse.flickManager.destroy();
    FlxG.touches.flickManager.destroy();
  }
}
