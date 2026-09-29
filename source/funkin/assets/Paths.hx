package funkin.assets;

import funkin.assets.Assets.AssetType;
import funkin.util.macro.ConsoleMacro.ConsoleClass;
import funkin.util.assets.AssetsUtil;
import haxe.io.Path;

using StringTools;

/**
 * A utility class which handles determining asset paths.
 * Provides validation and more.
 */
@:nullSafety
class Paths implements ConsoleClass
{
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

  /**
   * Construct an asset path for the given path, extension, and file type.
   * @param file The file to get the path for, without file extension.
   * @param ext The file extension to use.
   * @param validate Whether to validate that the file exists before returning.
   *   If false, the game won't throw any warnings if the file doesn't exist.
   * @param library The asset library to use. This falls back to the `default` library.
   * @return An AssetPath pointing to the given file.
   */
  static function build(file:String, ext:String, validate:Bool = true, ?library:String):AssetPath
  {
    // Remove redundant `assets/` from the path! This helps prevent `assets/assets/image.png`.
    if (file.startsWith('assets/')) file = file.substring(7);
    // Remove redundant file extensions! This helps prevent `image.png.png`.
    if (file.endsWith('.$ext')) file = file.substring(0, file.length - (ext.length + 1));

    @:privateAccess
    var shouldValidateCompat = validate && funkin.assets.Assets.initialized;

    var assetPathStr = funkin.modding.compat.Paths.getPath('$file.$ext', library, shouldValidateCompat);
    var assetPathId:String = haxe.io.Path.withoutExtension(assetPathStr);
    var assetPathExt:String = haxe.io.Path.extension(assetPathStr);

    // Build the asset path.
    var assetPath:AssetPath = new AssetPath(assetPathId, assetPathExt);

    if (!validate || assetPath.exists())
    {
      return assetPath;
    }
    else
    {
      trace(' ERROR '.bold().error() + 'Asset path "$assetPath" points to an asset that does not exist!');
      FlxG.log.warn('Asset path "$assetPath" points to an asset that does not exist!');
      // TODO: Improve error handling here.
      return assetPath;
    }
  }

  /**
   * Construct an asset path for a file with a specific extension.
   * Validates that the file exists before returning.
   *
   * @param file The file path without extension
   * @param ext The file extension to use
   * @param validate Whether to validate the file exists, defaults to `true`.
   *   If `true`, the game will complain if the asset path doesn't exist.
   *   This is helpful most of the time but obviously isn't helpful if you're querying IF a path exists yourself.
   * @param library The library to use, defaults to `default`
   * @return AssetPath
   */
  public static function file(file:String, ext:String, validate:Bool = true, ?library:String):AssetPath
  {
    return build(file, ext, validate, library);
  }

  /**
   * Convert a string ID directly to an asset path.
   * Try to avoid using this, ehe.
   *
   * @param id The asset path to convert.
   * @return AssetPath
   */
  @:allow(funkin.assets.Assets) @:allow(funkin.assets.FunkinBitmapFrontend)
  private static function raw(id:String, validate:Bool = true):AssetPath
  {
    var ext:String = haxe.io.Path.extension(id);
    var idWithoutExt:String = haxe.io.Path.withoutExtension(id);

    return file(idWithoutExt, ext, validate);
  }

  /**
   * Constructs an asset path for an Adobe Animate texture atlas.
   *
   * @param path The path to the texture atlas, without extension
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return AnimateAtlasAssetPathBuilder
   */
  public static function animateAtlas(path:String, validate:Bool = true):AnimateAtlasAssetPathBuilder
  {
    return new AnimateAtlasAssetPathBuilder(path);
  }

