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

  public static function hasAnonymousField(obj:Dynamic, name:String):Bool
  {
    return Reflect.hasField(obj, name);
  }
}
