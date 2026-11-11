package funkin.ui.debug.charting.selection;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.commands.timing.ModifyTimeChangeCommand;
import funkin.ui.debug.charting.commands.timing.RemoveTimeChangeCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorTimingToolbox;
import funkin.util.Constants;

/**
 * BPM/Time sigs
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorTimeChangeItems extends ChartEditorSelectableItems<SongTimeChange>
{
  var timeChanges(get, never):Array<SongTimeChange>;

  function get_timeChanges():Array<SongTimeChange>
  {
    return state.currentSongMetadata.timeChanges;
  }

  /**
   * The index of the first picked time change, the one the Timing panel shows. -1 when none is picked.
   */
  public var selectedIndex(get, never):Int;

  function get_selectedIndex():Int
  {
    return selected.length > 0 ? timeChanges.indexOf(selected[0]) : -1;
  }

  /**
   * The indexes of every picked time change still in the song.
   */
  public function selectedIndexes():Array<Int>
  {
    return [for (timeChange in selected) timeChanges.indexOf(timeChange)].filter(index -> index >= 0);
  }

  /**
   * Pick one time change by its index, or none if it's out of range.
   */
  public function selectIndex(index:Int, takeKeys:Bool = true, exclusive:Bool = true):Void
  {
    var timeChange:Null<SongTimeChange> = timeChanges[index];
    select(timeChange != null ? [timeChange] : [], takeKeys, exclusive);
  }

  override function itemUnderMouse():Null<SongTimeChange>
  {
    if (state.gridLines == null || state.isCursorOverHaxeUI) return null;
    var index:Int = state.gridLines.timeChangeUnderMouse();
    return index >= 0 ? timeChanges[index] : null;
  }

  override function canGrab(item:SongTimeChange):Bool
  {
    return timeChanges.indexOf(item) > 0;
  }

  override function itemsInBox(left:Float, right:Float, startMs:Float, endMs:Float):Array<SongTimeChange>
  {
    if (state.gridLines == null) return [];
    return [for (index in state.gridLines.timeChangesInBox(left, startMs, endMs)) timeChanges[index]];
  }

  override function getTime(item:SongTimeChange):Float
  {
    return item.timeStamp;
  }

  /**
   * Each time change sits between its neighbours, so only the held one moves.
   */
  override function dragItems(item:SongTimeChange):Array<SongTimeChange>
  {
    return [item];
  }

  /**
   * Measured from the time change before it, since that one decides how long its beats are.
   */
  override function timeAtStep(item:SongTimeChange, step:Float):Float
  {
    var index:Int = timeChanges.indexOf(item);
    var previous:Null<SongTimeChange> = timeChanges[index - 1];
    if (previous == null) return item.timeStamp;
    return previous.timeStamp + (step - previous.beatTime * Constants.STEPS_PER_BEAT) * stepMs(previous);
  }

  /**
   * Stays at least a step after the time change before it, and a step before the next one or the end of the song.
   */
  override function clampDelta(items:Array<SongTimeChange>, originalTimes:Array<Float>, delta:Float):Float
  {
    var item:SongTimeChange = items[0];
    var index:Int = timeChanges.indexOf(item);
    var previous:Null<SongTimeChange> = timeChanges[index - 1];
    if (previous == null) return 0;
    var next:Null<SongTimeChange> = timeChanges[index + 1];
    var target:Float = originalTimes[0] + delta;
    var min:Float = previous.timeStamp + stepMs(previous);
    var max:Float = (next != null ? next.timeStamp : state.songLengthInMs) - stepMs(item);
    return Math.max(min, Math.min(target, max)) - originalTimes[0];
  }

  /**
   * The scroll position is left alone until the drag ends, so the grid doesn't slide under the mouse.
   */
  override function setTimes(items:Array<SongTimeChange>, times:Array<Float>):Void
  {
    for (i in 0...items.length)
    {
      items[i].timeStamp = times[i];
    }
    Conductor.instance.mapTimeChanges(timeChanges);
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.gridLinesDirty = true;
    state.updateGridHeight();
  }

  override function commitMove(items:Array<SongTimeChange>, targetTimes:Array<Float>):Void
  {
    var item:SongTimeChange = items[0];
    state.performCommand(new ModifyTimeChangeCommand(timeChanges.indexOf(item), targetTimes[0], item.bpm, item.timeSignatureNum, item.timeSignatureDen));
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));
  }

  /**
   * Clicking the picked tag again opens the Timing panel.
   */
  override function onClickReleased(item:SongTimeChange, wasOnlySelection:Bool):Void
  {
    if (!wasOnlySelection) return;
    state.openToolboxFromGrid(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT, state.menubarItemToggleToolboxTiming);
    timingToolbox()?.refreshTimeChanges(timeChanges.indexOf(item));
  }

  /**
   * The Timing panel pointed at the picked time change. Built without being shown if it isn't open.
   */
  function timingToolbox():Null<ChartEditorTimingToolbox>
  {
    return cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT);
  }

  override public function copySelection():Void
  {
    var toolbox:Null<ChartEditorTimingToolbox> = timingToolbox();
    if (toolbox == null) return;

    var picked:Array<SongTimeChange> = selected.copy();
    toolbox.refreshTimeChanges(selectedIndex);
    toolbox.copySelection();
    select(picked);
    ChartEditorSelectableItems.lastCopied = this;
  }

  override public function pasteSelection():Void
  {
    timingToolbox()?.pasteSelection();
  }

  /**
   * Removes every picked time change except the first one in the song, as one undo step.
   */
  override public function deleteSelection():Void
  {
    var indexes:Array<Int> = selectedIndexes().filter(index -> index > 0);
    if (indexes.length == 0) return;
    indexes.sort((a, b) -> a - b);
    state.performCommand(new RemoveTimeChangeCommand(indexes[0], indexes.slice(1)));
  }

  static function stepMs(timeChange:SongTimeChange):Float
  {
    return ((Constants.SECS_PER_MIN / timeChange.bpm) * Constants.MS_PER_SEC) * (4 / timeChange.timeSignatureDen) / Constants.STEPS_PER_BEAT;
  }
}
#end
