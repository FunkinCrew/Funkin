package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;

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

  public function execute(state:CameraEditorState):Void
  {
    selectionBefore = state.selectedSongEvents.copy();
    for (cmd in commands)
      cmd.execute(state);
    state.selectedSongEvents = selectionAfter.copy();
  }

  public function undo(state:CameraEditorState):Void
  {
    var i:Int = commands.length;
    while (i-- > 0)
      commands[i].undo(state);
    state.selectedSongEvents = selectionBefore.copy();
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    for (cmd in commands)
      if (cmd.shouldAddToHistory(state)) return true;
    return false;
  }

  public function toString():String
  {
    return description;
  }
}
#end