  /**
   * Constructs an asset path for a `.txt` text file.
   * @param key The path to the text file, without file extension.
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return An AssetPath pointing to the text file.
   */
  public static function txt(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'txt', validate);
  }

  /**
   * Constructs an asset path for a `.srt` subtitle file.
   * @param key The path to the subtitle file, without file extension.
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return An AssetPath pointing to the subtitle file.
   */
  public static function srt(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'srt', validate);
  }

  /**
   * Constructs an asset path for a `.frag` shader file.
   *
   * @param key The file path without extension
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return AssetPath
   */
  public static function frag(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'frag', validate);
  }

  /**
   * Constructs an asset path for a `.vert` shader file.
   *
   * @param key The file path without extension
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return AssetPath
   */
  public static function vert(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'vert', validate);
  }

  /**
   * Constructs an asset path for a `.xml` data file.
   *
   * @param key The file path without extension
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return AssetPath
   */
  public static function xml(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'xml', validate);
  }

  /**
   * Constructs an asset path for a `.json` data file.
   *
   * @param key The file path without extension
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return AssetPath
   */
  public static function json(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'json', validate);
  }

  /**
   * Constructs an asset path for a sound file.
   *
   * @param key The file path without extension
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return AssetPath
   */
  public static function sound(key:String, validate:Bool = true):AssetPath
  {
    return file(key, Constants.EXT_SOUND, validate);
  }

  /**
   * Constructs an asset path for a sound file, randomly suffixing a number between `min` and `max`, inclusive.
   * For example, `soundRandom('sound', 1, 3)` will return `sound1`, `sound2`, or `sound3`.
   * @param key The path to the sound file(s), excluding the number suffix.
   * @param min The minimum number to return.
   * @param max The maximum number to return.
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @param library The asset path that the file is in
   * @return The constructed asset path.
   */
  public static function soundRandom(key:String, min:Int, max:Int, validate:Bool = true):AssetPath
  {
    return sound(key + FlxG.random.int(min, max), validate);
  }

  /**
   * Construct an asset path to a music track.
   * @param key The path to the folder containing the track and its metadata.
   * @param suffix An optional suffix to apply to the track name.
   *   For example, you can use this to fetch a `-start` variant of a track.
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @return The constructed asset path.
   */
  public static function music(key:String, ?suffix:String, validate:Bool = true):MusicAssetPathBuilder
  {
    return new MusicAssetPathBuilder(key, suffix);
  }

  /**
   * Construct an asset path for a video file.
   *
   * @param key The path to the video file.
   * @param ext The file extension of the video, defaults to `mp4`
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @return The constructed asset path.
   */
  public static function video(key:String, ext:String = 'mp4', validate:Bool = true):AssetPath
  {
    return Paths.build(key, ext, validate);
  }

  /**
   * Constructs an asset path for a vocal track in the `songs` folder.
   * @param song The song ID for the vocal track
   * @param suffix The suffix to add to the vocal track (e.g. "-erect" for alternate versions)
   * @param validate Whether to validate that the file exists before returning
   * @return AssetPath pointing to the vocal track file
   */
  public static function voices(song:String, suffix:String = '', validate:Bool = true):AssetPath
  {
    if (suffix == null) suffix = ''; // no suffix, for a sorta backwards compatibility with older-ish voice files

    return file('gameplay/songs/${song.toLowerCase()}/Voices$suffix', Constants.EXT_SOUND, validate);
  }

  /**
   * Gets the path to an `Inst.mp3/ogg` song instrumental from songs:assets/songs/`song`/
   * @param song name of the song to get instrumental for
   * @param suffix any suffix to add to end of song name, used for `-erect` variants usually
   * @param withExtension if it should return with the audio file extension `.mp3` or `.ogg`.
   * @param validate Whether to validate that the file exists
   * @return An AssetPath
   */
  public static function inst(song:String, suffix:String = '', validate:Bool = true):AssetPath
  {
    return file('gameplay/songs/${song.toLowerCase()}/Inst$suffix', Constants.EXT_SOUND, validate);
  }

  /**
   * Constructs an asset path for a `.png` image file.
   * @param key The path to the image file, without file extension.
   * @param validate Whether to validate that the file exists
   * @return An AssetPath pointing to the image file.
   */
  public static function image(key:String, validate:Bool = true):AssetPath
  {
    return file(key, 'png', validate);
  }

  /**
   * Constructs an asset path for a font file in the `fonts` folder.
   * Since `setFormat` directly requires a string, we don't use an AssetPath for this.
   * We still provide validation though.
   *
   * @param key The path to the font file, without file extension
   * @param ext The file extension of the font, defaults to `ttf`
   * @param validate Whether to validate that the file exists
   * @return A string containing the full asset path to the font file
   */
  public static function font(key:String, ext:String = 'ttf', validate:Bool = true):String
  {
    return file(key, ext, validate).toString();
  }
}

