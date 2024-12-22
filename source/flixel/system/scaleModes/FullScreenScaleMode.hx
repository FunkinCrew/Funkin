package flixel.system.scaleModes;

import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.FlxG;

class FullScreenScaleMode extends flixel.system.scaleModes.BaseScaleMode
{
  /**
   * The size of the screen cutout (e.g., for notches or camera cutouts).
   */
  public static var cutoutSize:FlxPoint = FlxPoint.get(0, 0);

  /**
   * The position of the notch on the screen.
   */
  public static var notchPosition:FlxPoint = FlxPoint.get(0, 0);

  /**
   * The size of the notch on the screen.
   */
  public static var notchSize:FlxPoint = FlxPoint.get(0, 0);

  /**
   * The maximum aspect ratio a screen can have.
   */
  public static var maxAspectRatio:FlxPoint = FlxPoint.get(20, 9);

  /**
   * The maximum ratio axis indicating on which axis the black bar will be added.
   */
  public static var maxRatioAxis:FlxAxes = X;

  /**
   * The aspect ratio of the game screen.
   */
  public static var gameRatio:Float = -1;

  /**
   * The size of the game cutout.
   */
  public static var gameCutoutSize:FlxPoint = FlxPoint.get(0, 0);

  /**
   * The position of the notch in game coordinates.
   */
  public static var gameNotchPosition:FlxPoint = FlxPoint.get(0, 0);

  /**
   * The size of the notch in game coordinates.
   */
  public static var gameNotchSize:FlxPoint = FlxPoint.get(0, 0);

  /**
   * The aspect ratio of the window.
   */
  public static var windowRatio:Float = -1;

  /**
   * The scale factor for the window.
   */
  public static var windowScale:FlxPoint = FlxPoint.get(1, 1);

  /**
   * Axis used to determine the ratio (X or Y).
   */
  public static var ratioAxis:FlxAxes = X;

  /**
   * Singleton instance of the `FullScreenScaleMode`.
   */
  public static var instance:FullScreenScaleMode = null;

  /**
   * Whether fullscreen scaling is enabled.
   */
  public static var enabled(default, set):Bool;

  /**
   * Constructor for `FullScreenScaleMode`.
   *
   * @param enable Whether fullscreen scaling should be enabled by default.
   */
  public function new(enable:Bool = true):Void
  {
    super();

    instance = this;

    enabled = enable;
  }

  /**
   * Measures and adjusts the game layout based on the provided screen width and height.
   * @param Width The width of the screen.
   * @param Height The height of the screen.
   */
  public override function onMeasure(Width:Int, Height:Int):Void
  {
    FlxG.width = FlxG.initialWidth;
    FlxG.height = FlxG.initialHeight;

    updateGameSize(Width, Height);
    updateDeviceSize(Width, Height);
    updateDeviceCutout(Width, Height);
    #if mobile
    updateDeviceNotch(funkin.mobile.util.ScreenUtil.getNotchRect());
    #end
    updateScaleOffset();
    updateGamePosition();

    adjustWindowScale();
  }

  private function updateDeviceCutout(Width:Int, Height:Int):Void
  {
    cutoutSize.set(0, 0);
    gameCutoutSize.set(0, 0);

    if (enabled)
    {
      if (ratioAxis == Y)
      {
        cutoutSize.y = Height - gameSize.y;
        gameCutoutSize.y = #if android cutoutSize.y / 2 #else cutoutSize.y #end;
      }
      else
      {
        cutoutSize.x = Width - gameSize.x;
        gameCutoutSize.x = #if android cutoutSize.x / 2 #else cutoutSize.x #end;
      }
    }
  }

  #if mobile
  private function updateDeviceNotch(notch:lime.math.Rectangle):Void
  {
    notchPosition.set(enabled ? notch.x : 0, enabled ? notch.y : 0);
    notchSize.set(enabled ? notch.width : 0, enabled ? notch.height : 0);
    #if android
    gameNotchPosition.set(notchPosition.x / 2, notchPosition.y / 2);
    gameNotchSize.set(notchSize.x / 2, notchSize.y / 2);
    #else
    gameNotchPosition.copyFrom(notchPosition);
    gameNotchSize.copyFrom(notchSize);
    #end
  }
  #end

  private function adjustWindowScale():Void
  {
    if ((cutoutSize.x > 0 || cutoutSize.y > 0) && enabled)
    {
      windowScale.set(1, 1);

      if (ratioAxis == Y)
      {
        gameSize.y += cutoutSize.y;

        var gameHeight:Float = gameSize.y / scale.y;

        if (gameHeight / FlxG.width > maxAspectRatio.y / maxAspectRatio.x && maxRatioAxis.y)
        {
          gameHeight = ((gameSize.x / scale.x) / maxAspectRatio.x) * maxAspectRatio.y;
          offset.y = Math.ceil((deviceSize.y - gameHeight) * 0.5);
          updateGamePosition();
        }

        FlxG.height = Math.floor(gameHeight);
        windowScale.y = FlxG.height / FlxG.initialHeight;
      }
      else
      {
        gameSize.x += cutoutSize.x;

        var gameWidth:Float = gameSize.x / scale.x;
        if (gameWidth / FlxG.height > maxAspectRatio.x / maxAspectRatio.y && maxRatioAxis.x)
        {
          gameWidth = ((gameSize.y / scale.y) / maxAspectRatio.y) * maxAspectRatio.x;
          offset.x = Math.ceil((deviceSize.x - gameWidth) * 0.5);
          updateGamePosition();
        }

        FlxG.width = Math.floor(gameWidth);
        windowScale.x = FlxG.width / FlxG.initialWidth;
      }
    }
  }

  /**
   * Updates the game size based on the provided width and height.
   * @param Width The width of the screen.
   * @param Height The height of the screen.
   */
  public override function updateGameSize(Width:Int, Height:Int):Void
  {
    gameRatio = FlxG.width / FlxG.height;
    windowRatio = Width / Height;
    ratioAxis = windowRatio < gameRatio ? FlxAxes.Y : FlxAxes.X;

    if (ratioAxis == FlxAxes.Y)
    {
      gameSize.x = Width;
      gameSize.y = Math.floor(gameSize.x / gameRatio);
    }
    else
    {
      gameSize.y = Height;
      gameSize.x = Math.floor(gameSize.y * gameRatio);
    }
  }

  @:noCompletion
  private static function set_enabled(Value:Bool):Bool
  {
    if (ratioAxis == FlxAxes.X #if android
      && (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P || android.Tools.isTablet()) #end)
    {
      enabled = Value;
    }
    else
    {
      enabled = false;
    }

    if (instance != null)
    {
      instance.horizontalAlign = enabled ? LEFT : CENTER;
      instance.verticalAlign = enabled ? TOP : CENTER;
      instance.onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);

      FlxG.signals.gameResized.dispatch(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
    }

    return enabled;
  }
}
