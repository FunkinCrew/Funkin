package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to deselect all selected notes and events
 * before or after a given timestamp.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class DeselectAllItemsBetweenTimeCommand implements ChartEditorCommand
{
  var time:Float;
  var above:Bool;
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;
  var shouldDeselectNotes:Bool;
  var shouldDeselectEvents:Bool;

  public function new(time:Float, above:Bool, shouldDeselectNotes:Bool, shouldDeselectEvents:Bool)
  {
    this.time = time;
    this.above = above;

    this.notes = [];
    this.events = [];

    this.shouldDeselectNotes = shouldDeselectNotes;
    this.shouldDeselectEvents = shouldDeselectEvents;
  }

  /**
   * Perform the action, deselecting all notes and events before or after the given timestamp.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    if (above)
    {
      if (shouldDeselectNotes)
      {
        for (i in 0...state.currentSongChartNoteData.length)
        {
          if (state.currentSongChartNoteData[i].time < time)
          {
            notes.pushUnique(state.currentSongChartNoteData[i]);
          }
          else
          {
            // We've reached the end of the notes above this time,
            // there's no reason to waste our time running this loop to completion
            break;
          }
        }
      }
      if (shouldDeselectEvents)
      {
        for (i in 0...state.currentSongChartEventData.length)
        {
          if (state.currentSongChartEventData[i].time < time)
          {
            events.pushUnique(state.currentSongChartEventData[i]);
          }
          else
          {
            break;
          }
        }
      }
    }
    else // Deselecting below the time given
    {
      if (shouldDeselectNotes)
      {
        for (i in 0...state.currentSongChartNoteData.length)
        {
          // Backwards for loop (kinda). Neat!
          if (state.currentSongChartNoteData[state.currentSongChartNoteData.length - i - 1].time > time)
          {
            notes.pushUnique(state.currentSongChartNoteData[state.currentSongChartNoteData.length - i - 1]);
          }
          else
          {
            // We've reached the end of the notes below this time,
            // there's no reason to waste our time running this loop to completion
            break;
          }
        }
      }
      if (shouldDeselectEvents)
      {
        for (i in 0...state.currentSongChartEventData.length)
        {
          if (state.currentSongChartEventData[state.currentSongChartEventData.length - i - 1].time > time)
          {
            events.pushUnique(state.currentSongChartEventData[state.currentSongChartEventData.length - i - 1]);
          }
          else
          {
            break;
          }
        }
      }
    }

    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentNoteSelection, this.notes);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentEventSelection, this.events);

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  /**
   * Reverse the action, re-selecting the notes and events that were deselected.
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
