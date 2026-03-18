package funkin.ui.debug.cameraeditor.handlers;

import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongChartData;

/**
 * A class to handle the Camera Event Auto Generator and its functionality.
 */
@:nullSafety
class CameraEditorAutoGeneratorHandler
{
  public static function autoGenEvents(state:CameraEditorState, params:CameraEditorAutoGenParams):Void
  {
    var chartData:Null<SongChartData> = state.currentSongChartData;

    if (chartData == null) return;

    var difficultyList:Array<String> = chartData.notes.keyValues();
    difficultyList.sort(funkin.util.SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

    // TODO: Is using the last difficulty the best method?
    var targetDifficulty:String = difficultyList[difficultyList.length - 1];

    var notes:Null<Array<SongNoteData>> = chartData.notes.get(targetDifficulty)?.clone();
    if (notes == null) return;

    switch (params.placementMode)
    {
      case CameraEditorAutoGenPlacementMode.Vanilla:
        // Determine the length of one measure.
        var firstTimeChange:Null<SongTimeChange> = state.currentSongMetadata?.timeChanges[0];
        // TODO: This should probably be in its own function!
        var beatLengthMs:Float = ((Constants.SECS_PER_MIN / (firstTimeChange?.bpm ?? 100)) * Constants.MS_PER_SEC) * (4 / (firstTimeChange?.timeSignatureDen ?? 4));
        // TODO: Should this be a parameter? Current value is 3 beats,
        // which is enough to prevent quick pauses while allowing for overlapping at the end of a measure.
        var period:Float = beatLengthMs * 3;

        var generatedEvents:Array<SongEventData> = autoGen_Vanilla(notes, period);

      default:
        trace(' WARNING '.warning() + ' Unknown Auto Generator placement mode: ' + params.placementMode);
        return;
    }
  }

  /**
   * Place one FocusCamera song event every time a character sings, after not singing for `period` milliseconds.
   *
   * @param notes The note data for the chart to generate events for.
   * @param period The time before it's no longer that character's turn to sing.
   * @return The generated FocusCamera events.
   */
  static function autoGen_Vanilla(notes:Array<SongNoteData>, period:Float):Array<SongEventData>
  {
    var result:Array<SongEventData> = [];

    var createFocus = function(time:Float, isPlayer:Bool):SongEventData
    {
      var event:SongEventData = new SongEventData(time, 'FocusCamera', {
        char: isPlayer ? 0 : 1
      });

      event.editorLayer = 'Generated';

      return event;
    }

    // Start with a focus event for the first character to sing.
    var firstNote:Null<SongNoteData> = notes.shift();
    if (firstNote == null) return [];
    var startsOnPlayer:Bool = firstNote.getMustHitNote();
    result.push(createFocus(0, startsOnPlayer));

    var lastTimeOtherCharacterSang:Float = 0.0;
    var isCurrentlyOnPlayer:Bool = startsOnPlayer;

    for (note in notes)
    {
      if (note.getMustHitNote() != isCurrentlyOnPlayer)
      {
        var timeSinceLastNote:Float = note.time - lastTimeOtherCharacterSang;
        trace('Time since last note ($timeSinceLastNote ms > $period ms) [${note.time} ms]');
        if (timeSinceLastNote >= period)
        {
          trace('Period exceeded, switching focus...');
          result.push(createFocus(note.time, !isCurrentlyOnPlayer));
          isCurrentlyOnPlayer = !isCurrentlyOnPlayer;
        }

        lastTimeOtherCharacterSang = note.time;
      }
    }

    return result;
  }
}

typedef CameraEditorAutoGenParams =
{
  var placementMode:CameraEditorAutoGenPlacementMode;
}

enum abstract CameraEditorAutoGenPlacementMode(String) from String
{
  /**
   * The `Vanilla` placement mode:
   * Every time a character's strumline has a note, when it hasn't had a note for a while,
   * focus the camera on that character.
   */
  public var Vanilla = 'vanilla';

  // If you think up any other algorithms, enumerate them here.
}
