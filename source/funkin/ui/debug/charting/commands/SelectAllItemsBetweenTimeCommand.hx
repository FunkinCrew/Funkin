package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Command that selects all notes and/or events above or past the time given in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SelectAllItemsBetweenTimeCommand implements ChartEditorCommand
{
  var time:Float;
  var above:Bool;

  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;

  var shouldSelectNotes:Bool;
  var shouldSelectEvents:Bool;

  public function new(time:Float, above:Bool, shouldSelectNotes:Bool, shouldSelectEvents:Bool)
  {
    this.time = time;
    this.above = above;

    this.notes = [];
    this.events = [];

    this.shouldSelectNotes = shouldSelectNotes;
    this.shouldSelectEvents = shouldSelectEvents;
  }

  public function execute(state:ChartEditorState):Void
  {
    if(above)
    {
      if (shouldSelectNotes)
      {
        for (i in 0...state.currentSongChartNoteData.length)
        {
          if (state.currentSongChartNoteData[i].time < time)
            notes.push(state.currentSongChartNoteData[i]);
          else
            //We've reached the end of the notes above this time,
            // there's no reason to waste our time running this loop to completion
            break;
        }
      }
      if (shouldSelectEvents)
      {
        for (i in 0...state.currentSongChartEventData.length)
        {
          if (state.currentSongChartEventData[i].time < time)
            events.push(state.currentSongChartEventData[i]);

          else
            break;
        }
      }
    }
    else // Selecting below the time given
    {
      if (shouldSelectNotes)
      {
        for (i in 0...state.currentSongChartNoteData.length)
        {
          // Backwards for loop (kinda). Neat!
          if (state.currentSongChartNoteData[state.currentSongChartNoteData.length - i - 1].time > time)
          notes.push(state.currentSongChartNoteData[state.currentSongChartNoteData.length - i- 1]);
          else
            // We've reached the end of the notes below this time,
            // there's no reason to waste our time running this loop to completion
            break;
        }
      }
      if (shouldSelectEvents)
      {
        for (i in 0...state.currentSongChartEventData.length)
        {
          if (state.currentSongChartEventData[state.currentSongChartEventData.length - i - 1].time > time)
          events.push(state.currentSongChartEventData[state.currentSongChartEventData.length- i- 1]);
          else
            break;
        }
      }
    }

    // Add the notes and events to the selection
    for (note in this.notes)
    {
      state.currentNoteSelection.push(note);
    }

    for (event in this.events)
    {
      state.currentEventSelection.push(event);
    }


    // I don't think it's neccesary to copy this code in, but someone will make an issue out of this if I don't, I'm sure.
    // If we just selected one or more events (and no notes), then we should make the event data toolbox display the event data for the selected event.
    if (this.notes.length == 0 && this.events.length == 1)
    {
      var eventSelected = this.events[0];

      state.eventKindToPlace = eventSelected.eventKind;

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
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentNoteSelection, this.notes);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentEventSelection, this.events);

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
