package funkin.assets;

import animate.FlxAnimateFrames;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.graphics.FunkinSprite.AtlasSpriteSettings;
import funkin.util.macro.ConsoleMacro.ConsoleClass;
import lime.app.Future;
import lime.app.Promises;
import lime.utils.AssetType as LimeAssetType;
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFLAssets;
import funkin.assets.FunkinBitmapFrontend;
//
// ~PATHS~
//
import funkin.assets.ValidatedPaths as Paths;

/**
 * A wrapper around `openfl.utils.Assets` which disallows access to the harmful functions,
 * while providing additional Funkin-specific functions and caching.
 */
@:nullSafety
class Assets implements ConsoleClass
{
  static var initialized:Bool = false;
  static final ASSET_TYPES:Array<Null<AssetType>> = [
    null,
    IMAGE,
    SOUND,
    VIDEO,
    TEXT,
    JSON,
    SHADER,
    SCRIPT,
    SCRIPTED_CLASS,
    CHART,
    STAGE,
    XML,
    FONT,
    UNKNOWN
  ];

  /**
   * Perform functions to initialize internal asset management.
   */
  public static function initialize():Void
  {
    if (initialized) return;
    initialized = true;

    trace(' ASSETS '.bold().bg_lime() + ' Initializing asset management...');

    // Enable our custom asset caches
    LimeAssets.cache = funkin.assets.FunkinAssetCache.FunkinLimeAssetCache.instance;
    OpenFLAssets.cache = funkin.assets.FunkinAssetCache.FunkinAssetCache.instance;
    @:privateAccess
    FlxG.bitmap = funkin.assets.FunkinBitmapFrontend.instance;

    // Cache the results of Assets.list()
    for (type in ASSET_TYPES)
    {
      Assets.list(type);
    }
  }

  /**
   * List data files that match the given prefix and suffix.
   * @param path A path prefix for the data file name.
   * @param suffix A path suffix for the data file name.
   * @param blacklist An array of paths to exclude from the list.
   * @param nested Whether to parse nested data files as only the last part of the path.
   *     Use `true`, if you expect files will be at `<path>/<id>/<id><suffix>`
   * @return A list of results, with path and extension removed.
   */
  public static function listDataFilesInPath(path:String, suffix:String = '.json', ?blacklist:Array<String>, nested:Bool = false):Array<String>
  {
    if (blacklist == null) blacklist = [];

    var textAssets:Array<String> = openfl.utils.Assets.list(TEXT);

    var queryPath:String = 'assets/${path}';

    var results:Array<String> = [];
    for (textPath in textAssets)
    {
      if (textPath.startsWith(queryPath) && textPath.endsWith(suffix))
      {
        var pathNoSuffix:String = textPath.substring(0, textPath.length - suffix.length);
        var pathNoPrefix:String = pathNoSuffix.substring(queryPath.length);

        var id:String = pathNoPrefix;
        if (nested)
        {
          var parts:Array<String> = pathNoPrefix.split('/');
          id = parts[0];
        }

        if (blacklist.contains(id)) continue;

        // No duplicates!
        if (!results.contains(id)) results.push(id);
      }
    }

    trace('[ASSETS] Got ${results.length} data files in path: ${queryPath}*${suffix}');

    return results;
  }

