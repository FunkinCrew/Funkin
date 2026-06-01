package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
/**
 * Represents a reversible action to set the audio offset for an audio track in the chart.
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

  /**
   * Perform the action, modifying the audio offset for the specified audio track.
   *
   * @param state The ChartEditorState to perform the command on.
   */
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

  /**
   * Reverse the action, reverting the audio offsets to the previous value.
   *
   * @param state The ChartEditorState to perform the command on.
   */
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

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (newOffset != oldOffset);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
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
#end
