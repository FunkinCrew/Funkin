package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import flixel.addons.util.FlxAsyncLoop;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.audio.FunkinSound;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.events.MouseEvent;
import funkin.Preferences;

typedef ScreenshotPluginParams =
{
  ?region:Rectangle,
  flashColor:Null<FlxColor>,
};

/**
 * What if `flixel.addons.plugin.screengrab.FlxScreenGrab` but it's better?
 * TODO: Contribute this upstream.
 */
class ScreenshotPlugin extends FlxBasic
{
  /**
   * Current `ScreenshotPlugin` instance
   */
  public static var instance:ScreenshotPlugin = null;

  public static final SCREENSHOT_FOLDER = 'screenshots';

  var region:Null<Rectangle>;

  /**
   * The color used for the flash
   */
  public static var flashColor(default, set):Int = 0xFFFFFFFF;

  public static function set_flashColor(v:Int):Int
  {
    flashColor = v;
    if (instance != null && instance.flashBitmap != null) instance.flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, v);
    return flashColor;
  }

  /**
   * A signal fired before the screenshot is taken.
   */
  public var onPreScreenshot(default, null):FlxTypedSignal<Void->Void>;

  /**
   * A signal fired after the screenshot is taken.
   * @param bitmap The bitmap that was captured.
   */
  public var onPostScreenshot(default, null):FlxTypedSignal<Bitmap->Void>;

  private static var lastWidth:Int;
  private static var lastHeight:Int;

  var containerThing:Sprite;
  var flashSprite:Sprite;
  var flashBitmap:Bitmap;
  var previewSprite:Sprite;
  var shotPreviewBitmap:Bitmap;
  var outlineBitmap:Bitmap;

  var wasMouseHidden:Bool = false;
  var screenshotTakenFrame:Int = 0;

  var screenshotBeingSpammed:Bool = false;

  var screenshotSpammedTimer:FlxTimer;

  var screenshotBuffer:Array<Bitmap> = [];
  var screenshotNameBuffer:Array<String> = [];

  var flashTween:FlxTween;

  var previewFadeInTween:FlxTween;
  var previewFadeOutTween:FlxTween;

  var asyncLoop:FlxAsyncLoop;

  public function new(params:ScreenshotPluginParams)
  {
    super();

    if (instance != null)
    {
      destroy();
      return;
    }

    instance = this;

    lastWidth = FlxG.width;
    lastHeight = FlxG.height;

    containerThing = new Sprite();
    FlxG.stage.addChild(containerThing);

    flashSprite = new Sprite();
    flashSprite.alpha = 0;
    flashBitmap = new Bitmap(new BitmapData(lastWidth, lastHeight, true, params.flashColor));
    flashSprite.addChild(flashBitmap);

    previewSprite = new Sprite();
    previewSprite.alpha = 0;
    containerThing.addChild(previewSprite);

    outlineBitmap = new Bitmap(new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF));
    outlineBitmap.x = 5;
    outlineBitmap.y = 5;
    previewSprite.addChild(outlineBitmap);

    shotPreviewBitmap = new Bitmap();
    shotPreviewBitmap.scaleX /= 5;
    shotPreviewBitmap.scaleY /= 5;
    previewSprite.addChild(shotPreviewBitmap);
    containerThing.addChild(flashSprite);

    region = params.region ?? null;
    flashColor = params.flashColor;

    onPreScreenshot = new FlxTypedSignal<Void->Void>();
    onPostScreenshot = new FlxTypedSignal<Bitmap->Void>();
    FlxG.signals.gameResized.add(this.resizeBitmap);
  }

  public override function update(elapsed:Float):Void
  {
    if (asyncLoop != null)
    {
      // If my loop hasn't started yet, start it
      if (!asyncLoop.started)
      {
        asyncLoop.start();
      }
      else
      {
        // if the loop has been started, and is finished, then we kill. it
        if (asyncLoop.finished)
        {
          trace("finished saving screenshot buffer");
          screenshotBuffer = [];
          screenshotNameBuffer = [];
          // your honor, league of legends
          asyncLoop.kill();
          asyncLoop.destroy();
          asyncLoop = null;
        }
      }
      // Examples ftw!
    }
    super.update(elapsed);

    /*
      This looks scary, oh no I pressed the button but no screenshot because screenshotTakenFrame != 0!
      But if you're crazy enough to have a macro that bumps into this
      then you're probably also going to hit 100 screenshots real fast
     */
    if (hasPressedScreenshot() && screenshotTakenFrame == 0)
    {
      if (Preferences.shouldHideMouse && !wasMouseHidden && FlxG.mouse.visible)
      {
        wasMouseHidden = true;
        Cursor.hide();
      }
      if (FlxG.keys.pressed.SHIFT)
      {
        openScreenshotsFolder();
        return; // We're only opening the screenshots folder (we don't want to accidentally take a screenshot after this)
      }
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
      // screenshot spamming timer
      if (screenshotSpammedTimer == null || screenshotSpammedTimer.finished == true)
      {
        screenshotSpammedTimer = new FlxTimer().start(1, function(_) {
          // The player's stopped spamming shots, so we can stop the screenshot spam mode too
          if (!Preferences.flashingLights) containerThing.alpha = 1;
          screenshotBeingSpammed = false;
          if (screenshotBuffer[0] != null) saveBufferedScreenshots(screenshotBuffer, screenshotNameBuffer);
          if (wasMouseHidden && !FlxG.mouse.visible)
          {
            wasMouseHidden = false;
            Cursor.show();
          }
        });
      }
      else // Pressing the screenshot key more than once every second enables the screenshot spam mode and resets the timer
      {
        screenshotBeingSpammed = true;
        if (!Preferences.flashingLights) containerThing.alpha = 0; // hide the preview completely
        screenshotSpammedTimer.reset(1);
      }
      screenshotTakenFrame++;
    }
    else if (screenshotTakenFrame > 1)
    {
      screenshotTakenFrame = 0;
      capture(); // After all these checks and waiting a frame, we finally try taking a screenshot
    }
    else if (screenshotTakenFrame > 0)
    {
      screenshotTakenFrame++;
    }
  }

  /**
   * Initialize the screenshot plugin.
   */
  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ScreenshotPlugin(
      {
        flashColor: Preferences.flashingLights ? FlxColor.WHITE : null, // Was originally a black flash.
      }));
  }

  public function hasPressedScreenshot():Bool
  {
    #if FEATURE_SCREENSHOTS
    return PlayerSettings.player1.controls.WINDOW_SCREENSHOT;
    #else
    return false;
    #end
  }

  public function updateFlashColor():Void
  {
    Preferences.flashingLights ? set_flashColor(FlxColor.WHITE) : null;
  }

  private function resizeBitmap(width:Int, height:Int)
  {
    lastWidth = width;
    lastHeight = height;
    flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, flashColor);
    outlineBitmap.bitmapData = new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF);
  }

  /**
   * Defines the region of the screen that should be captured.
   * You don't need to call this method if you want to capture the entire screen, that's the default behavior.
   */
  public function defineCaptureRegion(x:Int, y:Int, width:Int, height:Int):Void
  {
    region = new Rectangle(x, y, width, height);
  }

  /**
   * Capture the game screen as a bitmap.
   */
  public function capture():Void
  {
    onPreScreenshot.dispatch();

    // var captureRegion = region != null ? region : new Rectangle(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);

    // The actual work.
    // var bitmap = new Bitmap(new BitmapData(Math.floor(captureRegion.width), Math.floor(captureRegion.height), true, 0x00000000)); // Create a transparent empty bitmap.
    // var drawMatrix = new Matrix(1, 0, 0, 1, -captureRegion.x, -captureRegion.y); // Modifying this will scale or skew the bitmap.
    // bitmap.bitmapData.draw(FlxG.stage, drawMatrix);
    var shot = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));
    if (screenshotBeingSpammed == true)
    {
      // Save the screenshots to the buffer instead
      if (screenshotBuffer.length < 100)
      {
        screenshotBuffer.push(shot);
        screenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');
      }
      else
        throw "You've tried taking more than 100 screenshots at a time. Give the game a funkin break! Jeez. If you wanted those screenshots, well too bad!";
      showCaptureFeedback();
      showFancyPreview(shot);
      if (wasMouseHidden && !FlxG.mouse.visible && Preferences.flashingLights) // Just in case
      {
        wasMouseHidden = false;
        Cursor.show();
      }
    }
    else
    {
      saveScreenshot(shot, 'screenshot-${DateUtil.generateTimestamp()}', 1);
      // Show some feedback.
      showCaptureFeedback();
      showFancyPreview(shot);
      if (wasMouseHidden && !FlxG.mouse.visible)
      {
        wasMouseHidden = false;
        Cursor.show();
      }
    }
    onPostScreenshot.dispatch(shot);
  }

  final CAMERA_FLASH_DURATION = 0.25;

  /**
   * Visual and audio feedback when a screenshot is taken.
   */
  function showCaptureFeedback():Void
  {
    flashSprite.alpha = 1;
    FlxTween.tween(flashSprite, {alpha: 0}, 0.15);

    FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
    // I don't need this
    /*var flashBitmap;
        flashSprite = new Sprite();
        if (screenshotBeingSpammed == false)
        {
          flashBitmap = new Bitmap(new BitmapData(Std.int(FlxG.stage.width), Std.int(FlxG.stage.height), false, 0xFFFFFFFF));
          // flashSpr = new Sprite();
          flashSprite.addChild(flashBitmap);
          FlxG.stage.addChild(flashSprite);
        }
        flashTween = FlxTween.tween(flashSprite, {alpha: 0}, 0.15,
          {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
              flashTween = null;
              FlxG.stage.removeChild(flashSprite);
            }
      });
      // Play a sound (auto-play is true).
      FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
     */
  }

  static final PREVIEW_INITIAL_DELAY = 0.25; // How long before the preview starts fading in.
  static final PREVIEW_FADE_IN_DURATION = 0.3; // How long the preview takes to fade in.
  static final PREVIEW_FADE_OUT_DELAY = 1.25; // How long the preview stays on screen.
  static final PREVIEW_FADE_OUT_DURATION = 0.3; // How long the preview takes to fade out.

  function showFancyPreview(shot:Bitmap):Void
  {
    if (!Preferences.fancyPreview) return; // Sorry, the previews' been cancelled
    shotPreviewBitmap.bitmapData = shot.bitmapData;
    shotPreviewBitmap.x = outlineBitmap.x + 5;
    shotPreviewBitmap.y = outlineBitmap.y + 5;

    previewSprite.alpha = 1;
    FlxTween.tween(previewSprite, {alpha: 0}, 0.5, {startDelay: .5});
    // I just can't for the life of me get this thing to hide properly, so it's being disabled
    // I mean, steam doesn't make their screenshots this advanced anyways

    // ermmm stealing this??
    /*
        if (!wasMouseHidden && !FlxG.mouse.visible && screenshotBeingSpammed == false)
        {
          wasMouseHidden = true;
          Cursor.show();
        }

        // so that it doesnt change the alpha when tweening in/out
        var changingAlpha:Bool = false;

        // fuck it, cursed locally scoped functions, purely because im lazy
        // (and so we can check changingAlpha, which is locally scoped.... because I'm lazy...)
        var onHover = function(e:MouseEvent) {
          if (!changingAlpha) e.target.alpha = 0.6;
        };

        var onHoverOut = function(e:MouseEvent) {
          if (!changingAlpha) e.target.alpha = 1;
        }

        var cancelPreview = function():Void {
          if (screenshotBeingSpammed == true)
          {
            previewSprite.removeEventListener(MouseEvent.MOUSE_DOWN, openScreenshotsFolder);
            previewSprite.removeEventListener(MouseEvent.MOUSE_OVER, onHover);
            previewSprite.removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

            FlxG.stage.removeChild(previewSprite);

            if (previewFadeInTween != null) previewFadeInTween.cancel();
            if (previewFadeOutTween != null) previewFadeOutTween.cancel();

            if (wasMouseHidden)
            {
              Cursor.hide();
              wasMouseHidden = false;
            }

            return;
          }
        };

        var scale:Float = 0.25;
        var w:Int = Std.int(bitmap.bitmapData.width * scale);
        var h:Int = Std.int(bitmap.bitmapData.height * scale);

        var preview:BitmapData = new BitmapData(w, h, true);
        var matrix:openfl.geom.Matrix = new openfl.geom.Matrix();
        matrix.scale(scale, scale);
        preview.draw(bitmap.bitmapData, matrix);

        // used for movement + button stuff
        previewSprite = new Sprite();

        previewSprite.buttonMode = true;
        previewSprite.addEventListener(MouseEvent.MOUSE_DOWN, openScreenshotsFolder);
        previewSprite.addEventListener(MouseEvent.MOUSE_OVER, onHover);
        previewSprite.addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

        FlxG.stage.addChild(previewSprite);

        previewSprite.alpha = 0.0;
        previewSprite.y -= 10;

        var previewBitmap = new Bitmap(preview);
        previewSprite.addChild(previewBitmap);

        cancelPreview();

        // Wait to fade in.
        new FlxTimer().start(PREVIEW_INITIAL_DELAY, function(_) {
          cancelPreview();
          // Fade in.
          changingAlpha = true;
          previewFadeInTween = FlxTween.tween(previewSprite, {alpha: 1.0, y: 0}, PREVIEW_FADE_IN_DURATION,
            {
              ease: FlxEase.quartOut,
              onComplete: function(_) {
                changingAlpha = false;
                cancelPreview();
                // Wait to fade out.
                new FlxTimer().start(PREVIEW_FADE_OUT_DELAY, function(_) {
                  changingAlpha = true;
                  // Fade out.
                  previewFadeOutTween = FlxTween.tween(previewSprite, {alpha: 0.0, y: 10}, PREVIEW_FADE_OUT_DURATION,
                    {
                      ease: FlxEase.quartInOut,
                      onComplete: function(_) {
                        if (wasMouseHidden)
                        {
                          Cursor.hide();
                          wasMouseHidden = false;
                        }
                        // else if (!wasMouseAlreadyHidden)
                        previewSprite.removeEventListener(MouseEvent.MOUSE_DOWN, openScreenshotsFolder);
                        previewSprite.removeEventListener(MouseEvent.MOUSE_OVER, onHover);
                        previewSprite.removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

                        FlxG.stage.removeChild(previewSprite);
                      }
                    });
                });
              }
            });
      });
     */
  }

  function openScreenshotsFolder():Void
  {
    FileUtil.openFolder(SCREENSHOT_FOLDER);
  }

  static function getCurrentState():FlxState
  {
    var state = FlxG.state;
    while (state.subState != null)
    {
      state = state.subState;
    }
    return state;
  }

  static function getScreenshotPath():String
  {
    return '$SCREENSHOT_FOLDER/';
  }

  static function makeScreenshotPath():Void
  {
    FileUtil.createDirIfNotExists(SCREENSHOT_FOLDER);
  }

  /**
   * Convert a Bitmap to a PNG or JPEG ByteArray to save to a file.
   */
  function encode(bitmap:Bitmap):ByteArray
  {
    var compressor = returnEncoder(Preferences.saveFormat);
    return bitmap.bitmapData.encode(bitmap.bitmapData.rect, compressor);
  }

  var previousScreenshotName:String;
  var previousScreenshotCopyNum:Int;

  /**
   * Save the generated bitmap to a file.
   * @param bitmap The bitmap to save.
   */
  function saveScreenshot(bitmap:Bitmap, targetPath, screenShotNum:Int)
  {
    makeScreenshotPath();
    // Check that we're not overriding a previous image, and keep making a unique path until we can
    if (previousScreenshotName != targetPath && previousScreenshotName != (targetPath + ' (${previousScreenshotCopyNum})'))
    {
      previousScreenshotName = targetPath;
      targetPath = getScreenshotPath() + targetPath + '.' + Std.string(Preferences.saveFormat).toLowerCase();
      previousScreenshotCopyNum = 2;
    }
    else
    {
      var newTargetPath:String = targetPath + ' (${previousScreenshotCopyNum})';
      while (previousScreenshotName == newTargetPath)
      {
        previousScreenshotCopyNum++;
        newTargetPath = targetPath + ' (${previousScreenshotCopyNum})';
      }
      previousScreenshotName = newTargetPath;
      targetPath = getScreenshotPath() + newTargetPath + '.' + Std.string(Preferences.saveFormat).toLowerCase();
    }

    // TODO: Make this work on browser.
    // Maybe save the images into a buffer that you can download as a zip or something? That'd work

    /* Unhide the FlxTimer here to space out the screenshot saving some more,
      though note that when the state changes any screenshots not already saved will be lost */

    new FlxTimer().start(screenShotNum + 1, function(_) {
      var pngData = encode(bitmap);

      if (pngData == null)
      {
        trace('[WARN] Failed to encode ${Preferences.saveFormat} data');
        previousScreenshotName = null;
        return;
      }
      else
      {
        trace('Saving screenshot to: ' + targetPath);
        FileUtil.writeBytesToPath(targetPath, pngData);
      }
    });
  }

  // I' m very happy with this code, all of it just works
  function saveBufferedScreenshots(screenshots:Array<Bitmap>, screenshotNames)
  {
    trace('Saving screenshot buffer');
    var i:Int = 0;

    asyncLoop = new FlxAsyncLoop(screenshots.length, () -> {
      if (screenshots[i] != null)
      {
        saveScreenshot(screenshots[i], screenshotNames[i], i);
      }
      i++;
    }, 1);
    getCurrentState().add(asyncLoop);
    if (!Preferences.flashingLights) showFancyPreview(screenshots[screenshots.length - 1]); // show the preview for the last screenshot
  }

  public function returnEncoder(saveFormat:String):Any
  {
    return switch (saveFormat)
    {
      // JPEG encoder causes the game to crash?????
      // case "JPEG": new openfl.display.JPEGEncoderOptions();
      default: new openfl.display.PNGEncoderOptions();
    }
  }

  override public function destroy():Void
  {
    if (instance == this) instance = null;

    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    FlxG.signals.gameResized.remove(this.resizeBitmap);
    FlxG.stage.removeChild(containerThing);

    super.destroy();

    if (containerThing == null) return;

    @:privateAccess
    for (parent in [containerThing, flashSprite, previewSprite])
      for (child in parent.__children)
        parent.removeChild(child);

    containerThing = null;
    flashSprite = null;
    flashBitmap = null;
    previewSprite = null;
    shotPreviewBitmap = null;
    outlineBitmap = null;
  }
}
