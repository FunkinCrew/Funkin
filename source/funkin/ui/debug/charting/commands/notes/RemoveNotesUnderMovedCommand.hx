package funkin.ui.debug.charting.commands.notes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to remove notes that were under moved notes after they are deselected.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveNotesUnderMovedCommand implements ChartEditorCommand
{
  var movedNotes:Array<SongNoteData>;
  var removedNotes:Array<SongNoteData>;

  public function new(movedNotes:Array<SongNoteData>,
    removedNotes:Array<SongNoteData>)
  {
    this.movedNotes = movedNotes.copy();
    this.removedNotes = removedNotes.copy();
  }

  public function execute(state:ChartEditorState):Void
  {
    var removing:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
    for (note in removedNotes) removing.set(note, true);
    state.currentSongChartNoteData = state.currentSongChartNoteData.filter(note -> !removing.exists(note));

    var count:Int = removedNotes.length;
    state.warning('Removed Stacked Notes', count == 1 ? 'Removed 1 note that was under a moved note.' : 'Removed $count notes that were under moved notes.');

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(removedNotes);
    state.currentNoteSelection = movedNotes.filter(note -> state.currentSongChartNoteData.contains(note));
    state.currentEventSelection = [];
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return removedNotes.length > 0;
  }

  public function toString():String
  {
    return removedNotes.length == 1 ? 'Remove Stacked Note' : 'Remove ${removedNotes.length} Stacked Notes';
  }
}
#end
