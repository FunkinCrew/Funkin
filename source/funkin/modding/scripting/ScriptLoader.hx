package funkin.modding.scripting;

import funkin.modding.module.ModuleHandler;
import openfl.utils.Assets;

/**
 * Finds script files in every active mod and registers each one as a module.
 *
 * Scripts go in `scripts/modules/`. The extension picks the language:
 *   `.nx`   -> NXScript
 *   `.pico` -> hscript-plus
 */
class ScriptLoader
{
  public static inline final FOLDER:String = 'scripts/modules/';

  public static function loadModules():Void
  {
    var count:Int = 0;

    for (id in Assets.list())
    {
      if (!StringTools.startsWith(id, FOLDER)) continue;

      var backend:Null<IScriptBackend> = backendFor(id);
      if (backend == null) continue;

      try
      {
        backend.load(id);
        ModuleHandler.registerModule(new ScriptModule(id, backend));
        count++;
      }
      catch (e:Dynamic)
      {
        trace('[SCRIPT] Failed to load ${id}: ${e}');
      }
    }

    trace('[SCRIPT] Loaded ${count} script module(s).');
  }

  static function backendFor(id:String):Null<IScriptBackend>
  {
    if (StringTools.endsWith(id, '.nx')) return new NXScriptBackend();
    if (StringTools.endsWith(id, '.pico')) return new HscriptPlusBackend();
    return null;
  }
}
