package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.dialogs.ChartEditorColorPicker;
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.commands.RemoveCommentCommand;
import haxe.ui.containers.Panel;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Color;
import funkin.util.ColorUtil;

// nullSafety breaks on HaxeUI components *sob*

/**
 * The panel that displays the contents of a comment.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/components/comment.xml'))
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

    var dialog:ChartEditorColorPicker = ChartEditorColorPicker.build(chartEditorState, true, true);

    dialog.onColorSelected = onChangeColor;
    dialog.paletteColors = ChartEditorCommentHandler.buildCommentColorPalette(chartEditorState, commentData);
  }

  function onChangeColor(color:Color):Void
  {
    if (commentData == null) return;

    commentData.color = color.toHex();
    chartEditorState.commentColorToPlace = commentData.color;
    chartEditorState.commentDisplayDirty = true;
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
        chartEditorState.commentDisplayDirty = true;
      }
    });
  }

  @:bind(commentCardTextField, UIEvent.CHANGE)
  function onEditCommentCardTextField(_:UIEvent):Void
  {
    if (commentData == null) return;

    var newText:String = commentCardTextField.text;
    if (newText == commentData.text) return;

    // TODO: Make this undoable/redoable without being painful.
    commentData.text = newText;
    chartEditorState.commentDisplayDirty = true;
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

  /**
   * Update the horizontal and vertical position of the panel, relative to the grid.
   */
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

  /**
   * Update the text of the comment card.
   */
  public function updateText():Void
  {
    if (commentData == null) return;

    this.commentCardTextField.text = commentData.text;
  }

  /**
   * Update the color of the comment card.
   */
  public function updateColor():Void
  {
    if (commentData == null) return;

    var header = headerContainer.childComponents[0];
    // header child 0 is an icon
    var text = header.childComponents[1];

    trace(Type.getClassName(Type.getClass(text)));

    header.customStyle.backgroundColor = Color.fromString(commentData.color);
    header.customStyle.color = ColorUtil.getHaxeUITextColor(header.backgroundColor);
    header.invalidateComponentStyle();

    text.customStyle.color = ColorUtil.getHaxeUITextColor(header.backgroundColor);
    text.invalidateComponentStyle();
  }
}
#end
