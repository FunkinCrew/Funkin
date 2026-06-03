package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to append a list of notes and events to the current selection.
 * Use `SetItemSelectionCommand` to replace the current selection rather than appending to it.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SelectItemsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;

  public function new(?notes:Array<SongNoteData>, ?events:Array<SongEventData>)
  {
    this.notes = notes ?? [];
    this.events = events ?? [];
  }

  /**
   * Perform the action, adding the notes and events to the current selection.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    for (note in this.notes)
    {
      state.currentNoteSelection.pushUnique(note);
    }

    for (event in this.events)
    {
      state.currentEventSelection.pushUnique(event);
    }

    // If we just selected one or more events (and no notes), then we should make the event data toolbox display the event data for the selected event.
    if (this.notes.length == 0 && this.events.length == 1)
    {
      var eventSelected = this.events[0];

      state.eventKindToPlace = eventSelected.eventKind;

      var eventData = eventSelected.valueAsStruct();

      state.eventDataToPlace = eventData;

      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    }

    // If we just selected one or more notes (and no events), then we should make the note data toolbox display the note data for the selected note.
    if (this.events.length == 0 && this.notes.length == 1)
    {
      var noteSelected = this.notes[0];

      state.noteKindToPlace = noteSelected.kind;

      // This code is here to parse note data that's not built as a struct for some reason.
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
    }

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
  }

  /**
   * Reverse the action, deselecting the notes and events that were selected.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentNoteSelection, this.notes);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentEventSelection, this.events);

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
    var len:Int = notes.length + events.length;

    if (notes.length == 0)
    {
      if (events.length == 1)
      {
        return 'Select Event';
      }
      else
      {
        return 'Select ${events.length} Events';
      }
    }
    else if (events.length == 0)
    {
      if (notes.length == 1)
      {
        return 'Select Note';
      }
      else
      {
        return 'Select ${notes.length} Notes';
      }
    }

    return 'Select ${len} Items';
  }
}
#end
