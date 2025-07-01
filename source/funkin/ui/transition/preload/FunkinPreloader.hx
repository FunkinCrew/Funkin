package funkin.ui.transition.preload;

import funkin.mobile.util.ScreenUtil;
import openfl.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.Lib;
import flixel.system.FlxBasePreloader;
import funkin.util.MathUtil;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

using StringTools;

// Annotation embeds the asset in the executable for faster loading.
// Polymod can't override this, so we can't use this technique elsewhere.
#if FEATURE_TOUCH_HERE_TO_PLAY
@:bitmap('art/touchHereToPlay.png')
class TouchHereToPlayImage extends BitmapData {}
#end

/**
 * This preloader displays a VFD-esque display while the game downloads assets.
 */
class FunkinPreloader extends FlxBasePreloader
{
  /**
   * The width at the base resolution.
   * Scaled up/down appropriately as needed.
   */
  static final BASE_WIDTH:Float = 1280;

  /**
   * Margin at the sides and bottom, around the loading bar.
   */
  static final BAR_PADDING:Float = 20;

  static final BAR_HEIGHT:Int = 12;

  static final PIECES_COUNT:Int = 16;

  /**
   * Display takes this long (in seconds) to fade in.
   */
  static final FADE_TIME:Float = 2.5;

  // Ratio between window size and BASE_WIDTH
  var ratio:Float = 0;

  var currentState:FunkinPreloaderState = FunkinPreloaderState.NotStarted;

  // private var downloadingAssetsStartTime:Float = -1;
  private var downloadingAssetsPercent:Float = -1;
  private var downloadingAssetsComplete:Bool = false;

  private var preloadingPlayAssetsPercent:Float = -1;
  private var preloadingPlayAssetsStartTime:Float = -1;
  private var preloadingPlayAssetsComplete:Bool = false;

  private var cachingGraphicsPercent:Float = -1;
  private var cachingGraphicsStartTime:Float = -1;
  private var cachingGraphicsComplete:Bool = false;

  private var cachingAudioPercent:Float = -1;
  private var cachingAudioStartTime:Float = -1;
  private var cachingAudioComplete:Bool = false;

  private var cachingDataPercent:Float = -1;
  private var cachingDataStartTime:Float = -1;
  private var cachingDataComplete:Bool = false;

  private var parsingSpritesheetsPercent:Float = -1;
  private var parsingSpritesheetsStartTime:Float = -1;
  private var parsingSpritesheetsComplete:Bool = false;

  private var parsingStagesPercent:Float = -1;
  private var parsingStagesStartTime:Float = -1;
  private var parsingStagesComplete:Bool = false;

  private var parsingCharactersPercent:Float = -1;
  private var parsingCharactersStartTime:Float = -1;
  private var parsingCharactersComplete:Bool = false;

  private var parsingSongsPercent:Float = -1;
  private var parsingSongsStartTime:Float = -1;
  private var parsingSongsComplete:Bool = false;

  private var initializingScriptsPercent:Float = -1;

  private var cachingCoreAssetsPercent:Float = -1;

  /**
   * The timestamp when the other steps completed and the `Finishing up` step started.
   */
  private var completeTime:Float = -1;

  // Graphics
  #if FEATURE_TOUCH_HERE_TO_PLAY
  var touchHereToPlay:Bitmap;
  var touchHereSprite:Sprite;
  #end
  var progressBarPieces:Array<Sprite>;
  var progressLeftText:TextField;
  var progressRightText:TextField;

  var dspText:TextField;
  var fnfText:TextField;
  var enhancedText:TextField;
  var stereoText:TextField;

  var vfdShader:VFDOverlay;
  var vfdBitmap:Bitmap;
  var rTextGroup:Sprite;
  var progressLines:Sprite;

  public function new()
  {
    super(Constants.PRELOADER_MIN_STAGE_TIME);

    // We can't even call trace() yet, until Flixel loads.
    trace('Initializing custom preloader...');
  }

