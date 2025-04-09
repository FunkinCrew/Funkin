package funkin.util;

import Type.ValueType;
import polymod.hscript._internal.PolymodScriptClass;
import thx.Types;

@:nullSafety
class ReflectUtil
{
  public static function createEmptyInstance(cls:Class<Dynamic>):Dynamic
  {
    throw "Function Type.createEmptyInstance is blacklisted.";
  }

  public static function createInstance(cls:Class<Dynamic>, args:Array<Dynamic>):Dynamic
  {
    throw "Function Type.createInstance is blacklisted.";
  }

  public static function resolveClass(name:String):Class<Dynamic>
  {
    throw "Function Type.resolveClass is blacklisted.";
  }

  public static function resolveEnum(name:String):Enum<Dynamic>
  {
    throw "Function Type.resolveEnum is blacklisted.";
  }

  public static function typeof(value:Dynamic):ValueType
  {
    throw "Function Type.typeof is blacklisted.";
  }

  /**
   * Get the class name of a class type.
   *
   * @param cls The class type.
   * @return The class name.
   */
  public static function getClassName(cls:Class<Dynamic>):String
  {
    return Type.getClassName(cls);
  }

  /**
   * Get the class name of an object, class instance, or script class instance.
   *
   * @param obj The object instance.
   * @return The class name, or `null` if the object was not of a class.
   */
  public static function getClassNameOf(obj:Dynamic):Null<String>
  {
    @:privateAccess if (obj?._asc is PolymodScriptClass)
    {
      return obj._asc.get_className();
    }

    var cls:Class<Dynamic> = Type.getClass(obj);
    if (cls == null)
    {
      return null;
    }

    return getClassName(cls);
  }

  /**
   * Get a list of static fields of a class.
   *
   * @param cls The class type.
   * @return An array of field names.
   */
  public static function getClassFields(cls:Class<Dynamic>):Array<String>
  {
    return Type.getClassFields(cls);
  }

  /**
   * Get a list of static fields of an object.
   *
   * @param obj The object instance.
   * @return An array of field names, or `null` if the object was not of a class.
   */
  public static function getClassFieldsOf(obj:Dynamic):Null<Array<String>>
  {
    var cls:Class<Dynamic> = Type.getClass(obj);
    if (cls == null)
    {
      return null;
    }

    return getClassFields(cls);
  }

  /**
   * Get a list of instance fields of a class.
   *
   * @param cls The class type.
   * @return An array of field names.
   */
  public static function getInstanceFields(cls:Class<Dynamic>):Array<String>
  {
    return Type.getInstanceFields(cls);
  }

  /**
   * Get instance fields of an object or class instance.
   *
   * @param obj The object instance.
   * @return An array of field names, or `null` if the object was not an object.
   */
  public static function getInstanceFieldsOf(obj:Dynamic):Null<Array<String>>
  {
    var cls:Class<Dynamic> = Type.getClass(obj);
    if (cls == null)
    {
      return getFieldsOf(obj);
    }

    return getInstanceFields(cls);
  }

  public static function callMethod(obj:Dynamic, name:String, args:Array<Dynamic>):Dynamic
  {
    throw "Function Reflect.callMethod is blacklisted.";
  }

  /**
   * Check if a value is an anonymous object.
   *
   * @param value The value.
   * @return `true` if the object is anonymous, and `false` otherwise.
   */
  public static function isAnonymousObject(value:Dynamic):Bool
  {
    return Types.isAnonymousObject(value);
  }

  /**
   * Check if a value is an object.
   * This includes classes and class instances, structures (including anonymous objects), and enums.
   *
   * @param value The value.
   * @return `true` if the object is an object, and `false` otherwise.
   */
  public static function isObject(value:Dynamic):Bool
  {
    return Types.isObject(value);
  }

  /**
   * Check if a value is a function.
   *
   * @param value The value.
   * @return `true` if the object is a function, and `false` otherwise.
   */
  public static function isFunction(value:Dynamic):Bool
  {
    return Reflect.isFunction(value);
  }

