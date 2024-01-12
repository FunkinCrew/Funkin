package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Command to deselect a specific set of notes and events in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class DeselectItemsCommand implements ChartEditorCommand
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
    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentNoteSelection, this.notes);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentEventSelection, this.events);

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    for (note in this.notes)
    {
      state.currentNoteSelection.push(note);
    }

    for (event in this.events)
    {
      state.currentEventSelection.push(event);
    }

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0 || events.length > 0);
  }

  public function toString():String
  {
    var isPlural = (notes.length + events.length) > 1;
    var notesOnly = (notes.length > 0 && events.length == 0);
    var eventsOnly = (notes.length == 0 && events.length > 0);

    if (notesOnly)
    {
      return 'Deselect ${notes.length} ${isPlural ? 'Notes' : 'Note'}';
    }
    else if (eventsOnly)
    {
      return 'Deselect ${events.length} ${isPlural ? 'Events' : 'Event'}';
    }

    return 'Deselect ${notes.length + events.length} Items';
  }
}
