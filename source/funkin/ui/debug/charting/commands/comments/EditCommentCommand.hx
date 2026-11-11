package funkin.ui.debug.charting.commands.comments;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to change a comment's text or color.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class EditCommentCommand implements ChartEditorCommand
{
  var comment:CommentData;
  var text:Null<String>;
  var color:Null<String>;
  var previousText:String = '';
  var previousColor:String = '';

  public function new(targetComment:CommentData, newText:Null<String>, newColor:Null<String>)
  {
    this.comment = targetComment;
    this.text = newText;
    this.color = newColor;
  }

  /**
   * Perform the action, changing the comment.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    previousText = comment.text;
    previousColor = comment.color;
    if (text != null) comment.text = text;
    if (color != null) comment.color = color;

    state.commentDisplayDirty = true;
  }

  /**
   * Reverse the action, putting the old text and color back.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    comment.text = previousText;
    comment.color = previousColor;

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));

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
    return (text != null && text != previousText) || (color != null && color != previousColor);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return color != null ? 'Change Comment Color' : 'Edit Comment';
  }
}
#end
