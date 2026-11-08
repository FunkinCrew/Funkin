package funkin.ui.quickpanel;

import funkin.data.quickpanel.PanelData.PanelButtonAnim;

/**
 * The data behind one quick panel button.
 */
typedef QuickPanelButtonData =
{
  var ?id:String;

  /**
   * Label shown next to the icon.
   */
  var text:Null<String>;

  /**
   * Runs once the accept transition finishes.
   */
  var callback:Null<Void->Void>;

  /**
   * Icon name.
   */
  var icon:Null<String>;

  /**
   * Whether it is disabled.
   */
  var disabled:Null<Bool>;

  /**
   * Button Description.
   */
  var description:Null<String>;

  /**
   *
   */
  var transitioning:Null<Bool>;

  /**
   * Button anim params
   */
  var ?buttonAnim:PanelButtonAnim;
}

/**
 * An empty substate opened on top of the host state while the panel is open,
 * so the host stops updating (and reading input) underneath it.
 * Also responsible for for trriggering the assets query for the side panel.
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

  /**
   * Makes new PanelBlockerSubState
   */
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
