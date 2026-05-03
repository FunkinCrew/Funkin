package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;

/**
 * Represents a reversible action to perform multiple commands in a sequence at once.
 */
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class CompoundCommand implements CameraEditorCommand
{
  var commands:Array<CameraEditorCommand>;
  var description:String;
  var selectionAfter:Array<SongEventData>;
  var selectionBefore:Array<SongEventData> = [];

  public function new(commands:Array<CameraEditorCommand>, ?description:String, ?selectionAfter:Array<SongEventData>)
  {
    this.commands = commands.copy();
    this.description = description ?? 'Batch (${commands.length})';
    this.selectionAfter = selectionAfter ?? [];
  }

  /**
   * Perform the action, executing all the commands in sequence.
   * @param state The CameraEditorState to perform the command on.
   */
  public function execute(state:CameraEditorState):Void
  {
    selectionBefore = state.selectedSongEvents.copy();
    for (cmd in commands) cmd.execute(state);
    state.selectedSongEvents = selectionAfter.copy();
  }

  /**
   * Reverse the action, undoing all the commands in reverse order.
   * @param state The CameraEditorState to perform the command on.
   */
  public function undo(state:CameraEditorState):Void
  {
    var i:Int = commands.length;
    while (i-- > 0)
    {
      commands[i].undo(state);
    }
    state.selectedSongEvents = selectionBefore.copy();
  }

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The CameraEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    for (cmd in commands) if (cmd.shouldAddToHistory(state)) return true;
    return false;
  }

  public function toString():String
  {
    return description;
  }
}
#end
