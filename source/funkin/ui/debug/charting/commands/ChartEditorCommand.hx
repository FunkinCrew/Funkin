package funkin.ui.debug.charting.commands;

/**
 * Actions in the chart editor are backed by the Command pattern
 * (see Bob Nystrom's book "Game Programming Patterns" for more info)
 *
 * To make a functionality compatible with the undo/redo history, create a new class
 * that implements ChartEditorCommand, then call `ChartEditorState.performCommand(new Command())`
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
   * Get a short description of the action (for the UI).
   * For example, return `Add Left Note` to display `Undo Add Left Note` in the menu.
   */
  public function toString():String;
}
