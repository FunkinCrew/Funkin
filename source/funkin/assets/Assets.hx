package funkin.assets;

import animate.FlxAnimateFrames;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;
import flixel.system.frontEnds.AssetFrontEnd.FlxAssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.graphics.FunkinSprite.AtlasSpriteSettings;
import funkin.util.macro.ConsoleMacro.ConsoleClass;
import lime.app.Future;
import lime.app.Promises;
import lime.text.Font;
import lime.utils.AssetType as LimeAssetType;
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType as OpenFLAssetType;
import openfl.utils.Assets as OpenFLAssets;
//
// ~PATHS~
//
import funkin.assets.ValidatedPaths as Paths;

using StringTools;
using funkin.graphics.framebuffer.BitmapDataUtil;

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
   * Perform initialization for internal asset management.
   */
  @:access(funkin.assets.FunkinAssetCache, funkin.assets.FuunkinBitmapFrontend)
  public static function initialize():Void
  {
    if (initialized) return;
    initialized = true;

    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Initializing asset management...');
    #end

    // Enable our custom asset caches
    LimeAssets.cache = funkin.assets.FunkinAssetCache.FunkinLimeAssetCache.instance;
    OpenFLAssets.cache = funkin.assets.FunkinAssetCache.FunkinAssetCache.instance;
    untyped FlxG.bitmap = funkin.assets.FunkinBitmapFrontend.instance;

    animate.FlxAnimateAssets.getText = (path) -> Assets.getText(Paths.raw(path));
    animate.FlxAnimateAssets.getBytes = (path) -> Assets.getBytes(Paths.raw(path));
    animate.FlxAnimateAssets.getBitmapData = (path) -> Assets.getBitmapData(Paths.raw(path));

    FlxG.assets.getAssetUnsafe = flxGetAssetUnsafe;
    FlxG.assets.loadAsset = flxLoadAsset;
    FlxG.assets.exists = flxExists;
    FlxG.assets.isLocal = flxIsLocal;
    FlxG.assets.list = flxList;

    FunkinAssetCache.instance.cacheAssetLists(true);
  }

  /**
   * List data files that match the given prefix and suffix.
   *
   * @param path A path prefix for the data file name.
   * @param suffix A path suffix for the data file name.
   * @param blacklist An array of paths to exclude from the list.
   * @param nested Whether to parse nested data files as only the last part of the path.
   * Use `true`, if you expect files will be at `<path>/<id>/<id><suffix>`.
   * @return A list of results, with path and extension removed.
   */
  public static function listDataFilesInPath(path:String, suffix:String = '.json', ?blacklist:Array<String>, nested:Bool = false):Array<String>
  {
    var queryPath:String = 'assets/${path}';
    var textAssets:Array<String> = openfl.utils.Assets.list(TEXT);

    var results:Array<String> = [];
    for (textPath in textAssets)
    {
      // Filter matching assets
      if (!StringTools.startsWith(textPath, queryPath) || !StringTools.endsWith(textPath, suffix)) continue;

      // Isolate raw path
      var pathNoPrefix:String = textPath.substring(queryPath.length, textPath.length - suffix.length);
      var id:String = nested ? pathNoPrefix.split('/')[0] : pathNoPrefix;

      if (nested && !StringTools.endsWith(textPath, '$id$suffix')) continue;

      if (blacklist != null && blacklist.contains(id)) continue;

      results.pushUnique(id);
    }

    return results;
  }

  /**
   * Retrieve the BitmapData from the given asset path.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The path of the asset to retrieve.
   * @return The BitmapData for the asset.
   */
  public static function getBitmapData(assetPath:AssetPath):BitmapData
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Assets.getBitmapData(${assetPath.toString()})');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    if (FunkinAssetCache.instance.hasBitmapData(assetPath.toString()))
    {
      var result:Null<BitmapData> = FunkinAssetCache.instance.getBitmapData(assetPath.toString());

      if (result != null && FunkinAssetCache.instance.validateBitmapData(result))
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Bitmap data found in cache: ${assetPath.toString()}');
        #end
        return result;
      }
      else
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' INVALID bitmap data found in cache, purging and re-fetching: ${assetPath.toString()}');
        #end
        FunkinAssetCache.instance.removeBitmapData(assetPath.toString());
      }
    }

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'Bitmap data not cached, cannot load synchronously: ${assetPath.toString()}';
    #else
    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Bitmap data not found in cache: ${assetPath.toString()}');
    #end
    if (!assetPath.exists())
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Bitmap file does not exist: ${assetPath.toString()}');
      funkin.util.DebugUtil.printCallStack();
      #end
      throw 'Bitmap file does not exist: ${assetPath.toString()}';
    }
    // Fetch the asset synchronously.
    // NOTE: This WILL cause stutters! Try to use `cacheBitmapData()` so we don't end up here.
    var bitmapData:BitmapData = OpenFLAssets.getBitmapData(assetPath.toString(), false, !assetPath.needsPixelData, !assetPath.needsPixelData);
    // Upload the texture to the GPU immediately so we don't have to do it later.
    bitmapData.toGPU(false);
    FunkinAssetCache.instance.setBitmapData(assetPath.toString(), bitmapData);
    return bitmapData;
    #end
  }

  /**
   * Retrieve the FlxGraphic from the given asset path.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The path of the asset to retrieve.
   * @throws error If the asset isn't cached.
   * @return The FlxGraphic for the asset.
   */
  public static function getFlxGraphic(assetPath:AssetPath):FlxGraphic
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Assets.getFlxGraphic(${assetPath.toString()})');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    if (FunkinAssetCache.instance.hasFlxGraphic(assetPath.toString()) || FunkinAssetCache.instance.hasBitmapData(assetPath.toString()))
    {
      var result:Null<FlxGraphic> = FunkinAssetCache.instance.getFlxGraphic(assetPath.toString());

      if (FunkinAssetCache.instance.validateFlxGraphic(result))
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' FlxGraphic found in cache: ${assetPath.toString()}');
        #end
        return result;
      }
      else
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' INVALID FlxGraphic found in cache, purging and re-fetching: ${assetPath.toString()}');
        #end
        FunkinAssetCache.instance.removeFlxGraphic(assetPath.toString());
      }
    }

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'FlxGraphic not cached, cannot load synchronously: ${assetPath.toString()}';
    #else
    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Bitmap data not found in cache: ${assetPath.toString()}');
    #end
    if (!assetPath.exists())
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Bitmap file does not exist: ${assetPath.toString()}');
      funkin.util.DebugUtil.printCallStack();
      #end
      throw 'Bitmap file does not exist: ${assetPath.toString()}';
    }
    // Fetch the asset synchronously.
    // NOTE: This WILL cause stutters! Try to use `cacheBitmapData()` so we don't end up here.
    var bitmapData:BitmapData = OpenFLAssets.getBitmapData(assetPath.toString(), false, !assetPath.needsPixelData, !assetPath.needsPixelData);
    // Upload the texture to the GPU immediately so we don't have to do it later.
    bitmapData.toGPU(false);
    FunkinAssetCache.instance.setBitmapData(assetPath.toString(), bitmapData);
    return FunkinAssetCache.instance.setFlxGraphic(assetPath.toString(), bitmapData);
    #end
  }

  /**
   * Retrieve a spritesheet's image and data files, and create a FlxAtlasFrames object.
   * May cause stutters or throw an error if the assets are not cached.
   *
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the XML is next to it.
   * @return The generated FlxAtlasFrames.
   */
  public static function getSparrowAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Assets.getSparrowAtlas(${assetPath.toString()})');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';
    if (!assetPath.isAssetType(IMAGE)) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_STRICT_ASSET_CACHING
    if (isFlxGraphicCached(assetPath.image()))
    {
      var xmlAssetPath = assetPath.withAssetType(XML);

      var graphic:FlxGraphic = getFlxGraphic(assetPath.toString());
      // We don't really mind reading the text synchronously I guess.
      var data:String = getText(xmlAssetPath.toString());
      return FlxAtlasFrames.fromSparrow(graphic, data);
    }
    else
    {
      throw 'Asset not cached, cannot load synchronously: ${assetPath.image()}';
    }
    #else
    var xmlAssetPath = assetPath.withAssetType(XML);

    // Fetch the asset synchronously.
    // NOTE: This may cause stutters.
    var graphic:FlxGraphic = getFlxGraphic(assetPath);
    var data:String = getText(xmlAssetPath);
    return FlxAtlasFrames.fromSparrow(graphic, data);
    #end
  }

  /**
   * Retrieve a spritesheet's image and data files, and create a FlxAtlasFrames object.
   * May cause stutters or throw an error if the assets are not cached.
   *
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the TXT is next to it.
   * @return The generated FlxAtlasFrames.
   */
  public static function getPackerAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getPackerAtlas(${assetPath.toString()})');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    #if FEATURE_STRICT_ASSET_CACHING
    if (isFlxGraphicCached(assetPath.image()))
    {
      var txtAssetPath = assetPath.withAssetType(TEXT);

      var graphic:FlxGraphic = getFlxGraphic(assetPath.toString());
      // We don't really mind reading the text synchronously I guess.
      var data:String = getText(txtAssetPath.toString());
      return FlxAtlasFrames.fromSpriteSheetPacker(graphic, data);
    }
    else
    {
      throw 'Asset not cached, cannot load synchronously: ${assetPath.image()}';
    }
    #else
    var txtAssetPath = assetPath.withAssetType(TEXT);

    // Fetch the asset synchronously.
    // NOTE: This may cause stutters.
    var graphic:FlxGraphic = getFlxGraphic(assetPath);
    var data:String = getText(txtAssetPath);
    return FlxAtlasFrames.fromSpriteSheetPacker(graphic, data);
    #end
  }

  /**
   * Retrieve an Adobe Animate texture atlas's sprite frames, and parse and load them.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to the texture atlas. Use `Paths.animateAtlas` to build this.
   * @param settings Additional settings to use when loading the atlas sprite.
   * @return The generated FlxAnimateFrames.
   */
  public static function getAnimateAtlas(assetPath:AnimateAtlasAssetPathBuilder,
    settings:AtlasSpriteSettings):FlxAnimateFrames
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
      postStageMatrixApply: settings?.postStageMatrixApply ?? false,
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

    return FlxAnimateFrames.fromAnimate(
      assetPath.toString(),
      validatedSettings.spritemaps,
      validatedSettings.metadataJson,
      validatedSettings.cacheKey,
      validatedSettings.uniqueInCache,
      {
        swfMode: validatedSettings.swfMode,
        cacheOnLoad: validatedSettings.cacheOnLoad,
        filterQuality: validatedSettings.filterQuality,
        onSymbolCreate: validatedSettings.onSymbolCreate
      }
    );
  }

  /**
   * Retrieves a Bitmap from the given asset path, and builds a monospace Bitmap font from it.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to load the texture from.
   * @param fontLetters The letters to use in the font, in order.
   * @param letterSize The width and height of each letter, in pixels.
   * @return The generated FlxBitmapFont.
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
    return FlxBitmapFont.fromMonospace(Assets.getBitmapData(assetPath), fontLetters, letterSize);
    #end
  }

  /**
   * Retrieves a Bitmap and `.fnt` data from the given asset path, and builds a Bitmap font from it.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to load the texture from.
   *   Assume there is a corresponding `.fnt` file to locate each letter.
   * @return The generated FlxBitmapFont.
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
    return FlxBitmapFont.fromAngelCode(Assets.getBitmapData(assetPath), Assets.getText(assetPath.withExt('fnt')));
    #end
  }

  /**
   * Retrieves byte data from the given asset path.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to load from.
   * @return The byte contents of the file.
   */
  public static function getBytes(assetPath:AssetPath):haxe.io.Bytes
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Asset.getBytes(${assetPath.toString()})');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    var bytes = FunkinAssetCache.instance.getBytes(assetPath.toString());
    if (bytes != null) return bytes;

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'Bytes not cached, cannot load synchronously: ${assetPath.toString()}';
    #else
    if (!assetPath.exists())
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Bytes file does not exist: ${assetPath.toString()}');
      funkin.util.DebugUtil.printCallStack();
      #end
      throw 'Bytes file does not exist: ${assetPath.toString()}';
    }

    // Fetch the asset synchronously.
    // NOTE: This may cause stutters.
    var bytes:openfl.utils.ByteArray = OpenFLAssets.getBytes(assetPath.toString());
    FunkinAssetCache.instance.setBytes(assetPath.toString(), bytes);
    return bytes;
    #end
  }

  /**
   * Retrieves text from the given asset path.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to load from.
   * @return The text contents of the file.
   */
  public static function getText(assetPath:AssetPath):String
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Assets.getText(${assetPath.toString()})');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.txt()?';

    var text = FunkinAssetCache.instance.getText(assetPath.toString());
    if (text != null) return text;

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'Text not cached, cannot load synchronously: ${assetPath.toString()}';
    #else
    if (!assetPath.exists())
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Text file does not exist: ${assetPath.toString()}');
      funkin.util.DebugUtil.printCallStack();
      #end
      throw 'Text file does not exist: ${assetPath.toString()}';
    }

    // Fetch the asset synchronously.
    // NOTE: This may cause stutters.
    var text:String = OpenFLAssets.getText(assetPath.toString());
    FunkinAssetCache.instance.setText(assetPath.toString(), text);
    return text;
    #end
  }

  /**
   * Retrieves a Sound from the given asset path.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to load from.
   * @return The loaded sound.
   */
  public static function getSound(assetPath:AssetPath):openfl.media.Sound
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Assets.getSound($id)');
    #end
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    var sound = FunkinAssetCache.instance.getSound(assetPath.toString());
    if (sound != null) return sound;

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'Sound not cached, cannot load synchronously: $id';
    #else
    if (!assetPath.exists())
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Sound file does not exist: ${assetPath.toString()}');
      funkin.util.DebugUtil.printCallStack();
      #end
      throw 'Sound file does not exist: ${assetPath.toString()}';
    }

    // Fetch the asset synchronously.
    // NOTE: This may cause stutters.
    var sound:Sound = OpenFLAssets.getSound(assetPath.toString());
    FunkinAssetCache.instance.setSound(assetPath.toString(), sound);
    return sound;
    #end
  }

  /**
   * Get a Font, if it exists in the cache.
   * @param id The asset id of the Font.
   * @throws error If the Font does not exist in the cache and strict asset caching is enabled.
   * @return The Font, if available.
   */
  public function getFont(id:String):Font
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('Assets.getFont($id)');
    #end

    var font = FunkinAssetCache.instance.getFont(id);
    if (font != null) return font;

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'Font not cached, cannot load synchronously: $id';
    #else
    // Fetch the font synchronously. This will cause the game to stutter.
    if (!OpenFLAssets.exists(id))
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Font file does not exist: ${id}');
      funkin.util.DebugUtil.printCallStack();
      #end
      throw 'Font file does not exist: ${id}';
    }

    // Fetch the asset synchronously.
    // NOTE: This may cause stutters.
    var font:openfl.text.Font = OpenFLAssets.getFont(id);
    FunkinAssetCache.instance.setFont(id, font);
    return font;
    #end
  }

  /**
   * Retrieves a Sound file from the given asset path, with optimizations specific to long-duration music.
   * May cause stutters or throw an error if the asset is not cached.
   *
   * @param assetPath The asset path to load from.
   * @return The loaded sound.
   */
  public static function getMusic(assetPath:MusicAssetPathBuilder):openfl.media.Sound
  {
    if (assetPath == null) throw 'Input is not a valid Music AssetPath, did you call Paths.music()?';

    return getSound(assetPath.audio());
  }

  /**
   * Retrieves the BitmapData from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to retrieve.
   * @return A future for the BitmapData for the asset.
   */
  public static function loadBitmapData(assetPath:AssetPath):Future<BitmapData>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.fetchBitmapData(assetPath);
  }

  /**
   * Retrieves the FlxGraphic from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to retrieve.
   * @return A future for the FlxGraphic for the asset.
   */
  public static function loadFlxGraphic(assetPath:AssetPath):Future<FlxGraphic>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.fetchFlxGraphic(assetPath);
  }

  /**
   * Retrieves byte data from the given asset path, asynchronously.
   *
   * @param assetPath The asset path to load from.
   * @return A future which promises to return the byte contents of the file.
   */
  public static function loadBytes(assetPath:AssetPath):Future<openfl.utils.ByteArray>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    return FunkinAssetCache.instance.fetchBytes(assetPath);
  }

  /**
   * Load text from the given asset path, asynchronously.
   *
   * @param assetPath The asset path to load from.
   * @return A future which promises to return the text contents of the file.
   */
  public static function loadText(assetPath:AssetPath):Future<String>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.txt()?';

    return FunkinAssetCache.instance.fetchText(assetPath);
  }

  /**
   * Load a Sound file from the given asset path, asynchronously.
   *
   * @param assetPath The asset path to load from.
   * @return A future which promises to return the loaded sound.
   */
  public static function loadSound(assetPath:AssetPath):Future<openfl.media.Sound>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    return FunkinAssetCache.instance.fetchSound(assetPath);
  }

  /**
   * Load a Sound file from the given asset path, with optimizations specific to long-duration music, asynchronously.
   *
   * @param assetPath The asset path to load from.
   * @return A future which promises to return the loaded sound.
   */
  public static function loadMusic(assetPath:MusicAssetPathBuilder):Future<openfl.media.Sound>
  {
    if (assetPath == null) throw 'Input is not a valid Music AssetPath, did you call Paths.music()?';

    return FunkinAssetCache.instance.fetchSound(assetPath.audio());
  }

  /**
   * Fetch a spritesheet's image and data files, and create a FlxAtlasFrames object, asynchronously.
   *
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
   * Fetch a spritesheet's image and data files, and create a FlxAtlasFrames object, asynchronously.
   *
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
   * Load a Sound file from the given asset path, asynchronously.
   *
   * @param assetPath The asset path to load from.
   * @return A future which promises to return the loaded sound.
   */
  public static function loadFont(assetPath:AssetPath):Future<openfl.text.Font>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.font()?';

    return FunkinAssetCache.instance.fetchFont(assetPath);
  }

  /**
   * Cache the BitmapData from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the BitmapData for the asset.
   */
  public static function cacheBitmapData(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.cacheBitmapData(assetPath, permanent);
  }

  /**
   * Cache the FlxGraphic from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the FlxGraphic for the asset.
   */
  public static function cacheFlxGraphic(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.cacheFlxGraphic(assetPath, permanent);
  }

  /**
   * Cache the Sound from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the Sound for the asset.
   */
  public static function cacheSound(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    return FunkinAssetCache.instance.cacheSound(assetPath, permanent);
  }

  /**
   * Cache the text from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the Text for the asset.
   */
  public static function cacheText(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.txt()?';

    return FunkinAssetCache.instance.cacheText(assetPath, permanent);
  }

  /**
   * Cache the byte data from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the bytes for the asset.
   */
  public static function cacheBytes(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    return FunkinAssetCache.instance.cacheBytes(assetPath, permanent);
  }

  /**
   * Cache the font data from the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the font for the asset.
   */
  public static function cacheFont(assetPath:AssetPath):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.font()?';

    return FunkinAssetCache.instance.cacheFont(assetPath);
  }

  /**
   * Cache the asset from the given asset path, asynchronously.
   * Determines the asset type and guesses the correct caching function.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future for the bytes for the asset.
   */
  public static function cacheAsset(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    switch (assetPath.getAssetType())
    {
      case IMAGE:
        return cacheFlxGraphic(assetPath, permanent);

      case SOUND:
        return cacheSound(assetPath, permanent);

      case TEXT | JSON | SHADER | SCRIPT | SCRIPTED_CLASS | XML:
        return cacheText(assetPath, permanent);

      case FONT:
        return cacheFont(assetPath);

      case VIDEO | CHART | STAGE | UNKNOWN:
        return cacheBytes(assetPath, permanent);

      default:
        return cacheBytes(assetPath, permanent);
    }
  }

  /**
   * Cache the BitmapDatas for all the given asset paths, asynchronously.
   *
   * @param assetPaths The paths of the assets to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future, which provides progress updates for each cached asset, and an array of results when completed.
   */
  public static function cacheAllBitmapData(assetPaths:Array<AssetPath>, permanent:Bool = false):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheBitmapData(assetPath, permanent));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the FlxGraphics for all the given asset paths, asynchronously.
   *
   * @param assetPaths The paths of the assets to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future, which provides progress updates for each cached asset, and an array of results when completed.
   */
  public static function cacheAllFlxGraphics(assetPaths:Array<AssetPath>, permanent:Bool = false):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheFlxGraphic(assetPath, permanent));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the Sound for all the given asset paths, asynchronously.
   *
   * @param assetPaths The paths of the assets to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future, which provides progress updates for each cached asset, and an array of results when completed.
   */
  public static function cacheAllSounds(assetPaths:Array<AssetPath>, permanent:Bool = false):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheSound(assetPath, permanent));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the Text for all the given asset paths, asynchronously.
   *
   * @param assetPaths The paths of the assets to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future, which provides progress updates for each cached asset, and an array of results when completed.
   */
  public static function cacheAllText(assetPaths:Array<AssetPath>, permanent:Bool = false):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheText(assetPath, permanent));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the font for all the given asset paths, asynchronously.
   *
   * @param assetPaths The paths of the assets to cache.
   * @return A future, which provides progress updates for each cached font, and an array of results when completed.
   */
  public static function cacheAllFonts(assetPaths:Array<AssetPath>):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheFont(assetPath));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache the Bytes for all the given asset paths, asynchronously.
   *
   * @param assetPaths The paths of the assets to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future, which provides progress updates for each cached asset, and an array of results when completed.
   */
  public static function cacheAllBytes(assetPaths:Array<AssetPath>, permanent:Bool = false):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheBytes(assetPath, permanent));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Cache all the given asset paths, asynchronously.
   * Determines the asset type and guesses the correct caching function.
   *
   * @param assetPaths The paths of the assets to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future, which provides progress updates for each cached asset, and an array of results when completed.
   */
  public static function cacheAll(assetPaths:Array<AssetPath>, permanent:Bool = false):Future<Array<Future<Bool>>>
  {
    // Exclude null values, and ensure each path is only loaded once.
    assetPaths = (assetPaths ?? []).filterNull().distinct(AssetPath.equals);

    if (assetPaths.length == 0) return Future.withValue([]);

    var futures:Array<Future<Bool>> = [];

    for (assetPath in assetPaths)
    {
      futures.push(cacheAsset(assetPath));
    }

    return Promises.allSettled(futures);
  }

  /**
   * Return true if the graphic at the given asset path exists, and has been cached by a loading screen.
   *
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isFlxGraphicCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.hasFlxGraphic(assetPath.toString());
  }

  /**
   * Return true if the bitmap data at the given asset path exists, and has been cached by a loading screen.
   *
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isBitmapDataCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.image()?';

    return FunkinAssetCache.instance.hasBitmapData(assetPath.toString());
  }

  /**
   * Return true if the sound at the given asset path exists, and has been cached by a loading screen.
   *
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isSoundCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.sound()?';

    return FunkinAssetCache.instance.hasSound(assetPath.toString());
  }

  /**
   * Return true if the text at the given asset path exists, and has been cached by a loading screen.
   *
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isTextCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.text()?';

    return FunkinAssetCache.instance.hasText(assetPath.toString());
  }

  /**
   * Return true if the byte data at the given asset path exists, and has been cached by a loading screen.
   *
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isBytesCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    return FunkinAssetCache.instance.hasBytes(assetPath.toString());
  }

  /**
   * Return true if the asset at the given asset path exists, and has been cached by a loading screen.
   *
   * @param assetPath The asset path to check.
   * @return Whether it is currently cached.
   */
  public static function isAssetCached(assetPath:AssetPath):Bool
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.file()?';

    switch (assetPath.getAssetType())
    {
      case IMAGE:
        return isFlxGraphicCached(assetPath);

      case SOUND:
        return isSoundCached(assetPath);

      case TEXT | JSON | SHADER | SCRIPT | SCRIPTED_CLASS | XML:
        return isTextCached(assetPath);

      case VIDEO | CHART | STAGE | FONT | UNKNOWN:
        return isBytesCached(assetPath);

      default:
        return isBytesCached(assetPath);
    }
  }

  /**
   * Return a list of all the asset paths which should be available in all states.
   *
   * @param type The type of asset to list.
   * @return The list of asset paths that are needed by every state.
   */
  public static function queryPersistentAssets(type:AssetType):Array<AssetPath>
  {
    if (type == null) throw 'Input is not a valid AssetType';

    var results:Array<AssetPath> = [];

    // Keep the cursor assets cached persistently, since they could be used at any time.
    results = results.concat(funkin.input.Cursor.queryAssets(type));

    #if FEATURE_NEWGROUNDS
    // Keep the medal popup assets cached persistently, since it could show up at any time.
    results = results.concat(funkin.api.newgrounds.Medals.queryAssets(type));
    #end

    // Keep transition assets cached persistently, since we don't want to require a loading screen FOR a loading screen.
    // results = results.concat(funkin.ui.transition.Transition.queryAssets(type));

    switch (type)
    {
      case IMAGE:
        results.appendUnique([
          // Built-in
          Paths.file('images/logo/default', 'png', true, 'flixel'),

          // Fonts
          Paths.image('ui/fonts/default'),
          Paths.image('ui/fonts/bold'),
          Paths.image('ui/fonts/freeplay-clear'),
          Paths.image('ui/fonts/vcr-bmp'),

          // Soundtray
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
          Paths.image('ui/soundtray/bars-10'),

          #if mobile
          // Kevin and Michael.
          Paths.image('ui/cursor/mobile/michael'), Paths.image('ui/cursor/mobile/kevin'),
          #end
        ]);

      case SOUND:
        results.appendUnique([
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

      case JSON:
        // Medal popup
        results.appendUnique(Paths.animateAtlas('ui/medals/medal-popup').json());

      case XML:
        results.appendUnique([
          // Fonts
          Paths.xml('ui/fonts/default'),
          Paths.xml('ui/fonts/bold'),
        ]);

      case SHADER:
        results.appendUnique([Paths.frag('ui/shaders/custom-blend'), // Powers custom blend modes on FunkinCamera
        ]);

      case FONT:
        // Permenent precache ALL fonts.
        results.appendUnique(Assets.list(FONT));

      case TEXT:
        results.appendUnique([Paths.file('ui/fonts/vcr-bmp', 'fnt')]);

      default:
        // Nothing
        // results.appendUnique([]);
    }
    return results;
  }

  /**
   * Returns a list of all the asset paths which should be cached before starting the game.
   *
   * @param type The type of asset to list.
   * @return The list of asset paths which are needed by the preloader.
   */
  public static function queryPreloadAssets(type:AssetType):Array<AssetPath>
  {
    if (type == null) throw 'Input is not a valid AssetType';

    var results:Array<AssetPath> = [];

    // Start with the assets we use in every state.
    results.appendUnique(queryPersistentAssets(type));

    // Registry JSON data doesn't need to be included here.
    // This is because the registry entries are loaded asynchronously,
    // and there's no stutter from loading the JSON data in those threads.

    // We need the assets used to render the first state.
    // results.appendUnique(funkin.ui.title.TitleState.queryAssets(type));

    switch (type)
    {
      case SCRIPTED_CLASS:
        // Cache all scripted class files
        results.appendUnique(Assets.list(SCRIPTED_CLASS));
      case SCRIPT:
        // Cache all script files
        results.appendUnique(Assets.list(SCRIPT));
      case FONT:
        // Cache all font files
        results.appendUnique(Assets.list(FONT));
      default:
        // Nothing
    }

    return results;
  }

  /**
   * Determines whether the given asset of the given type exists.
   *
   * @param path The path to check.
   * @param type The asset type to check.
   * @return Whether the asset exists.
   */
  public static function exists(path:String, ?type:openfl.utils.AssetType):Bool
  {
    return openfl.utils.Assets.exists(path, type);
  }

  /**
   * Check whether the given asset at the given path exists.
   *
   * @param assetPath The path to check.
   * @return Whether the asset exists.
   */
  public static function assetExists(assetPath:AssetPath):Bool
  {
    // If asset cache is not initialized, manifest probably won't be either, so we just assume the file is there.
    if (!initialized) return true;

    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call a function from funkin.Paths?';

    return openfl.utils.Assets.exists(assetPath.toString());
  }

  /**
   * Get the file system path for an asset.
   *
   * @param assetPath The asset path to load from, relative to the assets folder.
   * @return The path to the asset on the file system.
   */
  public static function getPath(assetPath:AssetPath):String
  {
    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call a function from funkin.Paths?';

    return openfl.utils.Assets.getPath(assetPath.toString());
  }

  /**
   * Retrieve a list of all assets paths matching the given type.
   *
   * @param type The asset type to check.
   * @return A list of asset paths.
   */
  public static function list(?type:AssetType):Array<AssetPath>
  {
    return FunkinAssetCache.instance.list(type);
  }

  /**
   * Retrieve a list of all assets paths matching the given type within the given folder.
   *
   * @param path The path to filter by.
   * @param type (Optional) The asset type to check.
   * @param defaultPrefix Whether to use the default asset prefix.
   * @return A list of asset paths within the given folder.
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
   *
   * @param name The name of the library to check for.
   * @return Whether the asset library exists.
   */
  public static function hasLibrary(name:String):Bool
  {
    return openfl.utils.Assets.hasLibrary(name);
  }

  /**
   * Retrieve the asset library of the given name, synchronously.
   *
   * @param name The name of the asset library to retrieve.
   * @return The asset library to load.
   */
  public static function getLibrary(name:String):lime.utils.AssetLibrary
  {
    return openfl.utils.Assets.getLibrary(name);
  }

  /**
   * Retrieve the asset library of the given name, asynchronously.
   *
   * @param name The name of the asset library to retrieve.
   * @return The asset library to load.
   */
  public static function loadLibrary(name:String):Future<openfl.utils.AssetLibrary>
  {
    return openfl.utils.Assets.loadLibrary(name);
  }

  /**
   * Called when running `FlxG.assets.getAssetUnsafe()`.
   *
   * @param id The id of the asset, usually a path
   * @param type The type of asset to look for, determines the type
   * @param useCache IGNORED.
   * @return The asset, if found, otherwise `null` is returned
   */
  static function flxGetAssetUnsafe(id:String, type:FlxAssetType, useCache = true):Null<Any>
  {
    final VALIDATE = true;
    return switch (type)
    {
      case TEXT:
        funkin.assets.Assets.getText(Paths.raw(id, VALIDATE));
      case IMAGE:
        funkin.assets.Assets.getBitmapData(Paths.raw(id, VALIDATE));
      case SOUND:
        funkin.assets.Assets.getSound(Paths.raw(id, VALIDATE));
      case FONT:
        // uhhh idk
        OpenFLAssets.getFont(id, useCache);
      case BINARY:
        funkin.assets.Assets.getBytes(Paths.raw(id, VALIDATE));
    }
  }

  static function flxLoadAsset(id:String, type:FlxAssetType, useCache = true):Future<Any>
  {
    final VALIDATE = true;
    return switch (type)
    {
      case TEXT:
        Assets.loadText(Paths.txt(id));
      case IMAGE:
        Assets.loadBitmapData(Paths.image(id));
      case SOUND:
        Assets.loadSound(Paths.sound(id));
      case BINARY:
        Assets.loadBytes(Paths.raw(id, VALIDATE));
      case FONT:
        OpenFLAssets.loadFont(id, useCache);
    }
  }

  static function flxExists(id:String, ?type:FlxAssetType):Bool
  {
    final VALIDATE = false;
    return assetExists(Paths.raw(id, VALIDATE));
  }

  /**
   * We kinda change the behavior of this function a bit.
   *
   * If the Funkin asset cache has cached the asset, we consider it local,
   * since it can be retrieved synchronously.
   */
  static function flxIsLocal(id:String, ?type:FlxAssetType, useCache = true):Bool
  {
    #if FEATURE_STRICT_ASSET_CACHING
    final VALIDATE = false;
    return isAssetCached(Paths.raw(id, VALIDATE));
    #else
    // NOTE: If this returns false, Flixel doesn't let the game load the asset!
    return true;
    #end
  }

  static function flxList(?type:FlxAssetType):Array<String>
  {
    var result = list(type).map((assetPath) -> assetPath.toString());
    // trace('Assets.list(): $result');
    return result;
  }
}

/**
 * Similar to Lime's AssetType system, but with MUSIC and SOUND consolidated into one value,
 * and with TEXT split into several values including JSON and XML.
 */
@:nullSafety
enum abstract AssetType(String) from String to String from LimeAssetType
{
  /**
   * Files in (*.png, *.jpg, *.webp, *.astc) format.
   */
  public var IMAGE = 'IMAGE';

  /**
   * Files in (*.ogg and *.mp3) format.
   */
  public var SOUND = 'SOUND';

  /**
   * Files in (*.mp4 and *.webm) format.
   */
  public var VIDEO = 'VIDEO';

  /**
   * Files in (mainly *.txt and *.md, excludes JSON, XML, SHADER, SCRIPT) format.
   */
  public var TEXT = 'TEXT';

  /**
   * Files in (*.json) format.
   */
  public var JSON = 'JSON';

  /**
   * Files in (*.frag and *.vert) format.
   */
  public var SHADER = 'SHADER';

  /**
   * Files in (*.hx) format.
   */
  public var SCRIPT = 'SCRIPT';

  /**
   * Files in (*.hxc) format.
   */
  public var SCRIPTED_CLASS = 'SCRIPTED_CLASS';

  /**
   * Files in (*.fnfc) archive format.
   */
  public var CHART = 'CHART';

  /**
   * Files in (*.fnfs) archive format.
   */
  public var STAGE = 'STAGE';

  /**
   * Mods in (*.fnfmod) archive format.
   */
  public var MOD = 'MOD';

  /**
   * Files in (*.xml) format.
   */
  public var XML = 'XML';

  /**
   * Files in (*.otf and *.ttf) format.
   */
  public var FONT = 'FONT';

  /**
   * Files in (*.swf) format.
   */
  public var MOVIE_CLIP = 'MOVIE_CLIP';

  /**
   * Files in an undetermined file format.
   */
  public var UNKNOWN = 'UNKNOWN';

  /**
   * @param value The input LimeAssetType
   * @return Funkin AssetType
   */
  @:from
  public static function fromLimeAssetType(?value:LimeAssetType):Null<AssetType>
  {
    if (value == null) return null;

    switch (value)
    {
      case LimeAssetType.BINARY:
        return UNKNOWN;
      case LimeAssetType.FONT:
        return FONT;
      case LimeAssetType.IMAGE:
        return IMAGE;
      case LimeAssetType.MANIFEST:
        return TEXT;
      case LimeAssetType.MUSIC:
        return SOUND;
      case LimeAssetType.SOUND:
        return SOUND;
      case LimeAssetType.TEMPLATE:
        return TEXT;
      case LimeAssetType.TEXT:
        return TEXT;
      default:
        return cast value;
    }
  }

  /**
   * @param value The input OpenFLAssetType
   * @return Funkin AssetType
   */
  @:from
  public static function fromOpenFLAssetType(?value:OpenFLAssetType):Null<AssetType>
  {
    if (value == null) return null;

    switch (value)
    {
      case OpenFLAssetType.BINARY:
        return UNKNOWN;
      case OpenFLAssetType.FONT:
        return FONT;
      case OpenFLAssetType.IMAGE:
        return IMAGE;
      case OpenFLAssetType.MOVIE_CLIP:
        return MOVIE_CLIP;
      case OpenFLAssetType.MUSIC:
        return SOUND;
      case OpenFLAssetType.SOUND:
        return SOUND;
      case OpenFLAssetType.TEXT:
        return TEXT;

      default:
        return cast value;
    }
  }

  /**
   * @param value The input FlxAssetType
   * @return Funkin AssetType
   */
  @:from
  public static function fromFlxAssetType(?value:FlxAssetType):Null<AssetType>
  {
    if (value == null) return null;

    switch (value)
    {
      case FlxAssetType.BINARY:
        return UNKNOWN;
      case FlxAssetType.FONT:
        return FONT;
      case FlxAssetType.IMAGE:
        return IMAGE;
      case FlxAssetType.SOUND:
        return SOUND;
      case FlxAssetType.TEXT:
        return TEXT;

      default:
        return cast value;
    }
  }
}
