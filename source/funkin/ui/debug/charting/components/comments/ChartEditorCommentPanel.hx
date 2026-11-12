package funkin.ui.debug.charting.components.comments;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.dialogs.ChartEditorColorPicker;
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.commands.comments.EditCommentCommand;
import funkin.ui.debug.charting.commands.comments.RemoveCommentCommand;
import haxe.ui.containers.Panel;
import haxe.ui.events.FocusEvent;
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

  /**
   * The text the comment had when typing in it started, so the whole edit undoes as one step.
   */
  var textBeforeEdit:Null<String> = null;

  /**
   * Whether the panel is drawn as picked, so the style only changes when that does.
   */
  var shownSelected:Bool = false;

  /**
   * Whether the text box shows. Closed panels show only their header, with the start of the text as the title.
   */
  public var expanded(default, set):Bool = false;

  function set_expanded(value:Bool):Bool
  {
    if (expanded == value) return value;
    expanded = value;
    if (!expanded) commitTextEdit();
    commentPanelBody.hidden = !expanded;
    updateTitle();
    updatePosition();
    return value;
  }

  /**
   * How long the title preview of a closed comment can get.
   */
  static final TITLE_PREVIEW_LENGTH:Int = 28;

  function updateTitle():Void
  {
    var title:String = 'Comment';
    if (!expanded && commentData != null)
    {
      var firstLine:String = StringTools.trim(commentData.text.split('\n')[0]);
      if (firstLine.length > TITLE_PREVIEW_LENGTH) firstLine = firstLine.substr(0, TITLE_PREVIEW_LENGTH - 3) + '...';
      if (firstLine.length > 0) title = firstLine;
    }
    if (this.text != title) this.text = title;
  }

  /**
   * Whether a point is on the text box, which is only there while the panel is open.
   */
  public function textContains(x:Float, y:Float):Bool
  {
    return expanded && !hidden && commentCardTextField.hitTest(x, y);
  }

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

    chartEditorState.commentColorToPlace = color.toHex();
    chartEditorState.performCommand(new EditCommentCommand(commentData, null, color.toHex()));
  }

  /**
   * Called when the Delete button is clicked.
   */
  @:bind(commentButtonDelete, MouseEvent.CLICK)
  function onClickDelete(_:MouseEvent):Void
  {
    if (commentData == null) return;

    // Undoable like every other delete, so it doesn't ask first.
    commitTextEdit();
    chartEditorState.performCommand(new RemoveCommentCommand(commentData));
  }

  @:bind(commentCardTextField, UIEvent.CHANGE)
  function onEditCommentCardTextField(_:UIEvent):Void
  {
    if (commentData == null) return;

    var newText:String = commentCardTextField.text;
    if (newText == commentData.text) return;

    // Shown straight away, then saved as one undo step when the text box loses focus.
    textBeforeEdit ??= commentData.text;
    commentData.text = newText;
    chartEditorState.saveDataDirty = true;
    chartEditorState.commentDisplayDirty = true;
  }

  @:bind(commentCardTextField, FocusEvent.FOCUS_OUT)
  function onCommentCardTextFieldFocusOut(_:FocusEvent):Void
  {
    commitTextEdit();
  }

  /**
   * Turn the typing done since the text box got focus into one undoable edit.
   */
  public function commitTextEdit():Void
  {
    var before:Null<String> = textBeforeEdit;
    textBeforeEdit = null;
    if (commentData == null || before == null || before == commentData.text) return;

    var after:String = commentData.text;
    commentData.text = before;
    chartEditorState.performCommand(new EditCommentCommand(commentData, after, null));
  }

  /**
   * Whether a point is on the header, outside its buttons. That's the part that picks and drags the comment.
   */
  public function headerContains(x:Float, y:Float):Bool
  {
    if (hidden || commentData == null) return false;
    if (commentButtonColor.hitTest(x, y) || commentButtonDelete.hitTest(x, y)) return false;
    return headerContainer.hitTest(x, y);
  }

  /**
   * Called when the comment data is set.
   */
  function set_commentData(value:Null<CommentData>):Null<CommentData>
  {
    if (this.commentData == value) return this.commentData;

    // Moving on to another comment saves what was typed in this one.
    commitTextEdit();
    this.commentData = value;

    if (this.commentData == null)
    {
      this.hidden = true;
      return this.commentData;
    }

    this.hidden = false;

    expanded = chartEditorState.commentItems.isExpanded(this.commentData);
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
    chartEditorState.layoutCommentPanel(this);
  }

  /**
   * Update the text of the comment card.
   */
  public function updateText():Void
  {
    if (commentData == null) return;

    // Setting the same text again would move the caret while typing.
    if (this.commentCardTextField.text != commentData.text) this.commentCardTextField.text = commentData.text;
    updateTitle();
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

    header.customStyle.backgroundColor = Color.fromString(commentData.color);
    header.customStyle.color = ColorUtil.getHaxeUITextColor(header.backgroundColor);
    header.invalidateComponentStyle();

    text.customStyle.color = ColorUtil.getHaxeUITextColor(header.backgroundColor);
    text.invalidateComponentStyle();

    updateSelected();
  }

  /**
   * Outline the panel while its comment is picked, the same way picked notes get a box.
   */
  public function updateSelected():Void
  {
    var selected:Bool = commentData != null && chartEditorState.commentItems.contains(commentData);
    if (selected == shownSelected) return;
    shownSelected = selected;

    // Each side is set on its own, since HaxeUI draws the border from those.
    var color:Null<Int> = selected ? 0xFFFFFF : null;
    var size:Null<Float> = selected ? 2 : null;
    customStyle.borderColor = color;
    customStyle.borderTopColor = color;
    customStyle.borderLeftColor = color;
    customStyle.borderBottomColor = color;
    customStyle.borderRightColor = color;
    customStyle.borderSize = size;
    customStyle.borderTopSize = size;
    customStyle.borderLeftSize = size;
    customStyle.borderBottomSize = size;
    customStyle.borderRightSize = size;
    invalidateComponentStyle();
  }
}
#end
