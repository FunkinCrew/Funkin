package funkin.util;

import polymod.hscript._internal.PolymodClassDeclEx;
import polymod.hscript._internal.PolymodEnumDeclEx;
import polymod.hscript._internal.PolymodInterpEx;

/**
 * Utility class for accessing the AST descriptors and other information from scripted classes and enums loaded through Polymod.
 * Useful for mods that require reflection, inspection or mixin capabilities :)
 */
class PolymodUtil {
  /**
   * Returns a map of all currently loaded scripted enum descriptors.
   */
  public static function listScriptedEnums():Map<String, PolymodEnumDeclEx>
  {
    @:privateAccess
    return PolymodInterpEx._scriptEnumDescriptors;
  }

  /**
   * Retrieves a scripted enum descriptor by key.
   *
   * @param key The name of the scripted class. Include the package if the class has one; otherwise, just use the class name.
   * @return The scripted enum descriptor for the given key, or `null` if not found.
   */
  public static function getScriptedEnum(key:String):PolymodEnumDeclEx
  {
    @:privateAccess
    return PolymodInterpEx._scriptEnumDescriptors.get(key);
  }

  /**
   * Returns a map of all currently loaded scripted class descriptors.
   */
  public static function listScriptedClasses():Map<String, PolymodClassDeclEx>
  {
    @:privateAccess
    return PolymodInterpEx._scriptClassDescriptors;
  }

  /**
   * Retrieves a scripted class descriptor by key.
   *
   * @param key The name of the scripted class. Include the package if the class has one; otherwise, just use the class name.
   * @return The scripted class descriptor for the given key, or `null` if not found.
   */
  public static function getScriptedClass(key:String):PolymodClassDeclEx
  {
    return PolymodInterpEx.findScriptClassDescriptor(key);
  }
}
