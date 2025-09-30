package funkin.ui.debug.stageeditor.commands;

interface StageEditorCommand
{
  /**
   * Calling this function should perform the action that this command represents.
   * @param state The StageEditorState to perform the action on.
   */
  public function execute(state:StageEditorState):Void;

  /**
   * Calling this function should perform the inverse of the action that this command represents,
   * effectively undoing the action. Assume that the original action was the last action performed.
   * @param state The StageEditorState to undo the action on.
   */
  public function undo(state:StageEditorState):Void;

  /**
   * Return whether or not this command should be appended to the in the undo/redo history.
   * Generally this should be true, it should only be false if the command is minor and non-destructive,
   * like copying to the clipboard.
   *
   * Called after `execute()` is performed.
   */
  public function shouldAddToHistory(state:StageEditorState):Bool;

  /**
   * Get a short description of the action (for the UI).
   * For example, return `Add Left Note` to display `Undo Add Left Note` in the menu.
   */
  public function toString():String;
}
