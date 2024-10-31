package flixel.system.scaleModes;

import flixel.system.scaleModes.BaseScaleMode;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.FlxG;
#if android
import android.os.Build;
import android.Tools;
#end

class FullScreenScaleMode extends BaseScaleMode
{
  public static var windowScale:FlxPoint = FlxPoint.get(1, 1);
  public static var cutoutSize:FlxPoint = FlxPoint.get(0, 0);
  // x is game ratio, y is window ratio.
  public static var ratio:FlxPoint = FlxPoint.get(-1, -1);
  public static var ratioAxis:FlxAxes = X;
  public static var enabled(default, set):Bool;

  public function new(enable:Bool = true)
  {
    super();
    enabled = enable;
  }

  override public function onMeasure(Width:Int, Height:Int):Void
  {
    FlxG.width = FlxG.initialWidth;
    FlxG.height = FlxG.initialHeight;

    updateGameSize(Width, Height);
    updateDeviceSize(Width, Height);
    updateCutoutSize(Width, Height);
    updateScaleOffset();
    updateGamePosition();
    if ((cutoutSize.x > 0 || cutoutSize.y > 0) && enabled)
    {
      // trace('\nresized the game!\nDevice Size: ${deviceSize}\nGame Size: ${gameSize}\nCutout Size: ${cutoutSize}');
      fillScreen();
    }
  }

  override function updateGameSize(Width:Int, Height:Int):Void
  {
    ratio.x = FlxG.width / FlxG.height;
    ratio.y = Width / Height;

    ratioAxis = ratio.y < ratio.x ? Y : X;

    // trace('ratio axis: ' + ratioAxis);

    if (ratioAxis == Y)
    {
      gameSize.x = Width;
      gameSize.y = Math.floor(gameSize.x / ratio.x);
    }
    else
    {
      gameSize.y = Height;
      gameSize.x = Math.floor(gameSize.y * ratio.x);
    }
  }

  public function updateCutoutSize(Width:Float, Height:Float)
  {
    cutoutSize.set(0, 0);

    if (ratioAxis == Y)
    {
      cutoutSize.y = Height - gameSize.y;
    }
    else
    {
      cutoutSize.x = Width - gameSize.x;
    }
  }

  public function fillScreen()
  {
    if (ratioAxis == Y)
    {
      gameSize.y += cutoutSize.y;
      FlxG.height = Math.floor(gameSize.y / scale.y);
    }
    else
    {
      gameSize.x += cutoutSize.x;
      FlxG.width = Math.floor(gameSize.x / scale.x);
    }

    windowScale.set(FlxG.width / FlxG.initialWidth, FlxG.height / FlxG.initialHeight);
    // trace('resized game with size $gameSize and scale ${scale}');
    // trace('flixel width: ${FlxG.width} - flixel height: ${FlxG.height}');
    // trace('current window scale is $windowScale');
  }

  @:noCompletion
  private static function set_enabled(Value:Bool):Bool
  {
    // No idea what to do about this for iOS
    #if android
    if (!(VERSION.SDK_INT >= VERSION_CODES.P || Tools.isTablet()))
    {
      Value = false;
    }
    #end

    if (Value == true)
    {
      FlxG.scaleMode.horizontalAlign = LEFT;
      FlxG.scaleMode.verticalAlign = TOP;
    }
    else
    {
      FlxG.scaleMode.horizontalAlign = CENTER;
      FlxG.scaleMode.verticalAlign = CENTER;
    }

    return enabled = Value;
  }
}
