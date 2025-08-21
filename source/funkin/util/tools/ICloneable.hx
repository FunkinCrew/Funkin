package funkin.util.tools;

/**
 * Implement this on a class to enable `Array<T>.deepClone()` to work on it.
 * NOTE: T should be the type of the class that implements this interface.
 */
@:nullSafety
interface ICloneable<T>
{
  public function clone():T;
}
