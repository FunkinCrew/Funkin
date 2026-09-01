package funkin.util.assets;

import haxe.io.Path;
import funkin.assets.Assets.AssetType as FunkinAssetType;
import openfl.display.BitmapData;

using StringTools;

/**
 * Utility functions for working with assets and graphics.
 */
@:allow(funkin.assets.FunkinAssetCache)
class AssetsUtil
{
  static final EXTENSIONS:Map<String, FunkinAssetType> = [
    'astc' => FunkinAssetType.IMAGE, // Texture image utilizing Adaptive scalable texture compression
    'dds' => FunkinAssetType.IMAGE, // Texture image utilizing Adaptive scalable texture compression
    'bmp' => FunkinAssetType.IMAGE, // Bitmap image
    'css' => FunkinAssetType.TEXT, // Cascading stylesheet
    'csv' => FunkinAssetType.TEXT, // Comma-separated values file
    'fla' => FunkinAssetType.UNKNOWN, // Flash project
    'fnfc' => FunkinAssetType.CHART, // Friday Night Funkin chart
    'fnfs' => FunkinAssetType.STAGE, // Friday Night Funkin chart
    'fnfmod' => FunkinAssetType.MOD, // Friday Night Funkin chart
    'fnt' => FunkinAssetType.TEXT, // Bitmap Font data file
    'frag' => FunkinAssetType.TEXT, // GLSL fragment shader
    'gif' => FunkinAssetType.IMAGE, // Graphics Interchange Format image
    'hscript' => FunkinAssetType.SCRIPT, // Haxe script
    'hx' => FunkinAssetType.SCRIPT, // Haxe script
    'hxc' => FunkinAssetType.SCRIPTED_CLASS, // Haxe scripted class
    'hxs' => FunkinAssetType.SCRIPT, // Haxe script
    'ico' => FunkinAssetType.IMAGE, // Windows Icon file
    'jpeg' => FunkinAssetType.IMAGE, // JPEG texture image
    'jpg' => FunkinAssetType.IMAGE, // JPG texture image
    'json' => FunkinAssetType.JSON, // JavaScript Object Notation data
    'md' => FunkinAssetType.TEXT, // Markdown text file
    'mkv' => FunkinAssetType.VIDEO, // WebM video
    'mp3' => FunkinAssetType.SOUND, // MPEG-1 Audio Layer 3 audio
    'mp4' => FunkinAssetType.VIDEO, // MPEG-4 video
    'ogg' => FunkinAssetType.SOUND, // Ogg Vorbis audio
    'otf' => FunkinAssetType.FONT, // OpenType font
    'png' => FunkinAssetType.IMAGE, // Portable Network Graphics texture image
    'srt' => FunkinAssetType.TEXT, // SubRip Text Subtitles
    'tsv' => FunkinAssetType.TEXT, // Tab-separated values file
    'ttf' => FunkinAssetType.FONT, // TrueType font
    'txt' => FunkinAssetType.TEXT, // Text file
    'vert' => FunkinAssetType.TEXT, // GLSL vertex shader
    'wav' => FunkinAssetType.SOUND, // Waveform audio
    'webm' => FunkinAssetType.VIDEO, // WebM video
    'xml' => FunkinAssetType.XML, // Extensible Markup Language data
  ];

  /**
   * Returns the `FunkinAssetType` for a given path, if it has a known extension.
   * @param path The path to query.
   * @return The corresponding `FunkinAssetType`, or `FunkinAssetType.UNKNOWN`.
   */
  public static function guessTypeByExtension(path:String):FunkinAssetType
  {
    var ext:String = Path.extension(path).toLowerCase();

    if (EXTENSIONS.exists(ext)) return EXTENSIONS.get(ext);

    trace('Unknown extension for file: $path ($ext)');
    return FunkinAssetType.UNKNOWN;
  }
}
