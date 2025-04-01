package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Command that sets the start time or end time of the Freeplay preview.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetFreeplayPreviewCommand implements ChartEditorCommand
{
  var previousStartTime:Int = 0;
  var previousEndTime:Int = 0;
  var newStartTime:Null<Int> = null;
  var newEndTime:Null<Int> = null;

  public function new(newStartTime:Null<Int>, newEndTime:Null<Int>)
  {
    this.newStartTime = newStartTime;
    this.newEndTime = newEndTime;
  }

  public function execute(state:ChartEditorState):Void
  {
    this.previousStartTime = state.currentSongFreeplayPreviewStart;
    this.previousEndTime = state.currentSongFreeplayPreviewEnd;

    if (newStartTime != null) state.currentSongFreeplayPreviewStart = newStartTime;
    if (newEndTime != null) state.currentSongFreeplayPreviewEnd = newEndTime;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongFreeplayPreviewStart = previousStartTime;
    state.currentSongFreeplayPreviewEnd = previousEndTime;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return (newStartTime != null && newStartTime != previousStartTime) || (newEndTime != null && newEndTime != previousEndTime);
  }

  public function toString():String
  {
    var setStart = newStartTime != null && newStartTime != previousStartTime;
    var setEnd = newEndTime != null && newEndTime != previousEndTime;

    if (setStart && !setEnd)
    {
      return "Set Freeplay Preview Start Time";
    }
    else if (setEnd && !setStart)
    {
      return "Set Freeplay Preview End Time";
    }
    else
    {
      return "Set Freeplay Preview Start and End Times";
    }
  }
}
