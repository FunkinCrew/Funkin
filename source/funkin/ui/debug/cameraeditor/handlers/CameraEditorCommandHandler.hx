package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.debug.cameraeditor.commands.CameraEditorCommand;

/**
 * Handles commands in the camera editor. These are operations which enter the undo/redo history,
 * and can be executed or undone via the Edit menu.
 *
 * The `using` statement in `import.hx` allows you to call these functions on the CameraEditorState instance directly.
 */
@:nullSafety
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class CameraEditorCommandHandler
{
  /**
   * Perform (or redo) a command, then add it to the undo stack.
   *
   * @param state The CameraEditorState to perform the action on.
   * @param command The command to perform.
   * @param purgeRedoStack If `true`, the redo stack will be cleared after performing the command.
   */
  public static function performCommand(state:CameraEditorState, command:CameraEditorCommand, purgeRedoStack:Bool = true):Void
  {
    trace(' CAMERA EDITOR '.bold().bg_bright_yellow() + 'Performing command: ' + command.toString());
    command.execute(state);
    if (command.shouldAddToHistory(state))
    {
      state.undoHistory.push(command);
      state.commandHistoryDirty = true;
    }
    if (purgeRedoStack) state.redoHistory = [];
  }

  /**
   * Undo a command, then add it to the redo stack.
   *
   * @param state The CameraEditorState to undo the action on.
   * @param command The command to undo.
   */
  public static function undoCommand(state:CameraEditorState, command:CameraEditorCommand):Void
  {
    trace(' CAMERA EDITOR '.bold().bg_bright_yellow() + 'Undoing command: ' + command.toString());
    command.undo(state);
    // Note, if we are undoing a command, it should already be in the history,
    // therefore we don't need to check `shouldAddToHistory(state)`
    state.redoHistory.push(command);
    state.commandHistoryDirty = true;
  }

  /**
   * Undo the last command in the undo stack, then add it to the redo stack.
   *
   * @param state The CameraEditorState to undo the action on.
   */
  public static function undoLastCommand(state:CameraEditorState):Void
  {
    var command:Null<CameraEditorCommand> = state.undoHistory.pop();
    if (command == null)
    {
      trace(' CAMERA EDITOR '.bold().bg_bright_yellow() + 'No actions to undo.');
      return;
    }
    state.undoCommand(command);
  }

  /**
   * Redo the last command in the redo stack, then add it to the undo stack.
   *
   * @param state The CameraEditorState to undo the action on.
   */
  public static function redoLastCommand(state:CameraEditorState):Void
  {
    var command:Null<CameraEditorCommand> = state.redoHistory.pop();
    if (command == null)
    {
      trace(' CAMERA EDITOR '.bold().bg_bright_yellow() + 'No actions to redo.');
      return;
    }
    state.performCommand(command, false);
  }
}
#end
