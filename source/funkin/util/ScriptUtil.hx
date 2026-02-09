package funkin.util;

import polymod.hscript._internal.PolymodScriptClass;
import polymod.hscript._internal.PolymodStaticClassReference;
import polymod.hscript._internal.PolymodInterpEx;

/**
 * Class for accessing certain functions from Polymod that
 * may be useful for mods
 */
class ScriptUtil
{
  /**
   * Returns a list of scripted classes that extend a given class.
   *
   * @param clsPath The super class to get the scripted classes from.
   * @return An array of the names of the scripted classes.
   */
  public static function listScriptClassesExtending(clsPath:String):Array<String>
  {
    return PolymodScriptClass.listScriptClassesExtending(clsPath);
  }

  /**
   * Returns a static reference to a given scripted class.
   *
   * @param clsPath The scripted class to get.
   * @return The static reference.
   */
  public static function resolveStaticClassReference(clsPath:String):Null<PolymodStaticClassReference>
  {
    return PolymodStaticClassReference.tryBuild(clsPath);
  }

  /**
   * Returns a instance of a given scripted class.
   *
   * @param clsPath The scripted class to instantiate.
   * @param args Arguments for the contructor (if needed).
   * @return The new instance.
   */
  public static function instantiateFromScriptedClass(clsPath:String, ?args:Array<Dynamic>):Dynamic
  {
    return PolymodStaticClassReference.tryBuild(clsPath).instantiate(args);
  }
}
