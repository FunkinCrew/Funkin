package funkin.mobile.ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import funkin.mobile.util.SwipeUtil;
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
   * Whether this button is a circle or not (This affects the overlap check method).
   */
  public var isCircle:Bool = false;

  /**
   * A radius for circular buttons.
   */
  public var radius:Float = 0;

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
   * Whether the funkin button is a back button, button shouldn't call onDownHandler() on touch.pressed.
   */
  public var isBackButton:Bool = false;

  /**
   * Creates a new `FunkinButton` object.
   *
   * @param X The x position of the button.
   * @param Y The y position of the button.
   */
  public function new(X:Float = 0, Y:Float = 0):Void
  {
    super(X, Y);

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

  private function checkTouchOverlap(?touch:FlxTouch):Bool
  {
    var touches = touch == null ? FlxG.touches.list : [touch];
    for (camera in cameras)
    {
      for (touch in touches)
      {
        final worldPos:FlxPoint = touch.getWorldPosition(camera, _point);

        for (zone in deadZones)
        {
          if (zone != null && zone.overlapsPoint(worldPos, true, camera)) return false;
        }

        if ((!isCircle && overlapsPoint(worldPos, true, camera)) || (isCircle && circleOverlapsPoint(worldPos, camera)))
        {
          touchID = touch.touchPointID;
          if (buttonsTouchID.exists(touchID) && buttonsTouchID.get(touchID) != this)
          {
            var prevButton = buttonsTouchID.get(touchID);
            if (prevButton != null && !prevButton.limitToBounds)
            {
              prevButton.onOutHandler();
            }
          }
          buttonsTouchID.set(touchID, this);

          updateStatus(touch);

          return true;
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

  private function updateStatus(input:IFlxInput):Void
  {
    if (input.justPressed)
    {
      currentInput = input;

      onDownHandler();
    }
    else if (status == FunkinButtonStatus.NORMAL && !isBackButton)
    {
      if (input.pressed)
      {
        onDownHandler();
      }
    }
  }

  private function onUpHandler():Void
  {
    status = FunkinButtonStatus.NORMAL;

    input.release();

    buttonsTouchID.remove(touchID);

    touchID = -1;

    currentInput = null;

    onUp.dispatch();
  }

  private function onDownHandler():Void
  {
    status = FunkinButtonStatus.PRESSED;

    input.press();

    onDown.dispatch();
  }

  private function onOutHandler():Void
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
    if (isCircle)
    {
      if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

      getScreenPosition(_point, camera);

      final gfx:Graphics = beginDrawDebug(camera);

      drawDebugCircleColor(gfx, getDebugBoundingBoxColor(allowCollisions));

      endDrawDebug(camera);
    }
    else
    {
      super.drawDebugOnCamera(camera);
    }
  }

  @:noCompletion
  private function drawDebugCircleColor(gfx:Graphics, color:FlxColor):Void
  {
    gfx.lineStyle(2, color, 0.75);
    gfx.drawCircle(radius, radius, radius);
  }
  #end

  private inline function get_justReleased():Bool
  {
    return input.justReleased;
  }

  private inline function get_released():Bool
  {
    return input.released;
  }

  private inline function get_pressed():Bool
  {
    return input.pressed;
  }

  private inline function get_justPressed():Bool
  {
    return input.justPressed;
  }

  private inline function get_currentTouch():Null<FlxTouch>
  {
    return FlxG.touches.getByID(touchID);
  }
}
