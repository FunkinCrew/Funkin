package funkin.external.apple;

#if ios
/**
 * Utility class for keyboard detection.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml')) @:include('KeyboardUtil.hpp') @:unreflective
extern class KeyboardUtil
{
  /**
   * Retrieves wether a hardware keyboard is connected to the device.
   *
   * Works on iOS 16.4 and later.
   *
   * @return Returns a Boolean value that indicates whether someone is likely to enter text using a hardware keyboard.
   */
  @:native('Apple_KeyboardUtil_isKeyboardConnected')
  static function isKeyboardConnected():Bool;
}
#end
