package funkin.external.android;

#if android
import lime.system.JNI;

/**
 * A utility class to get Android device specs.
 */
class DeviceUtil
{
  /**
   * Retrieves the total device memory.
   *
   * @return The total memory in mb, or 0 on failure.
   */
  public static function getTotalMemory():Int
  {
    final method:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/DeviceUtil', 'getTotalMemory', '()I');

    if (method == null) return 0;

    return inline JNI.callStatic(method, []);
  }

  /**
   * Retrieves the media performance class the device was certified for.
   *
   * @return The performance class (31 and up), or 0 if the device has none.
   */
  public static function getPerformanceClass():Int
  {
    final method:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/DeviceUtil', 'getPerformanceClass', '()I');

    if (method == null) return 0;

    return inline JNI.callStatic(method, []);
  }
}
#end
