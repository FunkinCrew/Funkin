package funkin.util;

#if FLX_POINTER_INPUT
import flixel.FlxG;
import flixel.input.FlxSwipe;
#end
import funkin.util.TouchUtil;

// Turning this into a library or something would be nice -Zack
// NOTE DO NOT TOUCH THIS, I have a draft of a rework, and touching this would be a pain in the ass. -Zack

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
   * Detects an upward swipe gesture from the global mouse/touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_swipeUp():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch != null && TouchUtil.touch.justMovedUp;
    #else
    return FlxG.mouse.justMovedUp && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects a rightward swipe gesture from the global mouse/touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_swipeRight():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch != null && TouchUtil.touch.justMovedRight;
    #else
    return FlxG.mouse.justMovedRight && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects a leftward swipe gesture from the global mouse/touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_swipeLeft():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch != null && TouchUtil.touch.justMovedLeft;
    #else
    return FlxG.mouse.justMovedLeft && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects a downward swipe gesture from the global mouse/touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_swipeDown():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return TouchUtil.touch != null && TouchUtil.touch.justMovedDown;
    #else
    return FlxG.mouse.justMovedDown && FlxG.mouse.pressed;
    #end
    #else
    return false;
    #end
  }

  /**
   * Determines if there is any swipe input.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_swipeAny():Bool
    return swipeDown || swipeLeft || swipeRight || swipeUp;

  /**
   * Determines if there is an up swipe in the FlxG.swipes array.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_justSwipedUp():Bool
  {
    #if TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > 45 && swipe?.degrees < 135 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is a left swipe in the FlxG.swipes array.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_justSwipedRight():Bool
  {
    #if TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > -45 && swipe?.degrees < 45 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is a right swipe in the FlxG.swipes array.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_justSwipedLeft():Bool
  {
    #if TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return ((swipe?.degrees > 135 || swipe?.degrees < -135) && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is a down swipe in the FlxG.swipes array.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_justSwipedDown():Bool
  {
    #if TOUCH_CONTROLS
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > -135 && swipe?.degrees < -45 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is any swipe in the FlxG.swipes array.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_justSwipedAny():Bool
    return justSwipedDown || justSwipedLeft || justSwipedRight || justSwipedUp;

  /**
   * Detects an upward flick gesture from the flick manager in either the global mouse or touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_flickUp():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickUp;
    #else
    return FlxG.mouse.flickManager.flickUp;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects a rightward flick gesture from the flick manager in either the global mouse or touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_flickRight():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickRight;
    #else
    return FlxG.mouse.flickManager.flickRight;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects a leftward flick gesture from the flick manager in either the global mouse or touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_flickLeft():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickLeft;
    #else
    return FlxG.mouse.flickManager.flickLeft;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects a downward flick gesture from the flick manager in either the global mouse or touch.
   *
   * @return Bool
   */
  @:noCompletion
  inline static function get_flickDown():Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    return FlxG.touches.flickManager.flickDown;
    #else
    return FlxG.mouse.flickManager.flickDown;
    #end
    #else
    return false;
    #end
  }

  /**
   * Detects if there is any flick input.
   *
   * @return Bool
   */
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
