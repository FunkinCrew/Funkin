package funkin.mobile.util;

#if FLX_POINTER_INPUT
import flixel.FlxG;
import flixel.input.FlxSwipe;
#end
import funkin.mobile.util.TouchUtil;
import flixel.util.FlxTimer;

// Turning this into a library or something would be nice -Zack

/**
 * Utility class for handling swipe gestures in HaxeFlixel and dispatching signals for different swipe directions.
 *
 * Example usage:
 *
 * ```haxe
 * if (SwipeUtil.justSwipedLeft) trace("Swiped left!");
 *
 * if (SwipeUtil.justSwipedRight) trace("Swiped right!");
 *
 * if (SwipeUtil.justSwipedUp) trace("Swiped up!");
 *
 * if (SwipeUtil.justSwipedDown) trace("Swiped down!");
 *
 * if (SwipeUtil.justSwipedAny) trace("Swiped in any direction!");
 * ```
 */
class SwipeUtil
{
  /**
   * Boolean variable that tracks if a downward swipe has been detected.
   */
  public static var swipeDown(get, never):Bool;

  /**
   * Boolean variable that tracks if a leftward swipe has been detected.
   */
  public static var swipeLeft(get, never):Bool;

  /**
   * Boolean variable that tracks if an upward swipe has been detected.
   */
  public static var swipeUp(get, never):Bool;

  /**
   * Boolean variable that tracks if a rightward swipe has been detected.
   */
  public static var swipeRight(get, never):Bool;

  /**
   * Boolean variable that returns true if any swipe direction is detected (down, left, up, or right).
   */
  public static var swipeAny(get, never):Bool;

  /**
   * Indicates if there is a down swipe gesture detected.
   */
  public static var justSwipedDown(get, never):Bool;

  /**
   * Indicates if there is a left swipe gesture detected.
   */
  public static var justSwipedLeft(get, never):Bool;

  /**
   * Indicates if there is a right swipe gesture detected.
   */
  public static var justSwipedRight(get, never):Bool;

  /**
   * Indicates if there is an up swipe gesture detected.
   */
  public static var justSwipedUp(get, never):Bool;

  /**
   * Indicates if there is any swipe gesture detected.
   */
  public static var justSwipedAny(get, never):Bool;

  /**
   * Swipe sensitivity. Increase it for less sensitivity, decrease it for more.
   */
  public static var swipeThreshold:Float = 100;

  // Helper variables for handleSwipe()
  static var _startX:Float = 0;
  static var _startY:Float = 0;
  static var _isSwiping:Bool = false;

  /**
   * Detects a downward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if a downward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeDown():Bool
    return handleSwipe(Down);

  /**
   * Detects a leftward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if a leftward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeLeft():Bool
    return handleSwipe(Left);

  /**
   * Detects a rightward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if a rightward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeRight():Bool
    return handleSwipe(Right);

  /**
   * Detects an upward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if an upward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeUp():Bool
    return handleSwipe(Up);

  /**
   * Determines if there is any swipe input.
   *
   * @return True if any swipe input is detected, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeAny():Bool
    return swipeDown || swipeLeft || swipeRight || swipeUp;

  /**
   * Determines if there is a down swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is down, false otherwise.
   */
  @:noCompletion
  inline static function get_justSwipedDown():Bool
  {
    #if FLX_POINTER_INPUT
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > -135 && swipe?.degrees < -45 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is a right swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is right, false otherwise.
   */
  @:noCompletion
  inline static function get_justSwipedLeft():Bool
  {
    #if FLX_POINTER_INPUT
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return ((swipe?.degrees > 135 || swipe?.degrees < -135) && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is a left swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is left, false otherwise.
   */
  @:noCompletion
  inline static function get_justSwipedRight():Bool
  {
    #if FLX_POINTER_INPUT
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > -45 && swipe?.degrees < 45 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is an up swipe in the FlxG.swipes array.
   *
   * @return True if any swipe direction is up, false otherwise.
   */
  @:noCompletion
  inline static function get_justSwipedUp():Bool
  {
    #if FLX_POINTER_INPUT
    final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
    return (swipe?.degrees > 45 && swipe?.degrees < 135 && swipe?.distance > 20);
    #else
    return false;
    #end
  }

  /**
   * Determines if there is any swipe in the FlxG.swipes array.
   *
   * @return True if any swipe input is detected, false otherwise.
   */
  @:noCompletion
  inline static function get_justSwipedAny():Bool
    return justSwipedDown || justSwipedLeft || justSwipedRight || justSwipedUp;

  // Calling a function for each check might be eh, but I think its clean enough.

  /**
   * Handles swipe gestures and detects the direction of the swipe based on the input.
   * The function starts tracking the swipe when a touch is pressed and compares the
   * movement against a threshold to determine if the swipe is valid in the specified
   * direction (horizontal or vertical).
   *
   * @param direction The expected swipe direction, which can be one of the values from the SwipingDirection enum.
   * @return Bool True if the swipe in the given direction passes the threshold; false otherwise.
   */
  @:noCompletion
  static function handleSwipe(direction:SwipingDirection):Bool
  {
    #if FLX_POINTER_INPUT
    final touch = TouchUtil.touch;

    #if !mobile
    return false;
    #end

    if (touch == null) return false;

    // When touch is pressed, start tracking
    if (TouchUtil.pressed && !_isSwiping)
    {
      _startX = touch.viewX;
      _startY = touch.viewY;
      _isSwiping = true;
    }

    // Reset swipe state when touch is released
    if (!TouchUtil.pressed) _isSwiping = false;

    // If it's dragging
    if (_isSwiping)
    {
      final deltaX:Float = touch.viewX - _startX;
      final deltaY:Float = touch.viewY - _startY;

      // Handle swipe input
      final swiped:Bool = switch (direction)
      {
        case Right: deltaX > swipeThreshold;
        case Down: deltaY < -swipeThreshold;
        case Left: deltaX < -swipeThreshold;
        case Up: deltaY > swipeThreshold;
        case None: false;
      };

      // oldDirection = direction

      if (swiped)
      {
        _isSwiping = false;
        _startX = _startY = 0;
      }

      return swiped;
    }
    #end

    return false;
  }
}

enum SwipingDirection
{
  Right;
  Left;
  Down;
  Up;
  None;
}
