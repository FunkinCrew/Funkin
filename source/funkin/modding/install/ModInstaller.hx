package funkin.modding.install;

/**
 * Stub. The one-click mod installer is not part of QT Slice yet.
 * Every call here is a no-op, so the mod menu works without installing from links.
 */
typedef OneClickMod = Dynamic;

typedef OneClickRequest = Dynamic;

class ModInstaller
{
  public static function cancelDownload():Void {}

  public static function cancelInstall():Void {}

  public static function fetchMetadata(request:Dynamic, onDone:Dynamic, ?onError:Dynamic):Void {}

  public static function downloadIcon(mod:Dynamic, onDone:Dynamic):Void {}

  public static function isAlreadyInstalled(mod:Dynamic):Bool
  {
    return false;
  }

  public static function download(mod:Dynamic, onProgress:Dynamic):Void {}

  public static function install(mod:Dynamic, archivePath:String, onProgress:Dynamic):Void {}

  public static function requestForRequirement(requirement:Dynamic):Null<Dynamic>
  {
    return null;
  }
}