  /**
   * Retrieve the BitmapData for the given asset path, synchronously.
   * Fails if the asset isn't cached already.
   * @param assetPath The path of the asset to retrieve.
   * @param useCache TODO: THIS DOES NOTHING
   * @throws error If the asset isn't cached.
   * @return The BitmapData for the asset.
   */
  public static function getBitmapData(assetPath:AssetPath, useCache:Bool = true):BitmapData
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.getBitmapData(assetPath.toString());
  }

  /**
   * Retrieve the FlxGraphic for the given asset path, synchronously.
   * Fails if the asset isn't cached already.
   * @param assetPath The path of the asset to retrieve.
   * @throws error If the asset isn't cached.
   * @return The FlxGraphic for the asset.
   */
  public static function getFlxGraphic(assetPath:AssetPath):FlxGraphic
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.getFlxGraphic(assetPath.toString());
  }

  /**
   * Fetch a spritesheet's image and data files, and create a FlxAtlasFrames object.
   * Throws an ERROR if the asset isn't cached already.
   *
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the XML is next to it.
   * @return The generated FlxAtlasFrames.
   */
  public static function getSparrowAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';
    if (!assetPath.isAssetType(IMAGE)) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_STRICT_ASSET_CACHING
    if (isFlxGraphicCached(assetPath.image()))
    {
      return FunkinAssetCache.instance.getSparrowAtlas(assetPath);
    }
    else
    {
      throw 'Asset not cached, cannot load synchronously: ${assetPath.image()}';
    }
    #else
    return FunkinAssetCache.instance.getSparrowAtlas(assetPath);
    #end
  }

  /**
   * Fetch a spritesheet's image and data files, and create a FlxAtlasFrames object.
   * Throws an ERROR if the asset isn't cached already.
   *
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the TXT is next to it.
   * @return The generated FlxAtlasFrames.
   */
  public static function getPackerAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_STRICT_ASSET_CACHING
    if (isFlxGraphicCached(assetPath.image()))
    {
      return FunkinAssetCache.instance.getPackerAtlas(assetPath);
    }
    else
    {
      throw 'Asset not cached, cannot load synchronously: ${assetPath.image()}';
    }
    #else
    return FunkinAssetCache.instance.getPackerAtlas(assetPath);
    #end
  }

  /**
   * Fetch an Adobe Animate texture atlas's sprite frames, and parse and load them.
   * @param assetPath The asset path to the texture atlas. Use `Paths.animateAtlas` to build this.
   * @param settings Additional settings to use when loading the atlas sprite.
   * @return The generated FlxAnimateFrames
   */
  public static function getAnimateAtlas(assetPath:AnimateAtlasAssetPathBuilder, settings:AtlasSpriteSettings):FlxAnimateFrames
  {
    if (assetPath == null) throw 'Input is not a valid texture atlas AssetPath, did you call Paths.animateAtlas()?';

    var validatedSettings:AtlasSpriteSettings = {
      swfMode: settings?.swfMode ?? false,
      cacheOnLoad: settings?.cacheOnLoad ?? false,
      filterQuality: settings?.filterQuality ?? MEDIUM,
      spritemaps: settings?.spritemaps ?? null,
      metadataJson: settings?.metadataJson ?? null,
      cacheKey: settings?.cacheKey ?? null,
      uniqueInCache: settings?.uniqueInCache ?? false,
      onSymbolCreate: settings?.onSymbolCreate ?? null,
      applyStageMatrix: settings?.applyStageMatrix ?? false,
      useRenderTexture: settings?.useRenderTexture ?? false
    };

    // Validate asset path.
    if (!assetPath.jsonExists())
    {
      throw 'No data file exists at the specified path (${assetPath})';
    }

    if (!assetPath.imageExists())
    {
      throw 'No texture exists at the specified path (${assetPath})';
    }

    return FlxAnimateFrames.fromAnimate(assetPath.toString(), validatedSettings.spritemaps, validatedSettings.metadataJson, validatedSettings.cacheKey, validatedSettings.uniqueInCache, {
      swfMode: validatedSettings.swfMode,
      cacheOnLoad: validatedSettings.cacheOnLoad,
      filterQuality: validatedSettings.filterQuality,
      onSymbolCreate: validatedSettings.onSymbolCreate
    });
  }

  /**
   * Builds a monospace Bitmap font from the given asset path.
   *
   * @param assetPath The asset path to load the texture from
   * @param fontLetters The letters to use in the font, in order
   * @param letterSize The width and height of each letter, in pixels
   * @return The generated FlxBitmapFont
   */
  public static function getMonospaceBitmapFont(assetPath:AssetPath, fontLetters:String, letterSize:FlxPoint):FlxBitmapFont
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_STRICT_ASSET_CACHING
    if (isFlxGraphicCached(assetPath))
    {
      return FlxBitmapFont.fromMonospace(assetPath.toFlxBitmapFontGraphicAsset(), fontLetters, letterSize);
    }
    else
    {
      throw 'Asset not cached, cannot load synchronously: ${assetPath.toString()}';
    }
    #else
    return FlxBitmapFont.fromMonospace(assetPath.toFlxBitmapFontGraphicAsset(), fontLetters, letterSize);
    #end
  }

  /**
   * Builds a Bitmap font from the given asset path.
   *
   * @param assetPath The asset path to load the texture from.
   *   Assume there is a corresponding `.fnt` file to locate each letter.
   * @return The generated FlxBitmapFont
   */
  public static function getAngelBitmapFont(assetPath:AssetPath):FlxBitmapFont
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_STRICT_ASSET_CACHING
    if (isFlxGraphicCached(assetPath))
    {
      return FlxBitmapFont.fromAngelCode(assetPath.toFlxBitmapFontGraphicAsset(), assetPath.withExt('fnt').toString());
    }
    else
    {
      throw 'Asset not cached, cannot load synchronously: ${assetPath.toString()}';
    }
    #else
    return FlxBitmapFont.fromAngelCode(assetPath.toFlxBitmapFontGraphicAsset(), assetPath.withExt('fnt').toString());
    #end
  }

  /**
   * Load bytes from an asset
   * May cause stutters or throw an error if the asset is not cached
   * @param assetPath The asset path to load from
   * @return The byte contents of the file
   */
  public static function getBytes(assetPath:AssetPath):haxe.io.Bytes
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    return FunkinAssetCache.instance.getBytes(assetPath.toString());
  }

  /**
   * Load text from an asset.
   * May cause stutters or throw an error if the asset is not cached
   * @param assetPath The asset path to load from
   * @return The text contents of the file
   */
  public static function getText(assetPath:AssetPath):String
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.txt()?';

    return FunkinAssetCache.instance.getText(assetPath.toString());
  }

  /**
   * Load a Sound file from an asset
   * May cause stutters or throw an error if the asset is not cached
   * @param assetPath The asset path to load from
   * @return The loaded sound
   */
  public static function getSound(assetPath:AssetPath):openfl.media.Sound
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    return FunkinAssetCache.instance.getSound(assetPath.toString());
  }

  /**
   * Load a Sound file from an asset, with optimizations specific to long-duration music
   * May cause stutters or throw an error if the asset is not cached
   * @param assetPath The asset path to load from
   * @return The loaded sound
   */
  public static function getMusic(assetPath:MusicAssetPathBuilder):openfl.media.Sound
  {
    if (assetPath == null) throw 'Input is not a valid Music AssetPath, did you call Paths.music()?';

    return getSound(assetPath.audio());
  }

  /**
   * Retrieve the BitmapData for the given asset path, asynchronously.
   * @param assetPath The path of the asset to retrieve.
   * @return A future for the BitmapData for the asset.
   */
  public static function loadBitmapData(assetPath:AssetPath):Future<BitmapData>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.fetchBitmapData(assetPath);
  }

  /**
   * Retrieve the FlxGraphic for the given asset path, asynchronously.
   * @param assetPath The path of the asset to retrieve.
   * @return A future for the FlxGraphic for the asset.
   */
  public static function loadFlxGraphic(assetPath:AssetPath):Future<FlxGraphic>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.fetchFlxGraphic(assetPath);
  }

  /**
   * Load bytes from an asset asynchronously
   * @param assetPath The asset path to load from
   * @return A future which promises to return the byte contents of the file
   */
  public static function loadBytes(assetPath:AssetPath):Future<openfl.utils.ByteArray>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    return FunkinAssetCache.instance.fetchBytes(assetPath);
  }

  /**
   * Load text from an asset asynchronously
   * @param assetPath The asset path to load from
   * @return A future which promises to return the text contents of the file
   */
  public static function loadText(assetPath:AssetPath):Future<String>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.txt()?';

    return FunkinAssetCache.instance.fetchText(assetPath);
  }

  /**
   * Load a Sound file from an asset asynchronously
   * @param assetPath The asset path to load from
   * @return A future which promises to return the loaded sound
   */
  public static function loadSound(assetPath:AssetPath):Future<openfl.media.Sound>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    return FunkinAssetCache.instance.fetchSound(assetPath);
  }

  /**
   * Load a Sound file from an asset asynchronously, with optimizations specific to long-duration music
   * @param assetPath The asset path to load from
   * @return A future which promises to return the loaded sound
   */
  public static function loadMusic(assetPath:MusicAssetPathBuilder):Future<openfl.media.Sound>
  {
    if (assetPath == null) throw 'Input is not a valid Music AssetPath, did you call Paths.music()?';

    return FunkinAssetCache.instance.fetchSound(assetPath.audio());
  }

  /**
   * Fetch a spritesheet's image and data files, and create a FlxAtlasFrames object asynchronously.
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the XML is next to it.
   * @return A future representing the promise of generated FlxAtlasFrames.
   */
  public static function loadSparrowAtlas(assetPath:AssetPath):Future<FlxAtlasFrames>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.fetchSparrowAtlas(assetPath);
  }

  /**
   * Fetch a spritesheet's image and data files, and create a FlxAtlasFrames object asynchronously.
   * May take time to load the assets.
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the TXT is next to it.
   * @return A future representing the promise of generated FlxAtlasFrames.
   */
  public static function loadPackerAtlas(assetPath:AssetPath):Future<FlxAtlasFrames>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.fetchPackerAtlas(assetPath);
  }

  /**
   * Cache the BitmapData for the given asset path, asynchronously.
   * @param assetPath The path of the asset to cache.
   * @param uploadToGPU Whether or not to upload the BitmapData to the GPU before caching.
   * @return A future for the BitmapData for the asset.
   */
  public static function cacheBitmapData(assetPath:AssetPath, uploadToGPU:Bool = true):Future<BitmapData>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.cacheBitmapData(assetPath, uploadToGPU);
  }

  /**
   * Cache the FlxGraphic for the given asset path, asynchronously.
   * @param assetPath The path of the asset to cache.
   * @param uploadToGPU Whether or not to upload the BitmapData to the GPU before caching.
   * @return A future for the FlxGraphic for the asset.
   */
  public static function cacheFlxGraphic(assetPath:AssetPath, uploadToGPU:Bool = true):Future<FlxGraphic>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.cacheFlxGraphic(assetPath, uploadToGPU);
  }

  /**
   * Cache the Sound for the given asset path, asynchronously.
   * @param assetPath The path of the asset to cache.
   * @return A future for the Sound for the asset.
   */
  public static function cacheSound(assetPath:AssetPath):Future<Sound>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    return FunkinAssetCache.instance.cacheSound(assetPath);
  }

  /**
   * Cache the Text for the given asset path, asynchronously.
   * @param assetPath The path of the asset to cache.
   * @return A future for the Text for the asset.
   */
  public static function cacheText(assetPath:AssetPath):Future<String>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.txt()?';

    return FunkinAssetCache.instance.cacheText(assetPath);
  }

  /**
   * Cache the bytes for the given asset path, asynchronously.
   * @param assetPath The path of the asset to cache.
   * @return A future for the bytes for the asset.
   */
  public static function cacheBytes(assetPath:AssetPath):Future<openfl.utils.ByteArray>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    return FunkinAssetCache.instance.cacheBytes(assetPath);
  }

  /**
   * Cache the BitmapDatas for all the given asset paths, asynchronously.
   * @param assetPaths The paths of the assets to cache.
   * @param uploadToGPU Whether to upload the bitmap datas to the GPU, saving memory.
   * @return A future for an array of results.
   */
  public static function cacheAllBitmapData(assetPaths:Array<AssetPath>, uploadToGPU:Bool = true):Future<Array<Future<BitmapData>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<BitmapData>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheBitmapData(assetPath, uploadToGPU));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the FlxGraphics for all the given asset paths, asynchronously.
   * @param assetPaths The paths of the assets to cache.
   * @param uploadToGPU Whether to use GPU caching for this graphic.
   * @return A future for an array of results.
   */
  public static function cacheAllFlxGraphics(assetPaths:Array<AssetPath>, uploadToGPU:Bool = true):Future<Array<Future<FlxGraphic>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<FlxGraphic>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheFlxGraphic(assetPath, uploadToGPU));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the Sound for all the given asset paths, asynchronously.
   * @param assetPaths The paths of the assets to cache.
   * @return A future for an array of results.
   */
  public static function cacheAllSounds(assetPaths:Array<AssetPath>):Future<Array<Future<Sound>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Sound>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheSound(assetPath));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the Text for all the given asset paths, asynchronously.
   * @param assetPaths The paths of the assets to cache.
   * @return A future for an array of results.
   */
  public static function cacheAllText(assetPaths:Array<AssetPath>):Future<Array<Future<String>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<String>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheText(assetPath));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the Bytes for all the given asset paths, asynchronously.
   * @param assetPaths The paths of the assets to cache.
   * @return A future for an array of results.
   */
  public static function cacheAllBytes(assetPaths:Array<AssetPath>):Future<Array<Future<openfl.utils.ByteArray>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<openfl.utils.ByteArray>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheBytes(assetPath));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Return true if the graphic at the given asset path exists, and has been cached by a loading screen.
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isFlxGraphicCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.hasFlxGraphic(assetPath);
  }

  /**
   * Return a list of all the asset paths which should be available in all states.
   * @param type The type of asset to list.
   * @return The list of asset paths that are needed by every state.
   */
  public static function queryPersistentAssets(type:AssetType):Array<AssetPath>
  {
    if (type == null) throw 'Input is not a valid AssetType';

    var results:Array<AssetPath> = [];

    // results = results;.concat(funkin.input.Cursor.queryAssets(type));
    // results = results;.concat(funkin.ui.transition.Transition.queryAssets(type));
    // results = results;.concat(funkin.api.newgrounds.Medals.queryAssets(type));

    switch (type)
    {
      case IMAGE:
        results = results.concat([
          // Built-in
          Paths.file('images/logo/default', 'png', 'flixel'), // Fonts

          Paths.image('ui/fonts/default'),
          Paths.image('ui/fonts/bold'), // Soundtray

          Paths.image('ui/soundtray/volume-box'),
          Paths.image('ui/soundtray/bars-01'),
          Paths.image('ui/soundtray/bars-02'),
          Paths.image('ui/soundtray/bars-03'),
          Paths.image('ui/soundtray/bars-04'),
          Paths.image('ui/soundtray/bars-05'),
          Paths.image('ui/soundtray/bars-06'),
          Paths.image('ui/soundtray/bars-07'),
          Paths.image('ui/soundtray/bars-08'),
          Paths.image('ui/soundtray/bars-09'),
          Paths.image('ui/soundtray/bars-10'), // Medals,
        ]);

        results = results.concat(Paths.animateAtlas('ui/medals/medal-popup').image());
        results = results.concat([
          // Built-in
          Paths.file('sounds/beep', 'ogg', 'flixel'), // Menus

          Paths.sound('ui/main-menu/scroll-menu'),
          Paths.sound('ui/main-menu/confirm-menu'),
          Paths.sound('ui/main-menu/cancel-menu'), // Soundtray

          Paths.sound('ui/soundtray/volume-up'),
          Paths.sound('ui/soundtray/volume-down'),
          Paths.sound('ui/soundtray/volume-max'), // Screenshots

          Paths.sound('ui/main-menu/screenshot'),
        ]);

      case XML:
        results = results.concat([
          // Fonts
          Paths.xml('ui/fonts/default'),
          Paths.xml('ui/fonts/bold'),
        ]);

      case SHADER:
        results = results.concat([Paths.frag('ui/shaders/custom-blend'), // Powers custom blend modes on FunkinCamera
        ]);

      default:
        // Nothing
        // results = results.concat([]);
    }
    return results;
  }

  /**
   * Returns a list of all the asset paths which should be cached before starting the game.
   * @param type The type of asset to list.
   * @return The list of asset paths which are needed by the preloader.
   */
  public static function queryPreloadAssets(type:AssetType):Array<AssetPath>
  {
    if (type == null) throw 'Input is not a valid AssetType';

    // Start with the assets we use in every state.
    var results:Array<AssetPath> = queryPersistentAssets(type);

    // Fetch assets required by each registry at startup.
    // This is mainly used to fetch JSON data to register entries in each registry.
    // These will get uncached after the game starts but we don't need them anymore at that point.
    // results = results;.concat(SongRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(LevelRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(NoteStyleRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(PlayerRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(ConversationRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(DialogueBoxRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(SpeakerRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(FreeplayStyleRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(AlbumRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(StickerRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(StageRegistry.instance.queryRegistryAssets(type).filterNull());
    // results = results;.concat(CharacterDataParser.queryRegistryAssets(type).filterNull());

    // We need the assets used to render the first state.
    // results = results;.concat(funkin.ui.title.TitleState.queryAssets(type));

    switch (type)
    {
      case SCRIPTED_CLASS:
        // Cache all scripted class files
        results = results.concat(Assets.list(SCRIPTED_CLASS));
      case SCRIPT:
        // Cache all script files
        results = results.concat(Assets.list(SCRIPT));
      case FONT:
        // Cache all script files
        results = results.concat(Assets.list(FONT));
      default:
        // Nothing
    }

    return results;
  }

  /**
   * Determines whether the given asset of the given type exists.
   * @param path The path to check
   * @param type The asset type to check
   * @return Whether the asset exists
   */
  public static function exists(path:String, ?type:openfl.utils.AssetType):Bool
  {
    return openfl.utils.Assets.exists(path, type);
  }

  /**
   * Check whether the given asset at the given path exists.
   * @param assetPath The path to check
   * @return Whether the asset exists
   */
  public static function assetExists(assetPath:AssetPath):Bool
  {
    // If asset cache is not initialized, manifest probably won't be either, so we just assume the file is there.
    // TODO: Asset cache isn't getting initialized, fix it before uncommenting this!
    // if (!initialized) return true;

    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call a function from funkin.Paths?';

    return openfl.utils.Assets.exists(assetPath.toString());
  }

  /**
   * Get the file system path for an asset
   * @param assetPath The asset path to load from, relative to the assets folder
   * @return The path to the asset on the file system
   */
  public static function getPath(assetPath:AssetPath):String
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call a function from funkin.Paths?';

    return openfl.utils.Assets.getPath(assetPath.toString());
  }

  /**
   * Retrieve a list of all assets paths matching the given type
   * @param type The asset type to check
   * @return A list of asset paths
   */
  public static function list(?type:AssetType):Array<AssetPath>
  {
    return FunkinAssetCache.instance.list(type);
  }

  /**
   * Retrieve a list of all assets paths matching the given type within the given folder.
   * @param path The path to filter by
   * @param type (optional) The asset type to check
   * @param defaultPrefix Whether to
   * @return A list of asset paths within the given folder
   */
  public static function listInPath(path:String, ?type:AssetType, defaultPrefix:Bool = true):Array<AssetPath>
  {
    var results:Array<AssetPath> = list(type);

    // We don't need to cache this filter operation because it only takes a couple nanoseconds.
    var prefix:String = defaultPrefix ? 'assets/$path' : path;
    return results.filter((assetPath:AssetPath) ->
    {
      return assetPath.exists() && assetPath.toString().startsWith(prefix);
    });
  }

  /**
   * Return true if an asset library of the given name exists.
   * @param name The name of the library to check for
   * @return Whether it exists.
   */
  public static function hasLibrary(name:String):Bool
  {
    return openfl.utils.Assets.hasLibrary(name);
  }

  /**
   * Retrieve the asset library of the given name, synchronously.
   * @param name The name of the asset library to retrieve.
   * @return The asset library to load.
   */
  public static function getLibrary(name:String):lime.utils.AssetLibrary
  {
    return openfl.utils.Assets.getLibrary(name);
  }

  /**
   * Retrieve the asset library of the given name, asynchronously.
   * @param name The name of the asset library to retrieve.
   * @return The asset library to load.
   */
  public static function loadLibrary(name:String):Future<openfl.utils.AssetLibrary>
  {
    return openfl.utils.Assets.loadLibrary(name);
  }
}

