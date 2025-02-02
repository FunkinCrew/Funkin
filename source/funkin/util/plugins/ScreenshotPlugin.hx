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

typedef ScreenshotPluginParams =
{
  hotkeys:Array<FlxKey>,
  ?region:Rectangle,
  shouldHideMouse:Bool,
  flashColor:Null<FlxColor>,
  fancyPreview:Bool,
};

/**
 * What if `flixel.addons.plugin.screengrab.FlxScreenGrab` but it's better?
 * TODO: Contribute this upstream.
 */
class ScreenshotPlugin extends FlxBasic
{
  public static final SCREENSHOT_FOLDER = 'screenshots';

  var _hotkeys:Array<FlxKey>;

  var _region:Null<Rectangle>;

  var _shouldHideMouse:Bool;

  var _flashColor:Null<FlxColor>;

  var _fancyPreview:Bool;

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
  var shotDisplayBitmap:Bitmap;
  var outlineBitmap:Bitmap;

  var wasMouseHidden = false;

  var screenshotBeingSpammed:Bool = false;

  var screenshotSpammedTimer:FlxTimer;

  var screenshotBuffer:Array<Bitmap> = [];
  var screenshotNameBuffer:Array<String> = [];

  var flashTween:FlxTween;

  var previewFadeInTween:FlxTween;
  var previewFadeOutTween:FlxTween;

  public function new(params:ScreenshotPluginParams)
  {
    super();

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

    shotDisplayBitmap = new Bitmap();
    shotDisplayBitmap.scaleX /= 5;
    shotDisplayBitmap.scaleY /= 5;
    previewSprite.addChild(shotDisplayBitmap);
    containerThing.addChild(flashSprite);

    _hotkeys = params.hotkeys;
    _region = params.region ?? null;
    _shouldHideMouse = params.shouldHideMouse;
    _flashColor = params.flashColor;
    _fancyPreview = params.fancyPreview;

    onPreScreenshot = new FlxTypedSignal<Void->Void>();
    onPostScreenshot = new FlxTypedSignal<Bitmap->Void>();
    FlxG.signals.gameResized.add(this.resizeBitmap);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (hasPressedScreenshot())
    {
      if (_shouldHideMouse && !wasMouseHidden && FlxG.mouse.visible)
      {
        wasMouseHidden = true;
        // argh, even though this is happening, it's not happening fast enough before the screenshot is taken!
        // Whatever, I made the popup not show up, that's all I need
        Cursor.hide();
      }
      if (screenshotSpammedTimer == null || screenshotSpammedTimer.finished == true)
      {
        screenshotSpammedTimer = new FlxTimer().start(1, function(_) {
          containerThing.alpha = 1;
          screenshotBeingSpammed = false;
          if (screenshotBuffer[0] != null) saveBufferedScreenshots(screenshotBuffer, screenshotNameBuffer);
          if (_shouldHideMouse && wasMouseHidden && !FlxG.mouse.visible)
          {
            wasMouseHidden = false;
            Cursor.show();
          }
        });
      }
      else
      {
        screenshotBeingSpammed = true;
        containerThing.alpha = 0;
        screenshotSpammedTimer.reset(1);
      }
      capture();
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

        // TODO: Add a way to configure screenshots from the options menu.
        hotkeys: [FlxKey.F3],
        shouldHideMouse: true,
        fancyPreview: true,
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

  public function updatePreferences():Void
  {
    _flashColor = Preferences.flashingLights ? FlxColor.WHITE : null;
  }

  private function resizeBitmap(width:Int, height:Int)
  {
    lastWidth = width;
    lastHeight = height;
    flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, _flashColor);
    outlineBitmap.bitmapData = new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF);
  }

  /**
   * Defines the region of the screen that should be captured.
   * You don't need to call this method if you want to capture the entire screen, that's the default behavior.
   */
  public function defineCaptureRegion(x:Int, y:Int, width:Int, height:Int):Void
  {
    _region = new Rectangle(x, y, width, height);
  }

