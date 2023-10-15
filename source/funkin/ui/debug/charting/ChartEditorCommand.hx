package funkin.ui.debug.charting;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

using Lambda;

/**
 * Actions in the chart editor are backed by the Command pattern
 * (see Bob Nystrom's book "Game Programming Patterns" for more info)
 *
 * To make a function compatible with the undo/redo history, create a new class
 * that implements ChartEditorCommand, then call `ChartEditorState.performCommand(new Command())`
 */
interface ChartEditorCommand
{
  /**
   * Calling this function should perform the action that this command represents.
   * @param state The ChartEditorState to perform the action on.
   */
  public function execute(state:ChartEditorState):Void;

  /**
   * Calling this function should perform the inverse of the action that this command represents,
   * effectively undoing the action.
   * @param state The ChartEditorState to undo the action on.
   */
  public function undo(state:ChartEditorState):Void;

  /**
   * Get a short description of the action (for the UI).
   * For example, return `Add Left Note` to display `Undo Add Left Note` in the menu.
   */
  public function toString():String;
}

@:nullSafety
class AddNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var appendToSelection:Bool;

  public function new(notes:Array<SongNoteData>, appendToSelection:Bool = false)
  {
    this.notes = notes;
    this.appendToSelection = appendToSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    for (note in notes)
    {
      state.currentSongChartNoteData.push(note);
    }

    if (appendToSelection)
    {
      state.currentNoteSelection = state.currentNoteSelection.concat(notes);
    }
    else
    {
      state.currentNoteSelection = notes;
      state.currentEventSelection = [];
    }

    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];
    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    if (notes.length == 1)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Add $dir Note';
    }

    return 'Add ${notes.length} Notes';
  }
}

@:nullSafety
class RemoveNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;

  public function new(notes:Array<SongNoteData>)
  {
    this.notes = notes;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    for (note in notes)
    {
      state.currentSongChartNoteData.push(note);
    }
    state.currentNoteSelection = notes;
    state.currentEventSelection = [];
    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    if (notes.length == 1 && notes[0] != null)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Remove $dir Note';
    }

    return 'Remove ${notes.length} Notes';
  }
}

/**
 * Appends one or more items to the selection.
 */
@:nullSafety
class SelectItemsCommand implements ChartEditorCommand
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

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentNoteSelection, this.notes);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentEventSelection, this.events);

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
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

@:nullSafety
class AddEventsCommand implements ChartEditorCommand
{
  var events:Array<SongEventData>;
  var appendToSelection:Bool;

  public function new(events:Array<SongEventData>, appendToSelection:Bool = false)
  {
    this.events = events;
    this.appendToSelection = appendToSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    for (event in events)
    {
      state.currentSongChartEventData.push(event);
    }

    if (appendToSelection)
    {
      state.currentEventSelection = state.currentEventSelection.concat(events);
    }
    else
    {
      state.currentNoteSelection = [];
      state.currentEventSelection = events;
    }

    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    var len:Int = events.length;
    return 'Add $len Events';
  }
}

@:nullSafety
class RemoveEventsCommand implements ChartEditorCommand
{
  var events:Array<SongEventData>;

  public function new(events:Array<SongEventData>)
  {
    this.events = events;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);
    state.currentEventSelection = [];

    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    for (event in events)
    {
      state.currentSongChartEventData.push(event);
    }
    state.currentEventSelection = events;
    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    if (events.length == 1 && events[0] != null)
    {
      return 'Remove Event';
    }

    return 'Remove ${events.length} Events';
  }
}

@:nullSafety
class RemoveItemsCommand implements ChartEditorCommand
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
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    for (note in notes)
    {
      state.currentSongChartNoteData.push(note);
    }

    for (event in events)
    {
      state.currentSongChartEventData.push(event);
    }

    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    return 'Remove ${notes.length + events.length} Items';
  }
}

@:nullSafety
class SwitchDifficultyCommand implements ChartEditorCommand
{
  var prevDifficulty:String;
  var newDifficulty:String;
  var prevVariation:String;
  var newVariation:String;

  public function new(prevDifficulty:String, newDifficulty:String, prevVariation:String, newVariation:String)
  {
    this.prevDifficulty = prevDifficulty;
    this.newDifficulty = newDifficulty;
    this.prevVariation = prevVariation;
    this.newVariation = newVariation;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.selectedVariation = newVariation != null ? newVariation : prevVariation;
    state.selectedDifficulty = newDifficulty != null ? newDifficulty : prevDifficulty;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.selectedVariation = prevVariation != null ? prevVariation : newVariation;
    state.selectedDifficulty = prevDifficulty != null ? prevDifficulty : newDifficulty;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function toString():String
  {
    return 'Switch Difficulty';
  }
}

@:nullSafety
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

  public function toString():String
  {
    var noteCount = notes.length + events.length;

    if (noteCount == 1)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Deselect $dir Items';
    }

    return 'Deselect ${noteCount} Items';
  }
}

