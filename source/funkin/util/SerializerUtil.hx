package funkin.util;

import haxe.Json;
import thx.semver.Version;

class SerializerUtil
{
  static final INDENT_CHAR = "\t";

  /**
   * Convert a Haxe object to a JSON string.
  **/
  public static function toJSON(input:Dynamic, ?pretty:Bool = true):String
  {
    return Json.stringify(input, replacer, pretty ? INDENT_CHAR : null);
  }

  /**
   * Convert a JSON string to a Haxe object of the chosen type.		
   */
  public static function fromJSONTyped<T>(input:String, type:Class<T>):T
  {
    return cast Json.parse(input);
  }

  /**
   * Convert a JSON string to a Haxe object.
   */
  public static function fromJSON(input:String):Dynamic
  {
    return Json.parse(input);
  }

  /**
   * Customize how certain types are serialized when converting to JSON.
   */
  static function replacer(key:String, value:Dynamic):Dynamic
  {
    // Hacky because you can't use `isOfType` on a struct.
    if (key == "version")
    {
      if (Std.isOfType(value, String)) return value;

      // Stringify Version objects.
      var valueVersion:thx.semver.Version = cast value;
      var result = '${valueVersion.major}.${valueVersion.minor}.${valueVersion.patch}';
      if (valueVersion.hasPre) result += '-${valueVersion.pre}';
      if (valueVersion.hasBuild) result += '+${valueVersion.build}';
      return result;
    }

    // Else, return the value as-is.
    return value;
  }
}
