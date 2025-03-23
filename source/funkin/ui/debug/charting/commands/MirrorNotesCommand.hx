package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Command that mirrors a given array of notes on either or strumline individually,
 * along either the X (note direction) axis or Y (note time) axis.
 * Flip middle will only work when the given notes are in both strumlines - it's incompatible with individually mirroring the selection.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MirrorNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData> = [];
  var mirroredNotes:Array<SongNoteData> = [];
  var mirrorX:Bool = true;
  var mirrorY:Bool = true;

  public function new(notes:Array<SongNoteData>, mirrorIndividually:Bool = true, flipMiddle:Bool = false, mirrorX:Bool = true, mirrorY:Bool = true)
  {
    this.notes = notes;
    this.mirrorX = mirrorX;
    this.mirrorY = mirrorY;
    if (mirrorIndividually)
    {
      var playerNotes:Array<SongNoteData> = [];
      var opponentNotes:Array<SongNoteData> = [];
      // Sort the selection by the strumline positions and then mirror each individually
      for (note in notes)
      {
        if (note.data < ChartEditorState.STRUMLINE_SIZE)
        {
          playerNotes.push(note);
        }
        else if (note.data >= ChartEditorState.STRUMLINE_SIZE)
        {
          opponentNotes.push(note);
        }
      }
      if (playerNotes.length > 0)
      {
        this.mirroredNotes = mirroredNotes.concat(SongDataUtils.mirrorNotes(playerNotes, ChartEditorState.STRUMLINE_SIZE, flipMiddle, mirrorX, mirrorY));
      }
      if (opponentNotes.length > 0)
      {
        this.mirroredNotes = mirroredNotes.concat(SongDataUtils.mirrorNotes(opponentNotes, ChartEditorState.STRUMLINE_SIZE, flipMiddle, mirrorX, mirrorY));
      }
    }
    else
      this.mirroredNotes = SongDataUtils.mirrorNotes(notes, ChartEditorState.STRUMLINE_SIZE, flipMiddle, mirrorX, mirrorY);
  }

  public function execute(state:ChartEditorState):Void
  {
    // Delete the notes.
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

    // Add the flipped notes.
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(mirroredNotes);

    state.currentNoteSelection = mirroredNotes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, mirroredNotes);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);

    state.currentNoteSelection = notes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0 && mirrorX || !mirrorX && mirrorY && notes.length > 1);
  }

  public function toString():String
  {
    var len:Int = notes.length;
    return 'Mirror ${(notes.length > 1) ? '$len Notes' : 'Note'} on ${(mirrorX) ? 'X' : (mirrorY) ? 'Y' : 'huh?'} Axis';
  }
}
