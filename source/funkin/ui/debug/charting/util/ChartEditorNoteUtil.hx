package funkin.ui.debug.charting.util;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.NoteParamData;

class ChartEditorNoteUtil
{
  /**
   * Convert a note data value into a chart editor grid column number.
   */
  public static function noteDataToGridColumn(input:Int):Int
  {
    if (input < 0) input = 0;
    if (input >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      // Don't invert the Event column.
      input = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (input >= ChartEditorState.STRUMLINE_SIZE)
      {
        input -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        input += ChartEditorState.STRUMLINE_SIZE;
      }
    }
    return input;
  }

  /**
   * Convert a chart editor grid column number into a note data value.
   */
  public static function gridColumnToNoteData(input:Int):Int
  {
    if (input < 0) input = 0;
    if (input >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      // Don't invert the Event column.
      input = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (input >= ChartEditorState.STRUMLINE_SIZE)
      {
        input -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        input += ChartEditorState.STRUMLINE_SIZE;
      }
    }
    return input;
  }

  public static function cloneNoteParams(paramsToClone:Array<NoteParamData>):Array<NoteParamData>
  {
    var params:Array<NoteParamData> = [];
    for (param in paramsToClone)
    {
      params.push(param.clone());
    }
    return params;
  }
}
#end
