package funkin.ui.debug.charting.components;

import flixel.FlxSprite;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;

/**
 * A sprite that can be used to display a square over a selected note or event in the chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
class ChartEditorSelectionSquareSprite extends FlxSprite
{
  public var noteData:Null<SongNoteData>;
  public var eventData:Null<SongEventData>;

  public function new()
  {
    super();
  }
}
