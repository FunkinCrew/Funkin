package funkin.modding;

@:nullSafety
class CppiaScripts
{
  /**
   * Whether a loaded compiled script is providing this class.
   */
  public static function exists(clsName:String):Bool
  {
    #if (hxcpp && POLYMOD_CPPIA)
    return polymod.hscript._internal.PolymodCppiaClassReference.hasCppiaClass(clsName);
    #else
    return false;
    #end
  }

  /**
   * Every class the loaded compiled scripts provide.
   */
  public static function list():Array<String>
  {
    #if (hxcpp && POLYMOD_CPPIA)
    return polymod.hscript._internal.PolymodCppiaClassReference.listCppiaClasses();
    #else
    return [];
    #end
  }

  /**
   * Every provided class that descends from the named one.
   */
  public static function listExtending(clsPath:String):Array<String>
  {
    #if (hxcpp && POLYMOD_CPPIA)
    return polymod.hscript._internal.PolymodCppiaClassReference.listCppiaClassesExtending(clsPath);
    #else
    return [];
    #end
  }

  /**
   * The class itself, for a type check or to hand to something that wants one.
   */
  public static function resolve(clsName:String):Null<Class<Dynamic>>
  {
    #if (hxcpp && POLYMOD_CPPIA)
    return polymod.hscript._internal.PolymodCppiaClassReference.getCppiaClass(clsName);
    #else
    return null;
    #end
  }

  /**
   * Build one, reporting rather than throwing if it is missing or its constructor fails.
   */
  public static function create(clsName:String, ?args:Array<Dynamic>):Null<Dynamic>
  {
    #if (hxcpp && POLYMOD_CPPIA)
    var ref = polymod.hscript._internal.PolymodCppiaClassReference.tryBuildCppia(clsName);
    if (ref == null)
    {
      missing(clsName, 'constructed');
      return null;
    }
    return ref.instantiate(args ?? []);
    #else
    return null;
    #end
  }

  /**
   * Call one of its static functions.
   */
  public static function call(clsName:String, funcName:String, ?args:Array<Dynamic>):Dynamic
  {
    #if (hxcpp && POLYMOD_CPPIA)
    var ref = polymod.hscript._internal.PolymodCppiaClassReference.tryBuildCppia(clsName);
    if (ref == null)
    {
      missing(clsName, 'called');
      return null;
    }
    return ref.callFunction(funcName, args ?? []);
    #else
    return null;
    #end
  }

  /**
   * Read one of its static fields.
   */
  public static function getField(clsName:String, fieldName:String):Dynamic
  {
    #if (hxcpp && POLYMOD_CPPIA)
    var ref = polymod.hscript._internal.PolymodCppiaClassReference.tryBuildCppia(clsName);
    if (ref == null)
    {
      missing(clsName, 'read');
      return null;
    }
    return ref.getField(fieldName);
    #else
    return null;
    #end
  }

  /**
   * Write one of its static fields.
   */
  public static function setField(clsName:String, fieldName:String, value:Dynamic):Dynamic
  {
    #if (hxcpp && POLYMOD_CPPIA)
    var ref = polymod.hscript._internal.PolymodCppiaClassReference.tryBuildCppia(clsName);
    if (ref == null)
    {
      missing(clsName, 'written');
      return null;
    }
    return ref.setField(fieldName, value);
    #else
    return null;
    #end
  }

  static function missing(clsName:String, verb:String):Void
  {
    #if (hxcpp && POLYMOD_CPPIA)
    var reason:String = polymod.hscript._internal.PolymodCppiaClassReference.isInactiveCppiaClass(clsName) ? 'its mod is no longer enabled' : 'no loaded compiled script provides it';
    polymod.Polymod.error(SCRIPT_RUNTIME_EXCEPTION, 'Compiled class ($clsName) cannot be $verb, $reason. Check CppiaScripts.exists() first.', SCRIPT_RUNTIME);
    #end
  }
}
