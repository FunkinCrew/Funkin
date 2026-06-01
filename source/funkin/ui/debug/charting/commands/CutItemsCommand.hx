package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to cut the currently selected notes and song events,
 * adding them to the clipboard before deleting them from the chart.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class CutItemsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>)
  {
    this.notes = notes;
    this.events = events;
  }

  /**
   * Perform the action, cutting the currently selected notes and song events.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    // Copy the notes.
    SongDataUtils.writeItemsToClipboard({
      notes: SongDataUtils.buildNoteClipboard(notes),
      events: SongDataUtils.buildEventClipboard(events)
    });

    // Delete the notes.
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
    state.clipboardDirty = true;
    state.clipboardValid = true;
    state.sortChartData();
  }

  /**
   * Reverse the action, re-adding the cut notes and song events to the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(events);

    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
    state.sortChartData();
  }

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Always add it to the history.
    return (notes.length > 0 || events.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var len:Int = notes.length + events.length;

    if (notes.length == 0)
    {
      return 'Cut $len Events to Clipboard';
    }
    else if (events.length == 0)
    {
      return 'Cut $len Notes to Clipboard';
    }
    else
    {
      return 'Cut $len Items to Clipboard';
    }
  }
}
#end
