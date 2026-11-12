package funkin.ui.debug.charting.commands.song;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to add or remove a sub-beat, an extra beat line notes snap to.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ToggleSubBeatCommand implements ChartEditorCommand
{
  var time:Float;
  var adding:Bool;

  /**
   * @param time Where the sub-beat is, in milliseconds.
   * @param adding Add it when true, remove it when false.
   */
  public function new(time:Float, adding:Bool)
  {
    this.time = time;
    this.adding = adding;
  }

  /**
   * Perform the action, adding or removing the sub-beat.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    apply(state, adding);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/${adding ? 'note-place' : 'note-erase'}'));
  }

  /**
   * Reverse the action.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    apply(state, !adding);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
  }

  function apply(state:ChartEditorState, add:Bool):Void
  {
    var subBeats:Array<Float> = state.currentSubBeats();
    state.subBeatItems.clearSelection();
    if (add)
    {
      if (!subBeats.contains(time)) subBeats.push(time);
      subBeats.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    }
    else
    {
      subBeats.remove(time);
    }

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
    return true;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return adding ? 'Add Sub-Beat' : 'Remove Sub-Beat';
  }
}
#end