  override function create():Void
  {
    // Nothing happens in the base preloader.
    super.create();

    // Background color.
    Lib.current.stage.color = Constants.COLOR_PRELOADER_BG;

    // Width and height of the preloader.
    // Reference: Mobile resolution actually spits out smaller number
    // this._width is 893 on iPhone 14 Pro
    // and this._height is 393
    // so a few lines lower
    // ratio = 893 / 1280 / 2.0 = ~0.3 on iPhone
    // ratio = 1280 / 1280 / 2.0 = 0.5 on desktop
    // However on Android, this._width/_height are the devices actual resolution.
    this._width = Lib.current.stage.stageWidth;
    this._height = Lib.current.stage.stageHeight;

    trace('Preloader size: ' + this._width + 'x' + this._height);

    // Scale assets to the screen size.
    // Desktop is always 1:1 scale, mobile needs DPI normalization for consistent positioning
    #if mobile
    var display = lime.system.System.getDisplay(0);
    var dpiScale = display.dpi / 160.0; // 160 is Android's baseline DPI
    var normalizedWidth = this._width / dpiScale;
    ratio = normalizedWidth / BASE_WIDTH;
    #else
    ratio = 1.0; // Desktop is always 1:1 scale
    #end

    progressBarPieces = [];
    var maxBarWidth:Float = this._width - BAR_PADDING * 2;
    var pieceWidth:Float = maxBarWidth / PIECES_COUNT;
    var pieceGap:Int = 8;

    progressLines = new openfl.display.Sprite();
    progressLines.graphics.lineStyle(2, Constants.COLOR_PRELOADER_BAR);
    progressLines.graphics.drawRect(-2, 0, this._width + 4, 30);
    progressLines.y = this._height * 0.67;
    addChild(progressLines);

    for (i in 0...PIECES_COUNT)
    {
      var piece:Sprite = new Sprite();
      piece.graphics.beginFill(Constants.COLOR_PRELOADER_BAR);
      piece.graphics.drawRoundRect(0, 0, pieceWidth - pieceGap, BAR_HEIGHT, 4, 4);
      piece.graphics.endFill();

      piece.x = i * (piece.width + pieceGap);
      piece.y = progressLines.y + 8;
      addChild(piece);
      progressBarPieces.push(piece);
    }

    // Create the progress message.

    var progressLeftTextFormat:TextFormat = new TextFormat("DS-Digital", Std.int(32 * ratio), Constants.COLOR_PRELOADER_BAR, true);
    progressLeftTextFormat.align = TextFormatAlign.LEFT;
    var progressRightTextFormat:TextFormat = new TextFormat("DS-Digital", 16, Constants.COLOR_PRELOADER_BAR, true);
    progressRightTextFormat.align = TextFormatAlign.RIGHT;

    progressLeftText = makeText(BAR_PADDING * ratio, progressLines.y, 'Downloading assets...', Constants.COLOR_PRELOADER_BAR);
    progressLeftText.defaultTextFormat = progressLeftTextFormat;
    progressLeftText.width = this._width - BAR_PADDING * 2;
    addChild(progressLeftText);
    progressLeftText.y -= (progressLeftText.textHeight / ratio) * 2.5;

    if (!isLandscapeFlipped()) progressLeftText.x += ScreenUtil.getNotchRect().width * ratio;

    // Create the progress % in the bottom right
    // This displays in the bottom right corner, so it's generally safe from notches...
    // but we should do a sweep online to make sure that there's no hole-punch style cameras on android that may block this
    progressRightText = makeText(BAR_PADDING, this._height - BAR_PADDING - BAR_HEIGHT - 16 - 4, '0%', Constants.COLOR_PRELOADER_BAR);
    progressRightText.defaultTextFormat = progressRightTextFormat;
    addChild(progressRightText);

    // note: on mobile we generally dont want to scale these texts down
    // however should test on android + iPad to see how it fits!
    rTextGroup = new Sprite();
    rTextGroup.graphics.beginFill(Constants.COLOR_PRELOADER_BAR, 1);
    rTextGroup.graphics.drawRoundRect(0, 40, 64, 20, 5, 5);
    rTextGroup.graphics.drawRoundRect(70, 40, 58, 20, 5, 5);
    rTextGroup.graphics.endFill();
    rTextGroup.graphics.beginFill(Constants.COLOR_PRELOADER_BAR, 0.1);
    rTextGroup.graphics.drawRoundRect(0, 40, 128, 20, 5, 5);
    rTextGroup.graphics.endFill();
    rTextGroup.x = this._width * 0.64;
    rTextGroup.y = progressLeftText.y;
    addChild(rTextGroup);

    dspText = makeText(10, 33, 'DSP', 0x000000);
    dspText.width = this._width;
    dspText.height = 30;
    rTextGroup.addChild(dspText);

    fnfText = makeText(78, 33, 'FNF', 0x000000);
    fnfText.width = this._width;
    fnfText.height = 30;
    rTextGroup.addChild(fnfText);

    enhancedText = makeText(-100, 40, 'ENHANCED', Constants.COLOR_PRELOADER_BAR);
    enhancedText.width = this._width;
    enhancedText.height = 100;
    rTextGroup.addChild(enhancedText);

    stereoText = makeText(0, 0, 'STEREO', Constants.COLOR_PRELOADER_BAR);
    stereoText.width = this._width;
    stereoText.height = 100;
    rTextGroup.addChild(stereoText);

    // todo: check if these actually overlap the notch with some rect check thing
    // im making more sweeping assumptions rn because i only have iOS
    if (isLandscapeFlipped()) rTextGroup.x -= ScreenUtil.getNotchRect().width * ratio;

    vfdBitmap = new Bitmap(new BitmapData(this._width, this._height, true, 0xFFFFFFFF));
    addChild(vfdBitmap);

    vfdShader = new VFDOverlay();
    vfdBitmap.shader = vfdShader;

    #if FEATURE_TOUCH_HERE_TO_PLAY
    touchHereToPlay = createBitmap(TouchHereToPlayImage, function(bmp:Bitmap) {
      // Scale and center the touch to start image.
      // We have to do this inside the async call, after the image size is known.
      bmp.scaleX = bmp.scaleY = ratio;
      bmp.x = (this._width - bmp.width) / 2;
      bmp.y = (this._height - bmp.height) / 2;
    });
    touchHereToPlay.alpha = 0.0;

    touchHereSprite = new Sprite();
    touchHereSprite.buttonMode = false;
    touchHereSprite.addChild(touchHereToPlay);
    addChild(touchHereSprite);
    #end
  }

