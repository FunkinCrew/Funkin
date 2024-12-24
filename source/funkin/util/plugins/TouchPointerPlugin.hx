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

// TODO: Replace all the touchBuddy littered around the game's code with the ACTUAL touchBuddy.
// Thnk u agua and toffee <3

/**
 * @author moondroidcoder
 * Tracks your touch points in your game.
 */
class TouchPointerPlugin extends FlxBasic
{
  public var pointerGrp:FlxTypedSpriteGroup<TouchPointer>;

  public function new()
  {
    super();
    pointerGrp = new FlxTypedSpriteGroup<TouchPointer>();
    // add(pointerGrp);
  }

  public static function initialize()
  {
    FlxG.plugins.addPlugin(new TouchPointerPlugin());
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
        pointer = pointerGrp.recycle(TouchPointer);
        pointer.initialize(touch.touchPointID);
        pointerGrp.add(pointer);
      }

      pointer.updateFromTouch(touch);
    }

    for (pointer in pointerGrp.members)
    {
      if (pointer == null || touchExists(pointer.touchId)) continue;

      pointerGrp.remove(pointer, true);
    }
  }

  private function findPointerByTouchId(touchId:Int):TouchPointer
  {
    for (pointer in pointerGrp.members)
    {
      if (pointer == null || pointer.touchId == touchId) continue;

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
    lastPosition = new FlxPoint();
  }

  public function initialize(touchId:Int):Void
  {
    this.touchId = touchId;
    loadGraphic("assets/images/cursor/michael.png");
  }

  public function updateFromTouch(touch:FlxTouch):Void
  {
    // Update position
    x = touch.viewX;
    y = touch.viewY;

    // Calculate angle if moving
    if (lastPosition.x != touch.viewX || lastPosition.y != touch.viewY)
    {
      var angle = FlxAngle.angleBetweenPoints(lastPosition, new FlxPoint(touch.viewX, touch.viewY));
      this.angle = angle;
      loadGraphic("assets/images/cursor/kevin.png");
    }

    lastPosition.set(touch.viewX, touch.viewY);
  }

  override public function destroy():Void
  {
    lastPosition.put();
    super.destroy();
  }
}
