package funkin.data;

import funkin.util.SerializerUtil;
import thx.semver.Version;
import thx.semver.VersionRule;

/**
 * `json2object` has an annotation `@:jcustomwrite` which allows for custom serialization of values to be written to JSON.
 *
 * Functions must be of the signature `(T) -> String`, where `T` is the type of the property.
 */
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
   * `@:jcustomwrite(funkin.data.DataWrite.semverVersion)`
   */
  public static function semverVersion(value:Version):String
  {
    return value.toString();
  }

  /**
   * `@:jcustomwrite(funkin.data.DataWrite.semverVersionRule)`
   */
  public static function semverVersionRule(value:VersionRule):String
  {
    return value.toString();
  }
}
