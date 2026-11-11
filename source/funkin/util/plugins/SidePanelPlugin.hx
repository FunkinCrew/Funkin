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

  /**
   * Side panel plugin instance, but private!
   */
  static var _instance:Null<SidePanelPlugin> = null;

  /**
   * Whether the panel should exist for the current state.
   */
  public static var showGrabber(get, set):Bool;

  public static var requestedPanelId(default, null):Null<String> = null;
  static var requestedPullTab:Bool = true;

  /**
   * The live panel, if any.
   */
  public var panelState(default, null):Null<QuickPanelState> = null;

  /**
   * True until the first-run hint has been shown.
   */
  var firstRunHintPending:Bool;

  /**
   * Helper variable for the first-run hint.
   */
  var firstRunHintTimer:Float = 0;

  var switchingState:Bool = false;

  /**
   * Registers the plugin. Safe to call more than once.
   */
  public static function initialize():Void
  {
    if (_instance != null) return;
    FlxG.plugins.addPlugin(new SidePanelPlugin());
  }

  public static function requestPanel(panelId:Null<String>, showPullTab:Bool = true):Void
  {
    requestedPanelId = panelId;
    requestedPullTab = showPullTab;

    if (_instance != null && !_instance.switchingState) _instance.syncPanel();
  }

  /**
   * Creates Side panel plugin
   */
  function new()
  {
    super();
    _instance = this;

    firstRunHintPending = !Save.instance.quickMenuFirstRun.value;

    FlxG.signals.preStateSwitch.add(onPreStateSwitch);
    FlxG.signals.postStateSwitch.add(onPostStateSwitch);

    syncPanel();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    updateFirstRunHint(elapsed);
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

  /**
   * Syncs the panel with showGrabber, creating / destroying it.
   */
  function syncPanel():Void
  {
    if (requestedPanelId == null || FlxG.state == null)
    {
      destroyPanel();
      return;
    }

    if (panelState != null && (panelState.panelId != requestedPanelId || panelState.pullTabEnabled != requestedPullTab)) destroyPanel();

    createPanel();
  }

  /**
   * Creates the panel
   */
  function createPanel():Void
  {
    if (panelState != null || requestedPanelId == null) return;

    panelState = new QuickPanelState(requestedPanelId, requestedPullTab);
    add(panelState);
  }

  /**
   * Destroys the panel
   */
  function destroyPanel():Void
  {
    if (panelState == null) return;

    remove(panelState, true);
    panelState.destroy();
    panelState = null;
  }

  /**
   * Called before a state switch
   */
  function onPreStateSwitch():Void
  {
    switchingState = true;
    destroyPanel();
    requestedPanelId = null;
    requestedPullTab = true;
  }

  /**
   * Called after a state switch
   */
  function onPostStateSwitch():Void
  {
    switchingState = false;
    if (requestedPanelId == null && isScriptedState()) requestedPanelId = QuickPanelState.DEFAULT_PANEL_ID;
    syncPanel();
  }

  /**
   * On the very first run, show the hint shortly after the panel appears instead of waiting for inactivity.
   * @param elapsed Elapsed.
   */
  function updateFirstRunHint(elapsed:Float):Void
  {
    if (!firstRunHintPending || panelState == null || !panelState.pullTabEnabled) return;

    firstRunHintTimer += elapsed;
    if (firstRunHintTimer < FIRST_RUN_HINT_DELAY || panelState.isOpen) return;

    firstRunHintPending = false;
    firstRunHintTimer = 0;

    Save.instance.quickMenuFirstRun.value = true;
    Save.instance.flush();

    panelState.showHint();
  }

  /**
   * Checks if the state is scripted.
   * @return Whether the state is scripted.
   */
  static function isScriptedState():Bool
  {
    return FlxG.state != null && polymod.Polymod.isScriptedClass(FlxG.state);
  }

  /// Helpers

  static function get_instance():Null<SidePanelPlugin> return _instance;

  static function get_showGrabber():Bool return requestedPanelId != null;

  static function set_showGrabber(value:Bool):Bool
  {
    requestPanel(value ? QuickPanelState.DEFAULT_PANEL_ID : null);
    return value;
  }
}
