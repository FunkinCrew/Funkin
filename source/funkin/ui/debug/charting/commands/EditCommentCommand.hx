package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongData.CommentData;

/**
 * Represents a reversible action to modify a comment.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class EditCommentCommand implements ChartEditorCommand
{
  var comment:CommentData;
  var time:Null<Float>;
  var text:Null<String>;
  var color:Null<String>;

  public function new(targetComment:CommentData, newTime:Null<Float>, newText:Null<String>, newColor:Null<String>)
  {
    this.comment = targetComment;

    this.time = newTime;
    this.text = newText;
    this.color = newColor;
  }

  /**
   * Perform the action, adding the new comment.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    trace('Modifying comment');
    state.currentSongChartCommentData.push(comment);

    state.commentDisplayDirty = true;
  }

  /**
   * Reverse the action, removing the added comment.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartCommentData.remove(comment);

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
    // This command is undoable.
    return true;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return 'Add Comment';
  }
}
#end