  function makeText(txtX:Float, txtY:Float, txt:String, color:Int):TextField
  {
    var text:TextField = new TextField();
    text.selectable = false;
    text.width = this._width - BAR_PADDING * 2;
    text.x = txtX;
    text.y = txtY;
    text.text = txt;
    text.textColor = color;
    return text;
  }

  var lastElapsed:Float = 0.0;

  override function update(percent:Float):Void
  {
    var elapsed:Float = (Date.now().getTime() - this._startTime) / 1000.0;

    vfdShader.update(elapsed * 100);

    downloadingAssetsPercent = percent;
    var loadPercent:Float = updateState(percent, elapsed);
    updateGraphics(loadPercent, elapsed);

    lastElapsed = elapsed;
  }

  function updateState(percent:Float, elapsed:Float):Float
  {
    switch (currentState)
    {
      case FunkinPreloaderState.NotStarted:
        if (downloadingAssetsPercent > 0.0) currentState = FunkinPreloaderState.DownloadingAssets;

        return percent;

      case FunkinPreloaderState.DownloadingAssets:
        // Sometimes percent doesn't go to 100%, it's a floating point error.
        if (downloadingAssetsPercent >= 1.0
          || (elapsed > Constants.PRELOADER_MIN_STAGE_TIME
            && downloadingAssetsComplete)) currentState = FunkinPreloaderState.PreloadingPlayAssets;

        return percent;

      case FunkinPreloaderState.PreloadingPlayAssets:
        if (preloadingPlayAssetsPercent < 0.0)
        {
          preloadingPlayAssetsStartTime = elapsed;
          preloadingPlayAssetsPercent = 0.0;

          // This is quick enough to do synchronously.
          // Assets.initialize();

          /*
            // Make a future to retrieve the manifest
            var future:Future<lime.utils.AssetLibrary> = Assets.preloadLibrary('gameplay');

            future.onProgress((loaded:Int, total:Int) -> {
              preloadingPlayAssetsPercent = loaded / total;
            });
            future.onComplete((library:lime.utils.AssetLibrary) -> {
            });
           */

          // TODO: Reimplement this.
          preloadingPlayAssetsPercent = 1.0;
          preloadingPlayAssetsComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedPreloadingPlayAssets:Float = elapsed - preloadingPlayAssetsStartTime;
          if (preloadingPlayAssetsComplete && elapsedPreloadingPlayAssets >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.InitializingScripts;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (preloadingPlayAssetsPercent < (elapsedPreloadingPlayAssets / Constants.PRELOADER_MIN_STAGE_TIME)) return preloadingPlayAssetsPercent;
            else
              return elapsedPreloadingPlayAssets / Constants.PRELOADER_MIN_STAGE_TIME;
          }
        }
        else
        {
          if (preloadingPlayAssetsComplete) currentState = FunkinPreloaderState.InitializingScripts;
        }

        return preloadingPlayAssetsPercent;

      case FunkinPreloaderState.InitializingScripts:
        if (initializingScriptsPercent < 0.0)
        {
          initializingScriptsPercent = 0.0;

          /*
            var future:Future<Array<String>> = []; // PolymodHandler.loadNoModsAsync();

            future.onProgress((loaded:Int, total:Int) -> {
              trace('PolymodHandler.loadNoModsAsync() progress: ' + loaded + '/' + total);
              initializingScriptsPercent = loaded / total;
            });
            future.onComplete((result:Array<String>) -> {
              trace('Completed initializing scripts: ' + result);
            });
           */

          initializingScriptsPercent = 1.0;
          currentState = FunkinPreloaderState.CachingGraphics;
          return 0.0;
        }

        return initializingScriptsPercent;

      case CachingGraphics:
        if (cachingGraphicsPercent < 0)
        {
          cachingGraphicsPercent = 0.0;
          cachingGraphicsStartTime = elapsed;

          /*
            var assetsToCache:Array<String> = []; // Assets.listGraphics('core');

            var future:Future<Array<String>> = []; // Assets.cacheAssets(assetsToCache);
            future.onProgress((loaded:Int, total:Int) -> {
              cachingGraphicsPercent = loaded / total;
            });
            future.onComplete((_result) -> {
              trace('Completed caching graphics.');
            });
           */

          // TODO: Reimplement this.
          cachingGraphicsPercent = 1.0;
          cachingGraphicsComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingGraphics:Float = elapsed - cachingGraphicsStartTime;
          if (cachingGraphicsComplete && elapsedCachingGraphics >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.CachingAudio;
            return 0.0;
          }
          else
          {
            if (cachingGraphicsPercent < (elapsedCachingGraphics / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              // Return real progress if it's lower.
              return cachingGraphicsPercent;
            }
            else
            {
              // Return simulated progress if it's higher.
              return elapsedCachingGraphics / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (cachingGraphicsComplete)
          {
            currentState = FunkinPreloaderState.CachingAudio;
            return 0.0;
          }
          else
          {
            return cachingGraphicsPercent;
          }
        }

      case CachingAudio:
        if (cachingAudioPercent < 0)
        {
          cachingAudioPercent = 0.0;
          cachingAudioStartTime = elapsed;

          var assetsToCache:Array<String> = []; // Assets.listSound('core');

          /*
            var future:Future<Array<String>> = []; // Assets.cacheAssets(assetsToCache);

            future.onProgress((loaded:Int, total:Int) -> {
              cachingAudioPercent = loaded / total;
            });
            future.onComplete((_result) -> {
              trace('Completed caching audio.');
            });
           */

          // TODO: Reimplement this.
          cachingAudioPercent = 1.0;
          cachingAudioComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingAudio:Float = elapsed - cachingAudioStartTime;
          if (cachingAudioComplete && elapsedCachingAudio >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.CachingData;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (cachingAudioPercent < (elapsedCachingAudio / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              return cachingAudioPercent;
            }
            else
            {
              return elapsedCachingAudio / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (cachingAudioComplete)
          {
            currentState = FunkinPreloaderState.CachingData;
            return 0.0;
          }
          else
          {
            return cachingAudioPercent;
          }
        }

      case CachingData:
        if (cachingDataPercent < 0)
        {
          cachingDataPercent = 0.0;
          cachingDataStartTime = elapsed;

          var assetsToCache:Array<String> = [];
          var sparrowFramesToCache:Array<String> = [];

          // Core files
          // assetsToCache = assetsToCache.concat(Assets.listText('core'));
          // assetsToCache = assetsToCache.concat(Assets.listJSON('core'));
          // Core spritesheets
          // assetsToCache = assetsToCache.concat(Assets.listXML('core'));

          // Gameplay files
          // assetsToCache = assetsToCache.concat(Assets.listText('gameplay'));
          // assetsToCache = assetsToCache.concat(Assets.listJSON('gameplay'));
          // We're not caching gameplay spritesheets here because they're fetched on demand.

          /*
            var future:Future<Array<String>> = [];
            // Assets.cacheAssets(assetsToCache, true);
            future.onProgress((loaded:Int, total:Int) -> {
              cachingDataPercent = loaded / total;
            });
            future.onComplete((_result) -> {
              trace('Completed caching data.');
            });
           */
          cachingDataPercent = 1.0;
          cachingDataComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingData:Float = elapsed - cachingDataStartTime;
          if (cachingDataComplete && elapsedCachingData >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.ParsingSpritesheets;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (cachingDataPercent < (elapsedCachingData / Constants.PRELOADER_MIN_STAGE_TIME)) return cachingDataPercent;
            else
              return elapsedCachingData / Constants.PRELOADER_MIN_STAGE_TIME;
          }
        }
        else
        {
          if (cachingDataComplete)
          {
            currentState = FunkinPreloaderState.ParsingSpritesheets;
            return 0.0;
          }
        }

        return cachingDataPercent;

      case ParsingSpritesheets:
        if (parsingSpritesheetsPercent < 0)
        {
          parsingSpritesheetsPercent = 0.0;
          parsingSpritesheetsStartTime = elapsed;

          // Core spritesheets
          var sparrowFramesToCache = []; // Assets.listXML('core').map((xml:String) -> xml.replace('.xml', '').replace('core:assets/core/', ''));
          // We're not caching gameplay spritesheets here because they're fetched on demand.

          /*
            var future:Future<Array<String>> = []; // Assets.cacheSparrowFrames(sparrowFramesToCache, true);
            future.onProgress((loaded:Int, total:Int) -> {
              parsingSpritesheetsPercent = loaded / total;
            });
            future.onComplete((_result) -> {
              trace('Completed parsing spritesheets.');
            });
           */
          parsingSpritesheetsPercent = 1.0;
          parsingSpritesheetsComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedParsingSpritesheets:Float = elapsed - parsingSpritesheetsStartTime;
          if (parsingSpritesheetsComplete && elapsedParsingSpritesheets >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.ParsingStages;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (parsingSpritesheetsPercent < (elapsedParsingSpritesheets / Constants.PRELOADER_MIN_STAGE_TIME)) return parsingSpritesheetsPercent;
            else
              return elapsedParsingSpritesheets / Constants.PRELOADER_MIN_STAGE_TIME;
          }
        }
        else
        {
          if (parsingSpritesheetsComplete)
          {
            currentState = FunkinPreloaderState.ParsingStages;
            return 0.0;
          }
        }

        return parsingSpritesheetsPercent;

      case ParsingStages:
        if (parsingStagesPercent < 0)
        {
          parsingStagesPercent = 0.0;
          parsingStagesStartTime = elapsed;

          /*
            // TODO: Reimplement this.
            var future:Future<Array<String>> = []; // StageDataParser.loadStageCacheAsync();

            future.onProgress((loaded:Int, total:Int) -> {
              parsingStagesPercent = loaded / total;
            });

            future.onComplete((_result) -> {
              trace('Completed parsing stages.');
            });
           */

          parsingStagesPercent = 1.0;
          parsingStagesComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedParsingStages:Float = elapsed - parsingStagesStartTime;
          if (parsingStagesComplete && elapsedParsingStages >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.ParsingCharacters;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (parsingStagesPercent < (elapsedParsingStages / Constants.PRELOADER_MIN_STAGE_TIME)) return parsingStagesPercent;
            else
              return elapsedParsingStages / Constants.PRELOADER_MIN_STAGE_TIME;
          }
        }
        else
        {
          if (parsingStagesComplete)
          {
            currentState = FunkinPreloaderState.ParsingCharacters;
            return 0.0;
          }
        }

        return parsingStagesPercent;

      case ParsingCharacters:
        if (parsingCharactersPercent < 0)
        {
          parsingCharactersPercent = 0.0;
          parsingCharactersStartTime = elapsed;

          /*
            // TODO: Reimplement this.
            var future:Future<Array<String>> = []; // CharacterDataParser.loadCharacterCacheAsync();

            future.onProgress((loaded:Int, total:Int) -> {
              parsingCharactersPercent = loaded / total;
            });

            future.onComplete((_result) -> {
              trace('Completed parsing characters.');
            });
           */

          parsingCharactersPercent = 1.0;
          parsingCharactersComplete = true;
          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedParsingCharacters:Float = elapsed - parsingCharactersStartTime;
          if (parsingCharactersComplete && elapsedParsingCharacters >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.ParsingSongs;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (parsingCharactersPercent < (elapsedParsingCharacters / Constants.PRELOADER_MIN_STAGE_TIME)) return parsingCharactersPercent;
            else
              return elapsedParsingCharacters / Constants.PRELOADER_MIN_STAGE_TIME;
          }
        }
        else
        {
          if (parsingStagesComplete)
          {
            currentState = FunkinPreloaderState.ParsingSongs;
            return 0.0;
          }
        }

        return parsingCharactersPercent;

      case ParsingSongs:
        if (parsingSongsPercent < 0)
        {
          parsingSongsPercent = 0.0;
          parsingSongsStartTime = elapsed;

          /*
            // TODO: Reimplement this.
            var future:Future<Array<String>> = ;
            // SongDataParser.loadSongCacheAsync();

            future.onProgress((loaded:Int, total:Int) -> {
              parsingSongsPercent = loaded / total;
            });

            future.onComplete((_result) -> {
              trace('Completed parsing songs.');
            });
           */

          parsingSongsPercent = 1.0;
          parsingSongsComplete = true;

          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedParsingSongs:Float = elapsed - parsingSongsStartTime;
          if (parsingSongsComplete && elapsedParsingSongs >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = FunkinPreloaderState.Complete;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (parsingSongsPercent < (elapsedParsingSongs / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              return parsingSongsPercent;
            }
            else
            {
              return elapsedParsingSongs / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (parsingSongsComplete)
          {
            currentState = FunkinPreloaderState.Complete;
            return 0.0;
          }
          else
          {
            return parsingSongsPercent;
          }
        }
      case FunkinPreloaderState.Complete:
        if (completeTime < 0)
        {
          completeTime = elapsed;
        }

        return 1.0;
      #if FEATURE_TOUCH_HERE_TO_PLAY
      case FunkinPreloaderState.TouchHereToPlay:
        if (completeTime < 0)
        {
          completeTime = elapsed;
        }

        if (touchHereToPlay.alpha < 1.0)
        {
          touchHereSprite.buttonMode = true;
          touchHereToPlay.alpha = 1.0;
          removeChild(vfdBitmap);

          addEventListener(MouseEvent.CLICK, onTouchHereToPlay);
          touchHereSprite.addEventListener(MouseEvent.MOUSE_OVER, overTouchHereToPlay);
          touchHereSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);
          touchHereSprite.addEventListener(MouseEvent.MOUSE_OUT, outTouchHereToPlay);
        }

        return 1.0;
      #end

      default:
        // Do nothing.
    }

    return 0.0;
  }

  #if FEATURE_TOUCH_HERE_TO_PLAY
  function overTouchHereToPlay(e:MouseEvent):Void
  {
    touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio * 1.1;
    touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
    touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
  }

  function outTouchHereToPlay(e:MouseEvent):Void
  {
    touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio * 1;
    touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
    touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
  }

  function mouseDownTouchHereToPlay(e:MouseEvent):Void
  {
    touchHereToPlay.y += 10;
  }

  function onTouchHereToPlay(e:MouseEvent):Void
  {
    touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
    touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;

    removeEventListener(MouseEvent.CLICK, onTouchHereToPlay);
    touchHereSprite.removeEventListener(MouseEvent.MOUSE_OVER, overTouchHereToPlay);
    touchHereSprite.removeEventListener(MouseEvent.MOUSE_OUT, outTouchHereToPlay);
    touchHereSprite.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);

    // This is the actual thing that makes the game load.
    immediatelyStartGame();
  }
  #end

  public static final TOTAL_STEPS:Int = 11;
  static final ELLIPSIS_TIME:Float = 0.5;

  function updateGraphics(percent:Float, elapsed:Float):Void
  {
    // Render display (including transition out)
    if (completeTime > 0.0)
    {
      var elapsedFinished:Float = renderDisplayFadeOut(elapsed);
      if (elapsedFinished > FADE_TIME)
      {
        #if FEATURE_TOUCH_HERE_TO_PLAY
        // The display has faded out, but we're not quite done yet.
        // In order to prevent autoplay issues, we need the user to click after the loading finishes.
        currentState = FunkinPreloaderState.TouchHereToPlay;
        #else
        immediatelyStartGame();
        #end
      }
    }
    else
    {
      // Render progress bar
      var piecesToRender:Int = Std.int(percent * progressBarPieces.length);

      for (i => piece in progressBarPieces)
        piece.alpha = i <= piecesToRender ? 0.9 : 0.1;
    }

    // Cycle ellipsis count to show loading
    var ellipsisCount:Int = Std.int(elapsed / ELLIPSIS_TIME) % 3 + 1;
    var ellipsis:String = '';
    for (_ in 0...ellipsisCount)
      ellipsis += '.';

    // Render status text
    updateProgressLeftText(currentState.getProgressLeftText(TOTAL_STEPS, ellipsis));

    // Render percent text
    var percentage:Int = Math.floor(percent * 100);
    progressRightText.text = '$percentage%';

    if (currentState.getProgressLeftText() != null) trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');

    super.update(percent);
  }

  function updateProgressLeftText(text:Null<String>):Void
  {
    if (progressLeftText == null) return;

    if (text == null) progressLeftText.alpha = 0.0;
    else if (progressLeftText.text != text)
    {
      // We have to keep updating the text format, because the font can take a frame or two to load.
      progressLeftText.defaultTextFormat = new TextFormat("DS-Digital", 32, Constants.COLOR_PRELOADER_BAR, true);
      progressLeftText.defaultTextFormat.align = TextFormatAlign.LEFT;
      progressLeftText.text = text;

      dspText.defaultTextFormat = new TextFormat("Quantico", 20, 0x000000, false);
      dspText.text = 'DSP'; // fukin dum....
      dspText.textColor = 0x000000;

      fnfText.defaultTextFormat = new TextFormat("Quantico", 20, 0x000000, false);
      fnfText.text = 'FNF';
      fnfText.textColor = 0x000000;

      enhancedText.defaultTextFormat = new TextFormat("Inconsolata Black", 16, Constants.COLOR_PRELOADER_BAR, false);
      enhancedText.text = 'ENHANCED';
      enhancedText.textColor = Constants.COLOR_PRELOADER_BAR;

      stereoText.defaultTextFormat = new TextFormat("Inconsolata Bold", 36, Constants.COLOR_PRELOADER_BAR, false);
      stereoText.text = 'NATURAL STEREO';
    }
  }

  /**
   * Whether or not we are in flipped landscape device rotation,
   * generally for mobile to accomodate the device notch!
   * @return Bool
   */
  function isLandscapeFlipped():Bool
  {
    return lime.system.System.getDisplayOrientation(0) == DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED;
  }

  function immediatelyStartGame():Void
  {
    _loaded = true;
  }

  /**
   * Fade out the VFD display pieces.
   * @param	elapsed Elapsed time since the preloader started.
   * @return	Elapsed time since the preloader pieces started fading out.
   */
  function renderDisplayFadeOut(elapsed:Float):Float
  {
    // Fade-out takes FADE_TIME seconds.
    var elapsedFinished:Float = elapsed - completeTime;
    var alphaToFade:Float = 1.0 - MathUtil.easeInOutCirc(elapsedFinished / FADE_TIME);

    // Fade out progress bar too.
    progressLeftText.alpha = alphaToFade;
    progressRightText.alpha = alphaToFade;
    rTextGroup.alpha = alphaToFade;
    progressLines.alpha = alphaToFade;

    for (piece in progressBarPieces)
      piece.alpha = alphaToFade;

    return elapsedFinished;
  }

  override function destroy():Void
  {
    // Ensure the graphics are properly destroyed and GC'd.
    super.destroy();
  }

  override function onLoaded():Void
  {
    super.onLoaded();
    // We're not ACTUALLY finished.
    // This function gets called when the DownloadingAssets step is done.
    // We need to wait for the other steps, then the display to fade out.
    _loaded = false;
    downloadingAssetsComplete = true;
  }
}

enum abstract FunkinPreloaderState(String) to String
{
  /**
   * The state before downloading has begun.
   * Moves to either `DownloadingAssets` or `CachingGraphics` based on platform.
   */
  var NotStarted;

  /**
   * Downloading assets.
   * On HTML5, Lime will do this for us, before calling `onLoaded`.
   * On Native, this step will be completed immediately, and we'll go straight to `CachingGraphics`.
   */
  var DownloadingAssets;

  /**
   * Preloading play assets.
   * Loads the `manifest.json` for the `gameplay` library.
   * If we make the base preloader do this, it will download all the assets as well,
   * so we have to do it ourselves.
   */
  var PreloadingPlayAssets;

  /**
   * Loading FireTongue, loading Polymod, parsing and instantiating module scripts.
   */
  var InitializingScripts;

  /**
   * Loading all graphics from the `core` library to the cache.
   */
  var CachingGraphics;

  /**
   * Loading all audio from the `core` library to the cache.
   */
  var CachingAudio;

  /**
   * Loading all data files from the `core` library to the cache.
   */
  var CachingData;

  /**
   * Parsing all XML files from the `core` library into FlxFramesCollections and caching them.
   */
  var ParsingSpritesheets;

  /**
   * Parsing stage data and scripts.
   */
  var ParsingStages;

  /**
   * Parsing character data and scripts.
   */
  var ParsingCharacters;

  /**
   * Parsing song data and scripts.
   */
  var ParsingSongs;

  /**
   * Finishing up.
   */
  var Complete;

  #if FEATURE_TOUCH_HERE_TO_PLAY
  /**
   * Touch Here to Play is displayed.
   */
  var TouchHereToPlay;
  #end

  /**
   * Formats the status text for progress bar display.
   * @param steps The total number of steps. Defaults to `FunkinPreloader.TOTAL_STEPS`.
   * @param suffix What to append to the end of the text, usually those dynamic ellipsis. Defaults to an empty string.
   * @return String 'Loading \n0/$steps $suffix' for example
   */
  public function getProgressLeftText(?steps:Int, ?suffix:String):String
  {
    steps = steps ?? FunkinPreloader.TOTAL_STEPS;
    suffix = suffix ?? '';
    switch (this)
    {
      case NotStarted:
        return 'Loading \n0/$steps $suffix';
      case DownloadingAssets:
        return 'Downloading assets \n1/$steps $suffix';
      case PreloadingPlayAssets:
        return 'Preloading assets \n2/$steps $suffix';
      case InitializingScripts:
        return 'Initializing scripts \n3/$steps $suffix';
      case CachingGraphics:
        return 'Caching graphics \n4/$steps $suffix';
      case CachingAudio:
        return 'Caching audio \n5/$steps $suffix';
      case CachingData:
        return 'Caching data \n6/$steps $suffix';
      case ParsingSpritesheets:
        return 'Parsing spritesheets \n7/$steps $suffix';
      case ParsingStages:
        return 'Parsing stages \n8/$steps $suffix';
      case ParsingCharacters:
        return 'Parsing characters \n9/$steps $suffix';
      case ParsingSongs:
        return 'Parsing songs \n10/$steps $suffix';
      case Complete:
        return 'Finishing up \n$steps/$steps $suffix';
      #if FEATURE_TOUCH_HERE_TO_PLAY
      case TouchHereToPlay:
        return null; // return null here to hide the text
      #end
      default:
        return null;
    }
  }
}
