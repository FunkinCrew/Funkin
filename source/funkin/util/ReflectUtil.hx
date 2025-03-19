package funkin.util;

import Type;

class ReflectUtil
{
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

  public static function getAnonymousFieldsOf(obj:Dynamic):Array<String>
  {
    return Reflect.fields(obj);
  }

  public static function getAnonymousField(obj:Dynamic, name:String):Dynamic
  {
    return Reflect.field(obj, name);
  }

  public static function setAnonymousField(obj:Dynamic, name:String, value:Dynamic):Void
  {
    return Reflect.setField(obj, name, value);
  }

  public static function hasAnonymousField(obj:Dynamic, name:String):Bool
  {
    return Reflect.hasField(obj, name);
  }

  public static function copyAnonymousFieldsOf(obj:Dynamic):Dynamic
  {
    return Reflect.copy(obj);
  }

  public static function deleteAnonymousField(obj:Dynamic, name:String):Bool
  {
    return Reflect.deleteField(obj, name);
  }

  public static function compareValues(valueA:Dynamic, valueB:Dynamic):Int
  {
    return Reflect.compare(valueA, valueB);
  }

  public static function isObject(value:Dynamic):Bool
  {
    return Reflect.isObject(value);
  }

  public static function isFunction(value:Dynamic):Bool
  {
    return Reflect.isFunction(value);
  }

  public static function isEnumValue(value:Dynamic):Bool
  {
    return Reflect.isEnumValue(value);
  }

  public static function getProperty(obj:Dynamic, name:String):Dynamic
  {
    return Reflect.getProperty(obj, name);
  }

  public static function setProperty(obj:Dynamic, name:String, value:Dynamic):Void
  {
    return Reflect.setProperty(obj, name, value);
  }

  public static function compareMethods(functionA:Dynamic, functionB:Dynamic):Bool
  {
    return Reflect.compareMethods(functionA, functionB);
  }
}
