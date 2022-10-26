package funkin.ui.debug.charting;

import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongDataUtils;

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

class AddNotesCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;
	private var appendToSelection:Bool;

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
			state.currentSelection = state.currentSelection.concat(notes);
		}
		else
		{
			state.currentSelection = notes;
		}

		state.playSound(Paths.sound('funnyNoise/funnyNoise-08'));

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
		state.currentSelection = [];
		state.playSound(Paths.sound('funnyNoise/funnyNoise-01'));

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

class RemoveNotesCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
		state.currentSelection = [];
		state.playSound(Paths.sound('funnyNoise/funnyNoise-01'));

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
		state.currentSelection = notes;
		state.playSound(Paths.sound('funnyNoise/funnyNoise-08'));

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

class SwitchDifficultyCommand implements ChartEditorCommand
{
	private var prevDifficulty:String;
	private var newDifficulty:String;
	private var prevVariation:String;
	private var newVariation:String;

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

/**
 * Adds one or more notes to the selection.
 */
class SelectNotesCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function execute(state:ChartEditorState):Void
	{
		for (note in this.notes)
		{
			state.currentSelection.push(note);
		}

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSelection = SongDataUtils.subtractNotes(state.currentSelection, this.notes);

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function toString():String
	{
		if (notes.length == 1)
		{
			var dir:String = notes[0].getDirectionName();
			return 'Select $dir Note';
		}

		return 'Select ${notes.length} Notes';
	}
}

class DeselectNotesCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSelection = SongDataUtils.subtractNotes(state.currentSelection, this.notes);

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state:ChartEditorState):Void
	{
		for (note in this.notes)
		{
			state.currentSelection.push(note);
		}

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function toString():String
	{
		if (notes.length == 1)
		{
			var dir:String = notes[0].getDirectionName();
			return 'Deselect $dir Note';
		}

		return 'Deselect ${notes.length} Notes';
	}
}

/**
 * Sets the selection rather than appends it.
 * Deselects any notes that are not in the new selection.
 */
class SetNoteSelectionCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;
	private var previousSelection:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>, ?previousSelection:Array<SongNoteData>)
	{
		this.notes = notes;
		this.previousSelection = previousSelection == null ? [] : previousSelection;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSelection = notes;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSelection = previousSelection;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function toString():String
	{
		return 'Select ${notes.length} Notes';
	}
}

class SelectAllNotesCommand implements ChartEditorCommand
{
	private var previousSelection:Array<SongNoteData>;

	public function new(?previousSelection:Array<SongNoteData>)
	{
		this.previousSelection = previousSelection == null ? [] : previousSelection;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSelection = state.currentSongChartNoteData;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSelection = previousSelection;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function toString():String
	{
		return 'Select All Notes';
	}
}

class InvertSelectedNotesCommand implements ChartEditorCommand
{
	private var previousSelection:Array<SongNoteData>;

	public function new(?previousSelection:Array<SongNoteData>)
	{
		this.previousSelection = previousSelection == null ? [] : previousSelection;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSelection = SongDataUtils.subtractNotes(state.currentSongChartNoteData, previousSelection);
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSelection = previousSelection;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function toString():String
	{
		return 'Invert Selected Notes';
	}
}

class DeselectAllNotesCommand implements ChartEditorCommand
{
	private var previousSelection:Array<SongNoteData>;

	public function new(?previousSelection:Array<SongNoteData>)
	{
		this.previousSelection = previousSelection == null ? [] : previousSelection;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSelection = [];

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSelection = previousSelection;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function toString():String
	{
		return 'Deselect All Notes';
	}
}

class CutNotesCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function execute(state:ChartEditorState):Void
	{
		// Copy the notes.
		SongDataUtils.writeNotesToClipboard(SongDataUtils.buildClipboard(notes));

		// Delete the notes.
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
		state.currentSelection = [];
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);
		state.currentSelection = notes;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function toString():String
	{
		var len:Int = notes.length;
		return 'Cut $len Notes to Clipboard';
	}
}

class FlipNotesCommand implements ChartEditorCommand
{
	private var notes:Array<SongNoteData>;
	private var flippedNotes:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function execute(state:ChartEditorState):Void
	{
		// Delete the notes.
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

		// Add the flipped notes.
		flippedNotes = SongDataUtils.flipNotes(notes);
		state.currentSongChartNoteData = state.currentSongChartNoteData.concat(flippedNotes);

		state.currentSelection = flippedNotes;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, flippedNotes);
		state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);

		state.currentSelection = notes;

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

class PasteNotesCommand implements ChartEditorCommand
{
	private var targetTimestamp:Float;
	// Notes we added with this command, for undo.
	private var addedNotes:Array<SongNoteData>;

	public function new(targetTimestamp:Float)
	{
		this.targetTimestamp = targetTimestamp;
	}

	public function execute(state:ChartEditorState):Void
	{
		var currentClipboard:Array<SongNoteData> = SongDataUtils.readNotesFromClipboard();

		addedNotes = SongDataUtils.offsetSongNoteData(currentClipboard, Std.int(targetTimestamp));

		state.currentSongChartNoteData = state.currentSongChartNoteData.concat(addedNotes);
		state.currentSelection = addedNotes.copy();

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, addedNotes);
		state.currentSelection = [];

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function toString():String
	{
		var currentClipboard:Array<SongNoteData> = SongDataUtils.readNotesFromClipboard();
		return 'Paste ${currentClipboard.length} Notes from Clipboard';
	}
}

class AddEventsCommand implements ChartEditorCommand
{
	private var events:Array<SongEventData>;
	private var appendToSelection:Bool;

	public function new(events:Array<SongEventData>, ?appendToSelection:Bool = false)
	{
		this.events = events;
		this.appendToSelection = appendToSelection;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSongChartEventData = state.currentSongChartEventData.concat(events);
		// TODO: Allow selecting events.
		// state.currentSelection = events;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

		state.currentSelection = [];

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

class ExtendNoteLengthCommand implements ChartEditorCommand
{
	private var note:SongNoteData;
	private var oldLength:Float;
	private var newLength:Float;

	public function new(note:SongNoteData, newLength:Float)
	{
		this.note = note;
		this.oldLength = note.length;
		this.newLength = newLength;
	}

	public function execute(state:ChartEditorState):Void
	{
		note.length = newLength;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		note.length = oldLength;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function toString():String
	{
		return 'Extend Note Length';
	}
}
