package funkin.ui.debug.charting.commands;

/**
 * Command that copies a given set of notes and song events to the clipboard,
 * without deleting them from the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetAudioOffsetCommand implements ChartEditorCommand
{
  var type:AudioOffsetType;
  var oldOffset:Float = 0;
  var newOffset:Float;
  var refreshOffsetsToolbox:Bool;

  public function new(type:AudioOffsetType, newOffset:Float, refreshOffsetsToolbox:Bool = true)
  {
    this.type = type;
    this.newOffset = newOffset;
    this.refreshOffsetsToolbox = refreshOffsetsToolbox;
  }

  public function execute(state:ChartEditorState):Void
  {
    switch (type)
    {
      case INSTRUMENTAL:
        oldOffset = state.currentInstrumentalOffset;
        state.currentInstrumentalOffset = newOffset;

        // Update rendering.
        Conductor.instance.instrumentalOffset = state.currentInstrumentalOffset;
        state.songLengthInMs = (state.audioInstTrack?.length ?? 1000.0) + Conductor.instance.instrumentalOffset;
      case PLAYER:
        oldOffset = state.currentVocalOffsetPlayer;
        state.currentVocalOffsetPlayer = newOffset;

        // Update rendering.
        state.audioVocalTrackGroup.playerVoicesOffset = state.currentVocalOffsetPlayer;
      case OPPONENT:
        oldOffset = state.currentVocalOffsetOpponent;
        state.currentVocalOffsetOpponent = newOffset;

        // Update rendering.
        state.audioVocalTrackGroup.opponentVoicesOffset = state.currentVocalOffsetOpponent;
    }

    // Update the offsets toolbox.
    if (refreshOffsetsToolbox)
    {
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT);
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT);
    }
  }

  public function undo(state:ChartEditorState):Void
  {
    switch (type)
    {
      case INSTRUMENTAL:
        state.currentInstrumentalOffset = oldOffset;

        // Update rendering.
        Conductor.instance.instrumentalOffset = state.currentInstrumentalOffset;
        state.songLengthInMs = (state.audioInstTrack?.length ?? 1000.0) + Conductor.instance.instrumentalOffset;
      case PLAYER:
        state.currentVocalOffsetPlayer = oldOffset;

        // Update rendering.
        state.audioVocalTrackGroup.playerVoicesOffset = state.currentVocalOffsetPlayer;
      case OPPONENT:
        state.currentVocalOffsetOpponent = oldOffset;

        // Update rendering.
        state.audioVocalTrackGroup.opponentVoicesOffset = state.currentVocalOffsetOpponent;
    }

    // Update the offsets toolbox.
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT);
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (newOffset != oldOffset);
  }

  public function toString():String
  {
    switch (type)
    {
      case INSTRUMENTAL:
        return 'Set Inst. Audio Offset to $newOffset';
      case PLAYER:
        return 'Set Player Audio Offset to $newOffset';
      case OPPONENT:
        return 'Set Opponent Audio Offset to $newOffset';
    }
  }
}

enum AudioOffsetType
{
  INSTRUMENTAL;
  PLAYER;
  OPPONENT;
}
