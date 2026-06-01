package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
/**
 * Represents a reversible action to set the Freeplay preview start and end times.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetFreeplayPreviewCommand implements ChartEditorCommand
{
  var previousStartTime:Float = 0;
  var previousEndTime:Float = 0;
  var newStartTime:Null<Float> = null;
  var newEndTime:Null<Float> = null;

  public function new(newStartTime:Null<Float>, newEndTime:Null<Float>)
  {
    this.newStartTime = newStartTime;
    this.newEndTime = newEndTime;
  }

  /**
   * Perform the action, modifying the Freeplay preview start and end times.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    this.previousStartTime = state.currentSongFreeplayPreviewStart;
    this.previousEndTime = state.currentSongFreeplayPreviewEnd;

    if (newStartTime != null) state.currentSongFreeplayPreviewStart = newStartTime;
    if (newEndTime != null) state.currentSongFreeplayPreviewEnd = newEndTime;
  }

  /**
   * Reverse the action, reverting the Freeplay preview start and end times to the previous value.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongFreeplayPreviewStart = previousStartTime;
    state.currentSongFreeplayPreviewEnd = previousEndTime;
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
    return (newStartTime != null && newStartTime != previousStartTime) || (newEndTime != null && newEndTime != previousEndTime);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var setStart = newStartTime != null && newStartTime != previousStartTime;
    var setEnd = newEndTime != null && newEndTime != previousEndTime;

    if (setStart && !setEnd)
    {
      return 'Set Freeplay Preview Start Time';
    }
    else if (setEnd && !setStart)
    {
      return 'Set Freeplay Preview End Time';
    }
    else
    {
      return 'Set Freeplay Preview Start and End Times';
    }
  }
}
#end
