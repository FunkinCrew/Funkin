package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxContainer.FlxTypedContainer;
import funkin.save.Save;
import funkin.ui.quickpanel.QuickPanelState;

/**
 * Global plugin that hosts the quick panel on top of scripted (modded) states,
 * the panel itself is cycled.
 *
 * Set `showGrabber` to force the panel on or off for the current state.
 */
class SidePanelPlugin extends FlxTypedContainer<FlxBasic>
{
  /**
   * Seconds after the panel first appears before the first-run hint is shown.
   */
  static final FIRST_RUN_HINT_DELAY:Float = 3.0;

  /**
   * Side panel plugin instance
   */
  public static var instance(get, never):Null<SidePanelPlugin>;

  static var _instance:Null<SidePanelPlugin> = null;

  /**
   * Whether the panel should exist for the current state.
   */
  public static var showGrabber(default, set):Bool = false;

  /**
   * The live panel, if any.
   */
  public var panelState(default, null):Null<QuickPanelState> = null;

  var firstRunHintPending:Bool;
  var firstRunHintTimer:Float = 0;

  /**
   * Registers the plugin. Safe to call more than once.
   */
  public static function initialize():Void
  {
    if (_instance != null) return;
    FlxG.plugins.addPlugin(new SidePanelPlugin());
  }

  function new()
  {
    super();
    _instance = this;

    firstRunHintPending = !Save.instance.quickMenuFirstRun.value;

    FlxG.signals.preStateSwitch.add(onPreStateSwitch);
    FlxG.signals.postStateSwitch.add(onPostStateSwitch);

    syncPanel();
  }

  static function isScriptedState():Bool
  {
    return FlxG.state != null && polymod.Polymod.isScriptedClass(FlxG.state);
  }

  function syncPanel():Void
  {
    if (showGrabber && FlxG.state != null) createPanel();
    else
      destroyPanel();
  }

  function createPanel():Void
  {
    if (panelState != null) return;

    panelState = new QuickPanelState();
    add(panelState);
  }

  function destroyPanel():Void
  {
    if (panelState == null) return;

    remove(panelState, true);
    panelState.destroy();
    panelState = null;
  }

  function onPreStateSwitch():Void
  {
    destroyPanel();
  }

  function onPostStateSwitch():Void
  {
    showGrabber = isScriptedState();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    updateFirstRunHint(elapsed);
  }

  /**
   * On the very first run, show the hint shortly after the panel appears instead of waiting for inactivity.
   * @param elapsed Elapsed.
   */
  function updateFirstRunHint(elapsed:Float):Void
  {
    if (!firstRunHintPending || panelState == null) return;

    firstRunHintTimer += elapsed;
    if (firstRunHintTimer < FIRST_RUN_HINT_DELAY || panelState.isOpen) return;

    firstRunHintPending = false;
    firstRunHintTimer = 0;

    Save.instance.quickMenuFirstRun.value = true;
    Save.instance.flush();

    panelState.showHint();
  }

  override public function destroy():Void
  {
    FlxG.signals.preStateSwitch.remove(onPreStateSwitch);
    FlxG.signals.postStateSwitch.remove(onPostStateSwitch);

    destroyPanel();

    if (_instance == this) _instance = null;
    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    super.destroy();
  }

  /// Helpers

  static function get_instance():Null<SidePanelPlugin> return _instance;

  static function set_showGrabber(value:Bool):Bool
  {
    showGrabber = value;
    if (_instance != null) _instance.syncPanel();
    return value;
  }
}