/**
 * Similar to Lime's AssetType system, but with MUSIC and SOUND consolidated into one value,
 * and with TEXT split into several values including JSON and XML.
 */
enum abstract AssetType(String) from String to String from LimeAssetType
{
  /**
   * Files in (*.png, *.jpg, *.webp, *.astc) format
   */
  public var IMAGE = 'IMAGE';

  /**
   * Files in (*.ogg and *.mp3) format
   */
  public var SOUND = 'SOUND';

  /**
   * Files in (*.mp4 and *.webm) format
   */
  public var VIDEO = 'VIDEO';

  /**
   * Files in (mainly *.txt and *.md, excludes JSON, XML, SHADER, SCRIPT) format
   */
  public var TEXT = 'TEXT';

  /**
   * Files in (*.json) format
   */
  public var JSON = 'JSON';

  /**
   * Files in (*.frag and *.vert) format
   */
  public var SHADER = 'SHADER';

  /**
   * Files in (*.hx) format
   */
  public var SCRIPT = 'SCRIPT';

  /**
   * Files in (*.hxc) format
   */
  public var SCRIPTED_CLASS = 'SCRIPTED_CLASS';

  /**
   * Files in (*.fnfc) format
   */
  public var CHART = 'CHART';

  /**
   * Files in (*.fnfs) format
   */
  public var STAGE = 'STAGE';

  /**
   * Files in (*.xml) format
   */
  public var XML = 'XML';

  /**
   * Files in (*.otf and *.ttf) format
   */
  public var FONT = 'FONT';

  /**
   * Files in an
   */
  public var UNKNOWN = 'UNKNOWN';
}
