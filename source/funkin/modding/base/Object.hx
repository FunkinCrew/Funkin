package funkin.modding.base;

/**
 * An empty base class meant to be extended by scripts.
 */
@:nullSafety
class Object
{
  public function new() {}

  public function toString():String
  {
    return "(Object)";
  }
}
