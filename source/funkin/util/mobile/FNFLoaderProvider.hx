package funkin.util.mobile;

import flixel.util.FlxSignal;

using StringTools;

/**
 * Handles externally opened charts, mod archives, and FNFMOD links on mobile
 */
@:unreflective
class FNFLoaderProvider
{
  public static var onFNFCOpen:FlxTypedSignal<String->Void>;
  public static var onFNFMODOpen:FlxTypedSignal<String->Void>;
  public static var onModArchiveOpen:FlxTypedSignal<String->String->Void>;
  public static var onModArchiveError:FlxTypedSignal<String->Void>;

  public static function init():Void
  {
    onFNFCOpen = new FlxTypedSignal<String->Void>();
    onFNFMODOpen = new FlxTypedSignal<String->Void>();
    onModArchiveOpen = new FlxTypedSignal<String->String->Void>();
    onModArchiveError = new FlxTypedSignal<String->Void>();

    #if ios
    FlxG.stage.window.onDropFile.add(function(file:lime.utils.DroppedFile, state:String, x:Float, y:Float):Void
    {
      final path:Null<String> = file.path;

      if (path != null && path.startsWith("funkin:"))
      {
        if (path == launchFNFMOD && !launchFNFMODEchoed)
        {
          launchFNFMODEchoed = true;
          return;
        }

        onFNFMODOpen.dispatch(path);
        return;
      }

      if (path != null && isModArchiveURL(path))
      {
        getModArchiveFromURL(path);
        return;
      }

      if (path != null && isFNFCURL(path))
      {
        getFNFCFromURL(path);
        return;
      }

      final fileURL:Null<String> = lime.system.System.getHint('IOS_UIApplicationLaunchOptionsURLKey');

      if (fileURL != null && fileURL.length > 0 && !fileURL.startsWith("funkin:"))
      {
        if (isModArchiveURL(fileURL))
        {
          getModArchiveFromURL(fileURL);
        }
        else if (isFNFCURL(fileURL))
        {
          getFNFCFromURL(fileURL);
        }
      }
    });
    #elseif android
    funkin.external.android.CallbackUtil.onFNFCOpen.add(onFNFCOpen.dispatch);
    funkin.external.android.CallbackUtil.onFNFMODOpen.add(onFNFMODOpen.dispatch);
    funkin.external.android.CallbackUtil.onModArchiveOpen.add(onModArchiveOpen.dispatch);
    funkin.external.android.CallbackUtil.onModArchiveError.add(onModArchiveError.dispatch);
    #end
  }

  public static function queryModArchive():Null<
    {path:String, fileName:String}>
  {
    #if ios
    final fileURL:Null<String> = lime.system.System.getHint('IOS_UIApplicationLaunchOptionsURLKey');

    if (fileURL != null && isModArchiveURL(fileURL))
    {
      getModArchiveFromURL(fileURL);
    }
    #elseif android
    final pathField = funkin.external.android.JNIUtil.createStaticField('funkin/extensions/FNFLoaderExtension', 'lastModArchive', 'Ljava/lang/String;');
    final nameField = funkin.external.android.JNIUtil.createStaticField('funkin/extensions/FNFLoaderExtension', 'lastModArchiveName', 'Ljava/lang/String;');

    if (pathField != null && nameField != null)
    {
      final path:Null<String> = pathField.get();
      final fileName:Null<String> = nameField.get();

      if (path != null && fileName != null) return {
        path: path,
        fileName: fileName
      };
    }
    #end

    return null;
  }

  public static function queryModArchiveError():Null<String>
  {
    #if android
    final errorField = funkin.external.android.JNIUtil.createStaticField('funkin/extensions/FNFLoaderExtension', 'lastModArchiveError', 'Ljava/lang/String;');

    if (errorField != null)
    {
      return errorField.get();
    }
    #end

    return null;
  }

  public static function queryFNFC():Null<String>
  {
    #if ios
    final fileURL:Null<String> = lime.system.System.getHint('IOS_UIApplicationLaunchOptionsURLKey');

    if (fileURL != null && isFNFCURL(fileURL))
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
      launchFNFMOD = fileURL;
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
  private static var pendingModArchiveURL:Null<String> = null;
  private static var pendingModArchiveName:Null<String> = null;
  #end

  static function isModArchiveURL(url:String):Bool
  {
    final normalizedURL:String = url.split('?')[0].split('#')[0].toLowerCase();
    return normalizedURL.endsWith('.zip') || normalizedURL.endsWith('.fnfmod');
  }

  static function isFNFCURL(url:String):Bool
  {
    final normalizedURL:String = url.split('?')[0].split('#')[0].toLowerCase();
    return normalizedURL.endsWith('.fnfc');
  }

  #if ios
  @:noCompletion
  private static var launchFNFMOD:Null<String> = null;
  @:noCompletion
  private static var launchFNFMODEchoed:Bool = false;
  @:noCompletion
  private static var _lastFNFC:Null<String> = null;

  @:noCompletion
  private static function getFNFCFromURL(url:String):Void
  {
    funkin.external.apple.FNFCExtern.copyFNFCIntoCache((url : cpp.ConstCharStar), cpp.Callable.fromStaticFunction(fnfcCallback));
  }

  @:noCompletion
  private static function getModArchiveFromURL(url:String):Void
  {
    if (pendingModArchiveURL != null) return;

    final cleanURL:String = url.split('?')[0].split('#')[0];
    pendingModArchiveURL = url;
    pendingModArchiveName = haxe.io.Path.withoutDirectory(StringTools.urlDecode(cleanURL));

    funkin.external.apple.ModArchiveExtern.copyModArchiveIntoCache((url : cpp.ConstCharStar), cpp.Callable.fromStaticFunction(fnfcCallback));
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
        case 'MOD_ARCHIVE_RESULTS':
          onModArchiveOpen.dispatch(value, pendingModArchiveName ?? haxe.io.Path.withoutDirectory(value));
          pendingModArchiveURL = null;
          pendingModArchiveName = null;
        case 'MOD_ARCHIVE_ERROR':
          onModArchiveError.dispatch(value);
          pendingModArchiveURL = null;
          pendingModArchiveName = null;
        default:
      }
    }
  }
  #end
}
