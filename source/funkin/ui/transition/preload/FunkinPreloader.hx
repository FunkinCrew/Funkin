package funkin.ui.transition.preload;

import openfl.filters.GlowFilter;
import openfl.display.SpreadMethod;
import openfl.display.GradientType;
import openfl.geom.Matrix;
import openfl.filters.BlurFilter;
import openfl.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.Lib;
import flixel.system.FlxBasePreloader;
import funkin.modding.PolymodHandler;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.util.MathUtil;
import lime.app.Future;
import lime.math.Rectangle;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

using StringTools;

// Annotation embeds the asset in the executable for faster loading.
// Polymod can't override this, so we can't use this technique elsewhere.

@:bitmap("art/preloaderArt.png")
class LogoImage extends BitmapData {}

#if TOUCH_HERE_TO_PLAY
@:bitmap('art/touchHereToPlay.png')
class TouchHereToPlayImage extends BitmapData {}
#end

/**
 * This preloader displays a logo while the game downloads assets.
 */
class FunkinPreloader extends FlxBasePreloader
{
  /**
   * The logo image width at the base resolution.
   * Scaled up/down appropriately as needed.
   */
  static final BASE_WIDTH:Float = 1280;

  /**
   * Margin at the sides and bottom, around the loading bar.
   */
  static final BAR_PADDING:Float = 20;

  static final BAR_HEIGHT:Int = 12;

  /**
   * Logo takes this long (in seconds) to fade in.
   */
  static final LOGO_FADE_TIME:Float = 2.5;

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
  var logo:Bitmap;
  #if TOUCH_HERE_TO_PLAY
  var touchHereToPlay:Bitmap;
  var touchHereSprite:Sprite;
  #end
  var progressBarPieces:Array<Sprite>;
  var progressBar:Bitmap;
  var progressLeftText:TextField;
  var progressRightText:TextField;

  var dspText:TextField;
  var fnfText:TextField;
  var enhancedText:TextField;
  var stereoText:TextField;

  var vfdShader:VFDOverlay;
  var vfdBitmap:Bitmap;
  var box:Sprite;
  var progressLines:Sprite;

  public function new()
  {
    super(Constants.PRELOADER_MIN_STAGE_TIME);

    // We can't even call trace() yet, until Flixel loads.
    trace('Initializing custom preloader...');

    this.siteLockTitleText = Constants.SITE_LOCK_TITLE;
    this.siteLockBodyText = Constants.SITE_LOCK_DESC;
  }