/**
 * Represents a path to an asset, with a library, asset ID, and extension.
 * Easily converts to a string, while ensuring functions that expect an asset path don't receive a string by mistake.
 *
 * Any function that takes an AssetPath won't accept a string,
 * guaranteeing you correctly call one of the functions in `Paths`,
 * and pass a series of checks to ensure the file exists and is properly cached,
 * rather than passing a raw string by accident.
 */
@:nullSafety
@:allow(funkin.assets.Paths)
@:access(funkin.assets.Paths)
class AssetPath
{
  /**
   * The library this asset belongs to.
   * @default `default`
   */
  public var library(default, null):String;

  /**
   * The unique identifier for this asset within its library.
   * This is the path to the asset without its extension.
   */
  public var id(default, null):String;

  /**
   * The file extension for this asset.
   * @default Empty string, for files without an extension.
   */
  public var ext(default, null):String;

  /**
   * Whether we need the pixel data for this asset.
   * Necessary for things like masks but hurts memory usage.
   *
   * Call `AssetPath.withPixelData()` to enable this.
   */
  public var needsPixelData(default, null):Bool = false;

  /**
   * The asset path, with extension, without the library.
   */
  public var path(get, never):String;

  function get_path():String
  {
    if (this.ext == null || this.ext == '') return '${this.id}';
    return '${this.id}.${this.ext}';
  }

  /**
   * The asset's file name, with the extension and without the path.
   */
  public var fileName(get, never):String;

  function get_fileName():String
  {
    return Path.withoutDirectory(this.path);
  }

  /**
   * The asset's file name, without the extension or the path.
   */
  public var fileBareName(get, never):String;

  function get_fileBareName():String
  {
    return Path.withoutExtension(Path.withoutDirectory(this.path));
  }

  // Only construct from Paths.hx

  function new(id:String, ext:String, library:String = 'default')
  {
    this.id = id;
    this.ext = ext;
    this.library = library;
  }

  /**
   * Determine the AssetType for this AssetPath.
   * @return The AssetType corresponding to the file extension of this AssetPath.
   */
  public function getAssetType():AssetType
  {
    return AssetsUtil.guessTypeByExtension(this.path);
  }

  /**
   * Explicitly convert this AssetPath to an `FlxGraphicAsset`.
   * @return The resulting `FlxGraphicAsset`
   */
  public function toFlxGraphicAsset():flixel.system.FlxAssets.FlxGraphicAsset
  {
    return toString();
  }

  /**
   * Explicitly convert this AssetPath to an `FlxSoundAsset`.
   * @return The resulting `FlxSoundAsset`
   */
  public function toFlxSoundAsset():flixel.system.FlxAssets.FlxSoundAsset
  {
    return toString();
  }

  /**
   * Explicitly convert this AssetPath to an `FlxTilemapGraphicAsset`.
   * @return The resulting `FlxTilemapGraphicAsset`
   */
  public function toFlxTilemapGraphicAsset():flixel.system.FlxAssets.FlxTilemapGraphicAsset
  {
    return toString();
  }

  /**
   * Explicitly convert this AssetPath to an `FlxBitmapFontGraphicAsset`.
   * @return The resulting `FlxBitmapFontGraphicAsset`
   */
  public function toFlxBitmapFontGraphicAsset():flixel.system.FlxAssets.FlxBitmapFontGraphicAsset
  {
    return toString();
  }

  /**
   * Explicitly convert this AssetPath to an `FlxXmlAsset`.
   * @return The resulting `FlxXmlAsset`
   */
  public function toFlxXmlAsset():flixel.system.FlxAssets.FlxXmlAsset
  {
    return toString();
  }

  /**
   * @return Whether this asset exists on the file system.
   */
  public function exists():Bool
  {
    return Assets.assetExists(this);
  }

