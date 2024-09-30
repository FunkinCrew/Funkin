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

  public function new(params:ScreenshotPluginParams)
  {
    super();

    _hotkeys = params.hotkeys;
    _region = params.region ?? null;
    _shouldHideMouse = params.shouldHideMouse;
    _flashColor = params.flashColor;
    _fancyPreview = params.fancyPreview;

    onPreScreenshot = new FlxTypedSignal<Void->Void>();
    onPostScreenshot = new FlxTypedSignal<Bitmap->Void>();
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (hasPressedScreenshot())
    {
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
        shouldHideMouse: false,
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

    var wasMouseHidden = false;
    if (_shouldHideMouse && FlxG.mouse.visible)
    {
      wasMouseHidden = true;
      Cursor.hide();
    }

    // The actual work.
    // var bitmap = new Bitmap(new BitmapData(Math.floor(captureRegion.width), Math.floor(captureRegion.height), true, 0x00000000)); // Create a transparent empty bitmap.
    // var drawMatrix = new Matrix(1, 0, 0, 1, -captureRegion.x, -captureRegion.y); // Modifying this will scale or skew the bitmap.
    // bitmap.bitmapData.draw(FlxG.stage, drawMatrix);
    var bitmap = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));

    if (wasMouseHidden)
    {
      Cursor.show();
    }

    // Save the bitmap to a file.
    saveScreenshot(bitmap);

    // Show some feedback.
    showCaptureFeedback();
    if (_fancyPreview)
    {
      showFancyPreview(bitmap);
    }

    onPostScreenshot.dispatch(bitmap);
  }

  final CAMERA_FLASH_DURATION = 0.25;

  /**
   * Visual and audio feedback when a screenshot is taken.
   */
  function showCaptureFeedback():Void
  {
    var flashBitmap = new Bitmap(new BitmapData(Std.int(FlxG.stage.width), Std.int(FlxG.stage.height), false, 0xFFFFFFFF));
    var flashSpr = new Sprite();
    flashSpr.addChild(flashBitmap);
    FlxG.stage.addChild(flashSpr);
    FlxTween.tween(flashSpr, {alpha: 0}, 0.15, {ease: FlxEase.quadOut, onComplete: _ -> FlxG.stage.removeChild(flashSpr)});

    // Play a sound (auto-play is true).
    FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
  }

  static final PREVIEW_INITIAL_DELAY = 0.25; // How long before the preview starts fading in.
  static final PREVIEW_FADE_IN_DURATION = 0.3; // How long the preview takes to fade in.
  static final PREVIEW_FADE_OUT_DELAY = 1.25; // How long the preview stays on screen.
  static final PREVIEW_FADE_OUT_DURATION = 0.3; // How long the preview takes to fade out.

  function showFancyPreview(bitmap:Bitmap):Void
  {
    // ermmm stealing this??
    var wasMouseHidden = false;
    if (!FlxG.mouse.visible)
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

    var scale:Float = 0.25;
    var w:Int = Std.int(bitmap.bitmapData.width * scale);
    var h:Int = Std.int(bitmap.bitmapData.height * scale);

    var preview:BitmapData = new BitmapData(w, h, true);
    var matrix:openfl.geom.Matrix = new openfl.geom.Matrix();
    matrix.scale(scale, scale);
    preview.draw(bitmap.bitmapData, matrix);

    // used for movement + button stuff
    var previewSprite = new Sprite();

    previewSprite.buttonMode = true;
    previewSprite.addEventListener(MouseEvent.MOUSE_DOWN, openScreenshotsFolder);
    previewSprite.addEventListener(MouseEvent.MOUSE_OVER, onHover);
    previewSprite.addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

    FlxG.stage.addChild(previewSprite);

    previewSprite.alpha = 0.0;
    previewSprite.y -= 10;

    var previewBitmap = new Bitmap(preview);
    previewSprite.addChild(previewBitmap);

    // Wait to fade in.
    new FlxTimer().start(PREVIEW_INITIAL_DELAY, function(_) {
      // Fade in.
      changingAlpha = true;
      FlxTween.tween(previewSprite, {alpha: 1.0, y: 0}, PREVIEW_FADE_IN_DURATION,
        {
          ease: FlxEase.quartOut,
          onComplete: function(_) {
            changingAlpha = false;
            // Wait to fade out.
            new FlxTimer().start(PREVIEW_FADE_OUT_DELAY, function(_) {
              changingAlpha = true;
              // Fade out.
              FlxTween.tween(previewSprite, {alpha: 0.0, y: 10}, PREVIEW_FADE_OUT_DURATION,
                {
                  ease: FlxEase.quartInOut,
                  onComplete: function(_) {
                    if (wasMouseHidden)
                    {
                      Cursor.hide();
                    }

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
    return '$SCREENSHOT_FOLDER/screenshot-${DateUtil.generateTimestamp()}.png';
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

  /**
   * Save the generated bitmap to a file.
   * @param bitmap The bitmap to save.
   */
  static function saveScreenshot(bitmap:Bitmap)
  {
    makeScreenshotPath();
    var targetPath:String = getScreenshotPath();

    var pngData = encodePNG(bitmap);

    if (pngData == null)
    {
      trace('[WARN] Failed to encode PNG data.');
      return;
    }
    else
    {
      trace('Saving screenshot to: ' + targetPath);
      // TODO: Make this work on browser.
      FileUtil.writeBytesToPath(targetPath, pngData);
    }
  }
}
