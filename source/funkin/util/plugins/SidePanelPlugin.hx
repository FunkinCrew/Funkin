package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.FlxG;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import funkin.ui.quickpanel.QuickPanelState;
import funkin.ui.quickpanel.QuickPanelGroup;
import funkin.save.Save;

class SidePanelPlugin extends flixel.group.FlxContainer.FlxTypedContainer<FlxBasic>
{
  public static var instance(get, never):SidePanelPlugin;
  public static var showGrabber(default, set):Bool = false;
  static var shouldShowHint:Bool = false;

  static function set_showGrabber(value:Bool):Bool
  {
    showGrabber = value;
    if (_instance == null) return value;
    if (value) _instance.addPanel();
    else
      _instance.removePanel();
    return value;
  }

  static var _instance:Null<SidePanelPlugin> = null;

  static function get_instance():SidePanelPlugin
  {
    if (_instance == null) _instance = new SidePanelPlugin();
    return _instance;
  }

  var panelState:Null<QuickPanelState> = null;

  public function new()
  {
    super();
    _instance = this;

    shouldShowHint = !Save.instance.quickMenuFirstRun.value;

    FlxG.signals.postStateSwitch.add(onPostStateSwitch);
  }

  public static function initialize():Void
  {
    FlxG.plugins.drawOnTop = true;
    FlxG.plugins.addPlugin(new SidePanelPlugin());
  }

  static function isScriptedState():Bool
  {
    return polymod.Polymod.isScriptedClass(FlxG.state);
  }

  function addPanel():Void
  {
    if (panelState != null) return;
    FlxG.state.persistentDraw = true;
    panelState = new QuickPanelState();
    add(panelState);
    panelState.create();
  }

  function removePanel():Void
  {
    if (panelState == null) return;
    remove(panelState, true);
    panelState.destroy();
    panelState = null;
  }

  function onPostStateSwitch():Void
  {
    if (panelState != null)
    {
      remove(panelState, true);
      panelState.destroy();
      panelState = null;
    }

    showGrabber = isScriptedState();
  }

  var hintTimer:Float = 0;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (shouldShowHint && panelState != null && panelState.panel != null)
    {
      hintTimer += elapsed;
      if (hintTimer > 3 && panelState.panel.curState != PanelState.OPEN)
      {
        hintTimer = 0;
        Save.instance.quickMenuFirstRun.value = true;
        Save.instance.flush();
        shouldShowHint = false;
        panelState.panel.inactivityTimer = -1;
      }
    }
  }

  override public function destroy():Void
  {
    if (instance == this) _instance = null;
    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);
    FlxG.signals.postStateSwitch.remove(onPostStateSwitch);
    super.destroy();
  }
}