  /**
   * Used to revert an AssetPath to null if the asset does not exist.
   * Good for making retrieving an asset "optional".
   *
   * @return If the asset does not exist, return `null` . Otherwise, return the asset path.
   */
  public function orNull():Null<AssetPath>
  {
    return this.exists() ? this : null;
  }

  /**
   * Determine if this AssetPath is of the given AssetType.
   *
   * @param type The AssetType to compare with.
   * @return Whether this AssetPath is of the given AssetType.
   */
  public function isAssetType(type:AssetType):Bool
  {
    return type == this.getAssetType();
  }

  /**
   * Constructs a new AssetPath with the given extension.
   *
   * @param ext The file extension to use, without the `.`
   * @return The resulting AssetPath
   */
  public function withExt(ext:String):AssetPath
  {
    return new AssetPath(this.id, ext, this.library);
  }

  /**
   * Constructs a new AssetPath with the given AssetType.
   *
   * @param type The AssetType to use
   * @return The resulting AssetPath
   */
  public function withAssetType(type:AssetType):AssetPath
  {
    switch (type)
    {
      case IMAGE:
        return this.withExt('png');
      case SOUND:
        return this.withExt('ogg');
      case VIDEO:
        return this.withExt('mp4');
      case TEXT:
        return this.withExt('txt');
      case JSON:
        return this.withExt('json');
      case SHADER:
        return this.withExt('frag');
      case SCRIPT:
        return this.withExt('hx');
      case SCRIPTED_CLASS:
        return this.withExt('hxc');
      case CHART:
        return this.withExt('fnfc');
      case STAGE:
        return this.withExt('fnfs');
      case XML:
        return this.withExt('xml');
      case FONT:
        return this.withExt('ttf');

      default:
        return this;
    }
  }

  /**
   * By default, we get rid of the pixel data after we've uploaded it to the GPU to save memory.
   * Call this function to specify that this asset is a graphic which needs pixel data in RAM.
   * @return The AssetPath, for chaining calls together.
   */
  public function withPixelData():AssetPath
  {
    this.needsPixelData = true;

    return this;
  }

  public function toString():String
  {
    if (this.library == null || this.library == '' || this.library == 'default') return '${this.path}';
    return '${this.library}:${this.path}';
  }

  /**
   * @param a An AssetPath to compare.
   * @param b An AssetPath to compare.
   * @return Whether the two AssetPaths point to the same file.
   */
  public static function equals(a:AssetPath, b:AssetPath):Bool
  {
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }
}

/**
 * Holds the directory containing an Adobe Animate texture atlas,
 * and provides methods to construct asset paths for the texture and animation data.
 */
@:nullSafety
@:allow(funkin.assets.Paths)
@:access(funkin.assets.Paths)
class AnimateAtlasAssetPathBuilder
{
  /**
   * The ID for this Animate Atlas.
   * Provides the path to the folder containing the texture and animation data.
   */
  public var id(default, null):String;

  /**
   * The asset library where this atlas path is located, if not the default.
   */
  public var library(default, null):String;

  // Only construct from Paths.hx

  function new(id:String, library:String = 'default')
  {
    this.id = id;
    this.library = library;
  }

  /**
   * Retrieve the spritemap texture(s) at this atlas's asset path.
   * @return The AssetPath for the image. May be empty but will never be `null`.
   */
  public function image():Array<AssetPath>
  {
    var assetPaths:Array<AssetPath> = Assets.listInPath('${id}/', AssetType.IMAGE, true);

    return assetPaths;
  }

  /**
   * Retrieve the list of JSON files at this spritesheet's asset path.
   * @return The AssetPath for the JSON file. May be empty but will never be `null`.
   */
  public function json():Array<AssetPath>
  {
    var assetPaths:Array<AssetPath> = Assets.listInPath('${id}/', AssetType.JSON, true);

    return assetPaths;
  }

  /**
   * @return Whether the image files for this texture atlas exist.
   */
  public function imageExists():Bool
  {
    for (image in this.image())
    {
      if (!image.exists())
      {
        return false;
      }
    }

    return true;
  }