/**
 * Sets the selection rather than appends it.
 * Deselects any notes that are not in the new selection.
 */
@:nullSafety
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

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function toString():String
  {
    return 'Select ${notes.length} Items';
  }
}

@:nullSafety
class SelectAllItemsCommand implements ChartEditorCommand
{
  var previousNoteSelection:Array<SongNoteData>;
  var previousEventSelection:Array<SongEventData>;

  public function new(?previousNoteSelection:Array<SongNoteData>, ?previousEventSelection:Array<SongEventData>)
  {
    this.previousNoteSelection = previousNoteSelection == null ? [] : previousNoteSelection;
    this.previousEventSelection = previousEventSelection == null ? [] : previousEventSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentNoteSelection = state.currentSongChartNoteData;
    state.currentEventSelection = state.currentSongChartEventData;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function toString():String
  {
    return 'Select All Items';
  }
}

@:nullSafety
class InvertSelectedItemsCommand implements ChartEditorCommand
{
  var previousNoteSelection:Array<SongNoteData>;
  var previousEventSelection:Array<SongEventData>;

  public function new(?previousNoteSelection:Array<SongNoteData>, ?previousEventSelection:Array<SongEventData>)
  {
    this.previousNoteSelection = previousNoteSelection == null ? [] : previousNoteSelection;
    this.previousEventSelection = previousEventSelection == null ? [] : previousEventSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentSongChartNoteData, previousNoteSelection);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentSongChartEventData, previousEventSelection);
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function toString():String
  {
    return 'Invert Selected Items';
  }
}

@:nullSafety
class DeselectAllItemsCommand implements ChartEditorCommand
{
  var previousNoteSelection:Array<SongNoteData>;
  var previousEventSelection:Array<SongEventData>;

  public function new(?previousNoteSelection:Array<SongNoteData>, ?previousEventSelection:Array<SongEventData>)
  {
    this.previousNoteSelection = previousNoteSelection == null ? [] : previousNoteSelection;
    this.previousEventSelection = previousEventSelection == null ? [] : previousEventSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public function toString():String
  {
    return 'Deselect All Items';
  }
}

@:nullSafety
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

  public function toString():String
  {
    var len:Int = notes.length + events.length;

    if (notes.length == 0) return 'Cut $len Events to Clipboard';
    else if (events.length == 0) return 'Cut $len Notes to Clipboard';
    else
      return 'Cut $len Items to Clipboard';
  }
}

@:nullSafety
class FlipNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData> = [];
  var flippedNotes:Array<SongNoteData> = [];

  public function new(notes:Array<SongNoteData>)
  {
    this.notes = notes;
    this.flippedNotes = SongDataUtils.flipNotes(notes);
  }

  public function execute(state:ChartEditorState):Void
  {
    // Delete the notes.
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

    // Add the flipped notes.
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(flippedNotes);

    state.currentNoteSelection = flippedNotes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, flippedNotes);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);

    state.currentNoteSelection = notes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    var len:Int = notes.length;
    return 'Flip $len Notes';
  }
}

@:nullSafety
class PasteItemsCommand implements ChartEditorCommand
{
  var targetTimestamp:Float;
  // Notes we added with this command, for undo.
  var addedNotes:Array<SongNoteData> = [];
  var addedEvents:Array<SongEventData> = [];

  public function new(targetTimestamp:Float)
  {
    this.targetTimestamp = targetTimestamp;
  }

  public function execute(state:ChartEditorState):Void
  {
    var currentClipboard:SongClipboardItems = SongDataUtils.readItemsFromClipboard();

    addedNotes = SongDataUtils.offsetSongNoteData(currentClipboard.notes, Std.int(targetTimestamp));
    addedEvents = SongDataUtils.offsetSongEventData(currentClipboard.events, Std.int(targetTimestamp));

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(addedNotes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(addedEvents);
    state.currentNoteSelection = addedNotes.copy();
    state.currentEventSelection = addedEvents.copy();

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/undo'));

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, addedNotes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, addedEvents);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    var currentClipboard:SongClipboardItems = SongDataUtils.readItemsFromClipboard();

    var len:Int = currentClipboard.notes.length + currentClipboard.events.length;

    if (currentClipboard.notes.length == 0) return 'Paste $len Events';
    else if (currentClipboard.events.length == 0) return 'Paste $len Notes';
    else
      return 'Paste $len Items';
  }
}

@:nullSafety
class ExtendNoteLengthCommand implements ChartEditorCommand
{
  var note:SongNoteData;
  var oldLength:Float;
  var newLength:Float;

  public function new(note:SongNoteData, newLength:Float)
  {
    this.note = note;
    this.oldLength = note.length;
    this.newLength = newLength;
  }

  public function execute(state:ChartEditorState):Void
  {
    note.length = newLength;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    ChartEditorAudioHandler.playSound(Paths.sound('chartingSounds/undo'));

    note.length = oldLength;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    return 'Extend Note Length';
  }
}
