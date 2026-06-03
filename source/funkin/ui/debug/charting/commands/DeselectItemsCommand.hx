package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to remove a specific set of notes and events from the current selection.
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

  /**
   * Perform the action, deselecting the given notes and events.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentNoteSelection, this.notes);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentEventSelection, this.events);

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
  }

  /**
   * Reverse the action, reselecting the notes and events that were deselected.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    for (note in this.notes)
    {
      state.currentNoteSelection.pushUnique(note);
    }

    for (event in this.events)
    {
      state.currentEventSelection.pushUnique(event);
    }

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
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
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0 || events.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
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
#end
