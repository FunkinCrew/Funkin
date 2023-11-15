package funkin.util.tools;

class DynamicTools
{
  /**
   * Creates a full clone of the input `Dynamic`. Only guaranteed to work on anonymous structures.
   * @param input The `Dynamic` to clone.
   * @return A clone of the input `Dynamic`.
   */
  public static function clone(input:Dynamic):Dynamic
  {
    return Reflect.copy(input);
  }
}
