package funkin.ui.debug.charting.commands.items;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongDataUtils.SongClipboardItems;
import funkin.data.song.SongNoteDataUtils;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.commands.selection.SelectItemsCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorListKeyTarget;

/**
 * Represents a reversible action to insert the contents of the user's clipboard into the song at the provided timestamp.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class PasteItemsCommand implements ChartEditorCommand
{
  var targetTimestamp:Float;
  // Notes we added and removed with this command, for undo.
  var addedNotes:Array<SongNoteData> = [];
  var addedEvents:Array<SongEventData> = [];
  var removedNotes:Array<SongNoteData> = [];

  var subBeatsBefore:Null<Array<Float>> = null;
  var isRedo:Bool = false;
  var currentClipboard:SongClipboardItems = {
    valid: false,
    notes: [],
    events: []
  };

  public function new(targetTimestamp:Float)
  {
    this.targetTimestamp = targetTimestamp;
    // Doing this here so that clearing or changing the clipboard doesn't break the redo and string.
    this.currentClipboard = SongDataUtils.readItemsFromClipboard();
  }

  /**
   * Perform the action, pasting the clipboard contents into the song.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    if (currentClipboard.valid != true)
    {
      state.error('Failed to Paste', 'Could not parse clipboard contents.');
      state.clipboardDirty = true;
      state.clipboardValid = false;
      return;
    }

    var stepEndOfSong:Float = state.gridLengthInSteps;
    var stepCutoff:Float = stepEndOfSong - 1.0;
    var msCutoff:Float = Conductor.instance.getStepTimeInMs(stepCutoff);

    addedNotes = SongDataUtils.offsetSongNoteData(currentClipboard.notes, targetTimestamp);
    addedNotes = SongDataUtils.clampSongNoteData(addedNotes, 0.0, msCutoff);
    addedEvents = SongDataUtils.offsetSongEventData(currentClipboard.events, targetTimestamp);
    addedEvents = SongDataUtils.clampSongEventData(addedEvents, 0.0, msCutoff);

    removedNotes.clear();
    var mergedNotes:Array<SongNoteData> = SongNoteDataUtils.concatOverwrite(state.currentSongChartNoteData, addedNotes, removedNotes);

    state.currentSongChartNoteData = mergedNotes;
    state.currentSongChartEventData = state.currentSongChartEventData.concat(addedEvents);
    state.currentNoteSelection = addedNotes.copy();
    state.currentEventSelection = addedEvents.copy();

    var pastedSubBeats:Array<Float> = [];
    var copiedSubBeats:Array<Float> = currentClipboard.subBeats ?? [];
    var copiedSnaps:Array<Int> = currentClipboard.subBeatSnaps ?? [];
    for (i in 0...copiedSubBeats.length)
    {
      var time:Float = (copiedSubBeats[i] + targetTimestamp).clamp(0, msCutoff);
      if (state.isTimeOnSnap(time)) continue;
      pastedSubBeats.push(time);
      if (i < copiedSnaps.length) state.rememberSubBeatSnap(time, copiedSnaps[i]);
    }
    if (pastedSubBeats.length > 0)
    {
      var before:Array<Float> = state.currentSubBeats().copy();
      subBeatsBefore = before;
      setSubBeats(state, before.concat(pastedSubBeats));

      var keys:Null<ChartEditorListKeyTarget> = state.listKeyTarget;
      state.subBeatItems.selectTimes(pastedSubBeats, false);
      state.listKeyTarget = keys;
    }

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();

    var title = isRedo ? 'Redone Paste Successfully' : 'Paste Successful';
    var msg = 'Successfully pasted clipboard contents.';

    if (removedNotes.length == 1)
    {
      msg = 'But 1 overlapped note was overwritten.';
    }
    else if (removedNotes.length > 1)
    {
      msg = 'But ${removedNotes.length} overlapped notes were overwritten.';
    }
    else if (isRedo)
    {
      msg = 'Successfully placed pasted note(s) back.';
    }

    if (removedNotes.length > 0)
    {
      ChartEditorNotificationHandler.warning(state, title, msg);
    }
    else
    {
      ChartEditorNotificationHandler.success(state, title, msg);
    }

    isRedo = false;
  }

  function setSubBeats(state:ChartEditorState, times:Array<Float>):Void
  {
    var subBeats:Array<Float> = state.currentSubBeats();
    subBeats.resize(0);
    for (time in times)
    {
      if (!subBeats.contains(time)) subBeats.push(time);
    }
    subBeats.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    state.gridLinesDirty = true;
  }

  /**
   * Reverse the action, removing the pasted notes and events.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, addedNotes).concat(removedNotes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, addedEvents);
    state.currentEventSelection = [];
    var before:Null<Array<Float>> = subBeatsBefore;
    if (before != null)
    {
      setSubBeats(state, before);
      state.subBeatItems.clearSelection();
      subBeatsBefore = null;
    }
    state.performCommand(new SelectItemsCommand(removedNotes.copy()), false);

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();

    isRedo = true;
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
    return (addedNotes.length > 0 || addedEvents.length > 0 || removedNotes.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var len:Int = currentClipboard.notes.length + currentClipboard.events.length;

    if (currentClipboard.notes.length == 0)
    {
      return 'Paste $len Events';
    }
    else if (currentClipboard.events.length == 0)
    {
      return 'Paste $len Notes';
    }
    else
    {
      return 'Paste $len Items';
    }
  }
}
#end
