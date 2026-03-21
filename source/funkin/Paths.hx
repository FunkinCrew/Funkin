package funkin;

import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimateFrames;
import funkin.graphics.FunkinSprite.AtlasSpriteSettings;
import openfl.utils.AssetType;
import funkin.util.macro.ConsoleMacro;
import haxe.io.Path;

/**
 * A core class which handles determining asset paths.
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

  public static function stripLibrary(path:String):String
  {
    var idx = path.indexOf(":");
    return if (idx == -1) path; else path.substr(idx + 1);
  }

  public static function getLibrary(path:String):String
  {
    var idx = path.indexOf(":");
    return if (idx == -1) "preload"; else path.substr(0, idx);
  }

  public static function fixPathExtension(path:String, defaultExtension:String):String
  {
    return if (path.lastIndexOf(".") == -1) '${path}.$defaultExtension'; else path;
  }

  public static function normalizePath(path:String, ?defaultExtension:String):String
  {
    return if (defaultExtension == null) Path.normalize(path); else fixPathExtension(Path.normalize(path), defaultExtension);
  }

  public static function getPath(file:String, ?type:AssetType, ?library:String):String
  {
    if (library != null) return getLibraryPath(file, library);

    if (currentLevel != null)
    {
      var levelPath:String = getLibraryPath(file, currentLevel);
      if (Assets.exists(levelPath, type)) return levelPath;
    }

    var levelPath:String = getLibraryPathForce(file, 'shared');
    if (Assets.exists(levelPath, type)) return levelPath;

    return getPreloadPath(file);
  }

  public static function getLibraryPath(file:String, library = 'preload'):String
  {
    return if (library == 'preload' || library == 'default') getPreloadPath(file); else getLibraryPathForce(file, library);
  }

  static inline function getLibraryPathForce(file:String, library:String):String
  {
    return '$library:assets/$library/$file';
  }

  static inline function getPreloadPath(file:String):String
  {
    return 'assets/$file';
  }

  public static function file(file:String, ?type:AssetType, ?library:String):String
  {
    return getPath(file, type, library);
  }

  public static function animateAtlas(path:String, ?library:String):String
  {
    return getLibraryPath('images/$path', library);
  }

  public static function txt(key:String, ?library:String):String
  {
    return getPath(normalizePath('data/$key', 'txt'), TEXT, library);
  }

  public static function frag(key:String, ?library:String):String
  {
    return getPath(normalizePath('shaders/$key', 'frag'), TEXT, library);
  }

  public static function vert(key:String, ?library:String):String
  {
    return getPath(normalizePath('shaders/$key', 'vert'), TEXT, library);
  }

  public static function xml(key:String, ?library:String):String
  {
    return getPath(normalizePath('data/$key', 'xml'), TEXT, library);
  }

  public static function json(key:String, ?library:String):String
  {
    return getPath(normalizePath('data/$key', 'json'), TEXT, library);
  }

  public static function srt(key:String, ?library:String, ?directory:String = "data"):String
  {
    return getPath(normalizePath('${directory}/$key', 'srt'), TEXT, library);
  }

  public static function sound(key:String, ?library:String, ?directory:String = 'sounds', ?extension:String):String
  {
    if (extension == null)
    {
      var idx = key.lastIndexOf(".");
      if (idx != -1)
      {
        extension = key.substr(idx + 1);
        key = key.substr(0, idx);
      }
    }

    var normalizedPath = Path.normalize((directory == '' ? '' : directory + '/') + key);
    if (extension != null) return getPath(fixPathExtension(normalizedPath, extension), SOUND, library);

    // Attempt to find the sound by looping through the supported file formats.
    var path:String;
    for (extension in Constants.EXT_SOUNDS)
    {
      // no need to check if its exists in MUSIC type, as Openfl/Lime AssetLibrary have the same returns for SOUND and MUSIC internally.
      if (library != null)
      {
        path = getLibraryPath(fixPathExtension(normalizedPath, extension), library);
        if (Assets.exists(path, SOUND)/* || Assets.exists(path, MUSIC)*/) return path;
      }
      else
      {
        if (currentLevel != null)
        {
          path = getLibraryPath(fixPathExtension(normalizedPath, extension), currentLevel);
          if (Assets.exists(path, SOUND)/* || Assets.exists(path, MUSIC)*/) return path;
        }

        path = getLibraryPathForce(fixPathExtension(normalizedPath, extension), 'shared');
        if (Assets.exists(path, SOUND)/* || Assets.exists(path, MUSIC)*/) return path;
      }
    }

    if (library != null) return getLibraryPath(fixPathExtension(normalizedPath, Constants.EXT_SOUND), library);
    else return getPreloadPath(fixPathExtension(normalizedPath, Constants.EXT_SOUND));
  }

  public static function soundRandom(key:String, min:Int, max:Int, ?library:String, ?extension:String):String
  {
    return sound(key + FlxG.random.int(min, max), library, null, extension);
  }

  public static function music(key:String, ?library:String, ?extension:String):String
  {
    return sound(key, library, 'music', extension);
  }

  public static function videos(key:String, ?library:String):String
  {
    final path:Path = new Path(key);

    if (path.ext != null)
    {
      return getPath('videos/${path.file}.${path.ext}', BINARY, library ?? 'videos');
    }

    return getPath('videos/$key.${Constants.EXT_VIDEO}', BINARY, library ?? 'videos');
  }

  public static function song(key:String, ?extension:String):String
  {
    // For web platform that haven't loaded the library "songs" yet.
    if (Assets.getLibrary("songs") != null) return sound(key, 'songs', '', extension);
    else return getLibraryPathForce(normalizePath(key, extension ?? Constants.EXT_SOUND), 'songs');
  }

  public static function voices(song:String, ?suffix:String = '', ?extension:String):String
  {
    if (suffix == null) suffix = ''; // no suffix, for a sorta backwards compatibility with older-ish voice files
    return Paths.song('${song.toLowerCase()}/Voices$suffix', extension);
  }

  /**
   * Gets the path to an `Inst.mp3/ogg` song instrumental from songs:assets/songs/`song`/
   * @param song name of the song to get instrumental for
   * @param suffix any suffix to add to end of song name, used for `-erect` variants usually
   * @param extension The audio file extension of the track. If empty, it'll attempt to find a supported audio file format.
   * @return String
   */
  public static function inst(song:String, ?suffix:String = '', ?extension:String):String
  {
    return Paths.song('${song.toLowerCase()}/Inst$suffix', extension);
  }

  public static function image(key:String, ?library:String):String
  {
    return getPath('images/$key.png', IMAGE, library);
  }

  public static function font(key:String):String
  {
    return 'assets/fonts/$key';
  }

  public static function ui(key:String, ?library:String):String
  {
    return xml('ui/$key', library);
  }

  public static function fromPathsFunction(key:String, ?pathsFunction:PathsFunction):String
  {
    return switch (pathsFunction)
    {
      case FILE: file(key);
      case ATLAS: animateAtlas(key);
      case TXT: txt(key);
      case FRAG: frag(key);
      case VERT: vert(key);
      case XML: xml(key);
      case JSON: json(key);
      case SRT: srt(key);
      case SOUND: sound(key);
      case MUSIC: music(key);
      case VIDEOS: videos(key);
      case SONG: song(key);
      case INST: inst(key);
      case VOICES: voices(key);
      case FONT: font(key);
      case UI: ui(key);
      default: key;
    }
  }

  public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
  {
    return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
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
    return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
  }
}

enum abstract PathsFunction(String)
{
  var NONE;
  var FILE;
  var ATLAS;
  var TXT;
  var FRAG;
  var VERT;
  var XML;
  var JSON;
  var SRT;
  var SOUND;
  var MUSIC;
  var VIDEOS;
  var SONG;
  var INST;
  var VOICES;
  var FONT;
  var UI;
}
