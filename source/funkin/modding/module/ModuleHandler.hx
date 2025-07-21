package funkin.modding.module;

import funkin.util.SortUtil;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.module.Module;
import funkin.modding.module.ScriptedModule;

/**
 * Utility functions for loading and manipulating active modules.
 */
@:nullSafety
class ModuleHandler
{
  static final moduleCache:Map<String, Module> = new Map<String, Module>();
  static var modulePriorityOrder:Array<String> = [];

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
      var module:Module = ScriptedModule.init(moduleCls, moduleCls);
      if (module != null)
      {
        trace('    Loaded module: ${moduleCls}');

        // Then store it.
        addToModuleCache(module);
      }
      else
      {
        trace('    Failed to instantiate module: ${moduleCls}');
      }
    }
    reorderModuleCache();

    trace("[MODULEHANDLER] Module cache loaded.");
  }

  public static function buildModuleCallbacks():Void
  {
    FlxG.signals.postStateSwitch.add(onStateSwitchComplete);
  }

  static function onStateSwitchComplete():Void
  {
    callEvent(new StateChangeScriptEvent(STATE_CHANGE_END, FlxG.state, true));
  }

  static function addToModuleCache(module:Module):Void
  {
    moduleCache.set(module.moduleId, module);
  }

  static function reorderModuleCache():Void
  {
    modulePriorityOrder = moduleCache.keys().array();

    modulePriorityOrder.sort(sortByPriority);
  }

  /**
   * Given two module IDs, sort them by priority.
   * @return 1 or -1 depending on which module has a higher priority.
   */
  static function sortByPriority(a:String, b:String):Int
  {
    var aModule:Null<Module> = getModule(a);
    var bModule:Null<Module> = getModule(b);

    if (aModule == null || bModule == null)
    {
      return 0;
    }
    if (aModule.priority != bModule.priority)
    {
      return aModule.priority - bModule.priority;
    }
    else
    {
      return SortUtil.alphabetically(a, b);
    }
  }

  public static function getModule(moduleId:String):Null<Module>
  {
    return moduleCache.get(moduleId);
  }

  public static function activateModule(moduleId:String):Void
  {
    var module:Null<Module> = getModule(moduleId);
    if (module != null)
    {
      module.active = true;
    }
  }

  public static function deactivateModule(moduleId:String):Void
  {
    var module:Null<Module> = getModule(moduleId);
    if (module != null)
    {
      module.active = false;
    }
  }

  /**
   * Clear the module cache, forcing all modules to call shutdown events.
   */
  public static function clearModuleCache():Void
  {
    if (moduleCache != null)
    {
      var event = new ScriptEvent(DESTROY, false);

      // Note: Ignore stopPropagation()
      for (key => value in moduleCache)
      {
        ScriptEventDispatcher.callEvent(value, event);
      }

      moduleCache.clear();
      modulePriorityOrder = [];
    }
  }

  public static function callEvent(event:ScriptEvent):Void
  {
    for (moduleId in modulePriorityOrder)
    {
      var module:Null<Module> = moduleCache.get(moduleId);
      // The module needs to be active to receive events.
      if (module != null && module.active)
      {
        ScriptEventDispatcher.callEvent(module, event);
      }
    }
  }

  public static inline function callOnCreate():Void
  {
    callEvent(new ScriptEvent(CREATE, false));
  }
}
