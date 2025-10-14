package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;

/**
 * A command which modifies the give time change in the current song's time changes.
 * Annoyingly, due to the way haxe works, every value of the time change has to be passed into this.
 * Will clamp the target timestamp to a valid value.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ModifyTimeChangeCommand implements ChartEditorCommand
{
  var timeChangeIndex:Int;

  var targetBPM:Float;
  var previousBPM:Float = 100;

  var targetTimeStamp:Float;
  var previousTimeStamp:Float = 0;

  var targetNumerator:Int;
  var previousNumerator:Int = 4;

  var targetDenominator:Int;
  var previousDenominator:Int = 4;

  public function new(timeChangeIndex:Int, targetTimeStamp:Float, targetBPM:Float, targetNumerator:Int, targetDenominator:Int)
  {
    this.timeChangeIndex = timeChangeIndex;
    this.targetTimeStamp = thx.Floats.ceilTo(targetTimeStamp, 4);
    this.targetBPM = thx.Floats.ceilTo(targetBPM, 3);
    this.targetNumerator = targetNumerator;
    this.targetDenominator = targetDenominator;
  }

  public function execute(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    if (timeChanges == null || timeChanges.length == 0)
    {
      previousBPM = 100;
      previousTimeStamp = 0;
      timeChanges = [new SongTimeChange(previousTimeStamp, targetBPM)];
    }
    else
    {
      previousBPM = timeChanges[timeChangeIndex].bpm;
      previousTimeStamp = timeChanges[timeChangeIndex].timeStamp;
      previousNumerator = timeChanges[timeChangeIndex].timeSignatureNum;
      previousDenominator = timeChanges[timeChangeIndex].timeSignatureDen;
      timeChanges[timeChangeIndex].bpm = targetBPM;
      // Clamp the target timestamp to a valid value.
      targetTimeStamp.clamp((timeChanges[timeChangeIndex - 1]?.timeStamp ?? 0) + 1, (timeChanges[timeChangeIndex + 1]?.timeStamp ?? state.songLengthInMs) - 1);
      timeChanges[timeChangeIndex].timeStamp = targetTimeStamp;
      timeChanges[timeChangeIndex].timeSignatureNum = targetNumerator;
      timeChanges[timeChangeIndex].timeSignatureDen = targetDenominator;
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.scrollPositionInPixels = 0;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    if (metadataToolbox != null) metadataToolbox.refreshTimeChangeInputs();

    state.updateSongTime();
    state.updateGridHeight();
    state.updateTimeSignature();
  }

  public function undo(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    if (timeChanges == null || timeChanges.length == 0)
    {
      timeChanges = [new SongTimeChange(previousTimeStamp, targetBPM)];
    }
    else
    {
      timeChanges[timeChangeIndex].bpm = previousBPM;
      timeChanges[timeChangeIndex].timeStamp = previousTimeStamp;
      timeChanges[timeChangeIndex].timeSignatureNum = previousNumerator;
      timeChanges[timeChangeIndex].timeSignatureDen = previousDenominator;
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.scrollPositionInPixels = 0;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    if (metadataToolbox != null) metadataToolbox.refreshTimeChangeInputs(true);

    state.updateSongTime();
    state.updateGridHeight();
    state.updateTimeSignature();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (targetBPM != previousBPM
      || targetTimeStamp != previousTimeStamp
      || previousNumerator != targetNumerator
      || previousDenominator != targetDenominator);
  }

  public function toString():String
  {
    return 'TimeChange ${timeChangeIndex}: ${targetTimeStamp} ms : BPM: ${targetBPM} in ${targetNumerator}/${targetDenominator}';
  }
}
#end
