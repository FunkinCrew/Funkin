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
      if (url != null) getFNFCFromURL(url);
    });
    #elseif android
    CallbackUtil.onFNFCOpen.add(onFNFCOpen.dispatch);
    #end
  }

  public static function queryFNFC():Null<String>
  {
    #if ios
    final fileURL:Null<String> = System.getHint("IOS_UIApplicationLaunchOptionsURLKey");
    if (fileURL != null && fileURL.length > 0) getFNFCFromURL(fileURL);
    #elseif android
    final staticField = JNIUtil.createStaticField('funkin/extensions/FNFCExtension', 'lastFNFC', 'Ljava/lang/String;');
    if (staticField != null) return staticField.get();
    #end
    return null;
  }

  #if ios
  @:noCompletion
  private static var _lastFNFC:Null<String> = null;

  @:noCompletion
  private static function getFNFCFromURL(url:String):Void
  {
    var cURL:cpp.ConstCharStar = cast url;
    NativeFNFCUtil.copyFNFCIntoCache(cURL, cpp.Callable.fromStaticFunction(fnfcCallback));
  }

  @:noCompletion
  private static function fnfcCallback(cEvent:cpp.ConstCharStar, cValue:cpp.ConstCharStar)
  {
    var event:String = cast cEvent;
    var value:String = cast cValue;

    if (event != null && value != null)
    {
      trace('[$event] $value');
      switch (event)
      {
        case "FNFC_RESULTS":
          onFNFCOpen.dispatch(value);
        default:
      }
    }
  }
  #end
}
