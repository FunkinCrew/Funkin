package funkin.data;

import funkin.util.SerializerUtil;
import thx.semver.Version;
import thx.semver.VersionRule;
import haxe.ds.Either;

/**
 * `json2object` has an annotation `@:jcustomwrite` which allows for custom serialization of values to be written to JSON.
 *
 * Functions must be of the signature `(T) -> String`, where `T` is the type of the property.
 *
 * NOTE: Result must include quotation marks if the value is a string! json2object will not add them for you!
 */
@:nullSafety
class DataWrite
{
  /**
   * `@:jcustomwrite(funkin.data.DataWrite.dynamicValue)`
   * @param value
   * @return String
   */
  public static function dynamicValue(value:Dynamic):String
  {
    // Is this cheating? Yes. Do I care? No.
    return SerializerUtil.toJSON(value);
  }

  /**
   *
   * `@:jcustomwrite(funkin.data.DataWrite.semverVersion)`
   */
  public static function semverVersion(value:Version):String
  {
    return '"${value.toString()}"';
  }

  /**
   * `@:jcustomwrite(funkin.data.DataWrite.semverVersionRule)`
   */
  public static function semverVersionRule(value:VersionRule):String
  {
    return '"${value.toString()}"';
  }

  /**
   * `@:jcustomwrite(funkin.data.DataWrite.eitherFloatOrFloats)`
   */
  public static function eitherFloatOrFloats(value:Null<Either<Float, Array<Float>>>):String
  {
    switch (value)
    {
      case null:
        return '${1.0}';
      case Left(inner):
        return '$inner';
      case Right(inner):
        return dynamicValue(inner);
    }
  }
}
