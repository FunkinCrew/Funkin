package funkin.modding.scripting;

import nx.script.Interpreter;
import nx.script.Bytecode.Value;
import openfl.utils.Assets;

/**
 * Backend for NXScript (haxelib `nxscript` 0.5.8, MIT).
 *
 * Calls use `safeCall`, so a missing function returns null instead of throwing.
 * `has()` checks with `resolveCallable` first, so a function that is absent is never called.
 */
class NXScriptBackend implements IScriptBackend
{
  final interp:Interpreter;
  final disabled:Map<String, Bool> = new Map<String, Bool>();

  public function new()
  {
    interp = new Interpreter();
  }

  public function load(id:String):Void
  {
    trace('[NXSCRIPT] Running ${id}');
    // Reads through the mod-aware asset library, so mods can override scripts.
    interp.run(Assets.getText(id), id);
  }

  public function set(name:String, value:Dynamic):Void
  {
    interp.set(name, value);
  }

  public function has(name:String):Bool
  {
    if (disabled.exists(name)) return false;
    try
    {
      return interp.resolveCallable(name) != null;
    }
    catch (e:Dynamic)
    {
      return false;
    }
  }

  public function call(name:String, args:Array<Dynamic>):Dynamic
  {
    if (!has(name)) return null;
    try
    {
      var values:Array<Value> = [for (a in args) interp.vm.haxeToValue(a)];
      var result = interp.safeCall(name, values);
      return result == null ? null : interp.vm.valueToHaxe(result);
    }
    catch (e:Dynamic)
    {
      disabled.set(name, true);
      trace('[NXSCRIPT] Error in ${name}, disabled until restart: ${e}');
      return null;
    }
  }

  public function destroy():Void
  {
    // NXScript cleans up with its own garbage collector.
  }
}