  /**
   * @return Whether the `.json` files for this texture atlas exist.
   */
  public function jsonExists():Bool
  {
    for (json in this.json())
    {
      if (!json.exists())
      {
        return false;
      }
    }

    return true;
  }

  /**
   * @return `true` if the image and all required `.json` files for this texture atlas exist.
   */
  public function exists():Bool
  {
    // Validate textures.
    if (!this.imageExists()) return false;
    // Validate JSON files.
    if (!this.jsonExists()) return false;

    return true;
  }

  public function toString():String
  {
    if (this.library == null || this.library == '' || this.library == 'default') return 'assets/${this.id}';
    return Paths.build(this.id, '', false, this.library).toString();
  }
}

/**
 * Holds the directory containing a music track,
 * and provides methods to construct asset paths for the audio and the metadata.
 */
@:nullSafety
@:allow(funkin.assets.Paths)
@:access(funkin.assets.Paths)
class MusicAssetPathBuilder
{
  /**
   * The ID of the music track. Dictates where the audio and metadata are.
   */
  public var id(default, null):String;

  /**
   * An additional suffix to apply to the audio track path (and not the metadata path).
   */
  public var suffix(default, null):String;

  /**
   * The path to the music track.
   */
  public var dir(default, null):String;

  /**
   * If `false`, the path will not use the id as a folder name.
   */
  public var nested(default, null):Bool;

  // Only construct from Paths.hx

  function new(id:String, suffix:String = '', nested:Bool = true)
  {
    var parts = id.split('/');

    this.id = parts[parts.length - 1];
    this.dir = parts.slice(0, parts.length - 1).join('/');
    this.suffix = suffix;
    this.nested = nested;
  }

  /**
   * Retrieve the path to the audio track for this music.
   * @return The sound asset path.
   */
  public function audio():AssetPath
  {
    var s = this.suffix == '' ? '' : '${this.suffix}';
    var finalPath:AssetPath = nested ? Paths.sound('$dir/$id/$id$s') : Paths.sound('$dir/$id$s');
    return finalPath;
  }

  /**
   * Retrieve the path to the JSON metadata for this music.
   * Contains information about BPM and stuffs.
   * @return The JSON asset path.
   */
  public function metadata(?variation:String):AssetPath
  {
    if (variation == null) variation = Constants.DEFAULT_VARIATION;

    var s = this.suffix == '' ? '' : '${this.suffix}';
    var v = variation == Constants.DEFAULT_VARIATION ? '' : '-${variation}';
    var finalPath:AssetPath = nested ? Paths.json('$dir/$id/$id$s-metadata$v') : Paths.json('$dir/$id$s-metadata$v');
    return finalPath;
  }

  /**
   * @return `true` if the audio track this Music points at, actually exists.
   */
  public function audioExists():Bool
  {
    var s = this.suffix == '' ? '' : '${this.suffix}';
    var finalPath:AssetPath = nested ? Paths.sound('$dir/$id/$id$s', false) : Paths.sound('$dir/$id$s', false);
    return finalPath.exists();
  }

  /**
   * @return `true` if the JSON metadata this Music points at, actually exists.
   */
  public function metadataExists(?variation:String):Bool
  {
    if (variation == null) variation = Constants.DEFAULT_VARIATION;

    var s = this.suffix == '' ? '' : '${this.suffix}';
    var v = variation == Constants.DEFAULT_VARIATION ? '' : '-${variation}';
    var finalPath:AssetPath = nested ? Paths.json('$dir/$id/$id$s-metadata$v', false) : Paths.json('$dir/$id$s-metadata$v', false);
    return finalPath.exists();
  }

  /**
   * Create a new Music asset path with a different suffix.
   * For example, you can use this to fetch a `-start` or `-end` subtrack.
   * @param newSuffix The new suffix to use.
   * @return The constructed Music asset path.
   */
  public function withSuffix(newSuffix:String):MusicAssetPathBuilder
  {
    return new MusicAssetPathBuilder('$dir/$id', newSuffix);
  }

  public function toString():String
  {
    return '$dir/$id';
  }
}
