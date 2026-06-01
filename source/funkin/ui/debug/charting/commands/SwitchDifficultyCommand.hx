package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
/**
 * Represents a reversible action to switch the currently displayed difficulty (and variation).
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
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

  /**
   * Perform the action, switching the difficulty and loading the appropriate chart data.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    trace('Start switching variation.');
    state.selectedVariation = newVariation != null ? newVariation : prevVariation;
    trace('Done switching variation.');
    state.selectedDifficulty = newDifficulty != null ? newDifficulty : prevDifficulty;

    markDirty(state);
  }

  /**
   * Reverse the action, reverting to the previous difficulty and variation.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.selectedVariation = prevVariation != null ? prevVariation : newVariation;
    state.selectedDifficulty = prevDifficulty != null ? prevDifficulty : newDifficulty;

    markDirty(state);
  }

  function markDirty(state:ChartEditorState):Void
  {
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
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
    // Add to the history if we actually performed an action.
    return (prevVariation != newVariation || prevDifficulty != newDifficulty);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return 'Switch Difficulty to $newDifficulty ($newVariation)';
  }
}
#end
