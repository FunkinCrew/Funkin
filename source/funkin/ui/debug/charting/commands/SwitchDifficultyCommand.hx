package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
/**
 * Switch the current difficulty (and possibly variation) of the chart in the chart editor.
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
   * Perform the difficulty switch.
   * @param state The ChartEditorState to perform the action on.
   */
  public function execute(state:ChartEditorState):Void
  {
    state.selectedVariation = newVariation != null ? newVariation : prevVariation;
    state.selectedDifficulty = newDifficulty != null ? newDifficulty : prevDifficulty;

    markDirty(state);
  }

  /**
   * Reverse the difficulty switch.
   * @param state The ChartEditorState to perform the action on.
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
   * @param state The ChartEditorState to perform the action on.
   * @return Whether or not this instance of the command should be added to the history.
   *   If the command didn't actually change anything, return `false` to prevent polluting the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // Add to the history if we actually performed an action.
    return (prevVariation != newVariation || prevDifficulty != newDifficulty);
  }

  public function toString():String
  {
    return 'Switch Difficulty to $newDifficulty ($newVariation)';
  }
}
#end
