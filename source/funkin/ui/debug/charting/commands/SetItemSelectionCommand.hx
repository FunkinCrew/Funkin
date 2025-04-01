package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;

/**
 * Command to set the current selection in the chart editor (rather than appending it).
 * Deselects any notes that are not in the new selection.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetItemSelectionCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;
  var previousNoteSelection:Array<SongNoteData> = [];
  var previousEventSelection:Array<SongEventData> = [];

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>)
  {
    this.notes = notes;
    this.events = events;
  }

  public function execute(state:ChartEditorState):Void
  {
    this.previousNoteSelection = state.currentNoteSelection;
    this.previousEventSelection = state.currentEventSelection;

    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

    // If we just selected one or more events (and no notes), then we should make the event data toolbox display the event data for the selected event.
    if (this.notes.length == 0 && this.events.length == 1)
    {
      var eventSelected = this.events[0];

      if (state.eventKindToPlace == eventSelected.eventKind)
      {
        trace('Target event kind matches selection: ${eventSelected.eventKind}');
      }
      else
      {
        trace('Switching target event kind to match selection: ${state.eventKindToPlace} != ${eventSelected.eventKind}');
        state.eventKindToPlace = eventSelected.eventKind;
      }

      // This code is here to parse event data that's not built as a struct for some reason.
      // TODO: Clean this up or get rid of it.
      var eventSchema = eventSelected.getSchema();
      var defaultKey = null;
      if (eventSchema == null)
      {
        trace('[WARNING] Event schema not found for event ${eventSelected.eventKind}.');
      }
      else
      {
        defaultKey = eventSchema.getFirstField()?.name;
      }
      var eventData = eventSelected.valueAsStruct(defaultKey);

      var eventDataClone = Reflect.copy(eventData);

      if (eventDataClone != null)
      {
        state.eventDataToPlace = eventDataClone;
      }

      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    }

    // IF we just selected one or more notes (and no events), then we should make the note data toolbox display the note data for the selected note.
    if (this.events.length == 0 && this.notes.length == 1)
    {
      var noteSelected = this.notes[0];

      state.noteKindToPlace = noteSelected.kind;

      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
    }

    state.noteDisplayDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // Add to the history if we actually performed an action.
    return (state.currentNoteSelection != previousNoteSelection && state.currentEventSelection != previousEventSelection);
  }

  public function toString():String
  {
    return 'Select ${notes.length + events.length} Items';
  }
}
