package funkin.ui.debug.charting.handlers;

#if FEATURE_CHART_EDITOR
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
}
#end
