package funkin.ui.debug.charting.commands.comments;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to add one or more comments.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AddCommentCommand implements ChartEditorCommand
{
  var comments:Array<CommentData>;

  /**
   * Whether the added comments become the selection, like pasted notes do.
   */
  var selectAdded:Bool;

  public function new(comment:CommentData, ?otherComments:Array<CommentData>, selectAdded:Bool = false)
  {
    this.comments = [comment].concat(otherComments ?? []);
    this.selectAdded = selectAdded;
  }

  /**
   * Perform the action, adding the new comments.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    for (comment in comments)
    {
      state.currentSongChartCommentData.push(comment);
    }
    if (selectAdded) state.commentItems.select(comments.copy());

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

    state.commentDisplayDirty = true;
  }

  /**
   * Reverse the action, removing the added comments.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    for (comment in comments)
    {
      state.currentSongChartCommentData.remove(comment);
      state.commentItems.deselect(comment);
    }

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
    // This command is undoable.
    return true;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return comments.length == 1 ? 'Add Comment' : 'Add ${comments.length} Comments';
  }
}
#end
