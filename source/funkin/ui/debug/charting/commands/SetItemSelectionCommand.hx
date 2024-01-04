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
  var previousNoteSelection:Array<SongNoteData>;
  var previousEventSelection:Array<SongEventData>;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>, previousNoteSelection:Array<SongNoteData>,
      previousEventSelection:Array<SongEventData>)
  {
    this.notes = notes;
    this.events = events;
    this.previousNoteSelection = previousNoteSelection == null ? [] : previousNoteSelection;
    this.previousEventSelection = previousEventSelection == null ? [] : previousEventSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

    // If we just selected one or more events (and no notes), then we should make the event data toolbox display the event data for the selected event.
    if (this.notes.length == 0 && this.events.length >= 1)
    {
      var eventSelected = this.events[0];

      state.eventKindToPlace = eventSelected.event;

      // This code is here to parse event data that's not built as a struct for some reason.
      // TODO: Clean this up or get rid of it.
      var eventSchema = eventSelected.getSchema();
      var defaultKey = null;
      if (eventSchema == null)
      {
        trace('[WARNING] Event schema not found for event ${eventSelected.event}.');
      }
      else
      {
        defaultKey = eventSchema.getFirstField()?.name;
      }
      var eventData = eventSelected.valueAsStruct(defaultKey);

      state.eventDataToPlace = eventData;

      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    }

    state.noteDisplayDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
  }

  public function toString():String
  {
    return 'Select ${notes.length} Items';
  }
}