  /**
   * Capture the game screen as a bitmap.
   */
  public function capture():Void
  {
    onPreScreenshot.dispatch();

    var captureRegion = _region != null ? _region : new Rectangle(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);

    // The actual work.
    // var bitmap = new Bitmap(new BitmapData(Math.floor(captureRegion.width), Math.floor(captureRegion.height), true, 0x00000000)); // Create a transparent empty bitmap.
    // var drawMatrix = new Matrix(1, 0, 0, 1, -captureRegion.x, -captureRegion.y); // Modifying this will scale or skew the bitmap.
    // bitmap.bitmapData.draw(FlxG.stage, drawMatrix);
    var shot = null;
    if (containerThing.alpha == 0 && screenshotBeingSpammed == true)
    {
      // Hmm, the container is hiding, but it's still not hiding fast enough for this first spammed shot, so a timer?
      // [UH-OH!] yes! it works, finally!
      new FlxTimer().start(0.05, function(_) {
        shot = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));
        if (screenshotBuffer.length < 100)
        {
          screenshotBuffer.push(shot);
          screenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');
        }
        else
          throw "You've tried taking more than 100 screenshots at a time. Give the game a funkin break! Jeez. If you wanted those screenshots, well too bad!";
        FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
      });
    }
    else
    {
      // I wish I could have these effects and hide them too, but this works too. Hey, that rhymes!
      shot = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));
      saveScreenshot(shot, 'screenshot-${DateUtil.generateTimestamp()}');
      flashSprite.alpha = 1;
      FlxTween.tween(flashSprite, {alpha: 0}, 0.15);

      shotDisplayBitmap.bitmapData = shot.bitmapData;
      shotDisplayBitmap.x = outlineBitmap.x + 5;
      shotDisplayBitmap.y = outlineBitmap.y + 5;

      previewSprite.alpha = 1;
      FlxTween.tween(previewSprite, {alpha: 0}, 0.5, {startDelay: .5});

      if (_shouldHideMouse && wasMouseHidden && !FlxG.mouse.visible)
      {
        wasMouseHidden = false;
        Cursor.show();
      }

      FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
    }

    onPostScreenshot.dispatch(shot);
    // if (screenshotBeingSpammed == false)
    // { // Save the bitmap to a file.

    /*}
      //else // Save the screenshots to the buffer instead
      {

    }*/

    // Show some feedback.
  }

  final CAMERA_FLASH_DURATION = 0.25;

  /**
   * Visual and audio feedback when a screenshot is taken.
   */
  function showCaptureFeedback():Void
  {
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
    });*/
    // Play a sound (auto-play is true).
    FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
  }

  static final PREVIEW_INITIAL_DELAY = 0.25; // How long before the preview starts fading in.
  static final PREVIEW_FADE_IN_DURATION = 0.3; // How long the preview takes to fade in.
  static final PREVIEW_FADE_OUT_DELAY = 1.25; // How long the preview stays on screen.
  static final PREVIEW_FADE_OUT_DURATION = 0.3; // How long the preview takes to fade out.

  function showFancyPreview(bitmap:Bitmap):Void
  {
    // I just can't for the live of me get this thing to hide properly, so it's being disabled
    // I mean, steam doesn't make their screenshots this advanced anyways - Lasercar

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

  function openScreenshotsFolder(e:MouseEvent):Void
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
   * Convert a Bitmap to a PNG ByteArray to save to a file.
   */
  static function encodePNG(bitmap:Bitmap):ByteArray
  {
    return bitmap.bitmapData.encode(bitmap.bitmapData.rect, new PNGEncoderOptions());
  }

  var previousScreenshotName:String;
  var previousScreenshotCopyNum:Int;

  /**
   * Save the generated bitmap to a file.
   * @param bitmap The bitmap to save.
   */
  function saveScreenshot(bitmap:Bitmap, targetPath)
  {
    makeScreenshotPath();
    // Check that we're not overriding a previous image, and keep making a unique path until we can
    if (previousScreenshotName != targetPath)
    {
      previousScreenshotName = targetPath;
      targetPath = getScreenshotPath() + targetPath + '.png';
      previousScreenshotCopyNum = 2;
      trace(previousScreenshotName);
      trace(targetPath);
    }
    else
    {
      var newTargetPath:String = targetPath;
      while (previousScreenshotName == newTargetPath)
      {
        newTargetPath = targetPath + ' (${previousScreenshotCopyNum})';
        previousScreenshotCopyNum++;
      }
      previousScreenshotName = newTargetPath;
      targetPath = getScreenshotPath() + newTargetPath + '.png';
    }
    var pngData = encodePNG(bitmap);

    if (pngData == null)
    {
      trace('[WARN] Failed to encode PNG data.');
      previousScreenshotName = null;
      return;
    }
    else
    {
      trace('Saving screenshot to: ' + targetPath);
      // TODO: Make this work on browser.
      FileUtil.writeBytesToPath(targetPath, pngData);
    }
  }

  // If you want to do some multithreading, this'd be a great place to start, because idk how to do it - Lasercar
  function saveBufferedScreenshots(screenshots:Array<Bitmap>, screenshotNames)
  {
    trace('Saving screenshot buffer');
    // Game freeze in 3, 2, 1...
    for (i in 0...screenshots.length)
    {
      if (screenshots[i] != null) saveScreenshot(screenshots[i], screenshotNames[i]);
    }
    screenshotBuffer = [];
    screenshotNameBuffer = [];
  }
}
