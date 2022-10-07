package funkin.ui.debug.charting;

import funkin.play.song.SongData.SongNoteData;

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

class AddNoteCommand implements ChartEditorCommand
{
	private var note:SongNoteData;

	public function new(note:SongNoteData)
	{
		this.note = note;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData.push(note);
		state.playSound(Paths.sound('funnyNoise/funnyNoise-08'));
		state.noteDisplayDirty = true;
		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData.remove(note);
		state.playSound(Paths.sound('funnyNoise/funnyNoise-01'));
		state.noteDisplayDirty = true;
		state.sortChartData();
	}

	public function toString():String
	{
		var dir:String = note.getDirectionName();

		return 'Add $dir Note';
	}
}

class RemoveNoteCommand implements ChartEditorCommand
{
	private var note:SongNoteData;

	public function new(note:SongNoteData)
	{
		this.note = note;
	}

	public function execute(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData.remove(note);
		state.playSound(Paths.sound('funnyNoise/funnyNoise-01'));
		state.noteDisplayDirty = true;
		state.sortChartData();
	}

	public function undo(state:ChartEditorState):Void
	{
		state.currentSongChartNoteData.push(note);
		state.playSound(Paths.sound('funnyNoise/funnyNoise-08'));
		state.noteDisplayDirty = true;
		state.sortChartData();
	}

	public function toString():String
	{
		var dir:String = note.getDirectionName();

		return 'Remove $dir Note';
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
