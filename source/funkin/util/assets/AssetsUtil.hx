package funkin.util.assets;

import haxe.io.Path;
import funkin.assets.Assets.AssetType as FunkinAssetType;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.Texture;

using StringTools;

/**
 * Utility functions for working with assets and graphics.
 */
@:allow(funkin.assets.FunkinAssetCache)
class AssetsUtil
{
  /**
   * This function does the following:
   * - Retrieves the underlying texture from a BitmapData object.
   * - Uploads the texture to the GPU via the render context. This is handled by OpenFL differently based on target platform.
   * - Creates a new BitmapData object and ties the uploaded texture to it.
   *
   * NOTE: From what I've read, this must be done from the main thread to prevent corrupted graphics.
   *
   * @param bitmapData The BitmapData to upload.
   * @param optimizeForRender
   * @return BitmapData
   */
  static function uploadBitmapDataToGPU(bitmapData:BitmapData, optimizeForRender = true):BitmapData
  {
    #if FEATURE_GPU_TEXTURES
    trace('Uploading bitmap data to GPU... ${bitmapData?.image?.premultiplied}');

    // Retrieve the render context.
    var context:Context3D = FlxG.stage.context3D;

    // Create a new texture object using the render context.
    var texture:Texture = context.createTexture(bitmapData.width, bitmapData.height, Context3DTextureFormat.BGRA, optimizeForRender);

    // TODO: Figure out how to use texture.uploadCompressedTextureFromByteArray to save GPU memory.

    // Upload the texture to the GPU.
    // This is an expensive operation so don't do it in the UI thread if you can help it.
    texture.uploadFromBitmapData(bitmapData);

    // Now that the texture is uploaded, the `Texture` object is all we need to render it in-game.
    // We can dispose of the BitmapData object now.
    bitmapData.dispose();
    bitmapData.disposeImage();

    // Build a new, optimized BitmapData object using the Texture object.
    var output:BitmapData = BitmapData.fromTexture(texture);

    return output;
    #else
    // Don't do anything on builds with GPU textures turned off.
    return bitmapData;
    #end
  }

  /**
   * Returns the `FunkinAssetType` for a given path, if it has a known extension.
   * @param path The path to query.
   * @return The corresponding `FunkinAssetType`, or `FunkinAssetType.UNKNOWN`.
   */
  public static function guessTypeByExtension(path:String):FunkinAssetType
  {
    var ext:String = Path.extension(path);
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
      case 'hxs': // Haxe script
        return FunkinAssetType.SCRIPT;
      case 'hscript': // Haxe script
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
