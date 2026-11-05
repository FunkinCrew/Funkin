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
   * How close, in milliseconds, a time has to be to a snap to count as on it. Sub-beats aren't kept there.
   */
  static final ON_SNAP_MS:Float = 2;

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
    if (isOnSnap(state, step)) return;
    state.performCommand(new ToggleSubBeatCommand(Conductor.instance.getStepTimeInMs(step), true));
  }

  /**
   * The step of the sub-beat closest to a step, or `null` if there are none.
   */
  public static function nearestSubBeatStep(state:ChartEditorState, step:Float):Null<Float>
  {
    var subBeats:Array<Float> = currentSubBeats(state);
    if (subBeats.length == 0) return null;
    var time:Float = Conductor.instance.getStepTimeInMs(step);
    var low:Int = 0;
    var high:Int = subBeats.length;
    while (low < high)
    {
      var mid:Int = (low + high) >> 1;
      if (subBeats[mid] < time) low = mid + 1;
      else
        high = mid;
    }
    var best:Float = subBeats[low < subBeats.length ? low : subBeats.length - 1];
    if (low > 0 && Math.abs(subBeats[low - 1] - time) <= Math.abs(best - time)) best = subBeats[low - 1];
    return Conductor.instance.getTimeInSteps(best);
  }

  /**
   * Whether dragged items are shown somewhere other than where they are.
   */
  public static function isDragPreviewing(state:ChartEditorState):Bool
  {
    return state.dragTargetCurrentStep != 0 || state.dragAlignToSubBeats;
  }

  /**
   * Whether a sub-beat already sits at this step.
   */
  public static function hasSubBeatAt(state:ChartEditorState, step:Float):Bool
  {
    var nearest:Null<Float> = nearestSubBeatStep(state, step);
    if (nearest == null) return false;
    return Math.abs(Conductor.instance.getStepTimeInMs(nearest) - Conductor.instance.getStepTimeInMs(step)) < 0.001;
  }

  /**
   * Whether a step sits on the current snap.
   */
  public static function isOnSnap(state:ChartEditorState, step:Float):Bool
  {
    var snapped:Float = Math.fround(step / state.noteSnapRatio) * state.noteSnapRatio;
    return Math.abs(Conductor.instance.getStepTimeInMs(step) - Conductor.instance.getStepTimeInMs(snapped)) <= ON_SNAP_MS;
  }

  /**
   * Drop the sub-beats of the current variation that sit on the current snap.
   */
  @:nullSafety(Off)
  public static function removeSubBeatsOnSnap(state:ChartEditorState):Void
  {
    var subBeats:Null<Array<Float>> = state.currentSongChartData?.editorData?.subBeats;
    if (subBeats == null || subBeats.length == 0) return;
    var kept:Array<Float> = subBeats.filter(time -> !isTimeOnSnap(state, time));
    if (kept.length == subBeats.length) return;
    subBeats.resize(0);
    for (time in kept) subBeats.push(time);
    state.subBeatItems?.clearSelection();
    state.gridLinesDirty = true;
  }

  /**
   * Whether a time, in milliseconds, sits on the current snap.
   */
  public static function isTimeOnSnap(state:ChartEditorState, time:Float):Bool
  {
    return isOnSnap(state, Conductor.instance.getTimeInSteps(time));
  }

  /**
   * Whether an item dropped at this step needs a new sub-beat, being off the snap with none there already.
   */
  public static function needsSubBeat(state:ChartEditorState, step:Float):Bool
  {
    return !isOnSnap(state, step) && !hasSubBeatAt(state, step);
  }

  /**
   * Where a dragged item that starts at this step is shown.
   */
  public static function dragPreviewStep(state:ChartEditorState, stepTime:Float):Float
  {
    return (stepTime + state.dragTargetCurrentStep).clamp(0, state.lastSnappedGridStep);
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
