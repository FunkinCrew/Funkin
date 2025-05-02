package funkin.util.plugins;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
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

  /**
   * Initializes the TouchPointerPlugin by creating a new camera and setting it up to be drawn on top of other elements.
   */
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

    FlxG.signals.preStateSwitch.add(function() {
      instance.removeAll();
    });
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    for (touch in FlxG.touches.list)
    {
      if (touch == null) continue;

      if (touch.justPressed) removeAll(true);

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
      if (pointer.touchId != -2)
      {
        pointer.alpha = 0.8;
        FlxTween.tween(pointer, {alpha: 0}, FlxG.random.float(0.8, 0.9),
          {
            ease: FlxEase.cubeIn,
            onComplete: function(_) {
              remove(pointer, true);
            }
          });
        pointer.touchId = -2;
      }
    }
  }

  /**
   * Finds a TouchPointer object in the members list by its touch ID.
   *
   * @param touchId The ID of the touch to find.
   * @return The TouchPointer object with the specified touch ID, or null if not found.
   */
  private function findPointerByTouchId(touchId:Int):TouchPointer
  {
    for (pointer in members)
    {
      if (pointer == null || pointer.touchId != touchId) continue;

      return pointer;
    }
    return null;
  }

  /**
   * Checks if a touch with the specified ID exists in the current touch list.
   *
   * @param touchId The ID of the touch to check for.
   * @return True if a touch with the specified ID exists, false otherwise.
   */
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

  public function removeAll(skipTween:Bool = false)
  {
    for (pointer in members)
    {
      if (pointer == null) continue;

      if (skipTween)
      {
        FlxTween.cancelTweensOf(pointer);
        remove(pointer, true);
        continue;
      }

      pointer.alpha = 0.8;
      FlxTween.tween(pointer, {alpha: 0}, FlxG.random.float(0.8, 1),
        {
          ease: FlxEase.quadIn,
          onComplete: function(_) {
            remove(pointer, true);
          }
        });
    }
  }
}

/**
 * Represents a touch pointer in the game.
 */
class TouchPointer extends FlxSprite
{
  /**
   * Represents a touch pointer plugin.
   */
  public var touchId:Int = -1;

  /**
   * Stores the last position of the touch pointer.
   */
  private var lastPosition:FlxPoint;

  /**
   * Constructor for the TouchPointerPlugin class.
   * Initializes the touch pointer graphic and sets the scroll factor.
   */
  public function new()
  {
    super();
    makeGraphic(16, 16, FlxColor.RED);
    scrollFactor.set(0, 0);
    lastPosition = FlxPoint.get();
  }

  /**
   * Initializes the touch pointer object itself with the specified touch ID.
   * Loads the graphic for the touch pointer.
   *
   * @param touchId The ID of the touch event to initialize.
   */
  public function initialize(touchId:Int):Void
  {
    this.touchId = touchId;
    loadGraphic("assets/images/cursor/michael.png");
  }

  /**
   * Updates the position and angle of the touch pointer based on the given touch input.
   * Used in TouchPointerPlugin's update method.
   *
   * @param touch The FlxTouch object containing the current touch input data.
   */
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

  override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
  {
    super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
    color = 0xff6666e1;
    blend = "screen";
    return this;
  }
}
