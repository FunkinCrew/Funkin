package funkin.util;

import Type.ValueType;

class ReflectUtil
{
  public static function callMethod(obj:Dynamic, name:String, args:Array<Dynamic>):Dynamic
  {
    throw "Function Reflect.callMethod is blacklisted.";
  }

  public static function compare(valueA:Dynamic, valueB:Dynamic):Int
  {
    return compareValues(valueA, valueB);
  }

  public static function compareValues(valueA:Dynamic, valueB:Dynamic):Int
  {
    return Reflect.compare(valueA, valueB);
  }

  public static function compareMethods(functionA:Dynamic, functionB:Dynamic):Bool
  {
    return Reflect.compareMethods(functionA, functionB);
  }

  public static function copy(obj:Dynamic):Dynamic
  {
    return copyAnonymousFieldsOf(obj);
  }

  public static function copyAnonymousFieldsOf(obj:Dynamic):Dynamic
  {
    return Reflect.copy(obj);
  }

  public static function delete(obj:Dynamic, name:String):Bool
  {
    return delete(obj, name);
  }

  public static function deleteAnonymousField(obj:Dynamic, name:String):Bool
  {
    return Reflect.deleteField(obj, name);
  }

  public static function getField(obj:Dynamic, name:String):Dynamic
  {
    return getAnonymousField(obj, name);
  }

  public static function getAnonymousField(obj:Dynamic, name:String):Dynamic
  {
    return Reflect.field(obj, name);
  }

  public static function getFieldsOf(obj:Dynamic):Array<String>
  {
    return getAnonymousFieldsOf(obj);
  }

  public static function getAnonymousFieldsOf(obj:Dynamic):Array<String>
  {
    return Reflect.fields(obj);
  }

  public static function getProperty(obj:Dynamic, name:String):Dynamic
  {
    return Reflect.getProperty(obj, name);
  }

  public static function hasField(obj:Dynamic, name:String):Bool
  {
    return Reflect.hasField(obj, name);
  }

  public static function hasAnonymousField(obj:Dynamic, name:String):Bool
  {
    return Reflect.hasField(obj, name);
  }

  public static function isEnumValue(value:Dynamic):Bool
  {
    return Reflect.isEnumValue(value);
  }

  public static function isFunction(value:Dynamic):Bool
  {
    return Reflect.isFunction(value);
  }

  public static function isObject(value:Dynamic):Bool
  {
    return Reflect.isObject(value);
  }

  public static function setField(obj:Dynamic, name:String, value:Dynamic):Void
  {
    return setAnonymousField(obj, name, value);
  }

  public static function setAnonymousField(obj:Dynamic, name:String, value:Dynamic):Void
  {
    return Reflect.setField(obj, name, value);
  }

  public static function setProperty(obj:Dynamic, name:String, value:Dynamic):Void
  {
    return Reflect.setProperty(obj, name, value);
  }

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

  public static function getClassFields(cls:Class<Dynamic>):Array<String>
  {
    return Type.getClassFields(cls);
  }

  public static function getClassFieldsOf(obj:Dynamic):Array<String>
  {
    return Type.getClassFields(Type.getClass(obj));
  }

  public static function getInstanceFields(cls:Class<Dynamic>):Array<String>
  {
    return Type.getInstanceFields(cls);
  }

  public static function getInstanceFieldsOf(obj:Dynamic):Array<String>
  {
    return Type.getInstanceFields(Type.getClass(obj));
  }

  public static function getClassName(cls:Class<Dynamic>):String
  {
    return Type.getClassName(cls);
  }

  public static function getClassNameOf(obj:Dynamic):String
  {
    return Type.getClassName(Type.getClass(obj));
  }
}
