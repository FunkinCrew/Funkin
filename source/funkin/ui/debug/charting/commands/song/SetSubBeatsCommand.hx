package funkin.ui.debug.charting.commands.song;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a change to the list of sub-beats in the chart.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetSubBeatsCommand implements ChartEditorCommand
{
  var before:Array<Float>;
  var after:Array<Float>;

  var pickAfter:Array<Float>;
  var label:String;

  public function new(before:Array<Float>, after:Array<Float>, pickAfter:Array<Float>, label:String)
  {
    this.before = before.copy();
    this.after = after.copy();
    this.pickAfter = pickAfter.copy();
    this.label = label;
  }

  /**
   * Perform the action, putting the new list in place.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    apply(state, after);
    state.subBeatItems.selectTimes(pickAfter);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/${after.length < before.length ? 'note-erase' : 'note-place'}'));
  }

  /**
   * Reverse the action, putting the old list back.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    apply(state, before);
    state.subBeatItems.clearSelection();
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
  }

  function apply(state:ChartEditorState, times:Array<Float>):Void
  {
    var subBeats:Array<Float> = state.currentSubBeats();
    subBeats.resize(0);
    for (time in times)
    {
      if (!subBeats.contains(time)) subBeats.push(time);
    }
    subBeats.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));

    state.saveDataDirty = true;
    state.gridLinesDirty = true;
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
    if (before.length != after.length) return true;
    for (i in 0...before.length)
    {
      if (before[i] != after[i]) return true;
    }
    return false;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return label;
  }
}
#end
