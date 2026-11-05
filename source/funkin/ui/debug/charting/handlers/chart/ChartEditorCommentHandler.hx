package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.components.comments.ChartEditorCommentPanel;
import haxe.ui.util.Color;
import funkin.data.song.SongData.CommentData;

/**
 * Functions for interacting with comments in the chart editor.
 * Handlers split up the functionality of the Chart Editor into different classes based on focus to limit the amount of code in each class.
 */
@:nullSafety @:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCommentHandler
{
  /**
   * Space between the right edge of the grid and the comment panels.
   */
  static final COMMENT_PANEL_GAP:Float = 60;

  static final COMMENT_PANEL_WIDTH:Float = 300;

  static final COMMENT_PANEL_MIN_WIDTH:Float = 160;

  static final COMMENT_PANEL_HEIGHT:Float = 160;

  static final COMMENT_PANEL_COLLAPSED_HEIGHT:Float = 32;

  static final COMMENT_PANEL_BORDER:Float = 1;

  /**
   * Space kept between a panel and the right edge of the screen.
   */
  static final COMMENT_PANEL_MARGIN:Float = 8;

  /**
   * Build the list of preset colors to display in the comment color picker.
   *
   * @param state The ChartEditorState to operate on.
   * @param currentComment (Optional) The current comment being edited.
   * @return A list of colors to display in the comment color picker palette.
   */
  public static function buildCommentColorPalette(state:ChartEditorState, ?currentComment:CommentData):Array<Color>
  {
    var colorPalette:Array<Color> = [];

    if (currentComment != null)
    {
      // The first color in the palette should be the current comment color.
      colorPalette.pushUnique(currentComment.color);
    }

    // Add in all the colors we've used this chart, excluding colors we've already added.
    for (comment in state.currentSongChartCommentData)
    {
      colorPalette.pushUnique(comment.color);
    }

    return colorPalette;
  }

  /**
   * Where the comment panels start, right of the grid. Follows the grid when the window or UI scale changes.
   *
   * @return The left edge of the comment panels, in pixels.
   */
  public static function commentPanelX():Float
  {
    return ChartEditorState.GRID_X_POS + ChartEditorState.GRID_SIZE * (ChartEditorState.STRUMLINE_SIZE * 2 + 1) + COMMENT_PANEL_GAP;
  }

  static function collapsedHeight(panel:ChartEditorCommentPanel):Float
  {
    var header:Float = panel.headerContainer.height;
    return (header != null && header > 0) ? header + COMMENT_PANEL_BORDER * 2 : COMMENT_PANEL_COLLAPSED_HEIGHT;
  }

  /**
   * Place and size a comment panel.
   *
   * @param state The ChartEditorState to operate on.
   * @param panel The panel to place.
   */
  @:nullSafety(Off)
  public static function layoutCommentPanel(state:ChartEditorState, panel:ChartEditorCommentPanel):Void
  {
    var comment:Null<CommentData> = panel.commentData;
    if (comment == null) return;

    var x:Float = commentPanelX();
    var top:Float = ChartEditorState.GRID_INITIAL_Y_POS;
    var bottom:Float = FlxG.height - ChartEditorState.PLAYBAR_HEIGHT;
    var width:Float = Math.max(COMMENT_PANEL_MIN_WIDTH, Math.min(COMMENT_PANEL_WIDTH, FlxG.width - x - COMMENT_PANEL_MARGIN));
    var height:Float = Math.max(0, Math.min(panel.expanded ? COMMENT_PANEL_HEIGHT : collapsedHeight(panel), bottom - top));

    var timeY:Float = ChartEditorTimeScale.msToPixels(comment.time) + state.renderedNotes.y;
    var visible:Bool = height > 0 && timeY >= top - height && timeY <= bottom;
    if (panel.hidden == visible) panel.hidden = !visible;
    if (!visible) return;

    // Only touched when they change, since every change makes HaxeUI lay the panel out again.
    if (panel.width != width) panel.width = width;
    if (panel.height != height) panel.height = height;
    var y:Float = Math.max(top, Math.min(timeY, bottom - height));
    if (panel.x != x) panel.x = x;
    if (panel.y != y) panel.y = y;
  }
}
#end
