package funkin.external.android;

#if android
import lime.system.JNI;

/**
 * Utility class for keyboard detection.
 */
class KeyboardUtil
{
  /**
   * Returns `true` if a keyboard is currently connected to the device.
   */
  public static var keyboardConnected(get, never):Bool;

  @:noCompletion
  static function get_keyboardConnected():Bool
  {
    final method:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/KeyboardUtil', 'isKeyboardConnected', '()Z');

    if (method == null) return false;

    return inline JNI.callStatic(method, []);
  }
}
#end
