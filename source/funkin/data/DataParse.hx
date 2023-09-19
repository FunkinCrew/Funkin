package funkin.data;

import hxjsonast.Json;
import hxjsonast.Json.JObjectField;

/**
 * `json2object` has an annotation `@:jcustomparse` which allows for mutation of parsed values.
 *
 * It also allows for validation, since throwing an error in this function will cause the issue to be properly caught.
 * Parsing will fail and `parser.errors` will contain the thrown exception.
 *
 * Functions must be of the signature `(hxjsonast.Json, String) -> T`, where the String is the property name and `T` is the type of the property.
 */
class DataParse
{
  /**
   * `@:jcustomparse(funkin.data.DataParse.stringNotEmpty)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @throws If the property is not a string or is empty.
   */
  public static function stringNotEmpty(json:Json, name:String):String
  {
    switch (json.value)
    {
      case JString(s):
        if (s == "") throw 'Expected property $name to be non-empty.';
        return s;
      default:
        throw 'Expected property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a Dynamic value, either a object or something else.
   * @param json
   * @param name
   * @return The value of the property.
   */
  public static function dynamicValue(json:Json, name:String):Dynamic
  {
    return jsonToDynamic(json);
  }

  /**
   * Parser which outputs a Dynamic value, which must be an object with properties.
   * @param json
   * @param name
   * @return Dynamic
   */
  public static function dynamicObject(json:Json, name:String):Dynamic
  {
    switch (json.value)
    {
      case JObject(fields):
        return jsonFieldsToDynamicObject(fields);
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  static function jsonToDynamic(json:Json):Null<Dynamic>
  {
    return switch (json.value)
    {
      case JString(s): s;
      case JNumber(n): Std.parseInt(n);
      case JBool(b): b;
      case JNull: null;
      case JObject(fields): jsonFieldsToDynamicObject(fields);
      case JArray(values): jsonArrayToDynamicArray(values);
    }
  }

  /**
   * Array of JSON fields `[{key, value}, {key, value}]` to a Dynamic object `{key:value, key:value}`.
   * @param fields
   * @return Dynamic
   */
  static function jsonFieldsToDynamicObject(fields:Array<JObjectField>):Dynamic
  {
    var result:Dynamic = {};
    for (field in fields)
    {
      Reflect.setField(result, field.name, jsonToDynamic(field.value));
    }
    return result;
  }

  /**
   * Array of JSON elements `[Json, Json, Json]` to a Dynamic array `[String, Object, Int, Array]`
   * @param jsons
   * @return Array<Dynamic>
   */
  static function jsonArrayToDynamicArray(jsons:Array<Json>):Array<Null<Dynamic>>
  {
    return [for (json in jsons) jsonToDynamic(json)];
  }
}
