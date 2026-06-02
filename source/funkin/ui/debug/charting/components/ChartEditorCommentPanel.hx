package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import haxe.ui.util.Color;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import funkin.ui.debug.charting.commands.RemoveCommentCommand;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.events.MouseEvent;
import funkin.data.song.SongData.CommentData;
import haxe.ui.containers.Panel;

/**
 * The panel that displays the contents of a comment.
 */
// nullSafety breaks on HaxeUI components *sob*
@:access(funkin.ui.debug.charting.ChartEditorState) @:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/components/comment.xml'))
class ChartEditorCommentPanel extends Panel
{
  var chartEditorState:ChartEditorState;

  /**
   * The comment data that this panel represents.
   * You can set this to null to kill the panel and flag it for recycling.
   */
  public var commentData(default, set):Null<CommentData> = null;

  public function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;
  }

  /**
   * Called when the Color button is clicked.
   */
  @:bind(commentButtonColor, MouseEvent.CLICK)
  function onClickColor(_:MouseEvent):Void
  {
    if (commentData == null) return;

    trace('Changing color of comment: ${commentData}');
  }

  /**
   * Called when the Delete button is clicked.
   */
  @:bind(commentButtonDelete, MouseEvent.CLICK)
  function onClickDelete(_:MouseEvent):Void
  {
    if (commentData == null) return;

    trace('Deleting comment: ${commentData}');

    // Deletion confirm dialog.
    Dialogs.messageBox('You are about to delete this comment.\n\nAre you sure? ', 'Delete Comment', MessageBoxType.TYPE_YESNO, true, (btn:DialogButton) ->
    {
      if (btn == DialogButton.YES)
      {
        chartEditorState.performCommand(new RemoveCommentCommand(commentData));

        commentData = null;
      }
    });
  }

  /**
   * Called when the comment data is set.
   */
  function set_commentData(value:Null<CommentData>):Null<CommentData>
  {
    if (this.commentData == value) return this.commentData;

    this.commentData = value;

    if (this.commentData == null)
    {
      this.hidden = true;
      return this.commentData;
    }

    this.hidden = false;

    updatePosition();
    updateColor();
    updateText();

    return this.commentData;
  }

  public function updatePosition():Void
  {
    if (commentData == null) return;

    var songTimeMs:Float = commentData.time;
    var songTimeSteps:Float = Conductor.instance.getTimeInSteps(songTimeMs);
    var songTimePixels:Float = songTimeSteps * ChartEditorState.GRID_SIZE;

    var relativeSongPixels:Float = chartEditorState.renderedNotes.y;

    this.x = 900;
    this.y = songTimePixels + relativeSongPixels;
  }

  function updateText():Void
  {
    if (commentData == null) return;

    this.commentCardTextField.text = commentData.text;
  }

  function updateColor():Void
  {
    if (commentData == null) return;

    var header = headerContainer.childComponents[0];

    header.color = Color.fromString('white');
    header.backgroundColor = Color.fromString(commentData.color);
  }
}
#end
