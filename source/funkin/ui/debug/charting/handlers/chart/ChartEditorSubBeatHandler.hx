package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartEditorData;
import funkin.ui.debug.charting.commands.song.ToggleSubBeatCommand;

/**
 * Sub-beats allow for free-form note placement but still being snapped.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorSubBeatHandler
{
  /**
   * How close, in pixels, a press has to be to an existing sub-beat to remove it.
   */
  static final SUB_BEAT_REMOVE_PIXELS:Float = 4;

  /**
   * The sub-beats of the current variation, in milliseconds, sorted.
   */
  @:nullSafety(Off)
  public static function currentSubBeats(state:ChartEditorState):Array<Float>
  {
    var chartData = state.currentSongChartData;
    if (chartData.editorData == null) chartData.editorData = new SongChartEditorData();
    var editorData:SongChartEditorData = chartData.editorData;
    if (editorData.subBeats == null) editorData.subBeats = [];
    return editorData.subBeats;
  }

  /**
   * Add a sub-beat exactly where the mouse is, or remove the one under it.
   */
  public static function toggleSubBeatAtCursor(state:ChartEditorState):Void
  {
    if (state.gridTiledSprite == null || state.isCursorOverHaxeUI || !FlxG.mouse.overlaps(state.gridTiledSprite)) return;

    var mouseY:Float = FlxG.mouse.viewY - state.gridTiledSprite.y;
    for (existing in currentSubBeats(state))
    {
      if (Math.abs(ChartEditorTimeScale.msToPixels(existing) - mouseY) <= SUB_BEAT_REMOVE_PIXELS)
      {
        state.performCommand(new ToggleSubBeatCommand(existing, false));
        return;
      }
    }

    var step:Float = Math.max(0, Math.min(ChartEditorTimeScale.pixelsToStep(mouseY), state.lastSnappedGridStep));
    state.performCommand(new ToggleSubBeatCommand(Conductor.instance.getStepTimeInMs(step), true));
  }

  /**
   * Snap to a sub-beat instead when one is closer to the cursor than the normal snap, and within half a snap.
   *
   * @param cursorStep Where the cursor is, in steps.
   * @param snappedStep Where the normal snap puts it, in steps.
   * @return The step to snap to.
   */
  public static function snapToSubBeat(state:ChartEditorState, cursorStep:Float, snappedStep:Float):Float
  {
    var best:Float = snappedStep;
    var bestDistance:Float = Math.abs(cursorStep - snappedStep);
    var range:Float = state.noteSnapRatio / 2;
    for (time in currentSubBeats(state))
    {
      var subBeatStep:Float = Conductor.instance.getTimeInSteps(time);
      var distance:Float = Math.abs(cursorStep - subBeatStep);
      if (distance < bestDistance && distance <= range)
      {
        best = subBeatStep;
        bestDistance = distance;
      }
    }
    return best;
  }
}
#end
