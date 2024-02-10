package funkin.ui.debug.charting.commands;

/**
 * Actions in the chart editor are backed by the Command pattern
 * (see Bob Nystrom's book "Game Programming Patterns" for more info)
 *
 * To make a functionality compatible with the undo/redo history, create a new class
 * that implements ChartEditorCommand, then call `ChartEditorState.performCommand(new Command())`
 *
 * NOTE: Make the constructor very simple, as it may be called without executing by the command palette.
 */
interface ChartEditorCommand
{
  /**
   * Calling this function should perform the action that this command represents.
   * @param state The ChartEditorState to perform the action on.
   */
  public function execute(state:ChartEditorState):Void;

  /**
   * Calling this function should perform the inverse of the action that this command represents,
   * effectively undoing the action. Assume that the original action was the last action performed.
   * @param state The ChartEditorState to undo the action on.
   */
  public function undo(state:ChartEditorState):Void;

  /**
   * Return whether or not this command should be appended to the in the undo/redo history.
   * Generally this should be true, it should only be false if the command is minor and non-destructive,
   * like copying to the clipboard.
   *
   * Called after `execute()` is performed.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool;

  /**
   * Get a short description of the action (for the UI).
   * For example, return `Add Left Note` to display `Undo Add Left Note` in the menu.
   */
  public function toString():String;
}
