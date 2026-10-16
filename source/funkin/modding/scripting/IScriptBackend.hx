package funkin.modding.scripting;

/**
 * Common interface for every scripting language the engine can run.
 */
interface IScriptBackend
{
  /** Loads and runs a script file. Top-level code runs here. */
  public function load(id:String):Void;

  /** Exposes a value to the script under the given name. */
  public function set(name:String, value:Dynamic):Void;

  /** Returns true if the script defines a function with that name. */
  public function has(name:String):Bool;

  /** Calls a function defined by the script. Returns null if it is missing. */
  public function call(name:String, args:Array<Dynamic>):Dynamic;

  /** Releases resources. */
  public function destroy():Void;
}
