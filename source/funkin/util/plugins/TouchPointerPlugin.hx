package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxAngle;
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import funkin.graphics.FunkinCamera;

// TODO: Replace all the touchBuddy littered around the game's code with the ACTUAL touchBuddy.
// Thnk u agua and toffee <3

/**
 * @author moondroidcoder
 * Tracks your touch points in your game.
 */
class TouchPointerPlugin extends FlxTypedSpriteGroup<TouchPointer>
{
  /**
   * Whether the plugin is enabled.
   */
  public static var enabled(default, set):Bool = true;

  /**
   * A singleton instance of the plugin.
   */
  private static var instance:TouchPointerPlugin = null;

  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    var pointerCamera:FlxCamera = new FlxCamera();
    pointerCamera.bgColor.alpha = 0;
    instance = new TouchPointerPlugin();
    instance.cameras = [pointerCamera];

    FlxG.cameras.add(pointerCamera, false);
    FlxG.plugins.drawOnTop = true;
    FlxG.plugins.addPlugin(instance);

    function moveCameraToTop(camera:FlxCamera):Void
    {
      if (camera == pointerCamera && pointerCamera == null) return;

      // If there aren't any cameras then the CameraFrontEnd got reset so we have to wait for that finish (which is most of the time after state switch)
      if (FlxG.cameras.list.length == 0)
      {
        FlxG.signals.postStateSwitch.addOnce(moveCameraToTop.bind(null));
        return;
      }

      if (FlxG.cameras.list.contains(pointerCamera))
      {
        FlxG.cameras.list.remove(pointerCamera);
      }

      if (FlxG.game.contains(pointerCamera.flashSprite))
      {
        FlxG.game.removeChild(pointerCamera.flashSprite);
      }

      @:privateAccess
      FlxG.game.addChildAt(pointerCamera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer));
      FlxG.cameras.list.push(pointerCamera);
    }

    FlxG.cameras.cameraAdded.add(moveCameraToTop);

    FlxG.cameras.cameraRemoved.add(function(camera:FlxCamera) {
      if (camera == pointerCamera)
      {
        if (!camera.exists) // The camera got destroyed, we make a new one!
        {
          instance.cameras = [pointerCamera = new FlxCamera()];
          moveCameraToTop(null);
          pointerCamera.bgColor.alpha = 0;
          pointerCamera.ID = FlxG.cameras.list.length - 1;
        }
        else // It's not destroyed so just move it to the top!
        {
          moveCameraToTop(null);
        }
      }
      else
      {
        moveCameraToTop(null);
      }
    });
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    for (touch in FlxG.touches.list)
    {
      if (touch == null) continue;

      var pointer:TouchPointer = findPointerByTouchId(touch.touchPointID);

      if (pointer == null)
      {
        pointer = recycle(TouchPointer);
        pointer.initialize(touch.touchPointID);
        add(pointer);
      }

      pointer.updateFromTouch(touch);
    }

    for (pointer in members)
    {
      if (pointer == null || touchExists(pointer.touchId)) continue;

      remove(pointer, true);
    }
  }

  private function findPointerByTouchId(touchId:Int):TouchPointer
  {
    for (pointer in members)
    {
      if (pointer == null || pointer.touchId != touchId) continue;

      return pointer;
    }
    return null;
  }

  private function touchExists(touchId:Int):Bool
  {
    for (touch in FlxG.touches.list)
    {
      if (touch.touchPointID != touchId) continue;

      return true;
    }
    return false;
  }

  @:noCompletion
  private static function set_enabled(value:Bool):Bool
  {
    if (instance != null)
    {
      instance.exists = instance.visible = instance.active = instance.alive = value;
    }

    return enabled = value;
  }
}

class TouchPointer extends FlxSprite
{
  public var touchId:Int = -1;

  private var lastPosition:FlxPoint;

  public function new()
  {
    super();
    makeGraphic(16, 16, FlxColor.RED);
    scrollFactor.set(0, 0);
    lastPosition = FlxPoint.get();
  }

  public function initialize(touchId:Int):Void
  {
    this.touchId = touchId;
    loadGraphic("assets/images/cursor/michael.png");
  }

  public function updateFromTouch(touch:FlxTouch):Void
  {
    // Update position
    x = touch.viewX - width / 2;
    y = touch.viewY - height / 2;

    if (camera.target != null)
    {
      x -= camera.target.x;
      y -= camera.target.y;
    }

    // Calculate angle if moving
    if (lastPosition.distanceTo(FlxPoint.weak(touch.viewX, touch.viewY)) > 3)
    {
      var angle = FlxAngle.angleBetweenPoint(this, lastPosition, true);
      this.angle = angle;
      loadGraphic("assets/images/cursor/kevin.png");
    }
    else
    {
      angle = 0;
      loadGraphic("assets/images/cursor/michael.png");
    }

    lastPosition.set(touch.viewX, touch.viewY);
  }

  override public function destroy():Void
  {
    lastPosition.put();
    super.destroy();
  }
}
