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

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function execute(state:ChartEditorState):Void
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
		if (notes.length == 1)
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

class CopyNotesCommand implements ChartEditorCommand
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
		state.currentClipboard = SongDataUtils.buildClipboard(notes);
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentClipboard = previousSelection;
	}

	public function toString():String
	{
		var len:Int = notes.length;
		return 'Copy $len Notes to Clipboard';
	}
}

class CutNotesCommand implements ChartEditorCommand
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
		// Copy the notes.
		state.currentClipboard = SongDataUtils.buildClipboard(notes);

		// Delete the notes.
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
		state.currentSelection = [];
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentClipboard = previousSelection;
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

class PasteNotesCommand implements ChartEditorCommand
{
	private var targetTimestamp:Int;

	public function new(targetTimestamp:Int)
	{
		this.targetTimestamp = targetTimestamp;
	}

	public function execute(state:ChartEditorState):Void
	{
		var notesToAdd = SongDataUtils.offsetSongNoteData(state.currentClipboard, targetTimestamp);

		state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notesToAdd);
		state.currentSelection = notesToAdd;

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		// NOTE: We can assume that the previous action
		// defined the clipboard, so we don't need to redundantly it here... right?
		state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, state.currentClipboard);
		state.currentSelection = [];

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function toString():String
	{
		var len:Int = state.currentClipboard.length;
		return 'Paste $len Notes from Clipboard';
	}
}

class AddEventsCommand implements ChartEditorCommand
{
	private var events:Array<SongEventData>;

	//	private var previousSelection:Array<SongEventData>;

	public function new(events:Array<SongEventData>, ?previousSelection:Array<SongEventData>)
	{
		this.events = events;
		// this.previousSelection = previousSelection == null ? [] : previousSelection;
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
		// TODO: Allow selecting events.
		// state.currentSelection = previousSelection;

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
