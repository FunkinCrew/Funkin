package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Command that copies a given set of notes and song events to the clipboard,
 * and then deletes them from the chart editor.
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

  public function execute(state:ChartEditorState):Void
  {
    // Copy the notes.
    SongDataUtils.writeItemsToClipboard(
      {
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
    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(events);

    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Always add it to the history.
    return (notes.length > 0 || events.length > 0);
  }

  public function toString():String
  {
    var len:Int = notes.length + events.length;

    if (notes.length == 0) return 'Cut $len Events to Clipboard';
    else if (events.length == 0) return 'Cut $len Notes to Clipboard';
    else
      return 'Cut $len Items to Clipboard';
  }
}
