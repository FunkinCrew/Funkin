package funkin.util;

import funkin.util.tools.MapTools;
import haxe.DynamicAccess;

/**
 * Utilities for working with anonymous structures.
 */
class StructureUtil
{
  /**
   * Merge two structures, with the second overwriting the first.
   * Performs a SHALLOW clone, where child structures are not merged.
   * @param a The base structure.
   * @param b The new structure.
   * @return The merged structure.
   */
  public static function merge(a:Dynamic, b:Dynamic):Dynamic
  {
    var result:DynamicAccess<Dynamic> = Reflect.copy(a);

    for (field in Reflect.fields(b))
    {
      result.set(field, Reflect.field(b, field));
    }

    return result;
  }

  public static function toMap(a:Dynamic):haxe.ds.Map<String, Dynamic>
  {
    var result:haxe.ds.Map<String, Dynamic> = [];

    for (field in Reflect.fields(a))
    {
      result.set(field, Reflect.field(a, field));
    }

    return result;
  }

  public static function isMap(a:Dynamic):Bool
  {
    return Std.isOfType(a, haxe.Constraints.IMap);
  }

  public static function isObject(a:Dynamic):Bool
  {
    switch (Type.typeof(a))
    {
      case TObject:
        return true;
      default:
        return false;
    }
  }

  public static function isPrimitive(a:Dynamic):Bool
  {
    switch (Type.typeof(a))
    {
      case TInt | TFloat | TBool:
        return true;
      case TClass(c):
        return false;
      case TEnum(e):
        return false;
      case TObject:
        return false;
      case TFunction:
        return false;
      case TNull:
        return true;
      case TUnknown:
        return false;
      default:
        return false;
    }
  }

  /**
   * Merge two structures, with the second overwriting the first.
   * Performs a DEEP clone, where child structures are also merged recursively.
   * @param a The base structure.
   * @param b The new structure.
   * @return The merged structure.
   */
  public static function deepMerge(a:Dynamic, b:Dynamic):Dynamic
  {
    if (a == null) return b;
    if (b == null) return null;
    if (isPrimitive(a) && isPrimitive(b)) return b;
    if (isMap(b))
    {
      if (isMap(a))
      {
        return MapTools.merge(a, b);
      }
      else
      {
        return StructureUtil.toMap(a).merge(b);
      }
    }
    if (!Reflect.isObject(a) || !Reflect.isObject(b)) return b;
    if (Std.isOfType(b, haxe.ds.StringMap))
    {
      if (Std.isOfType(a, haxe.ds.StringMap))
      {
        return MapTools.merge(a, b);
      }
      else
      {
        return StructureUtil.toMap(a).merge(b);
      }
    }

    var result:DynamicAccess<Dynamic> = Reflect.copy(a);

    for (field in Reflect.fields(b))
    {
      if (Reflect.isObject(b))
      {
        // Note that isObject also returns true for class instances,
        // but we just assume that's not a problem here.
        result.set(field, deepMerge(Reflect.field(result, field), Reflect.field(b, field)));
      }
      else
      {
        // If we're here, b[field] is a primitive.
        result.set(field, Reflect.field(b, field));
      }
    }

    return result;
  }
}