  /**
   * Check if a value is an enum value.
   *
   * @param value The value.
   * @return `true` if the object is an enum value, and `false` otherwise.
   */
  public static function isEnumValue(value:Dynamic):Bool
  {
    return Reflect.isEnumValue(value);
  }

  /**
   * Check if a value is a primitive.
   * This includes `Int`, `Float`, `Bool`, `String`, and `Date`.
   *
   * @param value The value.
   * @return `true` if the object is a primitive, and `false` otherwise.
   */
  public static function isPrimitive(value:Dynamic):Bool
  {
    return Types.isPrimitive(value);
  }

  /**
   * Safely attempt to get a field of an object, or a field of a class if the field exists.
   *
   * @param obj The object instance.
   * @param name The field name.
   * @return The field value, or `null` if the field does not exist or the object was not an object.
   */
  public static function getField(obj:Dynamic, name:String):Null<Dynamic>
  {
    if (isAnonymousObject(obj) || hasField(obj, name))
    {
      return Reflect.field(obj, name);
    }

    return null;
  }

  /**
   * Get a list of fields of an object or class instance.
   *
   * @param obj The object instance.
   * @return An array of field names, or `null` if the object was not an object.
   */
  public static function getFieldsOf(obj:Dynamic):Null<Array<String>>
  {
    if (isObject(obj))
    {
      return Reflect.fields(obj);
    }

    return null;
  }

  /**
   * Safely attempt to set a field of an anonymous object, or a field of a class if the field exists.
   *
   * @param obj The object instance.
   * @param name The field name.
   * @param value The value to set.
   * @return The input value, for chaining, or `null` if the object was not an object.
   */
  public static function setField(obj:Dynamic, name:String, value:Dynamic):Null<Dynamic>
  {
    if (isAnonymousObject(obj) || hasField(obj, name))
    {
      Reflect.setField(obj, name, value);
      return value;
    }

    return null;
  }

  /**
   * Check if an object or class instance has a field.
   *
   * @param obj The object instance.
   * @param name The field name.
   * @return `true` if the field exists, and `false` otherwise or if the object was not an object.
   */
  public static function hasField(obj:Dynamic, name:String):Bool
  {
    if (!isObject(obj))
    {
      return false;
    }

    return Reflect.hasField(obj, name);
  }

  /**
   * Alias for `copyAnonymousFieldsOf`.
   */
  public static function copy(obj:Dynamic):Null<Dynamic>
  {
    return copyAnonymousFieldsOf(obj);
  }

  /**
   * Shallow-copy an anonymous object.
   *
   * @param obj The object instance.
   * @return A new anonymous object with the same fields, or `null` if the object was not an anonymous object.
   */
  public static function copyAnonymousFieldsOf(obj:Dynamic):Null<Dynamic>
  {
    if (isAnonymousObject(obj))
    {
      return Reflect.copy(obj);
    }

    return null;
  }

  /**
   * Alias for `deleteAnonymousField`.
   */
  public static function delete(obj:Dynamic, name:String):Bool
  {
    return deleteAnonymousField(obj, name);
  }

  /**
   * Delete a field of an anonymous object.
   *
   * @param obj The object instance.
   * @param name The field name.
   * @return `true` if the field existed and was deleted, and `false` otherwise.
   */
  public static function deleteAnonymousField(obj:Dynamic, name:String):Bool
  {
    if (isAnonymousObject(obj) && hasField(obj, name))
    {
      return Reflect.deleteField(obj, name);
    }

    return false;
  }

  /**
   * Safely attempt to get a property of an object, class instance, or scripted class instance.
   *
   * @param obj The object instance.
   * @param name The property name.
   * @return The property value, or `null` if the object was not an object or the property did not exist.
   */
  public static function getProperty(obj:Dynamic, name:String):Null<Dynamic>
  {
    if (!isObject(obj))
    {
      return null;
    }

    if (hasField(obj, name))
    {
      return Reflect.getProperty(obj, name);
    }

    @:privateAccess if (obj?._asc is PolymodScriptClass)
    {
      try
      {
        return getScriptField(obj, name);
      }
      catch (e:Dynamic) {}
    }

    return null;
  }

