package funkin.data;

import funkin.util.SerializerUtil;

/**
 * `json2object` has an annotation `@:jcustomwrite` which allows for custom serialization of values to be written to JSON.
 *
 * Functions must be of the signature `(T) -> String`, where `T` is the type of the property.
 */
class DataWrite
{
  public static function dynamicValue(value:Dynamic):String
  {
    // Is this cheating? Yes. Do I care? No.
    return SerializerUtil.toJSON(value);
  }
}
