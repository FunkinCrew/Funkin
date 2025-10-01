package funkin.mobile.util;

#if ios
import funkin.external.apple.FNFCUtil as NativeFNFCUtil;
#end
#if android
import funkin.external.android.JNIUtil;
import funkin.external.android.CallbackUtil;
#end
import lime.system.System;
import flixel.util.FlxSignal;

/**
 * A class for handling the flow of loading FNFC song packs on mobile.
 */
class FNFCUtil
{
  public static var onFNFCOpen:FlxTypedSignal<String->Void>;

  public static function init():Void
  {
    onFNFCOpen = new FlxTypedSignal<String->Void>();

    #if ios
    FlxG.stage.window.onDropFile.add(function(_) {
      final url = queryFNFC();
      if (url != null) onFNFCOpen.dispatch(getFNFCFromURL(url));
    });
    #elseif android
    CallbackUtil.onFNFCOpen.add(onFNFCOpen.dispatch);
    #end

    final fnfcFile:String = queryFNFC();

    if (fnfcFile != null)
    {
      trace('Got FNFC File from $fnfcFile!');
    }
  }

  public static function queryFNFC():Null<String>
  {
    #if ios
    return System.getHint("IOS_UIApplicationLaunchOptionsURLKey");
    #elseif android
    final staticField = JNIUtil.createStaticField('funkin/extensions/FNFCExtension', 'lastFNFC', 'Ljava/lang/String;');
    if (staticField != null) return staticField.get();
    #end
    return null;
  }

  #if ios
  /**
   * Copy a FNFC file from an iOS sandboxed URL into the cache directory and returns it's absolute path from there.
   * @param url A iOS `file://` URL.
   * @return    The new path that the file the URL points at inside of the cache directory.
   */
  @:noCompletion
  private static function getFNFCFromURL(url:String):String
  {
    var cURL:cpp.ConstCharStar = cast url;

    var cPath:cpp.ConstCharStar = NativeFNFCUtil.copyFNFCIntoCache(cURL);

    var path:String = cast cPath;
    return path;
  }
  #end
}
