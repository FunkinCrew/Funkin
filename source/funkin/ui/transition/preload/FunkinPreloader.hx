package funkin.ui.transition.preload;

import funkin.assets.FunkinAssetCache;
import lime.app.Future;
import funkin.mobile.util.ScreenUtil;
import funkin.data.BaseRegistry.LoadEntriesResult;
import openfl.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.Lib;
import flixel.math.FlxMath;
import flixel.system.FlxBasePreloader;
import funkin.util.MathUtil;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import funkin.assets.Assets;
import funkin.assets.Paths.AssetPath;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.util.plugins.SidePanelPlugin;
import funkin.play.event.SongEventHelper;
import funkin.data.event.SongEventRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.module.ModuleHandler;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.play.notes.notekind.NoteKindManager;

using StringTools;

// Annotation embeds the asset in the executable for faster loading.
// Polymod can't override this, so we can't use this technique elsewhere.
#if FEATURE_TOUCH_HERE_TO_PLAY
@:bitmap('art/touchHereToPlay.png')
class TouchHereToPlayImage extends BitmapData
{
}
#end

/**
 * This preloader displays a VFD-esque display while the game downloads assets.
 */
@:access(lime.graphics.Image)
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
  var downloadingAssetsPercent:Float = -1;
  // var downloadingAssetsStartTime:Float = -1;
  var downloadingAssetsComplete:Bool = false;
  var initializingScriptsPercent:Float = -1;
  var initializingScriptsStartTime:Float = -1;
  var initializingScriptsComplete:Bool = false;
  var parsingGameDataPercent:Float = -1;
  var parsingGameDataStartTime:Float = -1;
  var parsingGameDataComplete:Bool = false;
  var cachingGraphicsPercent:Float = -1;
  var cachingGraphicsStartTime:Float = -1;
  var cachingGraphicsComplete:Bool = false;
  var cachingFontsPercent:Float = -1;
  var cachingFontsStartTime:Float = -1;
  var cachingFontsComplete:Bool = false;
  var cachingAudioPercent:Float = -1;
  var cachingAudioStartTime:Float = -1;
  var cachingAudioComplete:Bool = false;
  var cachingDataPercent:Float = -1;
  var cachingDataStartTime:Float = -1;
  var cachingDataComplete:Bool = false;

  /**
   * The timestamp when the other steps completed and the `Finishing up` step started.
   */
  var completeTime:Float = -1;

  // Graphics
  #if FEATURE_TOUCH_HERE_TO_PLAY
  var touchedHereToPlay:Bool = false;
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

    trace(' PRELOADER '.bold().bg_note_left() + ' Starting custom preloader...');
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

    trace(' PRELOADER '.bold().bg_note_left() + ' Resolution: ${this._width}x${this._height}');

    // Scale assets to the screen size.
    // Desktop is always 1:1 scale, mobile needs DPI normalization for consistent positioning
    #if mobile
    var display = Lib.current.stage.window.display;
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

    var progressLeftTextFormat:TextFormat = new TextFormat('DS-Digital', Std.int(32 * ratio), Constants.COLOR_PRELOADER_BAR, true);
    progressLeftTextFormat.align = TextFormatAlign.LEFT;
    var progressRightTextFormat:TextFormat = new TextFormat('DS-Digital', 16, Constants.COLOR_PRELOADER_BAR, true);
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
    touchHereToPlay = createBitmap(TouchHereToPlayImage, function(bmp:Bitmap)
    {
      // Scale and center the touch to start image.
      // We have to do this inside the async call, after the image size is known.
      bmp.scaleX = bmp.scaleY = ratio * 0.5;
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
  var lastLoggedPercent:Int = -1;
  var lastLoggedState:FunkinPreloaderState = NotStarted;

  override function update(percent:Float):Void
  {
    var elapsed:Float = (Date.now().getTime() - this._startTime) / Constants.MS_PER_SEC;

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
      case NotStarted:
        if (downloadingAssetsPercent > 0.0)
        {
          currentState = DownloadingAssets;
        }

        return percent;

      case DownloadingAssets:
        // Sometimes percent doesn't go to 100%, it's a floating point error.
        if (downloadingAssetsPercent >= 1.0 || (elapsed > Constants.PRELOADER_MIN_STAGE_TIME && downloadingAssetsComplete))
        {
          currentState = InitializingScripts;
        }

        return percent;

      case InitializingScripts:
        if (initializingScriptsPercent < 0.0)
        {
          initializingScriptsPercent = 0.0;
          initializingScriptsStartTime = elapsed;

          // Do some tasks that need to be done before we start caching assets.
          // These are quick enough to do synchronously.
          funkin.util.tasks.TaskHandler.initialize(); // Initialize the thread pool.
          funkin.assets.Assets.initialize(); // Initialize the FunkinAssetCache.

          // Load mods to override assets BEFORE we cache them.
          // This is done synchronously.
          funkin.modding.PolymodHandler.loadEnabledMods();

          // Cache the results of Assets.list(), forcibly clearing any previous cache.
          FunkinAssetCache.instance.cacheAssetLists(true);

          // Then, initialize scripts.
          var future = funkin.modding.PolymodHandler.loadScripts(true);
          future.onProgress((loaded:Int, total:Int) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' PROGRESS initializing scripts (${loaded} / ${total})...');
            initializingScriptsPercent = loaded / total;
          });
          future.onComplete((_result) ->
          {
            var classList = polymod.hscript._internal.PolymodScriptClass.listScriptClasses();
            trace(' PRELOADER '.bold().bg_note_left() + ' Completed initializing ${classList.length} scripts...');
            initializingScriptsComplete = true;
          });
          return initializingScriptsPercent;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedInitializingScripts:Float = elapsed - initializingScriptsStartTime;
          if (initializingScriptsComplete && elapsedInitializingScripts >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = ParsingGameData;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (initializingScriptsPercent < (elapsedInitializingScripts / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              return initializingScriptsPercent;
            }
            else
            {
              return elapsedInitializingScripts / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (initializingScriptsComplete)
          {
            currentState = ParsingGameData;
          }
        }

        return initializingScriptsPercent;

      case ParsingGameData:
        if (parsingGameDataPercent < 0)
        {
          parsingGameDataPercent = 0.0;
          parsingGameDataStartTime = elapsed;

          // Load ALL registry data asynchronously.
          // We can queue multiple futures in order to do all of these in parallel.

          var futures:Array<Future<LoadEntriesResult>> = [];

          futures.push(SongRegistry.instance.loadEntriesAsync());
          futures.push(LevelRegistry.instance.loadEntriesAsync());
          futures.push(NoteStyleRegistry.instance.loadEntriesAsync());
          futures.push(PlayerRegistry.instance.loadEntriesAsync());
          futures.push(ConversationRegistry.instance.loadEntriesAsync());
          futures.push(DialogueBoxRegistry.instance.loadEntriesAsync());
          futures.push(SpeakerRegistry.instance.loadEntriesAsync());
          futures.push(AlbumRegistry.instance.loadEntriesAsync());
          futures.push(StageRegistry.instance.loadEntriesAsync());
          futures.push(StickerRegistry.instance.loadEntriesAsync());
          futures.push(FreeplayStyleRegistry.instance.loadEntriesAsync());
          futures.push(SongEventRegistry.loadEventCacheAsync());
          futures.push(NoteKindManager.loadNoteKindsAsync());
          futures.push(CharacterDataParser.loadCharacterCacheAsync());
          futures.push(ModuleHandler.loadModuleCacheAsync());

          var registryFuture = lime.app.Promises.allSettled(futures);

          registryFuture.onProgress((loaded:Int, total:Int) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Parsing game data... ${loaded}/${total}');
            parsingGameDataPercent = loaded / total;
          });
          registryFuture.onComplete((_result) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Completed parsing game data.');
            parsingGameDataComplete = true;
          });

          return parsingGameDataPercent;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedParsingGameData:Float = elapsed - cachingGraphicsStartTime;
          if (parsingGameDataComplete && elapsedParsingGameData >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = CachingGraphics;
            return 0.0;
          }
          else
          {
            if (parsingGameDataPercent < (elapsedParsingGameData / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              // Return real progress if it's lower.
              return parsingGameDataPercent;
            }
            else
            {
              // Return simulated progress if it's higher.
              return elapsedParsingGameData / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (parsingGameDataComplete)
          {
            currentState = CachingGraphics;
            return 0.0;
          }
        }

        return parsingGameDataPercent;

      case CachingGraphics:
        if (cachingGraphicsPercent < 0)
        {
          cachingGraphicsPercent = 0.0;
          cachingGraphicsStartTime = elapsed;

          final CACHE_PERMANENT:Bool = true;

          // TODO : THIS IS BANDAID. BAND. AID. REMOVE IT LATER! LIKE ACTUALLY - Moon
          // It just quickly fixes load time so we can push out mod menu quicker, I want to rewrite that menu properly hence this bandaid
          var modsThing:Array<polymod.Polymod.ModMetadata> = funkin.modding.PolymodHandler.getAllMods();

          for (mod in modsThing)
          {
            if (mod.id == null || mod.id.length == 0) continue;

            if (mod.icon == null || mod.icon.length == 0) continue;

            if (lime.graphics.Image.__isGIF(mod.icon)) continue;

            if (lime.graphics.Image.__isWebP(mod.icon)) continue;

            FunkinAssetCache.instance.permaCacheFlxGraphic(mod.id, openfl.display.BitmapData.fromBytes(mod.icon, true));
          }

          var assetsToCache:Array<AssetPath> = Assets.queryPreloadAssets(IMAGE);

          trace(' PRELOADER '.bold().bg_note_left() + ' Begin caching ${assetsToCache.length} graphics...');

          var future:Future<Array<Future<Bool>>> = Assets.cacheAllFlxGraphics(assetsToCache, CACHE_PERMANENT);

          future.onProgress((loaded:Int, total:Int) ->
          {
            cachingGraphicsPercent = loaded / total;
          });
          future.onComplete((_result) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Completed caching graphics.');
            cachingGraphicsComplete = true;
          });

          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingGraphics:Float = elapsed - cachingGraphicsStartTime;
          if (cachingGraphicsComplete && elapsedCachingGraphics >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = CachingFonts;
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
            currentState = CachingFonts;
            return 0.0;
          }
        }

        return cachingGraphicsPercent;

      case CachingFonts:
        if (cachingFontsPercent < 0.0)
        {
          cachingFontsStartTime = elapsed;
          cachingFontsPercent = 0.0;

          // Load and store font data for later use by the game.
          var fontsToPreload = Assets.queryPreloadAssets(FONT);

          var future:Future<Array<Future<Bool>>> = Assets.cacheAllFonts(fontsToPreload);
          future.onProgress((loaded:Int, total:Int) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Caching fonts... ${loaded}/${total}');
            cachingFontsPercent = loaded / total;
          });
          future.onComplete((_result) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Completed caching fonts.');
            cachingFontsComplete = true;
          });

          return cachingFontsPercent;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingFonts:Float = elapsed - cachingFontsStartTime;
          if (cachingFontsComplete && elapsedCachingFonts >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = CachingAudio;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (cachingFontsPercent < (elapsedCachingFonts / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              return cachingFontsPercent;
            }
            else
            {
              return elapsedCachingFonts / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (cachingFontsComplete)
          {
            currentState = CachingAudio;
          }
        }

        return cachingFontsPercent;

      case CachingAudio:
        if (cachingAudioPercent < 0)
        {
          cachingAudioPercent = 0.0;
          cachingAudioStartTime = elapsed;

          final CACHE_PERMANENT:Bool = true;

          var assetsToCache:Array<AssetPath> = Assets.queryPreloadAssets(SOUND);

          trace(' PRELOADER '.bold().bg_note_left() + ' Begin caching ${assetsToCache.length} sounds...');

          var future:Future<Array<Future<Bool>>> = Assets.cacheAllSounds(assetsToCache, CACHE_PERMANENT);

          future.onProgress((loaded:Int, total:Int) ->
          {
            cachingAudioPercent = loaded / total;
          });
          future.onComplete((_result) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Completed caching audio.');
            cachingAudioComplete = true;
          });

          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingAudio:Float = elapsed - cachingAudioStartTime;
          if (cachingAudioComplete && elapsedCachingAudio >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = CachingData;
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
            currentState = CachingData;
            return 0.0;
          }
        }
        return cachingAudioPercent;

      case CachingData:
        if (cachingDataPercent < 0)
        {
          cachingDataPercent = 0.0;
          cachingDataStartTime = elapsed;

          final CACHE_PERMANENT:Bool = true;

          var assetsToCache:Array<AssetPath> = [];

          assetsToCache.append(Assets.queryPreloadAssets(TEXT));
          assetsToCache.append(Assets.queryPreloadAssets(JSON));
          assetsToCache.append(Assets.queryPreloadAssets(SHADER));
          assetsToCache.append(Assets.queryPreloadAssets(SCRIPT));
          assetsToCache.append(Assets.queryPreloadAssets(XML));

          assetsToCache.append(Assets.queryPreloadAssets(UNKNOWN));

          trace(' PRELOADER '.bold().bg_note_left() + ' Begin caching ${assetsToCache.length} additional data files...');

          var future:Future<Array<Future<Bool>>> = Assets.cacheAll(assetsToCache, CACHE_PERMANENT);

          future.onProgress((loaded:Int, total:Int) ->
          {
            cachingDataPercent = loaded / total;
          });
          future.onComplete((_result) ->
          {
            trace(' PRELOADER '.bold().bg_note_left() + ' Completed caching data.');
            cachingDataComplete = true;
          });

          return 0.0;
        }
        else if (Constants.PRELOADER_MIN_STAGE_TIME > 0)
        {
          var elapsedCachingData:Float = elapsed - cachingDataStartTime;
          if (cachingDataComplete && elapsedCachingData >= Constants.PRELOADER_MIN_STAGE_TIME)
          {
            currentState = Complete;
            return 0.0;
          }
          else
          {
            // We need to return SIMULATED progress here.
            if (cachingDataPercent < (elapsedCachingData / Constants.PRELOADER_MIN_STAGE_TIME))
            {
              return cachingDataPercent;
            }
            else
            {
              return elapsedCachingData / Constants.PRELOADER_MIN_STAGE_TIME;
            }
          }
        }
        else
        {
          if (cachingDataComplete)
          {
            currentState = Complete;
            return 0.0;
          }
        }

        return cachingDataPercent;

      case Complete:
        if (completeTime <= 0)
        {
          completeTime = elapsed;
        }

        return 1.0;
      #if FEATURE_TOUCH_HERE_TO_PLAY
      case TouchHereToPlay:
        if (completeTime < 0)
        {
          completeTime = elapsed;
        }

        if (touchHereToPlay.alpha < 1.0)
        {
          touchHereSprite.buttonMode = true;
          touchHereToPlay.alpha = 1.0;
          removeChild(vfdBitmap);

          touchHereSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);
        }

        return 1.0;
      #end

      default:
        // Do nothing.
    }

    return 0.0;
  }

  #if FEATURE_TOUCH_HERE_TO_PLAY
  function mouseDownTouchHereToPlay(e:MouseEvent):Void
  {
    if (touchedHereToPlay)
    {
      return;
    }

    touchedHereToPlay = true;

    haxe.Timer.delay(function():Void
    {
      touchHereSprite.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);

      immediatelyStartGame();
    }, 1000);
  }

  function scaleAndCenter(bmp:Bitmap, scale:Float)
  {
    bmp.scaleX = bmp.scaleY = scale;
    bmp.x = (this._width - bmp.width) / 2;
    bmp.y = (this._height - bmp.height) / 2;
  }
  #end

  public static final TOTAL_STEPS:Int = 8;
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
        currentState = TouchHereToPlay;
        #else
        immediatelyStartGame();
        #end
      }
    }
    else
    {
      // Render progress bar
      var piecesToRender:Int = Std.int(percent * progressBarPieces.length);

      for (i => piece in progressBarPieces) piece.alpha = i <= piecesToRender ? 0.9 : 0.1;
    }

    // Cycle ellipsis count to show loading
    var ellipsisCount:Int = Std.int(elapsed / ELLIPSIS_TIME) % 3 + 1;
    var ellipsis:String = '';
    for (_ in 0...ellipsisCount) ellipsis += '.';

    // Render status text
    updateProgressLeftText(currentState.getProgressLeftText(TOTAL_STEPS, ellipsis));

    // Render percent text
    var percentage:Int = Math.floor(percent * 100);
    progressRightText.text = '$percentage%';

    // Only log when the state or percentage changes, so we don't spam the same line every frame (e.g. while pinned at 100% during fade-out).
    if (currentState.getProgressLeftText() != null && (currentState != lastLoggedState || percentage != lastLoggedPercent))
    {
      trace(' PRELOADER '.bold().bg_note_left() + ' $currentState ($percentage%, ${FlxMath.roundDecimal(elapsed, 2)} sec)');
      lastLoggedState = currentState;
      lastLoggedPercent = percentage;
    }

    #if FEATURE_TOUCH_HERE_TO_PLAY
    // Handle the size of the `touchHereToPlay` sprite.
    if (currentState == TouchHereToPlay)
    {
      // Normal size based on screen ratio.
      var targetScale:Float = ratio * 0.5;

      if (touchedHereToPlay)
      {
        // Make it smaller when pressed.
        targetScale = ratio * 0.45;
      }
      else if (touchHereSprite.hitTestPoint(mouseX, mouseY))
      {
        // Make it bigger when mouse is over it.
        targetScale = ratio * 0.55;
      }

      // Smoothly move current size to target size.
      scaleAndCenter(touchHereToPlay, touchHereToPlay.scaleX + (targetScale - touchHereToPlay.scaleX) * 0.15);
    }
    #end

    super.update(percent);
  }

  function updateProgressLeftText(text:Null<String>):Void
  {
    if (progressLeftText == null) return;

    if (text == null)
    {
      progressLeftText.alpha = 0.0;
    }
    else if (progressLeftText.text != text)
    {
      // We have to keep updating the text format, because the font can take a frame or two to load.
      progressLeftText.defaultTextFormat = new TextFormat('DS-Digital', 32, Constants.COLOR_PRELOADER_BAR, true);
      progressLeftText.defaultTextFormat.align = TextFormatAlign.LEFT;
      progressLeftText.text = text;

      dspText.defaultTextFormat = new TextFormat('Quantico', 20, 0x000000, false);
      dspText.text = 'DSP'; // fukin dum....
      dspText.textColor = 0x000000;

      fnfText.defaultTextFormat = new TextFormat('Quantico', 20, 0x000000, false);
      fnfText.text = 'FNF';
      fnfText.textColor = 0x000000;

      enhancedText.defaultTextFormat = new TextFormat('Inconsolata Black', 16, Constants.COLOR_PRELOADER_BAR, false);
      enhancedText.text = 'ENHANCED';
      enhancedText.textColor = Constants.COLOR_PRELOADER_BAR;

      stereoText.defaultTextFormat = new TextFormat('Inconsolata Bold', 36, Constants.COLOR_PRELOADER_BAR, false);
      stereoText.text = 'NATURAL STEREO';
    }
  }

  /**
   * Whether or not we are in flipped landscape device rotation,
   * generally for mobile to accommodate the device notch!
   * @return Bool
   */
  function isLandscapeFlipped():Bool
  {
    return lime.app.Application.current.window.display.orientation == LANDSCAPE_FLIPPED;
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

    for (piece in progressBarPieces) piece.alpha = alphaToFade;

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
   * Moves to `DownloadingAssets` immediately.
   */
  public var NotStarted;

  /**
   * Downloading assets.
   * On HTML5, Lime will do this for us, before calling `onLoaded`.
   * On Native, this step will be completed immediately, and we'll go straight to `CachingGraphics`.
   */
  public var DownloadingAssets;

  /**
   * Loading Polymod, enabling mods, and parsing and instantiating gameplay scripts.
   */
  public var InitializingScripts;

  /**
   * Loading and parsing game data into registries, including loading JSONS for characters, stages, etc.
   */
  public var ParsingGameData;

  /**
   * Loading all graphics into the cache that we need to preload before the game starts.
   */
  public var CachingGraphics;

  /**
   * Loading all fonts into the cache that we need to preload before the game starts.
   */
  public var CachingFonts;

  /**
   * Loading all audio into the cache that we need to preload before the game starts.
   */
  public var CachingAudio;

  /**
   * Loading all data into the cache that we need to preload before the game starts.
   */
  public var CachingData;

  /**
   * Finishing up.
   */
  public var Complete;

  #if FEATURE_TOUCH_HERE_TO_PLAY
  /**
   * Touch Here to Play is displayed.
   */
  public var TouchHereToPlay;
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
      case InitializingScripts:
        return 'Initializing scripts \n2/$steps $suffix';
      case ParsingGameData:
        return 'Parsing game data \n3/$steps $suffix';
      case CachingGraphics:
        return 'Caching graphics \n4/$steps $suffix';
      case CachingFonts:
        return 'Caching fonts \n5/$steps $suffix';
      case CachingAudio:
        return 'Caching audio \n6/$steps $suffix';
      case CachingData:
        return 'Caching additional data \n7/$steps $suffix';
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
