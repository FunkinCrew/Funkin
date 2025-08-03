package funkin.ui;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import funkin.util.MathUtil;

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
   * The size of the game in screen resolution relativly to the initial size.
   * eg: If screen is 1080p and initial size of the game is 1280x720 then this is 1920x1080.
   */
  public static var logicalSize:FlxPoint = FlxPoint.get(0, 0);

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
  public static var screenRatio:Float = -1;

  /**
   * The scale factor for the window.
   */
  public static var wideScale:FlxPoint = FlxPoint.get(1, 1);

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
   * Wether fake cutouts are added to the screen.
   */
  public static var hasFakeCutouts:Bool = false;

  @:noCompletion
  private static var cutoutBitmaps:Array<Bitmap> = [null, null];

  /**
   * Constructor for `FullScreenScaleMode`.
   *
   * @param enable Whether fullscreen scaling should be enabled by default.
   */
  public function new(enable:Bool = true):Void
  {
    super();

    instance = this;

    // Required so we can check on which axies is the game wide.
    if (FlxG.stage != null) updateGameSize(FlxG.stage.stageWidth, FlxG.stage.stageHeight);

    enabled = enable;
  }

  /**
   * Measures and adjusts the game layout based on the provided screen width and height.
   * @param Width The width of the screen.
   * @param Height The height of the screen.
   */
  override public function onMeasure(Width:Int, Height:Int):Void
  {
    untyped FlxG.width = FlxG.initialWidth;
    untyped FlxG.height = FlxG.initialHeight;

    updateGameSize(Width, Height);
    updateDeviceSize(Width, Height);
    updateDeviceCutout(Width, Height);
    #if mobile
    updateDeviceNotch(funkin.mobile.util.ScreenUtil.getNotchRect());
    #end
    updateScaleOffset();
    updateGamePosition();

    adjustGameSize();
  }

  /**
   * Add fake cutouts into the screen.
   * Useful for when switching from wide display into 16:9 seamlessly and directly is needed.
   * @param tweenDuration The duration of the tweens that adds the cutout bars. Using 0 will instantly put them on screen.
   * @param ease The function that's used for the tween.
   */
  public static function addCutouts(tweenDuration:Float = 0.0, ?ease:Float->Float):Void
  {
    if (cutoutSize.x == 0 && ratioAxis == X || cutoutSize.y == 0 && ratioAxis == Y)
    {
      return;
    }

    for (i => bitmap in cutoutBitmaps)
    {
      if (bitmap == null)
      {
        final game = FlxG.game;

        cutoutBitmaps[i] = bitmap = new Bitmap(new BitmapData(ratioAxis == X ? Math.ceil(cutoutSize.x / 2) : Math.ceil(FlxG.scaleMode.gameSize.x),
          ratioAxis == Y ? Math.ceil(cutoutSize.y / 2) : Math.ceil(FlxG.scaleMode.gameSize.y), true, 0xFF000000));
        game.parent.addChildAt(bitmap, game.parent.getChildIndex(game) + 1);
      }

      var targetX:Float = 0;
      var targetY:Float = 0;

      if (ratioAxis == X)
      {
        bitmap.x = (i == 0) ? -bitmap.width : FlxG.scaleMode.gameSize.x;
        targetX = (i == 0) ? 0 : FlxG.scaleMode.gameSize.x - bitmap.width;
        bitmap.y = 0;
        targetY = 0;
      }
      else
      {
        bitmap.x = 0;
        targetX = 0;
        bitmap.y = (i == 0) ? -bitmap.height : FlxG.scaleMode.gameSize.y;
        targetY = (i == 0) ? 0 : FlxG.scaleMode.gameSize.y - bitmap.height;
      }

      bitmap.alpha = 0;

      if (tweenDuration > 0.0)
      {
        FlxTween.tween(bitmap, {x: targetX, y: targetY, alpha: 1}, tweenDuration, {ease: ease ?? FlxEase.linear});
      }
      else
      {
        bitmap.x = targetX;
        bitmap.y = targetY;
        bitmap.alpha = 1;
      }
    }
    hasFakeCutouts = true;
  }

  /**
   * Remove the fake cutouts from the screen.
   * Used to go back from 16:9 into widescreen seamlessly and directly when needed.
   * @param tweenDuration The duration of the tweens that remove the cutout bars. Using 0 will instantly put them off screen.
   * @param ease The function that's used for the tween.
   */
  public static function removeCutouts(tweenDuration:Float = 0.0, ?ease:Float->Float):Void
  {
    for (i => bitmap in cutoutBitmaps)
    {
      if (bitmap == null)
      {
        trace("[WARNING] Tried to remove a cutout bar but there don't seem to be any.");
        continue;
      }

      final targetX:Float = (i == 0 || ratioAxis == Y) ? ratioAxis == Y ? 0 : -bitmap.width : FlxG.scaleMode.gameSize.x;
      final targetY:Float = (i == 0 || ratioAxis == X) ? ratioAxis == X ? 0 : -bitmap.height : FlxG.scaleMode.gameSize.y;

      if (tweenDuration > 0.0)
      {
        FlxTween.tween(bitmap, {x: targetX, y: targetY, alpha: 0}, tweenDuration, {ease: ease ?? FlxEase.linear});
      }
      else
      {
        bitmap.x = targetX;
        bitmap.y = targetY;
        bitmap.alpha = 0;
      }
    }
    hasFakeCutouts = false;
  }

  private function updateDeviceCutout(Width:Int, Height:Int):Void
  {
    if (enabled)
    {
      cutoutSize.x = ratioAxis == X ? Math.ceil(Width - logicalSize.x) : 0;
      cutoutSize.y = ratioAxis == Y ? Math.ceil(Height - logicalSize.y) : 0;
      gameCutoutSize.copyFrom(cutoutSize);
      gameCutoutSize /= logicalSize.x / FlxG.initialWidth;
    }
    else
    {
      cutoutSize.set(0, 0);
      gameCutoutSize.set(0, 0);
    }
  }

  override public function updateGameSize(Width:Int, Height:Int):Void
  {
    gameRatio = FlxG.width / FlxG.height;
    screenRatio = Width / Height;
    ratioAxis = screenRatio < gameRatio ? FlxAxes.Y : FlxAxes.X;

    logicalSize.set(Width, Height);

    if (ratioAxis == FlxAxes.Y)
    {
      gameSize.x = Width;
      logicalSize.y = Math.ceil(gameSize.x / gameRatio);
      gameSize.y = enabled ? Height : logicalSize.y;
    }
    else
    {
      gameSize.y = Height;
      logicalSize.x = Math.ceil(gameSize.y * gameRatio);
      gameSize.x = enabled ? Width : logicalSize.x;
    }
  }

  override public function updateScaleOffset():Void
  {
    scale.x = ratioAxis == X ? logicalSize.x / FlxG.width : deviceSize.x / FlxG.width;
    scale.y = ratioAxis == Y ? logicalSize.y / FlxG.height : deviceSize.y / FlxG.height;
    updateOffsetX();
    updateOffsetY();
  }

  #if mobile
  private function updateDeviceNotch(notch:lime.math.Rectangle):Void
  {
    notchPosition.set(enabled ? notch.x : 0, enabled ? notch.y : 0);
    notchSize.set(enabled ? notch.width : 0, enabled ? notch.height : 0);
    gameNotchPosition.copyFrom(notchPosition);
    gameNotchSize.copyFrom(notchSize);

    final scale:Float = logicalSize.x / FlxG.initialWidth;
    if (Math.ceil(logicalSize.x) > FlxG.initialWidth)
    {
      gameNotchPosition /= scale;
      gameNotchSize /= scale;
    }
    else
    {
      gameNotchPosition *= scale;
      gameNotchSize *= scale;
    }

    #if ios
    gameNotchPosition /= 2;
    gameNotchSize /= 2;
    #end
  }
  #end

  public function reset():Void
  {
    cutoutSize.set(0, 0);
    gameCutoutSize.set(0, 0);
    notchSize.set(0, 0);
    gameNotchSize.set(0, 0);
    notchPosition.set(0, 0);
    gameNotchPosition.set(0, 0);
  }

  private function adjustGameSize():Void
  {
    if ((cutoutSize.x > 0 || cutoutSize.y > 0) && enabled)
    {
      wideScale.set(1, 1);

      if (ratioAxis == Y)
      {
        var gameHeight:Float = gameSize.y / scale.y;

        #if desktop
        if (MathUtil.gcd(FlxG.width, Math.ceil(gameHeight)) == 1)
        {
          gameSize.y -= cutoutSize.y;
          offset.y = Math.ceil((deviceSize.y - gameSize.y) * 0.5);
          updateGamePosition();
          reset();
          return;
        }
        #end

        if (gameHeight / FlxG.width > maxAspectRatio.y / maxAspectRatio.x && maxRatioAxis.y)
        {
          final oldGameHeight = gameSize.y;
          gameHeight = ((gameSize.x / scale.x) / maxAspectRatio.x) * maxAspectRatio.y;
          gameSize.y = gameHeight * scale.y;

          final sizeDifference:Float = oldGameHeight - gameSize.y;
          final scale:Float = logicalSize.y / FlxG.initialHeight;
          cutoutSize.set(0, cutoutSize.y - sizeDifference);
          gameCutoutSize.copyFrom(cutoutSize);
          gameCutoutSize /= scale;

          notchSize.y = Math.max(0, notchSize.y - sizeDifference);
          gameNotchSize.y = notchSize.y / scale;

          offset.y = Math.ceil((deviceSize.y - gameSize.y) * 0.5);
          updateGamePosition();
        }

        untyped FlxG.height = Math.ceil(gameHeight);

        wideScale.y = FlxG.height / FlxG.initialHeight;
      }
      else
      {
        var gameWidth:Float = gameSize.x / scale.x;

        #if desktop
        if (MathUtil.gcd(Math.ceil(gameWidth), FlxG.height) == 1)
        {
          gameSize.x -= cutoutSize.x;
          offset.x = Math.ceil((deviceSize.x - gameSize.x) * 0.5);
          updateGamePosition();
          reset();
          return;
        }
        #end

        if (gameWidth / FlxG.height > maxAspectRatio.x / maxAspectRatio.y && maxRatioAxis.x)
        {
          final oldGameWidth = gameSize.x;
          gameWidth = ((gameSize.y / scale.y) / maxAspectRatio.y) * maxAspectRatio.x;
          gameSize.x = gameWidth * scale.x;

          final sizeDifference:Float = oldGameWidth - gameSize.x;
          final scale:Float = logicalSize.x / FlxG.initialWidth;
          cutoutSize.set(cutoutSize.x - sizeDifference, 0);
          gameCutoutSize.copyFrom(cutoutSize);
          gameCutoutSize /= scale;

          notchSize.x = Math.max(0, notchSize.x - sizeDifference);
          gameNotchSize.x = notchSize.x / scale;

          offset.x = Math.ceil((deviceSize.x - gameSize.x) * 0.5);
          updateGamePosition();
        }

        untyped FlxG.width = Math.ceil(gameWidth);

        wideScale.x = FlxG.width / FlxG.initialWidth;
      }
    }
  }

  @:noCompletion
  private static function set_enabled(Value:Bool):Bool
  {
    if (ratioAxis == FlxAxes.X #if android
      && (extension.androidtools.os.Build.VERSION.SDK_INT >= extension.androidtools.os.Build.VERSION_CODES.P
        || extension.androidtools.Tools.isTablet()) #end)
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
