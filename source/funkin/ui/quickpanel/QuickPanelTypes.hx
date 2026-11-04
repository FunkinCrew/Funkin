package funkin.ui.quickpanel;

import flixel.FlxSubState;

/**
 * Shared types for the quick panel.
 * TODO: Probably use UIStateMachine instead.
 */
enum PanelState
{
  CLOSED;
  OPENING;
  OPEN;
}

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
  public function new()
  {
    super();
  }
}