  override function create():Void
  {
    // Nothing happens in the base preloader.
    super.create();

    // Background color.
    Lib.current.stage.color = Constants.COLOR_PRELOADER_BG;

    // Width and height of the preloader.
    this._width = Lib.current.stage.stageWidth;
    this._height = Lib.current.stage.stageHeight;

    // Scale assets to the screen size.
    ratio = this._width / BASE_WIDTH / 2.0;

    // Create the logo.
    logo = createBitmap(LogoImage, function(bmp:Bitmap) {
      // Scale and center the logo.
      // We have to do this inside the async call, after the image size is known.
      bmp.scaleX = bmp.scaleY = ratio;
      bmp.x = (this._width - bmp.width) / 2;
      bmp.y = (this._height - bmp.height) / 2;
    });
    // addChild(logo);

    var amountOfPieces:Int = 16;
    progressBarPieces = [];
    var maxBarWidth = this._width - BAR_PADDING * 2;
    var pieceWidth = maxBarWidth / amountOfPieces;
    var pieceGap:Int = 8;

    progressLines = new openfl.display.Sprite();
    progressLines.graphics.lineStyle(2, Constants.COLOR_PRELOADER_BAR);
    progressLines.graphics.drawRect(-2, 480, this._width + 4, 30);
    addChild(progressLines);

    var progressBarPiece = new Sprite();
    progressBarPiece.graphics.beginFill(Constants.COLOR_PRELOADER_BAR);
    progressBarPiece.graphics.drawRoundRect(0, 0, pieceWidth - pieceGap, BAR_HEIGHT, 4, 4);
    progressBarPiece.graphics.endFill();

    for (i in 0...amountOfPieces)
    {
      var piece = new Sprite();
      piece.graphics.beginFill(Constants.COLOR_PRELOADER_BAR);
      piece.graphics.drawRoundRect(0, 0, pieceWidth - pieceGap, BAR_HEIGHT, 4, 4);
      piece.graphics.endFill();

      piece.x = i * (piece.width + pieceGap);
      piece.y = this._height - BAR_PADDING - BAR_HEIGHT - 200;
      addChild(piece);
      progressBarPieces.push(piece);
    }

    // Create the progress bar.
    // progressBar = new Bitmap(new BitmapData(1, BAR_HEIGHT, true, Constants.COLOR_PRELOADER_BAR));
    // progressBar.x = BAR_PADDING;
    // progressBar.y = this._height - BAR_PADDING - BAR_HEIGHT;
    // addChild(progressBar);

    // Create the progress message.
    progressLeftText = new TextField();
    dspText = new TextField();
    fnfText = new TextField();
    enhancedText = new TextField();
    stereoText = new TextField();

    var progressLeftTextFormat = new TextFormat("DS-Digital", 32, Constants.COLOR_PRELOADER_BAR, true);
    progressLeftTextFormat.align = TextFormatAlign.LEFT;
    progressLeftText.defaultTextFormat = progressLeftTextFormat;

    progressLeftText.selectable = false;
    progressLeftText.width = this._width - BAR_PADDING * 2;
    progressLeftText.text = 'Downloading assets...';
    progressLeftText.x = BAR_PADDING;
    progressLeftText.y = this._height - BAR_PADDING - BAR_HEIGHT - 290;
    // progressLeftText.shader = new VFDOverlay();
    addChild(progressLeftText);

    // Create the progress %.
    progressRightText = new TextField();

    var progressRightTextFormat = new TextFormat("DS-Digital", 16, Constants.COLOR_PRELOADER_BAR, true);
    progressRightTextFormat.align = TextFormatAlign.RIGHT;
    progressRightText.defaultTextFormat = progressRightTextFormat;

    progressRightText.selectable = false;
    progressRightText.width = this._width - BAR_PADDING * 2;
    progressRightText.text = '0%';
    progressRightText.x = BAR_PADDING;
    progressRightText.y = this._height - BAR_PADDING - BAR_HEIGHT - 16 - 4;
    addChild(progressRightText);

    box = new Sprite();
    box.graphics.beginFill(Constants.COLOR_PRELOADER_BAR, 1);
    box.graphics.drawRoundRect(0, 0, 64, 20, 5, 5);
    box.graphics.drawRoundRect(70, 0, 58, 20, 5, 5);
    box.graphics.endFill();
    box.graphics.beginFill(Constants.COLOR_PRELOADER_BAR, 0.1);
    box.graphics.drawRoundRect(0, 0, 128, 20, 5, 5);
    box.graphics.endFill();
    box.x = 880;
    box.y = 440;
    addChild(box);

    dspText.selectable = false;
    dspText.textColor = 0x000000;
    dspText.width = this._width;
    dspText.height = 30;
    dspText.text = 'DSP';
    dspText.x = 10;
    dspText.y = -7;
    box.addChild(dspText);

    fnfText.selectable = false;
    fnfText.textColor = 0x000000;
    fnfText.width = this._width;
    fnfText.height = 30;
    fnfText.x = 78;
    fnfText.y = -7;
    fnfText.text = 'FNF';
    box.addChild(fnfText);

    enhancedText.selectable = false;
    enhancedText.textColor = Constants.COLOR_PRELOADER_BAR;
    enhancedText.width = this._width;
    enhancedText.height = 100;
    enhancedText.text = 'ENHANCED';
    enhancedText.x = -100;
    enhancedText.y = 0;
    box.addChild(enhancedText);

    stereoText.selectable = false;
    stereoText.textColor = Constants.COLOR_PRELOADER_BAR;
    stereoText.width = this._width;
    stereoText.height = 100;
    stereoText.text = 'STEREO';
    stereoText.x = 0;
    stereoText.y = -40;
    box.addChild(stereoText);

    // var dummyMatrix:openfl.geom.Matrix = new Matrix();
    // dummyMatrix.createGradientBox(this._width, this._height * 0.1, 90 * Math.PI / 180);

    // var gradient:Sprite = new Sprite();
    // gradient.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0x000000], [1, 1], [0, 255], dummyMatrix, SpreadMethod.REFLECT);
    // gradient.graphics.drawRect(0, 0, this._width, this._height);
    // gradient.graphics.endFill();
    // addChild(gradient);

    vfdBitmap = new Bitmap(new BitmapData(this._width, this._height, true, 0xFFFFFFFF));
    addChild(vfdBitmap);

    vfdShader = new VFDOverlay();
    vfdBitmap.shader = vfdShader;

    #if TOUCH_HERE_TO_PLAY
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

  var lastElapsed:Float = 0.0;

  override function update(percent:Float):Void
  {
    var elapsed:Float = (Date.now().getTime() - this._startTime) / 1000.0;

    vfdShader.update(elapsed * 100);
    // trace('Time since last frame: ' + (lastElapsed - elapsed));

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
      #if TOUCH_HERE_TO_PLAY
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

  #if TOUCH_HERE_TO_PLAY
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

  static final TOTAL_STEPS:Int = 11;
  static final ELLIPSIS_TIME:Float = 0.5;

  function updateGraphics(percent:Float, elapsed:Float):Void
  {
    // Render logo (including transitions)
    if (completeTime > 0.0)
    {
      var elapsedFinished:Float = renderLogoFadeOut(elapsed);
      // trace('Fading out logo... (' + elapsedFinished + 's)');
      if (elapsedFinished > LOGO_FADE_TIME)
      {
        #if TOUCH_HERE_TO_PLAY
        // The logo has faded out, but we're not quite done yet.
        // In order to prevent autoplay issues, we need the user to click after the loading finishes.
        currentState = FunkinPreloaderState.TouchHereToPlay;
        #else
        immediatelyStartGame();
        #end
      }
    }
    else
    {
      renderLogoFadeIn(elapsed);

      // Render progress bar
      var maxWidth = this._width - BAR_PADDING * 2;
      var barWidth = maxWidth * percent;
      var piecesToRender:Int = Std.int(percent * progressBarPieces.length);

      for (i => piece in progressBarPieces)
      {
        piece.alpha = i <= piecesToRender ? 0.9 : 0.1;
      }
    }

    // progressBar.width = barWidth;

    // Cycle ellipsis count to show loading
    var ellipsisCount:Int = Std.int(elapsed / ELLIPSIS_TIME) % 3 + 1;
    var ellipsis:String = '';
    for (i in 0...ellipsisCount)
      ellipsis += '.';

    var percentage:Int = Math.floor(percent * 100);
    // Render status text
    switch (currentState)
    {
      // case FunkinPreloaderState.NotStarted:
      default:
        updateProgressLeftText('Loading \n0/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.DownloadingAssets:
        updateProgressLeftText('Downloading assets \n1/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.PreloadingPlayAssets:
        updateProgressLeftText('Preloading assets \n2/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.InitializingScripts:
        updateProgressLeftText('Initializing scripts \n3/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.CachingGraphics:
        updateProgressLeftText('Caching graphics \n4/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.CachingAudio:
        updateProgressLeftText('Caching audio \n5/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.CachingData:
        updateProgressLeftText('Caching data \n6/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.ParsingSpritesheets:
        updateProgressLeftText('Parsing spritesheets \n7/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.ParsingStages:
        updateProgressLeftText('Parsing stages \n8/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.ParsingCharacters:
        updateProgressLeftText('Parsing characters \n9/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.ParsingSongs:
        updateProgressLeftText('Parsing songs \n10/$TOTAL_STEPS $ellipsis');
        trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      case FunkinPreloaderState.Complete:
        updateProgressLeftText('Finishing up \n$TOTAL_STEPS/$TOTAL_STEPS $ellipsis');
        // trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      #if TOUCH_HERE_TO_PLAY
      case FunkinPreloaderState.TouchHereToPlay:
        updateProgressLeftText(null);
        // trace('Preloader state: ' + currentState + ' (' + percentage + '%, ' + elapsed + 's)');
      #end
    }

    // Render percent text
    progressRightText.text = '$percentage%';

    super.update(percent);
  }

  function updateProgressLeftText(text:Null<String>):Void
  {
    if (progressLeftText != null)
    {
      if (text == null)
      {
        progressLeftText.alpha = 0.0;
      }
      else if (progressLeftText.text != text)
      {
        // We have to keep updating the text format, because the font can take a frame or two to load.
        var progressLeftTextFormat = new TextFormat("DS-Digital", 32, Constants.COLOR_PRELOADER_BAR, true);
        progressLeftTextFormat.align = TextFormatAlign.LEFT;
        progressLeftText.defaultTextFormat = progressLeftTextFormat;
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
  }

  function immediatelyStartGame():Void
  {
    _loaded = true;
  }

  /**
   * Fade out the logo.
   * @param	elapsed Elapsed time since the preloader started.
   * @return	Elapsed time since the logo started fading out.
   */
  function renderLogoFadeOut(elapsed:Float):Float
  {
    // Fade-out takes LOGO_FADE_TIME seconds.
    var elapsedFinished = elapsed - completeTime;

    logo.alpha = 1.0 - MathUtil.easeInOutCirc(elapsedFinished / LOGO_FADE_TIME);
    logo.scaleX = (1.0 - MathUtil.easeInBack(elapsedFinished / LOGO_FADE_TIME)) * ratio;
    logo.scaleY = (1.0 - MathUtil.easeInBack(elapsedFinished / LOGO_FADE_TIME)) * ratio;
    logo.x = (this._width - logo.width) / 2;
    logo.y = (this._height - logo.height) / 2;

    // Fade out progress bar too.
    // progressBar.alpha = logo.alpha;
    progressLeftText.alpha = logo.alpha;
    progressRightText.alpha = logo.alpha;
    box.alpha = logo.alpha;
    dspText.alpha = logo.alpha;
    fnfText.alpha = logo.alpha;
    enhancedText.alpha = logo.alpha;
    stereoText.alpha = logo.alpha;
    progressLines.alpha = logo.alpha;

    for (piece in progressBarPieces)
      piece.alpha = logo.alpha;

    return elapsedFinished;
  }

  function renderLogoFadeIn(elapsed:Float):Void
  {
    // Fade-in takes LOGO_FADE_TIME seconds.
    logo.alpha = MathUtil.easeInOutCirc(elapsed / LOGO_FADE_TIME);
    logo.scaleX = MathUtil.easeOutBack(elapsed / LOGO_FADE_TIME) * ratio;
    logo.scaleY = MathUtil.easeOutBack(elapsed / LOGO_FADE_TIME) * ratio;
    logo.x = (this._width - logo.width) / 2;
    logo.y = (this._height - logo.height) / 2;
  }

  #if html5
  // These fields only exist on Web builds.

  /**
   * Format the layout of the site lock screen.
   */
  override function createSiteLockFailureScreen():Void
  {
    // addChild(createSiteLockFailureBackground(Constants.COLOR_PRELOADER_LOCK_BG, Constants.COLOR_PRELOADER_LOCK_BG));
    // addChild(createSiteLockFailureIcon(Constants.COLOR_PRELOADER_LOCK_FG, 0.9));
    // addChild(createSiteLockFailureText(30));
  }

  /**
   * Format the text of the site lock screen.
   */
  override function adjustSiteLockTextFields(titleText:TextField, bodyText:TextField, hyperlinkText:TextField):Void
  {
    var titleFormat = titleText.defaultTextFormat;
    titleFormat.align = TextFormatAlign.CENTER;
    titleFormat.color = Constants.COLOR_PRELOADER_LOCK_FONT;
    titleText.setTextFormat(titleFormat);

    var bodyFormat = bodyText.defaultTextFormat;
    bodyFormat.align = TextFormatAlign.CENTER;
    bodyFormat.color = Constants.COLOR_PRELOADER_LOCK_FONT;
    bodyText.setTextFormat(bodyFormat);

    var hyperlinkFormat = hyperlinkText.defaultTextFormat;
    hyperlinkFormat.align = TextFormatAlign.CENTER;
    hyperlinkFormat.color = Constants.COLOR_PRELOADER_LOCK_LINK;
    hyperlinkText.setTextFormat(hyperlinkFormat);
  }
  #end

  override function destroy():Void
  {
    // Ensure the graphics are properly destroyed and GC'd.
    removeChild(logo);
    // removeChild(progressBar);
    logo = null;
    super.destroy();
  }

  override function onLoaded():Void
  {
    super.onLoaded();
    // We're not ACTUALLY finished.
    // This function gets called when the DownloadingAssets step is done.
    // We need to wait for the other steps, then the logo to fade out.
    _loaded = false;
    downloadingAssetsComplete = true;
  }
}

enum FunkinPreloaderState
{
  /**
   * The state before downloading has begun.
   * Moves to either `DownloadingAssets` or `CachingGraphics` based on platform.
   */
  NotStarted;

  /**
   * Downloading assets.
   * On HTML5, Lime will do this for us, before calling `onLoaded`.
   * On Desktop, this step will be completed immediately, and we'll go straight to `CachingGraphics`.
   */
  DownloadingAssets;

  /**
   * Preloading play assets.
   * Loads the `manifest.json` for the `gameplay` library.
   * If we make the base preloader do this, it will download all the assets as well,
   * so we have to do it ourselves.
   */
  PreloadingPlayAssets;

  /**
   * Loading FireTongue, loading Polymod, parsing and instantiating module scripts.
   */
  InitializingScripts;

  /**
   * Loading all graphics from the `core` library to the cache.
   */
  CachingGraphics;

  /**
   * Loading all audio from the `core` library to the cache.
   */
  CachingAudio;

  /**
   * Loading all data files from the `core` library to the cache.
   */
  CachingData;

  /**
   * Parsing all XML files from the `core` library into FlxFramesCollections and caching them.
   */
  ParsingSpritesheets;

  /**
   * Parsing stage data and scripts.
   */
  ParsingStages;

  /**
   * Parsing character data and scripts.
   */
  ParsingCharacters;

  /**
   * Parsing song data and scripts.
   */
  ParsingSongs;

  /**
   * Finishing up.
   */
  Complete;

  #if TOUCH_HERE_TO_PLAY
  /**
   * Touch Here to Play is displayed.
   */
  TouchHereToPlay;
  #end
}
