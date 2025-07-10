package funkin.mobile.external.android;

import lime.system.JNI;

/**
 * A Utility class to manage the Application's Data folder on Android.
 */
@:unreflective
class DataFolderUtil
{
  @:noCompletion
  static var staticMethodCache:Map<String, Dynamic> = [];

  public static function openDataFolder():Void
  {
    final openDataFolderJNI:Null<Dynamic> = createStaticMethod('funkin/util/DataFolderUtil', 'openDataFolder', '()V');

    if (openDataFolderJNI != null) openDataFolderJNI();
  }

  @:noCompletion
  static function createStaticMethod(className:String, methodName:String, signature:String, cache:Bool = true):Null<Dynamic>
  {
    @:privateAccess
    className = JNI.transformClassName(className);

    final key:String = '$className::$methodName::$signature';

    if (cache && !staticMethodCache.exists(key)) staticMethodCache.set(key, JNI.createStaticMethod(className, methodName, signature));
    else if (!cache) return JNI.createStaticMethod(className, methodName, signature);

    return staticMethodCache.get(key);
  }
}
