package flixel.system.scaleModes;

import flixel.system.scaleModes.BaseScaleMode;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.FlxG;
#if android
import android.os.Build;
import android.Tools;
#end
#if mobile
import funkin.mobile.util.ScreenUtil;
#end

class FullScreenScaleMode extends BaseScaleMode
{
  public static final cutoutSize:FlxPoint = FlxPoint.get(0, 0);
  public static final notchPosition:FlxPoint = FlxPoint.get(0, 0);
  public static final notchSize:FlxPoint = FlxPoint.get(0, 0);

  public static final gameCutoutSize:FlxPoint = FlxPoint.get(0, 0);
  public static final gameNotchPosition:FlxPoint = FlxPoint.get(0, 0);
  public static final gameNotchSize:FlxPoint = FlxPoint.get(0, 0);

  public static final windowScale:FlxPoint = FlxPoint.get(1, 1);
  public static var gameRatio:Float = -1;
  public static var windowRatio:Float = -1;
  public static var ratioAxis:FlxAxes = X;

  public static var enabled(default, set):Bool;
  public static var instance:FullScreenScaleMode = null;

  public function new(enable:Bool = true)
  {
    super();
    instance = this;
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
    #if mobile
    updateNotch();
    #end
    if ((cutoutSize.x > 0 || cutoutSize.y > 0) && enabled)
    {
      fillScreen();
    }
  }

  override function updateGameSize(Width:Int, Height:Int):Void
  {
    gameRatio = FlxG.width / FlxG.height;
    windowRatio = Width / Height;

    ratioAxis = windowRatio < gameRatio ? Y : X;

    // trace('ratio axis: ' + ratioAxis);

    if (ratioAxis == Y)
    {
      gameSize.x = Width;
      gameSize.y = Math.floor(gameSize.x / gameRatio);
      enabled = false;
    }
    else
    {
      gameSize.y = Height;
      gameSize.x = Math.floor(gameSize.y * gameRatio);
    }
  }

  public function updateCutoutSize(Width:Float, Height:Float)
  {
    cutoutSize.set(0, 0);
    gameCutoutSize.set(0, 0);

    if (enabled)
    {
      if (ratioAxis == Y)
      {
        cutoutSize.y = Height - gameSize.y;
        #if android
        gameCutoutSize.y = cutoutSize.y / 2;
        // #elseif ios
        // gameCutoutSize.y = cutoutSize.y * 2;
        #else
        gameCutoutSize.y = cutoutSize.y;
        #end
      }
      else
      {
        cutoutSize.x = Width - gameSize.x;
        #if android
        gameCutoutSize.x = cutoutSize.x / 2;
        // #elseif ios
        // gameCutoutSize.x = cutoutSize.x * 2;
        #else
        gameCutoutSize.x = cutoutSize.x;
        #end
      }
    }
  }

  #if mobile
  public function updateNotch()
  {
    if (enabled)
    {
      var notch:lime.math.Rectangle = ScreenUtil.getNotchRect();
      notchPosition.set(notch.x, notch.y);
      notchSize.set(notch.width, notch.height);
      #if android
      gameNotchPosition.set(notchPosition.x / 2, notchPosition.y / 2);
      gameNotchSize.set(notchSize.x / 2, notchSize.y / 2);
      // #elseif ios
      // gameNotchPosition.set(notchPosition.x * 2, notchPosition.y * 2);
      // gameNotchSize.set(notchSize.x * 2, notchSize.y * 2);
      #else
      gameNotchPosition.set(notchPosition.x, notchPosition.y);
      gameNotchSize.set(notchSize.x, notchSize.y);
      #end
    }
    else
    {
      notchPosition.set(0, 0);
      gameNotchPosition.set(0, 0);
      notchSize.set(0, 0);
      gameNotchSize.set(0, 0);
    }
  }
  #end

  public function fillScreen()
  {
    windowScale.set(1, 1);
    if (ratioAxis == Y)
    {
      gameSize.y += cutoutSize.y;
      FlxG.height = Math.floor(gameSize.y / scale.y);
      windowScale.y = (FlxG.height / FlxG.initialHeight);
    }
    else
    {
      gameSize.x += cutoutSize.x;
      FlxG.width = Math.floor(gameSize.x / scale.x);
      windowScale.x = (FlxG.width / FlxG.initialWidth);
    }

    // trace('resized game with size $gameSize and scale ${scale}');
    // trace('flixel width: ${FlxG.width} - flixel height: ${FlxG.height}');
    // trace('current window scale is $windowScale');
  }

  @:noCompletion
  private static function set_enabled(Value:Bool):Bool
  {
    // TODO (??): Make the game work properly on screens that are wide vertically
    // TODO: Figure out a way to configure this for iOS Platforms.
    if (ratioAxis == Y #if andorid || !(VERSION.SDK_INT >= VERSION_CODES.P || Tools.isTablet()) #end)
    {
      Value = false;
    }

    enabled = Value;

    if (instance != null)
    {
      if (enabled == true)
      {
        instance.horizontalAlign = LEFT;
        instance.verticalAlign = TOP;
      }
      else
      {
        instance.horizontalAlign = CENTER;
        instance.verticalAlign = CENTER;
      }

      if (FlxG.stage != null)
      {
        instance.onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
        FlxG.signals.gameResized.dispatch(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
      }
    }

    return enabled;
  }
}
