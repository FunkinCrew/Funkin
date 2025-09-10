package funkin.mobile.util;

#if ios
import funkin.external.apple.FNFCUtil as NativeFNFCUtil;
#end
import flixel.util.FlxSignal;

/**
 * A class for handling the flow of loading FNFC song packs on mobile.
 */
class FNFCUtil
{
  public static var onFNCOpen:FlxTypedSignal<String->Void>;

  public static function init():Void
  {
    onFNCOpen = new FlxTypedSignal<String->Void>();

    #if ios
    FlxG.stage.window.onDropFile.add(function(_) {
      final url = lime.system.System.getHint("IOS_UIApplicationLaunchOptionsURLKey");
      onFNCOpen.dispatch(getFNFCFromURL(url));
    });
    #end
  }

  #if ios
  /**
   * Copy a FNFC file from an iOS sandboxed URL into the cache directory and returns it's absolute path from there.
   * @param url A iOS `file://` URL.
   * @return    The new path that the file the URL points at inside of the cache directory.
   */
  public static function getFNFCFromURL(url:String):String
  {
    var cURL:cpp.ConstCharStar = cast url;

    var cPath:cpp.ConstCharStar = NativeFNFCUtil.copyFNFCIntoCache(cURL);

    var path:String = cast cPath;
    return path;
  }
  #end
}
