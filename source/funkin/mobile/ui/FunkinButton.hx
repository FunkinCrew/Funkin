package funkin.mobile.ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import flixel.input.FlxInput;
import flixel.input.IFlxInput;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import openfl.display.Graphics;
import haxe.ds.Map;

/**
 * Enum representing the status of the button.
 */
enum abstract FunkinButtonStatus(Int) from Int to Int
{
  var NORMAL = 0;
  var PRESSED = 1;
}

/**
 * A simple button class that calls a function when touched.
 */
#if !display
@:generic
#end
@:allow(funkin.mobile.ui.FunkinHitbox)
@:allow(funkin.mobile.ui.FunkinButton)
class FunkinButton extends FunkinSprite implements IFlxInput
{
  /**
   * A map that's storing every active touch's ID that's pressing a button.
   */
  public static var buttonsTouchID:Map<Int, FunkinButton> = new Map();

  /**
   * The current state of the button, either `FunkinButtonStatus.NORMAL` or `FunkinButtonStatus.PRESSED`.
   */
  public var status:FunkinButtonStatus;

  /**
   * The callback function to call when the button is released.
   */
  public var onUp(default, null):FlxSignal = new FlxSignal();

  /**
   * The callback function to call when the button is pressed down.
   */
  public var onDown(default, null):FlxSignal = new FlxSignal();

  /**
   * The callback function to call when the button is no longer hovered over.
   */
  public var onOut(default, null):FlxSignal = new FlxSignal();

  /**
   * Whether the button was just released.
   */
  public var justReleased(get, never):Bool;

  /**
   * Whether the button is currently released.
   */
  public var released(get, never):Bool;

  /**
   * Whether the button is currently pressed.
   */
  public var pressed(get, never):Bool;

  /**
   * Whether the button was just pressed.
   */
  public var justPressed(get, never):Bool;

  /**
   * The touch instance that pressed this button.
   */
  public var currentTouch(get, never):Null<FlxTouch>;

  /**
   * An array of objects that blocks your input.
   */
  public var deadZones:Array<FunkinSprite> = [];

  /**
   * Whether the button should be released if you swiped over somwhere else.
   */
  public var limitToBounds:Bool = true;

  /**
   * A radius for circular buttons.
   * If this radius is larger than 0 then the overlap check will look if the touch point is inside this raius.
   */
  public var radius:Float = 0;

  /**
   * The vertices of the polygon defining the button's hitbox.
   * The array should contain points in the format: [x1, y1, x2, y2, ...].
   * If the array is empty, the polygon is ignored, and the default hitbox is used.
   */
  public var polygon:Null<Array<Float>> = null;

  /**
   * The input associated with the button, using `Int` as the type.
   */
  var input:FlxInput<Int>;

  /**
   * The input currently pressing this button, if none, it's `null`.
   * Needed to check for its release.
   */
  var currentInput:IFlxInput;

  /**
   * The ID of the touch object that pressed this button.
   */
  var touchID:Int = -1;

  /**
   * Whether the button should skip calling onDownHandler() on touch.pressed.
   */
  public var ignoreDownHandler:Bool = false;

  /**
   * Creates a new `FunkinButton` object.
   *
   * @param x The x position of the button.
   * @param y The y position of the button.
   */
  public function new(x:Float = 0, y:Float = 0):Void
  {
    super(x, y);

    status = FunkinButtonStatus.NORMAL;
    solid = false;
    immovable = true;
    #if FLX_DEBUG
    ignoreDrawDebug = true;
    #end
    scrollFactor.set();
    input = new FlxInput(0);
  }

  /**
   * Called by the game state when the state is changed (if this object belongs to the state).
   */
  public override function destroy():Void
  {
    deadZones = FlxDestroyUtil.destroyArray(deadZones);
    currentInput = null;
    input = null;

    buttonsTouchID.remove(touchID);

    touchID = -1;

    super.destroy();
  }

