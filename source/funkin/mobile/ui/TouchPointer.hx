package funkin.mobile.ui;

// Been considering making it a Bitmap instead and load it into a sprite or something but it got complicated real quick.
// Also this adds pixelOverlap to TouchUtil so, hell yeah !!
// W.I.P DONT TOUCH.
// TODO: Replace all the touchBuddy littered around the game's code with the ACTUAL touchBuddy.
// Thnk u agua and toffee <3
import openfl.display.Bitmap;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
import openfl.display.Stage;
import flixel.system.FlxAssets;
import openfl.display.BitmapData;
import flixel.util.FlxDestroyUtil;
import openfl.display.Sprite;
import flixel.FlxSprite;
import funkin.util.TouchUtil;
import flixel.math.FlxAngle;
import funkin.util.MathUtil;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class TouchPointerGrp extends FlxTypedSpriteGroup<TouchPointer>
{
  public var pointing:Bool = false;
  public var _pointTime:Int = -1;

  public function new(xPos:Float, yPos:Float)
  {
    super(xPos, yPos);
    scrollFactor.set(0, 0);
  }

  var _calcAngle:Float = 0;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (length > 0)
    {
      forEachDead(function(pointer:TouchPointer) {
        remove(pointer);
        pointer.destroy();
      });
    }

    #if mobile
    for (i in 0...FlxG.touches.list.length)
    {
      if (length == FlxG.touches.list.length) break;

      var touch = FlxG.touches.list[i];
      if (touch.justPressed)
      {
        add(new TouchPointer(touch.viewX, touch.viewY, i, touch.touchPointID));
      }
    }
    #end
  }

  public static function load()
  {
    #if mobile
    FlxG.state.add(new TouchPointerGrp(0, 0));
    #end
  }
}

class TouchPointer extends FlxSprite
{
  public var touchId:Int = -1;
  public var pointing:Bool = false;

  var _pointTime:Int = -1;
  var _calcAngle:Float = 0;
  var _pointId:Int;

  public var offsetX:Int = -50;
  public var offsetY:Int = -50;

  public function new(xPos:Float, yPos:Float, touch:Int, pId:Int)
  {
    super(xPos + offsetX, yPos + offsetY, "assets/images/cursor/michael.png");
    touchId = touch;
    _pointId = pId;
    scrollFactor.set(0, 0);
    // scale.set(0.5, 0.5);
  }

  override function update(elapsed:Float)
  {
    #if mobile
    var touch = FlxG.touches.list[touchId];
    if (touch != null && touch.touchPointID == _pointId)
    {
      alpha = 1;
      if (touch.justPressed) setPosition(touch.viewX, touch.viewY);

      if (touch.pressed)
      {
        if (touch.justMoved)
        {
          _pointTime = -1;
          if (!pointing) loadGraphic("assets/images/cursor/kevin.png");
          pointing = true;
        }

        if (pointing)
        {
          final dx:Float = (touch.viewX) - x;
          final dy:Float = (touch.viewY) - y;

          _calcAngle = (Math.abs(dx) > 1 || Math.abs(dy) > 1) ? FlxAngle.wrapAngle(Math.atan2(dy, dx) * 180 / Math.PI) : _calcAngle;

          if (touch.justMoved) angle = MathUtil.smoothLerp(angle, _calcAngle, elapsed, 0.08);

          _pointTime++;
          if (_pointTime > 100)
          {
            pointing = false;
            loadGraphic("assets/images/cursor/michael.png");
          }
        }
        else
        {
          angle = MathUtil.smoothLerp(angle, 0, elapsed, 0.08);
        }

        x = MathUtil.smoothLerp(x, touch.viewX, elapsed, 0.05);
        y = MathUtil.smoothLerp(y, touch.viewY, elapsed, 0.05);
      }
    }
    else
    {
      alpha -= 0.01;
    }

    if (touch?.justReleased)
    {
      pointing = false;
      loadGraphic("assets/images/cursor/michael.png");
    }

    if (alpha == 0) kill();
    #end
    super.update(elapsed);
  }

  public static function load() {}
}