  /**
   * Safely attempt to set a property of an object, class instance, or scripted class instance.
   *
   * @param obj The object instance.
   * @param name The property name.
   * @param value The value to set.
   * @return The input value, for chaining.
   */
  public static function setProperty(obj:Dynamic, name:String, value:Dynamic):Dynamic
  {
    if (!isObject(obj))
    {
      return value;
    }

    if (hasField(obj, name))
    {
      Reflect.setProperty(obj, name, value);
    }
    else @:privateAccess if (obj?._asc is PolymodScriptClass)
    {
      try
      {
        setScriptField(obj, name, value);
      }
      catch (e:Dynamic) {}
    }
    else
    {
      setField(obj, name, value);
    }

    return value;
  }

  @:deprecated("Use `getFieldsOf` instead")
  public static function getAnonymousFieldsOf(obj:Dynamic):Array<String>
  {
    return Reflect.fields(obj);
  }

  @:deprecated("Use `getField` instead")
  public static function getAnonymousField(obj:Dynamic, name:String):Dynamic
  {
    return Reflect.field(obj, name);
  }

  @:deprecated("Use `setField` instead")
  public static function setAnonymousField(obj:Dynamic, name:String, value:Dynamic):Void
  {
    Reflect.setField(obj, name, value);
  }

  @:deprecated("Use `hasField` instead")
  public static function hasAnonymousField(obj:Dynamic, name:String):Bool
  {
    return Reflect.hasField(obj, name);
  }

  /**
   * Safely attempt to get a script field of a scripted class instance.
   *
   * @param obj The scripted object instance.
   * @param name The field name.
   * @return The field value, or `null` if the object was not of a scripted class or the field did not exist.
   */
  public static function getScriptField(obj:Dynamic, name:String):Null<Dynamic>
  {
    @:privateAccess if (obj?._asc is PolymodScriptClass)
    {
      try
      {
        return obj.scriptGet(name);
      }
      catch (e:Dynamic) {}
    }

    return null;
  }

  /**
   * Get script fields of a scripted class instance.
   *
   * @param obj The scripted object instance.
   * @return An array of field names, or `null` if the object was not of a scripted class or the fields could not be retrieved.
   */
  public static function getScriptFieldsOf(obj:Dynamic):Null<Array<String>>
  {
    @:privateAccess if (obj?._asc is PolymodScriptClass)
    {
      var decls:Null<Map<String, hscript.Expr.FieldDecl>> = cast obj._asc._cachedFieldDecls;
      if (decls == null)
      {
        return null;
      }

      var scriptFields:Array<String> = new Array<String>();
      for (decl in decls.iterator())
      {
        scriptFields.push(decl.name);
      }

      return scriptFields;
    }

    return null;
  }

  /**
   * Safely attempt to set a script field of a scripted class instance.
   *
   * @param obj The scripted object instance.
   * @param name The field name.
   * @param value The value to set.
   * @return The input value, for chaining, or `null` if the object was not of a scripted class or the field did not exist.
   */
  public static function setScriptField(obj:Dynamic, name:String, value:Dynamic):Null<Dynamic>
  {
    @:privateAccess if (obj?._asc is PolymodScriptClass)
    {
      try
      {
        obj.scriptSet(name, value);
        return value;
      }
      catch (e:Dynamic) {}
    }

    return null;
  }

  /**
   * Alias for `compareValues`.
   */
  public static function compare(valueA:Dynamic, valueB:Dynamic):Int
  {
    return compareValues(valueA, valueB);
  }

  /**
   * Compares `valueA` and `valueB`.
   *
   * @see https://api.haxe.org/Reflect.html#compare
   *
   * @param valueA The first value to compare.
   * @param valueB The second value to compare.
   */
  public static function compareValues(valueA:Dynamic, valueB:Dynamic):Int
  {
    return Reflect.compare(valueA, valueB);
  }

  /**
   * Compares `functionA` and `functionB`.
   *
   * @see https://api.haxe.org/Reflect.html#compareMethods
   *
   * @param functionA The first function to compare.
   * @param functionB The second function to compare.
   */
  public static function compareMethods(functionA:Dynamic, functionB:Dynamic):Bool
  {
    return Reflect.compareMethods(functionA, functionB);
  }
}
