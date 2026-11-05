package funkin.ui.debug.charting.selection;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.song.SetSubBeatsCommand;
import funkin.ui.debug.charting.handlers.chart.ChartEditorSubBeatHandler;

/**
 * The sub-beats, picked and dragged by their tags right of the grid.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorSubBeatItems extends ChartEditorSelectableItems<Int>
{
  /**
   * How far from a tag's middle, in pixels, the mouse can be and still be on it.
   */
  static final TAG_REACH_Y:Float = 6;

  /**
   * The last copied sub-beats, relative to the first one.
   */
  var copied:Array<Float> = [];
  var copiedSnaps:Array<Int> = [];

  /**
   * How close, in milliseconds, a note has to be to a sub-beat to move with it.
   */
  static final ATTACHED_NOTE_MS:Float = 1;

  var dragStartTimes:Array<Float> = [];

  var attachedNotes:Array<Array<SongNoteData>> = [];
  var attachedTimes:Array<Array<Float>> = [];

  var subBeats(get, never):Array<Float>;

  function get_subBeats():Array<Float>
  {
    return state.currentSubBeats();
  }

  /**
   * The times of the picked sub-beats.
   */
  public function selectedTimes():Array<Float>
  {
    return [for (index in selected) if (index >= 0 && index < subBeats.length) subBeats[index]];
  }

  /**
   * Pick the sub-beats at these times. Used after the list changes and the places shift.
   */
  public function selectTimes(times:Array<Float>):Void
  {
    var indexes:Array<Int> = [];
    for (time in times)
    {
      var index:Int = subBeats.indexOf(time);
      if (index >= 0 && !indexes.contains(index)) indexes.push(index);
    }
    select(indexes);
  }

  /**
   * Where the tags sit, right of the grid.
   */
  function tagLeft():Float
  {
    return (state.gridTiledSprite?.x ?? 0) + ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT;
  }

  override function itemUnderMouse():Null<Int>
  {
    if (state.gridTiledSprite == null || state.isCursorOverHaxeUI) return null;
    var left:Float = tagLeft();
    if (FlxG.mouse.viewX < left - 2 || FlxG.mouse.viewX > left + 16) return null;
    var best:Null<Int> = null;
    var bestDistance:Float = TAG_REACH_Y;
    for (i in 0...subBeats.length)
    {
      var distance:Float = Math.abs(FlxG.mouse.viewY - itemScreenY(i));
      if (distance <= bestDistance)
      {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  override function itemsInBox(left:Float, right:Float, startMs:Float, endMs:Float):Array<Int>
  {
    if (right < tagLeft()) return [];
    return [for (i in 0...subBeats.length) if (subBeats[i] >= startMs && subBeats[i] <= endMs) i];
  }

  /**
   * Sub-beats move freely, they are the snap points.
   */
  override function snapStep(step:Float):Float
  {
    return step;
  }

  /**
   * Notes sitting on a dragged sub-beat come along with it.
   */
  override function dragItems(item:Int):Array<Int>
  {
    var items:Array<Int> = super.dragItems(item);
    dragStartTimes = [];
    attachedNotes = [];
    attachedTimes = [];
    for (index in items)
    {
      var time:Float = subBeats[index];
      var notes:Array<SongNoteData> = state.currentSongChartNoteData.filter(note -> Math.abs(note.time - time) <= ATTACHED_NOTE_MS);
      dragStartTimes.push(time);
      attachedNotes.push(notes);
      attachedTimes.push([for (note in notes) note.time]);
    }
    return items;
  }

  override function getTime(item:Int):Float
  {
    return subBeats[item];
  }

  /**
   * Moved in place while dragging, sorted once the drag ends.
   */
  override function setTimes(items:Array<Int>, times:Array<Float>):Void
  {
    var notesMoved:Bool = false;
    for (i in 0...items.length)
    {
      subBeats[items[i]] = times[i];
      if (i >= attachedNotes.length) continue;
      var delta:Float = times[i] - dragStartTimes[i];
      for (j in 0...attachedNotes[i].length)
      {
        attachedNotes[i][j].time = attachedTimes[i][j] + delta;
        notesMoved = true;
      }
    }
    state.gridLinesDirty = true;
    if (notesMoved) state.noteDisplayDirty = true;
  }

  override function commitMove(items:Array<Int>, targetTimes:Array<Float>):Void
  {
    var after:Array<Float> = subBeats.copy();
    for (i in 0...items.length)
    {
      after[items[i]] = targetTimes[i];
      var snap:Null<Int> = ChartEditorSubBeatHandler.subBeatSnapOf(state.currentSongChartData?.editorData, subBeats[items[i]]);
      if (snap != null) state.rememberSubBeatSnap(targetTimes[i], snap);
    }

    after = after.filter(time -> !state.isTimeOnSnap(time));
    var notes:Array<SongNoteData> = [];
    var notesBefore:Array<Float> = [];
    var notesAfter:Array<Float> = [];
    for (i in 0...items.length)
    {
      if (i >= attachedNotes.length) continue;
      var delta:Float = targetTimes[i] - dragStartTimes[i];
      for (j in 0...attachedNotes[i].length)
      {
        notes.push(attachedNotes[i][j]);
        notesBefore.push(attachedTimes[i][j]);
        notesAfter.push(attachedTimes[i][j] + delta);
      }
    }
    state.performCommand(new SetSubBeatsCommand(subBeats, after, targetTimes, items.length == 1 ? 'Move Sub-Beat' : 'Move Sub-Beats', notes, notesBefore,
      notesAfter));
    attachedNotes = [];
    attachedTimes = [];
    dragStartTimes = [];
  }

  override function onSelectionChanged():Void
  {
    state.gridLinesDirty = true;
  }

  override public function copySelection():Void
  {
    var times:Array<Float> = selectedTimes();
    if (times.length == 0) return;
    times.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    copied = [for (time in times) time - times[0]];
    copiedSnaps = [for (time in times) ChartEditorSubBeatHandler.subBeatSnapOf(state.currentSongChartData?.editorData, time) ?? 0];
    ChartEditorSelectableItems.lastCopied = this;
    state.success('Copied Sub-Beats', times.length == 1 ? 'Copied 1 sub-beat.' : 'Copied ${times.length} sub-beats.');
  }

  /**
   * Pastes the copied sub-beats starting at the playhead, then picks them.
   */
  override public function pasteSelection():Void
  {
    if (copied.length == 0) return;
    var start:Float = state.scrollPositionInMs + state.playheadPositionInMs;
    var pasted:Array<Float> = [];
    for (i in 0...copied.length)
    {
      var time:Float = start + copied[i];
      if (state.isTimeOnSnap(time)) continue;
      pasted.push(time);
      if (i < copiedSnaps.length) state.rememberSubBeatSnap(time, copiedSnaps[i]);
    }
    state.performCommand(new SetSubBeatsCommand(subBeats, subBeats.concat(pasted), pasted, 'Paste Sub-Beats'));
  }

  override public function deleteSelection():Void
  {
    var times:Array<Float> = selectedTimes();
    if (times.length == 0) return;
    var after:Array<Float> = subBeats.filter(time -> !times.contains(time));
    state.performCommand(new SetSubBeatsCommand(subBeats, after, [], times.length == 1 ? 'Remove Sub-Beat' : 'Remove Sub-Beats'));
  }
}
#end
