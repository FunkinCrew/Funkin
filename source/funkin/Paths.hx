package funkin;

import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimateFrames;
import funkin.graphics.FunkinSprite.AtlasSpriteSettings;
import openfl.utils.AssetType;
import funkin.util.macro.ConsoleMacro;
import haxe.io.Path;

using StringTools;

/**
 * A utility class which handles determining asset paths.
 */
@:nullSafety
class Paths implements ConsoleClass
{
  static var currentLevel:Null<String> = null;

  public static function setCurrentLevel(name:Null<String>):Void
  {
    if (name == null)
    {
      currentLevel = null;
    }
    else
    {
      currentLevel = name.toLowerCase();
    }
  }

  /**
   * Remove a library from an asset path string.
   * @param path The asset path string to remove the library from.
   * @return The asset path string without the library prefix.
   */
  public static function stripLibrary(path:String):String
  {
    var parts:Array<String> = path.split(':');
    if (parts.length < 2) return path;
    return parts[1];
  }

  /**
   * Fetch a library from an asset path string.
   * @param path The asset path string to get the library from.
   * @return The library name, or 'default' if no library is specified.
   */
  public static function getLibrary(path:String):String
  {
    var parts:Array<String> = path.split(':');
    if (parts.length < 2) return 'default';
    return parts[0];
  }

  static function getPath(file:String, type:AssetType, ?library:String):String
  {
    if (library != null) return getLibraryPath(file, library);

    var levelPath = getLibraryPath(file, 'default');

    // var areAssetsLoaded:Bool = Assets.list(type).length > 0;
    // if (!areAssetsLoaded)
    // {
    //   return levelPath;
    // }

    // trace('[ASSETS] Checking for $levelPath');
    if (Assets.exists(levelPath, type))
    {
      return levelPath;
    }

    return levelPath;
  }

  public static function getLibraryPath(file:String, library = 'default'):String
  {
    if (library == 'default' || library == 'preload') return 'assets/$file';

    return '$library:assets/$file';
  }

  public static function file(file:String, type:AssetType = TEXT, ?library:String):String
  {
    return getPath(file, type, library);
  }

  public static function animateAtlas(path:String, ?library:String):String
  {
    return getLibraryPath('$path', library);
  }

  public static function txt(key:String, ?library:String):String
  {
    return getPath('$key.txt', TEXT, library);
  }

  public static function frag(key:String, ?library:String):String
  {
    return getPath('$key.frag', TEXT, library);
  }

  public static function vert(key:String, ?library:String):String
  {
    return getPath('$key.vert', TEXT, library);
  }

  public static function xml(key:String, ?library:String):String
  {
    return getPath('$key.xml', TEXT, library);
  }

  public static function json(key:String, ?library:String):String
  {
    return getPath('$key.json', TEXT, library);
  }

  public static function srt(key:String, ?library:String, ?directory:String = ""):String
  {
    return getPath('$directory$key.srt', TEXT, library);
  }

  public static function sound(key:String, ?library:String):String
  {
    return getPath('$key.${Constants.EXT_SOUND}', SOUND, library);
  }

  public static function soundRandom(key:String, min:Int, max:Int, ?library:String):String
  {
    return sound(key + FlxG.random.int(min, max), library);
  }

  public static function music(key:String, ?library:String):String
  {
    return getPath('$key.${Constants.EXT_SOUND}', MUSIC, library);
  }

  public static function videos(key:String, ?library:String):String
  {
    final path:Path = new Path(key);

    if (path.ext != null)
    {
      return getPath(key, BINARY, library);
    }

    return getPath('$key.${Constants.EXT_VIDEO}', BINARY, library);
  }

  public static function voices(song:String, ?suffix:String = ''):String
  {
    if (suffix == null) suffix = ''; // no suffix, for a sorta backwards compatibility with older-ish voice files

    return getPath('gameplay/songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}', MUSIC);
  }

  /**
   * Gets the path to an `Inst.mp3/ogg` song instrumental from songs:assets/songs/`song`/
   * @param song name of the song to get instrumental for
   * @param suffix any suffix to add to end of song name, used for `-erect` variants usually
   * @param withExtension if it should return with the audio file extension `.mp3` or `.ogg`.
   * @return String
   */
  public static function inst(song:String, suffix:String = '', withExtension:Bool = true):String
  {
    var ext:String = withExtension ? '.${Constants.EXT_SOUND}' : '';
    return getPath('gameplay/songs/${song.toLowerCase()}/Inst$suffix$ext', MUSIC);
  }

  public static function musicMetadata(key:String, suffix:String = '', ?library:String):String
  {
    return getPath('$key-metadata$suffix.json', TEXT, library);
  }

  public static function image(key:String, ?library:String):String
  {
    return getPath('$key.png', IMAGE, library);
  }

  public static function font(key:String):String
  {
    return 'default:assets/$key';
  }

  public static function ui(key:String, ?library:String):String
  {
    return xml('ui/$key', library);
  }

  public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
  {
    return FlxAtlasFrames.fromSparrow(image(key, library), xml(key, library));
  }

  public static function getAnimateAtlas(key:String, ?library:String, settings:AtlasSpriteSettings):FlxAnimateFrames
  {
    var assetLibrary:String = library ?? "";
    var graphicKey:String = "";

    if (assetLibrary != "")
    {
      graphicKey = Paths.animateAtlas(key, assetLibrary);
    }
    else
    {
      graphicKey = Paths.animateAtlas(key);
    }

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
    if (!Assets.exists('${graphicKey}/Animation.json'))
    {
      throw 'No Animation.json file exists at the specified path (${graphicKey})';
    }

    return FlxAnimateFrames.fromAnimate(graphicKey, validatedSettings.spritemaps, validatedSettings.metadataJson, validatedSettings.cacheKey,
      validatedSettings.uniqueInCache, {
        swfMode: validatedSettings.swfMode,
        cacheOnLoad: validatedSettings.cacheOnLoad,
        filterQuality: validatedSettings.filterQuality,
        onSymbolCreate: validatedSettings.onSymbolCreate
      });
  }

  public static function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
  {
    return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), txt(key, library));
  }
}

enum abstract PathsFunction(String)
{
  var MUSIC;
  var INST;
  var VOICES;
  var SOUND;
}
