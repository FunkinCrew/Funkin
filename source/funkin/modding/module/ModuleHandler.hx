package funkin.modding.module;

import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;

/**
 * Utility functions for loading and manipulating active modules.
 */
class ModuleHandler
{
	static final moduleCache:Map<String, Module> = new Map<String, Module>();

	/**
	 * Whether modules start active by default.
	 */
	static final DEFAULT_STARTACTIVE:Bool = true;

	/**
	 * Parses and preloads the game's stage data and scripts when the game starts.
	 * 
	 * If you want to force stages to be reloaded, you can just call this function again.
	 */
	public static function loadModuleCache():Void
	{
		// Clear any stages that are cached if there were any.
		clearModuleCache();
		trace("[MODULEHANDLER] Loading module cache...");

		var scriptedModuleClassNames:Array<String> = ScriptedModule.listScriptClasses();
		trace('  Instantiating ${scriptedModuleClassNames.length} modules...');
		for (moduleCls in scriptedModuleClassNames)
		{
			var module:Module = ScriptedModule.init(moduleCls, moduleCls, DEFAULT_STARTACTIVE);
			if (module != null)
			{
				trace('    Loaded module: ${moduleCls}');

				// Then store it.
				moduleCache.set(module.moduleId, module);
			}
			else
			{
				trace('    Failed to instantiate module: ${moduleCls}');
			}
		}

		trace("[MODULEHANDLER] Module cache loaded.");
	}

	public static function clearModuleCache():Void
	{
		if (moduleCache != null)
		{
			// for (module in moduleCache)
			// {
			//	module.destroy();
			// }
			moduleCache.clear();
		}
	}

	public static function callEvent(event:ScriptEvent):Void
	{
		ScriptEventDispatcher.callEventOnAllTargets(moduleCache.iterator(), event);
	}
}
