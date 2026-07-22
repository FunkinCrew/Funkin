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
  /**
   * Uploads the specified bitmap data to the GPU.
   * NOTE: From what I've read, this must be done from the main thread to prevent corrupted graphics.
   *
   * @param bitmapData The BitmapData to upload.
   * @return The bitmap data
   */
  public static function uploadBitmapDataToGPU(bitmapData:BitmapData):BitmapData
  {
    #if FEATURE_GPU_TEXTURES
    trace('Uploading bitmap data to GPU... ${bitmapData?.image?.premultiplied}');

    // `disposeImage()` sets `readable` to false
    // calling `getTexture()` afterwards disposes the image from the CPU
    bitmapData.disposeImage();
    bitmapData.getTexture(FlxG.stage.context3D);
    #end

    return bitmapData;
  }

  /**
   * Returns the `FunkinAssetType` for a given path, if it has a known extension.
   * @param path The path to query.
   * @return The corresponding `FunkinAssetType`, or `FunkinAssetType.UNKNOWN`.
   */
  public static function guessTypeByExtension(path:String):FunkinAssetType
  {
    var ext:String = Path.extension(path).toLowerCase();
    switch (ext)
    {
      case 'fnfc': // Friday Night Funkin chart
        return FunkinAssetType.CHART;
      case 'png': // Portable Network Graphics texture image
        return FunkinAssetType.IMAGE;
      case 'jpg': // JPG texture image
        return FunkinAssetType.IMAGE;
      case 'jpeg': // JPEG texture image
        return FunkinAssetType.IMAGE;
      case 'gif': // Graphics Interchange Format image
        return FunkinAssetType.IMAGE;
      case 'bmp': // Bitmap image
        return FunkinAssetType.IMAGE;
      case 'astc': // Texture image utilizing Adaptive scalable texture compression
        return FunkinAssetType.IMAGE;
      case 'ogg': // Ogg Vorbis audio
        return FunkinAssetType.SOUND;
      case 'mp3': // MPEG-1 Audio Layer 3 audio
        return FunkinAssetType.SOUND;
      case 'wav': // Waveform audio
        return FunkinAssetType.SOUND;
      case 'mp4': // MPEG-4 video
        return FunkinAssetType.VIDEO;
      case 'webm': // WebM video
        return FunkinAssetType.VIDEO;
      case 'mkv': // WebM video
        return FunkinAssetType.VIDEO;
      case 'json': // JavaScript Object Notation data
        return FunkinAssetType.JSON;
      case 'xml': // Extensible Markup Language data
        return FunkinAssetType.XML;
      case 'txt': // Text file
        return FunkinAssetType.TEXT;
      case 'md': // Markdown text file
        return FunkinAssetType.TEXT;
      case 'tsv': // Tab-separated values file
        return FunkinAssetType.TEXT;
      case 'csv': // Comma-separated values file
        return FunkinAssetType.TEXT;
      case 'frag': // GLSL fragment shader
        return FunkinAssetType.TEXT;
      case 'vert': // GLSL vertex shader
        return FunkinAssetType.TEXT;
      case 'css': // Cascading stylesheet
        return FunkinAssetType.TEXT;
      case 'srt': // SubRip Text Subtitles
        return FunkinAssetType.TEXT;
      case 'fnt': // Bitmap Font data file
        return FunkinAssetType.TEXT;
      case 'hxs': // Haxe script
        return FunkinAssetType.SCRIPT;
      case 'hscript': // Haxe script
        return FunkinAssetType.SCRIPT;
      case 'hx': // Haxe script
        return FunkinAssetType.SCRIPT;
      case 'hxc': // Haxe scripted class
        return FunkinAssetType.SCRIPTED_CLASS;
      case 'ttf': // TrueType font
        return FunkinAssetType.FONT;
      case 'otf': // OpenType font
        return FunkinAssetType.FONT;
      case 'fla': // Flash project
        return FunkinAssetType.UNKNOWN;
      default: // Unknown
        trace('Unknown extension for file: $path');
        return FunkinAssetType.UNKNOWN;
    }
  }
}
