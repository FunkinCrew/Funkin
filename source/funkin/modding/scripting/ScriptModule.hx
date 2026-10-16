package funkin.modding.scripting;

import funkin.modding.events.ScriptEvent;
import funkin.modding.module.Module;

/**
 * A Module whose behaviour lives in a script file (.nx or .pico).
 *
 * Every engine event is forwarded to the script's `onScriptEvent(event)` function.
 * Scripts check `event.type` to decide what to do.
 */
class ScriptModule extends Module
{
  final backend:IScriptBackend;

  public function new(moduleId:String, backend:IScriptBackend)
  {
    super(moduleId);
    this.backend = backend;
  }

  override public function onScriptEvent(event:ScriptEvent):Void
  {
    backend.call('onScriptEvent', [event]);
  }

  override public function onDestroy(event:ScriptEvent):Void
  {
    backend.destroy();
  }
}
