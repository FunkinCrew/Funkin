package funkin.util.tools;

import haxe.DynamicAccess;

class DynamicAccessTools
{
  /**
   * Creates a full clone of the input `DynamicAccess`.
   * @param input The `Dynamic` to clone.
   * @return A clone of the input `Dynamic`.
   */
  public static function clone(input:DynamicAccess<T>):DynamicAccess<T>
  {
    return Reflect.copy(input);
  }
}