  /**
   * Called by the game loop automatically, handles touch over and click detection.
   */
  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if FLX_POINTER_INPUT
    // Update the button, but only if touches are enabled
    if (visible)
    {
      final overlapFound:Bool = checkTouchOverlap();
      final touchReleased:Bool = (currentTouch != null && currentTouch.justReleased);

      if ((currentInput != null && currentInput.justReleased || (!limitToBounds && touchReleased)) && overlapFound)
      {
        onUpHandler();
      }

      if (status != FunkinButtonStatus.NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased)))
      {
        if (limitToBounds || (!limitToBounds && touchReleased)) onOutHandler();
      }
    }
    #end

    input.update();
  }

  function checkTouchOverlap(?touch:FlxTouch):Bool
  {
    final touches:Array<FlxTouch> = touch == null ? FlxG.touches.list : [touch];

    for (camera in cameras)
    {
      for (touch in touches)
      {
        final worldPos:FlxPoint = touch.getWorldPosition(camera, _point);

        for (zone in deadZones)
        {
          if (zone != null && zone.overlapsPoint(worldPos, true, camera)) return false;
        }

        function updateTouchID():Void
        {
          touchID = touch.touchPointID;
          if (buttonsTouchID.exists(touchID) && buttonsTouchID.get(touchID) != this)
          {
            final prevButton:Null<FunkinButton> = buttonsTouchID.get(touchID);

            if (input != null && prevButton != null && prevButton.input != null && !prevButton.limitToBounds) prevButton.onOutHandler();
          }
          buttonsTouchID.set(touchID, this);

          updateStatus(touch);
        }

        if (polygon != null && polygon.length >= 6 && polygon.length % 2 == 0)
        {
          if (polygonOverlapsPoint(worldPos, false, camera))
          {
            updateTouchID();
            return true;
          }
        }
        else if (radius > 0)
        {
          if (circleOverlapsPoint(worldPos, camera))
          {
            updateTouchID();
            return true;
          }
        }
        else
        {
          if (overlapsPoint(worldPos, true, camera))
          {
            updateTouchID();
            return true;
          }
        }
      }
    }

    return false;
  }

  function circleOverlapsPoint(point:FlxPoint, ?camera:FlxCamera):Bool
  {
    if (camera == null) camera = FlxG.camera;

    final xPos = point.x - camera.scroll.x;
    final yPos = point.y - camera.scroll.y;
    getScreenPosition(_point, camera);
    point.putWeak();

    final distanceX = xPos - (_point.x + (width / 2));
    final distanceY = yPos - (_point.y + (height / 2));
    final distance = Math.sqrt((distanceX * distanceX) + (distanceY * distanceY));

    return distance <= radius;
  }

  function polygonOverlapsPoint(point:FlxPoint, inScreenSpace:Bool = false, ?camera:FlxCamera):Bool
  {
    if (polygon == null || polygon.length < 6 || polygon.length % 2 != 0) return false;

    if (!inScreenSpace) return isPointInPolygon(polygon, point, FlxPoint.weak(x, y));

    if (camera == null) camera = FlxG.camera;

    final pos:FlxPoint = FlxPoint.weak(point.x - camera.scroll.x, point.y - camera.scroll.y);

    point.putWeak();

    return isPointInPolygon(polygon, pos, getScreenPosition(_point, camera));
  }

  static function isPointInPolygon(vertices:Array<Float>, point:FlxPoint, ?offset:FlxPoint):Bool
  {
    if (offset == null) offset = FlxPoint.weak();

    var inside:Bool = false;

    final numsPoints:Int = Math.floor(vertices.length / 2);

    for (i in 0...numsPoints)
    {
      final vertex1:FlxPoint = FlxPoint.weak(vertices[i * 2] + offset.x, vertices[i * 2 + 1] + offset.y);
      final vertex2:FlxPoint = FlxPoint.weak(vertices[(i + 1) % numsPoints * 2] + offset.x, vertices[(i + 1) % numsPoints * 2 + 1] + offset.y);

      if (checkRayIntersection(vertex1, vertex2, point))
      {
        inside = !inside;
      }
    }

    point.putWeak();
    offset.putWeak();

    return inside;
  }

  static inline function checkRayIntersection(vertex1:FlxPoint, vertex2:FlxPoint, point:FlxPoint):Bool
  {
    final result:Bool = (vertex1.y > point.y) != (vertex2.y > point.y)
      && point.x < (vertex1.x + ((point.y - vertex1.y) / (vertex2.y - vertex1.y)) * (vertex2.x - vertex1.x));

    vertex1.putWeak();
    vertex2.putWeak();

    return result;
  }

  function isPressed(check:Bool):Bool
  {
    return !(status != FunkinButtonStatus.NORMAL && (!check || (currentInput != null && currentInput.justReleased)));
  }

  function updateStatus(newInput:IFlxInput):Void
  {
    if (newInput.justPressed)
    {
      currentInput = newInput;

      onDownHandler();
    }
    else if (status == FunkinButtonStatus.NORMAL && !ignoreDownHandler)
    {
      if (newInput.pressed)
      {
        onDownHandler();
      }
    }
  }

  function onUpHandler():Void
  {
    status = FunkinButtonStatus.NORMAL;

    input.release();

    buttonsTouchID.remove(touchID);

    touchID = -1;

    currentInput = null;

    onUp.dispatch();
  }

  function onDownHandler():Void
  {
    status = FunkinButtonStatus.PRESSED;

    input.press();

    onDown.dispatch();
  }

  function onOutHandler():Void
  {
    status = FunkinButtonStatus.NORMAL;

    input.release();

    buttonsTouchID.remove(touchID);

    touchID = -1;

    onOut.dispatch();
  }

  #if FLX_DEBUG
  public override function drawDebugOnCamera(camera:FlxCamera):Void
  {
    if (polygon != null && polygon.length >= 6 && polygon.length % 2 == 0)
    {
      if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

      getScreenPosition(_point, camera);

      final gfx:Graphics = beginDrawDebug(camera);

      final boundingBoxColor:Null<FlxColor> = getDebugBoundingBoxColor(allowCollisions);

      if (boundingBoxColor != null) drawDebugPolygonColor(gfx, polygon, boundingBoxColor);

      endDrawDebug(camera);
    }
    else if (radius > 0)
    {
      if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

      getScreenPosition(_point, camera);

      final gfx:Graphics = beginDrawDebug(camera);

      final boundingBoxColor:Null<FlxColor> = getDebugBoundingBoxColor(allowCollisions);

      if (boundingBoxColor != null) drawDebugCircleColor(gfx, boundingBoxColor);

      endDrawDebug(camera);
    }
    else
    {
      super.drawDebugOnCamera(camera);
    }
  }

  function drawDebugCircleColor(gfx:Graphics, color:FlxColor):Void
  {
    gfx.lineStyle(2, color, 0.75);
    gfx.drawCircle(radius, radius, radius);
  }

  function drawDebugPolygonColor(gfx:Graphics, vertices:Array<Float>, color:FlxColor):Void
  {
    gfx.lineStyle(2, color, 0.75);

    for (i in 0...Math.floor(vertices.length / 2))
    {
      if (i == 0)
      {
        gfx.moveTo(vertices[i * 2] + _point.x, vertices[i * 2 + 1] + _point.y);
      }
      else
      {
        gfx.lineTo(vertices[i * 2] + _point.x, vertices[i * 2 + 1] + _point.y);
      }
    }
  }
  #end

  inline function get_justReleased():Bool
  {
    return input.justReleased;
  }

  inline function get_released():Bool
  {
    return input.released;
  }

  inline function get_pressed():Bool
  {
    return input.pressed;
  }

  inline function get_justPressed():Bool
  {
    return input.justPressed;
  }

  inline function get_currentTouch():Null<FlxTouch>
  {
    return FlxG.touches.getByID(touchID);
  }
}
