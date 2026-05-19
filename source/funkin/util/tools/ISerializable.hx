package funkin.util.tools;

/**
 * Implement this on a class to specify a custom function for serializing its objects into JSON.
 * NOTE: Objects that don't implement this can still be serialized!
 * This just provides a custom implementation that's usually faster or reduces incompatibility.
 */
@:nullSafety
interface ISerializable
{
  /**
   * Serialize this object into a JSON string.
   *
   * @param pretty Whether to use pretty formatting on the output.
   * @return This object, converted into a JSON string.
   */
  public function serialize(pretty:Bool = true):String;
}
