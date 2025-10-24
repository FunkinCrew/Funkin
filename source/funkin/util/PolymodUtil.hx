package funkin.util;

import hscript.Printer;
import polymod.hscript._internal.PolymodClassDeclEx;
import polymod.hscript._internal.PolymodEnumDeclEx;
import polymod.hscript._internal.PolymodInterpEx;
import polymod.hscript._internal.PolymodScriptClass;

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

  /**
   * Returns a list of the names of all currently loaded scripted classes.
   */
  public static function listScriptClassesNames():Array<String>
  {
    return PolymodScriptClass.listScriptClasses();
  }

  /**
   * Returns a list of all currently loaded scripted classes that extend the specified class.
   *
   * @param clazz The parent class that the returned scripted classes should extend.
   * @return An array containing all fully qualified names of all scripted classes that are subclasses of the provided class.
   */
  public static function listScriptedClassesExtendingClass(clazz:Class<Dynamic>):Array<String>
  {
    @:privateAccess
    return PolymodScriptClass.listScriptClassesExtendingClass(clazz);
  }

  /**
   * Returns a new `hscript.Printer` instance.
   *
   * Can be used to convert scripted class expressions into a readable string representation,
   * which is useful for debugging or inspecting scripted classes.
   */
  public static function getPrinter():Printer
  {
    return new Printer();
  }
}
