package funkin.mobile.util;

#if FLX_POINTER_INPUT
import flixel.FlxG;
import flixel.input.FlxSwipe;
#end
import funkin.mobile.util.TouchUtil;

// Turning this into a library or something would be nice -Zack

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
   * Boolean variable that tracks if an upward swipe has been detected.
   */
  public static var swipeUp(get, never):Bool;

  /**
   * Boolean variable that tracks if a rightward swipe has been detected.
   */
  public static var swipeRight(get, never):Bool;

  /**
   * Boolean variable that tracks if a leftward swipe has been detected.
   */
  public static var swipeLeft(get, never):Bool;

  /**
   * Boolean variable that tracks if a downward swipe has been detected.
   */
  public static var swipeDown(get, never):Bool;

  /**
   * Boolean variable that returns true if any swipe direction is detected (down, left, up, or right).
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
   * Indicates if there is an up flick gesture detected.
   */
  public static var justFlickedUp(get, never):Bool;

  /**
   * Indicates if there is a right flick gesture detected.
   */
  public static var justFlickedRight(get, never):Bool;

  /**
   * Indicates if there is a left flick gesture detected.
   */
  public static var justFlickedLeft(get, never):Bool;

  /**
   * Indicates if there is a down flick gesture detected.
   */
  public static var justFlickedDown(get, never):Bool;

  /**
   * Indicates if there is any flick gesture detected.
   */
  public static var justFlickedAny(get, never):Bool;

  /**
   * Boolean variable that returns true if an upward flick direction is detected.
   */
  public static var flickUp(get, never):Bool;

  /**
   * Boolean variable that returns true if a rightward flick direction is detected.
   */
  public static var flickRight(get, never):Bool;

  /**
   *  Boolean variable that returns true if a leftward flick direction is detected.
   */
  public static var flickLeft(get, never):Bool;

  /**
   * Boolean variable that returns true if a downward flick direction is detected.
   */
  public static var flickDown(get, never):Bool;

  /**
   *  Boolean variable that returns true if any flick direction is detected (down, left, up, or right).
   */
  public static var flickAny(get, never):Bool;

  /**
   * The velocity threshold to cross for a flick to count.
   */
  public static var velocityThreshold:Float = 1000;

  /**
   * Swipe sensitivity. Increase it for less sensitivity, decrease it for more.
   */
  public static var swipeThreshold:Float = 70;

  // Helper variables for handleSwipe()
  static var _startX:Float = 0;
  static var _startY:Float = 0;
  static var _isSwiping:Bool = false;

  // Helper variables for handleFlick()
  static var _velocityY:Float = 0;
  static var _velocityX:Float = 0;

  /**
   * Detects an upward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if an upward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeUp():Bool
    return handleSwipe(Up);

  /**
   * Detects a rightward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if a rightward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeRight():Bool
    return handleSwipe(Right);

  /**
   * Detects a leftward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if a leftward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeLeft():Bool
    return handleSwipe(Left);

  /**
   * Detects a downward swipe gesture. If detected, it resets swipe state variables.
   *
   * @return Bool True if a downward swipe passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeDown():Bool
    return handleSwipe(Down);

  /**
   * Determines if there is any swipe input.
   *
   * @return Bool True if any swipe input is detected, false otherwise.
   */
  @:noCompletion
  inline static function get_swipeAny():Bool
    return swipeDown || swipeLeft || swipeRight || swipeUp;

  /**
   * Determines if there is an up swipe in the FlxG.swipes array.
   *
   * @return Bool True if any swipe direction is up, false otherwise.
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
   * @return Bool True if any swipe direction is left, false otherwise.
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
   * @return Bool True if any swipe direction is right, false otherwise.
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
   * @return Bool True if any swipe direction is down, false otherwise.
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
   * @return Bool True if any swipe input is detected, false otherwise.
   */
  @:noCompletion
  inline static function get_justSwipedAny():Bool
    return justSwipedDown || justSwipedLeft || justSwipedRight || justSwipedUp;

  /**
   * Detects an upward flick gesture. If detected, it resets the velocityY variables.
   *
   * @return Bool True if an upward flick gesture passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_flickUp():Bool
    return handleFlick(Up);

  /**
   * Detects a rightward flick gesture. If detected, it resets the velocityX variables.
   *
   * @return Bool True if a rightward flick gesture passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_flickRight():Bool
    return handleFlick(Right);

  /**
   * Detects a leftward flick gesture. If detected, it resets the velocityX variables.
   *
   * @return Bool True if a leftward flick gesture passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_flickLeft():Bool
    return handleFlick(Left);

  /**
   * Detects a downward flick gesture. If detected, it resets the velocityY variables.
   *
   * @return Bool True if a downward flick gesture passes the threshold, false otherwise.
   */
  @:noCompletion
  inline static function get_flickDown():Bool
    return handleFlick(Down);

  /**
   * Detects if there is any flick input.
   *
   * @return Bool True if any flick check is true, false otherwise.
   */
  @:noCompletion
  inline static function get_flickAny():Bool
    return flickUp || flickRight || flickLeft || flickDown;

  /**
   * Detects if the user has given an upward swipe input and has a velocity on the Y axis greater than 1.
   *
   * @return Bool True if both conditions are met, false otherwise.
   */
  @:noCompletion
  inline static function get_justFlickedUp():Bool
  {
    #if mobile
    return justSwipedUp && FlxG.touches.velocityY > 1;
    #else
    return false;
    #end
  }

  /**
   * Detects if the user has given a rightward swipe input and has a velocity on the X axis greater than 1.
   *
   * @return Bool True if both conditions are met, false otherwise.
   */
  @:noCompletion
  inline static function get_justFlickedRight():Bool
  {
    #if mobile
    return justSwipedUp && FlxG.touches.velocityX > 1;
    #else
    return false;
    #end
  }

  /**
   * Detects if the user has given a leftward swipe input and has a velocity on the X axis lesser than -1.
   *
   * @return Bool True if both conditions are met, false otherwise.
   */
  @:noCompletion
  inline static function get_justFlickedLeft():Bool
  {
    #if mobile
    return justSwipedUp && FlxG.touches.velocityX < -1;
    #else
    return false;
    #end
  }

  /**
   * Detects if the user has given a downward swipe input and has a velocity on the Y axis lesser than -1.
   *
   * @return Bool True if both conditions are met, false otherwise.
   */
  @:noCompletion
  inline static function get_justFlickedDown():Bool
  {
    #if mobile
    return justSwipedUp && FlxG.touches.velocityY < -1;
    #else
    return false;
    #end
  }

  /**
   * Detects if the user has given any flick inputs just now.
   *
   * @return Bool True if any flick inputs were detected, false otherwise.
   */
  @:noCompletion
  inline static function get_justFlickedAny():Bool
    return justFlickedUp || justFlickedRight || justFlickedLeft || justFlickedDown;

  // Calling a function for each check might be eh, but I think its clean enough.
  // TODO: Add mouse support to this somehow? for now just keep it.
  // TODO: Rework handleFlick.

  /**
   * Handles flick checks depending on the direction given.
   * First checks if the given velocity X/Y (depending whether it be vertical or horizontal),
   * has a value beyond 0, then adds it to our helper variables (_velocityX/Y).
   * If _velocityX/Y surpasses the velocityThreshold it return true, otherwise false.
   * @param direction The expected swipe direction, which can be one of the values from the SwipingDirection enum.
   * @return Bool True if the swipe in the given direction passes the threshold; false otherwise.
   */
  @:noCompletion
  static function handleFlick(direction:SwipingDirection):Bool
  {
    #if TOUCH_CONTROLS
    #if mobile
    var touches = FlxG.touches;
    #else
    var touches = FlxG.mouse;
    #end
    if (TouchUtil.pressed)
    {
      _velocityX = 0;
      _velocityY = 0;
      return false;
    }

    // Update velocities based on touch input if no touch is pressed
    final vertical:Bool = direction == Up || direction == Down;
    final horizontal:Bool = direction == Left || direction == Right;

    if (vertical && touches.velocityY == 0)
    {
      _velocityY = 0;
      return false;
    }

    if (horizontal && touches.velocityX == 0)
    {
      _velocityX = 0;
      return false;
    }

    final framerateRatio:Float = (1 / FlxG.elapsed) / FlxG.updateFramerate;

    // Apply frame-rate scaling using the ratio
    if (vertical) _velocityY += touches.velocityY / framerateRatio;
    if (horizontal) _velocityX += touches.velocityX / framerateRatio;

    // Check if a swipe matches the specified direction
    final swiped:Bool = switch (direction)
    {
      case Up: _velocityY > velocityThreshold;
      case Right: _velocityX > velocityThreshold;
      case Left: _velocityX < -velocityThreshold;
      case Down: _velocityY < -velocityThreshold;
      case None: false;
    };

    // Reset velocities based on swipe direction
    if (swiped)
    {
      if (vertical) _velocityY = 0;
      if (horizontal) _velocityX = 0;
    }

    return swiped;
    #else
    return false;
    #end
  }

  public static inline function resetSwipeVelocity():Void
  {
    #if mobile
    var touches = FlxG.touches;
    #else
    var touches = FlxG.mouse;
    #end

    @:privateAccess
    touches.velocityY = 0;
    @:privateAccess
    touches.velocityX = 0;
    _velocityY = 0;
    _velocityX = 0;
  }

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
    #if TOUCH_CONTROLS
    final touch = TouchUtil.touch;

    // Reset swipe state when touch is released/null and returns false.
    if (touch == null || !TouchUtil.pressed)
    {
      _isSwiping = false;
      return false;
    }
    // Goes on if touch isn't null/pressed.

    // When touch is pressed, start tracking.
    if (!_isSwiping)
    {
      _startX = touch.viewX;
      _startY = touch.viewY;
      _isSwiping = true; // true until touch is released/null.
    }

    // If it's dragging
    if (_isSwiping)
    {
      final deltaX:Float = touch.viewX - _startX;
      final deltaY:Float = touch.viewY - _startY;

      // Handle swipe input
      final swiped:Bool = switch (direction)
      {
        case Up: deltaY > swipeThreshold;
        case Right: deltaX > swipeThreshold;
        case Left: deltaX < -swipeThreshold;
        case Down: deltaY < -swipeThreshold;
        case None: false;
      };

      // Reset values if true.
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
  Up;
  Right;
  Left;
  Down;
  None;
}
