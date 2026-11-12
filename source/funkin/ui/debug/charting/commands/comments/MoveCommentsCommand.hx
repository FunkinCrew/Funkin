package funkin.ui.debug.charting.commands.comments;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to move comments to new times.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MoveCommentsCommand implements ChartEditorCommand
{
  var comments:Array<CommentData>;
  var targetTimes:Array<Float>;
  var previousTimes:Array<Float> = [];

  /**
   * @param comments The comments to move.
   * @param targetTimes Where each comment ends up, in milliseconds, in the same order.
   */
  public function new(comments:Array<CommentData>, targetTimes:Array<Float>)
  {
    this.comments = comments;
    this.targetTimes = targetTimes;
  }

  /**
   * Perform the action, moving the comments.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    previousTimes = [for (comment in comments) comment.time];
    for (i in 0...comments.length)
    {
      comments[i].time = targetTimes[i];
    }

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

    state.saveDataDirty = true;
    state.commentDisplayDirty = true;
  }

  /**
   * Reverse the action, putting the comments back where they were.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    for (i in 0...comments.length)
    {
      comments[i].time = previousTimes[i];
    }

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));

    state.saveDataDirty = true;
    state.commentDisplayDirty = true;
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
    for (i in 0...comments.length)
    {
      if (previousTimes[i] != targetTimes[i]) return true;
    }
    return false;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return comments.length == 1 ? 'Move Comment' : 'Move ${comments.length} Comments';
  }
}
#end
