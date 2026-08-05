package funkin.mobile.util;

import flixel.util.FlxSignal;

/**
 * A class for handling the flow of loading FNFC song packs and FNFMOD Links on mobile.
 */
@:unreflective
class FNFLoaderProvider
{
  public static var onFNFCOpen:FlxTypedSignal<String->Void>;
  public static var onFNFMODOpen:FlxTypedSignal<String->Void>;

  public static function init():Void
  {
    onFNFCOpen = new FlxTypedSignal<String->Void>();
    onFNFMODOpen = new FlxTypedSignal<String->Void>();

    #if ios
    FlxG.stage.window.onDropFile.add(function(path:String, state:String, x:Float, y:Float):Void
    {
      final fileURL:Null<String> = lime.system.System.getHint('IOS_UIApplicationLaunchOptionsURLKey');

      if (fileURL != null && fileURL.length > 0)
      {
        if (fileURL.startsWith("funkin:"))
        {
          onFNFMODOpen.dispatch(fileURL);
        }
        else
        {
          getFNFCFromURL(fileURL);
        }
      }
    });
    #elseif android
    funkin.external.android.CallbackUtil.onFNFCOpen.add(onFNFCOpen.dispatch);
    funkin.external.android.CallbackUtil.onFNFMODOpen.add(onFNFMODOpen.dispatch);
    #end
  }

  public static function queryFNFC():Null<String>
  {
    #if ios
    final fileURL:Null<String> = lime.system.System.getHint('IOS_UIApplicationLaunchOptionsURLKey');

    if (fileURL != null && fileURL.length > 0 && !fileURL.startsWith("funkin:"))
    {
      getFNFCFromURL(fileURL);
    }
    #elseif android
    final staticField = funkin.external.android.JNIUtil.createStaticField('funkin/extensions/FNFLoaderExtension', 'lastFNFC', 'Ljava/lang/String;');

    if (staticField != null)
    {
      return staticField.get();
    }
    #end

    return null;
  }

  public static function queryFNFMOD():Null<String>
  {
    #if ios
    final fileURL:Null<String> = lime.system.System.getHint('IOS_UIApplicationLaunchOptionsURLKey');

    if (fileURL != null && fileURL.length > 0 && fileURL.startsWith("funkin:"))
    {
      return fileURL;
    }
    #elseif android
    final staticField = funkin.external.android.JNIUtil.createStaticField('funkin/extensions/FNFLoaderExtension', 'lastFNFMOD', 'Ljava/lang/String;');

    if (staticField != null)
    {
      return staticField.get();
    }
    #end

    return null;
  }

  #if ios
  @:noCompletion
  private static var _lastFNFC:Null<String> = null;

  @:noCompletion
  private static function getFNFCFromURL(url:String):Void
  {
    funkin.external.apple.FNFCExtern.copyFNFCIntoCache((url : cpp.ConstCharStar), cpp.Callable.fromStaticFunction(fnfcCallback));
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
        case 'FNFC_RESULTS':
          onFNFCOpen.dispatch(value);
        default:
      }
    }
  }
  #end
}
