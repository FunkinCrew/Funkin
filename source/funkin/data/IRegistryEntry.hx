package funkin.data;

/**
 * An interface defining the necessary functions for a registry entry.
 * A `String->Void` constructor is also mandatory, but enforced elsewhere.
 * @param T The JSON data type of the registry entry.
 */
@:autoBuild(funkin.util.macro.RegistryMacro.buildEntry())
interface IRegistryEntry<T>
{
  public final id:String;

  // public function new(id:String):Void;
  public function destroy():Void;
  public function toString():String;

  // Can't make an interface field private I guess.
  public final _data:T;
  // Can't make a static field required by an interface I guess.
  // private static function _fetchData(id:String):Null<T>;
}
