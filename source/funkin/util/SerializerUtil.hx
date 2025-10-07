package funkin.util;

import haxe.Json;
import haxe.io.Bytes;

typedef ScoreInput =
{
  var d:Int; // Key pressed
  var l:Int; // Duration
  var t:Int; // Start timestamp
}

/**
 * Functions dedicated to serializing and deserializing data.
 * NOTE: Use `json2object` wherever possible, it's way more efficient.
 */
@:nullSafety
class SerializerUtil
{
  static final INDENT_CHAR = "\t";

  /**
   * Convert a Haxe object to a JSON string.
   * NOTE: Use `json2object.JsonWriter<T>` WHEREVER POSSIBLE. Do not use this one unless you ABSOLUTELY HAVE TO it's SLOW!
   * And don't even THINK about using `haxe.Json.stringify` without the replacer!
   */
  public static function toJSON(input:Dynamic, pretty:Bool = true):String
  {
    return Json.stringify(input, replacer, pretty ? INDENT_CHAR : null);
  }

  /**
   * Convert a JSON string to a Haxe object.
   */
  public static function fromJSON(input:String):Dynamic
  {
    input = sanitizeJSON(input);

    try
    {
      return Json.parse(input);
    }
    catch (e)
    {
      trace('An error occurred while parsing JSON from string data');
      trace(e);
      return null;
    }
  }

  /**
   * Convert a JSON byte array to a Haxe object.
   */
  public static function fromJSONBytes(input:Bytes):Null<Dynamic>
  {
    try
    {
      return Json.parse(input.toString());
    }
    catch (e:Dynamic)
    {
      trace('An error occurred while parsing JSON from byte data');
      trace(e);
      return null;
    }
  }

  /**
   * Customize how certain types are serialized when converting to JSON.
   */
  static function replacer(key:String, value:Dynamic):Dynamic
  {
    // Hacky because you can't use `isOfType` on a struct.
    if (key == "version")
    {
      if (value is String) return value;

      // Stringify Version objects.
      return serializeVersion(cast value);
    }

    // Else, return the value as-is.
    return value;
  }

  static inline function serializeVersion(value:thx.semver.Version):String
  {
    var result = '${value.major}.${value.minor}.${value.patch}';
    if (value.hasPre) result += '-${value.pre}';
    // TODO: Merge fix for version.hasBuild
    if (value.build.length > 0) result += '+${value.build}';
    return result;
  }

  /**
   * Trims garbage data that may accompany JSON strings converted from bytes.
   */
  static function sanitizeJSON(data:String):String
  {
    var startIndex:Int = -1;
    var closeChar:String = '';
    for (i => c in data)
    {
      if (c == '{'.code || c == '['.code)
      {
        startIndex = i;
        closeChar = (c == '{'.code) ? '}' : ']';
        break;
      }
    }
    if (startIndex == -1) return data;

    var endIndex = data.lastIndexOf(closeChar);
    if (endIndex == -1) endIndex = data.length - 1;

    return data.substring(startIndex, endIndex + 1);
  }
}
