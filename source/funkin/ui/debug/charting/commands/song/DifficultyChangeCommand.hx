package funkin.ui.debug.charting.commands.song;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible change to the song's variations and difficulties.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class DifficultyChangeCommand implements ChartEditorCommand
{
  var label:String;
  var action:Null<Void->Bool>;
  var before:Null<DifficultyLayout> = null;
  var after:Null<DifficultyLayout> = null;

  /**
   * Whether the change did anything. Callers that need to know check this after performing the command.
   */
  public var changed(default, null):Bool = false;

  /**
   * @param label What the undo history calls this.
   * @param action Makes the change. Returns whether anything changed.
   */
  public function new(label:String, action:Void->Bool)
  {
    this.label = label;
    this.action = action;
  }

  /**
   * Perform the action. The first time runs the change, redo puts the result back.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    var redoLayout:Null<DifficultyLayout> = after;
    if (redoLayout != null)
    {
      restore(state, redoLayout);
      return;
    }
    var run:Null<Void->Bool> = action;
    if (run == null) return;
    before = capture(state);
    changed = run();
    after = capture(state);
    if (changed) state.saveDataDirty = true;
    // The change has what it needs now, and holding on to it would keep the panel that made it alive.
    action = null;
  }

  /**
   * Reverse the action, putting the variations and difficulties back how they were.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    var undoLayout:Null<DifficultyLayout> = before;
    if (undoLayout == null) return;
    restore(state, undoLayout);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
  }

  /**
   * Copy the parts of the song these changes touch.
   */
  @:nullSafety(Off)
  static function capture(state:ChartEditorState):DifficultyLayout
  {
    var layout:DifficultyLayout =
      {
        metadata: state.songMetadata.copy(),
        chartData: state.songChartData.copy(),
        difficulties: new Map(),
        variations: new Map(),
        ratings: new Map(),
        scrollSpeeds: new Map(),
        notes: new Map(),
        selectedVariation: state.selectedVariation,
        selectedDifficulty: state.selectedDifficulty
      };
    for (variation => metadata in state.songMetadata)
    {
      var playData = metadata.playData;
      if (playData.difficulties != null) layout.difficulties.set(variation, playData.difficulties.copy());
      if (playData.songVariations != null) layout.variations.set(variation, playData.songVariations.copy());
      if (playData.ratings != null) layout.ratings.set(variation, playData.ratings.copy());
    }
    for (variation => chart in state.songChartData)
    {
      if (chart.scrollSpeed != null) layout.scrollSpeeds.set(variation, chart.scrollSpeed.copy());
      if (chart.notes != null) layout.notes.set(variation, chart.notes.copy());
    }
    return layout;
  }

  @:nullSafety(Off)
  static function restore(state:ChartEditorState, layout:DifficultyLayout):Void
  {
    state.songMetadata.clear();
    for (variation => metadata in layout.metadata)
    {
      state.songMetadata.set(variation, metadata);
      var playData = metadata.playData;
      if (layout.difficulties.exists(variation)) playData.difficulties = layout.difficulties.get(variation).copy();
      if (layout.variations.exists(variation)) playData.songVariations = layout.variations.get(variation).copy();
      if (layout.ratings.exists(variation)) playData.ratings = layout.ratings.get(variation).copy();
    }
    state.songChartData.clear();
    for (variation => chart in layout.chartData)
    {
      state.songChartData.set(variation, chart);
      if (layout.scrollSpeeds.exists(variation)) chart.scrollSpeed = layout.scrollSpeeds.get(variation).copy();
      if (layout.notes.exists(variation)) chart.notes = layout.notes.get(variation).copy();
    }

    // Picked notes may belong to a difficulty that is gone now.
    state.currentNoteSelection = [];
    state.currentEventSelection = [];
    state.selectedVariation = layout.selectedVariation;
    state.selectedDifficulty = layout.selectedDifficulty;
    state.difficultyHeatmapDirty = true;
    state.markDifficultiesChanged();
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
  }

  /**
   * Whether the command should display in the undo/redo menu.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return changed;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return label;
  }
}

typedef DifficultyLayout =
{
  var metadata:Map<String, SongMetadata>;
  var chartData:Map<String, SongChartData>;
  var difficulties:Map<String, Array<String>>;
  var variations:Map<String, Array<String>>;
  var ratings:Map<String, Map<String, Int>>;
  var scrollSpeeds:Map<String, Map<String, Float>>;
  var notes:Map<String, Map<String, Array<SongNoteData>>>;
  var selectedVariation:String;
  var selectedDifficulty:String;
}
#end
