// Hey!! Slight note from little me, Zack, I got rid of the for loops because essentially the functions just return the first touch they find back then.
// Now it looks more clean but the descriptions for some variables are inaccurate. Well they were already inaccurate but still.
// - Zack xoxo
//
// Another slight note from little me, it turns out it WAS accurate, my ass during clean up just completely forgot. My fault!! I gotta focus on multi-touch next time.
// Easy to fix but I'll tackle it for later.
// - Zack
package funkin.util;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end
import flixel.input.mouse.FlxMouse;
import flixel.math.FlxPoint;

/**
 * Utility class for handling touch input within the FlxG context.
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
   * Indicates if any touch is released this frame.
   */
  public static var released(get, never):Bool;

  /**
   * Indicates if any touch is moved this frame.
   */
  public static var justMoved(get, never):Bool;

  /**
   * The first touch in the FlxG.touches list.
   */
  #if mobile
  public static var touch(get, never):FlxTouch;
  #else
  public static var touch(get, never):FlxMouse;
  #end

  // static var _touchTween:FlxTween;

  /**
   * Checks if the specified object overlaps with any active touch.
   *
   * @param object The FlxBasic object to check for overlap.
   * @param camera Optional camera for the overlap check. Defaults to the object's camera.
   *
   * @return `true` if there is an overlap with any touch; `false` otherwise.
   */
  public static function overlaps(?object:FlxBasic, ?camera:FlxCamera):Bool
  {
    if (object == null || touch == null) return false;

    return touch.overlaps(object, camera ?? object.camera);

    return false;
  }

  /**
   * Checks if the specified object overlaps with any active touch using precise point checks.
   *
   * @param object The FlxObject to check for overlap.
   * @param camera Optional camera for the overlap check. Defaults to all cameras of the object.
   *
   * @return `true` if there is a precise overlap with any touch; `false` otherwise.
   */
  public static function overlapsComplex(?object:FlxObject, ?camera:FlxCamera):Bool
  {
    if (object == null || touch == null) return false;

    if (camera == null) camera = object.cameras[0];

    @:privateAccess
    return object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera);

    return false;
  }

  /**
   * Checks if the specified object overlaps with a specific point using precise point checks.
   *
   * @param object The FlxObject to check for overlap.
   * @param point The FlxPoint to check against the object.
   * @param inScreenSpace Whether to take scroll factors into account when checking for overlap.
   * @param camera Optional camera for the overlap check. Defaults to all cameras of the object.
   *
   * @return `true` if there is a precise overlap with the specified point; `false` otherwise.
   */
  public static function overlapsComplexPoint(?object:FlxObject, point:FlxPoint, ?inScreenSpace:Bool = false, ?camera:FlxCamera):Bool
  {
    if (object == null || point == null) return false;

    if (camera == null) camera = object.cameras[0];
    @:privateAccess
    if (object.overlapsPoint(point, inScreenSpace, camera))
    {
      point.putWeak();
      return true;
    }

    point.putWeak();

    return false;
  }

  /**
   * A helper function to check if the selection is pressed using touch.
   *
   * @param object The optional FlxBasic to check for overlap.
   * @param camera Optional camera for the overlap check. Defaults to all cameras of the object.
   * @param useOverlapsComplex If true and atleast the object is not null, the function will use complex overlaps method.
   */
  public static function pressAction(?object:FlxBasic, ?camera:FlxCamera, useOverlapsComplex:Bool = true):Bool
  {
    if (TouchUtil.touch == null || (TouchUtil.touch != null && TouchUtil.touch.ticksDeltaSincePress > 200)) return false;

    if (object == null && camera == null)
    {
      return justReleased;
    }
    else if (object != null)
    {
      final overlapsObject:Bool = useOverlapsComplex ? overlapsComplex(cast(object, FlxObject), camera) : overlaps(object, camera);
      return justReleased && overlapsObject;
    }

    return false;
  }

  // weird mix between "looks weird" and "looks neat" but i'll keep it for now -Zack

  @:noCompletion
  inline static function get_justMoved():Bool
    return touch != null && touch.justMoved;

  @:noCompletion
  inline static function get_pressed():Bool
    return touch != null && touch.pressed;

  @:noCompletion
  inline static function get_justPressed():Bool
    return touch != null && touch.justPressed;

  @:noCompletion
  inline static function get_justReleased():Bool
    return touch != null && touch.justReleased;

  @:noCompletion
  static function get_released():Bool
    return touch != null && touch.released;

  #if mobile
  @:noCompletion
  static function get_touch():FlxTouch
  {
    for (touch in FlxG.touches.list)
    {
      if (touch != null) return touch;
    }

    return FlxG.touches.getFirst();
  }
  #else
  @:noCompletion
  static function get_touch():FlxMouse
  {
    FlxG.mouse.visible = true;
    return FlxG.mouse;
  }
  #end
}
