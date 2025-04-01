package funkin.ui.debug.charting.commands;

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

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // Add to the history if we actually performed an action.
    return (prevVariation != newVariation || prevDifficulty != newDifficulty);
  }

  public function toString():String
  {
    return 'Switch Difficulty';
  }
}
