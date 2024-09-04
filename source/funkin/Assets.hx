package funkin;

/**
 * A wrapper around `openfl.utils.Assets` which disallows access to the harmful functions.
 * Later we'll add Funkin-specific caching to this.
 */
class Assets
{
  public static function getText(path:String):String
  {
    return openfl.utils.Assets.getText(path);
  }

  public static function getMusic(path:String):openfl.media.Sound
  {
    return openfl.utils.Assets.getMusic(path);
  }

  public static function getBitmapData(path:String):openfl.display.BitmapData
  {
    return openfl.utils.Assets.getBitmapData(path);
  }

  public static function getBytes(path:String):haxe.io.Bytes
  {
    return openfl.utils.Assets.getBytes(path);
  }

  public static function exists(path:String, ?type:openfl.utils.AssetType):Bool
  {
    return openfl.utils.Assets.exists(path, type);
  }

  public static function list(type:openfl.utils.AssetType):Array<String>
  {
    return openfl.utils.Assets.list(type);
  }
}
