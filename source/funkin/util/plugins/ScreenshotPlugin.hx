package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import funkin.util.WindowUtil;
import funkin.util.logging.CrashHandler;
import flixel.addons.util.FlxAsyncLoop;
import funkin.input.Cursor;
import funkin.audio.FunkinSound;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.events.MouseEvent;
import funkin.Preferences;

/**
 * Parameters for starting the `ScreenshotPlugin`.
 */
typedef ScreenshotPluginParams =
{
  ?region:Rectangle,
};

/**
 * A Flixel plugin, which renders on top of the game, and provides the functionality
 * and visual feedback for taking screenshots.
 */
@:nullSafety
class ScreenshotPlugin extends FlxBasic
{
  /**
   * Current `ScreenshotPlugin` instance
   */
  public static var instance(get, never):ScreenshotPlugin;

  static var _instance:Null<ScreenshotPlugin> = null;

  static function get_instance():ScreenshotPlugin
  {
    if (_instance == null)
    {
      _instance = new ScreenshotPlugin({});
    }
    return _instance;
  }

  /**
   * The folder where screenshots are saved
   */
  public static final SCREENSHOT_FOLDER:String = 'screenshots';

  var region:Null<Rectangle>;

  /**
   * A signal fired before the screenshot is taken.
   */
  public var onPreScreenshot(default, null):FlxSignal;

  /**
   * A signal fired after the screenshot is taken.
   * @param bitmap The bitmap that was captured.
   */
  public var onPostScreenshot(default, null):FlxTypedSignal<Bitmap->Void>;

  static var lastWidth:Int = 0;
  static var lastHeight:Int = 0;

  var flashSprite:Sprite;
  var flashBitmap:Bitmap;
  var previewSprite:Sprite;
  var shotPreviewBitmap:Bitmap;
  var outlineBitmap:Bitmap;

  var wasMouseHidden:Bool = false; // Used for hiding and then showing the mouse
  var wasMouseShown:Bool = false; // Used for showing and then hiding the mouse
  var screenshotTakenFrame:Int = 0;

  var screenshotBeingSpammed:Bool = false;

  var screenshotSpammedTimer:Null<FlxTimer> = null;

  var screenshotBuffer:Array<Bitmap> = [];
  var screenshotNameBuffer:Array<String> = [];

  var unsavedScreenshotBuffer:Array<Bitmap> = [];
  var unsavedScreenshotNameBuffer:Array<String> = [];

  var stateChanging:Bool = false;
  var noSavingScreenshots:Bool = false;

  var flashTween:Null<FlxTween> = null;

  var previewFadeInTween:Null<FlxTween> = null;
  var previewFadeOutTween:Null<FlxTween> = null;

  var asyncLoop:Null<FlxAsyncLoop> = null;

  public function new(params:ScreenshotPluginParams)
  {
    super();

    lastWidth = FlxG.width;
    lastHeight = FlxG.height;

    flashSprite = new Sprite();
    flashSprite.alpha = 0;
    flashBitmap = new Bitmap(new BitmapData(lastWidth, lastHeight, true, Preferences.flashingLights ? FlxColor.WHITE : FlxColor.TRANSPARENT));
    flashSprite.addChild(flashBitmap);

    previewSprite = new Sprite();
    previewSprite.alpha = 0;

    outlineBitmap = new Bitmap(new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF));
    outlineBitmap.x = 5;
    outlineBitmap.y = 5;
    previewSprite.addChild(outlineBitmap);

    shotPreviewBitmap = new Bitmap();
    shotPreviewBitmap.scaleX /= 5;
    shotPreviewBitmap.scaleY /= 5;

    previewSprite.addChild(shotPreviewBitmap);
    FlxG.stage.addChild(flashSprite);

    region = params.region ?? null;

    onPreScreenshot = new FlxTypedSignal<Void->Void>();
    onPostScreenshot = new FlxTypedSignal<Bitmap->Void>();
    FlxG.signals.gameResized.add(this.resizeBitmap);
    FlxG.signals.preStateSwitch.add(this.saveUnsavedBufferedScreenshots);
    FlxG.signals.postStateSwitch.add(this.postStateSwitch);
    // Called when clicking the X button on the window.
    WindowUtil.windowExit.add(onWindowClose);

