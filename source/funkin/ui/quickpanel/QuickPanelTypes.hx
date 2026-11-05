package funkin.ui.quickpanel;

import flixel.FlxSubState;

/**
 * one button's data for the quick panel
 * TODO: Make this more flexible.
 */
typedef QuickPanelButtonData =
{
  var text:Null<String>;
  var callback:Null<Void->Void>;
  var icon:Null<String>;
  var disabled:Null<Bool>;
  var description:Null<String>;
}

/**
 * An empty substate opened on top of the host state while the panel is open,
 */
class PanelBlockerSubState extends MusicBeatSubState
{
  /**
   * Called once the blocker is actually open on top of the host.
   */
  public var onReady:Null<PanelBlockerSubState->Void> = null;

  /**
   * Set when the panel no longer wants this blocker (closed or destroyed mid-load).
   */
  public var cancelled:Bool = false;

  public function new()
  {
    super();
  }

  override public function create():Void
  {
    super.create();

    if (cancelled)
    {
      close();
      return;
    }

    if (onReady != null) onReady(this);
  }
}
