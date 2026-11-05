package funkin.ui.debug.charting.util;

#if FEATURE_CHART_EDITOR
import flixel.util.FlxColor;
import funkin.data.song.SongData.NoteParamData;
import funkin.play.notes.notekind.NoteKind;
import funkin.play.notes.notekind.NoteKindManager;

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

  /**
   * The name shown for a note kind.
   */
  public static function noteKindName(kind:Null<String>):String
  {
    if (kind == null || kind.length == 0) return 'Default';
    var noteKind:Null<NoteKind> = NoteKindManager.getNoteKind(kind);
    var description:Null<String> = noteKind?.description;
    return (description != null && description.length > 0) ? description : kind;
  }

  /**
   * Gotta have UGH
   */
  static final NOTE_KIND_TAGS:Map<String, String> = ['ugh' => 'UG'];

  /**
   * A short tag for a note kind, drawn on its notes.
   */
  public static function noteKindTag(kind:Null<String>):String
  {
    if (kind == null || kind.length == 0) return '';
    var custom:Null<String> = NOTE_KIND_TAGS.get(kind);
    if (custom != null) return custom;
    var words:Array<String> = ~/[^A-Za-z0-9]+/g.split(noteKindName(kind)).filter(word -> word.length > 0);
    if (words.length == 0) return '?';
    if (words.length == 1) return words[0].substr(0, 2).toUpperCase();
    return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
  }

  /**
   * A color for a note kind.
   */
  public static function noteKindColor(kind:Null<String>):FlxColor
  {
    if (kind == null || kind.length == 0) return FlxColor.WHITE;
    var hash:Int = 0;
    for (i in 0...kind.length)
    {
      hash = (hash * 31 + StringTools.fastCodeAt(kind, i)) & 0x7FFFFFFF;
    }
    return FlxColor.fromHSB(hash % 360, 0.65, 1.0);
  }
}
#end
