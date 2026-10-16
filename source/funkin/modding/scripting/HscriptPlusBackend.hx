package funkin.modding.scripting;

import hscriptplus.plus.ScriptState;
import openfl.utils.Assets;

/**
 * Backend for `.pico` scripts, powered by the vendored hscript-plus.
 *
 * - Errors include the file, line and column (`scripts/modules/x.pico:3: ...`).
 * - A function that throws is logged once and disabled until restart.
 */
class HscriptPlusBackend implements IScriptBackend
{
  final state:ScriptState;
  final disabled:Map<String, Bool> = new Map<String, Bool>();

  public function new()
  {
    state = new ScriptState();
    // Reads script files from the mod-aware asset library, so mods can override them.
    state.getFileContent = Assets.getText;
    // Errors are traced instead of thrown so one broken script does not stop the game.
    state.rethrowError = false;
  }

  public function load(id:String):Void
  {
    trace('[PICOSCRIPT] Running ${id} (hscript-plus)');
    // executeFile keeps the path, so parse errors point at the right file.
    state.executeFile(id);
  }

  public function set(name:String, value:Dynamic):Void
  {
    state.set(name, value);
  }

  public function has(name:String):Bool
  {
    if (disabled.exists(name)) return false;
    var value:Dynamic = state.get(name);
    return value != null && Reflect.isFunction(value);
  }

  public function call(name:String, args:Array<Dynamic>):Dynamic
  {
    if (!has(name)) return null;
    var fn:Dynamic = state.get(name);
    try
    {
      return Reflect.callMethod(null, fn, args);
    }
    catch (e:Dynamic)
    {
      disabled.set(name, true);
      trace('[PICOSCRIPT] Error in ${name}, disabled until restart: ${e}');
      return null;
    }
  }

  public function destroy():Void
  {
    // hscript-plus keeps no native resources.
  }
}
