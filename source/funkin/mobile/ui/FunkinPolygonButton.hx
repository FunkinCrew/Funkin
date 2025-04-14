package funkin.mobile.ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.input.touch.FlxTouch;
import openfl.display.Graphics;

/**
 * The `FunkinPolygonButton` class represents a button with a non-standard polygonal hitbox.
 */
@:nullSafety
class FunkinPolygonButton extends FunkinButton
{
  /**
   * The vertices of the polygon defining the button's hitbox.
   * The array should contain points in the format: [x1, y1, x2, y2, ...].
   * If the array is empty, the polygon is ignored, and the default hitbox is used.
   */
  public var polygon:Null<Array<Float>> = null;

  public function overlapsPolygon(point:FlxPoint, inScreenSpace:Bool = false, ?camera:FlxCamera):Bool
  {
    if (polygon == null || polygon.length < 6 || polygon.length % 2 != 0) return false;

    if (!inScreenSpace) return isPointInPolygon(polygon, point, FlxPoint.weak(x, y));

    if (camera == null) camera = FlxG.camera;

    final pos:FlxPoint = FlxPoint.weak(point.x - camera.scroll.x, point.y - camera.scroll.y);

    point.putWeak();

    return isPointInPolygon(polygon, pos, getScreenPosition(_point, camera));
  }

  @:noCompletion
  private static function isPointInPolygon(polygon:Array<Float>, point:FlxPoint, ?offset:FlxPoint):Bool
  {
    if (offset == null) offset = FlxPoint.weak();

    var inside:Bool = false;

    final numsPoints:Int = Math.floor(polygon.length / 2);

    for (i in 0...numsPoints)
    {
      final vertex1:FlxPoint = FlxPoint.weak(polygon[i * 2] + offset.x, polygon[i * 2 + 1] + offset.y);
      final vertex2:FlxPoint = FlxPoint.weak(polygon[(i + 1) % numsPoints * 2] + offset.x, polygon[(i + 1) % numsPoints * 2 + 1] + offset.y);

      if (checkRayIntersection(vertex1, vertex2, point))
      {
        inside = !inside;
      }
    }

    point.putWeak();
    offset.putWeak();

    return inside;
  }

  @:noCompletion
  private static inline function checkRayIntersection(vertex1:FlxPoint, vertex2:FlxPoint, point:FlxPoint):Bool
  {
    final result:Bool = (vertex1.y > point.y) != (vertex2.y > point.y)
      && point.x < (vertex1.x + ((point.y - vertex1.y) / (vertex2.y - vertex1.y)) * (vertex2.x - vertex1.x));

    vertex1.putWeak();
    vertex2.putWeak();

    return result;
  }

  @:noCompletion
  private override function checkTouchOverlap(?touch:FlxTouch):Bool
  {
    if (polygon != null && polygon.length >= 6 && polygon.length % 2 == 0)
    {
      var touches = touch == null ? FlxG.touches.list : [touch];
      for (touch in touches)
      {
        for (camera in cameras)
        {
          final worldPos:FlxPoint = touch.getWorldPosition(camera, _point);

          for (zone in deadZones)
          {
            if (zone != null && zone.overlapsPoint(worldPos, true, camera)) return false;
          }

          if (overlapsPolygon(worldPos, false, camera))
          {
            updateStatus(touch);
            return true;
          }
        }
      }
      return false;
    }

    return super.checkTouchOverlap(touch);
  }

  #if FLX_DEBUG
  public override function drawDebugOnCamera(camera:FlxCamera):Void
  {
    if (polygon != null && polygon.length >= 6 && polygon.length % 2 == 0)
    {
      if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

      getScreenPosition(_point, camera);

      final gfx:Graphics = beginDrawDebug(camera);

      drawDebugPolygonColor(gfx, polygon, getDebugBoundingBoxColor(allowCollisions));

      endDrawDebug(camera);
    }
    else
      super.drawDebugOnCamera(camera);
  }

  @:noCompletion
  private function drawDebugPolygonColor(gfx:Graphics, polygon:Array<Float>, color:FlxColor):Void
  {
    gfx.lineStyle(2, color, 0.75);

    for (i in 0...Math.floor(polygon.length / 2))
    {
      if (i == 0) gfx.moveTo(polygon[i * 2] + _point.x, polygon[i * 2 + 1] + _point.y);
      else
        gfx.lineTo(polygon[i * 2] + _point.x, polygon[i * 2 + 1] + _point.y);
    }
  }
  #end
}
