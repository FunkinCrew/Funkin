package funkin.util;

import flixel.math.FlxPoint;

/**
 * Utility functions related to the mouse.
 */
@:nullSafety
class MouseUtil
{
  static var prevTargetPosition:FlxPoint = new FlxPoint();
  static var prevMousePosition:FlxPoint = new FlxPoint();

  /**
   * Used to be for general camera middle click dragging, now generalized for any click and drag type shit!
   * Listen I don't make the rules here
   * @param target what you want to be dragged, defaults to CAMERA SCROLL
   * @param justPressed the "justPressed", should be a button of some sort
   * @param pressed the "pressed", which should be the same button as `justPressed`
   */
  public static function mouseCamDrag(?target:FlxPoint, ?justPressed:Bool, ?pressed:Bool):Void
  {
    target ??= FlxG.camera.scroll;
    justPressed ??= FlxG.mouse.justPressedMiddle;
    pressed ??= FlxG.mouse.pressedMiddle;

    if (justPressed)
    {
      prevTargetPosition.set(target.x, target.y);
      prevMousePosition.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
    }

    if (pressed)
    {
      target.x = prevTargetPosition.x - (FlxG.mouse.viewX - prevMousePosition.x);
      target.y = prevTargetPosition.y - (FlxG.mouse.viewY - prevMousePosition.y);
    }
  }

  static final MOUSE_ZOOM_DEFAULT_INTENSITY:Float = 0.1;

  /**
   * Increment the zoom level of the current camera by the mouse wheel scroll value.
   *
   * @param intensityMult The intensity multiplier, defaults to 0.1
   * @param customWheel If specified, use a custom override value for the scroll wheel.
   **/
  public static function mouseWheelZoom(?intensityMult:Float, customWheel:Float = 0):Void
  {
    FlxG.camera.zoom += mouseWheelZoomData(intensityMult, customWheel);
  }

  /**
   * Get the zoom increment value based on the mouse wheel scroll, with an optional intensity multiplier and custom wheel value.
   * @param intensityMult The intensity multiplier
   * @param customWheel If specified, use a custom override value for the scroll wheel.
   * @return Float The calculated zoom increment value
   **/
  public static function mouseWheelZoomData(?intensityMult:Float, customWheel:Float = 0):Float
  {
    intensityMult ??= MOUSE_ZOOM_DEFAULT_INTENSITY;
    if (customWheel == 0) customWheel = FlxG.mouse.wheel;
    if (customWheel != 0) customWheel *= (intensityMult * FlxG.camera.zoom);
    return customWheel;
  }
}