    // Called when the game crashes.
    CrashHandler.errorSignal.add(onWindowCrash);
    CrashHandler.criticalErrorSignal.add(onWindowCrash);
  }

  public override function update(elapsed:Float):Void
  {
    if (asyncLoop != null)
    {
      // If the loop hasn't started yet, start it
      if (!asyncLoop.started)
      {
        asyncLoop.start();
      }
      else
      {
        // if the loop has been started, and is finished, then we kill. it
        if (asyncLoop.finished)
        {
          if (screenshotBuffer != [])
          {
            trace("finished processing screenshot buffer");
            screenshotBuffer = [];
            screenshotNameBuffer = [];
          }
          // your honor, league of legends
          asyncLoop.kill();
          asyncLoop.destroy();
          asyncLoop = null;
        }
      }
      // Examples ftw!
    }
    super.update(elapsed);

    /**
     * This looks scary, oh no I pressed the button but no screenshot because screenshotTakenFrame != 0!
     * But if you're crazy enough to have a macro that bumps into this
     * then you're probably also going to hit 100 screenshots real fast
     */
    if (hasPressedScreenshot() && screenshotTakenFrame == 0)
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        openScreenshotsFolder();
        return; // We're only opening the screenshots folder (we don't want to accidentally take a screenshot after this)
      }
      if (Preferences.shouldHideMouse && !wasMouseHidden && FlxG.mouse.visible)
      {
        wasMouseHidden = true;
        Cursor.hide();
      }
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
      // screenshot spamming timer
      if (screenshotSpammedTimer == null || screenshotSpammedTimer.finished)
      {
        screenshotSpammedTimer = new FlxTimer().start(1, function(_) {
          // The player's stopped spamming shots, so we can stop the screenshot spam mode too
          screenshotBeingSpammed = false;
          if (screenshotBuffer[0] != null) saveBufferedScreenshots(screenshotBuffer, screenshotNameBuffer);
          if (!Preferences.fancyPreview && wasMouseHidden && !FlxG.mouse.visible)
          {
            wasMouseHidden = false;
            Cursor.show();
          }
        });
      }
      else // Pressing the screenshot key more than once every second enables the screenshot spam mode and resets the timer
      {
        screenshotBeingSpammed = true;
        screenshotSpammedTimer.reset(1);
      }
      FlxG.stage.removeChild(previewSprite);
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
    FlxG.plugins.addPlugin(new ScreenshotPlugin({}));
  }

  /**
   * @return `true` if the screenshot key is currently pressed.
   */
  public function hasPressedScreenshot():Bool
  {
    #if FEATURE_SCREENSHOTS
    return PlayerSettings.player1.controls.WINDOW_SCREENSHOT;
    #else
    return false;
    #end
  }

  function resizeBitmap(width:Int, height:Int):Void
  {
    lastWidth = width;
    lastHeight = height;
    flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, Preferences.flashingLights ? FlxColor.WHITE : FlxColor.TRANSPARENT);
    outlineBitmap.bitmapData = new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF);
  }

  /**
   * Capture the game screen as a bitmap.
   */
  public function capture():Void
  {
    onPreScreenshot.dispatch();

    var shot:Bitmap = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));
    if (screenshotBeingSpammed)
    {
      // Save the screenshots to the buffer instead
      if (screenshotBuffer.length < 100)
      {
        screenshotBuffer.push(shot);
        screenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');

        unsavedScreenshotBuffer.push(shot);
        unsavedScreenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');
      }
      else
      {
        noSavingScreenshots = true;
        throw "You've tried taking more than 100 screenshots at a time. Give the game a funkin break! Jeez. If you wanted those screenshots, well too bad!";
      }
      showCaptureFeedback();
      if (wasMouseHidden && !FlxG.mouse.visible && Preferences.flashingLights) // Just in case
      {
        wasMouseHidden = false;
        Cursor.show();
      }
      if (!Preferences.previewOnSave) showFancyPreview(shot);
    }
    else
    {
      // Save the screenshot immediately, so it doesn't get lost by a state change
      saveScreenshot(shot, 'screenshot-${DateUtil.generateTimestamp()}', 1, false);
      // Show some feedback.
      showCaptureFeedback();
      if (wasMouseHidden && !FlxG.mouse.visible)
      {
        wasMouseHidden = false;
        Cursor.show();
      }
      if (!Preferences.previewOnSave) showFancyPreview(shot);
    }
    onPostScreenshot.dispatch(shot);
  }

  static final CAMERA_FLASH_DURATION:Float = 0.25;

  /**
   * Visual and audio feedback when a screenshot is taken.
   */
  function showCaptureFeedback():Void
  {
    if (stateChanging) return; // Flash off!
    flashSprite.alpha = 1;
    FlxTween.tween(flashSprite, {alpha: 0}, 0.15);

    FunkinSound.playOnce(Paths.sound('screenshot'), 1.0);
  }

  static final PREVIEW_INITIAL_DELAY:Float = 0.25; // How long before the preview starts fading in.
  static final PREVIEW_FADE_IN_DURATION:Float = 0.3; // How long the preview takes to fade in.
  static final PREVIEW_FADE_OUT_DELAY:Float = 1.25; // How long the preview stays on screen.
  static final PREVIEW_FADE_OUT_DURATION:Float = 0.3; // How long the preview takes to fade out.

  /**
   * Show a fancy preview for the screenshot
   */
  function showFancyPreview(shot:Bitmap):Void
  {
    if (!Preferences.fancyPreview || screenshotBeingSpammed && !Preferences.flashingLights || stateChanging) return; // Sorry, the previews' been cancelled
    shotPreviewBitmap.bitmapData = shot.bitmapData;
    shotPreviewBitmap.x = outlineBitmap.x + 5;
    shotPreviewBitmap.y = outlineBitmap.y + 5;

    shotPreviewBitmap.width = outlineBitmap.width - 10;
    shotPreviewBitmap.height = outlineBitmap.height - 10;

    // Remove the existing preview
    FlxG.stage.removeChild(previewSprite);

    // ermmm stealing this??

    if (!wasMouseShown && !wasMouseHidden && !FlxG.mouse.visible)
    {
      wasMouseShown = true;
      Cursor.show();
    }

    // so that it doesnt change the alpha when tweening in/out
    var changingAlpha:Bool = false;
    var targetAlpha:Float = 1;

    // fuck it, cursed locally scoped functions, purely because im lazy
    // (and so we can check changingAlpha, which is locally scoped.... because I'm lazy...)
    var onHover:MouseEvent->Void = function(e:MouseEvent) {
      if (!changingAlpha) e.target.alpha = 0.6;
      targetAlpha = 0.6;
    };

    var onHoverOut:MouseEvent->Void = function(e:MouseEvent) {
      if (!changingAlpha) e.target.alpha = 1;
      targetAlpha = 1;
    }

    // used for movement + button stuff
    previewSprite.buttonMode = true;
    previewSprite.addEventListener(MouseEvent.MOUSE_DOWN, previewSpriteOpenScreenshotsFolder);
    previewSprite.addEventListener(MouseEvent.MOUSE_MOVE, onHover);
    previewSprite.addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

    FlxTween.cancelTweensOf(previewSprite); // Reset the tweens
    FlxG.stage.addChild(previewSprite);
    previewSprite.alpha = 0.0;
    previewSprite.y -= 10;
    // set the alpha to 0.6 if the mouse is already over the preview sprite
    if (previewSprite.hitTestPoint(previewSprite.mouseX, previewSprite.mouseY)) targetAlpha = 0.6;
    // Wait to fade in.
    new FlxTimer().start(PREVIEW_INITIAL_DELAY, function(_) {
      // Fade in.
      changingAlpha = true;
      FlxTween.tween(previewSprite, {alpha: targetAlpha, y: 0}, PREVIEW_FADE_IN_DURATION,
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
                    if (wasMouseShown && FlxG.mouse.visible)
                    {
                      wasMouseShown = false;
                      Cursor.hide();
                    }
                    else if (wasMouseHidden && !FlxG.mouse.visible)
                    {
                      wasMouseHidden = false;
                      Cursor.show();
                    }

                    previewSprite.removeEventListener(MouseEvent.MOUSE_DOWN, previewSpriteOpenScreenshotsFolder);
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

  /**
   * This is a separate function, as running the previewsprite check
   * in the other one would mean you can't open the folder when the preview's hidden, lol
   * That, and it needs a mouse event as a parameter to work.
   */
  function previewSpriteOpenScreenshotsFolder(e:MouseEvent):Void
  {
    if (previewSprite.alpha <= 0) return;
    openScreenshotsFolder();
  }

  function openScreenshotsFolder():Void
  {
    FileUtil.openFolder(SCREENSHOT_FOLDER);
  }

  // Save them, save the screenshots
  function onWindowClose(exitCode:Int):Void
  {
    if (noSavingScreenshots) return; // sike
    saveUnsavedBufferedScreenshots();
  }

  function onWindowCrash(message:String):Void
  {
    if (noSavingScreenshots) return;
    saveUnsavedBufferedScreenshots();
  }

  static function getCurrentState():FlxState
  {
    var state:FlxState = FlxG.state;
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
  function encode(bitmap:Bitmap):ByteArray
  {
    var compressor:PNGEncoderOptions = new PNGEncoderOptions();
    return bitmap.bitmapData.encode(bitmap.bitmapData.rect, compressor);
  }

  var previousScreenshotName:Null<String> = null;
  var previousScreenshotCopyNum:Int = 0;

  /**
   * Save the generated bitmap to a file.
   * @param bitmap The bitmap to save.
   * @param targetPath The name of the screenshot.
   * @param screenShotNum Used for the delay save option, to space out the saving of the images.
   * @param delaySave If true, the image gets saved with the screenShotNum as the delay.
   */
  function saveScreenshot(bitmap:Bitmap, targetPath = "image", screenShotNum:Int = 0, delaySave:Bool = true):Void
  {
    makeScreenshotPath();
    // Check that we're not overriding a previous image, and keep making a unique path until we can
    if (previousScreenshotName != targetPath && previousScreenshotName != (targetPath + ' (${previousScreenshotCopyNum})'))
    {
      previousScreenshotName = targetPath;
      targetPath = getScreenshotPath() + targetPath + '.png';
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
      targetPath = getScreenshotPath() + newTargetPath + '.png';
    }

    // TODO: Make screenshot saving work on browser.
    // Maybe save the images into a buffer that you can download as a zip or something? That'd work
    // Shouldn't be too hard to do something similar to the chart editor saving

    if (delaySave)
    { // Save the images with a delay (a timer)
      new FlxTimer().start(screenShotNum, function(_) {
        var pngData:ByteArray = encode(bitmap);

        if (pngData == null)
        {
          trace('[WARN] Failed to encode PNG data');
          previousScreenshotName = null;
          // Just in case
          unsavedScreenshotBuffer.shift();
          unsavedScreenshotNameBuffer.shift();
          return;
        }
        else
        {
          trace('Saving screenshot to: ' + targetPath);
          FileUtil.writeBytesToPath(targetPath, pngData);
          // Remove the screenshot from the unsaved buffer because we literally just saved it
          unsavedScreenshotBuffer.shift();
          unsavedScreenshotNameBuffer.shift();
          if (Preferences.previewOnSave) showFancyPreview(bitmap); // Only show the preview after a screenshot is saved
        }
      });
    }
    else // Save the screenshot immediately
    {
      var pngData:ByteArray = encode(bitmap);

      if (pngData == null)
      {
        trace('[WARN] Failed to encode PNG data');
        previousScreenshotName = null;
        return;
      }
      else
      {
        trace('Saving screenshot to: ' + targetPath);
        FileUtil.writeBytesToPath(targetPath, pngData);
        if (Preferences.previewOnSave) showFancyPreview(bitmap); // Only show the preview after a screenshot is saved
      }
    }
  }

  // I' m very happy with this code, all of it just works
  function saveBufferedScreenshots(screenshots:Array<Bitmap>, screenshotNames:Array<String>):Void
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
    if (!Preferences.flashingLights && !Preferences.previewOnSave)
    {
      showFancyPreview(screenshots[screenshots.length - 1]); // show the preview for the last screenshot
    }
  }

  /**
   * Similar to the above function, but cancels the tweens, undos the mouse
   * and doesn't have the async loop because this is called before the state changes
   */
  function saveUnsavedBufferedScreenshots():Void
  {
    stateChanging = true;
    // Cancel the tweens of the capture feedback if they're running
    if (flashSprite.alpha != 0 || previewSprite.alpha != 0)
    {
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
    }

    // Undo the mouse stuff - we don't know what the next state will do with it
    if (wasMouseShown && FlxG.mouse.visible)
    {
      wasMouseShown = false;
      Cursor.hide();
    }
    else if (wasMouseHidden && !FlxG.mouse.visible)
    {
      wasMouseHidden = false;
      Cursor.show();
    }

    if (unsavedScreenshotBuffer[0] == null) return;
    // There's unsaved screenshots, let's save them! (haha, get it?)

    trace('Saving unsaved screenshots in buffer!');

    for (i in 0...unsavedScreenshotBuffer.length)
    {
      if (unsavedScreenshotBuffer[i] != null) saveScreenshot(unsavedScreenshotBuffer[i], unsavedScreenshotNameBuffer[i], i, false);
    }

    unsavedScreenshotBuffer = [];
    unsavedScreenshotNameBuffer = [];
  }

  function postStateSwitch():Void
  {
    stateChanging = false;
    screenshotBeingSpammed = false;
    FlxG.stage.removeChild(previewSprite);
  }

  override public function destroy():Void
  {
    if (instance == this) _instance = null;

    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    FlxG.signals.gameResized.remove(this.resizeBitmap);
    FlxG.signals.preStateSwitch.remove(this.saveUnsavedBufferedScreenshots);
    FlxG.signals.postStateSwitch.remove(this.postStateSwitch);
    FlxG.stage.removeChild(previewSprite);
    FlxG.stage.removeChild(flashSprite);
    WindowUtil.windowExit.remove(onWindowClose);
    CrashHandler.errorSignal.remove(onWindowCrash);
    CrashHandler.criticalErrorSignal.remove(onWindowCrash);

    super.destroy();

    @:privateAccess
    for (parent in [flashSprite, previewSprite])
    {
      if (parent == null) continue;
      for (child in parent.__children)
      {
        parent.removeChild(child);
      }
    }

    // flashSprite = null
    // flashBitmap = null
    // previewSprite = null
    // shotPreviewBitmap = null
    // outlineBitmap = null
  }
}
